#!/usr/bin/env python3
"""Export SharePoint-hosted OneNote notebook to Markdown in taxcompliance repo."""

from __future__ import annotations

import hashlib
import html2text
import json
import os
import re
import time
from pathlib import Path
from urllib.parse import urlparse

import msal
import requests

DEFAULT_CLIENT_ID = "14d82eec-204b-4c2f-b7e8-296a70dab67e"

SITE_HOST = "obenhaus.sharepoint.com"
SITE_PATH = "/sites/Wissen"
# sourcedoc from user URL = notebook "Notizbuch für Wissen"
NOTEBOOK_ID = "1-2257fecb-9c1c-4982-bd55-f31b6d91a6c2"
OUTPUT_ROOT = Path(__file__).resolve().parent.parent / "Notizbuch-fuer-Wissen"
MAX_NAME = 80

DELEGATED_SCOPES = ["Notes.Read.All", "Sites.Read.All"]
APPLICATION_SCOPES = ["https://graph.microsoft.com/.default"]


def slugify(name: str, max_len: int = MAX_NAME) -> str:
    name = name.strip()
    name = re.sub(r"[<>:\"/\\|?*]", "-", name)
    name = re.sub(r"\s+", "-", name)
    name = re.sub(r"-+", "-", name).strip("-") or "unbenannt"
    if len(name) > max_len:
        digest = hashlib.sha1(name.encode()).hexdigest()[:8]
        name = name[: max_len - 9].rstrip("-") + "-" + digest
    return name


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
    client_id = os.getenv("ENTRA_CLIENT_ID") or os.getenv("AZURE_CLIENT_ID") or DEFAULT_CLIENT_ID
    client_secret = os.getenv("ENTRA_CLIENT_SECRET") or os.getenv("AZURE_CLIENT_SECRET")
    auth_mode = (os.getenv("ENTRA_AUTH_MODE") or "auto").lower()
    if auth_mode == "auto":
        auth_mode = "client_credentials" if client_secret else "device_code"
    authority = (
        f"https://login.microsoftonline.com/{tenant_id}"
        if tenant_id
        else "https://login.microsoftonline.com/organizations"
    )
    return {
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
            raise RuntimeError("ENTRA_CLIENT_SECRET fehlt.")
        app = msal.ConfidentialClientApplication(
            config["client_id"],
            authority=config["authority"],
            client_credential=config["client_secret"],
        )
        result = app.acquire_token_for_client(scopes=APPLICATION_SCOPES)
        if "access_token" not in result:
            raise RuntimeError(result.get("error_description") or "Auth failed")
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
        raise RuntimeError(result.get("error_description") or "Auth failed")
    if cache.has_state_changed:
        cache_path.write_text(cache.serialize())
    return result["access_token"]


class GraphClient:
    def __init__(self, token: str):
        self.session = requests.Session()
        self.session.headers.update({"Authorization": f"Bearer {token}"})

    def request(self, method: str, url: str, **kwargs) -> requests.Response:
        retries = 12
        timeout = kwargs.pop("timeout", 120)
        for attempt in range(retries):
            resp = self.session.request(method, url, timeout=timeout, **kwargs)
            if resp.status_code != 429 and resp.status_code < 500:
                return resp
            retry_after = resp.headers.get("Retry-After")
            wait = int(retry_after) if retry_after and retry_after.isdigit() else min(30 * (attempt + 1), 180)
            print(f"Throttled ({resp.status_code}), wait {wait}s…", flush=True)
            time.sleep(wait)
        resp.raise_for_status()
        return resp

    def get_json(self, url: str) -> dict:
        resp = self.request("GET", url)
        resp.raise_for_status()
        return resp.json()

    def get_list(self, url: str) -> list:
        items: list = []
        while url:
            data = self.get_json(url)
            items.extend(data.get("value", []))
            url = data.get("@odata.nextLink")
        return items

    def get_text(self, url: str) -> str:
        resp = self.request("GET", url)
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
        filename = slugify(Path(parsed.path).name, 60) or f"asset-{hash(src) & 0xFFFF:x}"
        target = assets_dir / filename
        if not target.exists():
            try:
                resp = client.request("GET", src)
                resp.raise_for_status()
                target.write_bytes(resp.content)
            except requests.RequestException:
                continue
        html = html.replace(src, f"assets/{filename}")
    return html


def export_section(client: GraphClient, base: str, section: dict, parent_dir: Path, index_lines: list) -> None:
    name = section["displayName"]
    slug = slugify(name)
    section_dir = parent_dir / slug
    section_dir.mkdir(parents=True, exist_ok=True)

    pages = client.get_list(f"{base}/sections/{section['id']}/pages?$orderby=order")
    section_index = [f"# {name}", "", "## Seiten", ""]
    used: dict[str, int] = {}

    for page in pages:
        title = page.get("title") or "Unbenannte Seite"
        base_slug = slugify(title)
        used[base_slug] = used.get(base_slug, 0) + 1
        page_slug = base_slug if used[base_slug] == 1 else f"{base_slug}-{used[base_slug]}"
        page_subdir = section_dir / page_slug
        readme = page_subdir / "README.md"
        if readme.exists() and readme.stat().st_size > 20:
            section_index.append(f"- [{title}]({page_slug}/README.md)")
            print(f"Skip: {name} / {title}", flush=True)
            continue
        page_subdir.mkdir(parents=True, exist_ok=True)
        html = client.get_text(f"{base}/pages/{page['id']}/content")
        html = download_assets(client, html, page_subdir)
        readme.write_text(html_to_markdown(html, title), encoding="utf-8")
        section_index.append(f"- [{title}]({page_slug}/README.md)")
        print(f"Exported: {name} / {title}", flush=True)
        time.sleep(0.2)

    (section_dir / "README.md").write_text("\n".join(section_index) + "\n", encoding="utf-8")
    index_lines.append(f"- [{name}]({slug}/README.md)")


def export_group(client: GraphClient, base: str, group: dict, parent_dir: Path, index_lines: list) -> None:
    name = group["displayName"]
    slug = slugify(name)
    group_dir = parent_dir / slug
    group_dir.mkdir(parents=True, exist_ok=True)
    group_index = [f"# {name}", "", "## Abschnitte", ""]

    for section in client.get_list(f"{base}/sectionGroups/{group['id']}/sections"):
        export_section(client, base, section, group_dir, group_index)
    for subgroup in client.get_list(f"{base}/sectionGroups/{group['id']}/sectionGroups"):
        export_group(client, base, subgroup, group_dir, group_index)

    (group_dir / "README.md").write_text("\n".join(group_index) + "\n", encoding="utf-8")
    index_lines.append(f"- [{name}/]({slug}/README.md)")


def export_notebook(client: GraphClient, site_id: str) -> None:
    base = f"https://graph.microsoft.com/v1.0/sites/{site_id}/onenote"
    notebook = client.get_json(f"{base}/notebooks/{NOTEBOOK_ID}")
    notebook_name = notebook["displayName"]
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)

    index_lines = [
        f"# {notebook_name}",
        "",
        f"Quelle: SharePoint Wissen (`{SITE_HOST}{SITE_PATH}`)",
        f"Notebook-ID: `{NOTEBOOK_ID}`",
        "",
        "## Abschnitte",
        "",
    ]

    for section in client.get_list(f"{base}/notebooks/{NOTEBOOK_ID}/sections"):
        export_section(client, base, section, OUTPUT_ROOT, index_lines)
    for group in client.get_list(f"{base}/notebooks/{NOTEBOOK_ID}/sectionGroups"):
        export_group(client, base, group, OUTPUT_ROOT, index_lines)

    (OUTPUT_ROOT / "README.md").write_text("\n".join(index_lines) + "\n", encoding="utf-8")
    print(f"\nDone. Output: {OUTPUT_ROOT}", flush=True)


def main() -> int:
    token = get_token()
    client = GraphClient(token)
    site = client.get_json(f"https://graph.microsoft.com/v1.0/sites/{SITE_HOST}:{SITE_PATH}")
    export_notebook(client, site["id"])
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(130)
