# Ordner → Dokumentenmappen (Bibliothek Wissen)

**Site:** `https://obenhaus.sharepoint.com/sites/Wissen`
**Bibliothek:** `Freigegebene Dokumente`
**Inhaltstyp:** `Wissensmappe` (abgeleitet von `Dokumentenmappe`, `0x0120D520`)

Dokumentenmappen schliessen eine Lücke: das Thema wird ein Objekt mit eigenen
Metadaten, und diese Metadaten werden über *geteilte Spalten* auf die
enthaltenen Dokumente durchgeschrieben, statt nur im Ordnernamen zu stecken.

**Wichtiger Hinweis zu [`../termstore/`](../termstore/ARCHITECTURE.md):** Diese
Skripte und `ARCHITECTURE.md` sind für einen *anderen* Tenant geschrieben
(`transferpricingdocs.sharepoint.com`, siehe deren `$SiteUrl`/`$Tenant`), nicht
für `obenhaus.sharepoint.com`. Termstore und Websitespalten sind pro Tenant
getrennt — nichts davon existiert hier. Das Metadatenmodell in diesem Ordner
wurde live auf `obenhaus.sharepoint.com` erhoben (siehe Abschnitt 1a) und ist
komplett unabhängig vom `termstore`-Modell.

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

### 1a. Metadatenmodell: vorhanden, nicht das aus `../termstore/`

Auf `obenhaus.sharepoint.com` existiert weder eine `Wissen*`-Websitespalte noch
das im `termstore`-Ordner beschriebene Termset-Modell (`Rechtsgebiet`,
`Rechtsordnung`, `Dokumenttyp`, `Schlagworte`) — das ist für einen anderen
Tenant gebaut. Live geprüft (`Get-PnPTermGroup`, `Get-PnPField`) existiert
stattdessen ein **kanzleiweites** Modell, Gruppe `Steueranwaltskanzlei
Obenhaus`, das schon produktiv genutzt wird:

| Feld (intern) | Anzeige | Typ | Termset (Gruppe `Wissen`) | Werte |
|---|---|---|---|---|
| `Rechtsgebiet` | Themengebiet | einwertig, **Required** | `Themengebiet` | Steuerrecht, Öffentliches Recht, Zivilrecht, Strafrecht, Berufsrecht, IT, Recht allgemein, Soziale Sicherung, Project Management |
| `Rechtsordnung` | Rechtsordnung | mehrwertig | `Rechtsordnung` | Deutschland, Schweiz, Österreich, EU, OECD, Frankreich, Italien, Liechtenstein, Malta, Monaco |
| `Dossier-Stichwörter` | Schlagwörter | einwertig | `Dokument-Verschlagwortung` | Auftrag, Auswertung, Berechnung, Entwurf, Handakte, Liegenschaft, Memo, Stammakte, Steuer |

Die ersten beiden passen direkt und sind hier verwendet — flach statt
hierarchisch, aber inhaltlich richtig. Das dritte **nicht**: `Dossier-
Stichwörter` klassifiziert Aktendokumente (Auftrag, Berechnung, Entwurf,
Memo, Stammakte …), keine Sachthemen wie „TP – DEMPE" oder „Verfahren –
Selbstanzeige". Für Schlagworte gibt es auf diesem Tenant kein passendes
Termset — die Wissensmappe verzichtet deshalb bewusst darauf und trägt nur
`Rechtsgebiet` und `Rechtsordnung` als geteilte Felder. Details und die
Termsets, die sonst noch in der Gruppe `Wissen` existieren (`Publikationstyp`,
`Gericht`, `Publikationen`), stehen in Abschnitt 4.

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

**Weg A — über PnP.** Für PnP.PowerShell 3.3.0 verifizierte Signatur: das
Cmdlet hat **kein** `-Interactive`; der Standard-Parametersatz ist bereits der
interaktive Browser-Login, die Alternative ist `-DeviceLogin`.

```powershell
Register-PnPEntraIDAppForInteractiveLogin `
    -ApplicationName "PnP-Wissen-Migration" `
    -Tenant "obenhaus.onmicrosoft.com" `
    -SharePointDelegatePermissions "AllSites.FullControl" `
    -GraphDelegatePermissions "User.Read"
```

Der Aufruf legt die App an, öffnet die Zustimmung im Browser und gibt die
ClientId zurück. Bei anderen Modulversionen zuerst die Signatur prüfen, statt
Parameter zu raten:

```powershell
Get-Module PnP.PowerShell -ListAvailable | Select-Object Name, Version
Get-Command Register-PnPEntraIDAppForInteractiveLogin -Syntax
```

Wird ein Berechtigungswert nicht angenommen, die beiden
`*DelegatePermissions`-Parameter weglassen und die Berechtigungen nach Weg B
Schritt 5 im Portal nachtragen.

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

Danach immer mit der ClientId verbinden. **Die GUID muss wirklich eingesetzt
werden** — bleibt der Platzhalter stehen, endet der Browser-Login mit

```
AADSTS90013: Invalid input received from the user.
```

weil Entra den Platzhaltertext als `client_id` erhält. Ein `AADSTS90013` an
dieser Stelle ist also kein Berechtigungs-, sondern ein Tippproblem.

```powershell
$clientId = "11111111-2222-3333-4444-555555555555"   # GUID aus der Registrierung
Connect-PnPOnline -Url "https://obenhaus.sharepoint.com/sites/Wissen" `
                  -Interactive -ClientId $clientId -Tenant "obenhaus.onmicrosoft.com"
```

Nützliche Nebenbeobachtung zur Tenant-Angabe: kommt `AADSTS90013` (oder ein
anderer Fehler nach der Mandantenauflösung), war die `-Tenant`-Angabe richtig —
eine falsche Domäne bricht schon vorher mit `AADSTS90002 Tenant not found` ab.

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

### Bekannte Falle: `-Force` bei Enable/Disable-PnPFeature

**`-Force` bei `Enable-PnPFeature` / `Disable-PnPFeature` niemals manuell verwenden.**
In PnP.PowerShell ≥ 3.x ist der Parameter als veraltet markiert und löst intern
einen Entfernen-und-neu-Hinzufügen-Zyklus aus, statt ein reines Reaktivieren zu
sein.

Beobachtet auf einem Live-Tenant: das Feature Dokumentenmappen war laut
`Get-PnPFeature` aktiv. `Enable-PnPFeature -Scope Site -Identity <Id> -Force`
sollte die Provisionierung erzwingen, schlug aber ab mit

```
WARNING: Parameter 'Force' is obsolete.
Enable-PnPFeature: Feature with Id '...' is not installed in this farm,
and cannot be added to this scope.
```

und **deaktivierte dabei das zuvor aktive Feature**, statt es zu reaktivieren —
danach lieferte `Get-PnPFeature -Scope Site -Identity <Id>` keine Zeile mehr.
Die intern versuchte Entfernung gelang, das Neu-Hinzufügen scheiterte.

Fehlt der Basis-Inhaltstyp `0x0120D520`, obwohl das Feature aktiv ist (siehe
`Enable-Dokumentenmappen.ps1`), NICHT mit `-Force` reaktivieren. Stattdessen:

1. Ohne `-Force` versuchen — schadlos, da kein Entfernen-Zyklus ausgelöst wird,
   behebt auf dem beobachteten Tenant aber die eigentliche Ursache nicht:
   ```powershell
   Enable-PnPFeature -Scope Site -Identity 3bae86a2-776d-499d-9db8-fa4cd926e061
   ```
   Live beobachtet: **derselbe Fehler auch ohne `-Force`**
   (`... is not installed in this farm, and cannot be added to this scope.`).
   Das zeigt: die Blockade liegt nicht am Parameter `-Force`, sondern generell
   an der Reaktivierung dieser Feature-ID über PnP/CSOM auf diesem Tenant.
2. Über die native SharePoint-Oberfläche aktivieren — das umgeht CSOM
   vollständig und war der Weg, der auf dem betroffenen Tenant funktionierte:
   ```
   <Site-URL>/_layouts/15/ManageFeatures.aspx?Scope=Site
   ```
   Dort **Document Sets** suchen und **Activate** klicken. Fehlt die Zeile in
   der Liste komplett, ist es keine PnP-Eigenheit mehr, sondern vermutlich eine
   Tenant-Richtlinie — dann den SharePoint-Admin hinzuziehen.

`Enable-Dokumentenmappen.ps1` ruft `Enable-PnPFeature` seit diesem Befund ohne
`-Force` auf; da der Aufruf dort nur erfolgt, wenn das Feature laut
`Get-PnPFeature` noch **nicht** aktiv ist, ist ein Entfernen-Zyklus dort gar
nicht möglich.

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

**Schritt 2 ist bedingt.** `Rechtsgebiet` und `Rechtsordnung` sind
kanzleiweite Standardspalten und schon vorhanden (siehe Abschnitt 1a) — Schritt
2 bindet sie nur an den neuen Inhaltstyp. Existiert bereits ein Inhaltstyp auf
Basis `Dokumentenmappe` (aus einem früheren Lauf oder von anderswo), entfällt
Schritt 2 komplett — dann dessen Namen an die beiden Folgeskripte durchgeben:

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

Die Spalten sind vorhanden und kanzleiweit produktiv (siehe Abschnitt 1a) —
offen ist nicht die Konfiguration, sondern das **Anbinden** (Schritt 2) und
**Befüllen** (Schritt 4).

| Feld (intern) | Anzeige | Am Inhaltstyp | Geteilt (wird durchgeschrieben) |
|---|---|---|---|
| `Title` | Titel | ja | – (Willkommensseite) |
| `Rechtsgebiet` | Themengebiet | ja | **ja** |
| `Rechtsordnung` | Rechtsordnung | ja | **ja** |

Kein drittes geteiltes Feld für Schlagworte — Begründung in Abschnitt 1a. Auch
kein Dokumenttyp-Feld je Dokument: `Publikationstyp` (Rechtsprechung,
Verwaltungsvorschrift, Aufsatz, Gesetz, Kommentar/Handbuch, Skript, Notiz,
Nachricht, Meldungen/Anmerkungen) wäre inhaltlich das Gegenstück, ist aber noch
nicht an die Bibliothek `Freigegebene Dokumente` gebunden und nicht Teil dieser
Migration — dafür gibt es hier (anders als im `termstore`-Modell) noch kein
Skript.

`New-WissenMappeContentType.ps1` setzt geteilte Spalten und Willkommensseite
über CSOM, weil PnP.PowerShell dafür kein Cmdlet hat. Das Skript ist idempotent
und überspringt, was schon konfiguriert ist; scheitert der CSOM-Zugriff, gibt es
die UI-Schritte aus und läuft weiter.

**Live beobachtet: dieser CSOM-Zugriff scheitert unter PnP.PowerShell 3.3.0 auf
PowerShell 7** mit `Unable to find type
[Microsoft.Office.DocumentManagement.DocumentSets.DocumentSetTemplate]` — auch
der Fallback über `Microsoft.SharePoint.Client.DocumentManagement.dll` findet
nichts. Das ist kein transienter Fehler: die plattformübergreifende Version von
PnP.PowerShell bringt diese (historisch .NET-Framework-only) Assembly
offenbar gar nicht mit. Erneutes Ausführen behebt das nicht — direkt die
UI-Schritte gehen, die das Skript ausgibt.

**Dieser Schritt ist nicht optional.** Ohne ihn wird `Rechtsgebiet`/
`Rechtsordnung` an der Mappe gesetzt, aber nicht auf die enthaltenen Dokumente
durchgeschrieben — das ist der ganze Zweck dieser Migration. Erledigen, bevor
Schritt 4 (`Set-MappeMetadata.ps1`) läuft, sonst wirkt Schritt 4 wie erfolgreich,
ohne dass die Dokumente etwas davon sehen.

Weitere Termsets in der Gruppe `Wissen`, aktuell ungenutzt, aber möglicher
Ausgangspunkt für Folgearbeit:

| Termset | Werte |
|---|---|
| `Gericht` | Gerichte Deutschland, Gerichte Europa, Gerichte Schweiz (bislang nur die drei Oberkategorien, keine einzelnen Gerichte) |
| `Publikationen` | ungeprüft, welchem Zweck es dient |
| `Publikationstyp` | siehe oben — Kandidat für ein künftiges Dokumenttyp-Feld |

---

## 5. Schritt 4: die geteilten Spalten befüllen

Ein Wert pro Thema statt pro Dokument — SharePoint schreibt ihn anschliessend
selbst auf alle Dokumente der Mappe durch (asynchron, bei grossen Mappen einige
Minuten).

[`mappen-metadaten.csv`](mappen-metadaten.csv) enthält einen **Vorschlag je
Mappe**, abgeleitet aus Ordnername und Ablageort und vollständig gegen die
echten, live erhobenen Termsets `Themengebiet` und `Rechtsordnung` geprüft
(Abschnitt 1a) — keine erfundenen Terme, keine Terme aus dem falschen
`termstore`-Modell:

| | Mappen |
|---|---:|
| mit `Rechtsgebiet` | 59 von 59 — Pflichtfeld, jede Mappe bekommt einen Wert |
| mit `Rechtsordnung` | 46 von 59 |
| `Rechtsordnung` leer gelassen | 13 |

`Rechtsgebiet` ist am Feld selbst `Required="TRUE"` — deshalb bekommt jede
Mappe einen Wert, notfalls den Auffangbegriff `Recht allgemein` für
heterogene Sammelordner (`Checklisten`, `Gesetze`, `Statistik und Daten`,
`Compliance`, `03 Publikationen`, `04 Entwuerfe`, `05 Hinweise`, `06 Diverse`,
das zweite `Bewertung` unter `04 Recht allgemein`). `Rechtsordnung` ist nicht
Pflicht und bleibt dort leer, wo kein Land eindeutig zutrifft (z. B.
`Steuerwissenschaften`, `Vertragsrecht`, `01 Wassermeyer DBA`). Leere Zelle
heisst «nichts schreiben», nicht «Wert löschen».

**Themengebiet ist flach und grob** (nur neun Werte, keine Unterkategorien wie
„Verrechnungspreise" oder „Direkte Steuern") — fast jede Mappe zu
internationalem oder deutschem/schweizerischem Steuerrecht bekommt schlicht
`Steuerrecht`. Das ist die reale Granularität dieses Tenants, keine
Vereinfachung meinerseits.

**Der Vorschlag ist zu prüfen, nicht zu glauben.** Er stammt aus Ordnernamen,
nicht aus dem Inhalt. Judgment Calls, die Sie anders sehen können:

- `04 Recht allgemein/SchKG CH` → `Zivilrecht` (Schuldbetreibung/Konkurs als
  Zivilverfahrensrecht). Kein `Verfahrensrecht`-Themengebiet vorhanden, das
  näher läge.
- `04 Recht allgemein/Selbstanzeige` → `Strafrecht` (Steuerstrafrecht), nicht
  `Steuerrecht`.
- `05 eigene Literatur/02 SchwarzArbG-Komm` → `Strafrecht` (Sanktionsnorm),
  könnte auch `Soziale Sicherung` sein.
- `01 Internationales Steuerrecht/Zypern` → `Rechtsordnung` bleibt auf `EU`,
  weil kein Zypern-Term im Termset existiert.
- Die zwei gleichnamigen `CO2_Emsssionshandel`-Ordner erhalten unterschiedliche
  Werte: unter `02 Steuern DE` → `Steuerrecht` (Abgabenperspektive), unter
  `04 Recht allgemein` → `Öffentliches Recht` (Regulierungsperspektive).

Format der CSV (Semikolon, UTF-8 mit BOM), Rechtsordnung mehrwertig mit `` || ``:

```
Pfad;Rechtsgebiet;Rechtsordnung
02 Steuern DE/Umsatzsteuer;Steuerrecht;Deutschland
01 Internationales Steuerrecht/DBA-DE-CH;Steuerrecht;Deutschland || Schweiz
```

Beide Termsets sind flach — ein Blatt-Label reicht, ein vollständiger Termpfad
ist hier (anders als im `termstore`-Modell) nie nötig. Unbekannte Terme werden
gemeldet und übersprungen, nie geraten.

`-OnlyEmpty` lässt bereits gesetzte Werte unangetastet — für Nachläufe, nachdem
von Hand nachgeschärft wurde.

---

## 6. Danach

1. Ansicht **Alle Dokumente**: Spalte `Inhaltstyp` einblenden, um Mappen von
   Ordnern zu unterscheiden.
2. Prüfen, dass das Durchschreiben gegriffen hat: ein Dokument in einer
   befüllten Mappe öffnen, `Themengebiet` muss gesetzt sein.
3. Optional, als Folgearbeit: `Publikationstyp` an die Bibliothek binden und
   je Dokument befüllen (Rechtsprechung, Verwaltungsvorschrift, Aufsatz, …) —
   dafür existiert in diesem Ordner noch kein Skript.

## 7. Dateien

| Datei | Inhalt |
|---|---|
| `_Common.ps1` | Verbindung, Bibliotheks-Auflösung, Content-Type-IDs |
| `Enable-Dokumentenmappen.ps1` | Schritt 1: Feature + Inhaltstypen-Verwaltung |
| `New-WissenMappeContentType.ps1` | Schritt 2: Inhaltstyp `Wissensmappe` (bedingt), bindet `Rechtsgebiet`/`Rechtsordnung` |
| `Convert-FoldersToDocumentSets.ps1` | Schritt 3: Umwandlung, Protokoll, Rollback |
| `Set-MappeMetadata.ps1` | Schritt 4: `Rechtsgebiet`/`Rechtsordnung` je Mappe befüllen |
| `mappen-kandidaten.csv` | Bestandsaufnahme Ebene 1–2 mit Empfehlung |
| `mappen-metadaten.csv` | Vorschlag Rechtsgebiet (Themengebiet) / Rechtsordnung je Mappe |
| `dokumentenmappen-log.csv` | wird vom Konvertierungslauf geschrieben |
| `mappen-metadaten-log.csv` | wird vom Befüllungslauf geschrieben |
