#!/usr/bin/env python3
"""Export only remaining/incomplete section groups for Notizbuch für Wissen."""

from __future__ import annotations

import hashlib
import html2text
import re
import time
from pathlib import Path
from urllib.parse import urlparse

import msal
import requests

CACHE = Path.home() / ".cache" / "taxcompliance-onenote-msal.json"
CLIENT_ID = "14d82eec-204b-4c2f-b7e8-296a70dab67e"
SCOPES = ["Notes.Read.All", "Sites.Read.All"]
SITE = "obenhaus.sharepoint.com,c8e1905c-859d-437a-be04-8a06fe606322,df8e44e5-a0c7-49d4-a950-711142afe01e"
BASE = f"https://graph.microsoft.com/v1.0/sites/{SITE}/onenote"
ROOT = Path(__file__).resolve().parent.parent / "Notizbuch-fuer-Wissen"
MAX_NAME = 80

# Known incomplete top-level groups
TARGETS = [
    ("group", "1-034faf24-4faa-40d6-88f2-1119a5f267db", "Steuern DE"),
    ("group", "1-aebecd89-5ece-429b-9eed-87165b6cc068", "International"),
]


def slugify(name: str, max_len: int = MAX_NAME) -> str:
    name = re.sub(r'[<>:"/\\|?*]', "-", name.strip())
    name = re.sub(r"\s+", "-", name)
    name = re.sub(r"-+", "-", name).strip("-") or "unbenannt"
    if len(name) > max_len:
        digest = hashlib.sha1(name.encode()).hexdigest()[:8]
        name = name[: max_len - 9].rstrip("-") + "-" + digest
    return name


def get_session() -> requests.Session:
    cache = msal.SerializableTokenCache()
    cache.deserialize(CACHE.read_text())
    app = msal.PublicClientApplication(
        CLIENT_ID,
        authority="https://login.microsoftonline.com/organizations",
        token_cache=cache,
    )
    result = app.acquire_token_silent(SCOPES, account=app.get_accounts()[0])
    if not result or "access_token" not in result:
        raise RuntimeError("Token abgelaufen")
    if cache.has_state_changed:
        CACHE.write_text(cache.serialize())
    sess = requests.Session()
    sess.headers["Authorization"] = f"Bearer {result['access_token']}"
    return sess


def req(sess: requests.Session, url: str, tries: int = 30) -> requests.Response:
    for i in range(tries):
        try:
            r = sess.get(url, timeout=120)
        except requests.RequestException as e:
            wait = min(30 * (i + 1), 180)
            print(f"net error {e}; wait {wait}s", flush=True)
            time.sleep(wait)
            sess = get_session()
            continue
        if r.status_code == 401:
            sess = get_session()
            continue
        if r.status_code != 429 and r.status_code < 500:
            r.raise_for_status()
            return r
        wait = int(r.headers.get("Retry-After") or min(120 * (i + 1), 360))
        print(f"429 wait {wait}s", flush=True)
        time.sleep(wait)
    r.raise_for_status()
    return r


def get_list(sess: requests.Session, url: str) -> list:
    items: list = []
    while url:
        data = req(sess, url).json()
        items.extend(data.get("value", []))
        url = data.get("@odata.nextLink")
        time.sleep(1.5)
    return items


def html_to_md(html: str, title: str) -> str:
    c = html2text.HTML2Text()
    c.body_width = 0
    c.ignore_images = False
    c.ignore_links = False
    c.protect_links = True
    return f"# {title}\n\n{c.handle(html).strip()}\n"


def download_assets(sess: requests.Session, html: str, page_dir: Path) -> str:
    assets = page_dir / "assets"
    assets.mkdir(parents=True, exist_ok=True)
    for m in re.finditer(r'src="([^"]+)"', html):
        src = m.group(1)
        if not src.startswith("http"):
            continue
        parsed = urlparse(src)
        if "onenote" not in parsed.path and "sharepoint" not in parsed.netloc:
            continue
        filename = slugify(Path(parsed.path).name, 60)
        target = assets / filename
        if not target.exists():
            try:
                target.write_bytes(req(sess, src).content)
            except Exception:
                continue
        html = html.replace(src, f"assets/{filename}")
    return html


def export_section(sess: requests.Session, section: dict, parent: Path) -> tuple[str, str, int]:
    name = section["displayName"]
    slug = slugify(name)
    sdir = parent / slug
    sdir.mkdir(parents=True, exist_ok=True)
    pages = get_list(sess, f"{BASE}/sections/{section['id']}/pages?$orderby=order")
    index = [f"# {name}", "", "## Seiten", ""]
    used: dict[str, int] = {}
    new_count = 0
    for page in pages:
        title = page.get("title") or "Unbenannte Seite"
        base = slugify(title)
        used[base] = used.get(base, 0) + 1
        pslug = base if used[base] == 1 else f"{base}-{used[base]}"
        pdir = sdir / pslug
        readme = pdir / "README.md"
        if readme.exists() and readme.stat().st_size > 20:
            index.append(f"- [{title}]({pslug}/README.md)")
            continue
        pdir.mkdir(parents=True, exist_ok=True)
        html = req(sess, f"{BASE}/pages/{page['id']}/content").text
        html = download_assets(sess, html, pdir)
        readme.write_text(html_to_md(html, title), encoding="utf-8")
        index.append(f"- [{title}]({pslug}/README.md)")
        print(f"Exported: {name} / {title}", flush=True)
        new_count += 1
        time.sleep(2.0)
    (sdir / "README.md").write_text("\n".join(index) + "\n", encoding="utf-8")
    if new_count == 0:
        print(f"Section complete: {name} ({len(pages)} pages)", flush=True)
    return slug, name, new_count


def export_group(sess: requests.Session, group_id: str, name: str, parent: Path) -> tuple[str, str, int]:
    slug = slugify(name)
    gdir = parent / slug
    gdir.mkdir(parents=True, exist_ok=True)
    gindex = [f"# {name}", "", "## Abschnitte", ""]
    total_new = 0
    for section in get_list(sess, f"{BASE}/sectionGroups/{group_id}/sections"):
        sslug, sname, n = export_section(sess, section, gdir)
        gindex.append(f"- [{sname}]({sslug}/README.md)")
        total_new += n
    for sg in get_list(sess, f"{BASE}/sectionGroups/{group_id}/sectionGroups"):
        cslug, cname, n = export_group(sess, sg["id"], sg["displayName"], gdir)
        gindex.append(f"- [{cname}/]({cslug}/README.md)")
        total_new += n
    (gdir / "README.md").write_text("\n".join(gindex) + "\n", encoding="utf-8")
    return slug, name, total_new


def write_root_index() -> None:
    lines = [
        "# Notizbuch für Wissen",
        "",
        "Quelle: SharePoint Wissen (`obenhaus.sharepoint.com/sites/Wissen`)",
        "Notebook-ID: `1-2257fecb-9c1c-4982-bd55-f31b6d91a6c2`",
        "",
        "## Abschnitte",
        "",
    ]
    for child in sorted(p for p in ROOT.iterdir() if p.is_dir()):
        if (child / "README.md").exists():
            lines.append(f"- [{child.name}]({child.name}/README.md)")
    (ROOT / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    print("Cool-down 4 minutes…", flush=True)
    time.sleep(240)
    sess = get_session()
    for kind, sid, name in TARGETS:
        print(f"=== {kind}: {name}", flush=True)
        try:
            if kind == "group":
                _, _, n = export_group(sess, sid, name, ROOT)
                print(f"New pages in {name}: {n}", flush=True)
        except Exception as e:
            print(f"ERROR {name}: {e}", flush=True)
            sess = get_session()
    write_root_index()
    print(f"DONE. README files: {len(list(ROOT.rglob('README.md')))}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
