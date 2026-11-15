"""Orchestriert den gefuehrten Erfassungs-Chat fuer den ersten Anwendungsfall
(steuerliche Erfassung einer auslaendischen Gesellschaft in Deutschland).

Designprinzip (Vorgabe Nils Obenhaus, siehe ../../README.md
"Designprinzip: Tatsachen statt Wuerdigung"): der Chat erhebt ausschliesslich
Anknuepfungstatsachen. Das wird technisch an zwei Stellen durchgesetzt:

  1. Generator (siehe `generator/build_llm_schemas.py`): Ergebnis-/Systemfelder
     sind NIE Teil eines Chat-Schemas.
  2. Hier (`ConversationEngine`): bestimmte Tatsachenfelder werden NICHT
     direkt als Frage gestellt, weil die direkte Frage selbst schon die
     gesuchte Wuerdigung vorwegnaehme (z. B. "ist der Ort der Geschaeftsleitung
     abweichend?"). Stattdessen werden sie aus mehreren, wirklich
     tatsachenbezogenen Teilantworten zusammengesetzt (Komposit-Fragen, siehe
     `_COMPOSITE_ONLY_FIELDS` unten und die einzelnen `submit_*`-Methoden).

Die Zweig-Fuehrung (natuerliche Person vs. Gesellschaft) und das
"jede Information nur einmal fragen"-Prinzip sind ebenfalls hier verortet
(Zweig-Auswertung ueber `person_type`/`participant_type`/`party_type`;
ask-once ueber `ChatSession.fact_cache`).
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

from .config import Settings
from .document_upload import UploadResult, store_upload_mock
from .errors import ContentFilterError, LlmUnavailableError
from .field_classification_bridge import Branch
from .llm_client import LLMClient
from .schema_catalog import SchemaCatalog
from .session_store import ChatSession, SessionStore
from .sharepoint_client import SharePointClient
from .validation import (
    LegalFormDecision,
    check_iban_bic_rule,
    check_required_facts_complete,
    check_tax_office_cross_rule,
    evaluate_legal_form_decision,
)

FLOW_CONFIG_PATH = Path(__file__).parent / "flow_config.json"

# Felder, die NIE ueber die generische, schema-gefuehrte Abschnittsfrage
# gestellt werden, sondern ausschliesslich ueber eine dedizierte
# Komposit-Methode (siehe Moduldoc). Sie werden beim Aufbau des generischen
# Abschnitts-Schemas herausgefiltert (`_generic_schema_for_section`).
_COMPOSITE_ONLY_FIELDS: dict[str, set] = {
    "1_Allgemeiner_Stammblock": {"legal_form", "management_address"},
    "2_Unternehmens_Gruendungsmodul": {"legal_form", "deviating_fiscal_year", "fiscal_year_start"},
}

_BRANCH_KEY_FIELD = {
    "1_Allgemeiner_Stammblock": "party_type",
    "3_Personen_und_Vertretung": "person_type",
    "4_Beteiligte_und_Quoten": "participant_type",
}
_BRANCH_VALUE_MAP = {"Firma": Branch.GESELLSCHAFT, "Person": Branch.NATUERLICHE_PERSON}
_PERSON_TYPE_VALUE_MAP = {"natürlich": Branch.NATUERLICHE_PERSON, "nicht natürlich": Branch.GESELLSCHAFT}

SECTIONS_SINGLE = ["1_Allgemeiner_Stammblock", "2_Unternehmens_Gruendungsmodul", "6_Steuer_und_Umsatzsteuerprofil"]
SECTIONS_REPEATABLE = ["3_Personen_und_Vertretung", "4_Beteiligte_und_Quoten", "5_Betriebsstaetten", "8_Unterlagen"]


def _load_flow_config() -> dict:
    return json.loads(FLOW_CONFIG_PATH.read_text(encoding="utf-8"))


@dataclass
class TurnResult:
    assistant_message: str
    unsure_fields: list = field(default_factory=list)


@dataclass
class SubmitOutcome:
    written_lists: list = field(default_factory=list)
    eingang_fehler_count: int = 0
    deferred_sections: list = field(default_factory=list)
    """Abschnitte, die NICHT geschrieben wurden, weil ein amtlich unbedingtes
    Feld ohne sicheren Platzhalterwert offen/unsicher blieb (siehe
    `_submit_section`). Diese Faelle landen vollstaendig in `Eingang_Fehler`,
    damit nichts kommentarlos verloren geht."""


class ConversationError(Exception):
    def __init__(self, reason: str, message: str):
        super().__init__(message)
        self.reason = reason
        self.message = message


class ConversationEngine:
    def __init__(
        self,
        *,
        sharepoint: SharePointClient,
        llm: LLMClient,
        settings: Settings,
        sessions: SessionStore,
        schema_catalog: SchemaCatalog,
        flow_config: Optional[dict] = None,
    ):
        self._sharepoint = sharepoint
        self._llm = llm
        self._settings = settings
        self._sessions = sessions
        self._schemas = schema_catalog
        self._flow = flow_config or _load_flow_config()

    # -- Session-Start -----------------------------------------------------

    def start_session(self, case_id: str) -> ChatSession:
        session = self._sessions.create(case_id)
        session.current_section = SECTIONS_SINGLE[0]
        session.section_data[SECTIONS_SINGLE[0]] = {}
        self._sessions.save(session)
        return session

    # -- Begriffserklaerung --------------------------------------------------

    def explain(self, prompt_key: str) -> str:
        entry = self._flow["prompts"].get(prompt_key, {})
        return entry.get("erklaerung") or "Dazu liegt leider keine zusaetzliche Erklaerung vor."

    def question_text(self, prompt_key: str) -> str:
        entry = self._flow["prompts"].get(prompt_key, {})
        return entry.get("frage", prompt_key)

    # -- Generischer, schema-gefuehrter Abschnitt ---------------------------

    def generic_schema_for_section(
        self, list_name: str, *, branch: Optional[Branch] = None, already_known: Optional[set] = None
    ) -> dict:
        """Baut das fuer den naechsten LLM-Aufruf zu verwendende Schema:
        Komposit-Felder und bereits bekannte (ask-once) Felder werden
        entfernt, damit das Modell sie nicht erneut erfragt."""
        schema_name = list_name
        if branch is not None and list_name in _BRANCH_KEY_FIELD:
            schema_name = f"{list_name}__{branch.value}"
        exclude = set(_COMPOSITE_ONLY_FIELDS.get(list_name, set()))
        exclude |= already_known or set()
        return self._schemas.filtered_schema_envelope(schema_name, exclude_fields=exclude)

    def submit_free_text_answer(
        self, session: ChatSession, list_name: str, record_index: int, user_message: str
    ) -> TurnResult:
        record = self._record(session, list_name, record_index)
        branch = self._resolve_branch(list_name, record)
        already_known = {
            k for k in self._ask_once_fields(list_name) if k in session.fact_cache
        }
        schema_envelope = self.generic_schema_for_section(
            list_name, branch=branch, already_known=already_known
        )
        try:
            result = self._llm.extract(
                schema_envelope=schema_envelope,
                system_prompt=self._system_prompt(list_name),
                history=[],
                user_message=user_message,
            )
        except ContentFilterError as exc:
            return TurnResult(assistant_message=exc.neutral_message)
        except LlmUnavailableError as exc:
            return TurnResult(assistant_message=exc.neutral_message)

        for key, value in result.answers.items():
            record[key] = value
            if key in self._ask_once_fields(list_name) and value is not None:
                session.fact_cache[key] = value
        for key in result.unsure_fields:
            tag = f"{list_name}:{record_index}:{key}"
            if tag not in session.unsure_fields:
                session.unsure_fields.append(tag)

        self._sessions.save(session)
        return TurnResult(assistant_message=result.assistant_message, unsure_fields=result.unsure_fields)

    def _system_prompt(self, list_name: str) -> str:
        return (
            "Du fuehrst einen hoeflichen, verstaendlichen Erfassungs-Chat auf "
            "Deutsch fuer eine Steuerkanzlei. Du erhebst ausschliesslich "
            "Anknuepfungstatsachen, NIE eine steuerliche Wuerdigung. Frage "
            "jede Information nur einmal. Akzeptiere 'weiss ich nicht' als "
            "gueltige Antwort und markiere das betroffene Feld in "
            "unsure_fields, statt es zu erzwingen. Antworte als JSON mit den "
            f"Schluesseln updated_answers (passend zum Schema von {list_name}), "
            "assistant_message (naechste Frage oder Rueckmeldung) und "
            "unsure_fields (Liste von Feldnamen)."
        )

    def _ask_once_fields(self, list_name: str) -> set:
        return set(self._flow.get("ask_once", {}).get(list_name, []))

    def _record(self, session: ChatSession, list_name: str, record_index: int) -> dict:
        records = session.section_data.setdefault(list_name, [] if list_name in SECTIONS_REPEATABLE else {})
        if list_name in SECTIONS_REPEATABLE:
            while len(records) <= record_index:
                records.append({})
            return records[record_index]
        return records

    def _resolve_branch(self, list_name: str, record: dict) -> Optional[Branch]:
        key_field = _BRANCH_KEY_FIELD.get(list_name)
        if not key_field:
            return None
        raw_value = record.get(key_field)
        if raw_value is None:
            return None
        if list_name == "1_Allgemeiner_Stammblock":
            return _BRANCH_VALUE_MAP.get(raw_value)
        return _PERSON_TYPE_VALUE_MAP.get(raw_value)

    # -- Komposit-Frage: Rechtsform zweistufig ------------------------------

    def submit_legal_form(
        self,
        session: ChatSession,
        *,
        grundtyp: str,
        rechtsordnung: str,
        wortlaut: Optional[str] = None,
        staat: Optional[str] = None,
        auslaendische_kategorie: Optional[str] = None,
    ) -> LegalFormDecision:
        """Setzt die zweistufige Rechtsform-Erhebung um (Vorgabe Nils
        Obenhaus): Grundtyp -> deutsches/auslaendisches Recht -> bei
        auslaendischem Recht Wortlaut + Staat. Das Ergebnis wird EINMAL
        komponiert und gleichzeitig fuer `1_Allgemeiner_Stammblock.legal_form`
        UND `2_Unternehmens_Gruendungsmodul.legal_form` im ask-once-Cache
        hinterlegt - die Frage wird dem Mandanten dadurch nur einmal gestellt.
        """
        decision = evaluate_legal_form_decision(
            grundtyp=grundtyp,
            rechtsordnung=rechtsordnung,
            auslaendische_kategorie=auslaendische_kategorie,
        )
        if decision.action == "ablehnen":
            if decision.kanzlei_hinweis:
                self.add_internal_hint(session, decision.kanzlei_hinweis)
            self._sessions.save(session)
            return decision

        if rechtsordnung == "auslaendisch" and wortlaut:
            composed = f"{wortlaut} ({staat})" if staat else wortlaut
        else:
            composed = _GRUNDTYP_DISPLAY.get(grundtyp, grundtyp)

        session.fact_cache["legal_form"] = composed
        if decision.action == "manuelle_pruefung" and decision.kanzlei_hinweis:
            self.add_internal_hint(session, decision.kanzlei_hinweis)

        self._sessions.save(session)
        return decision

    # -- Komposit-Frage: Taetigkeit + Vermoegensverwaltung-Folgefrage ------

    def submit_business_activity(self, session: ChatSession, beschreibung: str) -> bool:
        """Speichert die offene Taetigkeitsbeschreibung. Gibt `True` zurueck,
        wenn eine Vermoegensverwaltungs-Folgefrage noetig ist (Vorgabe Nils
        Obenhaus: NIE direkt 'ausschliesslich vermoegensverwaltend?' fragen,
        sondern bei entsprechendem Hinweis nach Anteil an Umsatz/Gewinn)."""
        record = self._record(session, "1_Allgemeiner_Stammblock", 0)
        record["business_activity"] = beschreibung
        self._sessions.save(session)
        keywords = self._flow.get("vermoegensverwaltung_keywords", [])
        text_lower = beschreibung.lower()
        return any(kw in text_lower for kw in keywords)

    def submit_vermoegensverwaltung_anteile(
        self, session: ChatSession, *, anteil_umsatz: str, anteil_gewinn: str
    ) -> None:
        record = self._record(session, "1_Allgemeiner_Stammblock", 0)
        base = record.get("business_activity") or ""
        record["business_activity"] = (
            f"{base} Anteil Vermoegensverwaltung am Umsatz: {anteil_umsatz}. "
            f"Anteil am Gewinn: {anteil_gewinn}."
        ).strip()
        self._sessions.save(session)

    # -- Komposit-Frage: Wirtschaftsjahr ------------------------------------

    def submit_wirtschaftsjahr(
        self, session: ChatSession, *, entspricht_kalenderjahr: bool, beginn: Optional[str] = None
    ) -> None:
        record = self._record(session, "2_Unternehmens_Gruendungsmodul", 0)
        record["deviating_fiscal_year"] = not entspricht_kalenderjahr
        record["fiscal_year_start"] = None if entspricht_kalenderjahr else beginn
        self._sessions.save(session)

    # -- Komposit-Frage: Geschaeftsleitung / Arbeitsort der Geschaeftsfuehrer

    def submit_geschaeftsfuehrer_arbeitsort(
        self, session: ChatSession, *, person_name: str, arbeitsort: str, andere_orte: Optional[str]
    ) -> None:
        """Nils Obenhaus: NIE direkt nach 'abweichendem Ort der
        Geschaeftsleitung' fragen, sondern bei jedem Geschaeftsfuehrer nach
        dessen ueblichem Arbeitsort und etwaigen weiteren Orten. Die Antworten
        werden ueber alle Geschaeftsfuehrer hinweg in EINEM Textfeld
        (`1_Allgemeiner_Stammblock.management_address`) zusammengefasst."""
        record = self._record(session, "1_Allgemeiner_Stammblock", 0)
        existing = record.get("management_address") or ""
        line = f"{person_name}: arbeitet üblicherweise in {arbeitsort}."
        if andere_orte:
            line += f" Weitere Arbeitsorte: {andere_orte}."
        record["management_address"] = (existing + " " + line).strip() if existing else line
        self._sessions.save(session)

    # -- Dokument-Upload ------------------------------------------------------

    def handle_upload(
        self,
        session: ChatSession,
        *,
        filename: str,
        content_type: str,
        data: bytes,
        document_type: str,
        note: Optional[str] = None,
    ) -> UploadResult:
        result = store_upload_mock(
            filename=filename,
            content_type=content_type,
            data=data,
            document_type=document_type,
            settings=self._settings,
        )
        records = session.section_data.setdefault("8_Unterlagen", [])
        records.append(
            {
                "document_type": document_type,
                "note": note,
                "uploaded": True,
                "required": False,
                "file_link": result.file_link,
            }
        )
        self._sessions.save(session)
        return result

    # -- Interne Hinweise (NIE als Mandantenangabe) -------------------------

    def add_internal_hint(self, session: ChatSession, text: str) -> None:
        """Vorgabe Nils Obenhaus: ein Chat-Vorschlag darf als intern
        markierter Hinweis abgelegt werden, NIE als Mandantenangabe. Landet
        beim Abschluss angehaengt an `0_Fallsteuerung.processing_note`
        (bestehendes, ausdruecklich kanzleiinternes Freitextfeld), klar
        praefixiert und von den eigentlichen Mandantenantworten getrennt."""
        session.internal_hints.append(f"[Chat-Vorschlag, nicht verifiziert] {text}")
        self._sessions.save(session)

    # -- Zusammenfassung / Bestaetigung / Abschluss -------------------------

    def build_summary(self, session: ChatSession) -> dict:
        return {
            "case_id": session.case_id,
            "sections": {k: v for k, v in session.section_data.items()},
            "unsure_fields": list(session.unsure_fields),
            "internal_hints": list(session.internal_hints),
        }

    def confirm(self, session: ChatSession) -> None:
        session.confirmed = True
        self._sessions.save(session)

    def submit(self, session: ChatSession) -> SubmitOutcome:
        if not session.confirmed:
            raise ConversationError(
                "not_confirmed",
                "Bitte bestaetigen Sie zuerst die Zusammenfassung, bevor die Angaben gespeichert werden.",
            )
        if session.submitted:
            raise ConversationError("already_submitted", "Dieser Fall wurde bereits uebermittelt.")

        outcome = SubmitOutcome()
        unsure_by_list: dict[str, set] = {}
        for tag in session.unsure_fields:
            list_name, _, field_name = tag.split(":", 2)
            unsure_by_list.setdefault(list_name, set()).add(field_name)

        for list_name in SECTIONS_SINGLE:
            record = session.section_data.get(list_name) or {}
            if not record:
                continue
            self._submit_section(session, list_name, record, unsure_by_list.get(list_name, set()), outcome)

        for list_name in SECTIONS_REPEATABLE:
            for record in session.section_data.get(list_name, []):
                self._submit_section(session, list_name, record, set(), outcome)

        self._run_validation_rules(session, outcome)
        self._write_internal_hints(session)

        session.submitted = True
        self._sessions.delete(session.session_id)
        return outcome

    def _submit_section(
        self, session: ChatSession, list_name: str, record: dict, unsure: set, outcome: SubmitOutcome
    ) -> None:
        schema_name = list_name
        field_meta = self._schemas.field_meta(schema_name)
        missing = check_required_facts_complete(field_meta=field_meta, answers=record, unsure_fields=unsure)
        if missing:
            self._log_eingang_fehler(
                session,
                form_no=_FORM_NO.get(list_name, -1),
                reason=f"Amtlich unbedingte Felder fehlen: {', '.join(missing)}",
                payload=record,
            )
            outcome.deferred_sections.append(list_name)
            outcome.eingang_fehler_count += 1
            return

        fields = dict(record)
        fields["case_id"] = session.case_id
        if "legal_form" in self._ask_once_fields(list_name) or (
            list_name in _COMPOSITE_ONLY_FIELDS and "legal_form" in _COMPOSITE_ONLY_FIELDS[list_name]
        ):
            if "legal_form" in session.fact_cache:
                fields["legal_form"] = session.fact_cache["legal_form"]
        self._sharepoint.create_item(list_name, fields)
        outcome.written_lists.append(list_name)

    def _run_validation_rules(self, session: ChatSession, outcome: SubmitOutcome) -> None:
        list1 = session.section_data.get("1_Allgemeiner_Stammblock") or {}
        finding = check_iban_bic_rule(list1)
        if finding:
            self._log_eingang_fehler(session, form_no=1, reason=finding.message, payload=list1)
            outcome.eingang_fehler_count += 1

        list0 = self._sharepoint.get_item("0_Fallsteuerung", "case_id", session.case_id) or {}
        finding = check_tax_office_cross_rule(list0_snapshot=list0, list1_answers=list1)
        if finding:
            self._log_eingang_fehler(session, form_no=1, reason=finding.message, payload=list1)
            outcome.eingang_fehler_count += 1

    def _log_eingang_fehler(self, session: ChatSession, *, form_no: int, reason: str, payload: dict) -> None:
        self._sharepoint.create_item(
            "Eingang_Fehler",
            {
                "form_no": form_no,
                "case_id_raw": session.case_id,
                "reason": reason,
                "payload": json.dumps(payload, ensure_ascii=False),
                "status": "offen",
            },
        )

    def _write_internal_hints(self, session: ChatSession) -> None:
        if not session.internal_hints:
            return
        existing = self._sharepoint.get_item("0_Fallsteuerung", "case_id", session.case_id)
        if existing is None:
            return
        current_note = existing.get("processing_note") or ""
        appended = "\n".join(session.internal_hints)
        new_note = f"{current_note}\n{appended}".strip() if current_note else appended
        self._sharepoint.update_item("0_Fallsteuerung", existing["Id"], {"processing_note": new_note})


_GRUNDTYP_DISPLAY = {
    "einzelunternehmen": "Einzelunternehmen",
    "freiberufler": "Freiberufliche Taetigkeit",
    "personengesellschaft": "Personengesellschaft",
    "kapitalgesellschaft": "Kapitalgesellschaft",
}

_FORM_NO = {
    "1_Allgemeiner_Stammblock": 1,
    "2_Unternehmens_Gruendungsmodul": 2,
    "3_Personen_und_Vertretung": 3,
    "4_Beteiligte_und_Quoten": 4,
    "5_Betriebsstaetten": 5,
    "6_Steuer_und_Umsatzsteuerprofil": 6,
    "8_Unterlagen": 8,
}
