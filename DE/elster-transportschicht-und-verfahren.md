# ELSTER-Transportschicht und Verfahrenstaxonomie

**Quelle:** `ElsterXML-Schnittstelle_V11_2026.7.20.0.zip` (Doku "Einheitliche Elster-Datenschnittstelle XML", Version 4.3.0, Stand 12.2.2026), `Verzeichnis_der_Datenarten.csv`, sowie die Fachpakete ElsterDatenabholung, ElsterKontoabfrage, ElsterObjektspeicher (OTTER), RABE-Belegdatenhaltung, ElsterLohn/Lohnsteuerbescheinigung, LAVENDEL/HMS.

**Dies ist die fachliche Übersicht.** Paketspezifische Details (Endpunkte, vollständige Nutzdaten-/Message-Felder je Paket, Quellenpfade, offene Punkte je Paket) stehen jetzt unter [`elster/`](elster/): Einstiegspunkt [`elster/README.md`](elster/README.md), maschinenlesbares Rohinventar [`elster/inventar.json`](elster/inventar.json) (Scan 2026-09-28 des OneDrive-Ordners `01 Projekte/ELSTER-Entwickler`).

## A. Paketübersicht

| Paket | Version | Funktion | Detailseite |
|---|---|---|---|
| ElsterXML-Schnittstelle (v11) | Doku 4.3.0, Stand 12.2.2026 | Basis-Transportformat (TransferHeader/NutzdatenHeader), Verschlüsselung, Datenarten-Konzept | [`elster/elsterxml-v11.md`](elster/elsterxml-v11.md) |
| Authentifizierung / ELSTER-Token / Auth-Applet | V02.2.1 / 1.27 / v24.1 | Signatur- und Zertifikatsverfahren (Softtoken, Sicherheitsstick) | siehe `elster/elsterxml-v11.md` Abschnitt 3 |
| ElsterDatenabholung | v31.0.6 → v32.0.1 (lokal nur v32) | Empfangen: Postfach-Nachrichten, Bescheide, VaSt-Belege abholen | [`elster/datenabholung.md`](elster/datenabholung.md) |
| ElsterKontoabfrage | v2.1.3 | Steuerkonto-Abfrage (offene Beträge / Ist-Buchungen / Soll-Stellungen) | [`elster/kontoabfrage.md`](elster/kontoabfrage.md) |
| ElsterObjektspeicher „OTTER" | v1.4.6 | REST-Objektspeicher zum Hochladen grosser Anhänge (Push zu ELSTER) | [`elster/objektspeicher-otter.md`](elster/objektspeicher-otter.md) |
| RABE-Belegdatenhaltung (+ Infos Hersteller) | v2.3 (+ 1.3) | Gegenstück zu OTTER: Belege bleiben bei der Kanzlei, Finanzverwaltung holt sie ab (Pull) | [`elster/rabe-belegdatenhaltung.md`](elster/rabe-belegdatenhaltung.md) |
| ElsterLohn/Lohnsteuerbescheinigung | 1.36 (Stand 22.08.2024) | einziges Paket mit komplettem Formularvordruck (Muster mit Kennziffern, Kz 1–34); ab VZ 2026 Nachfolger ElsterKMV/LSTMitteilung | [`elster/elsterlohn-lstb.md`](elster/elsterlohn-lstb.md) |
| LAVENDEL Datenübermittler + HMS | 2.0.1 | Registrierung, wer (Datenübermittler) für welchen Arbeitgeber ELStAM abrufen darf | [`elster/lavendel-elstam.md`](elster/lavendel-elstam.md), [`elster/hms-mock.md`](elster/hms-mock.md) |
| InvStG § 51 XML-Anhang | Doku v1 / Muster v3 | Maschinenlesbarer Anhang zum Feststellungsbescheid | [`elster/invstg51-feststellung-anhang.md`](elster/invstg51-feststellung-anhang.md) |
| Serverstatus RSS | — | Ops: Annahmeserver-Status vs. eigener Fehler | [`elster/serverstatus-rss.md`](elster/serverstatus-rss.md) |

## B. ElsterXML-Grundaufbau

```
<Elster>
  <TransferHeader>...</TransferHeader>
  <DatenTeil>
    <Nutzdatenblock>
      <NutzdatenHeader>...</NutzdatenHeader>
      <Nutzdaten>...</Nutzdaten>
    </Nutzdatenblock>
  </DatenTeil>
</Elster>
```

TransferHeader (THeader) und NutzdatenHeader (NHeader) haben für jedes Fachverfahren denselben Elementaufbau; nur die Nutzdaten unterscheiden sich fachverfahrensspezifisch. Referenz-Schemata: `elster11_bisNH_extern.xsd`, `header/th000011_extern.xsd`, `header/ndh000011.xsd`, `header/headerbasis_datenarten.xsd`, `header/headerbasis_verfahren.xsd`, `header/headerelemente.xsd`.

### 1. Datenteile

| Element | Verschlüsselung | Inhalt |
|---|---|---|
| TransferHeader | weitestgehend unverschlüsselt, dem verschlüsselten Teil vorangestellt | Verarbeitungsinformationen für Clearingstelle, Verteilung an Bundesländer, Rückgabe-/Fehlermeldungen |
| NutzdatenHeader | innerhalb des verschlüsselten Teils | Verarbeitungsinformationen für den Datensatz, Rückgabe-/Fehlermeldungen |
| Nutzdaten | innerhalb des verschlüsselten Teils | fachverfahrensspezifischer, datentypabhängiger Datensatz |

Bei Sammellieferungen sind mehrere Nutzdatenblöcke möglich (nur teilweise unterstützt, siehe Doku Tz. 3.5).

### 2. Rückgabecode-Struktur

```xml
<RC>
  <Rueckgabe><Code>…</Code><Text>…</Text></Rueckgabe>
  <Stack><Code>…</Code><Text>…</Text></Stack>
</RC>
```

- `Code = 0` in TransferHeader **und** NutzdatenHeader → Daten vollständig entgegengenommen und verarbeitet.
- Strukturfehler/Übermittlungsfehler → Fehlermeldung im TransferHeader, DatenTeil bleibt leer (kein NutzdatenHeader/Nutzdaten).
- Inhaltliche Fehler in den Nutzdaten → TransferHeader-Code „0" (Übermittlung erfolgreich), qualifizierter Rückgabewert ungleich „0" im NutzdatenHeader, Nutzdaten leer.

### 3. Online- vs. Offline-Verfahren

| | Online-Verfahren | Offline-Verfahren |
|---|---|---|
| Bestätigung | sofort (Annahme/Fehler) | sofortige Annahmebestätigung nur zur Übermittlung, Verarbeitungsergebnis separat abzuholen |
| Beispiel | UStVA, LStA (Steueranmeldungen) | Lohnsteuerbescheinigungen (LStB) + Protokollanforderung |
| Besonderheit | — | ggf. `<TransportSchluessel>` im TransferHeader für spätere Protokollabholung nötig; Sammellieferungen nur hier möglich |

### 4. Standards

- Encoding: `utf-8` (historisch ISO-8859-15, seit Version 4.2.10 vollständig auf UTF-8 umgestellt; Version 4.3.0 vom 8.12.2025: Umstellung von 3DES auf **AES-Verschlüsselung**).
- Namespace: `http://www.elster.de/elsterxml/schema/v11`, einmalig im Wurzelelement `<Elster>` gesetzt; Fachverfahren nutzen eigene Namespaces erst innerhalb `<Nutzdaten>`.
- Authentifizierung: Signaturdaten werden bei DatenTeil-Authentifizierung im TransferHeader abgelegt (Vorgang `send-Auth`); Details in `Einheitliche_Datenschnittstelle_XML_Authentifizierung_V02.2.1.pdf` und `Spezifikation_ELSTER-Token_1.27.pdf`.
- Zeichenumfang: eingeschränktes Zeichenrepertoire (Pattern in Kap. 2.2 der Doku) — nicht beliebiges UTF-8, sondern eine definierte Teilmenge (lateinische Basis + Sonderzeichen inkl. Œ, œ, Š, š, Ÿ, Ž, ž, €).
- Kommunikation: HTTPS an die Server der Clearingstelle (`datenannahme{1-4}.elster.de`, siehe Aenderungsbedarf-Dokumentation im Ordner `ELSTER-Entwickler`).
- Client-Alternative: ERiC (Elster Rich Client) übernimmt Komprimierung/Verschlüsselung/Authentifizierung/Versand; alternativ kann die „offene Schnittstelle" direkt implementiert werden (roh-XML), siehe `Verzeichnis_der_Datenarten`.

## C. Taxonomie Verfahren / Datenart / Vorgang

Jede ELSTER-Datenlieferung wird über das Tripel **Verfahren – Datenart – Vorgang** adressiert (Element im ElsterXML-Header). Ausschnitt aus `Verzeichnis_der_Datenarten.csv` (offene Schnittstelle, ohne ERiC):

| Verfahren | Datenart | Vorgang | Anwendung |
|---|---|---|---|
| ElsterDatenabholung | ElsterLohn2Daten | send-Auth | offene Schnittstelle |
| ElsterDatenabholung | ElsterLohnDaten | send-Auth | offene Schnittstelle |
| ElsterDatenabholung | PostfachAnfrage | send-Auth / send-NoSig | offene Schnittstelle |
| ElsterDatenabholung | PostfachBestaetigung | send-Auth / send-NoSig | offene Schnittstelle |
| ElsterDatenabholung | PostfachStatus | send-Auth / send-NoSig | offene Schnittstelle |
| ElsterDatenabholung | ElsterKMVDaten | send-Auth | offene Schnittstelle |
| ElsterLohn2 | DUeAbmelden / DUeAnmelden / DUeUmmelden | send-Auth | offene Schnittstelle |
| ElsterLohn | LStB | send-Auth / send-Auth-Part | offene Schnittstelle |
| ElsterKMV | LSTMitteilung | send-Auth / send-Auth-Part | offene Schnittstelle |
| ElsterLohn | Lohnersatzleistung | send-Auth / send-Auth-Part | offene Schnittstelle |

Vollständige Liste (alle Verfahren/Datenarten/Vorgänge inkl. Anmeldungssteuern, ERiC-only-Kombinationen): `ElsterXML-Schnittstelle_V11_2026.7.20.0.zip → v11/Dokumente/Verzeichnis_der_Datenarten.csv` sowie `Verfahren_DatenArt_Vorgang_v*.xml` im COALA-Downloadbereich (nicht im gesichteten Bestand). `send-Auth` = signierte/authentifizierte Übermittlung, `send-NoSig` = unsignierte Anfrage/Statusabruf, `send-Auth-Part` = teilauthentifiziert (Sammellieferung).

## D. Bekannte Datenarten je Fachpaket (für Liste „ELSTER-Verfahren & Datenarten")

- **ElsterDatenabholung**: `PostfachStatus`, `PostfachAnfrage`, `PostfachBestaetigung` (Bestätigungspflicht binnen 24 h), `Statusabfrage`, `ElsterVaStDaten` (Anfrage/Einzelabholung/Sammelabholung).
- **ElsterKontoabfrage**: `Kontoabfrage-O` (offene Beträge), `Kontoabfrage-I` (Ist-Buchungen), `Kontoabfrage-ZS` (Soll-Stellungen).
- **ElsterLohn**: Datenart `LStB` trägt Neu/Korrektur **und** Storno (Nutzdaten-Root `LStBStorno`, gleiche Header-DatenArt); Datenart `Lohnersatzleistung` dokumentiert, aber ohne Schema im Paket; `eTIN` nur Altfälle (Schema bis 202201, danach entfernt).
- **LAVENDEL**: Arbeitnehmer anmelden/abmelden, Datenübermittler-Wechsel, Änderungsliste (Anmelde-/Abmelde-/Ummeldebestätigung, Monatsliste, Bruttoliste).
- **ElsterObjektspeicher (OTTER)**: REST-Push grosser Anhänge; Objekt-ID wird im ElsterXML referenziert; 7-Tage-Frist zur Abholung durch die Finanzverwaltung.
- **RABE-Belegdatenhaltung**: Pull-Gegenmodell zu OTTER — Belege verbleiben auf einem Server der Kanzlei, die Finanzverwaltung holt sie dort ab.
- **Grundsteuer** (aus Prüfziffer-Dokumentation): `Grundsteuerwert` (Bundesmodell), länderspezifisch `GrundsteuerBY`, `GrundsteuerBW`, `GrundsteuerHE`, `GrundsteuerHH`, `GrundsteuerNI`.

## E. Architekturschichten für eine eigene ELSTER-Anbindung

| Schicht | Baustein | Zweck |
|---|---|---|
| Transport & Auth | ElsterXML v11 + Authentifizierung + ELSTER-Token/Auth-Applet | XML-Aufbau, Verschlüsselung (AES), Signatur (RSASSA-PSS/SHA-256), Versand an `datenannahme{1-4}.elster.de` |
| Senden (Formulare/Meldungen) | verfahrensspezifische Datenart-Schemata + KmId/RefKmId-Logik für Korrektur/Storno | Befüllen und Übermitteln der Formulare |
| Belege/Anlagen hochladen | OTTER (Push) bzw. RABE (Pull) | Anhänge zur Finanzverwaltung bringen |
| Empfangen | ElsterDatenabholung (Postfach/Bescheide/VaSt) + ElsterKontoabfrage (Kontostatus) + DIVA-Katalog zur Klassifikation | Bescheide/Schreiben automatisiert abholen, bestätigen, einsortieren |
| Identität/Vertretung | LAVENDEL/HMS (nur ELStAM), Herstellerregistrierung (HerstellerID), Datenübermittler-/Vertreterregistrierung je Mandant | Wer darf für wen senden/empfangen |
| Validierung | Prüfziffern-Logik + Finanzamtsliste + Fehlercode-Katalog (siehe `elster-taxonomien-kataloge.md`) | gemeinsame Bibliothek für alle Schichten |

**Offene Punkte:** Herstellerregistrierung (HerstellerID/Zertifikat) beim ELSTER-Herstellerforum/IMS ist in den gesichteten Unterlagen nicht beschrieben; Entscheidung ERiC-Einbindung vs. Eigenimplementierung (inkl. Verschlüsselung/Signatur) steht aus; Test-Zertifikate liegen vor (`Test_Zertifikate.zip`, `Test_Zertifikate_3072_Bit.zip`), werden aber bewusst nicht inventarisiert (keine Schlüssel/Zertifikatsinhalte in diesem Repo).

## F. Gaps aus dem Scan 2026-09-28 (Zusammenfassung)

Vollständige, paketweise Gap-Auflistung in [`elster/README.md`](elster/README.md) Abschnitt 3. Wichtigste Punkte:

- **ElsterLohn_Lohnsteuerbescheinigung_1.36.zip** wurde inzwischen heruntergeladen und ausgewertet (siehe [`elster/elsterlohn-lstb.md`](elster/elsterlohn-lstb.md)) — enthält den einzigen kompletten Kennziffern-Formularvordruck (Kz 1–34) der gesichteten Pakete. Offen bleibt darin: Datenart `Lohnersatzleistung` ohne Schema/Beispiel im Paket, kein CSV-Feldkatalog, ElsterKMV/LSTMitteilung (ab VZ 2026) nicht enthalten.
- **VaSt-Informationen_v1.zip fehlt lokal** — Datenart `ElsterVaStDaten` ist in der Datenabholung referenziert, das zugehörige Hersteller-Infopaket selbst wurde nicht heruntergeladen (siehe [`elster/datenabholung.md`](elster/datenabholung.md) Abschnitt 5).
- **ERiC-Formularpakete (ESt/KSt/USt-VA/GewSt/ErbSt/Grundsteuer/steuerliche Erfassung) liegen nicht im gesichteten „ELSTER-Entwickler"-Ordner** — dies ist der separate ERiC-Entwicklerbereich; die dortigen Kennziffern-Feldkataloge sind hier **nicht** erfunden. Bereits im Repo vorhandene Feldkataloge (steuerliche Erfassung, BZSt2, § 6 AStG, W-IdNr.) liegen unter [`AO/README.md`](AO/README.md) und [`AStG/formulardaten-mitteilung-6-astg.md`](AStG/formulardaten-mitteilung-6-astg.md) und beruhen **nicht** auf einem ELSTER-Entwicklerpaket.
