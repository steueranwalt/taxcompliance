# Katalog: Finanzamtsdaten (GEMFA)

## 1. Zweck

Amtliche Liste aller Finanzämter (inkl. Test-Finanzämter), gepflegt im GEMFA-Verfahren (Version 2.0). Referenzkatalog für die `steuernummer`/Finanzamtsauflösung in [`../kontoabfrage.md`](../kontoabfrage.md) und für jede Nachricht, die ein Empfänger-Finanzamt benennt.

## 2. Daten: Verfahren / Datenart / Vorgang

Kein eigenes Verfahren — reiner Stammdatenkatalog.

### Schema

Je Bundesland ein Tabellenblatt (Sheet). Spalten:

| Spalte | Bedeutung |
|---|---|
| `Finanzamtsnummer` | BUFA-Nummer, 4-stellig |
| `Finanzamtsname` | Klartextname |
| `ÄnderungsInformationen` | `KEIN_DELTA` / `NEU` / `GELOESCHT` / `GEAENDERT` … (Datei ist diff-fähig ausgeliefert) |

Zusätzliches Sheet „Allg. Information": Diff-Angabe 15.04.2026 vs. 19.01.2026.

### Umfang

40 Sheets gesamt; ~566 Produktiv-Zeilen + ~186 Test-Zeilen.

## 3. Taxonomie / Kataloge

Dies **ist** der Katalog. Verwandt: [`pruefziffern-steuernummer-idnr.md`](pruefziffern-steuernummer-idnr.md) (Prüfziffernverfahren, das die `Finanzamtsnummer` als Teil der Steuernummer nutzt).

## 4. Quellen

- `Finanzamtsdaten.xlsx`, Stand 15.04.2026 (GEMFA 2.0, Diff gegen 19.01.2026).
- Portal-Name: `Finanzamtsdaten.xlsx`.

## 5. Gaps / offene Punkte

- Vollständige BUFA-Nummer-Bereiche je Bundesland wurden nicht Zeile für Zeile in dieses Repo übernommen; Referenztabelle Bundesland/Länderschlüssel/BUFA-Nummern-Bereich befindet sich stattdessen in Kapitel 9 der Prüfziffer-Dokumentation, siehe [`pruefziffern-steuernummer-idnr.md`](pruefziffern-steuernummer-idnr.md).
- Diff-Mechanik (`ÄnderungsInformationen`) wurde nur strukturell beschrieben; ein konkretes Delta-Beispiel wurde nicht extrahiert.
