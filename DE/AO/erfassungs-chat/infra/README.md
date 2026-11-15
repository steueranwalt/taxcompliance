# Infrastruktur (vorbereitet, NICHT deployt)

Siehe Haupt-README (`../README.md`), Abschnitt "Deploy-Schritte" fuer die
vollstaendige, ressourcenweise Freigabeliste und Kostenschaetzung.

- [`main.bicep`](main.bicep) - Function App (Flex Consumption), user-assigned
  Managed Identity, zwei Storage Accounts (Function-Deployment + `$web`),
  Log Analytics + Application Insights, Rollenzuweisung "Cognitive Services
  OpenAI User" auf `accompli-azureai`.
- [`main.parameters.example.json`](main.parameters.example.json) - Beispiel-Parameter.
- [`graph-sites-selected-setup.md`](graph-sites-selected-setup.md) - dokumentierte
  Graph-/PowerShell-Schritte fuer `Sites.Selected` (nicht ausgefuehrt).

Keine Secrets in diesen Dateien - alle Azure-Zugriffe laufen ueber die
user-assigned Managed Identity.
