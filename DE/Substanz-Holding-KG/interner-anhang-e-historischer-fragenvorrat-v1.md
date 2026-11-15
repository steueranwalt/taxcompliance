# Interner Anhang E: Historischer Fragenvorrat Version 1 (NUR INTERN)

> **Status seit Version 3 (Update 2):** Dieses Dokument ist **ausschliesslich für die interne Nachvollziehbarkeit** aufbewahrt (Vorgabe V3, Interner Anhang E: "Unverändert = Mandantenteil P01–N05 in `erfassungsbogen-entwurf-27-10-2026.md`. Nur intern, nicht zusätzlich ausgeben."). Es ist **keine aktuelle Mandantenvorlage mehr** und wird **nicht** an Mandanten versendet. Der aktuelle, mandantenfähige Fragenkatalog steht in [`Fragenkatalog-Substanzpruefung-Holding-KG.md`](Fragenkatalog-Substanzpruefung-Holding-KG.md) (Version 3). Die fachliche Begründung für die Ablösung ("Tagesgeschäft statt Einzelvorgang") steht in [`interner-anhang-a-tagesgeschaeft-ueberarbeitung.md`](interner-anhang-a-tagesgeschaeft-ueberarbeitung.md); die Fragen-Korrespondenztabelle V1→V3 in [`interner-anhang-c-historie.md`](interner-anhang-c-historie.md).

---

**Ursprünglicher Titel:** Fragenkatalog: Personen und tatsächlich ausgeübte Managementtätigkeiten (Version 1/2, Update 1, 27.10.2026). Nachfolgend unverändert archiviert.

**Legende Antworttyp (interner Hinweis, erschien nicht im Formular):** E = Einfachauswahl, M = Mehrfachauswahl, T = Text, Z = Zahl, D = Datum. Prozentangaben wurden als einzelne Zahlenfelder erfasst. Unterlagen erhielten eine Anlagenreferenz.

## Hinweise zum Ausfüllen (Mandantensicht, erscheint am Formularanfang)

Bitte erfassen Sie jede beteiligte Person einzeln, auch wenn sie bei einer anderen Gesellschaft angestellt ist oder mehrere Funktionen hat. Beschreiben Sie die tatsächlich ausgeübten Aufgaben. Eine Stellenbezeichnung oder eine vertragliche Aufgabenbeschreibung allein genügt nicht.

Die Angaben beziehen sich auf den im Begleitschreiben angegebenen Zeitraum. Falls noch kein Zeitraum vorgegeben wurde, geben Sie Anfang und Ende des von Ihnen beschriebenen Zeitraums an. Künftige Vorhaben bitte ausdrücklich als «geplant» kennzeichnen. Wenn sich die Verhältnisse geändert haben, unterscheiden Sie die Zeitabschnitte.

Die bekannten Gesellschaften werden als Auswahlliste bereitgestellt. Beteiligungsverhältnisse werden nicht nochmals abgefragt. Bei fehlenden Angaben wählen Sie «nicht bekannt»; bei fehlenden Unterlagen «nicht vorhanden» oder «wird nachgereicht». Diese Antworten sind von «nicht zutreffend» zu unterscheiden.

## 1. Person, Vertragsbindung und Einbindung (Formular 1 — Personenblatt)

**P01.** Wie heisst die Person?

- *Mandantensicht:* Freitext (Vorname, Nachname); bereits bekannte Personen können ausgewählt werden.
- *Interner Hinweis:* T. Ziel: `Personen.person_name`.

**P02.** Welche Funktion oder Stellenbezeichnung hat die Person?

- *Mandantensicht (Mehrfachauswahl):* Geschäftsführer / geschäftsführender Gesellschafter; Vorstand; Verwaltungsrat; CFO oder Finanzleitung; kaufmännische Leitung; Personalverantwortlicher; Bereichs- oder Projektleitung; Sachbearbeitung oder Assistenz; externer Berater; andere Funktion. Bitte für jede Funktion die betreffende Gesellschaft angeben.
- *Interner Hinweis:* M + T. Übersicht in `Personen.functions_overview`; je Funktion+Gesellschaft ein `Personenbindungen`-Datensatz (`funktion_code`).

**P03.** Bei welcher Gesellschaft oder welchem Auftraggeber besteht eine Anstellung oder eine andere vertragliche Bindung?

- *Mandantensicht (je Vertragsverhältnis):* Holding-KG / einzelne Beteiligungsgesellschaft / Schweizer Muttergesellschaft / andere Gesellschaft / keine vertragliche Bindung / nicht bekannt. Bei mehreren Bindungen jedes Verhältnis einzeln erfassen.
- *Interner Hinweis:* E je Vertragsverhältnis, Gesellschaft aus vorbereitetem Bestand. Ziel: `Personenbindungen.company_ref` (+ `company_status` für «keine»/«nicht bekannt»).

**P04.** Auf welcher Grundlage arbeitet die Person?

- *Mandantensicht (je Vertragsverhältnis):* Arbeitsvertrag / Geschäftsführer- oder Vorstandsvertrag / Mandats- oder Dienstleistungsvertrag / Tätigkeit als Gesellschafter ohne separaten Dienstvertrag / andere Vereinbarung / nur mündliche Vereinbarung / Grundlage nicht bekannt.
- *Interner Hinweis:* E. Ziel: `Personenbindungen.basis_code`.

**P05.** Liegt dazu ein schriftlicher Vertrag vor?

- *Mandantensicht:* Unterzeichnet vorhanden / nur Entwurf vorhanden / schriftlicher Vertrag vorhanden, aber derzeit nicht verfügbar / kein schriftlicher Vertrag / nicht bekannt. Bitte Vertrag, Nachträge, Stellenbeschreibung und gegebenenfalls Vereinbarung zum Einsatz bei anderen Gesellschaften beifügen oder benennen. Vertragsbeginn und gegebenenfalls Vertragsende angeben.
- *Interner Hinweis:* E + Anlagenreferenz. Ziel: `Personenbindungen.contract_status`, `.evidence_ref`, `.contract_start`, `.contract_end`.

**P06.** Seit wann übernimmt die Person tatsächlich Aufgaben im Zusammenhang mit der KG?

- *Mandantensicht:* Datum; genau bekannt / ungefähr bekannt. Falls Aufgaben gewechselt haben: Beginn und Ende je Aufgabenbereich ergänzen.
- *Interner Hinweis:* D + E. Ziel: `Personenbindungen.actual_start_date`, `.actual_start_precision`, `.task_change_text`.

**P07.** Wer legt im Arbeitsalltag die Aufgaben und Prioritäten dieser Person fest?

- *Mandantensicht (Mehrfachauswahl, Person + Gesellschaft):* Die Person selbst / eine andere benannte Person / mehrere benannte Personen / wechselnd nach Aufgabe / nicht bekannt. Wer kann konkrete Anweisungen geben, wer genehmigt Abwesenheiten und wer beurteilt die Arbeit? Namen und jeweilige Gesellschaft angeben.
- *Interner Hinweis:* M. Ziel: `Personeneinsaetze.weisungsgeber_ref` (LookupMulti), `.weisungsgeber_status`, `.weisungsgeber_text`.

**P08.** Wer vertritt die Person bei Abwesenheit?

- *Mandantensicht:* Benannte Vertretung / wechselnde Vertretung / keine Vertretung / nicht bekannt. Welche Aufgaben bleiben gegebenenfalls liegen?
- *Interner Hinweis:* E + Person/Gesellschaft. Ziel: `Personeneinsaetze.vertretung_ref`, `.vertretung_status`, `.liegengebliebene_aufgaben_text`.

## 2. Tatsächlich ausgeübte Aufgaben (Formular 2 — Tätigkeitsblatt)

**P09.** In welchen Bereichen arbeitet die Person tatsächlich?

- *Mandantensicht (Mehrfachauswahl, steuert Folgefragen):* Kunden, Vertrieb und Angebote; Einkauf, Lieferanten und Beschaffung; Personal und Mitarbeiterführung; Finanzen, Liquidität, Banken und Finanzierung; Buchführung, Steuern und Zusammenarbeit mit Beratern; Projekte, Leistungserbringung und betriebliche Abläufe; Unternehmensplanung, Budget und Investitionen; Berichte, Aufsicht und Kontrolle; Vorgaben, Anweisungen, Schulungen und Beratung; Organisation und Verwaltung der KG selbst; Wahrnehmung von Beteiligungs- und Gesellschafteraufgaben; Arbeiten für die Schweizer Muttergesellschaft; andere Aufgaben, bitte benennen; derzeit keine Aufgaben, nur geplant.
- *Interner Hinweis:* M; steuert Folgefragen (Forms-Branching je Bereich, siehe `sharepoint-forms/README.md`). Je ausgewähltem Bereich ein eigener `Taetigkeiten`-Datensatz (`bereich_code`).

### Aufgabenauswahl nach Bereichen (Handlungstabelle zu P09)

Für jeden ausgewählten Bereich die tatsächlich ausgeübten Handlungen markieren. Danach für jede unterscheidbare Tätigkeit den Zuordnungsblock P10 bis P18 ausfüllen. Unterschiedliche Empfänger oder Rollen werden getrennt erfasst.

| Bereich | Auswählbare tatsächliche Handlungen |
|---|---|
| Kunden und Vertrieb | Kundenkontakte anbahnen; Kunden betreuen; Angebote ausarbeiten; Preise und Rabatte bestimmen; Leistungsumfang und Termine verhandeln; Vertragsbedingungen aushandeln; Aufträge annehmen oder ablehnen; Reklamationen lösen; Vertriebsmitarbeitern konkrete Aufgaben geben |
| Lieferanten und Einkauf | Bedarf feststellen; Angebote einholen; Lieferanten auswählen; Preise, Mengen und Lieferbedingungen verhandeln; Bestellungen freigeben; Verträge aushandeln; Lieferprobleme entscheiden |
| Personal | Personalbedarf planen; Bewerber suchen und auswählen; Vorstellungsgespräche führen; Vergütung und Vertragsbedingungen verhandeln; Einstellungen oder Kündigungen entscheiden; Arbeitsverträge vorbereiten; Arbeitsverträge unterzeichnen; Ziele und Aufgaben festlegen; Arbeitseinsätze und Urlaub genehmigen; Leistung beurteilen |
| Finanzen und Banken | Liquidität planen; Zahlungen priorisieren oder freigeben; Forderungen verfolgen; Bankgespräche führen; Kredit- und Sicherheitenbedingungen verhandeln; Finanzierungsvorschläge vergleichen; Kredite auswählen; Finanzierung überwachen |
| Buchführung und Steuern | Belege bearbeiten; Monats- oder Jahresabschluss vorbereiten; Buchhalter und Steuerberater beauftragen oder steuern; Sachverhalte erläutern; steuerliche Wahlmöglichkeiten zur Entscheidung vorlegen; Entscheidungen nach Beratung treffen; Fristen überwachen |
| Projekte und Betrieb | Kapazitäten und Termine planen; Projekte leiten; Mitarbeitereinsatz bestimmen; Qualität und Leistungserbringung steuern; konkrete Probleme lösen; Leistungen oder Ergebnisse abnehmen |
| Planung und Investitionen | Unternehmensplanung erstellen; Budgets erarbeiten; Budgets freigeben; Investitionen prüfen; Investitionen auswählen oder freigeben; Umsetzung überwachen |
| Berichte und Kontrolle | Kennzahlen sammeln; Berichte erstellen; Berichte prüfen; Abweichungen erklären lassen; Geschäftsleitung befragen; Einhaltung von Vorgaben prüfen; Massnahmen empfehlen; konkrete Korrekturmassnahmen anordnen; Umsetzung verfolgen |
| Vorgaben und Schulung | allgemeine Richtlinien entwerfen; Richtlinien beschliessen; konkrete Einzelanweisungen geben; Mitarbeitende fachlich beraten; Schulungen konzipieren; Schulungen durchführen; Umsetzung in einzelnen Vorgängen begleiten |
| Eigene Organisation der KG | eigene Buchführung; eigene Steuerangelegenheiten; eigene Bankkonten und Zahlungen; eigenes Personal; eigene Räume und Ausstattung; eigene IT; eigene Managementverträge und Abrechnungen |
| Beteiligungs- und Gesellschafteraufgaben | Beteiligungen überwachen; Erwerb oder Verkauf von Beteiligungen vorbereiten; Stimmrechtsausübung vorbereiten; Gesellschafterbeschlüsse vorbereiten; als Vertreter eines Gesellschafters abstimmen; Ausschüttungsentscheidungen vorbereiten; Kapitalmassnahmen vorbereiten; Organbestellungen vorbereiten |
| Schweizer Mutter | Unterlagen für deren eigenen Abschluss oder Steuererklärungen erstellen; Unterlagen für Konzernabschluss aufbereiten; deren Gesellschafter- oder Verwaltungsratssitzungen vorbereiten; deren Investoren oder Finanzierer informieren; deren Beteiligungserwerb finanzieren; sonstige konkrete Arbeiten benennen |

*Interner Hinweis:* 90 Handlungen gesamt, als ein gemeinsames Choice-Codebook `P09_HANDLUNG` (Ziel: `Taetigkeiten.handlung_code`) hinterlegt; Forms zeigt je gewähltem Bereich nur die passende Teilliste (Branching, siehe `sharepoint-forms/README.md`). Vollständige Codes in `feldkatalog/feldkatalog.json`, Codebook `P09_HANDLUNG`.

### Zuordnungsblock: für jede Tätigkeit einzeln

**P10.** Welche konkrete Tätigkeit wird erfasst?

- *Mandantensicht:* Auswahl aus den markierten Handlungen des gewählten Bereichs + Freitext. Bitte nicht nur «Management» oder «Controlling» schreiben. Beispiel: «Monatliche Liquiditätsplanung für Gesellschaft A und Verhandlung ihrer Kontokorrentlinie».
- *Interner Hinweis:* Auswahl aus P09-Handlungstabelle + T. Ziel: `Taetigkeiten.handlung_code`, `.activity_text`.

**P11.** Für welche Gesellschaft wird die Tätigkeit ausgeführt und wer nutzt das Ergebnis unmittelbar?

- *Mandantensicht:* Holding-KG selbst / benannte Beteiligungsgesellschaft / Schweizer Mutter / andere Gesellschaft / nicht eindeutig. Bei mehreren unmittelbaren Empfängern Tätigkeit aufteilen oder gemeinsame Nutzung samt Aufteilung erläutern. «Konzern insgesamt» bitte durch konkrete Empfänger und Verwendungszwecke erläutern.
- *Interner Hinweis:* je E aus Gesellschaftsliste. Ziel: `Taetigkeiten.empfaenger_ref`, `.empfaenger_status`, `.mehrere_empfaenger_text`.

**P12.** In wessen Auftrag und in welcher Funktion handelt die Person dabei?

- *Mandantensicht:* Im Auftrag der KG / unmittelbar im Auftrag einer Beteiligungsgesellschaft / im Auftrag der Schweizer Mutter / aufgrund eigener Organfunktion bei der betreffenden Gesellschaft / als Vertreter eines Gesellschafters / anders / nicht bekannt. Auftraggebende Person und Gesellschaft benennen; mehrere Funktionen getrennt darstellen.
- *Interner Hinweis:* je E + Person/Gesellschaft. Ziel: `Taetigkeiten.auftrag_funktion`, `.auftraggeber_person_ref`, `.auftraggeber_gesellschaft_ref`.

**P13.** Was macht die Person bei dieser Tätigkeit?

- *Mandantensicht (Mehrfachauswahl):* Informationen sammeln / Vorschlag erarbeiten / Verhandlungen führen / verbindliche Vorgaben machen / selbst entscheiden / fremde Entscheidung umsetzen / Arbeit anderer kontrollieren / beraten oder schulen / nur berichten. Bitte bei mehreren Schritten den Ablauf kurz beschreiben.
- *Interner Hinweis:* M. Ziel: `Taetigkeiten.handlungstyp`, `.ablauf_text`.

**P14.** Wofür wird das Ergebnis konkret verwendet?

- *Mandantensicht (Mehrfachauswahl + kurzes Beispiel):* Für einen Kundenauftrag / Einkauf oder Lieferantenvertrag / Personalentscheidung / Finanzierung oder Zahlung / betriebliche Planung oder Umsetzung / Kontrolle der Geschäftsleitung / Verwaltung der KG selbst / Ausübung von Stimmrechten oder andere Gesellschafterbeschlüsse / Abschluss oder Berichterstattung der Schweizer Mutter / anderer Zweck.
- *Interner Hinweis:* M + T. Ziel: `Taetigkeiten.verwendungszweck`, `.verwendung_beispiel_text`.

**P15.** Seit wann, wie häufig und mit welchem Zeitaufwand erfolgt diese Tätigkeit?

- *Mandantensicht:* Beginn, gegebenenfalls Ende; täglich / mehrmals pro Woche / wöchentlich / monatlich / quartalsweise / jährlich / nur bei Bedarf / einmalig. Stunden im Bezugszeitraum; bei Schätzung als solche kennzeichnen. Häufigkeit und Stunden getrennt angeben.
- *Interner Hinweis:* D; E; Z. Ziel: `Taetigkeiten.activity_start`, `.activity_end`, `.frequency`, `.hours`, `.is_estimate`.

**P16.** Wo wird diese konkrete Tätigkeit ausgeübt?

- *Mandantensicht (je Ort eine Zahl):* KG-Büro / Räume einer benannten Beteiligungsgesellschaft / Homeoffice / Räume der Schweizer Gesellschaft / unterwegs oder beim Geschäftspartner / anderer Ort. Adresse beziehungsweise Ort und Land angeben. Zeitanteile dieser Tätigkeit auf die Orte verteilen, insgesamt 100 %. Bei Telefonaten und Videokonferenzen zählt der tatsächliche Aufenthaltsort der Person.
- *Interner Hinweis:* Z je Ort. Kein eigenes `Taetigkeiten`-Feld; Ziel: `Zeitverteilungen` (`bezug_typ=TAETIGKEIT`, `dimension=ORT`), 100-%-Prüfung mit Toleranz im Flow.

**P17.** Welches konkrete Ergebnis ist im Bezugszeitraum entstanden?

- *Mandantensicht:* Zum Beispiel verhandeltes Angebot, Vertragsentwurf, Einstellungsentscheidung, Liquiditätsplan, Schulungsunterlage oder Bericht. Datum, Empfänger und vorhandene Unterlagen nennen. Falls kein Fall angefallen ist: «kein tatsächlicher Fall im Zeitraum» auswählen.
- *Interner Hinweis:* T + Anlagenreferenz. Ziel: `Taetigkeiten.ergebnis_text`, `.ergebnis_datum`, `.ergebnis_empfaenger_text`, `.kein_fall_im_zeitraum`, `.ergebnis_nachweis_ref`.

**P18.** Wer erbringt dieselbe oder eine ähnliche Arbeit zusätzlich?

- *Mandantensicht:* Niemand / interne Person / externer Dienstleister / nicht bekannt. Was ergänzt die Person konkret, und welches zusätzliche Ergebnis entsteht? Falls das Ergebnis ausschliesslich für Berichtspflichten der Mutter angefordert wurde, dies angeben.
- *Interner Hinweis:* E + Person/Gesellschaft + T. Ziel: `Taetigkeiten.zusatz_erbringer`, `.zusatz_person_ref`, `.zusatz_gesellschaft_text`, `.zusatz_ergaenzung_text`, `.zusatz_nur_berichtspflicht_mutter`.

## 3. Arbeitszeit und tatsächliche Arbeitsorte je Person (Formular 1 — Personenblatt)

**P19.** Wie häufig arbeitet die Person insgesamt an Aufgaben im Zusammenhang mit der KG?

- *Mandantensicht:* Täglich / mehrmals pro Woche / wöchentlich / monatlich / nur bei Bedarf / im Zeitraum nicht tätig.
- *Interner Hinweis:* E. Ziel: `Personeneinsaetze.overall_frequency`.

**P20.** Wie gross ist die gesamte Arbeitszeit der Person und welcher Teil entfällt auf Tätigkeiten im Auftrag der KG?

- *Mandantensicht:* Gesamte Wochenstunden oder gesamte Stunden im Bezugszeitraum; davon Stunden im Auftrag der KG; daraus ungefährer Prozentanteil. Grundlage: Zeiterfassung / Kalenderauswertung / begründete Schätzung / andere Grundlage. Eigene Tätigkeiten für Beteiligungen ausserhalb eines KG-Auftrags gesondert angeben.
- *Interner Hinweis:* Z + Zeitraum + E. Ziel: `Personeneinsaetze.total_hours`, `.kg_hours`, `.kg_share_pct`, `.basis_code`, `.separate_activity_text`.

**P21.** Wie verteilen sich die Stunden im Auftrag der KG nach den unmittelbaren Empfängern?

- *Mandantensicht (je Empfänger eine Zahl):* KG selbst / jede betroffene Beteiligungsgesellschaft einzeln / Schweizer Mutter / andere Empfänger. Gesamt = 100 % der Stunden im Auftrag der KG. Die Tätigkeit für einen Empfänger bestimmt nicht automatisch, wer die Kosten tragen muss.
- *Interner Hinweis:* Z je Empfänger. Ziel: `Zeitverteilungen` (`bezug_typ=EINSATZ`, `dimension=EMPFAENGER`).

**P22.** Wie verteilen sich die Stunden im Auftrag der KG nach Arbeitsorten?

- *Mandantensicht (je Ort eine Zahl):* KG-Büro / einzelne Beteiligungsstandorte / jedes Homeoffice / Schweizer Gesellschaft / sonstige Orte. Gesamt = 100 % derselben Stunden. Für jeden Standort Ort, Land und möglichst Adresse angeben. P16 dient der genaueren Zuordnung einzelner Aufgaben.
- *Interner Hinweis:* Z je Ort. Ziel: `Zeitverteilungen` (`bezug_typ=EINSATZ`, `dimension=ORT`).

**P23.** Wie häufig und wie lange arbeitet die Person tatsächlich im KG-Büro?

- *Mandantensicht:* Täglich / mehrmals pro Woche / wöchentlich / monatlich / seltener / nie. Ungefähre Tage im Monat und Stunden je Anwesenheit; typische Tätigkeiten dort angeben.
- *Interner Hinweis:* E + Z. Ziel: `Personeneinsaetze.office_frequency`, `.office_days_per_month`, `.office_hours_per_visit`, `.office_typical_tasks_text`.

**P24.** Gibt es erhebliche zeitliche Schwankungen oder Änderungen?

- *Mandantensicht:* Nein / saisonal / projektbedingt / wegen Beginn oder Ende einer Funktion / andere Änderung. Betroffene Zeiträume und abweichende Stunden oder Orte angeben. Reisezeiten gesondert ausweisen, ohne sie zusätzlich als Arbeitszeit am Zielort zu zählen.
- *Interner Hinweis:* E + T. Ziel: `Personeneinsaetze.variation_type`, `.variation_text`, `.travel_time_text`.

## 4. Entscheidungen, Vorbereitung und Freigaben (Formular 3 — Entscheidungs-/Vertrags-/Kontrollblatt, Abschnitt E)

Diesen Block für jede relevante Entscheidungsart und betroffene Gesellschaft ausfüllen. Auch Personal-, Finanz- und Projektentscheidungen innerhalb einer Gesellschaft sind anzugeben.

**E01.** Um welche Entscheidung geht es?

- *Mandantensicht:* Kundenpreise oder Aufträge / Lieferanten oder Bestellungen / Einstellungen, Vergütung oder Kündigungen / Arbeitsorganisation / Finanzierung oder Sicherheiten / Zahlungen / Budget oder Investition / betriebliche oder strategische Planung / Beteiligungserwerb oder -verkauf / Ausschüttung / Kapitalmassnahme / Bestellung oder Abberufung eines Organs / andere Entscheidung.
- *Interner Hinweis:* E. Ziel: `Entscheidungsfaelle.art_code` (gemeinsames Codebook mit K05).

**E02.** Welche Gesellschaft betrifft die Entscheidung?

- *Mandantensicht:* Auswahl aus Gesellschaftsliste.
- *Interner Hinweis:* E Gesellschaft. Ziel: `Entscheidungsfaelle.gesellschaft_ref`, `.gesellschaft_status`.

**E03.** Welche Rolle hat die Person dabei tatsächlich?

- *Mandantensicht (Mehrfachauswahl):* Ermittelt Grundlagen / entwickelt Alternativen / empfiehlt eine Lösung / verhandelt mit Dritten / entscheidet selbst / entscheidet mit anderen / erteilt notwendige Zustimmung / setzt Entscheidung um / kontrolliert Umsetzung / wird nur informiert.
- *Interner Hinweis:* M. Ziel: `Fallbeteiligungen.e03_rolle` (je beteiligter Person ein Datensatz).

**E04.** Wer bestimmt tatsächlich das Ergebnis?

- *Mandantensicht:* Die Person allein / gemeinsam mit benannten Personen / andere Person / Sitzung eines benannten Gremiums / Gesellschafterbeschluss / nicht bekannt. Funktion und Gesellschaft der Entscheider angeben. Bei mehreren Rollen derselben Person jeweils angeben, in welcher Rolle sie handelt.
- *Interner Hinweis:* Person/Gesellschaft + E. Ziel: `Fallbeteiligungen.e04_entscheider`, `.person_ref`.

**E05.** Welche Grenzen oder Freigaben bestehen?

- *Mandantensicht (Mehrfachauswahl + Zahl/Text):* Keine zusätzliche Freigabe / innerhalb eines Budgets / bis zu einem Betrag / nur nach Zustimmung der Geschäftsleitung / nur nach Zustimmung von Gesellschaftern oder anderem Gremium / andere Vorgabe. Betragsgrenze mit Währung; schriftliche Regelung als Anlage.
- *Interner Hinweis:* M + Z/T. Ziel: `Entscheidungsfaelle.e05_grenzen`, `.e05_betrag`, `.e05_waehrung`, `.e05_regelung_ref`.

**E06.** Wie läuft eine Zustimmung in der Praxis ab?

- *Mandantensicht (+ Beispiel):* Andere Person prüft und ändert regelmässig Inhalte / prüft inhaltlich, ändert selten / bestätigt üblicherweise den fertigen Vorschlag / zeichnet lediglich formal gegen / Zustimmung wird nicht eingeholt / nicht bekannt. Kann die zustimmende Person ablehnen, und wann ist das zuletzt geschehen?
- *Interner Hinweis:* E + Beispiel. Ziel: `Entscheidungsfaelle.e06_ablauf`, `.e06_beispiel_text`.

**E07.** Wo halten sich die Beteiligten bei Vorbereitung, inhaltlicher Festlegung und abschliessender Freigabe auf?

- *Mandantensicht:* Jeden Schritt getrennt angeben. Bei Video-, Telefon- und Umlaufentscheidungen Aufenthaltsorte der einzelnen Beteiligten erfassen. Protokollort, Serverstandort und tatsächlicher Aufenthaltsort nicht gleichsetzen.
- *Interner Hinweis:* Person + Schritt + Ort/Land. Ziel: `Fallbeteiligungen.schritt`, `.ort_ref`, `.land_text`.

**E08.** Bitte nennen Sie einen tatsächlich abgeschlossenen Entscheidungsfall.

- *Mandantensicht:* Gegenstand; betroffene Gesellschaft; vorbereitende, entscheidende und unterzeichnende Personen; Datum; tatsächliche Orte; Ergebnis; Nachweis. Falls nur geplant, entsprechend kennzeichnen.
- *Interner Hinweis:* T + D + Anlagenreferenz. Ziel: `Entscheidungsfaelle.inhalt`, `.status`, `.ergebnis`, `.e08_datum`, `.e08_nachweis_ref`.

## 5. Vertragsverhandlungen und Abschlussreife (Formular 3, Abschnitt V)

Für jede Vertragsart und betroffene Gesellschaft gesondert beantworten. Eine fehlende Unterschriftsbefugnis schliesst die Fragen zu Verhandlungen nicht aus.

**V01.** Bei welchen Geschäften wirkt die Person mit?

- *Mandantensicht (Mehrfachauswahl):* Kundenverträge / Lieferantenverträge / Personalverträge / Kredite und Sicherheiten / Miet- oder Leasingverträge / Beraterverträge / sonstige Verträge / keine Mitwirkung. Nur ausgewählte Arten weiterführen.
- *Interner Hinweis:* M; «keine Mitwirkung» beendet den Abschnitt. Je Art ein `Vertragsvorgaenge`-Datensatz (`vertragsart`).

**V02.** Welche Gesellschaft soll Vertragspartei werden?

- *Mandantensicht:* Auswahl aus Gesellschaftsliste.
- *Interner Hinweis:* E Gesellschaft. Ziel: `Vertragsvorgaenge.vertragsgesellschaft_ref`.

**V03.** Welche Schritte übernimmt die Person tatsächlich?

- *Mandantensicht (Mehrfachauswahl):* Kontakt herstellen / Bedarf und Rahmen klären / Vertragspartner auswählen / Angebot erstellen oder einholen / Preise oder Vergütung verhandeln / Leistung, Menge, Laufzeit oder Termine verhandeln / Haftung, Sicherheiten oder Kündigung verhandeln / fertigen Vertragsentwurf abstimmen / bindende Zusage geben / unterzeichnen / nur Unterlagen weiterleiten.
- *Interner Hinweis:* M. Ziel: `Fallbeteiligungen.v03_schritte`.

**V04.** Mit wem führt sie diese Gespräche?

- *Mandantensicht (Mehrfachauswahl + Gesellschaft/Organisation):* Kunden / Lieferanten / Bewerber oder Mitarbeitende / Banken oder Finanzierer / Steuerberater oder Buchhalter / andere Berater / interne Verantwortliche / andere Gesprächspartner.
- *Interner Hinweis:* M + Gesellschaft/Organisation. Ziel: `Fallbeteiligungen.v04_gespraechspartner`, `.v04_gespraechspartner_text`.

**V05.** Was ist nach ihrer Verhandlung noch offen?

- *Mandantensicht:* Wesentliche wirtschaftliche Punkte / einzelne wirtschaftliche Punkte / nur rechtliche Detailprüfung / nur interne Freigabe / nur Unterschrift / nichts, bereits bindend vereinbart / nicht bekannt. Welche Punkte genau?
- *Interner Hinweis:* E + T. Ziel: `Vertragsvorgaenge.v05_offene_punkte`, `.v05_text`.

**V06.** Wer prüft, ändert oder genehmigt danach den Vertrag?

- *Mandantensicht:* Regelmässige wesentliche Änderungen / gelegentliche wesentliche Änderungen / gewöhnlich keine wesentlichen Änderungen / keine weitere Prüfung / nicht bekannt. Letzte Änderung oder Ablehnung als Beispiel nennen.
- *Interner Hinweis:* Person/Gesellschaft + E. Ziel: `Vertragsvorgaenge.v06_aenderungshaeufigkeit`, `.v06_beispiel_text`.

**V07.** Welche Unterlagen darf die Person für welche Gesellschaft unterzeichnen oder verbindlich bestätigen?

- *Mandantensicht (Mehrfachauswahl + Grenzen + Anlage):* Angebote / Auftragsbestätigungen / Kundenverträge / Bestellungen und Lieferantenverträge / Arbeitsverträge / Finanzierungsverträge / Zahlungsfreigaben / Berateraufträge / sonstige Dokumente / keine. Allein oder gemeinsam; Betragsgrenzen; Vollmacht oder Kompetenzordnung. Auch bindende E-Mail-Zusagen erfassen.
- *Interner Hinweis:* M + Grenzen + Anlage. Ziel: `Fallbeteiligungen.v07_unterlagenart`, `.v07_grenzen_text`, `.v07_nachweis_ref`, `.v07_email_zusage`.

**V08.** Wie häufig und wo finden Verhandlungen und Abschlüsse statt?

- *Mandantensicht:* Anzahl Vorgänge im Zeitraum; Verhandlungsort je Person; Ort der inhaltlichen Einigung; Freigabeort; Unterzeichnungsort. Bei unterschiedlichem Ablauf mehrere typische Fälle unterscheiden.
- *Interner Hinweis:* Z + Orte. Ziel: `Vertragsvorgaenge.v08_anzahl_vorgaenge`; Orte je Schritt in `Fallbeteiligungen.schritt`/`.ort_ref` (Codes VERHANDLUNG/INHALTLICHE_EINIGUNG/FREIGABE_VERTRAG/UNTERZEICHNUNG).

**V09.** Bitte beschreiben Sie einen bis zur Unterschrift vorbereiteten Vertrag.

- *Mandantensicht:* Vertragsart, Vertragsgesellschaft, Gegenpartei, beteiligte Personen, Zeitpunkte und Orte, ausgehandelte wesentliche Bedingungen, verbleibende Prüfung, tatsächliche Änderungen, Unterzeichner. Geeignete Anlagen: E-Mail-Verlauf, Entwurfsstände, Verhandlungsnotiz, Freigabe und unterschriebener Vertrag.
- *Interner Hinweis:* T + Anlagenreferenzen (mehrfach). Ziel: `Vertragsvorgaenge.gegenpartei_text`, `.v09_text`, `.v09_nachweis_ref` (LookupMulti).

## 6. Aufsicht, Kontrolle, Anweisungen und Schulungen (Formular 3, Abschnitt K)

**K01.** Was wird geprüft oder überwacht?

- *Mandantensicht (Mehrfachauswahl):* Geschäftsergebnis / Budget / Liquidität / Projekte / Personal / Einhaltung von Vorgaben / Tätigkeit der Geschäftsleitung / Wertentwicklung einer Beteiligung / anderes. Betroffene Gesellschaft auswählen.
- *Interner Hinweis:* M. Ziel: `Taetigkeiten.k01_gegenstand` (nur bei `bereich_code=BERICHTE_KONTROLLE`); Gesellschaft = `.empfaenger_ref`.

**K02.** Was geschieht bei einer Abweichung tatsächlich?

- *Mandantensicht (Mehrfachauswahl):* Bericht wird zur Kenntnis genommen / Erläuterung wird angefordert / Empfehlung wird abgegeben / allgemeine Vorgabe wird geändert / konkrete Massnahme wird verbindlich angeordnet / Person entscheidet den Einzelfall selbst / andere Reaktion. Beispiel und Empfänger angeben.
- *Interner Hinweis:* M. Ziel: `Taetigkeiten.k02_reaktion`, `.k02_beispiel_empfaenger_text`.

**K03.** Welchen Inhalt haben Anweisungen und Schulungen?

- *Mandantensicht (Mehrfachauswahl + Text):* Allgemeine Grundsätze / Fachwissen oder Methoden / Anwendung einer Software / Regeln und Abläufe / konkrete Bearbeitung eines Kunden-, Personal- oder Finanzierungsvorgangs / andere Inhalte. Wer bestimmt die Inhalte, wer nimmt teil, wer setzt sie um?
- *Interner Hinweis:* M + T. Ziel: `Taetigkeiten.k03_inhalt`, `.k03_inhalt_andere_text`, `.k03_wer_bestimmt_ref`, `.k03_wer_nimmt_teil_text`, `.k03_wer_setzt_um_ref`.

**K04.** Steuert die Person bestimmte Mitarbeitende oder Dienstleister?

- *Mandantensicht:* Regelmässig / fallweise / nein. Je gesteuerter Person oder Dienstleister: Name oder Funktion; Arbeitgeber beziehungsweise Vertragspartner; Gesellschaft, für die gearbeitet wird; Art der Steuerung; Häufigkeit; Befugnis, Aufgaben, Termine und Ergebnisse verbindlich festzulegen.
- *Interner Hinweis:* E + Liste. Ziel: `Steuerungsbeziehungen` (eigener Datensatz je gesteuerter Person/Dienstleister).

**K05.** Bitte nennen Sie einen Kontroll-, Anweisungs- oder Schulungsfall aus dem Zeitraum.

- *Mandantensicht:* Anlass, Beteiligte, Gesellschaft, Inhalt, Reaktion und Ergebnis; zum Beispiel Bericht mit Rückfragen, Massnahmenliste, konkrete Weisung, Schulungsagenda und Teilnehmerliste.
- *Interner Hinweis:* T + Anlagenreferenz. Ziel: `Entscheidungsfaelle.k05_text`, `.k05_nachweis_ref` (`art_code=E01_ART_KONTROLLE_ANWEISUNG_SCHULUNG`).

## 7. Eigene Aufgaben der KG und Arbeiten für die Muttergesellschaft (Formular 4 — Organisationsblatt)

**G01.** Welche Arbeiten dienen der eigenen Organisation der KG?

- *Mandantensicht (Mehrfachauswahl):* Eigene Buchführung und Abschlüsse / eigene Steuern / eigene Personalverwaltung / eigene Räume und Arbeitsmittel / eigene IT / eigene Finanzierung / Abrechnung ihrer Leistungen / eigene Vertragsverwaltung / andere / keine. Person und Zeitaufwand über P10 bis P18 zuordnen.
- *Interner Hinweis:* M; Gateway-Auswahl, keine eigene Spalte. Konkrete Arbeiten als `Taetigkeiten`-Datensätze mit `bereich_code=EIGENE_ORGANISATION`.

**G02.** Welche Aufgaben nimmt die KG im Zusammenhang mit ihren eigenen Beteiligungen wahr?

- *Mandantensicht (Mehrfachauswahl):* Überwachung der Beteiligungsentwicklung / Vorbereitung eigener Stimmabgaben / eigene Beteiligungserwerbe oder -verkäufe / Vorbereitung von Ausschüttungs- oder Kapitalentscheidungen ihrer Beteiligungen / andere / keine. Von Managementleistungen an die Beteiligungsgesellschaften getrennt beschreiben.
- *Interner Hinweis:* M; Gateway-Auswahl. Konkrete Arbeiten als `Taetigkeiten` mit `bereich_code=BETEILIGUNGS_GESELLSCHAFTER`.

**G03.** Welche Arbeiten werden für die Schweizer Muttergesellschaft erledigt?

- *Mandantensicht (Mehrfachauswahl):* Eigener Abschluss der Mutter / Konzernabschluss / eigene Steuererklärungen der Mutter / Gesellschafter- oder Verwaltungsratssitzungen der Mutter / Berichte an deren Anteilseigner / Finanzierung ihrer Beteiligungserwerbe / andere Arbeiten / keine. Je Arbeit konkreten Auftrag, Empfänger und Verwendungszweck nennen.
- *Interner Hinweis:* M; Gateway-Auswahl. Konkrete Arbeiten als `Taetigkeiten` mit `bereich_code=SCHWEIZER_MUTTER`.

**G04.** Wer hat diese Arbeiten angefordert und was entsteht daraus?

- *Mandantensicht:* Einzelabschluss / Konzernabschluss / Informationsbericht / Beschlussvorlage / Finanzierung / operative Entscheidung für eine benannte Gesellschaft / anderes Ergebnis. Wenn Unterlagen mehrfach genutzt werden, die unterschiedlichen Verwendungen beschreiben.
- *Interner Hinweis:* Person/Gesellschaft + M. Ziel: `Taetigkeiten.g04_ergebnistyp`, `.g04_mehrfachnutzung_text` (Auftraggeber bereits über P12).

**G05.** Wer würde die Arbeit erledigen, wenn die KG sie nicht übernähme?

- *Mandantensicht:* Die betreffende Beteiligung selbst / die Schweizer Mutter / anderer interner Bereich / externer Dienstleister / Arbeit würde entfallen / nicht bekannt. Tatsächliche Vertretung oder bisherige Handhabung nennen, sofern bekannt; keine rechtliche Beurteilung erforderlich.
- *Interner Hinweis:* E + T. Ziel: `Taetigkeiten.g05_alternative`, `.g05_text`.

**G06.** Gibt es schriftliche Leistungsvereinbarungen und tatsächlich gestellte Rechnungen?

- *Mandantensicht (je Dokumentart + Anlage):* Vorhanden / nicht vorhanden / wird nachgereicht / nicht bekannt. Vertragsparteien, Leistungsbeschreibung, Leistungszeitraum und Abrechnung benennen. Abweichungen zwischen Vereinbarung und tatsächlicher Arbeit kurz angeben.
- *Interner Hinweis:* E je Dokumentart + Anlage. Ziel: `Abrechnungen.g06_vereinbarung_status`, `.g06_vereinbarung_nachweis_ref`, `.g06_rechnung_status`, `.g06_rechnung_nachweis_ref`, `.g06_abweichung_text`.

## 8. Räume und tatsächliche Nutzung (Formular 5 — Raumblatt)

Für jeden Raum beziehungsweise klar abgegrenzten Arbeitsbereich einzeln ausfüllen. Arbeitsplatz in Räumen einer Beteiligung ausdrücklich als solchen erfassen.

**R01.** Welche Räume oder Arbeitsbereiche nutzt die KG?

- *Mandantensicht (+ Adresse):* Eigenes abgeschlossenes Büro / eigener Raum bei Beteiligung / gemeinsamer Raum bei Beteiligung / flexibel verfügbarer Arbeitsplatz / Besprechungsraum / Homeoffice / Räume der Schweizer Gesellschaft / Lager oder Archiv / andere Fläche.
- *Interner Hinweis:* E + Adresse. Ziel: `Raeume.ort_ref`, `.raumart` (**Raumart-Katalog jetzt durch R01 vorgegeben — frühere offene Frage damit erledigt**).

**R02.** Wer ist Eigentümer, Mieter und gegebenenfalls Untervermieter?

- *Mandantensicht (je Gesellschaft/Person + Anlage):* Jeweils getrennt angeben. Miet-, Untermiet- oder Nutzungsvereinbarung beifügen; Beginn und Ende der Nutzung nennen.
- *Interner Hinweis:* je Gesellschaft/Person + Anlage. Ziel: `Raeume.eigentuemer_gesellschaft_ref`, `.eigentuemer_person_ref`, `.mieter_ref`, `.untervermieter_text`, `.r02_nachweis_ref`, `.nutzung_beginn`, `.nutzung_ende`.

**R03.** Worüber kann die KG tatsächlich verfügen?

- *Mandantensicht (Mehrfachauswahl + Zahl):* Eigener Schlüssel oder Zugang / jederzeitiger Zugang / Zugang nur nach Anmeldung / fest zugewiesene Arbeitsplätze / nur gelegentliche Buchung / eigene Ablage / abschliessbare Aufbewahrung / eigene Beschilderung / keine ausschliessliche Fläche. Fläche in m² und Anzahl Arbeitsplätze angeben; bei gemeinsamer Nutzung deren Aufteilung erläutern.
- *Interner Hinweis:* M + Z. Ziel: `Raeume.verfuegung`, `.flaeche_qm`, `.anzahl_arbeitsplaetze`, `.aufteilung_text`.

**R04.** Wer arbeitet dort tatsächlich und wofür?

- *Mandantensicht (je Nutzer):* Typische Tage beziehungsweise Stunden im Monat, Aufgaben und Gesellschaft, für die gearbeitet wird. Andere Nutzer und zeitliche Überschneidungen angeben.
- *Interner Hinweis:* Person + Tätigkeit + Z. Ziel: `Ressourcennutzungen` (`bezug_typ=RAUM`, `raum_ref`, `person_ref`, `gesellschaft_ref`, `tage_oder_stunden_pro_monat`).

**R05.** Wie wird die Nutzung belegt?

- *Mandantensicht (Mehrfachauswahl + Anlagenreferenz):* Grundriss / Miet- oder Nutzungsvertrag / Fotos / Buchungs- oder Zutrittsdaten / Kalender / Besprechungsunterlagen / andere Unterlage / keine Unterlagen. Vorhandene Belege benennen, keine rückwirkenden Aufzeichnungen als zeitnah entstandene Dokumente darstellen.
- *Interner Hinweis:* M + Anlagenreferenz. Ziel: `Raeume.belegart`, `.r05_nachweis_ref` (LookupMulti).

**R06.** Wer bezahlt die Räume und laufenden Nebenkosten?

- *Mandantensicht:* Miete, Nebenkosten, Reinigung, Energie und sonstige Raumkosten; Zeitraum und Währung; direkt bezahlt / weiterbelastet / unentgeltlich bereitgestellt / nicht bekannt. Tatsächliche Erstattung und deren Grundlage angeben.
- *Interner Hinweis:* Gesellschaft + Z + E. Ziel: `Kosten` (`kostenart=KOSTENART_RAUMKOSTEN`, `raum_ref`, `betrag`, `waehrung`, `zeitraum_von/bis`).

## 9. Arbeitsmittel, Fahrzeuge, IT und Software (Formular 6 — Arbeitsmittelblatt)

Für jeden wesentlichen Gegenstand beziehungsweise gleichartig genutzten Bestand und jede Software einzeln ausfüllen. Persönlich zugeordnete Geräte und Fahrzeuge getrennt erfassen.

**A01.** Welches Arbeitsmittel wird genutzt?

- *Mandantensicht (+ Bezeichnung):* Fahrzeug / Schreibtisch, Stuhl oder sonstige Büroausstattung / Computer oder Notebook / Monitor oder Zubehör / Smartphone oder Tablet / Telefon- oder Internetanschluss / Drucker oder Scanner / Server oder Cloudspeicher / Software oder Datenbankzugang / anderes.
- *Interner Hinweis:* E + Bezeichnung. Ziel: `Arbeitsmittel.art_code`, `.bezeichnung`.

**A02.** Wem gehört das Arbeitsmittel und wer stellt es bereit?

- *Mandantensicht (je Person/Gesellschaft + Auswahl):* Eigentümer und Bereitsteller getrennt; gekauft / gemietet / geleast / privat bereitgestellt / nicht bekannt. Standort und Anschaffungs- beziehungsweise Nutzungsbeginn angeben.
- *Interner Hinweis:* je Person/Gesellschaft + E. Ziel: `Arbeitsmittel.eigentuemer_gesellschaft_ref`, `.eigentuemer_person_ref`, `.bereitsteller_ref`, `.bereitstellungsart`, `.ort_ref`, `.beginn`.

**A03.** Wer nutzt es tatsächlich für welche Aufgaben und Gesellschaften?

- *Mandantensicht (je Nutzer):* Nutzer einzeln angeben. Nutzungsanteile auf KG selbst, einzelne Beteiligungen, Schweizer Mutter, andere berufliche Zwecke und Privatnutzung verteilen. Gesamt je Arbeitsmittel = 100 % seiner tatsächlichen Nutzung. Grundlage nennen: Aufzeichnung / begründete Schätzung / andere Grundlage. Nichtnutzung gesondert erfassen.
- *Interner Hinweis:* Person + Tätigkeit + Gesellschaft + Z. Ziel: `Ressourcennutzungen` (`bezug_typ=MITTEL`, `anteil_prozent`, `basis_code`, `privat`).

**A04.** Wie häufig und wo wird es eingesetzt?

- *Mandantensicht:* Täglich / mehrmals pro Woche / wöchentlich / monatlich / nur bei Bedarf / derzeit nicht genutzt. KG-Räume / Beteiligungsräume / Homeoffice / Schweiz / mobil / anderer Ort.
- *Interner Hinweis:* E + Orte. Ziel: `Ressourcennutzungen.haeufigkeit`, `.ort_kategorie`.

**A05.** Bei Fahrzeugen: Für welche konkreten Fahrten wird das Fahrzeug genutzt?

- *Mandantensicht (Mehrfachauswahl + Zahl/Text):* Fahrt zu Kunden oder Lieferanten / Besuch einer Beteiligung / Bank- oder Beratertermin / Fahrt zur KG / andere betriebliche Fahrt / privat. Fahrer, Fahrtzweck, betroffene Gesellschaft, ungefähre Kilometer im Zeitraum und vorhandenes Fahrtenbuch oder andere Aufzeichnung nennen. Fahrzeughalter und Leasingnehmer gesondert angeben.
- *Interner Hinweis:* M + Z/T. Ziel: `Arbeitsmittel.fahrzeughalter_ref`, `.leasingnehmer_ref`, `.fahrtenbuch_status` (nicht Boolean — unterscheidet «nicht vorhanden» von «nicht bekannt»), `.fahrtenbuch_text`.

**A06.** Bei Smartphones und IT: Auf wen laufen Vertrag, Konto und Administration?

- *Mandantensicht (je Person/Gesellschaft):* Mobilfunkvertrag; E-Mail-Domain; Benutzerkonto; Geräteverwaltung; technischer Support; Speicherzugriff. Keine Passwörter oder Zugangsdaten angeben.
- *Interner Hinweis:* je Person/Gesellschaft. Ziel: `Arbeitsmittel.mobilfunkvertrag_ref`, `.email_domain_ref`, `.konto_ref`, `.geraeteverwaltung_ref`, `.support_ref`, `.speicherzugriff_ref`.

**A07.** Bei Software und Datenbanken: Wer ist Lizenz- beziehungsweise Abonnementnehmer?

- *Mandantensicht:* Produkt; Lizenznehmer; tatsächliche Nutzer; Anzahl verfügbarer und tatsächlich genutzter Lizenzen; Gesellschaften, für deren Aufgaben die Software genutzt wird; Nutzungsorte; bekannte Nutzungsbeschränkungen. Lizenz- oder Abonnementnachweis beifügen; rechtliche Zulässigkeit wird intern geprüft.
- *Interner Hinweis:* Gesellschaft + T/Z. Ziel: `Arbeitsmittel.lizenznehmer_ref`, `.anzahl_lizenzen_verfuegbar`, `.anzahl_lizenzen_genutzt`, `.a07_nachweis_ref`, `.beschraenkungen_text`.

**A08.** Wer trägt Anschaffungs- und laufende Kosten?

- *Mandantensicht:* Kaufpreis oder Leasingrate, Abschreibung laut Buchhaltung soweit verfügbar, Betrieb, Wartung, Versicherung, Telefon, Software und Support getrennt erfassen. Direkt bezahlt / erstattet / anteilig weiterbelastet / keine Abrechnung / nicht bekannt. Vertrag, Rechnung, Anlagenverzeichnis oder Umlagebeleg angeben. Kaufpreis und Abschreibung nicht als zwei laufende Kosten addieren.
- *Interner Hinweis:* Gesellschaft + Beträge/Zeitraum/Währung. Ziel: `Kosten` (`mittel_ref`, `betrag`, `waehrung`, `zeitraum_von/bis`, `zahlende_gesellschaft_ref`, `quelle_text`).

## 10. Personal-, Sach- und Gemeinkosten (Formular 7 — Kosten- und Belegblatt, Abschnitt C)

**C01.** Welche Gesellschaft bezahlt Vergütung und Nebenkosten jeder erfassten Person?

- *Mandantensicht:* Festvergütung / variable Vergütung / Arbeitgeberbeiträge / Spesen / sonstige Vergütung. Betrag, Währung, Zeitraum; bei Pauschalen deren Grundlage. Vertrauliche Vergütungsunterlagen können direkt an die Kanzlei übermittelt werden.
- *Interner Hinweis:* Person/Gesellschaft + Z. Ziel: `Kosten` (`kostenart`∈PERSONAL_*, `person_ref`, `betrag`, `waehrung`, `zeitraum_von/bis`, `zahlende_gesellschaft_ref`, `kostenbasis_text`, `vertraulich_hinweis`). **Betrag/Währung sind jetzt strukturiert vorgegeben — frühere offene Frage damit erledigt.**

**C02.** Welche Kosten werden für den Personaleinsatz an die KG oder von der KG weiterberechnet?

- *Mandantensicht (Mehrfachauswahl + Beträge):* Keine / feste Pauschale / nach Stunden / nach Zeitanteilen / nach anderem Schlüssel / nicht bekannt. Zahlende und empfangende Gesellschaft, Leistungszeitraum, Kostenbasis, gegebenenfalls gesonderter Zuschlag, Rechnung und tatsächliche Zahlung nennen.
- *Interner Hinweis:* M + Beträge. Ziel: `Kostenverteilungen.schluessel`, `.empfaenger_gesellschaft_ref`, `.anteil_prozent`, `.betrag`, `.weiterberechnet` (Choice Ja/Nein/unbekannt, **bewusst nicht Boolean**).

**C03.** Welche weiteren Kosten entstehen im Zusammenhang mit den Aufgaben der KG?

- *Mandantensicht (Mehrfachauswahl):* Raumkosten / Fahrzeuge / IT und Telefon / Software / Reisen / externe Beratung / Buchführung / Versicherungen / allgemeine Verwaltung / sonstige Kosten. Je Kostenart Betrag, Währung, Zeitraum, zuerst zahlende Gesellschaft und tatsächliche Erstattung erfassen.
- *Interner Hinweis:* M. Ziel: `Kosten.kostenart`, `.kostenart_andere_text`, `.betrag`, `.waehrung`, `.zeitraum_von/bis`, `.zahlende_gesellschaft_ref`.

**C04.** Lassen sich die Kosten direkt einer Tätigkeit oder Gesellschaft zuordnen?

- *Mandantensicht:* Vollständig / teilweise / nein / nicht bekannt. Direkte Zuordnung angeben. Für gemeinsame Kosten verwendeten Schlüssel auswählen: Zeit / Nutzung / Fläche / Anzahl Nutzer / anderer Schlüssel / kein Schlüssel; Grundlage und berechneten Anteil ergänzen.
- *Interner Hinweis:* E. Ziel: `Kosten.taetigkeit_ref`, `.zuordnung`, `.schluessel`, `.schluessel_begruendung`, `.berechneter_anteil`, `.quelle_text`.

**C05.** Welche Leistungen rechnet die KG tatsächlich ab?

- *Mandantensicht (Gesellschaft + Auswahl/Zahl):* Managementleistungen / Personalbereitstellung / Sachmittelbereitstellung / Kostenerstattung / andere Leistung / keine Abrechnung. Empfänger, Zeitraum, Betrag und Währung; Rechnung, Leistungsaufschrieb und Zahlungsnachweis. Vertraglich vorgesehene und tatsächlich erfolgte Abrechnung unterscheiden.
- *Interner Hinweis:* Gesellschaft + E/Z. Ziel: `Abrechnungen.leistender_ref`, `.empfaenger_ref`, `.leistungsart`, `.betrag`, `.waehrung`, `.zeitraum_von/bis`, `.rechnungsdatum`, `.zahlungsstatus`.

**C06.** Stimmen Angaben, Buchhaltung und Abrechnung überein?

- *Mandantensicht:* Ja / teilweise / nein / noch nicht abgestimmt. Differenzen, unentgeltliche Bereitstellungen und noch offene Erstattungen benennen. Keine steuerliche Würdigung erforderlich.
- *Interner Hinweis:* E + T. Ziel: `Erfassungen.reconciliation_status`, `.reconciliation_notes`, `.reconciliation_related_costs_text`.

## 11. Beispiele und Nachweise (Formular 7, Abschnitt N)

**N01.** Welche tatsächlich ausgeübten Managementtätigkeiten lassen sich konkret zeigen?

- *Mandantensicht (Mehrfachauswahl):* Kundengeschäft / Lieferantengeschäft / Personalentscheidung / Finanzierung / betriebliche Steuerung / Budget oder Investition / andere Tätigkeit. Je tatsächlich ausgeübtem wesentlichem Bereich einen aussagekräftigen Fall erfassen; bereits bei P17, E08, V09 oder K05 genannte Fälle referenzieren, nicht nochmals eingeben. Keine Beispiele erfinden, wenn im Zeitraum kein Fall angefallen ist.
- *Interner Hinweis:* M. Ziel: `Entscheidungsfaelle.n01_bereich`. **Keine feste Obergrenze mehr (früher «3 bis 5 Geschäftsvorgänge») — je wesentlichem Bereich ein Fall, Obergrenze damit erledigt.**

**N02.** Welche Unterlagen belegen die einzelnen Angaben?

- *Mandantensicht (Mehrfachauswahl je Fall):* Vertrag / Vollmacht / E-Mail-Verlauf / Kalender oder Gesprächsnotiz / Bericht oder Planung / Beschluss oder Freigabe / Arbeitsprodukt / Zeiterfassung / Rechnung oder Buchung / Zahlung / Raum- oder Gerätenachweis / sonstige Unterlage / kein Beleg vorhanden / wird nachgereicht.
- *Interner Hinweis:* M je Fall. Ziel: `Substanznachweise.dokumentart`, `Belegverknuepfungen.nachweis_ref`.

**N03.** Welche Angaben belegt die jeweilige Unterlage?

- *Mandantensicht:* Frage-ID, Person, Tätigkeit oder Fall; Dokumenttitel; Dokumentdatum; betroffene Gesellschaft; gegebenenfalls Seite oder Abschnitt. Belegstatus: liegt bei / bereits übermittelt / nur benannt / wird nachgereicht / nicht vorhanden.
- *Interner Hinweis:* Referenzen + D/T. Ziel: `Belegverknuepfungen.ziel_typ`, `.ziel_id`, `.frage_id`, `.belegter_sachverhalt`, `.seite_abschnitt`, `.belegstatus`; `Substanznachweise.dokumentdatum`, `.gesellschaft_ref`.

**N04.** Welche Angaben sind geschätzt, unvollständig oder noch zu klären?

- *Mandantensicht:* Betroffene Frage oder Datensatz-ID; Schätzungsgrundlage; fehlende Information; zuständige Ansprechperson; gegebenenfalls erwarteter Nachreichtermin.
- *Interner Hinweis:* Referenzen + T. Ziel: `Belegverknuepfungen.schaetzungsgrundlage_text`, `.fehlende_information_text`, `.ansprechperson_ref`, `.erwarteter_nachreichtermin`.

**N05.** Wer hat die Angaben zusammengestellt und für welchen Zeitraum?

- *Mandantensicht:* Ausfüllende Person; fachlich auskunftsfähige Ansprechperson; Beginn und Ende des Bezugszeitraums; Datum der Bearbeitung. Bestätigung: «Die Angaben beschreiben die tatsächlichen Verhältnisse nach unserem derzeitigen Kenntnisstand. Schätzungen und geplante Tätigkeiten sind gekennzeichnet.»
- *Interner Hinweis:* Name/Funktion + D. Ziel: `Erfassungen.compiler_name`, `.knowledgeable_contact`, `.processing_date`, `.confirmation_given`.
