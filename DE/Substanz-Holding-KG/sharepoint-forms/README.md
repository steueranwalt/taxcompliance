# SharePoint-Listen + Microsoft-Forms-Familie „Substanzprüfung Holding-KG" (Update 1)

Quellen: [`../Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md`](../Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md), [`../Fragenkatalog-Substanzpruefung-Holding-KG.md`](../Fragenkatalog-Substanzpruefung-Holding-KG.md), [`../feldkatalog/feldkatalog.json`](../feldkatalog/feldkatalog.json), Erfassungsbogen-Entwurf Nils Obenhaus (27.10.2026, Projekt 22032-2), Anhänge B1, B4, B5.

**Update 1 ersetzt die frühere Forms-Spezifikation (12 Formulare F0-F11) vollständig durch die in Anhang B1 vorgegebene Aufteilung in sieben Blätter.**

Vorbild und Konventionsquelle für Idempotenz/Spaltentypen: [`DE/AO/sharepoint-forms/README.md`](../../AO/sharepoint-forms/README.md) (PR #16).

Vertraulichkeit: Dieses Verzeichnis enthält ausschliesslich Schema-/Metadaten. Keine Mandats- oder Klientendaten. Beim Testdurchlauf ausschliesslich Dummy-Daten verwenden.

## A. Status

Noch nicht gegen einen Tenant ausgeführt. Dieses Modul nutzt `Eingang_Fehler` (DE/AO) mit und verweist optional auf `4_Beteiligte_und_Quoten` (DE/AO) — siehe Datenmodell, Abschnitt 4. **Voraussetzung:** `DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1` muss auf derselben Zielsite bereits gelaufen sein, bevor `New-SubstanzHoldingKGListen.ps1` ausgeführt wird.

## B. Zielsite

Dieselbe Zielsite wie beim AO-Modul (siehe `DE/AO/sharepoint-forms/README.md` Abschnitt B), damit `Eingang_Fehler` und `4_Beteiligte_und_Quoten` erreichbar sind. Zur offenen Frage einer separaten Site für `InterneBewertungen` siehe Datenmodell, Abschnitt 5 und 7.

## C. Listenerstellung (PnP-PowerShell)

```powershell
# Voraussetzung (einmalig, falls noch nicht geschehen):
.\..\..\AO\sharepoint-forms\New-SteuerlicheErfassungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/<ziel-site>" -ClientId "<Entra-App-ClientId>"

# Danach:
.\New-SubstanzHoldingKGListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/<ziel-site>" -ClientId "<Entra-App-ClientId>"
```

Legt an bzw. gleicht an: die 20 Listen aus dem Datenmodell (Abschnitt 2) sowie die Dokumentbibliothek `Substanznachweise`, in der im Skript berechneten, abhängigkeitssicheren Reihenfolge (jede Liste wird erst angelegt, nachdem alle Listen existieren, auf die sie per Lookup verweist — siehe `feldkatalog.json`, Schlüssel `erstellungsreihenfolge_sharepoint_listen`).

**Idempotenz/Angleichung:** identisches Verhalten wie `New-SteuerlicheErfassungListen.ps1` (DE/AO) — fehlende Listen/Spalten werden angelegt, vorhandene Spalten angeglichen (Anzeigename, Pflichtstatus, fehlende Auswahlwerte werden ergänzt, nie entfernt), nichts wird gelöscht.

**Choice-/MultiChoice-Spalten speichern stabile Codes, nicht die deutsche Beschriftung.** Beispiel: `Taetigkeiten.frequency` speichert `FREQ_DAILY`, nicht „täglich". Der Mandant sieht in Forms ausschliesslich die deutsche Beschriftung (B3: „Mandant sieht deutsche Beschriftungen"); das Mapping Code → Beschriftung steht im Feldkatalog (`codebooks`). Der Power-Automate-Flow übersetzt die in Forms gewählte deutsche Bezeichnung **vor** der Elementanlage in den stabilen Code. Diese Entscheidung ist bewusst anders als beim AO-Modul (dort speichert SharePoint direkt die deutsche Bezeichnung) — Begründung: B3 verlangt ausdrücklich stabile, vom Wortlaut unabhängige Codes, „unbekannt nie als 0".

**MultiChoice statt Choice für [M]-Fragen.** Jede im Fragenkatalog mit „Mehrfachauswahl" markierte Frage ist eine SharePoint-`MultiChoice`-Spalte (CAML `Type='MultiChoice'`), nicht mehrere Einzel-Booleans. In Microsoft Forms entspricht das einer Auswahl-Frage mit aktiviertem „Mehrere Antworten zulassen".

**LookupMulti für mehrere Personen/Nachweise.** Wo die Vorgabe ausdrücklich mehrere Personen oder mehrere Anlagen vorsieht (z. B. P07 „mehrere benannte Personen", V09 mehrere Anlagenarten), ist die Spalte als `LookupMulti` angelegt.

**Datumsfelder sind reine Datumsfelder (`DateOnly`)** ohne Uhrzeitkomponente.

**`Title` ist überall optional**, aus demselben Grund wie im AO-Modul.

### C1. ClientId / tenant-eigene Entra-App-Registrierung

Identische Einrichtung wie im AO-Modul — siehe [`DE/AO/sharepoint-forms/README.md`](../../AO/sharepoint-forms/README.md) Abschnitt C1.

## D. Fehlerprotokoll (`Eingang_Fehler`, DE/AO, wiederverwendet)

`Eingang_Fehler` wird von beiden Modulen gemeinsam genutzt. Nummerierungskonvention für `form_no` dieses Moduls (um Kollision mit den AO-Formularen 0-8 und den Formular-Nr. 101-111 der Update-0-Fassung dieses Moduls zu vermeiden):

| Formular (B1) | `form_no` |
|---|---|
| Formular 1 — Personenblatt | 201 |
| Formular 2 — Tätigkeitsblatt | 202 |
| Formular 3 — Entscheidungs-/Vertrags-/Kontrollblatt | 203 |
| Formular 4 — Organisationsblatt | 204 |
| Formular 5 — Raumblatt | 205 |
| Formular 6 — Arbeitsmittelblatt | 206 |
| Formular 7 — Kosten- und Belegblatt | 207 |

`case_id_raw` in `Eingang_Fehler` nimmt hier die rohe `ErfassungID`-Antwort auf (kein `access_code` vorgesehen, siehe Datenmodell, offene Frage 1).

## E. Forms-Aufteilung (Anhang B1) — sieben Blätter

Microsoft Forms kennt keine wiederholbaren Unterformulare; jedes der sieben Formulare wird deshalb **beliebig oft ausgefüllt**, mit einem gemeinsamen Erfassungsschlüssel. Mandanten sehen verständliche Formulartitel; technische IDs (Frage-IDs, Listen-/Spaltennamen) erscheinen **nicht** im Formulartext (siehe Fragenkatalog, "Mandantensicht").

Jedes Formular beginnt mit:

1. **Fall-ID** (`ErfassungID`) — Text, Pflicht.
2. **Name/Firma** nur bei Formular 1 (siehe unten); alle übrigen Formulare benötigen keine weitere Kennung, da sie über die referenzierte Person/Gesellschaft/Tätigkeit aufgelöst werden (siehe Flow-Spezifikation, Abschnitt G).

### E.1 Formular 1 — Personenblatt (P01-P09, P19-P24)

Einmal pro Person und Berichtszeitraum. Fragen P01-P08 (Vertragsbindung) und P19-P24 (Arbeitszeit/Präsenz) laut Fragenkatalog, Abschnitte 1 und 3. P09 (Tätigkeitsbereiche) steuert als Gateway-Mehrfachauswahl, welche Bereichs-Hinweistexte am Ende des Formulars erscheinen ("Bitte für jeden markierten Bereich das Tätigkeitsblatt [Formular 2] ausfüllen").

Ziel-Listen: `Personen`, `Personenbindungen` (je Vertragsverhältnis wiederholt), `Personeneinsaetze`.

### E.2 Formular 2 — Tätigkeitsblatt (P10-P18)

Wiederholt pro Person, Tätigkeit und Empfänger — Auswahl aus P09 als Vorgabe (keine automatische Formularübergreifende Übertragung in Microsoft Forms vorausgesetzt; der Mandant wählt den Bereich am Anfang von Formular 2 erneut). Je gewähltem Bereich zeigt Forms die zugehörige Handlungstabelle (Verzweigung, siehe Abschnitt F).

Ziel-Listen: `Taetigkeiten`, `Zeitverteilungen` (P16: Ortsverteilung).

### E.3 Formular 3 — Entscheidungs-/Vertrags-/Kontrollblatt (E, V, K)

Einstiegsauswahl „Worum geht es?" (Entscheidung / Vertragsverhandlung / Aufsicht-Kontrolle-Schulung) steuert, welcher Abschnitt (E, V oder K) angezeigt wird. Je Fall bzw. Art ein Formulardurchlauf.

Ziel-Listen: `Entscheidungsfaelle`, `Fallbeteiligungen`, `Vertragsvorgaenge`, `Steuerungsbeziehungen` (K04), `Taetigkeiten` (K01-K03, sofern die zugehörige Tätigkeit bereits über Formular 2 angelegt wurde — sonst Verweis in `Eingang_Fehler`, siehe Abschnitt G).

### E.4 Formular 4 — Organisationsblatt (G)

Einmal pro Zeitraum, mit Referenzen zu Tätigkeitsdatensätzen. G01-G03 sind Gateway-Mehrfachauswahlen (keine eigene Spalte, siehe Datenmodell); G04-G06 ergänzen vorhandene `Taetigkeiten`-Datensätze bzw. erzeugen `Abrechnungen`-Einträge.

Ziel-Listen: `Taetigkeiten` (G04, G05 als Zusatzspalten), `Abrechnungen` (G06).

### E.5 Formular 5 — Raumblatt (R)

Einmal pro Nutzungsbereich und Zeitraum.

Ziel-Listen: `Raeume`, `Orte` (R01), `Ressourcennutzungen` (R04), `Kosten` (R06).

### E.6 Formular 6 — Arbeitsmittelblatt (A)

Einmal pro Gegenstand bzw. Software und Zeitraum; Personen- und Gesellschaftsanteile als verknüpfte Nutzungsdatensätze.

Ziel-Listen: `Arbeitsmittel`, `Ressourcennutzungen` (A03-A04), `Kosten` (A08).

### E.7 Formular 7 — Kosten- und Belegblatt (C, N)

Kostenblatt (C), wiederholt pro Kostenposition; Belegblatt (N), wiederholt pro Nachweis oder Fall, in einem gemeinsamen Formular mit Einstiegsauswahl „Kostenangabe" vs. „Beleg/Beispiel nachreichen". N05 ist die gemeinsame Abschluss- und Zeitraumangabe (einmal je Erfassung, am Ende des Formulars als eigener Abschnitt, unabhängig von der C/N-Wiederholung).

Ziel-Listen: `Kosten`, `Kostenverteilungen`, `Abrechnungen` (C05), `Belegverknuepfungen`, `Substanznachweise`, `Erfassungen` (C06, N05).

## F. Verzweigung (Anhang B4)

- **P09** blendet nur passende Tätigkeitsbereiche (und in Formular 2 nur die zugehörige Handlungstabelle) ein. Keine Tätigkeit führt zu «nur geplant» oder «kein Fall» statt erfundener Detailantworten.
- **V01 „keine Mitwirkung"** überspringt V02-V09 (Formular 3, Vertragsabschnitt endet).
- **A01 „Software"** zeigt A07, **„Fahrzeug"** zeigt A05, **„Smartphone/IT"** zeigt A06 (Formular 6).
- **K04 „nein"** überspringt die Steuerungsdetails (Formular 3, Kontrollabschnitt).
- **Schriftlicher Vertrag vorhanden** (P05) führt zur Anlagenreferenz; **nicht vorhanden** führt zur Beschreibung der tatsächlichen Grundlage. Dokumentenmangel blockiert nicht die Tatsachenantwort.
- **Kostenkategorie** (implizit über C03/A08/R06) bestimmt, welches Zusatzfeld (Raum/Mittel/Person/externer Dienstleister) erscheint.

## G. Übernahme per Power Automate (Anhang B4)

Für jedes Formular/Liste-Paar ein Flow „Bei neuer Microsoft-Forms-Antwort → Element erstellen", mit folgendem Ablauf:

1. **Neue Antwort → Antwortdetails abrufen.**
2. **Codes und IDs auflösen:** die in Forms gewählte deutsche Bezeichnung auf den stabilen Code übersetzen (Nachschlagetabelle aus dem Feldkatalog, z. B. als Power-Automate-„Tabelle"-Aktion oder Datenquelle); `ErfassungID` gegen `Erfassungen.case_id` prüfen; Person/Gesellschaft-Namensangaben gegen `Personen`/`Gesellschaften` abgleichen (Flow-seitige „Get Items"-Suche nach `display_label`/`company_name`).
3. **Übernahmeschlüssel `FormID + ResponseID`** verhindert Doppelimport (Forms liefert beide in jedem Trigger-Payload; vor der Elementanlage prüfen, ob bereits ein Element mit demselben `FormID`+`ResponseID` existiert — z. B. als interne Zusatzspalte je Zielliste oder als Abgleich gegen ein separates Importprotokoll).
4. **`ErfassungID + PersonID + Zeitraum + Version`** unterscheidet Fortschreibungen (Korrekturantworten); Originalantwort und Korrekturversion werden beide aufbewahrt (`Erfassungen.version_number` hochzählen, nicht überschreiben).
5. **Datensatz erstellen/aktualisieren.**
6. **Verteilungen und Belegbeziehungen schreiben:** `Zeitverteilungen`/`Ressourcennutzungen`-Zeilen aus den Prozentfeldern der Antwort erzeugen; `Belegverknuepfungen`/`Substanznachweise` aus genannten Anlagenreferenzen.
7. **Prüfstatus setzen** (siehe unten) und bei Fehlschlag Element in `Eingang_Fehler` anlegen statt der stillen Verwerfung.

### G.1 Prüfregeln, die Forms nicht clientseitig abbilden kann

1. **100-%-Prüfung mit Toleranz:** Forms hat keine native Summenvalidierung. Der Flow summiert nach der Übernahme alle `Zeitverteilungen`/`Ressourcennutzungen`-Prozentwerte je Bezug (`bezug_typ`+`einsatz_ref`/`taetigkeit_ref`/Ressource) und prüft auf **99-101 %** Toleranz; ausserhalb dieses Bereichs wird das Element trotzdem angelegt, zusätzlich aber ein Eintrag in `Eingang_Fehler` erstellt (`reason = "Prozentsumme ausserhalb Toleranz (99-101 %)"`) zur Rückfrage, statt die Antwort zurückzuweisen.
2. **Getrennte Orts- und Empfängerverteilung.** P16/P22 (Ort) und P21 (Empfänger) sind **zwei unabhängige Verteilungen derselben Zeit** (`Zeitverteilungen.dimension = ORT` bzw. `EMPFAENGER`) — der Flow darf sie **nicht addieren** oder gegeneinander validieren, nur je Dimension separat auf 100 % prüfen.
3. **Aufgabenstunden nicht nochmals zu Einsatzstunden addieren.** `Taetigkeiten.hours` (P15, je Tätigkeit) und `Personeneinsaetze.kg_hours` (P20, gesamt je Person) sind unabhängige Angaben; der Flow führt keine automatische Konsistenzprüfung zwischen beiden durch (laut B4 "soll zur Gesamtverteilung je Person plausibel passen" — manuelle Plausibilisierung durch die Kanzlei, keine harte Flow-Regel).
4. **Formularübergreifende Kontextbedingungen:** z. B. K01-K03 (Formular 3) setzen eine bereits über Formular 2 angelegte `Taetigkeiten`-Zeile mit passendem `bereich_code` voraus. Findet der Flow keine passende Zeile, legt er statt eines verwaisten K-Eintrags einen Eintrag in `Eingang_Fehler` an (`reason = "Keine passende Taetigkeiten-Zeile fuer K-Block gefunden"`).
5. **Gegenseitig ausschliessende Zusatzfelder** (z. B. `Kosten`: nur das zur gewählten Kostenart passende Zusatzfeld `person_ref`/`raum_ref`/`mittel_ref` sollte befüllt sein): bei Widerspruch Eintrag in `Eingang_Fehler` statt stiller Übernahme.
6. **`ErfassungID`-Prüfung** vor jeder Elementanlage: unbekannte/fehlende `ErfassungID` → Eintrag in `Eingang_Fehler` (`form_no` gemäss Abschnitt D).

## H. Datei-Upload (Anhang B5)

**Kein nativer Forms-Datei-Upload** in den Mandanten-Formularen (Formulare 1-7). Grund: Der Forms-Fragetyp „Datei hochladen" verlangt vom Antwortenden ein Microsoft-Konto der eigenen Organisation, auch bei „Jeder mit dem Link kann antworten" (Quelle: Microsoft-Support, siehe Anhang B5). Ein extern zugänglicher Bogen darf sich darauf nicht verlassen.

**Stattdessen:**

1. Jede Frage, die im Fragenkatalog eine „Anlagenreferenz" verlangt, wird in Forms als **Text-Frage** umgesetzt ("Dateiname/Bezeichnung der Unterlage").
2. Ein **separater Kanzlei-Uploadweg** (z. B. bestehender sicherer Dateitransferdienst) nimmt die Datei entgegen.
3. Die Kanzlei (oder ein erweiterter Flow mit Anmeldepflicht) lädt die Datei in die Dokumentbibliothek **`Substanznachweise`** hoch und verknüpft sie über `Belegverknuepfungen` mit der referenzierten Zeile (`ziel_typ`+`ziel_id`, siehe Datenmodell Abschnitt 6).
4. Keine Zugangsdaten oder sensiblen Angaben in öffentlichen Links. Vertrauliche Vergütungsunterlagen (C01) können direkt an die Kanzlei übermittelt werden, ausserhalb der Formularkette.

## I. Freigabe und Rollout

1. Je Formular „..." → Einstellungen → „Wer kann antworten" → **„Jeder mit dem Link kann antworten"**.
2. Je Formular/Liste-Paar ein Power-Automate-Flow gemäss Abschnitt G.
3. Testdurchlauf mit Dummy-Erfassung vor Versand an echte Mandanten/Mitarbeitende der Holding-KG.
4. `Eingang_Fehler` regelmässig sichten (gemeinsam mit dem AO-Modul, da die Liste geteilt wird).
5. `display_label`-Felder (Personen, Taetigkeiten, Raeume, Arbeitsmittel, Entscheidungsfaelle, Vertragsvorgaenge, Kosten) durch den jeweiligen Flow nach Elementanlage befüllen, damit nachfolgende Lookups (z. B. `Zeitverteilungen.taetigkeit_ref`) sinnvoll anzeigen.
6. `InterneBewertungen`-Berechtigungen manuell nachprüfen (siehe Datenmodell, Abschnitt 5).

## J. Offene Punkte

Siehe Datenmodell, Abschnitt 7 ("Offene Fragen an Nils") — insbesondere Zugriffsschutz der öffentlichen Formulare (kein `access_code`-Mechanismus in Anhang B2 vorgesehen) und die Berechtigungsgruppe für `InterneBewertungen`.
