# Termstore Wissen – Architektur (Soll)

**Tenant:** `transferpricingdocs.sharepoint.com`  
**Gruppe:** `Wissen`  
**Sprachen:** DE (Standard, LCID 1031), EN (1033), FR (1036)

---

## Zielbild

```
Terminologiespeicher (transferpricingdocs.sharepoint.com)
└── Gruppe: Wissen
      ├── Termsatz: Rechtsgebiet        (hierarchisch, bis 4 Ebenen)
      ├── Termsatz: Rechtsordnung       (hierarchisch, 2 Ebenen)
      ├── Termsatz: Schlagworte         (flach, Präfix-Konvention)
      └── Termsatz: Dokumenttyp         (flach, kontrolliertes Vokabular)
```

**Trennungsregel**

| Facette | Zweck | Mehrfachwahl |
|---|---|---|
| Rechtsgebiet | *Wovon* handelt das Dokument? | ja |
| Rechtsordnung | *Welches Recht* gilt / welcher Raum? | ja |
| Dokumenttyp | *Welche Art* von Quelle? | nein (ideal 1) |
| Schlagworte | Feintags, Querschnittsthemen | ja |

Ordnerstruktur in der Bibliothek bleibt navigativ; Tags sind die abfragbare Facette (gefilterte Ansichten, Suche, KI-Wiki).

---

## 1. Rechtsgebiet (bereinigt)

**Leitregel:** Im Termsatz **Rechtsgebiet** stehen nur Fachgebiete.  
Keine Länderkürzel (CH/DE) und keine Einzelnormen (z. B. AO, FGO, AStG).

```
Öffentliches Recht
├── Verwaltungsrecht
├── Verfassungsrecht
├── Sozialversicherungsrecht
├── Ausländer- und Asylrecht
├── Datenschutz
└── Steuerrecht
      ├── Direkte Steuern
      ├── Indirekte Steuern
      ├── Steuerverfahrensrecht
      ├── Steuervollstreckung
      ├── Steuerstrafrecht
      └── Internationales Steuerrecht
            ├── Doppelbesteuerungsrecht
            ├── Verrechnungspreise
            └── Amtshilfe und Informationsaustausch

Privatrecht
Strafrecht
Verfahrensrecht
├── Steuerverfahrensrecht
├── Gerichtsverfahren
└── Rechtsschutz
```

Abgrenzung:
- **Rechtsordnung** trägt den Länder-/Rechtsraumbezug (CH/DE/EU/OECD usw.).
- **Rechtsgebiet** bleibt fachlich und systematisch stabil.
- Gesetzes-/Normbezug (AO, FGO, AStG, EStG …) gehört ggf. in Schlagworte oder Metadatenfelder, nicht ins Rechtsgebiet.

---

## 2. Rechtsordnung

```
Schweiz (CH) → Bund | Kantonal
Deutschland (DE) → Bundesrecht | Landesrecht
Österreich (AT)
Europäische Union (EU)
OECD
International / Bilateral
```

---

## 3. Schlagworte (flach)

Präfix-Konvention (Sortierung + Autocomplete):

| Präfix | Rolle |
|---|---|
| `Verfassung –` | Verfassungsfragen |
| `Verfahren –` | Verfahrens-/Prozess-Stichworte |
| `TP –` | Transfer-Pricing-Feintags |
| `Tax Compliance –` | Tax-CMS, GoBD, Kontrollen, Mitteilungspflichten |
| `Allgemein –` | Rest |

Listen: siehe `schlagworte.csv`.

## 3b. Synonyme (neu)

Für Suche/Autocomplete können Synonyme pro Sprache separat gepflegt werden (DE/EN/FR), ohne den Preferred Label zu ändern.  
Vorlage: `synonyms-de-en-fr.csv` (wird aktuell dokumentiert, nicht automatisch importiert).

---

## 4. Dokumenttyp  ← neu

Kontrolliertes Vokabular (ersetzt „nur Ordnername“):

| Term (DE) | EN | FR |
|---|---|---|
| Urteil / Rechtsprechung | Case law / Judgment | Jurisprudence |
| Verwaltungsanweisung | Administrative guidance | Instruction administrative |
| Gesetz / Verordnung | Statute / Regulation | Loi / Ordonnance |
| Gesetzesmaterialien | Legislative materials | Travaux préparatoires |
| Fachaufsatz | Article / Commentary piece | Article de doctrine |
| Kommentar (Werk) | Treatise / Commentary | Commentaire |
| Merkblatt / Leitfaden | Guidance note | Guide / Fiche |
| Arbeitshilfe / Checkliste | Checklist / Work aid | Aide-mémoire |
| Präsentation | Presentation | Présentation |
| Vertrag / Vereinbarung | Contract / Agreement | Contrat / Accord |
| Internes Memo | Internal memo | Note interne |
| Datensatz / Grounds | Dataset / Grounds | Jeu de données |

---

## Dateien in diesem Ordner

| Datei | Inhalt |
|---|---|
| `rechtsgebiet.csv` | Hierarchie für Import-PnPTaxonomy |
| `rechtsordnung.csv` | Hierarchie |
| `schlagworte.csv` | Flache Terme |
| `dokumenttyp.csv` | Flache Terme |
| `labels-de-en-fr.csv` | Mehrsprachige Labels (`TermSet;TermPath;DE;EN;FR`, Pfad mit `\|`) |
| `synonyms-de-en-fr.csv` | Synonym-Vorlage (`TermSet;TermPath;Language;Synonym`) |
| `Import-WissenTermstore.ps1` | Verbindung + Import + Labels |
| `Apply-Termstore.ps1` | Produktions-Runner (Retry, Delta-Import, optional Synonyme) |
| `Add-WissenLibraryColumns.ps1` | Managed-Metadata-Spalten in Bibliothek Wissen |
| `WISSEN-LIBRARY-COLUMNS.md` | Anleitung Spalten (PnP + UI) |
| `ARCHITECTURE.md` | Dieses Dokument |

---

## Import-Reihenfolge (read-first)

1. PnP PowerShell ≥ 2.x, Site-Admin oder Term Store Admin auf dem Tenant  
2. `Connect-PnPOnline` zur Site `https://transferpricingdocs.sharepoint.com/sites/wissen`  
3. `.\Import-WissenTermstore.ps1` (erstellt automatisch einen Snapshot in `%TEMP%/termstore-snapshot-*`)  
4. Das Skript importiert standardmäßig **additiv** nur fehlende Terme (kein Voll-Overwrite).  
5. In Bibliothek **Wissen**: Managed Metadata-Spalten anlegen und an Termsets binden.  
6. Optional: Labels (EN/FR) und danach Synonyme pflegen.

### Bibliotheksspalten (nach Termstore)

```powershell
cd _migration\termstore
.\Add-WissenLibraryColumns.ps1
```

Details: [`WISSEN-LIBRARY-COLUMNS.md`](WISSEN-LIBRARY-COLUMNS.md)

### Typische Verbindungsprobleme

| Symptom | Fix |
|---|---|
| `AADSTS…` / Login bricht ab | `-Interactive` statt `-DeviceLogin`; aktuelles PnP-Modul |
| `Access denied` auf Term Store | Rolle **Term Store Administrator** (SharePoint Admin Center → Content services → Term store) |
| Site-URL 404 | Site relative URL prüfen (`/sites/wissen` vs. `/sites/Wissen`) |
| Firewall / Conditional Access | Device Code vom gleichen Netzwerk / `-Interactive` im Browser mit MFA |
| App-only ohne Consent | Delegiert importieren **oder** App mit `TermStore.ReadWrite.All` + Admin Consent |

```powershell
# Empfohlen (interaktiv, MFA-freundlich)
Connect-PnPOnline -Url "https://transferpricingdocs.sharepoint.com/sites/wissen" -Interactive
```
