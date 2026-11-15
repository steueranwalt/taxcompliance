# Klickanleitung: Microsoft-Forms-Formulare EasyGov-Gründung

Ergänzt [`README.md`](README.md). Die Klickmechanik in [forms.office.com](https://forms.office.com) ist identisch mit [`DE/AO/sharepoint-forms/KLICKANLEITUNG-FORMS.md`](../../../DE/AO/sharepoint-forms/KLICKANLEITUNG-FORMS.md) Abschnitte A–D (Formular anlegen, Frage hinzufügen, Branching, Freigabe). Hier nur die EasyGov-Fragenlisten.

Titelpräfix: «EasyGov Gründung CH».

## Formular 0 — Fallsteuerung (Kanzlei)

| # | Frage | Typ | Optionen | Pflicht/Bedingt | Branching |
|---|---|---|---|---|---|
| 1 | Fall-ID | Text kurz | — | Pflicht | — |
| 2 | Rechtsform | Auswahl | siehe `wertelisten/rechtsformen.json` | Pflicht | steuert Formulare 3/4 |
| 3 | Datum ab | Datum | — | Pflicht | — |
| 4 | Umsatzangaben | Auswahl | weniger als CHF 100'000; CHF 100'000 oder mehr | Pflicht | — |
| 5 | Total Angestellte | Zahl | — | Pflicht | — |
| 6 | Beschäftigungsgrad | Auswahl | siehe `beschaeftigungsgrad.json` | Pflicht | — |
| 7 | Bereits früher Anmeldungen? | Auswahl | Nein, bisher noch nicht; Ja, und zwar | Pflicht | Ja → Frage 8 |
| 8 | Ja, und zwar | Auswahl (mehrere) | HR; MWST; Ausgleichskasse; UVG | Bedingt | — |
| 9 | Digitale Signatur | Auswahl | elektronische Gründung; Papierweg | Bedingt GmbH/AG | — |
| 10 | Resultat HR/MWST/AHV/UVG | Auswahl je Feld | zwingend; freiwillig; nach HR-Eintrag | Kanzleifeld, nicht Pflicht | nicht an Mandanten |

## Formulare 1–8

Spalten und Labels aus `felder.json` (gruppiert nach `sharepoint_liste`). Pflicht nur bei `sharepoint_required`. Bedingte Felder: Schalter «Erforderlich» aus, Verzweigung nach Abschnitt C der DE-Klickanleitung.

Wiederholbare Personen und Anteile: das Forms-Formular nimmt *einen* Datensatz; weitere über denselben Link mit gleicher Fall-ID oder direkt in der SharePoint-Liste.

Datei-Upload nur in Formular 8; EasyGov selbst lädt in der Gründung nichts hoch. Papierwege (KlG/KmG, EU ohne QES) als Dokumenttyp merken, Original bleibt postalisch.
