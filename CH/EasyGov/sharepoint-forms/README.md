# SharePoint-Listen + Microsoft-Forms-Familie «EasyGov Unternehmensgründung CH»

Quellen: [`../Einheitliches-Datenmodell-easygov-unternehmensgruendung.md`](../Einheitliches-Datenmodell-easygov-unternehmensgruendung.md), [`../felder.json`](../felder.json).

Vertraulichkeit: Nur Schema-/Metadaten. Keine Mandats- oder Klientendaten. Beim Testdurchlauf ausschliesslich Dummy-Daten.

Die Mechanik (PnP, ClientId, DateOnly, Required-Boolean-Falle, 32-Zeichen-Grenze, keine bedingten Pflichtfelder) ist dieselbe wie in [`DE/AO/sharepoint-forms/README.md`](../../../DE/AO/sharepoint-forms/README.md) Abschnitte A–C2. Hier nur die EasyGov-Abweichungen.

## A. Listenerstellung

```powershell
.\New-EasyGovGruendungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/<ziel-site>" -ClientId "<Entra-App-ClientId>"
```

Leitet die Spalten aus `felder.json` ab. Legt an bzw. gleicht an: `0_Fallsteuerung`, `1_Unternehmen`, `2_Personen`, `3_Kapital`, `3_Anteile`, `4_HR_Diverses`, `5_MWST`, `6_AHV`, `7_UVG`, `8_Unterlagen`, `Technische_Mindestfelder`, `Eingang_Fehler`.

`case_id` in Folgelisten: Lookup auf `0_Fallsteuerung` mit `RelationshipDeleteBehavior=Restrict`.

## B. Prüfskript

```powershell
.\Test-EasyGovGruendungListen.ps1
.\Test-EasyGovGruendungListen.ps1 -SiteUrl "https://obenhaus.sharepoint.com/sites/<ziel-site>" -ClientId "<Entra-App-ClientId>"
```

Ohne Site: statisch (ruft `../tests/test_konsistenz.py` auf). Mit Site: zusätzlich lesender Soll/Ist-Abgleich. Exit 0 = `ERGEBNIS: OK`.

Lokal/CI ohne PowerShell:

```
python3 ../tests/test_konsistenz.py
```

## C. Forms-Familie

Fragen 1:1 aus den Listenspalten, Labels aus dem Feldkatalog. Fall-ID jeweils erste Frage. Branching: bedingte Portalpflichten (Ausländer-Ausweis, Liberierung, Saldosteuersatz, Verbands-AK, UVG-IBAN). Kanzlei-Ergebnisfelder (Meldepflicht-Resultat) nicht an Mandanten.

Klicks: [`KLICKANLEITUNG-FORMS.md`](KLICKANLEITUNG-FORMS.md).

Routing aus Formular 0:

| Bedingung | Folgeformulare |
|---|---|
| immer | 1 Unternehmen, 2 Personen, 8 Unterlagen |
| GmbH oder AG | 3 Kapital, 4 HR Diverses |
| KlG oder KmG | 4 HR Diverses (Papier), KmG zusätzlich Kapital/Kommandite in Personen |
| Resultat MWST zwingend oder freiwillig gewünscht | 5 MWST |
| Resultat AHV zwingend | 6 AHV |
| Resultat UVG zwingend oder freiwillig | 7 UVG |

## D. Bekannte Portalgrenzen, die Listen nicht heilen

EasyGov erfasst keine juristischen Personen als GmbH/AG-Gesellschafter, keine Statuten, keine Revisionsstelle. Diese Lücken bleiben Kanzlei-/Notar-Erhebung in Formular 8 (`dokumenttypen`).
