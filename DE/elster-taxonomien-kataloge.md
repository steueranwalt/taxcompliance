# ELSTER-Taxonomien und Referenzkataloge

**Quellen:** `DIVA_SK_ArtDesSchreibens_v21.0.0.zip` (Schlüsselkatalog „Art des Schreibens", Version 21.0.0, Stand 3.6.2026), `Fehlerliste.xml` (laufend gepflegt, ausgewertet 19.9.2026: 477 Einträge), `Bescheidnr_Januar_2026.zip` (Bescheidnummern ESt/GSt/USt), `Pruefung_der_Steuer_und_Steueridentifikatsnummer.pdf` (Stand 15.4.2026), `Finanzamtsdaten.xlsx`.

**Dies ist die fachliche Übersicht.** Jeder Katalog hat seit dem Scan 2026-09-28 zusätzlich eine eigene, ausführlichere Detailseite unter [`elster/kataloge/`](elster/kataloge/) (Struktur/Schema, Umfang, Beispiele, Quellenpfade, offene Punkte je Katalog):

| Katalog | Detailseite |
|---|---|
| DIVA Art des Schreibens | [`elster/kataloge/diva-art-des-schreibens.md`](elster/kataloge/diva-art-des-schreibens.md) |
| Fehlerliste | [`elster/kataloge/fehlerliste.md`](elster/kataloge/fehlerliste.md) |
| Bescheidnummern ESt/GSt/USt | [`elster/kataloge/bescheidnummern.md`](elster/kataloge/bescheidnummern.md) |
| Prüfziffern Steuernummer/IdNr. + Grundsteuer | [`elster/kataloge/pruefziffern-steuernummer-idnr.md`](elster/kataloge/pruefziffern-steuernummer-idnr.md) |
| Finanzamtsdaten (GEMFA) | [`elster/kataloge/finanzamtsdaten.md`](elster/kataloge/finanzamtsdaten.md) |

## A. DIVA-Schlüsselkatalog „Art des Schreibens"

**Zweck (Kap. 5.1 der Doku):** Die Steuerverwaltung verwendet Schlüsselkataloge, um verfahrensübergreifend ausgetauschten Entitäten eindeutige Schlüssel und verwaltungsübliche Bezeichnungen gemäss AEAO zu § 122 Tz. 3.1.1.1 zuzuweisen. Der Katalog „Art des Schreibens" definiert die Typen von Textdokumenten (Verwaltungsakte und sonstige Mitteilungen), die von der Steuerverwaltung elektronisch bereitgestellt werden.

### I. Spalten des Schlüsselkatalogs (Tabellenblatt „Schlüssel" in `VDM_SK_ArtDesSchreibens_v21.0.0.xlsx`)

| Spalte | In Abholungsrequest | In Abholungsresponse | Bedeutung |
|---|---|---|---|
| `DateibezeichnungID` | Nein | Ja | numerischer Schlüsselwert, identifiziert Dokumenttypen eindeutig |
| `Klartext` | Nein | Nein | fachliche Beschreibung des Dokumenttyps |
| `Gültig von` | Nein | Nein | frühestmöglicher Verwendungszeitpunkt |
| `Gültig bis` | Nein | Nein | letztmöglicher Verwendungszeitpunkt |
| `Dateibezeichnung` | Nein | Ja | fachliche Beschreibung, wird in der Datenabholung mitgeliefert |
| `DateibezeichnungKurz` | Nein | Ja | Kurzbezeichnung gem. AEAO zu § 122 Tz. 3.1.1.1; wird u. a. im Betreff der Benachrichtigungsmail verwendet |
| `Verwaltungsakt` | Nein | Nein | Ja/Nein — ob der bereitgestellte Dokumenttyp ein Verwaltungsakt ist |
| `ELSTER-Dokumentengruppe` | Ja | Ja | gruppiert Dokumenttypen, nutzbar zur Filterung im Abholungsrequest (hiess bis Version 18 „Steuerart") |

### II. Abholung

Verfahren `ElsterDatenabholung`, Datenart `PostfachAnfrage`, plus `DatenartBereitstellung` aus der Excel-Tabelle.

### III. Beispiel-Metadatenstruktur (Datenabholung, ein Anhang)

```xml
<Anhaenge xmlns="http://finkonsens.de/elster/anhaenge/simple/v3" version="3">
  <Anhang>
    <Dateibezeichnung>Feststellungsbescheid nach § 27 ff KStG</Dateibezeichnung>
    <Dateityp>application/pdf</Dateityp>
    <Dateiinhalt>… [Base64-codiertes unverschlüsseltes PDF] …</Dateiinhalt>
    <Virengeprueft>false</Virengeprueft>
    <Normalisiert>false</Normalisiert>
    <MetadatenAnhang>
      <MetadatumAnhang><SchluesselAnhang>DateibezeichnungKurz</SchluesselAnhang><WertAnhang>FB27KStG</WertAnhang></MetadatumAnhang>
      <MetadatumAnhang><SchluesselAnhang>DateibezeichnungID</SchluesselAnhang><WertAnhang>003002</WertAnhang></MetadatumAnhang>
    </MetadatenAnhang>
  </Anhang>
</Anhaenge>
```

### IV. Versionsverlauf (Auszug, Änderungsnachweis der Doku)

| Version | Datum | Änderung |
|---|---|---|
| 14.0.1 | 16.5.2023 | Initiale Version |
| 15.1.0 | 3.4.2024 | Art des Schreibens „Sonstiges Schreiben" ergänzt |
| 16.0.0 | 12.8.2024 | diverse Arten für ESt, GewSt, KSt, ErbSt hinzugekommen |
| 17.0.0 | 27.1.2025 | Office-Schreiben (Schlüssel `10nnnn`) hinzu; behördeninterne Arten entfernt; Spalte „(Abholungs-)Datenart" umbenannt |
| 18.0.0 | 22.5.2025 | neue Arten mit `DateibezeichnungID ≥ 101551` |
| 19.0.0 | 16.9.2025 | 28 neue Schlüssel (u. a. `000160`–`000183`, `003044`, `101027`); 4 Schlüssel umbenannt |
| 21.0.0 | 3.6.2026 | aktueller Stand des gesichteten Katalogs |

**Hinweis zur Vollständigkeit:** Die vollständige Werteliste (mehrere hundert `DateibezeichnungID`-Einträge) liegt als Excel-Tabellenblatt `Schlüssel` in `VDM_SK_ArtDesSchreibens_v21.0.0.xlsx` vor und ist hier aus Umfangsgründen nicht Zeile für Zeile reproduziert; Mapping-Tabelle DIVA → interner Dokumenttyp: siehe `Aenderungsbedarf_ELSTER_vs_Architektur_2026-07-24.md` im Ordner `ELSTER-Entwickler`.

## B. Fehlerliste — Struktur und Klassifizierung

**Schema:** `<Fehlerliste xmlns="http://www.elster.de/fehlerliste/v1"><Fehler><Komponente/><Unterkomponente/><Klassifizierung/><Nummer/><Text/></Fehler>…</Fehlerliste>`

**Umfang (Stand der Sichtung):** 477 Fehlereinträge, 17 Komponenten (`01, 02, 05, 06, 07, 08, 11, 13, 19, 23, 37, 52, 60, 68, 69, 70, 90`).

### I. Klassifizierungswerte — Verteilung und Beispieltexte

Eine offizielle Legende der `Klassifizierung`-Werte liegt in den gesichteten Unterlagen nicht vor; die folgende Zuordnung ist aus je einem repräsentativen Fehlertext pro Wert abgeleitet und vor Automatisierungslogik durch weitere Stichproben zu verifizieren:

| Klassifizierung | Anzahl | Beispieltext | vorläufige Deutung |
|---:|---:|---|---|
| 0 | 24 | „Die Signaturprüfung wurde erfolgreich durchgeführt." | Erfolg/Bestätigung |
| 1 | 46 | „Bei der Verarbeitung der übermittelten Daten ist ein Fehler aufgetreten." | allgemeiner Verarbeitungsfehler |
| 3 | 26 | „Die Clearingstelle ist momentan nicht erreichbar, bitte versuchen Sie es später erneut." | temporär (Serverseite) |
| 5 | 328 | „Die Version der ELSTER-Komponente ist nicht mehr aktuell." | fachlich/technisch (grösste Gruppe) |
| 7 | 35 | „In der Datei web.xml sind nicht alle erforderlichen Einträge. Daten konnten nicht erfolgreich verarbeitet werden." | Konfigurationsfehler beim Hersteller/Client |
| 9 | 18 | „Ihr Request konnte nicht erfolgreich eingelesen werden." | schwerwiegend/Request unlesbar |

**Beispiel-Fehlereinträge (Komponente 01, Unterkomponente 001–002):**

| Komponente | Unterkomponente | Klassifizierung | Nummer | Text |
|---|---|---:|---|---|
| 01 | 001 | 5 | 008 | Version der ELSTER-Komponente nicht mehr aktuell — Update beim Softwarehersteller erfragen |
| 01 | 001 | 9 | 002 | Request konnte nicht erfolgreich eingelesen werden |
| 01 | 001 | 9 | 007 | schwerwiegender Fehler bei der Verarbeitung der gesamten Datenlieferung |
| 01 | 002 | 3 | 012/013 | Clearingstelle momentan nicht erreichbar |
| 01 | 002 | 5 | 005/007 | keine Versionsnummer aus dem TransferHeader ermittelbar |
| 01 | 002 | 5 | 010 | kein Schema zur THeader-Versionsnummer gefunden |
| 01 | 002 | 5 | 012 | „TH 08 ist an der offenen Schnittstelle nicht erlaubt" |
| 01 | 002 | 5 | 013/014 | Encoding entspricht weder ISO-8859-15 noch UTF-8 |

## C. Bescheidnummern-Kataloge

**Quelle:** `Bescheidnr_Januar_2026.zip`, Stand 21.1.2026 — separate XML-Kataloge je Steuerart: `Bescheidnummern_ESt.xml` (größter Katalog), `Bescheidnummern_GSt.xml`, `Bescheidnummern_USt.xml`. Format: Microsoft-Excel-XML-Workbook (`urn:schemas-microsoft-com:office:spreadsheet`), enthält die Bescheidarten-Codes je Steuerart feingranularer als der DIVA-Katalog. Dient als eigene Referenzliste „Bescheidarten (Steuerart)" — feldgenaue Auswertung der Codetabellen steht aus (Workbook-Zellinhalte, nicht als einfache Zeilen-CSV strukturiert).

## D. Prüfziffernverfahren

**Quelle:** `Pruefung_der_Steuer_und_Steueridentifikatsnummer.pdf`, Stand 15.4.2026 (116 Seiten).

### I. Verfahrenstyp je Bundesland (Steuernummer)

| Bundesland | Verfahren |
|---|---|
| Bayern, Berlin, Brandenburg, Bremen, Hamburg, Mecklenburg-Vorpommern, Niedersachsen, NRW, Saarland, Sachsen, Sachsen-Anhalt, Thüringen | 11er-Verfahren |
| Baden-Württemberg | 2er-Verfahren |
| Hessen, Schleswig-Holstein | modifiziertes 11er-Verfahren |
| Rheinland-Pfalz | (eigene Spalte in Quelltabelle — abweichend markiert) |

*Hinweis: die IdNr. (Steuer-Identifikationsnummer) hat unabhängig vom Bundesland ein bundeseinheitliches 11er-Modulo-Verfahren über die ersten 10 Stellen (Kap. 2.2 der Doku, mit Pseudocode).*

### II. Grundsteuer — Landesnummer, Datenart/Modell, Ordnungskriterium je Bundesland (Kap. 8)

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

**Wichtig für Erfassung:** In der Grundsteuererklärung ist nicht das Wohnsitz-Finanzamt der steuerpflichtigen Person, sondern das Lage-Finanzamt des Grundstücks massgebend (ausdrücklicher Hinweis der Quelle).

### III. Bundesland-Sonderfälle (bereits bekannt, aus Voranalyse bestätigt)

Bayern: Finanzamtsnummer wird in der gedruckten Steuernummer zunehmend weggelassen. Hessen: führende Null in der Steuernummer entfällt. Berlin: zwei Prüfzifferverfahren mit Bezirksausnahmen (Bezirke 201–693 nutzen Verfahren B). Detailtabellen je Bundesland (Aufbau der Steuernummer, Umrechnungsformel Finanzamt ↔ vereinheitlichte Steuernummer): Kap. 8.2 der Quelle, je Bundesland ein eigener Abschnitt (Baden-Württemberg, Berlin, Bremen, Hamburg, Hessen, Niedersachsen, NRW, Schleswig-Holstein).

## E. Finanzamtsdaten

**Quelle:** `Finanzamtsdaten.xlsx` / `Finanzamtsdaten.xml`, laufend durch ELSTER aktualisiert (mehrfach pro Quartal), ein Tabellenblatt je Bundesland. Kernspalten: `Finanzamtsnummer` (BUFA-Nr., 4-stellig), `Finanzamtsname`, `ÄnderungsInformationen` (Wert `KEIN_DELTA` oder Änderungsart — die Datei ist damit bereits diff-fähig ausgeliefert). Referenztabelle Bundesland/Länderschlüssel/BUFA-Nummern-Bereich: Kap. 9 der Prüfziffer-Dokumentation (Zeile ab „Bundesland — Finanzamtsnummer(n) — Länderschlüssel — BUFA-Nrn.").

## F. Übersicht aller Pakete/Formulare

Gesamtindex der ELSTER-Entwicklerpakete (Transport, Verfahren, Kataloge) inkl. expliziter ERiC-/Portal-Lücken: [`elster/README.md`](elster/README.md).

## G. Bezug zur SharePoint-Umsetzung

Die konkreten SharePoint-Listen, Inhaltstypen und Spalten sowie der Forms-/ELSTER-Datenfluss stehen im Kanzlei-Repo:

- `steuerkanzlei/sharepoint-architektur/elster-listen/einrichtungsplan-elster-listen-2026-09-20.md`
- `steuerkanzlei/sharepoint-architektur/elster-listen/schema/listen-schema.json`

Pilot-Site: `https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei`. Später identisches Schema auf dem TP-Docs-Tenant.

Ältere kanzleiinterne Entwürfe (`Aenderungsbedarf_ELSTER_vs_Architektur_2026-07-24.md`, `sp_listenschema_elster_meldungen.md` im Ordner `01 Projekte/ELSTER-Entwickler`) bleiben historische Quelle; die Listenplanung oben ist die aktuelle Umsetzungsgrundlage.
