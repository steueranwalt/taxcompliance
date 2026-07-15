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

## 1. Rechtsgebiet

### Öffentliches Recht → Steuerrecht (CH)
Wie bisher (DBSt, Kantonal, MWST, VSt, Stempel, Grundstückgewinn, Int. Steuerrecht CH, Verfahren CH, Steuerstrafrecht CH).

### Öffentliches Recht → Steuerrecht (DE)  ← neu
```
Steuerrecht (DE)
├── Einkommensteuer (EStG)
├── Körperschaftsteuer (KStG)
├── Gewerbesteuer (GewStG)
├── Umsatzsteuer (UStG)
├── Abgabenordnung / Verfahren (AO)
│     └── Außenprüfung / Betriebsprüfung
├── Nebenleistungen / Säumnis
├── Zollrecht (DE / Unionszollkodex)
├── Internationales Steuerrecht (DE)
│     ├── DBA / Abkommensrecht
│     └── Außensteuergesetz (AStG)
└── Steuerstrafrecht (DE)
```

### Öffentliches Recht → Internationales Steuerrecht → Verrechnungspreise  ← neu
Fachbereich Transfer Pricing als **eigener Ast** (nicht nur Schlagwort):

```
Internationales Steuerrecht
├── Verrechnungspreise
│     ├── Methoden / Arm’s Length
│     ├── Funktions- und Risikoanalyse
│     ├── Dokumentation (Master / Local / CbCR)
│     ├── Vergleichbarkeitsanalyse
│     ├── ICAs / Kostenumlagen
│     ├── Korrekturen / Secondary Adjustments
│     ├── Vorabverständigung (APA / MAP)
│     └── Nahestehende Personen / Beteiligung
├── Betriebsstättengewinnabgrenzung
└── Amtshilfe / Informationsaustausch (AIA, DAC6/7/8)
```

> Schlagworte `TP – …` bleiben für Querschnittsthemen (z. B. `TP – DEMPE`, `TP – Cost Plus`).  
> Der **Rechtsgebiet**-Ast steuert Ablage und Primärfilter.

### Übrige Äste
Privatrecht, Strafrecht, Verfahrensrecht, Verwaltungs-/Verfassungs-/Sozialversicherungs-/Asylrecht – unverändert.

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
| `Allgemein –` | Rest |

Listen: siehe `schlagworte.csv` (ersetzbar durch eure fertigen Import-CSVs).

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
| `Import-WissenTermstore.ps1` | Verbindung + Import + Labels |
| `ARCHITECTURE.md` | Dieses Dokument |

---

## Import-Reihenfolge

1. PnP PowerShell ≥ 2.x, Site-Admin oder Term Store Admin auf dem Tenant  
2. `Connect-PnPOnline` zur Site `https://transferpricingdocs.sharepoint.com/sites/wissen`  
3. `.\Import-WissenTermstore.ps1`  
4. In Bibliothek **Wissen**: Managed Metadata-Spalten anlegen und an Termsets binden  
5. Optional: Default-Werte / Content Types

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
