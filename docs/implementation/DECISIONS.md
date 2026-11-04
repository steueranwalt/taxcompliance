# Entscheidungen

Format: `D-YYYY-MM-DD-nn`. Status: `GEGOLTEN` (Nils), `VORGESCHLAGEN` (Agent, nicht bindend), `OFFEN` (nur Nils entscheidet).

Kein Agent setzt eine fachliche Freigabe. Keine Entscheidung hier ersetzt eine Rechtsprüfung.

## Geltende Vorgaben von Nils (04.11.2026)

Diese fünf Ablage-Entscheide gehen Abschnitt 3 des Master-Prompts vor, soweit sie ihn konkretisieren. Der Konflikt in D-2026-11-04-02 bleibt offen.

### D-2026-11-04-01 – Geplantes QM-Repo

- **Status:** GEGOLTEN
- **Entscheidung:** Geplantes QM liegt im GitHub-Repo `steueranwalt/qm`.
- **Prüfung 04.11.2026:** Repo für den verwendeten GitHub-Zugang nicht sichtbar (HTTP 404, GraphQL nicht auflösbar).
- **Folge:** keine PRs nach `qm`. Sobald das Repo existiert und lesbar ist, Inventur nachziehen.

### D-2026-11-04-02 – Massgebende Prozessbeschreibungen

- **Status:** GEGOLTEN hinsichtlich der Quelle `raw/`; **OFFEN** hinsichtlich des Verhältnisses zu QM/General
- **Entscheidung Nils:** Geltende, freigegebene Prozessbeschreibungen liegen in SharePoint QM > Dokumente > `raw` (`transferpricingdocs.sharepoint.com/sites/qm`, Ordner `raw`, flach, Präfix `LP_xxx__`). `raw/` ist die alleinige massgebende Quelle.
- **Zusatz Nils:** `QM/General/` bleibt bestehen.
- **Master-Prompt Abschnitt 3:** «SharePoint QM / General: Prozessbeschreibungen, Governance, Verantwortlichkeiten, Freigaben, Dokumentenlenkung.»
- **Konflikt (nicht entschieden):** Ist `QM/General/` nach der neuen Regel nur noch historisch/nicht massgebend, ein Spiegel, oder bleibt sie für Governance/Freigaben neben `raw/` zuständig? Der Agent entscheidet das nicht.
- **Zugang 04.11.2026:** SharePoint QM nicht lesbar (OneDrive-MCP ohne Auth; Graph-Client-Secret ungültig). Inhalt von `raw/` nicht inventarisiert.

### D-2026-11-04-03 – Arbeitshilfen und Skills

- **Status:** GEGOLTEN
- **Entscheidung:** Freigegebene Arbeitshilfen, einschliesslich Bot-Prompts und Skills, gehören ins QM-Wiki. Liegen sie technisch in einem Repo, braucht es in `qm` eine Indexierung.
- **Folge:** Keine neuen Skills in `taxcompliance` als Ersatzbibliothek. Vorhandene ELSTER-/Ableitungsartefakte bleiben; Index in `qm` erst bei Zugang und Freigabe.

### D-2026-11-04-04 – Technische Dokumentation

- **Status:** GEGOLTEN
- **Entscheidung:** Technische Dokumentation, umgesetzt und geplant, gehört ins GitHub-Repo `steueranwalt/steuerkanzlei`.
- **Prüfung 04.11.2026:** Repo nicht sichtbar (404).
- **Folge:** Umsetzungsdokumentation der Phasen liegt vorläufig in `docs/implementation/` von `taxcompliance` (Master-Prompt Abschnitt 17). Umzug nach `steuerkanzlei` nur nach Freigabe und wenn das Repo existiert. Kein PR nach `steuerkanzlei` ohne Freigabe.

### D-2026-11-04-05 – QM/General bleibt

- **Status:** GEGOLTEN als Bestandsschutz, Inhalt offen
- **Entscheidung:** `QM/General/` bleibt bestehen.
- **Folge:** keine Löschung, keine unkontrollierte Migration. Inhalt und Rolle gegenüber `raw/` siehe D-2026-11-04-02.

### D-2026-11-04-06 – Schreibgrenzen

- **Status:** GEGOLTEN
- **Entscheidung:** Code, Schemas und Tests nur in `steueranwalt/taxcompliance`. `qm`, `steuerkanzlei` und ein allfälliges Wissens-Repo nur lesen. SharePoint ausschliesslich lesend. Keine PRs in Fremdrepos ohne Freigabe. Nichts nach `main` mergen. Jede Phase ein eigener PR.

## Offene Entscheidungen

### D-2026-11-04-02a – Rolle von QM/General nach Einführung von `raw/`

- **Status:** OFFEN
- **Frage an Nils:** Soll der Master-Prompt Abschnitt 3 («QM / General = Prozessbeschreibungen») formell auf «nicht massgebend / historisch / nur Governance» geändert werden, oder bleiben in `QM/General/` weiterhin geltende Prozessdokumente neben `raw/`?
- **Agent:** inventarisiert `raw/` sobald Zugang besteht; ändert weder Master-Prompt noch SharePoint.

### D-2026-11-04-07 – `AGENTS.md` versus Code-Auftrag

- **Status:** OFFEN
- **Sachverhalt:** `AGENTS.md` beschreibt das Repo als inhaltsreine Wissensbasis ohne `package.json` und ohne Tests. Der Master-Prompt verlangt Schemas, Validatoren und Tests in genau diesem Repo.
- **Vorschlag:** `AGENTS.md` in P1 um einen Absatz «maschinenlesbare Schicht unter `schema/`, `data/`, `tools/`» ergänzen, die Markdown-Wissensbasis aber nicht zur App erklären.
- **Halt:** Wenn Nils das Repo bewusst codefrei halten will, P1 nicht mergen.

### D-2026-11-04-08 – Sichtbarkeit `qm` und `steuerkanzlei`

- **Status:** OFFEN
- **Frage:** Repos noch nicht angelegt, privat unter anderem Account, oder Zugang für `steueranwalt` fehlend?
- **Agent:** erneut lesen, sobald Nils den Zugang bestätigt. Nicht anlegen.

### D-2026-11-04-09 – Graph- / SharePoint-Zugang

- **Status:** OFFEN
- **Sachverhalt:** `AZURE_TENANT_ID` und `AZURE_CLIENT_ID` sind gesetzt; Tokenanforderung scheitert mit AADSTS7000215 (ungültiges Client Secret). OneDrive-MCP `needsAuth`.
- **Bitte:** gültiges Secret oder authentifizierter OneDrive-/SharePoint-Connector, nur Lesen.
- **Agent:** keine fiktive Synchronisation.

### D-2026-11-04-10 – Voragent drei Leistungspakete

- **Status:** OFFEN
- **Sachverhalt:** Agent `bc-590c616d-83b8-4206-9f6d-33325768887a` ist in diesem Environment nicht lesbar.
- **Bitte:** Transkript, Export oder Freigabe zum Einlesen.
- **Agent:** Pakete nicht aus dem Gedächtnis rekonstruieren.

### D-2026-11-04-11 – CH-Referenztatbestand (Phase 7B)

- **Status:** OFFEN
- **Vorschlag:** DBG-Einsprachefrist gemäss `CH/Verfahrensrecht/Fristenregister-Steuerverfahren-CH.md`, Quelle Fedlex, Status zunächst `LEGAL_REVIEW_REQUIRED`.
- **Halt:** verbindliche Wahl erst nach Nils oder nach nachgezogener Primärquelle.

### D-2026-11-04-12 – Offene PRs #18 und #22

- **Status:** OFFEN (nicht Teil dieses Auftrags)
- **Sachverhalt:** PR #22 Erfassungs-Chat (Branch `cursor/erfassungs-chat-prototyp-8be4`); PR #18 Substanz-Holding-KG. Beide unberührt lassen, solange Nils nichts Gegenteiliges sagt.

## Vorgeschlagene technische Entscheide (P1)

### D-2026-11-04-13 – Schema-Stack

- **Status:** VORGESCHLAGEN, technisch umgesetzt in Phase 1 (PR `cursor/phase-1-lkg-schema-bffc`)
- **Vorschlag:** JSON Schema Draft 2020-12; Validator Node/ajv unter `tools/lkg-validate/`; Instanzen unter `data/lkg/`; LKG-Markdown bleibt Leitdokument.
- **Alternative (verworfen vom Agenten, Nils kann sie wählen):** Python/`jsonschema`; YAML-Instanzen; neues Graphdatenbank-Framework. Begründung der Verwerfung: vorhandenes JSON-Schema in `DE/AO/`, Master-Prompt «bestehende Sprache verwenden», Kosten.
- **Hinweis:** Die Umsetzung ist widerrufbar (Ordner löschen). Kein Merge nach `main` ohne Review.

### D-2026-11-04-14 – Wiederverwendung Fall/Person

- **Status:** VORGESCHLAGEN
- **Vorschlag:** Erfassungsobjekte Fall/Person nicht in den LKG-Kern kopieren. LKG bleibt NORM → Version → Verfahren/Pflicht/Frist. Optionale spätere `CASE_REF`.
- **Grund:** Master-Prompt «doppelte Datenmodelle verhindern»; die Klassen dienen der ELSTER-Erfassung, nicht dem Rechtsgraphen.

## Entscheidungsregeln für Agents

1. Bestehende Strukturen nicht ersetzen ohne dokumentierte Migrationsentscheidung von Nils.
2. Fehlende Zugänge dokumentieren, nicht simulieren.
3. `LEGAL_APPROVED` setzt nur Nils oder eine von ihm benannte fachliche Stelle.
4. Ungeprüfte Rechtsinhalte: `DRAFT` oder `LEGAL_REVIEW_REQUIRED` plus `open_verification`.
5. Irreversible Schritte (Löschen, SharePoint-Schreiben, Merge nach `main`, Repo anlegen) nur nach ausdrücklicher Freigabe.
