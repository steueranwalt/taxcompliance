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

**SharePoint kennt keine bedingten Pflichtfelder.** Die Spalte „Erforderlich“ wird deshalb nur bei *unbedingten* Pflichtfeldern gesetzt (`-Required`). Alle mit „Bedingt“ markierten Felder bleiben in SharePoint optional; die Pflichtlogik wird ausschliesslich über Forms-Branching (Abschnitt E) durchgesetzt. Das gilt jetzt auch für `legal_capacity` (Rechtsfähigkeit, nur Personengesellschaft) und `par27_ao_agreement` (§ 27 AO, nur Körperschaft ausländischen Rechts, seit 28.10.2026 Kanzleifeld in `0_Fallsteuerung`, siehe Abschnitt H2).

**`Title` ist überall optional.** Die SharePoint-Standardvorlage macht die Spalte „Title“ in jeder neuen Liste zur Pflicht; die Forms-Flows befüllen „Title“ aber nicht zwangsläufig (die fachliche Kennung je Liste ist eine eigene Spalte, z. B. `case_id`, `last_name_or_company`, `site_name`). Das Skript schaltet „Title“ in jeder Liste auf optional. Empfehlung für die Power-Automate-Flows: „Title“ trotzdem mit einem sprechenden Wert befüllen (z. B. `case_id` + Name/Dokumenttyp), damit SharePoint-Standardansichten lesbar bleiben.

**Datumsfelder sind reine Datumsfelder (`DateOnly`), keine Datum-mit-Uhrzeit-Felder.** Geburtsdatum, Gründungsdatum, Tätigkeitsbeginn/-ende usw. benötigen keine Uhrzeitkomponente; alle entsprechenden Spalten sind mit `Format='DateOnly'` angelegt.

**Ja/Nein-Fragen sind SharePoint-Boolean-Spalten — ausser bei einem bekannten SharePoint-Fehlverhalten.** Jede als „Choice Ja/Nein“ in Abschnitt E bezeichnete Forms-Frage entspricht normalerweise einer SharePoint-Spalte vom Typ `Boolean` (z. B. `small_business_rule`, `works_elsewhere`). Der Flow muss die beiden Forms-Antwortoptionen „Ja“/„Nein“ auf `true`/`false` abbilden (Power Automate macht das bei einer 2-Options-Auswahl i. d. R. automatisch über den Textvergleich; bei Abweichungen einen Ausdruck wie `equals(outputs('...'), 'Ja')` verwenden). **Ausnahme (Befund Nils 28.10.2026):** Ist ein Boolean-Feld zusätzlich `-Required`, lässt es sich im nativen SharePoint-Formular effektiv nur mit „Ja“ sauber speichern (Checkbox-Pflicht-Verhalten). Betroffene Felder wurden deshalb auf ein **Choice**-Feld mit den Werten „Ja“/„Nein“ (ggf. plus „Unbekannt“) umgestellt, siehe `registration_status` und `trust_relationship_status` in Abschnitt H2. Für **neue** Pflicht-Ja/Nein-Felder deshalb immer Choice statt Boolean verwenden.

**Auswahlwerte (Choice-Optionen) sind immer mit Umlauten geschrieben** (z. B. „Körperschaft nach ausländischem Recht“, „Ständiger Vertreter“, „Treuhänder“, „römisch-katholisch“), identisch zwischen diesem README und dem Skript. Bei einer bereits laufenden Installation ergänzt das Skript fehlende (umlauthaltige) Auswahlwerte, entfernt aber etwaige ältere, nicht-umlauthaltige Varianten nicht automatisch (siehe Angleichungshinweis oben) — nach einem ersten produktiven Lauf ggf. manuell bereinigen, sobald sicher ist, dass keine Altdaten mehr die alte Schreibweise verwenden. **Schreibvarianten-Dubletten (Befund Nils 28.10.2026):** Auf einer frisch angelegten Site fanden sich dennoch Dubletten (z. B. „UG“ und „UG (haftungsbeschränkt)“, eine Rechtsform einmal mit Umlaut und einmal als „ae“-Variante) — verursacht durch mehrere nacheinander gegen dieselbe Site gelaufene historische Skriptversionen. `New-SteuerlicheErfassungListen.ps1` prüft deshalb vor jeder Verbindung statisch jede einzelne `-Choices`-Liste auf Schreibvarianten (`Test-ChoiceValueDuplicates`), und `Test-SteuerlicheErfassungListen.ps1` prüft zusätzlich die tatsächlichen Auswahlwerte auf der Zielsite (Prüfung „Auswahlwerte ohne Schreibvariante-Dubletten“) — siehe Abschnitt C2.

`created_by`/`created_at` (Liste 0) werden nicht als Zusatzspalten angelegt, sondern über die SharePoint-Systemfelder `Author`/`Created` abgebildet.

`related_object` (Liste 8) ist in SharePoint kein Multi-Listen-Lookup — ersatzweise vier Einzel-Lookups: `related_case`, `related_person`, `related_participation`, `related_site`. Da Forms selbst keinen Lookup kennt, nimmt die Forms-Frage „Bezug zu Objekt“ die Antwort stattdessen als Freitext in der Spalte `related_object_text` auf; die Auflösung auf die konkrete Lookup-Zeile erfolgt danach manuell oder über einen erweiterten Flow.

Die Lookup-Anzeigefelder (`ShowField`) für `related_person`, `related_participation` und `related_site` sind jeweils `display_label` (neue Textspalte in Liste 3/4/5), nicht `last_name_or_company`/`site_name` — letztere sind bei Namensgleichheit nicht eindeutig. Ein Flow sollte `display_label` unmittelbar nach Elementanlage befüllen, z. B. `"<Name> (<Rolle>, Fall <case_id>, ID <ID>)"`.

**`-HideFromForms` blendet Flow-generierte Felder im nativen SharePoint-Formular aus.** Felder, die nie von Hand, sondern ausschliesslich von einem Flow gesetzt werden (aktuell `access_code`), werden im nativen SharePoint-Neu-/Bearbeiten-Formular (nicht zu verwechseln mit den Microsoft-Forms-Umfragen F0-F8!) ausgeblendet (`ShowInNewForm`/`ShowInEditForm` = `FALSE`), bleiben aber in der Anzeige (DisplayForm) sichtbar, damit die Kanzlei den Wert bei Bedarf nachschlagen kann.

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

**Am 27./28.10.2026 auf einer FRISCHEN, leeren Site (`transferpricingdocs.sharepoint.com/sites/steuerdaten`) zusätzlich gefundene Fallen (die auf einer bereits bestehenden Site nicht auffielen, siehe Abschnitt A2/G):**

1. **Lookup mit `RelationshipDeleteBehavior` braucht einen Index bereits bei der Erstanlage, nicht erst bei einer späteren Angleichung:** `Add-PnPFieldFromXml` brach auf der frischen Site beim Anlegen eines neuen Lookup-Felds mit `Restrict` ab: „Dieses Nachschlagefeld kann kein Verhalten für Beziehungen erzwingen, weil es nicht indiziert ist.“ Auf `obenhaus` fiel das nicht auf, weil die Lookups dort aus einem früheren Lauf bereits vorhanden und indiziert waren — das Skript lief dort nur noch durch die Angleichung (`Set-LookupDeleteBehavior`, die bereits zuerst indiziert). Fix: `Indexed='TRUE'` wird jetzt im Erstellungs-XML gesetzt, sobald `DeleteBehavior != "None"` — idempotent für frische **und** bestehende Sites.
2. **Required-Boolean-Felder lassen sich im nativen SharePoint-Formular effektiv nur mit „Ja“ speichern:** `already_registered` (Pflicht, Boolean) liess sich beim Testdurchlauf auf der frischen Site nicht sauber mit „Nein“ ausfüllen — SharePoints Checkbox-Darstellung für ein Pflicht-Ja/Nein-Feld erzwingt praktisch den angehakten Zustand. Dasselbe Muster wurde bei `trust_relationship` gefunden. Fix: beide Felder durch ein **Choice**-Feld mit „Ja“/„Nein“ (ggf. zusätzlich „Unbekannt“) ersetzt — `registration_status`/`trust_relationship_status`, siehe Abschnitt H2. Eine Typänderung (`Boolean` → `Choice`) ist laut Punkt 3 oben nie automatisch möglich; die alten Spalten werden von diesem Skript nicht mehr angelegt/angeglichen und müssen auf Bestandssites manuell gelöscht werden (siehe Abschnitt H2 für den Entscheidungsstand je Feld).
3. **Schreibvarianten-Dubletten in Auswahlwerten:** auf der frischen Site fanden sich Dubletten wie „UG“/„UG (haftungsbeschränkt)“ nebeneinander sowie eine Rechtsform einmal mit Umlaut, einmal als „ae“-Schreibweise — verursacht durch mehrere, nacheinander gegen dieselbe Site gelaufene historische Skriptversionen (die nicht-destruktive Angleichung ergänzt Auswahlwerte nur, entfernt nie). Fix: `New-SteuerlicheErfassungListen.ps1` prüft vor jeder Verbindung statisch jede `-Choices`-Liste auf Schreibvarianten (`Get-NormalizedChoiceKey`/`Test-ChoiceValueDuplicates`, Normalisierung über ä/ö/ü/ß ↔ ae/oe/ue/ss und Gross-/Kleinschreibung) und bricht bei einem Fund ab; `Test-SteuerlicheErfassungListen.ps1` prüft zusätzlich die tatsächlichen Auswahlwerte auf der Zielsite (Prüfung „Auswahlwerte ohne Schreibvariante-Dubletten“), da nur dort die über mehrere Läufe akkumulierten Altlasten sichtbar sind.
4. **Required-Ergebnisfelder, gefunden vom parallelen Erfassungs-Chat-Generator (28.10.2026, PR #22, `DE/AO/erfassungs-chat/generator/output/required_ergebnis_konflikte.json`):** `formation_type` (Liste 2) und `site_type` (Liste 5) waren weiterhin `-Required`, obwohl beide nach der Grundregel Ergebnisfelder sind (Gründungsart inkl. Bar-/Sachgründung bzw. „feste/nicht feste Einrichtung“ nach § 12 AO sind selbst die rechtliche Einordnung, keine Mandanten-Tatsache). `tax_office` und `profit_determination_method` aus demselben Befund waren zu diesem Zeitpunkt bereits durch die Grundregel-Arbeit in diesem Skript behoben. Fix: beide Felder nicht mehr `-Required`, als Kanzleifeld gekennzeichnet (`-FieldRole "Ergebnis"`, siehe Abschnitt C3), neue Tatsachenfelder ergänzt (`capital_contribution_type`, `transformation_event`/`transformation_details` in Liste 2; `own_disposal_power` in Liste 5). Zusätzlich jetzt eine harte Invariante in `Add-Field`: ein `-Required`-Feld mit `-FieldRole "Ergebnis"` oder `"System"` (ausser `Type Lookup`, siehe `case_id`) löst sofort einen Fehler aus, damit dieses Muster nicht erneut unbemerkt entsteht.

### C3. Feld-Metadaten für externe Generatoren (`-FieldRole`/`-AppliesTo`)

Ergänzung zum parallelen PR #22 (`DE/AO/erfassungs-chat/`, Branch `cursor/erfassungs-chat-prototyp-8be4`): dessen Generator leitet aus diesem Skript ein JSON-Schema für einen Mandanten-Chat ab und muss dafür wissen, welche Felder er dem Mandanten überhaupt stellen darf (Grundregel: nur Tatsachen, nie eine Würdigung). Bis dahin pflegte der Generator eine von Hand erstellte, 169 Felder umfassende Übergangstabelle (`generator/classification_config.json`). `Add-Field` unterstützt deshalb jetzt zwei rein informative, **optionale** Parameter, die nie auf die SharePoint-Spalte selbst wirken (keine XML-/CSOM-Änderung), sondern ausschliesslich von einem Generator per Text-/AST-Parse dieses Skripts gelesen werden:

| Parameter | Werte | Standard, wenn weggelassen | Bedeutung |
|---|---|---|---|
| `-FieldRole` | `"Tatsache"` / `"Ergebnis"` / `"System"` | `"Tatsache"` | `Tatsache`: darf ein Generator/Chat erfragen. `Ergebnis`: rechtliche/steuerliche Würdigung oder Prognose der Kanzlei — nie erfragen, bleibt für die Kanzlei leer. `System`: kein fachlicher Inhalt, entweder (a) technisches/internes Feld (Lookup-Anzeigefeld, Flow-Flag, `Title` o. ä.) oder (b) Kontaktdaten, die im CRM der Kanzlei gepflegt werden (siehe Abschnitt C, „Ja/Nein-Fragen“-Hinweis zu CRM-Feldern). |
| `-AppliesTo` | `@("Alle")` / `@("Gesellschaft")` / `@("NatuerlichePerson")` | `@("Alle")` | Zweig, für den das Feld gilt — analog zum Branching in Abschnitt E (z. B. `party_type`/`person_type` = Firma/Person). `Alle` heisst: gilt unabhängig vom Zweig. |

**Nicht jedes Feld muss explizit getaggt werden** — nur die Ausnahmen von den beiden Standardwerten. Ein Feld ohne `-FieldRole` ist implizit `Tatsache`, ein Feld ohne `-AppliesTo` gilt implizit für `Alle`. Das hält das Skript lesbar (die grosse Mehrheit der ca. 236 Felder sind einfache, zweigunabhängige Tatsachenfelder) und ist bewusst identisch mit der Konvention, die der Generator bereits erwartet (siehe dortiger Modulkommentar `generator/field_classification.py`, Abschnitt „Erwartetes Metadaten-Format“).

**Harte Invariante:** `Add-Field` bricht sofort ab, wenn ein Feld `-Required` **und** `-FieldRole "Ergebnis"` oder `"System"` gesetzt hat (Ausnahme `Type Lookup`, z. B. `case_id` — ein technischer Fremdschlüssel wird vom Flow/der Session gesetzt, nie von einem Menschen über ein Pflicht-Formularfeld beantwortet). Das verhindert strukturell das genaue Muster, das der Erfassungs-Chat-Generator am 28.10.2026 für vier Felder meldete (siehe Punkt 4 oben) — `Test-SteuerlicheErfassungListen.ps1` prüft dieselbe Invariante zusätzlich statisch auf den Soll-Definitionen, bevor es sich verbindet.

**Vollständig getaggt sind** (Stand dieses Commits) die sieben vom Erfassungs-Chat genutzten Listen (`1_Allgemeiner_Stammblock`, `2_Unternehmens_Gruendungsmodul`, `3_Personen_und_Vertretung`, `4_Beteiligte_und_Quoten`, `5_Betriebsstaetten`, `6_Steuer_und_Umsatzsteuerprofil`, `8_Unterlagen`) — die Klassifizierung dort wurde direkt aus der bereits vorhandenen, ausführlich begründeten `classification_config.json` des parallelen PRs übernommen (für umbenannte/restrukturierte Felder dieser Runde, z. B. `legal_form_category` statt `legal_form`, sinngemäss neu zugeordnet). `0_Fallsteuerung` (kanzleiintern, nie Teil des Mandanten-Chats), `7_Auslandsmitteilung_BZSt2` (Outbound-spezifisch) sowie die beiden internen Referenzlisten `Technische_Mindestfelder`/`Eingang_Fehler` sind bewusst nicht getaggt, da sie ausserhalb des heutigen Chat-Scopes liegen (siehe `generator/cli.py`, `CHAT_LISTS`).

**Sobald PR #22 gemerged ist:** der Generator muss nur noch `MetadataClassificationProvider._read_metadata_role`/`_read_metadata_applies_to` in `field_classification.py` an diese beiden Attribute anpassen (die Kandidatennamen `field_role`/`applies_to` sind dort bereits exakt für dieses Format vorgesehen) sowie `pnp_schema_parser.py`s `FieldDef`/`_parse_add_field_block` um `field_role`/`applies_to` erweitern, damit der Text-Parser die beiden neuen `-FieldRole`/`-AppliesTo`-Parameter durchreicht (aktuell liest er zwar jeden `-ParamName`-Token, gibt aber nur die acht fest benannten `FieldDef`-Attribute weiter). `classification_config.json` bleibt als dauerhaftes Fallback für die beiden internen Listen bzw. für den Übergang bestehen — das ist bewusst so vorbereitet (siehe `CompositeClassificationProvider` dort).

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

Nur intern (Kanzlei), nicht an Mandanten versendet — dient der Fallanlage. Diese Liste ist die interne Steuerliste der Kanzlei und wird **nicht** vom Mandanten befüllt; „Formular 0“ ist deshalb strenggenommen kein Mandanten-Forms, sondern die direkte Dateneingabe durch die Kanzlei in `0_Fallsteuerung` (die Fragenliste hier dient nur der Vollständigkeit/Konsistenz mit den übrigen Abschnitten).

1. Richtung — Choice: „Ausländische Gesellschaft mit Bezug zu Deutschland (Inbound)“ / „Deutsche Gesellschaft/Person mit Auslandsbezug (Outbound)“ (Pflicht) — Wortlaut geändert 28.10.2026 (Review Nils), siehe Abschnitt H2 (**Breaking Change** für bestehende Flow-Bedingungen auf den alten Wortlaut)
2. Rechtsform / Formulartyp — Choice: Einzelunternehmen / Kapitalgesellschaft oder Genossenschaft / Personengesellschaft oder -gemeinschaft / Körperschaft nach ausländischem Recht / BZSt2-Mitteilung (Pflicht)
3. Bereits steuerlich erfasst — Choice: Ja / Nein / Unbekannt (nicht mehr Pflicht, seit 28.10.2026 `registration_status` statt `already_registered`, siehe Abschnitt H2 — ein Pflicht-Ja/Nein-Feld liess sich in SharePoint nur mit „Ja“ sauber speichern)
4. Bestehende Steuernummer — Text
   - **Branching:** nur einblenden, wenn Frage 3 = Ja
5. Land des Finanzamts — Choice: Deutschland / Österreich / Schweiz / Liechtenstein / Frankreich / Italien / Spanien / Niederlande / Belgien / Luxemburg / Polen / Vereinigtes Königreich / Vereinigte Staaten / Sonstiger EU/EWR-Staat / Sonstiger Staat / Unbekannt (nicht mehr Pflicht, seit 28.10.2026 Choice statt Text; wird von der Kanzlei nach Prüfung ausgefüllt, Ergebnisfeld — siehe Abschnitt H2 und Datenmodell Abschnitt 10)
6. Zuständiges Finanzamt — Text (nicht mehr Pflicht, von der Kanzlei nach Prüfung ausgefüllt, Ergebnisfeld)
7. Zielmeldung (BZSt2-Sachverhalt) — Choice: Betriebe/Betriebsstätten / PersG-Beteiligung / KapG-Beteiligung / Drittstaat-Beherrschung / Negativmeldung (wird von der Kanzlei nach Prüfung der Angaben festgelegt)
   - **Branching:** nur einblenden, wenn Frage 1 = Outbound
8. Persönliche Bearbeitungsnotiz — Text (lang)

Nicht als Forms-Frage, sondern Kanzleifelder, von der Kanzlei direkt in `0_Fallsteuerung` gepflegt: `case_status`, `par27_ao_agreement` (seit 28.10.2026 von Formular 1 hierher verschoben, siehe Abschnitt H2 — Mandant soll keine Zustimmung zu einer Zuständigkeitsvereinbarung selbst einschätzen), `crm_reference` (Referenz auf den Mandanten im CRM der Kanzlei, ersetzt die bisherigen Einzel-Kontaktfelder in Formular 1).

Formularende: Textblock mit Link-Liste zu Formular 1 sowie den je nach Antwort passenden Folgeformularen (siehe Routing-Tabelle Abschnitt E.9).

**Hinweis `access_code`:** Keine Forms-Frage. Der die Fallanlage auslösende Flow setzt beim Anlegen des `0_Fallsteuerung`-Elements zusätzlich `access_code` (Zufallswert, siehe Abschnitt D1) und übergibt `case_id` + `access_code` gemeinsam in den vorausgefüllten Links zu den Formularen 1-8, damit spätere Flows beide Werte prüfen können, bevor sie eine Formularantwort einem Fall zuordnen. Seit 28.10.2026 ist `access_code` zusätzlich im nativen SharePoint-Neu-/Bearbeiten-Formular ausgeblendet (`-HideFromForms`, siehe Abschnitt C), damit niemand den Wert versehentlich von Hand überschreibt.

### E.1 Formular 1 — Allgemeiner Stammblock (immer)

**Grundlegend überarbeitet 28.10.2026 (Review Nils, Grundregel „Tatsachen statt rechtlicher Würdigung“, siehe Datenmodell Abschnitt 10):** entfernt wurden Dubletten zu `0_Fallsteuerung` (Finanzamt), CRM-Kontaktfelder der Kanzlei (Telefon, Rückfrage-E-Mail), zwei reine Kanzleifelder/vorerst gestrichene Felder (`par27_ao_agreement` → verschoben nach Formular 0 als Kanzleifeld, `sepa_desired` → vorerst ganz entfernt) sowie `deviating_management_place`/`management_address` (gehören fachlich zur Person, nicht zum Unternehmen — jetzt in Formular 3, Fragen „Übliche Tätigkeitsorte“). Neu strukturiert: Rechtsform (vorher ein Freitextfeld) und Vermögensverwaltung (vorher eine rechtliche Ja/Nein-Würdigung).

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
10. Rechtsform — Grundtyp — Choice: Einzelunternehmen (gewerblich) / Freiberufliche Tätigkeit / Personengesellschaft / Kapitalgesellschaft
    - Branching: nur bei Frage 2 = Firma (SharePoint-Spalte `legal_form_category`, ersetzt seit 28.10.2026 das bisherige Freitextfeld `legal_form`, siehe Abschnitt H2)
11. Rechtsform — nach deutschem oder ausländischem Recht — Choice: nach deutschem Recht / nach ausländischem Recht
    - Branching: wie 10 (`legal_form_jurisdiction`, **neu**)
12. Konkrete Rechtsform (deutsches Recht) — Choice: GmbH / UG (haftungsbeschränkt) / AG / e.K. / OHG / KG / GmbH & Co. KG / GbR / PartG / sonstige deutsche Rechtsform
    - Branching: nur bei Frage 11 = nach deutschem Recht (`legal_form_german`, **neu**)
13. Rechtsform nach ausländischem Recht (Wortlaut) — Text
    - Branching: nur bei Frage 11 = nach ausländischem Recht (`legal_form_foreign_name`, **neu**)
14. Staat der ausländischen Rechtsform — Text
    - Branching: wie 13 (`legal_form_foreign_country`, **neu**)
15. Adressart — Choice: Inland / Ausland (Pflicht)
16. Strasse, Hausnummer, Zusatz — Text (Pflicht)
17. Adressergänzung — Text
18. Postleitzahl, Ort — Text (Pflicht)
19. Staat — Text
    - Branching: nur bei Frage 15 = Ausland
20. Postfach — Text
21. Internetadresse — Text
22. Genaue Tätigkeit — Text lang (Pflicht)
23. Verwaltet Vermögen (Beteiligungen, Immobilien, Kapitalvermögen usw.) — Choice Ja/Nein
    - Branching: nur bei Frage 2 = Firma (`asset_management_present`, ersetzt seit 28.10.2026 die rechtliche Würdigung „Ausschliesslich vermögensverwaltend tätig“/`asset_management_only`, siehe Abschnitt H2)
24. Art der Vermögensverwaltung — Text lang
    - Branching: nur bei Frage 23 = Ja (`asset_management_type`, **neu**)
25. Anteil Vermögensverwaltung am Umsatz in Prozent — Number (0-100)
    - Branching: wie 24 (`asset_mgmt_share_revenue`, **neu**)
26. Anteil Vermögensverwaltung am Gewinn in Prozent — Number (0-100)
    - Branching: wie 24 (`asset_mgmt_share_profit`, **neu**)
27. Weitere Tätigkeiten — Text lang
    - Branching: nur bei Frage 2 = Firma (`other_business_activities`, **neu**; die Kanzlei leitet „ausschliesslich vermögensverwaltend tätig“ aus Fragen 23-27 ab, siehe Datenmodell Abschnitt 10 Ableitungstabelle)
28. Art der Steuernummer-Angabe — Choice: bestehend / neu beantragen (Pflicht)
29. Steuernummer — Text
    - Branching: nur bei Frage 28 = bestehend
30. Steuerliche Beratung – Name/Firma — Text
31. Steuerliche Beratung – Adresse — Text lang
32. Steuerliche Beratung ist empfangsbevollmächtigt — Choice Ja/Nein
33. Bank – IBAN — Text
34. Bank – BIC — Text
    - Branching: nur einblenden bzw. hervorheben, wenn IBAN nicht mit DE beginnt (Forms kann Textinhalt nicht prüfen — Hinweistext „Pflicht bei ausländischem Institut“ in die Frage aufnehmen, keine harte Verzweigung möglich)
35. Bank – Kontoinhaber — Text
36. Ausländische Steuer-ID / TIN — Text
    - Branching: nur bei Frage 2 = Firma (`foreign_tax_id`, **neu**, Review Nils 28.10.2026: bislang fehlende Firmenangabe, Cross-Check gegen Formular 2 ergab keine Dublette)
37. Bestehende USt-IdNr. — Text
    - Branching: wie 36 (`vat_id_existing`, **neu**)

**Entfernt (28.10.2026, siehe Abschnitt H2 für Details je Feld):** „Zuständiges Finanzamt“ (Dublette zu Formular 0), „Telefon“/„Rückfrage-E-Mail“ (CRM-Kontaktdaten der Kanzlei, ersetzt durch `crm_reference` in Formular 0), „SEPA-Lastschrift gewünscht“ (vorerst ganz entfernt), „Zustimmung zur Zuständigkeitsvereinbarung nach § 27 AO“ (als Kanzleifeld nach Formular 0 verschoben, Mandant soll keine Zustimmung zu einer Zuständigkeitsvereinbarung selbst einschätzen), „Abweichender Ort der Geschäftsleitung“/„Ort der Geschäftsleitung – Adresse“ (als Tatsachenfelder zu den einzelnen Personen nach Formular 3 verschoben — der Ort der tatsächlichen Geschäftsleitung ist ein Ergebnisfeld, das die Kanzlei ableitet, siehe Datenmodell Abschnitt 10).

### E.2 Formular 2 — Unternehmens-/Gründungsmodul (Inbound; auch Einzelunternehmen und Personengesellschaften, siehe Routing-Tabelle E.9)

**Grundlegend überarbeitet 28.10.2026 (Review Nils, Grundregel „Tatsachen statt rechtlicher Würdigung“ + „jede Stammangabe genau an einer Stelle“, siehe Datenmodell Abschnitt 10):** „Bezeichnung des Unternehmens“ und „Rechtsform“ entfernt (Stammangaben, leben jetzt nur noch in Formular 1 — diese Liste referenziert über `case_id`). „Vorheriger Inhaber“, „Abweichendes Wirtschaftsjahr“ und „Gewinnermittlungsart“ neu strukturiert. **Ergänzt 28.10.2026 (Befund Erfassungs-Chat-Generator, PR #22):** „Gründungsart“ selbst ist eine rechtliche Einordnung (insb. Bar-/Sachgründung, Umwandlung) und daher ab sofort **keine Forms-Frage mehr**, sondern Kanzleifeld (`formation_type`, `-FieldRole "Ergebnis"`, siehe Abschnitt C3) — ersetzt durch zwei neue Tatsachenfragen (18/19 unten).

1. Fall-ID — Text (Pflicht)
2. Gründungsdatum — Date (Pflicht)
3. Beginn der Tätigkeit — Date (Pflicht)
4. Notarielle Errichtung / Musterprotokoll vom — Date
   - Branching: nur bei Rechtsform = Kapitalgesellschaft/Genossenschaft (Kontextfrage aus Formular 0/1 wiederholen oder als eigene Frage 3a führen)
5. Grund-/Stammkapital – Betrag — Number
   - Branching: nur bei Kapitalgesellschaft
6. Grund-/Stammkapital – Währung — Text
   - Branching: wie 5
7. Eingezahltes Kapital — Number
   - Branching: wie 5
   - Hinweistext: „Bitte Gründungsurkunde/Satzung/Gesellschaftsvertrag über Formular 8 (Unterlagen, Dokumenttyp „Gründungsurkunde“/„Satzung“) hochladen“ (kein eigenes Upload-Feld hier, siehe Formular 8, Review Nils 28.10.2026)
8. Grund-/Stammkapital erbracht als — Choice: Bareinlage / Sacheinlage / gemischt (Bar- und Sacheinlage)
   - Branching: wie 5 (`capital_contribution_type`, **neu** 28.10.2026 — Tatsachenfrage zur Ableitung von „Gründungsart“, siehe Datenmodell Abschnitt 10 Ableitungstabelle)
9. Handelsregister-Status — Choice: beabsichtigt / beantragt / erfolgt (Pflicht)
10. Ort des Amtsgerichts bzw. der ausländischen Registerbehörde — Text
    - Branching: nur wenn Frage 9 ≠ beabsichtigt (DisplayName seit 28.10.2026 verallgemeinert, deckt auch Körperschaft ausländischen Rechts ab, siehe Abschnitt H2 und E.9-Korrektur)
11. Register / Registernummer — Text
    - Branching: wie 10
12. Wurde die Tätigkeit vorher ganz oder teilweise von einem anderen Unternehmen bzw. einer anderen Person ausgeübt? — Choice Ja/Nein (`predecessor_exists`, ersetzt seit 28.10.2026 das Freitextfeld „Vorheriger Inhaber/Vorunternehmen“, siehe Abschnitt H2)
13. Vorheriger Inhaber / Vorunternehmen — Name — Text
    - Branching: nur bei Frage 12 = Ja (`predecessor_name`, **neu**)
14. Vorheriger Inhaber / Vorunternehmen — Steuernummer bzw. Anschrift — Text lang
    - Branching: wie 13 (`predecessor_tax_or_address`, **neu**)
15. Übernahme ganz oder teilweise — Choice: ganz / teilweise
    - Branching: wie 13 (`predecessor_scope`, **neu**)
16. Übernommen ab — Date
    - Branching: wie 13 (`predecessor_since`, **neu**)
17. Ist das Unternehmen durch eine gesellschaftsrechtliche Umwandlung entstanden (z. B. Verschmelzung, Spaltung, Formwechsel)? — Choice Ja/Nein (`transformation_event`, **neu** 28.10.2026 — weitere Tatsachenfrage zur Ableitung von „Gründungsart“)
18. Art der Umwandlung und beteiligte Rechtsträger — Text lang
    - Branching: nur bei Frage 17 = Ja (`transformation_details`, **neu**)
19. Entspricht das Wirtschaftsjahr dem Kalenderjahr? — Choice Ja/Nein (`fiscal_year_matches_calendar`, ersetzt seit 28.10.2026 „Abweichendes Wirtschaftsjahr“ mit umgekehrtem Vorzeichen, siehe Abschnitt H2)
20. Wirtschaftsjahr – Beginn — Date
    - Branching: nur bei Frage 19 = Nein
21. Wirtschaftsjahr – Ende — Date
    - Branching: wie 20 (`fiscal_year_end`, **neu** — „Beginn“ ohne „Ende“ war bislang unvollständig)
22. Voraussichtlicher Gewinn Eröffnungsjahr — Number (Pflicht)
23. Voraussichtlicher Gewinn Folgejahr — Number (Pflicht)
24. Buchführungs-/Bilanzierungspflicht nach ausländischem Recht — Choice Ja/Nein
    - Branching: nur bei Formulartyp = Körperschaft nach ausländischem Recht (`foreign_bookkeeping_obligation`, **neu**, Tatsachenfeld statt der rechtlichen Würdigung „Gewinnermittlungsart“)
25. Bereits bilanziert (freiwillig oder nach anderer Vorschrift) — Choice Ja/Nein (`voluntary_balance_sheet`, **neu**)
26. Rechtsgrundlage der Bilanzierung (z. B. Handelsrecht, ausländisches Recht) — Text
    - Branching: nur bei Frage 25 = Ja (`balance_sheet_basis`, **neu**; Handelsregister-Eintragung bereits über Frage 9, freiberufliche Tätigkeit bereits über Formular 1 Frage 10 abgedeckt — keine Dubletten angelegt. Die Kanzlei leitet „Gewinnermittlungsart“ aus den Fragen 9, 10 (Formular 1), 8, 12-18, 22-26 ab, siehe Datenmodell Abschnitt 10 Ableitungstabelle)
27. Konzernzugehörigkeit — Choice Ja/Nein
28. Herrschendes Unternehmen – Name — Text
    - Branching: nur bei Frage 27 = Ja
29. Organträgerschaft — Choice Ja/Nein
30. Rechtsfähigkeit — Choice Ja/Nein
    - Branching: nur bei Formulartyp = Personengesellschaft oder -gemeinschaft (Kontextfrage aus Formular 0 wiederholen; Datenmodell Kz 33, dort für diesen Formulartyp unbedingtes Pflichtfeld)
31. Aufteilungsschlüssel (Gewinn-/Verlustverteilung) — Text
    - Branching: wie 30 (Datenmodell Kz 80, dort unbedingtes Pflichtfeld)
32. Gründungsnotar — Name — Text
    - Hinweistext in die Frage aufnehmen: „Falls ausgefüllt, bitte auch die Adresse in der folgenden Frage angeben“ (ELSTER-Portalprüfung 26.10.2026: sobald ein Notar genannt ist, wird dessen Adresse bedingt Pflicht — Forms kann eine Pflicht nicht von einem vorangehenden Freitext abhängig machen, siehe Datenmodell Abschnitt 9.6)
33. Gründungsnotar — Adresse — Text lang
    - Hinweistext wie 32
34. Komplementärin einer KG — Choice Ja/Nein
35. Bezeichnung der KG — Text
    - Branching: nur bei Frage 34 = Ja
36. Handelsregister — Datum (beantragt am / Tag der Eintragung) — Date
    - Branching: nur bei Frage 9 ≠ beabsichtigt
37. Betriebsaufspaltung — Choice Ja/Nein
38. Bezeichnung des Besitzunternehmens — Text
    - Branching: nur bei Frage 37 = Ja
39. Bezeichnung des überlassenen Wirtschaftsguts (wesentliche Betriebsgrundlage) — Text
    - Branching: wie 38 (Kanzleientscheid 27.10.2026, siehe Datenmodell Abschnitt 9.6 — Wortlaut der ELSTER-Fehlerliste nannte nur „Bezeichnung“ ohne weiteren Kontext, der Wortlaut dieser Frage ist daher Kanzleientscheid und im Portal nicht verifiziert)
40. Beginn der tatsächlichen Nutzung — Date
    - Branching: wie 38
41. Anschrift und/oder Steuernummer des Besitzunternehmens — Text lang
    - Branching: wie 38
42. Körperschaftsteuerbefreiung nach § 5 KStG — Choice Ja/Nein
43. Nummer nach § 5 Absatz 1 KStG — Text
    - Branching: nur bei Frage 42 = Ja
44. Feststellung nach § 60a AO — Choice Ja/Nein
45. Zweck der Körperschaft — Text lang
    - Branching: nur bei Frage 44 = Ja
46. Organgesellschaft (körperschaftsteuerliche Organschaft) — Choice Ja/Nein
47. Name/Firma des Organträgers — Text
    - Branching: nur bei Frage 46 = Ja
48. Umsatzsteuerliche Organschaft — Choice Ja/Nein
49. Beginn der umsatzsteuerlichen Organschaft — Date
    - Branching: nur bei Frage 48 = Ja

Fragen 32-49 (Update 2, ELSTER-Portalprüfung 26.10.2026): bedingte Pflichtfelder, Status `belegt_bedingt`. Keine dieser Spalten ist in SharePoint bedingungslos `-Required`, da die Pflicht jeweils an die genannte Auswahl geknüpft ist — Details siehe Datenmodell Abschnitt 9.6.

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
16. Übliches Land der Tätigkeit (dieser Person) — Text
    - Branching: nur bei Frage 2 = Gesetzlicher Vertreter oder Ständiger Vertreter (`usual_workplace_country`, **neu** 28.10.2026, Review Nils — verschoben von Formular 1, siehe Abschnitt H2: der Ort der tatsächlichen Geschäftsleitung des Unternehmens ist ein Ergebnisfeld, das die Kanzlei aus den üblichen Tätigkeitsorten der gesetzlichen Vertreter ableitet, siehe Datenmodell Abschnitt 10 Ableitungstabelle)
17. Übliche Adresse/Ort der Tätigkeit (dieser Person) — Text lang
    - Branching: wie 16 (`usual_workplace_address`, **neu**)
18. Arbeitet auch regelmässig an einem anderen Ort — Choice Ja/Nein
    - Branching: wie 16 (`works_elsewhere`, **neu**)
19. Anderer Tätigkeitsort – wo und Anteil der Arbeitszeit — Text lang
    - Branching: nur bei Frage 18 = Ja (`other_workplace_details`, **neu**)

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
13. Treuhandverhältnis — Choice: Ja / Nein (Pflicht; seit 28.10.2026 Choice statt Boolean, `trust_relationship_status` ersetzt `trust_relationship` — gleiches Muster wie `registration_status`/`already_registered`, siehe Abschnitt C2, zweiter Fallen-Block Punkt 2, und Abschnitt H2)
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

Hinweis: je Betriebsstätte/Einrichtung eine Antwort. **Geändert 28.10.2026 (Befund Erfassungs-Chat-Generator, PR #22):** „Art der Einrichtung“ (fest/nicht fest) ist der Betriebsstätten-Begriff aus § 12 AO selbst und daher ab sofort **keine Forms-Frage mehr**, sondern Kanzleifeld (`site_type`, `-FieldRole "Ergebnis"`, siehe Abschnitt C3) — ersetzt durch eine neue Tatsachenfrage (5 unten). Fragen 11 und 13 (`vat_relevant_site`/`payroll_tax_site`) sind nach derselben Grundregel-Lesart ebenfalls Ergebnisfelder (siehe Datenmodell Abschnitt 10.3, offener Punkt) — bleiben in dieser Runde aber bewusst als Forms-Fragen bestehen, da sie nicht Teil des aktuellen Generator-Befunds waren; Umstellung für eine künftige Runde vorgesehen.

1. Fall-ID — Text (Pflicht)
2. Bezeichnung der Betriebsstätte/Einrichtung — Text (Pflicht)
3. Land — Text (Pflicht)
4. Adresse — Text lang (Pflicht)
5. Eigene, nicht nur vorübergehende Verfügungsmacht über die Einrichtung (z. B. eigener Schlüssel/Zugang, eigener Arbeitsplatz) — Choice Ja/Nein (`own_disposal_power`, **neu** 28.10.2026 — zentrales Tatbestandsmerkmal zur Ableitung von „Art der Einrichtung“, siehe Datenmodell Abschnitt 10 Ableitungstabelle)
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
2. Dokumenttyp — Choice: Gründungsurkunde / Satzung / Gesellschaftsvertrag / Vollmacht Steuerberatung / Empfangsvollmacht / SEPA-Mandat / Handelsregisterauszug / Sachgründungsbericht / Ansässigkeitsbescheinigung / Sonstiges (Pflicht; „Gründungsurkunde“/„Satzung“ ergänzt 28.10.2026, Review Nils — Formular 2 verweist für den Upload von Gründungsurkunde/Satzung/Gesellschaftsvertrag hierher statt ein eigenes Upload-Feld zu führen)
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
| Körperschaft nach ausländischem Recht | 1, 2, 3, 5, 8 |
| BZSt2-Mitteilung | 1, 4 (falls Beteiligungssachverhalt), 7, 8 |

**Routing-Korrektur 28.10.2026 (Review Nils, Audit Formular 1):** Formular 2 fehlte bislang bei „Körperschaft nach ausländischem Recht“, obwohl diese Rechtsform Registerangaben (Handelsregister-Status, Ort der Registerbehörde, Registernummer/-datum, siehe `registry_court`-DisplayName-Anpassung in Abschnitt H2), Gründungsdatum/-art und die neuen Tatsachenfelder zur Gewinnermittlung (`foreign_bookkeeping_obligation` usw.) genauso benötigt wie die übrigen Formulartypen. Formular 2 ergänzt.

**Bewusst ausgeschlossen (Kanzleientscheid 26.10.2026, siehe Datenmodell Abschnitt 9.1 Status `X`):** Verein/Stiftung/sonstige Körperschaft privaten Rechts sowie juristische Person des öffentlichen Rechts/Betrieb gewerblicher Art sind praktisch ohne Relevanz für die Kanzleipraxis. Es gibt deshalb **bewusst keinen** zusätzlichen `form_type`-Wert und **kein** zusätzliches Formular/keine zusätzliche Liste dafür — keine offene Frage mehr, sondern eine endgültige Entscheidung. Sollte doch einmal ein solcher Fall auftreten, läuft er ausschliesslich über `0_Fallsteuerung.processing_note` (Freitext) und manuelle Bearbeitung ausserhalb der Formularfamilie.

**Manueller Prüfschritt (Kanzleientscheid 26.10.2026, siehe Datenmodell Abschnitt 9.1 Status `M`):** Bei ausländischen Partnerships, LLPs, LLCs oder hybriden Rechtsformen entscheidet die Kanzlei den Rechtstypenvergleich und die steuerliche Einordnung **manuell**, bevor Formular 0 ausgefüllt wird — dafür gibt es bewusst keine Automatisierung in Formularen oder Listen. Je nach Ergebnis des manuellen Vergleichs wird der Fall anschliessend ganz regulär als „Personengesellschaft oder -gemeinschaft“ oder als „Körperschaft nach ausländischem Recht“ in Formular 0 erfasst.

### E.10 Prüfregeln für Power-Automate-Flows (bedingte Pflichtfelder, die Forms nicht abbilden kann)

Die meisten in Datenmodell Abschnitt 9.6 gelisteten bedingten Pflichtfelder (Update 2, ELSTER-Portalprüfung 26.10.2026) lassen sich über reguläres Forms-Branching abbilden (siehe Fragen 30-47 in E.2 und 19-33 in E.6 oben). Zwei Bedingungen kann Forms grundsätzlich nicht abbilden und müssen stattdessen als Prüfregel im jeweiligen Power-Automate-Flow (Formular-Antwort → Element erstellen) umgesetzt werden:

1. **Steuernummer/Land bei anderem Finanzamt** (Formular 1, Fragen 28/29 „Art der Steuernummer-Angabe“/„Steuernummer“, **nicht mehr** in Kombination mit einer Formular-1-Frage zu § 27 AO, da `par27_ao_agreement` seit 28.10.2026 als Kanzleifeld nur noch in `0_Fallsteuerung` existiert — die Bedingung verknüpft seitdem zwei Felder **innerhalb von** `0_Fallsteuerung` selbst, bleibt aber trotzdem eine Power-Automate-Prüfregel, da Forms für Formular 1 ohnehin keine Sicht auf `0_Fallsteuerung`-Felder hat): **Prüfregel:** Der Flow, der Formular-1-Antworten nach `1_Allgemeiner_Stammblock` überträgt, soll vor dem „Element erstellen“-Schritt per „Element abrufen“ aus `0_Fallsteuerung` prüfen, ob `par27_ao_agreement` = Ja **und** `registration_status` = Ja gilt (Feld seit 28.10.2026 umbenannt, vorher `already_registered`, siehe Abschnitt H2); ist dann `existing_tax_number` oder `tax_office_country` leer, Element stattdessen in `Eingang_Fehler` anlegen (`form_no` = 1, `reason` = „Steuernummer/Land bei anderem Finanzamt fehlt trotz § 27 AO-Zustimmung“, `payload` = Rohantwort) statt den unvollständigen Datensatz kommentarlos zu übernehmen.
2. **BIC nur bei bestimmten IBAN-Ländern** (Formular 1, Frage 34 „Bank – BIC“): Forms kann den Inhalt eines Textfelds nicht inspizieren, um eine Frage bedingt einzublenden. **Prüfregel:** Der Flow soll nach Übertragung prüfen, ob `bank_iban` mit einem der Länderpräfixe `AL`, `MD`, `MC`, `ME`, `MK`, `SM`, `CH` beginnt; falls ja und `bank_bic` leer ist, Element in `Eingang_Fehler` anlegen (`form_no` = 1, `reason` = „BIC fehlt bei nicht-SEPA-IBAN“) statt nur die bestehende Hinweistext-Lösung in Frage 34 zu verlassen.

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
- **Fachlicher Umbau 28.10.2026 (Review Nils, fresh-site Testlauf `transferpricingdocs`):** Lookup-Indexierungsbug, Required-Boolean-Muster, Grundregel-Umbau Listen 0-3/8 und Schreibvarianten-Dubletten sind behoben/umgesetzt — siehe Abschnitt C2 Punkte 4-6 und die neue Changelog-Tabelle in Abschnitt H2 unten für den vollständigen Stand inkl. der auf beiden Sites manuell nötigen Spalten-Löschungen.
- **Listen 3-8 noch nicht im Detail geprüft (Audit-Befund 28.10.2026):** Nils hat die Prüfung nach Listen 1/2 pausiert; weitere Befunde zu Listen 3-8 stehen noch aus. Eine erste eigene Durchsicht nach denselben Mustern (Würdigung statt Tatsache, Dubletten, Doppelabfragen, CRM-Daten, fehlende Verzweigung) ist in Abschnitt H2 als Audit-Ergebnis dokumentiert — nur `trust_relationship` (Liste 4) und die beiden Liste-8-Ergänzungen wurden umgesetzt, die übrigen Befunde sind offen und warten auf Nils' Rückmeldung bzw. eine eigene Umsetzungsrunde.

## H1. Changelog: interne Feldnamen (alt → neu) (28.10.2026, Laengenbegrenzung ueber 32 Zeichen)

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

## H2. Changelog 28.10.2026: Fachlicher Umbau (Review Nils, Grundregel Tatsachen/Rechtsfolgen)

Dieser Abschnitt dokumentiert den fachlichen Umbau aus der Pruefung von Nils (28.10.2026, Testlauf gegen die frische Site `transferpricingdocs.sharepoint.com/sites/steuerdaten`) — ergaenzend zur Changelog-Tabelle in Abschnitt H1 (die nur die laengenbedingten Umbenennungen vom Vortag betrifft). Grundregel: Der Mandant liefert **Tatsachen**, nie eine rechtliche/steuerliche Wuerdigung; die Kanzlei leitet Ergebnisfelder daraus ab (siehe Datenmodell Abschnitt 10 Ableitungstabelle).

### H2.1 Bugfixes (technisch, nicht fachlich)

| Bug | Fund | Fix |
|---|---|---|
| Lookup mit `RelationshipDeleteBehavior` braucht Index bereits bei Erstanlage | Skriptabbruch auf frischer Site beim Anlegen eines `case_id`-Lookups mit `Restrict` | `Indexed='TRUE'` im Erstellungs-XML, sobald `DeleteBehavior != None` (Abschnitt C2, zweiter Fallen-Block Punkt 1) |
| Required-Boolean-Felder lassen sich nur mit „Ja“ speichern | `already_registered`, `trust_relationship` (beide Boolean, `-Required`) | Durch Choice-Feld Ja/Nein(/Unbekannt) ersetzt: `registration_status`, `trust_relationship_status` (Abschnitt C2, zweiter Fallen-Block Punkt 2) |
| Schreibvarianten-Dubletten in Auswahlwerten | z. B. „UG“/„UG (haftungsbeschränkt)“, Rechtsform mit Umlaut/„ae“-Variante nebeneinander | Statischer Selbsttest `Test-ChoiceValueDuplicates` (Hauptskript) + Live-Pruefung in `Test-SteuerlicheErfassungListen.ps1` (Abschnitt C2, zweiter Fallen-Block Punkt 3) |
| Required-Ergebnisfelder (Befund paralleler Erfassungs-Chat-Generator, PR #22) | `tax_office` (bereits behoben), `formation_type`, `profit_determination_method` (bereits behoben), `site_type` | Zwei verbleibende Felder nicht mehr -Required + als Kanzleifeld markiert; neue harte Invariante in `Add-Field` verhindert das Muster strukturell (siehe Abschnitt C2 Punkt 4 und Abschnitt C3) |

### H2.2 Feldaenderungen nach Liste

**`0_Fallsteuerung`** (interne Steuerliste der Kanzlei, nicht vom Mandanten befuellt):

| Feld | Aenderung | Begruendung |
|---|---|---|
| `direction` | Choices: „Inbound“/„Outbound“ → „Ausländische Gesellschaft mit Bezug zu Deutschland (Inbound)“/„Deutsche Gesellschaft/Person mit Auslandsbezug (Outbound)“ | Nicht selbsterklaerend fuer die Kanzlei. **Breaking Change** fuer Flow-Bedingungen auf den alten Wortlaut |
| `already_registered` → `registration_status` | Boolean -Required → Choice (Ja/Nein/Unbekannt), nicht mehr Required | Required-Boolean-Bug (siehe H2.1) |
| `tax_office_country` | Text -Required → Choice (Laenderliste inkl. Unbekannt), nicht mehr Required | Ergebnisfeld, keine Mandanten-Tatsache; Choice statt Freitext |
| `tax_office` | nicht mehr Required | Ergebnisfeld, die Kanzlei bestimmt das Finanzamt |
| `target_notification` | DisplayName praezisiert („wird von der Kanzlei... festgelegt“) | Klarstellung Ergebnisfeld |
| `access_code` | `-HideFromForms` ergaenzt, DisplayName praezisiert | Niemand soll den Wert von Hand eintragen |
| `par27_ao_agreement` | **verschoben** von `1_Allgemeiner_Stammblock` hierher, als Kanzleifeld | Mandant soll keine Zustimmung zu einer Zustaendigkeitsvereinbarung selbst einschaetzen |
| `crm_reference` | **neu** (Text, Kanzleifeld) | Ersetzt die bisherigen CRM-Kontaktfelder in Liste 1 |

**`1_Allgemeiner_Stammblock`:**

| Feld | Aenderung | Begruendung |
|---|---|---|
| `legal_form` | **entfernt**, ersetzt durch `legal_form_category`, `legal_form_jurisdiction`, `legal_form_german`, `legal_form_foreign_name`, `legal_form_foreign_country` | Freitext → strukturierte Zwei-Fragen-Logik (Grundtyp, dt./ausl. Recht) |
| `asset_management_only` | **entfernt**, ersetzt durch `asset_management_present`, `asset_management_type`, `asset_mgmt_share_revenue`, `asset_mgmt_share_profit`, `other_business_activities` | Rechtliche Wuerdigung → Tatsachenfelder (Art/Anteil der Vermoegensverwaltung) |
| `tax_office` | **entfernt** | Dublette zu `0_Fallsteuerung` |
| `phone`, `callback_email` | **entfernt** | CRM-Kontaktdaten der Kanzlei, nicht Teil der Fallakte |
| `sepa_desired` | **entfernt** (vorerst ganz) | Review Nils: vorerst nicht benoetigt |
| `par27_ao_agreement` | **verschoben** nach `0_Fallsteuerung` | siehe oben |
| `deviating_management_place`, `management_address` | **entfernt**, Konzept als `usual_workplace_*` nach `3_Personen_und_Vertretung` verschoben | Gehoert fachlich zur Person (Geschaeftsfuehrer), nicht zum Unternehmen; Ort der Geschaeftsleitung ist Ergebnisfeld |
| `foreign_tax_id`, `vat_id_existing` | **neu** | Bislang fehlende Firmenangaben (Cross-Check gegen Liste 2: keine Dubletten) |

**`2_Unternehmens_Gruendungsmodul`:**

| Feld | Aenderung | Begruendung |
|---|---|---|
| `company_name`, `legal_form` (eigene Choice-Liste) | **entfernt** | Stammangaben, leben nur noch in Liste 1 (`last_name_or_company`, `legal_form_*`); diese Liste referenziert ueber `case_id` |
| `predecessor` | **entfernt**, ersetzt durch `predecessor_exists`, `predecessor_name`, `predecessor_tax_or_address`, `predecessor_scope`, `predecessor_since` | Freitext → Ja/Nein-Tatsache plus strukturierte Folgefragen |
| `deviating_fiscal_year` | **entfernt**, ersetzt durch `fiscal_year_matches_calendar` (umgekehrtes Vorzeichen) | Vermeidet doppeltes Pflichtfeld-Paar |
| `fiscal_year_end` | **neu** | „Beginn“ ohne „Ende“ war unvollstaendig |
| `profit_determination_method` | nicht mehr Required, DisplayName als Kanzleifeld praezisiert | Rechtliche Wuerdigung (§ 4/5 EStG) |
| `foreign_bookkeeping_obligation`, `voluntary_balance_sheet`, `balance_sheet_basis` | **neu** | Tatsachenfelder zur Ableitung der Gewinnermittlungsart |
| `registry_court` | DisplayName verallgemeinert („... bzw. der auslaendischen Registerbehoerde“) | Deckt auch Koerperschaft auslaendischen Rechts ab (siehe E.9-Routing-Korrektur) |
| `formation_type` | nicht mehr Required, DisplayName als Kanzleifeld praezisiert, `-FieldRole "Ergebnis"` | Befund Erfassungs-Chat-Generator 28.10.2026 (PR #22): "Gruendungsart" (Bar-/Sachgruendung, Umwandlung) ist selbst eine rechtliche Einordnung |
| `capital_contribution_type`, `transformation_event`, `transformation_details` | **neu** | Tatsachenfelder zur Ableitung von "Gruendungsart" |

**`3_Personen_und_Vertretung`:**

| Feld | Aenderung | Begruendung |
|---|---|---|
| `usual_workplace_country`, `usual_workplace_address`, `works_elsewhere`, `other_workplace_details` | **neu** | Ersetzt `deviating_management_place`/`management_address` aus Liste 1 (siehe oben) |

**`4_Beteiligte_und_Quoten`:**

| Feld | Aenderung | Begruendung |
|---|---|---|
| `trust_relationship` → `trust_relationship_status` | Boolean -Required → Choice (Ja/Nein), weiterhin Required | Required-Boolean-Bug (siehe H2.1); bleibt Pflicht (ELSTER Kz 90), „Unbekannt“ hier nicht vorgesehen |

**`5_Betriebsstaetten`:**

| Feld | Aenderung | Begruendung |
|---|---|---|
| `site_type` | nicht mehr Required, DisplayName als Kanzleifeld praezisiert, `-FieldRole "Ergebnis"` | Befund Erfassungs-Chat-Generator 28.10.2026 (PR #22): "fest/nicht fest" ist der Betriebsstaetten-Begriff aus Paragraf 12 AO selbst |
| `own_disposal_power` | **neu** | Tatsachenfeld (Verfuegungsmacht) zur Ableitung von "Art der Einrichtung" |

**`8_Unterlagen`:**

| Feld | Aenderung | Begruendung |
|---|---|---|
| `document_type` | Choices ergaenzt um „Gründungsurkunde“, „Satzung“ (additiv) | Upload-Referenzziel fuer Liste 2 |

### H2.3 Auf Bestandssites manuell zu loeschende Spalten

Dieses Skript legt eine Typaenderung (z. B. Boolean → Choice) **nie automatisch** an (siehe Abschnitt C2 Punkt 3) — die folgenden Spalten werden von `New-SteuerlicheErfassungListen.ps1` ab sofort **nicht mehr** angelegt oder angeglichen und muessen auf beiden bekannten Sites (`obenhaus.sharepoint.com/sites/steueranwaltskanzlei` und `transferpricingdocs.sharepoint.com/sites/steuerdaten`) **manuell** entfernt werden, nachdem das aktualisierte Skript einmal durchgelaufen ist:

| Liste | Alte Spalte | Ersetzt durch | Hinweis vor dem Loeschen |
|---|---|---|---|
| `0_Fallsteuerung` | `already_registered` | `registration_status` | Unbedenklich — beide Sites hatten beim Wechsel 0 Eintraege in `0_Fallsteuerung` |
| `1_Allgemeiner_Stammblock` | `legal_form` | `legal_form_category`/`legal_form_jurisdiction`/`legal_form_german`/`legal_form_foreign_name`/`legal_form_foreign_country` | Vor dem Loeschen pruefen, ob die Liste bereits befuellt ist (Dateninhalt ginge verloren) |
| `1_Allgemeiner_Stammblock` | `asset_management_only`, `tax_office`, `phone`, `callback_email`, `sepa_desired`, `par27_ao_agreement`, `deviating_management_place`, `management_address` | siehe Tabelle H2.2 | wie oben — Dateninhalt vor dem Loeschen sichern/pruefen |
| `2_Unternehmens_Gruendungsmodul` | `company_name`, `legal_form`, `predecessor`, `deviating_fiscal_year` | siehe Tabelle H2.2 | wie oben |
| `4_Beteiligte_und_Quoten` | `trust_relationship` | `trust_relationship_status` | **Kein 0-Eintraege-Nachweis bekannt** (anders als bei `already_registered`) — vor dem Loeschen auf beiden Sites pruefen, ob Liste 4 bereits befuellt ist |

**Empfohlene Reihenfolge je Site:** (1) aktualisiertes Skript einmal laufen lassen (idempotent, legt die neuen Spalten an/gleicht sie an, ruehrt die alten Spalten nicht an), (2) `Test-SteuerlicheErfassungListen.ps1` laufen lassen und `ERGEBNIS: OK` abwarten, (3) je Zeile oben pruefen, ob die Liste tatsaechlich leer ist bzw. ob vorhandene Werte zuerst manuell in die neue Spalte uebertragen werden muessen, (4) alte Spalte in der SharePoint-Listeneinstellung loeschen.
