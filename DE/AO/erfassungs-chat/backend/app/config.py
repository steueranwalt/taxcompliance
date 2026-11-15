"""Zentrale Konfiguration, ausschliesslich ueber Umgebungsvariablen.

Keine Secrets im Code oder im Repo (siehe ../../README.md "Datenschutz").
Alle Azure-Aufrufe erfolgen ueber Managed Identity (`DefaultAzureCredential`)
- es gibt bewusst keine API-Key-Variable fuer Azure OpenAI.
"""

from __future__ import annotations

import os
import tempfile
from dataclasses import dataclass


def _env_bool(name: str, default: bool) -> bool:
    raw = os.environ.get(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "ja", "yes"}


def _env_int(name: str, default: int) -> int:
    raw = os.environ.get(name)
    if raw is None:
        return default
    return int(raw)


@dataclass(frozen=True)
class Settings:
    # Mock-Schalter: ERFASSUNGSCHAT_MOCK_MODE=true laeuft komplett ohne Azure
    # (siehe README "Lokal testbar machen"). Granular pro Abhaengigkeit
    # ueberschreibbar, falls z. B. SharePoint real, LLM aber gemockt laufen
    # soll (oder umgekehrt fuer einen Dry-Run).
    mock_mode: bool = _env_bool("ERFASSUNGSCHAT_MOCK_MODE", True)
    mock_sharepoint: bool = _env_bool("ERFASSUNGSCHAT_MOCK_SHAREPOINT", mock_mode)
    mock_llm: bool = _env_bool("ERFASSUNGSCHAT_MOCK_LLM", mock_mode)

    # Azure OpenAI (accompli-azureai, switzerlandnorth/EU-Datenzone). Nur
    # Endpunkt + Deployment-Name als Konfiguration, kein Key.
    aoai_endpoint: str = os.environ.get("AOAI_ENDPOINT", "")
    aoai_deployment: str = os.environ.get("AOAI_DEPLOYMENT", "gpt-5.6-sol-dz")
    aoai_api_version: str = os.environ.get("AOAI_API_VERSION", "2024-08-01-preview")

    # Microsoft Graph / SharePoint (Sites.Selected, Managed Identity).
    graph_site_hostname: str = os.environ.get("GRAPH_SITE_HOSTNAME", "transferpricingdocs.sharepoint.com")
    graph_site_path: str = os.environ.get("GRAPH_SITE_PATH", "/sites/steuerdaten")

    # Managed Identity Client-ID (user-assigned MI), falls mehrere MI an der
    # Function App haengen - leer = systemseitig zugewiesene Identity bzw.
    # vom DefaultAzureCredential automatisch ermittelte Identity.
    managed_identity_client_id: str = os.environ.get("AZURE_CLIENT_ID", "")

    # Zugriffsschutz (siehe access_control.py).
    link_validity_hours: int = _env_int("ERFASSUNGSCHAT_LINK_VALIDITY_HOURS", 14 * 24)
    max_attempts_per_window: int = _env_int("ERFASSUNGSCHAT_MAX_ATTEMPTS", 5)
    lockout_window_minutes: int = _env_int("ERFASSUNGSCHAT_LOCKOUT_WINDOW_MINUTES", 15)
    lockout_duration_minutes: int = _env_int("ERFASSUNGSCHAT_LOCKOUT_DURATION_MINUTES", 60)
    rate_limit_per_minute: int = _env_int("ERFASSUNGSCHAT_RATE_LIMIT_PER_MINUTE", 20)

    # Serverseitige Chat-Session: nur so lange wie noetig, dann geloescht
    # (siehe README "Datenschutz").
    session_ttl_minutes: int = _env_int("ERFASSUNGSCHAT_SESSION_TTL_MINUTES", 45)

    # Datei-Upload (siehe document_upload.py).
    upload_max_bytes: int = _env_int("ERFASSUNGSCHAT_UPLOAD_MAX_BYTES", 15 * 1024 * 1024)

    # Pfad zu den generierten Schema-/Feld-Metadaten (siehe generator/cli.py).
    schema_output_dir: str = os.environ.get(
        "ERFASSUNGSCHAT_SCHEMA_DIR",
        os.path.join(os.path.dirname(__file__), "..", "..", "generator", "output"),
    )

    # Pfad zu den Mock-SharePoint-JSON-Dateien (nur relevant, wenn
    # mock_sharepoint=True).
    mock_sharepoint_dir: str = os.environ.get(
        "ERFASSUNGSCHAT_MOCK_SHAREPOINT_DIR",
        os.path.join(os.path.dirname(__file__), "..", "mocks", "sharepoint_data"),
    )

    # Zielordner fuer Mock-Datei-Uploads (siehe document_upload.py). Bewusst
    # AUSSERHALB des Repo-Baums (System-Temp), damit Testlaeufe keine
    # Upload-Artefakte ins Repository schreiben.
    mock_upload_dir: str = os.environ.get(
        "ERFASSUNGSCHAT_MOCK_UPLOAD_DIR",
        os.path.join(tempfile.gettempdir(), "erfassungschat-mock-uploads"),
    )


def get_settings() -> Settings:
    return Settings()
