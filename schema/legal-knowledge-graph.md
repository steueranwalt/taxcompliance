# Legal Knowledge Graph – verbindliches Metadatenmodell

**Stand:** 29.09.2026  
**Geltung:** DE, CH, EU und internationale Steuerrechtsquellen.

## 1. Grundsatz

Fachthema, Rechtsraum, föderale Ebene, Urheber, räumliche Geltung, Instrumenttyp, Rechtswirkung und Vollzug sind getrennte Dimensionen. Ordnernamen sind keine juristischen Klassifikatoren.

Beispiel: `topic: Steuerverfahrensrecht` bleibt für DE und CH identisch. `jurisdiction`, `legal_level` und `territory` bestimmen den konkreten Rechtsraum.

## 2. Kerndimensionen

```yaml
topic:

legal_system_type:
  # domestic | supranational | international

jurisdiction:
  # DE | CH | EU | MULTILATERAL

issuer:
  type:
    # state | supranational_organisation | international_organisation | treaty_parties
  organisation:
    # EU | OECD | UN | Council_of_Europe | WTO | FATF | other
  states: []

legal_level:
  # international | union | federal | state | canton | municipal

territory:
  countries: []
  subdivisions: []
  municipalities: []

instrument_type:
  # constitution | statute | ordinance
  # eu_regulation | eu_directive | eu_decision
  # treaty | multilateral_convention | protocol
  # model_convention | commentary | guideline | recommendation
  # standard | peer_review | administrative_agreement

legal_effect:
  binding: true
  binding_basis:
    # directly_applicable | domestic_law | treaty_ratification | implementation
    # incorporation | administrative_practice | interpretative | soft_law
  addressees: []

authority:
  organisation:
  authority_level:
    # union | federal | state | canton | district | municipal
  territory:
```

## 3. Wichtige Modellierungsregeln

1. **Jurisdiktion ist nicht föderale Ebene.** Zürich ist keine eigene Jurisdiktion, sondern `jurisdiction: CH`, `legal_level: canton`, `territory.subdivisions: [ZH]`.
2. **Rechtsetzungsebene ist nicht Vollzugsebene.** DBG ist Bundesrecht, kann aber durch kantonale Behörden vollzogen werden.
3. **EU ist supranationaler Rechtsraum und Urheber.** EU-Recht wird nicht als deutsche oder schweizerische föderale Ebene modelliert.
4. **OECD und UN sind primär Urheber/Organisationen, keine nationalen Jurisdiktionen.** Die Rechtswirkung folgt aus dem jeweiligen Instrument.
5. **DBA werden als internationale Vertragsinstrumente modelliert.** Die Vertragsstaaten stehen in `issuer.states`; nationale Umsetzung und Anwendung werden über Relationen verknüpft.
6. **Soft Law und bindendes Recht bleiben getrennt.** OECD-MA, Kommentar und Guidelines erhalten keine Bindungswirkung nur aufgrund ihrer fachlichen Bedeutung.
7. **Thema bleibt rechtsraumneutral.** Beispiel: `topic: Steuerverfahrensrecht`, danach Filter über Rechtsraum/Ebene.
8. **Geltungszeitraum gehört an die Normfassung, nicht nur an die Norm.**

## 4. Beispiele

### § 90 AO

```yaml
topic: Steuerverfahrensrecht
legal_system_type: domestic
jurisdiction: DE
issuer:
  type: state
  states: [DE]
legal_level: federal
territory:
  countries: [DE]
instrument_type: statute
legal_effect:
  binding: true
  binding_basis: domestic_law
```

### Art. 120 DBG

```yaml
topic: Steuerverfahrensrecht
legal_system_type: domestic
jurisdiction: CH
issuer:
  type: state
  states: [CH]
legal_level: federal
territory:
  countries: [CH]
instrument_type: statute
legal_effect:
  binding: true
  binding_basis: domestic_law
```

### Kantonales Steuerrecht Zürich

```yaml
topic: Steuerverfahrensrecht
legal_system_type: domestic
jurisdiction: CH
legal_level: canton
territory:
  countries: [CH]
  subdivisions: [ZH]
instrument_type: statute
```

### EU-Richtlinie

```yaml
legal_system_type: supranational
jurisdiction: EU
issuer:
  type: supranational_organisation
  organisation: EU
legal_level: union
instrument_type: eu_directive
legal_effect:
  binding: true
  binding_basis: implementation
```

### OECD-Musterabkommen

```yaml
legal_system_type: international
jurisdiction: MULTILATERAL
issuer:
  type: international_organisation
  organisation: OECD
legal_level: international
instrument_type: model_convention
legal_effect:
  binding: false
  binding_basis: interpretative
```

### DBA Deutschland–Schweiz

```yaml
legal_system_type: international
jurisdiction: MULTILATERAL
issuer:
  type: treaty_parties
  states: [DE, CH]
legal_level: international
territory:
  countries: [DE, CH]
instrument_type: treaty
legal_effect:
  binding: true
  binding_basis: treaty_ratification
```

## 5. Kernobjekte des Rechtsgraphen

`NORM`, `NORM_VERSION`, `PROCEDURE`, `DEADLINE`, `SOURCE`, `RELATION`.

Verfahren und Fristen verwenden dieselben Metadaten. Damit können DE und CH dasselbe technische Schema nutzen, ohne ihre materiellen Rechtsgraphen zu vermischen.

## 6. SharePoint/GitHub

- SharePoint `General`: RAW/Quellen.
- SharePoint `wiki`: kuratiertes Wissen; Thema und Rechtsraum über Metadaten, nicht über zusammengesetzte Fachbegriffe.
- GitHub: Schema, Regeln, IDs, Validatoren, Skills und ausführbare Flows.

Beispiel für eine Wiki-Karte:

```yaml
topic: Steuerverfahrensrecht
jurisdiction: CH
legal_level: canton
territory:
  subdivisions: [ZH]
knowledge_type: procedure_map
```

## 7. ID-Regel

IDs kodieren die fachliche Identität stabil, aber nicht jede veränderliche Metadateneigenschaft. Beispiele:

- `DE-AO-0090`
- `CH-DBG-0120`
- `EU-DAC6-2018-822`
- `INT-DBA-DE-CH-ART25`
- `OECD-MTC-ART25`

Dateien dürfen umziehen. Die ID bleibt bestehen.
