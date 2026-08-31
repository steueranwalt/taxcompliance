# Migration: SharePoint Wissen → neuer Tenant

Dieses Verzeichnis enthält die Migrationsblaupause für den Umzug der SharePoint-Site **Wissen** (`obenhaus.sharepoint.com/sites/Wissen`) auf einen neuen Tenant.

## Dateien

| Datei | Inhalt |
|---|---|
| [`wissen-site-strukturkarte.md`](wissen-site-strukturkarte.md) | Vollständiger Ordnerbaum der aktuellen Wissen-Site mit allen bekannten Dokumenten |
| [`mapping-sp-zu-repo.md`](mapping-sp-zu-repo.md) | Zuordnung: welche SP-Ordner welchem Repo-Pfad entsprechen |
| [`onenote_export.py`](onenote_export.py) | Exportiert das OneNote-Notizbuch `Diverses.one` nach Markdown |
| [`termstore/`](termstore/) | Termstore-Gruppe **Wissen** (CSVs + PnP-Import, read-first/additiv): Rechtsgebiet, Rechtsordnung, Schlagworte, Dokumenttyp |
| [`.env.example`](.env.example) | Vorlage für Entra-App-Zugangsdaten |

## Termstore (transferpricingdocs)

Architektur und Import: [`termstore/ARCHITECTURE.md`](termstore/ARCHITECTURE.md).

```powershell
cd _migration\termstore
Connect-PnPOnline -Url "https://transferpricingdocs.sharepoint.com/sites/wissen" -Interactive
.\Import-WissenTermstore.ps1
```

Hinweis: `Import-WissenTermstore.ps1` erstellt vor dem Import automatisch einen Snapshot (`%TEMP%\termstore-snapshot-*`) und importiert standardmäßig nur fehlende Terme (additiv).

Produktionslauf mit Retry/Delta/Synonymen:

```powershell
cd _migration\termstore
.\Apply-Termstore.ps1 -Connect -Interactive -ClientId "<APP-ID>" -Tenant "<TENANT>.onmicrosoft.com" -ApplySynonyms
```

Managed-Metadata-Spalten in Bibliothek Dokumente:

```powershell
cd _migration\termstore
.\Add-WissenLibraryColumns.ps1 -LibraryName "Shared Documents"
.\Add-WissenExtraColumns.ps1 -LibraryName "Shared Documents"
```

Siehe [`termstore/WISSEN-LIBRARY-COLUMNS.md`](termstore/WISSEN-LIBRARY-COLUMNS.md).

## OneNote → Markdown

Das Skript `onenote_export.py` liest das SharePoint-Notizbuch **Diverses.one** und legt im Repo unter `Diverses/` je **Abschnitt** einen Ordner an; jede Seite wird als `README.md` gespeichert.

### Entra-App (erforderlich)

In der App-Registrierung unter **API-Berechtigungen → Microsoft Graph**:

| Berechtigung | Typ | Zweck |
|---|---|---|
| `Notes.Read.All` | Delegiert **oder** Anwendung | OneNote-Inhalte lesen |
| `Sites.Read.All` | Delegiert **oder** Anwendung | SharePoint-Site `Wissen` auflösen |

**Admin-Einwilligung** erteilen.

### Variante A: Client Secret (empfohlen für Cloud Agent)

1. `_migration/.env.example` nach `_migration/.env` kopieren
2. Werte eintragen: `ENTRA_TENANT_ID`, `ENTRA_CLIENT_ID`, `ENTRA_CLIENT_SECRET`
3. Export starten:

```bash
python3 _migration/onenote_export.py
```

### Variante B: Device Code (interaktiv)

Ohne Client Secret startet das Skript den Device-Code-Flow. Den angezeigten Code unter https://login.microsoft.com/device eingeben.

## Grundprinzip

```
SharePoint Wissen (alt)  →  GitHub Repo (Index + Reintext)
                          +  SharePoint Wissen (neu, neuer Tenant)
```

- **Binärdokumente** (PDF, DOCX, XLSX): Direktmigration SP-alt → SP-neu via SharePoint Migration Tool oder PnP PowerShell
- **Reintext** (Gesetzestexte, Checklisten, Markdown): ins Repo, SP-neu verlinkt darauf
- **Strukturdefinition**: das Repo definiert den Soll-Ordnerbaum für SP-neu

## Status

- [x] Strukturkarte SP-alt erstellt (2026-05-26)
- [ ] Neuer Tenant eingerichtet
- [ ] SP-neu Ordnerstruktur angelegt
- [ ] Dokumente migriert
- [ ] Links/Verweise geprüft
