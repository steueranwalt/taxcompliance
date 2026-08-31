# Ordner → Dokumentenmappen (Bibliothek Wissen)

**Site:** `https://obenhaus.sharepoint.com/sites/Wissen`
**Bibliothek:** `Freigegebene Dokumente`
**Inhaltstyp:** `Wissensmappe` (abgeleitet von `Dokumentenmappe`, `0x0120D520`)

Fortsetzung von [`../termstore/ARCHITECTURE.md`](../termstore/ARCHITECTURE.md).
Dort galt: *«Ordnerstruktur bleibt navigativ; Tags sind die abfragbare Facette.»*
Dokumentenmappen schliessen die Lücke dazwischen — das Thema wird ein Objekt mit
eigenen Metadaten, und diese Metadaten werden über *geteilte Spalten* auf die
enthaltenen Dokumente durchgeschrieben, statt nur im Ordnernamen zu stecken.

---

## 1. Bestandsaufnahme (gelesen am 2026-08-31)

Die Bibliothek hat auf oberster Ebene neun Ordner:

| Ebene 1 | Grösse | Themenordner darunter | Als Mappe? |
|---|---:|---:|---|
| 01 Internationales Steuerrecht | 1,53 GB | 14 | Ebene 2 |
| 02 Steuern DE | 1,19 GB | 15 | Ebene 2 |
| 03 Steuern CH | 184 MB | 4 | Ebene 2 |
| 04 Recht allgemein | 1,50 GB | 20 | Ebene 2 |
| 05 eigene Literatur | 811 MB | 6 | Ebene 2 |
| 06 AI-Memory | 39 KB | 1 | nein |
| General | 543 MB | 10 | **nein** |
| Steuerrecht | 8,3 MB | – | **nein** |
| Wissen | 99 KB | – | **nein** |

Vollständige Liste mit Begründung pro Ordner:
[`mappen-kandidaten.csv`](mappen-kandidaten.csv) (91 Zeilen, 59 empfohlene Mappen).

### Drei Befunde, die die Migration bestimmen

1. **`Steuerrecht` und `Wissen` sind OneNote-Notizbücher**, keine Dokumentordner
   — sie enthalten `Notizbuch öffnen.onetoc2`, `.one`-Abschnitte und
   `OneNote_RecycleBin`. Ein Wechsel des Inhaltstyps würde das Notizbuch
   beschädigen. Das Konvertierungsskript erkennt Notizbücher an der
   `.onetoc2`-Datei und überspringt sie samt Unterbaum, unabhängig von der
   Ausnahmeliste.
2. **`General` ist der Teams-Kanalordner** und enthält gemischten Kanzleibetrieb
   inklusive `Personal_DE` und `Personal_CH` — kein Wissensbestand, deshalb per
   Vorgabe ausgenommen.
3. **Ebene 2 ist die richtige Granularität.** Ebene 1 wären acht Mappen von je
   über einem Gigabyte; ein einzelnes `Rechtsgebiet` pro Mappe wäre dort
   wertlos. Auf Ebene 2 stehen die tatsächlichen Themen (`Betriebstaette`,
   `Verrechnungspreise`, `Kassenbuchführung`, `Umsatzsteuer`, `Zoll` …) — genau
   die Einheit, für die `Rechtsgebiet` + `Rechtsordnung` je einen Wert haben.

---

## 2. Warum Umwandlung an Ort und Stelle

SharePoint hat keinen UI-Befehl «Ordner in Dokumentenmappe umwandeln». Es gibt
zwei Wege:

| | Neu anlegen + verschieben | **Inhaltstyp wechseln (hier verwendet)** |
|---|---|---|
| Dateien | werden verschoben | bleiben unberührt |
| Element-IDs, Versionen | gehen verloren | bleiben |
| Freigaben, Links | brechen | bleiben gültig |
| Dauer bei ~5 GB | Stunden, Drosselung | Sekunden pro Ordner |
| Von Microsoft dokumentiert | ja | nein |

Der Wechsel setzt am Listenelement des Ordners zwei Felder:

```
ContentTypeId              0x0120  →  <Id der Wissensmappe>
HTML_x0020_File_x0020_Type (leer)  →  SharePoint.DocumentSet
```

Das ist die etablierte Praxis-Lösung, aber **kein von Microsoft dokumentierter
Weg**. Deshalb: `-ReportOnly` zuerst, dann `-Limit 5` als Probelauf, und
`-Rollback` setzt jeden protokollierten Ordner wieder auf `0x0120` zurück.

**Verschachtelung:** Dokumentenmappen können keine Dokumentenmappen enthalten.
Deshalb wird immer genau eine Ebene umgewandelt (`-Depth`). Ordner unterhalb
einer Mappe bleiben normale Unterordner — das ist erlaubt und bleibt so.

---

## 3. Ablauf

Voraussetzungen: PnP.PowerShell ≥ 2.x, Site-Collection-Administrator auf
`/sites/Wissen`, und die `Wissen*`-Spalten aus
[`../termstore/`](../termstore/WISSEN-LIBRARY-COLUMNS.md).

```powershell
cd _migration\dokumentenmappen
Connect-PnPOnline -Url "https://obenhaus.sharepoint.com/sites/Wissen" -Interactive

# Schritt 1 – Feature + Inhaltstypen-Verwaltung
.\Enable-Dokumentenmappen.ps1 -WhatIf
.\Enable-Dokumentenmappen.ps1

# Schritt 2 – Inhaltstyp "Wissensmappe"
.\New-WissenMappeContentType.ps1 -WhatIf
.\New-WissenMappeContentType.ps1

# Schritt 3 – Analyse, Probelauf, Vollauf
.\Convert-FoldersToDocumentSets.ps1 -ReportOnly     # ändert nichts
.\Convert-FoldersToDocumentSets.ps1 -Limit 5        # fünf Ordner
.\Convert-FoldersToDocumentSets.ps1                 # alle
```

Nach dem Probelauf im Browser prüfen: der Ordner trägt das Mappen-Symbol, ein
Klick öffnet die Willkommensseite, die Dateien sind vollständig da.

Zurücknehmen:

```powershell
.\Convert-FoldersToDocumentSets.ps1 -Rollback -ReportPath .\dokumentenmappen-log.csv
```

### Wichtige Schalter

| Schalter | Wirkung |
|---|---|
| `-Depth 1` | statt der Themenordner die acht Hauptordner umwandeln |
| `-ExcludePath` | Ausnahmeliste; Vorgabe `General`, `Steuerrecht`, `Wissen` |
| `-Limit n` | nur die ersten n Kandidaten |
| `-SystemUpdate` | ohne neue Version und ohne «Geändert von» zu überschreiben |
| `-WhatIf` | zeigt jede Änderung, führt keine aus |

---

## 4. Metadatenmodell der Mappe

| Feld | Am Inhaltstyp | Geteilt (wird durchgeschrieben) |
|---|---|---|
| `Title` | ja | – (Willkommensseite) |
| `WissenRechtsgebiet` | ja | **ja** |
| `WissenRechtsordnung` | ja | **ja** |
| `WissenSchlagworte` | ja | **ja** |
| `WissenDokumenttyp` | nein | nein — je Dokument verschieden |
| `WissenJahr`, `WissenAutor`, `WissenWerk`, `WissenSeite`, `WissenFundstelle`, `WissenAktenzeichen` | nein | nein — je Dokument verschieden |

Das folgt der Trennungsregel aus `ARCHITECTURE.md`: *wovon* (Rechtsgebiet) und
*welches Recht* (Rechtsordnung) gelten für die ganze Mappe, *welche Art Quelle*
(Dokumenttyp) und die Fundstelle gelten je Dokument.

Die geteilten Spalten und die Willkommensseite werden über CSOM gesetzt —
PnP.PowerShell hat dafür kein Cmdlet. Scheitert das, gibt Schritt 2 die
UI-Schritte aus und läuft weiter; die Migration funktioniert auch ohne.

---

## 5. Danach

1. Ansicht **Alle Dokumente**: Spalte `Inhaltstyp` einblenden, um Mappen von
   Ordnern zu unterscheiden.
2. Je Mappe `Rechtsgebiet` und `Rechtsordnung` setzen — einmal pro Thema statt
   einmal pro Dokument. Die Werte für die 59 Mappen lassen sich aus
   `../termstore/wissen-metadata-extract.csv` vorbelegen.
3. Erst danach `Apply-WissenTaxonomy.ps1` für die dokumentspezifischen Felder
   laufen lassen — die geteilten Spalten sind dann bereits gefüllt.

## 6. Dateien

| Datei | Inhalt |
|---|---|
| `_Common.ps1` | Verbindung, Bibliotheks-Auflösung, Content-Type-IDs |
| `Enable-Dokumentenmappen.ps1` | Schritt 1: Feature + Inhaltstypen-Verwaltung |
| `New-WissenMappeContentType.ps1` | Schritt 2: Inhaltstyp `Wissensmappe` |
| `Convert-FoldersToDocumentSets.ps1` | Schritt 3: Umwandlung, Protokoll, Rollback |
| `mappen-kandidaten.csv` | Bestandsaufnahme Ebene 1–2 mit Empfehlung |
| `dokumentenmappen-log.csv` | wird vom Konvertierungslauf geschrieben |
