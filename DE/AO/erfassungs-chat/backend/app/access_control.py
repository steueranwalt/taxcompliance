"""Eigene Zugangspruefung fuer den Erfassungs-Chat.

Die Azure Function ist HTTP-anonym erreichbar (siehe README Zielarchitektur),
die eigentliche Pruefung erfolgt hier: `case_id` + `access_code` muessen zu
einem bestehenden, noch nicht abgelaufenen `0_Fallsteuerung`-Eintrag passen.
Dazu: Rate-Limit pro IP, Sperre nach Fehlversuchen, Ablauf des Links.

Diese Pruefung ersetzt NICHT die SharePoint-Berechtigung (die Function App
schreibt ueber eine eigene Managed Identity mit Sites.Selected) - sie ist
ausschliesslich die Mandantenseitige Plausibilitaets-/Missbrauchspruefung,
analog zur in `sharepoint-forms/README.md` Abschnitt D1 beschriebenen
Pruefung fuer die Forms-/Flow-Vorgaenger-Loesung.
"""

from __future__ import annotations

import hmac
import time
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Optional

from .config import Settings
from .sharepoint_client import SharePointClient


class AccessDenied(Exception):
    """Zugriff verweigert. `reason` ist ein stabiler, maschinenlesbarer Code
    (kein Freitext mit Interna) fuer die Frontend-Fehlermeldung."""

    def __init__(self, reason: str, message: str):
        super().__init__(message)
        self.reason = reason
        self.message = message


@dataclass
class _AttemptLog:
    timestamps: list[float] = field(default_factory=list)
    locked_until: Optional[float] = None


class RateLimiter:
    """Einfacher In-Memory-Rate-Limiter + Sperre nach Fehlversuchen, keyed
    nach Client-IP. Fuer eine Flex-Consumption-Function mit mehreren
    Instanzen ist das pro Instanz wirksam, nicht global - siehe README
    "Offene Punkte" (produktiv waere eine gemeinsame Zaehlstelle, z. B.
    Azure Table/Redis, noetig; fuer den Prototyp bewusst einfach gehalten).
    """

    def __init__(self, settings: Settings, *, clock=time.monotonic):
        self._settings = settings
        self._clock = clock
        self._rate_log: dict[str, list[float]] = {}
        self._attempt_log: dict[str, _AttemptLog] = {}

    def check_rate_limit(self, client_key: str) -> None:
        now = self._clock()
        window_start = now - 60.0
        log = self._rate_log.setdefault(client_key, [])
        log[:] = [t for t in log if t >= window_start]
        if len(log) >= self._settings.rate_limit_per_minute:
            raise AccessDenied(
                "rate_limited",
                "Zu viele Anfragen. Bitte warten Sie eine Minute und versuchen Sie es erneut.",
            )
        log.append(now)

    def check_not_locked(self, client_key: str) -> None:
        entry = self._attempt_log.get(client_key)
        if entry and entry.locked_until is not None:
            if self._clock() < entry.locked_until:
                raise AccessDenied(
                    "locked_out",
                    "Zu viele fehlgeschlagene Versuche. Bitte versuchen Sie es spaeter erneut "
                    "oder wenden Sie sich an die Kanzlei.",
                )
            entry.locked_until = None

    def record_failure(self, client_key: str) -> None:
        now = self._clock()
        window_start = now - self._settings.lockout_window_minutes * 60
        entry = self._attempt_log.setdefault(client_key, _AttemptLog())
        entry.timestamps = [t for t in entry.timestamps if t >= window_start]
        entry.timestamps.append(now)
        if len(entry.timestamps) >= self._settings.max_attempts_per_window:
            entry.locked_until = now + self._settings.lockout_duration_minutes * 60

    def record_success(self, client_key: str) -> None:
        self._attempt_log.pop(client_key, None)


@dataclass
class CaseAccessResult:
    case_id: str
    case_fields: dict


def _parse_case_created(case_fields: dict) -> Optional[datetime]:
    raw = case_fields.get("Created") or case_fields.get("created")
    if not raw:
        return None
    try:
        return datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return None


def verify_case_access(
    *,
    case_id: str,
    access_code: str,
    client_key: str,
    sharepoint: SharePointClient,
    settings: Settings,
    rate_limiter: RateLimiter,
    now: Optional[datetime] = None,
) -> CaseAccessResult:
    """Prueft `case_id` + `access_code` gegen `0_Fallsteuerung`.

    Wirft `AccessDenied` mit neutralem, nicht-Interna-preisgebendem Grund in
    allen Fehlerfaellen (unbekannte case_id, falscher access_code,
    abgelaufener Link, Sperre, Rate-Limit) - bewusst OHNE zu verraten, WELCHER
    der beiden Werte falsch war (verhindert Enumeration von case_id/access_code).
    """
    rate_limiter.check_rate_limit(client_key)
    rate_limiter.check_not_locked(client_key)

    now = now or datetime.now(timezone.utc)

    case_fields = sharepoint.get_item("0_Fallsteuerung", "case_id", case_id)
    generic_denied = AccessDenied(
        "invalid_credentials",
        "Fall-ID oder Zugangscode sind nicht gueltig. Bitte pruefen Sie den Link "
        "oder wenden Sie sich an die Kanzlei.",
    )

    if case_fields is None:
        rate_limiter.record_failure(client_key)
        raise generic_denied

    stored_code = case_fields.get("access_code") or ""
    # Konstante-Zeit-Vergleich gegen simples Timing-basiertes Erraten.
    if not stored_code or not hmac.compare_digest(stored_code, access_code):
        rate_limiter.record_failure(client_key)
        raise generic_denied

    created = _parse_case_created(case_fields)
    if created is not None:
        expiry = created + timedelta(hours=settings.link_validity_hours)
        if now > expiry:
            raise AccessDenied(
                "link_expired",
                "Dieser Link ist abgelaufen. Bitte wenden Sie sich an die Kanzlei "
                "fuer einen neuen Zugang.",
            )

    case_status = case_fields.get("case_status")
    if case_status == "übermittelt":
        raise AccessDenied(
            "case_closed",
            "Dieser Fall ist bereits abgeschlossen. Bei Rueckfragen wenden Sie "
            "sich bitte an die Kanzlei.",
        )

    rate_limiter.record_success(client_key)
    return CaseAccessResult(case_id=case_id, case_fields=case_fields)
