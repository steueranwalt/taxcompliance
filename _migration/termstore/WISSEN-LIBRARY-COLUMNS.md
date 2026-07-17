# Bibliothek Dokumente – Wissen-Metadaten

**Site:** `https://transferpricingdocs.sharepoint.com/sites/wissen`  
**Bibliothek:** `Shared Documents` (Anzeigename **Dokumente**)  
**Termstore-Gruppe:** `Wissen`  
**Spaltengruppe:** `Wissen Metadaten`

---

## 1. Taxonomie-Spalten (bereits angelegt)

| Anzeigename | Interner Name | Termset | Mehrfach |
|---|---|---|---|
| Rechtsgebiet | `WissenRechtsgebiet` | Rechtsgebiet | Ja |
| Rechtsordnung | `WissenRechtsordnung` | Rechtsordnung | Ja |
| Dokumenttyp | `WissenDokumenttyp` | Dokumenttyp | Nein |
| Schlagworte | `WissenSchlagworte` | Schlagworte | Ja |

Skript: `Add-WissenLibraryColumns.ps1`

---

## 2. Zusatzspalten (Jahr / Autor / Fundstelle)

| Anzeigename | Interner Name | Typ | Gilt für |
|---|---|---|---|
| Jahr | `WissenJahr` | Zahl | **alle** Dokumente |
| Autor | `WissenAutor` | Text | **alle** Dokumente |
| Werk | `WissenWerk` | Text | Fundstellen-Typen* |
| Seite | `WissenSeite` | Text | Fundstellen-Typen* |
| Fundstelle | `WissenFundstelle` | Mehrzeilig | optional, vollständige Zitation |
| Titel | `WissenTitel` | Text | Internes Memo, Fachaufsatz |
| Aktenzeichen | `WissenAktenzeichen` | Text | Urteil / Rechtsprechung, Verwaltungsanweisung |

\*Fundstellen-Typen (Wert in **Dokumenttyp**):

- Verwaltungsanweisung  
- Kommentar (Werk)  
- Fachaufsatz  
- Urteil / Rechtsprechung  
- Gesetzesmaterialien  

**Fundstelle strukturiert** = `Werk` + `Jahr` + `Seite`  
(Beispiel: *DStR* / *2024* / *143*)

`Autor` ist **nicht** der SharePoint-Ersteller (Created By), sondern Verfasser/Herausgeber.

### Anlegen

```powershell
cd "$env:TEMP\wissen-termstore"

# Skript laden
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/steueranwalt/taxcompliance/cursor/onenote-md-export-06a0/_migration/termstore/Add-WissenExtraColumns.ps1" -OutFile ".\Add-WissenExtraColumns.ps1"

Connect-PnPOnline -Url "https://transferpricingdocs.sharepoint.com/sites/wissen" -Interactive -ClientId "c77bfeb7-7624-497f-85d7-e509c5ec9dbc" -Tenant "transferpricingdocs.onmicrosoft.com"

.\Add-WissenExtraColumns.ps1 -LibraryName "Shared Documents"
```

Voraussetzung: `DenyAddAndCustomizePages` auf der Site = **Disabled** (Custom Script erlaubt).

---

## 3. Nutzungshinweis (Dokumenttyp → Felder)

SharePoint zeigt Spalten technisch immer; die **inhaltliche Pflicht** hängt vom Dokumenttyp ab:

| Dokumenttyp | Jahr | Autor | Titel | Aktenzeichen | Werk | Seite | Fundstelle (Text) |
|---|---|---|---|---|---|---|---|
| Urteil / Rechtsprechung | ja | ja | – | ja | ja | ja | optional |
| Verwaltungsanweisung | ja | ja | – | ja | ja | ja | optional |
| Kommentar (Werk) | ja | ja | – | – | ja | ja | optional |
| Fachaufsatz | ja | ja | ja | – | ja | ja | optional |
| Gesetzesmaterialien | ja | ja | – | – | ja | ja | optional |
| Merkblatt / Leitfaden | ja | ja | – | – | – | – | – |
| Arbeitshilfe / Checkliste | ja | ja | – | – | – | – | – |
| Präsentation | ja | ja | – | – | – | – | – |
| Vertrag / Vereinbarung | ja | ja | – | – | – | – | – |
| Internes Memo | ja | ja | ja | – | – | – | – |
| Datensatz / Grounds | ja | ja | – | – | – | – | – |
| Gesetz / Verordnung | ja | ja | – | – | – | – | – |

Bedingte Formularanzeige (Felder nur bei Fundstellen-Typen sichtbar) ist ein Folgeschritt (Power Apps oder JSON-Form).

---

## 4. Nach dem Anlegen

1. Ansicht **Alle Dokumente** → Spalten einblenden: Jahr, Autor, Titel, Aktenzeichen, Werk, Seite (Fundstelle optional)
2. Optional indizieren: Jahr, Dokumenttyp
3. Filteransicht z. B. „Urteile“: Dokumenttyp = Urteil / Rechtsprechung

---

## 5. Metadaten aus Dateien extrahieren und befüllen

### Extraktion (lokal / Repo)

```powershell
# Python 3
cd <repo>
python _migration\termstore\extract_wissen_metadata.py
# schreibt: _migration\termstore\wissen-metadata-extract.csv
```

Aus Dateiname + Dateikopf werden u. a. erkannt:
- Fundstelle `NJW 2024, 2092` / `DStR 2018, 2284`
- Autor aus Beck-Tabelle `TitelFundstelle`
- **Titel** (Fachaufsatz, Internes Memo) aus Überschrift / Beck-Tabelle
- **Aktenzeichen** (Urteil, Verwaltungsanweisung) aus BFH/FG-Zeilen, BMF-Schreiben
- Dokumenttyp / Rechtsordnung / Rechtsgebiet heuristisch aus Pfad

### Auf SharePoint schreiben

```powershell
cd "$env:TEMP\wissen-termstore"
# CSV + Apply-Skript vom Branch laden
$base = "https://raw.githubusercontent.com/steueranwalt/taxcompliance/cursor/onenote-md-export-06a0/_migration/termstore"
Invoke-WebRequest "$base/Apply-WissenMetadata.ps1" -OutFile .\Apply-WissenMetadata.ps1
Invoke-WebRequest "$base/wissen-metadata-extract.csv" -OutFile .\wissen-metadata-extract.csv

Connect-PnPOnline -Url "https://transferpricingdocs.sharepoint.com/sites/wissen" -Interactive -ClientId "c77bfeb7-7624-497f-85d7-e509c5ec9dbc" -Tenant "transferpricingdocs.onmicrosoft.com"

# Test mit 20 Dateien:
.\Apply-WissenMetadata.ps1 -CsvPath .\wissen-metadata-extract.csv -LibraryName "Shared Documents" -Limit 20

# Vollauf (nur leere Felder überschreiben nicht, wenn schon gesetzt: -OnlyEmpty)
.\Apply-WissenMetadata.ps1 -CsvPath .\wissen-metadata-extract.csv -LibraryName "Shared Documents" -OnlyEmpty
```
