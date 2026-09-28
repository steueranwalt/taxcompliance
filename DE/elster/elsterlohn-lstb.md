# ElsterLohn / Lohnsteuerbescheinigung 1.36 — ⚠️ ZIP fehlt lokal

> **Diese Seite basiert nur auf dem Portal-Eintrag und der begleitenden Auswertung, nicht auf dem entpackten Entwicklerpaket.** Das ZIP (`ElsterLohn_Lohnsteuerbescheinigung_1.36.zip`, ~58 MB) wurde beim Scan 2026-09-28 **nicht** heruntergeladen. Alle Aussagen hier sind entsprechend vorläufig.

## 1. Zweck

Einreichung von Lohnsteuerbescheinigungen durch den Arbeitgeber. Laut Auswertung das **einzige** Portal-Paket mit einem kompletten Kennziffern-Formularmuster — also fachlich der am ehesten mit einem „ERiC-Formular" vergleichbare Baustein unter den ELSTER-Entwickler-Paketen, obwohl es kein ERiC-Paket ist.

**Wichtiger Verfahrenswechsel:** Die Portal-Dokumentation zu ElsterLohn/LStB gilt nur bis **VZ 2025**. Ab **VZ 2026** ist produktiv das Nachfolgeverfahren **ElsterKMV** mit der Datenart **LSTMitteilung** zu verwenden; die zugehörige neue Dokumentation liegt nicht mehr im ELSTER-Entwickler-Portalordner, sondern unter **www.esteuer.de**.

## 2. Daten: Verfahren / Datenart / Vorgang

| Verfahren | Datenart | Vorgang | Hinweis |
|---|---|---|---|
| ElsterLohn | LStB | send-Auth / send-Auth-Part | gültig bis VZ 2025 |
| ElsterLohn | Lohnersatzleistung | send-Auth / send-Auth-Part | gültig bis VZ 2025 |
| ElsterKMV | LSTMitteilung | send-Auth / send-Auth-Part | **ab VZ 2026 produktiv** |
| (nur in Auswertung erwähnt) | LStBStorno | — | im ZIP nicht verifiziert (ZIP fehlt) |
| (nur in Auswertung erwähnt) | eTIN-Ermittlung | — | nur Altfälle bis VZ 2022 |

Diese Tripel stammen aus `Verzeichnis_der_Datenarten.csv` (Paket ElsterXML v11) und der Portal-/Auswertungs-Dokumentation, **nicht** aus dem ElsterLohn-ZIP selbst.

## 3. Taxonomie / Kataloge

- Kennziffern-Formularmuster (`Muster_LSTB_2025.pdf` o. ä.) liegt **nicht** lokal vor — laut Portal/Auswertung im ZIP enthalten. Für eine belastbare Kennziffern-Feldliste ist der Download des Pakets erforderlich (siehe Gaps).
- Verwandte Datenabholung-Datenarten (`ElsterLohnDaten`, `ElsterLohn2Daten`, `ElsterKMVDaten`) sind in [`datenabholung.md`](datenabholung.md) dokumentiert.

## 4. Quellen

- **Nicht lokal vorhanden:** `ElsterLohn_Lohnsteuerbescheinigung_1.36.zip` (Portal-Stand 28.08.2024, Version 1.36, ~58 MB).
- `schnittstellen.html` (Portal-Dump, Stand ~2026-07-24) — Quelle für Verfahrensname, Version und den ElsterKMV-Hinweis.
- `Auswertung_SharePoint_und_Schnittstelle.md` (kanzleiinterne Begleitanalyse, nicht Teil dieses Repos) — Quelle für LStBStorno/eTIN-Erwähnung und die Einschätzung „einziges Paket mit komplettem Formularmuster".
- Portal-Hinweis auf esteuer.de für die Nachfolgedokumentation ElsterKMV/LSTMitteilung (URL nicht im Inventar hinterlegt, nur als Fundstelle benannt).

## 5. Gaps / offene Punkte

- **ZIP fehlt** — Priorität laut Inventar „hoch (Muster)": Download erforderlich, um den vollständigen Kennziffernkatalog von LStB (bzw. dessen Struktur als Referenz für andere Formularkataloge) zu erfassen.
- Für den produktiven Fall (VZ 2026 ff.) fehlt die ElsterKMV-/LSTMitteilung-Dokumentation vollständig — muss separat von esteuer.de bezogen werden.
- Storno-Datenart `LStBStorno` und die eTIN-Regelung sind nur aus der Auswertung übernommen und im ZIP nicht verifizierbar, solange dieses fehlt.
- Dieses Paket ist **kein** Ersatz für die fehlenden ERiC-Formularpakete zu ESt/KSt/USt-VA/GewSt/ErbSt — es deckt ausschliesslich Lohnsteuerbescheinigungen ab.
