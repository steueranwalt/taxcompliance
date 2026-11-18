# SharePoint-Listen + Microsoft-Forms-Familie «EasyGov Unternehmensgründung CH»

Quellen: [`../Einheitliches-Datenmodell-easygov-unternehmensgruendung.md`](../Einheitliches-Datenmodell-easygov-unternehmensgruendung.md), [`../felder.json`](../felder.json).

Vertraulichkeit: Nur Schema-/Metadaten. Keine Mandats- oder Klientendaten. Beim Testdurchlauf ausschliesslich Dummy-Daten.

Die Mechanik (PnP, ClientId, DateOnly, Required-Boolean-Falle, 32-Zeichen-Grenze, keine bedingten Pflichtfelder) ist dieselbe wie in [`DE/AO/sharepoint-forms/README.md`](../../../DE/AO/sharepoint-forms/README.md) Abschnitte A–C2. Hier nur die EasyGov-Abweichungen.

Zielsite laut Entscheid: `https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei`. Dort laufen bereits die produktiven DE/AO-Listen. Dieses Skript darf sie nicht anfassen.

## A. Listenerstellung

```powershell
.\New-EasyGovGruendungListen.ps1 -WhatIf
.\New-EasyGovGruendungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei" -ClientId "<Entra-App-ClientId>"
```

Leitet die Spalten aus `felder.json` ab. Logische Listennamen im Katalog bleiben ohne Präfix; zur Laufzeit gilt `-ListPrefix` (Standard `CH_`). Angelegte bzw. angeglichene Listen:

`CH_0_Fallsteuerung`, `CH_1_Unternehmen`, `CH_2_Personen`, `CH_3_Kapital`, `CH_3_Anteile`, `CH_4_HR_Diverses`, `CH_5_MWST`, `CH_6_AHV`, `CH_7_UVG`, `CH_8_Unterlagen`, `CH_Technische_Mindestfelder`, `CH_Eingang_Fehler`.

`case_id` in Folgelisten: Lookup auf `CH_0_Fallsteuerung` mit `RelationshipDeleteBehavior=Restrict`. `person_label` in `CH_3_Anteile`: Lookup auf `CH_2_Personen.display_label`.

### Kollisionsschutz

Vor jeder Änderung bricht das Skript hart ab, wenn ein aufgelöster Listentitel nicht mit `CH_` beginnt. Damit bleiben `0_Fallsteuerung` … `9_Grundbesitz`, `8_Unterlagen`, `Technische_Mindestfelder` und `Eingang_Fehler` der DE/AO-Familie unangetastet. Idempotenz: fehlende Listen/Spalten anlegen, Anzeigenamen/Pflicht/fehlende Choices angleichen, nie löschen.

### Trockenlauf

`-WhatIf` verbindet nicht, schreibt nicht und listet nur, welche Listen und Spalten sichergestellt (angelegt oder angeglichen) würden. `SiteUrl`/`ClientId` sind dann nicht Pflicht.

## B. Prüfskript

```powershell
.\Test-EasyGovGruendungListen.ps1
.\Test-EasyGovGruendungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei" -ClientId "<Entra-App-ClientId>"
```

Ohne Site: statisch (ruft `../tests/test_konsistenz.py` auf, prüft Abdeckung von `felder.json` und `luecken.json` gegen die Skriptspalten, erwartet Lookup für `case_id`/`person_label`). Mit Site: zusätzlich lesender Soll/Ist-Abgleich gegen die `CH_`-Listen. Exit 0 = `ERGEBNIS: OK`.

Lokal/CI ohne PowerShell:

```
python3 ../tests/test_konsistenz.py
```

## C. Forms-Familie

Fragen 1:1 aus den Listenspalten, Labels aus dem Feldkatalog. Fall-ID jeweils erste Frage. Branching: bedingte Portalpflichten (Ausländer-Ausweis, Liberierung, Saldosteuersatz, Verbands-AK, UVG-IBAN). Kanzlei-Ergebnisfelder (Meldepflicht-Resultat) nicht an Mandanten.

Klicks: [`KLICKANLEITUNG-FORMS.md`](KLICKANLEITUNG-FORMS.md).

Routing aus Formular 0:

| Bedingung | Folgeformulare |
|---|---|
| immer | 1 Unternehmen, 2 Personen, 8 Unterlagen |
| GmbH oder AG | 3 Kapital, 4 HR Diverses |
| KlG oder KmG | 4 HR Diverses (Papier), KmG zusätzlich Kapital/Kommandite in Personen |
| Resultat MWST zwingend oder freiwillig gewünscht | 5 MWST |
| Resultat AHV zwingend | 6 AHV |
| Resultat UVG zwingend oder freiwillig | 7 UVG |

## D. Portalgrenzen, die als Kanzlei-Spalten erfasst werden

EasyGov fragt Statuten, Revisionsstelle/Opting-out, Vinkulierung/Nachschuss/Nebenleistung/Publikationsorgan, Bank/Kapitaleinzahlung, Nennwert, MWST-IBAN, Suva-Zweig und juristische GmbH/AG-Gesellschafter nicht ab. Das sind Tatsachen-Spalten der Kanzlei (siehe `luecken.json` `nicht_abgefragt` und Abschnitt E), keine Rechtswürdigung. Dateien bleiben in `CH_8_Unterlagen` (inkl. `file_link`).

## E. Anzeige-Felder mit SharePoint-Mapping

EasyGov zeigt einige Werte nur an (Gemeinde aus PLZ, HR-Amt, MWST-Summen, vorgeschlagene UVG-Versicherung). Das Datenmodell speichert Adresse inkl. Gemeinde und fachlich normalisierte Zahlen. Deshalb legt das Skript diese gemappten `anzeige`-Felder als Spalten an (`resMunicipality`, `domMunicipality`, `hr_office`, `rev3m_total`, `rev3m_relevant`, `suggested_insurer`). Reine Portalhinweise ohne Mapping bleiben ohne Spalte.

`CH_8_Unterlagen.file_link` ist analog DE/AO ein Hyperlink (URL) für Dateien ausserhalb von Forms.

Neue bzw. nachgetragene Kanzlei-Spalten (`pflichtstatus` `nicht_erfasst`, keine Rechtswürdigung):

| Liste (logisch → SharePoint) | Interner Name | Typ | Lücke |
|---|---|---|---|
| `4_HR_Diverses` → `CH_4_HR_Diverses` | `statutes_note` | Note | Statuten |
| `4_HR_Diverses` → `CH_4_HR_Diverses` | `auditor_name` | Text | Revisionsstelle |
| `4_HR_Diverses` → `CH_4_HR_Diverses` | `opting_out` | Choice Ja/Nein | Opting-out |
| `4_HR_Diverses` → `CH_4_HR_Diverses` | `transfer_restriction` | Choice Ja/Nein | Vinkulierung |
| `4_HR_Diverses` → `CH_4_HR_Diverses` | `capital_call_duty` | Choice Ja/Nein | Nachschusspflicht |
| `4_HR_Diverses` → `CH_4_HR_Diverses` | `accessory_duty` | Choice Ja/Nein | Nebenleistungspflicht |
| `4_HR_Diverses` → `CH_4_HR_Diverses` | `publication_organ` | Text | Publikationsorgan |
| `3_Kapital` → `CH_3_Kapital` | `capital_bank` | Text | Bank |
| `3_Kapital` → `CH_3_Kapital` | `capital_account` | Text | Konto oder IBAN |
| `3_Kapital` → `CH_3_Kapital` | `capital_paid_date` | DateOnly | Datum Kapitaleinzahlung |
| `3_Kapital` → `CH_3_Kapital` | `par_value` | Number | Nennwert |
| `5_MWST` → `CH_5_MWST` | `mwst_iban` | Text | MWST-IBAN |
| `7_UVG` → `CH_7_UVG` | `suva_branch` | Text | Suva-Zweig |
| `8_Unterlagen` → `CH_8_Unterlagen` | `file_link` | URL | analog DE/AO |
| `2_Personen` → `CH_2_Personen` | `person_type` | Choice (jetzt auch GmbH/AG) | juristische Person als Gesellschafter |
| `3_Kapital` → `CH_3_Kapital` | `liberation_types` | MultiChoice + Wert «durch Sachübernahme» | Sachübernahme |
