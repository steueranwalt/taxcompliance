"""Serverseitige Chat-Session: nur so lange wie noetig vorgehalten, dann
geloescht (siehe README "Datenschutz" und Zielarchitektur "Backend").

Die Session enthaelt waehrend des laufenden Chats personenbezogene
Entwuerfe (Mandantenangaben vor der Bestaetigung). Sie wird NICHT
persistent gespeichert (kein Azure Table/Cosmos in diesem Prototyp -
In-Memory mit TTL reicht fuer eine einzelne Function-Instanz; siehe README
"Offene Punkte" fuer produktive Mehrinstanz-Skalierung) und endet spaetestens
nach `session_ttl_minutes` oder sofort nach erfolgreichem Abschluss
(`delete_session`).
"""

from __future__ import annotations

import time
import uuid
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class ChatSession:
    session_id: str
    case_id: str
    created_at: float
    expires_at: float
    # Fakten, die bereits einmal erfragt wurden (ask-once, siehe
    # conversation.py) - Schluessel ist ein fachlicher fact_key, nicht
    # notwendigerweise identisch mit einem SharePoint-Internal-Name.
    fact_cache: dict = field(default_factory=dict)
    # Je Abschnitt (Liste) die bereits gesammelten Datensaetze (fuer
    # wiederholbare Abschnitte wie Personen/Beteiligte/Betriebsstaetten/
    # Unterlagen: eine Liste von Antwort-Dicts; fuer einmalige Abschnitte
    # wie Stammblock/Gruendung: genau ein Dict).
    section_data: dict = field(default_factory=dict)
    # Felder, die der Mandant explizit mit "weiss ich nicht" beantwortet hat
    # (Liste von (section, record_index, internal_name)-Tupeln als Strings).
    unsure_fields: list = field(default_factory=list)
    # Interne, klar als Chat-Vorschlag markierte Hinweise fuer die Kanzlei -
    # NIE als Mandantenangabe behandelt, siehe conversation.py.
    internal_hints: list = field(default_factory=list)
    current_section: str = ""
    confirmed: bool = False
    submitted: bool = False


class SessionStore:
    """In-Memory-Implementierung mit TTL. `Protocol`-artig gehalten, damit
    ein produktiver Ersatz (Azure Table Storage mit TTL, Redis) dieselbe
    Schnittstelle bedienen kann, ohne `conversation.py` zu aendern."""

    def __init__(self, *, ttl_minutes: int, clock=time.time):
        self._ttl_seconds = ttl_minutes * 60
        self._clock = clock
        self._sessions: dict[str, ChatSession] = {}

    def create(self, case_id: str) -> ChatSession:
        self._evict_expired()
        now = self._clock()
        session = ChatSession(
            session_id=str(uuid.uuid4()),
            case_id=case_id,
            created_at=now,
            expires_at=now + self._ttl_seconds,
        )
        self._sessions[session.session_id] = session
        return session

    def get(self, session_id: str) -> Optional[ChatSession]:
        self._evict_expired()
        return self._sessions.get(session_id)

    def save(self, session: ChatSession) -> None:
        session.expires_at = self._clock() + self._ttl_seconds
        self._sessions[session.session_id] = session

    def delete(self, session_id: str) -> None:
        self._sessions.pop(session_id, None)

    def _evict_expired(self) -> None:
        now = self._clock()
        expired = [sid for sid, s in self._sessions.items() if s.expires_at < now]
        for sid in expired:
            del self._sessions[sid]

    def active_session_count(self) -> int:
        self._evict_expired()
        return len(self._sessions)
