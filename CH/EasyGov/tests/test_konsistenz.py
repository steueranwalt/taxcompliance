#!/usr/bin/env python3
"""Konsistenztest EasyGov-Feldkatalog.

Lauffaehig lokal und in CI, ohne SharePoint und ohne PnP:

    python3 CH/EasyGov/tests/test_konsistenz.py

Prueft analog DE/AO/sharepoint-forms/Test-SteuerlicheErfassungListen.ps1
die Soll-Definitionen (hier JSON statt AST-Parse der Add-Field-Aufrufe):
eindeutige IDs, Pflichtstatus und Datentyp gesetzt, jede Wertelisten-Referenz
existiert, interne SharePoint-Namen <= 32 Zeichen und [A-Za-z0-9_], keine
Schreibvarianten-Dubletten, keine Required-Ergebnisfelder, keine Testdaten.
"""
from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FELDER_PATH = ROOT / "felder.json"
SCHEMA_PATH = ROOT / "felder.schema.json"
MATRIX_PATH = ROOT / "meldepflichten-matrix.json"
LUECKEN_PATH = ROOT / "luecken.json"
WL_DIR = ROOT / "wertelisten"
WL_SCHEMA = WL_DIR / "wertelisten.schema.json"

PFLICHT = {"unbedingt", "bedingt", "optional", "ergebnis", "system", "nicht_erfasst"}
TYPEN = {"text", "note", "number", "date", "choice", "multichoice", "boolean", "lookup", "checkbox_group", "aktion", "anzeige", "datei"}
RF = {"EU", "GmbH", "AG", "KlG", "KmG"}
ROLES = {"Tatsache", "Ergebnis", "System"}
BEREICH = {"gruendung", "hr", "mwst", "ahv", "uvg"}

LEAK_PATTERNS = [
    re.compile(r"756\.1234\.5678\.97"),
    re.compile(r"TEST Inventar", re.I),
    re.compile(r"1034523\d{3}"),
    re.compile(r"1034612683"),
    re.compile(r"Teststrasse", re.I),
    re.compile(r"HR_Anmelden-TEST", re.I),
    re.compile(r"AHV_Anmeldung_TEST", re.I),
    re.compile(r"UV_Anmeldung_TEST", re.I),
]

errors: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)


def load_json(path: Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001
        err(f"{path.name}: JSON unlesbar: {exc}")
        return None


def required_keys(obj: dict, keys: list[str], where: str) -> None:
    for k in keys:
        if k not in obj:
            err(f"{where}: Pflichtschlüssel fehlt: {k}")


def normalize_choice(value: str) -> str:
    n = value.strip().lower()
    n = n.replace("ä", "ae").replace("ö", "oe").replace("ü", "ue").replace("ß", "ss")
    n = re.sub(r"\s+", " ", n)
    return n


def test_felder(data: dict, wertelisten: set[str]) -> None:
    required_keys(data, ["schema_version", "stand", "quelle", "hinweis_rechtsverbindlichkeit", "felder"], "felder.json")
    felder = data.get("felder") or []
    if len(felder) < 50:
        err(f"felder.json: zu wenige Felder ({len(felder)})")
    ids: set[str] = set()
    by_sp: dict[tuple[str, str], list[dict]] = defaultdict(list)
    for i, f in enumerate(felder):
        loc = f.get("id") or f"index {i}"
        required_keys(f, ["id", "bereich", "anmeldung", "schritt", "label", "datentyp", "pflichtstatus", "rechtsformen"], loc)
        fid = f.get("id") or ""
        if fid in ids:
            err(f"doppelte Feld-ID: {fid}")
        ids.add(fid)
        if not re.match(r"^[a-z0-9]+(\.[a-z0-9_]+)+$", fid or ""):
            err(f"{fid}: ID entspricht nicht dem Schema-Muster")
        if f.get("bereich") not in BEREICH:
            err(f"{fid}: unbekannter Bereich {f.get('bereich')}")
        if f.get("datentyp") not in TYPEN:
            err(f"{fid}: Datentyp fehlt oder unzulässig: {f.get('datentyp')}")
        if f.get("pflichtstatus") not in PFLICHT:
            err(f"{fid}: Pflichtstatus fehlt oder unzulässig: {f.get('pflichtstatus')}")
        if f.get("field_role") not in ROLES:
            err(f"{fid}: field_role unzulässig: {f.get('field_role')}")
        rfs = f.get("rechtsformen") or []
        if not rfs or any(x not in RF for x in rfs):
            err(f"{fid}: Rechtsformen unvollständig/unzulässig: {rfs}")
        if f.get("pflichtstatus") == "bedingt" and not (f.get("bedingung") or "").strip():
            err(f"{fid}: bedingt ohne Bedingung")
        wl = f.get("werteliste")
        if wl and wl not in wertelisten:
            err(f"{fid}: Werteliste '{wl}' existiert nicht")
        if f.get("datentyp") in {"choice", "multichoice", "checkbox_group"} and not wl:
            err(f"{fid}: {f['datentyp']} ohne Werteliste")
        splist = f.get("sharepoint_liste")
        spname = f.get("sharepoint_internal_name")
        if (splist and not spname) or (spname and not splist):
            err(f"{fid}: SharePoint-Liste und interner Name nur gemeinsam setzen")
        if spname:
            if len(spname) > 32 or not re.match(r"^[A-Za-z][A-Za-z0-9_]{0,31}$", spname):
                err(f"{fid}: ungültiger interner Name '{spname}' ({len(spname)} Zeichen)")
            by_sp[(splist, spname)].append(f)
            if f.get("sharepoint_required") and f.get("field_role") != "Tatsache" and f.get("datentyp") != "lookup":
                err(f"{fid}: sharepoint_required trotz field_role={f.get('field_role')}")
        if f.get("label") and not str(f["label"]).strip():
            err(f"{fid}: leeres Label")

    for key, rows in by_sp.items():
        types = {r["datentyp"] for r in rows if r["datentyp"] not in {"aktion", "anzeige"}}
        if len(types) > 1:
            err(f"SharePoint {key[0]}/{key[1]}: Datentyp-Konflikt {types}")
        roles = {r["field_role"] for r in rows}
        if len(roles) > 1:
            err(f"SharePoint {key[0]}/{key[1]}: FieldRole-Konflikt {roles}")
        wls = {r.get("werteliste") for r in rows if r.get("werteliste")}
        if len(wls) > 1:
            err(f"SharePoint {key[0]}/{key[1]}: Wertelisten-Konflikt {wls}")


def test_wertelisten() -> set[str]:
    names: set[str] = set()
    for path in sorted(WL_DIR.glob("*.json")):
        if path.name == "wertelisten.schema.json":
            continue
        data = load_json(path)
        if not isinstance(data, dict):
            continue
        required_keys(data, ["id", "stand", "titel", "werte"], path.name)
        if data.get("id") != path.stem:
            err(f"{path.name}: id '{data.get('id')}' weicht vom Dateinamen ab")
        werte = data.get("werte") or []
        if len(werte) < 1:
            err(f"{path.name}: keine Werte")
        seen_norm: dict[str, str] = {}
        for w in werte:
            if not isinstance(w, dict) or not w.get("wert"):
                err(f"{path.name}: Werteintrag ohne 'wert'")
                continue
            val = w["wert"]
            key = normalize_choice(val)
            if key in seen_norm and seen_norm[key] != val:
                err(f"{path.name}: Schreibvarianten-Dublette '{seen_norm[key]}' vs. '{val}'")
            seen_norm[key] = val
        names.add(path.stem)
    if "branchen" not in names or "verbaende" not in names or "uvg_versicherer" not in names:
        err("Pflicht-Wertelisten branchen/verbaende/uvg_versicherer fehlen")
    return names


def test_matrix() -> None:
    data = load_json(MATRIX_PATH)
    if not isinstance(data, dict):
        return
    required_keys(data, ["schema_version", "stand", "hinweis", "zeilen"], "meldepflichten-matrix.json")
    ids = set()
    for z in data.get("zeilen") or []:
        required_keys(z, ["id", "rechtsform", "umsatz", "personal", "hr", "mwst", "ahv", "uvg"], z.get("id") or "matrix-zeile")
        if z.get("id") in ids:
            err(f"Matrix: doppelte id {z.get('id')}")
        ids.add(z.get("id"))
        if z.get("rechtsform") not in RF:
            err(f"Matrix {z.get('id')}: unbekannte Rechtsform")
    if len(ids) < 5:
        err("Matrix: zu wenige Zeilen")


def test_luecken() -> None:
    data = load_json(LUECKEN_PATH)
    if not isinstance(data, dict):
        return
    for key in ("bugs", "nicht_abgefragt", "offen"):
        if not data.get(key):
            err(f"luecken.json: {key} leer")
        ids = [x.get("id") for x in data.get(key) or []]
        if len(ids) != len(set(ids)):
            err(f"luecken.json: doppelte IDs in {key}")


def test_no_leaks_or_eszett() -> None:
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix not in {".json", ".md", ".ps1", ".py"}:
            continue
        if path.name.endswith(".schema.json"):
            continue
        text = path.read_text(encoding="utf-8")
        if path.parent.name == "tests":
            continue
        if "ß" in text:
            err(f"{path.relative_to(ROOT)}: enthält ß (Schweizer Schreibweise ss)")
        for pat in LEAK_PATTERNS:
            if pat.search(text):
                err(f"{path.relative_to(ROOT)}: verbotenes Test-/Entwurfsmuster {pat.pattern}")
        # NFC check not required; skip combining chars issues


def test_schemas_exist() -> None:
    for p in (SCHEMA_PATH, WL_SCHEMA, ROOT / "meldepflichten-matrix.schema.json"):
        if not p.exists():
            err(f"Schema fehlt: {p.name}")


def main() -> int:
    test_schemas_exist()
    wertelisten = test_wertelisten()
    data = load_json(FELDER_PATH)
    if isinstance(data, dict):
        test_felder(data, wertelisten)
    test_matrix()
    test_luecken()
    test_no_leaks_or_eszett()

    print(f"Prüfungen abgeschlossen. Dateien unter {ROOT}")
    if errors:
        print(f"ERGEBNIS: {len(errors)} Abweichungen")
        for e in errors:
            print(f"  - {e}")
        return 1
    n = len((load_json(FELDER_PATH) or {}).get("felder") or []) if FELDER_PATH.exists() else 0
    print(f"ERGEBNIS: OK ({n} Felder, {len(wertelisten)} Wertelisten)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
