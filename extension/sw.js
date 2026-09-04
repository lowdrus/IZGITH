/* IZGITH MV3: publicação nativa opcional, somente pelas páginas internas. */
importScripts('scripts/forse-worker.js', 'modules/jdownloader/background.js');
const DEFAULTS={theme:'cyber-01',autoMode:'confirm',operationMode:'unified',performanceMode:false,visualDepth:'3D',convDEnabled:true,izgithQueue:[],history:[]};
chrome.runtime.onInstalled.addListener(function(){
  chrome.storage.local.get(Object.keys(DEFAULTS)).then(function(current){
    const patch={};
    Object.keys(DEFAULTS).forEach(function(key){if(current[key]===undefined)patch[key]=DEFAULTS[key];});
    return Object.keys(patch).length?chrome.storage.local.set(patch):undefined;
  }).catch(function(error){console.warn('[IZGITH] storage init failed',error);});
});
function saveBase64(message,sendResponse){
  try{
    const filename=String(message.filename||'izgith-export.txt').replace(/[\\/:*?"<>|]+/g,'_');
    const mime=String(message.mime||'application/octet-stream');
    const base64=String(message.base64||'');
    if(!base64){sendResponse({ok:false,error:'Arquivo vazio.'});return;}
    chrome.downloads.download({url:'data:'+mime+';base64,'+base64,filename:filename,saveAs:true,conflictAction:'uniquify'})
      .then(function(id){sendResponse({ok:true,downloadId:id,saveDialog:true});})
      .catch(function(error){sendResponse({ok:false,error:String(error&&error.message||error)});});
  }catch(error){sendResponse({ok:false,error:String(error&&error.message||error)});}
}
chrome.runtime.onMessage.addListener(function(message,sender,sendResponse){
  if(!message||typeof message!=='object')return false;
  if(message.type==='PING'){sendResponse({ok:true,version:chrome.runtime.getManifest().version,mode:'unified',nativeMessaging:false});return false;}
  if(message.type==='SAVE_FILE'){saveBase64(message,sendResponse);return true;}
  if(message.type==='GET_MODE'){chrome.storage.local.get({operationMode:'unified'}).then(function(r){sendResponse({ok:true,operationMode:r.operationMode});}).catch(function(e){sendResponse({ok:false,error:String(e&&e.message||e)});});return true;}
  if(message.type==='SET_MODE'){
    const allowed=['unified','controlled','ultra'];
    const value=allowed.indexOf(message.operationMode)>=0?message.operationMode:'unified';
    chrome.storage.local.set({operationMode:value}).then(function(){sendResponse({ok:true,operationMode:value});}).catch(function(e){sendResponse({ok:false,error:String(e&&e.message||e)});});
    return true;
  }
  if(message.type==='GET_INTEGRATION_STATUS'){
    sendResponse({ok:true,nativeMessaging:{enabled:false,required:false},integrations:['SONPEF','CONV-D','KIT_UNICO','CHAT_HISTORY'],assistants:['Júlia','Ayella','IZART'],operationMode:'unified'});
    return false;
  }
  return false;
});
