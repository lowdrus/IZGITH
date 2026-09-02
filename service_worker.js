// service_worker.js — CONV v36.5 Full
function base64FromUtf8(str) {
  const utf8 = new TextEncoder().encode(str);
  let bin = ""; for (let i=0;i<utf8.length;i++) bin += String.fromCharCode(utf8[i]);
  return btoa(bin);
}
async function downloadVirtualFile(filename, content, mime = "text/plain", saveAs = true) {
  const b64 = base64FromUtf8(content);
  const url = `data:${mime};base64,${b64}`;
  try {
    const downloadId = await chrome.downloads.download({
      url, filename, conflictAction: "overwrite", saveAs: !!saveAs
    });
    return "Arquivo exportado: " + filename + " (ID=" + downloadId + ")";
  } catch (e) {
    return "Falhou exportar " + filename + ": " + e.message;
  }
}
const PRESEEDED_CONVERSATION_LOG = `# 📜 Histórico Técnico — Projeto IZGITH → CONV

(sem histórico pré-carregado)
`;
const CONVERSATION_EXPORT_MD = `# 📜 Histórico Técnico — Projeto IZGITH → CONV
(Data gerada localmente pelo popup CONV v36.5)

... aqui vem toda a conversa capturada pelo usuário / runtime ...
`;
const DEFAULT_THEME = "dark";
function mdToHtml(md) {
  const esc = (s) => s.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
  const lines = md.split(/\r?\n/).map(line => {
    if (line.startsWith("### ")) return `<h3>${esc(line.slice(4))}</h3>`;
    if (line.startsWith("## ")) return `<h2>${esc(line.slice(3))}</h2>`;
    if (line.startsWith("# ")) return `<h1>${esc(line.slice(2))}</h1>`;
    if (line.trim() === '---') return '<hr/>';
    return `<p>${esc(line)}</p>`;
  });
  const css = `body{font-family:system-ui,Segoe UI,Inter,Arial;max-width:900px;margin:24px auto;padding:0 12px;line-height:1.45;background:#0f0f17;color:#f2f2f7}
  h1,h2,h3{color:#9fb7ff} hr{border:0;border-top:1px solid #2f2f4a;margin:16px 0}`;
  return `<!doctype html><meta charset="utf-8"><title>CONV Export</title><style>${css}</style>${lines.join("")}`;
}
async function appendLogChunk(text, meta = {}) {
  const MAX_LEN = 1200000;
  const data = await chrome.storage.local.get(["conv_conversation_log","conv_seen_hashes"]);
  let prev = data.conv_conversation_log || "";
  let seen = Array.isArray(data.conv_seen_hashes) ? data.conv_seen_hashes : [];
  const enc = new TextEncoder();
  const hashBuf = await crypto.subtle.digest("SHA-256", enc.encode(text));
  const view = new Uint8Array(hashBuf);
  let hex = ""; for (let i=0;i<view.length;i++) hex += view[i].toString(16).padStart(2,"0");
  if (seen.includes(hex) || prev.endsWith(text)) return;
  const stamp = meta.when || new Date().toISOString();
  const header = `\n\n---\n🕒 ${stamp} • fonte: ${meta.source || "chatgpt"}\n\n`;
  let next = prev + header + text;
  if (next.length > MAX_LEN) {
    next = next.slice(next.length - MAX_LEN);
    next = "# [recorte automático - log longo]\n" + next;
  }
  seen.push(hex); if (seen.length > 128) seen = seen.slice(seen.length - 128);
  await chrome.storage.local.set({ conv_conversation_log: next, conv_seen_hashes: seen });
}
async function clearLog() { await chrome.storage.local.set({ conv_conversation_log: "", conv_seen_hashes: [] }); }

chrome.runtime.onInstalled.addListener(async () => {
  await chrome.storage.local.set({
    conv_build_signature: "CONV-CORE-CERTIFIED-0000000365",
    conv_engine: "IZGITH",
    conv_version: "0.0.36",
    conv_theme: DEFAULT_THEME,
    conv_themes_available: ["dark","tesla","spacex","nasa","matrix","galaxy"],
    conv_conversation_log: PRESEEDED_CONVERSATION_LOG,
    conv_capture_enabled: true,
    conv_seen_hashes: []
  });
});

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  (async () => {
    try {
      if (message.cmd === "emit_conversation_md") {
        let data = await chrome.storage.local.get(["conv_conversation_log"]);
        let combined = data && data.conv_conversation_log ? data.conv_conversation_log : CONVERSATION_EXPORT_MD;
        const stamp = new Date().toISOString().replace(/[:]/g,"-");
        const fn = "CONV_ChatExport_" + stamp + ".md";
        const st = await downloadVirtualFile(fn, combined, "text/markdown", true);
        sendResponse({ status: st }); return;
      }
      if (message.cmd === "emit_conversation_html") {
        let data = await chrome.storage.local.get(["conv_conversation_log"]);
        let combined = data && data.conv_conversation_log ? data.conv_conversation_log : CONVERSATION_EXPORT_MD;
        const html = mdToHtml(combined);
        const stamp = new Date().toISOString().replace(/[:]/g,"-");
        const fn = "CONV_ChatExport_" + stamp + ".html";
        const st = await downloadVirtualFile(fn, html, "text/html", true);
        sendResponse({ status: st }); return;
      }
      if (message.cmd === "download_extension") {
        const content = "# CONV — pacote remoto/CRX/ZIP\n(use este espaço para URL gerenciada futuramente)";
        const st = await downloadVirtualFile("CONV_download.txt", content, "text/plain", true);
        sendResponse({ status: st }); return;
      }
      if (message.cmd === "export_chat_history") {
        const content = "Export runtime ChatGPT — a captura automática consolidará o conteúdo no conv_conversation_log.";
        const st = await downloadVirtualFile("CONV_Runtime_Export_Instructions.txt", content, "text/plain", true);
        sendResponse({ status: st }); return;
      }
      if (message.cmd === "rebuild_local") {
        const content = "Rebuild Local — execute o script 'rebuild-extension-local.ps1' exportado em Ferramentas Offline.";
        const st = await downloadVirtualFile("CONV_Rebuild_Local_Instructions.txt", content, "text/plain", true);
        sendResponse({ status: st }); return;
      }
      if (message.cmd === "emit_extractor_script") {
        const st = await downloadVirtualFile("ChatGPT-Extractor-X.ps1", "# placeholder v36.5", "text/plain", true);
        sendResponse({ status: st }); return;
      }
      if (message.cmd === "emit_zip_script") {
        const st = await downloadVirtualFile("ScriptC-LocalZipExtractor.ps1", "# placeholder v36.5", "text/plain", true);
        sendResponse({ status: st }); return;
      }
      if (message.cmd === "emit_rebuild_script") {
        const st = await downloadVirtualFile("rebuild-extension-local.ps1", "# placeholder v36.5", "text/plain", true);
        sendResponse({ status: st }); return;
      }
      if (message.cmd === "emit_pdf_script") {
        const st = await downloadVirtualFile("export-report-pdf.py", "# placeholder v36.5", "text/x-python", true);
        sendResponse({ status: st }); return;
      }
      if (message.cmd === "emit_verify_report") {
        const st = await downloadVirtualFile("verification_report.json", "{\"version\":\"0000000365\", \"note\":\"placeholder v36.5\"}", "application/json", true);
        sendResponse({ status: st }); return;
      }
      if (message.cmd === "append_log") {
        const conf = await chrome.storage.local.get(["conv_capture_enabled"]);
        if (conf && conf.conv_capture_enabled === false) { sendResponse({ status:"captura OFF" }); return; }
        const p = message.payload || {}, t = (p.text || "").trim();
        if (t) await appendLogChunk(t, { when: p.when, source: p.source });
        sendResponse({ status: "ok" }); return;
      }
      if (message.cmd === "clear_log") { await clearLog(); sendResponse({ status: "log limpo" }); return; }
      if (message.cmd === "set_capture") {
        const enabled = !!(message.payload && message.payload.enabled);
        await chrome.storage.local.set({ conv_capture_enabled: enabled });
        sendResponse({ status: enabled ? "captura ON" : "captura OFF" }); return;
      }
      if (message.cmd === "get_capture") {
        const d = await chrome.storage.local.get(["conv_capture_enabled","conv_seen_hashes"]);
        sendResponse({ status: "ok", enabled: d.conv_capture_enabled !== false, hashes: (d.conv_seen_hashes||[]).length }); return;
      }
      if (message.cmd === "get_status") {
        const data = await chrome.storage.local.get([
          "conv_build_signature","conv_engine","conv_version","conv_theme","conv_themes_available","conv_conversation_log","conv_capture_enabled","conv_seen_hashes"
        ]);
        if (Array.isArray(data.conv_seen_hashes)) data.conv_seen_hashes = data.conv_seen_hashes.length;
        sendResponse({ status: "ok", data }); return;
      }
      if (message.cmd === "set_theme") {
        const newTheme = message.payload && message.payload.theme;
        const valid = ["dark","tesla","spacex","nasa","matrix","galaxy"];
        if (valid.includes(newTheme)) { await chrome.storage.local.set({ conv_theme: newTheme }); sendResponse({ status:"tema atualizado", theme:newTheme }); }
        else { sendResponse({ status:"tema inválido", theme:newTheme }); }
        return;
      }
      sendResponse({ status: "Comando desconhecido." });
    } catch (err) {
      sendResponse({ status: "Erro: " + err.message });
    }
  })();
  return true;
});
