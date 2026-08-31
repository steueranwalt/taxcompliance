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

### 3.1 Verbindung herstellen

Jedes Skript und jede Prüfabfrage braucht eine bestehende PnP-Verbindung. Ohne
sie kommt nur `You are not signed in. Please use Connect-PnPOnline to connect.`

```powershell
Connect-PnPOnline -Url "https://obenhaus.sharepoint.com/sites/Wissen" -Interactive
```

**Seit PnP.PowerShell 2.2 braucht `-Interactive` eine eigene `-ClientId`.** Die
frühere mehrmandantenfähige «PnP Management Shell»-App wurde von Microsoft
zurückgezogen. Ohne ClientId bricht der Aufruf ab mit:

```
WARNING: Please specify a valid client id for an Entra ID App Registration.
Connect-PnPOnline: Specified method is not supported.
```

Es braucht also **einmalig pro Tenant eine App-Registrierung**. Zwei Wege:

**Weg A — über PnP.** Die Parameter dieses Cmdlets haben sich zwischen den
Modulversionen geändert; erst die Signatur der installierten Version ansehen,
nicht raten:

```powershell
Get-Module PnP.PowerShell -ListAvailable | Select-Object Name, Version
Get-Command Register-PnPEntraIDAppForInteractiveLogin -Syntax
```

Dann mit den Parametern aufrufen, die die Signatur tatsächlich anbietet —
mindestens `-ApplicationName` und `-Tenant`. Der Aufruf legt die App an, öffnet
die Zustimmung und gibt die ClientId zurück.

**Weg B — von Hand im Entra Admin Center.** Unabhängig von der Modulversion und
das, was Weg A im Ergebnis auch tut:

1. Entra Admin Center → *App-Registrierungen* → *Neue Registrierung*
2. Name z. B. `PnP-Wissen-Migration`, *Nur eigene Organisation*
3. Umleitungs-URI: Typ *Öffentlicher Client / native*, Wert `http://localhost`
4. *Authentifizierung* → *Öffentliche Clientflows zulassen* auf **Ja**
5. *API-Berechtigungen* → *Delegiert*:
   SharePoint → `AllSites.FullControl`, Microsoft Graph → `User.Read`
6. *Administratorzustimmung erteilen*
7. Die *Anwendungs-ID (Client)* von der Übersichtsseite kopieren

Beide Wege brauchen die Entra-Rolle **Anwendungsadministrator** oder höher plus
das Recht, Administratorzustimmung zu erteilen. Fehlt das, muss die IT ran — es
ist eine Tenant-Einstellung, keine Einstellung der Site.

Danach immer mit der ClientId verbinden:

```powershell
$clientId = "<ClientId aus der Registrierung>"
Connect-PnPOnline -Url "https://obenhaus.sharepoint.com/sites/Wissen" `
                  -Interactive -ClientId $clientId -Tenant "obenhaus.onmicrosoft.com"
```

Ist `obenhaus.onmicrosoft.com` nicht die Anfangsdomäne des Tenants, stattdessen
die richtige `*.onmicrosoft.com`-Domäne oder die Tenant-GUID einsetzen. Die
Skripte nehmen `-ClientId` und `-Tenant` auch selbst an, zusammen mit `-Connect`:

```powershell
.\Convert-FoldersToDocumentSets.ps1 -ReportOnly -Connect -Interactive `
    -ClientId $clientId -Tenant "obenhaus.onmicrosoft.com"
```

Verbindung prüfen:

```powershell
Get-PnPConnection | Select-Object Url, ClientId
Get-PnPWeb | Select-Object Title, ServerRelativeUrl
```

### 3.2 Die vier Schritte

```powershell
cd _migration\dokumentenmappen
# Verbindung wie unter 3.1

# Schritt 1 – Feature + Inhaltstypen-Verwaltung
.\Enable-Dokumentenmappen.ps1 -WhatIf
.\Enable-Dokumentenmappen.ps1

# Schritt 2 – nur falls noch kein Dokumentenmappen-Inhaltstyp existiert
.\New-WissenMappeContentType.ps1 -WhatIf
.\New-WissenMappeContentType.ps1

# Schritt 3 – Analyse, Probelauf, Vollauf
.\Convert-FoldersToDocumentSets.ps1 -ReportOnly     # ändert nichts
.\Convert-FoldersToDocumentSets.ps1 -Limit 5        # fünf Ordner
.\Convert-FoldersToDocumentSets.ps1                 # alle

# Schritt 4 – geteilte Spalten befüllen
.\Set-MappeMetadata.ps1 -WhatIf
.\Set-MappeMetadata.ps1 -Limit 5
.\Set-MappeMetadata.ps1 -OnlyEmpty
```

**Schritt 2 ist bedingt.** Die `Wissen*`-Spalten sind in dieser Bibliothek
bereits angelegt und als geteilte Spalten konfiguriert. Existiert auch schon ein
Inhaltstyp auf Basis `Dokumentenmappe`, entfällt Schritt 2 — dann dessen Namen
an die beiden Folgeskripte durchgeben:

```powershell
.\Convert-FoldersToDocumentSets.ps1 -ContentTypeName "<vorhandener Inhaltstyp>"
```

Prüfen lässt sich das mit (Verbindung nach 3.1 muss stehen):

```powershell
Get-PnPContentType -List "Freigegebene Dokumente" |
    Where-Object { $_.Id.StringValue -like "0x0120D520*" } |
    Select-Object Name, @{n="Id";e={$_.Id.StringValue}}
```

Leere Ausgabe heisst: es gibt noch keinen Inhaltstyp auf Basis
`Dokumentenmappe` in der Bibliothek — dann Schritt 2 ausführen.

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

Die Spalten sind vorhanden und als geteilte Spalten konfiguriert — offen ist
nicht die Konfiguration, sondern das **Befüllen**. Genau das macht Schritt 4.

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

`New-WissenMappeContentType.ps1` setzt geteilte Spalten und Willkommensseite
über CSOM, weil PnP.PowerShell dafür kein Cmdlet hat. Das Skript ist idempotent
und überspringt, was schon konfiguriert ist; scheitert der CSOM-Zugriff, gibt es
die UI-Schritte aus und läuft weiter.

---

## 5. Schritt 4: die geteilten Spalten befüllen

Ein Wert pro Thema statt pro Dokument — SharePoint schreibt ihn anschliessend
selbst auf alle Dokumente der Mappe durch (asynchron, bei grossen Mappen einige
Minuten).

[`mappen-metadaten.csv`](mappen-metadaten.csv) enthält einen **Vorschlag je
Mappe**, abgeleitet aus Ordnername und Ablageort und vollständig gegen
`../termstore/rechtsgebiet.csv`, `rechtsordnung.csv` und `schlagworte.csv`
geprüft — keine erfundenen Terme:

| | Mappen |
|---|---:|
| mit `Rechtsgebiet` | 47 |
| mit `Rechtsordnung` | 49 |
| mit `Schlagworten` | 17 |
| bewusst leer gelassen | 8 |

Bewusst leer sind die heterogenen Sammelordner, bei denen ein einzelner Wert
falsch wäre: `04 Recht allgemein/Gesetze`, `Checklisten`, `Statistik und Daten`,
`Bewertung` (leer) sowie `05 eigene Literatur/03 Publikationen`, `04 Entwuerfe`,
`05 Hinweise`, `06 Diverse`. Leere Zelle heisst «nichts schreiben», nicht «Wert
löschen».

**Der Vorschlag ist zu prüfen, nicht zu glauben.** Er stammt aus Ordnernamen,
nicht aus dem Inhalt. Drei Stellen, die ich bewusst so und nicht anders
entschieden habe und die Sie anders sehen können:

- `04 Recht allgemein/SchKG CH` → `Verfahrensrecht`. Alternativ
  `Steuervollstreckung`, wenn der Ordner vor allem Steuerbezug hat.
- `02 Steuern DE/Kfz und Steuern` → `Direkte Steuern` (Annahme: Firmenwagen,
  1 %-Regelung). Bei Kfz-Steuer im engeren Sinn wäre `Indirekte Steuern` richtig.
- `02 Steuern DE/CO2_Emsssionshandel` → `Indirekte Steuern`; der gleichnamige
  Ordner unter `04 Recht allgemein` → `Verwaltungsrecht`, weil dort der
  ordnungsrechtliche Teil liegt.

Format der CSV (Semikolon, UTF-8 mit BOM), mehrere Werte je Zelle mit `` || ``:

```
Pfad;Rechtsgebiet;Rechtsordnung;Schlagworte
02 Steuern DE/Umsatzsteuer;Indirekte Steuern;Deutschland (DE);
01 Internationales Steuerrecht/DBA-DE-CH;Doppelbesteuerungsrecht;Deutschland (DE) || Schweiz (CH);
```

Terme gehen als Blatt-Label oder als vollständiger Termpfad. Der vollständige
Pfad ist nötig, wo ein Label mehrfach hängt — `Steuerverfahrensrecht` steht
sowohl unter `Steuerrecht` als auch unter `Verfahrensrecht`; die CSV benutzt
dort den Pfad. Unbekannte Terme werden gemeldet und übersprungen, nie geraten.

`-OnlyEmpty` lässt bereits gesetzte Werte unangetastet — für Nachläufe, nachdem
von Hand nachgeschärft wurde.

---

## 6. Danach

1. Ansicht **Alle Dokumente**: Spalte `Inhaltstyp` einblenden, um Mappen von
   Ordnern zu unterscheiden.
2. Prüfen, dass das Durchschreiben gegriffen hat: ein Dokument in einer
   befüllten Mappe öffnen, `Rechtsgebiet` muss gesetzt sein.
3. Erst danach `../termstore/Apply-WissenTaxonomy.ps1` für die
   dokumentspezifischen Felder (`Dokumenttyp`, Fundstelle) laufen lassen — die
   geteilten Spalten sind dann bereits gefüllt.

## 7. Dateien

| Datei | Inhalt |
|---|---|
| `_Common.ps1` | Verbindung, Bibliotheks-Auflösung, Content-Type-IDs |
| `Enable-Dokumentenmappen.ps1` | Schritt 1: Feature + Inhaltstypen-Verwaltung |
| `New-WissenMappeContentType.ps1` | Schritt 2: Inhaltstyp `Wissensmappe` (bedingt) |
| `Convert-FoldersToDocumentSets.ps1` | Schritt 3: Umwandlung, Protokoll, Rollback |
| `Set-MappeMetadata.ps1` | Schritt 4: geteilte Spalten befüllen |
| `mappen-kandidaten.csv` | Bestandsaufnahme Ebene 1–2 mit Empfehlung |
| `mappen-metadaten.csv` | Vorschlag Rechtsgebiet / Rechtsordnung / Schlagworte je Mappe |
| `dokumentenmappen-log.csv` | wird vom Konvertierungslauf geschrieben |
| `mappen-metadaten-log.csv` | wird vom Befüllungslauf geschrieben |
