# Einheitliches Datenmodell: Substanzprüfung Holding-KG

**Stand:** 27.10.2026, **Update 1** (ersetzt die Grobvorgabe-basierte Erstfassung vom 27.10.2026 vollständig).

**Fachliche Vorgabe:** Nils Obenhaus, ausgearbeiteter Erfassungsbogen-Entwurf „Personen und tatsächlich ausgeübte Managementtätigkeiten", Projekt 22032-2 «Atwork wg Holding-KG», Arbeitsfassung 27.10.2026 (`uploads/erfassungsbogen-entwurf-27-10-2026.md`, Anhänge A und B1-B6).

**Zweck:** strukturierte Datenerhebung zur personellen, sachlichen und organisatorischen Ausstattung der Holding-KG und zur tatsächlich ausgeübten Managementtätigkeit — als Nachweisgrundlage für die steuerliche Anerkennung der Holding-KG. Geht vollständig von der vorhandenen Konzernstruktur weg: Beteiligungsverhältnisse werden nicht nochmals abgefragt (siehe Abschnitt 4, Wiederverwendung).

**Rollen der Dokumente in `DE/Substanz-Holding-KG/`:**

| Dokument | Rolle |
|---|---|
| dieses Datenmodell | Architektur, Listenkatalog, Wiederverwendungsentscheidungen, Berechtigungskonzept |
| [`Fragenkatalog-Substanzpruefung-Holding-KG.md`](Fragenkatalog-Substanzpruefung-Holding-KG.md) | alle Fragen (P/E/V/K/G/R/A/C/N) mit stabilen IDs, Mandantensicht und internem Hinweis getrennt, inkl. P09-Handlungstabelle |
| [`interner-anhang-a-auswertungslogik.md`](interner-anhang-a-auswertungslogik.md) | NUR INTERN: Auswertungslogik, Rechtsprechung, VP-Zuordnungstabelle (A1-A7) |
| [`feldkatalog/feldkatalog.json`](feldkatalog/feldkatalog.json) | maschinenlesbarer Feldkatalog (B3): Formular, Frage-ID, Unterfeld-Suffix, Text, Antworttyp, Auswahlcode, Pflichtbedingung, ZielListe, ZielSpalte, Version + Codebooks |
| [`sharepoint-forms/README.md`](sharepoint-forms/README.md) | Forms-Aufteilung (B1), Flow-Spezifikation und Prüfregeln (B4), Datei-Upload-Konzept (B5) |
| [`sharepoint-forms/KLICKANLEITUNG-FORMS.md`](sharepoint-forms/KLICKANLEITUNG-FORMS.md) | Klickanleitung für die 7 Formulare |
| [`sharepoint-forms/New-SubstanzHoldingKGListen.ps1`](sharepoint-forms/New-SubstanzHoldingKGListen.ps1) | idempotentes PnP-PowerShell-Skript, erzeugt aus dem Feldkatalog, legt 20 Listen + Dokumentbibliothek an |

**Was sich mit Update 1 ändert:** Die frühere Listenfamilie `SH0_Substanzfall` bis `SH11_Belege` (12 Listen, eigenes Fragenschema ohne stabile IDs) wird **vollständig ersetzt** durch die 20 Listen aus Anhang B2 plus Dokumentbibliothek `Substanznachweise`, mit stabilen Frage-IDs, stabilen Auswahlcodes und einem maschinenlesbaren Feldkatalog als Single Source of Truth für Formulare, Flows und Skript.

## 1. Architekturprinzipien (aus Anhang A und B1-B6 übernommen)

- **Zwei Achsen statt starrer Dreiteilung** (Anhang A1): *Handlung* (laufende Geschäftsführung, Entscheidung/Umsetzung, Vorbereitung/Beratung, Aufsicht/Kontrolle, Vorgabe, Schulung, administrative Ausführung, Gesellschafterrechte) und *Zuordnung* (Auftrag der KG für eine Beteiligung, eigene Organisation der KG, eigene Beteiligungsaufgaben, Arbeiten für die Schweizer Mutter, sonstige/gemischte Empfänger) werden getrennt erfasst, nicht als ein einziges Klassifikationsfeld vermischt. Auftraggeber, Arbeitgeber, handelnde Gesellschaft, Vertragsgesellschaft, unmittelbarer Empfänger und Kostenträger bleiben eigenständige Felder (siehe `Taetigkeiten`, Abschnitt 2).
- **Keine Konzernstrukturerhebung.** `Gesellschaften` führt nur Name und Rolle im Bestand, keine Quoten (siehe Abschnitt 4).
- **Stabile IDs statt Freitextbezug.** Jede Frage behält ihre Frage-ID auch bei künftigen Textänderungen (B3); jede geschlossene Antwortmöglichkeit hat einen stabilen Code (z. B. `FREQ_DAILY`), die deutsche Beschriftung ist nur Anzeigetext im Formular. „Unbekannt" wird nie als `0`/`false` gespeichert, sondern als eigener Code (z. B. `..._UNBEKANNT`) oder eigener Choice-Wert — deshalb sind mehrere Felder, die auf den ersten Blick wie Ja/Nein-Fragen wirken, als Choice mit drei Werten (Ja/Nein/unbekannt) statt als SharePoint-Boolean angelegt (z. B. `Kostenverteilungen.weiterberechnet`).
- **Generische n:m-Verknüpfung statt Spezialfelder.** Prozentuale Verteilungen (Orte, Empfänger, Ressourcennutzung) und Beleg-Verknüpfungen sind eigene Listen mit Dimension/Bezugstyp-Feldern, nicht feste benannte Spalten je möglichem Gegenwert (`Zeitverteilungen`, `Ressourcennutzungen`, `Belegverknuepfungen`).
- **Datei-Upload nicht über Forms** (B5): Microsoft Forms verlangt für Datei-Upload-Fragen ein Microsoft-Konto der eigenen Organisation; ein extern zugänglicher Bogen darf sich darauf nicht verlassen. Stattdessen: separater Kanzlei-Uploadweg, im Formular nur Anlagenreferenz/Dateiname (siehe `sharepoint-forms/README.md`, Abschnitt G).

## 2. Kern-Datenmodell: 20 Listen + Dokumentbibliothek

### 2.1 Stammdatenlisten (listenübergreifend, nicht erfassungsgebunden)

| Liste | Rolle |
|---|---|
| `Gesellschaften` | bekannter Gesellschaftsbestand (Name, Rolle) — Lookup-Ziel für praktisch jede andere Liste |
| `Personen` | Personen, die für die Holding-KG tätig sind (P01-P02 Übersicht) |

### 2.2 Fallsteuerung

| Liste | Rolle |
|---|---|
| `Erfassungen` | eine Zeile je Substanzprüfungs-Erfassung (Zeitraum, Status, Abschluss, Abstimmungsstatus C06, Abschlusserklärung N05) |

### 2.3 Person, Vertrag, Einsatz (Abschnitte 1 und 3 des Fragenkatalogs)

| Liste | Rolle |
|---|---|
| `Personenbindungen` | vertragliche Bindung je Person × Gesellschaft (P02 je Funktion, P03-P05) |
| `Personeneinsaetze` | Arbeitszeit, Weisungsgeber, Vertretung, Büropräsenz je Person (P06-P08, P19-P20, P23-P24) |

### 2.4 Tätigkeit (Abschnitt 2, mit G- und K-Unterstruktur)

| Liste | Rolle |
|---|---|
| `Taetigkeiten` | zentrale Verknüpfungsliste Person × Tätigkeit × Beteiligung (P09-P18; G01-G05 und K01-K03/K05 als Unterstruktur je nach `bereich_code`) |
| `Orte` | Standortkatalog (P16/P22 referenzieren; eigenständig von `Raeume`, siehe Abschnitt 2.6) |
| `Zeitverteilungen` | n:m-Verknüpfung Zeitanteile auf Ort/Empfänger (P16, P21, P22), Summe je Bezug = 100 % |

### 2.5 Entscheidung, Vertrag, Steuerung (Abschnitte 4-6)

| Liste | Rolle |
|---|---|
| `Entscheidungsfaelle` | Entscheidungsfälle (E01-E08) sowie Kontroll-/Anweisungs-/Schulungsfälle (K05) — gemeinsames `art_code`-Codebook |
| `Vertragsvorgaenge` | Vertragsverhandlungen und Abschlussreife (V01-V02, V05-V06, V08-V09) |
| `Fallbeteiligungen` | Rolle/Schritte/Orte je beteiligter Person, polymorph zu `Entscheidungsfaelle` ODER `Vertragsvorgaenge` (E03/E04/E07; V03/V04/V07/V08) |
| `Steuerungsbeziehungen` | Steuerung von Mitarbeitenden/Dienstleistern (K04) |

### 2.6 Raum, Arbeitsmittel, Nutzung (Abschnitte 8-9)

| Liste | Rolle |
|---|---|
| `Raeume` | Geschäftsräume und tatsächliche Nutzung (R01-R06); referenziert `Orte` für den Standort |
| `Arbeitsmittel` | Arbeitsmittel, Fahrzeuge, IT und Software (A01-A02, A05-A07) |
| `Ressourcennutzungen` | n:m-Verknüpfung Raum/Mittel × Person × Tätigkeit × Nutzungsanteil (R04; A03-A04) |

### 2.7 Kosten und Abrechnung (Abschnitt 10)

| Liste | Rolle |
|---|---|
| `Kosten` | Personal-, Sach- und Gemeinkosten (C01-C04; A08; R06) |
| `Kostenverteilungen` | Weiterberechnung von Kosten auf Empfängergesellschaften (C02) |
| `Abrechnungen` | tatsächlich gestellte Abrechnungen/Leistungsvereinbarungen (G06, C05) |

### 2.8 Belege und interne Bewertung (Abschnitt 11, Anhang A)

| Liste/Bibliothek | Rolle |
|---|---|
| `Substanznachweise` (Dokumentbibliothek) | zentrale Belegablage; Datei-Upload-Ersatz nach B5 |
| `Belegverknuepfungen` | generische Verknüpfung Nachweis → beliebige Zielliste (N02-N04), polymorph über `ziel_typ`/`ziel_id` |
| `InterneBewertungen` | **nur intern, eingeschränkte Berechtigungen** — Auswertungshilfen zu Anhang A (A1-A7), siehe Abschnitt 5 |

### 2.9 Beziehungsdiagramm (vereinfacht)

```text
Gesellschaften ◄──────────────┐  (Lookup-Ziel fast aller Listen, keine Quoten)
Personen ◄──────────────┐     │
                         │     │
Personenbindungen ───────┘     │   (P02-P05, je Person x Gesellschaft)
Personeneinsaetze ───────┘     │   (P06-P08, P19-P24, je Person)
                                │
Taetigkeiten ───────────────────┘  (zentral: Person x Bereich x Empfaenger x Beteiligung)
  ├─► Zeitverteilungen (P16/P21/P22: Ort- und Empfaengerverteilung, je 100 %)
  ├─► Steuerungsbeziehungen (K04)
  └─► InterneBewertungen (nur intern)

Entscheidungsfaelle ──┐
Vertragsvorgaenge ────┼─► Fallbeteiligungen (polymorph: bezug_typ=ENTSCHEIDUNG|VERTRAG)
                      └─► InterneBewertungen (nur intern)

Raeume ──► Ressourcennutzungen ◄── Arbeitsmittel
Kosten ──► Kostenverteilungen

Substanznachweise ◄── Belegverknuepfungen (polymorph: ziel_typ/ziel_id auf jede der 20 Listen)
```

## 3. Listenübersicht mit Spaltenzahl

Spaltenzahl = Anzahl SharePoint-Spalten laut Feldkatalog (ohne das native `Title`-Feld), automatisiert aus `feldkatalog/feldkatalog.json` ausgezählt und gegen das PnP-Skript geprüft (keine Duplikate, keine fehlenden Codebook-Referenzen).

| Liste | Formular (B1) | Spalten | Erfassungsgebunden? |
|---|---|---|---|
| `Erfassungen` | intern (Fallanlage) | 15 | — (ist selbst die Fallsteuerung) |
| `Gesellschaften` | intern (Stammdatenpflege) | 5 | Nein (Stammdaten) |
| `Substanznachweise` (Bibliothek) | alle (Belege) | 7 | Ja |
| `Personen` | 1 — Personenblatt | 5 | Nein (Stammdaten) |
| `Personenbindungen` | 1 — Personenblatt | 16 | über Person/Gesellschaft |
| `Personeneinsaetze` | 1 — Personenblatt | 23 | Ja |
| `Orte` | 2 — Tätigkeitsblatt | 7 | über Gesellschaften |
| `Taetigkeiten` | 2 — Tätigkeitsblatt (+ 3, 4) | 45 | Ja |
| `Zeitverteilungen` | 1, 2 | 13 | über Einsatz/Tätigkeit |
| `Entscheidungsfaelle` | 3 — Entscheidungs-/Vertrags-/Kontrollblatt | 21 | Ja |
| `Vertragsvorgaenge` | 3 | 13 | Ja |
| `Fallbeteiligungen` | 3 | 19 | über Entscheidung/Vertrag |
| `Steuerungsbeziehungen` | 3 | 12 | Ja |
| `Raeume` | 5 — Raumblatt | 18 | Ja |
| `Arbeitsmittel` | 6 — Arbeitsmittelblatt | 27 | Ja |
| `Ressourcennutzungen` | 5, 6 | 17 | Ja |
| `Kosten` | 7 — Kosten- und Belegblatt (+ 5, 6) | 22 | Ja |
| `Kostenverteilungen` | 7 | 9 | über Kosten |
| `Abrechnungen` | 7 (+ 4) | 18 | Ja |
| `Belegverknuepfungen` | 7 | 13 | über Nachweis |
| `InterneBewertungen` | — (nur intern) | 11 | über Tätigkeit/Fall |

**Gesamt: 20 Listen + 1 Dokumentbibliothek, 336 Spalten, 7 Mandanten-/Kanzlei-Formulare.**

## 4. Wiederverwendung bestehender AO-Listen (neu begründet für Update 1)

Die Anhang-B2-Modellierung verlangt zwei eigene, listenübergreifende Stammdatenlisten (`Gesellschaften`, `Personen`) anstelle einer Übernahme bestehender AO-Listen. Prüfung je Kandidat:

| Kandidat (DE/AO) | Entscheidung | Begründung |
|---|---|---|
| `Eingang_Fehler` | **Wiederverwendet** (unverändert, keine neue Liste) | Generisches, modul-unabhängiges Fehlerprotokoll (`form_no`, `case_id_raw`, `reason`, `payload`, `status`). Dieses Modul nutzt es weiterhin für fehlgeschlagene Formular-Übernahmen (unbekannte/fehlende `ErfassungID`, Validierungsfehler) — Formular-Nr.-Konvention siehe `sharepoint-forms/README.md`, Abschnitt D. |
| `4_Beteiligte_und_Quoten` (Gesellschaften-Bestand) | **Nicht wiederverwendet als Stammliste — nur optionaler Cross-Reference-Lookup** | Anhang B2 modelliert `Gesellschaften` als eigenständige, erfassungsübergreifende Stammliste mit genau zwei fachlichen Spalten (Name, Rolle) — bewusst **ohne** Beteiligungsquote, da die Vorgabe Beteiligungsverhältnisse ausdrücklich nicht nochmals abfragt. `4_Beteiligte_und_Quoten` bildet dagegen Beteiligungsquoten **innerhalb eines bestimmten AO-Erfassungsfalls** ab (`case_id`-Lookup auf `0_Fallsteuerung`, Required) — ein anderer Zweck und eine andere Bindung. Eine direkte Wiederverwendung als Lookup-Ziel für die zahlreichen Gesellschaftsbezüge in diesem Modul (nahezu jede der 20 Listen referenziert `Gesellschaften`) würde entweder die AO-Liste zweckentfremden oder deren `case_id`-Pflichtbindung verletzen. Stattdessen: `Gesellschaften.ao_participation_ref` verweist **optional** auf einen bereits vorhandenen `4_Beteiligte_und_Quoten`-Datensatz (Lookup auf `display_label`), damit eine Kanzleiperson beim Anlegen des Gesellschaftsbestands auf bereits erfasste Beteiligungsgesellschaften zurückgreifen kann, ohne deren Quote zu wiederholen. |
| `3_Personen_und_Vertretung`, `5_Betriebsstaetten` | **Entfallen** (kein Cross-Reference mehr) | Anhang B2 sieht für dieses Redesign keine entsprechenden Querverweise vor (anders als die frühere SH0-SH11-Fassung). `Personen` und `Orte`/`Raeume` sind jetzt eigenständige, von Anhang B2 vollständig spezifizierte Stammdaten-/Fachlisten mit eigenem Fragenbezug; eine Verknüpfung zu den AO-Rollenlisten wäre zusätzliche Komplexität ohne Vorgabe-Grundlage. Bei Bedarf lässt sich ein analoger optionaler Lookup wie `ao_participation_ref` nachträglich ergänzen. |
| `0_Fallsteuerung`, `8_Unterlagen` | **Weiterhin nicht wiederverwendet** (Begründung unverändert) | `Erfassungen` und `Substanznachweise` ersetzen diese Rolle mit eigenem Fall-/Belegbegriff; `0_Fallsteuerung`s unbedingte AO-spezifische Pflichtfelder (Richtung, Finanzamt usw.) passen weiterhin nicht zu einer Substanzprüfung; `8_Unterlagen.case_id` bleibt ein Required-Lookup auf `0_Fallsteuerung`. |

**Zusammenfassung Update 1:** Von den geprüften AO-Listen wird nur `Eingang_Fehler` vollständig mitgenutzt; `4_Beteiligte_und_Quoten` dient als optionales Lookup-Ziel für die Gesellschaften-Stammdatenpflege, ohne dass dessen Quote übernommen wird. Die in Update 0 noch vorgesehenen Cross-Reference-Lookups zu `3_Personen_und_Vertretung` und `5_Betriebsstaetten` entfallen, da Anhang B2 sie nicht vorsieht.

## 5. InterneBewertungen: eingeschränkte Berechtigungen

Punkt 2 des Auftrags verlangt für `InterneBewertungen` eine eigene, eingeschränkte Berechtigung (Rechtevererbung brechen oder separate Site). **Umsetzung in diesem Modul:** Rechtevererbung brechen (Option a), dokumentiert wie folgt:

- Das PnP-Skript bricht die Rechtevererbung von `InterneBewertungen` über `List.BreakRoleInheritance($true, $false)` (CSOM), **kopiert dabei zunächst die bisherigen Zuweisungen**, damit der Lauf niemanden sofort aussperrt, und gibt danach eine Warnung aus.
- **Nach dem Lauf ist zwingend manuell nachzuarbeiten:** eine berechtigte Person muss die automatisch kopierten (zu weiten) Berechtigungen entfernen und nur eine definierte, enge Kanzlei-internen Prüfergruppe (z. B. "Substanzprüfung — interne Auswertung") mit Lese-/Schreibzugriff stehen lassen. Das Skript kann diesen Gruppennamen nicht automatisch bestimmen, da er tenant-/site-spezifisch ist (siehe `sharepoint-forms/README.md`, Abschnitt F).
- **Alternative Option b (separate Site):** falls die Kanzlei eine vollständige Site-Trennung bevorzugt (z. B. weil interne rechtliche Einordnungen grundsätzlich nicht auf derselben Site wie Mandantendaten liegen sollen), müsste `InterneBewertungen` auf eine zweite, enger berechtigte Site verlagert werden; die Lookup-Spalten `taetigkeit_ref`/`fall_ref` könnten dann nicht als native SharePoint-Lookups auf eine andere Site zeigen (SharePoint-Lookups sind site-lokal) und müssten durch Text-Referenzen (ID + Linkliste) ersetzt werden. Diese Alternative ist **nicht** umgesetzt, da sie das gesamte Modul architektonisch verändern würde; sie ist als offene Frage an Nils vermerkt (Abschnitt 7).

## 6. Belegkonzept (B5)

Microsoft Forms verlangt für Datei-Upload-Fragen ein Microsoft-Konto der eigenen Organisation (B5-Quelle: Microsoft-Support-Dokumentation, Abruf 27.10.2026) — ein extern zugänglicher Bogen darf sich darauf nicht verlassen. Umsetzung:

1. **Formulare fragen nur eine Anlagenreferenz/Dateiname als Text** (kein Datei-Upload-Fragetyp in den Mandanten-Formularen).
2. **Separater Kanzlei-Uploadweg** (z. B. bestehender Kanzlei-Dateitransferdienst oder eine interne SharePoint-Freigabe mit Gastzugriff) nimmt die eigentliche Datei entgegen.
3. Die Datei landet als Eintrag in der Dokumentbibliothek **`Substanznachweise`** (nativer Anhang/Dokument) bzw. wird über `dateilink` (URL) referenziert, falls sie extern verbleibt.
4. **`Belegverknuepfungen`** verknüpft einen `Substanznachweise`-Eintrag mit einer beliebigen Zielzeile (`ziel_typ` + `ziel_id`) und der jeweiligen Frage-ID (N02-N04) — ein Dokument kann so mehrere Angaben belegen, ohne mehrfach hochgeladen zu werden.

## 7. Offene Fragen an Nils

### Durch Update 1 erledigt (vormals offen)

- **Betrag/Währung:** jetzt durchgehend strukturiert vorgegeben (`Kosten.betrag`/`.waehrung`, `Abrechnungen.betrag`/`.waehrung` usw.) statt als Kanzleientscheid ergänzt — erledigt.
- **Raumart-Katalog:** R01 gibt den Katalog selbst vor (`Raeume.raumart`, 9 Werte) — erledigt, keine Kanzleientscheidung mehr nötig.
- **Obergrenze Geschäftsvorgänge:** entfällt; N01 sieht "je tatsächlich ausgeübtem wesentlichem Bereich ein Fall" vor, ohne feste Obergrenze (`Entscheidungsfaelle.n01_bereich` als MultiChoice, beliebig viele referenzierte Fälle über `Belegverknuepfungen`) — erledigt.

### Neu bzw. weiterhin offen

1. **Zugriffsschutz der öffentlichen Formulare:** B4 stellt ausdrücklich fest, dass öffentliche Formularparameter (`ErfassungID`, `ResponseID`) kein Berechtigungsnachweis sind, ohne ein Gegenmittel vorzugeben (anders als das `access_code`-Muster der steuerlichen Erfassung, DE/AO). Es wurde bewusst **kein** `access_code`-Feld ergänzt, da Anhang B2 keines vorsieht. Bitte bestätigen, ob ein Zugangscode-Mechanismus (analog `0_Fallsteuerung.access_code`) ergänzt werden soll, oder ob eine andere Absicherung (z. B. nur Freigabe über personalisierte Links, kein offener "Jeder mit dem Link"-Zugang) ausreicht.
2. **`InterneBewertungen` — Berechtigungsgruppe:** Das Skript bricht die Rechtevererbung, kann die zulässige Prüfergruppe aber nicht automatisch bestimmen (siehe Abschnitt 5). Bitte Namen/Kennung der vorgesehenen internen Gruppe mitteilen, oder bestätigen, dass dies manuell nach dem ersten Lauf erledigt wird.
3. **`Vertragsvorgaenge` — "FallID"-Spalte in Anhang B2:** B2 listet für `Vertragsvorgaenge` eine Spalte "FallID", obwohl kein Vorgabetext einen Vertragsvorgang mit einem Entscheidungsfall verknüpft. Dieses Modul interpretiert die Spalte als allgemeinen Erfassungsbezug (`erfassung_ref` → `Erfassungen`), nicht als Fremdschlüssel auf `Entscheidungsfaelle`. Bitte bestätigen oder korrigieren.
4. **Stammdaten-Reichweite von `Gesellschaften`/`Personen` über mehrere Erfassungen hinweg:** Anhang B2 bindet beide Listen nicht an eine `ErfassungID`. Dieses Modul behandelt sie deshalb als über mehrere Erfassungszeiträume desselben Mandats hinweg wiederverwendbare Stammdaten (mit optionalem `project_id`/`project_id_text`-Feld zur Mehrmandantentrennung auf derselben Site, über B2 hinaus ergänzt). Bitte bestätigen, ob das der Absicht entspricht, oder ob stattdessen je Erfassungszeitraum ein frischer Gesellschafts-/Personenbestand gewünscht ist.
5. **`N01`-Bereichscodes vs. 22-Tätigkeiten-Katalog (Update 0):** N01 verwendet einen eigenen, kleineren 7-Werte-Katalog (`N01_BEREICH`: Kundengeschäft, Lieferantengeschäft, Personalentscheidung, Finanzierung, betriebliche Steuerung, Budget/Investition, andere Tätigkeit) statt der feingranularen P09-Bereiche/Handlungen. Das ist wörtlich aus der Vorgabe übernommen; bitte bestätigen, dass dieser bewusst gröbere Beispiel-Katalog so bleiben soll.
6. **Separate Site für `InterneBewertungen` (Alternative b, Abschnitt 5):** falls eine vollständige Site-Trennung gewünscht ist, sind die betroffenen Lookup-Spalten (`taetigkeit_ref`, `fall_ref`) durch Text-Referenzen zu ersetzen (SharePoint-Lookups sind site-lokal) — bitte vor einer Umsetzung entscheiden, da dies das Skript strukturell ändert.
