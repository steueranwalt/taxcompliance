# SharePoint-Listen + Microsoft-Forms-Familie „Substanzprüfung Holding-KG" (Version 3, Update 3)

Quellen: [`../Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md`](../Einheitliches-Datenmodell-Substanzpruefung-Holding-KG.md), [`../Fragenkatalog-Substanzpruefung-Holding-KG.md`](../Fragenkatalog-Substanzpruefung-Holding-KG.md), [`../feldkatalog/feldkatalog.json`](../feldkatalog/feldkatalog.json), Erfassungsbogen Holding-KG Version 3 (Nils Obenhaus, 27.10.2026, Projekt 22032-2), Anhang B1-B4, sowie die Entscheidungen von Nils zu den fünf offenen Punkten aus Update 2 (siehe Datenmodell, Abschnitt 8).

**Update 2 ersetzte die Version-2-Forms-Spezifikation (7 Formulare F0-F7) vollständig durch die Version-3-Struktur mit Aufgaben als Bezugseinheit (5 Formularblätter). Update 3 ergänzt darauf aufbauend: Erfassungsreferenz + Formular-Enddatum als Schutz der öffentlichen Formulare (Abschnitt D/E), `InterneBewertungen_<Standort>` statt einer einzelnen `InterneBewertungen`-Liste (Abschnitt C/I), eine Flow-Prüfregel zur H-Handlungs-Spaltenexklusivität sowie `Aufgabenorte.bezugsart`/`.funktion` statt `.rollenbezug` (Abschnitt C/F).**

Vorbild und Konventionsquelle für Idempotenz/Spaltentypen: [`DE/AO/sharepoint-forms/README.md`](../../AO/sharepoint-forms/README.md) (PR #16).

Vertraulichkeit: Dieses Verzeichnis enthält ausschliesslich Schema-/Metadaten. Keine Mandats- oder Klientendaten. Beim Testdurchlauf ausschliesslich Dummy-Daten verwenden.

## A. Status

**Erster echter Lauf (Nils, 27.10.2026) gegen `https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei` ist abgebrochen** (siehe Abschnitt C3) — auf dieser Site existiert dadurch vermutlich bereits die Liste `Substanznachweise` mit dem Feld `nachweis_id`, aber kein `erfassung_ref`-Lookup und keine weiteren Listen. Das korrigierte Skript (Angleichungsmodus, idempotent) muss einmal erneut gegen diese Site laufen, um den Stand sauber fortzusetzen; dabei geht nichts verloren, bereits vorhandene Listen/Felder werden übersprungen bzw. angeglichen.

Dieses Modul nutzt `Eingang_Fehler` (DE/AO) mit und verweist optional auf `4_Beteiligte_und_Quoten` (DE/AO). **Voraussetzung:** `DE/AO/sharepoint-forms/New-SteuerlicheErfassungListen.ps1` muss auf derselben Zielsite bereits gelaufen sein.

## B. Zielsite

Dieselbe Zielsite wie beim AO-Modul (siehe `DE/AO/sharepoint-forms/README.md` Abschnitt B).

## C. Listenerstellung (PnP-PowerShell)

```powershell
# Voraussetzung (einmalig, falls noch nicht geschehen):
.\..\..\AO\sharepoint-forms\New-SteuerlicheErfassungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/<ziel-site>" -ClientId "<Entra-App-ClientId>"

# Danach (Default: nur InterneBewertungen_ZH, Gruppennamen laut Nils bereits vorbelegt):
.\New-SubstanzHoldingKGListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/<ziel-site>" -ClientId "<Entra-App-ClientId>"

# Mit explizit beiden Standorten (Default-Gruppennamen bleiben erhalten, siehe Abschnitt C2):
.\New-SubstanzHoldingKGListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/<ziel-site>" -ClientId "<Entra-App-ClientId>" -Standort ZH, HH

# Mit abweichenden Gruppennamen (überschreibt die Defaults):
.\New-SubstanzHoldingKGListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/<ziel-site>" -ClientId "<Entra-App-ClientId>" `
    -Standort ZH, HH `
    -StandortGruppen @{ ZH = "Kanzlei ZH"; HH = "Kanzlei-HH" } `
    -GesamtGruppe "steueranwaltskanzlei"
```

Legt an bzw. gleicht an: die 24 gemeinsamen Listen aus dem Datenmodell (Abschnitt 2) sowie die Dokumentbibliothek `Substanznachweise`, in der im Skript berechneten, abhängigkeitssicheren Reihenfolge (`feldkatalog.json`, Schlüssel `erstellungsreihenfolge_sharepoint_listen`), gefolgt von einer `InterneBewertungen_<Standort>`-Liste je Eintrag in `-Standort` (Default nur `ZH`, siehe Abschnitt C2).

**Idempotenz/Angleichung:** identisches Verhalten wie `New-SteuerlicheErfassungListen.ps1` (DE/AO).

**Choice-/MultiChoice-Spalten speichern stabile Codes, nicht die deutsche Beschriftung** — unverändert gegenüber Version 2 (siehe Datenmodell, Abschnitt 1).

**Vier getrennte Prüfzustände (B4).** "Nicht bekannt", "nicht zutreffend", "nicht gefragt" (keine Spalte/Wert, da durch Verzweigung gar nicht angezeigt) und Null (echte 0/leer) sind getrennt. Deshalb sind mehrere scheinbar binäre Fragen als Choice mit 3-4 Werten angelegt statt als Boolean (z. B. `Aufgabenzustaendigkeiten.t15_geaendert`). **Ermittelt vs. geschätzt** wird durchgehend als eigene Status-Spalte neben dem Zahlenfeld geführt (Codebook `ERMITTLUNGSART`).

**R26 als sechs Einzelfragen.** Die Vorgabe verlangt für R26 ausdrücklich separate Ja/Nein/unbekannt-Fragen statt einer MultiChoice; das Skript legt entsprechend sechs eigene Choice-Spalten an (`r26_eigener_zugang`, `r26_zugang_ohne_anmeldung`, `r26_fest_zugewiesen`, `r26_eigene_ablage`, `r26_abschliessbare_aufbewahrung`, `r26_nur_nach_buchung`).

**H-Handlungen (45 Einzelhandlungen).** In Forms als Einzelfragen (ausgeführt/nicht ausgeführt/nicht bekannt) je Bereich gestellt; im Skript kompakt als drei MultiChoice-Spalten auf `Personeneinsaetze` abgelegt (`handlungen_ausgefuehrt`, `handlungen_nicht_ausgefuehrt`, `handlungen_unbekannt`). Ein Handlungscode, der in **keiner** der drei Spalten steht, bedeutet "nicht gefragt" (der zugehörige Bereich wurde in S07 nicht ausgewählt) — nicht "nicht bekannt". Siehe Abschnitt G.1 zur Flow-Prüfregel gegen Mehrfachablage desselben Codes.

**`Aufgabenorte.bezugsart`/`.funktion` (Update 3, ersetzt `.rollenbezug`).** `bezugsart` ist Pflicht und unterscheidet `ARBEITSZEIT_ORT` (O01/O02, mit Stunden/Prozentanteil) von `FUNKTIONSORT` (O06, ohne Stunden/Prozentanteil); bei `FUNKTIONSORT` wird zusätzlich `funktion` (Vorbereitung/Verhandlung/Entscheidung/Freigabe) erfasst. Siehe Abschnitt G.1 zur Validierung gegen Doppelzählung.

**`Title` ist überall optional**, wie im AO-Modul.

### C1. ClientId / tenant-eigene Entra-App-Registrierung

Identisch zum AO-Modul — siehe [`DE/AO/sharepoint-forms/README.md`](../../AO/sharepoint-forms/README.md) Abschnitt C1.

### C2. `InterneBewertungen_<Standort>` — eigene Liste je Standort (Update 3)

Entscheidung Nils: Die Gruppe `steueranwaltskanzlei` sieht alle internen Bewertungen, die Standorte ZH und HH jeweils nur ihre eigenen. Umgesetzt über eine eigene physische Liste je Standort statt Item-Level-Berechtigung:

- **`-Standort`** (`string[]`, `ValidateSet('ZH','HH')`, Default `@('ZH')`): für welche Standorte eine `InterneBewertungen_<Standort>`-Liste angelegt/angeglichen wird. Default nur ZH, da laut Nils fast ausschliesslich ZH-Fälle vorkommen.
- **`-StandortGruppen`** (`hashtable`, Default `@{ ZH = 'Kanzlei ZH'; HH = 'Kanzlei-HH' }`): Zuordnung Standort → Gruppenname mit Zugriff auf die jeweilige Standort-Liste. **Schreibweise exakt wie von Nils vorgegeben: ZH mit Leerzeichen ("Kanzlei ZH"), HH mit Bindestrich ("Kanzlei-HH").**
- **`-GesamtGruppe`** (`string`, Default `'steueranwaltskanzlei'`): Gruppenname, der auf **allen** angelegten `InterneBewertungen_<Standort>`-Listen Zugriff erhält.

**SharePoint-Gruppe oder Microsoft-365-/Entra-ID-Gruppe — beides wird unterstützt.** Die drei Gruppennamen können entweder klassische SharePoint-Gruppen der Zielsite oder Microsoft-365-/Entra-ID-Gruppen sein (z. B. wenn die Kanzlei bereits mit M365-Gruppen statt SharePoint-eigenen Gruppen arbeitet). Für jeden der drei Namen versucht das Skript (`Grant-ListAccess`, siehe `New-SubstanzHoldingKGListen.ps1`):

1. **SharePoint-Gruppe der Site** (`Get-PnPGroup -Identity <Name>`) — wenn gefunden, direkte Rechtevergabe über `Set-PnPListPermission -Group`.
2. **Microsoft-365-Gruppe** nach Anzeigename (`Get-PnPMicrosoft365Group -Identity <Name>`) — wenn gefunden, wird die Gruppen-E-Mail-Adresse über `New-PnPUser` als SharePoint-Principal aufgelöst und darüber berechtigt.
3. **Sonstige Entra-ID-Gruppe** (z. B. eine Security-Gruppe ohne Mail-Attribut) nach Anzeigename (`Get-PnPAzureADGroup`/`Get-PnPEntraIDGroup -Identity <Name>`) — Auflösung über E-Mail, falls vorhanden, sonst über das Claims-Login-Format `c:0t.c|tenant|<ObjectId>`.

Wird ein Gruppenname in **keiner** der drei Formen gefunden, gibt das Skript nur eine `Write-Warning` aus und lässt die Liste für diese Gruppe ungenehmigt — **es wird nie ohne aufgelösten Principal automatisch Zugriff gewährt.** Im Erfolgsfall protokolliert das Skript je Gruppe, **welcher Principal-Typ und -Name** tatsächlich berechtigt wurde (z. B. "SharePoint-Gruppe 'Kanzlei ZH'" oder "Microsoft-365-Gruppe 'Kanzlei ZH' (`kanzlei-zh@obenhaus.onmicrosoft.com`)"), damit das später auf der Site nachvollziehbar ist.

**Berechtigungsstufe:** Beide Gruppentypen (Gesamtgruppe und Standortgruppe) erhalten **Bearbeiten**-Zugriff (nicht nur Lesen). Da der interne Name dieser Berechtigungsstufe je nach Sprache der Zielsite unterschiedlich heisst, probiert das Skript nacheinander `"Bearbeiten"` und `"Edit"` und verwendet den ersten, der auf der Zielsite existiert.

Für jede in `-Standort` genannte Liste bricht das Skript zusätzlich die Rechtevererbung, **ohne** bestehende Site-Berechtigungen zu kopieren (`BreakRoleInheritance($false, $false)`) — die Liste ist danach für alle ausser Site Collection Administrators unsichtbar, bis eine Gruppe erfolgreich berechtigt wurde ("fail closed").

Idempotent: ein späterer Lauf mit zusätzlichem `-Standort`-Wert (z. B. zuerst nur `ZH`, später `ZH,HH`) legt nur die fehlende Liste neu an; bestehende Listen/Berechtigungen bleiben unverändert.

Die übrigen 24 Fachlisten (Mandantendaten) bleiben gemeinsam/ungetrennt — siehe Datenmodell, Abschnitt 9, offener Punkt 1, falls auch dort eine Standorttrennung benötigt werden sollte.

### C3. Echter Testlauf 27.10.2026 — behobener Fehler und bekannte PnP-3.x-Fallen

**Der erste echte Lauf durch Nils** (PnP.PowerShell aktuell, PowerShell 7.6.9, gegen `https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei`) brach beim Anlegen von `Substanznachweise` ab, direkt nach dem ersten Feld (`nachweis_id`), mit dem Fehler "Dieses Nachschlagefeld kann kein Verhalten für Beziehungen erzwingen, weil es nicht indiziert ist" beim `Add-PnPFieldFromXml`-Aufruf für einen `erfassung_ref`-Lookup.

**Ursache:** Das Skript setzte `RelationshipDeleteBehavior="Restrict"` bislang **inline in der FieldXml bei der Erstanlage** eines Lookup-Felds. SharePoint verlangt für `Restrict`/`Cascade` aber einen bereits **indizierten** Lookup — ein neu angelegtes Feld ist zum Anlagezeitpunkt noch nicht indiziert, also schlägt die Anlage fehl. Dasselbe Problem besteht grundsätzlich auch im `DE/AO`-Modul (siehe dort README Abschnitt C2) für die dort bereits bestehenden Lookups; dort war es im Testlauf vom 27.10.2026 nicht aufgefallen, da die betroffenen Felder auf der Testsite bereits aus einem früheren Lauf existierten (nur der Angleichungspfad, nicht die Erstanlage, wurde durchlaufen) — bei diesem Modul war es der allererste Lauf überhaupt.

**Fix (nach dem im `DE/AO`-Modul etablierten Muster, README dort Abschnitt C2):**

1. **Lookup-Erstanlage ohne `RelationshipDeleteBehavior`:** `Add-Field` erzeugt neue Lookup-/LookupMulti-Felder jetzt immer **ohne** dieses Attribut in der initialen `FieldXml`. Das Löschverhalten wird ausschliesslich im zweiten Schritt gesetzt.
2. **`Set-LookupDeleteBehavior` indiziert zuerst, dann CSOM, dann Verifikation:** Nach jeder Feldanlage/-angleichung ruft `Add-Field` unbedingt `Set-LookupDeleteBehavior` auf (für neue **und** bereits bestehende Lookup-Felder mit `-DeleteBehavior Restrict`/`Cascade` gleichermassen). Diese Funktion indiziert das Feld zuerst über `Set-FieldIndexAndUniqueness`, setzt danach den Enum-Wert `RelationshipDeleteBehaviorType` direkt per CSOM (`$ctx.CastTo[Microsoft.SharePoint.Client.FieldLookup](...)`, `UpdateAndPushChanges($true)` statt `Set-PnPField -Values`, da Letzteres den String nur mit einer **Warnung** statt eines Fehlers ablehnt — siehe Punkt 4), und liest den Wert danach zurück, um ihn mit dem Sollwert zu vergleichen, bevor Erfolg gemeldet wird.
3. **Idempotente Fortsetzung eines teilweise angelegten Stands:** Da die Prüfung/Indizierung/CSOM-Setzung unbedingt bei **jedem** Lauf für **jeden** betroffenen Lookup erfolgt (nicht nur bei der Erstanlage), wird ein bereits teilweise angelegter Stand (z. B. `Substanznachweise` mit `nachweis_id`, aber ohne den fehlgeschlagenen `erfassung_ref`) beim nächsten Lauf sauber fortgesetzt: `New-ListIfMissing`/`Add-Field` überspringen bereits vorhandene Listen/Felder, legen fehlende neu an, und `Set-LookupDeleteBehavior` gleicht Indizierung und Löschverhalten für **alle** `erfassung_ref`-Lookups an — unabhängig davon, ob sie in diesem oder einem früheren Lauf entstanden sind.
4. **`-WarningAction Stop` und Zurücklesen vor jeder Erfolgsmeldung (übernommen aus `DE/AO`):** Alle `Set-PnPField`-Aufrufe (`Title`, `Required`, `Indexed`, `EnforceUniqueValues`, `Choices`) laufen jetzt mit `-WarningAction Stop`, damit eine von PnP nur als Warnung gemeldete, in Wahrheit fehlgeschlagene Eigenschaftsänderung (bekannte PnP-3.x-Falle: `"... Value will be ignored."`) zu einem fangbaren Fehler wird, statt vom Skript fälschlich als Erfolg gemeldet zu werden. Jede Erfolgsmeldung erfolgt erst nach einem erneuten `Get-PnPField`-Aufruf und Vergleich mit dem Sollwert.
5. **`Choices` explizit als `[string[]]`:** Beim Ergänzen von Auswahlwerten auf bereits bestehenden Choice-/MultiChoice-Feldern wird das zusammengeführte Array explizit als `[string[]]` typisiert (zur Laufzeit sonst `System.Object[]`, was `Set-PnPField` ebenfalls nur mit einer Warnung ablehnt); schlägt das dennoch fehl, greift ein CSOM-Fallback über `FieldChoice.Choices`.

Keines dieser Felder im Feldkatalog wurde verändert (weiterhin 367 Spalten, 89 Codebooks) — der Fix betrifft ausschliesslich die Hilfsfunktionen im Skript.

## D. Fehlerprotokoll (`Eingang_Fehler`, DE/AO, wiederverwendet)

Nummerierungskonvention für `form_no` dieses Moduls (Version 3), um Kollision mit AO (0-8) und früheren Modul-Fassungen (101-111 Update 0, 201-207 Update 1) zu vermeiden:

| Formular (B1) | `form_no` |
|---|---|
| Formular 1 — Personenblatt | 301 |
| Formular 2 — Aufgabenblatt | 302 |
| Formular 3 — Arbeitsorganisation, Zeit und Ort | 303 |
| Formular 4 — Ressourcen und Kosten | 304 |
| Formular 5 — Nachweise und Abschluss | 305 |

**Schutz der öffentlichen Formulare (Update 3, Entscheidung Nils):** Die Formulare bleiben öffentlich ("Jeder mit dem Link kann antworten", keine Gästekonten für externe Mandanten). Statt eines `access_code`-Mechanismus trägt jedes Formular ein Pflichtfeld **Erfassungsreferenz** (`referenzcode`, siehe `Erfassungen.referenzcode`). Vor jeder Elementanlage prüft der Flow:

1. Existiert zur eingegebenen Erfassungsreferenz ein `Erfassungen`-Datensatz? Wenn nicht: Ablage in `Eingang_Fehler`.
2. Ist der Status dieser Erfassung nicht `abgeschlossen` (siehe `Erfassungen.status`)? Ist er `abgeschlossen`, ebenfalls Ablage in `Eingang_Fehler` statt in den Fachlisten.

Diese Prüfung ist **ausdrücklich eine Plausibilitätsprüfung, kein Berechtigungsnachweis** (Anhang B3: "Erfassungsreferenzen sind keine Berechtigungsnachweise"). Die eigentliche Absicherung erfolgt organisatorisch: der Formular-Link wird ausschliesslich an den jeweiligen Mandanten versendet, und Microsoft Forms gewährt Antwortenden ohnehin keinerlei Leserecht auf die SharePoint-Listen — niemand kann über das Formular fremde Erfassungen einsehen, unabhängig von der Referenzprüfung. Zusätzlich wird je Formular ein **Formular-Enddatum** (`Erfassungen.formular_enddatum`, in Microsoft Forms unter Einstellungen → Start- und Enddatum einzutragen) nach Ende des jeweiligen Erhebungszeitraums gesetzt, sodass das Formular nach Fristablauf automatisch keine Antworten mehr annimmt.

## E. Forms-Aufteilung (Anhang B1) — fünf Blätter

Statische Forms-Listen müssen gepflegt werden. Automatische Live-Abfrage, beliebige Wiederholgruppen, automatische Datenübernahme zwischen Formularen und sichere Vorbelegung sind **keine** vorausgesetzten Funktionen (B3). Bei separaten Formularen werden bestehende Aufgaben über eine bereitgestellte Referenz (Text, intern aufgelöst) zugeordnet — keine erneute Tätigkeitsbeschreibung.

Jedes Formular beginnt mit der **Erfassungsreferenz** (`referenzcode`, Text, Pflicht) statt der rohen internen `ErfassungID` — siehe Abschnitt D zur Plausibilitätsprüfung durch den Flow.

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
7. **Erfassungsreferenz-Prüfung** (Update 3) vor jeder Elementanlage: unbekannte/fehlende `referenzcode`-Antwort oder Erfassung mit Status `abgeschlossen` → Eintrag in `Eingang_Fehler` statt in den Fachlisten (siehe Abschnitt D). Dies ist eine Plausibilitäts-, keine Berechtigungsprüfung.
8. **Formularübergreifende Kontextbedingungen** (z. B. D/V/K-Zeilen setzen eine bereits über Formular 2 angelegte `Aufgaben`-Zeile voraus): findet der Flow keine passende Zeile, Eintrag in `Eingang_Fehler` statt verwaistem Datensatz.
9. **H-Handlungen: Spaltenexklusivität** (Update 3). Derselbe Handlungscode (z. B. `H_PERSONAL_01_BEWERBER_AUSGEWAEHLT`) darf nicht gleichzeitig in mehr als einer der drei Spalten `handlungen_ausgefuehrt`/`handlungen_nicht_ausgefuehrt`/`handlungen_unbekannt` stehen. Verletzt eine Formularantwort dies (z. B. durch einen Bedienfehler bei der Übernahme), legt der Flow **keinen** stillschweigend bereinigten Datensatz an, sondern einen Eintrag in `Eingang_Fehler` bzw. `OffenePunkte`. Auswertungen je einzelner Handlung müssen entsprechend alle drei Spalten auflösen: ein Code ohne Eintrag in irgendeiner der drei Spalten bedeutet "nicht gefragt", nicht "nicht bekannt".
10. **`Aufgabenorte`: keine Doppelzählung zwischen Arbeitszeit-Ort und Funktionsort** (Update 3). Zeilen mit `bezugsart = FUNKTIONSORT` dürfen keine Werte in `o02_status`/`o02_stunden`/`o02_prozent` tragen (diese Spalten sind ausschliesslich für `bezugsart = ARBEITSZEIT_ORT` bestimmt). Der Flow weist eine Formularantwort, die beides gleichzeitig befüllt, ab (Eintrag in `Eingang_Fehler`), statt die Stunden stillschweigend zu übernehmen.

## H. Datei-Upload (keine nativen Forms-Uploads)

Wie in Version 2: kein nativer Forms-Datei-Upload. Jede Frage mit Anlagenreferenz wird als Text-Frage umgesetzt; die Datei läuft über den vorgesehenen Kanzlei-Übermittlungsweg in die Dokumentbibliothek `Substanznachweise`, verknüpft über `Belegverknuepfungen` (`ziel_typ`+`ziel_id`). Funktionen und Berechtigungen vor Einsatz im Tenant prüfen (B3).

## I. Freigabe und Rollout

1. Je Formular „Jeder mit dem Link kann antworten" — Link wird ausschliesslich an den jeweiligen Mandanten versendet (siehe Abschnitt D).
2. Je Formular in Microsoft Forms unter Einstellungen → Start- und Enddatum ein **Formular-Enddatum** nach Ende des jeweiligen Erhebungszeitraums eintragen (siehe Abschnitt D, `Erfassungen.formular_enddatum`).
3. Je Formular/Liste-Paar ein Power-Automate-Flow gemäss Abschnitt G, inklusive der Erfassungsreferenz-/Status-Prüfung (G.1, Regel 7) und der H-Handlungs-Spaltenexklusivitätsprüfung (G.1, Regel 9).
4. Testdurchlauf mit Dummy-Erfassung vor Versand an echte Mandanten/Mitarbeitende.
5. `Eingang_Fehler` regelmässig sichten (gemeinsam mit dem AO-Modul).
6. `display_label`-Felder durch den jeweiligen Flow nach Elementanlage befüllen.
7. `InterneBewertungen_<Standort>`-Berechtigungen prüfen: Die Gruppennamen `steueranwaltskanzlei` (Gesamtgruppe), `Kanzlei ZH` und `Kanzlei-HH` (Standortgruppen) sind als Default bereits im Skript hinterlegt (siehe Abschnitt C2) und müssen nur dann explizit überschrieben werden, wenn die tatsächlichen Gruppennamen im Zieltenant abweichen. Nach dem Lauf die Log-Ausgabe je Gruppe prüfen (SharePoint-Gruppe oder M365-/Entra-ID-Gruppe gefunden und berechtigt, oder Warnung bei nicht aufgelöstem Namen).

## J. Offene Punkte

Siehe Datenmodell, Abschnitt 9 — insbesondere, ob neben `InterneBewertungen` auch die Mandantendaten-Fachlisten eine Standorttrennung benötigen (als offener Punkt gemeldet, nicht umgesetzt). Die konkreten Gruppennamen (`steueranwaltskanzlei`, `Kanzlei ZH`, `Kanzlei-HH`) sind durch Nils bestätigt und als Default-Werte für `-GesamtGruppe`/`-StandortGruppen` hinterlegt; vor dem ersten echten Skriptlauf ist nur noch zu prüfen, ob diese Gruppen (als SharePoint-Gruppe oder M365-/Entra-ID-Gruppe) im Zieltenant tatsächlich existieren. Zugriffsschutz der öffentlichen Formulare, `InterneBewertungen`-Standorttrennung, R26-Granularität und H-Handlungs-Ablage sind durch die Entscheidungen Nils' in Update 3 bereits geklärt (siehe Datenmodell, Abschnitt 8).
