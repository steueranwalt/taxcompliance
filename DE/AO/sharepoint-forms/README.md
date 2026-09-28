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
Connect-PnPOnline -Url "https://obenhaus.sharepoint.com/sites/<ziel-site>" -Interactive
.\New-SteuerlicheErfassungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/<ziel-site>"
```

Legt an: `0_Fallsteuerung`, `1_Allgemeiner_Stammblock`, `2_Unternehmens_Gruendungsmodul`, `3_Personen_und_Vertretung`, `4_Beteiligte_und_Quoten`, `5_Betriebsstaetten`, `6_Steuer_und_Umsatzsteuerprofil`, `7_Auslandsmitteilung_BZSt2`, `8_Unterlagen`, `Technische_Mindestfelder` (intern, kein Form) — jeweils mit allen Spalten aus dem Auftrag, inkl. `case_id`-Lookup auf `0_Fallsteuerung` in jeder Folgeliste. Idempotent: bereits vorhandene Listen/Felder werden übersprungen, das Skript kann gefahrlos mehrfach laufen.

**SharePoint kennt keine bedingten Pflichtfelder.** Die Spalte „Erforderlich“ wird deshalb nur bei *unbedingten* Pflichtfeldern gesetzt (`-Required`). Alle mit „Bedingt“ markierten Felder bleiben in SharePoint optional; die Pflichtlogik wird ausschliesslich über Forms-Branching (Abschnitt E) durchgesetzt.

`created_by`/`created_at` (Liste 0) werden nicht als Zusatzspalten angelegt, sondern über die SharePoint-Systemfelder `Author`/`Created` abgebildet.

`related_object` (Liste 8) ist in SharePoint kein Multi-Listen-Lookup — ersatzweise vier Einzel-Lookups: `related_case`, `related_person`, `related_participation`, `related_site`.

## D. Fall-ID-Generator

`case_id` in Liste 0 ist ein einzeiliges Textfeld ohne serverseitige Auto-Nummerierung. Empfehlung: Format `JJJJ-NNNN` (z. B. `2026-0001`), vergeben durch die Kanzlei bei Fallanlage, oder ergänzend ein Power-Automate-Flow „Bei Erstellung eines Elements in 0_Fallsteuerung → berechne case_id aus ID-Spalte + Jahr → Element aktualisieren“. Bis ein Flow steht: manuelle Vergabe vor Weitergabe des Formularlinks an den Mandanten.

## E. Microsoft-Forms-Spezifikation je Formular

Formulare können nicht aus SharePoint-Spalten automatisch generiert werden, sobald Verzweigungsregeln nötig sind (die integrierte Funktion „Automatisieren → Formular erstellen“ erzeugt nur ein 1:1-Formular ohne Branching). Die folgenden Formulare deshalb direkt in [forms.office.com](https://forms.office.com) unter dem Konto der Zielsite anlegen, Fragen 1:1 aus den Listenspalten übernehmen. Fragetyp-Zuordnung:

| SharePoint-Spaltentyp | Forms-Fragetyp |
|---|---|
| Einzeiler Text | Text (kurze Antwort) |
| Mehrzeiliger Text | Text (lange Antwort) |
| Auswahl | Choice |
| Ja/Nein | Choice, 2 Optionen |
| Datum / Datum und Uhrzeit | Date |
| Zahl | Number |
| Anhang | File Upload (erfordert „Jeder mit einem Microsoft-Konto“ — siehe Hinweis unten) |
| Nachschlagefeld (Lookup) | Text (Fall-ID wird manuell/vom Vorformular übernommen, kein Live-Lookup in Forms) |

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

### E.2 Formular 2 — Unternehmens-/Gründungsmodul (nur Inbound)

1. Fall-ID — Text (Pflicht)
2. Bezeichnung des Unternehmens — Text (Pflicht)
3. Rechtsform — Choice (Pflicht)
4. Gründungsart — Choice: Neugründung / Übernahme / Umwandlung / Bar-/Sachgründung (Pflicht)
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

### E.3 Formular 3 — Personen und Vertretung (wenn vorhanden bzw. Pflicht)

Hinweis am Formularanfang: „Bitte für jede Person/Rolle eine eigene Antwort einreichen (Formular mehrfach ausfüllen).“ — Forms unterstützt keine wiederholbaren Unterobjekte innerhalb einer Antwort.

1. Fall-ID — Text (Pflicht)
2. Rolle — Choice: Gesetzlicher Vertreter / Ständiger Vertreter / Empfangsbevollmächtigter / Steuerliche Beratung / Ehegatte-Lebenspartner (Pflicht)
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
9. Tätigkeitsdauer – bis / unbekannt — Date
10. Umsatzsteuerliche Betriebsstätte — Choice Ja/Nein
11. Telefon / Internetadresse — Text
12. Lohnsteuerliche Betriebsstätte — Choice Ja/Nein

### E.6 Formular 6 — Steuer- und Umsatzsteuerprofil (nur Inbound)

1. Fall-ID — Text (Pflicht)
2. Geschätzter Umsatz Eröffnungsjahr — Number (Pflicht)
3. Geschätzter Umsatz Folgejahr — Number (Pflicht)
4. Kleinunternehmer-Regelung — Choice Ja/Nein
5. Verzicht auf Kleinunternehmer-Regelung — Choice Ja/Nein
   - Branching: nur bei Frage 4 = Ja
6. Voraussichtliche USt (Zahllast/Überschuss) — Number
7. Voranmeldungszeitraum — Choice: Monat / Quartal
8. USt-IdNr. beantragen — Choice Ja/Nein
9. Frühere USt-IdNr. — Text
   - Branching: nur bei Frage 8 = Nein (bereits vorhanden)
10. OSS-Verfahren — Choice Ja/Nein
11. Eigener Webshop — Choice Ja/Nein
12. Elektronische Schnittstelle — Text
    - Branching: nur bei Frage 11 = Ja
13. Bauleistungen über 10 % Weltumsatz — Choice Ja/Nein
14. Anzahl Arbeitnehmer insgesamt — Number
15. Beginn Lohnzahlungen — Date
    - Branching: nur bei Frage 14 > 0
16. Voraussichtliche Lohnsteuer — Number
    - Branching: wie 15
17. Freistellungsbescheinigung § 48b EStG — Choice Ja/Nein

### E.7 Formular 7 — Auslandsmitteilung BZSt2 (nur Outbound)

1. Fall-ID — Text (Pflicht)
2. Mitteilungsjahr — Number (Pflicht)
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
   - Branching: wie 5; bei Auswahl „13 Sonstiges“ Pflichtfeld „Erläuterung“ einblenden (zusätzliche Textfrage 9a)
10. Nominalkapital / Kapital — Number
    - Branching: wie 5
11. Im Inland steuerlich erfasst — Choice Ja/Nein
12. Beteiligte – Name / Anteil in % — Text
    - Branching: nur bei Frage 3 = PersG-Beteiligung oder KapG-Beteiligung
13. Beteiligt seit dem — Date
    - Branching: wie 12
14. Drittstaat-Beherrschung — Choice Ja/Nein
    - Branching: nur bei Frage 3 = Drittstaat-Beherrschung
15. Mitwirkung Steuerberatung — Choice Ja/Nein

### E.8 Formular 8 — Unterlagen (immer, bedingt)

1. Fall-ID — Text (Pflicht)
2. Dokumenttyp — Choice: Gesellschaftsvertrag / Vollmacht Steuerberatung / Empfangsvollmacht / SEPA-Mandat / Handelsregisterauszug / Sachgründungsbericht / Ansässigkeitsbescheinigung / Sonstiges (Pflicht)
3. Bezug zu Objekt — Text (Fall/Person/Beteiligung/Betriebsstätte-Kennung, da Forms kein Live-Lookup unterstützt)
4. Datei — File Upload (Pflicht)
5. Hinweis — Text lang

**Hinweis Datei-Upload:** Der Forms-Fragetyp „Datei hochladen“ verlangt vom Antwortenden zwingend die Anmeldung mit einem Microsoft-Konto (auch bei „Jeder mit dem Link kann antworten“). Externe Mandanten ohne Microsoft-Konto können daher Formular 8 nicht direkt nutzen — Alternativen: (a) Dateien per E-Mail/Kanzlei-Upload-Link separat einsammeln und Formular 8 nur für die Metadaten (Dokumenttyp, Hinweis) nutzen, oder (b) Formular 8 ausschliesslich für angemeldete Mandanten mit Microsoft-/Gastkonto vorsehen.

### E.9 Routing (Formular 0 → Folgeformulare)

Formularende von Formular 0 als Textblock mit bedingten Linklisten (Forms selbst kann kein formularübergreifendes Routing):

| Formulartyp | Pflicht-Folgeformulare |
|---|---|
| Einzelunternehmen | 1, 2, 3 (falls Vertretung/Empfangsbevollmächtigter), 6, 8 |
| Kapitalgesellschaft oder Genossenschaft | 1, 2, 3, 4, 5 (falls Betriebsstätten), 6, 8 |
| Personengesellschaft oder -gemeinschaft | 1, 2, 3 (falls Vertretung), 4, 5 (falls Betriebsstätten), 6, 8 |
| Körperschaft nach ausländischem Recht | 1, 3, 5, 8 |
| BZSt2-Mitteilung | 1, 4 (falls Beteiligungssachverhalt), 7, 8 |

## F. Freigabe und Rollout

1. Je Formular unter „…“ → Einstellungen → „Wer kann antworten“ → **„Jeder mit dem Link kann antworten“** aktivieren (Ausnahme Formular 8 bei Datei-Upload, siehe Hinweis oben).
2. Formular 0 als Startpunkt verlinken/einbetten (E-Mail an Mandant oder Einbettung auf einer Kanzlei-Landingpage).
3. Optional: Power-Automate-Flow „Bei neuer Microsoft-Forms-Antwort → Element in SharePoint-Liste erstellen“ je Formular/Liste-Paar, inkl. Zuordnung `case_id`/Lookup.
4. Testdurchlauf mit Dummy-Fall über den externen Link vor Versand an echte Mandanten: prüfen, ob alle Branching-Regeln (Abschnitt E) korrekt greifen und ob die Antworten korrekt in die zugehörige SharePoint-Liste geschrieben werden.

## G. Offene Punkte

- Schreibzugriff des Microsoft_365-Konnektors (`Sites.ReadWrite.All`, delegiert) fehlt noch — siehe Abschnitt A.
- Fall-ID-Vergabe (Abschnitt D) ist bis zur Power-Automate-Automatisierung manuell.
- Datei-Upload in Formular 8 erfordert Anmeldung — Alternativlösung mit dem Mandat abstimmen (Abschnitt E.8).
