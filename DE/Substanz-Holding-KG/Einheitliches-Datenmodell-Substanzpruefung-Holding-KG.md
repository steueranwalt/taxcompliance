# Einheitliches Datenmodell: Substanzprüfung Holding-KG (Version 3)

**Stand:** 27.10.2026, **Update 2** (ersetzt die Erstfassung "Update 1" vollständig).

**Fachliche Vorgabe:** Nils Obenhaus, Erfassungsbogen Holding-KG, **Version 3**, Projekt 22032-2 «Atwork wg Holding-KG» (`uploads/erfassungsbogen-v3-27-10-2026.md`, Anhänge A-C). Version 3 ersetzt die Versionen 1 und 2 vollständig als fachliche Grundlage.

**Kernänderung:** Gegenstand ist das **Tagesgeschäft**, nicht einzelne Vorgänge. Bezugseinheit ist die tatsächlich ausgeübte **Aufgabe** je Person, Gesellschaft und Zeitraum — eine wiederkehrende Zuständigkeit, kein abgeschlossener Geschäftsfall. Entscheidungskompetenzen, Vertragsverhandlungen, Aufsicht und Arbeitsorte werden als wiederkehrende Zuständigkeiten erhoben, nicht mehr über einen zuletzt abgeschlossenen Vorgang geführt.

**Rollen der Dokumente in `DE/Substanz-Holding-KG/`:**

| Dokument | Rolle |
|---|---|
| dieses Datenmodell | Architektur, Listenkatalog, Listensplit-Begründungen, Wiederverwendung, Berechtigungskonzept, Änderungsprotokoll V2 → V3 |
| [`Fragenkatalog-Substanzpruefung-Holding-KG.md`](Fragenkatalog-Substanzpruefung-Holding-KG.md) | alle Fragen (S, H, T, D, V, K, G, P, Z, O, R, A, C, N) mit stabilen IDs, Mandantensicht/interner Hinweis getrennt |
| [`feldkatalog/feldkatalog.json`](feldkatalog/feldkatalog.json) | maschinenlesbarer Feldkatalog (SchemaVersion 3) + Codebooks + Änderungsprotokoll |
| [`sharepoint-forms/README.md`](sharepoint-forms/README.md) | Forms-Aufteilung (5 Blätter), Flow-Spezifikation, Prüfregeln |
| [`sharepoint-forms/KLICKANLEITUNG-FORMS.md`](sharepoint-forms/KLICKANLEITUNG-FORMS.md) | Klickanleitung |
| [`sharepoint-forms/New-SubstanzHoldingKGListen.ps1`](sharepoint-forms/New-SubstanzHoldingKGListen.ps1) | idempotentes PnP-PowerShell-Skript, aus dem Feldkatalog erzeugt |
| [`interner-anhang-a-tagesgeschaeft-ueberarbeitung.md`](interner-anhang-a-tagesgeschaeft-ueberarbeitung.md) | NUR INTERN: Anhang A der V3 (Begründung Schemawechsel) |
| [`interner-anhang-c-historie.md`](interner-anhang-c-historie.md) | NUR INTERN: Anhang C (Korrespondenztabelle V1 → V3) |
| [`interner-anhang-d-rechtliche-hintergruende.md`](interner-anhang-d-rechtliche-hintergruende.md) | NUR INTERN: Anhang D (= Anhang A in V1, D1-D7, rechtliche Recherche) |
| [`interner-anhang-e-historischer-fragenvorrat-v1.md`](interner-anhang-e-historischer-fragenvorrat-v1.md) | NUR INTERN: Anhang E (historischer Fragenvorrat V1, nicht mandantenfähig) |

## 1. Architekturprinzipien

- **Aufgabe statt Vorgang.** `Aufgaben` ist die zentrale Liste: eine Zeile je wiederkehrender Zuständigkeit einer Person in einem Tätigkeitsbereich. **Keine Vorgangsliste mehr**: `Taetigkeiten`, `Entscheidungsfaelle`, `Vertragsvorgaenge`, `Fallbeteiligungen` und die FallID-Frage aus Version 2 entfallen ersatzlos. Ein konkreter Geschäftsfall ist weder Einstieg noch Voraussetzung für eine Antwort; Beispiele sind optionale Nachweise (`Belegverknuepfungen`), kein tragendes Datenobjekt.
- **H-Handlungen als Einzelfragen.** Die 45 Handlungen aus Abschnitt 1.2 werden in Forms als einzelne Fragen mit den Antworten ausgeführt/nicht ausgeführt/nicht bekannt gestellt (B3) — in SharePoint kompakt als drei MultiChoice-Spalten auf `Personeneinsaetze` abgelegt, da eine 1:1-Abbildung als 45 Einzelspalten keinen Mehrwert böte und die Forms-Darstellung davon unberührt bleibt.
- **S02 entfällt.** Die ausfüllende Person wird technisch aus den Forms-Metadaten (Responder/Absender) übernommen, nicht als Frage gespeichert. Der Rückfragekontakt bleibt eine eigene Frage (N24 → `Erfassungen.auskunftsperson_ref`).
- **Vier getrennte Prüfzustände statt Ja/Nein.** «Nicht bekannt», «nicht zutreffend», «nicht gefragt» (durch Verzweigung einfach nicht angezeigt — kein gespeicherter Wert) und Null (echte 0 bzw. leer) werden getrennt gehalten (B4). Deshalb sind etliche auf den ersten Blick binäre Fragen als 3- oder 4-wertige Choice statt als SharePoint-Boolean angelegt (z. B. `Aufgabenzustaendigkeiten.t15_geaendert`, `Kostenverteilungen.zuschlag`) — ein SharePoint-Boolean kann kein "nicht bekannt" ohne stillschweigenden `false`-Default abbilden.
- **Ermittelt vs. geschätzt getrennt.** Jede Zahlenfrage, bei der die Vorgabe ausdrücklich zwischen "aus Unterlagen ermittelt" und "geschätzt" unterscheidet, erhält eine eigene Status-Spalte (Codebook `ERMITTLUNGSART`) neben dem Zahlenfeld (z. B. `Personeneinsaetze.gesamtstunden_status`/`.gesamtstunden`).
- **Keine Summenkorrektur auf 100 %.** Orts- und Empfängerverteilung (`Aufgabenorte`, `Zeitverteilungen`) verteilen dieselbe Zeit aus unterschiedlichen Blickwinkeln und werden **nicht** automatisch auf 100 % normalisiert; unzugeordnete Restzeit wird ausdrücklich als eigener Status (`Z08_STATUS_REST_NICHT_ZUGEORDNET`) offengehalten statt stillschweigend verteilt.
- **Aufgabenreferenz statt Neubeschreibung.** Formulare, die sich auf bereits erfasste Aufgaben beziehen (z. B. O05 "welche der bereits genannten Aufgaben"), referenzieren diese über Lookup (`LookupMulti` auf `Aufgaben`) statt die Tätigkeit erneut zu beschreiben.
- **Stabile Codes statt deutscher Beschriftung in SharePoint.** Wie in Version 2: Choice-/MultiChoice-Spalten speichern den stabilen Code (z. B. `FREQ_DAILY`), die deutsche Beschriftung lebt im Feldkatalog (`codebooks`) und wird vom Flow verwendet, um die in Forms gewählte Bezeichnung vor der Elementanlage zu übersetzen.

## 2. Listenübersicht mit Spaltenzahl

25 Listen + Dokumentbibliothek `Substanznachweise` = 26 Objekte, 364 Spalten gesamt (automatisiert aus `feldkatalog/feldkatalog.json` ausgezählt, gegen das PnP-Skript geprüft: keine Duplikate, keine fehlenden Codebook-Referenzen, keine Lookup-Vorwärtsreferenzen).

| Liste/Bibliothek | Formular (B1) | Spalten | Rolle |
|---|---|---|---|
| `Personen` | 1 | 3 | Stammdaten, erfassungsübergreifend |
| `Erfassungen` | intern/5 | 11 | Fallsteuerung; Auskunftsperson aus N24 |
| `Gesellschaften` | intern | 5 | Bekannter Bestand, keine Quoten |
| `Orte` | 1/4 | 6 | Standortkatalog |
| `Substanznachweise` (Bibliothek) | 5 | 8 | Belegablage |
| `Funktionen` | 1 | 5 | Navigationsebene Person × Gesellschaft × Stellenbezeichnung |
| `Personenbindungen` | 3 | 21 | Vertrag + allgemeine Arbeitsorganisation (P30-P38) |
| `Aufgaben` | 2 | 23 | Zentrale Liste: wiederkehrende Aufgabe |
| `Personeneinsaetze` | 1/3 | 31 | Person × Zeitraum: S05-S07, H-Handlungen, Z01-Z07, O03-O05 |
| `Aufgabenempfaenger` | 2 | 11 | n:m Aufgabe × Empfängergesellschaft |
| `Aufgabenzustaendigkeiten` | 2 | 18 | Priorisierung, Mitwirkende, Änderungen je Aufgabe |
| `Entscheidungsbefugnisse` | 2 | 24 | Wiederkehrende Entscheidungszuständigkeit je Aufgabe × Entscheidungsart |
| `Vertragszustaendigkeiten` | 2 | 18 | Wiederkehrende Vertragszuständigkeit je Aufgabe × Vertragsart |
| `Kontrollaufgaben` | 2 | 10 | Aufsicht/Instruktion/Schulung je Aufgabe |
| `Steuerungsbeziehungen` | 2 | 8 | Gesteuerte Mitarbeitende/Dienstleister je Aufgabe |
| `Zeitverteilungen` | 3 | 7 | n:m Aufgabe × Empfängergesellschaft, Stunden |
| `Aufgabenorte` | 3 | 15 | Arbeitsorte je Aufgabe + Orte von Vorbereitung/Verhandlung/Entscheidung/Freigabe (O06) |
| `Raeume` | 4 | 26 | Geschäftsräume, Verfügungsmöglichkeiten |
| `Arbeitsmittel` | 4 | 26 | Arbeitsmittel, Fahrzeuge, IT, Software |
| `Ressourcennutzungen` | 4 | 15 | n:m Raum/Mittel × Person × Aufgabe |
| `Kosten` | 4 | 17 | Kostenposition |
| `Kostenverteilungen` | 4 | 10 | Weiterberechnung |
| `Abrechnungen` | 4 | 16 | Tatsächlich gestellte Abrechnungen |
| `Belegverknuepfungen` | 5 | 7 | Generische Verknüpfung Nachweis → Zielzeile |
| `OffenePunkte` | 5 | 10 | Fehlende Angaben/Nachweise |
| `InterneBewertungen` | — (nur intern) | 13 | Auswertungshilfen, eingeschränkte Berechtigungen |

**Gesamt: 25 Listen + 1 Dokumentbibliothek, 364 Spalten, 5 Formularblätter.**

## 3. Begründete Listensplits (zusammengesetzte B1-Zeilen aufgeteilt)

Anhang B1 fasst mehrere Listen in einzelnen Tabellenzeilen zusammen (z. B. "Gesellschaften / Personen / Orte", "Kontrollaufgaben / Steuerungsbeziehungen"). Jede Aufteilung in mehrere tatsächliche SharePoint-Listen ist hier begründet:

| B1-Zeile | Aufgeteilt in | Begründung |
|---|---|---|
| "Gesellschaften / Personen / Orte" | `Gesellschaften`, `Personen`, `Orte` | Drei inhaltlich unabhängige Stammdatenobjekte mit unterschiedlichen Attributen (Name/Rolle, Name, Adresse/Kategorie) und unterschiedlichen Referenzierungsmustern — eine gemeinsame Liste würde Spalten mit grossteils leeren Werten erzwingen. |
| "Funktionen / Personenbindungen" | `Funktionen`, `Personenbindungen` | **Unterschiedliche Fragetiefe und Kardinalität.** S04 (Funktionen) fragt nur Gesellschaft + Stellenbezeichnung — eine schlanke Navigationsebene, beliebig oft je Person. P30-P38 (Personenbindungen) bildet die tiefere vertragliche/organisatorische Beziehung ab (Vertragsart, Schriftform, Zeitraum, Weisungsgeber, Vertretung) und ist nicht zwingend 1:1 zu einer Funktion (eine Vertragsbeziehung kann mehrere Funktionen abdecken oder umgekehrt). |
| "Kontrollaufgaben / Steuerungsbeziehungen" | `Kontrollaufgaben`, `Steuerungsbeziehungen` | K10-K14 beschreiben Eigenschaften EINER Kontrollaufgabe (ein Datensatz je Aufgabe mit Kontrollbezug). K15-K17 sind eine **n:m-Verknüpfung** (eine Person kann mehrere Mitarbeitende/Dienstleister steuern, jede/r mit eigener Gesellschafts- und Festlegungs-Zuordnung) — strukturell wie die AO-Vorbild-Trennung Taetigkeiten/Steuerungsbeziehungen. |
| "Zeitverteilungen / Aufgabenorte" | `Zeitverteilungen`, `Aufgabenorte` | Beide sind n:m-Verteilungen derselben Zeit aus unterschiedlichen Blickwinkeln (B4), aber mit unterschiedlichem Zielobjekt (Gesellschaft vs. Ort) und `Aufgabenorte` trägt zusätzlich die O05-O08-Spezialfragen (KG-Büro-Aufgabenbezug, Homeoffice-Gründe, Alternativarbeitsplatz) sowie den polymorphen O06-Bezug zu Entscheidungsbefugnissen/Vertragszuständigkeiten/Kontrollaufgaben — inhaltlich zu unterschiedlich für eine gemeinsame Liste. |
| "Raeume / Arbeitsmittel / Ressourcennutzungen" | `Raeume`, `Arbeitsmittel`, `Ressourcennutzungen` | Drei eigenständige Entitäten: Bestandsobjekt Raum, Bestandsobjekt Arbeitsmittel, sowie die n:m-Nutzung durch Personen (R29/A24/A25/A32). Nutzungsdaten leben bewusst getrennt von den Bestandsobjekten, da ein Raum/Mittel mehrere Nutzungsinstanzen haben kann. |
| "Kosten / Kostenverteilungen / Abrechnungen" | `Kosten`, `Kostenverteilungen`, `Abrechnungen` | Kostenposition (C20-C24), ihre Weiterverteilung auf Empfänger (C25-C27, n:m) und tatsächlich gestellte Abrechnungen (C28-C31, eigenständiger Beleg-/Vereinbarungsbezug) sind unterschiedliche Vorgänge mit unterschiedlicher Kardinalität zueinander. |

Nicht aufgeteilt, da B1 bereits 1:1 einer Liste entspricht: `Erfassungen`, `Aufgaben`, `Aufgabenempfaenger`, `Aufgabenzustaendigkeiten`, `Entscheidungsbefugnisse`, `Vertragszustaendigkeiten`, `Substanznachweise`, `Belegverknuepfungen`, `OffenePunkte`, `InterneBewertungen`.

## 4. Polymorphe Bezüge (generische Zielreferenzen)

Zwei Listen verwenden bewusst einen generischen Zielbezug statt vieler meist leerer Einzel-Lookup-Spalten, exakt wie im B1-Entwurf vorgesehen ("keine Mehrfachablage"):

- **`Belegverknuepfungen`** (N21): `ziel_typ` (Choice, alle 25 Listennamen) + `ziel_id` (Text, stabile ID der referenzierten Zeile). Auflösung durch Flow/Kanzlei, kein SharePoint-Lookup je Zielliste.
- **`Aufgabenorte`** (O06): `rollenbezug` (AUSUEBUNG/VORBEREITUNG/VERHANDLUNG/ENTSCHEIDUNG/FREIGABE) plus **vier optionale Lookup-Spalten** (`aufgabe_ref`, `entscheidung_ref`, `vertrag_ref`, `kontrolle_ref`), von denen je Zeile nur eine befüllt ist — hier echte SharePoint-Lookups statt Text-ID, da die Zielmenge klein und stabil ist (vier statt 25 mögliche Ziele) und Lookup-Integrität (ShowField `display_label`) einen echten Mehrwert für Auswertungen bietet.
- **`OffenePunkte`** (N23/N26): `bezug_ziel_typ`/`bezug_ziel_id` nach demselben Muster wie `Belegverknuepfungen`, da ein offener Punkt sich auf eine beliebige Angabe irgendeiner Liste beziehen kann.

## 5. Wiederverwendung bestehender AO-Listen

Unverändert gegenüber Update 1, erneut geprüft für Version 3:

| Kandidat (DE/AO) | Entscheidung | Begründung |
|---|---|---|
| `Eingang_Fehler` | **Wiederverwendet** (unverändert) | Generisches, modul-unabhängiges Fehlerprotokoll. Formular-Nr.-Konvention für dieses Modul: 301-305 (siehe `sharepoint-forms/README.md`), um Kollision mit AO (0-8) und früheren Modul-Versionen (101-111, 201-207) zu vermeiden. |
| `4_Beteiligte_und_Quoten` | **Nur als optionaler Cross-Reference-Lookup** | `Gesellschaften.ao_participation_ref` verweist optional auf einen bereits erfassten AO-Beteiligungsdatensatz, ohne dessen Quote zu übernehmen — konsistent mit "Beteiligungsverhältnisse werden nicht erneut erhoben" (Abschnitt 1.1). |
| `0_Fallsteuerung`, `8_Unterlagen`, `3_Personen_und_Vertretung`, `5_Betriebsstaetten` | **Nicht wiederverwendet** | Unverändert: andere Pflichtfeld-Struktur, andere Fallbindung bzw. kein Bezug in Version 3 vorgesehen. |

## 6. InterneBewertungen: eingeschränkte Berechtigungen

Unverändert gegenüber Update 1 (Rechtevererbung gebrochen via `Set-RestrictedPermission`, `List.BreakRoleInheritance($true, $false)`, danach manuelle Nacharbeit der Berechtigungsgruppe — siehe `sharepoint-forms/README.md`, Abschnitt F). Die Bezüge sind an die neue Struktur angepasst: `InterneBewertungen.bezug_typ` unterscheidet jetzt `AUFGABE`/`ENTSCHEIDUNGSBEFUGNIS`/`VERTRAGSZUSTAENDIGKEIT`/`KONTROLLAUFGABE` (statt vormals `TAETIGKEIT`/`FALL`), mit je einer optionalen Lookup-Spalte auf die entsprechende Liste.

## 7. Änderungsprotokoll V2 → V3 (A1-Pflicht: T02/T03, T11/T12, D, V, K, G, O06)

Vorhandene V2-Antworten dürfen **nicht** unverändert als V3-Antworten interpretiert werden (Anhang A1 der V3-Vorgabe). Vollständige, maschinenlesbare Fassung in `feldkatalog/feldkatalog.json`, Schlüssel `aenderungsprotokoll_v2_v3`.

| Bereich | Version 2 | Version 3 |
|---|---|---|
| Grundprinzip | Führung über einen zuletzt abgeschlossenen Geschäftsvorgang (`Taetigkeiten`, `Entscheidungsfaelle`, `Vertragsvorgaenge`, `Fallbeteiligungen`). | Führung über das Tagesgeschäft; `Aufgaben` (wiederkehrende Zuständigkeit) ist die führende Einheit. Keine Vorgangsliste mehr. |
| S02 | Eigene Forms-Frage "Wer füllt dieses Formular aus?". | Gestrichen. Technisch aus Forms-Metadaten übernommen; Rückfragekontakt über N24. |
| T02/T03 | T02 = Auftrag/Funktion-ähnliche Frage; T03 analog zur Grobvorgabe. | T02 = Art/Dauerhaftigkeit der Aufgabenwahrnehmung. T03 = Beginn der Aufgabe (nicht des Vertragsverhältnisses — dafür P33). |
| T11/T12 | Nicht vorhanden in dieser Form. | Neu: unterschiedliche Zuständigkeiten innerhalb eines Aufgabenbereichs und deren Verteilung. |
| D (Entscheidungen) | `Entscheidungsfaelle` als eigenständige Vorgangsliste, ein Fall = eine abgeschlossene Entscheidung mit Pflichtdatum/-ergebnis/-nachweis. | `Entscheidungsbefugnisse` als wiederkehrende Zuständigkeit je Aufgabe × Entscheidungsart; kein abgeschlossener Fall nötig, Einzelfall nur optionaler Nachweis. |
| V (Verträge) | `Vertragsvorgaenge` als eigenständige Vorgangsliste, ein Vorgang = ein konkret beschriebener Vertrag. | `Vertragszustaendigkeiten` als wiederkehrende Zuständigkeit je Aufgabe × Vertragsart; Einzelvertrag nur bei gezielter Beleglücke. |
| K (Kontrolle) | Kontrollgegenstand/Reaktion/Schulung als `Taetigkeiten`-Zusatzspalten plus optionaler Einzelfallbericht (K05). | `Kontrollaufgaben` + `Steuerungsbeziehungen` als wiederkehrende Aufgaben; kein Einzelfallbericht mehr. |
| G (Eigene Aufgaben/Mutter) | `Taetigkeiten`-Zusatzspalten plus `Abrechnungen` (G06). | Zusatzspalten auf `Aufgaben`/`Aufgabenempfaenger`/`Aufgabenzustaendigkeiten`, erweitert um Organisationsregel (G14) und Vertretung (G15). |
| O06 | Ort je Verfahrensschritt als Spalten auf `Fallbeteiligungen` (gebunden an einen konkreten Fall). | `Aufgabenorte` mit Rollenbezug und polymorphem Bezug auf `Aufgaben`/`Entscheidungsbefugnisse`/`Vertragszustaendigkeiten`/`Kontrollaufgaben` — keine Fallbindung mehr. |

## 8. Offene Punkte (geprüft gegenüber Update 1)

### Durch Version 3 erledigt

- **FallID-Frage:** gestrichen, da keine Vorgangsliste mehr existiert (Vorgabe Nr. 2 dieses Updates). Keine Entsprechung mehr im Feldkatalog.
- **Zugriffsschutz der öffentlichen Formulare** (vormals offene Frage 1): weiterhin **nicht** gelöst — Version 3 sieht ebenfalls keinen `access_code`-Mechanismus vor ("Erfassungsreferenzen sind keine Berechtigungsnachweise", Anhang B3). Bleibt offen (siehe unten).
- **Vertragsvorgaenge-FallID-Interpretation** (vormals offene Frage 3): gegenstandslos, da `Vertragsvorgaenge` entfällt.
- **Stammdaten-Reichweite Gesellschaften/Personen** (vormals offene Frage 4): durch B1 bestätigt ("Verifizierter Bestand; bestehende Struktur nicht erneut erheben") — erfassungsübergreifende Stammdaten sind die richtige Modellierung, erledigt.
- **N01-Bereichscodes** (vormals offene Frage 5): gegenstandslos, N01 existiert in V3 nicht mehr in dieser Form (ersetzt durch die laufende Aufgabenerhebung).

### Weiterhin bzw. neu offen

1. **Zugriffsschutz der öffentlichen Formulare:** Anhang B3 stellt ausdrücklich fest, dass Erfassungsreferenzen keine Berechtigungsnachweise sind, ohne ein Gegenmittel vorzugeben. Bitte bestätigen, ob ein Zugangscode-Mechanismus ergänzt werden soll oder eine andere Absicherung (z. B. nur personalisierte Links) ausreicht.
2. **`InterneBewertungen` — Berechtigungsgruppe:** weiterhin offen (siehe Abschnitt 6); muss nach dem ersten Skriptlauf manuell eingetragen werden.
3. **R26 als sechs Einzelfragen:** Die Vorgabe verlangt ausdrücklich "je eine Einzelfrage" statt einer MultiChoice — damit entstehen sechs separate Ja/Nein/unbekannt-Spalten auf `Raeume`. Bitte bestätigen, dass diese Granularität (statt einer kompakteren MultiChoice) gewünscht bleibt, da sie das Formular spürbar verlängert.
4. **H-Handlungen als 3 MultiChoice-Spalten statt 45 Einzelspalten:** Modellierungsentscheidung dieses Updates (Abschnitt 1) — bitte bestätigen, dass die kompakte SharePoint-Ablage (3 Spalten) bei unveränderter Forms-Einzelfragen-Darstellung ausreicht, oder ob eine granularere Ablage (z. B. 45 Einzelspalten für feingranulare Auswertungen je Handlung) gewünscht ist.
5. **Aufgabenorte als Sammelliste für O01/O02 und O06:** Diese Zusammenlegung (Abschnitt 4) ist eine Modellierungsentscheidung dieses Updates, da B1 keine getrennten Listen für "Arbeitsort" und "Ort der Entscheidungsfindung" vorsieht. Bitte bestätigen oder eine Trennung anfordern, falls die Auswertung getrennte Sichten benötigt.
