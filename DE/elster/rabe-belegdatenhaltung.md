# RABE-Belegdatenhaltung v2.3 (+ Informationen für Hersteller 1.3)

## 1. Zweck

Externe Belegdatenhaltung — das Pull-Gegenmodell zu OTTER: Belege verbleiben auf einem Server der Kanzlei (bzw. des Herstellers), die Finanzverwaltung holt sie bei Bedarf dort ab, statt dass die Kanzlei sie aktiv zur Finanzverwaltung überträgt.

## 2. Daten: Verfahren / Datenart / Vorgang

Kein ElsterXML-Verfahren/keine Datenart — RABE ist eine **externe REST-Schnittstelle** (kein Bestandteil des Verfahren/Datenart/Vorgang-Tripels).

### REST-Endpunkte (OpenAPI `rabe-extern.yml`, Version 2.3)

| Endpunkt | Methode | Zweck |
|---|---|---|
| `/api/v1/belegpakete/{referenzId}` | GET | Metadaten zu Belegeinheiten (max. 20 pro Paket) |
| `/api/v1/belegeinheiten/{dateiId}` | GET | Einzelbeleg abrufen |
| `/api/v1/quittung/{anfrageId}` | POST/PUT | Quittung zur Abholung bestätigen |
| `/api/v1/alive` | GET | Health-Check |

### Schemata

- `rabe-extern-belegeinheiten.xsd` — Struktur der Belegeinheiten-Metadaten.
- `rabe-extern-quittung.xsd` — Struktur der Abhol-Quittung.

## 3. Taxonomie / Kataloge

Kein eigener Katalog. Fachliche Einordnung eines Belegs erfolgt extern über den Kontext der jeweiligen Anfrage (`referenzId`/`dateiId`), nicht über einen DIVA- oder Bescheidnummern-Katalog.

## 4. Quellen

- Paket: `RABE-Belegdatenhaltung_v2.3.zip`, Version 2.3 (Stand 09.04.2026). Lokal vollständig extrahiert.
  - `extracted/RABE-Belegdatenhaltung_v2.3/RABE-Belegdatenhaltung_v2.3/Dokumentation/RABE Client Extern_SSb_V2.3.pdf`
  - `extracted/RABE-Belegdatenhaltung_v2.3/RABE-Belegdatenhaltung_v2.3/OpenAPI/rabe-extern.yml`
  - `extracted/RABE-Belegdatenhaltung_v2.3/RABE-Belegdatenhaltung_v2.3/Schema/rabe-extern-belegeinheiten.xsd`
  - `extracted/RABE-Belegdatenhaltung_v2.3/RABE-Belegdatenhaltung_v2.3/Schema/rabe-extern-quittung.xsd`
- Begleit-PDF: `RABE_Informationen_fuer_Hersteller_Version_1.3.pdf`, Version 1.3 (Stand 27.11.2024) — fachliche/technische Hersteller-Infos, kein eigenes Schema-Paket, nur als Datei vorhanden (nicht extrahiert, da PDF).
- Portal-Namen: `RABE-Belegdatenhaltung_v2.3.zip`, `RABE_Informationen_fuer_Hersteller_Version_1.3.pdf`.

## 5. Gaps / offene Punkte

- Detailfelder der `belegeinheiten`- und `quittung`-XSD wurden aus dem Inventar nur auf Wurzel-/Endpunktebene erfasst, nicht bis auf Element-/Attributebene.
- Inhalt der Infos-für-Hersteller-PDF (1.3) wurde nicht im Volltext ausgewertet — nur als ergänzende Quelle referenziert.
