"use strict";

/**
 * Schlichtes Vanilla-JS, keine Build-Pipeline, kein Framework - passend zu
 * einer statischen $web-Seite ohne Server-Rendering (siehe README
 * Zielarchitektur "Frontend"). Spricht die in backend/function_app.py
 * definierten HTTP-Endpunkte an.
 *
 * API_BASE wird beim Deploy auf die Function-App-URL gesetzt (siehe
 * ../../infra/README.md). Fuer die lokale Entwicklung gegen den Mock-Modus
 * zeigt es per Default auf localhost:7071 (Azure Functions Core Tools
 * Default-Port).
 */
const API_BASE = window.ERFASSUNGSCHAT_API_BASE || "http://localhost:7071/api";

const state = {
  sessionId: null,
  currentListName: "1_Allgemeiner_Stammblock",
  currentRecordIndex: 0,
};

function qs(selector) {
  return document.querySelector(selector);
}

function parseLinkParams() {
  const params = new URLSearchParams(window.location.search);
  return { case_id: params.get("case_id"), access_code: params.get("access_code") };
}

function addMessage(container, sender, text) {
  const div = document.createElement("div");
  div.className = `nachricht ${sender === "chat" ? "chat" : "mandant"}`;
  const label = document.createElement("span");
  label.className = "absender";
  label.textContent = sender === "chat" ? "Chat" : "Sie";
  const body = document.createElement("span");
  body.textContent = text;
  div.append(label, body);
  container.appendChild(div);
  container.scrollTop = container.scrollHeight;
}

async function apiPost(path, body) {
  const resp = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body || {}),
  });
  const data = await resp.json().catch(() => ({}));
  if (!resp.ok) {
    const err = new Error(data.message || "Unbekannter Fehler");
    err.reason = data.error;
    throw err;
  }
  return data;
}

async function apiGet(path) {
  const resp = await fetch(`${API_BASE}${path}`);
  const data = await resp.json().catch(() => ({}));
  if (!resp.ok) {
    const err = new Error(data.message || "Unbekannter Fehler");
    err.reason = data.error;
    throw err;
  }
  return data;
}

function initZugangsformular() {
  const formular = qs("#zugang-formular");
  const fehlerAnzeige = qs("#zugang-fehler");
  const prefill = parseLinkParams();
  if (prefill.case_id) qs("#case-id").value = prefill.case_id;
  if (prefill.access_code) qs("#access-code").value = prefill.access_code;

  formular.addEventListener("submit", async (event) => {
    event.preventDefault();
    fehlerAnzeige.hidden = true;
    const case_id = qs("#case-id").value.trim();
    const access_code = qs("#access-code").value.trim();
    try {
      const result = await apiPost("/session/start", { case_id, access_code });
      state.sessionId = result.session_id;
      qs("#zugang").hidden = true;
      qs("#chat").hidden = false;
      addMessage(qs("#chat-verlauf"), "chat", result.frage);
    } catch (err) {
      fehlerAnzeige.textContent =
        err.message || "Zugang nicht möglich. Bitte prüfen Sie Fall-ID und Zugangscode.";
      fehlerAnzeige.hidden = false;
    }
  });
}

function initChatformular() {
  const formular = qs("#antwort-formular");
  const feld = qs("#antwort-feld");
  const verlauf = qs("#chat-verlauf");

  formular.addEventListener("submit", async (event) => {
    event.preventDefault();
    const text = feld.value.trim();
    if (!text) return;
    addMessage(verlauf, "mandant", text);
    feld.value = "";
    try {
      const result = await apiPost(`/session/${state.sessionId}/message`, {
        list_name: state.currentListName,
        record_index: state.currentRecordIndex,
        message: text,
      });
      addMessage(verlauf, "chat", result.assistant_message);
    } catch (err) {
      addMessage(verlauf, "chat", err.message || "Entschuldigung, das hat nicht funktioniert.");
    }
  });
}

function initErklaerungButton() {
  qs("#erklaerung-button").addEventListener("click", async () => {
    // Vereinfachte Zuordnung fuer den Prototyp: der aktuell gezeigte
    // Abschnittsname wird als Erklaerungs-Schluessel verwendet. In einer
    // ausgebauten Version wuerde der Chat den aktuellen Feld-Schluessel
    // mitliefern (siehe README "Offene Punkte").
    try {
      const result = await apiGet(
        `/session/${state.sessionId}/explain?feld=${encodeURIComponent(state.currentListName)}`
      );
      addMessage(qs("#chat-verlauf"), "chat", result.erklaerung);
    } catch (err) {
      addMessage(qs("#chat-verlauf"), "chat", "Dazu liegt leider keine Erklärung vor.");
    }
  });
}

function initUpload() {
  qs("#upload-button").addEventListener("click", async () => {
    const datei = qs("#upload-datei").files[0];
    if (!datei) {
      addMessage(qs("#chat-verlauf"), "chat", "Bitte wählen Sie zuerst eine Datei aus.");
      return;
    }
    const formData = new FormData();
    formData.append("file", datei);
    formData.append("document_type", qs("#upload-typ").value);
    try {
      const resp = await fetch(`${API_BASE}/session/${state.sessionId}/upload`, {
        method: "POST",
        body: formData,
      });
      const data = await resp.json();
      if (!resp.ok) throw new Error(data.message);
      addMessage(qs("#chat-verlauf"), "chat", "Danke, die Datei wurde hochgeladen.");
    } catch (err) {
      addMessage(qs("#chat-verlauf"), "chat", err.message || "Der Upload ist fehlgeschlagen.");
    }
  });
}

async function zeigeZusammenfassung() {
  const result = await apiGet(`/session/${state.sessionId}/summary`);
  const container = qs("#zusammenfassung-inhalt");
  container.innerHTML = "";
  for (const [abschnitt, daten] of Object.entries(result.sections || {})) {
    const h3 = document.createElement("h3");
    h3.textContent = abschnitt;
    const pre = document.createElement("pre");
    pre.textContent = JSON.stringify(daten, null, 2);
    container.append(h3, pre);
  }
  if ((result.unsure_fields || []).length) {
    const hinweis = document.createElement("p");
    hinweis.className = "hinweis";
    hinweis.textContent =
      "Folgende Angaben sind noch offen ('weiss ich nicht') - die Kanzlei meldet sich dazu: " +
      result.unsure_fields.join(", ");
    container.appendChild(hinweis);
  }
  qs("#chat").hidden = true;
  qs("#zusammenfassung").hidden = false;
}

function initBestaetigen() {
  qs("#bestaetigen-button").addEventListener("click", async () => {
    try {
      await apiPost(`/session/${state.sessionId}/confirm`, {});
      const result = await apiPost(`/session/${state.sessionId}/submit`, {});
      qs("#zusammenfassung").hidden = true;
      qs("#abschluss").hidden = false;
      qs("#abschluss-text").textContent =
        "Ihre Angaben wurden übermittelt. Die Kanzlei prüft den Fall und meldet sich bei Ihnen, falls noch Fragen offen sind.";
    } catch (err) {
      addMessage(qs("#chat-verlauf"), "chat", err.message || "Die Übermittlung ist fehlgeschlagen.");
    }
  });
}

document.addEventListener("DOMContentLoaded", () => {
  initZugangsformular();
  initChatformular();
  initErklaerungButton();
  initUpload();
  initBestaetigen();
  window.erfassungschatZeigeZusammenfassung = zeigeZusammenfassung;
});
