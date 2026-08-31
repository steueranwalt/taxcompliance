# Einheitliches Datenmodell: steuerliche Erfassung Deutschland und Auslandsbezug

**Stand:** 31.08.2026

**Quellen:** ELSTER-Fragebögen für Einzelunternehmen, Kapitalgesellschaft/Genossenschaft, Personengesellschaft/-gemeinschaft, Körperschaft nach ausländischem Recht sowie BZSt2 nach § 138 Abs. 2 AO.

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

Dieser Kern wird sowohl für Inbound-Fragebögen als auch für BZSt2 einmalig erhoben und in nachfolgenden Fragebögen vorbefüllt. Abweichungen werden pro Formular über eine Zuordnungstabelle an die jeweilige Kz übertragen.

| Objekt | Datenfeld | Inbound-Kz, Beispiele | BZSt2-Kz |
|---|---|---|---|
| Fall | Akten-/Fall-ID, Bearbeitungsnotiz, Erfassungsjahr | keine Kz | Jahr: keine Kz ausgewiesen |
| Steuerliche Identifikation | Art der Nummer, Steuernummer, IdNr., Wirtschafts-IdNr., zuständiges Finanzamt | Startseite; je nach Formular | keine Kz ausgewiesen |
| Meldepflichtiger | Person oder Firma | EU: 2–5; KapG: 2–6; PersG: 2–5 | keine Kz ausgewiesen |
| Name | Nachname/Firma; bei Person Vorname, Titel, Geburtsdatum | EU: 2–3; KapG/PersG: 2 | keine Kz ausgewiesen |
| Rechtsform | deutsche/ausländische Rechtsform, sonstige Rechtsform | KapG 63; PersG 31–32; Ausland 107 | keine Kz ausgewiesen |
| Adresse | Adressart, Strasse, Nummer, Zusatz, PLZ, Ort, Staat, Postfach | wiederkehrend, z. B. KapG 4–7 | 15–17, übrige Felder ohne Kz ausgewiesen |
| Kontakt | Telefon, Web-Adresse | wiederkehrend, z. B. KapG 11–12 | nicht abgefragt |
| Tätigkeit | genaue Tätigkeit; vermögensverwaltend ja/nein | EU 21; KapG 13–14; PersG 12; Ausland 12–13 | Sachverhalt in Mitteilungsmodul |
| Ort der Leitung | Abweichender Ort der Geschäftsleitung | EU 63–66; KapG 8–10; PersG 7–9; Ausland 7–9 | Adressart «Ort der Geschäftsleitung» |
| Steuerberatung | natürliche/juristische Person, Adresse, Telefon; Vollmacht | wiederkehrend | Mitwirkung: 30 |
| Bank | IBAN, BIC, Kontoinhaber, abweichender Kontoinhaber | EU/KapG/PersG/Ausland, jeweils eigener Kz-Block | nicht abgefragt |
| Anlagen | Dokumenttyp, Bezeichnung, Datei, Erforderlichkeit | formularspezifische Anlagen-Kz | Anhang ohne Kz ausgewiesen |

## 4. Wiederholbare Datenobjekte

Diese Objekte dürfen nicht in Freitextfeldern gesammelt werden. Jeder Datensatz erhält eine technische Objekt-ID und eine fortlaufende Nummer.

| Objekt | Kernfelder | Wichtige Formular-Kz |
|---|---|---|
| Adresse | Typ, Inland/Ausland, Strasse, Hausnummer, Zusatz, PLZ, Ort, Staat, Postfach | siehe allgemeiner Kern |
| Person | Anrede, Titel, Name, Vorname, Namenszusatz, Geburtsdatum, IdNr., Beruf | gesetzlicher Vertreter KapG 25–30; PersG-Vertretung 45–54; Ausland 76–85 |
| Juristische Person | Firma, Rechtsform, Sitz, Register, Registernummer, Steuerkennzeichen | Anteilseigner KapG 72–77; Beteiligter PersG 86–91; Ausland 124–130 |
| Betriebsstätte/Einrichtung | Bezeichnung, Adresse, Land, Art, feste/nicht feste Einrichtung, Eigentum, Nutzung | EU 70–74; KapG 15–19; Ausland Detailblock vor 56 |
| Beteiligung | Beteiligter/Anteilseigner, direkte/mittelbare Beteiligung, Rolle, Kapitalanteil, Prozentquote, Zähler/Nenner, Treuhand | KapG 67a–78, 90; PersG 92–99; Ausland 121–132; BZSt2: Beteiligten-Abschnitte |
| Vertretung | Person/Organisation, Rolle, Vertretungsbefugnis, Abschlussvollmacht | KapG 25–30; PersG 45–54; Ausland ständiger Vertreter 62–68 |
| Steuerprognose | Steuerart, Jahr, Betrag, Beteiligter, Sonderbetriebsbezug | EU 105–113; KapG 165–168; PersG 77, 93–95; Ausland 175–178 |
| Umsatzsteuerprofil | Umsatz, Steuerverfahren, Umsatzart, Steuersatz, USt-IdNr., OSS, Onlinehandel | jeweils eigenes USt-Kz-Modul |
| Dokument | Dokumenttyp, Bezug zu Objekt, vorhanden/hochgeladen, Dateiname, Hinweis | jeweils Anlagen-Kz-Modul |

## 5. Rechtsformspezifische Module und Kz

### 5.1 Einzelunternehmen

| Modul | Daten | Kz |
|---|---|---|
| Persönliche Verhältnisse | Religion, Ehe/Lebenspartnerschaft, Ehegatte, bisherige persönliche Verhältnisse | 5, 11–18, 47–54 |
| Unternehmen | Unternehmensbezeichnung, Unternehmensadresse, Tätigkeitsbeginn | 55–62, 69 |
| Register/Gründung | Handelsregister, Gründungsart, Vorinhaber | 80–92 |
| Vorbetätigung/Konzern | Vortätigkeit, Konzernunternehmen | 93–104 |
| Gewinn | Einkünfte, Sonderausgaben, Steuerabzug, Gewinnermittlung | 105–116 |
| Lohnsteuer | Arbeitnehmer, Lohnzahlungen, Lohnsteuerstätte | 118–126 |
| Umsatzsteuer | Geschäftsveräusserung, Umsatz, Kleinunternehmer, USt, Befreiung/Steuersatz, Ist/Soll, USt-IdNr., Bau/Gebäudereinigung | 127–162 |
| USt-Sonderverfahren | Organschaft, OSS, Onlinehandel, soziale Medien | 135–184 |
| Beilagen | Beilagenliste | 189–194 |

### 5.2 Kapitalgesellschaft oder Genossenschaft

| Modul | Daten | Kz |
|---|---|---|
| Gesellschaft/Vertretung | Sitz, Adresse, gesetzliche Vertreter | 2–30 |
| Register/Kapital | Notar, Register, Rechtsform, Tätigkeitsbeginn, Wirtschaftsjahr, Grund-/Stammkapital | 54–67 |
| Anteilseigner | natürliche/juristische Anteilseigner, Beteiligungsnummer, Kapital, Quote, Treuhand | 68–90 |
| Gründungs- und Umwandlungsvorgang | Bar-/Sachgründung, Einbringung, Anteilstausch, Umwandlung, Bewertung | 91–126 |
| Sonderstrukturen | Betriebsaufspaltung, Komplementärin, atypisch stille Beteiligung | 127–143 |
| Organschaft/Konzern/Steuerbefreiung | Organträger/-gesellschaft, Konzern, Befreiung nach § 5 KStG | 144–164 |
| Gewinn/Lohnsteuer | Vorauszahlungen; Arbeitnehmer und Lohnsteuerstätte | 165–177 |
| Umsatzsteuer | Umsatz, Kleinunternehmer, Steuerbefreiung/Steuersatz, Ist/Soll, USt-IdNr., Bau/Gebäudereinigung | 178–202 |
| OSS/Onlinehandel/Bauabzug | OSS, Webshop/Marktplätze, Freistellungsbescheinigung | 203–223 |
| Beilagen | Gesellschaftsvertrag, Verträge, Treuhand, Organschaft etc. | 224–236 |

### 5.3 Personengesellschaft oder Personengemeinschaft

| Modul | Daten | Kz |
|---|---|---|
| Gesellschaft/Gründung | Gesellschaftsname, Tätigkeit, Gründungsart, Vorinhaber/Vorunternehmen | 2–12, 23–30 |
| Rechtsform/Register | Rechtsform, Rechtsfähigkeit, Tätigkeitsbeginn, Register | 31–39 |
| Vertretung | vertretungsberechtigte natürliche/juristische Personen | 45–54 |
| Empfang/Vollmacht/Konzern | Steuerberatung, Empfangsbevollmächtigung, gemeinsamer Empfangsbevollmächtigter, Konzern | 55–76 |
| Gewinn/Verteilung | Gesellschaftsgewinn, Gewinnermittlung, Aufteilungsschlüssel, abweichendes Wirtschaftsjahr | 77–81 |
| Beteiligte | Identität, Rolle, Art des Beteiligten, Quote, Kapitalanteil, Sonderbetriebsdaten | 82–99, 92–95 |
| Lohnsteuer | Arbeitnehmer, Lohnsteuerstätte | 119–127 |
| Umsatzsteuer | Umsatz, Kleinunternehmer, Steuerbefreiung/Steuersatz, Ist/Soll, USt-IdNr., Bau/Gebäudereinigung | 128–161 |
| OSS/Onlinehandel/Beilagen | OSS, Marktplätze, Verträge und Vollmachten | 162–191 |

### 5.4 Körperschaft nach ausländischem Recht

| Modul | Daten | Kz |
|---|---|---|
| Deutscher Inlandsbezug | Regie-/Lohnarbeit, Subunternehmertätigkeit, Arbeitnehmerüberlassung | 14–17 |
| Zuständigkeit | Zustimmungsvereinbarung, bisherige deutsche Erfassung | 18–21 |
| Einrichtungen/Vertreter | feste/nicht feste deutsche Einrichtungen, Nutzung, ständiger Vertreter | Detailblock vor 56; 56–68 |
| Ausländische Gesellschaft | Gründungsstaat, Vertragsdatum, Rechtsform, Register, Notar | 106–116 |
| Dauer/Kapital | Tätigkeit in Deutschland, Wirtschaftsjahr, Kapital und Währung | 117–120 |
| Anteilseigner | natürliche/juristische Anteilseigner, Quote, Treuhand | 121–132 |
| Auslands-/Sonderstrukturen | ausländische Steuerbehörde, Inlandvermögen, Komplementärin, atypisch still | 145–155 |
| Organschaft/Konzern | Organschaft und Konzern | 156–174 |
| Gewinn/Lohnsteuer | Vorauszahlungen, Arbeitnehmer in Deutschland, Lohnsteuerstätte | 175–187 |
| Umsatzsteuerlicher Leistungsweg | Geschäftsveräusserung, Umsatz, Waren/Leistungen, Abnehmer, Steuerbarkeit, Einfuhr/Lager, Eingangsumsätze | 188–216 |
| Weitere Umsatzsteuer | Kleinunternehmer, Steuerbefreiung/Steuersatz, Ist/Soll, USt-IdNr., Vorsteuervergütung, EORI, Bau/Gebäudereinigung | 217–242 |
| OSS/Onlinehandel/Bauausführungen | OSS, Marktplätze, Bauausführungen/Montagen | 243–263 ff. |
| Beilagen | Gesellschaftsvertrag, Registerauszug, Verträge, Ansässigkeit, Bilanz etc. | 282–300 |

### 5.5 BZSt2: Auslandsbezug nach § 138 Abs. 2 AO

| Modul | Daten | Kz |
|---|---|---|
| Allgemeine Angaben | Person/Firma, Name, Vorname, Rechtsform, Geburtsdatum, Adressart, Anschrift | Adresse 15–17; übrige Angaben ohne Kz ausgewiesen |
| Mitteilungssachverhalt | Negativmeldung; ausländischer Betrieb/Betriebsstätte; ausländische Personen- oder Kapitalgesellschaft; Drittstaat-Gesellschaft | keine Kz ausgewiesen |
| Beteiligungsstruktur | Jede unmittelbare und mittelbare Beteiligung; bei Beteiligungen vollständiger Beteiligtenabschnitt | keine Kz ausgewiesen |
| Sammelmitteilung | Mitteilung durch ausländische Personengesellschaft/Treuhänder für alle inländischen Beteiligten | keine Kz ausgewiesen |
| Mitwirkung | Steuerberater, Bearbeiterkennzeichen, Mandantennummer, Bescheiddatenabholung | 30 |

Die beigefügte XML-Datei ist eine leere BZSt2-Instanz. Sie bestätigt die wiederholbaren Datensätze `gesellschaft`, `beteiligte` und `drittstaatgesellschaft`, enthält aber keine zusätzliche fachliche Feldzuordnung.

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
2. Eine zentrale Mappingtabelle ordnet jedem normierten Feld je Formulartyp die Kz, den technischen Zielpfad, Datentyp, Wiederholungsregel und Auslösebedingung zu.
3. Vor Übergabe validiert eine Regelmatrix die Pflichtfelder und sachverhaltsabhängigen Folgefelder.
4. Die Übertragung erzeugt eine formularspezifische ELSTER- oder BZSt-Datensatzstruktur. Der BZSt2-XML-Entwurf zeigt hierfür bereits die wiederholbaren Bereiche für Gesellschaften, Beteiligte und Drittstaat-Gesellschaften.
5. Anhänge werden als eigenständige Dokumentobjekte mit Bezug zum auslösenden Sachverhalt geführt.

## 8. Offene Validierungspunkte

- Vollständige Fehlerliste der Körperschaft nach ausländischem Recht abrufen und Pflichtmatrix ergänzen.
- Je Formulartyp die technischen XML-/ERiC-Feldbezeichner gegen einen exportierten Musterfall prüfen. Die sichtbare Kz ersetzt keinen technischen Feldpfad.
- Bedingungen für Folgefelder als Entscheidungsregeln dokumentieren, insbesondere Gründungsform, Treuhand, Organschaft, Umsatzsteuer, Bauleistungen, Onlinehandel und Auslandsbezug.
- Höchstzahl und Bearbeitung wiederholbarer Objekte festlegen. Bei mehr als zehn Betriebsstätten verweisen die ELSTER-Formulare auf einen PDF-Anhang.
