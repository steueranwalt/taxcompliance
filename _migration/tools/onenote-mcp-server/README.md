# onenote-mcp-server

Lokaler MCP-Server (stdio), der OneNote-Notizbücher liest, die auf der SharePoint-Site
`obenhaus.sharepoint.com/sites/Wissen` liegen. Grund: Der generische Microsoft-365-Connector
kann OneNote-Dateien (`application/msonenote`) nicht direkt lesen; dieser Server spricht
stattdessen die Microsoft Graph OneNote-API (`/onenote/notebooks`, `/sections`, `/pages`) im
App-Only-Modus (Client-Credentials-Flow) an.

## Voraussetzung: App-Registrierung in Entra ID

1. **Entra ID** → *App registrations* → *New registration*, Single-Tenant, kein Redirect-URI.
2. **Certificates & secrets** → neues Client Secret erzeugen, `Value` sicher notieren.
3. **API permissions** → Microsoft Graph → **Application permissions**:
   - `Notes.Read.All`
   - `Sites.Read.All`
   → *Grant admin consent*.

## Benötigte Umgebungsvariablen

| Variable | Beschreibung |
|---|---|
| `AZURE_TENANT_ID` | Directory (tenant) ID der App-Registrierung |
| `AZURE_CLIENT_ID` | Application (client) ID |
| `AZURE_CLIENT_SECRET` | Secret-Value aus Schritt 2 (**niemals committen**) |
| `GRAPH_SITE_HOSTNAME` | optional, Default `obenhaus.sharepoint.com` |
| `GRAPH_SITE_PATH` | optional, Default `/sites/Wissen` |

Diese Variablen gehören **nicht** in den Chat und **nicht** ins Repo — sie werden über die
Secrets/Environment-Variablen-Konfiguration der Session/des Environments gesetzt (siehe
`.mcp.json` im Repo-Root, das sie per `${VAR}`-Referenz einliest).

## Tools

| Tool | Zweck |
|---|---|
| `resolve_site` | Testet die Zugangsdaten, löst Hostname+Pfad zu einer Graph Site-ID auf |
| `list_notebooks` | Listet Notizbücher der Site |
| `list_sections` | Listet Abschnitte (optional gefiltert nach Notizbuch) |
| `list_pages` | Listet Seiten eines Abschnitts |
| `get_notebook_tree` | Kompletter Baum Notizbuch → Abschnitte → Seiten (ohne Inhalt) |
| `get_page_markdown` | Seiteninhalt als Markdown + Liste eingebetteter Ressourcen-URLs |
| `get_resource` | Lädt eine eingebettete Ressource (Bild/Datei) Base64-kodiert |

## Lokal testen

```bash
cd _migration/tools/onenote-mcp-server
npm install
AZURE_TENANT_ID=... AZURE_CLIENT_ID=... AZURE_CLIENT_SECRET=... node src/index.js
```

Der Prozess spricht MCP über stdio — zum manuellen Testen eignet sich z. B.
`npx @modelcontextprotocol/inspector node src/index.js`.
