# GemFA: amtliches Zustaendigkeitsverzeichnis der Finanzaemter

Stand der Recherche: 31.10.2026 (Klaerung Nils zu PR #24, Punkt 3).

## Quelle

Das Bundeszentralamt fuer Steuern (BZSt) veroeffentlicht das Auskunftssystem **GemFA 2.0** (Gemeinde-/Finanzamtszustaendigkeit) inklusive eines maschinenlesbaren Vollstaendig-Exports:

- Seite: <https://www.bzst.de/DE/Service/Behoerdenwegweiser/Finanzamtsuche/finanzamtsuche.html>
- Seitenstand beim Abruf: 15.10.2026
- **GemFA XML-Export** (ZIP, ca. 2 MB): vollstaendige GemFA-Daten einschliesslich der hausnummerngenauen Detailzustaendigkeiten und der Angaben zu den Datenschutzbeauftragten. Aktualisierung jeweils am 1. und am 15. jedes Monats.
- **GemFA XSD**: Beschreibungsdatei zum XML-Export, gueltig ab 05.03.2026.

Zusaetzlich katalogisiert auf GovData: <https://www.govdata.de/suche/daten/suche-nach-zustandigem-finanzamt> (Veroeffentlichung 01.05.2018, letzte Aenderung des Katalogeintrags 04.12.2024).

## Nutzungsbedingungen

GovData kennzeichnet den Datensatz als **amtliches Werk, lizenzfrei nach § 5 Abs. 1 UrhG**, Nutzungsart **freie Nutzung**. Eine darueber hinausgehende, einschraenkende Open-Data-Lizenz ist auf der BZSt-Downloadseite und im GovData-Katalogeintrag nicht genannt. Vor produktivem Einsatz die aktuelle Downloadseite nochmals auf geaenderte Hinweise pruefen.

## Warum die XML-Datei nicht ins Repo gehoert

Der Export ist rund 2 MB gross, wird zweimal monatlich aktualisiert und enthaelt hausnummergenaue Zustaendigkeiten (in 23 namentlich genannten Staedten sogar strassen- bzw. hausnummerngenau). Eine ins Repo eingefrorene Kopie waere innerhalb von spaetestens 14 Tagen veraltet und koennte nach Finanzamts-Zusammenlegungen falsche Vorschlaege liefern. Die Ableitungsregel `0_Fallsteuerung__tax_office` stuetzt sich deshalb auf den **jeweils aktuellen** GemFA-XML-Export (Abruf durch Flow oder Kanzlei zur Laufzeit), nicht auf eine statische Datei in diesem Repository.

## Verwendung in den Ableitungsregeln

- Anknuepfungspunkt (Ort/PLZ/Strasse) kommt aus den Tatsachenfeldern (Liste 1 `postal_code_city`/`street`, Liste 3 `usual_workplace_*`, Liste 5 `address`/`country`, Liste 9 `street`/`postal_code_city`/`country`).
- Der konkrete Finanzamts-Name wird gegen den aktuellen GemFA-XML-Export abgeglichen.
- Jeder so ermittelte Wert bleibt ein **Vorschlag** (`kanzlei_bestaetigung_erforderlich: true`).
- Reine Auslands-USt-Faelle ohne inlaendische Betriebsstaette laufen nicht ueber GemFA, sondern ueber `ustzustv-laendertabelle.json` (UStZustV § 1 Abs. 1).
