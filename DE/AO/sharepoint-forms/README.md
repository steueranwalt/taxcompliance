# SharePoint-Listen + Microsoft-Forms-Familie „Steuerliche Erfassung DE / Auslandsbezug“

Quellen: [`../Einheitliches-Datenmodell-steuerliche-Erfassung-DE-Auslandsbezug.md`](../Einheitliches-Datenmodell-steuerliche-Erfassung-DE-Auslandsbezug.md), [`../formulardaten-roherfassung.md`](../formulardaten-roherfassung.md).

Vertraulichkeit: Dieses Verzeichnis enthält ausschliesslich Schema-/Metadaten (Listen-, Spalten-, Formularstruktur, Kz-Referenzen). Keine Mandats- oder Klientendaten. Beim Testdurchlauf ausschliesslich Dummy-Daten verwenden.

## A. Status und offener Punkt

Der Microsoft_365-Konnektor dieser Session verfügt nur über delegierte Lesescopes (`Sites.Read.All` u. a.). Das Anlegen von Listen/Spalten per Graph API scheitert daran. `Sites.Manage.All`/`Sites.FullControl.All` sind in der Azure-AD-App-Registrierung zwar als **Anwendungsberechtigung** vorhanden, der Konnektor nutzt aber einen **delegierten** Token — dieser erhält den Schreib-Scope erst nach erneutem Verbindungs-/Consent-Vorgang des Konnektors (nicht durch blosses Freischalten in Azure AD).

Bis der Schreibzugriff steht, liegt hier ein vollständiges **PnP-PowerShell-Skript** (`New-SteuerlicheErfassungListen.ps1`), das eine berechtigte Person (Kanzlei-Admin oder mit erneuertem Konnektor-Zugriff) einmalig ausführt. Danach folgt die manuelle Forms-Einrichtung nach Abschnitt E — Microsoft Forms hat keine öffentliche API, weder für den Konnektor noch für MS Graph; die Formulare müssen so oder so von Hand (bzw. über „Automatisieren → Formular erstellen“ in SharePoint) angelegt werden.

## B. Zielsite bestimmen

Vor Ausführung prüfen (Website-Einstellungen → Freigabe → Erweiterte Einstellungen), welche der beiden Sites externe Formularantworten ohne Login zulässt:

1. `https://obenhaus.sharepoint.com/sites/steueranwaltskanzlei` (bevorzugt)
2. `https://obenhaus.sharepoint.com/sites/service` (Ausweichoption, falls 1. organisationsweit gesperrt ist)

## C. Listenerstellung (PnP-PowerShell)

```powershell
.\New-SteuerlicheErfassungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/<ziel-site>" -ClientId "<Entra-App-ClientId>"
```

Legt an bzw. gleicht an: `0_Fallsteuerung`, `1_Allgemeiner_Stammblock`, `2_Unternehmens_Gruendungsmodul`, `3_Personen_und_Vertretung`, `4_Beteiligte_und_Quoten`, `5_Betriebsstaetten`, `6_Steuer_und_Umsatzsteuerprofil`, `7_Auslandsmitteilung_BZSt2`, `8_Unterlagen`, `Technische_Mindestfelder` (intern, kein Form) sowie neu `Eingang_Fehler` (intern, kein Form; Protokoll fehlgeschlagener Formular-Übernahmen, siehe Abschnitt D1) — jeweils mit allen Spalten aus dem Auftrag, inkl. `case_id`-Lookup auf `0_Fallsteuerung` in jeder Folgeliste.

**Idempotenz/Angleichung:** Das Skript legt fehlende Listen/Spalten an. Bereits vorhandene Spalten werden **angeglichen**, nicht nur übersprungen: Anzeigename und Pflichtstatus werden nachgezogen, fehlende Auswahlwerte werden **ergänzt** (nie entfernt). Es werden nie Listen, Spalten oder Auswahlwerte gelöscht. Angleichungen, die an vorhandenen Daten scheitern können (z. B. „eindeutige Werte“ bei bereits vorhandenen Duplikaten), brechen den Lauf nicht ab, sondern erzeugen nur eine Warnung in der Konsole — diese Zeilen danach manuell prüfen.

**SharePoint kennt keine bedingten Pflichtfelder.** Die Spalte „Erforderlich“ wird deshalb nur bei *unbedingten* Pflichtfeldern gesetzt (`-Required`). Alle mit „Bedingt“ markierten Felder bleiben in SharePoint optional; die Pflichtlogik wird ausschliesslich über Forms-Branching (Abschnitt E) durchgesetzt. Das gilt jetzt auch für `legal_capacity` (Rechtsfähigkeit, nur Personengesellschaft) und `par27_ao_agreement` (§ 27 AO, nur Körperschaft ausländischen Rechts).

**`Title` ist überall optional.** Die SharePoint-Standardvorlage macht die Spalte „Title“ in jeder neuen Liste zur Pflicht; die Forms-Flows befüllen „Title“ aber nicht zwangsläufig (die fachliche Kennung je Liste ist eine eigene Spalte, z. B. `case_id`, `last_name_or_company`, `site_name`). Das Skript schaltet „Title“ in jeder Liste auf optional. Empfehlung für die Power-Automate-Flows: „Title“ trotzdem mit einem sprechenden Wert befüllen (z. B. `case_id` + Name/Dokumenttyp), damit SharePoint-Standardansichten lesbar bleiben.

**Datumsfelder sind reine Datumsfelder (`DateOnly`), keine Datum-mit-Uhrzeit-Felder.** Geburtsdatum, Gründungsdatum, Tätigkeitsbeginn/-ende usw. benötigen keine Uhrzeitkomponente; alle entsprechenden Spalten sind mit `Format='DateOnly'` angelegt.

**Ja/Nein-Fragen sind SharePoint-Boolean-Spalten.** Jede als „Choice Ja/Nein“ in Abschnitt E bezeichnete Forms-Frage entspricht einer SharePoint-Spalte vom Typ `Boolean` (z. B. `already_registered`, `small_business_rule`, `sepa_desired`). Der Flow muss die beiden Forms-Antwortoptionen „Ja“/„Nein“ auf `true`/`false` abbilden (Power Automate macht das bei einer 2-Options-Auswahl i. d. R. automatisch über den Textvergleich; bei Abweichungen einen Ausdruck wie `equals(outputs('...'), 'Ja')` verwenden).

**Auswahlwerte (Choice-Optionen) sind immer mit Umlauten geschrieben** (z. B. „Körperschaft nach ausländischem Recht“, „Ständiger Vertreter“, „Treuhänder“, „römisch-katholisch“), identisch zwischen diesem README und dem Skript. Bei einer bereits laufenden Installation ergänzt das Skript fehlende (umlauthaltige) Auswahlwerte, entfernt aber etwaige ältere, nicht-umlauthaltige Varianten nicht automatisch (siehe Angleichungshinweis oben) — nach einem ersten produktiven Lauf ggf. manuell bereinigen, sobald sicher ist, dass keine Altdaten mehr die alte Schreibweise verwenden.

`created_by`/`created_at` (Liste 0) werden nicht als Zusatzspalten angelegt, sondern über die SharePoint-Systemfelder `Author`/`Created` abgebildet.

`related_object` (Liste 8) ist in SharePoint kein Multi-Listen-Lookup — ersatzweise vier Einzel-Lookups: `related_case`, `related_person`, `related_participation`, `related_site`. Da Forms selbst keinen Lookup kennt, nimmt die Forms-Frage „Bezug zu Objekt“ die Antwort stattdessen als Freitext in der Spalte `related_object_text` auf; die Auflösung auf die konkrete Lookup-Zeile erfolgt danach manuell oder über einen erweiterten Flow.

Die Lookup-Anzeigefelder (`ShowField`) für `related_person`, `related_participation` und `related_site` sind jeweils `display_label` (neue Textspalte in Liste 3/4/5), nicht `last_name_or_company`/`site_name` — letztere sind bei Namensgleichheit nicht eindeutig. Ein Flow sollte `display_label` unmittelbar nach Elementanlage befüllen, z. B. `"<Name> (<Rolle>, Fall <case_id>, ID <ID>)"`.

**Löschverhalten der `case_id`-Lookups:** In allen Folgelisten (1-8, `Technische_Mindestfelder`) ist der `case_id`-Lookup auf `0_Fallsteuerung` mit `RelationshipDeleteBehavior="Restrict"` angelegt — ein Fallsteuerungs-Datensatz kann nicht gelöscht werden, solange noch Folgedatensätze referenzieren. Die optionalen Sekundär-Lookups in Liste 8 (`related_person`, `related_participation`, `related_site`, `related_case`) bleiben beim Standardverhalten `None`, damit das Löschen einer Person/Beteiligung/Betriebsstätte nicht an einer angehängten Unterlage scheitert.

### C1. ClientId / tenant-eigene Entra-App-Registrierung (statt PnP Management Shell)

Seit September 2024 ist die generische PnP-Management-Shell-App (`31359c7f-bd7e-475c-86db-fdb8c937548e`) in den meisten Tenants gesperrt bzw. deaktiviert — `-ClientId` ist daher **faktisch Pflicht** und im Skript als Pflichtparameter hinterlegt. Einmalige Einrichtung durch eine Person mit Entra-Admin-Rechten im Tenant `steueranwaltskanzlei.com`:

1. [Azure Portal](https://portal.azure.com) → **Microsoft Entra ID** → **App-Registrierungen** → **Neue Registrierung**.
2. Name frei wählbar (z. B. „PnP PowerShell – Steuerliche Erfassung“), Kontotyp **„Konten nur in diesem Organisationsverzeichnis“**.
3. **Authentifizierung** → **Plattform hinzufügen** → **Mobile and desktop applications** → Redirect-URI `http://localhost` auswählen (Public-Client-Flow, kein Client-Secret nötig).
4. Unter **Authentifizierung** → **Erweiterte Einstellungen**: „Öffentliche Clientflows zulassen“ auf **Ja**.
5. **API-Berechtigungen** → **Berechtigung hinzufügen** → **SharePoint** → **Delegierte Berechtigungen** → `AllSites.FullControl` → hinzufügen, danach **Administratorzustimmung erteilen**.
6. Die **Anwendungs-ID (Client)** von der Übersichtsseite als `-ClientId` verwenden.

Danach wie gewohnt:

```powershell
.\New-SteuerlicheErfassungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/<ziel-site>" -ClientId "<Anwendungs-ID aus Schritt 6>"
```

`Connect-PnPOnline -Interactive` öffnet ein Anmeldefenster; die anmeldende Person benötigt mindestens Mitgliedsrechte auf der Zielsite.

### C2. Prüfskript und bekannte PnP-3.x-Fallen

**`Test-SteuerlicheErfassungListen.ps1`** (gleicher Ordner) prüft rein lesend, ob eine Zielsite tatsächlich dem Soll-Stand aus `New-SteuerlicheErfassungListen.ps1` entspricht:

```powershell
.\Test-SteuerlicheErfassungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/<ziel-site>" -ClientId "<Entra-App-ClientId>"
```

Es liest die Soll-Felder direkt aus `New-SteuerlicheErfassungListen.ps1` (per Parse des Skripts, nicht per Dot-Sourcing/Ausführung — letzteres würde sofort live verbinden und Änderungen vornehmen), damit es **keine zweite, von Hand gepflegte Feldliste** gibt, die aus dem Takt geraten könnte. Vor jeder Verbindung prüft es ausserdem dieselbe Namensregel wie das Hauptskript (siehe unten). Geprüft werden je Feld: Existenz, Feldtyp (inkl. `DateOnly` vs. `DateTime`), Vollständigkeit der Auswahlwerte, bei Lookups mit Löschverhalten `Restrict`/`Cascade` Indizierung + tatsächliches `RelationshipDeleteBehavior`, sowie `EnforceUniqueValues` dort, wo das Hauptskript es verlangt (aktuell `case_id` und `access_code` in `0_Fallsteuerung`). SharePoint-Systemfelder (`Title`, `TaxKeyword`, `Author`, `Editor`, `Created`, `Modified`, `ContentType`, `Attachments`, `ID` usw.) werden nie geprüft, da sie nicht aus einem `Add-Field`-Aufruf stammen. Ausgabe: eine Soll/Ist-Tabelle je Prüfung, am Ende zusätzlich eine eindeutige Zeile `ERGEBNIS: OK` bzw. `ERGEBNIS: <n> Abweichungen`; Exit-Code `0` ohne Abweichungen, `1` bei mindestens einer Abweichung.

**Bekannte PnP.PowerShell-3.x-Fallen (gefunden im echten Testlauf 27.10.2026, PnP.PowerShell 3.4.1 / PowerShell 7.6.9 gegen `steueranwaltskanzlei`):** `Set-PnPField -Values @{...}` kann bei zwei Eigenschaftstypen den gelieferten Wert nicht zuverlässig konvertieren und gibt dabei nur eine **Warnung** aus (`"... Value will be ignored."`), **keinen Fehler** — ein Skript ohne `-WarningAction Stop` läuft weiter und meldet fälschlich Erfolg:

1. **`RelationshipDeleteBehavior`** (Lookup-Löschverhalten): ein String wie `"Restrict"` wird nicht in den Enum-Typ `Microsoft.SharePoint.Client.RelationshipDeleteBehaviorType` konvertiert. Zusätzlich verlangt SharePoint für `Restrict`/`Cascade` einen **indizierten** Lookup — das Skript indizierte Lookups vor dieser Korrektur nicht automatisch mit. Fix: zuerst indizieren, dann den Enum-Wert direkt per CSOM setzen (`$ctx.CastTo[Microsoft.SharePoint.Client.FieldLookup](...)`, `UpdateAndPushChanges($true)`), danach zurücklesen und verifizieren.
2. **`Choices`** (Auswahlwerte bei bestehenden Choice-Feldern): ein PowerShell-Array aus `@($existingChoices) + @($missingChoices)` ist zur Laufzeit `System.Object[]`, nicht `System.String[]`, und wird ebenfalls nur mit einer Warnung abgelehnt. Fix: das Array explizit als `[string[]]` typisieren; schlägt das trotzdem fehl, Fallback direkt per CSOM (`FieldChoice.Choices`).

**Allgemeine Regel im Skript seit diesem Update:** jeder `Set-PnPField`-Aufruf läuft mit `-WarningAction Stop` (jede Warnung wird zum fangbaren Fehler) und jede Erfolgsmeldung erfolgt erst, nachdem der Wert erneut gelesen und mit dem Sollwert verglichen wurde — nie mehr "Erfolg", nur weil der Cmdlet-Aufruf selbst keine Exception geworfen hat.

**Weitere, am 27./28.10.2026 im Realbetrieb gefundene Fallen (Prüflauf mit `Test-SteuerlicheErfassungListen.ps1`: 21 Abweichungen bei 272 Prüfungen):**

1. **Interne Feldnamen über 32 Zeichen (KRITISCH):** SharePoint kürzt `InternalName` intern auf 32 Zeichen. Ein Skript, das einen längeren Namen verwendet, findet das Feld bei einem späteren Angleichungslauf unter dem vollen (nicht gekürzten) Namen nicht mehr wieder und legt es **erneut** an — SharePoint hängt dem (ebenfalls gekürzten) Namen des Duplikats automatisch einen Zahlen-Suffix an (`_0`, `_1`, …). Betraf 6 Felder, siehe Changelog-Tabelle unten. Fix: alle sechs Felder auf sprechende Namen ≤ 32 Zeichen umbenannt; zusätzlich eine harte Namensregel-Prüfung ganz am Anfang **beider** Skripte (vor jeder Verbindung/Änderung), die abbricht, sobald ein interner Name > 32 Zeichen ist oder Zeichen ausserhalb `[A-Za-z0-9_]` enthält — im Hauptskript per statischem AST-Parse seiner selbst (`Test-InternalFieldNamingRules`, zusätzlich eine Laufzeit-Prüfung in `Add-Field` als zweites Sicherheitsnetz), im Prüfskript auf denselben bereits eingelesenen Soll-Definitionen. **Die bereits entstandenen Duplikate mit Suffix wurden von der Kanzlei direkt auf der Site gelöscht, nicht durch dieses Skript.**
2. **`DisplayFormat` bei bereits bestehenden Datumsfeldern:** die bisherige Angleichungslogik prüfte und korrigierte `DisplayFormat` bei bereits vorhandenen Feldern nie — nur die XML-Erstellung eines **neuen** Felds setzte `Format='DateOnly'` korrekt. Dadurch standen 13 schon bestehende Datumsfelder auf der Zielsite trotz `-Type DateOnly` im Skript weiterhin auf `DisplayFormat=DateTime`. Fix: neue Funktion `Set-DateOnlyFormat`, die nach jeder Feldanlage/-angleichung für `-Type DateOnly` unbedingt aufgerufen wird (wie schon `Set-FieldIndexAndUniqueness`/`Set-LookupDeleteBehavior`), das `DisplayFormat` bei Abweichung direkt per CSOM setzt (`$ctx.CastTo[Microsoft.SharePoint.Client.FieldDateTime](...)`, `DisplayFormat = [Microsoft.SharePoint.Client.DateTimeFieldFormatType]::DateOnly`) und danach zurückliest/verifiziert.
3. **Typabweichungen werden jetzt klar gewarnt, nie still übernommen oder automatisch korrigiert:** `notification_year` stand auf der Zielsite bereits als `Number`, obwohl das Skript es als `Text` definierte (Entscheid revidiert, siehe Changelog); `participant_name_share` stand als `Text` statt `Note`. SharePoint unterstützt Typänderungen an bestehenden Feldern ohnehin nicht zuverlässig per Skript — das Skript **löscht und ändert deshalb den Typ nie automatisch**, meldet eine Typabweichung aber jetzt immer klar mit Liste/Feld/Soll/Ist (`TYP-ABWEICHUNG: ...`) statt still weiterzulaufen, und überspringt bei einer Typabweichung die typspezifische Angleichung (z. B. Auswahlwerte-Ergänzung), da diese auf dem falschen Feldtyp keinen Sinn ergäbe.

## D. Fall-ID-Generator

`case_id` in Liste 0 ist ein einzeiliges Textfeld ohne serverseitige Auto-Nummerierung, jetzt **indiziert und mit „eindeutige Werte erzwingen“** versehen (fachliche Prüfung Punkt 2: `case_id` war weder indiziert noch eindeutig). Empfehlung: Format `JJJJ-NNNN` (z. B. `2026-0001`), vergeben durch die Kanzlei bei Fallanlage, oder ergänzend ein Power-Automate-Flow „Bei Erstellung eines Elements in 0_Fallsteuerung → berechne case_id aus ID-Spalte + Jahr → Element aktualisieren“.

**Wichtig wegen `case_id` = Pflicht + eindeutig:** `case_id` bleibt (wie bisher) eine SharePoint-Pflichtspalte. Ein Flow, der das Element zunächst ohne `case_id` anlegen und den Wert erst in einem zweiten Schritt aus der SharePoint-`ID` berechnen würde, schlägt an der Pflicht-Prüfung fehl. Ein künftiger Auto-Nummerierungs-Flow muss `case_id` daher **vor** dem „Element erstellen“-Schritt berechnen (z. B. höchste bisherige Fall-ID je Jahr per „Elemente abrufen“ + sortieren ermitteln), nicht aus der neu erzeugten `ID`-Spalte ableiten. Bis ein solcher Flow steht: manuelle Vergabe vor Weitergabe des Formularlinks an den Mandanten.

### D1. Zugangscode (`access_code`) und `Eingang_Fehler`

Fall-IDs im Format `JJJJ-NNNN` sind fortlaufend und damit leicht erratbar. Liste 0 erhält deshalb zusätzlich die Spalte `access_code` (Text, indiziert, eindeutige Werte erzwungen, **nicht** `-Required` — ein nachträgliches Pflichtfeld ohne Default würde bei bereits vorhandenen Fallsteuerungs-Einträgen die Spaltenanlage verhindern). Empfehlung: Der fallanlegende Flow setzt `access_code` unmittelbar bei Fallanlage, z. B. per Power-Automate-Ausdruck `toUpper(substring(guid(),0,10))`. Jeder Flow, der eine Formularantwort (1-8) einem Fall zuordnet, sollte künftig `case_id` **und** `access_code` gemeinsam prüfen (z. B. als vorausgefüllte, aber unsichtbare/geschützte Felder im Formularlink), bevor ein Element in der Zielliste erzeugt wird.

Schlägt diese Prüfung fehl (unbekannte/fehlende `case_id`, falscher `access_code`, sonstige Validierungsfehler), landet die Formularantwort nicht kommentarlos im Nichts, sondern wird in der neuen internen Liste **`Eingang_Fehler`** protokolliert (`form_no`, `case_id_raw`, `reason`, `payload`, `status`). Diese Liste regelmässig sichten (siehe Abschnitt F).

## E. Microsoft-Forms-Spezifikation je Formular

Formulare können nicht aus SharePoint-Spalten automatisch generiert werden, sobald Verzweigungsregeln nötig sind (die integrierte Funktion „Automatisieren → Formular erstellen“ erzeugt nur ein 1:1-Formular ohne Branching). Die folgenden Formulare deshalb direkt in [forms.office.com](https://forms.office.com) unter dem Konto der Zielsite anlegen, Fragen 1:1 aus den Listenspalten übernehmen. Fragetyp-Zuordnung:

| SharePoint-Spaltentyp | Forms-Fragetyp |
|---|---|
| Einzeiler Text | Text (kurze Antwort) |
| Mehrzeiliger Text | Text (lange Antwort) |
| Auswahl | Choice |
| Ja/Nein (Boolean) | Choice, 2 Optionen „Ja“/„Nein“ |
| Datum (`DateOnly`, ohne Uhrzeit) | Date |
| Zahl | Number |
| Anhang | File Upload (erfordert „Jeder mit einem Microsoft-Konto“ — siehe Hinweis unten) |
| Hyperlink (z. B. `file_link`) | keine eigene Forms-Frage; wird durch einen Flow oder manuell befüllt, falls eine Datei ausserhalb von Forms abgelegt wird |
| Nachschlagefeld (Lookup) | Text (Fall-ID wird manuell/vom Vorformular übernommen, kein Live-Lookup in Forms); bei Liste 8 zusätzlich `related_object_text` als Freitext-Rohantwort |

Jedes Formular erhält als erste Frage `Fall-ID` (Text, Pflicht) — vom Formular 0 übernehmen bzw. dem Mandanten mitteilen.

### E.0 Formular 0 — Fallsteuerung

Nur intern (Kanzlei), nicht an Mandanten versendet — dient der Fallanlage.

1. Richtung — Choice: Inbound / Outbound (Pflicht)
2. Rechtsform / Formulartyp — Choice: Einzelunternehmen / Kapitalgesellschaft oder Genossenschaft / Personengesellschaft oder -gemeinschaft / Körperschaft nach ausländischem Recht / BZSt2-Mitteilung (Pflicht)
3. Bereits steuerlich erfasst — Choice Ja/Nein (Pflicht)
4. Bestehende Steuernummer — Text
   - **Branching:** nur einblenden, wenn Frage 3 = Ja
5. Land des Finanzamts — Text (Pflicht)
6. Zuständiges Finanzamt — Text (Pflicht)
7. Zielmeldung (BZSt2-Sachverhalt) — Choice: Betriebe/Betriebsstätten / PersG-Beteiligung / KapG-Beteiligung / Drittstaat-Beherrschung / Negativmeldung
   - **Branching:** nur einblenden, wenn Frage 1 = Outbound
8. Persönliche Bearbeitungsnotiz — Text (lang)

Formularende: Textblock mit Link-Liste zu Formular 1 sowie den je nach Antwort passenden Folgeformularen (siehe Routing-Tabelle Abschnitt E.9).

**Hinweis `access_code`:** Keine Forms-Frage. Der die Fallanlage auslösende Flow setzt beim Anlegen des `0_Fallsteuerung`-Elements zusätzlich `access_code` (Zufallswert, siehe Abschnitt D1) und übergibt `case_id` + `access_code` gemeinsam in den vorausgefüllten Links zu den Formularen 1-8, damit spätere Flows beide Werte prüfen können, bevor sie eine Formularantwort einem Fall zuordnen.

### E.1 Formular 1 — Allgemeiner Stammblock (immer)

1. Fall-ID — Text (Pflicht)
2. Art des Meldepflichtigen — Choice: Person / Firma (Pflicht)
3. Anrede / Titel — Text
   - Branching: nur bei Frage 2 = Person
4. Name / Firma — Text (Pflicht)
5. Vorname — Text
   - Branching: nur bei Frage 2 = Person
6. Namensvorsatz / -zusatz — Text
7. Geburtsdatum — Date
   - Branching: nur bei Frage 2 = Person
8. Religion — Choice: keine / römisch-katholisch / evangelisch / sonstige
   - Branching: nur bei Frage 2 = Person UND Formulartyp = Einzelunternehmen (aus Formular 0 bekannt, in Forms als Kontextfrage 2a „Formulartyp“ wiederholen, da Forms nicht formularübergreifend verzweigt)
9. Identifikationsnummer / Wirtschafts-IdNr. — Text (Pflicht)
10. Rechtsform (deutsch/ausländisch/sonstig) — Text
    - Branching: nur bei Frage 2 = Firma
11. Adressart — Choice: Inland / Ausland (Pflicht)
12. Strasse, Hausnummer, Zusatz — Text (Pflicht)
13. Adressergänzung — Text
14. Postleitzahl, Ort — Text (Pflicht)
15. Staat — Text
    - Branching: nur bei Frage 11 = Ausland
16. Postfach — Text
17. Telefon — Text
18. Internetadresse — Text
19. Genaue Tätigkeit — Text lang (Pflicht)
20. Ausschliesslich vermögensverwaltend tätig — Choice Ja/Nein
21. Abweichender Ort der Geschäftsleitung — Choice Ja/Nein
22. Ort der Geschäftsleitung – Adresse — Text lang
    - Branching: nur bei Frage 21 = Ja
23. Art der Steuernummer-Angabe — Choice: bestehend / neu beantragen (Pflicht)
24. Steuernummer — Text
    - Branching: nur bei Frage 23 = bestehend
25. Zuständiges Finanzamt — Text (Pflicht)
26. Steuerliche Beratung – Name/Firma — Text
27. Steuerliche Beratung – Adresse — Text lang
28. Steuerliche Beratung ist empfangsbevollmächtigt — Choice Ja/Nein
29. Bank – IBAN — Text
30. Bank – BIC — Text
    - Branching: nur einblenden bzw. hervorheben, wenn IBAN nicht mit DE beginnt (Forms kann Textinhalt nicht prüfen — Hinweistext „Pflicht bei ausländischem Institut“ in die Frage aufnehmen, keine harte Verzweigung möglich)
31. Bank – Kontoinhaber — Text
32. Rückfrage-E-Mail (freiwillig) — Text
33. SEPA-Lastschrift gewünscht — Choice Ja/Nein
34. Zustimmung zur Zuständigkeitsvereinbarung nach § 27 AO — Choice Ja/Nein
    - Branching: nur bei Formulartyp = Körperschaft nach ausländischem Recht (Kontextfrage aus Formular 0 wiederholen, Datenmodell Abschnitt 2.4 Kz 18, dort unbedingtes Pflichtfeld für diesen Formulartyp)

### E.2 Formular 2 — Unternehmens-/Gründungsmodul (Inbound; auch Einzelunternehmen und Personengesellschaften, siehe Routing-Tabelle E.9)

1. Fall-ID — Text (Pflicht)
2. Bezeichnung des Unternehmens — Text (Pflicht)
3. Rechtsform — Choice (Pflicht): Einzelunternehmen; Freiberufliche Tätigkeit; Eingetragener Kaufmann (e.K.); GmbH; UG (haftungsbeschränkt); AG; SE; KGaA; eingetragene Genossenschaft (eG); GbR/eGbR; OHG; KG; GmbH & Co. KG; PartG/PartG mbB; sonstige deutsche Rechtsform; ausländische Rechtsform
4. Gründungsart — Choice: Neugründung / Übernahme / Umwandlung / Bargründung / Sachgründung (Pflicht, 5 getrennte Optionen; Bar- und Sachgründung werden bewusst nicht zu einer Option zusammengefasst, da das Datenmodell beide als eigenständiges unbedingtes Pflichtfeld unterscheidet, Kz 91)
5. Gründungsdatum — Date (Pflicht)
6. Beginn der Tätigkeit — Date (Pflicht)
7. Notarielle Errichtung / Musterprotokoll vom — Date
   - Branching: nur bei Rechtsform = Kapitalgesellschaft/Genossenschaft (Kontextfrage aus Formular 0 wiederholen oder als eigene Frage 3a führen)
8. Grund-/Stammkapital – Betrag — Number
   - Branching: nur bei Kapitalgesellschaft
9. Grund-/Stammkapital – Währung — Text
   - Branching: wie 8
10. Eingezahltes Kapital — Number
    - Branching: wie 8
11. Handelsregister-Status — Choice: beabsichtigt / beantragt / erfolgt (Pflicht)
12. Ort des Amtsgerichts — Text
    - Branching: nur wenn Frage 11 ≠ beabsichtigt
13. Register / Registernummer — Text
    - Branching: wie 12
14. Vorheriger Inhaber / Vorunternehmen — Text lang
    - Branching: nur bei Frage 4 = Übernahme
15. Abweichendes Wirtschaftsjahr — Choice Ja/Nein
16. Wirtschaftsjahr – Beginn — Date
    - Branching: nur bei Frage 15 = Ja
17. Gewinnermittlungsart — Choice (Pflicht)
18. Voraussichtlicher Gewinn Eröffnungsjahr — Number (Pflicht)
19. Voraussichtlicher Gewinn Folgejahr — Number (Pflicht)
20. Konzernzugehörigkeit — Choice Ja/Nein
21. Herrschendes Unternehmen – Name — Text
    - Branching: nur bei Frage 20 = Ja
22. Organträgerschaft — Choice Ja/Nein
23. Rechtsfähigkeit — Choice Ja/Nein
    - Branching: nur bei Formulartyp = Personengesellschaft oder -gemeinschaft (Kontextfrage aus Formular 0 wiederholen; Datenmodell Kz 33, dort für diesen Formulartyp unbedingtes Pflichtfeld)
24. Aufteilungsschlüssel (Gewinn-/Verlustverteilung) — Text
    - Branching: wie 23 (Datenmodell Kz 80, dort unbedingtes Pflichtfeld)
25. Gründungsnotar — Name — Text
    - Hinweistext in die Frage aufnehmen: „Falls ausgefüllt, bitte auch die Adresse in der folgenden Frage angeben“ (ELSTER-Portalprüfung 26.10.2026: sobald ein Notar genannt ist, wird dessen Adresse bedingt Pflicht — Forms kann eine Pflicht nicht von einem vorangehenden Freitext abhängig machen, siehe Datenmodell Abschnitt 9.6)
26. Gründungsnotar — Adresse — Text lang
    - Hinweistext wie 25
27. Komplementärin einer KG — Choice Ja/Nein
28. Bezeichnung der KG — Text
    - Branching: nur bei Frage 27 = Ja
29. Handelsregister — Datum (beantragt am / Tag der Eintragung) — Date
    - Branching: nur bei Frage 11 ≠ beabsichtigt
30. Betriebsaufspaltung — Choice Ja/Nein
31. Bezeichnung des Besitzunternehmens — Text
    - Branching: nur bei Frage 30 = Ja
32. Bezeichnung des überlassenen Wirtschaftsguts (wesentliche Betriebsgrundlage) — Text
    - Branching: wie 31 (Kanzleientscheid 27.10.2026, siehe Datenmodell Abschnitt 9.6 — Wortlaut der ELSTER-Fehlerliste nannte nur „Bezeichnung“ ohne weiteren Kontext, der Wortlaut dieser Frage ist daher Kanzleientscheid und im Portal nicht verifiziert)
33. Beginn der tatsächlichen Nutzung — Date
    - Branching: wie 31
34. Anschrift und/oder Steuernummer des Besitzunternehmens — Text lang
    - Branching: wie 31
35. Körperschaftsteuerbefreiung nach § 5 KStG — Choice Ja/Nein
36. Nummer nach § 5 Absatz 1 KStG — Text
    - Branching: nur bei Frage 35 = Ja
37. Feststellung nach § 60a AO — Choice Ja/Nein
38. Zweck der Körperschaft — Text lang
    - Branching: nur bei Frage 37 = Ja
39. Organgesellschaft (körperschaftsteuerliche Organschaft) — Choice Ja/Nein
40. Name/Firma des Organträgers — Text
    - Branching: nur bei Frage 39 = Ja
41. Umsatzsteuerliche Organschaft — Choice Ja/Nein
42. Beginn der umsatzsteuerlichen Organschaft — Date
    - Branching: nur bei Frage 41 = Ja

Fragen 25-42 (Update 2, ELSTER-Portalprüfung 26.10.2026): bedingte Pflichtfelder, Status `belegt_bedingt`. Keine dieser Spalten ist in SharePoint bedingungslos `-Required`, da die Pflicht jeweils an die genannte Auswahl geknüpft ist — Details siehe Datenmodell Abschnitt 9.6.

### E.3 Formular 3 — Personen und Vertretung (wenn vorhanden bzw. Pflicht)

Hinweis am Formularanfang: „Bitte für jede Person/Rolle eine eigene Antwort einreichen (Formular mehrfach ausfüllen).“ — Forms unterstützt keine wiederholbaren Unterobjekte innerhalb einer Antwort.

1. Fall-ID — Text (Pflicht)
2. Rolle — Choice: Gesetzlicher Vertreter / Ständiger Vertreter / Empfangsbevollmächtigter / Steuerliche Beratung / Ehegatte/Lebenspartner (Pflicht)
3. Art der Person — Choice: natürlich / nicht natürlich (Pflicht)
4. Anrede / Titel — Text
   - Branching: nur bei Frage 3 = natürlich
5. Name / Firma — Text (Pflicht)
6. Vorname — Text
   - Branching: nur bei Frage 3 = natürlich
7. Geburtsdatum — Date
   - Branching: nur bei Frage 3 = natürlich
8. Identifikationsnummer — Text
9. Beruf / Tätigkeit — Text
10. Adresse — Text lang (Pflicht)
11. Telefon — Text
12. Steuerliche Kennzeichen (Land/Steuernummer/Finanzamt) — Text
13. Abhängige/unabhängige Person — Choice
    - Branching: nur bei Frage 2 = Ständiger Vertreter
14. Abschlussvollmacht — Choice Ja/Nein
    - Branching: wie 13
15. Empfangsbevollmächtigt — Choice Ja/Nein

### E.4 Formular 4 — Beteiligte und Quoten (KapG, PersG, Ausland, BZSt2)

Hinweis am Formularanfang: je Beteiligtem eine Antwort.

1. Fall-ID — Text (Pflicht)
2. Laufende Nummer / Zeichnernummer — Number (Pflicht)
3. Art des Beteiligten — Choice: natürlich / nicht natürlich (Pflicht)
4. Name / Firma — Text (Pflicht)
5. Geburtsdatum — Date
   - Branching: nur bei Frage 3 = natürlich
6. Adresse — Text lang (Pflicht)
7. Steuerliche Kennzeichen (Land/Steuernummer/Finanzamt/Wirtschafts-IdNr.) — Text
8. Art der Beteiligung — Choice: direkt / mittelbar (Pflicht)
9. Rolle — Choice: Anteilseigner / Gesellschafter / Treuhänder (Pflicht)
10. Beteiligung nominell — Number (Pflicht)
11. Beteiligung in Prozent — Number (Pflicht)
12. Zähler / Nenner — Text
    - Branching: nur bei Formulartyp = Personengesellschaft (Kontextfrage wiederholen)
13. Treuhandverhältnis — Choice Ja/Nein (Pflicht)
14. Voraussichtlicher Gewinnanteil Eröffnungsjahr — Number
    - Branching: wie 12
15. Voraussichtlicher Gewinnanteil Folgejahr — Number
    - Branching: wie 12
16. Beschränkte Steuerpflicht — Choice Ja/Nein
17. Beteiligt seit dem — Date
    - Branching: nur bei Richtung = Outbound/BZSt2
18. Stimmrechte in Prozent — Number
    - Bezieht sich auf Frage 11 (Beteiligung in Prozent); nur ausfüllen, falls die Stimmrechtsquote von der Kapitalquote abweicht (Datenmodell 9.2 „Beteiligte“)

### E.5 Formular 5 — Betriebsstätten (wenn vorhanden)

Hinweis: je Betriebsstätte/Einrichtung eine Antwort.

1. Fall-ID — Text (Pflicht)
2. Bezeichnung der Betriebsstätte/Einrichtung — Text (Pflicht)
3. Land — Text (Pflicht)
4. Adresse — Text lang (Pflicht)
5. Art der Einrichtung — Choice: fest / nicht fest (Pflicht)
6. Eigentumsverhältnis — Choice: Eigentum / Miete / Nutzung
7. Nutzungsart — Choice: Lagerung / Verarbeitung / Einkauf / Werbung / Sonstige
   - Branching: nur bei Formulartyp = Körperschaft nach ausländischem Recht UND Tätigkeit im Inland
8. Tätigkeitsdauer – von — Date
9. Tätigkeitsdauer bis unbekannt (noch andauernd) — Choice Ja/Nein
10. Tätigkeitsdauer – bis — Date
    - Branching: nur einblenden, wenn Frage 9 = Nein (Forms verzweigt nur vorwärts, siehe KLICKANLEITUNG-FORMS.md Abschnitt C)
11. Umsatzsteuerliche Betriebsstätte — Choice Ja/Nein
12. Telefon / Internetadresse — Text
13. Lohnsteuerliche Betriebsstätte — Choice Ja/Nein

### E.6 Formular 6 — Steuer- und Umsatzsteuerprofil (nur Inbound)

1. Fall-ID — Text (Pflicht)
2. Geschätzter Umsatz Eröffnungsjahr — Number (Pflicht)
3. Geschätzter Umsatz Folgejahr — Number (Pflicht)
4. Kleinunternehmer-Regelung — Choice Ja/Nein
5. Verzicht auf Kleinunternehmer-Regelung — Choice Ja/Nein
   - Branching: nur bei Frage 4 = Ja
6. Voraussichtliche USt (Zahllast/Überschuss) — Number
7. Voranmeldungszeitraum — Choice: Monat / Quartal
8. Soll-/Ist-Besteuerung — Choice: Soll-Besteuerung / Ist-Besteuerung
9. USt-IdNr. beantragen — Choice Ja/Nein
10. Frühere USt-IdNr. — Text
    - Branching: nur bei Frage 9 = Nein (bereits vorhanden)
11. OSS-Verfahren — Choice Ja/Nein
12. Eigener Webshop — Choice Ja/Nein
13. Elektronische Schnittstelle — Text
    - Branching: nur bei Frage 12 = Ja
14. Bauleistungen über 10 % Weltumsatz — Choice Ja/Nein
15. Anzahl Arbeitnehmer insgesamt — Number
16. Beginn Lohnzahlungen — Date
    - Branching: nur bei Frage 15 > 0
17. Voraussichtliche Lohnsteuer — Number
    - Branching: wie 16
18. Freistellungsbescheinigung § 48b EStG — Choice Ja/Nein
19. Steuerfreie Umsätze nach § 4 UStG — Choice Ja/Nein
20. Art des Umsatzes (steuerfrei) — Text
    - Branching: nur bei Frage 19 = Ja
21. Ermässigter Steuersatz — Choice Ja/Nein
22. Art des Umsatzes (ermässigter Satz) — Text
    - Branching: nur bei Frage 21 = Ja
23. Nullsteuersatz — Choice Ja/Nein
24. Art des Umsatzes (Nullsteuersatz) — Text
    - Branching: nur bei Frage 23 = Ja
25. Rechtsvorschrift zum Nullsteuersatz — Text
    - Branching: wie 24
26. Durchschnittssatzbesteuerung § 24 UStG (Land-/Forstwirtschaft) — Choice Ja/Nein
27. Art des Umsatzes (§ 24 UStG) — Text
    - Branching: nur bei Frage 26 = Ja
28. Durchschnittssatzbesteuerung beibehalten oder Verzicht — Choice: Durchschnittssatzbesteuerung beibehalten / Verzicht auf Durchschnittssatzbesteuerung
    - Branching: wie 27
29. Vorsteuervergütung beantragt — Choice Ja/Nein
    - Branching: nur bei Formulartyp = Körperschaft nach ausländischem Recht (Kontextfrage aus Formular 0 wiederholen; nur in diesem Formulartyp laut ELSTER-Portalprüfung bestätigt)
30. Datum der Vorsteuervergütung — Date
    - Branching: nur bei Frage 29 = Ja
31. Aktenzeichen Vorsteuervergütung — Text
    - Branching: wie 30
32. Internetadresse (URL) des Webshops — Text
    - Branching: nur bei Frage 12 = Ja (Eigener Webshop)
33. Identifikationsmerkmal der elektronischen Schnittstelle — Text
    - Branching: nur bei Frage 13 ausgefüllt (Elektronische Schnittstelle)

Fragen 19-33 (Update 2, ELSTER-Portalprüfung 26.10.2026): bedingte Pflichtfelder, Status `belegt_bedingt`, keine Spalte bedingungslos `-Required` — Details siehe Datenmodell Abschnitt 9.6.

### E.7 Formular 7 — Auslandsmitteilung BZSt2 (nur Outbound)

1. Fall-ID — Text (Pflicht)
2. Mitteilungsjahr — Number (Pflicht); SharePoint-Zielspalte `notification_year` ist **Number** mit `Min=1000`/`Max=9999`/`Decimals=0` (Entscheid 28.10.2026, siehe Changelog unten — revidiert die ursprüngliche Text-Entscheidung aus der ersten Prüfung, da die Zielsite das Feld bereits als Number angelegt hatte und Formular 6/E.7 Frage 2 in Forms ohnehin als Zahlenfrage 1000–9999 gebaut ist)
3. Sachverhalt — Choice: Betriebe/Betriebsstätten / PersG-Beteiligung / KapG-Beteiligung / Drittstaat-Beherrschung / Negativmeldung (Pflicht)
4. Steuer-/Identifikationsnummer — Text (Pflicht)
5. Typ der Auslandseinheit — Choice: Betriebsstätte / Betrieb / Personengesellschaft / Kapitalgesellschaft / Vermögensmasse
   - Branching: nur bei Frage 3 ≠ Negativmeldung
6. Firmenname / Rechtsform — Text
   - Branching: wie 5
7. Adresse / Staat — Text lang
   - Branching: wie 5
8. Gründungsdatum — Date
   - Branching: wie 5
9. Tätigkeitskennzahl (1–13) — Choice (1–13 gemäss Fussnote 10)
   - Branching: wie 5; bei Auswahl „13 Sonstiges“ Pflichtfeld „Erläuterung“ einblenden (Frage 10)
10. Erläuterung zu „Sonstiges“ — Text
    - Branching: nur bei Frage 9 = „13 Sonstiges“ (SharePoint-Spalte `activity_code_explanation`)
11. Nominalkapital / Kapital — Number
    - Branching: wie 5
12. Im Inland steuerlich erfasst — Choice Ja/Nein
13. Beteiligte – Name / Anteil in % — Text lang (mehrzeilig, da i. d. R. mehrere Beteiligte; SharePoint-Spalte `participant_name_share` ist vom Typ „Mehrzeiliger Text“)
    - Branching: nur bei Frage 3 = PersG-Beteiligung oder KapG-Beteiligung
14. Beteiligt seit dem — Date
    - Branching: wie 13
15. Drittstaat-Beherrschung — Choice Ja/Nein
    - Branching: nur bei Frage 3 = Drittstaat-Beherrschung
16. Mitwirkung Steuerberatung — Choice Ja/Nein

### E.8 Formular 8 — Unterlagen (immer, bedingt)

1. Fall-ID — Text (Pflicht)
2. Dokumenttyp — Choice: Gesellschaftsvertrag / Vollmacht Steuerberatung / Empfangsvollmacht / SEPA-Mandat / Handelsregisterauszug / Sachgründungsbericht / Ansässigkeitsbescheinigung / Sonstiges (Pflicht)
3. Bezug zu Objekt — Text (Fall/Person/Beteiligung/Betriebsstätte-Kennung, da Forms kein Live-Lookup unterstützt; SharePoint-Zielspalte `related_object_text` — die eigentlichen Lookup-Spalten `related_case`/`related_person`/`related_participation`/`related_site` werden erst danach manuell oder durch einen erweiterten Flow aus diesem Freitext aufgelöst)
4. Datei — File Upload (Pflicht)
5. Hinweis — Text lang

Nicht als Forms-Frage, sondern durch Flow/manuell befüllt: `required`/`uploaded` (interne Kanzlei-Flags, Default „Nein“, keine Forms-Pflichtfelder mehr) sowie `file_link` (Hyperlink-Spalte für den Fall, dass eine Datei nicht über Forms, sondern über einen separaten Kanzlei-Upload-Weg eingesammelt wird, siehe Alternative (a) unten).

**Hinweis Datei-Upload:** Der Forms-Fragetyp „Datei hochladen“ verlangt vom Antwortenden zwingend die Anmeldung mit einem Microsoft-Konto (auch bei „Jeder mit dem Link kann antworten“). Externe Mandanten ohne Microsoft-Konto können daher Formular 8 nicht direkt nutzen — Alternativen: (a) Dateien per E-Mail/Kanzlei-Upload-Link separat einsammeln, den Link in `file_link` hinterlegen und Formular 8 nur für die Metadaten (Dokumenttyp, Hinweis) nutzen, oder (b) Formular 8 ausschliesslich für angemeldete Mandanten mit Microsoft-/Gastkonto vorsehen.

### E.9 Routing (Formular 0 → Folgeformulare)

Formularende von Formular 0 als Textblock mit bedingten Linklisten (Forms selbst kann kein formularübergreifendes Routing):

| Formulartyp | Pflicht-Folgeformulare |
|---|---|
| Einzelunternehmen | 1, 2, 3 (falls Vertretung/Empfangsbevollmächtigter), 6, 8 |
| Kapitalgesellschaft oder Genossenschaft | 1, 2, 3, 4, 5 (falls Betriebsstätten), 6, 8 |
| Personengesellschaft oder -gemeinschaft | 1, 2, 3 (falls Vertretung), 4, 5 (falls Betriebsstätten), 6, 8 |
| Körperschaft nach ausländischem Recht | 1, 3, 5, 8 |
| BZSt2-Mitteilung | 1, 4 (falls Beteiligungssachverhalt), 7, 8 |

**Bewusst ausgeschlossen (Kanzleientscheid 26.10.2026, siehe Datenmodell Abschnitt 9.1 Status `X`):** Verein/Stiftung/sonstige Körperschaft privaten Rechts sowie juristische Person des öffentlichen Rechts/Betrieb gewerblicher Art sind praktisch ohne Relevanz für die Kanzleipraxis. Es gibt deshalb **bewusst keinen** zusätzlichen `form_type`-Wert und **kein** zusätzliches Formular/keine zusätzliche Liste dafür — keine offene Frage mehr, sondern eine endgültige Entscheidung. Sollte doch einmal ein solcher Fall auftreten, läuft er ausschliesslich über `0_Fallsteuerung.processing_note` (Freitext) und manuelle Bearbeitung ausserhalb der Formularfamilie.

**Manueller Prüfschritt (Kanzleientscheid 26.10.2026, siehe Datenmodell Abschnitt 9.1 Status `M`):** Bei ausländischen Partnerships, LLPs, LLCs oder hybriden Rechtsformen entscheidet die Kanzlei den Rechtstypenvergleich und die steuerliche Einordnung **manuell**, bevor Formular 0 ausgefüllt wird — dafür gibt es bewusst keine Automatisierung in Formularen oder Listen. Je nach Ergebnis des manuellen Vergleichs wird der Fall anschliessend ganz regulär als „Personengesellschaft oder -gemeinschaft“ oder als „Körperschaft nach ausländischem Recht“ in Formular 0 erfasst.

### E.10 Prüfregeln für Power-Automate-Flows (bedingte Pflichtfelder, die Forms nicht abbilden kann)

Die meisten in Datenmodell Abschnitt 9.6 gelisteten bedingten Pflichtfelder (Update 2, ELSTER-Portalprüfung 26.10.2026) lassen sich über reguläres Forms-Branching abbilden (siehe Fragen 25-42 in E.2 und 19-33 in E.6 oben). Zwei Bedingungen kann Forms grundsätzlich nicht abbilden und müssen stattdessen als Prüfregel im jeweiligen Power-Automate-Flow (Formular-Antwort → Element erstellen) umgesetzt werden:

1. **Steuernummer/Land bei anderem Finanzamt** (Formular 1, Fragen 23/24 „Art der Steuernummer-Angabe“/„Steuernummer“ in Kombination mit Formular 1 Frage 34 „Zustimmung § 27 AO“ **und** Formular 0 Frage 3 „Bereits steuerlich erfasst“): Die Bedingung verknüpft ein Feld aus Formular 0 mit einem Feld aus Formular 1 — Forms-Branching wirkt nur innerhalb eines Formulars, nicht formularübergreifend. **Prüfregel:** Der Flow, der Formular-1-Antworten nach `1_Allgemeiner_Stammblock` überträgt, soll vor dem „Element erstellen“-Schritt per „Element abrufen“ aus `0_Fallsteuerung` prüfen, ob `par27_ao_agreement` = Ja **und** `already_registered` = Ja gilt; ist dann `existing_tax_number` oder `tax_office_country` leer, Element stattdessen in `Eingang_Fehler` anlegen (`form_no` = 1, `reason` = „Steuernummer/Land bei anderem Finanzamt fehlt trotz § 27 AO-Zustimmung“, `payload` = Rohantwort) statt den unvollständigen Datensatz kommentarlos zu übernehmen.
2. **BIC nur bei bestimmten IBAN-Ländern** (Formular 1, Frage 30 „Bank – BIC“): Forms kann den Inhalt eines Textfelds nicht inspizieren, um eine Frage bedingt einzublenden. **Prüfregel:** Der Flow soll nach Übertragung prüfen, ob `bank_iban` mit einem der Länderpräfixe `AL`, `MD`, `MC`, `ME`, `MK`, `SM`, `CH` beginnt; falls ja und `bank_bic` leer ist, Element in `Eingang_Fehler` anlegen (`form_no` = 1, `reason` = „BIC fehlt bei nicht-SEPA-IBAN“) statt nur die bestehende Hinweistext-Lösung in Frage 30 zu verlassen.

Beide Prüfregeln ersetzen **nicht** die reguläre Übertragung — sie laufen zusätzlich, bevor bzw. nachdem der Flow das Element in der Zielliste anlegt, und dienen ausschliesslich dazu, unvollständige Fälle sichtbar zu machen statt sie unbemerkt zu übernehmen.

## F. Freigabe und Rollout

1. Je Formular unter „…“ → Einstellungen → „Wer kann antworten“ → **„Jeder mit dem Link kann antworten“** aktivieren (Ausnahme Formular 8 bei Datei-Upload, siehe Hinweis oben).
2. Formular 0 als Startpunkt verlinken/einbetten (E-Mail an Mandant oder Einbettung auf einer Kanzlei-Landingpage). Der fallanlegende Flow setzt dabei `access_code` (Abschnitt D1) und baut die vorausgefüllten Links zu den Formularen 1-8 mit `case_id` **und** `access_code` auf.
3. Optional: Power-Automate-Flow „Bei neuer Microsoft-Forms-Antwort → Element in SharePoint-Liste erstellen“ je Formular/Liste-Paar, inkl. Zuordnung `case_id`/Lookup. Jeder dieser Flows sollte vor dem „Element erstellen“-Schritt `case_id` + `access_code` gegen `0_Fallsteuerung` prüfen und bei Fehlschlag stattdessen ein Element in `Eingang_Fehler` anlegen (Abschnitt D1), statt die Antwort kommentarlos zu verwerfen.
4. Testdurchlauf mit Dummy-Fall über den externen Link vor Versand an echte Mandanten: prüfen, ob alle Branching-Regeln (Abschnitt E) korrekt greifen und ob die Antworten korrekt in die zugehörige SharePoint-Liste geschrieben werden.
5. `Eingang_Fehler` regelmässig sichten (z. B. wöchentlich), um fehlgeschlagene Formular-Übernahmen zeitnah manuell nachzubearbeiten.

## G. Offene Punkte

- Schreibzugriff des Microsoft_365-Konnektors (`Sites.ReadWrite.All`, delegiert) fehlt noch — siehe Abschnitt A.
- Fall-ID-Vergabe (Abschnitt D) ist bis zur Power-Automate-Automatisierung manuell; ein künftiger Auto-Nummerierungs-Flow muss `case_id` vor der Elementanlage berechnen (siehe Abschnitt D, da `case_id` Pflicht **und** eindeutig ist).
- Datei-Upload in Formular 8 erfordert Anmeldung — Alternativlösung mit dem Mandat abstimmen (Abschnitt E.8).
- **Nicht vollständig getestete bedingte Pfade (Update 2):** Die ELSTER-Portalprüfung 26.10.2026 hat 23 (Auslandskörperschaft) bzw. 27 (Kapitalgesellschaft/Genossenschaft) bedingte Auslöser ermittelt und in Datenmodell Abschnitt 9.6 dokumentiert — damit ist der vormals offene Punkt „bedingte Pflichtfelder“ weitestgehend geschlossen. Laut den Quelldateien selbst blieben einige Pfade ungetestet (u. a. Auslandskörperschaft: Betriebsstätte Ausland/nicht fest, unabhängige Person, Bauausführung; Kapitalgesellschaft: nicht natürlicher Vertreter, Notar-Staat/Register-Optionen einzeln, USt-IdNr.-Grund Option 2/3) — siehe Datenmodell Abschnitt 9.6 für die vollständige Liste.
- **`case_id`/`access_code` bei bereits produktiv genutzten Listen:** Falls das Skript gegen eine Site läuft, auf der `0_Fallsteuerung` bereits Datensätze enthält, kann „eindeutige Werte erzwingen“ fehlschlagen, falls Altdaten doppelte oder leere `case_id`-Werte enthalten; das Skript warnt in diesem Fall nur, behebt die Duplikate aber nicht automatisch (siehe Abschnitt C).
- **Erneuter Nachlauf nach dem Prüflauf 27./28.10.2026 nötig:** `Test-SteuerlicheErfassungListen.ps1` fand 21 Abweichungen bei 272 Prüfungen (Lookups/Restrict/Unique/Auswahlwerte waren bereits in Ordnung — siehe Abschnitt C2, zweiter Fallen-Block, für die Einzelheiten der neu behobenen Fehler). Die Kanzlei löscht die entstandenen Duplikate (Namensfalle) sowie `participant_name_share` (Typabweichung) selbst direkt auf der Site; danach das korrigierte Skript einmal erneut laufen lassen (Angleichungsmodus, nichts geht verloren) und mit `Test-SteuerlicheErfassungListen.ps1` verifizieren, dass `ERGEBNIS: OK` gemeldet wird.

**Keine offenen Punkte mehr (per 26.10.2026 entschieden/verifiziert):**

- Verein/Stiftung/sonstige Körperschaft privaten Rechts sowie juristische Person des öffentlichen Rechts/Betrieb gewerblicher Art: Kanzleientscheid — bewusst ausgeschlossen, praktisch ohne Relevanz (Datenmodell 9.1 Status `X`, siehe Abschnitt E.9 oben).
- Ausländische Partnerships/LLPs/LLCs/hybride Rechtsformen: Kanzleientscheid — Rechtstypenvergleich ist ein definierter manueller Prüfschritt der Kanzlei vor Formular 0, keine Automatisierung vorgesehen (Datenmodell 9.1 Status `M`, siehe Abschnitt E.9 oben).
- KapG-Kz 179 (Umsatzschätzung Eröffnungs- **und** Folgejahr): durch ELSTER-Portalprüfung 26.10.2026 (verification_date 2026-10-26) als unbedingtes Pflichtfeld bestätigt; beide Felder (`estimated_revenue_opening_year`, `estimated_revenue_following_year` in Liste 6) sind bereits `-Required`, kein Skriptänderungsbedarf.
- Bedingte Pflichtfelder (Update 2): 50 Auslöser (23 Auslandskörperschaft + 27 Kapitalgesellschaft/Genossenschaft) durch ELSTER-Portalprüfung 26.10.2026 ermittelt, in Datenmodell Abschnitt 9.6 dokumentiert und als 33 neue, nicht `-Required` gesetzte Spalten in `New-SteuerlicheErfassungListen.ps1` (Liste 2 und Liste 6) sowie als Forms-Fragen mit Branching (E.2 Fragen 25-42, E.6 Fragen 19-33) bzw. Power-Automate-Prüfregeln (E.10) nachgezogen. Residuale, laut Quelldateien nicht getestete Einzelpfade bleiben als kleinerer offener Punkt oben stehen.
- Formular 2 Frage 32 (Update 3): Kanzleientscheid Nils 27.10.2026 — Feld wird geführt als „Bezeichnung des überlassenen Wirtschaftsguts (wesentliche Betriebsgrundlage)“, der Wortlaut ist Kanzleientscheid und **nicht** im ELSTER-Portal verifiziert. Der interne Spaltenname war damals unverändert geblieben, wurde aber am 28.10.2026 aus einem anderen Grund (32-Zeichen-Grenze) von `split_ownership_asset_description` auf `split_owner_asset_description` umbenannt — siehe Changelog-Tabelle unten.
- Interne Feldnamen über 32 Zeichen (28.10.2026): alle 6 betroffenen Felder umbenannt, harte Namensregel-Prüfung in beiden Skripten ergänzt (siehe Abschnitt C2 „Interne Feldnamen über 32 Zeichen“, Changelog-Tabelle unten).
- `DisplayFormat` bei bestehenden Datumsfeldern (28.10.2026): `Set-DateOnlyFormat` zieht `DisplayFormat=DateOnly` jetzt auch bei bereits vorhandenen Feldern nach (siehe Abschnitt C2 „`DisplayFormat` bei bereits bestehenden Datumsfeldern“).
- `notification_year` Number statt Text (28.10.2026, Entscheid revidiert): Skript jetzt `Number` mit `Min=1000`/`Max=9999`/`Decimals=0`, passend zur bereits produktiven Zielsite und zur bestehenden Forms-Frage (siehe Abschnitt C2 „Typabweichungen werden jetzt klar gewarnt“, Changelog-Tabelle unten).

## H. Changelog: interne Feldnamen (alt → neu)

**Wichtig für den Power-Automate-Flow-Bauplan:** Jeder Flow, der eine Formular-Antwort auf eine dieser Spalten mappt (per internem Feldnamen, z. B. in einer „Element erstellen“-Aktion), muss beim nächsten Bearbeiten auf den neuen Namen umgestellt werden. Die sechs Felder wurden am 28.10.2026 umbenannt, weil ihr bisheriger interner Name über 32 Zeichen lang war und SharePoint ihn stillschweigend kürzte (siehe Abschnitt C2 „Interne Feldnamen über 32 Zeichen“) — Anzeigename, Bedeutung und Pflichtstatus der Felder bleiben unverändert, nur der interne Name ändert sich.

| Liste | Alter interner Name (> 32 Zeichen) | Neuer interner Name | Anzeigename |
|---|---|---|---|
| `2_Unternehmens_Gruendungsmodul` | `is_controlling_company_for_tax_group` (36) | `is_tax_group_parent` (20) | Organtraegerschaft |
| `2_Unternehmens_Gruendungsmodul` | `split_ownership_address_or_tax_number` (37) | `split_owner_address_or_taxno` (28) | Anschrift und/oder Steuernummer des Besitzunternehmens |
| `2_Unternehmens_Gruendungsmodul` | `split_ownership_asset_description` (33) | `split_owner_asset_description` (29) | Bezeichnung des überlassenen Wirtschaftsguts (wesentliche Betriebsgrundlage, Betriebsaufspaltung) |
| `4_Beteiligte_und_Quoten` | `expected_profit_share_opening_year` (34) | `profit_share_opening_year` (25) | Voraussichtlicher Gewinnanteil Eröffnungsjahr |
| `4_Beteiligte_und_Quoten` | `expected_profit_share_following_year` (36) | `profit_share_following_year` (27) | Voraussichtlicher Gewinnanteil Folgejahr |
| `6_Steuer_und_Umsatzsteuerprofil` | `exemption_certificate_construction` (34) | `exemption_cert_48b_construction` (31) | Freistellungsbescheinigung § 48b EStG |

**Vorgehen auf der Zielsite:** Die durch den Namenskürzungsfehler entstandenen Duplikate (mit Zahlen-Suffix `_0`…`_4`) wurden von der Kanzlei direkt auf der Site gelöscht (die betroffenen Listen waren leer). Das korrigierte Skript legt die Spalten beim nächsten Lauf unter dem neuen, kurzen Namen neu an — dieselbe Spalte, nur mit dem jetzt korrekten internen Namen; es handelt sich **nicht** um eine automatische Umbenennung einer bereits produktiv befüllten Spalte (SharePoint unterstützt das Umbenennen des internen Namens ohnehin nicht nachträglich).
