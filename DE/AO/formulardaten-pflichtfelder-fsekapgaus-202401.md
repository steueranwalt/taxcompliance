# Pflichtfelder: fsekapgaus-202401 – Fragebogen steuerliche Erfassung, Körperschaft nach ausländischem Recht

**Methode:** Ermittelt am 26.10.2026 durch Prüfläufe im ELSTER-Portal, ohne Absenden, ohne Mandantendaten (leeres Formular, nur Auswahlfelder umgestellt, „Prüfen“, ohne Speichern verlassen). Zeile = Zeilennummer im Formular; die ELSTER-Prüfliste zeigt keine Kz.

**Bezug:** Feld-/Kz-Katalog in [`formulardaten-roherfassung.md`](formulardaten-roherfassung.md) Abschnitt 4; Formularvorschlag in [`../elster/erfassungsformulare.json`](../elster/erfassungsformulare.json) (`steuerliche-erfassung-auslandskoerperschaft`).

## Unbedingte Pflichtfelder (leeres Formular, ELSTER-Prüfliste)

| Seite | Feld | Fehlertext |
|---|---|---|
| Startseite | Steuernummer (Neuantrag vorausgewählt) | siehe Prüfliste |
| 1 | Name der Firma laut Register | siehe Prüfliste |
| 1 | Art der Tätigkeiten in der BRD | siehe Prüfliste |
| 3 | Einverständnis Zuständigkeitsvereinbarung | siehe Prüfliste |
| 3 | bereits bei anderem Finanzamt erfasst | siehe Prüfliste |

## Bedingte Pflichtfelder

| Zeile | Feld | Pflicht (bedingt) | Bedingung | Fehlertext |
|---|---|---|---|---|
| 20 | Abschn. 3: Steuernummer + Land | ja | Abschn. 3: Z18 Zuständigkeitsvereinbarung = Ja und Z19 bereits bei anderem FA erfasst = Ja | Bitte geben Sie die Steuernummer an, unter der die Körperschaft bei einem anderen deutschen Finanzamt bereits steuerlich erfasst ist. |
| 23–25 | Abschn. 4: Adresse | ja | Abschn. 4: Betriebstätte Inland, Eintrag mit Eigentumsverhältnis (Z27) | Es wurden der Name der Betriebstätte und / oder Angaben zu Kommunikationsverbindungen angegeben. Bitte machen Sie auch Angaben zur Adresse der Betriebstätte (1. feste Betriebsstätte im Inland). |
| 27 | Abschn. 4: genau eine Auswahl | ja | Abschn. 4: Z27 beide Häkchen | Bitte machen Sie eine Angabe zu den Eigentumsverhältnissen … Es ist nur eine Auswahl zulässig. |
| 64, 65–67 | Abschn. 6: Vorname, Name, Geburtsdatum (Z64), Inlandsadresse (Z65–67) | ja | Abschn. 6: Eintrag, Z62 = abhängige Person, Z63 = Ja | Bei der 1. tätigen Person sind die Art der Abhängigkeit, Vorname, Name, Geburtsdatum und eine Inlandsanschrift erforderlich. |
| 76/77, 78–80 | Abschn. 7: Name, Vorname, Geburtsdatum (Z76/77); Adresse In-/Ausland (Z78–80) | ja | Abschn. 7: Vertreter-Eintrag (Anrede gesetzt) | Bitte geben Sie Vorname, Name und Geburtsdatum an (1. Vertreter). / Bitte geben Sie eine Inlands- oder eine Auslandsanschrift an (1. Vertreter). |
| 86 | Abschn. 8: Vorname, Name | ja | Abschn. 8: Anrede natürliche Person (Z86) | Bitte geben Sie Anrede, Vorname und Name an. |
| 86–92, 88–90 | Abschn. 8: Angaben Beratung (Z86–92), Adresse (Z88–90) | ja | Abschn. 9: Z93 Beratung empfangsbevollmächtigt | Es wurde angegeben, dass die steuerliche Beratung empfangsbevollmächtigt ist. Bitte machen Sie Angaben zur steuerlichen Beratung. / Bitte geben Sie eine Inlands- oder Auslandsanschrift an. |
| 101/102, 105 | Abschn. 10: IBAN (Z101/102), Kontoinhaber (Z105); BIC bei IBAN aus AL, MD, MC, ME, MK, SM, CH | ja | Abschn. 10: Z104 Kontoinhaber = abweichend | Die IBAN und die Rolle des Kontoinhabers müssen gemeinsam angegeben werden. / … keine IBAN angegeben … / … Angaben im Feld 'ggf. abweichende(r) Kontoinhaber(in) …' |
| 109–111 | Abschn. 11: Adresse Notar | ja | Abschn. 11: Notar Anrede (Z108) | Es wurden Angaben zum Gründungsnotar gemacht. Bitte geben Sie dazu eine Inlands- oder Auslandsanschrift an. |
| 118 | Abschn. 12: Beginn | ja | Abschn. 12: Z118 abweichendes Wj = Ja | Es wurde ein abweichendes Wirtschaftsjahr eingegeben. Bitte machen Sie auch Angaben im Feld 'Beginn'. |
| 119 | Abschn. 12: Höhe Kapital (Z119), Bezeichnung sonstige Währung | ja | Abschn. 12: Z119/120 Währung gewählt / Sonstige | Die Felder 'Höhe des Grund- oder Stammkapitals' und 'ggf. abweichende Währung' müssen gemeinsam angegeben werden. / Bitte machen Sie eine Angabe im Feld 'Bezeichnung der sonstigen Währung'. |
| 121, 126–128, 131 | Abschn. 13: Name, Vorname, Geburtsdatum (Z121); Adresse (Z126–128); Beteiligung % (Z131) | ja | Abschn. 13: Anteilseigner-Eintrag (Z121) | … müssen gemeinsam angegeben werden (1. Anteilseigner). / … Inlands- oder Auslandsanschrift … / … 'Beteiligung prozentual' … |
| 150 | Abschn. 14: Bezeichnung der KG | ja | Abschn. 14: Z149 Komplementärin | Bitte machen Sie Angaben im Feld 'Bezeichnung der KG'. |
| 169 | Abschn. 15: Name herrschendes Unternehmen | ja | Abschn. 15: Z168 Konzernzugehörigkeit | Bitte geben Sie den Namen des Konzerns an. |
| 219 | Abschn. 19: Betrag | ja | Abschn. 19: Z219 voraussichtliche USt = Zahllast | Die Felder 'Voraussichtliche Umsatzsteuer' und 'Betrag' müssen gemeinsam angegeben werden. |
| 222 | Abschn. 19: Art des Umsatzes | ja | Abschn. 19: Z221 steuerfreie Umsätze = Ja | Bitte machen Sie Angaben im Feld 'Art des Umsatzes oder der Tätigkeit'. |
| 224 | Abschn. 19: Art des Umsatzes | ja | Abschn. 19: Z223 ermäßigter Satz = Ja | dito |
| 226, 225a | Abschn. 19: Art des Umsatzes (Z226) + mind. eine Rechtsvorschrift (Z225a) | ja | Abschn. 19: Z225 Nullsteuersatz = Ja | … sowie zu mindestens einer Rechtsvorschrift. |
| 228, 229/230 | Abschn. 19: Art (Z228) + genau eins von Z229/Z230 | ja | Abschn. 19: Z227 § 24 UStG = Ja | … Durchschnittssatzbesteuerung … oder Verzicht … Es ist nur eine Auswahl zulässig. (Text aus Screenshot) |
| 238 | Abschn. 20: Datum, Aktenzeichen | ja | Abschn. 20: Z237 Vorsteuervergütung beantragt = Ja | Die Angaben zur Vergütung von Vorsteuern sind lückenhaft … (Datum, Aktenzeichen). |
| 256 | Abschn. 22: URL | ja | Abschn. 22: Z255 eigener Webshop | Bitte geben Sie die Internetadresse ihres Webshops im Feld 'Web-Adresse (URL)' an. |
| — | Abschn. 22: Name Schnittstelle, Identifikationsmerkmal | ja | Abschn. 22: Z257 elektronische Schnittstelle | … 'Name der elektronischen Schnittstelle' und 'Identifikationsmerkmal (z. B. Accountname)'. |
| 300 | Abschn. 24: Aufzählung | ja | Abschn. 24: Z299 weitere Unterlagen | … konkrete Angaben im Feld 'Weitere Unterlagen (bitte aufzählen)'. |

## Ohne neue Fehler (geprüft)

Abschn. 1 Z13–17; 5 Z56–59, Z61; 11 Gründungsstaat/Register; 12 Ende unbekannt; 13 Z132 Treuhand; 14 Z149 daneben gewerblich, Z153; 15 Z156/157; 17 Z217, Z231; 18 Z188, Z194–216; 20 Z234, Z235, Z240–242; 21 Z243, Z249; 23 Z263.

## Nicht getestet

4 Ausland/nicht feste Betriebsstätte; 6 unabhängige Person; 23 Bauausführung; 19 Z220, Z232/233; 21 Z244–248, Z250–254; gelbe Hinweisliste nicht ausgewertet.

## Konflikte / Hinweise

Konflikte (keine Pflicht): Z217+Z218, Z229+Z230 gleichzeitig.
