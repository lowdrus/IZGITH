// content/chat_capture.js — v36.5
(function() {
  const SEND_INTERVAL_MS = 1500;
  let pending = false;
  let lastHash = "";

  function sha256(str) {
    const encoder = new TextEncoder();
    const data = encoder.encode(str);
    return crypto.subtle.digest("SHA-256", data).then(buf => {
      const b = new Uint8Array(buf);
      let hex = "";
      for (let i = 0; i < b.length; i++) hex += b[i].toString(16).padStart(2, "0");
      return hex;
    });
  }

  function scrapeConversationText() {
    try {
      const root = document.body;
      if (!root) return "";
      let text = root.innerText || "";
      text = text.replace(/\s+\n/g, "\n").replace(/\n{3,}/g, "\n\n");
      return text.trim();
    } catch (e) {
      return "";
    }
  }

  async function sendSnapshot() {
    if (pending) return;
    pending = true;
    try {
      const conf = await chrome.storage.local.get(["conv_capture_enabled"]);
      if (conf && conf.conv_capture_enabled === false) return;

      const snapshot = scrapeConversationText();
      if (!snapshot || snapshot.length < 10) return;

      const h = await sha256(snapshot);
      if (h === lastHash) return;
      lastHash = h;

      chrome.runtime.sendMessage({
        cmd: "append_log",
        payload: { source: location.hostname, when: new Date().toISOString(), text: snapshot, hash: h }
      }, () => {});
    } finally {
      pending = false;
    }
  }

  setTimeout(sendSnapshot, 1200);
  setInterval(sendSnapshot, SEND_INTERVAL_MS);
  const obs = new MutationObserver(() => { setTimeout(sendSnapshot, 300); });
  obs.observe(document.documentElement, { subtree: true, childList: true, characterData: true });
})();
