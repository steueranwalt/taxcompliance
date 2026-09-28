# ElsterLohn / Lohnsteuerbescheinigung 1.36

> **Update 2026-09-28 (Folge-Scan):** Das ZIP wurde inzwischen heruntergeladen und lokal extrahiert (`ElsterLohn_Lohnsteuerbescheinigung_1.36.zip`, ≈56 MB → ≈138 MB entpackt, `extracted/ElsterLohn_Lohnsteuerbescheinigung_1.36/`). Diese Seite basiert jetzt auf dem entpackten Paket (Schemata, SST-Dokus, BMF-Muster, XML-Beispiele), nicht mehr nur auf dem Portal-Eintrag.

## 1. Zweck

Elektronische Übermittlung von **Lohnsteuerbescheinigungen** (§ 41b EStG) an das Verfahren **RMS-KMV ElsterLohn** über die offene ElsterXML-Schnittstelle (TransferHeader v11).

Das Paket enthält Schemata, SST-Dokumentationen, BMF-Muster/Vordrucke und XML-Beispiele für LStB (Neu/Korrektur) sowie LStBStorno. Es ist das **einzige** Portal-Paket mit vollständigem Formularvordruck inkl. Kennziffern — insofern ein Referenzmuster für Feldkataloge weiterer ELSTER-Formulare, obwohl es selbst kein ERiC-Paket ist.

**Gültigkeit laut Portal:** Doku/Verfahren bis einschliesslich **VZ 2025**. Ab **VZ 2026** produktiv: Verfahren `ElsterKMV`, Datenart `LSTMitteilung` (neue Doku: [www.esteuer.de](https://www.esteuer.de/#kmv#lohnsteuerbescheinigung)) — **nicht** in diesem ZIP enthalten.

## 2. Daten: Verfahren / Datenart / Vorgang

| Verfahren | Datenart | Vorgang | Inhalt | Quelle |
|---|---|---|---|---|
| `ElsterLohn` | `LStB` | `send-Auth` / `send-Auth-Part` | Lohnsteuerbescheinigung Neu/Korrektur (§ 41b EStG); **auch Storno** (Nutzdaten-Root `LStBStorno`, gleiche Header-DatenArt `LStB`) | XML-Beispiele, Verfahrensablauf, `Verzeichnis_der_Datenarten.csv` |
| `ElsterLohn` | `Lohnersatzleistung` | `send-Auth` / `send-Auth-Part` | Lohnersatzleistungsbescheinigungen (§ 32b EStG) | Verfahrensablauf + CSV; **kein XSD/Beispiel in diesem ZIP** |
| `ElsterKMV` | `LSTMitteilung` | `send-Auth` / `send-Auth-Part` | Nachfolger LStB ab VZ 2026 | nur Portal/`schnittstellen.html` + CSV; **nicht im ZIP** |

Historischer Hinweis aus dem Verfahrensablauf: Datenart `RBM` (Rentenbezugsmitteilungen, ZfA) — bis 2014 über ElsterLohn, ab 2015 über KMV; `ProtokollAnforderung` entfällt mit TH11 (Abruf stattdessen über `ElsterDatenabholung` / Datenart `ElsterLohnDaten`, siehe [`datenabholung.md`](datenabholung.md)).

**TransferHeader-Beispiel (Neu 202501):** `Verfahren=ElsterLohn`, `DatenArt=LStB`, `Vorgang=send-Auth`, Empfänger-Ziel `CS`, NutzdatenHeader-Empfänger = Bundesland (`id="L"`).

### Nutzdaten-Wurzelelemente im Paket

| Root-Element | Namespace / Version | Anweisung `art` | Schema |
|---|---|---|---|
| `Lohnsteuerbescheinigung` | `http://finkonsens.de/rms/elo/lstb/vYYYY01`, `version="YYYY01"`, `art="ELStAM"` | `Neu` / `Korrektur` | `lstbYYYY01.xsd` (+ `_adapter.xsd`) |
| `LStBStorno` | v1: `…/LStBStornoV1/…`; v2: `http://finkonsens.de/rms/elo/lstbstorno/v2` | `Storno` | `lstb_storno_000001.xsd` / `000002.xsd` |

**LStB-Jahresversionen im Paket:** 201201, 201301, 201302, 201401, 201501, 201601, 201701, 201801, 201901, 202001, 202101, 202201, 202301, 202401, **202501** (aktuell).

**Korrektur (ab 2016):** `Anweisung art="Korrektur"` + `KmId` + `RefKmId` der Ursprungsmeldung. Ab LStB 202501 optional `KorrekturGrund` (`Einfache Berichtigung` | `Paragraph 41c`) — Pflicht bei Korrektur zu LStB 2025 ab 01.03.2026.

**Storno:** gleiche Header-DatenArt `LStB`; Nutzdaten enthalten nur `KmId`/`RefKmId`, `Zuflussjahr`, IdNr oder ETIN, Ordnungsmerkmal, Arbeitgeber. Storno v2 ab ~2022 (nur Namespace-Änderung, Inhalt entspricht v1).

**eTIN:** optionales Arbeitnehmer-Kennzeichen in älteren LStB-Schemas (noch in 202201, **nicht mehr** in 202301/202501) und optional in Storno. Referenz-Tool: `Tools/eTIN/` (Java). Nur für Altfälle relevant; IdNr ist Standard.

## 3. Taxonomie / Kataloge: Kennziffern LStB 202501

### Schema-Struktur (`lstb202501.xsd`)

Root `Lohnsteuerbescheinigung` → Sequenz:

1. **Anweisung** — `art`, `KmId`, optional `RefKmId`, optional `KorrekturGrund`
2. **Dauer** — `jahr`, `Anfang`/`Ende` (TTMM) → Formular-Nr. **1** (Bescheinigungszeitraum)
3. **Allgemein** — `IdNr`, `Ordnungsmerkmal`, `Person` (Name, Geburtsdaten, Adresse)
4. **Besteuerungsmerkmale** — `ELStAM` (Steuerklasse, Kinder, KiSt, Freibetrag/Hinzurechnung) *oder* historische Alternativen
5. **Besteuerungsgrundlagen** — nummerierte Bescheinigungswerte (Kennziffern) + Arbeitgeber

**Zählung (202501):** ca. **29** Schema-Elemente mit expliziter Kennziffer-Dokumentation (`N.` / `Na.`); plus unnummerierte Felder (Grossbuchstaben, Kammerbeitrag, Zusatzversorgung, …). Der Vordruck-Muster (`Muster_LSTB_2025.pdf`) listet Kennziffern **1–34** durchnummeriert (teils unbesetzt: 11–14, 19, 33).

Das Schema verwendet **sprechende Elementnamen**, nicht `kzNN`; die Kennziffern-Zuordnung steht in den XSD-Annotationen und im Vordruck-Muster.

### Kennziffer → XML-Feld (aus Schema-Annotationen `lstb202501.xsd`, Stichprobe)

| Kz | XML-Element | Kurzlabel |
|---|---|---|
| 1 | `Dauer` | Bescheinigungszeitraum |
| 2 | `AnzahlU` | Zeiträume ohne Anspruch auf Arbeitslohn |
| 3 | `BruttoArbLohn` | Bruttoarbeitslohn einschl. Sachbezüge |
| 4 | `LSteuer` | Einbehaltene Lohnsteuer von 3. |
| 5 | `Soli` | Einbehaltener Solidaritätszuschlag von 3. |
| 6 | `ArbnKiSteuer` | Einbehaltene Kirchensteuer AN |
| 7 | `EhegKiSteuer` | Einbehaltene Kirchensteuer Ehegatte |
| 8 | `VBez` | Versorgungsbezüge (in 3.) |
| 9 | `ErmStVBezMKalJahr` | Versorgungsbezüge für mehrere Kalenderjahre |
| 10 | `ErmStBetrMKalJahr` | Arbeitslohn mehrere KJ / Entschädigungen |
| 15 | `LeistungenProgVorbeh` | Leistungen Progressionsvorbehalt (z. B. Lohnersatz) |
| 15a | `KurzArbGeld` | (Saison-)Kurzarbeitergeld in 15. |
| 16a/b | `StFreiArbLohnDBA` / `StFreiArbLohnATE` | Steuerfreier Arbeitslohn DBA / ATE |
| 17 | `StFreiArbgLeistg` | Steuerfreie AG-Leistungen Entfernungspauschale |
| 18 | `PauschArbgLeistg` | Pauschal besteuerte AG-Leistungen Fahrten |
| 21 | `StFreiDopHaushalt` | Steuerfreie AG-Leistungen doppelte Haushaltsführung |
| 22a/b | `ArbgAnteilRenVers` / `ArbgAnteilBerufsVers` | AG-Anteil RV / berufsständisch |
| 23a/b | `ArbnAnteilRenVers` / `ArbnAnteilBerufsVers` | AN-Anteil RV / berufsständisch |
| 24a–c | `StFreiGeKrankVers` / `StFreiPrKrankVers` / `StFreiGePflegeVers` | Steuerfreie AG-Zuschüsse KV/PV |
| 25–27 | `ArbnAnteilKrankVers` / `ArbnAnteilPflegVers` / `ArbnAnteilArblVers` | AN-Beiträge KV / PV / AV |
| 28 | `BeitrPrKrankVers` | Beiträge private KV + Pflege-Pflicht |
| 34 | `FreibetragDbaTuerkei` | Freibetrag DBA Türkei |

**Ohne Formular-Nr. im Schema u. a.:** `Grossbuchstaben` (S, M, F, FR1–3), `Kammerbeitrag` (HB/SL), `ArbnAnteilWBUmlage`, Zusatzversorgung AG/AN, `AnzahlArbTag`, `StFreiFahrtKAusw`, `NErmStVBezMKalJahr`.

### Kennziffern 29–32 (aus dem Vordruck-Muster `Muster_LSTB_2025.pdf`, nicht in der obigen XSD-Stichprobe erfasst)

| Kz | Bezeichnung laut Vordruck |
|---|---|
| 29 | Bemessungsgrundlage für den Versorgungsfreibetrag zu 8. |
| 30 | Massgebendes Kalenderjahr des Versorgungsbeginns zu 8. |
| 31 | Zu 8. bei unterjähriger Zahlung: Erster und letzter Monat, für den Versorgungsbezüge gezahlt wurden |
| 32 | *(im PDF-Textextrakt unvollständig: „…zahlungen von Versorgungsbezügen — in 3. und 8. enthalten"; Zeilenanfang fehlt — vermutlich „Nachzahlungen", aber nicht sicher verifiziert)* |

**Unbesetzte Kennziffern laut Vordruck:** 11, 12, 13–14, 19, 33 (explizit als „unbesetzt" ausgewiesen). Kennziffer **20** taucht im PDF-Textextrakt nicht auf (Sprung von 19 auf 21) — ob dies eine echte Lücke in der Vordruck-Nummerierung ist oder ein Extraktionsartefakt des mehrspaltigen Formularlayouts, wurde **nicht** verifiziert (siehe Gaps).

**Bekannte Zeilenverluste im PDF-Textextrakt:** Kirchensteuer/Krankenversicherungs-Zeilen (Kz 6/7, 24a–c, 26) erscheinen im linearen Textextrakt teils verkürzt oder fehlend, weil der Vordruck mehrspaltig gesetzt ist. Die Schema-Stichprobe oben (aus den XSD-Annotationen) ist dafür die verlässlichere Quelle als der rohe PDF-Text.

### Taxonomie-Querbezug

- Keine CSV-Datei im Paket selbst — das Datenarten-Tripel steht in `Verzeichnis_der_Datenarten.csv` des ElsterXML-Pakets, siehe [`elsterxml-v11.md`](elsterxml-v11.md).
- Verwandte Datenabholung-Datenarten (`ElsterLohnDaten`, `ElsterLohn2Daten`, `ElsterKMVDaten`) sind in [`datenabholung.md`](datenabholung.md) dokumentiert.
- Kein DIVA-Bezug (LStB wird direkt zwischen Arbeitgeber und Finanzverwaltung übermittelt, nicht über die Postfach-Abholung mit DIVA-Filterung).

## 4. Quellen

Basis: `extracted/ElsterLohn_Lohnsteuerbescheinigung_1.36/ElsterLohn_Lohnsteuerbescheinigung_1.36/`

| Pfad | Inhalt |
|---|---|
| `readme.pdf` | Archiv-Struktur, Änderungslog 1.36 |
| `Doku/SST_ElsterLohn_Verfahrensablauf.pdf` | Verfahren, DatenArt/Vorgang, TH-Felder |
| `Doku/SST_ElsterLohn_Lohnsteuerbescheinigung.pdf` | Allgemeingültige LStB-Vorgaben (Korrektur/Storno) |
| `Doku/SST_ElsterLohn_Datenschnittstelle_LStB_202501.pdf` | Feldkatalog LStB 2025 (≈1,6 MB, 112 S.) |
| `Doku/SST_ElsterLohn_Datenschnittstelle_LStBStorno_*.pdf` | Storno v1/v2 |
| `Doku/SST_ElsterLohn_eTIN.pdf` | eTIN-Regelwerk |
| `Doku/SST_KMV_Datenschnittstelle_Protokoll_6.pdf` | Verarbeitungsprotokoll v6 |
| `Doku/BMF/YYYY/` | BMF-Bekanntmachungen Muster LStB |
| `Schemata/lstb202501.xsd` (+ Adapter) | Aktuelles Nutzdaten-Schema |
| `Schemata/lstb_storno_000002.xsd` | Storno v2 |
| `Schemata/elster11_elo_extern.xsd` | Wrapper: Choice aller LStB-/Storno-Roots |
| `Vordruck/Muster_LSTB_2025.pdf` | Kennziffern-Vordruck (≈96 KB) — Primärquelle für Abschnitt 3 |
| `XMLs/ELO_DatenLieferung_LStB_202501_{Neu,Korrektur}.xml` | Header+Nutzdaten-Beispiele |
| `XMLs/ELO_DatenLieferung_LStBStorno_v2_2025.xml` | Storno-Beispiel |
| `Tools/eTIN/` | Java eTIN-Referenz |
| `Doku_zu_XML/elster11_elo_extern.html` | HTML-Schemadoku (sehr gross) |

**Portal-Name:** `ElsterLohn_Lohnsteuerbescheinigung_1.36.zip`, Version 1.36 (Stand 22.08.2024, Portal 28.08.2024).

## 5. Gaps / offene Punkte

- **Datenart `Lohnersatzleistung`:** in Verfahrensablauf und `Verzeichnis_der_Datenarten.csv` genannt, aber **kein XSD, keine Beispiele, keine SST-Datei** im Archiv enthalten. Feldkatalog dafür bleibt unbekannt.
- **ElsterKMV / Datenart `LSTMitteilung` ab VZ 2026:** nur Portal-Hinweis; keine Schemata/Doku in diesem ZIP — muss separat von esteuer.de bezogen werden.
- **Kein CSV-Feldkatalog** im Paket (nur Vordruck-PDF + XSD-Annotationen + SST-PDF-Dokumentation).
- **eTIN** ab Schema-Version 202301 aus dem aktuellen LStB-Schema entfernt; nur noch in Storno, im Tool `Tools/eTIN/` und für Altfälle relevant.
- **`ProtokollAnforderung`** entfallen mit TH11; Protokollabruf läuft über `ElsterDatenabholung` (Datenart `ElsterLohnDaten`).
- **Kennziffern 29–32 und die Frage nach Kz 20** wurden nur aus dem rohen PDF-Textextrakt des Vordrucks abgeleitet, nicht gegen die XSD-Annotationen kreuzgeprüft (Abschnitt 3 markiert die verbleibende Unsicherheit bei Kz 32 und 20 explizit).
- Dieses Paket ist weiterhin **kein** Ersatz für die fehlenden ERiC-Formularpakete zu ESt/KSt/USt-VA/GewSt/ErbSt — es deckt ausschliesslich Lohnsteuerbescheinigungen (LStB) ab.
