"""Baut aus dem Feldkatalog (siehe `pnp_schema_parser.py`) und der
Feldklassifizierung (siehe `field_classification.py`) je Liste ein JSON-Schema
fuer Azure-OpenAI-Structured-Outputs (`response_format: json_schema`,
`strict: true`).

Regeln aus der Zielarchitektur (siehe ../README.md):

  - Hoechstens 100 Properties pro Schema.
  - Hoechstens 5 Verschachtelungsebenen.
  - Alle Felder sind `required`; Nullbarkeit wird ueber eine Union mit `null`
    abgebildet (`strict` Structured Outputs verlangt, dass jedes in
    `properties` gelistete Feld auch in `required` steht).
  - Kein `pattern`, kein `format`.
  - Ein Schema pro Liste/Abschnitt (nie ein Monolith ueber alle 217 Felder).

Ergebnisfelder (siehe `field_classification.FieldRole.ERGEBNIS`) und
Systemfelder (`FieldRole.SYSTEM`) werden NIE in ein Chat-Schema aufgenommen -
das ist technisch die Durchsetzung des Designprinzips "Tatsachen statt
Wuerdigung" (siehe README).
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from .field_classification import Branch, ClassificationProvider, FieldRole
from .pnp_schema_parser import Catalog, FieldDef

MAX_PROPERTIES = 100
MAX_NESTING_LEVELS = 5

# SharePoint-Typ -> JSON-Schema-Typ (ohne pattern/format, wie vorgegeben).
# Datumsfelder werden als einfacher String mit Beschreibung "JJJJ-MM-TT"
# abgebildet (kein `format: date`, da Structured Outputs `format` verbietet).
_TYPE_MAP = {
    "Text": "string",
    "Note": "string",
    "URL": "string",
    "Number": "number",
    "Boolean": "boolean",
    "DateOnly": "string",
    "DateTime": "string",
    "Choice": "string",  # wird unten durch enum spezialisiert
}


class SchemaBuildError(ValueError):
    pass


@dataclass
class IncludedFieldMeta:
    """Begleitinformation zu einem im Chat-Schema enthaltenen Feld, die der
    Backend-Code braucht, aber die Azure-OpenAI-Structured-Outputs-Schema
    selbst NICHT enthalten darf (z. B. ob ein Feld amtlich unbedingt ist).
    Wird separat als "field_meta" neben dem eigentlichen JSON-Schema
    ausgegeben, siehe `build_section`.
    """

    internal_name: str
    display_name: str
    sharepoint_type: str
    required_unbedingt: bool
    applies_to: str
    choices: list[str]
    note: Optional[str]

    def to_dict(self) -> dict:
        return {
            "internal_name": self.internal_name,
            "display_name": self.display_name,
            "sharepoint_type": self.sharepoint_type,
            "required_unbedingt": self.required_unbedingt,
            "applies_to": self.applies_to,
            "choices": self.choices,
            "note": self.note,
        }


@dataclass
class SectionBuildResult:
    list_name: str
    schema: dict
    field_meta: list[IncludedFieldMeta]
    excluded: list[dict]
    """Transparenzbericht: welche Felder ausgeschlossen wurden und warum
    (role + note), damit im PR-Review sichtbar ist, dass z. B. `tax_office`
    oder `small_business_rule` bewusst NICHT im Schema stehen."""

    def to_field_meta_dict(self) -> dict:
        return {
            "list": self.list_name,
            "fields": [m.to_dict() for m in self.field_meta],
        }

    def to_excluded_dict(self) -> dict:
        return {"list": self.list_name, "excluded": self.excluded}


def _json_type_for(f: FieldDef) -> str:
    try:
        return _TYPE_MAP[f.type]
    except KeyError as exc:
        raise SchemaBuildError(
            f"Kein JSON-Schema-Typ fuer SharePoint-Typ '{f.type}' "
            f"({f.list_name}/{f.internal_name}) hinterlegt."
        ) from exc


def _property_schema(f: FieldDef) -> dict:
    """Baut die JSON-Schema-Property fuer EIN Feld. Immer nullable (Union mit
    `null`), unabhaengig vom SharePoint-Pflichtstatus - siehe Moduldoc: die
    fachliche Pflicht wird NICHT ueber das LLM-Schema erzwungen (das LLM muss
    'nicht bekannt' immer ausdruecken koennen), sondern nachtraeglich vom
    Backend gegen `field_meta.required_unbedingt` geprueft (siehe
    `backend/app/validation.py`).
    """
    base_type = _json_type_for(f)
    description_parts = [f.display_name]
    if f.type == "DateOnly":
        description_parts.append("Format JJJJ-MM-TT, kein Textformat erzwungen.")
    if f.type == "Choice" and f.choices:
        description_parts.append("Zulaessige Werte: " + ", ".join(f.choices) + ".")
    if f.default_value is not None:
        description_parts.append(f"Vorbelegung, falls nichts bekannt: {f.default_value}.")

    prop: dict = {
        "type": [base_type, "null"],
        "description": " ".join(description_parts),
    }
    if f.type == "Choice" and f.choices:
        # enum darf laut Structured-Outputs-Regeln neben den Soll-Werten auch
        # null enthalten, wenn der Typ eine Union mit null ist.
        prop["enum"] = list(f.choices) + [None]
    return prop


def build_section(
    *,
    catalog: Catalog,
    list_name: str,
    classifier: ClassificationProvider,
    branch: Optional[Branch] = None,
) -> SectionBuildResult:
    """Baut das Chat-Schema fuer EINE SharePoint-Liste.

    `branch`: wenn gesetzt, werden Felder, deren Klassifizierung einen
    anderen Zweig (`applies_to`) verlangt, aus dem Schema ausgeschlossen
    (z. B. ein Beteiligter, der laut `participant_type` eine Gesellschaft
    ist, bekommt kein `date_of_birth`-Feld). Wenn `None`, werden alle Felder
    unabhaengig vom Zweig aufgenommen (sinnvoll fuer die erste, noch
    zweigunabhaengige Frage, die den Zweig ueberhaupt erst bestimmt, z. B.
    `party_type`/`person_type`/`participant_type` selbst).
    """
    fields = catalog.fields_of(list_name)
    properties: dict[str, dict] = {}
    field_meta: list[IncludedFieldMeta] = []
    excluded: list[dict] = []

    for f in fields:
        classification = classifier.classify(f)
        if classification.role is not FieldRole.TATSACHE:
            excluded.append(
                {
                    "internal_name": f.internal_name,
                    "role": classification.role.value,
                    "note": classification.note,
                }
            )
            continue
        if (
            branch is not None
            and classification.applies_to is not Branch.ALLE
            and classification.applies_to is not branch
        ):
            excluded.append(
                {
                    "internal_name": f.internal_name,
                    "role": "tatsache_anderer_zweig",
                    "note": (
                        f"Gilt nur fuer Zweig '{classification.applies_to.value}', "
                        f"aktueller Zweig ist '{branch.value}'."
                    ),
                }
            )
            continue

        properties[f.internal_name] = _property_schema(f)
        field_meta.append(
            IncludedFieldMeta(
                internal_name=f.internal_name,
                display_name=f.display_name,
                sharepoint_type=f.type,
                required_unbedingt=f.required,
                applies_to=classification.applies_to.value,
                choices=list(f.choices),
                note=classification.note,
            )
        )

    if len(properties) > MAX_PROPERTIES:
        raise SchemaBuildError(
            f"Schema fuer '{list_name}' hat {len(properties)} Properties, "
            f"erlaubt sind hoechstens {MAX_PROPERTIES}. Liste muss weiter "
            "unterteilt werden (z. B. in mehrere Chat-Abschnitte)."
        )

    schema = {
        "type": "object",
        "title": list_name,
        "additionalProperties": False,
        "properties": properties,
        "required": list(properties.keys()),
    }

    _assert_max_nesting(schema, list_name)

    return SectionBuildResult(
        list_name=list_name, schema=schema, field_meta=field_meta, excluded=excluded
    )


def _assert_max_nesting(schema: dict, list_name: str, _level: int = 1) -> None:
    if _level > MAX_NESTING_LEVELS:
        raise SchemaBuildError(
            f"Schema fuer '{list_name}' ueberschreitet {MAX_NESTING_LEVELS} "
            "Verschachtelungsebenen."
        )
    props = schema.get("properties", {})
    for prop_schema in props.values():
        if isinstance(prop_schema, dict) and prop_schema.get("type") == "object":
            _assert_max_nesting(prop_schema, list_name, _level + 1)
        if isinstance(prop_schema, dict) and prop_schema.get("type") == "array":
            items = prop_schema.get("items")
            if isinstance(items, dict) and items.get("type") == "object":
                _assert_max_nesting(items, list_name, _level + 1)


def wrap_for_structured_outputs(section: SectionBuildResult, *, schema_name: str) -> dict:
    """Verpackt das reine JSON-Schema in den von der Azure-OpenAI-Chat-
    Completions-API erwarteten `response_format`-Envelope (API-Version
    2024-08-01-preview oder neuer, `strict: true`).
    """
    return {
        "type": "json_schema",
        "json_schema": {
            "name": schema_name,
            "strict": True,
            "schema": section.schema,
        },
    }
