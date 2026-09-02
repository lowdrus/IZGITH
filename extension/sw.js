const DEFAULTS = {
  theme: 'cyber-neon',
  autoMode: 'confirm',
  operationMode: 'unified',
  performanceMode: false,
  githubRepos: [],
  history: []
};

chrome.runtime.onInstalled.addListener(async ({ reason }) => {
  const current = await chrome.storage.local.get(Object.keys(DEFAULTS));
  const patch = {};
  for (const [key, value] of Object.entries(DEFAULTS)) {
    if (current[key] === undefined) patch[key] = value;
  }
  if (Object.keys(patch).length) await chrome.storage.local.set(patch);
  console.info(`[IZGITH] ${reason}`);
});

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (!message || typeof message.type !== 'string') return false;
  if (message.type === 'PING') {
    sendResponse({ ok: true, version: chrome.runtime.getManifest().version });
    return false;
  }
  if (message.type === 'GET_MODE') {
    chrome.storage.local.get({ operationMode: 'unified' }).then(({ operationMode }) => {
      sendResponse({ ok: true, operationMode });
    }).catch(error => sendResponse({ ok: false, error: String(error) }));
    return true;
  }
  return false;
});
