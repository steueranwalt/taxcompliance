# Quellensteuer: Aufbau der ESTV-Tarifdateien

Stand: 20.9.2026 · Format gültig ab 1.1.2025 · Abruf 20.9.2026

Fachliche Dokumentation des **Satzaufbaus**. Die Tarifdateien selbst gehören
nicht in dieses öffentliche Repo (siehe [Rechtslage](#rechtslage)).

Technik (Parser, Lookup) liegt nach Übernahme in `steueranwalt/steuerkanzlei`,
nicht hier.

## Quellen

| Dokument | URL | Abruf |
|----------|-----|-------|
| ESTV, Aufbau und Recordformate — **Löhne**, gültig ab 1.1.2025 | [PDF](https://www.estv.admin.ch/dam/de/sd-web/AvojuyFCZY95/qst-tarife-recordformate-loehne-2025-de.pdf) | 20.9.2026 |
| ESTV, Aufbau und Recordformate — **übrige Einkünfte**, gültig ab 1.1.2025 | [PDF](https://www.estv.admin.ch/dam/de/sd-web/oFSE9NY33E1k/qst-tarife-recordformate-einkuenfte-2025-de.pdf) | 20.9.2026 |
| ESTV, Tarifdateien für Lohnbuchhaltung | [Seite](https://www.estv.admin.ch/de/quellensteuertarife-import-in-lohnbuchhaltungssysteme) | 20.9.2026 |
| ESTV, Tarifdateien für übrige Einkünfte | [Seite](https://www.estv.admin.ch/de/quellensteuertarife-fuer-uebrige-einkuenfte) | 20.9.2026 |
| QStV Art. 1 (Tarifcodes) | [Fedlex AS 2024 478](https://www.fedlex.admin.ch/eli/oc/2024/478/de) | 20.9.2026 |

Codeliste: [`qst-tarifcodes.csv`](qst-tarifcodes.csv) / [`qst-tarifcodes.json`](qst-tarifcodes.json).
Kantonskennzeichen: [`kantonskennzeichen.csv`](kantonskennzeichen.csv).
Aktualisierung: [`quellensteuer-aktualisierung.md`](quellensteuer-aktualisierung.md).

## Zwei getrennte Serien

| Serie | Dateiname | Inhalt |
|-------|-----------|--------|
| Löhne | `tarjjkt.txt` / `.zip` | Progressive Lohntarife, vordefinierte Kategorien, Bezugsprovision, Median |
| Übrige Einkünfte | `vsljjkt.txt` / `.zip` | BGSA, Ersatzeinkünfte, Renten, Kapitalleistungen, Bezugsprovision inkl. `PLS` |

`jj` = Jahr (zwei Ziffern), `kt` = Kantonskennzeichen (`ZH`, `BE`, …).
Zusätzlich liefert die ESTV ein Schweiz-Paket. Stand Lohn 2026: Schweiz-Paket
vom 04.03.2026 (Korrektur Aargau).

Beides ist **ASCII mit festen Spaltenpositionen**. Weder XML noch JSON.
In der ESTV-PDF steht `·` für ein Leerzeichen; die echten Dateien enthalten
ASCII-Space (`0x20`).

## Rechtslage

- Die Dateien dienen Arbeitgebern, Software-Lieferanten und vergleichbaren
  Stellen. Eine allgemeine Publikation als PDF auf der ESTV-Seite ist nicht
  vorgesehen; die maschinenlesbaren ZIP/TXT stellt die ESTV gleichwohl bereit.
- **Weiterverbreitung: freigegeben** (Kanzlei, 21.9.2026). In diesem Repo
  liegen die Schweiz-TXT-ZIP 2026 plus SHA-256, nicht die entpackten 179-MB-TXT.
- Die ESTV haftet nicht für Vollständigkeit und Richtigkeit. Zuständig ist die
  jeweilige **kantonale** Steuerverwaltung.
- Eine Open-Data-Lizenz im engeren Sinn liegt nicht vor; die Freigabe gilt
  gleichwohl für diese Verwendung.

## Gemeinsame Regeln

- Beträge in 9-stelligen Feldern: Franken mit **zwei impliziten Nachkommastellen**.
  `000650100` = Fr. 6'501.00.
- Steuersatz in 5-stelligen Feldern: Prozent mit zwei impliziten Nachkommastellen.
  `00715` = 7,15 %.
- Einkommen/Leistungen in den Lohndateien sind **monatlich**.
- Transaktionsart: `01` Neuzugang, `02` Mutation, `03` Löschung.
- Kirchensteuer (letztes Zeichen des QSt-Codes, wo vorgesehen): `Y` mit, `N` ohne.
- Kantone, die nur `Y` oder nur `N` berechnen, liefern nur diese Variante.

## Satzarten

| Recordart | Serie | Inhalt | Typische Länge |
|-----------|-------|--------|----------------|
| `00` | beide | Vorlauf, einer je Datei | 110 |
| `06` | beide | progressive Tarife (Lohn bzw. übrige Einkünfte) | 62 |
| `11` | Löhne | vordefinierte Kategorien `HE`, `ME`, `NO`, `SF` | 62 |
| `12` | beide | Bezugsprovision | 62 |
| `13` | beide | Medianwert `MED` (Höchstbetrag satzbestimmendes Ehegatteneinkommen, Tarif C) | 62 |
| `99` | beide | Endrecord mit Anzahl aller Records inkl. `00` und `99` | 39 |

### Recordart 00 — Vorlauf

| Feld | Pos. | Länge | Inhalt |
|------|------|-------|--------|
| 1 | 01–02 | 2 | `00` |
| 2 | 03–04 | 2 | Kanton |
| 3 | 05–19 | 15 | SSL-Nummer, leer |
| 4 | 20–27 | 8 | Erstellungsdatum `JJJJMMTT` |
| 5 | 28–67 | 40 | Textzeile 1, leer |
| 6 | 68–107 | 40 | Textzeile 2, leer |
| 7 | 108–110 | 3 | Status, leer |

Amtliches Beispiel (Löhne 2025):

```
00BE···············20241125···················································································
```

Vorlauf, Kanton Bern, erstellt am 25.11.2024.

### Recordart 06 — progressive Tarife (Löhne)

| Feld | Pos. | Länge | Inhalt |
|------|------|-------|--------|
| 1 | 01–02 | 2 | `06` |
| 2 | 03–04 | 2 | Transaktionsart |
| 3 | 05–06 | 2 | Kanton |
| 4 | 07–16 | 10 | QSt-Code, links, mit Spaces aufgefüllt |
| 5 | 17–24 | 8 | gültig ab `JJJJMMTT` |
| 6 | 25–33 | 9 | steuerbares Einkommen ab Fr. |
| 7 | 34–42 | 9 | Tarifschritt in Fr. |
| 8 | 43 | 1 | Geschlecht, leer |
| 9 | 44–45 | 2 | Anzahl Kinder `00`–`09` |
| 10 | 46–54 | 9 | Mindeststeuer in Fr. |
| 11 | 55–59 | 5 | Steuer-%-Satz |
| 12 | 60–62 | 3 | Status, leer |

Amtliches Beispiel (Löhne 2025):

```
0601BEB2N·······20250101000650100000005000·0200000000000715···
```

Gelesen: Neuzugang, BE, Tarif `B2N` (verheirateter Alleinverdiener, 2 Kinder,
ohne Kirchensteuer), gültig ab 01.01.2025, Einkommen ab Fr. 6'501.00,
Tarifschritt Fr. 50.00, keine Mindeststeuer, Satz 7,15 %.

Die gleichen 12 Felder gelten für Recordart 06 der Serie *übrige Einkünfte*;
Feld 6 heisst dort «steuerbare Leistung ab». Codes dort: `E0N`/`E0Y`,
`G9N`/`Q9N`/`V9N`, `W9N`/`W9G`, `Y9N`, `Z9N`.

### Recordart 11 — vordefinierte Kategorien (nur Löhne)

Gleiches Feldlayout wie Recordart 06. Kinderfeld immer `00`. Codes:

| Code | Bedeutung | Rechtsgrund |
|------|-----------|-------------|
| `HEN` / `HEY` | Verwaltungsräte | Art. 93 DBG |
| `MEN` / `MEY` | Mitarbeiterbeteiligungen | Art. 97a DBG |
| `NON` / `NOY` | Korrektur (fälschlich / nicht an der Quelle besteuert) | ESTV-Format Ziff. 4.5 |
| `SFN` | Grenzgänger Frankreich, Sondervereinbarung | nur BE, BS, BL, JU, NE, SO, VD, VS |

Fixe Sätze, keine Kinderstaffel.

### Recordart 12 — Bezugsprovision

Gleiches Feldlayout. Codes Löhne: `PEL` (elektronisch), `PPA` (Papier),
`PSP` (vereinfachtes Verfahren). Serie übrige Einkünfte zusätzlich `PLS`
(Kapitalleistungen). Mindeststeuer bei Löhnen fix 0; bei übrigen Einkünften
trägt Feld 10 die maximale Bezugsprovision.

### Recordart 13 — Median

Ein Datensatz je Datei, Code `MED`. Der kantonale Höchstbetrag für das
satzbestimmende Ehegatteneinkommen (Tarif C) steht in Feld 10
(Mindeststeuer-Feld). Steuersatz fix 0.

Amtliches Beispiel:

```
1301BEMED·······20250101000000100099999900·0000057750000000···
```

Median Fr. 5'775.00.

### Recordart 99 — Ende

| Feld | Pos. | Länge | Inhalt |
|------|------|-------|--------|
| 1 | 01–02 | 2 | `99` |
| 2 | 03–17 | 15 | Absender SSL, leer |
| 3 | 18–19 | 2 | Kanton |
| 4 | 20–27 | 8 | Anzahl Records inkl. `00` und `99` |
| 5 | 28–36 | 9 | Checksumme, leer |
| 6 | 37–39 | 3 | Status, leer |

Amtliches Beispiel: `99···············BE00055047············` — 55'047 Records.

## QSt-Code

Drei Teile: Tarifgruppe + Kinderzahl + Kirchensteuer bzw. Länderzeichen.

Ausnahmen laut ESTV Löhne 2025 Ziff. 4.2:

- `H`, `P`, `U` nur mit 1–9 Kindern.
- `G`, `Q`, `V` immer `G9N`, `Q9N`, `V9N` — unabhängig von Kindern und Kirche.
- Vordefinierte Kategorien immer ohne Kinder.

`R`–`V` nur in **GR, TI, VS** (seit 1.1.2024).

In der Serie übrige Einkünfte ist das dritte Zeichen frei: bei Renten
`W9G` = Ansässigkeit Deutschland, nicht Kirchensteuer.

## Betrags- und Lookup-Logik

Tarifschritt-Beispiel der ESTV: ab Fr. 3'101.00, Schritt Fr. 50.00 → bis
Fr. 3'150.00; nächste Stufe ab Fr. 3'151.00. Also

`bis = ab + Schritt − Fr. 1.00`.

Lookup: höchste Stufe mit `ab ≤ steuerbares Monatseinkommen`.

Mindeststeuer (ESTV Ziff. 4.4):

```
wenn Einkommen × Satz < Mindeststeuer dann Mindeststeuer
sonst Einkommen × Satz
```

Kantone ohne Mindeststeuer müssen Feld 10 auf 0 lassen. Fixsätze bei
Tarif `D` (typisch nur Genf) und `E`.

Alle Lohnstufen decken Fr. 1.00 bis mindestens Fr. 100'000.00 ab.

## Sortierung in der Datei (Löhne)

1. Recordart aufsteigend
2. Tarifcode
3. Kirchensteuer `N` vor `Y`
4. Kinderzahl
5. Einkommen ab

## Was dieses Format nicht ist

Muster wie `ZH2026A0N000025000000024500` oder eine XML-Struktur
`<taxData><kanton><tarif><entry/>` entsprechen den ESTV-Dateien **nicht**.
Ein Parser schneidet feste Spalten je Recordart, er sucht nicht mit einem
Regulärausdruck über die ganze Zeile.

Die Repos `gendx/fetch-ch-tax-rates` und `gendx/swiss-taxes` betreffen
Einkommens- und Vermögenssteuer, nicht die Quellensteuer.
