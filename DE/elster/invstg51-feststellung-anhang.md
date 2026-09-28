# InvStG § 51 Feststellung — XML-Anhang

## 1. Zweck

Maschinenlesbarer Anhang zum Bescheid über die gesonderte und einheitliche Feststellung nach § 51 InvStG. Der Anhang ergänzt den PDF-Bescheid, ist aber **selbst kein eigener Verwaltungsakt**.

## 2. Daten: Verfahren / Datenart / Vorgang

| Verfahren | Datenart | Vorgang |
|---|---|---|
| ElsterErklaerung / Bescheid-Anhang | InvStG51Feststellung (Namespace `…/elstererklaerung/invstg51feststellung/v3`) | — (Anhang, kein eigenständiger Sendevorgang dokumentiert) |

Gilt laut Doku für Datenartversion 3 **und** 4; Namespace-Version ist 3.

### Struktur (aus dem Muster `MUSTER_Anlage_zur_Ges_einh_Fest_51_InvStG.xml`)

```text
InvStG51Feststellung
└── BescheidInformationen
    ├── Nachrichtenkopf
    ├── Briefkopf
    ├── Empfaenger
    ├── Bekanntgabeadressat
    ├── SPIF_AVF_Anteilklasse
    ├── Feststellungen
    └── Erklaerungen
└── InvSt1
    ├── Allgemeines
    ├── Ertragsverw
    └── … (weitere Unterabschnitte, im Inventar nicht vollständig aufgelöst)
└── FB
    └── Bescheid / GINSTER
```

## 3. Taxonomie / Kataloge

- DIVA-Dokumentengruppe `DIVAInvStG51Feststellung` — 4 Schlüssel im DIVA-Katalog „Art des Schreibens" (siehe [`kataloge/diva-art-des-schreibens.md`](kataloge/diva-art-des-schreibens.md)).

## 4. Quellen

- `Dokumentation_XML-Anhang_zu_InvStG51Feststellung_v1.pdf` — Doku Version 1 (Portal 09.01.2025, Fassung 18.12.2024).
- `MUSTER_Anlage_zur_Ges_einh_Fest_51_InvStG.xml` — Muster-XML, Version 3.
- Portal-Namen: `Dokumentation_XML-Anhang_zu_InvStG51Feststellung_v1.pdf`, `MUSTER_Anlage_zur_Ges_einh_Fest_51_InvStG.xml`.

## 5. Gaps / offene Punkte

- Die Unterstruktur von `InvSt1` (über `Allgemeines`/`Ertragsverw` hinaus) und von `FB` (`Bescheid`/`GINSTER`) wurde aus dem Muster nicht vollständig bis auf Feldebene ausgezählt — nur die oberste Gliederungsebene ist hier dokumentiert.
- Zusammenhang zu den übrigen 3 DIVA-Schlüsseln der Gruppe `DIVAInvStG51Feststellung` (welcher Schlüssel für welchen Anhang-/Bescheidtyp) wurde nicht im Detail aufgelöst.
