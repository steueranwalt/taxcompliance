# Migration: SharePoint Wissen → neuer Tenant

Dieses Verzeichnis enthält die Migrationsblaupause für den Umzug der SharePoint-Site **Wissen** (`obenhaus.sharepoint.com/sites/Wissen`) auf einen neuen Tenant.

## Dateien

| Datei | Inhalt |
|---|---|
| [`wissen-site-strukturkarte.md`](wissen-site-strukturkarte.md) | Vollständiger Ordnerbaum der aktuellen Wissen-Site mit allen bekannten Dokumenten |
| [`mapping-sp-zu-repo.md`](mapping-sp-zu-repo.md) | Zuordnung: welche SP-Ordner welchem Repo-Pfad entsprechen |

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
