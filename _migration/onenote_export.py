#!/usr/bin/env python3
"""Export SharePoint-hosted OneNote notebook to Markdown in taxcompliance repo."""

from __future__ import annotations

import html2text
import json
import os
import re
from pathlib import Path
from urllib.parse import urlparse

import msal
import requests

# Fallback: Microsoft Graph Command Line Tools (public client, device-code capable)
DEFAULT_CLIENT_ID = "14d82eec-204b-4c2f-b7e8-296a70dab67e"

SITE_HOST = "obenhaus.sharepoint.com"
SITE_PATH = "/sites/Wissen"
NOTEBOOK_ID = "f70597e9-18cd-4f95-b673-0f90a54455e7"
OUTPUT_ROOT = Path(__file__).resolve().parent.parent / "Diverses"

DELEGATED_SCOPES = ["Notes.Read.All", "Sites.Read.All"]
APPLICATION_SCOPES = ["https://graph.microsoft.com/.default"]


def slugify(name: str) -> str:
    name = name.strip()
    name = re.sub(r"[<>:\"/\\|?*]", "-", name)
    name = re.sub(r"\s+", "-", name)
    name = re.sub(r"-+", "-", name)
    return name.strip("-") or "unbenannt"


def load_env_file() -> None:
    env_path = Path(__file__).resolve().parent / ".env"
    if not env_path.exists():
        return
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def auth_config() -> dict:
    tenant_id = os.getenv("ENTRA_TENANT_ID") or os.getenv("AZURE_TENANT_ID")
    client_id = os.getenv("ENTRA_CLIENT_ID") or os.getenv("AZURE_CLIENT_ID")
    client_secret = os.getenv("ENTRA_CLIENT_SECRET") or os.getenv("AZURE_CLIENT_SECRET")
    auth_mode = (os.getenv("ENTRA_AUTH_MODE") or "auto").lower()

    if not client_id:
        client_id = DEFAULT_CLIENT_ID

    if auth_mode == "auto":
        auth_mode = "client_credentials" if client_secret else "device_code"

    authority = (
        f"https://login.microsoftonline.com/{tenant_id}"
        if tenant_id
        else "https://login.microsoftonline.com/organizations"
    )

    return {
        "tenant_id": tenant_id,
        "client_id": client_id,
        "client_secret": client_secret,
        "auth_mode": auth_mode,
        "authority": authority,
    }


def get_token() -> str:
    load_env_file()
    config = auth_config()

    if config["auth_mode"] == "client_credentials":
        if not config["client_secret"]:
            raise RuntimeError(
                "ENTRA_CLIENT_SECRET fehlt. Für App-only-Zugriff Client Secret setzen "
                "oder ENTRA_AUTH_MODE=device_code verwenden."
            )
        app = msal.ConfidentialClientApplication(
            config["client_id"],
            authority=config["authority"],
            client_credential=config["client_secret"],
        )
        result = app.acquire_token_for_client(scopes=APPLICATION_SCOPES)
        if "access_token" not in result:
            raise RuntimeError(
                result.get("error_description")
                or result.get("error")
                or "Client-Credentials-Auth fehlgeschlagen"
            )
        return result["access_token"]

    cache = msal.SerializableTokenCache()
    cache_path = Path.home() / ".cache" / "taxcompliance-onenote-msal.json"
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    if cache_path.exists():
        cache.deserialize(cache_path.read_text())

    app = msal.PublicClientApplication(
        config["client_id"],
        authority=config["authority"],
        token_cache=cache,
    )

    accounts = app.get_accounts()
    if accounts:
        result = app.acquire_token_silent(DELEGATED_SCOPES, account=accounts[0])
        if result and "access_token" in result:
            if cache.has_state_changed:
                cache_path.write_text(cache.serialize())
            return result["access_token"]

    flow = app.initiate_device_flow(scopes=DELEGATED_SCOPES)
    if "user_code" not in flow:
        raise RuntimeError(f"Device flow failed: {json.dumps(flow, indent=2)}")

    print(flow["message"], flush=True)
    result = app.acquire_token_by_device_flow(flow)
    if "access_token" not in result:
        raise RuntimeError(
            result.get("error_description") or result.get("error") or "Auth failed"
        )

    if cache.has_state_changed:
        cache_path.write_text(cache.serialize())
    return result["access_token"]


class GraphClient:
    def __init__(self, token: str):
        self.session = requests.Session()
        self.session.headers.update({"Authorization": f"Bearer {token}"})

    def get_json(self, url: str) -> dict:
        resp = self.session.get(url, timeout=60)
        resp.raise_for_status()
        return resp.json()

    def get_text(self, url: str) -> str:
        resp = self.session.get(url, timeout=120)
        resp.raise_for_status()
        return resp.text


def html_to_markdown(html: str, title: str) -> str:
    converter = html2text.HTML2Text()
    converter.body_width = 0
    converter.ignore_images = False
    converter.ignore_links = False
    converter.protect_links = True
    body = converter.handle(html).strip()
    return f"# {title}\n\n{body}\n"


def download_assets(client: GraphClient, html: str, page_dir: Path) -> str:
    assets_dir = page_dir / "assets"
    assets_dir.mkdir(parents=True, exist_ok=True)

    for match in re.finditer(r'src="([^"]+)"', html):
        src = match.group(1)
        if not src.startswith("http"):
            continue
        parsed = urlparse(src)
        if "onenote" not in parsed.path and "sharepoint" not in parsed.netloc:
            continue
        filename = slugify(Path(parsed.path).name) or f"asset-{hash(src) & 0xFFFF:x}"
        target = assets_dir / filename
        if target.exists():
            continue
        try:
            resp = client.session.get(src, timeout=120)
            resp.raise_for_status()
            target.write_bytes(resp.content)
            html = html.replace(src, f"assets/{filename}")
        except requests.RequestException:
            pass
    return html


def resolve_site_id(client: GraphClient) -> str:
    site = client.get_json(
        f"https://graph.microsoft.com/v1.0/sites/{SITE_HOST}:{SITE_PATH}"
    )
    return site["id"]


def export_notebook(client: GraphClient, site_id: str) -> None:
    base = f"https://graph.microsoft.com/v1.0/sites/{site_id}/onenote"
    notebooks = client.get_json(f"{base}/notebooks")
    notebook = next(
        (n for n in notebooks.get("value", []) if n.get("id", "").endswith(NOTEBOOK_ID)),
        None,
    )
    if not notebook:
        notebook = next(
            (
                n
                for n in notebooks.get("value", [])
                if "diverses" in n.get("displayName", "").lower()
            ),
            None,
        )
    if not notebook:
        names = [n.get("displayName") for n in notebooks.get("value", [])]
        raise RuntimeError(f"Notebook not found. Available: {names}")

    notebook_name = notebook["displayName"]
    notebook_dir = OUTPUT_ROOT
    notebook_dir.mkdir(parents=True, exist_ok=True)

    sections = client.get_json(f"{base}/notebooks/{notebook['id']}/sections")
    index_lines = [
        f"# {notebook_name}",
        "",
        f"Quelle: SharePoint Wissen (`{SITE_HOST}{SITE_PATH}`)",
        f"Notebook-ID: `{NOTEBOOK_ID}`",
        "",
        "## Abschnitte",
        "",
    ]

    for section in sections.get("value", []):
        section_name = section["displayName"]
        section_slug = slugify(section_name)
        section_dir = notebook_dir / section_slug
        section_dir.mkdir(parents=True, exist_ok=True)

        pages = client.get_json(f"{base}/sections/{section['id']}/pages")
        section_index = [f"# {section_name}", "", "## Seiten", ""]

        for page in pages.get("value", []):
            title = page.get("title") or "Unbenannte Seite"
            page_slug = slugify(title)
            page_dir = section_dir / page_slug
            page_dir.mkdir(parents=True, exist_ok=True)

            html = client.get_text(f"{base}/pages/{page['id']}/content")
            html = download_assets(client, html, page_dir)
            markdown = html_to_markdown(html, title)

            (page_dir / "README.md").write_text(markdown, encoding="utf-8")
            section_index.append(f"- [{title}]({page_slug}/README.md)")
            print(f"Exported: {section_name} / {title}", flush=True)

        (section_dir / "README.md").write_text(
            "\n".join(section_index) + "\n", encoding="utf-8"
        )
        index_lines.append(f"- [{section_name}]({section_slug}/README.md)")

    (notebook_dir / "README.md").write_text("\n".join(index_lines) + "\n", encoding="utf-8")
    print(f"\nDone. Output: {notebook_dir}", flush=True)


def main() -> int:
    token = get_token()
    client = GraphClient(token)
    site_id = resolve_site_id(client)
    export_notebook(client, site_id)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(130)
