# Quellensteuer: Bezug und Aktualisierung der Tarifdateien

Stand: 21.9.2026 · Abruf der ESTV-Seiten am 21.9.2026

## Entscheidungen (21.9.2026)

| Punkt | Entscheidung |
|-------|----------------|
| Weiterverbreitung | **Ja** — die ESTV-Tarifdateien dürfen weiterverbreitet werden |
| Umfang | Löhne **und** übrige Einkünfte |
| Kantone | **alle 26** |

In Git liegen die Schweiz-TXT-ZIP plus [`tarife/2026/manifest.json`](tarife/2026/manifest.json)
(URL, ESTV-Stand, SHA-256). Entpackte TXT nicht einchecken (~179 MB).

## Kalender

| Wer | Was | Wann |
|-----|-----|------|
| Kantone | liefern `tarjjkt` / `vsljjkt` an die ESTV | jährlich bis **30. November** |
| ESTV | schaltet die Dateien auf der Homepage auf | in der Regel **Anfang Dezember** |
| ESTV | unterjährige Korrekturen einzelner Kantone | bei Bedarf |

Verzögerungen und Korrekturen: `dvs@estv.admin.ch`.

2026: Schwyz (übrige Einkünfte 08.01.2026), Uri (Löhne 08.01.2026), Aargau
(Löhne Schweiz-Paket 04.03.2026).

## Direkte Paket-URLs 2026

- Löhne, alle Kantone: https://www.estv2.admin.ch/qst/2026/loehne/tar2026txt.zip
- Übrige Einkünfte, alle Kantone: https://www.estv2.admin.ch/qst/2026/uebrige-einkuenfte/vsl2026txt.zip

Einzelkantone folgen dem Muster `tar26xx.zip` / `vsl26xx.zip` unter
`https://www.estv2.admin.ch/qst/2026/loehne/` bzw. `.../uebrige-einkuenfte/`.

Downloader und Prüfung: `steuerkanzlei` → `scripts/ch-quellensteuer/download_qst_tariffs.py`.

## Was die ESTV prüft — und was nicht

Die ESTV prüft nur Tarifcodes laut Spezifikation (`R`–`V` nur GR/TI/VS),
Vorlauf- und Endrecord sowie die Anzahl der Datensätze. Den materiellen
Inhalt prüft sie nicht. Massgeblich bleiben die lesbaren Tarife der
kantonalen Steuerverwaltung.

## Haftung

Die ESTV haftet nicht für Vollständigkeit und Richtigkeit. Zuständig ist die
jeweilige kantonale Steuerverwaltung.

## Bezugs-Seiten

- Löhne: <https://www.estv.admin.ch/de/quellensteuertarife-import-in-lohnbuchhaltungssysteme>
- Übrige Einkünfte: <https://www.estv.admin.ch/de/quellensteuertarife-fuer-uebrige-einkuenfte>
