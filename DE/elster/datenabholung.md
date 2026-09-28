# ElsterDatenabholung v32.0.1

## 1. Zweck

Abholung von Daten, die die Finanzverwaltung im ELSTER-Postfach bereitstellt: Postfach-Nachrichten, Bescheide sowie VaSt-Belege (Vorausgefüllte Steuererklärung). Portal listet parallel v31.0.6 und v32.0.1; lokal nur v32.0.1 vorhanden (beide sollen laut Portal parallel gültig sein).

## 2. Daten: Verfahren / Datenart / Vorgang

| Verfahren | Datenart | Vorgang |
|---|---|---|
| ElsterDatenabholung | PostfachStatus | send-Auth / send-NoSig |
| ElsterDatenabholung | PostfachAnfrage | send-Auth / send-NoSig |
| ElsterDatenabholung | PostfachBestaetigung | send-Auth / send-NoSig |
| ElsterDatenabholung | Statusabfrage | laut SSb (nicht weiter spezifiziert im Inventar) |
| ElsterDatenabholung | ElsterVaStDaten | send-Auth |
| ElsterDatenabholung | ElsterLohnDaten | send-Auth |
| ElsterDatenabholung | ElsterLohn2Daten | send-Auth |
| ElsterDatenabholung | ElsterKMVDaten | send-Auth |

### Message-Typen (Schema `datenabholung_32.xsd`)

- Wurzel `Datenabholung` mit drei Anwendungsfällen: `Anfrage`, `Abholung`, `Statusabfrage`.
- Request/Response-Paare: `PostfachStatus`, `PostfachAnfrage`, `PostfachBestaetigung`.
- `Bereitstellungen` / `Bereitstellung` — enthält je Bereitstellung:
  - `Datenpaket`
  - `Anhaenge` — mit `Dateiname`, `Dateibezeichnung`, `Dateityp`, `DateiReferenzId` (Referenz auf ein OTTER-Objekt bei grossen Anhängen)
  - `MetaInformationen`
  - `VertreterInformation`
  - `Fingerprint` / `Abholzertifikat`

**Bestätigungspflicht:** Laut Auswertung-Dokumentation ist nach `PostfachAnfrage` binnen 24 h eine `PostfachBestaetigung` erforderlich (Detailfrist nicht im Schema selbst, sondern im SSb-PDF).

## 3. Taxonomie / Kataloge

- Filterung der Abholung über DIVA-Katalog `ELSTER-Dokumentengruppe` (Feld auch in Datenabholungs-Requests nutzbar) bzw. `DatenartBereitstellung` — siehe [`kataloge/diva-art-des-schreibens.md`](kataloge/diva-art-des-schreibens.md).
- Anhänge, die als eigenständiges Objekt referenziert werden, verweisen auf [`objektspeicher-otter.md`](objektspeicher-otter.md) (Objekt-ID/`DateiReferenzId`).
- Weitere Verfahren/Datenart-Kombinationen: siehe [`elsterxml-v11.md`](elsterxml-v11.md).

## 4. Quellen

- Paket: `ElsterDatenabholung-v32.0.1.zip`, Version 32.0.1 (Portal zusätzlich v31.0.6). Lokal vollständig extrahiert.
- `extracted/ElsterDatenabholung-v32.0.1/Dokumentation/SSb ElsterDatenabholung - Extern V32.0.1.pdf`
- `extracted/ElsterDatenabholung-v32.0.1/Schemata/datenabholung_32.xsd`
- `extracted/ElsterDatenabholung-v32.0.1/Schemata/elster11_datenabholung_32.xsd`
- `extracted/ElsterDatenabholung-v32.0.1/Beispiele_TH11/`
- Portal-Namen: `ElsterDatenabholung-v31.0.6.zip` (**nicht** lokal, niedrige Priorität laut Inventar — v32 deckt Inventar fachlich ab), `ElsterDatenabholung-v32.0.1.zip` (lokal).

## 5. Gaps / offene Punkte

- `ElsterDatenabholung-v31.0.6.zip` wurde nicht heruntergeladen (Inventar-Priorität „niedrig", da v32 fachlich ausreicht und parallel gültig bleibt).
- Genaue Frist/Ablauf der `PostfachBestaetigung`-Pflicht (24 h laut Auswertung) ist nicht im XSD selbst kodiert, sondern nur in der Prosa-Dokumentation — für eine belastbare Implementierungsaussage müsste die SSb-PDF im Volltext ausgewertet werden (hier nicht geschehen).
- Die Datenart `ElsterVaStDaten` verweist fachlich auf das separate Paket **VaSt-Informationen v1**, dessen ZIP nicht lokal vorliegt (siehe Repo-weite Gap-Liste in [`README.md`](README.md) Abschnitt 4).
- `Statusabfrage` ist im Inventar nur als „(laut SSb)" vermerkt — keine Detailfelder erfasst.
