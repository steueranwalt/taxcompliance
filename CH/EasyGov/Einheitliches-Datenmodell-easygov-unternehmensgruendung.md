# Einheitliches Datenmodell: EasyGov-Unternehmensgründung Schweiz

**Stand:** 15.11.2026

**Quellen:** Live-Inventar EasyGov.swiss (Gründung, Handelsregister, AHV, UVG) und ESTV-Formular `mwstanmelden.estv.admin.ch/registration`. Ergänzend die bestehende Analyse [`../Handelsregister/handelsregister_einzelunternehmen_formularfelder_lp_beratung.md`](../Handelsregister/handelsregister_einzelunternehmen_formularfelder_lp_beratung.md) (EasyGov-Ausdruck Einzelunternehmen, Formularstand 11.8.2025).

**Rollen der Dokumente in `CH/EasyGov/`:**

| Dokument | Rolle |
|---|---|
| dieses Datenmodell | Zielbild, Pflichtlogik, normalisierte Objekte, Forms-/Listen-Architektur |
| [`formulardaten-roherfassung.md`](formulardaten-roherfassung.md) | vollständiger Feldkatalog je Portalstrecke |
| [`formulardaten-pflichtfelder.md`](formulardaten-pflichtfelder.md) | unbedingte und bedingte Pflichtfelder |
| [`meldepflichten-matrix.md`](meldepflichten-matrix.md) | Resultat HR/MWST/AHV/UVG |
| [`felder.json`](felder.json) | maschinenlesbare Quelle für SharePoint-Skripte und Tests |

Feldgenaue Portal-Labels stehen in der Rohfassung. Hier stehen Objektstruktur und Architektur.

## 1. Ziel und Abgrenzung

Das Datenmodell dient der einheitlichen Erhebung für die Gründung eines Schweizer Unternehmens über EasyGov, unabhängig davon, in welcher Portalstrecke ein Label erscheint.

Abgedeckte Rechtsformen: Einzelunternehmen (EU), GmbH, AG, Kollektivgesellschaft (KlG), Kommanditgesellschaft (KmG).

**Nicht** Gegenstand: Transparenzregister (von EasyGov nach HR-Eintrag erwähnt, Felder nicht erhoben), kantonale Bewilligungen, produktive Übermittlung.

## 2. Pflichtlogik aus dem Live-Inventar

Unbedingte Portalpflichten (Auszug; vollständig in der Pflichtfeld-Datei):

### 2.1 Meldepflichten (alle Rechtsformen)

| Datenfeld | Pflichtstatus |
|---|---|
| Provisorischer Unternehmensname | unbedingt |
| Rechtsform | unbedingt |
| Datum ab (Beginn Tätigkeit) | unbedingt |
| Umsatzangaben | unbedingt |
| Total Angestellte (Köpfe, Inhaber zählt) | unbedingt |
| Beschäftigungsgrad | unbedingt |
| Branche | unbedingt |
| Extern Erledigtes (Ja/Nein) | unbedingt |

Berufsbezeichnung und Handel mit Produkten: unbedingt nur Einzelunternehmen. Digitale Signatur: unbedingt GmbH/AG.

### 2.2 Person (Inhaber, Gesellschafter, Vertreter)

| Datenfeld | Pflichtstatus |
|---|---|
| Staatsangehörigkeit(en) (Kategorie) | unbedingt |
| Zivilrechtlicher Wohnsitz | unbedingt |
| Zivilstand | unbedingt |
| Anrede, Familienname, Vorname, Geburtsdatum | unbedingt |
| AHV-Nummer | unbedingt bei EU/KlG/KmG; in GmbH/AG-Basisdaten nicht abgefragt |
| Heimatort | bedingt, Schweizer Bürger, mindestens 1 |
| Steuerpflicht USA | unbedingt GmbH/AG |
| Funktion und Zeichnungsberechtigung | unbedingt GmbH/AG (Gründer) und bei weiteren Vertretern |

### 2.3 Unternehmen

| Datenfeld | Pflichtstatus |
|---|---|
| Unternehmensbezeichnung, Zweck | unbedingt |
| Geschäftsdomizil Strasse, PLZ, Ort | unbedingt |
| Geschäftsaufnahme, Geschäftsjahresende (TT.MM.) | unbedingt |
| Firmenprüfung Grundregeln und Konflikte | unbedingt EU (Portal-Aktionen) |

### 2.4 Kapital (GmbH/AG)

| Datenfeld | Pflichtstatus |
|---|---|
| Stamm- bzw. Aktienkapital und Währung | unbedingt |
| Liberierungsart | unbedingt |
| GmbH: Anzahl Stammanteile total und je Gründer | unbedingt |
| AG: Liberierungsumfang; Namens- und Inhaberaktien gesamt und je Aktionär | unbedingt |
| Kapitalband | optional AG |

### 2.5 MWST (ESTV)

| Datenfeld | Pflichtstatus |
|---|---|
| Firmenname, Strasse, PLZ, Ort, Telefon | unbedingt |
| Versandhandel; erstes Geschäftsjahr Start/Ende | unbedingt |
| Übernahme eines bestehenden Unternehmens | unbedingt |
| Obligatorische Steuerpflicht per; Art der Abrechnung; Methode; Tätigkeiten | unbedingt |
| Freiwillige Unterstellung Art. 11 | bedingt, nur unter der Schwelle |

### 2.6 AHV / UVG

AHV: Handelsregistereintrag, Verbandszugehörigkeit, Anzahl Kunden, zuletzt Beiträge, Mitarbeit, Einkommensschätzung, Risiko-Freitext, Personalzahlen, UVG-Name, BVG-Anschluss, Kontoinhaber/IBAN, Korrespondenzadresse unbedingt (teils bedingt nach Auswahl).

UVG: Mitarbeiterzahlen, Lohnsummen, Prämienzyklus, Kontoart, Ansprechperson, Korrespondenz, Weiterfahren, Versicherer unbedingt.

Mengenvorgaben, keine einzelne Spalte: KlG mindestens zwei natürliche Gesellschafter; KmG mindestens ein unbeschränkt und ein beschränkt Haftender; AG mindestens ein Verwaltungsrat.

## 3. Einheitlicher allgemeiner Kern

Dieser Kern wird einmalig erhoben und in HR/MWST/AHV/UVG vorbefüllt. Formularspezifische Wiederholungen stehen in der Rohfassung.

| Objekt | Datenfeld | Portal (Beispiele) |
|---|---|---|
| Fall | Fall-ID, Rechtsform, Umsatzband, Personal, Extern Erledigtes, digitale Signatur | Meldepflichten |
| Unternehmen | Bezeichnung, Zweck, Branche, Domizil, Geschäftsaufnahme, Jahresende, MWST-ID | Basisdaten, HR Diverses |
| Person | Name, AHV, Wohnsitz, Ausweis, Funktion, Zeichnung | Basisdaten, HR Gründer/Vertreter, MWST Inhaber |
| Adresse | Strasse, Nummer, Zusatz, Postfach, PLZ, Ort, Gemeinde, Land, Telefon, E-Mail | Wohnsitz, Domizil, Korrespondenz |
| Kapital | Betrag, Währung, Liberierung, Anteile, Nennwert, Bank/Konto/Datum der Einzahlung | HR GmbH/AG; Bankfelder Kanzlei |
| Meldepflicht-Resultat | HR, MWST, AHV, UVG | Ergebnisfelder, nicht Mandantenwürdigung |

## 4. Wiederholbare Datenobjekte

Nicht in Freitextfeldern sammeln. Jeder Datensatz: Fall-ID, Objekt-ID, laufende Nummer.

| Objekt | Kernfelder |
|---|---|
| Person | Rolle, Personentyp (auch GmbH/AG-Gesellschafter juristische Person), Personalien, Adresse, Funktion, Zeichnung, Haftung (KmG) |
| Beteiligung / Anteil | Person, Anzahl Stammanteile bzw. Namens-/Inhaberaktien |
| Standort | weitere Geschäftslokale (Portal optional; hier vorerst Freitext, Ausbau offen) |
| Dokument | Dokumenttyp, Hinweis, Bezug |

## 5. Empfohlene Forms-Architektur

Ein einzelnes MS Forms-Formular kann wiederholbare Tabellen nicht belastbar abbilden. Fallnummer als Schlüssel, analog DE/AO Abschnitt 6:

| Form | Liste | Zweck | Auslöser |
|---|---|---|---|
| 0. Fallsteuerung | `CH_0_Fallsteuerung` | Rechtsform, Umsatz, Personal, Extern Erledigtes, Resultat (Kanzlei) | immer |
| 1. Unternehmen | `CH_1_Unternehmen` | Firma, Zweck, Branche, Domizil | immer |
| 2. Personen | `CH_2_Personen` | Inhaber, Gesellschafter, Vertreter | immer; Anzahl nach Rechtsform |
| 3. Kapital | `CH_3_Kapital`, `CH_3_Anteile` | Stamm-/Aktienkapital, Liberierung, Anteile | GmbH, AG, KmG-Kommandite |
| 4. HR Diverses | `CH_4_HR_Diverses` | Auszüge, Notar, Anmeldungsart, Bemerkungen, Statutenangaben | wenn HR |
| 5. MWST | `CH_5_MWST` | ESTV-spezifische Umsatz- und Modalitätenfelder | wenn MWST |
| 6. AHV | `CH_6_AHV` | Ausgleichskasse, Selbständigkeit, Personal | wenn AHV |
| 7. UVG | `CH_7_UVG` | Lohnsummen, Versicherer | wenn UVG |
| 8. Unterlagen | `CH_8_Unterlagen` | Belege (EasyGov hat in der Gründung keine Uploads) | immer, bedingt |

In `felder.json` stehen die logischen Namen ohne Präfix (`0_Fallsteuerung`, …). Das SharePoint-Skript hängt den Parameter `-ListPrefix` an (Standard `CH_`), damit dieselben Titel wie die DE/AO-Listen auf `sites/steueranwaltskanzlei` nicht überschrieben werden.

### Technische Mindestfelder in jeder Antwort

`case_id | form_type | object_type | object_id | field_key | field_label | value | data_type | required_status | condition | source | verification_date`

Zulässige Pflichtstatus: `unbedingt`, `bedingt`, `optional`, `ergebnis`, `system`. Umsetzung: Liste `CH_Technische_Mindestfelder`.

SharePoint kennt keine bedingten Pflichtfelder. `-Required` nur bei unbedingter Pflicht für jeden Datensatz der Liste. Ja/Nein-Pflichtfelder als Choice «Ja»/«Nein», nicht als Boolean (Befund DE/AO 28.10.2026).

Interne Feldnamen: höchstens 32 Zeichen, nur `[A-Za-z0-9_]`.

## 6. Trennung Tatsachen / Rechtsfolgen

Der Mandant liefert Tatsachen. Die Meldepflichten-Resultate (HR/MWST/AHV/UVG zwingend oder freiwillig) sind Ergebnisfelder der Kanzlei, auch wenn EasyGov sie im Cockpit anzeigt. Grundlage: [`meldepflichten-matrix.json`](meldepflichten-matrix.json). Kein Automatismus ohne Bestätigung durch eine berufsrechtlich zugelassene Person.

## 7. Übergabeprinzip

1. Forms/Listen speichern fachlich normalisierte Daten, nicht bloss EasyGov-Feldnamen.
2. `felder.json` ordnet jedem Portalvorkommen Liste, internen Namen, Datentyp und Werteliste zu.
3. Vor einer Portalübertragung prüft die Kanzlei Pflichtfelder und Mengenvorgaben.
4. Anhänge als Dokumentobjekte mit Bezug zum Sachverhalt; Papierwege (KlG/KmG, EU ohne QES) bleiben postalisch.

## 8. Offene Validierungspunkte

Siehe [`luecken-und-offene-punkte.md`](luecken-und-offene-punkte.md). Portalfehler und ungespielte Pfade bleiben offen. Die Blöcke unter `nicht_abgefragt` haben Kanzlei-Spalten (Statuten, Revisionsstelle, Opting-out, Vinkulierung, Nachschuss, Nebenleistung, Publikationsorgan, Bank/Kapitaleinzahlung, Nennwert, Sachübernahme als Liberierungswert, MWST-IBAN, Suva-Zweig, `person_type` auch für GmbH/AG). Keine Rechtswürdigung in den Listen.

Anzeige-Felder mit `sharepoint_*`-Mapping werden als Spalten geführt, weil das Datenmodell Adresse (inkl. Gemeinde) und fachlich normalisierte Werte speichert, nicht nur das, was das Portal als editierbares Eingabefeld zeigt. Mappinglose Anzeigen bleiben ohne Spalte.
