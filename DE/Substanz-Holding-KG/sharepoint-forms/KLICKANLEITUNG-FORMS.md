# Klickanleitung: Microsoft-Forms-Formulare manuell anlegen (Substanzprüfung Holding-KG)

Diese Anleitung ergänzt [`README.md`](README.md), Abschnitt E, und übernimmt die allgemeine Mechanik unverändert aus [`DE/AO/sharepoint-forms/KLICKANLEITUNG-FORMS.md`](../../AO/sharepoint-forms/KLICKANLEITUNG-FORMS.md) (Abschnitte A-D dort). Hier wird sie kurz wiederholt und danach auf Formular 0 (Fallanlage) als vollständig ausformuliertes Muster angewendet; für die Formulare 1-11 gelten dieselben Klickschritte, angewendet auf die Fragenlisten in `README.md` Abschnitte E.1-E.11.

## A. Formular anlegen (einmalig pro Formular)

1. Browser öffnen, `forms.office.com` aufrufen, mit dem Kanzlei-Microsoft-Konto anmelden (dem Konto mit Zugriff auf die Zielsite, siehe `README.md` Abschnitt B).
2. Oben links **„Neues Formular"** klicken.
3. Titelfeld: Formulartitel eintragen (z. B. „1 – Personen – Substanzprüfung Holding-KG"). Im Beschreibungsfeld optional einen Hinweistext ergänzen, bei mehrfach ausfüllbaren Formularen zusätzlich: „Bitte für jede(n) [Person/Tätigkeit/...] eine eigene Antwort einreichen (Formular mehrfach ausfüllen)."
4. Formular wird automatisch fortlaufend gespeichert.

## B. Eine Frage hinzufügen (pro Frage wiederholen)

Identische Zuordnungstabelle wie im AO-Modul:

| Spaltentyp aus Datenmodell | Klick in Forms |
|---|---|
| Einzeiler Text | **„Text"** → Schalter „Lange Antwort" **AUS** lassen |
| Mehrzeiliger Text (Note) | **„Text"** → Schalter **„Lange Antwort"** aktivieren |
| Auswahl (Choice) | **„Auswahl"** |
| Ja/Nein (Boolean) | **„Auswahl"** mit genau 2 Optionen „Ja" / „Nein" |
| Datum (DateOnly) | **„Datum"** |
| Zahl (Number) | **„Text"** → unten **„Einschränkungen"** → **„Zahl"** wählen |
| Anhang / Datei-Upload | **„Datei-Upload"** |

Pflicht-/Bedingt-Logik, Auswahloptionen eintragen und Branching: identisch zu `DE/AO/sharepoint-forms/KLICKANLEITUNG-FORMS.md` Abschnitte B und C (Schritte 1:1 übertragbar, hier nicht wiederholt).

## C. Branching (Verzweigung) einrichten

Identische Mechanik wie im AO-Modul (`DE/AO/sharepoint-forms/KLICKANLEITUNG-FORMS.md` Abschnitt C): Branching funktioniert nur auf Auswahl-Fragen als Auslöser und wirkt nur vorwärts. Für die Mehrfachauslöser-Situation in Formular 10 (eine Auswahl-Frage „Kostenkategorie" mit vier sich ausschliessenden Folgefragen) gilt dieselbe Technik wie bei den BZSt2-Auswahlfragen im AO-Modul: pro Antwortoption auf die jeweils passende Folgefrage verzweigen, alle anderen Kategorie-Folgefragen überspringen.

## D. Freigabe „Jeder mit dem Link kann antworten" aktivieren

Identische Schritte wie `DE/AO/sharepoint-forms/KLICKANLEITUNG-FORMS.md` Abschnitt D. Für Formulare mit Datei-Upload (1, 3, 4, 11) gilt derselbe Hinweis zur Anmeldepflicht (siehe `README.md` Abschnitt E.11).

## E. Formular 0 — Substanzfall (Muster, vollständig ausformuliert)

Titel: „0 – Substanzfall – Substanzprüfung Holding-KG"

| # | Frage | Typ (Klick gemäss B) | Optionen (bei Auswahl) | Pflicht/Bedingt | Branching (gemäss C) |
|---|---|---|---|---|---|
| 1 | Name der Holding-KG | Text (kurz) | — | Pflicht | — |
| 2 | Steuernummer/Identifikationsnummer der Holding-KG (falls bekannt) | Text (kurz) | — | Nein | — |
| 3 | Bezug: Fall der steuerlichen Erfassung (DE/AO, Fall-ID, falls vorhanden) | Text (kurz) | — | Nein | — |
| 4 | Prüfungszeitraum — von | Datum | — | Nein | — |
| 5 | Prüfungszeitraum — bis | Datum | — | Nein | — |
| 6 | Mandatsverantwortliche Person (Kanzlei) | Text (kurz) | — | Nein | — |
| 7 | Persönliche Bearbeitungsnotiz | Text (lang) | — | Nein | — |

Am Ende des Formulars (Abschnitt → nur Beschreibungstext ohne Frage) folgende Routing-Hinweise als Fliesstext einfügen, mit den Links aus den bereits angelegten Formularen 1-11 (`README.md` Abschnitt E.12):

> „Vielen Dank. Bitte fahren Sie mit folgenden Formularen fort: [Linkliste]. Formulare 4 (Geschäftsräume), 5/6 (Assets) und 9 (Geschäftsvorgänge) nur ausfüllen, soweit einschlägig; Formular 9 mit drei bis fünf Beispielen."

**Zugangscode nicht vergessen:** Formular 0 fragt keinen Zugangscode ab — der fallanlegende Flow (bzw. die Kanzleiperson) setzt `access_code` direkt in `SH0_Substanzfall`, sobald das Element angelegt ist, und baut die Links zu F1-F11 mit `case_id` **und** `access_code` auf (`README.md` Abschnitt D).

Danach: Schritte A-D für die Formulare 1-11 identisch wiederholen, mit den Fragenlisten aus `README.md` Abschnitte E.1-E.11. Jedes dieser Formulare beginnt zusätzlich mit „Fall-ID" (Text, Pflicht) und „Zugangscode" (Text, Pflicht) als Fragen 1 und 2 (in der README-Nummerierung bereits so geführt).

## F. Reihenfolge und Zeitaufwand

Empfohlene Bearbeitungsreihenfolge (Formular 0 zuerst als Routing-Ausgangspunkt, danach stammdatennah vor verknüpfungslastig):

1. Formular 0 (7 Fragen, ca. 10 Min.)
2. Formular 5 — Assets Stammdaten (7 Fragen, ca. 10 Min.)
3. Formular 4 — Geschäftsräume (21 Fragen inkl. Branching, ca. 20 Min.)
4. Formular 1 — Personen (18 Fragen, ca. 20 Min.)
5. Formular 11 — Belege (6 Fragen, ca. 10 Min.)
6. Formular 6 — Asset-Nutzung (10 Fragen, ca. 15 Min.)
7. Formular 2 — Entscheidungsprozesse (11 Fragen inkl. Branching, ca. 15 Min.)
8. Formular 7 — Tagesgeschäft/Präsenz (14 Fragen inkl. Branching, ca. 15 Min.)
9. Formular 3 — Managementtätigkeiten (13 Fragen inkl. Branching, ca. 20 Min. — wichtigstes Formular, 22-Werte-Auswahlliste sorgfältig eintragen)
10. Formular 8 — Zusammenarbeit Beteiligungen (14 Fragen, ca. 15 Min.)
11. Formular 9 — Geschäftsvorgänge (12 Fragen, ca. 15 Min.)
12. Formular 10 — Kosten (14 Fragen inkl. Mehrfach-Branching, ca. 15 Min.)

Gesamtaufwand grob 3-3,5 Stunden für alle 12 Formulare inkl. Testklicks in der Vorschau (vergleichbar mit dem AO-Modul).

**Wichtig beim Eintragen der Auswahllisten:** Die 22 Managementtätigkeiten (Formulare 3, 6, 8), die 12 Entscheidungsarten (Formular 2) und die 12 Asset-Kategorien (Formular 5) müssen **zeichengenau** wie im Datenmodell (Abschnitt 3) bzw. im Skript (`New-SubstanzHoldingKGListen.ps1`) eingetragen werden — inklusive Umlauten (z. B. „Geschäftsführung / Unterstützung der Geschäftsleitung", „Büromöbel") und ohne „ß" (Schweizer Schreibweise). Abweichende Schreibweisen führen dazu, dass der Flow die Forms-Antwort nicht auf den passenden SharePoint-Choice-Wert abbilden kann.

## G. Nach Fertigstellung

- Jedes Formular per „Antworten" → „..." → „In Excel öffnen" einmal leer testen, um die Spaltenreihenfolge gegen die Ziel-SharePoint-Liste zu prüfen.
- Testdurchlauf mit Dummy-Fall gemäss `README.md` Abschnitt F.4, vor Versand an echte Mandanten/Mitarbeitende der Holding-KG.
- Power-Automate-Flows je Formular/Liste-Paar einrichten (`README.md` Abschnitt F.3), inkl. `case_id`/`access_code`-Prüfung und `Eingang_Fehler`-Fallback (`README.md` Abschnitt D1/G).
- Für Formular 10 zusätzlich die Prüfregel zu den gegenseitig ausschliessenden Kostenkategorie-Feldern umsetzen (`README.md` Abschnitt G, Punkt 3).
- `display_label`- und `_ref`-Lookup-Auflösung je Liste einrichten (`README.md` Abschnitt F, Punkte 6-7).
- `Eingang_Fehler` (geteilt mit dem AO-Modul) regelmässig sichten.
