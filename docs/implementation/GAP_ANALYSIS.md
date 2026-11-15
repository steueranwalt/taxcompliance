# Gap-Analyse (Phase 0)

**Stand:** 04.11.2026  
**Bezug:** `INVENTORY.md`, Master-Prompt Abschnitte 2 und 18, Entscheidungen Nils 04.11.2026 in `DECISIONS.md`.

Statuswerte in dieser Datei beschreiben den technischen Ist-Stand, nicht eine fachliche Freigabe.

## 1. Die neun Zielgebiete

| # | Zielgebiet | Ist-Status | Vorhanden | Fehlt für die Definition of Done |
|---|---|---|---|---|
| 1 | Steuerrechtliche Kommentierungen | nur Markdown-Wissen | DBA-Schrifttum und OneNote unter `Notizbuch-fuer-Wissen/International/DBA-DE-CH/`; Wiki-Pfade in den Fristenregistern | Objekt `COMMENTARY` an `NORM_VERSION`; Trennung Primärquelle / Verwaltung / Rechtsprechung / Literatur / eigene Bewertung; Versionsbindung |
| 2 | Verfahrenslandkarten | partiell strukturiert (Markdown) | CH: `CH/Verfahrensrecht/Verfahrenslandkarte-Steuerrecht-CH.md` mit `CH-P-*`; DE: Gliederung in `DE/Verfahrensrecht/Fristenregister-AO-FGO.md` § 18 | Einheitliches Schema `PROCEDURE` / `PROCEDURE_STEP` / `STATE` / `DECISION` / `TRANSITION`; DE-IDs; maschinenlesbare Instanzen; Landkarten-Export |
| 3 | Fristenlandkarten | partiell strukturiert (Markdown) | DE- und CH-Fristenregister; CH mit `CH-F-*`; Soll-YAML in beiden Dateien | Schema `DEADLINE`; befüllte Instanzen; Validator; Kalender-/Feiertagslogik |
| 4 | Verjährungslandkarten | nur Markdown-Wissen | DE §§ 169–171, 228–231 AO; CH Verjährungsmatrix Abschnitt 12 | eigener Regeltyp `LIMITATION`; Hemmung/Unterbrechung als Daten, nicht als Prosa |
| 5 | Tax-Compliance-Kataloge | partiell (Erfassung) / sonst Wissen | AO-Erfassungsmodell und Ableitungsregeln; Notizbuch Tax-Compliance | Schema `OBLIGATION` / `EVIDENCE` / `FINDING` / `ACTION`; keine Dubletten; Sachverhalt → Pflichten |
| 6 | Prozessflows und Zustandsübergänge | nur Spezifikation | CH-Prozess-YAML (unbefüllt); DE § 18 als Gliederung | ausführbare Transitionen; Fristen-Engine; Tests |
| 7 | Arbeitshilfen und Checklisten | Platzhalter | `Arbeitsmaterialien/` fast leer; StBVV-32 als Ausnahme | QM-Wiki-Indexierung laut Nils; stabile IDs auf Regeln |
| 8 | ChatGPT-Skills, Bots, Plugins | partiell dokumentiert | ELSTER-Kanzlei-Bot-Ablauf; OneNote-MCP; offener Erfassungs-Chat PR #22 | stabile Schnittstellen (Norm, Verfahren, Frist, Compliance, Quelle, Änderungsfolgen); kein zweites Skill-Repo ohne Index |
| 9 | Juristische Recherche und Mandatsarbeit | nur Wissen / Migration | OneNote-Export; SharePoint-Mapping; Connector-Hinweis «Deutsches Recht» | Provenienzobjekt `SOURCE`; keine erfundenen Fundstellen; Mandatsdaten bleiben draussen |

## 2. Lücken gegenüber den Objektklassen (Phase 1)

| Klasse | Im Repo | Lücke |
|---|---|---|
| `NORM` | Name in `schema/legal-knowledge-graph.md`; eingebettete `normen[]` in `ableitungsregeln.json` | keine Norm-Registry, keine stabile ID-Datei |
| `NORM_VERSION` | Konzept «Geltungszeitraum an der Normfassung»; Felder `rechtsstand`, `applicable_from`/`to` in Markdown | keine Versionsentität; Historie nicht maschinenlesbar |
| `SOURCE` | `quelle`, `knowledge_refs`, SharePoint-Tabellen | kein einheitliches Provenienzschema |
| `RELATION` | LKG-Text (DBA über Relationen) | kein typisiertes Relationsschema |
| `PROCEDURE` | CH-Tabellen `CH-P-*` | DE ohne IDs; keine JSON-Instanzen |
| `PROCEDURE_STEP` | CH `states[]` nur als YAML-Soll | nicht serialisiert |
| `EVENT` | Auslöser-Spalten in Tabellen | kein EVENT-Typ |
| `STATE` | CH `state_id` in der Spezifikation | nicht instantiiert |
| `DECISION` | CH `decision_gate` | nicht instantiiert |
| `TRANSITION` | CH `next_states` | nicht instantiiert |
| `DEADLINE` | Inhalt in Markdown; CH-IDs | kein JSON, kein Validator |
| `LIMITATION` | Verjährungsabschnitte | kein eigener Typ |
| `OBLIGATION` | Meldepflichten tabellarisch; Ableitungsregeln sind keine Pflichten | kein Pflichtenmodell |
| `EVIDENCE` | nicht vorhanden | — |
| `FINDING` | nicht vorhanden | — |
| `ACTION` | nur `action` im CH-YAML-Entwurf | — |
| Fall / Person | vorhanden im Erfassungsmodell | wiederverwenden, nicht als LKG-Kern duplizieren |
| `Entity` / `Deployment` | nicht als LKG-Klassen vorhanden | nicht erfinden; Erfassungsobjekte bleiben fachlich getrennt |

## 3. Fehlende Quellen und Zugänge

| Quelle | Erwartet | Geprüft | Folge |
|---|---|---|---|
| SharePoint QM `raw/` | geltende Prozessbeschreibungen | OneDrive-MCP ohne Auth; Graph-Token ungültig | Inhalt nicht inventarisiert; nichts erfinden |
| SharePoint Wissen / General und Wiki | Primärquellen und Kommentierungen | Site in `_migration/` dokumentiert; Live-Zugriff fehlgeschlagen | nur Repo-Abbilder und Wiki-Pfade in den Fristenregistern |
| GitHub `steueranwalt/qm` | geplantes QM | 404 | keine Indexdateien lesbar |
| GitHub `steueranwalt/steuerkanzlei` | technische Dokumentation | 404 | keine Architektur aus diesem Repo |
| Cloud-Agent `bc-590c616d-…` | drei Leistungspakete | Transkript nicht zugänglich | offene Quelle |
| Connector «Deutsches Recht» | Primärnormen für das DE-Fristenregister | nur als Quellenhinweis in der Markdown-Datei | keine Live-Normprüfung in dieser Phase |
| `AZURE_*` in der Umgebung | Graph/OneNote | Secret ungültig (AADSTS7000215) | SharePoint und OneNote live nicht lesbar |

## 4. Was erhalten bleibt (keine Ersatzmigration)

Diese Bestände werden nicht ersetzt, solange Nils keine Migrationsentscheidung dokumentiert:

- `schema/legal-knowledge-graph.md` als Metadaten-Leitdokument
- `DE/AO/ableitungsregeln.json` und UStZustV-Tabelle
- SharePoint-Forms-Skript und Erfassungsdatenmodell
- DE/CH-Fristenregister und CH-Verfahrenslandkarte als Fachquellen für Instanzen
- OneNote-Export unter `Notizbuch-fuer-Wissen/`
- ELSTER-Kataloge und CH-Quellensteuertarife

Phase 1 ergänzt maschinenlesbare Schemas **neben** diesen Beständen.

## 5. Blocker für spätere Phasen (nicht für Phase 1)

Phase 1 (Schemas, Validator, Beispieldatensatz) ist ohne SharePoint und ohne die anderen Repos möglich.

Später blockiert, bis Nils Zugang oder Freigabe gibt:

1. Live-Inventur QM `raw/` und Entscheidung QM/General versus `raw/` (`DECISIONS.md` D-2026-11-04-02).
2. Indexierung von Arbeitshilfen in `steueranwalt/qm`.
3. Technische Doku in `steueranwalt/steuerkanzlei` (lesen, nicht schreiben).
4. Inhalt der drei Leistungspakete des Voragenten.
5. Fachliche Freigabe jeder Rechtsregel (`LEGAL_APPROVED` darf kein Agent setzen).
