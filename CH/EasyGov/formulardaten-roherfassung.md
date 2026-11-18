# Formulardaten: Rohfassung EasyGov-Unternehmensgründung

Vollständiger Feldkatalog der bei EasyGov.swiss und `mwstanmelden.estv.admin.ch` erhobenen Angaben.

**Stand:** 2026-11-15

**Quelle:** EasyGov.swiss (Unternehmensgründung, HR, AHV, UVG) und mwstanmelden.estv.admin.ch, Live-Inventar 15.11.2026 an Testentwürfen. Keine Mandatsdaten.

**Zugehöriges Zielbild:** [`Einheitliches-Datenmodell-easygov-unternehmensgruendung.md`](Einheitliches-Datenmodell-easygov-unternehmensgruendung.md). Maschinenlesbar: [`felder.json`](felder.json) (Schema [`felder.schema.json`](felder.schema.json)).

Labels folgen dem Live-Inventar vom 15.11.2026. Keine Mandats- oder Testdaten.

Anzahl Portal- und Kanzleifelder: **333**.

## 1. Gründungsablauf EasyGov (Meldepflichten und Basisdaten)

### vorlaeufiger_name — Vorläufiger Name

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.vorlaeufiger_name.provisorischer_name` | Provisorischer Unternehmensname | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |

### meldepflichten — 1. Rechtsform

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.meldepflichten.rechtsform` | Rechtsform | choice | unbedingt | EU, GmbH, AG, KlG, KmG | rechtsformen |  |

### meldepflichten — 3. Tätigkeit

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.meldepflichten.datum_ab` | Datum ab | date | unbedingt | EU, GmbH, AG, KlG, KmG | — | Beginn der Tätigkeit. |
| `gruendung.meldepflichten.umsatzangaben` | Umsatzangaben | choice | unbedingt | EU, GmbH, AG, KlG, KmG | umsatzangaben | Schwelle HR und MWST gemeinsam seit 1.1.2010; Selbstüberwachung. |
| `gruendung.meldepflichten.total_angestellte` | Total Angestellte | number | unbedingt | EU, GmbH, AG, KlG, KmG | — | Inklusive Inhaber, Köpfe nicht FTE. Ohne Personal = 1. |
| `gruendung.meldepflichten.beschaeftigungsgrad` | Beschäftigungsgrad | choice | unbedingt | EU, GmbH, AG, KlG, KmG | beschaeftigungsgrad |  |
| `gruendung.meldepflichten.berufsbezeichnung` | Berufsbezeichnung | choice | unbedingt | EU | berufsbezeichnungen | Nur Einzelunternehmen. Akkordeon, keine Suche. Hinweis Bewilligungspflicht nur Info. |
| `gruendung.meldepflichten.beruf_freitext` | Mein Beruf | text | bedingt | EU | — | Berufsbezeichnung = Keine der obigen Bezeichnungen trifft zu |
| `gruendung.meldepflichten.handel_mit_produkten` | Handel mit Produkten | choice | unbedingt | EU | ja_nein | Freier Beruf mit Warenhandel wird ab CHF 100'000 HR-pflichtig. |
| `gruendung.meldepflichten.branche` | Branche | multichoice | unbedingt | EU, GmbH, AG, KlG, KmG | branchen | Mehrfachauswahl Kategorien und Unterwerte. |

### meldepflichten — 2. Extern Erledigtes

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.meldepflichten.extern_status` | Sind für das Unternehmen bereits früher Anmeldungen getätigt worden? | choice | unbedingt | EU, GmbH, AG, KlG, KmG | extern_erledigtes_status | Keine weiteren Felder; Resultat unverändert. |
| `gruendung.meldepflichten.extern_arten` | Ja, und zwar | multichoice | bedingt | EU, GmbH, AG, KlG, KmG | extern_erledigtes_arten | bereits früher Anmeldungen = Ja, und zwar |

### meldepflichten — Digitale Signatur

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.meldepflichten.digitale_signatur` | Digitale Signatur und Bereitschaft zur Vertretung beim Errichtungsakt | choice | unbedingt | GmbH, AG | digitale_signatur | Elektronisch: EasyGov erzeugt Auftragsdokument für Notar. MWST/AHV/UVG/Transparenzregister erst nach HR-Eintrag. |

### meldepflichten — 4. Resultat

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.meldepflichten.resultat_hr` | Resultat Handelsregister | choice | ergebnis | EU, GmbH, AG, KlG, KmG | meldepflicht_status | Von EasyGov angezeigt; Kanzlei prüft gegen Meldepflichten-Matrix. |
| `gruendung.meldepflichten.resultat_mwst` | Resultat MWST | choice | ergebnis | EU, GmbH, AG, KlG, KmG | meldepflicht_status |  |
| `gruendung.meldepflichten.resultat_ahv` | Resultat AHV/IV/EO/ALV | choice | ergebnis | EU, GmbH, AG, KlG, KmG | meldepflicht_status |  |
| `gruendung.meldepflichten.resultat_uvg` | Resultat UVG | choice | ergebnis | EU, GmbH, AG, KlG, KmG | meldepflicht_status | EasyGov nennt Suva oder Privatversicherer nach Tätigkeit. |

### basisdaten — Definitive Rechtsform

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.basis.definitive_rechtsform` | Definitive Rechtsform | anzeige | unbedingt | EU, GmbH, AG, KlG, KmG | — | Bestätigung der bereits gewählten Rechtsform, danach nicht mehr änderbar. Keine eigene Spalte. |

### basisdaten — Fragen

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.basis.staatsangehoerigkeit` | Staatsangehörigkeit(en) | choice | unbedingt | EU, GmbH, AG, KlG, KmG | staatsangehoerigkeit_kategorie | Ausländer/in: Hinweis Arbeitsbewilligung. GmbH/AG: Hinweis Bewilligung/Meldung nur für Ausweise B/S/F. |
| `gruendung.basis.wohnsitz` | Zivilrechtlicher Wohnsitz | choice | unbedingt | EU, GmbH, AG, KlG, KmG | zivilrechtlicher_wohnsitz |  |
| `gruendung.basis.zivilstand` | Zivilstand | choice | unbedingt | EU, GmbH, AG, KlG, KmG | zivilstand |  |
| `gruendung.basis.steuerpflicht_usa` | Steuerpflicht USA | choice | unbedingt | GmbH, AG | ja_nein | Tooltip US-Bürger/Greencard. |

### basisdaten — Personalien

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.basis.anrede` | Anrede | choice | unbedingt | EU, GmbH, AG, KlG, KmG | anrede |  |
| `gruendung.basis.titel` | Titel | text | optional | EU, GmbH, AG, KlG, KmG | — | Akademischer Titel; Nachweis ggf. nötig. |
| `gruendung.basis.familienname` | Familienname | text | unbedingt | EU, GmbH, AG, KlG, KmG | — | Schreibweise gemäss Ausweis. |
| `gruendung.basis.lediger_name` | Lediger Name | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `gruendung.basis.vorname` | Vorname | text | unbedingt | EU, GmbH, AG, KlG, KmG | — | Ein Vorname / Rufname. |
| `gruendung.basis.weitere_vornamen` | Weitere Vornamen | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `gruendung.basis.geburtsdatum` | Geburtsdatum | date | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `gruendung.basis.ahv_nummer` | AHV-Nummer | text | unbedingt | EU, KlG, KmG | — | Format 756.NNNN.NNNN.NN. Ohne Nummer: 756.9999.9999.99. Nicht in GmbH/AG-Basisdaten. KlG je Gesellschafter. |

### basisdaten — Heimatort(e)

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.basis.heimatort` | Heimatort erfassen | lookup | bedingt | EU, GmbH, AG, KlG, KmG | — | Staatsangehörigkeit = Schweizer/in oder Schweizer/in mit Doppelbürgerschaft(en) |

### basisdaten — Ausländer Wohnsitz CH

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.basis.ausweiskategorie` | Ausweiskategorie | choice | bedingt | EU, GmbH, AG, KlG, KmG | ausweiskategorien | Ausländer/in und Wohnsitz Schweiz |
| `gruendung.basis.einreisedatum` | Einreisedatum | date | bedingt | EU, GmbH, AG, KlG, KmG | — | Ausländer/in und Wohnsitz Schweiz |

### basisdaten — Ausländer

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.basis.staatsangehoerigkeit_staaten` | Staatsangehörigkeit(en) | lookup | bedingt | EU, GmbH, AG, KlG, KmG | — | Ausländer/in |

### basisdaten — Wohnadresse Schweiz

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.basis.wohnsitz_ch.adresssuche` | Adresssuche | lookup | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Schweiz |
| `gruendung.basis.wohnsitz_ch.strasse` | Strasse | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Schweiz |
| `gruendung.basis.wohnsitz_ch.nummer` | Nummer | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Schweiz |
| `gruendung.basis.wohnsitz_ch.adresszusaetze` | Adresszusätze | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Schweiz |
| `gruendung.basis.wohnsitz_ch.postfach` | Postfach | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Schweiz |
| `gruendung.basis.wohnsitz_ch.plz` | Postleitzahl | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Schweiz |
| `gruendung.basis.wohnsitz_ch.ort` | Ort | lookup | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Schweiz |
| `gruendung.basis.wohnsitz_ch.politische_gemeinde` | Politische Gemeinde | anzeige | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Schweiz |
| `gruendung.basis.wohnsitz_ch.telefon` | Telefon | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Schweiz |
| `gruendung.basis.wohnsitz_ch.weiteres_telefon` | Weiteres Telefon | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Schweiz |
| `gruendung.basis.wohnsitz_ch.telefax` | Telefax | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Schweiz |
| `gruendung.basis.wohnsitz_ch.email` | E-Mail | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Schweiz |
| `gruendung.basis.wohnsitz_email_pflicht_kapg` | E-Mail | text | unbedingt | GmbH, AG | — | Bei GmbH/AG Pflicht; bei EU optional. |

### basisdaten — Wohnsitz Ausland

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.basis.wohnsitz_ausland.strasse` | Strasse | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Ausland |
| `gruendung.basis.wohnsitz_ausland.nummer` | Nummer | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Ausland |
| `gruendung.basis.wohnsitz_ausland.adresszusaetze` | Adresszusätze | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Ausland |
| `gruendung.basis.wohnsitz_ausland.postfach` | Postfach | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Ausland |
| `gruendung.basis.wohnsitz_ausland.plz` | Postleitzahl | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Ausland |
| `gruendung.basis.wohnsitz_ausland.ort` | Ort | lookup | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Ausland |
| `gruendung.basis.wohnsitz_ausland.land` | Land | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Ausland |
| `gruendung.basis.wohnsitz_ausland.telefon` | Telefon | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Ausland |
| `gruendung.basis.wohnsitz_ausland.weiteres_telefon` | Weiteres Telefon | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Ausland |
| `gruendung.basis.wohnsitz_ausland.telefax` | Telefax | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Ausland |
| `gruendung.basis.wohnsitz_ausland.email` | E-Mail | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Ausland |
| `gruendung.basis.wohnsitz_ausland.hinweise` | Hinweise Wohnsitz Ausland | anzeige | optional | EU, GmbH, AG, KlG, KmG | — | Zivilrechtlicher Wohnsitz = Ausland |

### basisdaten — Person

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.basis.rolle` | Rolle | choice | unbedingt | EU, GmbH, AG, KlG, KmG | funktionen | Hauptgründer = Kontaktperson. Weitere Gründer in HR-Anmeldung (GmbH/AG). KlG mindestens 2 natürliche Personen. KmG mindestens 1 unbeschränkt + 1 beschränkt. |

### basisdaten — Vertretungsverhältnis/Funktion

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.basis.funktion` | Funktion | choice | unbedingt | GmbH, AG | funktionen |  |
| `gruendung.basis.zeichnungsberechtigung` | Zeichnungsberechtigung | choice | unbedingt | GmbH, AG | zeichnungsberechtigung |  |
| `gruendung.basis.beschraenkt_hauptsitz` | Beschränkt auf den Hauptsitz | boolean | optional | GmbH, AG | — | Relevant bei Zweigniederlassungen. |

### basisdaten — Gesellschafter KmG

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.kmg.haftung` | Haftung | choice | unbedingt | KmG | haftung_kmg |  |
| `gruendung.kmg.kommanditsumme` | Kommanditsumme (in CHF) | number | bedingt | KmG | — | Haftung = beschränkt |
| `gruendung.kmg.einlageart` | Wie erfolgt die Einlage | choice | bedingt | KmG | einlageart_kmg | Haftung = beschränkt |
| `gruendung.kmg.personentyp` | Art der Person | choice | bedingt | GmbH, AG, KmG | personentyp | KmG-Kommanditär immer; GmbH/AG wenn Gesellschafter eine juristische Person ist (Portal erfasst das nicht) |

### basisdaten — Juristische Person KmG

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.kmg.jp_domizil_ch` | Ist das Firmendomizil in der Schweiz? | choice | bedingt | GmbH, AG, KmG | ja_nein | Personentyp = juristische Person (Portal: nur KmG-Kommanditär; GmbH/AG Kanzlei) |
| `gruendung.kmg.jp_rechtsform` | Rechtsform | choice | bedingt | GmbH, AG, KmG | rechtsformen_juristische_person | Personentyp = juristische Person (Portal: nur KmG-Kommanditär; GmbH/AG Kanzlei) |
| `gruendung.kmg.jp_suche` | Unternehmensname oder UID | text | bedingt | GmbH, AG, KmG | — | Personentyp = juristische Person (Portal: nur KmG-Kommanditär; GmbH/AG Kanzlei) |

### basisdaten — Geschäftsdomizil

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.firma.adressvorlage` | Adressvorlage | choice | optional | EU, GmbH, AG, KlG, KmG | adressvorlage |  |
| `gruendung.firma.co` | c/o | text | optional | EU, GmbH, AG, KlG, KmG | — | Bei fehlendem eigenem Domizil; Domizilhaltererklärung nötig. |
| `gruendung.firma.domizil.adresssuche` | Adresssuche | lookup | optional | EU, GmbH, AG, KlG, KmG | — | Optional; Autocomplete. |
| `gruendung.firma.domizil.strasse` | Strasse | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `gruendung.firma.domizil.nummer` | Nummer | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `gruendung.firma.domizil.adresszusaetze` | Adresszusätze | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `gruendung.firma.domizil.postfach` | Postfach | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `gruendung.firma.domizil.plz` | Postleitzahl | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `gruendung.firma.domizil.ort` | Ort | lookup | unbedingt | EU, GmbH, AG, KlG, KmG | — | Combobox/Autocomplete; Ort (PLZ) Gemeinde, Kanton. |
| `gruendung.firma.domizil.politische_gemeinde` | Politische Gemeinde | anzeige | unbedingt | EU, GmbH, AG, KlG, KmG | — | Wird automatisch aus der PLZ/Ort-Auswahl gesetzt. |
| `gruendung.firma.domizil.telefon` | Telefon | text | optional | EU, GmbH, AG, KlG, KmG | — | Format +41..., ohne Leerzeichen. |
| `gruendung.firma.domizil.weiteres_telefon` | Weiteres Telefon | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `gruendung.firma.domizil.telefax` | Telefax | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `gruendung.firma.domizil.email` | E-Mail | text | optional | EU, GmbH, AG, KlG, KmG | — |  |

### basisdaten — Firma

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.firma.bezeichnung` | Unternehmensbezeichnung | text | unbedingt | EU, GmbH, AG, KlG, KmG | — | Einzelunternehmen: muss Familiennamen enthalten. Prüfung zeigt zuständiges HR-Amt (GmbH). |
| `gruendung.firma.pruefung_grundregeln` | Grundregeln | aktion | unbedingt | EU | — | Pflicht-Button im Portal, kein Datenwert. |
| `gruendung.firma.pruefung_konflikte` | Konflikte bestehende Unternehmen | aktion | unbedingt | EU | — | Pflicht-Button im Portal. |
| `gruendung.firma.pruefung_marken` | Marken | aktion | optional | EU | — | Empfohlen. |
| `gruendung.firma.pruefung_webdomain` | Webdomain | aktion | optional | EU | — |  |
| `gruendung.firma.zweck` | Unternehmenszweck | note | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `gruendung.firma.branche_anzeige` | Branche | anzeige | unbedingt | EU, GmbH, AG, KlG, KmG | branchen | Anzeige mit Bearbeiten; Wert aus Meldepflichten, keine zweite Spalte. |
| `gruendung.firma.geschaeftsaufnahme` | Geschäftsaufnahme / Beginn Geschäftstätigkeit | date | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `gruendung.firma.geschaeftsjahresende` | Geschäftsjahresabschluss jeweils am | text | unbedingt | EU, GmbH, AG, KlG, KmG | — | Format TT.MM. |
| `gruendung.firma.hr_amt` | Zuständiges Handelsregisteramt | anzeige | optional | GmbH, AG | — | Wird bei der Firmenprüfung angezeigt. |

### basisdaten — Weitere Geschäftslokale

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `gruendung.firma.weitere_lokale` | Weitere Geschäftslokale | note | optional | EU, GmbH, AG, KlG, KmG | — | Optional erfassen. Selbständige Zweigniederlassung braucht eigenen HR-Eintrag. |

### kanzlei — Fallsteuerung

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `system.fall.case_id` | Fall-ID | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `system.fall.access_code` | Zugangscode | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `system.fall.status` | Fallstatus | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `system.fall.crm` | CRM-Referenz | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `system.fall.notiz` | Persönliche Bearbeitungsnotiz | note | optional | EU, GmbH, AG, KlG, KmG | — |  |

### kanzlei — Personen

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `system.person.display_label` | Anzeigelabel | text | optional | EU, GmbH, AG, KlG, KmG | — |  |

### kanzlei — Technische Mindestfelder

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `system.min.case_id` | case_id | lookup | unbedingt | EU, GmbH, AG, KlG, KmG | — | Lookup auf 0_Fallsteuerung.case_id, analog den übrigen Folgelisten. |
| `system.min.field_key` | field_key | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `system.min.field_label` | field_label | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `system.min.data_type` | data_type | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `system.min.required_status` | required_status | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `system.min.value` | value | note | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `system.min.source` | source | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `system.min.verification_date` | verification_date | date | optional | EU, GmbH, AG, KlG, KmG | — |  |

### kanzlei — Eingang Fehler

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `system.fehler.form_no` | form_no | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `system.fehler.case_id_raw` | case_id_raw | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `system.fehler.reason` | reason | note | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `system.fehler.payload` | payload | note | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `system.fehler.status` | status | text | optional | EU, GmbH, AG, KlG, KmG | — |  |

## 2. Handelsregister-Anmeldung

### hr-kapitalgesellschaft — 1 Gründerinnen/Gründer

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `hr.kapg.gruender_typ` | Natürliche Person erfassen | aktion | unbedingt | GmbH, AG | — | Portalaktion. EasyGov erfasst keine juristische Person als GmbH/AG-Gesellschafter. Kanzlei: person_type in 2_Personen. |

### hr-gmbh — 2 Kapital und Anteile GmbH

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `hr.kapg.stammkapital` | Stammkapital | number | unbedingt | GmbH | — | Mindest-Stammkapital CHF 20'000, voll liberiert. Nennwert > 0 (unter CHF 100 möglich). Separates Nennwertfeld par_value in 3_Kapital (nicht in EasyGov). |
| `hr.gmbh.anzahl_stammanteile` | Anzahl Stammanteile total | number | unbedingt | GmbH | — | Jede/r Gesellschafter/in mindestens 1 Stammanteil. |
| `hr.gmbh.anteile_pro_gruender` | Anzahl Stammanteile pro Gründerin/Gründer | number | unbedingt | GmbH | — |  |

### hr-kapitalgesellschaft — 2 Kapital

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `hr.kapg.waehrung` | Währung | choice | unbedingt | GmbH, AG | waehrungen | Fremdwährung zulässig wenn wesentlich; GmbH Gegenwert >= CHF 20'000. |
| `hr.kapg.liberierungsart` | Liberierungsart | multichoice | unbedingt | GmbH, AG | liberierungsart | Checkboxen, kombinierbar. Sachübernahme im Portal nicht sichtbar; Werteliste enthält den Wert für die Kanzlei-Erhebung. |
| `hr.kapg.bemerkungen_kapital` | Bemerkungen zu Kapital und Stammanteilen / Aktien | note | optional | GmbH, AG | — |  |

### hr-ag — 2 Kapital und Aktien AG

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `hr.ag.aktienkapital` | Aktienkapital | number | unbedingt | AG | — |  |
| `hr.ag.liberierungsumfang` | Liberierungsumfang | number | unbedingt | AG | — | CHF, mindestens 20 % bzw. CHF 50'000. |
| `hr.ag.kapitalband_unten` | Kapitalband untere Grenze | number | optional | AG | — |  |
| `hr.ag.kapitalband_oben` | Kapitalband obere Grenze | number | optional | AG | — |  |
| `hr.ag.kapitalband_jahre` | Kapitalband Dauer | number | optional | AG | — | Maximal 5 Jahre. |
| `hr.ag.namensaktien_total` | Anzahl Namensaktien | number | unbedingt | AG | — | Gesamt und je Aktionär. Keine Stimmrechtsaktien, keine Partizipationsscheine. Nennwert: Spalte par_value in 3_Kapital (nicht in EasyGov). |
| `hr.ag.inhaberaktien_total` | Anzahl Inhaberaktien | number | unbedingt | AG | — |  |
| `hr.ag.namensaktien_je` | Anzahl Namensaktien je Aktionär | number | unbedingt | AG | — |  |
| `hr.ag.inhaberaktien_je` | Anzahl Inhaberaktien je Aktionär | number | unbedingt | AG | — |  |

### hr-ag — 3 Sonstige Vertretungen

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `hr.ag.min_verwaltungsrat` | Mindestens ein Mitglied des Verwaltungsrats | anzeige | unbedingt | AG | — | Mengenpflicht über Datensätze in 2_Personen, keine einzelne Spalte. |

### hr-gmbh — 3 Sonstige Vertretungen

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `hr.vertretung.funktion_gmbh` | Funktion | choice | unbedingt | GmbH | funktionen |  |

### hr-eu — 1 Vertretungen

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `hr.vertretung.funktion_eu` | Funktion | choice | unbedingt | EU | funktionen | Inhaber hat immer Einzelunterschrift. Weitere ständige Vertreter optional. |

### hr — Vertretungen

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `hr.vertretung.zeichnungsberechtigung` | Zeichnungsberechtigung | choice | unbedingt | EU, GmbH, AG, KlG, KmG | zeichnungsberechtigung |  |

### hr — Diverses

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `hr.diverses.mwst_id` | Mehrwertsteuer-ID | text | optional | EU, GmbH, AG, KlG, KmG | — | Format CHE-000.000.000. |
| `hr.diverses.firma_weitere_sprachen` | Firma in weiteren Sprachen | boolean | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `hr.diverses.hauptsprache` | Hauptsprache | choice | bedingt | EU, GmbH, AG, KlG, KmG | sprachen | Firma in weiteren Sprachen = Ja |
| `hr.diverses.sprache` | Sprache | choice | bedingt | EU, GmbH, AG, KlG, KmG | sprachen | Firma in weiteren Sprachen = Ja |
| `hr.diverses.uebersetzte_bezeichnung` | Übersetzte Unternehmensbezeichnung | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Firma in weiteren Sprachen = Ja |
| `hr.diverses.bemerkungen` | Bemerkungen | note | optional | EU, GmbH, AG, KlG, KmG | — |  |

### hr-kapitalgesellschaft — Notarwahl

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `hr.diverses.notar_suche_name` | Notar Familienname | text | bedingt | GmbH, AG | — | elektronische Gründung |
| `hr.diverses.notar_suche_vorname` | Notar Vorname | text | bedingt | GmbH, AG | — | elektronische Gründung |
| `hr.diverses.notar_kanton` | Notar Kanton | choice | bedingt | GmbH, AG | kantone | elektronische Gründung |
| `hr.diverses.notar_nicht_gefunden` | keine Notarin gefunden, Gründung auf dem Papierweg | boolean | optional | GmbH, AG | — | elektronische Gründung |
| `hr.diverses.bemerkungen_notar` | Bemerkungen an Notar | note | optional | GmbH, AG | — |  |

### hr-ag — Notar Papierweg

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `hr.diverses.notar_papier_anrede` | Anrede | choice | bedingt | AG | anrede | Papierweg |
| `hr.diverses.notar_papier_name` | Name / Firma | text | bedingt | AG | — | Papierweg |
| `hr.diverses.notar_papier_vorname` | Vorname | text | optional | AG | — | Papierweg |
| `hr.diverses.notar_papier_adresse` | Adresse | note | bedingt | AG | — | Papierweg |
| `hr.diverses.notar_papier_telefon` | Telefon | text | optional | AG | — | Papierweg |
| `hr.diverses.notar_papier_email` | E-Mail | text | optional | AG | — | Papierweg |

### hr — Bestellungen

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `hr.diverses.anzahl_auszuege` | Anzahl beglaubigter Handelsregisterauszüge nach Publikation | number | unbedingt | EU, GmbH, AG, KlG, KmG | — | 0–10, kostenpflichtig, kantonal. EU-Gebühr laut EasyGov CHF 180–300, allgemein CHF 120–600. |
| `hr.diverses.anzahl_vorzeitig` | Anzahl vorzeitig bestellter Auszüge | number | unbedingt | EU, GmbH, AG, KlG, KmG | — | 0–10, Kosten zusätzlich. |

### hr-eu — Diverses

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `hr.diverses.anmeldungsart` | Anmeldungsart | choice | unbedingt | EU | anmeldungsart_hr |  |

### hr — Abschliessen

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `hr.diverses.bestaetigung` | Ich habe meine Angaben geprüft | boolean | unbedingt | EU, GmbH, AG, KlG, KmG | — | Danach keine Korrektur. Prozessfeld, nicht als Mandanten-Stammdatum führen. |

### hr-klg-kmg — Unterzeichnung

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `hr.klg.unterschrift_beglaubigung` | Persönliche Unterschrift und Beglaubigung je Gesellschafter | anzeige | unbedingt | KlG, KmG | — | Urkundsperson; Ausweis Pass/ID, kein Führerausweis. Original per Post. KlG/KmG ohne Notar. Dokumenttyp in Liste 8. |

### kanzlei — Anteile

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `system.anteile.person_label` | Gesellschafter Anzeigelabel | lookup | unbedingt | GmbH, AG | — |  |

### kanzlei — Unterlagen

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `system.unterlagen.typ` | Dokumenttyp | choice | unbedingt | EU, GmbH, AG, KlG, KmG | dokumenttypen |  |
| `system.unterlagen.hinweis` | Hinweis | note | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `system.unterlagen.file_link` | Link zur Datei (falls extern abgelegt) | url | optional | EU, GmbH, AG, KlG, KmG | — | Hyperlink, analog DE/AO file_link. Nicht aus einer Forms-Upload-Frage; Flow oder Kanzlei. |

### kanzlei — Notar / Gesellschaftsvertrag

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `kanzlei.hr.statuten` | Statuten / Gesellschaftsvertrag | note | nicht_erfasst | GmbH, AG | — | EasyGov fragt Statuten nicht ab. Wortlaut oder Hinweis der Kanzlei/des Notars, keine Rechtswürdigung. Datei weiterhin über 8_Unterlagen. |

### kanzlei — Revision

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `kanzlei.hr.revisionsstelle` | Revisionsstelle (Name) | text | nicht_erfasst | GmbH, AG | — | Nicht in EasyGov. Name der Revisionsstelle, falls gewählt. |
| `kanzlei.hr.opting_out` | Opting-out | choice | nicht_erfasst | GmbH, AG | ja_nein | Nicht in EasyGov. Ja/Nein-Tatsache, keine Prüfung der Zulässigkeit. |

### kanzlei — Statutenangaben

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `kanzlei.hr.vinkulierung` | Vinkulierung | choice | nicht_erfasst | GmbH, AG | ja_nein | Nicht in EasyGov. Ob Vinkulierung vorgesehen ist; keine rechtliche Würdigung. |
| `kanzlei.hr.nachschuss` | Nachschusspflicht | choice | nicht_erfasst | GmbH, AG | ja_nein | Nicht in EasyGov. Ob Nachschusspflicht vorgesehen ist. |
| `kanzlei.hr.nebenleistung` | Nebenleistungspflicht | choice | nicht_erfasst | GmbH, AG | ja_nein | Nicht in EasyGov. Ob Nebenleistungspflicht vorgesehen ist. |
| `kanzlei.hr.publikationsorgan` | Publikationsorgan | text | nicht_erfasst | GmbH, AG | — | Nicht in EasyGov. Bezeichnung des Publikationsorgans. |

### kanzlei — Kapitaleinzahlung

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `kanzlei.kapital.bank` | Bank | text | nicht_erfasst | GmbH, AG | — | Nicht in EasyGov. Bank der Kapitaleinzahlung. |
| `kanzlei.kapital.konto_iban` | Konto oder IBAN | text | nicht_erfasst | GmbH, AG | — | Nicht in EasyGov. Konto oder IBAN der Kapitaleinzahlung. |
| `kanzlei.kapital.einzahlungsdatum` | Datum Kapitaleinzahlung | date | nicht_erfasst | GmbH, AG | — | Nicht in EasyGov. |

### kanzlei — Kapital

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `kanzlei.kapital.nennwert` | Nennwert | number | nicht_erfasst | GmbH, AG | — | Nicht in EasyGov; dort implizit Kapital/Anzahl. Keine Stimmrechtsaktien, keine Partizipationsscheine. |

## 3. MWST-Anmeldung (ESTV)

### estv-mwst — Unternehmen

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `mwst.unternehmen.firmenname` | Firmenname | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.unternehmen.co` | c/o | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.unternehmen.strasse` | Strasse | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.unternehmen.nr` | Nr | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.unternehmen.plz` | PLZ | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.unternehmen.ort` | Ort | lookup | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.unternehmen.postfach` | Postfach hinzufügen | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.unternehmen.telefon` | Telefonnummer | text | unbedingt | EU, GmbH, AG, KlG, KmG | — | +41… |
| `mwst.unternehmen.email` | E-Mail | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.unternehmen.elektronische_plattform` | Elektronische Plattform | choice | optional | EU, GmbH, AG, KlG, KmG | ja_nein | Art. 3 Bst. l MWSTG, MWST-Info 27. |
| `mwst.unternehmen.inhaber_ja_nein` | Sind Sie Inhaber/in des Einzelunternehmens? | choice | optional | EU | ja_nein |  |
| `mwst.unternehmen.inhaber_anrede` | Herr/Frau | choice | unbedingt | EU | anrede |  |
| `mwst.unternehmen.inhaber_vorname` | Vorname | text | optional | EU | — |  |
| `mwst.unternehmen.inhaber_name` | Name | text | unbedingt | EU | — |  |
| `mwst.unternehmen.inhaber_geburt` | Geburtsdatum | date | unbedingt | EU | — |  |
| `mwst.unternehmen.inhaber_staat` | Staatsbürgerschaft | lookup | unbedingt | EU | — | Länderliste ESTV; Vollkatalog im Inventar nicht erhoben. |
| `mwst.unternehmen.inhaber_heimatort` | Heimatort | lookup | unbedingt | EU | — |  |
| `mwst.unternehmen.ahv` | Sozialversicherungsnummer (AHV) | text | unbedingt | EU | — | Prüfziffervalidierung. Format 756.NNNN.NNNN.NN. |
| `mwst.unternehmen.privat_identisch` | Privatadresse identisch mit Sitzadresse? | choice | optional | EU | ja_nein |  |
| `mwst.unternehmen.zustelladresse` | Zustelladresse | choice | optional | EU, GmbH, AG, KlG, KmG | mwst_zustelladresse |  |
| `mwst.unternehmen.uebernahme` | Haben Sie ein bestehendes Unternehmen übernommen? | choice | unbedingt | EU, GmbH, AG, KlG, KmG | ja_nein |  |

### estv-mwst — Umsatz

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `mwst.umsatz.versandhandel` | Versandhandel | choice | unbedingt | EU, GmbH, AG, KlG, KmG | ja_nein | Lieferung von Gegenständen, die wegen Steuerbetrag <= CHF 5 von der Einfuhrsteuer befreit sind. Ja ohne Zusatzfelder. |
| `mwst.umsatz.gj_start` | Erstes Geschäftsjahr Startdatum | date | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.umsatz.gj_ende` | Erstes Geschäftsjahr Abschlussdatum | date | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.umsatz.freiwillige_unterstellung` | Freiwillige Unterstellung Art. 11 MWSTG | choice | bedingt | EU, GmbH, AG, KlG, KmG | ja_nein | nur unter der Umsatzschwelle sichtbar |
| `mwst.umsatz.steuerpflicht_per` | Obligatorische Steuerpflicht per | choice | unbedingt | EU, GmbH, AG, KlG, KmG | mwst_steuerpflicht_beginn | MWST-Info 02 Ziff. 5.2.1.1. |
| `mwst.umsatz.steuerpflicht_anderes_datum` | Anderes Datum | date | bedingt | EU, GmbH, AG, KlG, KmG | — | Obligatorische Steuerpflicht per = Anderes Datum |

### estv-mwst — Umsatz erste 3 Monate

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `mwst.umsatz.m3_inland_export` | Lieferungen und Dienstleistungen im Inland inkl. Export | number | bedingt | EU, GmbH, AG, KlG, KmG | — | gültige Daten erstes Geschäftsjahr |
| `mwst.umsatz.m3_ausland` | Lieferungen und Dienstleistungen ausserhalb der Schweiz, ohne ausgenommene Leistungen | number | bedingt | EU, GmbH, AG, KlG, KmG | — | gültige Daten erstes Geschäftsjahr |
| `mwst.umsatz.m3_ausgenommen` | Von der Steuer ausgenommene Leistungen und andere Mittelflüsse | number | bedingt | EU, GmbH, AG, KlG, KmG | — | gültige Daten erstes Geschäftsjahr |
| `mwst.umsatz.m3_total` | Total | anzeige | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.umsatz.m3_massgebend` | davon massgebend | anzeige | optional | EU, GmbH, AG, KlG, KmG | — | Zeilen 1+2, hochgerechnet auf 12 Monate. |

### estv-mwst — Umsatz im Geschäftsjahr

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `mwst.umsatz.gj_inland_export` | Lieferungen und Dienstleistungen im Inland inkl. Export | number | bedingt | EU, GmbH, AG, KlG, KmG | — | gültige Daten erstes Geschäftsjahr |
| `mwst.umsatz.gj_ausland` | Lieferungen und Dienstleistungen ausserhalb der Schweiz, ohne ausgenommene Leistungen | number | bedingt | EU, GmbH, AG, KlG, KmG | — | gültige Daten erstes Geschäftsjahr |
| `mwst.umsatz.gj_ausgenommen` | Von der Steuer ausgenommene Leistungen und andere Mittelflüsse | number | bedingt | EU, GmbH, AG, KlG, KmG | — | gültige Daten erstes Geschäftsjahr |

### estv-mwst — Modalitäten

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `mwst.modalitaeten.abrechnungsart` | Art der Abrechnung | choice | unbedingt | EU, GmbH, AG, KlG, KmG | mwst_abrechnungsart | Art. 39, 40 MWSTG. |
| `mwst.modalitaeten.methode` | Methode | choice | unbedingt | EU, GmbH, AG, KlG, KmG | mwst_methode | Saldosteuersatz Art. 37 Abs. 1: Umsatz <= CHF 5'024'000, Steuer <= CHF 108'000. |
| `mwst.modalitaeten.taetigkeiten` | Tätigkeiten | lookup | unbedingt | EU, GmbH, AG, KlG, KmG | mwst_taetigkeitscodes_beispiele | ESTV-Autocomplete, mehrere möglich. Vollkatalog nicht erhoben. |
| `mwst.modalitaeten.taetigkeiten_freitext` | Tätigkeiten (manuell) | note | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.modalitaeten.sss_anteil` | Anteil je Tätigkeit (Saldosteuersatz) | number | nicht_erfasst | EU, GmbH, AG, KlG, KmG | — | Methode = Saldosteuersatz |

### estv-mwst — Kontakt

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `mwst.kontakt.firmenname` | Firmenname | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.kontakt.vorname` | Vorname | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.kontakt.name` | Name | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.kontakt.email` | E-Mail | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.kontakt.telefon` | Telefonnummer | text | unbedingt | EU, GmbH, AG, KlG, KmG | — | +41XXXXXXXXX. EasyGov/ESTV ohne IBAN in diesem Schritt; Kanzlei-Spalte mwst_iban in 5_MWST. |

### estv-mwst — Zusammenfassung

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `mwst.abschluss.bestaetigung` | Bestätigung | boolean | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `mwst.abschluss.captcha` | CAPTCHA | text | unbedingt | EU, GmbH, AG, KlG, KmG | — | 7 Zeichen. Kein PDF. Korrespondenz per Briefpost an Sitzadresse. |

### kanzlei — Kontakt

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `kanzlei.mwst.iban` | MWST-IBAN | text | nicht_erfasst | EU, GmbH, AG, KlG, KmG | — | ESTV-Strecke ohne IBAN. Kanzlei-Erhebung. |

## 4. AHV-Anmeldung

### ahv — 1 Unternehmensstruktur

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `ahv.struktur.hr_eintrag` | Handelsregistereintrag | choice | unbedingt | EU, GmbH, AG, KlG, KmG | ahv_handelsregistereintrag |  |
| `ahv.struktur.uid_suche` | Unternehmensname oder UID | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Handelsregistereintrag = eingetragen |
| `ahv.struktur.verbandszugehoerigkeit` | Verbandszugehörigkeit | choice | unbedingt | EU, GmbH, AG, KlG, KmG | ahv_verbandszugehoerigkeit |  |
| `ahv.struktur.beitrittsdatum` | Beitrittsdatum | date | bedingt | EU, GmbH, AG, KlG, KmG | — | Verbandszugehörigkeit = Mitgliedschaft besteht |
| `ahv.struktur.verband` | bei Verband | lookup | bedingt | EU, GmbH, AG, KlG, KmG | verbaende | Verbandszugehörigkeit = Mitgliedschaft besteht |
| `ahv.struktur.verband_vorschlag` | Vorschlagsliste Verbände/AK | lookup | bedingt | EU, GmbH, AG, KlG, KmG | verbaende | Verbandszugehörigkeit = Mitgliedschaft geplant |
| `ahv.struktur.unternehmen_entstehung` | Das Unternehmen | choice | optional | EU, GmbH, AG, KlG, KmG | ahv_uebernahmeart |  |
| `ahv.struktur.uebernahme_durch` | durch | choice | bedingt | EU, GmbH, AG, KlG, KmG | ahv_uebernahme_durch | Das Unternehmen = von Vorgänger übernommen |
| `ahv.struktur.vorgaenger_name` | Name | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Das Unternehmen = von Vorgänger übernommen |
| `ahv.struktur.abrechnungsnr` | Abrechnungs-Nr. | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Das Unternehmen = von Vorgänger übernommen |
| `ahv.struktur.eigenkapital` | Eigenkapital | number | optional | EU, GmbH, AG, KlG, KmG | — | Gebundenes Kapital in CHF. |
| `ahv.struktur.darlehen` | Darlehen/Kredite | number | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.struktur.inv_werkzeuge` | Werkzeuge und Maschinen | number | optional | EU, GmbH, AG, KlG, KmG | — | Übernahme durch Kauf |
| `ahv.struktur.inv_fahrzeuge` | Fahrzeuge | number | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.struktur.inv_waren` | Wareninventar | number | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.struktur.inv_weitere` | weitere Investitionen | number | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.struktur.inv_weitere_art` | Art der Investition | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.struktur.miete_buero` | Büroraum | number | optional | EU, GmbH, AG, KlG, KmG | — | Übernahme durch Miete |
| `ahv.struktur.miete_laden` | Ladenlokal | number | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.struktur.miete_werkstatt` | Werkstatt | number | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.struktur.miete_lager` | Lagerräume | number | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.struktur.ort_taetigkeit` | Ort der Tätigkeit | multichoice | optional | EU, GmbH, AG, KlG, KmG | ahv_taetigkeitsort |  |
| `ahv.struktur.anzahl_kunden` | Anzahl der Kunden | number | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.struktur.kunde_1` | Kunde 1 | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.struktur.kunde_2` | Kunde 2 | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.struktur.kunde_3` | Kunde 3 | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.struktur.auftraege` | Beschreibung der Aufträge | note | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.struktur.neuster_auftrag` | Datum des neusten Auftrags | date | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.struktur.agent` | Agent/Vertreter | choice | optional | EU, GmbH, AG, KlG, KmG | ja_nein |  |
| `ahv.struktur.auftraggeber` | Auftraggeber (Name, Adresse) | note | bedingt | EU, GmbH, AG, KlG, KmG | — | Agent/Vertreter = Ja |

### ahv — 2 Mitarbeitender Inhaber

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `ahv.inhaber.beitraege_zuletzt` | Zuletzt AHV-Beiträge bezahlt als | choice | unbedingt | EU | ahv_beitraege_zuletzt |  |
| `ahv.inhaber.ak_name` | Ausgleichskasse Name | text | bedingt | EU | — | Zuletzt AHV-Beiträge mit Ausgleichskasse |
| `ahv.inhaber.ak_von` | Von | date | bedingt | EU | — | Zuletzt AHV-Beiträge mit Ausgleichskasse |
| `ahv.inhaber.ak_bis` | Bis | date | bedingt | EU | — | Zuletzt AHV-Beiträge mit Ausgleichskasse |
| `ahv.inhaber.verband_ak_einzel` | Als Einzelperson einer Verbands-AK angeschlossen? | choice | optional | EU | ja_nein |  |
| `ahv.inhaber.verband_ak_name` | Name | text | bedingt | EU | — | Einzelperson Verbands-AK = Ja |
| `ahv.inhaber.verband_ak_liste` | Ausgleichskasse | lookup | bedingt | EU | ausgleichskassen | Einzelperson Verbands-AK = Ja |
| `ahv.inhaber.kinder` | Kinder unter 18 oder in Ausbildung? | choice | optional | EU | ja_nein |  |
| `ahv.inhaber.mitarbeit` | Mitarbeit im Unternehmen | choice | unbedingt | EU | ahv_mitarbeit |  |
| `ahv.inhaber.rolle` | Ihre Rolle | text | unbedingt | EU | — |  |
| `ahv.inhaber.nebene_bezeichnung` | Nebenerwerb / Haupterwerb Bezeichnung | text | bedingt | EU | — | Haupterwerb optional bzw. Nebenerwerb Pflicht für die jeweils andere Tätigkeit |
| `ahv.inhaber.nebene_arbeitgeber` | Name Arbeitgeber | text | bedingt | EU | — | Angaben zum anderen Erwerb |
| `ahv.inhaber.nebene_adresse` | Adresse | text | bedingt | EU | — | Angaben zum anderen Erwerb |
| `ahv.inhaber.nebene_plzort` | PLZ Ort | text | bedingt | EU | — | Angaben zum anderen Erwerb |
| `ahv.inhaber.einkommen` | Finanzielle Abgeltung Betrag | number | unbedingt | EU | — | Geschätztes Einkommen nach Spesen, erste 12 Monate, CHF. |
| `ahv.inhaber.risiko_checkboxen` | Risiko | checkbox_group | optional | EU | ahv_risiko_checkboxen |  |
| `ahv.inhaber.risiko_text` | Kurze Beschreibung des unternehmerischen Risikos | note | unbedingt | EU | — |  |
| `ahv.inhaber.arbeitsorganisation` | Arbeitsorganisation | checkbox_group | optional | EU | ahv_arbeitsorganisation |  |
| `ahv.inhaber.in_wessen_namen` | In wessen Namen tätig? | choice | optional | EU | ahv_in_wessen_namen |  |
| `ahv.inhaber.auftritt` | Auftritt | checkbox_group | optional | EU | ahv_auftritt |  |

### ahv — 3 Personal und Lohn

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `ahv.personal.fam_anzahl` | Familienangehörige (ohne Ehepartner) Anzahl Personen | number | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.personal.fam_lohnsumme` | Jährliche Lohnsumme Familienangehörige | number | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.personal.fam_seit` | angestellt seit (Familienangehörige) | date | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.personal.fam_kinder` | Kinder | choice | unbedingt | EU, GmbH, AG, KlG, KmG | ja_nein |  |
| `ahv.personal.ang_anzahl` | Angestellte Anzahl Personen | number | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.personal.ang_lohnsumme` | Jährliche Lohnsumme Angestellte | number | bedingt | EU, GmbH, AG, KlG, KmG | — | Anzahl Angestellte > 0 |
| `ahv.personal.ang_seit` | angestellt seit (Angestellte) | date | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.personal.ang_kinder` | Kinder (Angestellte, für Kinderzulagen) | choice | unbedingt | EU, GmbH, AG, KlG, KmG | ja_nein |  |
| `ahv.personal.ahv_ausweis_formulare` | Anzahl Antragsformulare AHV-Ausweis | number | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.personal.lohnbuchhaltung` | Lohnbuchhaltung | multichoice | optional | EU, GmbH, AG, KlG, KmG | ahv_lohnbuchhaltung |  |
| `ahv.personal.uvg_name` | UVG Name Versicherung | text | unbedingt | EU, GmbH, AG, KlG, KmG | — | Privatversicherer. |
| `ahv.personal.bvg_anschluss` | BVG Anschluss | choice | unbedingt | EU, GmbH, AG, KlG, KmG | ja_nein |  |
| `ahv.personal.bvg_name` | BVG Name Versicherung | text | bedingt | EU, GmbH, AG, KlG, KmG | — | BVG Anschluss = Ja |
| `ahv.personal.bvg_begruendung` | Begründung | note | bedingt | EU, GmbH, AG, KlG, KmG | — | BVG Anschluss = Nein |

### ahv — 4 Kontaktadressen

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `ahv.kontakt.kontoinhaber` | Kontoinhaber/in | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.kontakt.iban` | IBAN | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.kontakt.treuhand` | Adresse der Treuhandstelle | text | optional | EU, GmbH, AG, KlG, KmG | — | Auswahl, «keine vorhanden». |
| `ahv.kontakt.person_nachname` | Kontaktperson Familienname | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.kontakt.person_vorname` | Kontaktperson Vorname | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.kontakt.person_telefon` | Kontaktperson Telefon | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.kontakt.person_mobil` | Kontaktperson Mobil | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.kontakt.person_email` | Kontaktperson E-Mail | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.kontakt.korr_name` | Korrespondenzadresse Name/Firma | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.kontakt.korr_strasse` | Korrespondenzadresse Strasse | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.kontakt.korr_nummer` | Korrespondenzadresse Nummer | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.kontakt.korr_zusatz` | Korrespondenzadresse Adresszusätze | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.kontakt.korr_postfach` | Korrespondenzadresse Postfach | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.kontakt.korr_plz` | Korrespondenzadresse PLZ | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.kontakt.korr_ort` | Korrespondenzadresse Ort | lookup | unbedingt | EU, GmbH, AG, KlG, KmG | — | Autocomplete. |
| `ahv.kontakt.bemerkungen` | Bemerkungen an AK | note | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `ahv.kontakt.angebote` | Angebote Verband/AK | choice | optional | EU, GmbH, AG, KlG, KmG | ja_nein |  |

### ahv — 5 Abschliessen

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `ahv.abschluss.bestaetigung` | Bestätigung | boolean | unbedingt | EU, GmbH, AG, KlG, KmG | — | Danach keine Korrektur mehr. Fertigstellen = Übermittlung, dann Unterschreiben. |

## 5. UVG-Anmeldung

### uvg — 1 Personal und Lohn

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `uvg.personal.anzahl_aufnahme` | Anzahl Mitarbeitende inkl. mitarbeitende Inhaber am Geschäftsaufnahme | number | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.personal.anzahl_plus6` | Anzahl Mitarbeitende in ca. 6 Monaten | number | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.personal.gruppen` | Unter den Mitarbeitenden | multichoice | optional | EU, GmbH, AG, KlG, KmG | uvg_mitarbeitende_gruppen |  |
| `uvg.personal.freiwillige_inhaber` | Freiwillige UV für Inhaber (unverbindlich) | choice | unbedingt | EU | ja_nein | Nur Einzelunternehmen, keine Folgefelder. |
| `uvg.personal.lohn_laufend` | Lohnsumme aller Mitarbeitenden laufendes Jahr | number | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.personal.lohn_folge` | Lohnsumme aller Mitarbeitenden Folgejahr | number | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |

### uvg — 2 Diverses

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `uvg.diverses.praemienzahlung` | Prämienzahlung | choice | unbedingt | EU, GmbH, AG, KlG, KmG | uvg_praemienzahlung |  |
| `uvg.diverses.kontoart` | Konto | choice | unbedingt | EU, GmbH, AG, KlG, KmG | uvg_kontoart |  |
| `uvg.diverses.kontoinhaber` | Kontoinhaber/in | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Konto = Bank- oder Postkonto |
| `uvg.diverses.iban` | IBAN | text | bedingt | EU, GmbH, AG, KlG, KmG | — | Konto = Bank- oder Postkonto |
| `uvg.diverses.ahv_ak` | AHV-Ausgleichskasse | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.ahv_mitgliednr` | AHV Mitgliedernummer | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.krankentaggeld` | Krankentaggeldversicherung/Krankenkasse | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.kranken_nr` | Mitglieder-/Policennummer | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.ansprech_nachname` | Ansprechperson Familienname | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.ansprech_vorname` | Ansprechperson Vorname | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.ansprech_telefon` | Ansprechperson Telefon | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.ansprech_mobil` | Ansprechperson Mobil | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.ansprech_email` | Ansprechperson E-Mail | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.korr_name` | Korrespondenzadresse Name/Firma | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.korr_strasse` | Korrespondenzadresse Strasse | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.korr_nr` | Korrespondenzadresse Hausnummer | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.korr_plz` | Korrespondenzadresse PLZ | text | unbedingt | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.korr_zusatz` | Korrespondenzadresse Adresszusätze | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.korr_postfach` | Korrespondenzadresse Postfach | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.korr_ort` | Korrespondenzadresse Ort | text | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.bemerkungen` | Bemerkungen an Versicherung | note | optional | EU, GmbH, AG, KlG, KmG | — |  |
| `uvg.diverses.zustaendige_versicherung` | Zuständige Versicherung | anzeige | optional | EU, GmbH, AG, KlG, KmG | — | EasyGov schätzt Suva/Privat aus der Branche. Suva-Zweig: Spalte suva_branch in 7_UVG. |
| `uvg.diverses.weiterfahren` | Wie weiterfahren? | choice | unbedingt | EU, GmbH, AG, KlG, KmG | uvg_weiterfahren |  |
| `uvg.diverses.versicherer` | UVG-Versicherer | multichoice | unbedingt | EU, GmbH, AG, KlG, KmG | uvg_versicherer |  |

### uvg — 3 Abschliessen

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `uvg.abschluss.bestaetigung` | Bestätigung | boolean | unbedingt | EU, GmbH, AG, KlG, KmG | — | Fertigstellen = elektronischer Versand an gewählte Versicherer. |

### kanzlei — Diverses

| ID | Label | Typ | Pflicht | Rechtsformen | Werteliste | Bedingung / Hinweis |
|---|---|---|---|---|---|---|
| `kanzlei.uvg.suva_zweig` | Suva-Zweig | text | nicht_erfasst | EU, GmbH, AG, KlG, KmG | — | Suva-Zweig im EasyGov-Inventar nicht gesehen. Freitext, keine Werteliste. |

