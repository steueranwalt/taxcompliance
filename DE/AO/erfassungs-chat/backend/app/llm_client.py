"""LLM-Anbindung: Azure OpenAI (accompli-azureai, Managed Identity, Structured
Outputs) mit einem deterministischen Mock fuer lokale Tests/Demo ohne Azure.

Sicherheitsregeln aus der Zielarchitektur, hier durchgesetzt:
  - `store=false` bei jedem Chat-Completions-Aufruf.
  - Es werden NIE Chat-Inhalte geloggt, nur Metadaten (Listenname,
    Dauer, Status) - siehe `logging.getLogger(__name__)`-Aufrufe unten.
  - `content_filter`-Fehler werden abgefangen und als `ContentFilterError`
    mit neutraler Mandantenmeldung weitergegeben (siehe errors.py).
  - API-Version >= 2024-08-01-preview, `response_format.json_schema.strict`.
  - Keine API-Keys: Token ueber `DefaultAzureCredential`
    (`https://cognitiveservices.azure.com/.default`).
"""

from __future__ import annotations

import json
import logging
import re
import time
from dataclasses import dataclass, field
from typing import Optional, Protocol

from .errors import ContentFilterError, LlmUnavailableError

logger = logging.getLogger("erfassungschat.llm")


@dataclass
class ExtractionResult:
    answers: dict
    """Nur Schluessel, die im uebergebenen Schema stehen. Werte entsprechen
    dem Schema (also ggf. `None` fuer 'nicht bekannt')."""

    assistant_message: str
    """Naechste Frage bzw. Rueckmeldung an den Mandanten, in einfacher,
    verstaendlicher Sprache."""

    unsure_fields: list = field(default_factory=list)
    """Felder, bei denen der Mandant explizit 'weiss ich nicht' o.ae. gesagt
    hat (vs. Felder, die schlicht noch nicht gefragt wurden)."""


class LLMClient(Protocol):
    def extract(
        self,
        *,
        schema_envelope: dict,
        system_prompt: str,
        history: list[dict],
        user_message: str,
    ) -> ExtractionResult:
        ...


# Phrasen, die der Mandant typischerweise benutzt, um Unwissen auszudruecken
# - siehe README "akzeptiert 'weiss ich nicht'". Nur fuer den Mock relevant;
# die echte Azure-OpenAI-Variante erkennt das ueber das LLM selbst (Prompt
# weist das Modell explizit an, solche Aussagen als unsure_fields statt als
# Fehler zu behandeln).
_UNSURE_PATTERNS = [
    r"wei(ss|ß)\b[^.?!]*\bnicht\b",
    r"keine ahnung",
    r"unbekannt",
    r"kann ich nicht sagen",
    r"\bk\.?\s*a\.?\b",
]
_UNSURE_RE = re.compile("|".join(_UNSURE_PATTERNS), re.IGNORECASE)

_YES_RE = re.compile(r"^\s*(ja|yes|j)\b", re.IGNORECASE)
_NO_RE = re.compile(r"^\s*(nein|no|n)\b", re.IGNORECASE)


class MockLLMClient:
    """Deterministischer Ersatz fuer Azure OpenAI, fuer Tests/Demo ohne
    Azure-Zugang (siehe README "Lokal testbar machen").

    Zwei Eingabeformen werden unterstuetzt:

    1. `user_message` ist ein JSON-Objekt (z. B. `'{"company_name": "Acme"}'`):
       wird direkt als Antwortpatch uebernommen (fuer deterministische
       Orchestrierungs-Tests, die NICHT die NLU selbst testen wollen).
    2. `user_message` ist Freitext: einfache Heuristik fuer die aktuell
       offene(n) Frage(n) - erkennt "weiss ich nicht"-Phrasen sowie Ja/Nein
       fuer Boolean-Felder. Nur fuer die Demo-Szenarien gedacht, ersetzt
       keine echte Spracherkennung.
    """

    def extract(
        self,
        *,
        schema_envelope: dict,
        system_prompt: str,
        history: list[dict],
        user_message: str,
    ) -> ExtractionResult:
        properties = schema_envelope["json_schema"]["schema"]["properties"]
        answers: dict = {}
        unsure: list[str] = []

        parsed_json = self._try_parse_json(user_message)
        if parsed_json is not None:
            for key, value in parsed_json.items():
                if key in properties:
                    answers[key] = value
                    if value is None:
                        unsure.append(key)
            return ExtractionResult(
                answers=answers,
                assistant_message="Danke, das habe ich notiert.",
                unsure_fields=unsure,
            )

        open_fields = [k for k in properties.keys()]
        target_field = open_fields[0] if open_fields else None

        if _UNSURE_RE.search(user_message):
            if target_field:
                answers[target_field] = None
                unsure.append(target_field)
            return ExtractionResult(
                answers=answers,
                assistant_message=(
                    "Kein Problem, das tragen wir als offen ein - die Kanzlei "
                    "meldet sich dazu bei Ihnen."
                ),
                unsure_fields=unsure,
            )

        if target_field and properties[target_field].get("type") == ["boolean", "null"]:
            if _YES_RE.match(user_message):
                answers[target_field] = True
            elif _NO_RE.match(user_message):
                answers[target_field] = False

        if target_field and target_field not in answers:
            answers[target_field] = user_message.strip() or None

        return ExtractionResult(
            answers=answers, assistant_message="Danke, das habe ich notiert.", unsure_fields=unsure
        )

    @staticmethod
    def _try_parse_json(text: str) -> Optional[dict]:
        stripped = text.strip()
        if not stripped.startswith("{"):
            return None
        try:
            parsed = json.loads(stripped)
        except (json.JSONDecodeError, ValueError):
            return None
        return parsed if isinstance(parsed, dict) else None


class AzureOpenAIClient:
    """Echte Azure-OpenAI-Anbindung ueber Managed Identity. NICHT in dieser
    Session gegen die echte Ressource getestet (siehe README "Rahmen").

    Lazy Import von `openai`/`azure-identity`, damit Mock-Betrieb und Tests
    ohne diese Pakete laufen (siehe backend/requirements.txt).
    """

    def __init__(
        self,
        *,
        endpoint: str,
        deployment: str,
        api_version: str,
        managed_identity_client_id: str = "",
    ):
        self._endpoint = endpoint
        self._deployment = deployment
        self._api_version = api_version
        self._managed_identity_client_id = managed_identity_client_id
        self._client = None

    def _ensure_client(self):
        if self._client is not None:
            return
        try:
            from azure.identity import (  # type: ignore
                DefaultAzureCredential,
                get_bearer_token_provider,
            )
            from openai import AzureOpenAI  # type: ignore
        except ImportError as exc:  # pragma: no cover - nur ohne Azure-Pakete
            raise LlmUnavailableError(
                "openai/azure-identity nicht installiert - siehe backend/requirements.txt. "
                "Fuer lokale Tests ERFASSUNGSCHAT_MOCK_LLM=true setzen."
            ) from exc

        cred_kwargs = {}
        if self._managed_identity_client_id:
            cred_kwargs["managed_identity_client_id"] = self._managed_identity_client_id
        credential = DefaultAzureCredential(**cred_kwargs)
        token_provider = get_bearer_token_provider(
            credential, "https://cognitiveservices.azure.com/.default"
        )
        self._client = AzureOpenAI(
            azure_endpoint=self._endpoint,
            azure_ad_token_provider=token_provider,
            api_version=self._api_version,
        )

    def extract(
        self,
        *,
        schema_envelope: dict,
        system_prompt: str,
        history: list[dict],
        user_message: str,
    ) -> ExtractionResult:
        self._ensure_client()
        messages = (
            [{"role": "system", "content": system_prompt}]
            + history
            + [{"role": "user", "content": user_message}]
        )

        started = time.monotonic()
        schema_name = schema_envelope["json_schema"]["name"]
        try:
            completion = self._client.chat.completions.create(
                model=self._deployment,
                messages=messages,
                response_format=schema_envelope,
                store=False,
            )
        except Exception as exc:  # pragma: no cover - echter Azure-Fehlerpfad
            if self._is_content_filter_error(exc):
                logger.warning(
                    "content_filter_blockiert schema=%s dauer_ms=%d",
                    schema_name,
                    int((time.monotonic() - started) * 1000),
                )
                raise ContentFilterError(category="request") from exc
            logger.error(
                "llm_aufruf_fehlgeschlagen schema=%s dauer_ms=%d typ=%s",
                schema_name,
                int((time.monotonic() - started) * 1000),
                type(exc).__name__,
            )
            raise LlmUnavailableError(str(type(exc).__name__)) from exc

        choice = completion.choices[0]
        if choice.finish_reason == "content_filter":
            logger.warning(
                "content_filter_blockiert schema=%s dauer_ms=%d",
                schema_name,
                int((time.monotonic() - started) * 1000),
            )
            raise ContentFilterError(category="response")

        logger.info(
            "llm_aufruf_ok schema=%s dauer_ms=%d",
            schema_name,
            int((time.monotonic() - started) * 1000),
        )

        payload = json.loads(choice.message.content)
        answers = payload.get("updated_answers", payload)
        assistant_message = payload.get("assistant_message", "")
        unsure_fields = payload.get("unsure_fields", [])
        return ExtractionResult(
            answers=answers, assistant_message=assistant_message, unsure_fields=unsure_fields
        )

    @staticmethod
    def _is_content_filter_error(exc: Exception) -> bool:
        body = getattr(exc, "body", None) or {}
        code = ""
        if isinstance(body, dict):
            code = str(body.get("error", {}).get("code", ""))
        return "content_filter" in code or "content_filter" in str(exc).lower()
