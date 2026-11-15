# Bestandsregister (Phase 0)

**Stand der Inventur:** 04.11.2026  
**Untersuchtes Repo:** `steueranwalt/taxcompliance`, Branch `main`, Commit `3499982`  
**Methode:** vollständiger Verzeichnisbaum, gezielte Lektüre der kuratierten Fachdateien, GitHub-API, Graph-Tokenprobe, Cloud-Agent-Liste. Keine flächendeckende OneNote-Seiteninventur.

Jeder Befund ist auf eine Datei, einen Commit, eine Schnittstelle oder einen überprüften Nicht-Zugang zurückführbar.

## 1. Repository und Git

| Prüfpunkt | Befund | Beleg |
|---|---|---|
| Remote | `https://github.com/steueranwalt/taxcompliance` | `git remote -v` |
| Branch zum Inventurzeitpunkt | `main` = `origin/main` = `3499982` | `git fetch origin main`; `git log` |
| Letzter Commit | SharePoint-Forms Grundregel, 31.10.2026, PR #24 | Commit `3499982` |
| Offene Issues | keine | GitHub `list_issues` + `gh issue list` |
| Offene PRs (fremd) | #22 Erfassungs-Chat; #18 Substanz-Holding-KG | `gh pr list` |
| `docs/implementation/` | fehlte vor dieser Phase | Verzeichnisbaum 04.11.2026 |
| `AGENTS.md` | beschreibt das Repo als reine Markdown-Wissensbasis ohne Tests | `AGENTS.md` |

## 2. Agent-Regeln und vorhandene Anweisungen

| Datei | Rolle |
|---|---|
| `AGENTS.md` | Cloud-Agent: keine Abhängigkeiten, kein Dev-Server, Markdown-Preview |
| `.mcp.json` | OneNote-MCP gegen `obenhaus.sharepoint.com/sites/Wissen`; erwartet `AZURE_*` |
| `_migration/.env.example` | Entra-Vorlage für Graph/OneNote; `.env` ist gitignored |
| `schema/legal-knowledge-graph.md` | verbindliches Metadatenmodell (Stand 29.09.2026) |
| `DE/AO/Einheitliches-Datenmodell-steuerliche-Erfassung-DE-Auslandsbezug.md` | Fall-/Personenmodell für ELSTER-Erfassung |
| `DE/AO/sharepoint-forms/README.md` | SharePoint-Listen und Forms |

Kein `.cursor/`-Ordner, keine committed Cursor-Skills.

## 3. Verzeichnisstruktur (Ist)

```
Arbeitsmaterialien/     Checklisten, Muster, Rechtsprechung, Schulung, StBVV-32
CH/                     DBG, Handelsregister, Kantone, MWSTG, StG, StHG, VStG, Verfahrensrecht, Sonstiges
DE/                     AO, AStG, EStG, ErbStG, GewStG, KStG, UStG, Verfahrensrecht, elster, Sonstiges
DE-CH/                  Betriebsstätten, DBA, Grenzgänger, Verrechnungspreise, Wegzug-Zuzug (weitgehend Platzhalter)
Notizbuch-fuer-Wissen/  OneNote-Export (~1300 Markdown-Seiten)
_migration/             SharePoint-/OneNote-/Termstore-Werkzeuge
schema/                 nur legal-knowledge-graph.md
steuerliche-erfassung/  Umleitung nach DE/AO/
```

`INDEX.md` ist bewusst lückenhaft: unter anderem nicht indexiert sind `schema/`, `DE/Verfahrensrecht/`, `CH/Verfahrensrecht/`, `DE-CH/*`, `Notizbuch-fuer-Wissen/Steuern-DE/`, `Notizbuch-fuer-Wissen/Steuern-CH/`, `_migration/`.

## 4. Maschinenlesbare Artefakte

| Artefakt | Inhalt | Beleg |
|---|---|---|
| `schema/legal-knowledge-graph.md` | Metadaten-Dimensionen; Kernobjekte nur namentlich: `NORM`, `NORM_VERSION`, `PROCEDURE`, `DEADLINE`, `SOURCE`, `RELATION` | Abschnitt 5 |
| `DE/AO/ableitungsregeln.schema.json` + `.json` | JSON Schema Draft 2020-12; 12 Ableitungsregeln mit `normen[].rechtsstand` | Stand 31.10.2026 |
| `DE/AO/ustzustv-laendertabelle.schema.json` + `.json` | Länder → Finanzamt | Stand 31.10.2026 |
| `DE/elster/inventar.json` | ELSTER-Paketinventar | `DE/elster/` |
| `DE/elster/erfassungsformulare.json` | Formularliste Kanzlei-Bot | `DE/elster/` |
| `DE/elster/katalog-verfahren-datenarten.json` | ELSTER-Technikverfahren, nicht AO/FGO | `DE/elster/` |
| `CH/DBG/qst-tarifcodes.json` + Tarife 2026 | Quellensteuer-Codeliste | `CH/DBG/` |

Kein JSON-Schema und kein Validator für den Legal Knowledge Graph. Kein `package.json` auf Repo-Ebene. Keine automatisierten Tests.

## 5. Verfahrens-, Fristen- und Verjährungsmodelle

### 5.1 Deutschland

Nur eine kuratierte Datei: `DE/Verfahrensrecht/Fristenregister-AO-FGO.md` (Commit-Linie ab `1217dd8` / `abb98b3`).

- Markdown-Tabellen zu Fristberechnung, Bekanntgabe, Einspruch/Klage, Festsetzungs- und Zahlungsverjährung (§§ 169–171, 228–231 AO), Säumnis, DBA Art. 26.
- Soll-YAML für Fristentatbestände (Abschnitt 16) und DBA-Felder (Abschnitt 19.3): nicht befüllt.
- Verfahrenslandkarte als Gliederung (Abschnitt 18), keine eigenen Verfahrens-IDs analog `CH-P-*`.
- Primärquelle laut Datei: Connector «Deutsches Recht», 29.09.2026; expliziter Vorbehalt vor automatischer Fristberechnung.

### 5.2 Schweiz

| Datei | Inhalt |
|---|---|
| `CH/Verfahrensrecht/Fristenregister-Steuerverfahren-CH.md` | Tabellen mit Frist-IDs `CH-F-*`; Soll-YAML Abschnitt 13; Verjährungsmatrix Abschnitt 12 |
| `CH/Verfahrensrecht/Verfahrenslandkarte-Steuerrecht-CH.md` | Prozess-YAML Abschnitt 12; Verfahrensmatrix `CH-P-*` (DBG, StHG, MWST, VSt, VwVG, BVGer, BGer) |

Beide Dateien verweisen auf `schema/legal-knowledge-graph.md`. Kantonale Unterschiede sind als `kantonale_konkretisierung_noetig` vorgesehen, nicht durch pauschale Bundesregeln ersetzt.

### 5.3 Statusbegriffe (nicht vereinheitlicht)

- `pruefstatus` in DE/CH-Fristenregistern
- `verification_status` in der CH-Verfahrenslandkarte und in DE-SharePoint-Hinweisen
- Kein Statusmodell im LKG-Dokument

## 6. Tax-Compliance- und Personaleinsatz-Modelle

| Bereich | Ist | Beleg |
|---|---|---|
| Steuerliche Erfassung DE | Fall (`case_id`), Person, juristische Person, Betriebsstätte; SharePoint-Listen 0–9 | `DE/AO/Einheitliches-Datenmodell-steuerliche-Erfassung-DE-Auslandsbezug.md`, `DE/AO/sharepoint-forms/` |
| `Entity` / `Deployment` als LKG-Klassen | nicht vorhanden | Suche im kuratierten Baum |
| Tax Compliance kuratiert | dünn; INDEX ohne eigenes Compliance-Modul | `INDEX.md`, `Arbeitsmaterialien/` |
| Tax Compliance Notizbuch | umfangreich, unstrukturiert | `Notizbuch-fuer-Wissen/Steuern-DE/Verfahrensrecht/Tax-Compliance/` |
| Personaleinsatz DE↔CH | `DE-CH/Grenzgaenger/` nur `.gitkeep`; Inhalt im Notizbuch (DBA Art. 15/15a, A1, AÜG) | siehe Gap-Analyse |
| Drei Leistungspakete des Voragenten | nicht im Repo, Transkript nicht zugänglich | Abschnitt 10 |

## 7. Kommentierungen, Arbeitshilfen, Skills

| Bereich | Ist | Beleg |
|---|---|---|
| Kommentierungen | DBA-Schrifttum und OneNote-Fliessetext; keine Normversionsbindung | `Notizbuch-fuer-Wissen/International/DBA-DE-CH/` |
| Arbeitshilfen | `Arbeitsmaterialien/` weitgehend leer; Ausnahme `Einrichtung-Buchfuehrung-StBVV-32/` | `Arbeitsmaterialien/README.md` |
| Kanzlei-Bot ELSTER | dokumentierter Ablauf plus JSON-Kataloge | `DE/elster/elster-formularausfuellung-ablauf.md` |
| Erfassungs-Chat | in Ableitungsschema referenziert (`DE/AO/erfassungs-chat/`), Ordner fehlt; offener PR #22 | `ableitungsregeln.schema.json`, PR #22 |
| Ausführbare Skills im Repo | keine | kein `.cursor/`, kein Skill-Manifest |

## 8. SharePoint (nur lesend geprüft)

### 8.1 Dokumentierte Sites

| Site | Quelle der Angabe | Live-Zugang 04.11.2026 |
|---|---|---|
| `obenhaus.sharepoint.com/sites/Wissen` | `.mcp.json`, `_migration/README.md` | kein Graph-Token (AADSTS7000215, ungültiges Client Secret) |
| `transferpricingdocs.sharepoint.com/sites/wissen` | `_migration/README.md` (Termstore) | nicht geprüft, gleicher Tokenfehler |
| `transferpricingdocs.sharepoint.com/sites/qm`, Ordner `raw` | Auftrag Nils 04.11.2026 | kein Zugang; OneDrive-MCP `needsAuth` |

OneDrive-MCP: nicht authentifiziert. Azure-MCP: keine SharePoint-Site-Tools. Keine produktive Synchronisation gemeldet.

### 8.2 Im Repo abgebildete SharePoint-Struktur

- `_migration/wissen-site-strukturkarte.md`: Ordnerbaum der Wissen-Site, einschliesslich `General/`
- `_migration/mapping-sp-zu-repo.md`: Zuordnung SharePoint → Repo; Reintext `DE/AO/grounds/` ist geplant, nicht im Tree
- Fristenregister DE/CH enthalten Wiki-Pfadtabellen (`wiki/Steuerverfahrensrecht_DE/`, `wiki/Tax Compliance/`, …)
- `DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1`: ausführbares Listenmodell, nicht die QM-Prozessquelle

## 9. Weitere Repositories

Über `gh repo list steueranwalt` (14 sichtbare Repos) und GitHub-Suche `org:steueranwalt`:

| Repo | Status | Konsequenz |
|---|---|---|
| `steueranwalt/taxcompliance` | vorhanden, Schreibziel | dieses Repo |
| `steueranwalt/qm` | 404 / GraphQL nicht auflösbar | geplant laut Nils, nicht sichtbar |
| `steueranwalt/steuerkanzlei` | 404 / GraphQL nicht auflösbar | geplant laut Nils, nicht sichtbar |
| `steueranwalt/tp-automation` | öffentlich, leer (Size 0, 20.04.2026) | kein LKG-Inhalt |
| Forks (`claude-fuer-deutsches-recht`, `rechtsinfo_api`, …) | vorhanden | nicht als Wissensbibliothek verwendet |

Kein separates Wissens-Repo sichtbar. Keine PRs ausserhalb von `taxcompliance` angelegt.

## 10. Cloud-Agent-Vorarbeit

`cursor-cloud-list-cloud-agents` (Environment `steueranwalt/taxcompliance`, 11 Einträge einschliesslich Archiv):

| Agent | Bezug | Zugang |
|---|---|---|
| `bc-590c616d-83b8-4206-9f6d-33325768887a` | drei Leistungspakete nur im Chat | nicht in der Liste; `batch-fetch-details` → not available |
| `bc-aecda02c-8182-5020-af38-54b16fd38be4` | Erfassungs-Chat, Branch `cursor/erfassungs-chat-prototyp-8be4`, Status ERROR | PR #22 offen |
| `bc-1aadd383-48bc-57f2-9a2f-07fd6f9b1230` | Substanzprüfung Holding-KG | PR #18 offen |
| weitere | ELSTER, SharePoint-Forms, OneNote-Export | bereits in `main` bzw. gemergt |

Die drei Leistungspakete (Gründung DE–CH; CH-Gesellschaft in DE; Personaleinsatz DE→CH) sind offene Quelle. Inhalt nicht erfunden.

## 11. Dubletten und technische Schulden (nur belegt)

1. DE-Verfahrenslandkarte steckt in `Fristenregister-AO-FGO.md` §§ 18–19; CH hat eine eigene Landkarte.
2. CH-Fristenregister: doppelte Hauptnummer «5.»
3. Frist-IDs: CH `CH-F-*` / `CH-P-*`; DE ohne IDs in den Tabellen, obwohl Abschnitt 18 IDs verlangt.
4. Status-Enumerationen `pruefstatus` versus `verification_status` versus Master-Prompt-Status.
5. `INDEX.md` deckt den Tree nicht.
6. `AGENTS.md` («kein Test-Suite») widerspricht dem Umsetzungsauftrag (Schemas, Validatoren, Tests).
7. Master-Prompt Abschnitt 3 (QM/General = Prozessbeschreibungen) weicht von Nils 04.11.2026 ab; siehe `DECISIONS.md`.
8. Referenziertes `DE/AO/erfassungs-chat/` und `DE/AO/grounds/` fehlen im Tree.
9. `sharepoint-forms/README.md` nennt 14 Ergebnisfelder, `ableitungsregeln.json` enthält 12 Regeln.

## 12. Implementierungsstand der neun Zielgebiete

Siehe `GAP_ANALYSIS.md`. Kurz: kuratiertes Markdown-Wissen und zwei JSON-Inseln (AO-Erfassung, ELSTER, CH-QSt); kein ausführbarer Rechtsgraph.
