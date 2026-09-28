# HMS Auslieferungspaket Hersteller v2.0.1 (ELStAM-Mock)

## 1. Zweck

Hersteller-Mock-System (HMS) zum Testen der LAVENDEL-/ELStAM-Anbindung ohne Produktivumgebung. Kein Produktivverfahren — liefert Beispiel-/Template-XML für die in [`lavendel-elstam.md`](lavendel-elstam.md) beschriebenen Nachrichtentypen.

## 2. Daten: Verfahren / Datenart / Vorgang

| Verfahren | Datenart | Vorgang |
|---|---|---|
| ElsterLohn2 (Test) | DUeAnmelden | send-Auth |
| ElsterLohn2 (Test) | DUeAbmelden | send-Auth |
| ElsterLohn2 (Test) | DUeUmmelden | send-Auth |
| ElsterLohn2 (Test) | Aenderungsliste-* | send-Auth |

Fachlich identisch mit LAVENDEL (siehe [`lavendel-elstam.md`](lavendel-elstam.md)); der Unterschied liegt in der Testumgebung/Mock-Semantik, nicht im Nachrichtenformat.

### Inhalt des Pakets

Templates je Geschäftsvorfall-IdNr: Anmelden / Abmelden / Ummelden sowie die zugehörigen Änderungslisten, organisiert in den Ordnern `HMS-Template-XML_V2_0_1/` und `HMS-XML_V2_0_1/`.

## 3. Taxonomie / Kataloge

- **Geschäftsvorfall-Katalog:** IdNr-Nummernkreise je Template, dokumentiert in `HMS_Geschäftsvorfälle_IdNr_V2_0_1.xlsx`. Ordnet einer Test-IdNr einen bestimmten Geschäftsvorfall (z. B. „erfolgreiche Anmeldung", „Fehlerfall X") zu.

## 4. Quellen

- Paket: `HMS_Auslieferungspaket_Hersteller_V2_0_1.zip`, Version 2.0.1 (Stand 09.07.2025). Lokal vollständig extrahiert.
- `extracted/HMS_Auslieferungspaket_Hersteller_V2_0_1/HMS_Auslieferungspaket_Hersteller_V2_0_1/dokumentation/`
- `extracted/HMS_Auslieferungspaket_Hersteller_V2_0_1/HMS_Auslieferungspaket_Hersteller_V2_0_1/HMS-Template-XML_V2_0_1/`
- `extracted/HMS_Auslieferungspaket_Hersteller_V2_0_1/HMS_Auslieferungspaket_Hersteller_V2_0_1/HMS-XML_V2_0_1/`
- Portal-Name: `HMS_Auslieferungspaket_Hersteller_V2_0_1.zip`.

## 5. Gaps / offene Punkte

- Die genaue Zuordnung IdNr-Nummernkreis → Geschäftsvorfall wurde aus der Excel-Datei nicht zeilenweise extrahiert (nur als Katalog referenziert, kein Dump in diesem Repo).
- Rein für Testzwecke relevant — keine Auswirkung auf produktive Feldkataloge.
