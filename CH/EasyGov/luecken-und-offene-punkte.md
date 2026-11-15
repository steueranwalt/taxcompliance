# Lücken, dokumentierte EasyGov-Fehler und offene Punkte

**Stand:** 2026-11-15. Quelle: Live-Inventar, ohne Testdaten und ohne Entwurfs-IDs.

Maschinenlesbar: [`luecken.json`](luecken.json).

## Dokumentierte Portalfehler

### Saldosteuersatz-Anteilsfeld nicht gefunden

Bereich: `mwst`. Bei Methode Saldosteuersatz erscheint der Fehler, Anteile aller Tätigkeiten müssten in der Summe 100 % ergeben. Anteilsfeld und SSS-Auswahl waren im Inventar nicht auffindbar.

### KlG-PDF Titel Einzelunternehmen

Bereich: `hr`. Strukturiertes KlG-Anmelde-PDF trägt auf Seite 2 den Titel «Anmeldung eines Einzelunternehmens».

### KmG-PDF Einlageart falsch ausgegeben

Bereich: `hr`. PDF-Text zur Kommandite gibt die Einlageart nicht korrekt wieder.

### KmG-PDF Kommanditär als unbeschränkt haftend

Bereich: `hr`. Kommanditär auf Seite 5 fälschlich als unbeschränkt haftend bezeichnet.

### KmG-PDF Titel Einzelunternehmen

Bereich: `hr`. Wie KlG: PDF-Titel «Anmeldung eines Einzelunternehmens».

### KlG Cockpit «Vollständig» ohne Einreichung

Bereich: `hr`. Nach «Später fertigstellen» zeigt das Cockpit den HR-Prozess als vollständig, obwohl die Abschluss-Checkbox nicht gesetzt und nichts eingereicht wurde (Papierweg).

### Branchenkatalog HR-Seite Ladefehler

Bereich: `hr`. Branche-Seite in der HR-Anmeldung EU lud nicht; Liste aus dem Gründungsablauf übernommen.

### ZH keine Treffer elektronische Gründung

Bereich: `hr`. Notarsuche Kanton ZH ohne Treffer für elektronische Gründung (Stand 15.11.2026). Fallback-Checkbox auf Papierweg.

## Von EasyGov nicht abgefragt (beim Notar bzw. der Kanzlei zu erheben)

- **Statuten / Gesellschaftsvertrag** — EasyGov fragt Statuten nicht ab; beim Notar zu erheben.
- **Revisionsstelle / Opting-out** — Weder GmbH- noch AG-HR-Strecke fragt Revisionsstelle oder Opting-out ab.
- **Vinkulierung, Nachschuss, Nebenleistung, Publikationsorgan** — Nicht in EasyGov; beim Notar zu erheben.
- **Bank / Kapitaleinzahlung** — Keine Uploads, keine Bankbestätigung in EasyGov.
- **Juristische Person als GmbH/AG-Gesellschafter** — HR-Strecke erlaubt nur natürliche Personen als Gründer.
- **Separates Nennwertfeld** — Kein Nennwertfeld; implizit Kapital/Anzahl. Keine Stimmrechtsaktien, keine Partizipationsscheine.
- **Sachübernahme-Option** — In der Liberierungsart nicht sichtbar.
- **IBAN in der MWST-Anmeldung** — ESTV-Strecke ohne IBAN und ohne AHV im Kontakt-Schritt.
- **Suva-pflichtige Branche** — Suva-Zweig im UVG-Inventar nicht gesehen.

## Offene Erhebungspunkte

- **Wohnsitz Ausland im HR-EU-Detail** — In der HR-Anmeldung EU nicht im Detail aufgenommen; in den Gründungs-Basisdaten (Varianten) dokumentiert.
- **Schweizer/in mit Wohnsitz Ausland** — Pfad in den Varianten offen.
- **UVG Anmeldung statt Offerte** — Pfad «Anmeldung an Ihren UVG-Versicherer senden» nicht durchgespielt.
- **MWST Datumsfeld Anderes Datum** — Feld bei «Anderes Datum» nicht im Detail erfasst.
- **Vollständige Rechtsformliste juristische Personen** — KmG-Kommanditär: Portal-Liste nur beispielhaft erhoben.
- **Kontakt-/Rechnungsadresse bei 0 Auszügen** — Felder bei 0 Auszügen nicht eingeblendet; Typ offen.
- **Weitere Geschäftslokale als wiederholbares Objekt** — Im Portal optional; hier vorerst Freitext, analog DE Standortliste noch nicht ausgebaut.
- **KlG/KmG unter CHF 100'000** — Meldepflichten-Kombinationen unter der Schwelle nicht separat durchgespielt.
- **Transparenzregister** — EasyGov erwähnt es für GmbH/AG nach HR-Eintrag; Felder nicht erhoben.

## Bezug zur bestehenden HR-EU-Analyse

Die ältere, anonymisierte Auswertung eines EasyGov-Ausdrucks «Anmeldung eines Einzelunternehmens» (Formularstand 11.8.2025, Kanton ZH) bleibt unter [`../Handelsregister/handelsregister_einzelunternehmen_formularfelder_lp_beratung.md`](../Handelsregister/handelsregister_einzelunternehmen_formularfelder_lp_beratung.md). Abweichungen zum Live-Inventar 15.11.2026 sind in der Rohfassung und in den offenen Punkten kenntlich; die ältere Analyse wird nicht ersetzt.

