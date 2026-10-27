# SharePoint-Listen + Microsoft-Forms-Familie „Substanzprüfung Holding-KG" (Version 3, Update 2)

Quellen: [`../Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md`](../Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md), [`../Fragenkatalog-Substanzpruefung-Holding-KG.md`](../Fragenkatalog-Substanzpruefung-Holding-KG.md), [`../feldkatalog/feldkatalog.json`](../feldkatalog/feldkatalog.json), Erfassungsbogen Holding-KG Version 3 (Nils Obenhaus, 27.10.2026, Projekt 22032-2), Anhang B1-B4.

**Update 2 ersetzt die Version-2-Forms-Spezifikation (7 Formulare F0-F7) vollständig durch die Version-3-Struktur mit Aufgaben als Bezugseinheit (5 Formularblätter).**

Vorbild und Konventionsquelle für Idempotenz/Spaltentypen: [`DE/AO/sharepoint-forms/README.md`](../../AO/sharepoint-forms/README.md) (PR #16).

Vertraulichkeit: Dieses Verzeichnis enthält ausschliesslich Schema-/Metadaten. Keine Mandats- oder Klientendaten. Beim Testdurchlauf ausschliesslich Dummy-Daten verwenden.

## A. Status

Noch nicht gegen einen Tenant ausgeführt. Dieses Modul nutzt `Eingang_Fehler` (DE/AO) mit und verweist optional auf `4_Beteiligte_und_Quoten` (DE/AO). **Voraussetzung:** `DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1` muss auf derselben Zielsite bereits gelaufen sein.

## B. Zielsite

Dieselbe Zielsite wie beim AO-Modul (siehe `DE/AO/sharepoint-forms/README.md` Abschnitt B).

## C. Listenerstellung (PnP-PowerShell)

```powershell
# Voraussetzung (einmalig, falls noch nicht geschehen):
.\..\..\AO\sharepoint-forms\New-SteuerlicheErfassungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/<ziel-site>" -ClientId "<Entra-App-ClientId>"

# Danach:
.\New-SubstanzHoldingKGListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/<ziel-site>" -ClientId "<Entra-App-ClientId>"
```

Legt an bzw. gleicht an: die 25 Listen aus dem Datenmodell (Abschnitt 2) sowie die Dokumentbibliothek `Substanznachweise`, in der im Skript berechneten, abhängigkeitssicheren Reihenfolge (`feldkatalog.json`, Schlüssel `erstellungsreihenfolge_sharepoint_listen`).

**Idempotenz/Angleichung:** identisches Verhalten wie `New-SteuerlicheErfassungListen.ps1` (DE/AO).

**Choice-/MultiChoice-Spalten speichern stabile Codes, nicht die deutsche Beschriftung** — unverändert gegenüber Version 2 (siehe Datenmodell, Abschnitt 1).

**Vier getrennte Prüfzustände (B4).** "Nicht bekannt", "nicht zutreffend", "nicht gefragt" (keine Spalte/Wert, da durch Verzweigung gar nicht angezeigt) und Null (echte 0/leer) sind getrennt. Deshalb sind mehrere scheinbar binäre Fragen als Choice mit 3-4 Werten angelegt statt als Boolean (z. B. `Aufgabenzustaendigkeiten.t15_geaendert`). **Ermittelt vs. geschätzt** wird durchgehend als eigene Status-Spalte neben dem Zahlenfeld geführt (Codebook `ERMITTLUNGSART`).

**R26 als sechs Einzelfragen.** Die Vorgabe verlangt für R26 ausdrücklich separate Ja/Nein/unbekannt-Fragen statt einer MultiChoice; das Skript legt entsprechend sechs eigene Choice-Spalten an (`r26_eigener_zugang`, `r26_zugang_ohne_anmeldung`, `r26_fest_zugewiesen`, `r26_eigene_ablage`, `r26_abschliessbare_aufbewahrung`, `r26_nur_nach_buchung`).

**H-Handlungen (45 Einzelhandlungen).** In Forms als Einzelfragen (ausgeführt/nicht ausgeführt/nicht bekannt) je Bereich gestellt; im Skript kompakt als drei MultiChoice-Spalten auf `Personeneinsaetze` abgelegt (`handlungen_ausgefuehrt`, `handlungen_nicht_ausgefuehrt`, `handlungen_unbekannt`).

**`Title` ist überall optional**, wie im AO-Modul.

### C1. ClientId / tenant-eigene Entra-App-Registrierung

Identisch zum AO-Modul — siehe [`DE/AO/sharepoint-forms/README.md`](../../AO/sharepoint-forms/README.md) Abschnitt C1.

## D. Fehlerprotokoll (`Eingang_Fehler`, DE/AO, wiederverwendet)

Nummerierungskonvention für `form_no` dieses Moduls (Version 3), um Kollision mit AO (0-8) und früheren Modul-Fassungen (101-111 Update 0, 201-207 Update 1) zu vermeiden:

| Formular (B1) | `form_no` |
|---|---|
| Formular 1 — Personenblatt | 301 |
| Formular 2 — Aufgabenblatt | 302 |
| Formular 3 — Arbeitsorganisation, Zeit und Ort | 303 |
| Formular 4 — Ressourcen und Kosten | 304 |
| Formular 5 — Nachweise und Abschluss | 305 |

Kein `access_code` vorgesehen (Anhang B3: "Erfassungsreferenzen sind keine Berechtigungsnachweise" — siehe Datenmodell, offene Frage 1). `case_id_raw` nimmt die rohe `ErfassungID`-Antwort auf.

## E. Forms-Aufteilung (Anhang B1) — fünf Blätter

Statische Forms-Listen müssen gepflegt werden. Automatische Live-Abfrage, beliebige Wiederholgruppen, automatische Datenübernahme zwischen Formularen und sichere Vorbelegung sind **keine** vorausgesetzten Funktionen (B3). Bei separaten Formularen werden bestehende Aufgaben über eine bereitgestellte Referenz (Text, intern aufgelöst) zugeordnet — keine erneute Tätigkeitsbeschreibung.

Jedes Formular beginnt mit **Fall-ID** (`ErfassungID`, Text, Pflicht).

### E.1 Formular 1 — Personenblatt (S01, S03-S07, H01a-H08f)

Einmal pro Person und Berichtszeitraum. Abschnitt 1.1 (vorbereitete Angaben) und 1.2 (Handlungen je gewähltem Bereich, als Einzelfragen) in einem Formular.

Ziel-Listen: `Personen`, `Funktionen`, `Erfassungen` (Zeitraum), `Personeneinsaetze` (S05-S07 + H-Bestätigungen).

### E.2 Formular 2 — Aufgabenblatt (T01-T16; D01-D10, V10-V18, K10-K17, G10-G15 bedingt)

Wiederholt je zusammenhängendem Aufgabenbereich und abweichender Gesellschaftszuordnung. D, V und K erscheinen nur bei entsprechend bestätigten Aufgaben (B3); G nur bei Bereich = eigene Verwaltung bzw. Beteiligungen/Mutter.

Ziel-Listen: `Aufgaben`, `Aufgabenempfaenger`, `Aufgabenzustaendigkeiten`, `Entscheidungsbefugnisse`, `Vertragszustaendigkeiten`, `Kontrollaufgaben`, `Steuerungsbeziehungen`.

### E.3 Formular 3 — Arbeitsorganisation, Zeit und Ort (P30-P38, Z01-Z08, O01-O08)

Einmal je Person (Abschnitt 4 des Fragenkatalogs: "Diese Angaben einmal je Person erfassen"), nach Abschluss der zugehörigen Aufgabenblätter, da Z05/Z08/O05 bereits erfasste Aufgaben referenzieren.

Ziel-Listen: `Personenbindungen`, `Personeneinsaetze` (Z01-Z07, O03-O05), `Zeitverteilungen` (Z08), `Aufgabenorte` (O01-O02, O06-O08).

### E.4 Formular 4 — Ressourcen und Kosten (R20-R29, A20-A32, C20-C31)

Rollenbezogen: Administration/IT/Personalstelle/Buchhaltung füllt jeweils nur die Teile aus, zu denen Auskunft gegeben werden kann (R20-Gateway); weitere Teile erhalten Status "offen" in `OffenePunkte` mit benannter Ansprechstelle.

Ziel-Listen: `Raeume`, `Arbeitsmittel`, `Ressourcennutzungen`, `Kosten`, `Kostenverteilungen`, `Abrechnungen`, `OffenePunkte` (unvollständige Module).

### E.5 Formular 5 — Nachweise und Abschluss (N20-N26)

Nachweise gesammelt am Schluss; fehlende Dokumente blockieren Tatsachenangaben nicht (B3).

Ziel-Listen: `Substanznachweise`, `Belegverknuepfungen`, `OffenePunkte`, `Erfassungen` (N24-N26).

## F. Verzweigung (Anhang B3)

- **S07** blendet in Formular 1 nur die Handlungstabelle(n) der gewählten Bereiche ein.
- **D, V, K** in Formular 2 nur bei entsprechend bestätigten Aufgaben: kein Vertragsbereich (V10 = "keine") bedeutet keine V11-V18-Fragen; keine zusätzliche Zustimmung (D04 = "keine") bedeutet keine D05-D07-Fragen.
- **G** in Formular 2 nur bei `bereich_code` = eigene Verwaltung bzw. Beteiligungen/Mutter.
- **A20** in Formular 4 steuert A26-A28 (Software), A29-A30 (IT/Smartphone), A31-A32 (Fahrzeug).
- **O01 = Homeoffice** schaltet O07/O08 frei.
- **C24 = ja/noch offen** schaltet C25-C27 frei.

## G. Übernahme per Power Automate (Anhang B3)

Identischer Ablauf wie in der Version-2-Fassung (Antwort abrufen → Codes/IDs auflösen → `FormID + ResponseID` als Übernahmeschlüssel gegen Doppelimport prüfen → Element erstellen/aktualisieren → Verteilungen/Belegbeziehungen schreiben → Prüfstatus setzen, bei Fehlschlag Eintrag in `Eingang_Fehler`). **Originalantworten bleiben unverändert erhalten; Normalisierung und interne Bewertung werden getrennt gespeichert** (B3).

### G.1 Prüfregeln ohne Scheingenauigkeit (B4)

1. **Keine Summenkorrektur auf 100 %.** `Zeitverteilungen`/`Aufgabenorte`-Prozentwerte werden **nicht** automatisch normalisiert; unzugeordnete Restzeit bleibt als eigener Status (`REST_NICHT_ZUGEORDNET`) offen, statt künstlich verteilt zu werden.
2. **Prozent nur bei konsistenter Basis und Nenner > 0.** Der Flow berechnet abgeleitete Prozentwerte aus Stunden nur, wenn eine gültige Gesamtbasis vorliegt und der Nenner grösser 0 ist; andernfalls bleibt das Prozentfeld leer (nicht 0).
3. **Orts- und Empfängerverteilung sind unabhängig.** Keine gegenseitige Additions- oder Konsistenzprüfung zwischen `Aufgabenorte` (Ort-Dimension) und `Zeitverteilungen` (Empfänger-Dimension) — beide verteilen dieselbe Zeit aus unterschiedlichen Blickwinkeln (B4).
4. **Ressourcenanteile nicht ungeprüft aus Arbeitszeitanteilen übernehmen.** `Ressourcennutzungen.a25_menge` wird eigenständig erfasst, nicht automatisch aus `Personeneinsaetze`/`Zeitverteilungen` abgeleitet.
5. **Kaufpreis und Abschreibung nicht als doppelte laufende Kosten addieren** — getrennte `Kosten`-Kostenarten je Komponente.
6. **Rechnungsstellung, ursprüngliche Zahlung und Erstattung getrennt dokumentieren** (`Kosten.zahlende_gesellschaft_ref` vs. `Kostenverteilungen.empfaenger_gesellschaft_ref`/`.rechnungsempfaenger_ref`).
7. **`ErfassungID`-Prüfung** vor jeder Elementanlage: unbekannte/fehlende `ErfassungID` → Eintrag in `Eingang_Fehler`.
8. **Formularübergreifende Kontextbedingungen** (z. B. D/V/K-Zeilen setzen eine bereits über Formular 2 angelegte `Aufgaben`-Zeile voraus): findet der Flow keine passende Zeile, Eintrag in `Eingang_Fehler` statt verwaistem Datensatz.

## H. Datei-Upload (keine nativen Forms-Uploads)

Wie in Version 2: kein nativer Forms-Datei-Upload. Jede Frage mit Anlagenreferenz wird als Text-Frage umgesetzt; die Datei läuft über den vorgesehenen Kanzlei-Übermittlungsweg in die Dokumentbibliothek `Substanznachweise`, verknüpft über `Belegverknuepfungen` (`ziel_typ`+`ziel_id`). Funktionen und Berechtigungen vor Einsatz im Tenant prüfen (B3).

## I. Freigabe und Rollout

1. Je Formular „Jeder mit dem Link kann antworten".
2. Je Formular/Liste-Paar ein Power-Automate-Flow gemäss Abschnitt G.
3. Testdurchlauf mit Dummy-Erfassung vor Versand an echte Mandanten/Mitarbeitende.
4. `Eingang_Fehler` regelmässig sichten (gemeinsam mit dem AO-Modul).
5. `display_label`-Felder durch den jeweiligen Flow nach Elementanlage befüllen.
6. `InterneBewertungen`-Berechtigungen manuell nachprüfen (siehe Datenmodell, Abschnitt 6).

## J. Offene Punkte

Siehe Datenmodell, Abschnitt 8 — insbesondere Zugriffsschutz der öffentlichen Formulare, `InterneBewertungen`-Berechtigungsgruppe, Granularität von R26 und der H-Handlungs-Ablage.
