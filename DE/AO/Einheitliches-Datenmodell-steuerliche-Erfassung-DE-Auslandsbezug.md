# Einheitliches Datenmodell: steuerliche Erfassung Deutschland und Auslandsbezug

**Stand:** 31.08.2026

**Quellen:** ELSTER-Fragebögen für Einzelunternehmen, Kapitalgesellschaft/Genossenschaft, Personengesellschaft/-gemeinschaft, Körperschaft nach ausländischem Recht sowie BZSt2 nach § 138 Abs. 2 AO. Ergänzend ausgewertet (separat geführt): Antrag erneute W-IdNr.-Mitteilung; ASt-Mitteilung nach § 6 AStG.

**Rollen der Dokumente in `DE/AO/`:**

| Dokument | Rolle |
|---|---|
| dieses Datenmodell | Zielbild, Pflichtlogik, normalisierte Objekte, Forms-/Übergabe-Architektur |
| [`formulardaten-roherfassung.md`](formulardaten-roherfassung.md) | vollständiger Feld-/Kz-Katalog je Fragebogen inkl. BZSt2 |
| [`formulardaten-widnr-erneute-mitteilung.md`](formulardaten-widnr-erneute-mitteilung.md) | separates FMS-Formular; Overlap nur Identifikation |
| [`../AStG/formulardaten-mitteilung-6-astg.md`](../AStG/formulardaten-mitteilung-6-astg.md) | separates AStG-/InvStG-Modul (kein §-138-AO-Ersatz) |

Feldgenaue Kz der Erfassungsfragebögen und BZSt2 stehen in der Rohfassung. Hier stehen Pflichtstatus, Objektstruktur und Architektur.

## 1. Ziel und Abgrenzung

Das Datenmodell dient der einheitlichen Erhebung für zwei Richtungen:

- **Inbound:** steuerliche Erfassung eines Unternehmens oder einer ausländischen Körperschaft mit deutscher Tätigkeit.
- **Outbound:** Mitteilung von Betrieben, Betriebsstätten, Beteiligungen oder Beherrschungsmöglichkeiten im Ausland nach § 138 Abs. 2 AO (BZSt2).

**Kz** bezeichnet die im jeweiligen Formular ausgewiesene Zeile. Fehlt im BZSt2-Auszug eine Zeilennummer, ist dies ausdrücklich als *keine Kz ausgewiesen* vermerkt. Die Kz ist immer formularspezifisch, keine globale technische Feld-ID.

## 2. Pflichtlogik aus den ELSTER-Fehlerlisten

### 2.1 Einzelunternehmen

| Datenfeld | Kz | Pflichtstatus |
|---|---|---|
| Bestehende Steuernummer oder Antrag auf neue Steuernummer | keine Kz ausgewiesen | unbedingt |
| Name, Vorname, Geburtsdatum, Religion | 2, 3, 5 | unbedingt |
| Genaue Tätigkeit | 21 | unbedingt |
| Unternehmensanschrift oder Kennzeichnung Wohnanschrift | 56–59 | unbedingt |
| Tätigkeitsbeginn | 69 | unbedingt |
| Gründungsart, Gründungsdatum | 85 | unbedingt |
| Mindestens eine relevante Einkunftsart, Eröffnungs- und Folgejahr | 105–107, 110 | unbedingt |
| Gewinnermittlungsart | 114 | unbedingt |
| Geschätzter Umsatz, Eröffnungs- und Folgejahr | 130 | unbedingt |

### 2.2 Kapitalgesellschaft oder Genossenschaft

| Datenfeld | Kz | Pflichtstatus |
|---|---|---|
| Bestehende Steuernummer oder Antrag auf neue Steuernummer | keine Kz ausgewiesen | unbedingt |
| Registerfirma | 2 | unbedingt |
| Genaue Tätigkeit | 13 | unbedingt |
| Datum der notariellen Errichtung oder des Musterprotokolls | 54 | unbedingt |
| Rechtsform | 63 | unbedingt |
| Tätigkeitsbeginn | 64 | unbedingt |
| Grund-/Stammkapital | 66 | unbedingt |
| Mindestens ein Anteilseigner | 69 oder 72 | unbedingt |
| Treuhandverhältnis: ja/nein | 90 | unbedingt |
| Bar- oder Sachgründung | 91 | unbedingt |
| Voraussichtlicher Gewinn im Gründungsjahr | 165 | unbedingt |
| Mindestens ein gesetzlicher Vertreter | 25 | unbedingt |
| Geschätzter Umsatz, Eröffnungs- und Folgejahr | 179 | unbedingt (bestätigt: ELSTER-Portalprüfung 26.10.2026, verification_date 2026-10-26 — leeres Formular fsekapg-202401 zeigt Eröffnungs- **und** Folgejahr als eigene unbedingte Pflichtfehler) |

### 2.3 Personengesellschaft oder Personengemeinschaft

| Datenfeld | Kz | Pflichtstatus |
|---|---|---|
| Bestehende Steuernummer oder Antrag auf neue Steuernummer | keine Kz ausgewiesen | unbedingt |
| Name der Gesellschaft/Gemeinschaft | 2 | unbedingt |
| Genaue Tätigkeit | 12 | unbedingt |
| Gründungsart, Gründungsdatum | 23 | unbedingt |
| Rechtsform | 31 | unbedingt |
| Rechtsfähigkeit: ja/nein | 33 | unbedingt |
| Tätigkeitsbeginn | 34 | unbedingt |
| Gesellschaftsgewinn, Eröffnungs- und Folgejahr | 77 | unbedingt |
| Gewinnermittlungsart | 78 | unbedingt |
| Aufteilungsschlüssel | 80 | unbedingt |
| Geschätzter Umsatz, Eröffnungs- und Folgejahr | 129 | unbedingt |
| Mindestens zwei Beteiligte | Beteiligtenblock 82–99 | unbedingt |

### 2.4 Körperschaft nach ausländischem Recht

Die unbedingten Pflichtfelder sind vollständig bestätigt: ELSTER-Portalprüfung 26.10.2026, verification_date 2026-10-26 (leeres Formular fsekapgaus-202401, „Neue Steuernummer beantragen“, nichts abgesendet) zeigt genau 5 unbedingte Pflichtfehler — identisch mit den 5 Zeilen der Tabelle unten. Offen bleiben ausschliesslich *bedingte* Pflichtfelder, die im leeren Formular noch nicht sichtbar sind und erst nach Auswahl bestimmter Antworten erscheinen; diese sind durch einen weiteren Prüflauf mit Testdaten zu ermitteln.

| Datenfeld | Kz | Pflichtstatus |
|---|---|---|
| Bestehende Steuernummer oder Antrag auf neue Steuernummer | keine Kz ausgewiesen | unbedingt |
| Registerfirma | 2 | unbedingt |
| Genaue Tätigkeit in Deutschland | 12 | unbedingt |
| Zustimmung zur Zuständigkeitsvereinbarung nach § 27 AO | 18 | unbedingt |
| Bereits bei anderem deutschen Finanzamt erfasst: ja/nein | 19 | unbedingt |

### 2.5 BZSt2: Mitteilung nach § 138 Abs. 2 AO

| Datenfeld | Kz | Pflichtstatus |
|---|---|---|
| Mitteilungsjahr | keine Kz ausgewiesen | unbedingt |
| Genau eine Steuer- oder Identifikationsnummer | keine Kz ausgewiesen | unbedingt |
| Person oder Firma | keine Kz ausgewiesen | unbedingt |
| Nachname bzw. Firmenname | keine Kz ausgewiesen | unbedingt |
| Adressart | keine Kz ausgewiesen | unbedingt |
| Ort oder Postfach der Adresse | 15–17 | unbedingt |
| Mitteilungssachverhalt bzw. Negativmeldung | keine Kz ausgewiesen | unbedingt |

## 3. Einheitlicher allgemeiner Kern

Dieser Kern wird sowohl für Inbound-Fragebögen als auch für BZSt2 einmalig erhoben und in nachfolgenden Fragebögen vorbefüllt. Die formularspezifischen Feld-/Kz-Zeilen stehen in der [Rohfassung](formulardaten-roherfassung.md).

| Objekt | Datenfeld | Inbound (Rohfassung) | BZSt2 (Rohfassung) |
|---|---|---|---|
| Fall | Akten-/Fall-ID, Bearbeitungsnotiz, Erfassungsjahr | Startseite je Fragebogen | Startseite / Mitteilungsjahr |
| Steuerliche Identifikation | Art der Nummer, Steuernummer, IdNr., Wirtschafts-IdNr., zuständiges Finanzamt | Startseite; Identifikationsfelder | Startseite / Identifikation |
| Meldepflichtiger | Person oder Firma | Allgemeine Angaben | Allgemeine Angaben |
| Name | Nachname/Firma; bei Person Vorname, Titel, Geburtsdatum | Allgemeine Angaben | Allgemeine Angaben |
| Rechtsform | deutsche/ausländische Rechtsform, sonstige Rechtsform | KapG / PersG / Ausland | Allgemeine Angaben |
| Adresse | Adressart, Strasse, Nummer, Zusatz, PLZ, Ort, Staat, Postfach | wiederkehrende Adressblöcke | Adresse (u. a. 15–17) |
| Kontakt | Telefon, Web-Adresse | wiederkehrende Kontaktblöcke | nicht abgefragt |
| Tätigkeit | genaue Tätigkeit; vermögensverwaltend ja/nein | Tätigkeitsfelder je Fragebogen | Sachverhalt in Mitteilungsmodul |
| Ort der Leitung | Abweichender Ort der Geschäftsleitung | jeweiliger Leitungsblock | Adressart «Ort der Geschäftsleitung» |
| Steuerberatung | natürliche/juristische Person, Adresse, Telefon; Vollmacht | Steuerberatung / Empfang | Mitwirkung |
| Bank | IBAN, BIC, Kontoinhaber, abweichender Kontoinhaber | Bankverbindung je Fragebogen | nicht abgefragt |
| Anlagen | Dokumenttyp, Bezeichnung, Datei, Erforderlichkeit | Beilagen / Unterlagen | Anhänge |

## 4. Wiederholbare Datenobjekte

Diese Objekte dürfen nicht in Freitextfeldern gesammelt werden. Jeder Datensatz erhält eine technische Objekt-ID und eine fortlaufende Nummer. Feldlisten und Kz: [Rohfassung](formulardaten-roherfassung.md).

| Objekt | Kernfelder | Rohfassung (Beispiele) |
|---|---|---|
| Adresse | Typ, Inland/Ausland, Strasse, Hausnummer, Zusatz, PLZ, Ort, Staat, Postfach | Adressblöcke in allen Fragebögen |
| Person | Anrede, Titel, Name, Vorname, Namenszusatz, Geburtsdatum, IdNr., Beruf | gesetzliche Vertreter, Vertretung, BZSt2-Person |
| Juristische Person | Firma, Rechtsform, Sitz, Register, Registernummer, Steuerkennzeichen | Anteilseigner / Beteiligte |
| Betriebsstätte/Einrichtung | Bezeichnung, Adresse, Land, Art, feste/nicht feste Einrichtung, Eigentum, Nutzung | Betriebstätten-/Einrichtungsblöcke |
| Beteiligung | Beteiligter/Anteilseigner, direkte/mittelbare Beteiligung, Rolle, Kapitalanteil, Prozentquote, Zähler/Nenner, Treuhand | Anteilseigner / Beteiligte / BZSt2-Beteiligungsstruktur |
| Vertretung | Person/Organisation, Rolle, Vertretungsbefugnis, Abschlussvollmacht | gesetzliche / ständige Vertreter, Empfang |
| Steuerprognose | Steuerart, Jahr, Betrag, Beteiligter, Sonderbetriebsbezug | Vorauszahlungen / Gewinnanteile |
| Umsatzsteuerprofil | Umsatz, Steuerverfahren, Umsatzart, Steuersatz, USt-IdNr., OSS, Onlinehandel | USt-/OSS-/Onlinehandelsblöcke |
| Dokument | Dokumenttyp, Bezug zu Objekt, vorhanden/hochgeladen, Dateiname, Hinweis | Beilagen / Anhänge |

## 5. Rechtsformspezifische Module → Rohfassung

Die früheren Modul-/Kz-Tabellen sind in die Rohfassung überführt. Hier nur die Zuordnung:

| Modulfamilie | Rohfassung |
|---|---|
| Einzelunternehmen | [`formulardaten-roherfassung.md`](formulardaten-roherfassung.md) → Abschnitt 1 |
| Kapitalgesellschaft / Genossenschaft | [`formulardaten-roherfassung.md`](formulardaten-roherfassung.md) → Abschnitt 2 |
| Personengesellschaft / -gemeinschaft | [`formulardaten-roherfassung.md`](formulardaten-roherfassung.md) → Abschnitt 3 |
| Körperschaft nach ausländischem Recht | [`formulardaten-roherfassung.md`](formulardaten-roherfassung.md) → Abschnitt 4 |
| BZSt2 (§ 138 Abs. 2 AO) | [`formulardaten-roherfassung.md`](formulardaten-roherfassung.md) → Abschnitt 5 |

Die leere BZSt2-XML-Instanz in der Rohfassung bestätigt die wiederholbaren Datensätze `gesellschaft`, `beteiligte` und `drittstaatgesellschaft`, ohne zusätzliche fachliche Feldzuordnung.

## 6. Empfohlene Forms-Architektur

Ein einzelnes MS Forms-Formular kann Verzweigungen, aber keine belastbaren, dynamisch wiederholbaren Tabellenobjekte abbilden. Daher empfiehlt sich eine Fallnummer als gemeinsamer Schlüssel und folgende Formfamilie:

| Form | Zweck | Auslöser |
|---|---|---|
| 0. Fallsteuerung | Inbound/Outbound, Rechtsform, bestehende Erfassung, Zielmeldung, Fallnummer | immer |
| 1. Allgemeiner Stammblock | Meldepflichtiger, Adresse, Kontakt, Identifikation, Steuerberatung | immer |
| 2. Unternehmens-/Gründungsmodul | Rechtsform-, Register-, Kapital- und Gründungsdaten | Inbound |
| 3. Personen und Vertretung | Gesetzliche Vertreter, ständige Vertreter, Empfangsbevollmächtigte | wenn vorhanden bzw. Pflicht |
| 4. Beteiligte und Quoten | Anteilseigner/Beteiligte, Rollen, direkte/mittelbare Quoten, Treuhand | KapG, PersG, Ausland, BZSt2 |
| 5. Betriebsstätten und Inlands-/Auslandsbezug | In- und ausländische Einrichtungen, Nutzung, Tätigkeitsdauer | wenn vorhanden |
| 6. Steuer- und Umsatzsteuerprofil | Gewinn- und Umsatzschätzungen, Lohnsteuer, USt, USt-IdNr., OSS | Inbound |
| 7. Auslandsmitteilung | § 138 AO-Sachverhalt, Auslandsbetrieb, Auslandsgesellschaft, Drittstaatbeherrschung | Outbound |
| 8. Unterlagen | Abfrage und Upload-Nachweise | immer, bedingt |

### Technische Mindestfelder in jeder Antwort

- `case_id`
- `entity_id` oder `person_id`
- `object_type`
- `object_sequence`
- `source_form_type` (EU, KapG, PersG, Auslandskörperschaft, BZSt2)
- `elster_kz` bzw. `bzst_kz`
- `value`
- `conditional_trigger`
- `validation_status`

Umsetzung: SharePoint-Liste `Technische_Mindestfelder` in [`sharepoint-forms/New-SteuerlicheErfassungListen.ps1`](sharepoint-forms/New-SteuerlicheErfassungListen.ps1); seit der Abschnitt-9-Erweiterung zusätzlich um die Spalten des Feldkatalogs 9.5 ergänzt (`object_id`, `field_key`, `field_label`, `data_type`, `required_status`, `source`, `verification_date`). `condition` aus 9.5 wird dort durch das bereits vorhandene `conditional_trigger` abgebildet, nicht dupliziert.

## 7. Übergabeprinzip für ELSTER und BZSt

1. Forms/Listen speichern fachlich normalisierte Daten, nicht bloss ELSTER-Feldnamen.
2. Eine zentrale Mappingtabelle ordnet jedem normierten Feld je Formulartyp die Kz (aus der Rohfassung), den technischen Zielpfad, Datentyp, Wiederholungsregel und Auslösebedingung zu.
3. Vor Übergabe validiert eine Regelmatrix die Pflichtfelder (Abschnitt 2) und sachverhaltsabhängigen Folgefelder.
4. Die Übertragung erzeugt eine formularspezifische ELSTER- oder BZSt-Datensatzstruktur. Der BZSt2-XML-Entwurf in der Rohfassung zeigt bereits die wiederholbaren Bereiche für Gesellschaften, Beteiligte und Drittstaat-Gesellschaften.
5. Anhänge werden als eigenständige Dokumentobjekte mit Bezug zum auslösenden Sachverhalt geführt.

## 8. Offene Validierungspunkte

- Vollständige Fehlerliste der Körperschaft nach ausländischem Recht abrufen und Pflichtmatrix ergänzen.
- Je Formulartyp die technischen XML-/ERiC-Feldbezeichner gegen einen exportierten Musterfall prüfen. Die sichtbare Kz ersetzt keinen technischen Feldpfad.
- Bedingungen für Folgefelder als Entscheidungsregeln dokumentieren, insbesondere Gründungsform, Treuhand, Organschaft, Umsatzsteuer, Bauleistungen, Onlinehandel und Auslandsbezug.
- Höchstzahl und Bearbeitung wiederholbarer Objekte festlegen. Bei mehr als zehn Betriebsstätten verweisen die ELSTER-Formulare auf einen PDF-Anhang.


---

## 9. Ergänzte Mandanten-Erhebungsmatrix (20.10.2026): Rechtsformen und Auslandssachverhalte

**Ziel:** Vollständige fachliche Intake-Checkliste für steuerliche Erfassungen/Anzeigen. Die Datenerhebung erfolgt unabhängig von einer produktiven ELSTER-Schnittstelle. Frühere Tabellen in den Abschnitten 2–8 und der [formulardaten-roherfassung.md](formulardaten-roherfassung.md) bleiben gültige Quellbasis. **Status:** \`B\` belegtes unbedingtes Feld laut ausgewerteter ELSTER-Fehlerliste, \`F\` als Formularfrage im Rohkatalog belegt und fallabhängig relevant, \`E\` ergänzende Kanzlei-Frage ohne nachgewiesene amtliche Formular-Pflicht, \`I\` interner Prozesswert, \`X\` bewusst ausgeschlossen (Kanzleientscheid, praktisch ohne Relevanz, keine Pflichtfeldermittlung und keine Umsetzung in Formularen/Listen vorgesehen), \`M\` definierter manueller Prüfschritt durch die Kanzlei ohne Automatisierung in Formularen/Listen. Ein E-Feld ist **nicht** als gesetzliches Pflichtfeld auszugeben.

### 9.1 Fallentscheidung und Rechtsformmatrix

| Fall | Formularkanal/Erhebungsweg | Zusatzfragen | Status |
|---|---|---|---|
| Einzelunternehmen / Freiberufler / e.K. / Land- und Forstwirtschaft | Fragebogen Einzelunternehmen | persönliche Daten, Tätigkeit, Gründungs-/Beginn, Steuerprognosen | B/F |
| GmbH, UG (haftungsbeschränkt), AG, SE, KGaA, eG | Fragebogen Kapitalgesellschaft/Genossenschaft | Satzung, Register, Kapital, Gesellschafter, Vertretung, ggf. Organschaft | B/F/E |
| GbR/eGbR, OHG, KG, GmbH & Co. KG, PartG/PartG mbB, Gemeinschaften | Fragebogen Personengesellschaft/-gemeinschaft, nach Sachverhaltsqualifikation | Mitunternehmer, Quoten, Gewinnverteilung, Rechtsfähigkeit, Sonderbetrieb | B/F/E |
| Erbengemeinschaft, stille Gesellschaft, vermögensverwaltende Gemeinschaft | zuerst Steuer- und Verfahrensstatus klären | Mitunternehmerschaft oder Überschusseinkünfte, gesonderte Feststellung, Beteiligte | E |
| Verein (e.V./n.e.V.), Stiftung, gemeinnützige/mildtätige/kirchliche Körperschaften, sonstige Körperschaft privaten Rechts | **Kanzleientscheid 26.10.2026: bewusst ausgeschlossen** — praktisch ohne Relevanz für die Kanzleipraxis, kein Fragebogen-/Formularkanal vorgesehen | — | X |
| Ausländische Kapitalgesellschaft (AG, Ltd., Inc., BV, Sàrl etc.) | Fragebogen Körperschaft ausländischen Rechts, wenn zutreffend | Heimatstaat und Register, Ort tatsächlicher Leitung, DE-Tätigkeit, ständige Vertreter, inländische Einrichtung, Steuerarten | B/F/E; unbedingte Pflichtliste vollständig bestätigt (ELSTER-Portalprüfung 26.10.2026, siehe 2.4/9.3), bedingte Pflichtfelder noch offen |
| Ausländische Partnership, LLP, LLC oder hybride Rechtsform | **Kanzleientscheid 26.10.2026:** zunächst manueller Rechtstypenvergleich und steuerliche Einordnung durch die Kanzlei (kein Formular-/Listen-Automatismus); danach ggf. Fragebogen Körperschaft ausländischen Rechts oder Personengesellschaft je nach Ergebnis | Gesellschafter, ausländische Steuertransparenz, deutsche Tätigkeiten, Betriebsstätten, Steuerpflicht | M |
| Deutsche Gesellschaft mit **ausländischer Betriebsstätte** oder Auslandsbeteiligung | inländischer Rechtsform-Fragebogen und eigenständiges Auslandsmodul | Standort, Aufgaben, Personal, Vertretung, Dauer, ausländische Register-/Steuerdaten, ggf. eigenständige §-138-AO-Meldung | F/E |
| Ausländische Gesellschaft mit deutscher Zweigniederlassung/Bau-/Montage-/Vertreter-/Geschäftsleitungsstätte | Auslandsrechtsform-Fragebogen bzw. steuerartspezifische Registrierung nach Prüfung | Standort und Nutzung, Tätigkeiten, Projektzeitraum, Abschlussvollmacht, Ort der Geschäftsleitung, inländische Umsätze/Löhne | F/E |
| Ausländischer Rechtsträger ohne inländische Betriebsstätte, aber mit inländischen Umsätzen/Einkünften | zuerst Registrierungsanlass und Steuerarten bestimmen | USt-Registrierung, inländische Einkünfte, Steuerschuldnerschaft, frühere Steuernummer | E |
| Juristische Person öffentlichen Rechts / Betrieb gewerblicher Art | **Kanzleientscheid 26.10.2026: bewusst ausgeschlossen** — praktisch ohne Relevanz für die Kanzleipraxis, keine eigene Erfassungsroute vorgesehen | — | X |

### 9.2 Gemeinsamer Stammblock

| Feldgruppe | Vom Mandanten zu erheben | Quelle/Status |
|---|---|---|
| Fallführung | Fallnummer, Anlass (Neugründung/Übernahme/Umwandlung/Verlagerung/Neuregistrierung), Richtung DE/ausländische Tätigkeit, Bearbeitungsjahr, Zielsteuerarten, gewünschtes Datum | I/E |
| Rechtsträger | voller Name/Firma, Rechtsform genau, Gründungsstaat, Sitz, Unternehmensgegenstand, Gründungs-/Tätigkeitsbeginn, ggf. Rechtstypenvergleich | B/F/E |
| Identifikation | vorhandene DE-Steuernummer/Finanzamt oder Neuantrag, IdNr. natürlicher Personen, W-IdNr. soweit bekannt, USt-IdNr., ausländische Steuer-IDs, Registergericht/Registernummer | B/F/E |
| Adressen separat | Wohnsitz, Unternehmensanschrift, Satzungssitz, Ort tatsächlicher Geschäftsleitung, Zustelladresse; Inland/Ausland mit Strasse, Nummer, PLZ, Ort, Staat, Gültigkeitsdauer | B/F/E |
| Tätigkeit | genaue Branche/Tätigkeitsbeschreibung, Produktions-/Dienstleistungsorte, Vorbereitungshandlungen, Beginn, wesentliche Kunden-/Lieferstaaten, vermögensverwaltend ja/nein | B/F/E |
| Personen | Einzelunternehmer, gesetzliche Vertreter, Geschäftsführer, Vorstände, vertretungsberechtigte Gesellschafter, Berater, Empfangsbevollmächtigte; Namen, Geburtsdatum und Identifikationsdaten soweit zulässig/abgefragt, Anschriften, Vertretungsmacht | B/F/E |
| Beteiligte | sämtliche Gesellschafter/Genossen/Partner, Identifikation, natürliche/juristische Person, direkte/mittelbare Quote und Stimmrechte, Eintritt/Austritt, Treuhand, wirtschaftlich relevante Sonderverhältnisse | B/F/E |
| Gründung/Historie | Vertrags-/Urkundendatum, Registerstatus und Datum, Bar-/Sachgründung, Kapital, Vorinhaber, Umwandlung, zuvor ausgeübte Tätigkeiten, Konzernbezug, Vorregistrierung | B/F |
| Bank/Kontakt | IBAN, ggf. BIC, Inhaber, SEPA-Wunsch, Telefon, Webadresse, freiwillige Rückfrage-E-Mail | F/E |
| Ertragsteuer/Prognosen | voraussichtlicher Gewinn/Verlust und Einkünfte im Gründungs- und Folgejahr, Gewinnermittlung, Wirtschaftsjahr, abweichendes WJ, Verteilungsschlüssel | B/F |
| Umsatzsteuer | Umsatz je Eröffnungs- und Folgejahr, USt-Schuld/Überschuss, Kleinunternehmerstatus und Verzicht soweit zulässig, Soll-/Ist-Besteuerung, steuerfreie und ermässigte Umsätze, Nullsteuersatz, Durchschnittssatz, Reverse-Charge-Fälle, Organschaft, OSS, USt-IdNr., Handel über Webshops/Plattformen und soziale Medien, Bau-/Reinigungsleistungen | B/F/E |
| Lohnsteuer | Zahl der Beschäftigten (inkl. geringfügig/Familie), erste Entgeltzahlung, Lohnsteuerschätzung, lohnsteuerliche Betriebsstätte, grenzüberschreitende Personaleinsätze | F/E |
| Unterlagen | Satzung/Vertrag, Registerauszug, Gesellschafterliste, Vertretungsnachweise, Übernahme-/Umwandlungsdokumente, Bank-/Vollmachtsbelege, ausländische Dokumente/Übersetzungen soweit fallrelevant | F/E |

### 9.3 Im Quellmodell unbedingt dokumentierte Pflichtblöcke (Kz jeweils formularbezogen)

- **Einzelunternehmen:** Steuernummer oder Neuantrag; Name/Vorname/Geburtsdatum/Religion (2, 3, 5), Tätigkeit (21), Betriebsadresse oder Wohnsitz-Identität (56–59), Beginn (69), Gründungsart und Datum (85), mindestens eine relevante Einkunftsart samt Prognose (105–107, 110), Gewinnermittlung (114), Umsatzschätzung (130).
- **Kapitalgesellschaft/Genossenschaft:** Steuernummer oder Neuantrag; Firma (2), Tätigkeit (13), notarielle Errichtung (54), Rechtsform (63), Tätigkeitsbeginn (64), Grund-/Stammkapital (66), mindestens ein Anteilseigner (69 oder 72), Treuhand ja/nein (90), Bar-/Sachgründung (91), voraussichtlicher Gewinn (165), gesetzlicher Vertreter (25), Umsatzschätzung Eröffnungs- **und** Folgejahr (179, **bestätigt unbedingt**: ELSTER-Portalprüfung 26.10.2026, verification_date 2026-10-26, leeres Formular fsekapg-202401 mit 14 unbedingten Pflichtfehlern insgesamt — „unsicher“ entfällt).
- **Personengesellschaft/-gemeinschaft:** Steuernummer oder Neuantrag; Name (2), Tätigkeit (12), Gründungsart/Datum (23), Rechtsform (31), Rechtsfähigkeit (33), Beginn (34), Gewinn beider Jahre (77), Gewinnermittlung (78), Aufteilungsschlüssel (80), Umsatz (129), mindestens zwei Beteiligte (82–99).
- **Ausländische Körperschaft:** Steuernummer oder Neuantrag; Firma (2), DE-Tätigkeit (12), Zustimmung zur Zuständigkeitsvereinbarung nach § 27 AO (18), Vorregistrierung anderes deutsches FA ja/nein (19). **Bestätigt vollständig** (ELSTER-Portalprüfung 26.10.2026, verification_date 2026-10-26, leeres Formular fsekapgaus-202401: genau diese 5 unbedingten Pflichtfehler, keine weiteren) — „Fehlerliste unvollständig“ entfällt. Offen bleiben nur *bedingte* Pflichtfelder, die erst nach Auswahl bestimmter Antworten im Formular erscheinen.
- **Verein/Stiftung/sonstige Körperschaft privaten Rechts:** **Kanzleientscheid 26.10.2026: bewusst ausgeschlossen** (Status X, siehe 9.1) — praktisch ohne Relevanz für die Kanzleipraxis; keine Pflichtfeldermittlung und kein gesonderter Fragebogen vorgesehen.

### 9.4 Wiederholbares Auslandsmodul

| Erhebungsobjekt | Daten | Zweck/Status |
|---|---|---|
| Standort/Betriebsstätte | Staat, vollständige Anschrift, Art (Büro, Filiale, Werk, Lager, Bau/Montage, Homeoffice, Server usw.), Eröffnung/Schliessung, Nutzungsrecht, Personal, Tätigkeiten | F/E |
| Projekte Bau/Montage | Projektname, Auftraggeber, Verträge, Einsatz-/Unterbrechungs-/Enddaten, Subunternehmer, Dauer | E |
| Geschäftsleitung | tatsächlicher Entscheidort, Geschäftsführer/Entscheider, Zeitraum, Sitzungen, Beschluss-/Vertragsunterlagen | E |
| Vertreter | Person/Firma, Staat, Tätigkeiten, Vertragsverhandlungen/Abschlüsse, Vollmachten, Abhängigkeit, Zeitraum | E |
| Beteiligung Ausland | Gesellschaft, Rechtsform, Land, Register-/Steuer-ID, Erwerbs-/Änderungsdatum, direkte/mittelbare Quoten, Stimmrechte, Beherrschungsmöglichkeiten, Mitinhaber | F/E |
| Steuerstatus | DE- und ausländische Steuernummer, Ansässigkeitsstaat, Register, vorhandene Ansässigkeitsbelege, Steuer- und DBA-Positionen, Umsatzsteuer-Registrierung | E |
| Betriebsstättenprüfung | **separate** sachverhaltsabhängige Einschätzung für § 12 AO, DBA-Art.-5-Betriebsstätte, USt-feste Niederlassung und lohnsteuerliche Betriebsstätte; nicht in einem Bool-Wert vermengen | E; fachliche Prüfung, nicht formularische Pflicht |
| § 138 Abs. 2 AO / BZSt2 | Mitteilungsjahr; meldepflichtige Person/Firma samt Steuer-/IdNr. und Adresse; Ereignis (Auslandsbetrieb/-Betriebsstätte, Personengesellschafts-/Kapitalgesellschaftsbeteiligung, Drittstaat-Beherrschung); Datum, Auslandseinheit, Beteiligte/Quoten; Negativmeldung nur bei tatsächlicher Relevanz | B/F/E; **eigenständiger Prozess**, kein Ersatz für Erfassungsfragebogen |
| Sonstige Anzeigen | weitere in Frage kommende Anzeigepflichten, etwa § 138 Abs. 3 AO oder § 6 AStG, im **gesonderten** Prüf-/Meldeprozess klären | E |

### 9.5 Ablauf im LP_Beratung

1. Interne Fallweiche: Rechtsform, Gründungs-/Ansässigkeitsstaat, Tätigkeit in DE, vorhandene Registrierung, betroffene Steuerarten.
2. Mandantenfragebogen modular: Stammblock immer, danach Rechtsform, Beteiligte, Betriebsstätten, Ertrag-/USt-/Lohnsteuer, Unterlagen. Bedingte Felder nur bei passendem Sachverhalt.
3. Beteiligte, Vertreter, Standorte und Dokumente als eigene **wiederholbare Datensätze**, jeweils Fall-ID, Objekt-ID, Ort, Staat und zeitlichem Bezug.
4. Auslandsmodul für jede ausländische Einrichtung/Einheit, getrennte Prüfung inländischer Anmeldung und möglicher Outbound-Anzeige nach § 138 AO.
5. Plausibilitätsprüfung auf Zeiträume, Rechtsform, Beteiligungsquoten, Kapital, Registerbelege, Identifikationsnummern, Betriebsbeginn, Ertrags- und Umsatzprognosen.
6. Fehlende Daten dokumentieren und gezielt anfordern; Fall für korrekte amtliche Erfassungsmaske vorbereiten.
7. Fachliche Freigabe durch verantwortliche Berufsperson. **Keine produktive XML-/ERiC-Schnittstelle erforderlich oder behauptet.**

**Minimaler Feldkatalog pro Eintrag:** \`case_id | form_type | object_type | object_id | field_key | field_label | value | data_type | required_status | condition | elster_kz | source | verification_date\`. Zulässige Pflichtstatus: \`belegt_unbedingt\`, \`belegt_bedingt\`, \`intake_empfohlen\`, \`amtlich_ungeprüft\`.

### 9.6 Bedingte Pflichtfelder (ELSTER-Portalprüfung 26.10.2026, Update 2)

Ermittelt am 26.10.2026 in ELSTER an je einem leeren Formular (`fsekapgaus-202401` Körperschaft nach ausländischem Recht, 23 Auslöser; `fsekapg-202401` Kapitalgesellschaft/Genossenschaft, 27 Auslöser), jeweils Auswahlfelder umgestellt, „Prüfen“, nichts gesendet, ohne Speichern verlassen. Die Prüfliste zeigt keine Kz, nur Abschnitt/Zeile und Fehlertext — Status durchgehend `belegt_bedingt` (nicht `belegt_unbedingt`: die Pflicht gilt nur bei der jeweils genannten Bedingung). Quelle überall „ELSTER-Portalprüfung 26.10.2026“, verification_date 2026-10-26. Mehrfach in beiden Formularen identisch gefundene Auslöser (z. B. Vertreter-/Beratungs-/Bankangaben, USt-Block) sind hier zusammengefasst, nicht doppelt aufgeführt.

| Auslöser (Bedingung) | Dadurch bedingt erforderlich | SharePoint-Spalte | Liste | Spalte | Quelle |
|---|---|---|---|---|---|
| `par27_ao_agreement` = Ja **und** `registration_status` = Ja (seit 28.10.2026 beide Felder in Liste 0, vorher `already_registered` in Liste 1; siehe Abschnitt 10/Changelog `sharepoint-forms/README.md` Abschnitt H2) | Steuernummer und Land des anderen Finanzamts | `existing_tax_number`, `tax_office_country` | 0 | bestehend | A |
| Betriebsstätten-Eintrag angelegt (In- oder Ausland) | vollständige Adresse | `address` | 5 | bestehend (bereits `-Required`) | A, B |
| `role` = Ständiger Vertreter **und** `dependency_status` = abhängig | Vorname, Name, Geburtsdatum, Inlandsadresse | `last_name_or_company`, `first_name`, `date_of_birth`, `address` | 3 | bestehend | A |
| `role` = Gesetzlicher Vertreter bzw. Empfangsbevollmächtigter, Eintrag angelegt | Vorname, Name, Geburtsdatum, Adresse | `last_name_or_company`, `first_name`, `date_of_birth`, `address` | 3 | bestehend | A, B |
| `advisor_is_authorized_recipient` = Ja | Name/Firma und Adresse der steuerlichen Beratung | `tax_advisor_name`, `tax_advisor_address` | 1 | bestehend | A, B |
| `bank_account_holder` ausgefüllt (abweichender Kontoinhaber) | IBAN, Kontoinhaber; BIC zusätzlich nur bei IBAN aus AL, MD, MC, ME, MK, SM, CH | `bank_iban`, `bank_account_holder`, `bank_bic` | 1 | bestehend, Bedingung präzisiert | A, B |
| `notary_name` ausgefüllt | Adresse des Gründungsnotars | `notary_address` | 2 | **neu** | A, B |
| `deviating_fiscal_year` = Ja | Beginn des Wirtschaftsjahrs | `fiscal_year_start` | 2 | bestehend | A, B |
| `share_capital_currency` ausgefüllt (insb. „Sonstige“) | Betrag und Bezeichnung der Währung | `share_capital_amount`, `share_capital_currency` | 2 | bestehend | A |
| Beteiligte-Eintrag angelegt | Name, Vorname, Geburtsdatum, Adresse, Beteiligung in % | `last_name_or_company`, `date_of_birth`, `address`, `share_percentage` | 4 | bestehend | A, B |
| `is_general_partner_of_kg` = Ja | Bezeichnung der KG | `general_partner_kg_name` | 2 | **neu** | A, B |
| `register_status` ≠ beabsichtigt (beantragt/erfolgt) | Datum (beantragt am bzw. Tag der Eintragung), Registergericht, Registernummer | `register_date`, `registry_court`, `register_number` | 2 | `register_date` **neu**, übrige bestehend | A, B |
| `part_of_group` = Ja | Name des Konzerns | `controlling_company_name` | 2 | bestehend | A, B |
| `split_ownership_structure` = Ja (Betriebsaufspaltung) | Bezeichnung Besitzunternehmen, Bezeichnung des überlassenen Wirtschaftsguts (wesentliche Betriebsgrundlage), Beginn der Nutzung, Adresse und/oder Steuernummer des Besitzunternehmens | `split_ownership_company_name`, `split_owner_asset_description`, `split_ownership_usage_start`, `split_owner_address_or_taxno` | 2 | **neu** | B |
| `kst_exemption` = Ja (Körperschaftsteuerbefreiung § 5 KStG) | Nummer nach § 5 Abs. 1 KStG | `kst_exemption_number` | 2 | **neu** | B |
| `par60a_ao_determination` = Ja (Feststellung § 60a AO) | Zweck der Körperschaft | `par60a_ao_purpose` | 2 | **neu** | B |
| `is_tax_group_subsidiary` = Ja (körperschaftsteuerliche Organgesellschaft) | Name/Firma des Organträgers | `tax_group_parent_name` | 2 | **neu** | B |
| `is_vat_group_member` = Ja (umsatzsteuerliche Organschaft) | Beginn der umsatzsteuerlichen Organschaft | `vat_group_start_date` | 2 | **neu** | B |
| Voraussichtliche USt = Zahllast (innerhalb `expected_vat_amount`-Kontext) | Betrag | `expected_vat_amount` | 6 | bestehend | A, B |
| `vat_tax_free_sales` = Ja (§ 4 UStG) | Art des Umsatzes | `vat_tax_free_sales_type` | 6 | **neu** | A, B |
| `vat_reduced_rate_sales` = Ja | Art des Umsatzes | `vat_reduced_rate_sales_type` | 6 | **neu** | A, B |
| `vat_zero_rate_sales` = Ja | Art des Umsatzes, mindestens eine Rechtsvorschrift | `vat_zero_rate_sales_type`, `vat_zero_rate_legal_basis` | 6 | **neu** | A, B |
| `vat_flat_rate_agriculture` = Ja (§ 24 UStG) | Art des Umsatzes, genau eine Auswahl Durchschnittssatzbesteuerung/Verzicht | `vat_flat_rate_agriculture_type`, `vat_flat_rate_agriculture_choice` | 6 | **neu** | A, B |
| `input_tax_refund_requested` = Ja (nur Auslandskörperschaft) | Datum, Aktenzeichen | `input_tax_refund_date`, `input_tax_refund_reference` | 6 | **neu** | A |
| `own_webshop` = Ja | Internetadresse (URL) des Webshops | `webshop_url` | 6 | **neu** | A, B |
| `electronic_interface` ausgefüllt | Identifikationsmerkmal (z. B. Accountname) | `electronic_interface_identifier` | 6 | **neu** | A, B |
| `document_type` = Sonstiges / weitere Unterlagen | Aufzählung der Unterlagen | `note` | 8 | bestehend | A, B |

**Nicht als Forms-Verzweigung abbildbar (formularübergreifende UND-Bedingung bzw. Textinhaltsprüfung):** siehe `sharepoint-forms/README.md` Abschnitt E (neuer Unterabschnitt Prüfregeln) — diese zwei Fälle werden stattdessen als Power-Automate-Prüfregel mit Fallback in `Eingang_Fehler` dokumentiert:

1. Steuernummer/Land (Zeile 1 der Tabelle oben): Bedingung verknüpft `registration_status` mit `par27_ao_agreement` — beide Felder leben seit 28.10.2026 als Kanzleifelder in Liste 0 (vorher `already_registered` in Liste 1), die Prüfregel bleibt trotzdem als Power-Automate-Schritt nötig, da Forms für Formular 1 keine Sicht auf Liste-0-Felder hat.
2. BIC-Pflicht abhängig vom IBAN-Länderpräfix (AL, MD, MC, ME, MK, SM, CH): Forms kann Textinhalte nicht inspizieren, um eine Frage bedingt einzublenden.

Alle übrigen Zeilen der Tabelle sind reine Einzelformular-Bedingungen (eine auslösende Choice/Boolean-Frage im selben Formular) und werden über reguläres Forms-Branching abgebildet (Details je Feld in `sharepoint-forms/README.md`).

**Nicht vollständig getestet (laut Quelldateien, kein abschliessender Befund):** fsekapgaus — Abschnitt 4 Ausland/nicht feste Betriebsstätte, Abschnitt 6 unabhängige Person, Abschnitt 23 Bauausführung, Abschnitt 19 Z220/Z232/Z233, Abschnitt 21 Z244–248/Z250–254, gelbe Hinweisliste; fsekapg — Telefon-/Marktplatzlisten, Abschnitt 4 nicht natürlicher Vertreter, Abschnitt 8 Notar-Staat/Register-Optionen einzeln, Abschnitt 17 Überschuss/Z193 allein, Abschnitt 18 UStIdNr-Grund Option 2/3, Startseite „Steuernummer eingeben“/„Datenübernahme aus Profil“. Diese Pfade sind weiterhin offen (siehe Abschnitt G in `sharepoint-forms/README.md`).

**Offene Verifikation:** die oben gelisteten „nicht vollständig getesteten“ Pfade beider Formulare, aktueller Formularstand 2026, §-138-AO-Einzelfallfristen. E-Felder sind nicht als amtlich zwingend zu kommunizieren. **Kein offener Verifikationsbedarf mehr:** Vereins-/Körperschaftsfragebogen und juristische Personen öffentlichen Rechts sind per Kanzleientscheid vom 26.10.2026 bewusst ausgeschlossen (Status X, siehe 9.1); ausländische Partnerships/LLCs sind als definierter manueller Prüfschritt der Kanzlei festgelegt (Status M, siehe 9.1); die unbedingte Pflichtliste der Körperschaft ausländischen Rechts sowie KapG-Kz 179 sind durch die ELSTER-Portalprüfung vom 26.10.2026 bestätigt (siehe 2.2/2.4/9.3); die bedingten Pflichtfelder beider Formulare sind durch dieselbe Portalprüfung weitestgehend ermittelt und in Abschnitt 9.6 dokumentiert sowie als `belegt_bedingt`-Spalten in der SharePoint-Liste nachgezogen (siehe `sharepoint-forms/New-SteuerlicheErfassungListen.ps1`).

**Umsetzungsstand SharePoint/Forms:** [`sharepoint-forms/README.md`](sharepoint-forms/README.md) Abschnitt E/E.9 bildet 9.1-9.4 für die bereits belegten Formulartypen (Einzelunternehmen, Kapitalgesellschaft/Genossenschaft, Personengesellschaft/-gemeinschaft, Körperschaft ausländischen Rechts, BZSt2) ab, inkl. Stimmrechte, Rechtsfähigkeit, Aufteilungsschlüssel, § 27 AO-Zustimmung, SEPA-Wunsch, Rückfrage-E-Mail und Soll-/Ist-Besteuerung. Für Vereine/Stiftungen/sonstige Körperschaften privaten Rechts sowie juristische Personen öffentlichen Rechts (siehe 9.1, Status X) ist **bewusst kein** eigenes Formular/keine eigene Liste vorgesehen — Kanzleientscheid vom 26.10.2026: praktisch ohne Relevanz, keine weitere Pflichtfeldermittlung geplant. Für ausländische Partnerships/LLPs/LLCs (siehe 9.1, Status M) ist ebenfalls keine Automatisierung vorgesehen; der Rechtstypenvergleich erfolgt manuell durch die Kanzlei, bevor ein Fall einem der bestehenden Formulartypen (Formular 2 Personengesellschaft oder Körperschaft ausländischen Rechts) zugeordnet wird. Alle unbedingten Pflichtfelder aus 2.2/2.4/9.3, die laut ELSTER-Portalprüfung 26.10.2026 (verification_date 2026-10-26) bestehen, sind in der Skript-Feldliste bereits als Spalte vorhanden (Firma/`last_name_or_company` in Liste 1, Tätigkeit/`business_activity`, Rechtsform/`legal_form_category`+`legal_form_german`/`legal_form_foreign_name` in Liste 1 (seit 28.10.2026, siehe Abschnitt 10 — vorher `legal_form` in Liste 2, siehe `sharepoint-forms/README.md` Abschnitt H2), Gründungsart/`formation_type`, Tätigkeitsbeginn/`activity_start_date`, Treuhandverhältnis/`trust_relationship_status` (seit 28.10.2026, vorher `trust_relationship`, siehe Abschnitt 10), voraussichtlicher Gewinn Eröffnungsjahr/`expected_profit_opening_year`, Umsatzschätzung Eröffnungs- und Folgejahr/`estimated_revenue_opening_year`+`estimated_revenue_following_year`, Zustimmung § 27 AO/`par27_ao_agreement` (seit 28.10.2026 Kanzleifeld in Liste 0), Vorregistrierung/`registration_status` (seit 28.10.2026, vorher `already_registered`)); notarielle Errichtung (`notarial_deed_date`) und Grund-/Stammkapital (`share_capital_amount`) sind ebenfalls als Spalte vorhanden, bleiben aber — wie bei allen Feldern, die nur für einen Formulartyp unbedingt sind — in SharePoint ohne `-Required`, da die Pflicht nur für Kapitalgesellschaften gilt und SharePoint keine formulartyp-bedingten Pflichtfelder kennt (Durchsetzung über Forms-Branching, siehe `sharepoint-forms/README.md` Abschnitt C). „Mindestens ein Anteilseigner“ bzw. „mindestens ein gesetzlicher Vertreter“ sind Mengen-/Mindestanzahl-Bedingungen über mehrere Datensätze einer Liste hinweg und lassen sich nicht als einzelne SharePoint-Spalte abbilden; sie werden über die Plausibilitätsprüfung (Schritt 5) vor Fallabschluss manuell geprüft. Die bedingten Pflichtfelder aus Abschnitt 9.6 (Update 2) sind in Liste 2 und Liste 6 als zusätzliche, bewusst nicht `-Required` gesetzte Spalten ergänzt (33 neue Spalten insgesamt); keine bestehende Spalte wurde dafür geändert, entfernt oder umbenannt.

**`split_owner_asset_description` (Abschnitt 9.6, Betriebsaufspaltung) — entschieden:** Kanzleientscheid Nils 27.10.2026: Das Feld wird geführt als „Bezeichnung des überlassenen Wirtschaftsguts (wesentliche Betriebsgrundlage)“. Die ELSTER-Fehlerliste nannte für Zeile 135 nur den Fehlertext „Bezeichnung“ ohne weiteren Kontext; der obige Wortlaut ist Kanzleientscheid und **nicht** im ELSTER-Portal verifiziert. Interner Spaltenname damals unverändert geblieben; am 28.10.2026 aus einem anderen Grund (32-Zeichen-Grenze) von `split_ownership_asset_description` auf `split_owner_asset_description` umbenannt, siehe `sharepoint-forms/README.md` Abschnitt H1 (Changelog).

**Grundregel Tatsachen/Rechtsfolgen (28.10.2026):** siehe neuer Abschnitt 10 unten für die systematische Trennung von Tatsachenfeldern (vom Mandanten erhoben) und Ergebnisfeldern (von der Kanzlei abgeleitet), inkl. Ableitungstabelle. Betroffene Felder aus diesem Abschnitt: `already_registered` → `registration_status`, `trust_relationship` → `trust_relationship_status` (beide: Required-Boolean-Bug, siehe `sharepoint-forms/README.md` Abschnitt C2, zweiter Fallen-Block Punkt 2), `legal_form` → `legal_form_category`/`legal_form_jurisdiction`/`legal_form_german`/`legal_form_foreign_name`/`legal_form_foreign_country` (Tatsachen statt Freitext-Einordnung).

**Provenienz:** Basismodell und \`DE/AO/formulardaten-roherfassung.md\` aus diesem Repository; OneDrive \`01 Projekte/ELSTER-Entwickler/SharePoint_Listenschema_ELSTER_Meldungen_2026-09-19.md\` (interner Projektentwurf). Status B/F beruht auf dort dokumentierter Formularauswertung; Status E auf ergänzender kanzleiinterner Datenerhebungslogik.

## 10. Trennung Tatsachen/Rechtsfolgen (Grundregel, ergänzt 28.10.2026)

### 10.1 Grundregel

Review Nils 28.10.2026 (Testlauf gegen die frische Site `transferpricingdocs.sharepoint.com/sites/steuerdaten`): Der Mandant liefert in den Formularen 0-8 ausschliesslich **Tatsachen** — nie eine eigene steuerliche oder rechtliche Einschätzung. Jede Frage, die implizit eine rechtliche Würdigung voraussetzt (z. B. „ist Ihr Unternehmen ausschliesslich vermögensverwaltend tätig?“), wird durch eine oder mehrere Tatsachenfragen ersetzt, aus denen die Kanzlei das rechtliche Ergebnis selbst ableitet (z. B. anhand AO, UStG, EStG, KStG, GewStG sowie der bereits dokumentierten Prüfregeln in Abschnitt 9.6/`sharepoint-forms/README.md` Abschnitt E.10).

Beispiele aus der Review (nicht erschöpfend, siehe Ableitungstabelle 10.2 für den aktuellen Umsetzungsstand):

- **Zuständiges Finanzamt:** statt direkt zu fragen, werden Ort der Geschäftsleitung, Sitz, Betriebsstätte in Deutschland, Ort der Tätigkeit in Deutschland, Wohnsitz/gewöhnlicher Aufenthalt der Beteiligten, Art der Umsätze und Ansässigkeitsstaat erhoben (§§ 18-20 AO).
- **Soll-/Ist-Versteuerung:** statt direkt zu fragen, werden voraussichtlicher Umsatz des Eröffnungs- und Folgejahres, Buchführungspflicht und freiberufliche Tätigkeit erhoben (§ 20 UStG).
- **Kleinunternehmerregelung:** Umsatz Vorjahr/laufendes Jahr, Sitz/Ansässigkeit, Art der Umsätze (§ 19 UStG).
- **Zielmeldung/BZSt-Sachverhalt, Organschaft, Betriebsstätte:** bleiben Ergebnisfelder, die die Kanzlei nach Prüfung der erhobenen Tatsachen festlegt.

**Ergebnisfelder** (von der Kanzlei abgeleitete Spalten) bleiben als Spalten erhalten, werden aber: (a) **nicht** `-Required` gesetzt, (b) im DisplayName als Kanzleifeld gekennzeichnet (z. B. „... von der Kanzlei nach Prüfung ausgefüllt“), und (c) **nicht** als Mandanten-Forms-Frage geführt, sondern — soweit noch Teil eines Mandanten-Formulars — klar als Kanzlei-intern markiert bzw. ganz in die interne Liste `0_Fallsteuerung` verschoben.

### 10.2 Ableitungstabelle (Ergebnisfeld → Tatsachenfelder)

**Vollständig umgesetzt 30.10.2026** (Nils-Auftrag „Grundregel jetzt für ALLE Listen vollständig umsetzen"), **Klärung Nils zu PR #24 eingearbeitet 31.10.2026**. Diese Tabelle bleibt die lesbare Kurzfassung; die vollständige, maschinenlesbare Wenn-Dann-Übersetzungstabelle mit exakten Schwellenwerten, Normen inkl. Rechtsstand, Ausnahmen und als unsicher markierten Verzweigungen steht in [`ableitungsregeln.json`](ableitungsregeln.json) (Schema: [`ableitungsregeln.schema.json`](ableitungsregeln.schema.json)) — siehe Abschnitt 10.4.

| Ergebnisfeld (Kanzleifeld) | Liste | Rechtsgrundlage | Abgeleitet aus (Tatsachenfelder) |
|---|---|---|---|
| `tax_office` (Zuständiges Finanzamt) | 0 | §§ 10, 18-20 AO, UStZustV | `party_type`/`address_type`/`postal_code_city`/`legal_form_category`/`legal_form_jurisdiction` (Liste 1), `usual_workplace_country`/`usual_workplace_address`/`works_elsewhere` der gesetzlichen Vertreter (Liste 3), Betriebsstätten in Deutschland (`country`/`site_type`, Liste 5). **Bestimmt nur den Anknüpfungspunkt (Ort) — der konkrete Finanzamts-Name erfordert zusätzlich einen Abgleich mit dem Zuständigkeitsverzeichnis des jeweiligen Bundeslandes bzw. (bei reinen Auslands-USt-Fällen) mit der `ustzustv-laendertabelle.json` (noch nicht befüllt, siehe Abschnitt 10.3); für den allgemeinen Ertragsteuer-Inlandsfall bleibt der konkrete Finanzamts-Name ohne verifizierte GemFA-Datenquelle `"manuelle Prüfung"`.** |
| `tax_office_country` (Land des Finanzamts) | 0 | §§ 18-20 AO | `party_type`/`address_type`/`country`/`legal_form_category`/`legal_form_jurisdiction`/`legal_form_foreign_country` (Liste 1), Betriebsstätten im Inland (Liste 5). **Klassifizierung als Ergebnisfeld am 31.10.2026 von Nils bestätigt** (Folge einer Rechtsprüfung — Sitz, Ort der Geschäftsleitung, Betriebsstätten-/Grundstückslage, Wohnsitz bei natürlichen Personen —, nicht vom Mandanten selbst zu bestimmen); eine unstrukturierte Grundstückslage bleibt offener Punkt, siehe Abschnitt 10.3. |
| `target_notification` (Zielmeldung/BZSt2-Sachverhalt) | 0 | § 138 Abs. 2 Satz 1 Nr. 1-4 AO | `direction` (Liste 0), Betriebsstätten im Ausland (Liste 5), Beteiligungsart/-quote/Erwerbs- und Veräusserungsdatum/Kaufpreis/Anschaffungsnebenkosten/Sitz-und-Geschäftsleitung-im-Ausland/Börsennotierung (`participation_type`/`share_percentage`/`participation_since`/`disposal_date`/`purchase_price`/`acquisition_incidental_costs`/`target_seat_and_mgmt_abroad`/`target_stock_listed`, Liste 4, letzte sechs **neu/ergänzt** 31.10.2026 — Befund „Nominalwert reicht nicht" für § 138 Abs. 2 Satz 1 Nr. 3 AO, `nominal_share` dafür nicht mehr massgeblich), `third_country_control` (Liste 7). Meldeschwelle Nr. 3: 10 % Beteiligung (unmittelbar und mittelbar zusammengerechnet) oder eigene Anschaffungskosten > 150.000 EUR, Börsenklausel bei Quote < 1 %; Aggregation über mehrere Datensätze bleibt offener Punkt, siehe Abschnitt 10.3. |
| `profit_determination_method` (Gewinnermittlungsart) | 2 | §§ 4, 5 EStG, § 141 AO, § 238 HGB | `legal_form_category` (Liste 1), `register_status` (Liste 2), `domestic_bookkeeping_obligation` (Liste 2, **neu** 30.10.2026 — schliesst eine Lücke: bislang war nur die ausländische Buchführungspflicht erfasst), `foreign_bookkeeping_obligation`, `voluntary_balance_sheet` (Liste 2). Freiberufler (`legal_form_category = 'Freiberufliche Tätigkeit'`) sind von § 141 AO dem Wortlaut nach nicht erfasst — eigene vorrangige Ableitungszeile, **ergänzt** 31.10.2026. |
| `site_type` (Art der Einrichtung: fest/nicht fest) | 5 | § 12 AO | `own_disposal_power`, `activity_period_from`/`activity_period_to`/`activity_period_to_unknown` (Liste 5) |
| Ort der tatsächlichen Geschäftsleitung (keine eigene Spalte, Hilfsableitung für `tax_office`) | — | § 10 AO | `usual_workplace_country`/`usual_workplace_address`/`works_elsewhere`/`other_workplace_details` je gesetzlichem Vertreter (Liste 3) |
| „Ausschliesslich vermögensverwaltend tätig" (keine eigene Spalte, konzeptuelle Ableitung) | — | § 14 Satz 3 AO, § 9 Nr. 1 S. 2 GewStG, § 15 Abs. 3 Nr. 1 EStG | `asset_management_present`, `asset_management_type`, `asset_mgmt_share_revenue`/`asset_mgmt_share_profit`, `other_business_activities` (Liste 1). **Die exakte Schwelle hängt vom Verwendungszweck ab (erweiterte Kürzung vs. Abfärbetheorie) — offene Frage an Nils.** |
| `dependency_status` (Abhängige/unabhängige Person, ständiger Vertreter) | 3 | § 13 AO, Art. 5 Abs. 5/6 OECD-MA | `instruction_bound`, `integrated_into_organization`, `bears_entrepreneurial_risk`, `fixed_remuneration` (alle Liste 3, **neu** 30.10.2026) |
| `limited_tax_liability` (Beschränkte Steuerpflicht) | 4 | § 1 Abs. 4 EStG, § 2 Nr. 1 KStG | `participant_type` (bestehend), `domestic_residence` (natürliche Person, **neu** 30.10.2026), `domestic_seat_or_management` (Gesellschaft, **neu** 30.10.2026) |
| `vat_relevant_site` (Umsatzsteuerliche Betriebsstätte) | 5 | § 3a Abs. 1 UStG, Art. 11 MwSt-DVO | `site_type` (Ergebnis dieser Liste), `staff_present_onsite` (**neu** 30.10.2026) |
| `payroll_tax_site` (Lohnsteuerliche Betriebsstätte) | 5 | § 41 Abs. 2, § 38 Abs. 3 EStG | `site_type`, `staff_present_onsite`, `employer_function_onsite`, `wages_paid_from_site` (letzte drei **neu** 30.10.2026) |
| `small_business_rule` (Kleinunternehmerregelung) | 6 | § 19 Abs. 1 UStG, Rechtsstand/Schwellen (25.000/100.000 EUR ab 1.1.2025, vorher 22.000/50.000 EUR) am 31.10.2026 von Nils bestätigt, siehe `ableitungsregeln.json` | `prior_year_revenue` (**neu** 30.10.2026), `estimated_revenue_opening_year` (bestehend), `predecessor_exists` (Liste 2, bestehend) |
| `vat_taxation_method` (Soll-/Ist-Besteuerung, Antragsvorschlag) | 6 | § 16 Abs. 1, § 20 Satz 1 Nr. 1 UStG, Schwelle 800.000 EUR seit 1.1.2024 (WachstumschancenG, am 31.10.2026 von Nils bestätigt) | `legal_form_category` (Liste 1), `prior_year_revenue` (**neu**), `domestic_bookkeeping_obligation` (Liste 2, **neu**), `predecessor_exists` (Liste 2) |

### 10.3 Offene Punkte / nächste Runde

- **Vollständig umgesetzt 30.10.2026:** Alle sechs in Abschnitt 10.3 der Vorversion als offen vorgemerkten Felder (`dependency_status`, `limited_tax_liability`, `vat_relevant_site`, `payroll_tax_site`, `small_business_rule`, `vat_taxation_method`) sind jetzt mit eigenen Tatsachenfeldern, Kanzleifeld-DisplayNamen und vollständigen Ableitungsregeln (`ableitungsregeln.json`) ausgestattet. Die Ableitungstabelle oben sowie `sharepoint-forms/README.md` Abschnitte E.3/E.4/E.5/E.6 wurden entsprechend angepasst.
- **Fachliche Klärung bei Nils am 31.10.2026 beantwortet** (siehe `sharepoint-forms/README.md` Abschnitt H4 für die vollständige Umsetzung je Punkt): (1) Klassifizierung von `tax_office_country` als Ergebnisfeld bestätigt; (2) `formation_type` in `formation_origin` (neu, Entstehungsart) und `capital_contribution_type` (präzisiert, Kapitalaufbringung) aufgespalten — Zeile in der Ableitungstabelle oben entfernt, da beide Nachfolgefelder jetzt direkte Tatsachenfragen sind; (3) Rechtsstand der Schwellenwerte für Kleinunternehmerregelung (§ 19 UStG), Ist-Besteuerung (§ 20 UStG) und Buchführungspflicht (§ 141 AO, inkl. Freiberufler-Ausnahme) mit genauer WachstumschancenG-Fundstelle bestätigt; (4) `tax_office`-Finanzamts-Lookup teilautomatisiert (UStZustV-Ländertabelle für reine Auslands-USt-Fälle, siehe unten) bzw. als `"manuelle Prüfung"` mit Begründung markiert (allgemeiner Ertragsteuer-Inlandsfall, keine verifizierte GemFA-Quelle); (5) § 138 Abs. 2 Satz 1 Nr. 3 AO („Nominalwert reicht nicht"): sechs neue Tatsachenfelder in Liste 4, siehe Ableitungstabelle oben.
- **Neue offene fachliche Punkte nach der 31.10.2026-Klärung** (siehe `ableitungsregeln.json` `offene_fragen_global` für den vollen Wortlaut): Grundstückslage wird nur unstrukturiert in `asset_management_type` (Freitext) erfasst, relevant für § 18 AO; [`ustzustv-laendertabelle.json`](ustzustv-laendertabelle.json) ist bewusst **nicht befüllt** (Risiko einer falschen Finanzamt-Zuordnung bei geratenen Angaben — Schema steht bereit, siehe [`ustzustv-laendertabelle.schema.json`](ustzustv-laendertabelle.schema.json)); keine verifizierte, lizenzrechtlich nutzbare GemFA-Datenquelle für die allgemeine Ertragsteuer-Zuständigkeit identifiziert; die datensatzübergreifende Aggregation unmittelbarer/mittelbarer Quoten und Anschaffungskosten über mehrere `4_Beteiligte_und_Quoten`-Datensätze (§ 138 Abs. 2 Satz 1 Nr. 3 AO) ist als Flow-/Kanzlei-Prozessschritt dokumentiert, nicht als einzelne Feldbedingung abbildbar; `formation_origin` überschneidet sich inhaltlich mit `predecessor_exists`/`transformation_event` (bewusst als eigene Frage beibehalten, Konsistenzprüfung im Flow offen).
- Beim systematischen Audit **aller** Listen 0-8 am 30.10.2026 zusätzlich als Ergebnisfelder identifiziert, aber **noch nicht** mit eigenen Ableitungsregeln ausgestattet (Umfang hätte den Rahmen dieser Runde gesprengt, Rechtsstand-Risiko bei hastiger Schätzung zu hoch) — empfohlen als nächste Vertiefungsrunde: `is_tax_group_parent`, `legal_capacity`, `split_ownership_structure` (+4 zugehörige Felder), `kst_exemption` (+1), `par60a_ao_determination` (+1), `is_tax_group_subsidiary` (+1), `is_vat_group_member` (+1) in Liste 2; `vat_filing_period`, `expected_vat_amount`, `expected_payroll_tax`, `construction_services_over_10pct` sowie die rund 15 UStG-Ausnahmetatbestands-Felder (`vat_tax_free_sales*`, `vat_reduced_rate_sales*`, `vat_zero_rate_sales*`, `vat_flat_rate_agriculture*`, `input_tax_refund_*`) in Liste 6; `third_country_control` in Liste 7 (ausserhalb des Erfassungs-Chat-Scopes, siehe `generator/cli.py` `CHAT_LISTS`, aber fachlich dieselbe Würdigungsproblematik wie `target_notification`).
- Seit 28.10.2026 trägt jedes `Add-Field`-Feld in den sieben vom Erfassungs-Chat genutzten Listen (1, 2, 3, 4, 5, 6, 8) ein maschinenlesbares `-FieldRole`-Metadatum (`Tatsache`/`Ergebnis`/`System`, siehe `sharepoint-forms/README.md` Abschnitt C3) direkt im PnP-Skript.
- Lists 3-8-Audit (siehe `sharepoint-forms/README.md` Abschnitt G): Nils' eigene Prüfung zu Listen 3-8 steht fachlich weiterhin aus; der 30.10.2026-Durchlauf ist eine eigenständige Vertiefung, kein Ersatz dafür.

### 10.4 Maschinenlesbare Ableitungsregeln (`ableitungsregeln.json`)

Ergänzt 30.10.2026 (Nils-Auftrag): Die obige Tabelle nennt nur, **welche** Tatsachenfelder in ein Ergebnisfeld einfliessen. Die eigentliche Übersetzungstabelle „wenn diese Tatsachen, dann diese Rechtsfolge = einzutragender Wert" steht maschinenlesbar in zwei neuen Dateien im selben Verzeichnis wie dieses Dokument:

- [`ableitungsregeln.schema.json`](ableitungsregeln.schema.json) — JSON Schema (Draft 2020-12), das die Struktur verbindlich festlegt.
- [`ableitungsregeln.json`](ableitungsregeln.json) — die eigentlichen Regeln, eine gegen das Schema validierte Instanz.

**Format je Regel** (ein Eintrag im Array `regeln`): eine eindeutige `id`, Referenz auf das `ergebnisfeld` (Liste + interner Name), eine Liste von `normen` (Gesetz, Fundstelle, **Rechtsstand als Datum**, Kurzbeschreibung — wichtig bei kürzlich reformierten Normen), die zugrunde liegenden `tatsachenfelder`, eine geordnete Liste von `ableitungszeilen` (je Zeile: `bedingung_text` lesbar, optional `bedingung` strukturiert als boolescher Ausdruck über Tatsachenfelder mit `und`/`oder`/`nicht`/`vergleich`, `ergebniswert` als exakter einzutragender Wert, optionale `ausnahmen`, sowie `unsicher`/`offene_frage_an_nils` wenn die Zeile fachlich nicht abschliessend gesichert ist), ein `fallback` für den Fall, dass keine Zeile eindeutig zutrifft (Standardwert `"manuelle Pruefung"`), und `kanzlei_bestaetigung_erforderlich: true` (immer gesetzt — kein Automatismus ohne Bestätigung durch eine berufsrechtlich zugelassene Person).

**Vorgesehene Nutzung:** Ein Power-Automate-Flow, der Erfassungs-Chat (`erfassungs-chat/`) oder ein künftiger ELSTER-Bot liest diese Datei, wertet die `ableitungszeilen` gegen die tatsächlich erhobenen Tatsachenwerte aus und zeigt der Kanzlei einen **Vorschlag** samt Norm und Begründung an. Die Kanzlei bestätigt (oder korrigiert) den Vorschlag, bevor er in SharePoint oder ELSTER eingetragen wird — zu keinem Zeitpunkt erfolgt eine automatische Eintragung ohne diese Bestätigung (siehe `hinweis_rechtsverbindlichkeit` in der Datei selbst).

**Rechtsstand und Unsicherheiten:** Globaler Rechtsstand `"2026-10-31"`, abweichende Rechtsstände je Norm dort, wo eine Norm kürzlich reformiert wurde (insbesondere § 19 UStG zum 1.1.2025, § 20 UStG-Schwelle zum 1.1.2024 und § 141 AO-Schwellen zum 1.1.2024, beide durch das Wachstumschancengesetz vom 27.3.2024, BGBl. 2024 I Nr. 108, Art. 97 § 19 Abs. 3 und 4 EGAO — am 31.10.2026 von Nils bestätigt). Als `unsicher: true` markierte Regelzeilen sind **keine gesicherte Rechtsauskunft** — sie benennen in `offene_frage_an_nils` explizit die zu klärende Fachfrage, statt eine Schätzung als sicher auszugeben. Die Datei enthält zusätzlich `offene_fragen_global` für Fragen, die ein einzelnes Ergebnisfeld übergreifen (z. B. die unstrukturierte Grundstückslage oder die unbefüllte `ustzustv-laendertabelle.json`). Kommentarliteratur (Klein/Raetke, AO, 19. Aufl. 2025) wird in den Normen ausschliesslich als Fundstelle zitiert (z. B. „§ 141 Rn. 3-11", „§ 138 Rn. 24-31"), nie als wiedergegebener oder paraphrasierter Kommentartext — der Verlag schliesst eine KI-/TDM-Nutzung aus.
