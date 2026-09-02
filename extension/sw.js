/* IZGITH 6.0.0.00044 - MV3 service worker. */
const DEFAULTS = {
  theme: 'cyber-neon',
  autoMode: 'confirm',
  operationMode: 'unified',
  performanceMode: false,
  githubRepos: [],
  history: []
};

const NATIVE_HOST = 'com.izgith.host';

chrome.runtime.onInstalled.addListener(function(details) {
  chrome.storage.local.get(Object.keys(DEFAULTS)).then(function(current) {
    const patch = {};
    Object.keys(DEFAULTS).forEach(function(key) {
      if (current[key] === undefined) patch[key] = DEFAULTS[key];
    });
    if (Object.keys(patch).length) return chrome.storage.local.set(patch);
  }).catch(function(error) {
    console.warn('[IZGITH] storage init failed', error);
  });
  console.info('[IZGITH] installed/updated:', details.reason);
});

function nativeHostCheck(sendResponse) {
  let port;
  try {
    port = chrome.runtime.connectNative(NATIVE_HOST);
  } catch (error) {
    sendResponse({ ok: false, available: false, code: 'CONNECT_THROW', error: String(error && error.message || error) });
    return;
  }

  let finished = false;
  let timer = setTimeout(function() {
    finish({ ok: false, available: false, code: 'TIMEOUT', error: 'Native host did not respond.' });
  }, 3000);

  function finish(payload) {
    if (finished) return;
    finished = true;
    clearTimeout(timer);
    try { port.disconnect(); } catch (_) {}
    sendResponse(payload);
  }

  port.onMessage.addListener(function(message) {
    finish({ ok: true, available: true, response: message || null });
  });

  port.onDisconnect.addListener(function() {
    /* lastError is consumed synchronously so Chrome does not emit an unchecked runtime.lastError. */
    const lastError = chrome.runtime.lastError;
    finish({
      ok: false,
      available: false,
      code: 'DISCONNECT',
      error: lastError && lastError.message ? lastError.message : 'Native host disconnected without a response.'
    });
  });

  try {
    port.postMessage({ command: 'ping' });
  } catch (error) {
    finish({ ok: false, available: false, code: 'POST_THROW', error: String(error && error.message || error) });
  }
}

chrome.runtime.onMessage.addListener(function(message, sender, sendResponse) {
  if (!message || typeof message !== 'object') return false;

  if (message.type === 'PING') {
    sendResponse({ ok: true, version: chrome.runtime.getManifest().version });
    return false;
  }

  if (message.type === 'NATIVE_HOST_CHECK') {
    nativeHostCheck(sendResponse);
    return true;
  }

  if (message.type === 'GET_MODE') {
    chrome.storage.local.get({ operationMode: 'unified' }).then(function(result) {
      sendResponse({ ok: true, operationMode: result.operationMode });
    }).catch(function(error) {
      sendResponse({ ok: false, error: String(error && error.message || error) });
    });
    return true;
  }

  if (message.type === 'GET_INTEGRATION_STATUS') {
    sendResponse({
      ok: true,
      nativeMessaging: { host: NATIVE_HOST, bootRequired: false },
      integrations: ['SONPEF', 'CONVGPT', 'KIT_UNICO', 'CHAT_HISTORY'],
      assistants: ['Júlia', 'Ayelle', 'IZART']
    });
    return false;
  }

  return false;
});
