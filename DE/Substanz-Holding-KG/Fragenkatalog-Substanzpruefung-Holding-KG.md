# Fragenkatalog: Personen und tatsächlich ausgeübte Managementtätigkeiten (Version 3)

**Stand:** 27.10.2026 (Update 2). **Fachliche Vorgabe:** Nils Obenhaus, Erfassungsbogen Holding-KG, **Version 3**, Projekt 22032-2 «Atwork wg Holding-KG». Version 3 **ersetzt** die Versionen 1 und 2 vollständig. Kernänderung: Gegenstand ist das **Tagesgeschäft**, nicht einzelne Vorgänge; Bezugseinheit ist die tatsächlich ausgeübte Aufgabe je Person, Gesellschaft und Zeitraum.

**Zweck dieses Dokuments:** vollständiger Fragenkatalog mit stabilen Frage-IDs, für jede Frage getrennt in **Mandantensicht** (Wortlaut und Auswahlwerte, wie sie im jeweiligen Formular erscheinen) und **internen Hinweis** (Antworttyp, Verzweigungs-/Datenmodellbezug — erscheint nicht im Mandanten-Formular). Die maschinenlesbare Entsprechung steht in [`feldkatalog/feldkatalog.json`](feldkatalog/feldkatalog.json) (SchemaVersion 3); das Datenmodell in [`Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md`](Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md). Interne Anhänge A–E (siehe unten) erscheinen **nie** in der Mandantensicht.

**S02 entfällt** (Vorgabe Nils): Die ausfüllende Person wird **technisch aus den Forms-Metadaten (Responder/Absender)** übernommen, nicht per Frage erhoben. Der Rückfragekontakt bleibt eine eigene Frage (N24).

**Legende Antworttyp:** E = Einfachauswahl, M = Mehrfachauswahl, T = Text, Z = Zahl, D = Datum. «Nicht bekannt», «nicht zutreffend», «nicht gefragt» (durch Verzweigung einfach nicht angezeigt) und Null (echte 0 bzw. leer) werden getrennt gespeichert — nie wird «nicht bekannt» als 0 abgelegt.

## Hinweise für die ausfüllende Person (Mandantensicht, Formularanfang)

Mit diesen Angaben erfassen wir, wie die Holding-KG tatsächlich arbeitet. Bitte beziehen Sie Ihre Antworten auf den angegebenen Zeitraum. Schätzungen und geplante Tätigkeiten können Sie ausdrücklich kennzeichnen. Fehlende Angaben und Unterlagen können anschliessend geklärt werden.

Beginnen Sie mit einer Person. Danach werden nur die für deren Aufgaben passenden Fragen benötigt. Angaben zu Räumen, Arbeitsmitteln und Kosten können die dafür zuständigen Personen ergänzen. Bereits erfasste Aufgaben und bereits übermittelte Unterlagen müssen nicht nochmals eingegeben werden.

Auswahlfelder enthalten bei Bedarf «anderes, bitte angeben», «nicht bekannt» oder «nicht zutreffend». Diese Antworten werden getrennt gespeichert.

## 1. Person und Aufgabenüberblick (Formular 1 — Personenblatt)

### 1.1 Vorbereitete Angaben bestätigen

Zeitraum und bekannte Gesellschaften werden durch die Kanzlei eingesetzt. Die Konzernstruktur wird nicht erneut erhoben. Namen und Funktionen werden nur vorausgefüllt, soweit sie aus dem Projektbestand verifiziert sind. Für jede Person ein eigenes Personenblatt.

**S01.** Für welchen Zeitraum gelten die folgenden Angaben?

- *Mandantensicht:* Vorgegebener Zeitraum: bestätigen / korrigieren. Bei Korrektur Beginn und Ende als Datumsfelder.
- *Interner Hinweis:* Ziel: `Erfassungen.period_from`/`.period_to`/`.period_confirmed`.

~~**S02.**~~ Wer füllt dieses Personenblatt aus? — **gestrichen (Vorgabe Nils).** Ausfüllende Person wird technisch aus Forms-Absender/Metadaten erfasst, nicht abgefragt.

**S03.** Welche Person wird beschrieben?

- *Mandantensicht:* Bekannte Person auswählen / weitere Person ergänzen. Bei neuer Person Vorname und Nachname eingeben.
- *Interner Hinweis:* Ziel: `Personen.person_name`.

**S04.** Welche Funktion hat diese Person?

- *Mandantensicht:* Je Funktion ein Eintrag: Gesellschaft auswählen; Stellenbezeichnung angeben. Mehrere Funktionen sind möglich.
- *Interner Hinweis:* Ziel: `Funktionen` (je Funktion ein Datensatz, eigenständig von `Personenbindungen` — siehe Datenmodell).

**S05.** War die Person im angegebenen Zeitraum im Zusammenhang mit der KG tätig?

- *Mandantensicht:* Ja / nein, Tätigkeit erst geplant / nein, Tätigkeit bereits beendet / nein, keine solche Tätigkeit / nicht bekannt. Nur tatsächliche Tätigkeitszeiträume weiter vertiefen; Planungen gesondert kennzeichnen.
- *Interner Hinweis:* Ziel: `Personeneinsaetze.taetigkeit_status`.

**S06.** Seit wann übernimmt die Person diese Aufgaben tatsächlich?

- *Mandantensicht:* Datum / ungefähres Datum / nicht bekannt. Nur bei beendeter Tätigkeit folgt ein separates Feld zum Enddatum. Änderungen werden später im Aufgabenblatt erfasst.
- *Interner Hinweis:* Anzeige: S05 = ja oder Tätigkeit bereits beendet. Ziel: `Personeneinsaetze.taetigkeit_beginn`/`.taetigkeit_beginn_genauigkeit`/`.taetigkeit_ende`.

**S07.** In welchen Bereichen hat die Person gearbeitet?

- *Mandantensicht:* Kurze Bereichsauswahl, mehrere Antworten möglich: Kunden und Lieferanten / Personal / Finanzen und Berater / Projekte und Unternehmensplanung / Berichte und Kontrolle / Vorgaben und Schulung / eigene Verwaltung der KG / Beteiligungsaufgaben und Arbeiten für die Schweizer Mutter / anderer Bereich. Zusätzlich: Aufgaben derzeit nicht bekannt. Diese Übersicht dient der Navigation; nicht ausgewählte Bereiche gelten nicht automatisch als ausdrücklich verneinte Tätigkeiten.
- *Interner Hinweis:* Anzeige: tatsächliche Tätigkeit vorhanden (S05). Ziel: `Personeneinsaetze.bereiche` (MultiChoice).

### 1.2 Handlungen innerhalb der gewählten Bereiche

Bitte geben Sie für die angezeigten Handlungen jeweils an: ausgeführt / nicht ausgeführt / nicht bekannt. Die Handlungen werden als **einzelne Fragen** mit denselben Antwortmöglichkeiten angezeigt (B3). Die folgende Tabelle zeigt den internen Fragenvorrat, keine grosse Matrix für den Mandanten.

| Bereich | Einzeln abzufragende Handlungen (je als eigene Frage: ausgeführt / nicht ausgeführt / nicht bekannt) |
|---|---|
| Kunden und Lieferanten | Kunden betreut; Angebote ausgearbeitet; Preise festgelegt; Kundenverträge verhandelt; Lieferanten ausgewählt; Lieferantenverträge verhandelt |
| Personal | Bewerber ausgewählt; Vergütung oder Vertragsbedingungen verhandelt; Einstellungen oder Kündigungen entschieden; konkrete Arbeitsaufgaben verteilt; Abwesenheiten genehmigt; Leistungen von Mitarbeitenden beurteilt |
| Finanzen und Berater | Liquidität geplant; Zahlungen freigegeben; Bankgespräche geführt; Finanzierungsbedingungen verhandelt; Buchhalter oder Steuerberater gesteuert; Entscheidungen nach deren Beratung getroffen |
| Projekte und Planung | Projekte geleitet; Kapazitäten oder Termine geplant; betriebliche Probleme entschieden; Budgets vorbereitet; Budgets freigegeben; Investitionen ausgewählt oder freigegeben |
| Berichte und Kontrolle | Berichte erstellt; Berichte geprüft; Erläuterungen angefordert; Massnahmen empfohlen; konkrete Korrekturmassnahmen angeordnet |
| Vorgaben und Schulung | allgemeine Richtlinien entwickelt; allgemeine Vorgaben beschlossen; konkrete Einzelanweisungen gegeben; Mitarbeitende geschult |
| Eigene Verwaltung der KG | eigene Buchführung oder Steuern bearbeitet; eigenes Personal verwaltet; eigene Räume oder Arbeitsmittel verwaltet; eigene IT betreut; eigene Finanzierung bearbeitet; eigene Leistungen abgerechnet |
| Beteiligungen und Mutter | Beteiligungsentwicklung überwacht; Beteiligungserwerb oder -verkauf vorbereitet; Stimmabgaben oder Gesellschafterbeschlüsse vorbereitet; Ausschüttung oder Kapitalmassnahme vorbereitet; Unterlagen für Abschluss oder Konzernabschluss der Mutter erstellt; Sitzungen oder Berichte für die Mutter vorbereitet |

Je gewähltem Bereich folgt zusätzlich: «Welche weitere Aufgabe hat die Person in diesem Bereich ausgeübt?» Antwort: keine weitere / kurze Bezeichnung / nicht bekannt.

*Interner Hinweis:* 45 Handlungen gesamt (Codebook `H_HANDLUNG`), als Forms-Einzelfragen je Bereich; im Datenmodell kompakt als drei MultiChoice-Spalten auf `Personeneinsaetze` gespeichert (`handlungen_ausgefuehrt`, `handlungen_nicht_ausgefuehrt`, `handlungen_unbekannt`). Bestätigte Handlungen werden anschliessend zu Aufgaben zusammengefasst, soweit Auftrag und Empfänger übereinstimmen (Ziel: `Aufgaben.handlungen_bezug`).

## 2. Aufgaben und Zuständigkeiten im Tagesgeschäft (Formular 2 — Aufgabenblatt)

Für jede Person werden die tatsächlich ausgeübten Aufgaben nach Tätigkeitsbereich und betroffener Gesellschaft erfasst. Massgeblich ist die laufende Arbeit im angegebenen Zeitraum.

**T01.** Welche Aufgabe übernimmt die Person im Tagesgeschäft?

- *Mandantensicht:* Bestätigten Aufgabenbereich auswählen und Tätigkeit konkretisieren, etwa «Finanzleitung der Gesellschaft A» oder «Verhandlung von Kundenverträgen für Gesellschaft B».
- *Interner Hinweis:* Ziel: `Aufgaben.bereich_code`, `.t01_text`.

**T02.** Wie ist die Person in diesem Aufgabenbereich tätig?

- *Mandantensicht:* Dauerhaft zuständig / regelmässig mitwirkend / Vertretung / fallweise Unterstützung / ausschliesslich für ein befristetes Projekt / Aufgabe nur geplant / nicht bekannt. Bei fallweiser Tätigkeit den üblichen Anlass kurz angeben.
- *Interner Hinweis:* **Geänderte Bedeutung gegenüber V2** (dort T02 = Auftrag/Funktion-Frage). Ziel: `Aufgaben.t02_art`, `.t02_anlass_text`.

**T03.** Seit wann übt die Person diese Aufgabe aus?

- *Mandantensicht:* Datum / ungefährer Beginn / nicht bekannt. Bei beendeter Tätigkeit Ende separat angeben.
- *Interner Hinweis:* **Geänderte Bedeutung gegenüber V2** (bezieht sich auf die Aufgabe, nicht auf das Vertragsverhältnis — dafür P33). Ziel: `Aufgaben.t03_beginn`/`.t03_beginn_genauigkeit`/`.t03_ende`.

**T04.** Für welche Gesellschaften übernimmt die Person diese Aufgabe?

- *Mandantensicht:* KG selbst / einzelne Beteiligungsgesellschaften / Schweizer Mutter / andere Gesellschaft. Gesellschaften aus dem bekannten Bestand auswählen. Unterschiedliche Aufgaben und Rollen getrennt zuordnen.
- *Interner Hinweis:* Ziel: `Aufgabenempfaenger.gesellschaft_ref`/`.gesellschaft_status` (je Empfänger ein Datensatz).

**T05.** Welche Tätigkeiten führt die Person dabei selbst aus?

- *Mandantensicht:* Informationen auswerten / Entscheidungen vorbereiten / Verträge verhandeln / Entscheidungen treffen / verbindliche Einzelanweisungen geben / Umsetzung steuern / Arbeitsergebnisse kontrollieren / beraten / schulen / administrative Arbeiten ausführen / andere Tätigkeit. Die Auswahl wird anhand der bestätigten Handlungen aus Abschnitt 1 eingegrenzt.
- *Interner Hinweis:* Ziel: `Aufgaben.t05_taetigkeiten` (MultiChoice).

**T06.** Wer legt die Aufgaben und Prioritäten in diesem Bereich fest?

- *Mandantensicht:* Person selbst / benannte Person oder Personen / festgelegte Aufgabenverteilung / wechselnd nach Zuständigkeit / nicht bekannt. Zugehörige Gesellschaft jeweils angeben.
- *Interner Hinweis:* Ziel: `Aufgabenzustaendigkeiten.t06_prioritaet_ref`/`.t06_prioritaet_status`/`.t06_gesellschaft_ref`.

**T07.** In wessen Auftrag übernimmt die Person diese Aufgaben?

- *Mandantensicht:* Im Auftrag der KG / unmittelbar für eine Beteiligung / im Auftrag der Schweizer Mutter / anderer Auftrag / keine gesonderte Beauftragung / nicht bekannt. Bei mehreren Aufträgen Tätigkeiten zuordnen.
- *Interner Hinweis:* Ziel: `Aufgaben.t07_auftrag`.

**T08.** In welcher Funktion ist die Person in diesem Aufgabenbereich tätig?

- *Mandantensicht:* Bekannte Funktion auswählen / andere Funktion / mehrere Funktionen / nicht bekannt. Anstellung, Auftrag und Organfunktion getrennt speichern.
- *Interner Hinweis:* Ziel: `Aufgaben.t08_funktion_ref` (→ `Funktionen`), `.t08_funktion_status`, `.t08_andere_text`.

**T09.** Mit welchen Personen oder Stellen arbeitet sie in diesem Aufgabenbereich regelmässig zusammen?

- *Mandantensicht:* Geschäftsleitung / Fachabteilungen / Mitarbeitende / Kunden / Lieferanten / Banken / Buchhaltung oder Steuerberatung / andere Berater / Gesellschafter oder deren Vertreter / andere Stellen. Jeweils Gesellschaft beziehungsweise Organisation zuordnen.
- *Interner Hinweis:* Ziel: `Aufgaben.t09_zusammenarbeit` (MultiChoice), `.t09_zusammenarbeit_text`.

**T10.** Wem kommen diese Arbeiten unmittelbar zugute?

- *Mandantensicht:* Benannte Beteiligungsgesellschaft bei ihrem laufenden Geschäft / KG bei ihrer eigenen Verwaltung / KG bei der Wahrnehmung ihrer Beteiligungsrechte / Schweizer Mutter bei ihren eigenen Aufgaben / andere Gesellschaft / mehrere Empfänger / Zuordnung nicht bekannt. Bei mehreren Empfängern die Verwendung der Arbeitsergebnisse kurz zuordnen. Der mittelbare Vorteil aus der Beteiligung allein genügt nicht als Antwort.
- *Interner Hinweis:* Ziel: `Aufgabenempfaenger.nutzen_art`, `.verwendung_text`.

**T11.** Bestehen innerhalb dieses Aufgabenbereichs unterschiedliche Zuständigkeiten?

- *Mandantensicht:* Nein / ja, nach Gesellschaft / ja, nach Geschäft oder Betragsgrenze / ja, nach Standort / andere Aufteilung / nicht bekannt.
- *Interner Hinweis:* **Neu gegenüber V2.** Ziel: `Aufgabenzustaendigkeiten.t11_unterschiedlich`.

**T12.** Wie sind diese Zuständigkeiten verteilt?

- *Mandantensicht:* Nur die unterschiedliche Aufgaben- oder Befugnisverteilung beschreiben; bereits erfasste Angaben übernehmen.
- *Interner Hinweis:* Anzeige: T11 benennt unterschiedliche Zuständigkeiten. Ziel: `Aufgabenzustaendigkeiten.t12_text`.

**T13.** Wer übernimmt weitere Teile dieser Aufgabe?

- *Mandantensicht:* Benannte interne Personen / externe Dienstleister / niemand / nicht bekannt. Gesellschaft beziehungsweise Arbeitgeber zuordnen.
- *Interner Hinweis:* Ziel: `Aufgabenzustaendigkeiten.t13_status`, `.t13_personen_ref` (LookupMulti), `.t13_dienstleister_text`, `.t13_gesellschaft_ref`.

**T14.** Wie sind die Arbeiten zwischen diesen Beteiligten verteilt?

- *Mandantensicht:* Eigener Aufgabenanteil und Aufgaben der weiteren Beteiligten kurz abgrenzen; vorhandene Aufgabenbeschreibungen können referenziert werden.
- *Interner Hinweis:* Anzeige: T13 benennt weitere Beteiligte. Ziel: `Aufgabenzustaendigkeiten.t14_aufteilung_text`.

**T15.** Hat sich diese Aufgabenverteilung im Zeitraum geändert?

- *Mandantensicht:* Nein / ja / nicht bekannt. Bei ja Änderungszeitpunkt und geänderte Zuständigkeit getrennt erfassen.
- *Interner Hinweis:* Ziel: `Aufgabenzustaendigkeiten.t15_geaendert` (Choice, 3 Werte — bewusst nicht Boolean), `.t15_zeitpunkt`, `.t15_neue_zustaendigkeit_text`.

**T16.** Wie häufig arbeitet die Person in diesem Aufgabenbereich?

- *Mandantensicht:* Täglich / mehrmals pro Woche / wöchentlich / monatlich / quartalsweise / jährlich / nur bei Bedarf / nicht bekannt. Zeitumfang unter Abschnitt 4 zuordnen.
- *Interner Hinweis:* Ziel: `Aufgaben.t16_haeufigkeit`.

## 3. Führung, Entscheidungsbefugnisse und Zusammenarbeit (Formular 2, bedingte Abschnitte)

Die folgenden Fragen betreffen die tatsächliche Arbeitsteilung im Tagesgeschäft. Je nach Aufgabenbereich werden nur die passenden Fragen angezeigt (B3: D/V/K nur bei entsprechenden Aufgaben).

### 3.1 Entscheidungen und Freigaben

**D01.** Welche Entscheidungsaufgaben übernimmt die Person tatsächlich?

- *Mandantensicht:* Entscheidet selbst / entscheidet gemeinsam mit anderen / bereitet Entscheidungen vor / erteilt erforderliche Zustimmungen / setzt Entscheidungen um / kontrolliert die Umsetzung / keine Entscheidungsaufgaben / nicht bekannt. Mehrfachauswahl; «keine» exklusiv.
- *Interner Hinweis:* Ziel: `Aufgaben.d01_rollen` (Gateway für Entscheidungsbefugnisse-Erfassung).

**D02.** Welche Entscheidungen betrifft dies?

- *Mandantensicht:* Preise oder Kundenaufträge / Lieferanten oder Einkauf / Einstellungen, Vergütung oder Kündigungen / Personaleinsatz / Finanzierung / Zahlungen / Budgets / Investitionen / Unternehmensplanung / Beteiligungen / Ausschüttungen / Kapitalmassnahmen / Organbestellungen / andere Entscheidungen. Für jede ausgewählte Entscheidungsart die tatsächlich betroffene Gesellschaft zuordnen.
- *Interner Hinweis:* Anzeige: Entscheidungsaufgabe vorhanden (D01 ≠ keine). Ziel: `Entscheidungsbefugnisse.entscheidungsart_code`, `.gesellschaft_ref` (je Art×Gesellschaft ein Datensatz).

**D03.** Wer trifft in diesem Bereich die inhaltlichen Entscheidungen?

- *Mandantensicht:* Person allein / gemeinsam mit benannten Personen / andere benannte Person / Geschäftsleitung / anderes benanntes Gremium / Gesellschafter / unterschiedlich nach Entscheidungsart / nicht bekannt. Gesellschaft und Funktion zuordnen.
- *Interner Hinweis:* Ziel: `Entscheidungsbefugnisse.d03_entscheider_ref` (LookupMulti), `.d03_status`, `.d03_gesellschaft_ref`, `.d03_funktion_text`.

**D04.** Für welche Entscheidungen ist eine zusätzliche Zustimmung erforderlich?

- *Mandantensicht:* Keine / nach Betrag / ausserhalb des Budgets / nach Vertrags- oder Entscheidungsart / grundsätzlich erforderlich / andere Regel / nicht bekannt. Bei unterschiedlichen Regeln je Entscheidungsart trennen.
- *Interner Hinweis:* Ziel: `Entscheidungsbefugnisse.d04_zustimmung`.

**D05.** Wer erteilt diese Zustimmung?

- *Mandantensicht:* Benannte Person oder Gremium; Gesellschaft und Funktion zuordnen.
- *Interner Hinweis:* Anzeige: Zustimmung erforderlich. Ziel: `Entscheidungsbefugnisse.d05_erteiler_ref`, `.d05_gesellschaft_ref`, `.d05_funktion_text`.

**D06.** Wie werden Entscheidungsvorschläge vor der Freigabe tatsächlich bearbeitet?

- *Mandantensicht:* Inhaltlich geprüft / mit den Verantwortlichen besprochen / zur Ergänzung zurückgegeben / inhaltlich geändert / gelegentlich abgelehnt / ohne weitere Bearbeitung bestätigt / unterschiedliche Handhabung / nicht bekannt. Mehrfachauswahl. Eine inhaltliche Prüfung kann auch ohne Änderung enden.
- *Interner Hinweis:* Anzeige: Zustimmung erforderlich. Ziel: `Entscheidungsbefugnisse.d06_bearbeitung`.

**D07.** Welche Punkte werden dabei geprüft oder abgestimmt?

- *Mandantensicht:* Wirtschaftliche Bedingungen / Finanzierung oder Liquidität / Personal / Budget / rechtliche oder steuerliche Fragen / Umsetzung / andere Punkte / nicht bekannt.
- *Interner Hinweis:* Anzeige: Prüfung oder Abstimmung vorhanden. Ziel: `Entscheidungsbefugnisse.d07_pruefpunkte`.

**D08.** Welche Grenzen gelten für die eigenen Entscheidungsbefugnisse?

- *Mandantensicht:* Keine gesonderte Grenze / Betrag / Budget / Themenbereich / Zustimmungsvorbehalt / andere Grenze / nicht bekannt. Betragsgrenze und Währung als eigene Felder; schriftliche Regelung später zuordnen.
- *Interner Hinweis:* Ziel: `Entscheidungsbefugnisse.d08_grenzen`, `.d08_betrag`, `.d08_waehrung`, `.d08_regelung_ref`.

**D09.** Wer verantwortet die Umsetzung der Entscheidungen?

- *Mandantensicht:* Person selbst / benannte Mitarbeitende / Geschäftsleitung der betroffenen Gesellschaft / externer Dienstleister / je Entscheidung unterschiedlich / nicht bekannt.
- *Interner Hinweis:* Ziel: `Entscheidungsbefugnisse.d09_umsetzung`.

**D10.** Welche Entscheidungen werden tatsächlich den Gesellschaftern vorgelegt?

- *Mandantensicht:* Beteiligungserwerb oder -verkauf / Ausschüttung / Kapitalmassnahme / Organbestellung / Budget oder Investition / andere Entscheidung / keine / nicht bekannt. Gesellschaft, deren Gesellschafter entscheiden, und handelnde Vertreter getrennt angeben. Keine rechtliche Bewertung verlangen.
- *Interner Hinweis:* Ziel: `Entscheidungsbefugnisse.d10_gesellschafter_vorgelegt`, `.d10_gesellschaft_ref`, `.d10_vertreter_ref`.

### 3.2 Vertragsverhandlungen im Tagesgeschäft

**V10.** Bei welchen Verträgen übernimmt die Person Aufgaben?

- *Mandantensicht:* Kundenverträge / Lieferantenverträge / Personalverträge / Kredite oder Sicherheiten / Miete oder Leasing / Beraterverträge / andere Verträge / keine / nicht bekannt. Je ausgewählter Vertragsart die folgenden Angaben, soweit die Zuständigkeit abweicht.
- *Interner Hinweis:* Ziel: `Vertragszustaendigkeiten.vertragsart_code` (je Art ein Datensatz).

**V11.** Für welche Gesellschaft übernimmt sie diese Vertragsaufgaben?

- *Mandantensicht:* Gesellschaft auswählen; Vertragspartei ausdrücklich benennen.
- *Interner Hinweis:* Anzeige: Vertragsaufgaben vorhanden. Ziel: `Vertragszustaendigkeiten.vertragspartei_ref`, `.vertragspartei_text`.

**V12.** Mit welchen Geschäftspartnern oder Ansprechpartnern führt sie die Gespräche?

- *Mandantensicht:* Kunden / Lieferanten / Bewerber oder Mitarbeitende / Banken oder Finanzierer / Vermieter oder Leasinggeber / Steuerberater oder andere Berater / andere Ansprechpartner.
- *Interner Hinweis:* Anzeige: Vertragsaufgaben vorhanden. Ziel: `Vertragszustaendigkeiten.v12_gespraechspartner`.

**V13.** Welche Teile der Verhandlung übernimmt sie selbst?

- *Mandantensicht:* Kontakt und Bedarfsklärung / Auswahl des Vertragspartners / Preis oder Vergütung / Leistung oder Menge / Termine oder Laufzeit / Haftung oder Sicherheiten / Kündigungsbedingungen / Abstimmung des unterschriftsreifen Vertrags / andere Aufgaben.
- *Interner Hinweis:* Anzeige: Vertragsaufgaben vorhanden. Ziel: `Vertragszustaendigkeiten.v13_teile`.

**V14.** Bis zu welchem Stand führt sie die Verhandlungen üblicherweise?

- *Mandantensicht:* Klärt nur Grundlagen / bereitet ein Angebot vor / verhandelt einzelne Bedingungen / stimmt die wesentlichen Bedingungen vollständig ab / stimmt den Vertrag bis auf interne Freigabe oder Unterschrift vollständig ab / schliesst selbst verbindlich ab / unterschiedlich je Vertragsart / nicht bekannt.
- *Interner Hinweis:* Anzeige: Vertragsaufgaben vorhanden. Ziel: `Vertragszustaendigkeiten.v14_abschlussreife`.

**V15.** Welche Bearbeitung erfolgt danach durch andere Personen?

- *Mandantensicht:* Weitere wirtschaftliche Verhandlung / rechtliche Detailprüfung / inhaltliche Freigabe / regelmässig wesentliche Änderungen / nur Unterzeichnung / keine weitere Bearbeitung / unterschiedlich / nicht bekannt. Zuständige Personen und Gesellschaften getrennt angeben. Bereits beschriebene Freigaberegeln übernehmen.
- *Interner Hinweis:* Anzeige: Vertragsaufgaben vorhanden. Ziel: `Vertragszustaendigkeiten.v15_bearbeitung`, `.v15_zustaendige_ref` (LookupMulti), `.v15_gesellschaft_ref`.

**V16.** Wer erklärt die verbindliche Zusage oder unterzeichnet üblicherweise?

- *Mandantensicht:* Person selbst / andere benannte Person / gemeinsame Zeichnung / je Vertragsart unterschiedlich / nicht bekannt. E-Mail-Zusagen und Unterschriften können unterschiedliche Zuständigkeiten haben.
- *Interner Hinweis:* Anzeige: Vertragsaufgaben vorhanden. Ziel: `Vertragszustaendigkeiten.v16_zeichnung`, `.v16_person_ref` (LookupMulti).

**V17.** Welche Verträge oder Unterlagen darf die Person für die jeweilige Gesellschaft verbindlich bestätigen oder unterzeichnen?

- *Mandantensicht:* Angebote / Auftragsbestätigungen / Kundenverträge / Bestellungen oder Lieferantenverträge / Personalverträge / Finanzierungsverträge / Zahlungsfreigaben / Berateraufträge / andere Unterlagen / keine / nicht bekannt. Einzel- oder gemeinsame Zeichnung und Grenzen gesondert erfassen.
- *Interner Hinweis:* Ziel: `Vertragszustaendigkeiten.v17_unterlagenart`, `.v17_grenzen_text`, `.v17_nachweis_ref`.

**V18.** Wie häufig führt sie solche Verhandlungen?

- *Mandantensicht:* Täglich / mehrmals pro Woche / wöchentlich / monatlich / seltener / nur bei Bedarf / nicht bekannt. Anzahl nur angeben, wenn ohne unverhältnismässige Rekonstruktion verfügbar.
- *Interner Hinweis:* Anzeige: Vertragsaufgaben vorhanden. Ziel: `Vertragszustaendigkeiten.v18_haeufigkeit`.

### 3.3 Aufsicht, Kontrolle, Instruktion und Schulung

**K10.** Welche Bereiche überwacht oder kontrolliert die Person?

- *Mandantensicht:* Ergebnis / Budget / Liquidität / Projekte / Personal / Einhaltung von Vorgaben / Tätigkeit der Geschäftsleitung / Beteiligungsentwicklung / andere Bereiche / keine Kontrollaufgaben / nicht bekannt.
- *Interner Hinweis:* Ziel: `Kontrollaufgaben.k10_gegenstand`.

**K11.** Welche Befugnisse übt sie bei Abweichungen tatsächlich aus?

- *Mandantensicht:* Erläuterungen verlangen / Empfehlungen geben / allgemeine Vorgaben anpassen / konkrete Massnahmen verbindlich anordnen / selbst in die Bearbeitung eingreifen / Umsetzung nachhalten / nur berichten / andere Befugnisse / nicht bekannt.
- *Interner Hinweis:* Anzeige: Kontrollaufgaben vorhanden. Ziel: `Kontrollaufgaben.k11_befugnisse`.

**K12.** Welche Art von Vorgaben, Beratung oder Schulung übernimmt sie?

- *Mandantensicht:* Allgemeine Richtlinien / Fachwissen oder Methoden / Softwareanwendung / allgemeine Arbeitsabläufe / konkrete Anweisungen zur täglichen Arbeit / andere Inhalte / keine solche Aufgabe / nicht bekannt.
- *Interner Hinweis:* Ziel: `Kontrollaufgaben.k12_art`.

**K13.** An welche Personen oder Bereiche richten sich diese Leistungen?

- *Mandantensicht:* Geschäftsleitung / Fachabteilungen / einzelne Mitarbeitende / Dienstleister / andere Empfänger. Gesellschaft zuordnen.
- *Interner Hinweis:* Anzeige: Vorgaben, Beratung oder Schulung vorhanden. Ziel: `Kontrollaufgaben.k13_adressaten`, `.k13_gesellschaft_ref`.

**K14.** Wer legt deren Inhalt fest?

- *Mandantensicht:* Person selbst / benannte Geschäftsleitung / Schweizer Mutter / andere Person oder Stelle / gemeinsame Festlegung / nicht bekannt.
- *Interner Hinweis:* Anzeige: Vorgaben, Beratung oder Schulung vorhanden. Ziel: `Kontrollaufgaben.k14_festleger_ref`, `.k14_status`.

**K15.** Welche Mitarbeitenden oder Dienstleister steuert die Person im Tagesgeschäft?

- *Mandantensicht:* Benannte Personen oder Funktionen / Dienstleister / keine / nicht bekannt. Arbeitgeber beziehungsweise Vertragspartner jeweils zuordnen.
- *Interner Hinweis:* Ziel: `Steuerungsbeziehungen.gesteuerte_person_ref`, `.dienstleister_text`, `.status`.

**K16.** Für welche Gesellschaft arbeiten diese Mitarbeitenden oder Dienstleister?

- *Mandantensicht:* Gesellschaft auswählen; mehrere Empfänger nach Aufgabe unterscheiden.
- *Interner Hinweis:* Anzeige: gesteuerte Personen/Dienstleister vorhanden. Ziel: `Steuerungsbeziehungen.k16_gesellschaft_ref`.

**K17.** Was legt die Person für diese Mitarbeitenden oder Dienstleister tatsächlich fest?

- *Mandantensicht:* Aufgaben / Prioritäten / Termine / Vorgehensweise / erwartete Ergebnisse / Abnahme / andere Punkte / keine verbindlichen Vorgaben / nicht bekannt.
- *Interner Hinweis:* Anzeige: gesteuerte Personen/Dienstleister vorhanden. Ziel: `Steuerungsbeziehungen.k17_festlegung`.

### 3.4 Eigene Aufgaben der KG und Arbeiten für die Schweizer Mutter

**G10.** Welche Aufgaben betreffen die eigene Organisation oder Beteiligungsverwaltung der KG?

- *Mandantensicht:* Eigene Buchführung und Steuern / eigenes Personal / eigene Räume und Ausstattung / eigene IT / eigene Finanzierung / Abrechnung ihrer Managementleistungen / Überwachung ihrer Beteiligungen / Vorbereitung ihrer Stimmabgaben oder Gesellschafterbeschlüsse / andere Aufgaben / keine. Bereits bestätigte Aufgaben übernehmen.
- *Interner Hinweis:* Nur bei `bereich_code=EIGENE_VERWALTUNG`. Ziel: `Aufgaben.g10_aufgabenart`.

**G11.** Für welche Gesellschaft werden Beteiligungsrechte oder Gesellschafteraufgaben wahrgenommen?

- *Mandantensicht:* Für die KG als Anteilseignerin / für die Schweizer Mutter als Anteilseignerin / für eine andere Gesellschaft / nicht bekannt. Betroffene Beteiligung getrennt angeben.
- *Interner Hinweis:* Ziel: `Aufgabenempfaenger.g11_rolle`, `.g11_beteiligung_ref`.

**G12.** Welche laufenden Arbeiten werden für die Schweizer Mutter erledigt?

- *Mandantensicht:* Eigener Abschluss der Mutter / Konzernabschluss / Steuererklärungen der Mutter / deren Sitzungsunterlagen / Berichte an deren Anteilseigner / Finanzierung ihrer Beteiligungserwerbe / andere Arbeiten / keine. Tätige Personen aus dem Bestand zuordnen.
- *Interner Hinweis:* Nur bei `bereich_code=BETEILIGUNG_MUTTER`. Ziel: `Aufgaben.g12_mutterarbeiten`.

**G13.** Wer nutzt diese Arbeitsergebnisse zusätzlich?

- *Mandantensicht:* Keine weiteren Empfänger / benannte weitere Gesellschaften oder Stellen / nicht bekannt. Nutzung kurz angeben; unterschiedliche Verwendungen getrennt halten.
- *Interner Hinweis:* Anzeige: Arbeiten für die Mutter vorhanden. Ziel: `Aufgabenempfaenger.g13_zusatz_empfaenger_ref`, `.g13_zusatz_empfaenger_text`.

**G14.** Wie ist die Zuständigkeit für diese Aufgaben organisatorisch geregelt?

- *Mandantensicht:* Ständige Aufgabenverteilung / schriftlicher Auftrag / mündliche Absprache / wiederkehrende Anforderung / wechselnde Zuständigkeit / andere Regel / nicht bekannt.
- *Interner Hinweis:* Ziel: `Aufgabenzustaendigkeiten.g14_regelung`.

**G15.** Wie werden diese Aufgaben bei Abwesenheit weitergeführt?

- *Mandantensicht:* Benannte Vertretung / Verteilung auf mehrere Personen / externer Dienstleister / Aufgabe bleibt liegen / bisher kein Vertretungsfall / nicht bekannt.
- *Interner Hinweis:* Ziel: `Aufgabenzustaendigkeiten.g15_vertretung`.

## 4. Arbeitsorganisation, Zeit und Ort (Formular 3)

### 4.1 Vertragsbindung und Zuständigkeiten

Diese Angaben einmal je Person erfassen. Mehrere Vertragsverhältnisse werden getrennt angegeben. Zuständige Personalstelle kann ergänzen.

**P30.** Mit welcher Gesellschaft besteht ein Vertrag für die Tätigkeit der Person?

- *Mandantensicht:* Gesellschaft auswählen / mehrere Vertragsverhältnisse / kein Vertrag / nicht bekannt. Bei mehreren je Verhältnis eigene Angaben.
- *Interner Hinweis:* Ziel: `Personenbindungen.gesellschaft_ref`, `.gesellschaft_status`.

**P31.** Welche Art von Vertrag besteht?

- *Mandantensicht:* Arbeitsvertrag / Geschäftsführer- oder Vorstandsvertrag / Mandats- oder Dienstleistungsvertrag / andere Vereinbarung / Vertragsart nicht bekannt. Schriftform wird separat abgefragt.
- *Interner Hinweis:* Anzeige: Vertragsverhältnis vorhanden. Ziel: `Personenbindungen.vertragsart`.

**P32.** Welcher schriftliche Stand liegt vor?

- *Mandantensicht:* Unterzeichnete Fassung / nur Entwurf / schriftlicher Vertrag derzeit nicht verfügbar / nur mündliche Vereinbarung / keine Vereinbarung / nicht bekannt. Anlagen später gesammelt zuordnen.
- *Interner Hinweis:* Ziel: `Personenbindungen.schriftform`, `.nachweis_ref`.

**P33.** Seit wann besteht das Vertragsverhältnis?

- *Mandantensicht:* Datum / ungefähres Datum / nicht bekannt. Enddatum nur bei beendetem Verhältnis.
- *Interner Hinweis:* Anzeige: Vertragsverhältnis vorhanden. Ziel: `Personenbindungen.beginn`/`.beginn_genauigkeit`/`.ende`.

**P34.** Wer legt im Arbeitsalltag die Aufgaben und Prioritäten fest?

- *Mandantensicht:* Person selbst / benannte Person oder Personen / wechselnd je Aufgabe / nicht bekannt. Person und Gesellschaft verknüpfen.
- *Interner Hinweis:* Ziel: `Personenbindungen.weisungsgeber_ref`, `.weisungsgeber_status`.

**P35.** Wer kann der Person konkrete Arbeitsanweisungen geben?

- *Mandantensicht:* Wie bei Aufgaben und Prioritäten / andere benannte Person oder Personen / niemand / nicht bekannt. Abweichende Zuständigkeiten je Aufgabenbereich getrennt erhalten.
- *Interner Hinweis:* Ziel: `Personenbindungen.anweisungsbefugter_ref`, `.anweisungsbefugter_status`.

**P36.** Wer genehmigt Abwesenheiten?

- *Mandantensicht:* Bekannte zuständige Person übernehmen / andere Person / keine Genehmigung vorgesehen / nicht bekannt.
- *Interner Hinweis:* Ziel: `Personenbindungen.abwesenheit_genehmiger_ref`, `.abwesenheit_genehmiger_status`.

**P37.** Wer beurteilt die Arbeit der Person?

- *Mandantensicht:* Bekannte zuständige Person übernehmen / andere Person / keine solche Beurteilung vorgesehen / nicht bekannt.
- *Interner Hinweis:* Ziel: `Personenbindungen.beurteiler_ref`, `.beurteiler_status`.

**P38.** Wer vertritt die Person bei Abwesenheit?

- *Mandantensicht:* Benannte Person / wechselnd je Aufgabe / keine Vertretung / nicht bekannt. Bei wechselnder Vertretung auf Aufgabenblätter verweisen.
- *Interner Hinweis:* Ziel: `Personenbindungen.vertretung_ref`, `.vertretung_status`.

### 4.2 Zeitaufwand nachvollziehbar angeben

**Z01.** Welche Unterlagen können die Zeitangaben stützen?

- *Mandantensicht:* Zeiterfassung / Kalender / Projekt- oder Arbeitsunterlagen / andere Unterlagen / keine Unterlagen. Mehrfachauswahl, «keine» exklusiv.
- *Interner Hinweis:* Ziel: `Personeneinsaetze.zeitnachweis_unterlagenart`.

**Z02.** Wie häufig hat die Person im Zusammenhang mit der KG gearbeitet?

- *Mandantensicht:* Täglich / mehrmals pro Woche / wöchentlich / monatlich / nur bei Bedarf / einmalig / im Zeitraum nicht tätig / nicht bekannt.
- *Interner Hinweis:* Ziel: `Personeneinsaetze.gesamthaeufigkeit`.

**Z03.** Wie viele Arbeitsstunden hat die Person insgesamt im Zeitraum geleistet?

- *Mandantensicht:* Aus Unterlagen ermittelt / geschätzt / nicht bekannt. Bei bekanntem oder geschätztem Umfang Stundenfeld anzeigen. Keine verpflichtende Umrechnung aus einer typischen Woche.
- *Interner Hinweis:* Ermittelt-vs.-geschätzt getrennt (B4). Ziel: `Personeneinsaetze.gesamtstunden_status`, `.gesamtstunden`.

**Z04.** Wie viele dieser Stunden entfielen auf Arbeiten im Auftrag der KG?

- *Mandantensicht:* Aus Unterlagen ermittelt / geschätzt / nicht bekannt; danach Stundenfeld. Kann der Auftrag nicht sicher zugeordnet werden, offene Zuordnung kennzeichnen. Direkte Tätigkeit für eine Beteiligung ausserhalb des KG-Auftrags nicht einbeziehen.
- *Interner Hinweis:* Ziel: `Personeneinsaetze.kg_stunden_status`, `.kg_stunden`, `.kg_stunden_offene_zuordnung`.

**Z05.** Wie viele dieser Stunden entfielen auf die jeweilige Aufgabe?

- *Mandantensicht:* Je Aufgabenblatt Stunden / ungefährer Stundenumfang / nicht bekannt. Wenn genaue Aufgabenaufteilung nicht möglich: unaufgeteilter Rest als «noch nicht zugeordnet» erfassen, keine erfundenen Anteile. Zeitbasis identisch mit Z04.
- *Interner Hinweis:* Ziel: `Zeitverteilungen.status`/`.stunden` (Code `Z08_STATUS_REST_NICHT_ZUGEORDNET` für die ausdrücklich offene Restzeit — **keine Summenkorrektur**, B4).

**Z06.** Worauf beruht die Schätzung?

- *Mandantensicht:* Kalender / typische Arbeitswoche / Umfang wiederkehrender Arbeiten und ungefährer Aufwand / andere Grundlage / keine nähere Grundlage.
- *Interner Hinweis:* Anzeige: mindestens eine Zeitangabe geschätzt. Ziel: `Personeneinsaetze.schaetzgrundlage`.

**Z07.** Gab es Zeitabschnitte mit deutlich anderem Arbeitsumfang?

- *Mandantensicht:* Nein / ja / nicht bekannt. Bei ja: Zeitabschnitt und abweichende Stunden getrennt erfassen, statt eine typische Woche auf das ganze Jahr zu übertragen.
- *Interner Hinweis:* Ziel: `Personeneinsaetze.zeitabschnitt_abweichend` (Choice, 3 Werte), `.zeitabschnitt_von`/`.zeitabschnitt_bis`/`.zeitabschnitt_stunden`.

**Z08.** Wie verteilen sich die Stunden im Auftrag der KG auf die unmittelbar betroffenen Gesellschaften?

- *Mandantensicht:* Bereits eindeutig einer Gesellschaft zugeordnete Aufgabenstunden anzeigen und übernehmen. Nur bei Aufgaben mit mehreren Empfängern oder offenen Stunden nachfragen: Stunden je Empfänger aus Unterlagen / geschätzte Stunden / nur geschätzte Anteile möglich / Aufteilung nicht bekannt. Eigene Aufgaben der KG und Arbeiten für die Schweizer Mutter getrennt von Arbeiten für jede Beteiligung führen. Keine zusätzliche unabhängige Gesamtschätzung verlangen, wenn sich die Verteilung aus den Aufgabenstunden ergibt.
- *Interner Hinweis:* Ziel: `Zeitverteilungen.empfaenger_ref`, `.status`, `.stunden`, `.anteil_geschaetzt_prozent`. Prozent nur bei konsistenter Basis und Nenner > 0 berechnen (B4); keine Summenkorrektur auf 100 %.

### 4.3 Arbeitsorte

**O01.** An welchen Orten führte die Person die erfassten Aufgaben aus?

- *Mandantensicht:* KG-Büro / Räume einer Beteiligung / Homeoffice / Räume der Schweizer Gesellschaft / beim Geschäftspartner / unterwegs / anderer Ort. Je Standort Adresse oder Ort und Land erfassen, bekannte Orte übernehmen.
- *Interner Hinweis:* Ziel: `Aufgabenorte.ort_ref` (`rollenbezug=AUSUEBUNG`).

**O02.** Wie viel Arbeitszeit entfiel auf den jeweiligen Ort?

- *Mandantensicht:* Wenn verfügbar Stunden aus derselben Bezugsperiode; sonst geschätzte Stunden / nur geschätzter Prozentanteil möglich / nicht bekannt. Prozentangaben sind eine Alternative, keine zusätzliche Schätzpflicht. Bei unterschiedlichen Aufgabenorten je Aufgabe aufteilen.
- *Interner Hinweis:* Ziel: `Aufgabenorte.o02_status`, `.o02_stunden`, `.o02_prozent`.

**O03.** Wie häufig war die Person im KG-Büro tätig?

- *Mandantensicht:* Täglich / mehrmals pro Woche / wöchentlich / monatlich / seltener / nie / nicht bekannt.
- *Interner Hinweis:* Ziel: `Personeneinsaetze.kg_buero_haeufigkeit`.

**O04.** Wie viele Tage arbeitete die Person im Zeitraum im KG-Büro?

- *Mandantensicht:* Ermittelte Tage / geschätzte Tage / nicht bekannt. Stunden dort aus O02 übernehmen, nicht nochmals unabhängig schätzen.
- *Interner Hinweis:* Anzeige: O03 nicht «nie». Ziel: `Personeneinsaetze.kg_buero_tage_status`, `.kg_buero_tage`.

**O05.** Welche der bereits genannten Aufgaben erledigte sie im KG-Büro?

- *Mandantensicht:* Vorhandene Aufgaben auswählen / andere Aufgabe ergänzen / nicht bekannt.
- *Interner Hinweis:* Anzeige: O03 nicht «nie». Ziel: `Personeneinsaetze.kg_buero_aufgaben_ref` (LookupMulti), `.kg_buero_andere_text`.

**O06.** Wo üben die jeweils zuständigen Personen Vorbereitung, Verhandlung, Entscheidung und Freigabe regelmässig aus?

- *Mandantensicht:* Je Aufgaben- oder Entscheidungsart die beteiligten Personen und deren tatsächliche Arbeitsorte zuordnen. Vorhandene Standortangaben übernehmen. Bei Telefon- und Videobesprechungen zählt der Aufenthaltsort der jeweiligen Person. Wechselnde Orte und abweichende Zuständigkeiten kennzeichnen. Keine Rekonstruktion einzelner Geschäftsfälle verlangen.
- *Interner Hinweis:* **Geänderte Bedeutung gegenüber V2** (dort `Fallbeteiligungen.schritt`/`.ort_ref`, gebunden an einen konkreten Fall). Ziel: `Aufgabenorte.rollenbezug` (VORBEREITUNG/VERHANDLUNG/ENTSCHEIDUNG/FREIGABE), `.entscheidung_ref`/`.vertrag_ref`/`.kontrolle_ref` (polymorph), `.person_ref`, `.ort_ref`.

**O07.** Warum wurde für diese Arbeit das Homeoffice genutzt?

- *Mandantensicht:* Persönlicher Wunsch / Vorgabe des Unternehmens / kein anderer Arbeitsplatz verfügbar / Nähe zu Kunden oder anderen Geschäftspartnern / anderer tatsächlicher Grund / nicht bekannt. Mehrere Gründe möglich.
- *Interner Hinweis:* Anzeige: Homeoffice in O01 vorhanden. Ziel: `Aufgabenorte.o07_grund`.

**O08.** Stand für diese Arbeit ein anderer Arbeitsplatz zur Verfügung?

- *Mandantensicht:* Ja / nein / teilweise / nicht bekannt. Bei ja Standort auswählen.
- *Interner Hinweis:* Anzeige: Homeoffice in O01 vorhanden. Ziel: `Aufgabenorte.o08_alternativer_arbeitsplatz`, `.o08_alternativ_ort_ref`.

## 5. Räume, Arbeitsmittel und Kosten ergänzen (Formular 4, rollenbezogen)

Dieses Modul kann von Administration, IT, Personalstelle oder Buchhaltung ausgefüllt werden. Bereits bekannte Personen, Aufgaben und Standorte werden übernommen.

**R20.** Zu welchen Angaben können Sie Auskunft geben?

- *Mandantensicht:* Räume / Fahrzeuge oder Büroausstattung / IT oder Software / Personalkosten / weitere Kosten und Abrechnungen. Name der ergänzenden Person einmal im Modulkopf.
- *Interner Hinweis:* Gateway-Auswahl, keine eigene Spalte — steuert, welche Unterabschnitte 5.1-5.3 angezeigt werden.

### 5.1 Ein Raum oder Arbeitsbereich

**R21.** Welcher Raum oder Arbeitsbereich wird genutzt?

- *Mandantensicht:* Bekannten Standort auswählen; Bereich bezeichnen. Eigenes Büro / eigener Raum bei Beteiligung / gemeinsamer Raum / wechselnder Arbeitsplatz / Besprechungsraum / Homeoffice / Archiv / anderer Bereich.
- *Interner Hinweis:* Ziel: `Raeume.ort_ref`, `.raumart`.

**R22.** Wem gehört der Raum?

- *Mandantensicht:* Gesellschaft oder Person / nicht bekannt.
- *Interner Hinweis:* Ziel: `Raeume.eigentuemer_ref`/`.eigentuemer_person_ref`, `.r22_status`.

**R23.** Wer ist Mieter des Raums?

- *Mandantensicht:* Gesellschaft oder Person / kein Mietverhältnis / nicht bekannt.
- *Interner Hinweis:* Ziel: `Raeume.mieter_ref`, `.r23_status`.

**R24.** Wer stellt den Raum der KG zur Verfügung?

- *Mandantensicht:* Eigentümer / Mieter / anderer Bereitsteller / nicht bekannt. Name beziehungsweise Gesellschaft separat zuordnen.
- *Interner Hinweis:* Ziel: `Raeume.r24_bereitsteller`, `.r24_name_text`.

**R25.** Auf welcher Vereinbarung beruht die Nutzung?

- *Mandantensicht:* Mietvertrag / Untermietvertrag / andere schriftliche Vereinbarung / mündliche Absprache / keine Vereinbarung bekannt / nicht bekannt. Beginn und gegebenenfalls Ende jeweils separate Datumsfelder.
- *Interner Hinweis:* Ziel: `Raeume.r25_vereinbarung`, `.r25_beginn`, `.r25_ende`.

**R26.** Wie kann die KG den Raum nutzen?

- *Mandantensicht:* Je eine Einzelfrage zu: eigener Schlüssel oder Zugang; Zugang ohne Voranmeldung; fest zugewiesene Arbeitsplätze; eigene Ablage; abschliessbare Aufbewahrung. Antwort jeweils ja / nein / nicht bekannt. Raum nur nach Buchung verfügbar: gesondert ja / nein / nicht bekannt.
- *Interner Hinweis:* **Sechs einzelne Ja/Nein/unbekannt-Fragen**, nicht MultiChoice. Ziel: `Raeume.r26_eigener_zugang`, `.r26_zugang_ohne_anmeldung`, `.r26_fest_zugewiesen`, `.r26_eigene_ablage`, `.r26_abschliessbare_aufbewahrung`, `.r26_nur_nach_buchung`.

**R27.** Welche Fläche wird genutzt?

- *Mandantensicht:* m² aus Unterlagen / geschätzte m² / nicht bekannt; gemeinsam genutzte Fläche kennzeichnen.
- *Interner Hinweis:* Ziel: `Raeume.r27_flaeche_status`, `.r27_flaeche_qm`, `.r27_gemeinsam_genutzt`.

**R28.** Wie viele Arbeitsplätze stehen dort zur Verfügung?

- *Mandantensicht:* Anzahl / nicht bekannt.
- *Interner Hinweis:* Ziel: `Raeume.r28_status`, `.r28_anzahl_arbeitsplaetze`.

**R29.** Wer nutzt den Raum tatsächlich?

- *Mandantensicht:* Person aus Bestand / andere Nutzergruppe / nicht bekannt. Aufgaben und Nutzungsstunden aus vorhandenen Angaben übernehmen; andere Nutzung und Überschneidungen nur ergänzen.
- *Interner Hinweis:* Ziel: `Ressourcennutzungen` (`bezug_typ=RAUM`, `raum_ref`, `person_ref`).

### 5.2 Ein Arbeitsmittel oder eine Software

**A20.** Welches Arbeitsmittel wird genutzt?

- *Mandantensicht:* Fahrzeug / Büroausstattung / Computer / Smartphone oder Tablet / Telefon oder Internet / Drucker / Server oder Cloud / Software oder Datenbank / anderes. Bezeichnung als separates Textfeld.
- *Interner Hinweis:* Ziel: `Arbeitsmittel.art_code`, `.bezeichnung_text`.

**A21.** Wem gehört das Arbeitsmittel?

- *Mandantensicht:* Gesellschaft oder Person / nicht bekannt. Bei Software anstelle Eigentum Lizenznehmer unter A26 abfragen.
- *Interner Hinweis:* Ziel: `Arbeitsmittel.eigentuemer_ref`/`.eigentuemer_person_ref`, `.a21_status`.

**A22.** Wer stellt es zur Verfügung?

- *Mandantensicht:* Bekannten Eigentümer übernehmen / anderer Bereitsteller / nicht bekannt.
- *Interner Hinweis:* Ziel: `Arbeitsmittel.a22_bereitsteller_ref`, `.a22_status`.

**A23.** Auf welcher Grundlage wird es genutzt?

- *Mandantensicht:* Gekauft / gemietet / geleast / privat bereitgestellt / andere Grundlage / nicht bekannt. Nutzungsbeginn und gegebenenfalls Ende getrennt erfassen.
- *Interner Hinweis:* Ziel: `Arbeitsmittel.a23_grundlage`, `.a23_beginn`, `.a23_ende`.

**A24.** Wer nutzt es tatsächlich?

- *Mandantensicht:* Eine oder mehrere bekannte Personen / andere Nutzer / nicht bekannt. Je Nutzer Aufgaben und Gesellschaft zuordnen; vorhandene Angaben übernehmen.
- *Interner Hinweis:* Ziel: `Ressourcennutzungen` (`bezug_typ=MITTEL`, `mittel_ref`, `person_ref`, `gesellschaft_ref`, `aufgabe_ref`).

**A25.** Wie verteilt sich die tatsächliche Nutzung?

- *Mandantensicht:* Soweit verfügbar Nutzungsstunden, Kilometer oder andere geeignete Einheit; sonst geschätzte Anteile nach Gesellschaft und gegebenenfalls Privatnutzung / nicht aufteilbar / derzeit ungenutzt. Bezugszeitraum ausdrücklich angeben; Geräteanteile nicht aus Arbeitszeitanteilen ungeprüft ableiten.
- *Interner Hinweis:* Ziel: `Ressourcennutzungen.a25_einheit`, `.a25_menge`, `.a25_privatanteil_prozent`, `.bezugszeitraum_von`/`.bezugszeitraum_bis`.

**A26.** Wer ist Lizenz- oder Abonnementnehmer?

- *Mandantensicht:* Gesellschaft oder Person / nicht bekannt. Produkt aus A20 übernehmen.
- *Interner Hinweis:* Anzeige: Software oder Datenbank. Ziel: `Arbeitsmittel.a26_lizenznehmer_ref`, `.a26_status`.

**A27.** Wie viele Lizenzen stehen zur Verfügung?

- *Mandantensicht:* Anzahl / nicht bekannt.
- *Interner Hinweis:* Anzeige: Software oder Datenbank. Ziel: `Arbeitsmittel.a27_status`, `.a27_lizenzen_verfuegbar`.

**A28.** Wie viele davon werden tatsächlich genutzt?

- *Mandantensicht:* Anzahl / nicht bekannt. Nutzer aus A24 übernehmen. Bekannte Nutzungsbeschränkungen optional angeben.
- *Interner Hinweis:* Anzeige: Software oder Datenbank. Ziel: `Arbeitsmittel.a28_status`, `.a28_lizenzen_genutzt`, `.a28_beschraenkungen_text`.

**A29.** Auf wen läuft der Mobilfunk- oder IT-Vertrag?

- *Mandantensicht:* Gesellschaft oder Person / nicht bekannt.
- *Interner Hinweis:* Anzeige: Smartphone, Telefon oder IT-Vertrag. Ziel: `Arbeitsmittel.a29_vertrag_ref`, `.a29_status`.

**A30.** Wer verwaltet das Gerät oder Benutzerkonto?

- *Mandantensicht:* Interne Person oder Stelle / Dienstleister / niemand gesondert / nicht bekannt. E-Mail-Domain und Speicherzugriff nur soweit relevant ergänzen; keine Passwörter.
- *Interner Hinweis:* Anzeige: IT oder Smartphone. Ziel: `Arbeitsmittel.a30_verwalter_ref`, `.a30_status`.

**A31.** Wer ist Fahrzeughalter?

- *Mandantensicht:* Gesellschaft oder Person / nicht bekannt. Leasingnehmer separat unter Nutzungsgrundlage zuordnen.
- *Interner Hinweis:* Anzeige: Fahrzeug. Ziel: `Arbeitsmittel.a31_halter_ref`, `.a31_status`.

**A32.** Für welche Fahrten wurde das Fahrzeug eingesetzt?

- *Mandantensicht:* Kunden oder Lieferanten / Beteiligungsbesuche / Bank oder Berater / KG-Büro / andere berufliche Fahrten / private Fahrten. Fahrer aus A24 übernehmen; Kilometer und Grundlage der Aufteilung in A25.
- *Interner Hinweis:* Anzeige: Fahrzeug. Ziel: `Ressourcennutzungen.a32_fahrtzweck`.

### 5.3 Eine Kostenposition oder Abrechnung

**C20.** Welche Kostenposition wird beschrieben?

- *Mandantensicht:* Vergütung / Arbeitgeberbeiträge / Spesen / Raumkosten / Fahrzeug / IT oder Telefon / Software / Reise / Beratung / Buchführung / Versicherung / sonstige Verwaltung. Person, Raum, Mittel oder Aufgabe verknüpfen, soweit zuordenbar.
- *Interner Hinweis:* Ziel: `Kosten.kostenart`, `.person_ref`/`.raum_ref`/`.mittel_ref`/`.aufgabe_ref`.

**C21.** Welche Gesellschaft hat diese Kosten zunächst bezahlt?

- *Mandantensicht:* Gesellschaft auswählen / noch nicht bezahlt / nicht bekannt. Bei offener Rechnung Rechnungsempfänger separat benennen.
- *Interner Hinweis:* Ziel: `Kosten.zahlende_gesellschaft_ref`, `.c21_status`, `.c21_rechnungsempfaenger_text`.

**C22.** Auf welchen Zeitraum beziehen sich die Kosten?

- *Mandantensicht:* Beginn und Ende oder eindeutig bezeichnete Abrechnungsperiode.
- *Interner Hinweis:* Ziel: `Kosten.zeitraum_von`/`.zeitraum_bis`.

**C23.** Wie hoch ist der Betrag?

- *Mandantensicht:* Betrag laut Unterlagen / geschätzter Betrag / nicht bekannt; Betrag und Währung getrennte Felder. Kaufpreis, Abschreibung und laufende Betriebskosten als unterschiedliche Kostenarten führen.
- *Interner Hinweis:* Ziel: `Kosten.betrag_status`, `.betrag`, `.waehrung`.

**C24.** Wurden diese Kosten einer anderen Gesellschaft berechnet oder von ihr erstattet?

- *Mandantensicht:* Ja, vollständig / ja, teilweise / nein / noch offen / nicht bekannt.
- *Interner Hinweis:* Ziel: `Kosten.weiterberechnung`.

**C25.** Welche Gesellschaft erhielt die Rechnung oder erstattete die Kosten?

- *Mandantensicht:* Gesellschaft auswählen; Rechnungsempfänger und tatsächlich zahlende Gesellschaft getrennt ergänzen, wenn abweichend.
- *Interner Hinweis:* Anzeige: C24 = ja oder noch offen. Ziel: `Kostenverteilungen.empfaenger_gesellschaft_ref`, `.rechnungsempfaenger_ref`.

**C26.** Wie wurde der berechnete Anteil bestimmt?

- *Mandantensicht:* Direkt zugeordnet / Stunden / Nutzung / Fläche / Anzahl Nutzer / feste Pauschale / anderer Schlüssel / nicht bekannt. Bei Teilbeträgen Betrag separat angeben.
- *Interner Hinweis:* Anzeige: C24 = ja oder noch offen. Ziel: `Kostenverteilungen.schluessel`, `.betrag`.

**C27.** Wurde ein Zuschlag berechnet?

- *Mandantensicht:* Ja / nein / nicht bekannt; bei ja Zuschlagsbasis und Höhe getrennt.
- *Interner Hinweis:* Anzeige: C24 = ja oder noch offen. Ziel: `Kostenverteilungen.zuschlag` (Choice, 3 Werte), `.zuschlag_basis_text`, `.zuschlag_hoehe`.

**C28.** Welche Leistung rechnete die KG ab?

- *Mandantensicht:* Management / Personalbereitstellung / Arbeitsmittelbereitstellung / Kostenerstattung / andere Leistung / keine Abrechnung / nicht bekannt. Leistender, Empfänger, Zeitraum und Betrag aus vorhandener Abrechnung übernehmen, nicht erneut schätzen.
- *Interner Hinweis:* Ziel: `Abrechnungen.leistungsart`, `.leistender_ref`, `.empfaenger_ref`, `.zeitraum_von`/`.zeitraum_bis`, `.betrag`, `.waehrung`.

**C29.** Liegt eine Vereinbarung zu dieser Leistung vor?

- *Mandantensicht:* Unterzeichnet / nur Entwurf / vorhanden, derzeit nicht verfügbar / keine schriftliche Vereinbarung / nicht bekannt.
- *Interner Hinweis:* Ziel: `Abrechnungen.vereinbarung_status`, `.c29_nachweis_ref`.

**C30.** Welche Unterschiede zwischen Vereinbarung und tatsächlicher Ausführung sind bekannt?

- *Mandantensicht:* Keine bekannt / Unterschiede, kurz beschreiben / noch nicht verglichen. Eine bisher fehlende Prüfung nicht als Übereinstimmung speichern.
- *Interner Hinweis:* Ziel: `Abrechnungen.c30_abweichung`, `.c30_text`.

**C31.** Sind Angaben und Abrechnungen mit der Buchhaltung abgestimmt?

- *Mandantensicht:* Ja / teilweise / nein / noch nicht geprüft. Bekannte Differenzen separat benennen.
- *Interner Hinweis:* Ziel: `Abrechnungen.c31_abgestimmt`, `.c31_differenzen_text`.

## 6. Laufende Tätigkeit belegen und offene Angaben klären (Formular 5 — Nachweise und Abschluss)

Vorhandene Unterlagen können Sie jetzt gesammelt zuordnen oder später nachreichen. Bereits übermittelte Unterlagen genügt es zu benennen. Ein Dokument kann mehrere Angaben belegen.

**N20.** Welche Unterlage können Sie einer Angabe zuordnen?

- *Mandantensicht:* Vertrag oder Nachtrag / Stellenbeschreibung / Vollmacht oder Kompetenzordnung / E-Mail oder Gesprächsnotiz / Kalender oder Zeiterfassung / Plan oder Bericht / Beschluss oder Freigabe / Schulungsunterlage / Rechnung oder Buchung / Zahlungsnachweis / Raum- oder Gerätenachweis / andere Unterlage. Dokumenttitel und Datum als einzelne Felder.
- *Interner Hinweis:* Ziel: `Substanznachweise.dokumentart`, `.dokumenttitel_text`, `.dokumentdatum`.

**N21.** Welche Aufgabe, Zuständigkeit oder sonstige Angabe belegt die Unterlage?

- *Mandantensicht:* Vorhandene Person, Aufgabe, Entscheidungsbefugnis, Vertragszuständigkeit, Raum, Mittel oder Kostenposition auswählen; bei Bedarf Seite oder Abschnitt angeben. Laufende Unterlagen wie Managementberichte, Kalender, Zeitaufschriebe, Kompetenzordnungen oder wiederkehrende Abrechnungen können mehrere Angaben belegen.
- *Interner Hinweis:* Keine Mehrfachablage (B1): je belegter Angabe ein `Belegverknuepfungen`-Datensatz, generischer Bezug `ziel_typ`+`ziel_id`. Ziel: `Belegverknuepfungen.nachweis_ref`, `.ziel_typ`, `.ziel_id`, `.frage_id_text`, `.abschnitt_text`; `Substanznachweise.gesellschaft_ref`.

**N22.** Wie ist die Unterlage verfügbar?

- *Mandantensicht:* Wird jetzt übermittelt / bereits übermittelt / kann nachgereicht werden / derzeit nicht auffindbar / Dokument nicht vorhanden / Verfügbarkeit nicht bekannt. Externe Dateiübermittlung über den vorgesehenen Kanzleiweg; keine native Forms-Uploadfunktion voraussetzen.
- *Interner Hinweis:* Ziel: `Substanznachweise.verfuegbarkeit`, `.dateilink`.

**N23.** Welche Angaben müssen noch geklärt werden?

- *Mandantensicht:* Vorhandene offene Felder bestätigen / weitere offene Angabe benennen / keine weiteren offenen Angaben. Zuständige Person optional zuordnen; Nachreichtermin nur falls tatsächlich vereinbart.
- *Interner Hinweis:* Ziel: `OffenePunkte.art`, `.beschreibung_text`, `.bezug_ziel_typ`/`.bezug_ziel_id`, `.ansprechperson_ref`, `.nachreichtermin`.

**N24.** Wen können wir zu diesen Angaben ansprechen?

- *Mandantensicht:* Ausfüllende Person / andere benannte Person / unterschiedliche Ansprechpartner je Modul. Gesellschaft und Funktion aus Bestand übernehmen.
- *Interner Hinweis:* **Ersetzt S02** als einzigen Rückfragekontakt-Mechanismus. Ziel: `Erfassungen.auskunftsperson_ref`/`.auskunftsperson_text`.

**N25.** Entsprechen die Angaben Ihrem derzeitigen Kenntnisstand?

- *Mandantensicht:* Ja, Schätzungen und offene Punkte sind gekennzeichnet / es bestehen noch zu ergänzende Angaben. Keine rechtliche Vollständigkeitsbestätigung verlangen; beides erlaubt Übermittlung, letzteres setzt Status «unvollständig».
- *Interner Hinweis:* Ziel: `Erfassungen.confirmation_status`.

**N26.** Gibt es für eine wesentliche Angabe noch keinen passenden Nachweis?

- *Mandantensicht:* Nein / ja / nicht bekannt. Bei ja zunächst vorhandene laufende Unterlagen benennen. Nur wenn die Zuständigkeit oder tatsächliche Ausübung sonst nicht nachvollziehbar ist, kann die Kanzlei gezielt ein Vertragsmuster oder ein repräsentatives Beispiel anfordern. Kein allgemeines Pflichtfeld für einen einzelnen Geschäftsfall.
- *Interner Hinweis:* Ziel: `Erfassungen.missing_evidence_status`; ggf. zusätzlicher `OffenePunkte`-Datensatz (`art=FEHLENDER_NACHWEIS`).

## Interne Anhänge (nie in der Mandantensicht)

| Anhang | Inhalt | Dokument |
|---|---|---|
| A | Überarbeitung auf das Tagesgeschäft (A1-A5, Version 3) | [`interner-anhang-a-tagesgeschaeft-ueberarbeitung.md`](interner-anhang-a-tagesgeschaeft-ueberarbeitung.md) |
| B | Forms und SharePoint mit Aufgaben als Bezugseinheit (B1-B4) | aufgegangen in [Datenmodell](Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md) und [`sharepoint-forms/README.md`](sharepoint-forms/README.md) |
| C | Fachliche Vollständigkeit und Historie (Korrespondenz V1→V3) | [`interner-anhang-c-historie.md`](interner-anhang-c-historie.md) |
| D | Rechtliche Hintergründe der Vorfassung (= Anhang A in V1, D1-D7) | [`interner-anhang-d-rechtliche-hintergruende.md`](interner-anhang-d-rechtliche-hintergruende.md) |
| E | Historischer Fragenvorrat Version 1 (P01-N05) | [`interner-anhang-e-historischer-fragenvorrat-v1.md`](interner-anhang-e-historischer-fragenvorrat-v1.md) |
