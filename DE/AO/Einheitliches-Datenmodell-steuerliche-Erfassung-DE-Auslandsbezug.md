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
| Geschätzter Umsatz, Eröffnungs- und Folgejahr | 179 | unbedingt, im Auszug nicht eindeutig referenziert |

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

Die übermittelte Fehlerliste endet nach den folgenden Angaben. Weitergehende Pflichtfelder sind daher erst bei einem vollständigen Validierungslauf zu bestätigen.

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
