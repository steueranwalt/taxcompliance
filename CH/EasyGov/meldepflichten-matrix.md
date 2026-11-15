# Meldepflichten-Matrix EasyGov

**Stand:** 2026-11-15. Schwelle Umsatz: CHF 100'000.

Ohne Gewähr, Momentaufnahme EasyGov 15.11.2026, evtl. unvollständig (kantonale Bewilligungen). UVG: EasyGov nennt Suva oder Privatversicherer nach Tätigkeit. GmbH/AG: MWST, AHV, UVG, Transparenzregister erst nach HR-Eintrag. KlG/KmG mit Umsatz ab CHF 100'000 und Personal im Inventar analog KapG-Cockpit (HR, AHV, MWST, UVG zwingend) – nicht für alle Umsatz/Personal-Kombinationen separat durchgespielt.

Maschinenlesbar: [`meldepflichten-matrix.json`](meldepflichten-matrix.json).

| ID | Rechtsform | Umsatz | Personal | HR | MWST | AHV | UVG | Hinweis |
|---|---|---|---|---|---|---|---|---|
| eu_u100_allein | EU | weniger als CHF 100'000 | nur Inhaber (1 Person) | freiwillig | freiwillig | zwingend | freiwillig | UVG freiwillig für Inhaber. |
| eu_u100_personal | EU | weniger als CHF 100'000 | mit Angestellten | freiwillig | freiwillig | zwingend | zwingend |  |
| eu_ab100_allein | EU | CHF 100'000 oder mehr | nur Inhaber (1 Person) | zwingend | zwingend | zwingend | freiwillig |  |
| eu_ab100_personal | EU | CHF 100'000 oder mehr | mit Angestellten | zwingend | zwingend | zwingend | zwingend |  |
| gmbh_u100_allein | GmbH | weniger als CHF 100'000 | nur Inhaber (1 Person) | zwingend | freiwillig | zwingend | zwingend | HR zwingend wegen Rechtsform. MWST/AHV/UVG laut EasyGov erst nach HR-Eintrag im Cockpit. |
| gmbh_ab100_personal | GmbH | CHF 100'000 oder mehr | mit Angestellten | zwingend | zwingend | zwingend | zwingend | MWST/AHV/UVG im Cockpit erst nach HR-Eintrag freigeschaltet. |
| ag_u100_allein | AG | weniger als CHF 100'000 | nur Inhaber (1 Person) | zwingend | freiwillig | zwingend | zwingend | Analog GmbH, nicht als eigener Variantenpfad durchgespielt. |
| ag_ab100_personal | AG | CHF 100'000 oder mehr | mit Angestellten | zwingend | zwingend | zwingend | zwingend | Analog GmbH. |
| klg_ab100_personal | KlG | CHF 100'000 oder mehr | mit Angestellten | zwingend | zwingend | zwingend | zwingend | Cockpit-Momentaufnahme; KlG-PDF-Weg. Kombinationen unter CHF 100'000 nicht separat erhoben. |
| kmg_ab100_personal | KmG | CHF 100'000 oder mehr | mit Angestellten | zwingend | zwingend | zwingend | zwingend | Cockpit sofort zwingend HR/AHV/MWST/UVG. |

Rechtsgrundlagen der Schwelle, soweit im Inventar genannt: HR- und MWST-Grenze gemeinsam seit 1.1.2010; MWST Art. 11 (freiwillige Unterstellung), Art. 18 Abs. 2 und Art. 21 (ausgenommene Leistungen), Art. 37 Abs. 1 (Saldosteuersatz), Art. 39/40 (Abrechnungsart); MWST-Info 02 Ziff. 5.2.1.1 und MWST-Info 27; OR 459 (Prokura).

