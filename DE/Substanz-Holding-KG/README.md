# Substanzprüfung Holding-KG

Datenerhebung zur personellen, sachlichen und organisatorischen Ausstattung der Holding-KG und zur tatsächlich ausgeübten Managementtätigkeit — unabhängig von der Konzernstruktur als solcher. Fachliche Vorgabe: Nils Obenhaus, Erfassungsbogen Holding-KG **Version 3**, Projekt 22032-2 (**Update 2**, ersetzt Version 1 und Version 2 vollständig). Kernänderung: Gegenstand ist das **Tagesgeschäft**, nicht einzelne Vorgänge — Bezugseinheit ist die tatsächlich ausgeübte Aufgabe je Person, Gesellschaft und Zeitraum.

## Dokumente

| Dokument | Rolle |
|---|---|
| [Einheitliches Datenmodell](Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md) | Architektur, 25 Listen + Dokumentbibliothek, Listensplit-Begründungen, Wiederverwendung, Berechtigungskonzept, Änderungsprotokoll V2→V3 |
| [Fragenkatalog](Fragenkatalog-Substanzpruefung-Holding-KG.md) | alle Fragen (S, H, T, D, V, K, G, P, Z, O, R, A, C, N) mit stabilen IDs, Mandantensicht/interner Hinweis getrennt |
| [`feldkatalog/feldkatalog.json`](feldkatalog/feldkatalog.json) | maschinenlesbarer Feldkatalog (SchemaVersion 3) + Codebooks + Änderungsprotokoll |
| [`sharepoint-forms/README.md`](sharepoint-forms/README.md) | Forms-Aufteilung (5 Blätter), Flow-Spezifikation, Prüfregeln |
| [`sharepoint-forms/KLICKANLEITUNG-FORMS.md`](sharepoint-forms/KLICKANLEITUNG-FORMS.md) | Klickanleitung |
| [`sharepoint-forms/New-SubstanzHoldingKGListen.ps1`](sharepoint-forms/New-SubstanzHoldingKGListen.ps1) | idempotentes PnP-PowerShell-Skript (25 Listen + Dokumentbibliothek) |
| [`interner-anhang-a-tagesgeschaeft-ueberarbeitung.md`](interner-anhang-a-tagesgeschaeft-ueberarbeitung.md) | NUR INTERN: Anhang A V3 — Begründung Schemawechsel auf Tagesgeschäft |
| [`interner-anhang-c-historie.md`](interner-anhang-c-historie.md) | NUR INTERN: Anhang C — Korrespondenztabelle V1→V3 |
| [`interner-anhang-d-rechtliche-hintergruende.md`](interner-anhang-d-rechtliche-hintergruende.md) | NUR INTERN: Anhang D (= Anhang A in V1) — rechtliche Recherche |
| [`interner-anhang-e-historischer-fragenvorrat-v1.md`](interner-anhang-e-historischer-fragenvorrat-v1.md) | NUR INTERN: Anhang E — historischer Fragenvorrat V1, nicht mandantenfähig |

## Verhältnis zur steuerlichen Erfassung (`DE/AO/`)

Dieses Modul folgt denselben Grundkonventionen wie [`DE/AO/sharepoint-forms/`](../AO/sharepoint-forms/README.md) und nutzt `Eingang_Fehler` mit; `4_Beteiligte_und_Quoten` dient optional als Cross-Reference beim Aufbau des `Gesellschaften`-Bestands. Begründung je Liste: siehe Datenmodell, Abschnitt 5. `New-SubstanzHoldingKGListen.ps1` setzt voraus, dass `DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1` auf derselben Zielsite bereits gelaufen ist.

## Status

Noch nicht gegen einen Tenant ausgeführt. Offene fachliche Fragen an Nils: siehe Datenmodell, Abschnitt 8.
