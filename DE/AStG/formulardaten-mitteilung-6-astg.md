# Formulardaten: ASt – Mitteilung nach § 6 AStG

**Stand der Auswertung:** 31.08.2026

**Quellen:**

- FMS-XML-Rohinstanz (leer): [`FRM_ASt_Mitteilung_6_AStG.xml`](FRM_ASt_Mitteilung_6_AStG.xml) → `catalog://Steuerformulare/aussteu/wegzug/034514`
- amtliches Vordruckmuster laut BMF-Schreiben v. 12.12.2025, IV B 5 - S 1369/00008/002/085 (ASt-Mitteilung ggf. i. V. m. § 19 Abs. 3 / § 49 Abs. 5 InvStG)

## Abgrenzung zum AO-Erfassungsbestand

| | Dieses Formular | `DE/AO` Erfassung / BZSt2 |
|---|---|---|
| Rechtsgrundlage | § 6 AStG (Wegzugsbesteuerung / Stundung), ggf. InvStG | §§ 137 ff., 138 Abs. 2 AO |
| Zweck | jährliche Bestätigung / meldepflichtige Ereignisse bei besteuertem Vermögenszuwachs | steuerliche Erfassung Inland bzw. Auslandsmitteilung BZSt2 |
| Overlap | Person, Anschrift, Steuernummer, IdNr., W-IdNr. | Stammblock / Identifikation |
| Separat zu führen | Anteilswerte, gemeiner Wert, Gewinnausschüttungen/Einlagenrückgewähr, Ereigniscodes aF/nF, Zurechnungsbestätigung | — |

Nicht in die ELSTER-Fragebögen oder BZSt2 einmischen; eigenes Modul unter AStG.

## 1. Kopf / Mitteilungsart

| Kz | Feld |
|---|---|
| 1 | Steuernummer |
| 2 | Identifikationsnummer; Jahr der Mitteilung |
| 3 | An das Finanzamt |
| 4 | Jährliche Bestätigung Anschrift/Zurechnung nach § 6 Abs. 7 AStG a. F. bis 31. Januar (`1 = Ja`) |
| 5 | Jährliche Bestätigung nach § 6 Abs. 5 AStG ggf. i. V. m. InvStG bis 31. Juli (`1 = Ja`) |
| 6 | Mitteilung meldepflichtiges Ereignis a. F. (§ 6 Abs. 5 S. 4 / Abs. 8 S. 2 AStG a. F. bzw. § 21 Abs. 3 S. 2 Nr. 2 AStG) (`1 = Ja`) |
| 7 | Mitteilung meldepflichtiges Ereignis n. F. (§ 6 Abs. 4 S. 5 bzw. S. 7 AStG) (`1 = Ja`) |

## 2. Angaben zur steuerpflichtigen Person

| Kz | Feld |
|---|---|
| 8 | Name, Vorname, Titel |
| 9 | Ausländisches Identifikationsmerkmal |
| 10 | Nur Gesamtrechtsnachfolge: Sterbedatum |
| 11 | Gesamtrechtsnachfolger: Steuernummer, Identifikationsnummer |
| 12–13 | Gesamtrechtsnachfolger: Name, Vorname, Titel (sowie ggf. weiteres Identifikationsmerkmal) |
| 14 | Anschrift zum Zeitpunkt der Mitteilung: Straße, Hausnummer, Hausnummerzusatz |
| 15 | Postleitzahl, Ort, Staat |
| 16 | Anschrift zum 31.12. des Vorjahres (nur bei Abweichung und Tatbestand § 6 Abs. 1 AStG a. F.): Straße, Hausnummer, Hausnummerzusatz |
| 17 | Postleitzahl, Ort, Staat (Vorjahresanschrift) |
| 18–19 | frei |

## 3. Anteile an Kapitalgesellschaften bzw. (Spezial-)Investmentfonds

Wiederholbarer Block (bei Papier: weitere Anteile in Anlage).

| Kz | Feld |
|---|---|
| 20 | Steuernummer (des Anteils-/Gesellschaftsbezugs) |
| 21 | Wirtschafts-Identifikationsnummer (`DE-…`) |
| 22 | Ausländisches Identifikationsmerkmal |
| 23 | Bei (Spezial-)Investmentfonds: ISIN |
| 24 | Bezeichnung der Gesellschaft (ggf. WKN) bzw. des (Spezial-)Investmentfonds |
| 25 | Veranlagungszeitraum der Berücksichtigung des Vermögenszuwachses |
| 26 | Maßeinheit Anteile: `1` Prozent · `2` Euro · `3` Stückzahl |
| 27 | Höhe der Anteile / Stückzahl, für die Vermögenszuwachs besteuert wurde |
| 28 | Gemeiner Wert zum Tatbestandszeitpunkt (EUR) |
| 29 | Kumulierte Gewinnausschüttungen/Einlagenrückgewähr zum Zeitpunkt der letzten Mitteilung |
| 30 | Gewinnausschüttungen/Einlagenrückgewähr seit letzter Mitteilung bzw. kumuliert bei Erstmitteilung |
| 31 | Kumulierte Gewinnausschüttungen/Einlagenrückgewähr zum Mitteilungszeitpunkt |
| 32 | Überschreitung 25 % des Wertes laut Zeile 28 (Betrag EUR) |
| 33 | Überschreitung 25 % des Wertes laut Zeile 28 (Prozent) |
| 34–39 | frei |

Bei Investmentanteilen treten Ausschüttungen / steuerfreie Kapitalrückzahlungen bzw. bei Spezial-Investmentanteilen ausgeschüttete/ausschüttungsgleiche Erträge und Substanzbeträge an die Stelle (Anleitung Fn. 11).

## 4. Zurechnung der Anteile

| Kz | Feld |
|---|---|
| 40 | Höhe der Anteile / Stückzahl (wie Zeile 26) |
| 41 | Bestätigung: Anteile weiterhin zuzurechnen (`1 = Ja`) |
| 42 | Erwerb als Gesamtrechtsnachfolger seit letzter Mitteilung (`1 = Ja`) |
| 43 | Zurechnung an Einzelrechtsnachfolger (`1 = Ja`) |
| 44 | Einzelrechtsnachfolger: Name, Vorname, Titel |
| 45 | Straße, Hausnummer, Hausnummerzusatz |
| 46 | Postleitzahl, Ort, Staat |
| 47 | Datum Eintritt Einzelrechtsnachfolge |
| 48–49 | frei |

## 5. Meldepflichtiges Ereignis

| Kz | Feld |
|---|---|
| 50 | Höhe der Anteile / Stückzahl, für die das Ereignis eingetreten ist |
| 51 | Zeitpunkt des meldepflichtigen Ereignisses |
| 52 | Ereigniscodes a. F. (§ 6 Abs. 5 S. 4 AStG a. F. / § 21 Abs. 3 S. 2 Nr. 2 AStG), Werte 1–8 |
| 53 | Ereigniscodes n. F. (§ 6 Abs. 4 S. 5 bzw. 7 AStG), Werte 1–8 |
| 54–59 | frei |

### Ereigniscodes Zeile 52 (Auswahl, a. F.)

1. Wegfall vergleichbarer unbeschränkter Steuerpflicht in EU/EWR (ggf. UK)
2. Wegfall Staatsangehörigkeit EU/EWR (ggf. UK)
3. Veräußerung / verdeckte Einlage / § 17 Abs. 4 EStG (Verträge beifügen)
4. Übertragung auf nicht unbeschränkt steuerpflichtige Person außerhalb EU/EWR
5. Entnahme / Ansatz Teilwert oder gemeiner Wert
6. Anteile nicht mehr in EU-/EWR-Betriebsstätte eingelegt
7. Zuordnung weder UK- noch EU-/EWR-Betriebsstätte (§ 6 Abs. 8 S. 2 Nr. 1 AStG a. F.)
8. Gewinnausschüttungen/Einlagenrückgewähr > 25 % nach dem 16.08.2023

### Ereigniscodes Zeile 53 (Auswahl, n. F.)

1. Jahresrate nicht fristgerecht
2. Mitwirkungspflichten nicht erfüllt
3. Insolvenz angemeldet
4. Anteile veräußert oder übertragen
5. Gewinnausschüttungen/Einlagenrückgewähr > 25 %
6. Rückkehrer: deutsches Besteuerungsrecht nicht wieder im früheren Umfang
7. Rückkehrer: Rückkehrabsicht entfallen
8. Rückkehrer: Einlage in Betriebsvermögen

## 6. Ergänzende Angaben / Unterschrift

| Kz | Feld |
|---|---|
| 60 | Kennzeichnung ergänzender Angaben (`1`–`4`: nicht erklärbar / abweichende Rechtsauffassung / vertiefte Prüfung / Mehrfach) |
| 61 | Freitext ergänzende Angaben |
| 62–69 | frei |
| 70 | Eigenhändige Unterschrift, Datum |
| 71 | Ort |

## 7. FMS-XML-Rohinstanz

Die hochgeladene Instanz ist leer (`<datarow />`). Sie bestätigt nur den Katalogpfad `catalog://Steuerformulare/aussteu/wegzug/034514`. Feldgenaue XML-Element-IDs stehen damit noch aus und sind gegen einen ausgefüllten FMS-Export nachzuziehen.
