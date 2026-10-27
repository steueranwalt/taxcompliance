# Substanzprüfung Holding-KG

Datenerhebung zur tatsächlichen Substanz einer Holding-KG und zur tatsächlich ausgeübten Managementtätigkeit — unabhängig von der Konzernstruktur als solcher. Fachliche Vorgabe: Nils Obenhaus, 27.10.2026.

## Dokumente

| Dokument | Rolle |
|---|---|
| [Einheitliches Datenmodell](Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md) | Kern-Datenmodell (Person/Tätigkeit/Ort/Asset), Listenkatalog, Abdeckungstabelle Frage → Liste.Spalte, Wiederverwendungsentscheidungen, Leitfragen-Nachweis |
| [`sharepoint-forms/README.md`](sharepoint-forms/README.md) | SharePoint-Listen- und Microsoft-Forms-Architektur, Flow-Zuordnung, Prüfregeln |
| [`sharepoint-forms/KLICKANLEITUNG-FORMS.md`](sharepoint-forms/KLICKANLEITUNG-FORMS.md) | Klickanleitung zur manuellen Forms-Erstellung |
| [`sharepoint-forms/New-SubstanzHoldingKGListen.ps1`](sharepoint-forms/New-SubstanzHoldingKGListen.ps1) | idempotentes PnP-PowerShell-Skript (Listen SH0-SH11) |

## Verhältnis zur steuerlichen Erfassung (`DE/AO/`)

Dieses Modul folgt denselben Konventionen (Namensgebung, Idempotenz, Spaltentypen, Umlautschreibweise, Flow-Muster) wie [`DE/AO/sharepoint-forms/`](../AO/sharepoint-forms/README.md) und nutzt zwei von dessen Listen mit (`Eingang_Fehler`, `4_Beteiligte_und_Quoten`); zwei weitere (`3_Personen_und_Vertretung`, `5_Betriebsstaetten`) sind optional als Cross-Reference-Lookup verknüpft. Begründung je Liste: siehe Datenmodell, Abschnitt "Wiederverwendung". `New-SubstanzHoldingKGListen.ps1` setzt voraus, dass `DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1` auf derselben Zielsite bereits gelaufen ist.

## Status

Noch nicht gegen einen Tenant ausgeführt (siehe Skript-Header und `sharepoint-forms/README.md` Abschnitt H). Offene fachliche Fragen an Nils: siehe Datenmodell, Abschnitt "Offene Fragen an Nils".
