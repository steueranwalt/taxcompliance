#!/usr/bin/env python3
"""Erzeugt die lesbaren Markdown-Sichten aus felder.json / Matrix / Luecken."""
from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load() -> dict:
    return json.loads((ROOT / "felder.json").read_text(encoding="utf-8"))


def md_escape(text: str) -> str:
    return text.replace("|", "\\|").replace("\n", " ")


def rf(row: dict) -> str:
    return ", ".join(row.get("rechtsformen") or [])


def write_roherfassung(data: dict) -> None:
    felder = data["felder"]
    by_bereich: dict[str, list] = defaultdict(list)
    for f in felder:
        by_bereich[f["bereich"]].append(f)
    order = ["gruendung", "hr", "mwst", "ahv", "uvg"]
    titles = {
        "gruendung": "1. Gründungsablauf EasyGov (Meldepflichten und Basisdaten)",
        "hr": "2. Handelsregister-Anmeldung",
        "mwst": "3. MWST-Anmeldung (ESTV)",
        "ahv": "4. AHV-Anmeldung",
        "uvg": "5. UVG-Anmeldung",
    }
    lines = [
        "# Formulardaten: Rohfassung EasyGov-Unternehmensgründung",
        "",
        "Vollständiger Feldkatalog der bei EasyGov.swiss und `mwstanmelden.estv.admin.ch` erhobenen Angaben.",
        "",
        f"**Stand:** {data['stand']}",
        "",
        f"**Quelle:** {data['quelle']}",
        "",
        "**Zugehöriges Zielbild:** [`Einheitliches-Datenmodell-easygov-unternehmensgruendung.md`](Einheitliches-Datenmodell-easygov-unternehmensgruendung.md). Maschinenlesbar: [`felder.json`](felder.json) (Schema [`felder.schema.json`](felder.schema.json)).",
        "",
        "Labels folgen dem Live-Inventar vom 15.11.2026. Keine Mandats- oder Testdaten.",
        "",
        f"Anzahl Portal- und Kanzleifelder: **{len(felder)}**.",
        "",
    ]
    for bereich in order:
        lines.append(f"## {titles[bereich]}")
        lines.append("")
        groups: dict[tuple[str, str], list] = defaultdict(list)
        for f in by_bereich[bereich]:
            groups[(f["anmeldung"], f["schritt"])].append(f)
        for (anm, schritt), rows in groups.items():
            lines.append(f"### {anm} — {schritt}")
            lines.append("")
            lines.append("| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |")
            lines.append("|---|---|---|---|---|---|---|")
            for f in rows:
                hinw = f.get("bedingung") or f.get("hinweise") or ""
                lines.append(
                    "| `{id}` | {label} | {typ} | {pfl} | {rf} | {wl} | {hinw} |".format(
                        id=f["id"],
                        label=md_escape(f["label"]),
                        typ=f["datentyp"],
                        pfl=f["pflichtstatus"],
                        rf=rf(f),
                        wl=f.get("werteliste") or "—",
                        hinw=md_escape(hinw)[:220],
                    )
                )
            lines.append("")
    (ROOT / "formulardaten-roherfassung.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_pflichtfelder(data: dict) -> None:
    felder = data["felder"]
    unb = [f for f in felder if f["pflichtstatus"] == "unbedingt" and f["field_role"] == "Tatsache"]
    bed = [f for f in felder if f["pflichtstatus"] == "bedingt"]
    lines = [
        "# Pflichtfelder: EasyGov-Unternehmensgründung",
        "",
        f"**Methode:** Live-Inventar EasyGov und ESTV-Formular `mwstanmelden.estv.admin.ch` am {data['stand']}, Testentwürfe ohne Übermittlung, ohne Mandatsdaten.",
        "",
        "**Bezug:** Feldkatalog [`formulardaten-roherfassung.md`](formulardaten-roherfassung.md); Zielbild [`Einheitliches-Datenmodell-easygov-unternehmensgruendung.md`](Einheitliches-Datenmodell-easygov-unternehmensgruendung.md).",
        "",
        "SharePoint setzt «Erforderlich» nur bei unbedingter Pflicht, die für jeden Datensatz der Zielliste gilt (`sharepoint_required`). Alle übrigen Pflichten laufen über Forms-Branching, analog [`DE/AO/sharepoint-forms/README.md`](../../DE/AO/sharepoint-forms/README.md) Abschnitt C.",
        "",
        "## Unbedingte Pflichtfelder (Portal, Tatsachen)",
        "",
        f"{len(unb)} Felder. Prozess-Checkboxen (Bestätigung, CAPTCHA) und reine Aktionen sind in der Rohfassung dokumentiert, erscheinen hier nur, soweit sie ein Datenfeld sind.",
        "",
        "| Bereich | Schritt | Label | Rechtsformen |",
        "|---|---|---|---|",
    ]
    for f in unb:
        if f["datentyp"] in {"aktion", "anzeige"}:
            continue
        lines.append(f"| {f['bereich']} | {md_escape(f['schritt'])} | {md_escape(f['label'])} | {rf(f)} |")
    lines += [
        "",
        "## Bedingte Pflichtfelder",
        "",
        f"{len(bed)} Felder.",
        "",
        "| Bereich | Label | Bedingung | Rechtsformen |",
        "|---|---|---|---|",
    ]
    for f in bed:
        lines.append(
            f"| {f['bereich']} | {md_escape(f['label'])} | {md_escape(f.get('bedingung') or '—')} | {rf(f)} |"
        )
    lines += [
        "",
        "## Nicht als Forms-Pflicht abbilden",
        "",
        "- Ergebnisfelder der Meldepflichten-Matrix (`result_hr` / `result_mwst` / `result_ahv` / `result_uvg`) füllt die Kanzlei nach Prüfung.",
        "- «Mindestens zwei Gesellschafter» (KlG), «mindestens ein VR» (AG), «mindestens ein unbeschränkt und ein beschränkt Haftender» (KmG) sind Mengenvorgaben über `2_Personen`.",
        "- Saldosteuersatz-Anteile: Portalpflicht dokumentiert, Feld im Inventar nicht gefunden (siehe [`luecken-und-offene-punkte.md`](luecken-und-offene-punkte.md)).",
        "",
    ]
    (ROOT / "formulardaten-pflichtfelder.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_matrix() -> None:
    m = json.loads((ROOT / "meldepflichten-matrix.json").read_text(encoding="utf-8"))
    lines = [
        "# Meldepflichten-Matrix EasyGov",
        "",
        f"**Stand:** {m['stand']}. Schwelle Umsatz: CHF {m['schwelle_umsatz_chf']:,}".replace(",", "'") + ".",
        "",
        m["hinweis"],
        "",
        "Maschinenlesbar: [`meldepflichten-matrix.json`](meldepflichten-matrix.json).",
        "",
        "| ID | Rechtsform | Umsatz | Personal | HR | MWST | AHV | UVG | Hinweis |",
        "|---|---|---|---|---|---|---|---|---|",
    ]
    umsatz = {"unter_100k": "weniger als CHF 100'000", "ab_100k": "CHF 100'000 oder mehr"}
    personal = {"nur_inhaber": "nur Inhaber (1 Person)", "mit_angestellten": "mit Angestellten"}
    for z in m["zeilen"]:
        lines.append(
            "| {id} | {rf} | {u} | {p} | {hr} | {mwst} | {ahv} | {uvg} | {h} |".format(
                id=z["id"],
                rf=z["rechtsform"],
                u=umsatz[z["umsatz"]],
                p=personal[z["personal"]],
                hr=z["hr"],
                mwst=z["mwst"],
                ahv=z["ahv"],
                uvg=z["uvg"],
                h=md_escape(z.get("hinweis") or ""),
            )
        )
    lines += [
        "",
        "Rechtsgrundlagen der Schwelle, soweit im Inventar genannt: HR- und MWST-Grenze gemeinsam seit 1.1.2010; MWST Art. 11 (freiwillige Unterstellung), Art. 18 Abs. 2 und Art. 21 (ausgenommene Leistungen), Art. 37 Abs. 1 (Saldosteuersatz), Art. 39/40 (Abrechnungsart); MWST-Info 02 Ziff. 5.2.1.1 und MWST-Info 27; OR 459 (Prokura).",
        "",
    ]
    (ROOT / "meldepflichten-matrix.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_luecken() -> None:
    d = json.loads((ROOT / "luecken.json").read_text(encoding="utf-8"))
    lines = [
        "# Lücken, dokumentierte EasyGov-Fehler und offene Punkte",
        "",
        f"**Stand:** {d['stand']}. Quelle: Live-Inventar, ohne Testdaten und ohne Entwurfs-IDs.",
        "",
        "Maschinenlesbar: [`luecken.json`](luecken.json).",
        "",
        "## Dokumentierte Portalfehler",
        "",
    ]
    for b in d["bugs"]:
        lines += [f"### {b['titel']}", "", f"Bereich: `{b['bereich']}`. {b['beschreibung']}", ""]
    lines += ["## Von EasyGov nicht abgefragt (beim Notar bzw. der Kanzlei zu erheben)", ""]
    for g in d["nicht_abgefragt"]:
        extra = ""
        if g.get("spalten"):
            extra = " Spalten: " + ", ".join(
                f"`{c['liste']}.{c['internal_name']}`" for c in g["spalten"]
            ) + "."
        lines += [f"- **{g['titel']}** — {g['beschreibung']}{extra}"]
    lines += ["", "## Offene Erhebungspunkte", ""]
    for g in d["offen"]:
        lines += [f"- **{g['titel']}** — {g['beschreibung']}"]
    lines += [
        "",
        "## Bezug zur bestehenden HR-EU-Analyse",
        "",
        "Die ältere, anonymisierte Auswertung eines EasyGov-Ausdrucks «Anmeldung eines Einzelunternehmens» (Formularstand 11.8.2025, Kanton ZH) bleibt unter [`../Handelsregister/handelsregister_einzelunternehmen_formularfelder_lp_beratung.md`](../Handelsregister/handelsregister_einzelunternehmen_formularfelder_lp_beratung.md). Abweichungen zum Live-Inventar 15.11.2026 sind in der Rohfassung und in den offenen Punkten kenntlich; die ältere Analyse wird nicht ersetzt.",
        "",
    ]
    (ROOT / "luecken-und-offene-punkte.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    data = load()
    write_roherfassung(data)
    write_pflichtfelder(data)
    write_matrix()
    write_luecken()
    print("rendered markdown views")


if __name__ == "__main__":
    main()
