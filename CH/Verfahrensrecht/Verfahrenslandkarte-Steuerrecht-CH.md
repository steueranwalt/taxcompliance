# Verfahrenslandkarte Schweizer Steuerrecht (Bund)

**Rechtsstand:** 29.09.2026  
**Zweck:** Grundlage für Rechtsanalyse, Skills/Bots und Prozessflows. Korrespondiert strukturell mit dem deutschen Verfahrens- und Fristenregister.

> **Kanonische Reihenfolge:** Allgemeiner Teil → Besteuerungsverfahren (Ermittlung und Veranlagung/Festsetzung) → Steuererhebung/Bezug → Steuervollstreckung → Rechtsmittel/Prozess → Änderungsverfahren → Buchprüfung/Kontrolle → Steuer-/Verwaltungsstrafverfahren → Einzelsteuerarten → internationales Steuerverfahren → Verjährung/Verwirkung.

## 1. Allgemeiner Teil

Querschnitt: Zuständigkeit, Parteistellung, Vertretung, rechtliches Gehör, Akteneinsicht, Mitwirkung/Edition, Beweis, Verfügung/Entscheid, Eröffnung/Zustellung, Fristberechnung, Fristenstillstand, Wiederherstellung und Rechtskraft.

## 2. Besteuerungsverfahren

### 2.1 Ermittlung der Besteuerungsgrundlagen
```text
steuerlich relevantes Ereignis
→ Erklärung/Meldung oder Ermittlung von Amtes wegen
→ Mitwirkung/Edition
→ Sachverhalts- und Beweiserhebung
→ Bemessungsgrundlage
→ Veranlagung/Festsetzung/Verfügung
```

### 2.2 Veranlagung/Festsetzung und Einsprache
Ordentliche Veranlagung, Ermessensveranlagung, Selbstdeklaration, Feststellungsverfügung und Einsprache werden als unterscheidbare Prozesszweige geführt.

## 3. Steuererhebung / Steuerbezug

Fälligkeit → Zahlung/Verrechnung → Verzinsung → ggf. Stundung/Ratenzahlung → Erlass → Sicherstellung → Rückerstattung → Bezugsverjährung.

## 4. Steuervollstreckung

Nicht erfüllte vollstreckbare Steuerforderung → Mahn-/Betreibungsphase → Rechtsöffnung bzw. steuerrechtliche Vollstreckungswirkung → Sicherungsmassnahmen → Abschluss. Schnittstellen zum SchKG werden explizit referenziert.

## 5. Rechtsmittel und Steuerprozess

Einsprache und spezialgesetzliche interne Rechtsbehelfe → kantonale Justizbehörden bzw. Bundesverwaltungsgericht → Bundesgericht. Eigene Zweige: Zwischenentscheide, aufschiebende Wirkung, vorsorgliche Massnahmen, Rechtsverweigerung/Rechtsverzögerung und ausserordentliche Rechtsmittel.

## 6. Änderungs- und Korrekturverfahren

Revision, Nachsteuer, Berichtigung und die innerstaatliche Umsetzung internationaler Verständigungsvereinbarungen werden als eigenständige State Machines geführt. Rechtskraftdurchbrechung, relative und absolute Fristen sind getrennte Zustände.

## 7. Steuerliche Buchprüfungen und Kontrollen

```text
Prüfungsanlass
→ Ankündigung/Anordnung soweit vorgesehen
→ Mitwirkung/Edition
→ Prüfung/Kontrolle
→ Feststellungen
→ rechtliches Gehör
→ steuerartspezifische Folgehandlung
→ Verfügung/Veranlagung/Nachsteuer/Strafverfahren
→ Rechtsmittel
```

## 8. Steuerstraf- und Verwaltungsstrafverfahren

Getrennte Prozessfamilien für DBG/StHG, MWSTG, VStG, StG und VStrR. Der Übergang aus einem Besteuerungs- oder Kontrollverfahren in ein Strafverfahren ist als Ereignis mit eigenem Rechte- und Fristenregime abzubilden.

## 9. Besonderheiten nach Einzelsteuerarten

Direkte Bundessteuer/StHG, MWST, Verrechnungssteuer und Stempelabgaben erhalten jeweils eigene Unterflows für Festsetzung/Veranlagung, Bezug, Kontrolle, Rechtsmittel, Korrektur, Verjährung und Strafverfahren.

## 10. Internationales Steuerverfahren

### 10.1 DBA / Verständigungsverfahren
```text
bestehende oder drohende abkommenswidrige Besteuerung
→ anwendbares DBA und Protokoll bestimmen
→ Antragsfrist bestimmen
→ MAP-Antrag bei zuständiger Behörde
→ Eintretens-/Vollständigkeitsprüfung
→ zwischenstaatliche Verhandlung
→ Verständigungsvereinbarung
→ Annahme/Zustimmung soweit erforderlich
→ innerstaatliche Umsetzung nach StADG
→ ggf. Umsetzungsverfügung und Rechtsmittel
```

### 10.2 DBA Deutschland–Schweiz
Das DBA DE–CH wird als Referenzabkommen vollständig verfahrensbezogen inventarisiert. Erfasst werden MAP, gegebenenfalls Schiedsverfahren, Verhältnis zu innerstaatlichen Rechtsmitteln, Quellen-/Verrechnungssteuerentlastung, Rückerstattung und alle Fristen aus Abkommen, Protokoll, Änderungsprotokollen und einschlägiger Verwaltungspraxis. Die jeweilige geltende Fassung ist versionsbezogen zu bestimmen.

### 10.3 OECD-Musterabkommen
Art. 25 OECD-MA und die OECD-MAP-Praxis werden als Referenzmodell hinterlegt. Fristen daraus werden nicht automatisch auf ein konkretes DBA übertragen.

### 10.4 StADG
Das StADG wird als eigene Verfahrensschicht modelliert: Verständigungsverfahren, Umsetzung von Verständigungsvereinbarungen, DBA-bezogene Entlastungs-/Erstattungsverfahren und weitere vom Gesetz erfasste internationale Abkommensverfahren.

### 10.5 ESTV/SIF-Verwaltungspraxis
Kreisschreiben, Rundschreiben, Wegleitungen, Länderinformationen und sonstige Praxispublikationen werden mit Dokument-ID, Version/Gültigkeitsdatum und betroffenen Prozess-/Frist-IDs referenziert. Sie dürfen Gesetz oder DBA nicht überschreiben.

### 10.6 Internationale Amtshilfe
StAhiG-Verfahren bleiben von MAP getrennt: Ersuchen → Informationsbeschaffung → Information/Parteirechte → Schlussverfügung → BVGer → gegebenenfalls BGer.

## 11. Verjährung und Verwirkung

Jede Verjährung/Verwirkung wird als Zustandsmaschine modelliert: Start-Ereignis → Lauf relative Frist → Stillstand → Unterbrechung/Neubeginn → relative Frist → absolute Höchstfrist → Rechtsfolge.

## 12. Prozessdatenmodell

```yaml
process_id:
parent_process_id:
procedure_family:
tax_type:
trigger:
entry_conditions:
authority:
party_role:
states:
  - state_id:
    event:
    action:
    deadline_ids: []
    limitation_ids: []
    required_inputs: []
    decision_gate:
    next_states: []
decision_type:
remedy_ids: []
parallel_process_ids: []
legal_sources: []
administrative_guidance: []
valid_from:
valid_to:
verification_status:
```

## 13. Detailmatrix

### 13.1 Bestehende Verfahrensmatrix

| ID | Verfahren | Typischer Auslöser | Verwaltungsstufe | Erstentscheidung | Rechtsmittelkette bis letzte Instanz | Fristenanker |
|---|---|---|---|---|---|---|
| CH-P-DBG-01 | Ordentliche Veranlagung direkte Bundessteuer | Steuerperiode / Steuererklärung / Veranlagung von Amtes wegen | kantonale Veranlagungsbehörde | Veranlagungsverfügung | Einsprache → kantonale Steuerrekurskommission → ggf. weitere kantonale Instanz → Beschwerde in öffentlich-rechtlichen Angelegenheiten ans BGer | DBG 132 ff., 140 ff., 145; BGG 100 |
| CH-P-DBG-02 | Ermessensveranlagung | ungenügende Mitwirkung / fehlende Erklärung | kantonale Veranlagungsbehörde | Ermessensveranlagung | Einsprache nur wegen offensichtlicher Unrichtigkeit → kantonaler Rechtsweg → BGer | DBG 130 II, 132 III, 133 |
| CH-P-DBG-03 | Nachsteuer | nachträglich bekannt gewordene Tatsachen/Beweismittel | kantonale Steuerbehörde | Nachsteuerverfügung | Einsprache → kantonaler Rechtsweg → BGer | DBG 151–153, insb. Einleitungsverwirkung 10 Jahre |
| CH-P-DBG-04 | Revision rechtskräftiger Entscheid | Revisionsgrund | Behörde/Gericht, das entschieden hat | Revisionsentscheid | Rechtsmittel nach Verfahrensstufe → ggf. BGer | DBG 147–149; 90 Tage ab Entdeckung, absolut 10 Jahre |
| CH-P-DBG-05 | Berichtigung/Rechenfehler | Rechnungs-/Schreibfehler | zuständige Behörde | Berichtigungsentscheid | nach Spezialregel / ordentlicher Rechtsweg | DBG 150 |
| CH-P-DBG-06 | Steuererlass | Erlassgesuch | kantonale Behörde | Erlassentscheid | Rechtsweg nach DBG/kantonalem Recht; Zugang zum BGer gesondert prüfen | DBG 167 ff. |
| CH-P-DBG-07 | Sicherstellung | Gefährdung Steuerbezug | kantonale Verwaltung | Sicherstellungsverfügung | direkte Beschwerde nach DBG-System → ggf. BGer | DBG 169 |
| CH-P-DBG-08 | Steuerstrafverfahren DBG | Verdacht Verfahrenspflichtverletzung/Hinterziehung | kantonale Behörde | Straf-/Bussenentscheid | Einsprache/Rekurs nach DBG/kantonalem Verfahrensweg → BGer | DBG 174 ff., 182 ff., Verjährung Art. 184 |
| CH-P-STHG-01 | Kantons-/Gemeindesteuer Veranlagung | Steuerperiode | kantonale Steuerbehörde | Veranlagung | Einsprache → unabhängige Justizbehörde → ggf. zweite kantonale Instanz → BGer | StHG 48 ff.; kantonales Recht konkretisiert |
| CH-P-STHG-02 | Nachsteuer kantonal | neue Tatsachen | kantonale Steuerbehörde | Nachsteuerentscheid | kantonaler Rechtsweg → BGer | StHG 53 |
| CH-P-STHG-03 | Revision kantonal | Revisionsgrund | zuständige kantonale Instanz | Revisionsentscheid | kantonaler Rechtsweg → BGer | StHG 51 |
| CH-P-MWST-01 | MWST Selbstveranlagung / Abrechnung | Ende Abrechnungsperiode | ESTV | zunächst Abrechnung; bei Streit Verfügung | Einsprache ESTV → BVGer → BGer | MWSTG 71 ff., 81 ff.; VwVG subsidiär/soweit verwiesen |
| CH-P-MWST-02 | MWST Kontrolle / Einschätzungsmitteilung | Kontrolle / Differenz | ESTV | Einschätzungsmitteilung, bei Bestreitung Verfügung | Einsprache → BVGer → BGer | MWSTG 78 ff., 82 ff.; Verjährung Art. 42 |
| CH-P-MWST-03 | MWST Feststellungsverfügung/Ruling-nahe Feststellung | schutzwürdiges Interesse / Gesuch | ESTV | Verfügung | Einsprache → BVGer → BGer | MWSTG 82; VwVG |
| CH-P-MWST-04 | MWST Steuererlass | Gesuch | ESTV | Verfügung | Einsprache/Beschwerde gemäss MWSTG → BVGer → ggf. BGer | MWSTG 92 |
| CH-P-MWST-05 | MWST Sicherstellung/Vollstreckung | Gefährdung/ausstehende Forderung | ESTV | Sicherstellungs-/Vollstreckungsmassnahme | Spezialrechtsmittel → BVGer/BGer je Entscheid | MWSTG 93 ff.; SchKG-Bezüge |
| CH-P-MWST-06 | MWST Strafverfahren | Verdacht Widerhandlung | ESTV / Strafbehörde | Strafbescheid/Strafverfügung | Einsprache/gerichtlicher Weg nach VStrR → ggf. BGer | MWSTG 96 ff.; VStrR |
| CH-P-VST-01 | Erhebung Verrechnungssteuer | steuerbarer Ertrag / Leistung | ESTV | Steuerforderung; bei Streit Entscheid | Einsprache ESTV → BVGer → BGer | VStG 16, 38 ff., 42 ff. |
| CH-P-VST-02 | Meldeverfahren statt Entrichtung | meldefähige Leistung | ESTV | Anerkennung/Verweigerung; ggf. Entscheid | Einsprache → BVGer → BGer | VStG/VStV, tatbestandsspezifische Meldefristen |
| CH-P-VST-03 | Rückerstattung natürliche/juristische Person | Rückerstattungsantrag | Kanton bzw. ESTV je Anspruchsberechtigtem | Rückerstattungsentscheid | kantonaler Rechtsweg oder Einsprache ESTV → BVGer → BGer | VStG 29 ff., 48 ff.; Verwirkung Art. 32 |
| CH-P-VWV-01 | Allgemeines Bundesverwaltungsverfahren in Steuersachen | Gesuch oder Verwaltungshandlung, soweit Spezialsteuerrecht nicht abschliessend | Bundesbehörde | Verfügung | Beschwerde nach VwVG/VGG → BVGer → BGer | VwVG 20–24, 50 ff.; VGG; BGG |
| CH-P-BVGER-01 | Beschwerde ans Bundesverwaltungsgericht | anfechtbare Verfügung | BVGer | Urteil/Entscheid | BGer, soweit zulässig | VwVG 50 ff.; VGG; BGG 82 ff., 100 |
| CH-P-BGER-01 | Beschwerde in öffentlich-rechtlichen Angelegenheiten | kantonal letztinstanzlicher oder BVGer-Endentscheid | Bundesgericht | Bundesgerichtsurteil | Revision BGer als ausserordentliches Rechtsmittel | BGG 82 ff., 90 ff., 100; Revision 121 ff. |
| CH-P-EIL-01 | Vorsorgliche Massnahmen / aufschiebende Wirkung | drohender Vollzug / Eilbedürftigkeit | jeweilige Behörde/Gericht | Zwischenentscheid | selbständige Anfechtung nur unter gesetzlichen Voraussetzungen | VwVG 55/56; BGG 93; Spezialgesetze |
| CH-P-REV-01 | Revision Bundesverwaltungsverfahren | Revisionsgrund | zuständige Instanz | Revisionsentscheid | nach einschlägigem Instanzenzug | VwVG 66 ff. bzw. Spezialgesetz |
| CH-P-REV-02 | Revision Bundesgericht | Revisionsgrund | BGer | Revisionsurteil | kein ordentliches nationales Rechtsmittel | BGG 121 ff., Fristen Art. 124 |

### 13.2 Bestehende Standardabläufe

### 2.1 Direkte Bundessteuer
```text
Steuerperiode
→ Erklärung / Mitwirkung
→ Veranlagung (ggf. Ermessen)
→ Zustellung Veranlagungsverfügung
→ 30 Tage Einsprache
→ Einspracheentscheid
→ 30 Tage Beschwerde an kantonale Steuerrekurskommission
→ ggf. zweite kantonale Gerichtsinstanz
→ grundsätzlich 30 Tage Beschwerde ans Bundesgericht
→ Rechtskraft
→ ggf. Revision / Nachsteuer / Berichtigung
→ Bezug / Vollstreckung / Bezugsverjährung
```

### 2.2 MWST
```text
Steuerpflicht / Abrechnungsperiode
→ Selbstdeklaration und Zahlung
→ ggf. Kontrolle / Einschätzungsmitteilung
→ bei Streit: Verfügung
→ Einsprache bei ESTV
→ Beschwerde Bundesverwaltungsgericht
→ Beschwerde Bundesgericht
→ Rechtskraft / Bezug
→ ggf. Revision / Erlass / Vollstreckung
```

### 2.3 Verrechnungssteuer, Erhebung
```text
steuerbare Leistung
→ Deklaration/Entrichtung oder Meldeverfahren
→ ggf. Entscheid ESTV
→ Einsprache
→ Bundesverwaltungsgericht
→ Bundesgericht
→ Bezug/Vollstreckung
```

### 2.4 Verrechnungssteuer, Rückerstattung
```text
steuerbelastete Leistung
→ Rückerstattungsantrag innerhalb Verwirkungsfrist
→ kantonale Behörde oder ESTV
→ Entscheid
→ jeweiliger Einsprache-/Beschwerdeweg
→ Bundesgericht
```

### 2.5 Ausserordentliche Korrektur
```text
rechtskräftiger Entscheid
→ Revisionsgrund entdeckt
→ Revisionsgesuch innerhalb relativer Frist
→ Prüfung absolute Frist
→ Revisionsentscheid
→ neue Sachentscheidung oder Abweisung
→ Rechtsmittel nach anwendbarem Verfahrensrecht
```

### 13.3 Verbindung zum Fristenregister

Jeder Prozessschritt soll mindestens folgende Schlüssel tragen:

```yaml
prozess_id: CH-P-...
schritt:
ausloeser:
entscheidform:
frist_id: CH-F-...
rechtsmittel:
naechste_instanz:
aufschiebende_wirkung:
rechtskraft:
quelle:
rechtsstand:
pruefstatus:
```

### 13.4 Abgrenzung und Ausbau

Die Karte bildet zunächst die bundesrechtlich zentralen Steuerverfahren ab. Noch separat zu inventarisieren sind insbesondere Stempelabgaben, internationale Amtshilfe (StAhiG), automatischer Informationsaustausch, Verständigungs-/Schiedsverfahren nach DBA und StADG, Zoll/Einfuhrsteuer-Sonderverfahren, Wehrpflichtersatz, Schwerverkehrsabgaben sowie kantonale Besonderheiten aller 26 Kantone. Bei StHG-Verfahren ist stets das kantonale Verfahrensrecht zusätzlich zu prüfen.

## 14. Quellen

Amtliche konsolidierte Erlasse über Fedlex, insbesondere DBG SR 642.11, StHG SR 642.14, VwVG SR 172.021, MWSTG SR 641.20, MWSTV SR 641.201, VStG SR 642.21, VStV SR 642.211, BGG SR 173.110 und VGG SR 173.32.

## 15. SharePoint-Kartographie der Wissensbasis

Die Prozesslandkarte referenziert die interne SharePoint-Wissensbasis auf Dokumentebene. Die Referenz ist Provenienz, nicht Rechtsquelle eigener Art.

| Prozessfamilie | Interne Wissensknoten |
|---|---|
| Allgemeiner Teil / Rechte im Verfahren | `wiki/Steuerverfahrensrecht_CH/`; ergänzend vergleichend `wiki/Steuerverfahrensrecht_DE/` |
| Besteuerungsverfahren | `wiki/Steuerverfahrensrecht_CH/EinkVermSteuer_1.md`, `EinkVermSteuer_2.md`, `GewinnKapitalSteuer_1.md`, `GewinnKapitalSteuer_2.md` |
| Rechtsmittel | `wiki/Steuerverfahrensrecht_CH/Rechtsmittel-gegen-einkommens-vermoegenssteuerveranlagungen_CH_2018.md` |
| Revision/Korrektur | `wiki/Revision/`; `wiki/Korrekturen/` |
| Nachsteuer | `wiki/Steuerverfahrensrecht_CH/Nachsteuern Verfahren.md`; `Nachsteuern Verjaehrung.md`; `Nachsteuersteuern Allgemeines AG.md` |
| Steuerstrafverfahren | `wiki/Steuerverfahrensrecht_CH/Die Straftatbestände - kurz beleuchtet.md` |
| Tax Compliance / materielle Pflichten | `wiki/Tax Compliance/Tax-Compliance-Schweiz-Pflichten.md`; `Tax_Compliance_DE_CH_2026.xlsx` |
| MAP / DBA DE-CH | `wiki/importiert/05 eigene Literatur/01 Wassermeyer DBA/01 Schweiz/Bd5-Schweiz-026_fortgeschrieben.docx` (Art. 26) |
| Informationsaustausch / StAhiG | `.../Bd5-Schweiz-027_fortgeschrieben_2026-06-27.docx` (Art. 27); `wiki/Amtshilfe und Rechtshilfe/`; `wiki/Informationsaustausch/` |
| DBA-Missbrauch → Konsultation | `.../Bd5-Schweiz-023 fortgeschrieben.docx` (Art. 23 Abs. 2 → Art. 26 Abs. 3) |
| APA | `wiki/Vorabverständigung/`; Art.-26-Kommentierung |
| Doppelbesteuerung | `wiki/Doppelbesteuerung/` |
| internationale/koordinierte Prüfung | `General/01 Internationales Steuerrecht/Verrechnungspreise/Koelner Tage Internationale Verrechnungspreise Seminarunterlagen 2026-09-24.pdf` |

### 15.1 Erkenntnisse für das Prozessmodell

Die Art.-26-Kommentierung bestätigt, dass MAP nicht als blosser Rechtsmittel-Unterfall modelliert werden darf. Zu unterscheiden sind: Verständigungsverfahren auf Antrag, Konsultationsverfahren, APA/Vorabverständigung und Schiedsverfahren. Zusätzlich sind Tatsachenfeststellung/Aussenprüfung, Informationsaustausch nach Art. 27, innerstaatliche Rechtsmittel und die innerstaatliche Umsetzung einer Verständigung als verknüpfte, aber eigenständige Prozesse abzubilden.

Für das DBA DE-CH ist deshalb folgende Verfeinerung der State Machine vorgesehen:

```text
abkommenswidrige Besteuerung / drohende Besteuerung
→ MAP-Antrag
→ Zuständigkeits-/Zulässigkeits-/Vollständigkeitsprüfung
→ einseitige Abhilfe möglich?
  → ja: nationale Abhilfe
  → nein: bilaterale Verständigung
→ Verständigung erreicht?
  → ja: Zustimmung/Annahme soweit erforderlich → innerstaatliche Umsetzung
  → nein: Voraussetzungen Schiedsverfahren prüfen
→ Schiedsverfahren
→ bindende Lösung nach Abkommensregime
→ innerstaatliche Umsetzung
```

Parallelzustände: innerstaatliches Rechtsmittel, Revision/Nachsteuer bzw. Festsetzungsverfahren, Informationsaustausch und gegebenenfalls Aussenprüfung.

### 15.2 Quellen-Governance

SharePoint-Pfade werden als stabile interne Wissensreferenzen erfasst. Für belastbare Automatisierung gilt: `eigene_notiz/seminar/kommentar → Primärquelle ermitteln → geltende Fassung bestimmen → Aussage verifizieren → verification_status = gegen_primaerquelle_verifiziert`. Historische Dokumente, etwa die Rechtsmittelübersicht 2018, werden nicht ohne Rechtsstandsprüfung als aktuelle Regelquelle verwendet.
