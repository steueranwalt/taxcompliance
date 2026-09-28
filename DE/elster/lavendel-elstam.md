# LAVENDEL Datenübermittler v2.0.1 (ELStAM)

## 1. Zweck

Verwaltung, **wer** (welcher Datenübermittler) für welchen Arbeitgeber Elektronische LohnSteuerAbzugsMerkmale (ELStAM) abrufen darf: Anmeldung/Abmeldung von Arbeitnehmern beim Datenübermittler, Wechsel des Datenübermittlers, sowie Abruf von Änderungslisten (Monats-/Bruttolisten). Fachlich „LAVENDEL"/ELStAM, technisch über das ElsterXML-Verfahren `ElsterLohn2` transportiert.

## 2. Daten: Verfahren / Datenart / Vorgang

| Verfahren | Datenart | Vorgang |
|---|---|---|
| ElsterLohn2 | DUeAnmelden | send-Auth |
| ElsterLohn2 | DUeAbmelden | send-Auth |
| ElsterLohn2 | DUeUmmelden | send-Auth |
| ElsterLohn2 | AenderungslisteDUe / AenderungslisteElstam (Header-Enums) | send-Auth |

### Message-Typen (Schema, `elster11_lavendel_extern-v2.xsd` + `datenuebermittler-v201/`)

- `ArbeitnehmerAnmeldenRequest` — Element `ArbeitnehmerAn` mit Feldern: `idnr`, `gebdat`, `istHauptarbeitgeber`, `beschaeftigungsbeginn`, `refDatumAG`, `stnrAG`.
- `ArbeitnehmerAbmeldenRequest`.
- `DatenuebermittlerWechselRequest`.
- `Aenderungsliste` — Attribut `Art` mit den Werten: `BRUTTOLISTE`, `MONATSLISTE`, `ANMELDEBESTAETIGUNGSLISTE`, `ABMELDEBESTAETIGUNGSLISTE`, `UMMELDEBESTAETIGUNGSLISTE`.

Beispiel-Instanzen zu diesen Nachrichtentypen liegen nicht im LAVENDEL-Paket selbst, sondern im Mock-Paket — siehe [`hms-mock.md`](hms-mock.md).

## 3. Taxonomie / Kataloge

- SimpleTypes für Steuerklasse und Konfession (ELStAM-spezifische Wertebereiche) — im Schema-Ordner `resources/`, nicht separat als eigenständiger Katalog in diesem Repo aufbereitet.
- `Aenderungsliste`-Art-Enum (s. o.).
- Verfahrenshinweise als Prosa-PDF (`Verfahrenshinweise_LAVENDEL_V-201.pdf`).

## 4. Quellen

- Paket: `LAVENDEL_Datenuebermittler_Version_2.0.1.zip`, Version 2.0.1 (Stand 03.07.2025). Lokal vollständig extrahiert.
- `extracted/LAVENDEL_Datenuebermittler_Version_2.0.1/v201/readme.txt`
- `extracted/LAVENDEL_Datenuebermittler_Version_2.0.1/v201/Dokumentation/Schnittstellenbeschreibung_LAVENDEL_V-201.pdf`
- `extracted/LAVENDEL_Datenuebermittler_Version_2.0.1/v201/Dokumentation/Verfahrenshinweise_LAVENDEL_V-201.pdf`
- `extracted/LAVENDEL_Datenuebermittler_Version_2.0.1/v201/resources/elster11_lavendel_extern-v2.xsd`
- `extracted/LAVENDEL_Datenuebermittler_Version_2.0.1/v201/resources/datenuebermittler-v201/`
- Portal-Name: `LAVENDEL_Datenuebermittler_Version_2.0.1.zip`.

## 5. Gaps / offene Punkte

- SimpleType-Wertelisten für Steuerklasse/Konfession sind im Schema vorhanden, aber in diesem Repo nicht als eigener Katalog ausgezählt/dokumentiert (kein eigenes `kataloge/*.md`, da im Inventar nicht mit Counts erfasst).
- Beispielinstanzen der o. g. Request-Typen liegen praktisch nur im HMS-Mock-Paket vor, nicht im LAVENDEL-Paket selbst — für Konformitätstests beide Pakete zusammen heranziehen.
