"""Maschinell pruefbare Validierungsregeln.

1. `evaluate_legal_form_decision`: setzt die Kanzleientscheide durch
   (Vereine/Stiftungen/jPoeR ausgeschlossen; auslaendische PersG/LLP/LLC in
   die manuelle Pruefung, Fall wird markiert statt abgelehnt) - angewandt
   waehrend der zweistufigen Rechtsform-Frage (siehe conversation.py).
2. `check_iban_bic_rule` / `check_tax_office_cross_rule`: die zwei Pruefregeln
   aus `sharepoint-forms/README.md` Abschnitt E.10, die Forms-Branching nicht
   abbilden kann (siehe Datenmodell Abschnitt 9.6 Fussnote).
3. `check_required_facts_complete`: generische Pflichtfeld-Vollstaendigkeits-
   pruefung auf Basis der generierten `field_meta` (Pflicht = `required_unbedingt`
   im Katalog) - NICHT gegen Ergebnisfelder (die sind per Generator nie im
   Schema und folglich nie Teil dieser Pruefung).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional

# IBAN-Laenderpraefixe, bei denen laut Datenmodell Abschnitt 9.6 eine BIC
# zusaetzlich zur IBAN verlangt wird (Nicht-SEPA-Sonderfaelle).
_BIC_REQUIRED_IBAN_PREFIXES = ("AL", "MD", "MC", "ME", "MK", "SM", "CH")


@dataclass
class ValidationFinding:
    rule: str
    severity: str  # "eingang_fehler" (-> Eingang_Fehler-Liste) oder "hinweis"
    message: str
    fields: list = field(default_factory=list)


def check_iban_bic_rule(list1_answers: dict) -> Optional[ValidationFinding]:
    """E.10 Regel 2: BIC nur bei bestimmten Nicht-SEPA-IBAN-Laendern Pflicht."""
    iban = (list1_answers.get("bank_iban") or "").strip().upper()
    bic = (list1_answers.get("bank_bic") or "").strip()
    if not iban:
        return None
    if iban[:2] in _BIC_REQUIRED_IBAN_PREFIXES and not bic:
        return ValidationFinding(
            rule="E.10.2_bic_bei_nicht_sepa_iban",
            severity="eingang_fehler",
            message="BIC fehlt bei nicht-SEPA-IBAN (Laenderpraefix erfordert BIC).",
            fields=["bank_iban", "bank_bic"],
        )
    return None


def check_tax_office_cross_rule(*, list0_snapshot: dict, list1_answers: dict) -> Optional[ValidationFinding]:
    """E.10 Regel 1: wenn der Mandant der Zustaendigkeitsvereinbarung nach
    Paragraf 27 AO zustimmt UND der Fall laut 0_Fallsteuerung bereits
    anderswo erfasst ist, muessen `existing_tax_number`/`tax_office_country`
    in 0_Fallsteuerung gesetzt sein. Diese beiden Felder liegen auf
    0_Fallsteuerung (Kanzlei-intern) - der Chat fragt sie nicht selbst,
    prueft aber die Konsistenz und meldet eine Luecke an die Kanzlei
    (Eingang_Fehler), statt den Fall unvollstaendig durchlaufen zu lassen.
    """
    par27 = list1_answers.get("par27_ao_agreement")
    already_registered = list0_snapshot.get("already_registered")
    if par27 is True and already_registered is True:
        existing_tax_number = (list0_snapshot.get("existing_tax_number") or "").strip()
        tax_office_country = (list0_snapshot.get("tax_office_country") or "").strip()
        if not existing_tax_number or not tax_office_country:
            return ValidationFinding(
                rule="E.10.1_steuernummer_land_bei_par27",
                severity="eingang_fehler",
                message=(
                    "Zustimmung zu Paragraf 27 AO und bereits andernorts erfasst, "
                    "aber bestehende Steuernummer/Land des Finanzamts fehlen in "
                    "0_Fallsteuerung - bitte durch die Kanzlei ergaenzen."
                ),
                fields=["existing_tax_number", "tax_office_country"],
            )
    return None


def check_required_facts_complete(
    *, field_meta: list[dict], answers: dict, unsure_fields: set
) -> list[str]:
    """Liefert die internen Namen amtlich unbedingter Felder, die weder
    beantwortet noch explizit als 'weiss ich nicht' markiert sind - also
    schlicht noch nicht gefragt wurden. Vom Aufrufer genutzt, um zu
    entscheiden, ob ein Abschnitt fuer die Zusammenfassung bereit ist."""
    missing = []
    for meta in field_meta:
        if not meta.get("required_unbedingt"):
            continue
        name = meta["internal_name"]
        if name in unsure_fields:
            continue
        if answers.get(name) in (None, ""):
            missing.append(name)
    return missing


# --- Kanzleientscheide (Rechtsform-Routing) --------------------------------

EXCLUDED_GRUNDTYPEN = {"verein_stiftung_jpoer"}
MANUAL_REVIEW_FOREIGN_FORMS = {"personengesellschaftsartig_llp_llc"}


@dataclass
class LegalFormDecision:
    action: str  # "weiter" | "manuelle_pruefung" | "ablehnen"
    mandant_message: str
    kanzlei_hinweis: Optional[str] = None


def evaluate_legal_form_decision(
    *,
    grundtyp: str,
    rechtsordnung: str,
    auslaendische_kategorie: Optional[str] = None,
) -> LegalFormDecision:
    """Setzt die Kanzleientscheide waehrend der zweistufigen Rechtsform-Frage
    (siehe conversation.py flow_config.legal_form_zweistufig) durch.

    `grundtyp`: "einzelunternehmen" | "freiberufler" | "personengesellschaft"
                | "kapitalgesellschaft" | "verein_stiftung_jpoer"
    `rechtsordnung`: "deutsch" | "auslaendisch"
    `auslaendische_kategorie` (nur bei rechtsordnung == "auslaendisch", grobe
        Einordnung z. B. aus dem Wortlaut der Rechtsform abgeleitet):
        "kapitalgesellschaftsartig" | "personengesellschaftsartig_llp_llc"
        | None (unbestimmt -> wie kapitalgesellschaftsartig behandelt, die
        Kanzlei kann das spaeter korrigieren)
    """
    if grundtyp in EXCLUDED_GRUNDTYPEN:
        return LegalFormDecision(
            action="ablehnen",
            mandant_message=(
                "Fuer Vereine, Stiftungen und juristische Personen des "
                "oeffentlichen Rechts bietet dieser Chat aktuell keine "
                "Erfassung an. Bitte wenden Sie sich direkt an die Kanzlei."
            ),
            kanzlei_hinweis=(
                "Mandant hat im Chat einen Verein/eine Stiftung/eine jPoeR "
                "angegeben - laut Kanzleientscheid 26.10.2026 bewusst "
                "ausgeschlossen, Fall wurde nicht weiter erfasst."
            ),
        )

    if (
        rechtsordnung == "auslaendisch"
        and (auslaendische_kategorie or "") in MANUAL_REVIEW_FOREIGN_FORMS
    ):
        return LegalFormDecision(
            action="manuelle_pruefung",
            mandant_message=(
                "Vielen Dank. Ihre Angaben werden erfasst; da es sich um eine "
                "Personengesellschaft/LLP/LLC nach auslaendischem Recht "
                "handelt, prueft die Kanzlei die steuerliche Einordnung "
                "zusaetzlich manuell."
            ),
            kanzlei_hinweis=(
                "Auslaendische Partnership/LLP/LLC - Rechtstypenvergleich "
                "laut Kanzleientscheid 26.10.2026 manuell durch die Kanzlei "
                "vorzunehmen, Fall NICHT abgelehnt, nur markiert."
            ),
        )

    return LegalFormDecision(action="weiter", mandant_message="")
