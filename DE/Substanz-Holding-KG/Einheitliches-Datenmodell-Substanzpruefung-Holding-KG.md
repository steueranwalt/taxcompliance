# Einheitliches Datenmodell: Datenerhebung zur Substanzprüfung einer Holding-KG

**Stand:** 27.10.2026

**Fachliche Vorgabe:** Nils Obenhaus, 27.10.2026 ("Erfassungsbogen Substanz und Managementtätigkeit Holding-KG").

**Zweck:** strukturierte Datenerhebung zur **tatsächlichen Substanz** einer Holding-KG und zur **tatsächlich ausgeübten Managementtätigkeit**, als Nachweisgrundlage für die steuerliche Anerkennung der Holding-KG (z. B. gegen den Vorwurf einer funktionslosen Zwischenholding, Geschäftsleitungsort-/Betriebsstättenfragen, Missbrauchsprüfung).

**Ausdrücklich nicht Gegenstand:** die Konzernstruktur als solche (Beteiligungsquoten, Organigramm, Gesellschafterkette). Wo eine Beteiligungsgesellschaft benannt werden muss, wird sie als Bezug (Lookup/Freitext) referenziert, nicht neu strukturell erhoben — siehe Abschnitt "Wiederverwendung".

**Leitlogik** (durchgehend aus der Vorgabe übernommen): *Was gibt es? → Wer nutzt es? → Wann? → Wo? → Wie? → Wofür? → Wer macht was? → Wie lässt sich das belegen?*

**Verwandtes Vorbild:** [`DE/AO/sharepoint-forms/`](../AO/sharepoint-forms/README.md) (PnP-Skript, Datenmodell, Forms-Klickanleitung für die steuerliche Erfassung DE/Auslandsbezug). Dieses Modul übernimmt dessen Konventionen (Namensgebung, Idempotenz, Spaltentypen, Flow-Muster, Umlautschreibweise) und nutzt zwei seiner Listen mit, siehe Abschnitt "Wiederverwendung".

**Rollen der Dokumente in `DE/Substanz-Holding-KG/`:**

| Dokument | Rolle |
|---|---|
| dieses Datenmodell | Kern-Datenmodell, Listenkatalog, Abdeckungstabelle, Wiederverwendungsentscheidungen, Leitfragen-Nachweis |
| [`sharepoint-forms/README.md`](sharepoint-forms/README.md) | SharePoint-Listen- und Forms-Architektur, Flow-Zuordnung, Prüfregeln |
| [`sharepoint-forms/KLICKANLEITUNG-FORMS.md`](sharepoint-forms/KLICKANLEITUNG-FORMS.md) | Klickanleitung für die manuelle Forms-Erstellung |
| [`sharepoint-forms/New-SubstanzHoldingKGListen.ps1`](sharepoint-forms/New-SubstanzHoldingKGListen.ps1) | idempotentes PnP-PowerShell-Skript, legt Listen SH0-SH11 an |

## 1. Kern-Datenmodell

Vier wiederkehrende Kerndatensätze, miteinander verknüpft (wörtlich aus der Vorgabe):

| Kerndatensatz | Liste | Rolle |
|---|---|---|
| **Person** | `SH1_Personen` | wer ist für die Holding-KG tätig |
| **Tätigkeit** | `SH3_Managementtaetigkeiten` | was wird gemacht (22 Managementtätigkeiten, einheitliche Unterstruktur) |
| **Ort** | `SH4_Orte` | wo (Geschäftsraum/Bereich) |
| **Asset** | `SH5_Assets` + `SH6_Asset_Nutzung` | womit (Arbeitsmittel + deren Nutzung) |

**Verknüpfung (n:m):** `SH3_Managementtaetigkeiten` ist die zentrale Verknüpfungsliste des Modells. Jede Zeile verbindet eine Tätigkeit über Lookup-Spalten mit genau einer Person (`handled_by_ref`), optional einer Beteiligungsgesellschaft (`participation_ref`, wiederverwendet aus der steuerlichen Erfassung) und optional einem Ort (`location_ref`). Sind mehrere Personen/Orte an derselben Tätigkeit beteiligt, entstehen mehrere Zeilen mit demselben `activity_type` — das ist die n:m-Auflösung "Person-Tätigkeit" aus dem Auftrag, realisiert als Verknüpfungsliste statt als Mehrfach-Lookup (bessere Auswertbarkeit in Power Automate/Forms, konsistent mit dem AO-Vorbild, das ebenfalls keine Mehrfach-Lookups verwendet).

Analog für Assets: `SH6_Asset_Nutzung` ist die im Auftrag ausdrücklich geforderte Verknüpfungsliste **Asset → Standort → Nutzer → Tätigkeit → Nutzungsumfang** (je Zeile eine Nutzungsinstanz eines Assets).

```
Person (SH1) ──┐
               ├─ handled_by_ref ──┐
Ort (SH4) ─────┤                   │
               ├─ location_ref ────┼──► Tätigkeit (SH3)  ──► Beteiligungsgesellschaft
Asset (SH5) ───┤                   │       (participation_ref, Lookup auf
               ├─ asset_ref ───────┘        4_Beteiligte_und_Quoten, DE/AO)
               └─ user_ref/location_ref ──► Asset-Nutzung (SH6)
```

Alle Fachlisten hängen zusätzlich per Pflicht-Lookup `case_id` (Löschverhalten `Restrict`) an der Fallsteuerung `SH0_Substanzfall` — ein Substanzfall kann nicht gelöscht werden, solange Folgedatensätze existieren (identisches Muster zu `0_Fallsteuerung` im AO-Modell).

### 1.1 Technisches Muster: Referenzen auf Person/Ort/Asset/Beteiligung

Microsoft Forms kann keine Live-Lookups auf SharePoint-Listenzeilen anzeigen (dieselbe Einschränkung wie im AO-Modell, dort dokumentiert in `DE/AO/sharepoint-forms/README.md` Abschnitt E, Zeile "Nachschlagefeld (Lookup)"). Jede Spalte, die im Kern-Datenmodell auf `SH1_Personen`, `SH4_Orte`, `SH5_Assets` oder `4_Beteiligte_und_Quoten` verweist, besteht deshalb modulweit aus **zwei Spalten**:

- `<feld>_text` — die eigentliche Forms-Frage, Freitext (Name/Bezeichnung, wie in der Ursprungsliste erfasst). Diese Spalte trägt die Vorgabe-Frage.
- `<feld>_ref` — SharePoint-Lookup-Spalte auf die Zielliste (`ShowField = display_label`), **kein Forms-Feld**. Wird nach Elementanlage manuell oder durch einen erweiterten Power-Automate-Flow aus `<feld>_text` aufgelöst (identisches Muster zu `related_object_text`/`related_person`/`related_participation`/`related_site` in `8_Unterlagen`, DE/AO).

Diese Zweiteilung ist in der Abdeckungstabelle unten so vermerkt: die Vorgabe-Frage ist der `_text` Spalte zugeordnet, die `_ref`-Spalte ist eine abgeleitete Normalisierung ohne eigene Forms-Frage.

## 2. Listenübersicht

| # | Liste | Formular | Neu/Wiederverwendet | Spalten (ohne `Title`) | Vorgabe-Abschnitt |
|---|---|---|---|---|---|
| SH0 | `SH0_Substanzfall` | F0 (intern) | neu | 10 | Fallsteuerung (kein eigener Vorgabe-Abschnitt) |
| SH1 | `SH1_Personen` | F1 | neu | 20 | 1. Personen |
| SH2 | `SH2_Entscheidungsprozesse` | F2 | neu | 15 | 3. Entscheidungen |
| SH3 | `SH3_Managementtaetigkeiten` | F3 | neu | 17 | 2. Managementtätigkeiten |
| SH4 | `SH4_Orte` | F4 | neu | 22 | 4. Geschäftsräume |
| SH5 | `SH5_Assets` | F5 | neu | 8 | 5. Arbeitsplätze und Sachmittel (Stammdaten) |
| SH6 | `SH6_Asset_Nutzung` | F6 | neu | 13 | 5. Arbeitsplätze und Sachmittel (Nutzung) |
| SH7 | `SH7_Tagesgeschaeft_Praesenz` | F7 | neu | 15 | 6. Tagesgeschäft/Präsenz |
| SH8 | `SH8_Zusammenarbeit_Beteiligungen` | F8 | neu | 17 | 7. Zusammenarbeit Beteiligungsgesellschaften |
| SH9 | `SH9_Geschaeftsvorgaenge` | F9 | neu | 16 | 8. Konkrete Geschäftsvorgänge |
| SH10 | `SH10_Kosten` | F10 | neu | 17 | 9. Kosten |
| SH11 | `SH11_Belege` | F11 | neu | 11 | Belegfragen, Querschnitt (Punkt 5 des Auftrags) |
| — | `Eingang_Fehler` | — (kein Formular) | **wiederverwendet** (DE/AO) | unverändert | Fehlerprotokoll Formularübernahme |
| — | `4_Beteiligte_und_Quoten` | — (kein Formular) | **wiederverwendet** (DE/AO) | unverändert | Lookup-Ziel "Beteiligungsgesellschaft" |
| — | `3_Personen_und_Vertretung`, `5_Betriebsstaetten` | — (kein Formular) | **nur als optionaler Cross-Reference-Lookup** (DE/AO) | unverändert | siehe Abschnitt "Wiederverwendung" |

**Gesamt: 12 neue Listen, 181 neue Spalten, 11 Formulare für Mandanten/Kanzlei-Erfassung + 1 internes Formular (F0) = 12 Formulare.** Keine neue Liste dupliziert eine bestehende AO-Liste; die Wiederverwendungsprüfung in Abschnitt 4 begründet jede Entscheidung einzeln.

## 3. Listen im Detail (Felder, Typen, Herkunft je Frage)

Legende: **P** = Pflicht (`-Required` im Skript), **B** = bedingt/optional, **Lookup\*** = Lookup-Spalte ohne eigene Forms-Frage (siehe Abschnitt 1.1).

### 3.1 `SH0_Substanzfall` (Formular 0, intern — Fallsteuerung)

Kein eigener Vorgabe-Abschnitt; Analogon zu `0_Fallsteuerung` (DE/AO), aber eigenständige Liste (Begründung: Abschnitt 4).

| Spalte | Typ | Pflicht | Bedeutung |
|---|---|---|---|
| `case_id` | Text, indiziert, eindeutig | P | Fall-ID Substanzprüfung, Format empfohlen `SH-JJJJ-NNNN` |
| `access_code` | Text, indiziert, eindeutig | B | Zugangscode Mandantenprüfung (Muster wie `0_Fallsteuerung.access_code`) |
| `holding_name` | Text | P | Name der Holding-KG |
| `holding_tax_number` | Text | B | Steuernummer/IdNr. der Holding-KG, falls bekannt |
| `related_erfassung_case` | Lookup\* → `0_Fallsteuerung.case_id` | B | Bezug auf vorhandenen AO-Erfassungsfall (ermöglicht Wiederverwendung von `4_Beteiligte_und_Quoten`) |
| `review_period_from` / `review_period_to` | DateOnly | B | Prüfungszeitraum |
| `engagement_contact` | Text | B | mandatsverantwortliche Person (Kanzlei) |
| `processing_note` | Note | B | Bearbeitungsnotiz |
| `case_status` | Choice (offen / in Bearbeitung / vollständig / ausgewertet) | P | Bearbeitungsstatus |

### 3.2 `SH1_Personen` (Formular 1) — Vorgabe Abschnitt 1

| Spalte | Typ | Pflicht | Vorgabe-Frage |
|---|---|---|---|
| `case_id` | Lookup → SH0 | P | (Fallzuordnung) |
| `person_name` | Text | P | Name |
| `function_title` | Text | P | Funktion / Stellenbezeichnung |
| `employer_company_text` | Text | P | Bei welcher Gesellschaft angestellt oder vertraglich gebunden? |
| `employer_participation_ref` | Lookup\* → `4_Beteiligte_und_Quoten` | B | (Auflösung von `employer_company_text`, kein eigener Forms-Schritt) |
| `vertretung_ref` | Lookup\* → `3_Personen_und_Vertretung` | B | Zusatzfeld, Cross-Reference zur Wiederverwendung (nicht aus Vorgabe-Frage) |
| `actual_tasks` | Note | P | Welche Aufgaben übernimmt die Person tatsächlich für die Holding-KG? |
| `tasks_since` | DateOnly | B | Seit wann? |
| `work_frequency` | Choice (Häufigkeitsskala) | P | Wie häufig arbeitet sie für die Holding-KG? |
| `work_time_share` | Text | B | Wie viel Arbeitszeit entfällt ungefähr auf Aufgaben der Holding-KG? |
| `work_locations` | Note | B | An welchen Orten führt die Person diese Aufgaben aus? |
| `office_presence_frequency` | Choice (Häufigkeitsskala) | B | Wie häufig arbeitet die Person in den Geschäftsräumen der Holding-KG? |
| `decisions_own` | Note | B | Welche Entscheidungen trifft die Person selbst? |
| `decisions_prepared_only` | Note | B | Welche Entscheidungen bereitet sie nur vor? |
| `signing_authority` | Note | B | Welche Verträge oder sonstigen Unterlagen darf sie unterschreiben? |
| `staff_or_vendors_managed` | Note | B | Welche Mitarbeiter oder Dienstleister steuert sie? |
| `tools_used` | Note | B | Welche Arbeitsmittel nutzt sie? (Freitext-Zusammenfassung; strukturiert in `SH6_Asset_Nutzung.user_ref`) |
| `typical_week_description` | Note | P | Offene Frage: typische Arbeitswoche/Monat |
| `evidence_note` | Note | B | Belegfrage (Punkt 5): Hinweis Datei-Upload/Dokumentbibliothek |
| `display_label` | Text | B | kein Forms-Feld, Lookup-Anzeigefeld (Flow befüllt nach Anlage) |

**Häufigkeitsskala** (modulweit einheitlich verwendet, wörtlich aus Frage "Wie häufig arbeitet sie für die Holding-KG?"): `täglich`, `mehrmals pro Woche`, `wöchentlich`, `monatlich`, `nur bei Bedarf`.

### 3.3 `SH3_Managementtaetigkeiten` (Formular 3) — Vorgabe Abschnitt 2

22 Tätigkeiten als Choice-Katalog (`activity_type`), **einheitliche Unterstruktur** je Zeile, identisch zur Vorgabe-Unterstruktur:

> "Wird die Aufgabe von der Holding-KG tatsächlich wahrgenommen? Wer bearbeitet sie? Was wird konkret gemacht? Wie häufig? Für welche Beteiligungsgesellschaft? Wo wird sie ausgeübt? Welche Unterlagen entstehen? Wer trifft die abschliessende Entscheidung?"

| Spalte | Typ | Pflicht | Vorgabe-Frage |
|---|---|---|---|
| `case_id` | Lookup → SH0 | P | (Fallzuordnung) |
| `activity_type` | Choice (22 Werte) | P | Tätigkeit (Katalog, siehe unten) |
| `other_activity_description` | Text | B | Bezeichnung, falls "sonstige Managementaufgaben" |
| `actually_performed` | Boolean | P | Wird die Aufgabe von der Holding-KG tatsächlich wahrgenommen? |
| `handled_by_text` | Text | P | Wer bearbeitet sie? |
| `handled_by_ref` | Lookup\* → SH1 | B | (Auflösung von `handled_by_text`) |
| `description_concrete` | Note | P | Was wird konkret gemacht? |
| `frequency` | Choice (Häufigkeitsskala) | P | Wie häufig? |
| `participation_text` | Text | B | Für welche Beteiligungsgesellschaft? |
| `participation_ref` | Lookup\* → `4_Beteiligte_und_Quoten` | B | (Auflösung, wiederverwendete Liste) |
| `location_text` | Text | B | Wo wird sie ausgeübt? |
| `location_ref` | Lookup\* → SH4 | B | (Auflösung von `location_text`) |
| `documents_created` | Note | B | Welche Unterlagen entstehen? |
| `evidence_note` | Note | B | Belegfrage (Punkt 5) |
| `final_decision_text` | Text | B | Wer trifft die abschliessende Entscheidung? |
| `final_decision_ref` | Lookup\* → SH1 | B | (Auflösung von `final_decision_text`) |
| `display_label` | Text | B | kein Forms-Feld |

**22 Managementtätigkeiten** (Choice-Katalog `activity_type`, wörtlich aus der Vorgabe): Geschäftsplanung / Unternehmenssteuerung; Strategie und Unternehmensplanung; Budgetplanung; Controlling; Liquiditätsplanung; Finanzierung; Investitionen; Geschäftsführung / Unterstützung der Geschäftsleitung; Vertriebssteuerung; Marketing; Preisgestaltung; Einkauf; Personalplanung; Einstellungen und Vergütungen; Organisation; Rechnungswesen; Steuern; Recht; Compliance; IT; Produktentwicklung / F&E; sonstige Managementaufgaben.

Ziel laut Vorgabe: **Tätigkeitsprofil statt Funktionsliste** — jede Zeile ist eine konkrete, belegbare Ausübungsinstanz, nicht nur eine abstrakte Zuständigkeit.

### 3.4 `SH4_Orte` (Formular 4) — Vorgabe Abschnitt 4

| Spalte | Typ | Pflicht | Vorgabe-Frage |
|---|---|---|---|
| `case_id` | Lookup → SH0 | P | (Fallzuordnung) |
| `address` | Note | P | Anschrift |
| `room_number` | Text | B | Raum / Raumnummer |
| `size_sqm` | Number | B | Grösse |
| `room_type` | Choice (Büro/Besprechungsraum/Empfang/Lager/Home-Office/Sonstige) | B | Art des Raums (Kanzleientscheid: geschlossener Katalog statt Freitext, siehe Abschnitt 7) |
| `betriebsstaette_text` / `betriebsstaette_ref` | Text / Lookup\* → `5_Betriebsstaetten` | B | Zusatzfeld, Cross-Reference zur Wiederverwendung (nicht aus Vorgabe-Frage) |
| `used_by` | Note | B | Wer nutzt ihn? (Zusammenfassung; strukturiert in `SH3.location_ref`/`SH6.location_ref`) |
| `usage_frequency` | Choice (Häufigkeitsskala) | B | Wie häufig? |
| `used_for_activities` | Note | B | Für welche Tätigkeiten? |
| `exclusively_for_holding` | Boolean | P | Ausschliesslich für Holding-KG? |
| `other_users_if_not_exclusive` | Text | B | Wenn nein, wer sonst? |
| `availability_for_holding` | Note | B | Wann steht er der Holding-KG zur Verfügung? |
| `workstations` | Note | B | Welche Arbeitsplätze? |
| `equipment` | Note | B | Welche Ausstattung? |
| `access_persons` | Note | B | Wer hat Zugang? |
| `access_credentials` | Note | B | Schlüssel/Zugangskarten/Berechtigungen? |
| `floor_plan_available` | Boolean | B | Grundriss vorhanden? (Belegfrage Punkt 5) |
| `floor_plan_link` | URL | B | Verweis auf Grundriss (Belegfrage Punkt 5) |
| `photos_available` | Boolean | B | Fotos vorhanden? (Belegfrage Punkt 5) |
| `photos_link` | URL | B | Verweis auf Fotos (Belegfrage Punkt 5) |
| `display_label` | Text | B | kein Forms-Feld |

### 3.5 `SH5_Assets` (Formular 5) — Vorgabe Abschnitt 5 (Stammdaten "was ist vorhanden")

| Spalte | Typ | Pflicht | Vorgabe-Frage |
|---|---|---|---|
| `case_id` | Lookup → SH0 | P | (Fallzuordnung) |
| `asset_category` | Choice (12 Kategorien) | P | Kategorie (Katalog, siehe unten) |
| `asset_description` | Text | P | Was ist vorhanden? |
| `owner_text` | Text | B | Wem gehört es? |
| `cost_bearing_company_text` | Text | P | Welche Gesellschaft trägt die Kosten? |
| `cost_bearing_company_ref` | Lookup\* → `4_Beteiligte_und_Quoten` | B | (Auflösung von `cost_bearing_company_text`) |
| `evidence_note` | Note | B | Belegfrage (Punkt 5) |
| `display_label` | Text | B | kein Forms-Feld |

**12 Asset-Kategorien** (wörtlich aus der Vorgabe): Schreibtische und Arbeitsplätze; Büromöbel; Computer; Bildschirme; Mobiltelefone; Drucker; Server / Netzwerk; Software; Fahrzeuge; Fahrräder; Besprechungsräume; sonstige technische Ausstattung.

Die Fragen "Wo befindet es sich? Wer nutzt es? Wie häufig? Für welche Tätigkeit? Ausschliesslich für Holding-KG? Wenn nein, wer noch?" stehen **bewusst nicht** hier, sondern in `SH6_Asset_Nutzung` — siehe 3.6 (Vorgabe: *"Datenmodell: Asset → Standort → Nutzer → Tätigkeit → Nutzungsumfang"*, ein Asset kann mehrere Nutzungsinstanzen haben).

### 3.6 `SH6_Asset_Nutzung` (Formular 6) — Vorgabe Abschnitt 5 (Nutzung, n:m-Verknüpfungsliste)

| Spalte | Typ | Pflicht | Vorgabe-Frage |
|---|---|---|---|
| `case_id` | Lookup → SH0 | P | (Fallzuordnung) |
| `asset_text` | Text | P | Welches Arbeitsmittel/Asset? |
| `asset_ref` | Lookup\* → SH5 | B | (Auflösung) |
| `location_text` | Text | B | Wo befindet es sich? |
| `location_ref` | Lookup\* → SH4 | B | (Auflösung) |
| `user_text` | Text | P | Wer nutzt es? |
| `user_ref` | Lookup\* → SH1 | B | (Auflösung) |
| `usage_frequency` | Choice (Häufigkeitsskala) | P | Wie häufig? |
| `used_for_activity` | Choice (22 Tätigkeiten) | B | Für welche Tätigkeit? |
| `exclusively_for_holding` | Boolean | P | Ausschliesslich für Holding-KG? |
| `other_users_if_not_exclusive` | Text | B | Wenn nein, wer noch? |
| `usage_extent_note` | Note | B | Nutzungsumfang |
| `display_label` | Text | B | kein Forms-Feld |

### 3.7 `SH2_Entscheidungsprozesse` (Formular 2) — Vorgabe Abschnitt 3

12 Entscheidungsarten als Choice-Katalog (`decision_type`), einheitliche Unterstruktur je Zeile:

| Spalte | Typ | Pflicht | Vorgabe-Frage |
|---|---|---|---|
| `case_id` | Lookup → SH0 | P | (Fallzuordnung) |
| `decision_type` | Choice (12 Werte) | P | Art der Entscheidung (Katalog, siehe unten) |
| `who_first_involved_text` / `_ref` | Text / Lookup\* → SH1 | B | Wer beschäftigt sich zuerst damit? |
| `who_prepares_text` / `_ref` | Text / Lookup\* → SH1 | B | Wer bereitet vor? |
| `who_recommends_text` / `_ref` | Text / Lookup\* → SH1 | B | Wer gibt Empfehlung ab? |
| `who_decides_final_text` / `_ref` | Text (P) / Lookup\* → SH1 | P | Wer trifft die endgültige Entscheidung? |
| `decision_maker_location` | Text | B | Wo befindet sich diese Person bei der Entscheidung? |
| `decision_channel` | Choice (Meeting/E-Mail/Telefonisch/Anders) | B | Meeting / E-Mail / telefonisch / anders? |
| `documented_in_writing` | Boolean | B | Schriftlich festgehalten? |
| `documentation_location` | Note | B | Wenn ja, wo? (inkl. Belegfrage Punkt 5) |
| `display_label` | Text | B | kein Forms-Feld |

**12 Entscheidungsarten** (wörtlich aus der Vorgabe): Budget; Investitionen; Finanzierung; Personal; Geschäftsführung; wichtige Verträge; Preisgestaltung; Vertrieb; Produkte; strategische Projekte; Ausschüttungen; Erwerb oder Verkauf von Beteiligungen.

### 3.8 `SH7_Tagesgeschaeft_Praesenz` (Formular 7) — Vorgabe Abschnitt 6

| Spalte | Typ | Pflicht | Vorgabe-Frage |
|---|---|---|---|
| `case_id` | Lookup → SH0 | P | (Fallzuordnung) |
| `location_text` / `location_ref` | Text / Lookup\* → SH4 | B | Zusatzfeld: optionaler Bezug zum Geschäftsraum |
| `typical_days_per_month` | Number | B | An wie vielen Tagen pro Monat sind Personen der Holding-KG typischerweise vor Ort? |
| `persons_onsite_text` | Note | P | Welche Personen? |
| `activities_onsite` | Note | P | Was tun sie dort konkret? |
| `management_meetings_held` | Boolean | B | Finden dort Managementbesprechungen statt? |
| `meeting_frequency` | Choice (Häufigkeitsskala) | B | Wie häufig? |
| `meeting_participants` | Note | B | Wer nimmt teil? |
| `documents_created_or_signed` / `_note` | Boolean / Note | B | Werden dort Unterlagen erstellt oder unterschrieben? (inkl. Belegfrage) |
| `emails_or_transactions_handled` | Boolean | B | Werden von dort E-Mails versandt oder Geschäftsvorgänge bearbeitet? |
| `stakeholder_calls_held` | Boolean | B | Werden von dort Gespräche mit Geschäftsführern, Vorständen, Banken, Kunden oder Beratern geführt? |
| `tasks_done_elsewhere` | Note | B | Welche Aufgaben werden regelmässig von anderen Orten aus erledigt? |
| `display_label` | Text | B | kein Forms-Feld |

Zweck laut Vorgabe: tatsächliche Präsenz von bloss vorhandener Infrastruktur unterscheiden.

### 3.9 `SH8_Zusammenarbeit_Beteiligungen` (Formular 8) — Vorgabe Abschnitt 7

| Spalte | Typ | Pflicht | Vorgabe-Frage |
|---|---|---|---|
| `case_id` | Lookup → SH0 | P | (Fallzuordnung) |
| `participation_text` / `participation_ref` | Text (P) / Lookup\* → `4_Beteiligte_und_Quoten` | P | Beteiligungsgesellschaft (wiederverwendete Liste) |
| `typical_service_type` | Choice (22 Tätigkeiten, optional) | B | Zuordnung zu einer Managementtätigkeit (Konsistenzfeld, keine eigene Vorgabe-Frage) |
| `typical_service_description` | Text | P | (Bezeichnung der) typische(n) Managementleistung, je typische Managementleistung erfasst |
| `contact_initiator_text` / `_ref` | Text (P) / Lookup\* → SH1 | P | Wer bei der Holding-KG nimmt Kontakt auf? |
| `counterpart_text` | Text | B | Mit wem wird dort gesprochen? |
| `frequency` | Choice (Häufigkeitsskala) | B | Wie häufig? |
| `topic` | Note | P | Was wird besprochen? |
| `guidance_given` | Note | B | Welche Vorgaben oder Empfehlungen gibt die Holding-KG? |
| `information_received` | Note | B | Welche Informationen erhält sie zurück? |
| `documents_exchanged` | Note | B | Welche Unterlagen werden ausgetauscht? (inkl. Belegfrage) |
| `outcome_next_steps` | Note | B | Was passiert anschliessend? |
| `control_person_text` / `_ref` | Text / Lookup\* → SH1 | B | Wer kontrolliert die Umsetzung? |
| `display_label` | Text | B | kein Forms-Feld |

Hinweis laut Vorgabe: nach echten Abläufen fragen, nicht nach Vertragsformulierungen.

### 3.10 `SH9_Geschaeftsvorgaenge` (Formular 9) — Vorgabe Abschnitt 8

3-5 Beispiele je Fall (`sequence_number` 1-5).

| Spalte | Typ | Pflicht | Vorgabe-Frage |
|---|---|---|---|
| `case_id` | Lookup → SH0 | P | (Fallzuordnung) |
| `sequence_number` | Number (1-5) | P | laufende Nummer des Beispiels |
| `subject` | Note | P | Worum ging es? |
| `participation_text` / `_ref` | Text (P) / Lookup\* → `4_Beteiligte_und_Quoten` | P | Welche Beteiligungsgesellschaft? |
| `involved_person_text` / `_ref` | Text (P) / Lookup\* → SH1 | P | Wer auf Seiten der Holding-KG beteiligt? |
| `action_taken` | Note | P | Was hat diese Person konkret gemacht? |
| `event_date` | DateOnly | P | Wann? |
| `location_text` / `location_ref` | Text / Lookup\* → SH4 | B | Wo? |
| `decision_made` | Note | B | Welche Entscheidung wurde getroffen? |
| `documents_created` | Note | B | Welche Unterlagen entstanden? (inkl. Belegfrage) |
| `implemented_by_text` / `_ref` | Text / Lookup\* → SH1 | B | Wer setzte die Entscheidung um? |
| `display_label` | Text | B | kein Forms-Feld |

### 3.11 `SH10_Kosten` (Formular 10) — Vorgabe Abschnitt 9

| Spalte | Typ | Pflicht | Vorgabe-Frage |
|---|---|---|---|
| `case_id` | Lookup → SH0 | P | (Fallzuordnung) |
| `cost_category` | Choice (Personen/Räume/Arbeitsmittel/externe Dienstleister) | P | Kategorisierung der vier Kostenarten-Fragen |
| `related_person_text` / `_ref` | Text / Lookup\* → SH1 | B | Welche Personen verursachen Kosten für die Holding-KG? |
| `related_location_text` / `_ref` | Text / Lookup\* → SH4 | B | Welche Räume werden genutzt? |
| `related_asset_text` / `_ref` | Text / Lookup\* → SH5 | B | Welche Arbeitsmittel? |
| `external_provider_name` | Text | B | Welche externen Dienstleister? |
| `cost_description` | Note | P | Welche Kosten entstehen daraus? |
| `cost_amount` / `cost_currency` | Number / Text | B | Betrag (Ergänzung zur Kostenbeschreibung, nicht wörtlich gefragt, aber für Auswertbarkeit nötig) |
| `paying_company_initially` | Text | P | Welche Gesellschaft bezahlt zunächst? |
| `allocation_method` | Note | P | Wie werden sie der Holding-KG zugeordnet? |
| `recharged` | Boolean | B | Werden sie weiterberechnet? |
| `recharge_note` | Note | B | Weiterberechnung — Details (Ergänzung zu `recharged`) |
| `display_label` | Text | B | kein Forms-Feld |

### 3.12 `SH11_Belege` (Formular 11) — Belegfragen, Querschnitt (Punkt 5 des Auftrags)

Strukturell identisch zu `8_Unterlagen` (DE/AO), aber eigenständige Liste — Begründung siehe Abschnitt 4.

| Spalte | Typ | Pflicht | Bedeutung |
|---|---|---|---|
| `case_id` | Lookup → SH0 | P | (Fallzuordnung) |
| `document_type` | Choice (8 Werte, siehe unten) | P | Dokumenttyp |
| `related_object_text` | Text | B | Bezug zu Objekt (Freitext, da kein Live-Lookup in Forms) |
| `related_person` | Lookup\* → SH1 | B | Auflösung (optional) |
| `related_activity` | Lookup\* → SH3 | B | Auflösung (optional) |
| `related_location` | Lookup\* → SH4 | B | Auflösung (optional) |
| `related_asset` | Lookup\* → SH5 | B | Auflösung (optional) |
| `note` | Note | B | Hinweis |
| `required` / `uploaded` | Boolean (Default 0) | B | intern, kein Forms-Feld |
| `file_link` | URL | B | Link zur Datei, falls extern abgelegt |

Datei-Upload erfolgt wie bei `8_Unterlagen` über den nativen Forms-/SharePoint-Anhang (kein eigenes Feld) bzw. über `file_link`, falls extern abgelegt — siehe `sharepoint-forms/README.md` Abschnitt E.11 für den Hinweis zur Anmeldepflicht bei Forms-Datei-Upload.

**Dokumenttypen** (`document_type`): Nachweis Managementtätigkeit; Protokoll / Beschlussdokumentation; Vertrag / Vollmacht; Grundriss; Foto Geschäftsraum; Foto Arbeitsmittel; Rechnung / Kostenbeleg; Sonstiges.

## 4. Wiederverwendung bestehender AO-Listen

Prüfung je Liste/Kandidat aus dem Auftrag ("Fall/Mandant mit case_id, access_code, Eingang_Fehler, Personen/Vertreter, Anschriften, Beteiligungen"):

| Kandidat (DE/AO) | Entscheidung | Begründung |
|---|---|---|
| `0_Fallsteuerung` (Fall/Mandant, case_id/access_code) | **Nicht wiederverwendet** — eigene Liste `SH0_Substanzfall` mit identischem Muster | `0_Fallsteuerung` erzwingt unbedingte Pflichtfelder, die für eine Substanzprüfung fachfremd wären (`direction` Inbound/Outbound, `already_registered`, `tax_office_country`, `tax_office` — alle `-Required`). Eine Substanzprüfung ist zudem kein einmaliger Erfassungsvorgang, sondern ein wiederkehrender Prüfzeitraum für eine bereits bestehende Gesellschaft. Eine Zweckentfremdung würde entweder bedeutungslose Pflichtwerte erzwingen oder das produktiv genutzte Pflichtfeld-Schema von PR #16 verändern. Das bewährte **Muster** (`case_id`/`access_code`, indiziert + eindeutig, idempotente Angleichung) wird deshalb 1:1 in `SH0_Substanzfall` übernommen, nicht die Liste selbst. `SH0_Substanzfall.related_erfassung_case` verlinkt optional auf einen bestehenden `0_Fallsteuerung`-Datensatz, um die Beteiligungs-Wiederverwendung unten zu ermöglichen. |
| `Eingang_Fehler` | **Wiederverwendet** (keine neue Liste) | Generisches, modul-unabhängiges Fehlerprotokoll (`form_no`, `case_id_raw`, `reason`, `payload`, `status`) ohne Fachfeld-Bindung an die AO-Erfassung. Dieses Modul nutzt sie für fehlgeschlagene Formular-Übernahmen (unbekannte `case_id`/`access_code`, Validierungsfehler) mit — siehe Nummerierungskonvention in `sharepoint-forms/README.md` Abschnitt D1 (Formular-Nr. 101-111, um Kollision mit den AO-Formular-Nr. 0-8 zu vermeiden). |
| `3_Personen_und_Vertretung` (Personen/Vertreter) | **Nicht wiederverwendet** — eigene Liste `SH1_Personen`, nur optionaler Cross-Reference-Lookup | `3_Personen_und_Vertretung` bildet die **rechtliche Vertretungsrolle** einer Person gegenüber dem Finanzamt ab (`role`: Gesetzlicher Vertreter / Ständiger Vertreter / Empfangsbevollmächtigter / Steuerliche Beratung / Ehegatte-Lebenspartner) mit Pflicht-Lookup auf `0_Fallsteuerung`. Die Substanzprüfung braucht dagegen ein **operatives Tätigkeitsprofil** (Aufgaben, Häufigkeit, Arbeitszeitanteil, Entscheidungsbefugnisse, Unterschriftsvollmacht, gesteuerte Mitarbeiter) — ein strukturell anderer Fragenkatalog, zudem an einen anderen Fall-Typ gebunden (ein SharePoint-Lookup-Feld kann nur eine Zielliste referenzieren, `3_Personen_und_Vertretung.case_id` zeigt zwingend auf `0_Fallsteuerung`, nicht auf `SH0_Substanzfall`). `SH1_Personen.vertretung_ref` verweist optional auf eine dort bereits erfasste Person (z. B. identischer Geschäftsführer), um Doppelerfassung bei der Mandatsarbeit sichtbar zu machen. |
| `4_Beteiligte_und_Quoten` (Beteiligungen) | **Wiederverwendet als Lookup-Ziel** (keine neue Beteiligungs-Stammliste) | Die Vorgabe schliesst Fragen zur Konzernstruktur als solcher ausdrücklich aus — es wird nirgends nach Beteiligungsquoten gefragt. Wo eine Beteiligungsgesellschaft nur *benannt* werden muss (Tätigkeit, Zusammenarbeit, Geschäftsvorgang, Asset-Kostenträger, Personen-Arbeitgeber), verweisen `participation_ref`/`employer_participation_ref`/`cost_bearing_company_ref` optional auf `4_Beteiligte_und_Quoten.display_label` — identisches Lookup-Muster wie `related_participation` in `8_Unterlagen` (DE/AO). Eine eigene "Beteiligungsgesellschaften-Stammliste" entfiele damit vollständig; steht kein `4_Beteiligte_und_Quoten`-Eintrag zur Verfügung (z. B. Holding-KG ohne AO-Erfassungsfall im System), bleibt der parallele `_text`-Freitext die massgebliche Angabe. |
| `5_Betriebsstaetten` (keine explizite Vorgabe, aber naheliegend für "Ort") | **Nicht wiederverwendet** — eigene Liste `SH4_Orte`, nur optionaler Cross-Reference-Lookup | `5_Betriebsstaetten` bildet eine **steuerlich/rechtlich gemeldete Einheit je Standort** ab (Land, Eigentumsverhältnis, umsatz-/lohnsteuerliche Relevanz) auf Unternehmensebene, nicht die raumscharfen Substanzmerkmale (Raumnummer, Grösse, Zugang/Schlüssel, Ausstattung, Grundriss, Fotos), die die Vorgabe für "Geschäftsräume/Bereiche" verlangt. `SH4_Orte.betriebsstaette_ref` verweist optional auf eine bereits gemeldete Betriebsstätte, falls Deckungsgleichheit besteht. |
| "Anschriften" (eigenständige Liste) | **Nicht vorhanden, daher nichts wiederzuverwenden** | Das AO-Modell führt keine eigenständige Anschriften-Liste; Adressen sind Felder je Objekt (`1_Allgemeiner_Stammblock.street`/`postal_code_city`, `3_Personen_und_Vertretung.address`, `5_Betriebsstaetten.address`). Dieses Modul übernimmt dasselbe Muster (`SH4_Orte.address` als Note-Feld je Geschäftsraum) statt eine neue, bislang nicht existierende Konvention einzuführen. |
| `8_Unterlagen` (Belege) | **Nicht wiederverwendet** — eigene, strukturell identische Liste `SH11_Belege` | `8_Unterlagen.case_id` ist ein **Required**-Lookup fest auf `0_Fallsteuerung` konfiguriert; eine SharePoint-Lookup-Spalte kann nur eine Zielliste referenzieren. Eine Umwidmung auf zwei Fall-Typen (AO-Erfassung und Substanzprüfung) würde das produktiv genutzte Pflichtfeld aus PR #16 brechen. `SH11_Belege` übernimmt deshalb das vollständige Muster (`document_type`-Choice, `related_object_text` + sekundäre optionale Lookups, `required`/`uploaded`, `file_link`), bindet `case_id` aber an `SH0_Substanzfall`. |
| `Technische_Mindestfelder` | **Nicht einschlägig** | Diese Liste bildet ELSTER-/BZSt2-Kz-Referenzen (amtliche Formular-Kennziffern) ab; die Substanzprüfung hat keinen amtlichen Formularbezug dieser Art, daher kein Analogon nötig. |

**Zusammenfassung:** 2 von 7 geprüften Kandidaten werden tatsächlich physisch mitgenutzt (`Eingang_Fehler` vollständig, `4_Beteiligte_und_Quoten` als Lookup-Ziel ohne neue Beteiligungs-Stammdaten); 2 weitere (`3_Personen_und_Vertretung`, `5_Betriebsstaetten`) werden über optionale Cross-Reference-Lookups verknüpft, ohne ihre Fachlisten direkt zu übernehmen; die übrigen Kandidaten sind entweder nicht einschlägig oder existieren im Quellmodell nicht.

## 5. Leitfragen-Nachweis

Leitfrage laut Auftrag: *"Wer macht was, wann, wie häufig, wo, mit welchen Mitteln, für welche Beteiligung und mit welchem Ergebnis?"* — muss **pro Tätigkeit** aus den Daten beantwortbar sein.

### 5.1 Datenpfad je Tätigkeits-Zeile

Eine einzelne Zeile in `SH3_Managementtaetigkeiten` beantwortet die Leitfrage direkt bzw. über einen kurzen Join:

| Leitfrage-Element | Spalte/Quelle |
|---|---|
| **Wer** macht es | `SH3.handled_by_text` (Rohantwort) bzw. `SH3.handled_by_ref` → `SH1_Personen` (Name, Funktion, Arbeitszeitanteil) |
| **Was** macht die Person | `SH3.activity_type` (Katalogwert) + `SH3.description_concrete` (konkrete Beschreibung) |
| **Wann** / **wie häufig** | `SH3.frequency` (Häufigkeitsskala); ergänzend `SH1_Personen.tasks_since` (seit wann die Person überhaupt tätig ist) |
| **Wo** | `SH3.location_text`/`location_ref` → `SH4_Orte` (Anschrift, Raum, Ausstattung) |
| **Mit welchen Mitteln** | Join über `SH6_Asset_Nutzung` gefiltert auf `user_ref = SH3.handled_by_ref` **und** `used_for_activity = SH3.activity_type` → liefert die konkret genutzten Assets (`SH6.asset_ref` → `SH5_Assets.asset_description`) |
| **Für welche Beteiligung** | `SH3.participation_text`/`participation_ref` → `4_Beteiligte_und_Quoten` (Name der Beteiligungsgesellschaft, ohne Quote/Struktur) |
| **Mit welchem Ergebnis** | `SH3.documents_created` (entstandene Unterlagen) + `SH3.final_decision_text`/`final_decision_ref` (wer abschliessend entschieden hat) + verknüpfte Belege in `SH11_Belege` (gefiltert auf `related_activity = SH3.display_label`) |

### 5.2 Beispielhafte Beantwortung (fiktive Beispielzeile)

Angenommen, `SH3_Managementtaetigkeiten` enthält folgende Zeile für `case_id = SH-2026-0001`:

| Spalte | Beispielwert |
|---|---|
| `activity_type` | Controlling |
| `actually_performed` | Ja |
| `handled_by_text` | Anna Berger |
| `description_concrete` | monatliche Soll-Ist-Analyse und Reporting an die Geschäftsleitung der Beteiligungsgesellschaft |
| `frequency` | monatlich |
| `participation_text` | Muster-Beteiligungs-GmbH |
| `location_text` | Geschäftsraum Zürich, Büro 2 |
| `documents_created` | Reporting-Deck (PDF), Protokoll Soll-Ist-Besprechung |
| `final_decision_text` | Anna Berger (operative Freigabe) |

Ergänzt durch einen gefilterten Blick in `SH6_Asset_Nutzung` (`user_text = Anna Berger`, `used_for_activity = Controlling`) ergibt sich z. B. "Laptop Controlling-Team" und "Reporting-Software" als genutzte Mittel, und ein gefilterter Blick in `SH11_Belege` (`related_object_text` enthält den Tätigkeitsbezug) liefert das hochgeladene Reporting-Deck als Beleg.

**Antwort auf die Leitfrage für diese Zeile:** *Anna Berger (wer) führt monatlich (wann/wie häufig) im Büro 2 des Geschäftsraums Zürich (wo) mit Laptop und Reporting-Software (Mittel) das Controlling (was) für die Muster-Beteiligungs-GmbH (Beteiligung) durch und erstellt dazu ein Reporting-Deck, das sie selbst operativ freigibt (Ergebnis).*

Dieser Nachweis ist für jede der 22 Tätigkeiten identisch herleitbar, da alle Zeilen in `SH3_Managementtaetigkeiten` dieselbe Unterstruktur tragen (siehe Abschnitt 3.3).

## 6. Belegkonzept (Querschnitt, Punkt 5 des Auftrags)

Zwei sich ergänzende Mechanismen, konsistent mit dem AO-Vorbild:

1. **Direkte Boolean-/Note-Hinweisfelder je Bereich**, wo die Vorgabe wörtlich danach fragt: `SH4_Orte.floor_plan_available`/`floor_plan_link` (Grundriss), `SH4_Orte.photos_available`/`photos_link` (Fotos), sowie `evidence_note`/`documents_created`-Felder in `SH1`, `SH3`, `SH5`, `SH7`-`SH9` für "welche Unterlagen entstehen"-Fragen.
2. **Zentrale Belege-Liste `SH11_Belege`** (Formular 11) als Datei-Ablage mit Dokumenttyp-Katalog, optionalen Lookups auf Person/Tätigkeit/Ort/Asset und nativer Dateianlage bzw. `file_link` für extern abgelegte Dateien — strukturell identisch zu `8_Unterlagen` (DE/AO), siehe Abschnitt 4 für die Begründung der eigenständigen Liste.

Damit ist jede Beleg-/Nachweisfrage aus dem Auftrag einer Spalte zugeordnet, ohne pro Bereich eine eigene Dokumentbibliothek anzulegen.

## 7. Offene Fragen an Nils

1. **Raumart-Katalog (`SH4_Orte.room_type`):** Die Vorgabe fragt "Art des Raums" ohne vorgegebenen Katalog. Kanzleientscheid in diesem Entwurf: geschlossene Choice-Liste (Büro/Besprechungsraum/Empfang/Lager/Home-Office/Sonstige) statt Freitext, um Auswertbarkeit zu sichern — bitte bestätigen oder anderen Katalog vorgeben.
2. **Kostenwährung/-betrag (`SH10_Kosten.cost_amount`/`cost_currency`):** Die Vorgabe fragt nur nach "welche Kosten entstehen" als Freitext; für eine auswertbare Kostenübersicht wurden `cost_amount` (Zahl) und `cost_currency` ergänzt. Bitte bestätigen, ob eine strukturierte Betragsangabe gewünscht ist oder ob ausschliesslich die Freitextbeschreibung (`cost_description`) genügen soll.
3. **Geschäftsvorgänge-Obergrenze:** Die Vorgabe nennt "drei bis fünf" Beispiele; `sequence_number` ist mit `Min 1`/`Max 5` begrenzt. Falls mehr als 5 Geschäftsvorgänge dokumentiert werden sollen (z. B. bei umfangreicheren Mandaten), bitte die Grenze freigeben.
4. **`SH0_Substanzfall.case_id`-Format:** Es wird (wie bei `0_Fallsteuerung`) kein serverseitiger Nummerngenerator angelegt. Empfehlung in diesem Entwurf: `SH-JJJJ-NNNN`, um Kollisionen mit AO-Fall-IDs (`JJJJ-NNNN`) sicher auszuschliessen. Bitte Namenskonvention bestätigen, insbesondere falls ein gemeinsamer Fall-ID-Raum über beide Module gewünscht ist.
5. **Formular 8 (Zusammenarbeit mit Beteiligungsgesellschaften) — Granularität:** Die Vorgabe spricht von "je typischer Managementleistung"; `typical_service_type` ist in diesem Entwurf optional an den 22-Tätigkeiten-Katalog angelehnt (Konsistenzfeld). Bitte bestätigen, ob diese Zuordnung sinnvoll ist oder ob "typische Managementleistung" bewusst freier/feingranularer als die 22 Tätigkeiten gefasst werden soll.
6. **Zugriffsrechte/Vertraulichkeit:** Wie bei der steuerlichen Erfassung enthalten diese Listen potenziell sensible operative Detaildaten (Gehaltsnahe Arbeitszeitangaben, Zugangsberechtigungen, Kostenzuordnungen). Soll dieselbe Zielsite (`steueranwaltskanzlei`) verwendet werden, oder ist eine separate, enger berechtigte Site für die Substanzprüfungsdaten vorzuziehen?
