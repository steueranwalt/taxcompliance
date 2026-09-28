# Katalog: Bescheidwertnummern (ESt / GSt / USt), Januar 2026

## 1. Zweck

Katalog der in elektronischen Bescheiden verwendeten Bescheidwertnummern für Einkommensteuer (ESt), Gewerbesteuer (GSt) und Umsatzsteuer (USt) — feingranularer als der DIVA-Katalog „Art des Schreibens" ([`diva-art-des-schreibens.md`](diva-art-des-schreibens.md)), der nur den Dokumenttyp, nicht die einzelnen Bescheidwerte klassifiziert.

## 2. Daten: Verfahren / Datenart / Vorgang

Kein eigenes Verfahren — Referenzkatalog, der von Bescheid-verarbeitenden Verfahren (Datenabholung, Kontoabfrage) konsumiert werden kann, ohne selbst Teil des Verfahren/Datenart/Vorgang-Tripels zu sein.

### Schema

Microsoft-Excel-XML-Workbook (`urn:schemas-microsoft-com:office:spreadsheet`, SpreadsheetML). Spalten: `Bescheidwertnr.`, `Bezeichnung`, `Dezimalst.`, `Art*)`.

### Umfang (gezählte 10-stellige Codes)

| Steuerart | Anzahl Codes |
|---|---:|
| Einkommensteuer (ESt) | ~1.865 |
| Gewerbesteuer (GSt) | ~401 |
| Umsatzsteuer (USt) | ~229 |

## 3. Taxonomie / Kataloge

Dies **ist** der Katalog (drei separate Dateien, eine je Steuerart). Verwandt: [`diva-art-des-schreibens.md`](diva-art-des-schreibens.md) (Bescheidtyp), [`finanzamtsdaten.md`](finanzamtsdaten.md) (erlassendes Finanzamt).

## 4. Quellen

- Paket: `Bescheidnr_Januar_2026.zip`, Stand 21.01.2026 (Portal-Stand 22.01.2026). Lokal vollständig extrahiert.
- `extracted/Bescheidnr_Januar_2026/Bescheidnummern_ESt.xml`
- `extracted/Bescheidnr_Januar_2026/Bescheidnummern_GSt.xml`
- `extracted/Bescheidnr_Januar_2026/Bescheidnummern_USt.xml`
- Portal-Name: `Bescheidnr_Januar_2026.zip`.

## 5. Gaps / offene Punkte

- Feldgenaue Auswertung der Codetabellen (Zellinhalte je Bescheidwertnummer) steht aus — die Workbook-Struktur ist nicht als einfache Zeilen-CSV aufgebaut, sondern als SpreadsheetML mit Zellreferenzen; eine vollständige Extraktion aller ~2.500 Codes wurde hier nicht vorgenommen.
- Bedeutung der Spalte `Art*)` (Fussnote im Original) wurde nicht aufgelöst.
