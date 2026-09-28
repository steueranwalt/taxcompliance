# Katalog: Prüfziffernverfahren Steuernummer/IdNr. (+ Grundsteuer-Ordnungskriterien)

## 1. Zweck

Beschreibt die Prüfziffernverfahren für die Steuernummer (je Bundesland unterschiedlich) und die Steuer-Identifikationsnummer (IdNr., bundeseinheitlich), sowie die Ordnungskriterien der Grundsteuer je Bundesland.

## 2. Daten: Verfahren / Datenart / Vorgang

Kein eigenes ElsterXML-Verfahren — Validierungslogik/Referenzkatalog. Die Grundsteuer-Datenarten sind fachlich mit der Datenabholung (siehe [`../datenabholung.md`](../datenabholung.md)) und potenziell künftigen Grundsteuer-Formularverfahren verknüpft, liegen aber selbst nicht als ElsterXML-Verfahren im Inventar vor.

### Verfahrenstyp je Bundesland (Steuernummer)

| Bundesland | Verfahren |
|---|---|
| Bayern, Berlin, Brandenburg, Bremen, Hamburg, Mecklenburg-Vorpommern, Niedersachsen, NRW, Saarland, Sachsen, Sachsen-Anhalt, Thüringen | 11er-Verfahren |
| Baden-Württemberg | 2er-Verfahren |
| Hessen, Schleswig-Holstein | modifiziertes 11er-Verfahren |
| Rheinland-Pfalz | eigene Spalte in Quelltabelle (abweichend markiert) |

Die IdNr. hat unabhängig vom Bundesland ein bundeseinheitliches 11er-Modulo-Verfahren über die ersten 10 Stellen (Kap. 2.2 der Quelle, mit Pseudocode).

### Grundsteuer — Landesnummer, Datenart/Modell, Ordnungskriterium

| Bundesland | Landesnummer | Datenart/Modell | Ordnungskriterium |
|---|---:|---|---|
| Baden-Württemberg | 28 | GrundsteuerBW | Aktenzeichen |
| Bayern | 9 | GrundsteuerBY | Aktenzeichen |
| Berlin | 11 | Grundsteuerwert (Bundesmodell) | Steuernummer |
| Brandenburg | 30 | Grundsteuerwert (Bundesmodell) | Aktenzeichen |
| Bremen | 24 | Grundsteuerwert (Bundesmodell) | Steuernummer |
| Hamburg | 22 | GrundsteuerHH | Steuernummer |
| Hessen | 26 | GrundsteuerHE | Aktenzeichen |
| Mecklenburg-Vorpommern | 40 | Grundsteuerwert (Bundesmodell) | Aktenzeichen |
| Niedersachsen | 23 | GrundsteuerNI | Aktenzeichen |
| Nordrhein-Westfalen | 5 | Grundsteuerwert (Bundesmodell) | Aktenzeichen |
| Rheinland-Pfalz | 27 | Grundsteuerwert (Bundesmodell) | Aktenzeichen |
| Saarland | 10 | Grundsteuerwert (Bundesmodell) | Aktenzeichen |
| Sachsen | 32 | Grundsteuerwert (Bundesmodell) | Aktenzeichen |
| Sachsen-Anhalt | 31 | Grundsteuerwert (Bundesmodell) | Aktenzeichen |
| Schleswig-Holstein | 21 | Grundsteuerwert (Bundesmodell) | Steuernummer |
| Thüringen | 41 | Grundsteuerwert (Bundesmodell) | Aktenzeichen |

**Wichtig für Erfassung:** In der Grundsteuererklärung ist nicht das Wohnsitz-Finanzamt der steuerpflichtigen Person, sondern das **Lage-Finanzamt des Grundstücks** massgebend (ausdrücklicher Hinweis der Quelle).

### Bundesland-Sonderfälle

Bayern: Finanzamtsnummer wird in der gedruckten Steuernummer zunehmend weggelassen. Hessen: führende Null in der Steuernummer entfällt. Berlin: zwei Prüfzifferverfahren mit Bezirksausnahmen (Bezirke 201–693 nutzen Verfahren B). Detailtabellen je Bundesland (Aufbau der Steuernummer, Umrechnungsformel Finanzamt ↔ vereinheitlichte Steuernummer): Kap. 8.2 der Quelle, je Bundesland ein eigener Abschnitt (Baden-Württemberg, Berlin, Bremen, Hamburg, Hessen, Niedersachsen, NRW, Schleswig-Holstein).

## 3. Taxonomie / Kataloge

Dies **ist** der Katalog. Verwandt: [`finanzamtsdaten.md`](finanzamtsdaten.md) (BUFA-Nummer-Bereiche je Bundesland, Kap. 9 derselben Quelle).

## 4. Quellen

- `Pruefung_der_Steuer_und_Steueridentifikatsnummer.pdf`, Stand 15.04.2026 (116 Seiten).
- Portal-Name: `Pruefung_der_Steuer_und_Steueridentifikatsnummer.pdf`.

## 5. Gaps / offene Punkte

- Die Grundsteuer-Datenarten (`Grundsteuerwert`, `GrundsteuerBY`, `GrundsteuerBW`, `GrundsteuerHE`, `GrundsteuerHH`, `GrundsteuerNI`) sind hier nur als Nomenklatur aus der Prüfziffer-Doku übernommen — ein eigenes ElsterXML-Verfahren/Schema für die Grundsteuererklärung liegt in den ELSTER-Entwickler-Paketen **nicht** vor (siehe Gap-Liste in [`../README.md`](../README.md)).
- Detailtabellen je Bundesland (Kap. 8.2) wurden nicht Zeile für Zeile in dieses Repo übernommen, nur referenziert.
- Referenztabelle Bundesland/Länderschlüssel/BUFA-Nummern-Bereich (Kap. 9) ist im Prüfziffer-PDF, nicht in `Finanzamtsdaten.xlsx` selbst — siehe [`finanzamtsdaten.md`](finanzamtsdaten.md).
