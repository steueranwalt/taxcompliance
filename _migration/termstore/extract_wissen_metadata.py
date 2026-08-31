#!/usr/bin/env python3
"""Extract Jahr/Autor/Werk/Seite/Fundstelle/Titel/Aktenzeichen from Notizbuch markdown.

Writes CSV for Apply-WissenMetadata.ps1. Paths are relative to repo root and
match SharePoint under Shared Documents/Wissen/...
"""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

JOURNALS = (
    "DStR",
    "DStRE",
    "IStR",
    "ISR",
    "NJW",
    "NStZ",
    "NVwZ",
    "BB",
    "DB",
    "ZStP",
    "FR",
    "stbp",
    "PStR",
    "AO-StB",
    "GmbHR",
    "WPg",
    "BFH/NV",
    "BFHE",
    "BStBl",
)

JOURNAL_RE = "|".join(re.escape(j) for j in JOURNALS)

# DStR 2018, 2284  |  NJW 2024, 2092  |  DStR-2002,-1641
CITE_RE = re.compile(
    rf"(?P<werk>{JOURNAL_RE})\s*[- ]?\s*(?P<jahr>19\d{{2}}|20[0-2]\d)\s*[,;-]\s*(?P<seite>\d{{1,5}}(?:\s*[-–]\s*\d{{1,5}})?)",
    re.I,
)
# Autor: Werk title | Journal year, page   (beck table)
TITLE_FUND_RE = re.compile(
    rf"(?P<autor>[A-Za-zÄÖÜäöüß/\-]+(?:\s*/\s*[A-Za-zÄÖÜäöüß/\-]+)?)\s*:\s*.{{5,120}}?\s*\|\s*"
    rf"(?P<werk>{JOURNAL_RE})\s+(?P<jahr>19\d{{2}}|20[0-2]\d),\s*(?P<seite>\d{{1,5}})",
    re.I,
)
# Dietrich: ... (NJW 2024, 2092)
PAREN_CITE_RE = re.compile(
    rf"(?P<autor>[A-Za-zÄÖÜäöüß/\-]+(?:\s*/\s*[A-Za-zÄÖÜäöüß/\-]+)?)\s*:\s*.{{0,80}}?\("
    rf"(?P<werk>{JOURNAL_RE})\s+(?P<jahr>19\d{{2}}|20[0-2]\d),\s*(?P<seite>\d{{1,5}})\)",
    re.I,
)
YEAR_RE = re.compile(r"(?<!\d)(19\d{2}|20[0-2]\d)(?!\d)")
BMF_RE = re.compile(
    r"BMF\s*(?:v\.|vom)?\s*(?P<d>\d{1,2}\.\d{1,2}\.(?P<jahr>19\d{2}|20[0-2]\d))",
    re.I,
)
BFH_RE = re.compile(
    r"BFH(?:[,\s]|-Urt).*?(?:vom\s*)?(?P<d>\d{1,2}\.\d{1,2}\.(?P<jahr>19\d{2}|20[0-2]\d))",
    re.I,
)

SENAT_AZ_RE = re.compile(
    r"\b((?:[IVX]+|I{1,3}V?|VI{0,3}|IX|X(?:I{0,3}|IV)?)\s+R\s+\d{1,4}/\d{2,4})\b",
    re.I,
)
FG_K_AZ_RE = re.compile(
    r"\b(\d{1,2}\s+K\s+\d{1,5}/\d{2}(?:\s+[A-Z])?)\b",
    re.I,
)
BMF_AZ_RE = re.compile(
    r"BMF\s+(?:v\.|vom)\s*\d{1,2}\.\d{1,2}\.\d{4}\s*[–\-]\s*"
    r"((?:IV|III|II|I|VI|VII|VIII|IX|X)\s+[A-Z]\s+\d+(?:\s*[–\-]\s*S\s+[\d/\-\s]+?)"
    r"(?=\s*,|\s+BStBl|\s*$|\)|\.))",
    re.I,
)
VA_AZ_STANDALONE_RE = re.compile(
    r"\b((?:IV|III|II|I|VI|VII|VIII|IX|X)\s+[A-Z]\s+\d+\s*[–\-]\s*S\s+[\d/\-\s]+?"
    r"(?=\s*,|\s+BStBl|\s*$|\)|\.))",
    re.I,
)
COURT_DECISION_AZ_RE = re.compile(
    r"(?:FG\s+[^,\n]{0,40},\s*)?(?:Gerichtsbescheid|Urteil|Beschluss)"
    r"(?:\s*\([^)]+\))?\s*(?:vom|v\.)\s*"
    r"\d{1,2}\.\s*\d{1,2}\.\s*\d{4}\s*[-–]\s*"
    r"(\d{1,2}\s+K\s+[\d/]+(?:\s+[A-Z])?)",
    re.I,
)
BECK_TITLE_ROW_RE = re.compile(
    rf"^\s*[^:]+:\s*(.+?)\s*\|\s*(?:{JOURNAL_RE})\s+\d{{4}}",
    re.M | re.I,
)
_TITLE_SUFFIX_RE = re.compile(
    rf"\s*[-–]\s*(?:beck-online|steuern-haufe|datev-magazin|personal-haufe)\s*$",
    re.I,
)
_JOURNAL_SUFFIX_RE = re.compile(
    rf"\s*[-–]\s*{JOURNAL_RE}\s+\d{{4}},\s*\d{{1,5}}\s*$",
    re.I,
)


_AUTHOR_STOP = {
    "titel",
    "fundstelle",
    "ausgeschnitten",
    "siehe",
    "hier",
    "vgl",
    "nach",
    "beim",
    "oder",
    "und",
    "bzw",
    "munchen",
    "münchen",
    "berlin",
    "zurich",
    "zürich",
}


def clean_author(a: str | None) -> str | None:
    if not a:
        return None
    a = a.strip(" -:|")
    a = re.sub(r"\s+", " ", a)
    if len(a) < 3 or len(a) > 80:
        return None
    if a.lower() in _AUTHOR_STOP:
        return None
    if not re.search(r"[A-Za-zÄÖÜäöüß]", a):
        return None
    # require capital letter start (author surnames)
    if not re.match(r"^[A-ZÄÖÜ]", a):
        return None
    return a


def infer_dokumenttyp(path: str, name: str, text: str) -> str | None:
    path_name = f"{path} {name}".lower()
    head = text[:1500].lower()
    if any(
        x in path_name
        for x in ("bfh", "fg-", "fg_", "urteil", "urt.", "beschluss", "rechtsprechung")
    ):
        return "Urteil / Rechtsprechung"
    if any(x in path_name for x in ("bmf", "ofd", "verwaltungsanweisung", "anwendungsschreiben")):
        return "Verwaltungsanweisung"
    if re.search(r"\bbmf\b", head) and "schreiben" in path_name:
        return "Verwaltungsanweisung"
    if "kommentar" in path_name:
        return "Kommentar (Werk)"
    if any(x in path_name for x in ("bt-drs", "br-drs", "gesetzesmaterial", "regierungsentwurf", "referentenentwurf")):
        return "Gesetzesmaterialien"
    if any(x in path_name for x in ("checkliste", "arbeitshilfe", "muster-")):
        return "Arbeitshilfe / Checkliste"
    if any(
        x in path_name
        for x in ("internes-memo", "interner-vermerk", "interne-notiz", "/memo/")
    ):
        return "Internes Memo"
    if any(x in path_name for x in ("präsentation", "prasentation", "summit", "vortrag")):
        return "Präsentation"
    if any(x in path_name for x in ("merkblatt", "leitfaden")):
        return "Merkblatt / Leitfaden"
    if CITE_RE.search(name) or "titelfundstelle" in head or CITE_RE.search(text[:2500]):
        return "Fachaufsatz"
    if any(x in path_name for x in ("haufe", "beck-online", "datev-magazin")):
        return "Fachaufsatz"
    return None


def clean_title(text: str | None) -> str | None:
    if not text:
        return None
    t = text.strip(" -|:")
    t = _TITLE_SUFFIX_RE.sub("", t)
    t = _JOURNAL_SUFFIX_RE.sub("", t)
    t = re.sub(r"\s+", " ", t).strip()
    if len(t) < 5 or len(t) > 300:
        return None
    return t


def title_from_filename(stem: str) -> str | None:
    s = stem.replace("-", " ")
    s = re.sub(r"\s+[a-f0-9]{8}$", "", s, flags=re.I)
    s = _TITLE_SUFFIX_RE.sub("", s)
    s = _JOURNAL_SUFFIX_RE.sub("", s)
    s = re.sub(r"\s+", " ", s).strip()
    if len(s) >= 5:
        return s[:300]
    return None


def extract_titel(name: str, text: str, dokumenttyp: str | None) -> str | None:
    if dokumenttyp not in ("Fachaufsatz", "Internes Memo"):
        return None

    head = text[:5000]
    m = BECK_TITLE_ROW_RE.search(head)
    if m:
        t = clean_title(m.group(1))
        if t:
            return t

    h1s = [clean_title(h) for h in re.findall(r"^#\s+(.+)$", head, re.M)]
    h1s = [h for h in h1s if h]
    if len(h1s) >= 2 and len(h1s[1]) > max(20, len(h1s[0]) * 0.6):
        return h1s[1]
    if h1s:
        return h1s[0]
    return title_from_filename(name)


def _normalize_az(az: str) -> str:
    az = az.replace("–", "-").strip()
    az = re.sub(r"\s+", " ", az)
    az = re.sub(r"\s*/\s*", "/", az)
    return az[:120]


def az_from_filename(stem: str) -> str | None:
    m = re.search(
        r"(IV|III|II|I|VI|VII|VIII|IX|X)-B-(\d+).*?S-([\d\-]+)",
        stem,
        re.I,
    )
    if m:
        s_part = m.group(3).replace("-", "/")
        return _normalize_az(f"{m.group(1)} B {m.group(2)} - S {s_part}")

    # FG-BW-12-K-623-22 -> 12 K 623/22
    m = re.search(
        r"(?:^|[- ])(?:FG[- ]?(?:BW|München|Münster|NRW|Berlin|Hamburg|Köln|Saarland|Nürnberg|Düsseldorf|Kassel|Schleswig|Bremen|Rheinland|Hessen)[- ]?)?"
        r"(\d{1,2})[- ]K[- ](\d{1,5})[- ](\d{2})(?:[- ]([A-Z]))?",
        stem,
        re.I,
    )
    if m:
        az = f"{m.group(1)} K {m.group(2)}/{m.group(3)}"
        if m.group(4):
            az += f" {m.group(4)}"
        return _normalize_az(az)

    m = re.search(
        r"(?:^|[- ])([IVX]+)[- ]R[- ](\d{1,4})[- ](\d{2,4})",
        stem,
        re.I,
    )
    if m:
        return _normalize_az(f"{m.group(1)} R {m.group(2)}/{m.group(3)}")

    m = BMF_AZ_RE.search(stem.replace("-", " "))
    if m:
        return _normalize_az(m.group(1))

    m = VA_AZ_STANDALONE_RE.search(stem.replace("-", " "))
    if m:
        return _normalize_az(m.group(1))
    return None


def extract_aktenzeichen(name: str, text: str, dokumenttyp: str | None) -> str | None:
    if dokumenttyp not in ("Urteil / Rechtsprechung", "Verwaltungsanweisung"):
        return None

    head = text[:6000]
    prefix = f"{name}\n{head}"

    h1 = re.search(r"^#\s+(.+)$", head[:800], re.M)
    if h1:
        line = h1.group(1)
        for rx in (FG_K_AZ_RE, SENAT_AZ_RE):
            m = rx.search(line)
            if m:
                return _normalize_az(m.group(1))
        m = re.search(
            r"(?:FG|BFH|Finanzgericht)[^,\n]{0,40}(\d{1,2}\s+K\s+\d{1,5}/\d{2,4})",
            line,
            re.I,
        )
        if m:
            return _normalize_az(m.group(1))

    for line in head.splitlines()[:35]:
        m = COURT_DECISION_AZ_RE.search(line)
        if m:
            return _normalize_az(m.group(1))
        if re.match(r"^\s*(?:FG|BFH|Finanzgericht|Bundesfinanzhof)\b", line, re.I):
            for rx in (FG_K_AZ_RE, SENAT_AZ_RE):
                m = rx.search(line)
                if m:
                    return _normalize_az(m.group(1))

    for rx in (BMF_AZ_RE, VA_AZ_STANDALONE_RE):
        m = rx.search(prefix)
        if m:
            return _normalize_az(m.group(1))

    return az_from_filename(name)


def infer_rechtsordnung(path: str) -> str | None:
    p = path.replace("\\", "/")
    if re.search(r"(Steuern-CH|/CH/|_CH|Schweiz)", p):
        return "Schweiz (CH)"
    if re.search(r"(Steuern-DE|/DE/|_DE|Deutschland)", p):
        return "Deutschland (DE)"
    if re.search(r"(International|Transferpricing|DBA|Verrechnungspreis|OECD)", p, re.I):
        return "International / Bilateral"
    return None


def infer_rechtsgebiet(path: str) -> str | None:
    p = path.replace("\\", "/").lower()
    mapping = [
        (r"verrechnungspreis|transferpricing|funktionen|dokumentation", "Verrechnungspreise"),
        (r"steuerstraf", "Steuerstrafrecht"),
        (r"/bp/|betriebspr[uü]fung|au[sß]enpr[uü]fung", "Steuerverfahrensrecht"),
        (r"ust|umsatzsteuer|mwst", "Indirekte Steuern"),
        (r"est|kst|gewst|einkommen|k[oö]rperschaft|gewerbesteuer", "Direkte Steuern"),
        (r"astg|hinzurechnung|au[sß]ensteuer", "Internationales Steuerrecht"),
        (r"dba|doppelbesteuer", "Doppelbesteuerungsrecht"),
        (r"datenschutz|dsgvo|bdsg", "Datenschutz"),
        (r"zoll", "Internationales Steuerrecht"),
        (r"steuerrecht|/steuern-", "Steuerrecht"),
        (r"strafverfahren|stpo|strafrecht", "Strafrecht"),
        (r"verfahrensrecht|prozessrecht|fgo", "Verfahrensrecht"),
    ]
    for rx, label in mapping:
        if re.search(rx, p):
            return label
    return None


def extract_from_text_and_name(name: str, text: str) -> dict:
    head = text[:4000]
    out: dict[str, str | int | None] = {
        "Jahr": None,
        "Autor": None,
        "Werk": None,
        "Seite": None,
        "Fundstelle": None,
    }

    for rx in (TITLE_FUND_RE, PAREN_CITE_RE):
        m = rx.search(head)
        if m:
            out["Autor"] = clean_author(m.group("autor"))
            out["Werk"] = m.group("werk")
            out["Jahr"] = int(m.group("jahr"))
            out["Seite"] = m.group("seite").replace("–", "-").replace(" ", "")
            out["Fundstelle"] = f"{out['Werk']} {out['Jahr']}, {out['Seite']}"
            return out

    for source in (name.replace("-", " "), head):
        m = CITE_RE.search(source)
        if m:
            out["Werk"] = m.group("werk")
            out["Jahr"] = int(m.group("jahr"))
            out["Seite"] = m.group("seite").replace("–", "-").replace(" ", "")
            out["Fundstelle"] = f"{out['Werk']} {out['Jahr']}, {out['Seite']}"
            break

    if out["Jahr"] is None:
        for rx in (BMF_RE, BFH_RE):
            m = rx.search(f"{name} {head}")
            if m:
                out["Jahr"] = int(m.group("jahr"))
                break
    if out["Jahr"] is None:
        years = [int(y) for y in YEAR_RE.findall(name)]
        years = [y for y in years if 1950 <= y <= 2026]
        if years:
            out["Jahr"] = max(years)

    # Autor from "Name: Title | Journal" without full match already handled
    if out["Autor"] is None:
        m = re.search(
            r"^#\s*.{0,80}?\b([A-ZÄÖÜ][a-zäöüß]+(?:/[A-ZÄÖÜ][a-zäöüß]+)+)\b",
            head,
            re.M,
        )
        # weak – skip
        m2 = re.search(
            rf"([A-ZÄÖÜ][A-Za-zÄÖÜäöüß/\-]{{2,40}})\s*:\s*.{{5,100}}?\(({JOURNAL_RE})\s+\d{{4}}",
            head,
        )
        if m2:
            out["Autor"] = clean_author(m2.group(1))

    if out["Werk"] and out["Jahr"] and out["Seite"] and not out["Fundstelle"]:
        out["Fundstelle"] = f"{out['Werk']} {out['Jahr']}, {out['Seite']}"
    return out


def process_file(path: Path, root: Path) -> dict:
    rel = path.relative_to(root).as_posix()
    text = path.read_text(encoding="utf-8", errors="ignore")
    meta = extract_from_text_and_name(path.stem, text)
    dokumenttyp = infer_dokumenttyp(rel, path.stem, text) or ""
    return {
        "FileLeafRef": path.name,
        "ServerRelativePath": f"Wissen/{root.name}/{rel}".replace("\\", "/"),
        "LocalPath": str(path.relative_to(root.parent)).replace("\\", "/"),
        "Jahr": meta["Jahr"] or "",
        "Autor": meta["Autor"] or "",
        "Werk": meta["Werk"] or "",
        "Seite": meta["Seite"] or "",
        "Fundstelle": meta["Fundstelle"] or "",
        "Titel": extract_titel(path.stem, text, dokumenttyp or None) or "",
        "Aktenzeichen": extract_aktenzeichen(path.stem, text, dokumenttyp or None) or "",
        "Dokumenttyp": dokumenttyp,
        "Rechtsordnung": infer_rechtsordnung(rel) or "",
        "Rechtsgebiet": infer_rechtsgebiet(rel) or "",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--root",
        default=str(Path(__file__).resolve().parents[2] / "Notizbuch-fuer-Wissen"),
    )
    ap.add_argument(
        "--out",
        default=str(Path(__file__).resolve().parent / "wissen-metadata-extract.csv"),
    )
    args = ap.parse_args()
    root = Path(args.root)
    rows = []
    for p in sorted(root.rglob("*.md")):
        if p.name.upper() == "README.MD":
            continue
        rows.append(process_file(p, root))

    out = Path(args.out)
    fields = [
        "ServerRelativePath",
        "LocalPath",
        "FileLeafRef",
        "Jahr",
        "Autor",
        "Werk",
        "Seite",
        "Fundstelle",
        "Titel",
        "Aktenzeichen",
        "Dokumenttyp",
        "Rechtsordnung",
        "Rechtsgebiet",
    ]
    with out.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, delimiter=";")
        w.writeheader()
        w.writerows(rows)

    filled = sum(
        1
        for r in rows
        if r["Jahr"] or r["Werk"] or r["Autor"] or r["Dokumenttyp"] or r["Titel"] or r["Aktenzeichen"]
    )
    print(f"Wrote {len(rows)} rows -> {out}")
    print(f"With any extracted meta: {filled}")
    print(
        "With Fundstelle parts:",
        sum(1 for r in rows if r["Werk"] and r["Jahr"] and r["Seite"]),
    )
    print("With Titel:", sum(1 for r in rows if r["Titel"]))
    print("With Aktenzeichen:", sum(1 for r in rows if r["Aktenzeichen"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
