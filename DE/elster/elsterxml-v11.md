# ElsterBasis-XML-Schnittstelle (ElsterXML v11)

## 1. Zweck

Einheitliches Transportformat, das **jedes** ELSTER-Fachverfahren nutzt: `TransferHeader` (THeader) + `NutzdatenHeader` (NHeader) + `Nutzdaten`. Regelt Aufbau, Verschlüsselung, Signatur und Kommunikation der Datenlieferung — unabhängig vom fachlichen Inhalt der `Nutzdaten`. Ausführliche Aufbereitung des Grundgerüsts (Datenteile, Rückgabecodes, Online-/Offline-Unterscheidung, AES-Umstellung) steht bereits in [`../elster-transportschicht-und-verfahren.md`](../elster-transportschicht-und-verfahren.md); diese Seite fasst die paketspezifischen Fakten aus dem Inventar zusammen.

## 2. Daten: Verfahren / Datenart / Vorgang

Das Paket selbst definiert kein eigenes Fachverfahren, sondern den **Tripel-Mechanismus** (Verfahren – Datenart – Vorgang), über den alle anderen Pakete adressiert werden.

| Vorgang | Bedeutung |
|---|---|
| `send-Auth` | signierte/authentifizierte Übermittlung |
| `send-NoSig` | unsignierte Anfrage / Statusabruf |
| `send-Auth-Part` | teilauthentifizierte Übermittlung (Sammellieferung) |

Die konkreten Verfahren/Datenart-Kombinationen, die über diese Vorgänge laufen, sind in `Verzeichnis_der_Datenarten.csv` gelistet (18 Zeilen, nur „offene Schnittstelle": Datenabholung, Lohn, Lohn2, KMV — siehe [`datenabholung.md`](datenabholung.md), [`elsterlohn-lstb.md`](elsterlohn-lstb.md), [`lavendel-elstam.md`](lavendel-elstam.md)).

Die Schema-Enums sind deutlich umfangreicher als die CSV der offenen Schnittstelle:

| Schema | Umfang | Hinweis |
|---|---|---|
| `headerbasis_verfahren.xsd` | ~80 Verfahren | Vollkatalog inkl. ERiC-only-Verfahren |
| `headerbasis_datenarten.xsd` | ~854 Datenarten | Vollkatalog inkl. ERiC-only-Datenarten |

Diese ~854 Datenarten decken u. a. die ERiC-Formularverfahren (ESt, KSt, UStVA, GewSt, ErbSt …) ab, die **nicht** über die offene Schnittstelle nutzbar und in den ELSTER-Entwickler-Paketen nicht mit Feld-/Kennziffernkatalogen dokumentiert sind (siehe Abschnitt 5 „Gaps").

## 3. Taxonomie / Kataloge

- `Verzeichnis_der_Datenarten.csv` — offene-Schnittstelle-Ausschnitt (18 Zeilen).
- `headerbasis_verfahren.xsd`, `headerbasis_datenarten.xsd` — Vollkataloge (Enum-Schemata).
- Authentifizierung V02.2.1, ELSTER-Token-Spezifikation 1.27 — siehe [`../elster-transportschicht-und-verfahren.md`](../elster-transportschicht-und-verfahren.md) Abschnitt B/D.
- Encoding UTF-8; AES-Verschlüsselung ab Doku-Version 4.3.0 (Dezember 2025).

## 4. Quellen

- Paket: `ElsterXML-Schnittstelle_V11_2026.7.20.0.zip`, Version 2026.7.20.0, Doku-Version 4.3.0 (Stand 12.2.2026). Lokal vollständig extrahiert.
- `extracted/ElsterXML-Schnittstelle_V11_2026.7.20.0/v11/{Dokumente,Schemata,Schemadokumentation}/`
  - `Dokumente/Einheitliche_Datenschnittstelle_XML_11.pdf`
  - `Dokumente/Einheitliche_Datenschnittstelle_XML_Authentifizierung_V02.2.1.pdf`
  - `Dokumente/Spezifikation_ELSTER-Token_1.27.pdf`
  - `Dokumente/Verzeichnis_der_Datenarten.csv`
  - `Dokumente/kleine_Uebersicht.txt`
  - `Schemata/elster11_bisNH_extern.xsd`, `Schemata/header/`
- Portal-Name: `ElsterXML-Schnittstelle_V11_2026.7.20.0.zip` (unter `https://download.elster.de/download/schnittstellen/`).

## 5. Gaps / offene Punkte

- Die ~854 Datenarten in `headerbasis_datenarten.xsd` sind nur als Enum-Namen vorhanden, nicht mit Feldkatalogen hinterlegt. Die Formularfeldkataloge zu ESt/KSt/USt-VA/GewSt/ErbSt/Einspruch/steuerliche Erfassung liegen **nicht** in den ELSTER-Entwickler-Paketen, sondern (soweit im Repo vorhanden) unter `DE/AO/formulardaten-roherfassung.md` und `DE/AStG/formulardaten-mitteilung-6-astg.md`. Sie sind hier bewusst **nicht** erfunden.
- `Verfahren_DatenArt_Vorgang_v*.xml` (vollständige maschinenlesbare Verfahren-Datenart-Vorgang-Liste aus dem COALA-Downloadbereich) liegt nicht im gesichteten Bestand.
