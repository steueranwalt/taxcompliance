"""Fehlerklassen, die eine neutrale, mandantengeeignete Meldung tragen und
NIE Rohinhalte (Prompt/Antwort) in die Exception-Message packen - diese
Exceptions landen in App-Insights-Traces, und dort duerfen laut
Zielarchitektur ausschliesslich Metadaten stehen, keine Chat-Inhalte."""

from __future__ import annotations


class ContentFilterError(RuntimeError):
    """Azure OpenAI hat die Anfrage oder Antwort wegen eines
    Content-Filter-Treffers abgelehnt (`finish_reason == "content_filter"`
    bzw. HTTP 400 mit `error.code == "content_filter"`).

    Der Mandant bekommt ausschliesslich `neutral_message`, niemals den
    Rohfehler von Azure OpenAI (der ggf. den anstoessigen Ausschnitt zitiert).
    """

    neutral_message = (
        "Diese Eingabe konnte nicht automatisch verarbeitet werden. "
        "Bitte formulieren Sie Ihre Antwort anders oder wenden Sie sich an "
        "die Kanzlei, falls das Problem bestehen bleibt."
    )

    def __init__(self, *, category: str = "unknown"):
        super().__init__(f"content_filter:{category}")
        self.category = category


class LlmUnavailableError(RuntimeError):
    neutral_message = (
        "Der Chat ist derzeit technisch nicht erreichbar. Bitte versuchen "
        "Sie es in ein paar Minuten erneut."
    )
