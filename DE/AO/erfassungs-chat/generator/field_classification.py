"""Klassifiziert Felder aus dem Feldkatalog in Tatsache / Ergebnis / System
und ordnet sie optional einem Zweig zu (natuerliche Person / Gesellschaft).

Hintergrund (Vorgabe Nils Obenhaus, siehe ../README.md Abschnitt
"Designprinzip: Tatsachen statt Wuerdigung"):

    Der Chat erhebt Tatsachen, keine rechtlichen Ergebnisse. Er fragt nie
    nach einer steuerlichen Wuerdigung (z. B. zustaendiges Finanzamt,
    Soll-/Ist-Versteuerung, Kleinunternehmerregelung, BZSt-Zielmeldung,
    Organschaft, Betriebsstaette ja/nein), sondern nach den
    Anknuepfungstatsachen, aus denen die Kanzlei das beurteilt.

Ein paralleler PR baut dafuer die eigentliche Grundlage direkt ins
Datenmodell/PnP-Skript ein: eine Grundregel, eine Ableitungstabelle
Ergebnisfeld -> Tatsachenfelder und ein `applies_to`-Metadatum je Feld.
Dieses Modul ist deshalb bewusst zweistufig aufgebaut:

1. `MetadataClassificationProvider` liest diese Metadaten, SOBALD sie im
   Katalog vorhanden sind (siehe `FieldDef`-Erweiterung weiter unten im
   Kommentar "Erwartetes Metadaten-Format"). Heute liefert er fuer jedes
   Feld `None` zurueck, weil die Metadaten noch nicht existieren.
2. `ConfigClassificationProvider` ist der Uebergangszustand: eine von Hand
   gepflegte, versionierte Ausschluss- und Zweigtabelle in
   `classification_config.json`. Sie deckt nur die fuer den ersten
   Anwendungsfall (auslaendische Gesellschaft, Formulare 1/3/4/5/6/8)
   benoetigten Listen ab.

`CompositeClassificationProvider` fragt zuerst die Metadaten, dann die
Konfiguration und wirft, wenn keine der beiden eine Klassifizierung kennt
(so dass neue Felder nach einem Merge nicht versehentlich ungeprueft als
Tatsache durchgereicht werden, siehe Test `test_unclassified_field_raises`).

Erwartetes Metadaten-Format (sobald der parallele PR es liefert):
    Die Annahme ist, dass `Add-Field`-Aufrufe im PnP-Skript um zwei weitere,
    optionale Parameter erweitert werden, die dieser Generator dann direkt
    aus dem AST/Catalog lesen kann, z. B.:

        -FieldRole "Ergebnis"            # oder "Tatsache" (Default, wenn Parameter fehlt)
        -AppliesTo @("Gesellschaft")     # oder @("NatuerlichePerson"), fehlt = beide

    Da das genaue Format erst mit dem parallelen PR feststeht, ist
    `MetadataClassificationProvider` absichtlich ein duenner Adapter: er
    erwartet diese zwei Attribute optional auf `FieldDef` (ueber `getattr`,
    nicht ueber eine feste Dataclass-Erweiterung, damit der Parser in
    `pnp_schema_parser.py` nicht vorab wissen muss, wie das echte Metadatum
    am Ende heisst). Sobald der parallele PR gemerged ist, muss hier nur
    `_read_metadata_role`/`_read_metadata_applies_to` an das tatsaechliche
    Attribut/die tatsaechliche Spalte angepasst werden - der Rest des
    Generators (Schema-Bau, Tests) bleibt unveraendert, weil er ausschliesslich
    gegen `ClassificationProvider.classify()` programmiert ist, nie gegen die
    Konfigdatei direkt.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Optional, Protocol

from .pnp_schema_parser import FieldDef


class FieldRole(str, Enum):
    """Rolle eines Feldes aus Sicht der Chat-Fragefuehrung."""

    TATSACHE = "tatsache"
    """Anknuepfungstatsache: darf der Chat erfragen."""

    ERGEBNIS = "ergebnis"
    """Rechtliche/steuerliche Wuerdigung oder Prognose der Kanzlei: der Chat
    fragt dieses Feld NIE ab. Es bleibt fuer die Kanzlei leer."""

    SYSTEM = "system"
    """Kein fachlicher Chat-Inhalt - aus zwei moeglichen Gruenden:
    (a) technisches/internes Feld (Lookup-Anzeigefeld, Flow-Flag, Title o.ae.)
        oder
    (b) Kontaktdaten (E-Mail, Telefon, Ansprechpartner), die laut Nils
        Obenhaus im CRM der Kanzlei gepflegt werden und deshalb nicht im
        Chat erhoben werden - siehe `note` am jeweiligen Konfigeintrag fuer
        den konkreten Grund."""


class Branch(str, Enum):
    """Zweig der Fragefuehrung, abhaengig von der Art des Meldepflichtigen
    bzw. der jeweils betroffenen Person/Gesellschaft innerhalb eines
    wiederholbaren Objekts (z. B. Vertreter, Beteiligter)."""

    ALLE = "alle"
    NATUERLICHE_PERSON = "natuerliche_person"
    GESELLSCHAFT = "gesellschaft"


@dataclass(frozen=True)
class FieldClassification:
    role: FieldRole
    applies_to: Branch = Branch.ALLE
    note: Optional[str] = None
    source: str = "config"
    """Woher die Klassifizierung stammt: "metadata" (aus dem PnP-Skript/
    Datenmodell, sobald vorhanden) oder "config" (Uebergangstabelle)."""

    def to_dict(self) -> dict:
        return {
            "role": self.role.value,
            "applies_to": self.applies_to.value,
            "note": self.note,
            "source": self.source,
        }


class ClassificationProvider(Protocol):
    def classify(self, field: FieldDef) -> Optional[FieldClassification]:
        """Liefert die Klassifizierung oder `None`, wenn dieser Provider das
        Feld nicht kennt (dann fragt der naechste Provider in der Kette)."""
        ...


class MetadataClassificationProvider:
    """Liest `FieldRole`/`applies_to` direkt aus dem Katalogeintrag, falls der
    parallele PR (Datenmodell/PnP-Skript) diese Attribute bereits liefert.

    Siehe Moduldoc oben fuer das erwartete (vorlaeufige) Attributformat.
    Solange diese Attribute nicht existieren, liefert dieser Provider fuer
    jedes Feld `None` und die Kette faellt auf `ConfigClassificationProvider`
    zurueck - das ist der gewuenschte Zustand "nutzt die Metadaten, sobald
    sie da sind", ohne dass heute irgendetwas rekonstruiert werden muss.
    """

    _ROLE_ATTR_CANDIDATES = ("field_role", "FieldRole", "ergebnis_oder_tatsache")
    _APPLIES_TO_ATTR_CANDIDATES = ("applies_to", "AppliesTo")

    _ROLE_VALUE_MAP = {
        "ergebnis": FieldRole.ERGEBNIS,
        "tatsache": FieldRole.TATSACHE,
        "system": FieldRole.SYSTEM,
    }
    _BRANCH_VALUE_MAP = {
        "gesellschaft": Branch.GESELLSCHAFT,
        "natuerlichepersoN".lower(): Branch.NATUERLICHE_PERSON,
        "natuerliche_person": Branch.NATUERLICHE_PERSON,
        "alle": Branch.ALLE,
    }

    def classify(self, field: FieldDef) -> Optional[FieldClassification]:
        raw_role = self._read_first(field, self._ROLE_ATTR_CANDIDATES)
        if raw_role is None:
            return None
        role = self._ROLE_VALUE_MAP.get(str(raw_role).strip().lower())
        if role is None:
            return None

        raw_applies_to = self._read_first(field, self._APPLIES_TO_ATTR_CANDIDATES)
        branch = Branch.ALLE
        if raw_applies_to:
            values = (
                raw_applies_to
                if isinstance(raw_applies_to, (list, tuple, set))
                else [raw_applies_to]
            )
            mapped = {
                self._BRANCH_VALUE_MAP.get(str(v).strip().lower())
                for v in values
            }
            mapped.discard(None)
            if len(mapped) == 1:
                branch = next(iter(mapped))
            elif len(mapped) > 1:
                branch = Branch.ALLE

        return FieldClassification(role=role, applies_to=branch, source="metadata")

    @staticmethod
    def _read_first(field: FieldDef, names: tuple[str, ...]):
        for name in names:
            value = getattr(field, name, None)
            if value is not None:
                return value
        return None


class ConfigClassificationProvider:
    """Uebergangsloesung: von Hand gepflegte Ausschluss-/Zweigtabelle.

    Format der JSON-Konfiguration (`classification_config.json`):

        {
          "<Listenname>": {
            "<InternalName>": {
              "role": "tatsache" | "ergebnis" | "system",
              "applies_to": "alle" | "natuerliche_person" | "gesellschaft",
              "note": "kurze Begruendung, erscheint im Transparenzbericht"
            }
          }
        }

    Nicht gelistete Felder liefern `None` (nicht klassifiziert) - siehe
    `CompositeClassificationProvider` fuer das resultierende "Fail-Closed"-
    Verhalten.
    """

    def __init__(self, config: dict):
        self._config = config

    @classmethod
    def from_file(cls, path: str | Path) -> "ConfigClassificationProvider":
        data = json.loads(Path(path).read_text(encoding="utf-8"))
        return cls(data)

    def classify(self, field: FieldDef) -> Optional[FieldClassification]:
        list_cfg = self._config.get(field.list_name)
        if not list_cfg:
            return None
        entry = list_cfg.get(field.internal_name)
        if not entry:
            return None
        role = FieldRole(entry["role"])
        branch = Branch(entry.get("applies_to", "alle"))
        note = entry.get("note")
        return FieldClassification(role=role, applies_to=branch, note=note, source="config")


class UnclassifiedFieldError(ValueError):
    """Ein Feld aus dem Katalog ist weder per Metadatum noch per
    Konfigurationstabelle klassifiziert. Das Generator-Build bricht bewusst
    ab (Fail-Closed), statt ein neues Feld unklassifiziert als Tatsache an
    den Chat durchzureichen - siehe README "Designprinzip"."""


class CompositeClassificationProvider:
    """Fragt mehrere Provider in Reihenfolge; wirft, wenn keiner zustaendig
    ist. Das garantiert, dass ein nach einem Merge neu hinzugekommenes Feld
    NICHT automatisch als Tatsache in den Chat uebernommen wird, sondern den
    Generator-Lauf sichtbar scheitern laesst, bis es in der Konfiguration
    (oder spaeter: im Datenmodell-Metadatum) eingetragen wurde.
    """

    def __init__(self, providers: list[ClassificationProvider]):
        self._providers = providers

    def classify(self, field: FieldDef) -> FieldClassification:
        for provider in self._providers:
            result = provider.classify(field)
            if result is not None:
                return result
        raise UnclassifiedFieldError(
            f"Kein Classification-Provider kennt {field.list_name}/{field.internal_name}. "
            "Feld in classification_config.json eintragen (role=tatsache/ergebnis/system) "
            "oder - sobald verfuegbar - im Datenmodell/PnP-Skript als Metadatum pflegen."
        )


def default_provider(config_path: Optional[str | Path] = None) -> CompositeClassificationProvider:
    if config_path is None:
        config_path = Path(__file__).parent / "classification_config.json"
    return CompositeClassificationProvider(
        [
            MetadataClassificationProvider(),
            ConfigClassificationProvider.from_file(config_path),
        ]
    )
