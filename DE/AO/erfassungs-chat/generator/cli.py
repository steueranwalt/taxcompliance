"""CLI: regeneriert alle abgeleiteten Artefakte (Katalog, Schemas,
Feld-Metadaten, Transparenzbericht) aus dem PnP-Skript.

Aufruf (aus `DE/AO/erfassungs-chat/`):

    python3 -m generator.cli build

Schreibt nach `generator/output/`:
  - catalog.json                     vollstaendiger Soll-Feldkatalog (217 Felder)
  - schemas/<Liste>.schema.json      Structured-Outputs-Schema je Liste
  - field_meta/<Liste>.meta.json     Begleitinfos je enthaltenem Feld
  - classification_report.json       je Liste: enthaltene vs. ausgeschlossene
                                      Felder mit Grund (Ergebnis/System/Zweig)

Diese Dateien sind GENERIERT - nicht von Hand bearbeiten. Nach einem Merge im
PnP-Skript (z. B. Aenderungen an `0_Fallsteuerung`) oder in
`classification_config.json` hier erneut ausfuehren und den Diff committen.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from .build_llm_schemas import SectionBuildResult, build_section, wrap_for_structured_outputs
from .field_classification import Branch, default_provider
from .pnp_schema_parser import parse_script_file

THIS_DIR = Path(__file__).parent
DEFAULT_SCRIPT_PATH = THIS_DIR.parent.parent / "sharepoint-forms" / "New-SteuerlicheErfassungListen.ps1"
DEFAULT_OUTPUT_DIR = THIS_DIR / "output"

# Listen, die der Mandanten-Chat fuer den ersten Anwendungsfall (steuerliche
# Erfassung einer auslaendischen Gesellschaft in Deutschland) tatsaechlich
# bespielt. 0_Fallsteuerung bleibt kanzleiintern (siehe README "Scope"),
# 7_Auslandsmitteilung_BZSt2 ist outbound-spezifisch. Gegenueber der
# ELSTER-Formular-Routingtabelle (sharepoint-forms/README.md Abschnitt E.9,
# die nur 1/3/5/8 fuer "Koerperschaft nach auslaendischem Recht" vorsieht)
# wurden 2/4/6 bewusst ergaenzt, weil Nils Obenhaus zusaetzliche Tatsachen
# (Gruendung/Wirtschaftsjahr, Beteiligte/Wohnsitz, Umsaetze) verlangt, die
# nicht im amtlichen ELSTER-Formular, aber im Datenmodell stehen.
CHAT_LISTS = [
    "1_Allgemeiner_Stammblock",
    "2_Unternehmens_Gruendungsmodul",
    "3_Personen_und_Vertretung",
    "4_Beteiligte_und_Quoten",
    "5_Betriebsstaetten",
    "6_Steuer_und_Umsatzsteuerprofil",
    "8_Unterlagen",
]

# Listen mit einem Zweig-Schluesselfeld (natuerliche Person vs. Gesellschaft).
# Fuer diese Listen werden zwei Schema-Varianten erzeugt (<Liste>.schema.json
# fuer den Zweig-unabhaengigen Teil ist nicht noetig, da branch=None bereits
# alle Felder liefert - die Zweig-Varianten dienen der Laufzeit-Nutzung durch
# `backend/app/conversation.py`, das nach Kenntnis des Zweigs gezielt
# nachfragt).
BRANCHED_LISTS = {
    "1_Allgemeiner_Stammblock": "party_type",
    "3_Personen_und_Vertretung": "person_type",
    "4_Beteiligte_und_Quoten": "participant_type",
}


def build_all(script_path: Path, output_dir: Path) -> None:
    catalog = parse_script_file(script_path)
    classifier = default_provider()

    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "schemas").mkdir(exist_ok=True)
    (output_dir / "field_meta").mkdir(exist_ok=True)

    (output_dir / "catalog.json").write_text(
        json.dumps(catalog.to_dict(), ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    classification_report: dict[str, list[dict]] = {}
    required_ergebnis_conflicts: dict[str, list[str]] = {}

    for list_name in CHAT_LISTS:
        if list_name not in catalog.list_names():
            raise SystemExit(
                f"Liste '{list_name}' nicht im Katalog gefunden - Skript "
                "geaendert? CHAT_LISTS in cli.py pruefen."
            )

        section = build_section(catalog=catalog, list_name=list_name, classifier=classifier, branch=None)
        _write_section(output_dir, section, suffix="")
        classification_report[list_name] = {
            "enthalten": [m.internal_name for m in section.field_meta],
            "ausgeschlossen": section.excluded,
        }

        # Transparenz-Report: SharePoint-Spalten, die (a) als Ergebnisfeld vom
        # Chat ausgeschlossen sind, ABER (b) im PnP-Skript weiterhin
        # `-Required` sind. Ein Graph-Schreibzugriff auf diese Liste scheitert
        # dann an SharePoints eigener Pflichtfeldpruefung, da der Chat den
        # Wert nie erhebt - siehe README "Offene Punkte" (Abstimmung mit dem
        # parallelen Datenmodell-PR notwendig, der diese Spalten voraussichtlich
        # auf nicht-Pflicht umstellt).
        excluded_as_ergebnis = {
            x["internal_name"] for x in section.excluded if x["role"] == "ergebnis"
        }
        conflicts = [
            f.internal_name
            for f in catalog.fields_of(list_name)
            if f.required and f.internal_name in excluded_as_ergebnis
        ]
        if conflicts:
            required_ergebnis_conflicts[list_name] = conflicts

        branch_key = BRANCHED_LISTS.get(list_name)
        if branch_key:
            for branch in (Branch.NATUERLICHE_PERSON, Branch.GESELLSCHAFT):
                branched_section = build_section(
                    catalog=catalog, list_name=list_name, classifier=classifier, branch=branch
                )
                _write_section(output_dir, branched_section, suffix=f"__{branch.value}")

    (output_dir / "classification_report.json").write_text(
        json.dumps(classification_report, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (output_dir / "required_ergebnis_konflikte.json").write_text(
        json.dumps(required_ergebnis_conflicts, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def _write_section(output_dir: Path, section: SectionBuildResult, *, suffix: str) -> None:
    schema_name = f"{section.list_name}{suffix}"
    envelope = wrap_for_structured_outputs(section, schema_name=schema_name)
    (output_dir / "schemas" / f"{schema_name}.schema.json").write_text(
        json.dumps(envelope, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (output_dir / "field_meta" / f"{schema_name}.meta.json").write_text(
        json.dumps(section.to_field_meta_dict(), ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    build_cmd = sub.add_parser("build", help="Alle Artefakte neu generieren.")
    build_cmd.add_argument("--script", type=Path, default=DEFAULT_SCRIPT_PATH)
    build_cmd.add_argument("--output", type=Path, default=DEFAULT_OUTPUT_DIR)
    args = parser.parse_args()

    if args.command == "build":
        build_all(args.script, args.output)
        print(f"Generiert nach {args.output}")


if __name__ == "__main__":
    main()
