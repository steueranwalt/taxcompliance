# Pflichtfelder: fsekapg-202401 – Fragebogen steuerliche Erfassung, Gründung Kapitalgesellschaft/Genossenschaft

**Methode:** Ermittelt am 26.10.2026 durch Prüfläufe im ELSTER-Portal, ohne Absenden, ohne Mandantendaten (leeres Formular, nur Auswahlfelder umgestellt, „Prüfen“, ohne Speichern verlassen). Zeile = Zeilennummer im Formular; die ELSTER-Prüfliste zeigt keine Kz.

**Bezug:** Feld-/Kz-Katalog in [`formulardaten-roherfassung.md`](formulardaten-roherfassung.md) Abschnitt 2; Formularvorschlag in [`../elster/erfassungsformulare.json`](../elster/erfassungsformulare.json) (`steuerliche-erfassung-kapg`).

## Unbedingte Pflichtfelder (leeres Formular, ELSTER-Prüfliste)

| Seite | Feld | Fehlertext |
|---|---|---|
| Startseite | Steuernummer | siehe Prüfliste |
| 1 | Name | siehe Prüfliste |
| 1 | Art der Tätigkeit | siehe Prüfliste |
| 17 | Zeile 179: Eröffnungsjahr | siehe Prüfliste |
| 17 | Zeile 179: Folgejahr | siehe Prüfliste |
| 8 | Errichtung: notarieller Vertrag vom | siehe Prüfliste |
| 8 | Rechtsform | siehe Prüfliste |
| 9 | Beginn der Tätigkeit | siehe Prüfliste |
| 9 | Grund-/Stammkapital | siehe Prüfliste |
| 10 | Treuhand | siehe Prüfliste |
| 10 | mindestens ein Anteilseigner | siehe Prüfliste |
| 11 | Entstehungsart | siehe Prüfliste |
| 15 | voraussichtlicher Gewinn | siehe Prüfliste |
| 4 | mindestens ein gesetzlicher Vertreter | siehe Prüfliste |

## Bedingte Pflichtfelder

| Zeile | Feld | Pflicht (bedingt) | Bedingung | Fehlertext |
|---|---|---|---|---|
| 6 | Abschn. 1: PLZ, Ort, Staat | ja | Abschn. 1: Staat Auslandsadresse gewählt, Z6 | Es wurden Angaben zu einer Auslandsanschrift gemacht. Folgende Felder müssen hier mindestens ausgefüllt sein: 'Postleitzahl', 'Ort', 'Staat'. |
| 8–10 | Abschn. 2: PLZ, Ort, Staat | ja | Abschn. 2: Ort der Geschäftsleitung, Staat gewählt, Z8–10 | dito |
| 18 | Abschn. 3: PLZ, Ort, Staat | ja | Abschn. 3: Betriebstätte-Eintrag, Staat gewählt, Z18 | dito |
| 25/26, 28–30 | Abschn. 4: Vorname, Name, Geburtsdatum Z25/26; In-/Auslandsanschrift Z28–30 | ja | Abschn. 4: Vertreter-Eintrag, Anrede, Z25 | Bitte geben Sie Vorname, Name und Geburtsdatum an (1. Vertreter). / Bitte geben Sie eine Inlands- oder eine Auslandsanschrift an (1. Vertreter). |
| 34, 36–38 | Abschn. 5: Anrede, Vorname, Name Z34; Anschrift Z36–38 | ja | Abschn. 5: Beratung Anrede nat. Person, Z34 | Bitte geben Sie Anrede, Vorname und Name an. / Bitte geben Sie eine Inlands- oder Auslandsanschrift an. |
| 35, 36–38 | Abschn. 5: Firmenbezeichnung Z35; Anschrift Z36–38 | ja | Abschn. 5: Beratung Anrede Firma, Z35 | Bitte geben Sie den Firmennamen an. / … Anschrift … |
| 42/43, 44–46 | Abschn. 6: Name/Vorname bzw. Firma; Anschrift Z44–46 | ja | Abschn. 6: Empfangsbevollmächtigter Anrede (Z42 nat. / Z43 Firma) | wie Abschn. 5 |
| — | Abschn. 5: Angaben zur Beratung | ja | Abschn. 6: Z41 Beratung empfangsbevollmächtigt | Es wurde angegeben, dass die steuerliche Beratung empfangsbevollmächtigt ist. Bitte machen Sie Angaben zur steuerlichen Beratung. (nur in Firma-Variante beobachtet) |
| 49/50, 51, 53 | Abschn. 7: IBAN Z49/Z50, BIC Z51 (bei best. IBAN-Ländern), Name abweichender Kontoinhaber Z53 | ja | Abschn. 7: Z52 Kontoinhaber = abweichend | Die IBAN und die Rolle des Kontoinhabers müssen gemeinsam angegeben werden. / … keine IBAN … / … 'Name des abweichenden Kontoinhabers'. |
| 55, 56 | Abschn. 8: beantragt am Z55, Ort Amtsgericht Z56 | ja | Abschn. 8: Z55 Antrag Handelsregister gestellt | … 'Eintragung wurde beantragt am' und 'Ort des Amtsgerichts'. |
| 55, 56, 57 | Abschn. 8: Tag der Eintragung Z55, Register + Registernummer Z57, Ort Amtsgericht Z56 | ja | Abschn. 8: Z55 Eintragung erfolgt = Ja | … 'Tag der Eintragung', 'Register', 'Registernummer' und 'Ort des Amtsgerichts'. |
| 59–61 | Abschn. 8: Anschrift Notar | ja | Abschn. 8: Notar Anrede, Z58 | Es wurden Angaben zum Gründungsnotar gemacht. Bitte geben Sie dazu eine Inlands- oder Auslandsanschrift an. |
| 65 | Abschn. 9: Beginn | ja | Abschn. 9: Z65 abweichendes Wj = Ja | … Bitte machen Sie auch Angaben im Feld 'Ja, Beginn'. |
| 69/70, 74–76a, 78 | Abschn. 10: Name, Vorname, Geburtsdatum Z69/70; Anschrift Z74–76a; Beteiligung % Z78 | ja | Abschn. 10: Anteilseigner nat. Person, Z69 | … müssen gemeinsam angegeben werden. / … Inlands- oder Auslandsanschrift. / … 'Höhe der Beteiligung in Prozent' … |
| 128/129, 135, 136 | Abschn. 12: Bezeichnung Besitzunternehmen Z128, Bezeichnung Z135, Beginn Nutzung Z136, Anschrift und/oder StNr Z128/129 | ja | Abschn. 12: Z127 Betriebsaufspaltung | Es wurden Angaben zur Betriebsaufspaltung gemacht … / Bitte machen Sie Angaben in den Feldern 'Bezeichnung des Besitzunternehmens', 'Bezeichnung', 'Beginn der tatsächlichen Nutzung' sowie zur Anschrift und / oder Steuernummer des Besitzunternehmens. |
| 138 | Abschn. 13: Bezeichnung KG | ja | Abschn. 13: Z137 Komplementärin = Ja | Bitte machen Sie Angaben im Feld 'Bezeichnung der KG'. |
| 157 | Abschn. 14: Name Konzern | ja | Abschn. 14: Z156 Konzernzugehörigkeit | Bitte geben Sie den Namen des Konzerns an. |
| 162 | Abschn. 14: Nummer § 5 Abs. 1 KStG | ja | Abschn. 14: Z162 KSt-Befreiung = Ja | Bitte machen Sie eine Angabe im Feld 'Wenn ja, tragen Sie bitte die Nummer aus § 5 Absatz 1 KStG ein:'. |
| 164 | Abschn. 14: Zweck | ja | Abschn. 14: Z163 § 60a-Feststellung = Ja | Bitte machen Sie eine Angabe im Feld 'Die Körperschaft verfolgt folgenden Zweck:'. |
| 152 | Abschn. 14: Name/Firma Organträger | ja | Abschn. 14: Organgesellschaft (Z146/150/151, Eintrag Z152) | Die Kapitalgesellschaft ist eine Organgesellschaft. Bitte machen Sie auch Angaben zum Namen beziehungsweise Firmennamen des Organträgers. |
| 155 | Abschn. 14: Beginn USt-Organschaft | ja | Abschn. 14: Z151 umsatzsteuerliche Organgesellschaft | Bitte machen Sie Angaben im Feld 'Beginn der umsatzsteuerlichen Organschaft'. |
| 182 | Abschn. 17: Betrag | ja | Abschn. 17: Z182 voraussichtliche USt = Zahllast | Die Felder 'Voraussichtliche Umsatzsteuer' und 'Betrag' müssen gemeinsam angegeben werden. |
| 185 | Abschn. 17: Art des Umsatzes | ja | Abschn. 17: Z184 § 4 steuerfrei = Ja | Bitte machen Sie Angaben im Feld 'Art des Umsatzes oder der Tätigkeit'. |
| 187 | Abschn. 17: Art | ja | Abschn. 17: Z186 ermäßigt = Ja | dito |
| 189, 188a | Abschn. 17: Art Z189 + mind. eine Rechtsvorschrift Z188a | ja | Abschn. 17: Z188 Nullsteuersatz = Ja | … sowie zu mindestens einer Rechtsvorschrift. |
| 191, 192/193 | Abschn. 17: Art Z191 + genau eins von Z192/Z193 | ja | Abschn. 17: Z190 § 24 = Ja | … Durchschnittssatzbesteuerung … oder … verzichtet … Es ist nur eine Auswahl zulässig. |
| 236 | Abschn. 22: Aufzählung | ja | Abschn. 22: Z235 weitere Unterlagen | … konkrete Angaben im Feld 'Weitere Unterlagen (bitte aufzählen)'. |

## Ohne neue Fehler (geprüft)

Rechtsform (alle 7 Optionen); 10 Treuhand = Ja; 11 alle Gründungsarten/Sacheinlagen/Umwandlung; 13 daneben gewerblich, atypisch still; 14 Z144/145; 17 Z178, Z180, Z181, Z194–196; 18 Z197–202; 19 One-Stop-Shop; 21 Z223; übrige Unterlagen-Checkboxen.

## Nicht getestet

Telefon-/Marktplatzlisten (Hinzufügen erst nach Texteingabe); 4 nicht nat. Vertreter; 8 Notar-Staat, Register-Optionen einzeln; 17 Überschuss, Z193 allein; 18 UStIdNr-Grund Option 2/3; Startseite „Steuernummer eingeben“/„Datenübernahme aus Profil“.

## Konflikte / Hinweise

Nur Hinweise (gelb, nicht blockierend): Auslandsanschrift ohne Straße/Hausnummer (Abschn. 1, 2, 3); Z215 Webshop → URL Z216; Z217 Schnittstelle → Name + Identifikationsmerkmal.

Konflikte: Z180 Kleinunternehmer + Z181 Verzicht; Z183 Monat als VAZ ohne Überschuss > 9.000 €; Anteilseigner zugleich nat. und nicht nat. Person.
