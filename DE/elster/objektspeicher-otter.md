# ElsterObjektspeicher „OTTER" v1.4.6

## 1. Zweck

REST-basierter Objektspeicher für den Austausch **grosser** Objekte ausserhalb des ElsterXML-Nutzdatenblocks — primär für den Download im Rahmen der Datenabholung, daneben auch für den Upload grosser Anhänge. Kein ElsterXML-Verfahren im Sinne von Verfahren/Datenart/Vorgang, sondern eine parallele REST-Schnittstelle.

## 2. Daten: Verfahren / Datenart / Vorgang

Es gibt **kein** ElsterXML-Verfahren/keine Datenart für OTTER — die Schnittstelle ist rein REST-basiert (OpenAPI 3.0.3, Datei `otter.yml`, Version 1.4.6).

| Endpunkt | Methode | Zweck |
|---|---|---|
| `/api/v1/obj/{objektid}` | GET | Objekt abrufen (fetch) |
| `/api/v1/obj` | POST | Objekt einstellen (send) |
| `/api/v1/health` | GET | Health-Check |

**Authentifizierung:** Clientzertifikat (keine ElsterXML-Signatur).

**Header-Konzept:** `x-elster-empfaenger-typ` mit den Werten `ACCOUNT_ID`, `FINGERPRINT`, `ABHOLZERTIFIKAT` — steuert, wie der Empfänger eines Objekts identifiziert wird.

Objekt-IDs werden nicht isoliert verwendet, sondern im ElsterXML-Nutzdatenblock der Datenabholung referenziert (siehe `DateiReferenzId` in [`datenabholung.md`](datenabholung.md)).

## 3. Taxonomie / Kataloge

Kein eigener Katalog. Die Objekt-IDs sind Laufzeit-Referenzen, keine Taxonomiewerte; die fachliche Einordnung des referenzierten Objekts erfolgt über die DIVA-Metadaten in der Datenabholung (siehe [`kataloge/diva-art-des-schreibens.md`](kataloge/diva-art-des-schreibens.md)).

## 4. Quellen

- Paket: `ElsterObjektspeicher_v1.4.6.zip`, Version 1.4.6. Lokal vollständig extrahiert.
- `extracted/ElsterObjektspeicher_v1.4.6/ElsterObjektspeicher_v1.4.6/Dokumentation/OTTER-SSb-v1.4.6.pdf`
- `extracted/ElsterObjektspeicher_v1.4.6/ElsterObjektspeicher_v1.4.6/OpenAPI/otter.yml`
- Portal-Name: `ElsterObjektspeicher_v1.4.6.zip`.

## 5. Gaps / offene Punkte

- Frist für die Abholung eines eingestellten Objekts durch die Finanzverwaltung wird im bereits bestehenden Übersichtsdokument [`../elster-transportschicht-und-verfahren.md`](../elster-transportschicht-und-verfahren.md) mit „7-Tage-Frist" beschrieben; im hier ausgewerteten Inventar selbst nicht separat verifiziert — bei Bedarf gegen die OTTER-SSb-PDF im Volltext prüfen.
- Vollständige Fehlercode-/Statuscode-Liste der REST-Antworten (z. B. HTTP-4xx/5xx-Semantik) wurde aus der `otter.yml` nicht extrahiert; nur die drei Endpunkte sind hier erfasst.
