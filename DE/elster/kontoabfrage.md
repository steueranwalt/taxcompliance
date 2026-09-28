# ElsterKontoabfrage v2.1.3

## 1. Zweck

Online-Abfrage des Steuerkontos beim Finanzamt (offene Beträge, Ist-Buchungen, zum Soll gestellte Beträge). Voraussetzung: eine erteilte Vollmacht für den abfragenden Datenübermittler.

## 2. Daten: Verfahren / Datenart / Vorgang

| Verfahren | Datenart | Vorgang |
|---|---|---|
| ElsterKontoabfrage | Kontoabfrage | send-Auth |

### Nutzdaten

Wurzelelement `kontoabfrage`, `version="6"`. Je Anfrageteil ein `kontoabfrage-art`:

| Art | Bedeutung | Schema |
|---|---|---|
| `O` | offene Beträge | `eko_o_abfrage_000006.xsd` |
| `I` | Ist-Buchungen | `eko_i_abfrage_000006.xsd` |
| `ZS` | zum Soll gestellte Beträge | `eko_zs_abfrage_000006.xsd` |

**Input-Schlüsselfelder:** `steuernummer`, `steuerart`, `zeitraum`, `wertstellungsdatum`.

**Output-Elemente:** `steuerkontoOffeneBetraege`, `steuerkontoTilgungen`, `steuerkontoauszug`, dazugehörige Summenfelder, `Erläuterungen`, `bearbeitungshinweis`.

## 3. Taxonomie / Kataloge

Kein eigener Katalog im Paket. Für `steuerart` und `steuernummer`-Validierung gelten die allgemeinen Referenzkataloge:

- [`kataloge/pruefziffern-steuernummer-idnr.md`](kataloge/pruefziffern-steuernummer-idnr.md) — Prüfziffernverfahren je Bundesland.
- [`kataloge/finanzamtsdaten.md`](kataloge/finanzamtsdaten.md) — Finanzamtsnummern (BUFA), gegen die die `steuernummer` aufgelöst wird.
- Bescheidwertnummern-Kataloge (ESt/GSt/USt) sind fachlich verwandt, aber nicht direkt Teil der Kontoabfrage-Nutzdaten — siehe [`kataloge/bescheidnummern.md`](kataloge/bescheidnummern.md).

## 4. Quellen

- Paket: `ElsterKontoabfrage_v2.1.3.zip`, Version 2.1.3 (Stand 24.11.2025). Lokal vollständig extrahiert.
- `extracted/ElsterKontoabfrage_v2.1.3/Version_2.1.3/ElsterKontoabfrage/Doku/ElsterKontoabfrage_Schnittstellenbeschreibung_V2.1.3.pdf`
- `extracted/ElsterKontoabfrage_v2.1.3/Version_2.1.3/ElsterKontoabfrage/Schemata/Kontoabfrage-6.xsd`
- `extracted/ElsterKontoabfrage_v2.1.3/Version_2.1.3/ElsterKontoabfrage/Schemata/eko_o_abfrage_000006.xsd`
- `extracted/ElsterKontoabfrage_v2.1.3/Version_2.1.3/ElsterKontoabfrage/Schemata/eko_i_abfrage_000006.xsd`
- `extracted/ElsterKontoabfrage_v2.1.3/Version_2.1.3/ElsterKontoabfrage/Schemata/eko_zs_abfrage_000006.xsd`
- `extracted/ElsterKontoabfrage_v2.1.3/Version_2.1.3/ElsterKontoabfrage/Beispiele/`
- Portal-Name: `ElsterKontoabfrage_v2.1.3.zip`.

## 5. Gaps / offene Punkte

- Vollständiger Feldkatalog von `steuerkontoOffeneBetraege` / `steuerkontoTilgungen` / `steuerkontoauszug` (alle Unterfelder je Buchungssatz) wurde aus den XSD nicht bis auf Feldebene extrahiert — nur die Wurzelbezeichner sind hier erfasst.
- Encoding laut Inventar UTF-8; keine weiteren Abweichungen zur allgemeinen Transportschicht ([`elsterxml-v11.md`](elsterxml-v11.md)) dokumentiert.
