# Katalog: ELSTER-Fehlerliste

## 1. Zweck

Zentraler Fehlercode-Katalog für alle ELSTER-Übermittlungen — jeder in TransferHeader/NutzdatenHeader zurückgegebene Fehlercode (siehe Rückgabecode-Struktur in [`../../elster-transportschicht-und-verfahren.md`](../../elster-transportschicht-und-verfahren.md) Abschnitt B.2) lässt sich hierüber nachschlagen.

## 2. Daten: Verfahren / Datenart / Vorgang

Kein eigenes Verfahren — die Fehlerliste ist ein Querschnittskatalog, der von **allen** Verfahren referenziert wird (Code im `RC`/`Rueckgabe`/`Stack`-Element).

### Schema (`Fehlerliste.xml`)

```text
<Fehlerliste xmlns="http://www.elster.de/fehlerliste/v1">
  <Fehler>
    <Komponente/>
    <Unterkomponente/>
    <Klassifizierung/>
    <Nummer/>
    <Text/>
  </Fehler>
  …
</Fehlerliste>
```

### Umfang

477 `<Fehler>`-Einträge, 17 Komponenten (`01, 02, 05, 06, 07, 08, 11, 13, 19, 23, 37, 52, 60, 68, 69, 70, 90`).

### Klassifizierungswerte — Verteilung

Eine offizielle Legende der `Klassifizierung`-Werte liegt in den gesichteten Unterlagen **nicht** vor; die folgende Zuordnung ist aus je einem repräsentativen Fehlertext pro Wert abgeleitet und vor Automatisierungslogik durch weitere Stichproben zu verifizieren:

| Klassifizierung | Anzahl | Beispieltext | vorläufige Deutung |
|---:|---:|---|---|
| 0 | 24 | „Die Signaturprüfung wurde erfolgreich durchgeführt." | Erfolg/Bestätigung |
| 1 | 46 | „Bei der Verarbeitung der übermittelten Daten ist ein Fehler aufgetreten." | allgemeiner Verarbeitungsfehler |
| 3 | 26 | „Die Clearingstelle ist momentan nicht erreichbar, bitte versuchen Sie es später erneut." | temporär (serverseitig) |
| 5 | 328 | „Die Version der ELSTER-Komponente ist nicht mehr aktuell." | fachlich/technisch (grösste Gruppe) |
| 7 | 35 | „In der Datei web.xml sind nicht alle erforderlichen Einträge. Daten konnten nicht erfolgreich verarbeitet werden." | Konfigurationsfehler beim Hersteller/Client |
| 9 | 18 | „Ihr Request konnte nicht erfolgreich eingelesen werden." | schwerwiegend/Request unlesbar |

### Beispiel-Einträge (Komponente 01, Unterkomponente 001–002)

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

## 3. Taxonomie / Kataloge

Dies **ist** der Katalog. Querbezug: Rückgabecode-Struktur in [`../../elster-transportschicht-und-verfahren.md`](../../elster-transportschicht-und-verfahren.md) Abschnitt B.2.

## 4. Quellen

- `Fehlerliste.xml`, Portal-Stand 24.11.2025 (laufend gepflegt).
- Portal-Namen: `Fehlerliste.pdf` (**nicht lokal**, niedrige Priorität laut Inventar, da XML vorhanden), `Fehlerliste.xml` (lokal vorhanden).

## 5. Gaps / offene Punkte

- Offizielle Legende der `Klassifizierung`-Werte (0/1/3/5/7/9) ist **nicht** dokumentiert vorgefunden worden; die obige Deutung ist eine Ableitung aus Beispieltexten und muss vor produktivem Einsatz (z. B. Retry-Logik nach Klassifizierung) verifiziert werden.
- `Fehlerliste.pdf` (Prosa-Fassung, ggf. mit zusätzlichem Kontext zur Klassifizierung) wurde nicht heruntergeladen.
