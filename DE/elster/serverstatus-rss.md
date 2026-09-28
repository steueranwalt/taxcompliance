# ELSTER Serverstatus RSS

## 1. Zweck

Ops-Hilfsmittel, um bei Übermittlungsproblemen zwischen einer Störung der ELSTER-Annahmeserver und einem eigenen (Client-seitigen) Fehler unterscheiden zu können.

## 2. Daten: Verfahren / Datenart / Vorgang

Kein ElsterXML-Verfahren — reiner Informations-Feed, kein Bestandteil des Tripels Verfahren/Datenart/Vorgang.

**Feed:** RSS 2.0, URL `https://www.elster.de/elsterweb/serverstatus_rss`.

**Mapping:** Die begleitende PDF-Dokumentation beschreibt, wie sich Verfahren/Steuerart auf die `<title>`-Elemente der Feed-Einträge abbilden (z. B. welche Titel-Formulierungen zu welchem Fachverfahren gehören). Detailmapping wurde aus dem Inventar nicht Zeile für Zeile übernommen.

## 3. Taxonomie / Kataloge

Kein eigener Katalog.

## 4. Quellen

- `serverstatus_rss_documentation.pdf` — nicht über das HTML-Portal-Dump verlinkt, aber separat vorhanden.

## 5. Gaps / offene Punkte

- Vollständiges Mapping Verfahren/Steuerart → Feed-`<title>` wurde nicht aus der PDF extrahiert; bei Bedarf für eine Monitoring-Integration im Volltext nachziehen.
- Kein Formularpaket, daher kein Bezug zu Kennziffernkatalogen.
