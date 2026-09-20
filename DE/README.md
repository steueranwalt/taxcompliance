# ELSTER-Infrastruktur: Schnittstellenbeschreibungen und Taxonomien

Generische Transport-, Verwaltungs- und Nebenverfahrens-Infrastruktur von ELSTER, auf der jedes Fachverfahren (ESt, KSt, USt, GewSt, ErbSt, Lohnsteuer …) aufsetzt. Ausgewertet aus dem Ordner `01 Projekte/ELSTER-Entwickler` (11 Schnittstellenpakete + Referenzdaten), Stand der Pakete 2026-01 bis 2026-07-24, Sichtung 19.9.2026.

**Wichtige Abgrenzung:** Die eigentlichen Formular-Schnittstellen der Steuererklärungen (ESt, KSt, USt-VA, GewSt, ErbSt mit ihren Kennziffern-Katalogen) liegen **nicht** in den gesichteten Unterlagen, sondern im separaten ERiC-/Vordruck-Entwicklerpaket. Die hier dokumentierte Infrastruktur ist die Schicht darunter (Transport, Authentifizierung, Datenabholung, Dokumenttyp- und Fehlercode-Kataloge).

## Dokumente

| Dokument | Inhalt |
|---|---|
| [`elster-transportschicht-und-verfahren.md`](elster-transportschicht-und-verfahren.md) | ElsterXML-Grundaufbau (TransferHeader/NutzdatenHeader), Authentifizierung/Verschlüsselung, Online-/Offline-Verfahren, Verfahren-Datenart-Vorgang-Taxonomie je Paket (ElsterDatenabholung, ElsterKontoabfrage, ElsterObjektspeicher/OTTER, RABE, ElsterLohn, LAVENDEL/HMS) |
| [`elster-taxonomien-kataloge.md`](elster-taxonomien-kataloge.md) | DIVA-Schlüsselkatalog „Art des Schreibens", Fehlerliste/Klassifizierung, Bescheidnummern-Kataloge (ESt/GSt/USt), Prüfziffernverfahren, Finanzamtsdaten |

## Bezug zu den übrigen `DE/AO`-Dokumenten

Feldkatalog und Pflichtlogik der Erfassungsfragebögen und der BZSt2-/AStG-Meldungen stehen separat in [`AO/formulardaten-roherfassung.md`](AO/formulardaten-roherfassung.md), [`AO/Einheitliches-Datenmodell-steuerliche-Erfassung-DE-Auslandsbezug.md`](AO/Einheitliches-Datenmodell-steuerliche-Erfassung-DE-Auslandsbezug.md) und [`AStG/formulardaten-mitteilung-6-astg.md`](AStG/formulardaten-mitteilung-6-astg.md). Die dort verwendeten Katalogwerte (z. B. DIVA-`DateibezeichnungID`, Finanzamtsnummern) sind hier definiert.

Die SharePoint-Listenplanung (Inhaltstypen, Spalten, Forms, Pilot-Site) liegt im Repo `steuerkanzlei` unter `sharepoint-architektur/elster-listen/`.
