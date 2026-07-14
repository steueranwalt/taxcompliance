#!/usr/bin/env python3
"""Upload taxcompliance repo files to SharePoint Shared Documents/Wissen."""

from __future__ import annotations

import mimetypes
import time
from pathlib import Path

import msal
import requests

CLIENT_ID = "14d82eec-204b-4c2f-b7e8-296a70dab67e"
SCOPES = ["Sites.ReadWrite.All", "Files.ReadWrite.All"]
CACHE = Path.home() / ".cache" / "taxcompliance-sp-upload-msal.json"
DRIVE_ID = "b!txUA-xYwAkOWZsanStn0ZsLEnMxBv4hNnNIRXFHFgEbo5NGN2fQwSpPVL0s3Ns58"
DEST_ROOT = "Wissen"  # Shared Documents/Wissen
REPO_ROOT = Path(__file__).resolve().parent.parent

SKIP_DIR_NAMES = {".git", "__pycache__", ".cache", "node_modules"}
SKIP_FILE_NAMES = {".env", ".DS_Store"}
# Optional tooling – still useful on SP; include _migration except secrets
MAX_SIMPLE_UPLOAD = 3_900_000  # bytes; Graph simple upload limit ~4MB


def get_session() -> requests.Session:
    cache = msal.SerializableTokenCache()
    if CACHE.exists():
        cache.deserialize(CACHE.read_text())
    app = msal.PublicClientApplication(
        CLIENT_ID,
        authority="https://login.microsoftonline.com/organizations",
        token_cache=cache,
    )
    accounts = app.get_accounts()
    result = app.acquire_token_silent(SCOPES, account=accounts[0]) if accounts else None
    if not result or "access_token" not in result:
        flow = app.initiate_device_flow(scopes=SCOPES)
        print(flow["message"], flush=True)
        result = app.acquire_token_by_device_flow(flow)
        if "access_token" not in result:
            raise RuntimeError(result)
        CACHE.write_text(cache.serialize())
    elif cache.has_state_changed:
        CACHE.write_text(cache.serialize())
    sess = requests.Session()
    sess.headers["Authorization"] = f"Bearer {result['access_token']}"
    return sess


def iter_files(root: Path):
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(root)
        if any(part in SKIP_DIR_NAMES for part in rel.parts):
            continue
        if path.name in SKIP_FILE_NAMES:
            continue
        yield path, rel


def request_with_retry(sess: requests.Session, method: str, url: str, **kwargs) -> requests.Response:
    for attempt in range(12):
        try:
            resp = sess.request(method, url, timeout=180, **kwargs)
        except requests.RequestException as e:
            wait = min(30 * (attempt + 1), 180)
            print(f"net {e}; wait {wait}s", flush=True)
            time.sleep(wait)
            continue
        if resp.status_code == 401:
            # refresh token
            new = get_session()
            sess.headers["Authorization"] = new.headers["Authorization"]
            continue
        if resp.status_code in (429, 500, 502, 503, 504):
            wait = int(resp.headers.get("Retry-After") or min(30 * (attempt + 1), 180))
            print(f"{resp.status_code} wait {wait}s", flush=True)
            time.sleep(wait)
            continue
        return resp
    resp.raise_for_status()
    return resp


def upload_file(sess: requests.Session, local: Path, rel: Path) -> None:
    dest = f"{DEST_ROOT}/{rel.as_posix()}"
    url = f"https://graph.microsoft.com/v1.0/drives/{DRIVE_ID}/root:/{dest}:/content"
    data = local.read_bytes()
    mime = mimetypes.guess_type(local.name)[0] or "application/octet-stream"
    if len(data) <= MAX_SIMPLE_UPLOAD:
        resp = request_with_retry(
            sess,
            "PUT",
            url,
            data=data,
            headers={"Content-Type": mime},
        )
        if resp.status_code not in (200, 201):
            raise RuntimeError(f"{rel}: {resp.status_code} {resp.text[:300]}")
        return

    # upload session for larger files
    session_url = f"https://graph.microsoft.com/v1.0/drives/{DRIVE_ID}/root:/{dest}:/createUploadSession"
    resp = request_with_retry(
        sess,
        "POST",
        session_url,
        json={"item": {"@microsoft.graph.conflictBehavior": "replace", "name": local.name}},
    )
    resp.raise_for_status()
    upload_url = resp.json()["uploadUrl"]
    chunk = 3_276_800  # 3.125 MiB
    size = len(data)
    start = 0
    while start < size:
        end = min(start + chunk, size) - 1
        part = data[start : end + 1]
        headers = {
            "Content-Length": str(len(part)),
            "Content-Range": f"bytes {start}-{end}/{size}",
        }
        r = request_with_retry(sess, "PUT", upload_url, data=part, headers=headers)
        if r.status_code not in (200, 201, 202):
            raise RuntimeError(f"chunk {rel}: {r.status_code} {r.text[:200]}")
        start = end + 1


def main() -> int:
    sess = get_session()
    files = list(iter_files(REPO_ROOT))
    print(f"Uploading {len(files)} files to Shared Documents/{DEST_ROOT}/ …", flush=True)
    ok = 0
    for i, (local, rel) in enumerate(files, 1):
        try:
            upload_file(sess, local, rel)
            ok += 1
            if i % 25 == 0 or i == len(files):
                print(f"[{i}/{len(files)}] ok={ok} last={rel}", flush=True)
            time.sleep(0.15)
        except Exception as e:
            print(f"FAIL {rel}: {e}", flush=True)
            time.sleep(2)
    print(f"Done. Uploaded {ok}/{len(files)}", flush=True)
    return 0 if ok == len(files) else 1


if __name__ == "__main__":
    raise SystemExit(main())
