# Status

Zentrale Fortschrittsdatei gemäss Master-Prompt Abschnitt 17.

**Aktualisiert:** 04.11.2026  
**Aktuelle Phase:** 0 abgeschlossen (dieser PR); Phase 1 als nächster PR  
**Gesamtstand:** Inventur und Planung im Repo; noch kein ausführbarer Rechtsgraph

Statuswerte: `NOT_STARTED`, `IN_PROGRESS`, `BLOCKED`, `IMPLEMENTED`, `TESTED`, `REVIEW_REQUIRED`, `ACCEPTED`.

Als abgeschlossen gilt ein Paket nur, wenn die Abnahmekriterien erfüllt sind. Technische Tests sind keine juristische Freigabe.

## Arbeitspakete

| ID | Agent | Aufgabe | Priorität | Status | Dateien | Commit | Tests | Offene Abhängigkeiten | Blocker | Nächster Schritt |
|---|---|---|---|---|---|---|---|---|---|---|
| P0 | A0 + A1 | Bestandsaufnahme, Gap, Plan, Entscheidungen | P0 | REVIEW_REQUIRED | `docs/implementation/INVENTORY.md`, `GAP_ANALYSIS.md`, `IMPLEMENTATION_PLAN.md`, `DECISIONS.md`, `STATUS.md` | dieser Branch | keine automatisierten Tests vorgesehen (Dokumentationspaket) | SharePoint, `qm`, `steuerkanzlei`, Voragent | Zugang extern | Review Nils; danach P1-PR |
| P1 | A2 | Schemas, Normversionierung, Validator, Tests | P0 | NOT_STARTED | geplant: `schema/lkg/`, `data/lkg/`, `tools/lkg-validate/` | — | ausstehend | D-2026-11-04-07, D-2026-11-04-13 | keiner für den technischen Entwurf | eigener PR nach Merge-Freigabe oder parallel auf neuem Branch |
| P2 | A3 / A6 | Vertikale Referenz A, § 171 AO | P0 | NOT_STARTED | — | — | — | P1; Quellenlage § 171 | keine fachliche Freigabe fingieren | nach P1 |
| P3 | A3 | Verfahrenslandkarte DE Kern | P1 | NOT_STARTED | — | — | — | P1 | — | nach P1 |
| P4 | A6 | Fristen-Engine Kern | P1 | NOT_STARTED | — | — | — | P1, P2 | — | nach P2 |
| P5 | A4 | CH-Referenz B | P1 | NOT_STARTED | — | — | — | P1; D-2026-11-04-11 | Quellenwahl CH | nach P1 und Entscheid Nils oder geprüfter Fedlex-Stelle |
| P6 | A5 | Compliance-Kern | P1 | NOT_STARTED | — | — | — | P1; D-2026-11-04-10 | Voragent-Pakete | Skelett ohne erfundene Paketinhalte |
| P7 | A3 / A4 | Referenz C, MAP DE–CH | P0 (Abnahme) | NOT_STARTED | — | — | — | P3, P5 | — | nach DE- und CH-Kern |
| P8 | A7 | Kommentierungsgraph | P1 | NOT_STARTED | — | — | — | P1, P2 | SharePoint Wiki | nach P2 |
| P9 | A7 | Skill-Adapter | P2 | NOT_STARTED | — | — | — | P1–P4; D-2026-11-04-03 | `qm`-Index | vorhandenen ELSTER-Skill prüfen |
| P10 | A8 | QS und Governance | P0 vor Produktiv | NOT_STARTED | — | — | — | alle vorigen | — | Statusmodell bereits in P1 anlegen |

## Phase 0 – Zusammenfassung (Abschnitt 17)

### 1. Was wurde tatsächlich implementiert?

Keine ausführbare Regel-Engine. Angelegt ist die Steuerungsdokumentation für das Tax Legal Knowledge System: Inventar, Gap-Analyse, Implementierungsreihenfolge, Entscheidungslog, Status. Externe Systeme wurden auf tatsächlichen Zugang geprüft und fehlende Zugänge festgehalten.

### 2. Welche Dateien erstellt/geändert?

Neu:

- `docs/implementation/INVENTORY.md`
- `docs/implementation/GAP_ANALYSIS.md`
- `docs/implementation/IMPLEMENTATION_PLAN.md`
- `docs/implementation/DECISIONS.md`
- `docs/implementation/STATUS.md`

Keine bestehenden Fachdateien geändert. Kein Markdown unter `DE/`, `CH/`, `schema/` angefasst.

### 3. Welche Tests ausgeführt?

Keine Unit- oder Integrationstests (Dokumentationspaket). Stattdessen überprüfbare Zugangs- und Bestandstests:

- `git fetch origin main` → lokal = `3499982`
- GitHub: `steueranwalt/qm` und `steueranwalt/steuerkanzlei` → 404
- Graph-Token → AADSTS7000215
- OneDrive-MCP → `needsAuth`
- Cloud-Agent `bc-590c616d-83b8-4206-9f6d-33325768887a` → nicht zugänglich
- Lektüre: `schema/legal-knowledge-graph.md`, DE/CH-Fristenregister, CH-Verfahrenslandkarte, AO-Ableitungsschema, `_migration/README.md`

### 4. Welche fehlgeschlagen?

- Live-Inventur SharePoint Wissen und QM
- Lesen von `qm` und `steuerkanzlei`
- Einlesen der drei Leistungspakete des Voragenten

Das sind Zugangsfehler, keine Testregressionen.

### 5. Welche fachlichen oder technischen Fragen sind offen?

Siehe `DECISIONS.md`, insbesondere:

- D-2026-11-04-02a Rolle `QM/General/` versus `raw/`
- D-2026-11-04-07 `AGENTS.md` versus Code in diesem Repo
- D-2026-11-04-08 Repo-Sichtbarkeit
- D-2026-11-04-09 Graph-Secret / SharePoint-Auth
- D-2026-11-04-10 Voragent-Transkript
- D-2026-11-04-11 CH-Referenztatbestand

### 6. Welche nächste Phase beginnt?

Phase 1: verbindliches Datenmodell und Normversionierung in einem eigenen PR. Anschliessend erster vertikaler Referenzdatensatz § 171 AO (P2), ohne die Fristen-Engine vorwegzunehmen.

Phase 1 startet ohne Halt, weil sie keine fachliche Freigabe, keine Fremdrepos und kein SharePoint-Schreiben braucht. Halt vor `LEGAL_APPROVED`, vor CH-Tatbestandswahl und vor jeder Migration.
