# Klickanleitung: Microsoft-Forms-Formulare manuell anlegen

Diese Anleitung ergänzt [`README.md`](README.md), Abschnitt E. Sie beschreibt die konkreten Klicks in [forms.office.com](https://forms.office.com), damit jede Person ohne Vorkenntnisse die 9 Formulare selbst zusammenstellen kann. Die Mechanik (A–D) wird einmal erklärt; danach folgt für jedes Formular nur noch die Fragenliste mit Typ, Pflicht/Bedingt und ggf. Branching-Hinweis — die allgemeinen Klickschritte aus A–D gelten dafür jeweils sinngemäß.

## A. Formular anlegen (einmalig pro Formular)

1. Browser öffnen, `forms.office.com` aufrufen, mit dem Kanzlei-Microsoft-Konto anmelden (dem Konto, das auch Zugriff auf die Zielsite `steueranwaltskanzlei` hat).
2. Oben links **„Neues Formular"** klicken.
3. Auf der Titelseite:
   - Titelfeld anklicken, Formulartitel eintragen (z. B. „0 – Fallsteuerung – Steuerliche Erfassung DE / Auslandsbezug").
   - Darunter im Beschreibungsfeld optional einen kurzen Hinweistext einfügen (z. B. „Bitte alle Fragen vollständig beantworten. Bei Rückfragen: [Kanzlei-Kontakt]").
4. Formular wird automatisch fortlaufend gespeichert — kein expliziter „Speichern"-Button nötig.

## B. Eine Frage hinzufügen (pro Frage wiederholen)

1. Im Formular auf **„+ Neu hinzufügen"** klicken (erscheint unten in der Fragenliste).
2. Im Dropdown den passenden Fragetyp wählen — Zuordnung zur Spaltenliste:

   | Spaltentyp aus README | Klick in Forms |
   |---|---|
   | Einzeiler Text | **„Text"** → Schalter „Lange Antwort" **AUS** lassen |
   | Mehrzeiliger Text | **„Text"** → Schalter **„Lange Antwort"** aktivieren |
   | Auswahl (Choice) | **„Auswahl"** |
   | Ja/Nein | **„Auswahl"** mit genau 2 Optionen „Ja" / „Nein" |
   | Datum / Datum und Uhrzeit | **„Datum"** |
   | Zahl | **„Text"** → unten **„Einschränkungen"** → **„Zahl"** wählen |
   | Anhang | **„Datei-Upload"** |

3. Fragetext in das Feld **„Frage"** eintragen (Wortlaut aus der jeweiligen Fragenliste unten).
4. Bei **Auswahl**-Fragen: pro Option auf **„Option hinzufügen"** klicken und den Text eintragen (Reihenfolge wie in der Choice-Liste unten).
5. Ist die Frage laut Tabelle **Pflicht** (nicht „Bedingt"): rechts unten bei der Frage den Schalter **„Erforderlich"** aktivieren (Toggle wird blau).
6. Ist die Frage **Bedingt**: Schalter „Erforderlich" **AUS** lassen — die Pflicht wird stattdessen über Branching gesteuert (siehe C) bzw. bleibt bei „Bedingt ohne harte Branching-Möglichkeit" als Hinweistext in der Frage stehen (bei Textfeldern ohne exakte Bedingungsprüfung, siehe README-Anmerkungen).
7. Für Datei-Upload-Fragen erscheint automatisch der Hinweis „Antwortende müssen sich anmelden" — das ist die in der README (Abschnitt E.8) beschriebene Einschränkung.

## C. Branching (Verzweigung) einrichten

Branching funktioniert in Forms nur auf **Auswahl**-Fragen (Choice/Ja-Nein) als Auslöser und wirkt, indem eine spätere Frage bei einer bestimmten Antwort übersprungen oder angezeigt wird.

1. Bei der auslösenden Auswahl-Frage (z. B. „Bereits steuerlich erfasst") rechts oben auf die drei Punkte **„..."** klicken → **„Verzweigung hinzufügen"**.
2. Es erscheint pro Antwortoption ein Dropdown „Weiter zu". Standardmässig zeigt jede Option auf „Nächste Frage".
3. Bei der Option, die die Folgefrage **auslösen** soll (z. B. „Ja" bei „Bereits steuerlich erfasst"): Dropdown auf **„Nächste Frage"** lassen (die Folgefrage – z. B. „Bestehende Steuernummer" – bleibt direkt danach sichtbar).
4. Bei der Option, die die Folgefrage **überspringen** soll (z. B. „Nein"): im Dropdown die **übernächste** Frage auswählen (die Frage, die *nach* der zu überspringenden Frage kommt) — dadurch wird die dazwischenliegende Frage bei dieser Antwort nicht angezeigt.
5. Wichtig: Verzweigungen wirken nur **vorwärts** und nur auf **eine** auslösende Frage gleichzeitig. Bei Bedingungen, die von **mehreren** Fragen abhängen (z. B. „Frage 2 = Person UND Formulartyp = Einzelunternehmen"), gibt es zwei Möglichkeiten:
   - **Einfachste Lösung:** nur nach der jeweils relevantesten Einzelbedingung verzweigen und den Rest im Fragetext als Hinweis ergänzen (z. B. „Nur ausfüllen, falls Einzelunternehmen").
   - **Genauere Lösung:** die zweite Bedingung als eigene, vorgeschaltete Auswahlfrage im selben Formular wiederholen (in der Fragenliste unten mit „Kontextfrage wiederholen" vermerkt) und danach verzweigen.
6. Test: über **„Vorschau"** (oben rechts, Symbol Auge/Handy) die Antwortpfade durchklicken und prüfen, ob die Bedingt-Felder korrekt ein-/ausgeblendet werden.

## D. Freigabe „Jeder mit dem Link kann antworten" aktivieren

1. Oben rechts im Formular auf **„..."** (drei Punkte) klicken → oder direkt auf den Button **„Freigeben"**.
2. Im Freigabe-Dialog unter **„Wer kann antworten"**: **„Jeder mit dem Link kann antworten"** auswählen (nicht „Nur Personen in meiner Organisation").
3. Bei Formularen mit Datei-Upload (Formular 8): Hinweis beachten — trotz dieser Einstellung verlangt der Datei-Upload-Fragetyp vom Antwortenden ein Microsoft-Konto (siehe README Abschnitt E.8). Für dieses Formular ggf. den Datei-Upload weglassen und stattdessen nur Metadaten abfragen, wenn Mandanten ohne Konto antworten sollen.
4. Link kopieren (**„Kopieren"**-Symbol neben dem generierten Link) — dieser Link geht später an die Mandanten bzw. wird in Formular 0 als Routing-Linkliste eingebettet (README Abschnitt E.9).
5. Optional: QR-Code-Symbol für Druck/Einbettung nutzen.

## E. Formular 0 — Fallsteuerung (Muster, vollständig ausformuliert)

Titel: „0 – Fallsteuerung – Steuerliche Erfassung DE / Auslandsbezug"

| # | Frage | Typ (Klick gemäss B) | Optionen (bei Auswahl) | Pflicht/Bedingt | Branching (gemäss C) |
|---|---|---|---|---|---|
| 1 | Richtung | Auswahl | Inbound; Outbound | Pflicht | Löst Sichtbarkeit von Frage 7 aus |
| 2 | Rechtsform / Formulartyp | Auswahl | Einzelunternehmen; Kapitalgesellschaft oder Genossenschaft; Personengesellschaft oder -gemeinschaft; Körperschaft nach ausländischem Recht; BZSt2-Mitteilung | Pflicht | — |
| 3 | Bereits steuerlich erfasst | Auswahl | Ja; Nein | Pflicht | Bei „Ja" → Frage 4 sichtbar; bei „Nein" → Frage 4 überspringen (Verzweigung auf Frage 5) |
| 4 | Bestehende Steuernummer | Text (kurz) | — | Bedingt (nur bei Frage 3 = Ja) | Ziel der Verzweigung aus Frage 3 |
| 5 | Land des Finanzamts | Text (kurz) | — | Pflicht | — |
| 6 | Zuständiges Finanzamt | Text (kurz) | — | Pflicht | — |
| 7 | Zielmeldung (BZSt2-Sachverhalt) | Auswahl | Betriebe/Betriebsstätten; PersG-Beteiligung; KapG-Beteiligung; Drittstaat-Beherrschung; Negativmeldung | Bedingt (nur bei Frage 1 = Outbound) | Bei Frage 1 = Inbound → diese Frage in der Verzweigung von Frage 1 überspringen |
| 8 | Persönliche Bearbeitungsnotiz | Text (lang) | — | Nein | — |

Am Ende des Formulars (Textabschnitt statt Frage: über **„+ Neu hinzufügen"** → **„Abschnitt"**, dort nur Beschreibungstext ohne Frage einfügen) folgende Routing-Hinweise als Fliesstext einfügen, mit den Links aus den bereits angelegten Formularen 1–8 (Abschnitt E.9 der README):

> „Vielen Dank. Bitte fahren Sie je nach Ihrer Auswahl mit folgenden Formularen fort: [Linkliste gemäss README Abschnitt E.9]."

Danach: Schritte A–D für die Formulare 1–8 identisch wiederholen, mit den Fragenlisten aus `README.md` Abschnitte E.1–E.8. Die dortigen Zeilen sind bereits im selben Format (Frage / Typ / Pflicht / Branching-Bedingung) gehalten und lassen sich 1:1 in die Tabellenspalten dieser Klickanleitung übertragen.

## F. Reihenfolge und Zeitaufwand

Empfohlene Bearbeitungsreihenfolge (steigende Komplexität, Formular 0 zuerst als Routing-Ausgangspunkt):

1. Formular 0 (8 Fragen, ca. 10 Min.)
2. Formular 1 (31 Fragen, ca. 25 Min.)
3. Formular 8 (5 Fragen, ca. 5 Min. — Datei-Upload-Hinweis beachten)
4. Formular 3, 5, 6 (12–17 Fragen, je ca. 15 Min.)
5. Formular 2, 4, 7 (16–20 Fragen, je ca. 20 Min., meiste Branching-Fälle)

Gesamtaufwand grob 2–2,5 Stunden für alle 9 Formulare inkl. Testklicks in der Vorschau.

## G. Nach Fertigstellung

- Jedes Formular per **„Antworten" → „..." → „In Excel öffnen"** einmal leer testen, um zu prüfen, dass die Spaltenreihenfolge zur Ziel-SharePoint-Liste passt.
- Testdurchlauf mit Dummy-Daten gemäss README Abschnitt F.4, bevor echte Mandanten die Links erhalten.
- Optional: Power-Automate-Flow „Bei neuer Forms-Antwort → Element in SharePoint-Liste erstellen" je Formular/Liste-Paar (README Abschnitt F.3) einrichten, um die manuelle Übertragung der Antworten zu vermeiden.
