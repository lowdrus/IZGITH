const DEFAULTS = {
  theme: 'cyber-neon',
  autoMode: 'confirm',
  operationMode: 'unified',
  performanceMode: false,
  githubRepos: [],
  history: []
};

const NATIVE_HOST = 'com.izgith.host';

chrome.runtime.onInstalled.addListener(async ({ reason }) => {
  const current = await chrome.storage.local.get(Object.keys(DEFAULTS));
  const patch = {};
  for (const [key, value] of Object.entries(DEFAULTS)) {
    if (current[key] === undefined) patch[key] = value;
  }
  if (Object.keys(patch).length) await chrome.storage.local.set(patch);
  console.info(`[IZGITH] ${reason}`);
});

function nativeHostCheck(sendResponse) {
  let port;
  try { port = chrome.runtime.connectNative(NATIVE_HOST); }
  catch (error) { sendResponse({ ok:false, available:false, error:String(error?.message || error) }); return; }
  let finished = false;
  const finish = payload => { if (finished) return; finished = true; sendResponse(payload); try { port.disconnect(); } catch (_) {} };
  const timer = setTimeout(() => finish({ ok:false, available:false, error:'Native host did not respond.' }), 2500);
  port.onMessage.addListener(message => { clearTimeout(timer); finish({ ok:true, available:true, response:message ?? null }); });
  port.onDisconnect.addListener(() => {
    clearTimeout(timer);
    const runtimeError = chrome.runtime.lastError;
    finish({ ok:false, available:false, error:runtimeError?.message || 'Native host disconnected without a response.' });
  });
  try { port.postMessage({ cmd:'ping' }); }
  catch (error) { clearTimeout(timer); finish({ ok:false, available:false, error:String(error?.message || error) }); }
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (!message || typeof message !== 'object') return false;
  if (message.type === 'PING') { sendResponse({ ok:true, version:chrome.runtime.getManifest().version }); return false; }
  if (message.type === 'NATIVE_HOST_CHECK') { nativeHostCheck(sendResponse); return true; }
  if (message.type === 'GET_MODE') {
    chrome.storage.local.get({ operationMode:'unified' }).then(({ operationMode }) => sendResponse({ ok:true, operationMode })).catch(error => sendResponse({ ok:false, error:String(error) }));
    return true;
  }
  if (message.type === 'GET_INTEGRATION_STATUS') {
    sendResponse({ ok:true, nativeMessaging:{ host:NATIVE_HOST, bootRequired:false }, integrations:['SONPEF','CONVGPT','KIT_UNICO','CHAT_HISTORY'], assistants:['Júlia','Ayelle','IZART'] });
    return false;
  }
  return false;
});
