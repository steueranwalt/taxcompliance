# Substanzprüfung Holding-KG

Datenerhebung zur personellen, sachlichen und organisatorischen Ausstattung der Holding-KG und zur tatsächlich ausgeübten Managementtätigkeit — unabhängig von der Konzernstruktur als solcher. Fachliche Vorgabe: Nils Obenhaus, ausgearbeiteter Erfassungsbogen-Entwurf, Projekt 22032-2, Arbeitsfassung 27.10.2026 (**Update 1**, ersetzt die frühere Grobvorgabe vollständig).

## Dokumente

| Dokument | Rolle |
|---|---|
| [Einheitliches Datenmodell](Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md) | Architektur, 20 Listen + Dokumentbibliothek, Wiederverwendungsentscheidungen, Berechtigungskonzept `InterneBewertungen` |
| [Fragenkatalog](Fragenkatalog-Substanzpruefung-Holding-KG.md) | alle Fragen (P/E/V/K/G/R/A/C/N) mit stabilen IDs, Mandantensicht/interner Hinweis getrennt, P09-Handlungstabelle |
| [Interner Anhang A](interner-anhang-a-auswertungslogik.md) | NUR INTERN: Auswertungslogik, Rechtsprechung, VP-Zuordnungstabelle — nicht an Mandanten versenden |
| [`feldkatalog/feldkatalog.json`](feldkatalog/feldkatalog.json) | maschinenlesbarer Feldkatalog (Formular, Frage-ID, Unterfeld-Suffix, Antworttyp, Auswahlcode, Pflichtbedingung, ZielListe, ZielSpalte, Version) + Codebooks |
| [`sharepoint-forms/README.md`](sharepoint-forms/README.md) | Forms-Aufteilung (7 Blätter), Flow-Spezifikation, Prüfregeln, Datei-Upload-Konzept |
| [`sharepoint-forms/KLICKANLEITUNG-FORMS.md`](sharepoint-forms/KLICKANLEITUNG-FORMS.md) | Klickanleitung für die 7 Formulare |
| [`sharepoint-forms/New-SubstanzHoldingKGListen.ps1`](sharepoint-forms/New-SubstanzHoldingKGListen.ps1) | idempotentes PnP-PowerShell-Skript (20 Listen + Dokumentbibliothek), aus dem Feldkatalog erzeugt |

## Verhältnis zur steuerlichen Erfassung (`DE/AO/`)

Dieses Modul folgt denselben Grundkonventionen (Idempotenz, Spaltentypen, Flow-Muster) wie [`DE/AO/sharepoint-forms/`](../AO/sharepoint-forms/README.md) und nutzt `Eingang_Fehler` mit; `4_Beteiligte_und_Quoten` dient optional als Cross-Reference beim Aufbau des `Gesellschaften`-Bestands. Begründung je Liste: siehe Datenmodell, Abschnitt 4 ("Wiederverwendung"). `New-SubstanzHoldingKGListen.ps1` setzt voraus, dass `DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1` auf derselben Zielsite bereits gelaufen ist.

## Status

Noch nicht gegen einen Tenant ausgeführt. Offene fachliche Fragen an Nils: siehe Datenmodell, Abschnitt 7.
