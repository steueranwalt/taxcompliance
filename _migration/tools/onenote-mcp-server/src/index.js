#!/usr/bin/env node
// MCP-Server: liest OneNote-Notizbücher, die auf einer SharePoint-Site liegen,
// über Microsoft Graph (App-Only / Client-Credentials-Flow) und liefert
// Notizbuch-/Abschnitts-/Seitenstruktur sowie Seiteninhalt als Markdown.

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import TurndownService from "turndown";
import { gfm } from "turndown-plugin-gfm";
import { graphRequest, graphListAll, resolveSiteId } from "./graph.js";

const DEFAULT_HOSTNAME = process.env.GRAPH_SITE_HOSTNAME ?? "obenhaus.sharepoint.com";
const DEFAULT_SITE_PATH = process.env.GRAPH_SITE_PATH ?? "/sites/Wissen";

const turndown = new TurndownService({ headingStyle: "atx", codeBlockStyle: "fenced" });
turndown.use(gfm);

const siteIdCache = new Map(); // "hostname|path" -> siteId

async function getSiteId(hostname, sitePath) {
  const h = hostname ?? DEFAULT_HOSTNAME;
  const p = sitePath ?? DEFAULT_SITE_PATH;
  const key = `${h}|${p}`;
  if (!siteIdCache.has(key)) {
    siteIdCache.set(key, await resolveSiteId(h, p));
  }
  return siteIdCache.get(key);
}

const siteArgs = {
  siteHostname: z
    .string()
    .optional()
    .describe(`SharePoint-Hostname, Default: ${DEFAULT_HOSTNAME}`),
  sitePath: z
    .string()
    .optional()
    .describe(`Site-Pfad, Default: ${DEFAULT_SITE_PATH}`),
};

function textResult(data) {
  return { content: [{ type: "text", text: JSON.stringify(data, null, 2) }] };
}

const server = new McpServer({ name: "onenote-graph", version: "0.1.0" });

server.registerTool(
  "resolve_site",
  {
    title: "SharePoint-Site auflösen",
    description:
      "Löst Hostname + Site-Pfad zu einer Graph Site-ID auf. Nützlich zum Testen der Zugangsdaten.",
    inputSchema: siteArgs,
  },
  async ({ siteHostname, sitePath }) => {
    const siteId = await getSiteId(siteHostname, sitePath);
    return textResult({ siteId, hostname: siteHostname ?? DEFAULT_HOSTNAME, sitePath: sitePath ?? DEFAULT_SITE_PATH });
  }
);

server.registerTool(
  "list_notebooks",
  {
    title: "Notizbücher auflisten",
    description: "Listet alle OneNote-Notizbücher auf der konfigurierten SharePoint-Site.",
    inputSchema: siteArgs,
  },
  async ({ siteHostname, sitePath }) => {
    const siteId = await getSiteId(siteHostname, sitePath);
    const notebooks = await graphListAll(`/sites/${siteId}/onenote/notebooks`);
    return textResult(
      notebooks.map((n) => ({ id: n.id, displayName: n.displayName, lastModified: n.lastModifiedDateTime }))
    );
  }
);

server.registerTool(
  "list_sections",
  {
    title: "Abschnitte auflisten",
    description:
      "Listet OneNote-Abschnitte. Ohne notebookId werden ALLE Abschnitte der Site zurückgegeben (auch aus Section Groups).",
    inputSchema: {
      notebookId: z.string().optional().describe("Falls gesetzt: nur Abschnitte dieses Notizbuchs"),
      ...siteArgs,
    },
  },
  async ({ notebookId, siteHostname, sitePath }) => {
    const siteId = await getSiteId(siteHostname, sitePath);
    const path = notebookId
      ? `/sites/${siteId}/onenote/notebooks/${notebookId}/sections`
      : `/sites/${siteId}/onenote/sections`;
    const sections = await graphListAll(path);
    return textResult(
      sections.map((s) => ({
        id: s.id,
        displayName: s.displayName,
        lastModified: s.lastModifiedDateTime,
        parentNotebook: s.parentNotebook?.displayName,
      }))
    );
  }
);

server.registerTool(
  "list_pages",
  {
    title: "Seiten eines Abschnitts auflisten",
    description: "Listet alle Seiten eines OneNote-Abschnitts (in Notizbuch-Reihenfolge).",
    inputSchema: {
      sectionId: z.string().describe("ID des Abschnitts (aus list_sections)"),
      ...siteArgs,
    },
  },
  async ({ sectionId, siteHostname, sitePath }) => {
    const siteId = await getSiteId(siteHostname, sitePath);
    const pages = await graphListAll(
      `/sites/${siteId}/onenote/sections/${sectionId}/pages?$orderby=order&$top=100`
    );
    return textResult(
      pages.map((p) => ({
        id: p.id,
        title: p.title,
        level: p.level,
        order: p.order,
        createdDateTime: p.createdDateTime,
        lastModifiedDateTime: p.lastModifiedDateTime,
      }))
    );
  }
);

server.registerTool(
  "get_notebook_tree",
  {
    title: "Vollständigen Notizbuch-Baum abrufen",
    description:
      "Läuft Notizbuch → Abschnitte → Seiten ab und liefert die gesamte Struktur als verschachteltes JSON (ohne Seiteninhalt). Guter erster Schritt vor dem Export.",
    inputSchema: {
      notebookId: z.string().optional().describe("Falls leer: alle Notizbücher der Site"),
      ...siteArgs,
    },
  },
  async ({ notebookId, siteHostname, sitePath }) => {
    const siteId = await getSiteId(siteHostname, sitePath);
    const notebooks = notebookId
      ? [await graphRequest(`/sites/${siteId}/onenote/notebooks/${notebookId}`)]
      : await graphListAll(`/sites/${siteId}/onenote/notebooks`);

    const tree = [];
    for (const nb of notebooks) {
      const sections = await graphListAll(`/sites/${siteId}/onenote/notebooks/${nb.id}/sections`);
      const sectionNodes = [];
      for (const sec of sections) {
        const pages = await graphListAll(
          `/sites/${siteId}/onenote/sections/${sec.id}/pages?$orderby=order&$top=100`
        );
        sectionNodes.push({
          id: sec.id,
          displayName: sec.displayName,
          pages: pages.map((p) => ({ id: p.id, title: p.title, order: p.order })),
        });
      }
      tree.push({ id: nb.id, displayName: nb.displayName, sections: sectionNodes });
    }
    return textResult(tree);
  }
);

server.registerTool(
  "get_page_markdown",
  {
    title: "Seiteninhalt als Markdown",
    description:
      "Holt den HTML-Inhalt einer OneNote-Seite und wandelt ihn nach Markdown um. Liefert zusätzlich eine Liste eingebetteter Ressourcen (Bilder/Dateien) mit ihren Graph-URLs, die separat über get_resource geladen werden können.",
    inputSchema: {
      pageId: z.string().describe("ID der Seite (aus list_pages / get_notebook_tree)"),
      ...siteArgs,
    },
  },
  async ({ pageId, siteHostname, sitePath }) => {
    const siteId = await getSiteId(siteHostname, sitePath);
    const res = await graphRequest(`/sites/${siteId}/onenote/pages/${pageId}/content`, { raw: true });
    const html = await res.text();

    const resourceUrls = [...html.matchAll(/(?:src|data-fullres-src)="([^"]+)"/g)]
      .map((m) => m[1])
      .filter((u) => u.includes("/onenote/resources/"));

    const markdown = turndown.turndown(html);

    return textResult({
      pageId,
      markdown,
      embeddedResources: [...new Set(resourceUrls)],
    });
  }
);

server.registerTool(
  "get_resource",
  {
    title: "Eingebettete Ressource laden",
    description:
      "Lädt ein eingebettetes Bild/eine Datei einer OneNote-Seite (URL aus get_page_markdown) und liefert sie Base64-kodiert.",
    inputSchema: {
      resourceUrl: z.string().describe("Vollständige Graph-Ressourcen-URL aus embeddedResources"),
    },
  },
  async ({ resourceUrl }) => {
    const res = await graphRequest(resourceUrl, { raw: true });
    const contentType = res.headers.get("content-type") ?? "application/octet-stream";
    const buffer = Buffer.from(await res.arrayBuffer());
    return textResult({ contentType, base64: buffer.toString("base64") });
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
