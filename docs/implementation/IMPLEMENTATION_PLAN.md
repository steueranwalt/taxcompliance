# Implementierungsplan

**Stand:** 04.11.2026  
**Grundlage:** Master-Prompt Abschnitte 16–18, `INVENTORY.md`, `GAP_ANALYSIS.md`, `DECISIONS.md`.  
**Schreibziel:** nur `steueranwalt/taxcompliance`. Andere Repos und SharePoint nur lesen, derzeit ohne Zugang.

## 1. Verbindliche Reihenfolge

1. Inventar und Lücken (diese Phase, P0).
2. Ist gegen die neun Zielgebiete prüfen (abgeschlossen in `GAP_ANALYSIS.md`).
3. Vorhandene Modelle wiederverwenden: LKG-Metadaten, CH-IDs, DE-Soll-YAML, Erfassungs-Fall/Person, JSON Schema Draft 2020-12.
4. Verbindliche Schemas und Normversionierung (nächste Phase).
5. Drei vertikale Referenzfälle als minimales Gesamtsystem, beginnend mit § 171 AO.
6. Fristen-, Verjährungs-, Verfahrens- und Compliance-Module erweitern.
7. SharePoint- und Skill-Integrationen, sobald Zugang besteht.
8. Tests, Dokumentation, Übergabe.

Keine flächendeckende Normerfassung vor den drei Referenzimplementierungen.

## 2. Arbeitspakete und PRs

Jedes Paket ist ein eigener PR. Nichts wird nach `main` gemergt.

| Paket | Phase | PR-Inhalt | Abnahme | Abhängigkeit |
|---|---|---|---|---|
| P0 Inventur | 0 | `docs/implementation/*` | jeder Befund belegt | — |
| P1 Datenmodell | 1 | JSON-Schemas, Validator, Tests, ein gültiger und mehrere ungültige Beispieldatensätze | ungültige Referenzen, widersprüchliche Geltungszeiträume, fehlende Pflichtangaben werden erkannt | P0 |
| P2 Referenz A § 171 AO | 7A / vertikal 1 | Instanzen NORM/NORM_VERSION/SOURCE/LIMITATION/EVENT plus Änderungsfolgen-Haken | validierbar, quellenbezogen, Status nicht `LEGAL_APPROVED` | P1 |
| P3 Verfahrenslandkarten DE Kern | 2 | AO-Veranlagung, Bekanntgabe, Einspruch, AdV, Klage – als Instanzen | maschinenlesbar und als Landkarte ausgebbar | P1 |
| P4 Fristen-Engine Kern | 3 | Berechnungsregeln, Kalender, Wochenende; Tests Jahreswechsel/Schaltjahr | deterministisch; unvollständige Regel → Prüfstatus | P1, P2 |
| P5 CH-Referenz B | 7B / 2 / 3 | ein benannter CH-Tatbestand (Vorschlag: DBG-Einsprachefrist, offen bis Quellenprüfung) | eigenständige CH-Logik, nicht DE-Kopie | P1; fachliche Quellenwahl |
| P6 Compliance-Kern | 4 | `OBLIGATION` an Normversion und Frist; Testfälle DE/CH/Personaleinsatz-Skelett | fehlende Tatsache ≠ verneinte Voraussetzung | P1; Voragent-Pakete offen |
| P7 Referenz C MAP DE–CH | 7C | Art. 26 DBA DE–CH aus dem vorhandenen Fristenregister | beide Jurisdiktionen, parallele innerstaatliche Pfade | P3, P5 |
| P8 Kommentierungsgraph | 5 | `COMMENTARY` + Impact bei Normversionsänderung | von der Version zu Quelle, Kommentar, Verfahren, Regel | P1, P2 |
| P9 Skill-Adapter | 6 | Adapter an vorhandenem ELSTER- oder Ableitungsskill; keine neuen Skills ohne Bedarf | strukturierte Anfrage → validiertes Ergebnis oder dokumentiert unverbunden | P1–P4 |
| P10 QS/Governance | 8 | Statusmodell, Audit-Log-Felder, Freigabe ≠ Test | Tests grün ≠ juristische Freigabe | alle vorigen |

P2 darf ein Minimaldatensatz aus P1 weiterziehen. Die volle Engine kommt in P4, nicht in P1.

## 3. Technische Leitplanken für P1

Vorschlag an Nils, umgesetzt erst im P1-PR (nicht irreversibel):

- Sprache: JSON Schema Draft 2020-12, wie `DE/AO/ableitungsregeln.schema.json`.
- Ablage: `schema/lkg/` für Schemas, `data/lkg/` für Instanzen, `tools/lkg-validate/` für Validator und Tests. Bestehende Markdown-Dateien bleiben.
- Laufzeit: Node.js (vorinstalliert). Kleines lokales `package.json` nur unter `tools/lkg-validate/`, nicht das Wissensrepo in eine App umbauen.
- Bestehende LKG-Dimensionen (`jurisdiction`, `legal_level`, `territory`, …) werden Felder von `NORM` / `NORM_VERSION`, nicht ein zweites Metamodell.
- ID-Regel aus `schema/legal-knowledge-graph.md` Abschnitt 7 bleibt.
- Status mindestens: `DRAFT`, `SOURCE_VERIFIED`, `LEGAL_REVIEW_REQUIRED`, `LEGAL_APPROVED`, `SUPERSEDED`. Mapping von `pruefstatus` / `verification_status` dokumentieren.
- Fall/Person aus dem Erfassungsmodell werden nicht nachgebaut. Optional später Relation `CASE_REF`.
- Keine personenbezogenen Mandatsdaten in Fixtures.
- Keine erfundenen Rechtsquellen. Ungeprüfte Stellen: `LEGAL_REVIEW_REQUIRED` plus `open_verification`.

Falls Nils eine andere Sprache (Python) oder einen anderen Pfad will: vor dem P1-Merge sagen. Der Vorschlag folgt dem vorhandenen JSON-Schema und vermeidet ein neues Framework.

## 4. Erste vertikale Referenz (nach P1)

**A – Deutschland, § 171 AO**, weil das DE-Fristenregister die Ablaufhemmung bereits als eigenen Tatbestand führt und der Master-Prompt sie als Abnahmefall setzt.

Minimaler Pfad: `NORM` § 171 AO → `NORM_VERSION` (Rechtsstand 29.09.2026, Quelle Connector-Hinweis, Status `LEGAL_REVIEW_REQUIRED`) → `SOURCE` → ausgewählte Hemmungstatbestände als `LIMITATION` → auslösendes `EVENT` → Verknüpfung zu Festsetzungsverjährung und Verfahren. Mehrere Tatbestände und Fassungen erst, wenn Quellen im Repo oder nach Freigabe nachgezogen sind.

**B und C** erst nach P1 und nach Quellenprüfung. Vorschlag B: DBG-Einsprache, Quelle Fedlex-Hinweis im CH-Fristenregister. Vorschlag C: Art. 26 DBA DE–CH, bereits in `Fristenregister-AO-FGO.md` Abschnitt 19.2.

## 5. Was diese Phase nicht tut

- keine Schemas oder Validatoren (gehören in P1)
- kein Merge nach `main`
- keine PRs in `qm` oder `steuerkanzlei`
- kein Schreiben nach SharePoint
- kein Erfinden der drei Leistungspakete
- keine fachliche Freigabe

## 6. Haltelinien

Anhalten und berichten, wenn eine der folgenden Stellen erreicht ist:

- fachliche Wahl des verbindlichen CH-Referenztatbestands
- SharePoint- oder Repo-Berechtigung für QM / Wissen / `steuerkanzlei`
- Migration oder Löschung bestehender Markdown-Bestände
- Setzen von `LEGAL_APPROVED`
- Konflikt QM/General versus `raw/` (`DECISIONS.md` D-2026-11-04-02)
