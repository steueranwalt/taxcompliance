"""SharePoint-Zugriff ueber Microsoft Graph (Sites.Selected, Managed
Identity) - mit einem reinen JSON-Mock-Modus fuer lokale Tests ohne Azure.

Beide Implementierungen erfuellen dasselbe `SharePointClient`-Protocol, damit
`conversation.py`/`validation.py` nie wissen muessen, ob sie gegen Azure oder
gegen lokale JSON-Dateien arbeiten (siehe README "Lokal testbar machen").

`GraphSharePointClient` importiert `azure-identity`/`requests` bewusst erst
beim ersten echten Aufruf (lazy import), damit die Unit-Tests und der
Mock-Betrieb ohne diese Pakete installiert laufen.
"""

from __future__ import annotations

import json
import uuid
from pathlib import Path
from typing import Optional, Protocol


class SharePointError(RuntimeError):
    pass


class SharePointClient(Protocol):
    def get_item(self, list_name: str, lookup_field: str, lookup_value: str) -> Optional[dict]:
        """Liefert das erste Element der Liste, bei dem `lookup_field` ==
        `lookup_value` ist, oder `None`."""
        ...

    def create_item(self, list_name: str, fields: dict) -> dict:
        """Legt ein neues Element an und gibt es (inkl. vergebener ID)
        zurueck."""
        ...

    def update_item(self, list_name: str, item_id: str, fields: dict) -> dict:
        ...


class MockSharePointClient:
    """Haelt den Zustand aller Listen als JSON-Dateien unter
    `mock_sharepoint_dir` (eine Datei je Liste, Inhalt: Liste von Objekten
    inkl. technischer `Id`). Seed-Daten fuer das Testszenario liegen in
    `backend/mocks/sharepoint_data/`.

    Schreibt NICHT automatisch zurueck auf die Datei (damit Tests
    reproduzierbar bleiben und parallel laufen koennen) - `persist()` muss
    explizit aufgerufen werden, wenn ein Test/Demo-Lauf den Endzustand
    inspizieren soll.
    """

    def __init__(self, data_dir: str | Path):
        self._dir = Path(data_dir)
        self._lists: dict[str, list[dict]] = {}
        self._dirty: set[str] = set()
        if self._dir.exists():
            for f in self._dir.glob("*.json"):
                self._lists[f.stem] = json.loads(f.read_text(encoding="utf-8"))

    def _list(self, list_name: str) -> list[dict]:
        return self._lists.setdefault(list_name, [])

    def get_item(self, list_name: str, lookup_field: str, lookup_value: str) -> Optional[dict]:
        for item in self._list(list_name):
            if item.get(lookup_field) == lookup_value:
                return dict(item)
        return None

    def get_items(self, list_name: str, lookup_field: str, lookup_value: str) -> list[dict]:
        return [
            dict(item)
            for item in self._list(list_name)
            if item.get(lookup_field) == lookup_value
        ]

    def create_item(self, list_name: str, fields: dict) -> dict:
        items = self._list(list_name)
        new_item = dict(fields)
        new_item.setdefault("Id", str(uuid.uuid4()))
        items.append(new_item)
        self._dirty.add(list_name)
        return dict(new_item)

    def update_item(self, list_name: str, item_id: str, fields: dict) -> dict:
        items = self._list(list_name)
        for item in items:
            if item.get("Id") == item_id:
                item.update(fields)
                self._dirty.add(list_name)
                return dict(item)
        raise SharePointError(f"Element {item_id} nicht in {list_name} gefunden.")

    def persist(self) -> None:
        self._dir.mkdir(parents=True, exist_ok=True)
        for list_name in self._dirty:
            path = self._dir / f"{list_name}.json"
            path.write_text(
                json.dumps(self._lists[list_name], ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )

    def snapshot(self) -> dict[str, list[dict]]:
        """Fuer Tests: aktueller In-Memory-Zustand aller Listen."""
        return {name: [dict(i) for i in items] for name, items in self._lists.items()}


class GraphSharePointClient:
    """Echter Microsoft-Graph-Zugriff ueber Managed Identity (Sites.Selected).

    NICHT in dieser Session gegen einen Tenant getestet (siehe README
    "Rahmen"). Lazy Imports, damit `azure-identity`/`requests` nur bei
    echtem Azure-Betrieb installiert sein muessen.
    """

    def __init__(self, *, site_hostname: str, site_path: str, managed_identity_client_id: str = ""):
        self._site_hostname = site_hostname
        self._site_path = site_path
        self._managed_identity_client_id = managed_identity_client_id
        self._site_id: Optional[str] = None
        self._list_ids: dict[str, str] = {}
        self._credential = None
        self._session = None

    def _ensure_client(self):
        if self._credential is not None:
            return
        try:
            import requests  # type: ignore
            from azure.identity import DefaultAzureCredential  # type: ignore
        except ImportError as exc:  # pragma: no cover - nur ohne Azure-Pakete
            raise SharePointError(
                "azure-identity/requests nicht installiert - siehe "
                "backend/requirements.txt. Fuer lokale Tests ERFASSUNGSCHAT_MOCK_SHAREPOINT=true setzen."
            ) from exc
        kwargs = {}
        if self._managed_identity_client_id:
            kwargs["managed_identity_client_id"] = self._managed_identity_client_id
        self._credential = DefaultAzureCredential(**kwargs)
        self._session = requests.Session()

    def _token(self) -> str:
        self._ensure_client()
        token = self._credential.get_token("https://graph.microsoft.com/.default")
        return token.token

    def _graph_get(self, path: str) -> dict:
        self._ensure_client()
        resp = self._session.get(
            f"https://graph.microsoft.com/v1.0{path}",
            headers={"Authorization": f"Bearer {self._token()}"},
            timeout=30,
        )
        if resp.status_code >= 400:
            raise SharePointError(f"Graph GET {path} fehlgeschlagen: {resp.status_code} {resp.text[:500]}")
        return resp.json()

    def _graph_post(self, path: str, body: dict) -> dict:
        self._ensure_client()
        resp = self._session.post(
            f"https://graph.microsoft.com/v1.0{path}",
            headers={"Authorization": f"Bearer {self._token()}", "Content-Type": "application/json"},
            json=body,
            timeout=30,
        )
        if resp.status_code >= 400:
            raise SharePointError(f"Graph POST {path} fehlgeschlagen: {resp.status_code} {resp.text[:500]}")
        return resp.json()

    def _graph_patch(self, path: str, body: dict) -> dict:
        self._ensure_client()
        resp = self._session.patch(
            f"https://graph.microsoft.com/v1.0{path}",
            headers={"Authorization": f"Bearer {self._token()}", "Content-Type": "application/json"},
            json=body,
            timeout=30,
        )
        if resp.status_code >= 400:
            raise SharePointError(f"Graph PATCH {path} fehlgeschlagen: {resp.status_code} {resp.text[:500]}")
        return resp.json()

    def _resolve_site_id(self) -> str:
        if self._site_id is None:
            data = self._graph_get(f"/sites/{self._site_hostname}:{self._site_path}")
            self._site_id = data["id"]
        return self._site_id

    def _resolve_list_id(self, list_name: str) -> str:
        if list_name not in self._list_ids:
            site_id = self._resolve_site_id()
            data = self._graph_get(f"/sites/{site_id}/lists/{list_name}")
            self._list_ids[list_name] = data["id"]
        return self._list_ids[list_name]

    def get_item(self, list_name: str, lookup_field: str, lookup_value: str) -> Optional[dict]:
        site_id = self._resolve_site_id()
        list_id = self._resolve_list_id(list_name)
        safe_value = str(lookup_value).replace("'", "''")
        data = self._graph_get(
            f"/sites/{site_id}/lists/{list_id}/items"
            f"?expand=fields&$filter=fields/{lookup_field} eq '{safe_value}'"
        )
        values = data.get("value", [])
        if not values:
            return None
        return values[0]["fields"]

    def create_item(self, list_name: str, fields: dict) -> dict:
        site_id = self._resolve_site_id()
        list_id = self._resolve_list_id(list_name)
        data = self._graph_post(f"/sites/{site_id}/lists/{list_id}/items", {"fields": fields})
        return data["fields"]

    def update_item(self, list_name: str, item_id: str, fields: dict) -> dict:
        site_id = self._resolve_site_id()
        list_id = self._resolve_list_id(list_name)
        data = self._graph_patch(f"/sites/{site_id}/lists/{list_id}/items/{item_id}/fields", fields)
        return data
