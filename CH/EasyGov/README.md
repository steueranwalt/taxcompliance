# EasyGov: Feldinventar Unternehmensgründung (Schweiz)

Strukturiertes Feldinventar aller Angaben, die [EasyGov.swiss](https://www.easygov.swiss) bei einer Unternehmensgründung abfragt, einschliesslich der anschliessenden Strecken Handelsregister, MWST (ESTV), AHV und UVG. Grundlage für SharePoint-Listen zur Datenerfassung, analog [`DE/AO/`](../../DE/AO/).

**Stand:** 15.11.2026 (Live-Inventar an Testentwürfen, nichts übermittelt).

**Keine Mandats- oder Personendaten.** Testdaten, Entwurfs-IDs und Dateipfade aus der Erhebung sind nicht übernommen.

## Dokumente

| Dokument | Rolle |
|---|---|
| [Einheitliches Datenmodell](Einheitliches-Datenmodell-easygov-unternehmensgruendung.md) | Zielbild, Objekte, Pflichtlogik, Forms-/Listen-Architektur |
| [Formulardaten: Rohfassung](formulardaten-roherfassung.md) | vollständiger Feldkatalog je Strecke |
| [Pflichtfelder](formulardaten-pflichtfelder.md) | unbedingte und bedingte Portalpflichten |
| [Meldepflichten-Matrix](meldepflichten-matrix.md) | Rechtsform × Umsatz × Personal → HR/MWST/AHV/UVG |
| [Lücken und offene Punkte](luecken-und-offene-punkte.md) | Portalfehler, nicht abgefragte Daten, offene Pfade |
| [`felder.json`](felder.json) / [`felder.schema.json`](felder.schema.json) | maschinenlesbarer Feldkatalog |
| [`wertelisten/`](wertelisten/) | Branchen, Berufe, Zeichnung, Funktionen, Verbände, Ausgleichskassen, UVG-Versicherer u. a. |
| [`sharepoint-forms/`](sharepoint-forms/) | PnP-Skript, Prüfskript, Klickanleitung Forms |

Verwandt, bleibt bestehen: [Handelsregisteranmeldung Einzelunternehmen (Ausdruck 11.8.2025)](../Handelsregister/handelsregister_einzelunternehmen_formularfelder_lp_beratung.md).

## Quellen-URLs

| Quelle | Rolle |
|---|---|
| https://www.easygov.swiss | Gründung, HR, AHV, UVG |
| https://mwstanmelden.estv.admin.ch/registration | MWST-Anmeldung ESTV |

## Rechtsgrundlagen (soweit im Inventar genannt)

- Art. 11 MWSTG (freiwillige Unterstellung)
- Art. 18 Abs. 2 und Art. 21 MWSTG (ausgenommene Leistungen und andere Mittelflüsse)
- Art. 37 Abs. 1 MWSTG (Saldosteuersatz; Schwellen Umsatz CHF 5'024'000 / Steuer CHF 108'000)
- Art. 39, 40 MWSTG (Art der Abrechnung)
- Art. 3 Bst. l MWSTG, MWST-Info 27 (elektronische Plattform)
- MWST-Info 02 Ziff. 5.2.1.1 (Beginn der obligatorischen Steuerpflicht)
- OR 459 (Prokura)
- HR- und MWST-Umsatzgrenze gemeinsam CHF 100'000 seit 1.1.2010 (Selbstüberwachung)

## Gebühren (Portalhinweise)

- Handelsregister: allgemein ca. CHF 120–600 je Rechtsform; Einzelunternehmen laut EasyGov CHF 180–300, Rechnung nach Publikation
- MWST-Anmeldung: gebührenfrei; bei frischem HR-Eintrag UID abwarten
- UVG: keine Gebühren
- Beglaubigte Handelsregisterauszüge: kostenpflichtig, kantonal, 0–10 Stück

## Tests

```
python3 CH/EasyGov/tests/test_konsistenz.py
pwsh CH/EasyGov/sharepoint-forms/Test-EasyGovGruendungListen.ps1
```

Der Python-Test ist die CI-/Lokal-Prüfung (ohne SharePoint). Das PowerShell-Prüfskript ruft ihn auf und kann zusätzlich eine Zielsite lesen.
