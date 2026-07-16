# Bibliothek Wissen – Managed Metadata Spalten

**Site:** `https://transferpricingdocs.sharepoint.com/sites/wissen`  
**Termstore-Gruppe:** `Wissen`

---

## Ziel-Spalten

| Anzeigename | Interner Name | Termset | Mehrfach |
|---|---|---|---|
| Rechtsgebiet | `WissenRechtsgebiet` | Rechtsgebiet | Ja |
| Rechtsordnung | `WissenRechtsordnung` | Rechtsordnung | Ja |
| Dokumenttyp | `WissenDokumenttyp` | Dokumenttyp | Nein |
| Schlagworte | `WissenSchlagworte` | Schlagworte | Ja |

**Spaltengruppe:** `Wissen Metadaten`

---

## Variante A – automatisch (PnP, empfohlen)

```powershell
cd "$env:TEMP\wissen-termstore"
# oder: cd <repo>\_migration\termstore

$clientId = "c77bfeb7-7624-497f-85d7-e509c5ec9dbc"
$tenant   = "transferpricingdocs.onmicrosoft.com"

Connect-PnPOnline -Url "https://transferpricingdocs.sharepoint.com/sites/wissen" -Interactive -ClientId $clientId -Tenant $tenant

.\Add-WissenLibraryColumns.ps1
```

Falls die Bibliothek nicht `Wissen` heißt, sondern die Standard-Dokumentenbibliothek:

```powershell
.\Add-WissenLibraryColumns.ps1 -LibraryName "Freigegebene Dokumente"
```

Dry-run:

```powershell
.\Add-WissenLibraryColumns.ps1 -WhatIf
```

---

## Variante B – manuell (UI)

1. Site **Wissen** → Bibliothek **Wissen** (oder **Freigegebene Dokumente**)
2. **Bibliothekseinstellungen** → **Spalten erstellen**
3. Typ: **Verwaltete Metadaten**
4. Termset jeweils aus Gruppe **Wissen** wählen
5. Mehrfachauswahl nur bei Rechtsgebiet, Rechtsordnung, Schlagworte

---

## Nach dem Anlegen

1. **Standardansicht** erweitern (alle 4 Spalten sichtbar)
2. Optional gefilterte Ansichten:
   - `Nach Rechtsgebiet`
   - `Nach Dokumenttyp`
   - `TP-Inhalte` (Rechtsgebiet enthält Verrechnungspreise)
3. Spalten **indizieren** (Bibliothekseinstellungen → indizierte Spalten), wenn Filter/Suche darauf basieren soll

---

## Berechtigungen (Entra App)

Delegated Graph (bereits für Termstore genutzt):

- `TermStore.ReadWrite.All`
- `Sites.ReadWrite.All`

Zusätzlich SharePoint: Listenverwaltung auf der Zielbibliothek.

---

## Abgrenzung Termstore vs. Bibliothek

| Ebene | Zweck |
|---|---|
| Termstore | Kontrolliertes Vokabular (Taxonomie) |
| Bibliotheksspalten | Metadaten an jedem Dokument |
| Ordnerstruktur | Navigation/Ablage (bleibt bestehen) |

Dokumente werden über **Rechtsgebiet + Rechtsordnung + Dokumenttyp + Schlagworte** auffindbar, unabhängig vom Ordnerpfad.
