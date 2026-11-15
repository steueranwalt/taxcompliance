"""Datei-Upload im Chat (z. B. Gruendungsurkunde, Satzung/Gesellschaftsvertrag),
landet als Metadatensatz in `8_Unterlagen` (Vorgabe Nils Obenhaus).

Begrenzt Groesse und Dateityp. Die eigentlichen Bytes werden NICHT in
SharePoint selbst abgelegt (SharePoint-Spalte `file_link` ist ein reiner
Hyperlink, siehe `sharepoint-forms/README.md` Abschnitt E.8/8_Unterlagen) -
im Mock-Modus landen sie unter `mock_upload_dir`, im Azure-Betrieb waeren sie
in einem separaten, nicht-oeffentlichen Blob-Container abzulegen (siehe
../../infra/README.md "Offene Punkte").

WICHTIG - bewusst NICHT implementiert, siehe README "Offene Punkte":
    Es findet HIER KEINE Malware-/Virenpruefung der hochgeladenen Datei statt.
    Das ist ein offener Punkt vor einem produktiven Einsatz mit echten
    Mandantendaten (z. B. Microsoft Defender for Storage/EICAR-Test oder ein
    Virenscan-Schritt vor Freigabe des Blobs). Bis dahin NUR mit Testdaten
    verwenden (siehe Haupt-README "Datenschutz").
"""

from __future__ import annotations

import hashlib
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from .config import Settings

# Bewusst klein gehalten: die in 8_Unterlagen vorgesehenen Dokumenttypen
# (Gesellschaftsvertrag/Gruendungsurkunde, Satzung, Handelsregisterauszug,
# Vollmachten) sind ueblicherweise PDF oder Scans. Keine Office-Formate mit
# Makro-Risiko, keine Archive.
ALLOWED_EXTENSIONS = {".pdf", ".jpg", ".jpeg", ".png"}
ALLOWED_CONTENT_TYPES = {"application/pdf", "image/jpeg", "image/png"}


class UploadRejected(Exception):
    def __init__(self, reason: str, message: str):
        super().__init__(message)
        self.reason = reason
        self.message = message


@dataclass
class UploadResult:
    file_link: str
    document_type: str
    original_filename: str
    size_bytes: int
    sha256: str


def validate_upload(
    *, filename: str, content_type: str, data: bytes, settings: Settings
) -> None:
    extension = Path(filename).suffix.lower()
    if extension not in ALLOWED_EXTENSIONS:
        raise UploadRejected(
            "type_not_allowed",
            f"Dieser Dateityp wird nicht unterstuetzt. Erlaubt sind: "
            f"{', '.join(sorted(ALLOWED_EXTENSIONS))}.",
        )
    if content_type not in ALLOWED_CONTENT_TYPES:
        raise UploadRejected(
            "type_not_allowed",
            f"Dieser Dateityp wird nicht unterstuetzt. Erlaubt sind: PDF, JPG, PNG.",
        )
    if len(data) == 0:
        raise UploadRejected("empty_file", "Die Datei ist leer.")
    if len(data) > settings.upload_max_bytes:
        max_mb = settings.upload_max_bytes / (1024 * 1024)
        raise UploadRejected(
            "too_large",
            f"Die Datei ist zu gross (maximal {max_mb:.0f} MB).",
        )


def store_upload_mock(
    *,
    filename: str,
    content_type: str,
    data: bytes,
    document_type: str,
    settings: Settings,
    mock_upload_dir: Optional[str | Path] = None,
) -> UploadResult:
    """Validiert und speichert einen Upload lokal (Mock-Modus). Fuer den
    echten Azure-Betrieb siehe README/infra: Upload muesste stattdessen in
    einen privaten Blob-Container der Function-Storage gehen; dieselbe
    `validate_upload`-Pruefung bliebe unveraendert."""
    validate_upload(filename=filename, content_type=content_type, data=data, settings=settings)

    target_dir = Path(mock_upload_dir or settings.mock_upload_dir)
    target_dir.mkdir(parents=True, exist_ok=True)

    digest = hashlib.sha256(data).hexdigest()
    stored_name = f"{uuid.uuid4()}{Path(filename).suffix.lower()}"
    (target_dir / stored_name).write_bytes(data)

    return UploadResult(
        file_link=f"mock://uploads/{stored_name}",
        document_type=document_type,
        original_filename=filename,
        size_bytes=len(data),
        sha256=digest,
    )
