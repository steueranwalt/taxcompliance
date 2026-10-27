# SharePoint-Listen + Microsoft-Forms-Familie „Substanzprüfung Holding-KG"

Quellen: [`../Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md`](../Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md), fachliche Vorgabe Nils Obenhaus (27.10.2026).

Vorbild und Konventionsquelle: [`DE/AO/sharepoint-forms/README.md`](../../AO/sharepoint-forms/README.md) (PR #16, Branch `cursor/update-sharepoint-forms-script-3e90`). Namensgebung, Idempotenz-Logik, Spaltentypen, Umlautschreibweise und Flow-Muster sind von dort übernommen — Abweichungen sind im Datenmodell (Abschnitt "Wiederverwendung") begründet.

Vertraulichkeit: Dieses Verzeichnis enthält ausschliesslich Schema-/Metadaten (Listen-, Spalten-, Formularstruktur). Keine Mandats- oder Klientendaten. Beim Testdurchlauf ausschliesslich Dummy-Daten verwenden. Diese Listen können operative Detaildaten enthalten (Arbeitszeitanteile, Zugangsberechtigungen, Kostenzuordnungen) — siehe Datenmodell, offene Frage 6, zur Zielsite-/Berechtigungsentscheidung.

## A. Status und Abhängigkeit zur steuerlichen Erfassung

Dieses Modul **nutzt zwei Listen der steuerlichen Erfassung (DE/AO) mit** (`Eingang_Fehler`, `4_Beteiligte_und_Quoten`) und verweist optional auf zwei weitere (`3_Personen_und_Vertretung`, `5_Betriebsstaetten`) — siehe Datenmodell, Abschnitt "Wiederverwendung". **Voraussetzung:** `DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1` muss auf derselben Zielsite bereits gelaufen sein, bevor `New-SubstanzHoldingKGListen.ps1` ausgeführt wird — sonst schlagen die Lookup-Feldanlagen auf diese vier Listen fehl (das Skript bricht an der jeweiligen Stelle mit einer PnP-Fehlermeldung "Liste nicht gefunden" ab, da `Get-PnPList -Identity <Liste>` für ein Lookup-Ziel zwingend ist, anders als bei fehlenden, aber optionalen Choice-Werten).

Wie im AO-Modul gilt: Microsoft Forms hat keine öffentliche API; die Formulare müssen von Hand angelegt werden (Klickanleitung: [`KLICKANLEITUNG-FORMS.md`](KLICKANLEITUNG-FORMS.md)).

## B. Zielsite

Dieselbe Zielsite wie beim AO-Modul verwenden (siehe `DE/AO/sharepoint-forms/README.md` Abschnitt B), damit die mitgenutzten Listen (`Eingang_Fehler`, `4_Beteiligte_und_Quoten` usw.) tatsächlich erreichbar sind:

1. `https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei` (bevorzugt)
2. `https://obenhaus.sharepoint.com/sites/service` (Ausweichoption)

Falls aus Vertraulichkeitsgründen eine separate, enger berechtigte Site gewünscht wird (offene Frage 6 im Datenmodell), müssten `Eingang_Fehler`, `4_Beteiligte_und_Quoten`, `3_Personen_und_Vertretung` und `5_Betriebsstaetten` dorthin repliziert oder die entsprechenden Lookup-Spalten in `New-SubstanzHoldingKGListen.ps1` entfernt werden — das ist mit Nils vor dem ersten Lauf zu klären.

## C. Listenerstellung (PnP-PowerShell)

```powershell
# Voraussetzung (einmalig, falls noch nicht geschehen):
.\..\..\AO\sharepoint-forms\New-SteuerlicheErfassungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/<ziel-site>" -ClientId "<Entra-App-ClientId>"

# Danach:
.\New-SubstanzHoldingKGListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/<ziel-site>" -ClientId "<Entra-App-ClientId>"
```

Legt an bzw. gleicht an: `SH0_Substanzfall`, `SH1_Personen`, `SH2_Entscheidungsprozesse`, `SH3_Managementtaetigkeiten`, `SH4_Orte`, `SH5_Assets`, `SH6_Asset_Nutzung`, `SH7_Tagesgeschaeft_Praesenz`, `SH8_Zusammenarbeit_Beteiligungen`, `SH9_Geschaeftsvorgaenge`, `SH10_Kosten`, `SH11_Belege` — jeweils mit allen Spalten aus dem Datenmodell, inkl. `case_id`-Lookup auf `SH0_Substanzfall` in jeder Folgeliste (Löschverhalten `Restrict`).

**Idempotenz/Angleichung:** identisches Verhalten wie `New-SteuerlicheErfassungListen.ps1` (DE/AO) — fehlende Listen/Spalten werden angelegt, vorhandene Spalten angeglichen (Anzeigename, Pflichtstatus, fehlende Auswahlwerte werden ergänzt, nie entfernt), nichts wird gelöscht. Angleichungen, die an vorhandenen Daten scheitern können, erzeugen nur eine Warnung und brechen den Lauf nicht ab.

**`Title` ist überall optional**, aus demselben Grund wie im AO-Modul (die fachliche Kennung je Liste ist `case_id`/`display_label`, nicht `Title`).

**Datumsfelder sind reine Datumsfelder (`DateOnly`)** ohne Uhrzeitkomponente (`tasks_since`, `review_period_from/to`, `event_date` usw.).

**Ja/Nein-Fragen sind SharePoint-Boolean-Spalten** (z. B. `actually_performed`, `exclusively_for_holding`, `documented_in_writing`). Der Flow muss „Ja"/„Nein" auf `true`/`false` abbilden, identisch zum AO-Muster.

**Auswahlwerte sind immer mit Umlauten geschrieben** (z. B. „Geschäftsplanung / Unternehmenssteuerung", „Büromöbel", „Erwerb oder Verkauf von Beteiligungen") und **ohne „ß"** (Schweizer Schreibweise, z. B. „ausschliesslich", „Grösse" statt „ausschließlich"/„Größe") — identisch zwischen Datenmodell, diesem README, der Klickanleitung und dem Skript. Das Skript ist wie `New-SteuerlicheErfassungListen.ps1` als UTF-8-Datei **mit BOM** gespeichert, damit PowerShell die Umlaute korrekt liest (dieselbe Lösung wie in PR #16). Bei einer bereits laufenden Installation ergänzt das Skript fehlende Auswahlwerte, entfernt aber nichts automatisch.

**Referenz-Spaltenpaare (`<feld>_text`/`<feld>_ref`):** siehe Datenmodell Abschnitt 1.1. Nur `<feld>_text` ist eine Forms-Frage; `<feld>_ref` wird nach Elementanlage manuell oder durch einen erweiterten Flow aufgelöst (identisches Muster zu `related_object_text`/`related_person` in `8_Unterlagen`, DE/AO).

**Löschverhalten der `case_id`-Lookups:** `Restrict` auf `SH0_Substanzfall` in allen Folgelisten (SH1-SH11) — ein Substanzfall kann nicht gelöscht werden, solange Folgedatensätze existieren. Alle sekundären Lookups (Person-, Ort-, Asset-, Tätigkeits- und Beteiligungsbezüge) bleiben beim Standardverhalten `None`.

### C1. ClientId / tenant-eigene Entra-App-Registrierung

Identische Einrichtung wie im AO-Modul — siehe [`DE/AO/sharepoint-forms/README.md`](../../AO/sharepoint-forms/README.md) Abschnitt C1. Dieselbe App-Registrierung (dieselbe `ClientId`) kann für beide Skripte verwendet werden, da beide dieselbe delegierte Berechtigung `AllSites.FullControl` benötigen.

## D. Fall-ID und Zugangscode

`SH0_Substanzfall.case_id` ist analog zu `0_Fallsteuerung.case_id` ein einzeiliges Textfeld, indiziert und mit „eindeutige Werte erzwingen" versehen, ohne serverseitige Auto-Nummerierung. **Empfohlenes Format: `SH-JJJJ-NNNN`** (z. B. `SH-2026-0001`), um Verwechslungen mit AO-Fall-IDs (`JJJJ-NNNN`) auszuschliessen — zu bestätigen (Datenmodell, offene Frage 4).

`access_code` (Text, indiziert, eindeutig, **nicht** `-Required`) folgt demselben Muster wie `0_Fallsteuerung.access_code`: der fallanlegende Flow setzt ihn unmittelbar bei Fallanlage (z. B. `toUpper(substring(guid(),0,10))`). Jeder Flow, der eine Formularantwort (F1-F11) einem Fall zuordnet, prüft `case_id` **und** `access_code` gemeinsam, bevor ein Element in der Zielliste erzeugt wird.

### D1. `Eingang_Fehler` — Nummerierungskonvention für dieses Modul

`Eingang_Fehler` wird von beiden Modulen gemeinsam genutzt (siehe Datenmodell, Abschnitt "Wiederverwendung"). Damit `form_no` (Number-Feld) nicht mit den AO-Formularen 0-8 kollidiert, verwenden die Flows dieses Moduls folgende Nummerierung:

| Formular | `form_no` |
|---|---|
| F0 — Substanzfall (intern, keine Eingang_Fehler-Prüfung nötig, siehe unten) | — |
| F1 — Personen | 101 |
| F2 — Entscheidungsprozesse | 102 |
| F3 — Managementtätigkeiten | 103 |
| F4 — Geschäftsräume/Bereiche | 104 |
| F5 — Assets | 105 |
| F6 — Asset-Nutzung | 106 |
| F7 — Tagesgeschäft/Präsenz | 107 |
| F8 — Zusammenarbeit Beteiligungen | 108 |
| F9 — Geschäftsvorgänge | 109 |
| F10 — Kosten | 110 |
| F11 — Belege | 111 |

F0 (Fallanlage) prüft naturgemäss keine vorausgesetzte `case_id` (sie wird dort gerade erst erzeugt) und schreibt deshalb nie nach `Eingang_Fehler`.

Schlägt die `case_id`/`access_code`-Prüfung für ein Formular F1-F11 fehl (unbekannte/fehlende `case_id`, falscher `access_code`, sonstige Validierungsfehler), legt der jeweilige Flow einen Eintrag in `Eingang_Fehler` an (`form_no` gemäss Tabelle, `case_id_raw`, `reason`, `payload`, `status = "offen"`) statt die Antwort kommentarlos zu verwerfen — identisches Verfahren wie im AO-Modul.

## E. Microsoft-Forms-Spezifikation je Formular

Fragetyp-Zuordnung identisch zum AO-Modul (siehe `DE/AO/sharepoint-forms/README.md` Abschnitt E, Tabelle). Jedes Formular (ausser F0) erhält als erste Frage „Fall-ID" (Text, Pflicht) und als zweite Frage „Zugangscode" (Text, Pflicht) — beide vom Mandanten/der Kanzlei aus der Fallanlage übernommen bzw. per vorausgefülltem Link übergeben (siehe Abschnitt F).

**Mehrfachausfüllung statt wiederholbarer Abschnitte:** Microsoft Forms kennt keine wiederholbaren Unterabschnitte innerhalb einer Antwort. Da praktisch jede Liste dieses Moduls (Personen, Tätigkeiten, Entscheidungsarten, Orte, Assets, Asset-Nutzung, Zusammenarbeit, Geschäftsvorgänge, Kosten, Belege) mehrere Zeilen je Fall benötigt, gilt modulweit: **ein Formular je Datensatztyp, beliebig oft ausfüllbar.** Hinweistext am Formularanfang: „Bitte für jede(n) [Person/Tätigkeit/Entscheidungsart/Raum/Asset/...] eine eigene Antwort einreichen (Formular mehrfach ausfüllen)." Das ist identisch zum bereits etablierten Muster der Formulare 3, 4, 5 im AO-Modul.

### E.0 Formular 0 — Substanzfall (intern, Fallanlage)

Nur intern (Kanzlei), nicht an Mandanten versendet.

1. Name der Holding-KG — Text (Pflicht)
2. Steuernummer/Identifikationsnummer der Holding-KG (falls bekannt) — Text
3. Bezug: Fall der steuerlichen Erfassung (DE/AO, Fall-ID, falls vorhanden) — Text
   - kein Live-Lookup; Flow löst `related_erfassung_case` nach Elementanlage auf, falls die angegebene Fall-ID in `0_Fallsteuerung` existiert
4. Prüfungszeitraum — von — Date
5. Prüfungszeitraum — bis — Date
6. Mandatsverantwortliche Person (Kanzlei) — Text
7. Persönliche Bearbeitungsnotiz — Text (lang)

Formularende: Textblock mit Link-Liste zu den Formularen F1-F11 (siehe Routing, Abschnitt E.11). `access_code` ist keine Forms-Frage — der fallanlegende Flow setzt ihn beim Anlegen des `SH0_Substanzfall`-Elements und übergibt `case_id` + `access_code` in den vorausgefüllten Links zu F1-F11 (identisches Verfahren wie `0_Fallsteuerung`, DE/AO).

### E.1 Formular 1 — Personen (Vorgabe Abschnitt 1)

1. Fall-ID — Text (Pflicht)
2. Zugangscode — Text (Pflicht)
3. Name — Text (Pflicht)
4. Funktion / Stellenbezeichnung — Text (Pflicht)
5. Bei welcher Gesellschaft angestellt oder vertraglich gebunden? — Text (Pflicht)
6. Welche Aufgaben übernimmt die Person tatsächlich für die Holding-KG? — Text (lang, Pflicht)
7. Seit wann? — Date
8. Wie häufig arbeitet sie für die Holding-KG? — Auswahl (Pflicht): täglich; mehrmals pro Woche; wöchentlich; monatlich; nur bei Bedarf
9. Wie viel Arbeitszeit entfällt ungefähr auf Aufgaben der Holding-KG? — Text
10. An welchen Orten führt die Person diese Aufgaben aus? — Text (lang)
11. Wie häufig arbeitet die Person in den Geschäftsräumen der Holding-KG? — Auswahl (wie Frage 8)
12. Welche Entscheidungen trifft die Person selbst? — Text (lang)
13. Welche Entscheidungen bereitet sie nur vor? — Text (lang)
14. Welche Verträge oder sonstigen Unterlagen darf sie unterschreiben? — Text (lang)
15. Welche Mitarbeiter oder Dienstleister steuert sie? — Text (lang)
16. Welche Arbeitsmittel nutzt sie? — Text (lang)
17. Offene Frage: Bitte beschreiben Sie anhand einer typischen Arbeitswoche oder eines typischen Monats, welche Tätigkeiten Sie für die Holding-KG tatsächlich ausüben. — Text (lang, Pflicht)
18. Belege/Nachweise (z. B. Anstellungsvertrag, Vollmacht) — Datei-Upload oder Hinweistext auf Dokumentbibliothek (siehe Hinweis Datei-Upload, Abschnitt E.11)

Keine Branching-Regeln (alle Fragen linear, keine der Fragen hängt von einer anderen innerhalb desselben Formulars ab).

### E.2 Formular 2 — Entscheidungsprozesse (Vorgabe Abschnitt 3)

1. Fall-ID — Text (Pflicht)
2. Zugangscode — Text (Pflicht)
3. Art der Entscheidung — Auswahl (Pflicht): Budget; Investitionen; Finanzierung; Personal; Geschäftsführung; wichtige Verträge; Preisgestaltung; Vertrieb; Produkte; strategische Projekte; Ausschüttungen; Erwerb oder Verkauf von Beteiligungen
4. Wer beschäftigt sich zuerst damit? — Text
5. Wer bereitet vor? — Text
6. Wer gibt Empfehlung ab? — Text
7. Wer trifft die endgültige Entscheidung? — Text (Pflicht)
8. Wo befindet sich diese Person bei der Entscheidung? — Text
9. Meeting / E-Mail / telefonisch / anders? — Auswahl: Meeting; E-Mail; Telefonisch; Anders
10. Schriftlich festgehalten? — Auswahl Ja/Nein
11. Wenn ja, wo? — Text (lang)
    - Branching: nur einblenden, wenn Frage 10 = Ja

### E.3 Formular 3 — Managementtätigkeiten (Vorgabe Abschnitt 2)

Hinweis am Formularanfang: „Bitte für jede Tätigkeit, die tatsächlich ausgeübt wird (ggf. je Beteiligungsgesellschaft getrennt), eine eigene Antwort einreichen."

1. Fall-ID — Text (Pflicht)
2. Zugangscode — Text (Pflicht)
3. Tätigkeit — Auswahl (Pflicht): die 22 Managementtätigkeiten (siehe Datenmodell Abschnitt 3.3)
4. Bezeichnung, falls „sonstige Managementaufgaben" — Text
   - Branching: nur einblenden, wenn Frage 3 = „sonstige Managementaufgaben"
5. Wird die Aufgabe von der Holding-KG tatsächlich wahrgenommen? — Auswahl Ja/Nein (Pflicht)
6. Wer bearbeitet sie? — Text (Pflicht)
7. Was wird konkret gemacht? — Text (lang, Pflicht)
8. Wie häufig? — Auswahl (Pflicht, wie Formular 1 Frage 8)
9. Für welche Beteiligungsgesellschaft? — Text
10. Wo wird sie ausgeübt? — Text
11. Welche Unterlagen entstehen? — Text (lang)
12. Belege/Nachweise — Datei-Upload oder Hinweistext
13. Wer trifft die abschliessende Entscheidung? — Text

### E.4 Formular 4 — Geschäftsräume/Bereiche (Vorgabe Abschnitt 4)

1. Fall-ID — Text (Pflicht)
2. Zugangscode — Text (Pflicht)
3. Anschrift — Text (lang, Pflicht)
4. Raum / Raumnummer — Text
5. Grösse (m²) — Zahl
6. Art des Raums — Auswahl: Büro; Besprechungsraum; Empfang; Lager; Home-Office / mitbenutzter Raum; Sonstige
7. Bezug: ggf. bereits gemeldete Betriebsstätte (Bezeichnung) — Text
8. Wer nutzt ihn? — Text (lang)
9. Wie häufig? — Auswahl (wie Formular 1 Frage 8)
10. Für welche Tätigkeiten? — Text (lang)
11. Ausschliesslich für Holding-KG? — Auswahl Ja/Nein (Pflicht)
12. Wenn nein, wer sonst? — Text
    - Branching: nur einblenden, wenn Frage 11 = Nein
13. Wann steht er der Holding-KG zur Verfügung? — Text (lang)
14. Welche Arbeitsplätze? — Text (lang)
15. Welche Ausstattung? — Text (lang)
16. Wer hat Zugang? — Text (lang)
17. Schlüssel/Zugangskarten/Berechtigungen? — Text (lang)
18. Grundriss vorhanden? — Auswahl Ja/Nein
19. Verweis auf Grundriss (Datei-Upload oder Dokumentbibliothek) — Datei-Upload
    - Branching: nur einblenden, wenn Frage 18 = Ja
20. Fotos vorhanden? — Auswahl Ja/Nein
21. Verweis auf Fotos (Datei-Upload oder Dokumentbibliothek) — Datei-Upload
    - Branching: nur einblenden, wenn Frage 20 = Ja

### E.5 Formular 5 — Assets (Vorgabe Abschnitt 5, Stammdaten)

1. Fall-ID — Text (Pflicht)
2. Zugangscode — Text (Pflicht)
3. Kategorie — Auswahl (Pflicht): Schreibtische und Arbeitsplätze; Büromöbel; Computer; Bildschirme; Mobiltelefone; Drucker; Server / Netzwerk; Software; Fahrzeuge; Fahrräder; Besprechungsräume; sonstige technische Ausstattung
4. Was ist vorhanden? (Bezeichnung/Beschreibung) — Text (Pflicht)
5. Wem gehört es? — Text
6. Welche Gesellschaft trägt die Kosten? — Text (Pflicht)
7. Belege/Nachweise (z. B. Fotos, Rechnungen) — Datei-Upload oder Hinweistext

### E.6 Formular 6 — Asset-Nutzung (Vorgabe Abschnitt 5, Nutzung)

Hinweis am Formularanfang: „Bitte für jede Nutzungsinstanz eines Arbeitsmittels (gleiches Asset an unterschiedlichen Standorten/durch unterschiedliche Nutzer) eine eigene Antwort einreichen."

1. Fall-ID — Text (Pflicht)
2. Zugangscode — Text (Pflicht)
3. Welches Arbeitsmittel/Asset? (Bezeichnung, wie in Formular 5 erfasst) — Text (Pflicht)
4. Wo befindet es sich? — Text
5. Wer nutzt es? — Text (Pflicht)
6. Wie häufig? — Auswahl (Pflicht, wie Formular 1 Frage 8)
7. Für welche Tätigkeit? — Auswahl: die 22 Managementtätigkeiten
8. Ausschliesslich für Holding-KG? — Auswahl Ja/Nein (Pflicht)
9. Wenn nein, wer noch? — Text
   - Branching: nur einblenden, wenn Frage 8 = Nein
10. Nutzungsumfang (Details, z. B. Anteil/Stunden) — Text (lang)

### E.7 Formular 7 — Tagesgeschäft/Präsenz (Vorgabe Abschnitt 6)

1. Fall-ID — Text (Pflicht)
2. Zugangscode — Text (Pflicht)
3. Bezug: Geschäftsraum (Bezeichnung, optional) — Text
4. An wie vielen Tagen pro Monat sind Personen der Holding-KG typischerweise vor Ort? — Zahl
5. Welche Personen? — Text (lang, Pflicht)
6. Was tun sie dort konkret? — Text (lang, Pflicht)
7. Finden dort Managementbesprechungen statt? — Auswahl Ja/Nein
8. Wie häufig? — Auswahl (wie Formular 1 Frage 8)
   - Branching: nur einblenden, wenn Frage 7 = Ja
9. Wer nimmt teil? — Text (lang)
   - Branching: wie Frage 8
10. Werden dort Unterlagen erstellt oder unterschrieben? — Auswahl Ja/Nein
11. Details dazu (inkl. Hinweis Datei-Upload/Dokumentbibliothek) — Text (lang)
    - Branching: nur einblenden, wenn Frage 10 = Ja
12. Werden von dort E-Mails versandt oder Geschäftsvorgänge bearbeitet? — Auswahl Ja/Nein
13. Werden von dort Gespräche mit Geschäftsführern, Vorständen, Banken, Kunden oder Beratern geführt? — Auswahl Ja/Nein
14. Welche Aufgaben werden regelmässig von anderen Orten aus erledigt? — Text (lang)

### E.8 Formular 8 — Zusammenarbeit mit Beteiligungsgesellschaften (Vorgabe Abschnitt 7)

Hinweis am Formularanfang: „Bitte je typischer Managementleistung gegenüber einer Beteiligungsgesellschaft eine eigene Antwort einreichen."

1. Fall-ID — Text (Pflicht)
2. Zugangscode — Text (Pflicht)
3. Beteiligungsgesellschaft — Text (Pflicht)
4. Zuordnung zu einer Managementtätigkeit (optional) — Auswahl: die 22 Managementtätigkeiten
5. Bezeichnung der typischen Managementleistung — Text (Pflicht)
6. Wer bei der Holding-KG nimmt Kontakt auf? — Text (Pflicht)
7. Mit wem wird dort gesprochen? — Text
8. Wie häufig? — Auswahl (wie Formular 1 Frage 8)
9. Was wird besprochen? — Text (lang, Pflicht)
10. Welche Vorgaben oder Empfehlungen gibt die Holding-KG? — Text (lang)
11. Welche Informationen erhält sie zurück? — Text (lang)
12. Welche Unterlagen werden ausgetauscht? (inkl. Hinweis Datei-Upload/Dokumentbibliothek) — Text (lang)
13. Was passiert anschliessend? — Text (lang)
14. Wer kontrolliert die Umsetzung? — Text

### E.9 Formular 9 — Konkrete Geschäftsvorgänge (Vorgabe Abschnitt 8)

Hinweis am Formularanfang: „Bitte drei bis fünf konkrete Beispiele aus den letzten Monaten schildern — je Beispiel eine eigene Antwort (laufende Nummer 1-5)."

1. Fall-ID — Text (Pflicht)
2. Zugangscode — Text (Pflicht)
3. Laufende Nummer (1-5) — Zahl (Pflicht)
4. Worum ging es? — Text (lang, Pflicht)
5. Welche Beteiligungsgesellschaft? — Text (Pflicht)
6. Wer auf Seiten der Holding-KG beteiligt? — Text (Pflicht)
7. Was hat diese Person konkret gemacht? — Text (lang, Pflicht)
8. Wann? — Datum (Pflicht)
9. Wo? — Text
10. Welche Entscheidung wurde getroffen? — Text (lang)
11. Welche Unterlagen entstanden? (inkl. Hinweis Datei-Upload/Dokumentbibliothek) — Text (lang)
12. Wer setzte die Entscheidung um? — Text

### E.10 Formular 10 — Kosten (Vorgabe Abschnitt 9)

1. Fall-ID — Text (Pflicht)
2. Zugangscode — Text (Pflicht)
3. Kostenkategorie — Auswahl (Pflicht): Personen; Räume; Arbeitsmittel; externe Dienstleister
4. Welche Personen verursachen Kosten? — Text
   - Branching: nur einblenden, wenn Frage 3 = Personen
5. Welche Räume werden genutzt? — Text
   - Branching: nur einblenden, wenn Frage 3 = Räume
6. Welche Arbeitsmittel? — Text
   - Branching: nur einblenden, wenn Frage 3 = Arbeitsmittel
7. Welche externen Dienstleister? — Text
   - Branching: nur einblenden, wenn Frage 3 = externe Dienstleister
8. Welche Kosten entstehen daraus? — Text (lang, Pflicht)
9. Betrag (geschätzt) — Zahl
10. Währung — Text (Default-Hinweis „EUR", sofern nicht anders angegeben)
11. Welche Gesellschaft bezahlt zunächst? — Text (Pflicht)
12. Wie werden sie der Holding-KG zugeordnet? — Text (lang, Pflicht)
13. Werden sie weiterberechnet? — Auswahl Ja/Nein
14. Weiterberechnung — Details — Text (lang)
    - Branching: nur einblenden, wenn Frage 13 = Ja

**Hinweis zu Fragen 4-7:** Forms-Branching erlaubt genau eine auslösende Auswahl-Frage (Frage 3) mit vier sich gegenseitig ausschliessenden Folgefragen — identisch zum Verzweigungsmuster in `KLICKANLEITUNG-FORMS.md` Abschnitt C. Die Reihenfolge Personen → Räume → Arbeitsmittel → externe Dienstleister ist dafür in der Formularstruktur bindend.

### E.11 Formular 11 — Belege (Querschnitt, Punkt 5 des Auftrags)

Analog zu Formular 8 (`8_Unterlagen`) im AO-Modul.

1. Fall-ID — Text (Pflicht)
2. Zugangscode — Text (Pflicht)
3. Dokumenttyp — Auswahl (Pflicht): Nachweis Managementtätigkeit; Protokoll / Beschlussdokumentation; Vertrag / Vollmacht; Grundriss; Foto Geschäftsraum; Foto Arbeitsmittel; Rechnung / Kostenbeleg; Sonstiges
4. Bezug zu Objekt (Person/Tätigkeit/Ort/Asset/Geschäftsvorgang-Kennung) — Text
   - kein Live-Lookup; `related_person`/`related_activity`/`related_location`/`related_asset` werden danach manuell oder durch einen erweiterten Flow aus diesem Freitext aufgelöst
5. Datei — Datei-Upload (Pflicht)
6. Hinweis — Text (lang)

**Hinweis Datei-Upload (identisch zum AO-Modul):** Der Forms-Fragetyp „Datei hochladen" verlangt vom Antwortenden die Anmeldung mit einem Microsoft-Konto, auch bei „Jeder mit dem Link kann antworten". Für externe Personen ohne Microsoft-Konto (z. B. Mitarbeitende der Holding-KG ohne Kanzlei-Gastzugang) gelten dieselben zwei Alternativen wie im AO-Modul: (a) Dateien separat per E-Mail/Kanzlei-Upload-Link einsammeln und in `file_link` hinterlegen, oder (b) das Formular nur für angemeldete Personen vorsehen. Dies betrifft auch die Datei-Upload-Fragen in den Formularen 1, 3, 4 (Grundriss/Fotos), 7-9 (Belege-Hinweise).

### E.12 Routing (Formular 0 → Folgeformulare)

Anders als im AO-Modul (wo der Formulartyp über Verzweigungen bestimmt, welche Folgeformulare nötig sind) sind in diesem Modul **alle Formulare F1-F11 für jeden Substanzfall grundsätzlich einschlägig** — die Vorgabe unterscheidet nicht nach Rechtsform/Richtung, sondern deckt durchgehend dieselbe Holding-KG ab. Formular 0 endet deshalb mit einer vollständigen Linkliste zu F1-F11 (kein bedingtes Routing), ergänzt um den Hinweis: „Formulare 4 (Geschäftsräume), 5/6 (Assets) und 9 (Geschäftsvorgänge) nur ausfüllen, soweit einschlägig; Formular 9 mit 3-5 Beispielen."

## F. Freigabe und Rollout

1. Je Formular „..." → Einstellungen → „Wer kann antworten" → **„Jeder mit dem Link kann antworten"** (Ausnahme Formulare mit Datei-Upload, siehe Hinweis E.11).
2. Formular 0 bleibt intern (Kanzlei legt den Fall an). Der fallanlegende Flow setzt `access_code` und baut die vorausgefüllten Links zu F1-F11 mit `case_id` **und** `access_code` auf.
3. Je Formular/Liste-Paar ein Power-Automate-Flow „Bei neuer Microsoft-Forms-Antwort → Element in SharePoint-Liste erstellen", der vor der Elementanlage `case_id` + `access_code` gegen `SH0_Substanzfall` prüft und bei Fehlschlag einen Eintrag in `Eingang_Fehler` anlegt (`form_no` gemäss Abschnitt D1).
4. Testdurchlauf mit Dummy-Fall vor Versand an echte Mandanten/Mitarbeitende der Holding-KG.
5. `Eingang_Fehler` regelmässig sichten (gemeinsam mit dem AO-Modul, da die Liste geteilt wird).
6. Nach Eingang der Formularantworten: `display_label` in `SH1_Personen`, `SH3_Managementtaetigkeiten`, `SH4_Orte`, `SH5_Assets` usw. durch den jeweiligen Flow befüllen (z. B. `"<Name> (<Funktion>, Fall <case_id>, ID <ID>)"` für Personen), damit die `_ref`-Lookup-Spalten in den übrigen Listen sinnvoll anzeigen.
7. Anschliessend die `_ref`-Lookup-Spalten (siehe Datenmodell Abschnitt 1.1) manuell oder durch einen erweiterten Flow aus den `_text`-Rohantworten auflösen — identisches Vorgehen wie `related_person`/`related_participation`/`related_site` in `8_Unterlagen` (DE/AO).

## G. Prüfregeln für Power-Automate-Flows (Forms kann diese Bedingungen nicht abbilden)

1. **Formularübergreifende Kontextbedingungen** (z. B. „Tätigkeit nur für eine tatsächlich in `4_Beteiligte_und_Quoten` geführte Beteiligungsgesellschaft auswerten"): Forms-Branching wirkt nur innerhalb eines Formulars. Der Flow, der Formular-3-Antworten nach `SH3_Managementtaetigkeiten` überträgt, sollte `participation_text` optional gegen `4_Beteiligte_und_Quoten.display_label` abgleichen und bei Treffer `participation_ref` direkt setzen (statt die Auflösung ausschliesslich manuell vorzusehen).
2. **`sequence_number`-Bereichsprüfung (Formular 9):** SharePoint begrenzt `sequence_number` zwar serverseitig auf 1-5 (`Min`/`Max`), Forms prüft Zahlenbereiche aber nicht clientseitig. Der Flow sollte bei Werten ausserhalb 1-5 das Element in `Eingang_Fehler` anlegen (`form_no = 109`, `reason = "Laufende Nummer ausserhalb 1-5"`) statt die SharePoint-Fehlermeldung ungefiltert durchzureichen.
3. **Gegenseitig ausschliessende Kostenkategorie-Felder (Formular 10):** Der Flow sollte prüfen, dass nur das zur gewählten `cost_category` passende Text-Feld (`related_person_text`/`related_location_text`/`related_asset_text`/`external_provider_name`) befüllt ist; sind mehrere oder keines befüllt, Element statt direkter Übernahme in `Eingang_Fehler` anlegen (`form_no = 110`, `reason = "Kostenkategorie und Zusatzfeld passen nicht zusammen"`).
4. **`case_id`/`access_code`-Prüfung** vor jeder Elementanlage (F1-F11): siehe Abschnitt D/D1, identisch zum AO-Modul.

## H. Offene Punkte

- Siehe Datenmodell, Abschnitt "Offene Fragen an Nils" (Raumart-Katalog, Kostenbetrag/-währung, Geschäftsvorgänge-Obergrenze, Fall-ID-Format, Granularität Formular 8, Zielsite/Vertraulichkeit).
- Wie im AO-Modul: der Microsoft_365-Konnektor dieser Session verfügt nur über delegierte Lesescopes; das Skript wird deshalb **nicht** in dieser Session gegen einen Tenant ausgeführt, sondern von einer berechtigten Person mit erneuertem Konnektor-/PnP-Zugriff.
- `_ref`-Lookup-Auflösung (Abschnitt F, Punkt 7) ist bis zu einem erweiterten Flow ein manueller Schritt — wie bei `related_person`/`related_participation`/`related_site` im AO-Modul bereits dokumentiert und dort ebenfalls noch offen.
