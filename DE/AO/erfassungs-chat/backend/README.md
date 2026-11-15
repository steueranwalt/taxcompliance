# Backend (Azure Functions, Python)

Siehe Haupt-README (`../README.md`) für Architektur, Designprinzip und
Deploy-Schritte. Dieser Ordner enthält nur die technischen Details.

## Warum Python statt TypeScript

Python wurde gewählt, weil:

- der Schema-Generator (`../generator/`) ebenfalls Python ist – gemeinsame
  Konzepte (Feldkatalog, Klassifizierung) sind so ohne Sprachbruch testbar;
- die Azure-SDKs für Managed Identity (`azure-identity`), Azure OpenAI
  (`openai`) und Microsoft Graph (`requests`) in Python ebenso ausgereift
  sind wie in TypeScript;
- Azure Functions Flex Consumption Python 3.12 unterstützt;
- die Mock-/Test-Infrastruktur ohne zusätzliche Build-Schritte (kein
  `tsc`/`npm install`) läuft, was für einen Prototyp mit häufigen Iterationen
  einfacher ist.

## Lokal ausführen

```bash
cd DE/AO/erfassungs-chat/backend
python3 -m unittest discover -s tests -t .
```

Mit laufenden Azure Functions Core Tools (`func`, hier nicht vorinstalliert):

```bash
cp local.settings.json.example local.settings.json
func start
```

## Struktur

- `app/` – reine Logik ohne `azure.functions`-Abhängigkeit (testbar ohne
  Functions-Host).
- `function_app.py` – dünner HTTP-Wrapper (Azure Functions v2
  Programmiermodell).
- `mocks/sharepoint_data/` – Mock-SharePoint-Listen (ausschliesslich
  Testdaten, siehe Haupt-README „Datenschutz“).
- `tests/` – Unit- und Szenario-Tests.
