// Dünner Microsoft-Graph-Client für App-Only-Zugriff (Client-Credentials-Flow).
// Braucht: AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET als Umgebungsvariablen.

const GRAPH_BASE = "https://graph.microsoft.com/v1.0";

let cachedToken = null; // { value, expiresAt }

function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(
      `Umgebungsvariable ${name} fehlt. Bitte in der Environment-Konfiguration setzen (siehe README).`
    );
  }
  return value;
}

async function getAccessToken() {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 30_000) {
    return cachedToken.value;
  }

  const tenantId = requireEnv("AZURE_TENANT_ID");
  const clientId = requireEnv("AZURE_CLIENT_ID");
  const clientSecret = requireEnv("AZURE_CLIENT_SECRET");

  const tokenUrl = `https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/token`;
  const body = new URLSearchParams({
    grant_type: "client_credentials",
    client_id: clientId,
    client_secret: clientSecret,
    scope: "https://graph.microsoft.com/.default",
  });

  const res = await fetch(tokenUrl, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Token-Anfrage fehlgeschlagen (${res.status}): ${text}`);
  }

  const json = await res.json();
  cachedToken = {
    value: json.access_token,
    expiresAt: Date.now() + json.expires_in * 1000,
  };
  return cachedToken.value;
}

async function graphRequest(path, { raw = false } = {}) {
  const token = await getAccessToken();
  const url = path.startsWith("http") ? path : `${GRAPH_BASE}${path}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Graph-Anfrage an ${url} fehlgeschlagen (${res.status}): ${text}`);
  }

  if (raw) {
    return res;
  }
  return res.json();
}

// Läuft alle @odata.nextLink-Seiten ab und sammelt "value" zu einer flachen Liste.
async function graphListAll(path) {
  let items = [];
  let next = `${GRAPH_BASE}${path}`;
  while (next) {
    const page = await graphRequest(next);
    items = items.concat(page.value ?? []);
    next = page["@odata.nextLink"] ?? null;
  }
  return items;
}

async function resolveSiteId(hostname, sitePath) {
  const normalizedPath = sitePath.startsWith("/") ? sitePath : `/${sitePath}`;
  const site = await graphRequest(`/sites/${hostname}:${normalizedPath}`);
  return site.id;
}

export { getAccessToken, graphRequest, graphListAll, resolveSiteId, GRAPH_BASE };
