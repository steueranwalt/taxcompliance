# Katalog: DIVA Schlüsselkatalog „Art des Schreibens" (v21.0.0)

## 1. Zweck

Schlüsselkatalog, mit dem die Steuerverwaltung verfahrensübergreifend ausgetauschten Dokumenten eindeutige Schlüssel und verwaltungsübliche Bezeichnungen gemäss AEAO zu § 122 Tz. 3.1.1.1 zuweist. Definiert die Typen von Textdokumenten (Verwaltungsakte und sonstige Mitteilungen), die die Steuerverwaltung elektronisch bereitstellt. Wird als Filter in [`../datenabholung.md`](../datenabholung.md) genutzt (Feld `ELSTER-Dokumentengruppe`, bis Version 18 „Steuerart" genannt).

## 2. Daten: Verfahren / Datenart / Vorgang

Kein eigenes Verfahren — der Katalog wirkt als **Filter-/Metadatenkatalog** innerhalb von `ElsterDatenabholung` / `PostfachAnfrage` (siehe [`../datenabholung.md`](../datenabholung.md)).

### Schema (Tabellenblatt „Schlüssel", `VDM_SK_ArtDesSchreibens_v21.0.0.xlsx`)

| Spalte | In Abholungsrequest | In Abholungsresponse | Bedeutung |
|---|---|---|---|
| `DateibezeichnungID` | Nein | Ja | numerischer Schlüsselwert, identifiziert Dokumenttypen eindeutig |
| `Klartext` | Nein | Nein | fachliche Beschreibung des Dokumenttyps |
| `Gültig von` | Nein | Nein | frühestmöglicher Verwendungszeitpunkt |
| `Gültig bis` | Nein | Nein | letztmöglicher Verwendungszeitpunkt |
| `Dateibezeichnung` | Nein | Ja | fachliche Beschreibung, wird in der Datenabholung mitgeliefert |
| `DateibezeichnungKurz` | Nein | Ja | Kurzbezeichnung gem. AEAO zu § 122 Tz. 3.1.1.1; u. a. im Betreff der Benachrichtigungsmail |
| `Verwaltungsakt` | Nein | Nein | Ja/Nein — ob der Dokumenttyp ein Verwaltungsakt ist |
| `ELSTER-Dokumentengruppe` | Ja | Ja | gruppiert Dokumenttypen, nutzbar als Filter im Abholungsrequest |

### Umfang und Dokumentengruppen (Counts)

335 Datenzeilen im Sheet „Schlüssel". Wichtigste Dokumentengruppen (Auszug):

| Dokumentengruppe | Anzahl |
|---|---:|
| DivaSonstigerVA | 138 |
| DivaSonstigeMitteilung | 101 |
| DivaBescheidKSt | 15 |
| DivaBescheidGewSt | 10 |
| DivaBescheidESt | 7 |
| DIVAInvStG51Feststellung | 4 |
| WIdNrVA | 1 |
| VerbindlicheAuskunft | 3 |

Daneben weitere Gruppen für Grunderwerbsteuer, Erbschaft-/Schenkungsteuer, Rennwett-/Lotterie-/Automatensteuern u. a. (im Inventar nicht mit Einzel-Counts erfasst).

**Beispiel:** `DateibezeichnungID` `003002`, Kurzform `FB27KStG` = Feststellungsbescheid nach § 27 ff. KStG.

### Beispiel-Metadatenstruktur (ein Anhang in der Datenabholung)

```xml
<Anhaenge xmlns="http://finkonsens.de/elster/anhaenge/simple/v3" version="3">
  <Anhang>
    <Dateibezeichnung>Feststellungsbescheid nach § 27 ff KStG</Dateibezeichnung>
    <Dateityp>application/pdf</Dateityp>
    <Dateiinhalt>… [Base64-codiertes unverschlüsseltes PDF] …</Dateiinhalt>
    <Virengeprueft>false</Virengeprueft>
    <Normalisiert>false</Normalisiert>
    <MetadatenAnhang>
      <MetadatumAnhang><SchluesselAnhang>DateibezeichnungKurz</SchluesselAnhang><WertAnhang>FB27KStG</WertAnhang></MetadatumAnhang>
      <MetadatumAnhang><SchluesselAnhang>DateibezeichnungID</SchluesselAnhang><WertAnhang>003002</WertAnhang></MetadatumAnhang>
    </MetadatenAnhang>
  </Anhang>
</Anhaenge>
```

### Versionsverlauf (Auszug)

| Version | Datum | Änderung |
|---|---|---|
| 14.0.1 | 16.5.2023 | Initiale Version |
| 15.1.0 | 3.4.2024 | Art des Schreibens „Sonstiges Schreiben" ergänzt |
| 16.0.0 | 12.8.2024 | diverse Arten für ESt, GewSt, KSt, ErbSt hinzugekommen |
| 17.0.0 | 27.1.2025 | Office-Schreiben (Schlüssel `10nnnn`) hinzu; behördeninterne Arten entfernt |
| 18.0.0 | 22.5.2025 | neue Arten mit `DateibezeichnungID ≥ 101551` |
| 19.0.0 | 16.9.2025 | 28 neue Schlüssel; 4 Schlüssel umbenannt |
| 21.0.0 | 3.6.2026 | aktueller Stand des gesichteten Katalogs |

## 3. Taxonomie / Kataloge

Dies **ist** der Katalog. Verwandte Kataloge: [`bescheidnummern.md`](bescheidnummern.md) (feingranularere Bescheidwertnummern je Steuerart) und [`finanzamtsdaten.md`](finanzamtsdaten.md) (Empfänger-Finanzamt).

## 4. Quellen

- Paket: `DIVA_SK_ArtDesSchreibens_v21.0.0.zip`, Version 21.0.0 (Stand Katalog/Doku ~03.06.2026; Portal-Download 25.06.2026). Lokal vollständig extrahiert.
- `extracted/DIVA_SK_ArtDesSchreibens_v21.0.0/VDM_SK_ArtDesSchreibens_v21.0.0.xlsx`
- `extracted/DIVA_SK_ArtDesSchreibens_v21.0.0/DIVA_SK_ArtDesSchreibens_v21.0.0.pdf`
- Portal-Name: `DIVA_SK_ArtDesSchreibens_v21.0.0.zip`.

## 5. Gaps / offene Punkte

- Die vollständige Werteliste (335 `DateibezeichnungID`-Einträge) liegt nur im Excel-Tabellenblatt „Schlüssel" vor und ist hier aus Umfangsgründen nicht zeilenweise reproduziert.
- Mapping DIVA → interner Dokumenttyp (kanzleiinterne Zuordnungstabelle) steht in `Aenderungsbedarf_ELSTER_vs_Architektur_2026-07-24.md` (kanzleiintern, nicht Teil dieses Repos).
