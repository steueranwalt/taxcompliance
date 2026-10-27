# Klickanleitung: Microsoft-Forms-Formulare manuell anlegen (Version 3, Update 3 — fünf Blätter)

Diese Anleitung ergänzt [`README.md`](README.md) und übernimmt die allgemeine Klick-Mechanik aus [`DE/AO/sharepoint-forms/KLICKANLEITUNG-FORMS.md`](../../AO/sharepoint-forms/KLICKANLEITUNG-FORMS.md) (Abschnitte A-D dort). Die Fragentexte und Auswahlwerte stehen vollständig in [`../Fragenkatalog-Substanzpruefung-Holding-KG.md`](../Fragenkatalog-Substanzpruefung-Holding-KG.md) — **nur die Mandantensicht-Abschnitte eintragen, nicht die internen Hinweise.**

## A. Formular anlegen (einmalig pro Formular)

1. Browser öffnen, `forms.office.com` aufrufen, mit dem Kanzlei-Microsoft-Konto anmelden.
2. **„Neues Formular"** klicken. Titel z. B. „1 – Personenblatt – Substanzprüfung Holding-KG (V3)".
3. Erste Frage immer: „Erfassungsreferenz" (Text, Pflicht) — **nicht** die interne `ErfassungID`/Fall-ID; der Flow prüft diese Referenz als Plausibilitätsprüfung (siehe `README.md` Abschnitt D).
4. Unter **„Einstellungen"** (Zahnrad-Symbol oben rechts) → „Start- und Enddatum" das **Formular-Enddatum** nach Ende des jeweiligen Erhebungszeitraums eintragen (`README.md` Abschnitt D/I).

## B. Eine Frage hinzufügen

| Interner Antworttyp | Klick in Forms |
|---|---|
| T (Einzeiler) | **„Text"** → „Lange Antwort" **AUS** |
| T (mehrzeilig) | **„Text"** → „Lange Antwort" **EIN** |
| E (Einfachauswahl) | **„Auswahl"** |
| M (Mehrfachauswahl) | **„Auswahl"** → „Mehrere Antworten zulassen" **EIN** |
| D (Datum) | **„Datum"** |
| Z (Zahl) | **„Text"** → „Einschränkungen" → „Zahl" |
| Anlagenreferenz | **„Text"** (NICHT „Datei-Upload" — siehe `README.md` Abschnitt H) |

**Wichtig — H-Handlungen (Formular 1, Abschnitt 1.2):** Jede der 45 Handlungen wird als **eigene Auswahl-Frage** mit genau drei Optionen angelegt: „ausgeführt" / „nicht ausgeführt" / „nicht bekannt" — **nicht** als eine grosse Mehrfachauswahl-Liste. Je gewähltem Bereich aus S07 nur die zugehörigen 4-6 Handlungs-Einzelfragen einblenden (Verzweigung, siehe Abschnitt C).

**Wichtig — R26 (Formular 4):** Sechs **einzelne** Ja/Nein/nicht-bekannt-Fragen (eigener Zugang, Zugang ohne Anmeldung, fest zugewiesene Arbeitsplätze, eigene Ablage, abschliessbare Aufbewahrung, nur nach Buchung) — nicht als eine MultiChoice-Liste.

Die Auswahloptionen in Forms zeigen die **deutsche Beschriftung** (Mandantensicht); der Flow übersetzt später in den stabilen Code (siehe `README.md` Abschnitt C/G).

## C. Branching (Verzweigung)

Identische Mechanik wie im AO-Modul. Zusätzlich für dieses Modul:

- **Formular 1:** S07 (Bereichsauswahl) verzweigt zu den 4-8 Handlungs-Einzelfragen je gewähltem Bereich (Abschnitt 1.2). S05 ≠ "ja"/"bereits beendet" überspringt S06.
- **Formular 2:** D01 ≠ "keine" schaltet D02-D10 frei; V10 ≠ "keine" schaltet V11-V18 frei; K10 ≠ "keine Kontrollaufgaben" schaltet K11 frei; `bereich_code` = eigene Verwaltung/Beteiligungen schaltet G10-G15 frei.
- **Formular 3:** O01 = Homeoffice schaltet O07/O08 frei; O03 ≠ "nie" schaltet O04/O05 frei.
- **Formular 4:** R20 (Gateway) blendet nur die zu den gewählten Auskunftsbereichen passenden Unterabschnitte (5.1-5.3) ein; A20 steuert A26-A32 wie in `README.md` Abschnitt F beschrieben; C24 = ja/noch offen schaltet C25-C27 frei.

## D. Freigabe „Jeder mit dem Link kann antworten"

Identisch zu `DE/AO/sharepoint-forms/KLICKANLEITUNG-FORMS.md` Abschnitt D. Keine Datei-Upload-Fragen in diesen fünf Formularen.

## E. Reihenfolge und Zeitaufwand

1. Formular 1 — Personenblatt (ca. 20-30 Min. je Person, inkl. 45 Handlungs-Einzelfragen über Verzweigung)
2. Formular 2 — Aufgabenblatt (ca. 20-25 Min. je Aufgabe, abhängig von D/V/K/G-Verzweigungen)
3. Formular 3 — Arbeitsorganisation, Zeit und Ort (ca. 20 Min. je Person)
4. Formular 4 — Ressourcen und Kosten (ca. 15-20 Min. je Raum/Mittel/Kostenposition, rollenbezogen)
5. Formular 5 — Nachweise und Abschluss (ca. 15 Min.)

Gesamtaufwand grob 2-2,5 Stunden für das Grundgerüst aller fünf Formulare (ohne die je Person/Aufgabe wiederholten Ausfüllungen selbst).

## F. Nach Fertigstellung

- Jedes Formular per „Antworten" → „..." → „In Excel öffnen" einmal leer testen.
- Testdurchlauf mit Dummy-Erfassung gemäss `README.md` Abschnitt I.
- Power-Automate-Flows je Formular/Liste-Paar einrichten (`README.md` Abschnitt G), inkl. Code-Auflösung, `FormID+ResponseID`-Übernahmeschlüssel, Erfassungsreferenz-/Status-Prüfung, H-Handlungs-Spaltenexklusivitätsprüfung und `Eingang_Fehler`-Fallback.
- `InterneBewertungen_<Standort>`-Berechtigungen beim PnP-Skriptlauf über `-StandortGruppen`/`-GesamtGruppe` mit den tatsächlichen SharePoint-Gruppennamen setzen (Datenmodell, Abschnitt 6; `README.md` Abschnitt C2) — kein manuelles Nachtragen mehr nötig, sofern die Gruppennamen beim Lauf übergeben werden.
- `Eingang_Fehler` (geteilt mit dem AO-Modul) regelmässig sichten.
