# Pflichtfelder: EasyGov-Unternehmensgründung

**Methode:** Live-Inventar EasyGov und ESTV-Formular `mwstanmelden.estv.admin.ch` am 2026-11-15, Testentwürfe ohne Übermittlung, ohne Mandatsdaten.

**Bezug:** Feldkatalog [`formulardaten-roherfassung.md`](formulardaten-roherfassung.md); Zielbild [`Einheitliches-Datenmodell-easygov-unternehmensgruendung.md`](Einheitliches-Datenmodell-easygov-unternehmensgruendung.md).

SharePoint setzt «Erforderlich» nur bei unbedingter Pflicht, die für jeden Datensatz der Zielliste gilt (`sharepoint_required`). Alle übrigen Pflichten laufen über Forms-Branching, analog [`DE/AO/sharepoint-forms/README.md`](../../DE/AO/sharepoint-forms/README.md) Abschnitt C.

## Unbedingte Pflichtfelder (Portal, Tatsachen)

119 Felder. Prozess-Checkboxen (Bestätigung, CAPTCHA) und reine Aktionen sind in der Rohfassung dokumentiert, erscheinen hier nur, soweit sie ein Datenfeld sind.

| Bereich | Schritt | Label | Rechtsformen |
|---|---|---|---|
| gruendung | Vorläufiger Name | Provisorischer Unternehmensname | EU, GmbH, AG, KlG, KmG |
| gruendung | 1. Rechtsform | Rechtsform | EU, GmbH, AG, KlG, KmG |
| gruendung | 3. Tätigkeit | Datum ab | EU, GmbH, AG, KlG, KmG |
| gruendung | 3. Tätigkeit | Umsatzangaben | EU, GmbH, AG, KlG, KmG |
| gruendung | 3. Tätigkeit | Total Angestellte | EU, GmbH, AG, KlG, KmG |
| gruendung | 3. Tätigkeit | Beschäftigungsgrad | EU, GmbH, AG, KlG, KmG |
| gruendung | 3. Tätigkeit | Berufsbezeichnung | EU |
| gruendung | 3. Tätigkeit | Handel mit Produkten | EU |
| gruendung | 3. Tätigkeit | Branche | EU, GmbH, AG, KlG, KmG |
| gruendung | 2. Extern Erledigtes | Sind für das Unternehmen bereits früher Anmeldungen getätigt worden? | EU, GmbH, AG, KlG, KmG |
| gruendung | Digitale Signatur | Digitale Signatur und Bereitschaft zur Vertretung beim Errichtungsakt | GmbH, AG |
| gruendung | Fragen | Staatsangehörigkeit(en) | EU, GmbH, AG, KlG, KmG |
| gruendung | Fragen | Zivilrechtlicher Wohnsitz | EU, GmbH, AG, KlG, KmG |
| gruendung | Fragen | Zivilstand | EU, GmbH, AG, KlG, KmG |
| gruendung | Fragen | Steuerpflicht USA | GmbH, AG |
| gruendung | Personalien | Anrede | EU, GmbH, AG, KlG, KmG |
| gruendung | Personalien | Familienname | EU, GmbH, AG, KlG, KmG |
| gruendung | Personalien | Vorname | EU, GmbH, AG, KlG, KmG |
| gruendung | Personalien | Geburtsdatum | EU, GmbH, AG, KlG, KmG |
| gruendung | Personalien | AHV-Nummer | EU, KlG, KmG |
| gruendung | Wohnadresse Schweiz | E-Mail | GmbH, AG |
| gruendung | Person | Rolle | EU, GmbH, AG, KlG, KmG |
| gruendung | Vertretungsverhältnis/Funktion | Funktion | GmbH, AG |
| gruendung | Vertretungsverhältnis/Funktion | Zeichnungsberechtigung | GmbH, AG |
| gruendung | Gesellschafter KmG | Haftung | KmG |
| gruendung | Geschäftsdomizil | Strasse | EU, GmbH, AG, KlG, KmG |
| gruendung | Geschäftsdomizil | Postleitzahl | EU, GmbH, AG, KlG, KmG |
| gruendung | Geschäftsdomizil | Ort | EU, GmbH, AG, KlG, KmG |
| gruendung | Firma | Unternehmensbezeichnung | EU, GmbH, AG, KlG, KmG |
| gruendung | Firma | Unternehmenszweck | EU, GmbH, AG, KlG, KmG |
| gruendung | Firma | Geschäftsaufnahme / Beginn Geschäftstätigkeit | EU, GmbH, AG, KlG, KmG |
| gruendung | Firma | Geschäftsjahresabschluss jeweils am | EU, GmbH, AG, KlG, KmG |
| hr | 2 Kapital und Anteile GmbH | Stammkapital | GmbH |
| hr | 2 Kapital | Währung | GmbH, AG |
| hr | 2 Kapital und Anteile GmbH | Anzahl Stammanteile total | GmbH |
| hr | 2 Kapital | Liberierungsart | GmbH, AG |
| hr | 2 Kapital und Anteile GmbH | Anzahl Stammanteile pro Gründerin/Gründer | GmbH |
| hr | 2 Kapital und Aktien AG | Aktienkapital | AG |
| hr | 2 Kapital und Aktien AG | Liberierungsumfang | AG |
| hr | 2 Kapital und Aktien AG | Anzahl Namensaktien | AG |
| hr | 2 Kapital und Aktien AG | Anzahl Inhaberaktien | AG |
| hr | 2 Kapital und Aktien AG | Anzahl Namensaktien je Aktionär | AG |
| hr | 2 Kapital und Aktien AG | Anzahl Inhaberaktien je Aktionär | AG |
| hr | 3 Sonstige Vertretungen | Funktion | GmbH |
| hr | 1 Vertretungen | Funktion | EU |
| hr | Vertretungen | Zeichnungsberechtigung | EU, GmbH, AG, KlG, KmG |
| hr | Bestellungen | Anzahl beglaubigter Handelsregisterauszüge nach Publikation | EU, GmbH, AG, KlG, KmG |
| hr | Bestellungen | Anzahl vorzeitig bestellter Auszüge | EU, GmbH, AG, KlG, KmG |
| hr | Diverses | Anmeldungsart | EU |
| hr | Abschliessen | Ich habe meine Angaben geprüft | EU, GmbH, AG, KlG, KmG |
| mwst | Unternehmen | Firmenname | EU, GmbH, AG, KlG, KmG |
| mwst | Unternehmen | Strasse | EU, GmbH, AG, KlG, KmG |
| mwst | Unternehmen | PLZ | EU, GmbH, AG, KlG, KmG |
| mwst | Unternehmen | Ort | EU, GmbH, AG, KlG, KmG |
| mwst | Unternehmen | Telefonnummer | EU, GmbH, AG, KlG, KmG |
| mwst | Unternehmen | Herr/Frau | EU |
| mwst | Unternehmen | Name | EU |
| mwst | Unternehmen | Geburtsdatum | EU |
| mwst | Unternehmen | Staatsbürgerschaft | EU |
| mwst | Unternehmen | Heimatort | EU |
| mwst | Unternehmen | Sozialversicherungsnummer (AHV) | EU |
| mwst | Unternehmen | Haben Sie ein bestehendes Unternehmen übernommen? | EU, GmbH, AG, KlG, KmG |
| mwst | Umsatz | Versandhandel | EU, GmbH, AG, KlG, KmG |
| mwst | Umsatz | Erstes Geschäftsjahr Startdatum | EU, GmbH, AG, KlG, KmG |
| mwst | Umsatz | Erstes Geschäftsjahr Abschlussdatum | EU, GmbH, AG, KlG, KmG |
| mwst | Umsatz | Obligatorische Steuerpflicht per | EU, GmbH, AG, KlG, KmG |
| mwst | Modalitäten | Art der Abrechnung | EU, GmbH, AG, KlG, KmG |
| mwst | Modalitäten | Methode | EU, GmbH, AG, KlG, KmG |
| mwst | Modalitäten | Tätigkeiten | EU, GmbH, AG, KlG, KmG |
| mwst | Kontakt | Telefonnummer | EU, GmbH, AG, KlG, KmG |
| mwst | Zusammenfassung | Bestätigung | EU, GmbH, AG, KlG, KmG |
| mwst | Zusammenfassung | CAPTCHA | EU, GmbH, AG, KlG, KmG |
| ahv | 1 Unternehmensstruktur | Handelsregistereintrag | EU, GmbH, AG, KlG, KmG |
| ahv | 1 Unternehmensstruktur | Verbandszugehörigkeit | EU, GmbH, AG, KlG, KmG |
| ahv | 1 Unternehmensstruktur | Anzahl der Kunden | EU, GmbH, AG, KlG, KmG |
| ahv | 2 Mitarbeitender Inhaber | Zuletzt AHV-Beiträge bezahlt als | EU |
| ahv | 2 Mitarbeitender Inhaber | Mitarbeit im Unternehmen | EU |
| ahv | 2 Mitarbeitender Inhaber | Ihre Rolle | EU |
| ahv | 2 Mitarbeitender Inhaber | Finanzielle Abgeltung Betrag | EU |
| ahv | 2 Mitarbeitender Inhaber | Kurze Beschreibung des unternehmerischen Risikos | EU |
| ahv | 3 Personal und Lohn | Familienangehörige (ohne Ehepartner) Anzahl Personen | EU, GmbH, AG, KlG, KmG |
| ahv | 3 Personal und Lohn | Kinder | EU, GmbH, AG, KlG, KmG |
| ahv | 3 Personal und Lohn | Angestellte Anzahl Personen | EU, GmbH, AG, KlG, KmG |
| ahv | 3 Personal und Lohn | Kinder (Angestellte, für Kinderzulagen) | EU, GmbH, AG, KlG, KmG |
| ahv | 3 Personal und Lohn | UVG Name Versicherung | EU, GmbH, AG, KlG, KmG |
| ahv | 3 Personal und Lohn | BVG Anschluss | EU, GmbH, AG, KlG, KmG |
| ahv | 4 Kontaktadressen | Kontoinhaber/in | EU, GmbH, AG, KlG, KmG |
| ahv | 4 Kontaktadressen | IBAN | EU, GmbH, AG, KlG, KmG |
| ahv | 4 Kontaktadressen | Korrespondenzadresse Name/Firma | EU, GmbH, AG, KlG, KmG |
| ahv | 4 Kontaktadressen | Korrespondenzadresse Strasse | EU, GmbH, AG, KlG, KmG |
| ahv | 4 Kontaktadressen | Korrespondenzadresse PLZ | EU, GmbH, AG, KlG, KmG |
| ahv | 4 Kontaktadressen | Korrespondenzadresse Ort | EU, GmbH, AG, KlG, KmG |
| ahv | 5 Abschliessen | Bestätigung | EU, GmbH, AG, KlG, KmG |
| uvg | 1 Personal und Lohn | Anzahl Mitarbeitende inkl. mitarbeitende Inhaber am Geschäftsaufnahme | EU, GmbH, AG, KlG, KmG |
| uvg | 1 Personal und Lohn | Anzahl Mitarbeitende in ca. 6 Monaten | EU, GmbH, AG, KlG, KmG |
| uvg | 1 Personal und Lohn | Freiwillige UV für Inhaber (unverbindlich) | EU |
| uvg | 1 Personal und Lohn | Lohnsumme aller Mitarbeitenden laufendes Jahr | EU, GmbH, AG, KlG, KmG |
| uvg | 1 Personal und Lohn | Lohnsumme aller Mitarbeitenden Folgejahr | EU, GmbH, AG, KlG, KmG |
| uvg | 2 Diverses | Prämienzahlung | EU, GmbH, AG, KlG, KmG |
| uvg | 2 Diverses | Konto | EU, GmbH, AG, KlG, KmG |
| uvg | 2 Diverses | Ansprechperson Familienname | EU, GmbH, AG, KlG, KmG |
| uvg | 2 Diverses | Ansprechperson Vorname | EU, GmbH, AG, KlG, KmG |
| uvg | 2 Diverses | Ansprechperson Telefon | EU, GmbH, AG, KlG, KmG |
| uvg | 2 Diverses | Korrespondenzadresse Name/Firma | EU, GmbH, AG, KlG, KmG |
| uvg | 2 Diverses | Korrespondenzadresse Strasse | EU, GmbH, AG, KlG, KmG |
| uvg | 2 Diverses | Korrespondenzadresse Hausnummer | EU, GmbH, AG, KlG, KmG |
| uvg | 2 Diverses | Korrespondenzadresse PLZ | EU, GmbH, AG, KlG, KmG |
| uvg | 2 Diverses | Wie weiterfahren? | EU, GmbH, AG, KlG, KmG |
| uvg | 2 Diverses | UVG-Versicherer | EU, GmbH, AG, KlG, KmG |
| uvg | 3 Abschliessen | Bestätigung | EU, GmbH, AG, KlG, KmG |
| gruendung | Fallsteuerung | Fall-ID | EU, GmbH, AG, KlG, KmG |
| hr | Unterlagen | Dokumenttyp | EU, GmbH, AG, KlG, KmG |

## Bedingte Pflichtfelder

74 Felder.

| Bereich | Label | Bedingung | Rechtsformen |
|---|---|---|---|
| gruendung | Mein Beruf | Berufsbezeichnung = Keine der obigen Bezeichnungen trifft zu | EU |
| gruendung | Ja, und zwar | bereits früher Anmeldungen = Ja, und zwar | EU, GmbH, AG, KlG, KmG |
| gruendung | Heimatort erfassen | Staatsangehörigkeit = Schweizer/in oder Schweizer/in mit Doppelbürgerschaft(en) | EU, GmbH, AG, KlG, KmG |
| gruendung | Ausweiskategorie | Ausländer/in und Wohnsitz Schweiz | EU, GmbH, AG, KlG, KmG |
| gruendung | Einreisedatum | Ausländer/in und Wohnsitz Schweiz | EU, GmbH, AG, KlG, KmG |
| gruendung | Staatsangehörigkeit(en) | Ausländer/in | EU, GmbH, AG, KlG, KmG |
| gruendung | Adresssuche | Zivilrechtlicher Wohnsitz = Schweiz | EU, GmbH, AG, KlG, KmG |
| gruendung | Strasse | Zivilrechtlicher Wohnsitz = Schweiz | EU, GmbH, AG, KlG, KmG |
| gruendung | Nummer | Zivilrechtlicher Wohnsitz = Schweiz | EU, GmbH, AG, KlG, KmG |
| gruendung | Adresszusätze | Zivilrechtlicher Wohnsitz = Schweiz | EU, GmbH, AG, KlG, KmG |
| gruendung | Postfach | Zivilrechtlicher Wohnsitz = Schweiz | EU, GmbH, AG, KlG, KmG |
| gruendung | Postleitzahl | Zivilrechtlicher Wohnsitz = Schweiz | EU, GmbH, AG, KlG, KmG |
| gruendung | Ort | Zivilrechtlicher Wohnsitz = Schweiz | EU, GmbH, AG, KlG, KmG |
| gruendung | Politische Gemeinde | Zivilrechtlicher Wohnsitz = Schweiz | EU, GmbH, AG, KlG, KmG |
| gruendung | Telefon | Zivilrechtlicher Wohnsitz = Schweiz | EU, GmbH, AG, KlG, KmG |
| gruendung | Weiteres Telefon | Zivilrechtlicher Wohnsitz = Schweiz | EU, GmbH, AG, KlG, KmG |
| gruendung | Telefax | Zivilrechtlicher Wohnsitz = Schweiz | EU, GmbH, AG, KlG, KmG |
| gruendung | E-Mail | Zivilrechtlicher Wohnsitz = Schweiz | EU, GmbH, AG, KlG, KmG |
| gruendung | Strasse | Zivilrechtlicher Wohnsitz = Ausland | EU, GmbH, AG, KlG, KmG |
| gruendung | Nummer | Zivilrechtlicher Wohnsitz = Ausland | EU, GmbH, AG, KlG, KmG |
| gruendung | Adresszusätze | Zivilrechtlicher Wohnsitz = Ausland | EU, GmbH, AG, KlG, KmG |
| gruendung | Postfach | Zivilrechtlicher Wohnsitz = Ausland | EU, GmbH, AG, KlG, KmG |
| gruendung | Postleitzahl | Zivilrechtlicher Wohnsitz = Ausland | EU, GmbH, AG, KlG, KmG |
| gruendung | Ort | Zivilrechtlicher Wohnsitz = Ausland | EU, GmbH, AG, KlG, KmG |
| gruendung | Land | Zivilrechtlicher Wohnsitz = Ausland | EU, GmbH, AG, KlG, KmG |
| gruendung | Telefon | Zivilrechtlicher Wohnsitz = Ausland | EU, GmbH, AG, KlG, KmG |
| gruendung | Weiteres Telefon | Zivilrechtlicher Wohnsitz = Ausland | EU, GmbH, AG, KlG, KmG |
| gruendung | Telefax | Zivilrechtlicher Wohnsitz = Ausland | EU, GmbH, AG, KlG, KmG |
| gruendung | E-Mail | Zivilrechtlicher Wohnsitz = Ausland | EU, GmbH, AG, KlG, KmG |
| gruendung | Kommanditsumme (in CHF) | Haftung = beschränkt | KmG |
| gruendung | Wie erfolgt die Einlage | Haftung = beschränkt | KmG |
| gruendung | Art der Person | KmG-Kommanditär immer; GmbH/AG wenn Gesellschafter eine juristische Person ist (Portal erfasst das nicht) | GmbH, AG, KmG |
| gruendung | Ist das Firmendomizil in der Schweiz? | Personentyp = juristische Person (Portal: nur KmG-Kommanditär; GmbH/AG Kanzlei) | GmbH, AG, KmG |
| gruendung | Rechtsform | Personentyp = juristische Person (Portal: nur KmG-Kommanditär; GmbH/AG Kanzlei) | GmbH, AG, KmG |
| gruendung | Unternehmensname oder UID | Personentyp = juristische Person (Portal: nur KmG-Kommanditär; GmbH/AG Kanzlei) | GmbH, AG, KmG |
| hr | Hauptsprache | Firma in weiteren Sprachen = Ja | EU, GmbH, AG, KlG, KmG |
| hr | Sprache | Firma in weiteren Sprachen = Ja | EU, GmbH, AG, KlG, KmG |
| hr | Übersetzte Unternehmensbezeichnung | Firma in weiteren Sprachen = Ja | EU, GmbH, AG, KlG, KmG |
| hr | Notar Familienname | elektronische Gründung | GmbH, AG |
| hr | Notar Vorname | elektronische Gründung | GmbH, AG |
| hr | Notar Kanton | elektronische Gründung | GmbH, AG |
| hr | Anrede | Papierweg | AG |
| hr | Name / Firma | Papierweg | AG |
| hr | Adresse | Papierweg | AG |
| mwst | Lieferungen und Dienstleistungen im Inland inkl. Export | gültige Daten erstes Geschäftsjahr | EU, GmbH, AG, KlG, KmG |
| mwst | Lieferungen und Dienstleistungen ausserhalb der Schweiz, ohne ausgenommene Leistungen | gültige Daten erstes Geschäftsjahr | EU, GmbH, AG, KlG, KmG |
| mwst | Von der Steuer ausgenommene Leistungen und andere Mittelflüsse | gültige Daten erstes Geschäftsjahr | EU, GmbH, AG, KlG, KmG |
| mwst | Lieferungen und Dienstleistungen im Inland inkl. Export | gültige Daten erstes Geschäftsjahr | EU, GmbH, AG, KlG, KmG |
| mwst | Lieferungen und Dienstleistungen ausserhalb der Schweiz, ohne ausgenommene Leistungen | gültige Daten erstes Geschäftsjahr | EU, GmbH, AG, KlG, KmG |
| mwst | Von der Steuer ausgenommene Leistungen und andere Mittelflüsse | gültige Daten erstes Geschäftsjahr | EU, GmbH, AG, KlG, KmG |
| mwst | Freiwillige Unterstellung Art. 11 MWSTG | nur unter der Umsatzschwelle sichtbar | EU, GmbH, AG, KlG, KmG |
| mwst | Anderes Datum | Obligatorische Steuerpflicht per = Anderes Datum | EU, GmbH, AG, KlG, KmG |
| ahv | Unternehmensname oder UID | Handelsregistereintrag = eingetragen | EU, GmbH, AG, KlG, KmG |
| ahv | Beitrittsdatum | Verbandszugehörigkeit = Mitgliedschaft besteht | EU, GmbH, AG, KlG, KmG |
| ahv | bei Verband | Verbandszugehörigkeit = Mitgliedschaft besteht | EU, GmbH, AG, KlG, KmG |
| ahv | Vorschlagsliste Verbände/AK | Verbandszugehörigkeit = Mitgliedschaft geplant | EU, GmbH, AG, KlG, KmG |
| ahv | durch | Das Unternehmen = von Vorgänger übernommen | EU, GmbH, AG, KlG, KmG |
| ahv | Name | Das Unternehmen = von Vorgänger übernommen | EU, GmbH, AG, KlG, KmG |
| ahv | Abrechnungs-Nr. | Das Unternehmen = von Vorgänger übernommen | EU, GmbH, AG, KlG, KmG |
| ahv | Auftraggeber (Name, Adresse) | Agent/Vertreter = Ja | EU, GmbH, AG, KlG, KmG |
| ahv | Ausgleichskasse Name | Zuletzt AHV-Beiträge mit Ausgleichskasse | EU |
| ahv | Von | Zuletzt AHV-Beiträge mit Ausgleichskasse | EU |
| ahv | Bis | Zuletzt AHV-Beiträge mit Ausgleichskasse | EU |
| ahv | Name | Einzelperson Verbands-AK = Ja | EU |
| ahv | Ausgleichskasse | Einzelperson Verbands-AK = Ja | EU |
| ahv | Nebenerwerb / Haupterwerb Bezeichnung | Haupterwerb optional bzw. Nebenerwerb Pflicht für die jeweils andere Tätigkeit | EU |
| ahv | Name Arbeitgeber | Angaben zum anderen Erwerb | EU |
| ahv | Adresse | Angaben zum anderen Erwerb | EU |
| ahv | PLZ Ort | Angaben zum anderen Erwerb | EU |
| ahv | Jährliche Lohnsumme Angestellte | Anzahl Angestellte > 0 | EU, GmbH, AG, KlG, KmG |
| ahv | BVG Name Versicherung | BVG Anschluss = Ja | EU, GmbH, AG, KlG, KmG |
| ahv | Begründung | BVG Anschluss = Nein | EU, GmbH, AG, KlG, KmG |
| uvg | Kontoinhaber/in | Konto = Bank- oder Postkonto | EU, GmbH, AG, KlG, KmG |
| uvg | IBAN | Konto = Bank- oder Postkonto | EU, GmbH, AG, KlG, KmG |

## Nicht als Forms-Pflicht abbilden

- Ergebnisfelder der Meldepflichten-Matrix (`result_hr` / `result_mwst` / `result_ahv` / `result_uvg`) füllt die Kanzlei nach Prüfung.
- «Mindestens zwei Gesellschafter» (KlG), «mindestens ein VR» (AG), «mindestens ein unbeschränkt und ein beschränkt Haftender» (KmG) sind Mengenvorgaben über `2_Personen`.
- Saldosteuersatz-Anteile: Portalpflicht dokumentiert, Feld im Inventar nicht gefunden (siehe [`luecken-und-offene-punkte.md`](luecken-und-offene-punkte.md)).

