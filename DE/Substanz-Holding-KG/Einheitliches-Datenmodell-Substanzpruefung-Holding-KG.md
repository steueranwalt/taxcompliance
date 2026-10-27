# Einheitliches Datenmodell: Substanzprüfung Holding-KG (Version 3)

**Stand:** 27.10.2026, **Update 3** (ergänzt Update 2 um die Entscheidungen von Nils Obenhaus zu den fünf zuvor offenen Punkten; Schema bleibt SchemaVersion 3, siehe Abschnitt 9).

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
- **H-Handlungen als Einzelfragen.** Die 45 Handlungen aus Abschnitt 1.2 werden in Forms als einzelne Fragen mit den Antworten ausgeführt/nicht ausgeführt/nicht bekannt gestellt (B3) — in SharePoint kompakt als drei MultiChoice-Spalten auf `Personeneinsaetze` abgelegt (bestätigt, Update 3), da eine 1:1-Abbildung als 45 Einzelspalten keinen Mehrwert böte und die Forms-Darstellung davon unberührt bleibt. Ein Handlungscode, der in **keiner** der drei Spalten steht, bedeutet "nicht gefragt" (zugehöriger Bereich in S07 nicht ausgewählt), nicht "nicht bekannt". Der Flow prüft zusätzlich, dass derselbe Handlungscode nicht in mehr als einer der drei Spalten vorkommt (siehe `sharepoint-forms/README.md`); Auswertungen je einzelner Handlung müssen alle drei Spalten auflösen.
- **Erfassungsreferenz als Plausibilitätsprüfung (nicht Berechtigungsnachweis).** Da die Formulare öffentlich bleiben ("Jeder kann antworten", keine Gästekonten), trägt jedes der fünf Formulare ein Pflichtfeld Erfassungsreferenz (`Erfassungen.referenzcode`). Der Flow prüft Referenz und Status der Erfassung vor jeder Elementanlage; bei ungültiger oder bereits abgeschlossener Referenz erfolgt die Ablage in `Eingang_Fehler` statt in den Fachlisten. Dies ist **keine Zugriffskontrolle**, sondern eine Plausibilitätsprüfung — der Link wird ausschliesslich an den jeweiligen Mandanten versendet, und Antwortende können ohnehin keine fremden Daten einsehen, da Forms keine Leserechte auf die SharePoint-Listen gewährt. Siehe `sharepoint-forms/README.md`, Abschnitt D.
- **InterneBewertungen je Standort getrennt.** `InterneBewertungen` wird nicht als einzelne Liste, sondern als eine Liste je Standort (`InterneBewertungen_ZH`, `InterneBewertungen_HH`) mit gebrochener Rechtevererbung auf Listenebene angelegt (kein Item-Level-Permissioning). Die Gruppe `steueranwaltskanzlei` erhält Zugriff auf alle Standort-Listen, die Standort-Gruppen (z. B. "Substanzprüfung ZH"/"Substanzprüfung HH") nur auf ihre eigene. Alle übrigen Fachlisten (Mandantendaten) bleiben gemeinsam/ungetrennt — siehe Abschnitt 6 und offener Punkt 1 in Abschnitt 8.
- **S02 entfällt.** Die ausfüllende Person wird technisch aus den Forms-Metadaten (Responder/Absender) übernommen, nicht als Frage gespeichert. Der Rückfragekontakt bleibt eine eigene Frage (N24 → `Erfassungen.auskunftsperson_ref`).
- **Vier getrennte Prüfzustände statt Ja/Nein.** «Nicht bekannt», «nicht zutreffend», «nicht gefragt» (durch Verzweigung einfach nicht angezeigt — kein gespeicherter Wert) und Null (echte 0 bzw. leer) werden getrennt gehalten (B4). Deshalb sind etliche auf den ersten Blick binäre Fragen als 3- oder 4-wertige Choice statt als SharePoint-Boolean angelegt (z. B. `Aufgabenzustaendigkeiten.t15_geaendert`, `Kostenverteilungen.zuschlag`) — ein SharePoint-Boolean kann kein "nicht bekannt" ohne stillschweigenden `false`-Default abbilden.
- **Ermittelt vs. geschätzt getrennt.** Jede Zahlenfrage, bei der die Vorgabe ausdrücklich zwischen "aus Unterlagen ermittelt" und "geschätzt" unterscheidet, erhält eine eigene Status-Spalte (Codebook `ERMITTLUNGSART`) neben dem Zahlenfeld (z. B. `Personeneinsaetze.gesamtstunden_status`/`.gesamtstunden`).
- **Keine Summenkorrektur auf 100 %.** Orts- und Empfängerverteilung (`Aufgabenorte`, `Zeitverteilungen`) verteilen dieselbe Zeit aus unterschiedlichen Blickwinkeln und werden **nicht** automatisch auf 100 % normalisiert; unzugeordnete Restzeit wird ausdrücklich als eigener Status (`Z08_STATUS_REST_NICHT_ZUGEORDNET`) offengehalten statt stillschweigend verteilt.
- **Aufgabenreferenz statt Neubeschreibung.** Formulare, die sich auf bereits erfasste Aufgaben beziehen (z. B. O05 "welche der bereits genannten Aufgaben"), referenzieren diese über Lookup (`LookupMulti` auf `Aufgaben`) statt die Tätigkeit erneut zu beschreiben.
- **Stabile Codes statt deutscher Beschriftung in SharePoint.** Wie in Version 2: Choice-/MultiChoice-Spalten speichern den stabilen Code (z. B. `FREQ_DAILY`), die deutsche Beschriftung lebt im Feldkatalog (`codebooks`) und wird vom Flow verwendet, um die in Forms gewählte Bezeichnung vor der Elementanlage zu übersetzen.

## 2. Listenübersicht mit Spaltenzahl

24 gemeinsame Listen + Dokumentbibliothek `Substanznachweise` + eine Liste `InterneBewertungen_<Standort>` je Eintrag im Skriptparameter `-Standort` (Default: nur `InterneBewertungen_ZH`) = standardmässig 26 Objekte, 367 Spalten gesamt (automatisiert aus `feldkatalog/feldkatalog.json` ausgezählt, gegen das PnP-Skript geprüft: keine Duplikate, keine fehlenden Codebook-Referenzen, keine Lookup-Vorwärtsreferenzen). Bei zusätzlichem Standort HH kommen ein weiteres Objekt und 13 weitere Spalten hinzu (`InterneBewertungen_HH`, schemagleich zu `InterneBewertungen_ZH`).

| Liste/Bibliothek | Formular (B1) | Spalten | Rolle |
|---|---|---|---|
| `Personen` | 1 | 3 | Stammdaten, erfassungsübergreifend |
| `Erfassungen` | intern/5 | 13 | Fallsteuerung; Auskunftsperson aus N24; Erfassungsreferenz + Formular-Enddatum (Update 3) |
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
| `Aufgabenorte` | 3 | 16 | Arbeitsorte je Aufgabe (`bezugsart` = Arbeitszeit-Ort) + Orte von Vorbereitung/Verhandlung/Entscheidung/Freigabe (`bezugsart` = Funktionsort, O06, Update 3) |
| `Raeume` | 4 | 26 | Geschäftsräume, Verfügungsmöglichkeiten |
| `Arbeitsmittel` | 4 | 26 | Arbeitsmittel, Fahrzeuge, IT, Software |
| `Ressourcennutzungen` | 4 | 15 | n:m Raum/Mittel × Person × Aufgabe |
| `Kosten` | 4 | 17 | Kostenposition |
| `Kostenverteilungen` | 4 | 10 | Weiterberechnung |
| `Abrechnungen` | 4 | 16 | Tatsächlich gestellte Abrechnungen |
| `Belegverknuepfungen` | 5 | 7 | Generische Verknüpfung Nachweis → Zielzeile |
| `OffenePunkte` | 5 | 10 | Fehlende Angaben/Nachweise |
| `InterneBewertungen_ZH` / `InterneBewertungen_HH` | — (nur intern) | 13 je Standort | Auswertungshilfen, eigene Liste je Standort mit eingeschränkten Berechtigungen (Update 3) |

**Gesamt (Default, nur Standort ZH): 24 gemeinsame Listen + 1 Dokumentbibliothek + 1 `InterneBewertungen_ZH` = 26 Objekte, 367 Spalten, 5 Formularblätter.**

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
- **`Aufgabenorte`** (O01/O02/O06, Update 3): eine **Pflicht-Spalte** `bezugsart` (`ARBEITSZEIT_ORT` für O01/O02, mit Stunden/Anteilen; `FUNKTIONSORT` für O06, ohne Stunden/Anteile) ersetzt den vormaligen `rollenbezug`. Bei `bezugsart = FUNKTIONSORT` wird zusätzlich `funktion` (Vorbereitung/Verhandlung/Entscheidung/Freigabe) gesetzt. Dazu **vier optionale Lookup-Spalten** (`aufgabe_ref`, `entscheidung_ref`, `vertrag_ref`, `kontrolle_ref`), von denen je Zeile nur eine befüllt ist — hier echte SharePoint-Lookups statt Text-ID, da die Zielmenge klein und stabil ist (vier statt 26 mögliche Ziele) und Lookup-Integrität (ShowField `display_label`) einen echten Mehrwert für Auswertungen bietet. Zeilen mit `bezugsart = FUNKTIONSORT` dürfen keine Stunden/Prozentwerte (`o02_status`/`o02_stunden`/`o02_prozent`) tragen; der Flow validiert dies, um Doppelzählung zwischen Arbeitszeit- und Funktionsort-Zeilen zu verhindern (siehe `sharepoint-forms/README.md`).
- **`OffenePunkte`** (N23/N26): `bezug_ziel_typ`/`bezug_ziel_id` nach demselben Muster wie `Belegverknuepfungen`, da ein offener Punkt sich auf eine beliebige Angabe irgendeiner Liste beziehen kann.

## 5. Wiederverwendung bestehender AO-Listen

Unverändert gegenüber Update 1, erneut geprüft für Version 3:

| Kandidat (DE/AO) | Entscheidung | Begründung |
|---|---|---|
| `Eingang_Fehler` | **Wiederverwendet** (unverändert) | Generisches, modul-unabhängiges Fehlerprotokoll. Formular-Nr.-Konvention für dieses Modul: 301-305 (siehe `sharepoint-forms/README.md`), um Kollision mit AO (0-8) und früheren Modul-Versionen (101-111, 201-207) zu vermeiden. |
| `4_Beteiligte_und_Quoten` | **Nur als optionaler Cross-Reference-Lookup** | `Gesellschaften.ao_participation_ref` verweist optional auf einen bereits erfassten AO-Beteiligungsdatensatz, ohne dessen Quote zu übernehmen — konsistent mit "Beteiligungsverhältnisse werden nicht erneut erhoben" (Abschnitt 1.1). |
| `0_Fallsteuerung`, `8_Unterlagen`, `3_Personen_und_Vertretung`, `5_Betriebsstaetten` | **Nicht wiederverwendet** | Unverändert: andere Pflichtfeld-Struktur, andere Fallbindung bzw. kein Bezug in Version 3 vorgesehen. |

## 6. InterneBewertungen: eingeschränkte Berechtigungen je Standort (Update 3)

Die Bezüge sind an die neue Struktur angepasst: `InterneBewertungen.bezug_typ` unterscheidet `AUFGABE`/`ENTSCHEIDUNGSBEFUGNIS`/`VERTRAGSZUSTAENDIGKEIT`/`KONTROLLAUFGABE`, mit je einer optionalen Lookup-Spalte auf die entsprechende Liste (unverändert gegenüber Update 2).

**Neu in Update 3 — Standort-Trennung nach Entscheidung Nils:** Die Gruppe `steueranwaltskanzlei` soll alle internen Bewertungen sehen können, die Gruppen am Standort ZH bzw. HH jeweils nur ihre eigenen. Da SharePoint-Standardlisten keine granulare Item-Level-Berechtigung auf Gruppenebene bieten, die sich sauber pflegen lässt, wird dies über **eine eigene Liste je Standort** gelöst statt über Item-Level-Permissioning auf einer gemeinsamen Liste:

- `InterneBewertungen_ZH`, `InterneBewertungen_HH` — identisches Schema (13 Spalten, siehe Abschnitt 2), eigenständige physische Listen.
- Jede Liste bricht ihre Rechtevererbung **ohne** die bestehenden Site-Berechtigungen zu kopieren (`BreakRoleInheritance($false, $false)`, bewusste Änderung gegenüber dem `$true` aus Update 1/2 — "fail closed": die Liste ist nach dem Brechen für niemanden ausser Site Collection Administrators sichtbar, bis eine Gruppe erfolgreich berechtigt wurde).
- Zugriff (**Bearbeiten**, nicht nur Lesen) wird danach gezielt je Gruppe vergeben: die standortspezifische Gruppe nur auf ihre eigene Liste, die Gesamtgruppe (`steueranwaltskanzlei`) auf alle angelegten Standort-Listen.

**Skriptparameter** (`New-SubstanzHoldingKGListen.ps1`), Default-Gruppennamen von Nils bestätigt:

| Parameter | Typ/Default | Zweck |
|---|---|---|
| `-Standort` | `string[]`, `ValidateSet('ZH','HH')`, Default `@('ZH')` | Für welche Standorte eine `InterneBewertungen_<Standort>`-Liste angelegt/angeglichen wird. Default nur ZH, da laut Nils fast ausschliesslich ZH-Fälle vorkommen. |
| `-StandortGruppen` | `hashtable`, Default `@{ ZH = 'Kanzlei ZH'; HH = 'Kanzlei-HH' }` | Zuordnung Standort → Gruppenname mit Zugriff auf die jeweilige Standort-Liste. Schreibweise exakt wie von Nils vorgegeben: ZH mit Leerzeichen, HH mit Bindestrich. |
| `-GesamtGruppe` | `string`, Default `'steueranwaltskanzlei'` | Gruppenname, der auf **allen** angelegten `InterneBewertungen_<Standort>`-Listen Zugriff erhält. |

**SharePoint-Gruppe oder Microsoft-365-/Entra-ID-Gruppe.** Da die Kanzlei möglicherweise mit M365-/Entra-ID-Gruppen statt klassischen SharePoint-Gruppen arbeitet, löst das Skript jeden der drei Gruppennamen in dieser Reihenfolge auf: (1) SharePoint-Gruppe der Zielsite, (2) Microsoft-365-Gruppe nach Anzeigename, (3) sonstige Entra-ID-Gruppe (z. B. Security-Gruppe) nach Anzeigename. Bei (2)/(3) wird die Gruppe über ihre E-Mail-Adresse (bzw. bei fehlendem Mail-Attribut über das Claims-Login-Format) als SharePoint-Principal aufgelöst, bevor die Berechtigung gesetzt wird. Welcher Principal-Typ und -Name tatsächlich berechtigt wurde, wird im Skriptlog ausgegeben.

**Berechtigungsstufe sprachunabhängig.** Da der interne Name der Berechtigungsstufe "Bearbeiten" je nach Sprache der Zielsite unterschiedlich heisst, probiert das Skript nacheinander `"Bearbeiten"` und `"Edit"` und verwendet den ersten Namen, der auf der Zielsite tatsächlich existiert.

**Idempotenz:** Ein späterer Lauf mit einem zusätzlichen `-Standort`-Wert (z. B. zuerst nur `ZH`, später `ZH,HH`) legt nur die fehlende Liste neu an und lässt bereits bestehende Listen/Berechtigungen unverändert — bestehende Listen werden nie gelöscht oder umbenannt.

**Keine Rechtevergabe ohne aufgelöste Gruppe (Warnung statt Fehler):** Lässt sich ein Gruppenname in keiner der drei Formen auflösen (oder fehlt er ganz), bricht das Skript die Vererbung trotzdem (die Liste bleibt also gesperrt), gibt aber nur eine `Write-Warning` aus und läuft weiter — es wird nie automatisch eine breite Berechtigung vergeben, nur weil ein Gruppenname nicht gefunden wurde.

Die übrigen 24 Fachlisten (Mandantendaten) bleiben unverändert gemeinsam — siehe offenen Punkt 1 in Abschnitt 9 zur Frage, ob auch dort eine Standorttrennung nötig ist.

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
| O06 | Ort je Verfahrensschritt als Spalten auf `Fallbeteiligungen` (gebunden an einen konkreten Fall). | `Aufgabenorte` mit polymorphem Bezug auf `Aufgaben`/`Entscheidungsbefugnisse`/`Vertragszustaendigkeiten`/`Kontrollaufgaben` — keine Fallbindung mehr. Rollenbezug-Spalte in Update 3 durch `bezugsart`/`funktion` ersetzt, siehe Abschnitt 8. |

## 8. Änderungsprotokoll Update 2 → Update 3 (Entscheidungen Nils zu den fünf offenen Punkten)

Nils Obenhaus hat die fünf am Ende von Update 2 offenen Punkte wie folgt entschieden; Umsetzung in diesem Update:

| Offener Punkt (Update 2) | Entscheidung | Umsetzung |
|---|---|---|
| 1. Zugriffsschutz der öffentlichen Formulare | Forms bleibt öffentlich ("Jeder kann antworten", keine Gästekonten). Schutz ohne Hürden: Link nur an den Mandanten, Pflichtfeld Erfassungsreferenz, Formular-Enddatum. | `Erfassungen.referenzcode` (Pflichtfeld, indiziert/eindeutig) + `Erfassungen.formular_enddatum` neu angelegt; Flow prüft Referenz + Status vor Elementanlage, Fehlfälle → `Eingang_Fehler` (siehe Abschnitt 1, `sharepoint-forms/README.md` Abschnitt D). Ausdrücklich als Plausibilitätsprüfung dokumentiert, nicht als Berechtigungsnachweis. |
| 2. `InterneBewertungen` nach Standort | Eigene Liste je Standort (`InterneBewertungen_ZH`/`_HH`), gebrochene Vererbung auf Listenebene, kein Item-Level-Permissioning. Skriptparameter für Standorte und Gruppennamen, Default nur ZH, idempotent, keine Rechtevergabe ohne Gruppenname. Konkrete Gruppennamen (`steueranwaltskanzlei`, `Kanzlei ZH`, `Kanzlei-HH`) sowie Unterstützung für SharePoint- UND M365-/Entra-ID-Gruppen nachgereicht. | Siehe Abschnitt 6 (neu) und `-Standort`/`-StandortGruppen`/`-GesamtGruppe` in `New-SubstanzHoldingKGListen.ps1` (Default-Gruppennamen gesetzt, `Grant-ListAccess` löst SharePoint- oder M365-/Entra-ID-Gruppen auf, Berechtigungsstufe Bearbeiten). Neuer offener Punkt zu Mandantendaten-Standorttrennung in Abschnitt 9. |
| 3. R26 als sechs Einzelfragen | Bestätigt, keine Änderung. | Keine Codeänderung nötig; `Raeume.r26_*` bleibt sechs einzelne Ja/Nein/unbekannt-Spalten. |
| 4. H-Handlungen als 3 MultiChoice-Spalten | Bestätigt. Ergänzung: kein Handlungscode darf in mehr als einer der drei Spalten vorkommen; Auswertungen je Handlung müssen alle drei Spalten auflösen. | Dokumentationshinweise an `handlungen_ausgefuehrt`/`handlungen_nicht_ausgefuehrt`/`handlungen_unbekannt` ergänzt (Feldkatalog); neue Flow-Prüfregel in `sharepoint-forms/README.md`. |
| 5. `Aufgabenorte` als Sammelliste O01/O02 + O06 | Bestätigt, mit neuer Pflicht-Spalte `Bezugsart` (Arbeitszeit-Ort vs. Funktionsort mit Funktion Vorbereitung/Verhandlung/Entscheidung/Freigabe). Funktionsort-Zeilen ohne Stunden/Anteile; Validierung gegen Doppelzählung. | `Aufgabenorte.rollenbezug` ersetzt durch `bezugsart` (Pflicht) + `funktion` (bedingt); neue Codebooks `AUFGABENORT_BEZUGSART`/`AUFGABENORT_FUNKTION`. Siehe Abschnitt 4. |

## 9. Offene Punkte (geprüft gegenüber Update 1)

### Durch Version 3 erledigt

- **FallID-Frage:** gestrichen, da keine Vorgangsliste mehr existiert (Vorgabe Nr. 2 dieses Updates). Keine Entsprechung mehr im Feldkatalog.
- **Vertragsvorgaenge-FallID-Interpretation** (vormals offene Frage 3): gegenstandslos, da `Vertragsvorgaenge` entfällt.
- **Stammdaten-Reichweite Gesellschaften/Personen** (vormals offene Frage 4): durch B1 bestätigt ("Verifizierter Bestand; bestehende Struktur nicht erneut erheben") — erfassungsübergreifende Stammdaten sind die richtige Modellierung, erledigt.
- **N01-Bereichscodes** (vormals offene Frage 5): gegenstandslos, N01 existiert in V3 nicht mehr in dieser Form (ersetzt durch die laufende Aufgabenerhebung).

### Durch Update 3 (Entscheidungen Nils) erledigt

- **Zugriffsschutz der öffentlichen Formulare:** entschieden — Forms bleibt öffentlich, Schutz über Pflichtfeld Erfassungsreferenz + Formular-Enddatum + Versand des Links ausschliesslich an den Mandanten (siehe Abschnitt 1 und 8, `sharepoint-forms/README.md` Abschnitt D). Ausdrücklich als Plausibilitätsprüfung dokumentiert, nicht als Berechtigungsnachweis; Antwortende können keine fremden Daten einsehen.
- **`InterneBewertungen` — Berechtigungsgruppe:** entschieden — eigene Liste je Standort mit Skriptparametern für Gruppennamen (siehe Abschnitt 6); die konkreten Gruppennamen sind beim tatsächlichen Skriptlauf als Parameter zu übergeben.
- **R26 als sechs Einzelfragen:** bestätigt, keine Änderung nötig.
- **H-Handlungen als 3 MultiChoice-Spalten statt 45 Einzelspalten:** bestätigt, ergänzt um die Flow-Prüfregel zur Spalten-Exklusivität (siehe Abschnitt 1 und 8).
- **Aufgabenorte als Sammelliste für O01/O02 und O06:** bestätigt, mit neuer Pflicht-Spalte `Bezugsart`/`Funktion` statt `Rollenbezug` (siehe Abschnitt 4 und 8).

### Weiterhin bzw. neu offen

1. **Standorttrennung auch für Mandantendaten?** Nils hat die Standorttrennung ausdrücklich nur für `InterneBewertungen` entschieden; die übrigen 24 Fachlisten (Mandantendaten: Personen, Gesellschaften, Aufgaben usw.) bleiben bewusst gemeinsam. Sollte sich aus Datenschutz- oder Mandatstrennungsgründen herausstellen, dass auch Mandantendaten je Standort getrennt werden müssen, ist dies ein **separater, deutlich grösserer Umbau** (jede Fachliste bräuchte entweder eine eigene Standort-Spalte mit Item-Level-Berechtigung oder eine vollständige Listen-Duplizierung je Standort) und wird hiermit ausdrücklich als offener Punkt gemeldet, nicht umgesetzt (Vorgabe Nils: "falls nötig, als offenen Punkt melden, nicht umbauen").
2. ~~**Konkrete Gruppennamen für `-StandortGruppen`/`-GesamtGruppe`.**~~ **Erledigt:** Nils hat die Gruppennamen bestätigt — Gesamtgruppe `steueranwaltskanzlei`, Standort ZH `Kanzlei ZH` (mit Leerzeichen), Standort HH `Kanzlei-HH` (mit Bindestrich). Als Default-Werte im Skript hinterlegt (siehe Abschnitt 6); das Skript akzeptiert sowohl klassische SharePoint-Gruppen als auch Microsoft-365-/Entra-ID-Gruppen mit diesen Namen. Vor dem ersten echten Lauf ist nur noch zu prüfen, ob die Gruppen im Zieltenant tatsächlich existieren (Log-Ausgabe von `Grant-ListAccess` zeigt den aufgelösten Principal je Gruppe).
