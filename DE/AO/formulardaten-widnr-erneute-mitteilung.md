# Formulardaten: Antrag auf erneute Mitteilung der Wirtschafts-Identifikationsnummer

**Stand der Auswertung:** 31.08.2026

**Quellen:**

- FMS-XML-Rohinstanz (leer): [`quellen/FRM_WIdNr_erneute_Mitteilung.xml`](quellen/FRM_WIdNr_erneute_Mitteilung.xml) → `catalog://Unternehmen/wid/widnr`
- Rechtsgrundlage der Nummer: §§ 139a, 139c AO; Vergabe/Mitteilung durch BZSt / ELSTER

## Abgrenzung zum AO-Erfassungsbestand

| | Dieses Formular | ELSTER-Fragebögen / Datenmodell |
|---|---|---|
| Zweck | erneute Zustellung/Abruf der bereits zugeteilten W-IdNr. | steuerliche Erfassung; W-IdNr. als Identifikationsfeld |
| Overlap | Bezug auf wirtschaftlich Tätigen / Identifikation | Feld «Wirtschafts-Identifikationsnummer» in Start-/Stammblöcken |
| Separat zu führen | Verwaltungsvorgang «erneute Mitteilung» (kein Erfassungsfragebogen) | — |

Die W-IdNr. selbst gehört in den allgemeinen Identifikationskern. Dieses Formular ist ein **separater BZSt-/FMS-Vorgang**, kein ELSTER-Erfassungsfragebogen und kein BZSt2.

## Bekannter Inhalt der Rohinstanz

| Element | Wert |
|---|---|
| Formular | `catalog://Unternehmen/wid/widnr` |
| Instanz | leere `<datarow />` — keine fachlichen Felder im Export |

## Fachlicher Rahmen (ohne Feldliste aus dem Leer-Export)

Solange die FMS-Instanz leer ist, sind nur Rahmenangaben dokumentierbar:

- **Automatische Vergabe:** kein Erstantrag nötig; Zuteilung durch BZSt (u. a. über ELSTER-Postfach bzw. öffentliche Bekanntmachung bei bestehender USt-IdNr.).
- **Erneute Mitteilung:** über FMS/BZSt auslösbar, wenn das Mitteilungsschreiben erneut benötigt wird.
- **Format:** `DE` + 9 Ziffern; Unterscheidungsmerkmal je wirtschaftlicher Tätigkeit möglich.
- **Bezug Erfassung:** in den Fragebögen erscheint die W-IdNr. bereits als Datenfeld (siehe [`formulardaten-roherfassung.md`](formulardaten-roherfassung.md)); Mapping dort belassen.

## Offener Punkt

Feldgenaue Kz/XML-IDs des Antragsformulars nachziehen, sobald ein ausgefüllter FMS-Export oder die amtliche Feldhilfe vorliegt.
