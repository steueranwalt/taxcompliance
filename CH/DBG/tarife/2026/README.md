# ESTV-Quellensteuertarife 2026

Weiterverbreitung: **freigegeben** (Kanzlei, 21.9.2026).
Umfang: Löhne **und** übrige Einkünfte, **alle 26 Kantone**.

In Git gehören nur:

- die beiden Schweiz-TXT-ZIP (`tar2026txt.zip`, `vsl2026txt.zip`, zusammen ~13 MB)
- [`manifest.json`](manifest.json) mit URL, ESTV-Stand und SHA-256

Nicht einchecken: die entpackten TXT (Löhne allein ~179 MB). Nach dem Klonen:

```
python3 scripts/ch-quellensteuer/download_qst_tariffs.py \
  --out CH/DBG/tarife/2026 --keep-zip
```

im Repo `steuerkanzlei`, mit `--manifest` auf diese Datei. Oder die ZIP direkt
von der ESTV laden und gegen das Manifest prüfen.

| Paket | URL | ESTV-Stand |
|-------|-----|------------|
| Löhne | https://www.estv2.admin.ch/qst/2026/loehne/tar2026txt.zip | 04.03.2026 |
| Übrige Einkünfte | https://www.estv2.admin.ch/qst/2026/uebrige-einkuenfte/vsl2026txt.zip | 09.01.2026 |

Die ESTV haftet nicht für Vollständigkeit und Richtigkeit. Zuständig sind die
kantonalen Steuerverwaltungen.
