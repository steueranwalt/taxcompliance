"""Parst `New-SteuerlicheErfassungListen.ps1` (PnP-PowerShell-Skript) in einen
maschinenlesbaren Feldkatalog.

Zweck (siehe ../README.md): Das Soll-Schema fuer den Erfassungs-Chat wird NICHT
von Hand abgeschrieben, sondern aus derselben Quelle abgeleitet, die auch die
SharePoint-Listen erzeugt. Nach einem Merge, der z. B. `0_Fallsteuerung`
aendert (neue Choice-Werte, neue Felder, geaenderter Pflichtstatus), liefert
ein erneuter Lauf dieses Parsers automatisch den aktuellen Stand - ohne dass
jemand den Chat-Code anfassen muss.

Der Parser ist bewusst kein vollstaendiger PowerShell-Interpreter. Er nutzt
dieselbe Konvention, die auch `Test-SteuerlicheErfassungListen.ps1` im Skript
selbst beschreibt: jeder `Add-Field`-Aufruf ist eine in sich abgeschlossene
Anweisung, die mit `Add-Field -List "..."` am Zeilenanfang (ggf. mit
Einrueckung) beginnt und bis unmittelbar vor den naechsten `Add-Field`- bzw.
`New-ListIfMissing`-Aufruf (oder das Dateiende) reicht. Innerhalb dieses
Blocks werden die acht benannten Parameter ausgewertet, die im Skript
tatsaechlich verwendet werden (siehe `Add-Field`-Funktionssignatur dort).

Dieses Modul hat bewusst KEINE Abhaengigkeit von PowerShell/PnP - es laeuft
mit der Python-Standardbibliothek, da auf dieser VM kein `pwsh` verfuegbar
ist und der Generator auch in einer reinen Python-/Azure-Functions-Umgebung
laufen soll.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


_STATEMENT_START_RE = re.compile(
    r"^[ \t]*(Add-Field|New-ListIfMissing)\b", re.MULTILINE
)

# Erkennt "-ParamName" am Zeilenanfang eines Tokens (inkl. Zeilenumbrueche
# durch Backtick-Fortsetzung `\``\n, die vorher durch _join_continuations
# bereits zu Leerzeichen normalisiert wurden).
_PARAM_RE = re.compile(r"-([A-Za-z]+)\b")

_STRING_RE = re.compile(r'"((?:[^"]|"")*)"')
_ARRAY_RE = re.compile(r"@\(([^)]*)\)", re.DOTALL)
_BOOL_SWITCH_PARAMS = {"Required", "Indexed", "EnforceUniqueValues"}
_NUMERIC_PARAMS = {"Min", "Max", "Decimals"}


@dataclass
class FieldDef:
    """Eine Spalte, wie sie ein `Add-Field`-Aufruf im PnP-Skript beschreibt."""

    list_name: str
    internal_name: str
    display_name: str
    type: str
    required: bool = False
    choices: list[str] = field(default_factory=list)
    lookup_list: Optional[str] = None
    lookup_field: Optional[str] = None
    delete_behavior: str = "None"
    indexed: bool = False
    enforce_unique_values: bool = False
    min: Optional[float] = None
    max: Optional[float] = None
    decimals: Optional[int] = None
    default_value: Optional[str] = None

    def to_dict(self) -> dict:
        return {
            "list": self.list_name,
            "internal_name": self.internal_name,
            "display_name": self.display_name,
            "type": self.type,
            "required": self.required,
            "choices": list(self.choices),
            "lookup_list": self.lookup_list,
            "lookup_field": self.lookup_field,
            "delete_behavior": self.delete_behavior,
            "indexed": self.indexed,
            "enforce_unique_values": self.enforce_unique_values,
            "min": self.min,
            "max": self.max,
            "decimals": self.decimals,
            "default_value": self.default_value,
        }


@dataclass
class ListDef:
    """Eine SharePoint-Liste in Reihenfolge ihrer `New-ListIfMissing`-Anlage."""

    name: str
    fields: list[FieldDef] = field(default_factory=list)


@dataclass
class Catalog:
    """Vollstaendiger, aus dem Skript geparster Soll-Zustand."""

    lists: list[ListDef] = field(default_factory=list)

    def list_names(self) -> list[str]:
        return [l.name for l in self.lists]

    def fields_of(self, list_name: str) -> list[FieldDef]:
        for l in self.lists:
            if l.name == list_name:
                return l.fields
        raise KeyError(f"Liste nicht im Katalog: {list_name}")

    def to_dict(self) -> dict:
        return {
            "lists": [
                {"name": l.name, "fields": [f.to_dict() for f in l.fields]}
                for l in self.lists
            ]
        }


class PnpScriptParseError(ValueError):
    """Wird geworfen, wenn das Skript nicht in der erwarteten Form vorliegt."""


def _unescape_ps_string(raw: str) -> str:
    # PowerShell verdoppelt in einfachen/doppelten Strings eingebettete
    # Anfuehrungszeichen ("") statt sie mit Backslash zu escapen.
    return raw.replace('""', '"')


def _extract_statement_blocks(script_text: str) -> list[tuple[str, int]]:
    """Zerlegt den Skripttext in (Blocktext, Startzeile)-Tupel je Anweisung.

    Jeder Block reicht vom Beginn eines `Add-Field`- oder
    `New-ListIfMissing`-Aufrufs bis unmittelbar vor den naechsten solchen
    Aufruf (oder das Dateiende). Kommentarzeilen *vor* einem Aufruf gehoeren
    damit zum vorherigen Block und werden dort schlicht ignoriert, da nur
    nach benannten Parametern gesucht wird.
    """
    starts = [m.start() for m in _STATEMENT_START_RE.finditer(script_text)]
    if not starts:
        raise PnpScriptParseError(
            "Keine Add-Field/New-ListIfMissing-Aufrufe im Skript gefunden."
        )
    blocks = []
    for i, start in enumerate(starts):
        end = starts[i + 1] if i + 1 < len(starts) else len(script_text)
        block_text = script_text[start:end]
        line_no = script_text.count("\n", 0, start) + 1
        blocks.append((block_text, line_no))
    return blocks


def _join_continuations(block_text: str) -> str:
    """Normalisiert Backtick-Zeilenfortsetzungen und Zeilenumbrueche zu
    Leerzeichen, damit Parameter unabhaengig vom Zeilenumbruch gefunden
    werden. Entfernt dabei Kommentarzeilen (beginnend mit `#`), damit ein
    Kommentar mit einer zufaelligen Raute mitten in einer mehrzeiligen
    Choices-Liste nicht versehentlich den Rest der Anweisung verschluckt.
    """
    lines = block_text.splitlines()
    cleaned = []
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("#"):
            continue
        # Trailing Backtick ist nur eine Zeilenfortsetzung, kein Zeichen.
        if stripped.endswith("`"):
            stripped = stripped[:-1]
        cleaned.append(stripped)
    return " ".join(cleaned)


def _parse_choices(raw_array: str) -> list[str]:
    return [
        _unescape_ps_string(m.group(1)) for m in _STRING_RE.finditer(raw_array)
    ]


def _parse_param_value(joined: str, start_idx: int) -> tuple[Optional[str], int]:
    """Liest ab `start_idx` (direkt nach dem Parameternamen) den Wert.

    Gibt (Rohwert als String ODER None bei Switch-Parameter, neue Position)
    zurueck. Werte sind entweder ein Quoted-String, ein `@( ... )`-Array oder
    ein nacktes Wort/Zahl (z. B. `-Type Choice`, `-Min 0`).
    """
    rest = joined[start_idx:]
    m = re.match(r"\s+", rest)
    if not m:
        return None, start_idx  # Switch-Parameter am Ende der Anweisung
    after_ws = start_idx + m.end()
    rest2 = joined[after_ws:]

    if rest2.startswith('"'):
        sm = _STRING_RE.match(rest2)
        if not sm:
            raise PnpScriptParseError(f"Unbeendeter String ab Position {after_ws}")
        return sm.group(0), after_ws + sm.end()

    if rest2.startswith("@("):
        am = _ARRAY_RE.match(rest2)
        if not am:
            raise PnpScriptParseError(f"Unbeendetes Array ab Position {after_ws}")
        return am.group(0), after_ws + am.end()

    # Naechster Parameter (Switch ohne Wert) oder Ende der Anweisung.
    if rest2.startswith("-") and re.match(r"^-[A-Za-z]", rest2):
        return None, start_idx

    wm = re.match(r"[^\s]+", rest2)
    if not wm:
        return None, start_idx
    return wm.group(0), after_ws + wm.end()


def _parse_add_field_block(joined: str, line_no: int) -> FieldDef:
    params: dict[str, object] = {}
    for pm in _PARAM_RE.finditer(joined):
        name = pm.group(1)
        if name in _BOOL_SWITCH_PARAMS and (
            pm.end() >= len(joined) or joined[pm.end()] in " \t" 
        ):
            # Kann sowohl Switch (-Required) als auch spaeter mit Wert
            # verwendet werden; im Skript werden diese drei ausschliesslich
            # als Switches benutzt, daher reicht die reine Praesenzpruefung.
            pass
        value_raw, _ = _parse_param_value(joined, pm.end())
        if name in _BOOL_SWITCH_PARAMS:
            params[name] = True
            continue
        if value_raw is None:
            continue
        if value_raw.startswith('"'):
            params[name] = _unescape_ps_string(_STRING_RE.match(value_raw).group(1))
        elif value_raw.startswith("@("):
            params[name] = _parse_choices(value_raw)
        else:
            params[name] = value_raw

    try:
        list_name = str(params["List"])
        internal_name = str(params["InternalName"])
        display_name = str(params["DisplayName"])
        field_type = str(params["Type"])
    except KeyError as exc:
        raise PnpScriptParseError(
            f"Add-Field-Aufruf in Zeile {line_no} fehlt Pflichtparameter: {exc}"
        ) from exc

    def _num(name: str) -> Optional[float]:
        raw = params.get(name)
        if raw is None:
            return None
        return float(raw)

    decimals_raw = params.get("Decimals")

    return FieldDef(
        list_name=list_name,
        internal_name=internal_name,
        display_name=display_name,
        type=field_type,
        required=bool(params.get("Required", False)),
        choices=list(params.get("Choices", []) or []),
        lookup_list=params.get("LookupList"),
        lookup_field=params.get("LookupField"),
        delete_behavior=str(params.get("DeleteBehavior", "None")),
        indexed=bool(params.get("Indexed", False)),
        enforce_unique_values=bool(params.get("EnforceUniqueValues", False)),
        min=_num("Min"),
        max=_num("Max"),
        decimals=int(decimals_raw) if decimals_raw is not None else None,
        default_value=params.get("DefaultValue"),
    )


def _parse_new_list_block(joined: str, line_no: int) -> str:
    m = re.search(r"-Title\s+" + _STRING_RE.pattern, joined)
    if not m:
        raise PnpScriptParseError(
            f"New-ListIfMissing-Aufruf in Zeile {line_no} ohne -Title."
        )
    return _unescape_ps_string(m.group(1))


def parse_script(script_text: str) -> Catalog:
    """Parst den vollstaendigen Skripttext in einen `Catalog`.

    Reihenfolge der Listen und Felder entspricht der Reihenfolge im Skript.
    """
    catalog = Catalog()
    current_list: Optional[ListDef] = None

    for block_text, line_no in _extract_statement_blocks(script_text):
        joined = _join_continuations(block_text)
        if joined.startswith("New-ListIfMissing"):
            list_name = _parse_new_list_block(joined, line_no)
            current_list = ListDef(name=list_name)
            catalog.lists.append(current_list)
        elif joined.startswith("Add-Field"):
            field_def = _parse_add_field_block(joined, line_no)
            if current_list is None or current_list.name != field_def.list_name:
                # Add-Field kann theoretisch vor der zugehoerigen
                # New-ListIfMissing-Zeile im Text stehen (im Skript nicht der
                # Fall, aber defensiv behandelt): an die passende/neue Liste haengen.
                existing = next(
                    (l for l in catalog.lists if l.name == field_def.list_name), None
                )
                if existing is None:
                    existing = ListDef(name=field_def.list_name)
                    catalog.lists.append(existing)
                current_list = existing
            current_list.fields.append(field_def)
        else:  # pragma: no cover - durch Regex ausgeschlossen
            raise PnpScriptParseError(f"Unbekannter Anweisungstyp in Zeile {line_no}")

    return catalog


def parse_script_file(path: str | Path) -> Catalog:
    text = Path(path).read_text(encoding="utf-8")
    return parse_script(text)
