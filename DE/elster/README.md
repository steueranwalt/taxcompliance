# ELSTER-Entwicklerpakete: Formulare, Verfahren, Taxonomien

Ausgewertet aus dem OneDrive-Ordner `01 Projekte/ELSTER-Entwickler` (Scan 2026-09-28, Basisverzeichnis `/workspace/elster-entwickler`). Maschinenlesbare Quelle: [`inventar.json`](inventar.json) (18 Einträge, Snapshot des Original-Inventars). Diese Seite ist der Einstiegspunkt: eine Seite je Paket/Formular/Katalog, jeweils mit Zweck, Verfahren/Datenart/Vorgang bzw. Endpunkten, Taxonomie-Bezug, Quellen und offenen Punkten.

**Verhältnis zu den bestehenden Übersichtsdokumenten:** [`../elster-transportschicht-und-verfahren.md`](../elster-transportschicht-und-verfahren.md) und [`../elster-taxonomien-kataloge.md`](../elster-taxonomien-kataloge.md) bleiben als **fachliche Übersichten** bestehen (jetzt ergänzt um Verweise hierher); die Einzelseiten in diesem Ordner enthalten die paketspezifischen Details und die pro Paket klar markierten Lücken.

**Ausgeschlossen (bewusst):** `Test_Zertifikate*.zip`, `Test_Zertifikate_3072_Bit.zip` — keine Inventarisierung von Schlüsselmaterial/Zertifikatsinhalten in diesem Repo.

## 1. Paketübersicht

| Paket/Katalog | Version | Verfahren | Lokal | Typ | Detailseite |
|---|---|---|---|---|---|
| ElsterBasis-XML-Schnittstelle | 2026.7.20.0 / Doku 4.3.0 | Header für alle Verfahren | ja | Transport | [`elsterxml-v11.md`](elsterxml-v11.md) |
| ElsterDatenabholung | 32.0.1 (+ Portal 31.0.6) | ElsterDatenabholung | ja | Empfang | [`datenabholung.md`](datenabholung.md) |
| ElsterObjektspeicher (OTTER) | 1.4.6 | OTTER (REST) | ja | Objekt-Push/Pull | [`objektspeicher-otter.md`](objektspeicher-otter.md) |
| ElsterLohn / LStB (+ ElsterKMV) | 1.36 | ElsterLohn → ab VZ 2026 ElsterKMV | **nein** (~58 MB) | Formular-Muster | [`elsterlohn-lstb.md`](elsterlohn-lstb.md) |
| ElsterKontoabfrage | 2.1.3 | ElsterKontoabfrage | ja | Abfrage | [`kontoabfrage.md`](kontoabfrage.md) |
| LAVENDEL Datenübermittler | 2.0.1 | ElsterLohn2 / LAVENDEL | ja | ELStAM | [`lavendel-elstam.md`](lavendel-elstam.md) |
| HMS Hersteller-Mock | 2.0.1 | ElsterLohn2 (Test) | ja | Mock | [`hms-mock.md`](hms-mock.md) |
| RABE-Belegdatenhaltung (+ Infos Hersteller) | 2.3 (+ 1.3) | RABE (REST Extern) | ja | Beleg-Pull | [`rabe-belegdatenhaltung.md`](rabe-belegdatenhaltung.md) |
| InvStG § 51 XML-Anhang | Doku v1 / Muster v3 | Bescheid-Anhang | ja (PDF+XML) | Anhang-Schema | [`invstg51-feststellung-anhang.md`](invstg51-feststellung-anhang.md) |
| Serverstatus RSS | — | — | ja (PDF) | Ops | [`serverstatus-rss.md`](serverstatus-rss.md) |
| DIVA Art des Schreibens | 21.0.0 | Filter in Datenabholung | ja | Katalog | [`kataloge/diva-art-des-schreibens.md`](kataloge/diva-art-des-schreibens.md) |
| ELSTER-Fehlerliste | Stand 24.11.2025 | — | ja (XML) | Katalog | [`kataloge/fehlerliste.md`](kataloge/fehlerliste.md) |
| Bescheidwertnummern ESt/GSt/USt | Januar 2026 | — | ja | Katalog | [`kataloge/bescheidnummern.md`](kataloge/bescheidnummern.md) |
| Finanzamtsdaten (GEMFA) | Stand 15.04.2026 | — | ja (xlsx) | Katalog | [`kataloge/finanzamtsdaten.md`](kataloge/finanzamtsdaten.md) |
| Prüfziffern Steuernummer/IdNr. (+ Grundsteuer) | Stand 15.04.2026 | — | ja (PDF) | Katalog | [`kataloge/pruefziffern-steuernummer-idnr.md`](kataloge/pruefziffern-steuernummer-idnr.md) |
| VaSt-Informationen | v1 (2013) | ElsterVaStDaten | **nein** | Doku | siehe [`datenabholung.md`](datenabholung.md) Abschnitt 5 (kein eigenes Paket, ZIP fehlt) |
| Portal-Dump `schnittstellen.html` | Stand ~2026-07-24 | — | ja | Index | Quelle für die Gap-Liste unten, keine eigene Detailseite |

**Nicht als eigenes Paket geführt, aber in dieses Repo eingeflossen:** die kanzleiinternen Begleit-MDs `Auswertung_SharePoint_und_Schnittstelle.md`, `Aenderungsbedarf_ELSTER_vs_Architektur_2026-07-24.md`, `SharePoint_Listenschema_ELSTER_Meldungen_2026-09-19.md` sind **keine** ELSTER-Pakete und nicht Teil dieses Repos (mandatsbezogene Architekturentscheidungen); sie werden nur als Quelle einzelner Zusatzangaben (z. B. ElsterLohn-Storno/eTIN) zitiert.

## 2. Offizielle Download-Basis

Alle Pakete stammen von `https://download.elster.de/download/schnittstellen/` (Portal-Dump `schnittstellen.html`, Stand ~2026-07-24).

## 3. ERiC-/Portal-Lücken (explizit)

### 3.1 Fachformulare / Erklärungen — **nicht** in den ELSTER-Entwickler-Paketen enthalten

Diese liegen typischerweise im separaten **ERiC-Entwicklerbereich** bzw. in jährlichen Steuerschnittstellen-Dokumenten und sind hier **nicht** vorhanden — sie werden **nicht erfunden**:

- Einkommensteuer (ESt 1A und Anlagen)
- Körperschaftsteuer (KSt)
- Umsatzsteuer-Voranmeldung / USt-Erklärung
- Gewerbesteuer-Erklärung
- Erbschaft-/Schenkungsteuer
- Grundsteuererklärung (Bundesmodell + Länder) — nur Prüfziffer-/Datenart-Hinweise vorhanden ([`kataloge/pruefziffern-steuernummer-idnr.md`](kataloge/pruefziffern-steuernummer-idnr.md)), keine Formular-XSD
- Einspruch / sonstige AO-Verfahrensschreiben (kein Entwicklerpaket)
- Fragebogen steuerliche Erfassung (4 Rechtsformen) — Feldkatalog bereits im Repo unter [`../AO/formulardaten-roherfassung.md`](../AO/formulardaten-roherfassung.md), **keine** ELSTER-ZIP/XSD hier
- BZSt2 § 138 Abs. 2 AO, ASt-Mitteilung § 6 AStG, erneute W-IdNr-Mitteilung — Repo-Feldkataloge unter [`../AO/README.md`](../AO/README.md) und [`../AStG/formulardaten-mitteilung-6-astg.md`](../AStG/formulardaten-mitteilung-6-astg.md), keine Entwicklerpakete hier
- eBilanzen / E-Bilanz-Taxonomien
- Anmeldungssteuern-Pakete (LStA, UStVA) als eigene COALA-Downloads

### 3.2 Portal-Downloads noch fehlend

| Datei | Priorität | Grund |
|---|---|---|
| `ElsterLohn_Lohnsteuerbescheinigung_1.36.zip` (~58 MB) | hoch (Muster) | Kennziffern-Feldkatalog; alternativ esteuer.de für ElsterKMV/LSTMitteilung ab VZ 2026 — siehe [`elsterlohn-lstb.md`](elsterlohn-lstb.md) |
| `VaSt-Informationen_v1.zip` | mittel | VaSt-Abholung fachlich (Datenart `ElsterVaStDaten`) — siehe [`datenabholung.md`](datenabholung.md) |
| `ElsterDatenabholung-v31.0.6.zip` | niedrig | parallel gültig; v32 reicht für Inventar |
| `Fehlerliste.pdf` | niedrig | XML vorhanden ([`kataloge/fehlerliste.md`](kataloge/fehlerliste.md)) |
| ERiC Common / Formularpakete (ESt, KSt, USt, GewSt, ErbSt, Grundsteuer, steuerliche Erfassung) | **kritisch** für Formularvollständigkeit | nicht im offenen Schnittstellen-Ordner |
| Dokumentation ElsterKMV / LSTMitteilung (esteuer.de) | hoch ab VZ 2026 | Nachfolger LStB |

### 3.3 Bewusst ausgeschlossen

- `Test_Zertifikate.zip`, `Test_Zertifikate_3072_Bit.zip` — keine Inventarisierung von Schlüsselmaterial.

## 4. Bezug zu bestehenden `DE/AO`- und `DE/AStG`-Feldkatalogen

| Thema | Wo im Repo | Bezug zu ELSTER-Entwickler |
|---|---|---|
| Fragebogen steuerliche Erfassung | [`../AO/formulardaten-roherfassung.md`](../AO/formulardaten-roherfassung.md) | Feldkatalog eigenständig gepflegt; **kein** ELSTER-Entwicklerpaket vorhanden (ERiC-Gap, siehe 3.1) |
| Einheitliches Datenmodell steuerliche Erfassung | [`../AO/Einheitliches-Datenmodell-steuerliche-Erfassung-DE-Auslandsbezug.md`](../AO/Einheitliches-Datenmodell-steuerliche-Erfassung-DE-Auslandsbezug.md) | nutzt u. a. Finanzamtsnummern/IdNr.-Logik, die hier in [`kataloge/finanzamtsdaten.md`](kataloge/finanzamtsdaten.md) / [`kataloge/pruefziffern-steuernummer-idnr.md`](kataloge/pruefziffern-steuernummer-idnr.md) katalogisiert sind |
| W-IdNr.: erneute Mitteilung | [`../AO/formulardaten-widnr-erneute-mitteilung.md`](../AO/formulardaten-widnr-erneute-mitteilung.md) | DIVA-Gruppe `WIdNrVA` (1 Schlüssel) — siehe [`kataloge/diva-art-des-schreibens.md`](kataloge/diva-art-des-schreibens.md) |
| ASt-Mitteilung § 6 AStG | [`../AStG/formulardaten-mitteilung-6-astg.md`](../AStG/formulardaten-mitteilung-6-astg.md) | eigenständiger Feldkatalog, kein ELSTER-Entwicklerpaket in diesem Scan |

## 5. Quellenhinweis

Fakten aus ZIP/XSD/PDF/HTML des gesichteten Bestands; alles Unbekannte ist in den Einzelseiten unter „Gaps / offene Punkte" markiert. Vollständiges maschinenlesbares Rohinventar: [`inventar.json`](inventar.json).
