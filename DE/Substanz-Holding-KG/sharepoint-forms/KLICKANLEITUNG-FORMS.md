# Klickanleitung: Microsoft-Forms-Formulare manuell anlegen (Update 1 — sieben Blätter)

Diese Anleitung ergänzt [`README.md`](README.md) und übernimmt die allgemeine Klick-Mechanik aus [`DE/AO/sharepoint-forms/KLICKANLEITUNG-FORMS.md`](../../AO/sharepoint-forms/KLICKANLEITUNG-FORMS.md) (Abschnitte A-D dort). Die Fragentexte und Auswahlwerte für die sieben Formulare stehen vollständig in [`../Fragenkatalog-Substanzpruefung-Holding-KG.md`](../Fragenkatalog-Substanzpruefung-Holding-KG.md) — **nur die Mandantensicht-Abschnitte dort eintragen, nicht die internen Hinweise.**

## A. Formular anlegen (einmalig pro Formular)

1. Browser öffnen, `forms.office.com` aufrufen, mit dem Kanzlei-Microsoft-Konto anmelden.
2. **„Neues Formular"** klicken. Titel z. B. „1 – Personenblatt – Substanzprüfung Holding-KG".
3. Im Beschreibungsfeld: „Bitte für jede Person eine eigene Antwort einreichen (Formular mehrfach ausfüllen)." (bzw. die passende Wiederholungslogik laut `README.md` Abschnitt E).
4. Erste Frage immer: „Fall-ID" (Text, Pflicht).

## B. Eine Frage hinzufügen

| Interner Antworttyp (Fragenkatalog) | Klick in Forms |
|---|---|
| T (Einzeiler) | **„Text"** → „Lange Antwort" **AUS** |
| T (mehrzeilig, z. B. Beschreibungen) | **„Text"** → „Lange Antwort" **EIN** |
| E (Einfachauswahl) | **„Auswahl"** |
| M (Mehrfachauswahl) | **„Auswahl"** → „Mehrere Antworten zulassen" **EIN** |
| D (Datum) | **„Datum"** |
| Z (Zahl) | **„Text"** → „Einschränkungen" → „Zahl" |
| Anlagenreferenz | **„Text"** (NICHT „Datei-Upload" — siehe `README.md` Abschnitt H) |

**Wichtig:** Die Auswahloptionen in Forms zeigen die **deutsche Beschriftung** aus dem Fragenkatalog (Mandantensicht), nicht den internen Code (z. B. „täglich", nicht `FREQ_DAILY`). Der Flow übersetzt die Forms-Antwort später in den Code (siehe `README.md` Abschnitt C und G).

Pflicht-/Bedingt-Logik: laut `README.md` (Pflichtbedingung aus `feldkatalog.json`) den Schalter „Erforderlich" nur bei `unbedingt` aktivieren.

## C. Branching (Verzweigung)

Identische Mechanik wie im AO-Modul. Zusätzlich für dieses Modul:

- **Formular 2 (Tätigkeitsblatt):** Frage „Bereich" (P09-Auswahl, am Anfang wiederholt) löst eine Verzweigung zur passenden **Handlungstabelle** aus (siehe Fragenkatalog, Abschnitt 2). Je Bereich eine eigene Auswahl-Frage mit den zugehörigen Handlungen aus der Tabelle; nur die zum gewählten Bereich passende Frage bleibt sichtbar, alle anderen werden übersprungen.
- **Formular 3 (Entscheidungs-/Vertrags-/Kontrollblatt):** Einstiegsfrage „Worum geht es?" (Entscheidung / Vertragsverhandlung / Aufsicht-Kontrolle-Schulung) verzweigt zu den E-, V- bzw. K-Fragenblöcken.
- **Formular 6 (Arbeitsmittelblatt):** A01 „Art des Arbeitsmittels" verzweigt zu A05 (Fahrzeug), A06 (Smartphone/IT) bzw. A07 (Software).
- **Formular 7 (Kosten- und Belegblatt):** Einstiegsfrage „Kostenangabe oder Beleg/Beispiel nachreichen?" verzweigt zu den C- bzw. N-Fragenblöcken; N05 (Abschlussangabe) erscheint unabhängig davon am Formularende.

## D. Freigabe „Jeder mit dem Link kann antworten"

Identische Schritte wie `DE/AO/sharepoint-forms/KLICKANLEITUNG-FORMS.md` Abschnitt D. **Keine** Datei-Upload-Fragen in diesen sieben Formularen (siehe `README.md` Abschnitt H) — daher ist die Anmeldepflicht-Problematik für dieses Modul durchgängig vermieden.

## E. Reihenfolge und Zeitaufwand

1. Formular 1 — Personenblatt (ca. 20 Min. je Person)
2. Formular 2 — Tätigkeitsblatt (ca. 25 Min. je Tätigkeit — Handlungstabelle sorgfältig nach Bereich verzweigen, 90 Handlungen gesamt)
3. Formular 5 — Raumblatt (ca. 20 Min. je Raum)
4. Formular 6 — Arbeitsmittelblatt (ca. 20 Min. je Gegenstand/Software)
5. Formular 3 — Entscheidungs-/Vertrags-/Kontrollblatt (ca. 20-25 Min. je Fall, abhängig vom gewählten Abschnitt E/V/K)
6. Formular 4 — Organisationsblatt (ca. 15 Min. je Zeitraum)
7. Formular 7 — Kosten- und Belegblatt (ca. 20-25 Min., inkl. N05-Abschlussangabe)

Gesamtaufwand grob 2,5-3 Stunden für das Grundgerüst aller sieben Formulare (ohne die je Person/Tätigkeit/Fall wiederholten Ausfüllungen selbst).

**Wichtig beim Eintragen der Handlungstabelle (Formular 2):** Alle 90 Handlungen aus der P09-Handlungstabelle (Fragenkatalog, Abschnitt 2) müssen **zeichengenau** wie dort angegeben eingetragen werden, gruppiert nach den zwölf Bereichen. Reihenfolge innerhalb eines Bereichs wie in der Tabelle.

## F. Nach Fertigstellung

- Jedes Formular per „Antworten" → „..." → „In Excel öffnen" einmal leer testen.
- Testdurchlauf mit Dummy-Erfassung gemäss `README.md` Abschnitt I.
- Power-Automate-Flows je Formular/Liste-Paar einrichten (`README.md` Abschnitt G), inkl. Code-Auflösung, `FormID+ResponseID`-Übernahmeschlüssel und `Eingang_Fehler`-Fallback.
- `InterneBewertungen`-Berechtigungsgruppe manuell nachtragen (Datenmodell, Abschnitt 5).
- `Eingang_Fehler` (geteilt mit dem AO-Modul) regelmässig sichten.
