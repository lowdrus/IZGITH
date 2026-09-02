/* IZGITH 6.0.0.00051 - MV3 service worker. Native Messaging is optional. */
const DEFAULTS = { theme: 'cyber-neon', autoMode: 'confirm', operationMode: 'unified', performanceMode: false, githubRepos: [], history: [] };
const NATIVE_HOST = 'com.izgith.host';
const NATIVE_TIMEOUT_MS = 5000;

chrome.runtime.onInstalled.addListener(function(details) {
  chrome.storage.local.get(Object.keys(DEFAULTS)).then(function(current) {
    const patch = {};
    Object.keys(DEFAULTS).forEach(function(key) { if (current[key] === undefined) patch[key] = DEFAULTS[key]; });
    return Object.keys(patch).length ? chrome.storage.local.set(patch) : undefined;
  }).catch(function(error) { console.warn('[IZGITH] storage init failed', error); });
  console.info('[IZGITH] installed/updated:', details.reason);
});

function nativeRequest(payload, timeoutMs) {
  return new Promise(function(resolve) {
    let port = null, finished = false, timer = null;
    function finish(result) { if (finished) return; finished = true; if (timer) clearTimeout(timer); if (port) { try { port.disconnect(); } catch (_) {} } resolve(result); }
    try { port = chrome.runtime.connectNative(NATIVE_HOST); }
    catch (error) { finish({ok:false,available:false,code:'CONNECT_THROW',error:String(error && error.message || error)}); return; }
    timer = setTimeout(function() { finish({ok:false,available:false,code:'TIMEOUT',error:'Native host did not respond in time.'}); }, timeoutMs || NATIVE_TIMEOUT_MS);
    port.onMessage.addListener(function(message) { finish({ok:true,available:true,response:message || null}); });
    port.onDisconnect.addListener(function() {
      const lastError = chrome.runtime.lastError;
      finish({ok:false,available:false,code:'DISCONNECT',error:lastError && lastError.message ? lastError.message : 'Native host disconnected without a response.'});
    });
    try { port.postMessage(payload || {command:'ping'}); }
    catch (error) { finish({ok:false,available:false,code:'POST_THROW',error:String(error && error.message || error)}); }
  });
}

chrome.runtime.onMessage.addListener(function(message, sender, sendResponse) {
  if (!message || typeof message !== 'object') return false;
  if (message.type === 'PING') { sendResponse({ok:true,version:chrome.runtime.getManifest().version,mode:'unified'}); return false; }
  if (message.type === 'NATIVE_HOST_CHECK') {
    nativeRequest({command:'ping'}, 3000).then(function(result) { sendResponse({ok:result.ok===true,available:result.available===true,host:NATIVE_HOST,code:result.code||null,error:result.error||null,response:result.response||null}); });
    return true;
  }
  if (message.type === 'NATIVE_CALL') { nativeRequest(message.payload || {}, NATIVE_TIMEOUT_MS).then(sendResponse); return true; }
  if (message.type === 'GET_MODE') { chrome.storage.local.get({operationMode:'unified'}).then(function(r){sendResponse({ok:true,operationMode:r.operationMode});}).catch(function(e){sendResponse({ok:false,error:String(e && e.message || e)});}); return true; }
  if (message.type === 'SET_MODE') {
    const allowed=['unified','controlled','ultra']; const value=allowed.indexOf(message.operationMode)>=0 ? message.operationMode : 'unified';
    chrome.storage.local.set({operationMode:value}).then(function(){sendResponse({ok:true,operationMode:value});}).catch(function(e){sendResponse({ok:false,error:String(e && e.message || e)});}); return true;
  }
  if (message.type === 'GET_INTEGRATION_STATUS') { sendResponse({ok:true,nativeMessaging:{host:NATIVE_HOST,bootRequired:false,probeBeforeCall:true},integrations:['SONPEF','CONVGPT','KIT_UNICO','CHAT_HISTORY'],assistants:['Júlia','Ayella','IZART'],operationMode:'unified'}); return false; }
  return false;
});
