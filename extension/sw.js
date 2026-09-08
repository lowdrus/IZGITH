/* IZGITH 6.0.0.00074 - MV3 service worker. Browser-first; Native Messaging is deliberately not used. */
const DEFAULTS={theme:'cyber-01',autoMode:'confirm',operationMode:'unified',performanceMode:false,visualDepth:'3D',convDEnabled:true,upperUrlEnabled:false,upperGithubEnabled:false,izgithQueue:[],history:[],fsncLastCapture:null,fsncAutoPublish:false,lastRepositoryUrl:''};
let githubToken=null;

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

function parseRepository(value){
  try{
    const u=new URL(String(value||''));
    if(u.protocol!=='https:'||u.hostname!=='github.com')return null;
    const parts=u.pathname.split('/').filter(Boolean);
    if(parts.length!==2)return null;
    return {owner:parts[0],repo:parts[1].replace(/\\.git$/,'' )};
  }catch(_){return null;}
}
function encodeBase64Utf8(value){
  const bytes=new TextEncoder().encode(String(value));
  let binary='';
  for(let i=0;i<bytes.length;i+=0x8000)binary+=String.fromCharCode.apply(null,bytes.subarray(i,i+0x8000));
  return btoa(binary);
}
function safeSegment(value){return String(value||'item').replace(/[^a-zA-Z0-9._-]+/g,'_').slice(0,80)||'item';}

async function githubRequest(url,options){
  if(!githubToken)throw new Error('GitHub não autorizado. Use Autorizar no UPPER GITHUB.');
  const headers=Object.assign({'Accept':'application/vnd.github+json','Authorization':'Bearer '+githubToken,'X-GitHub-Api-Version':'2022-11-28'},options&&options.headers||{});
  const response=await fetch(url,Object.assign({},options||{}, {headers:headers}));
  const text=await response.text();
  let data=null;try{data=text?JSON.parse(text):null;}catch(_){data={message:text};}
  if(!response.ok)throw new Error(String(data&&data.message||('GitHub HTTP '+response.status)));
  return data;
}

async function publishCapture(capture,repository,branch){
  const target=parseRepository(repository||'');
  if(!target)throw new Error('Repositório GitHub inválido. Use https://github.com/usuario/repositorio.');
  const ref=String(branch||'main');
  const provider=safeSegment(capture&&capture.host||capture&&capture.provider||'ia');
  const stamp=new Date().toISOString().replace(/[:.]/g,'-');
  const path='captures/fsnc/'+provider+'/'+stamp+'.json';
  const api='https://api.github.com/repos/'+encodeURIComponent(target.owner)+'/'+encodeURIComponent(target.repo)+'/contents/'+path.split('/').map(encodeURIComponent).join('/')+'?ref='+encodeURIComponent(ref);
  let existing=null;
  try{existing=await githubRequest(api,{method:'GET'});}catch(e){if(!/Not Found/i.test(String(e.message)))throw e;}
  const body={message:'feat(fsnc): publish captured conversation · '+provider,content:encodeBase64Utf8(JSON.stringify(capture,null,2)),branch:ref};
  if(existing&&existing.sha)body.sha=existing.sha;
  const saved=await githubRequest(api.replace(/\?ref=.*$/,''),{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
  return {path:path,commit:saved&&saved.commit&&saved.commit.sha||null,html_url:saved&&saved.content&&saved.content.html_url||null};
}

chrome.runtime.onMessage.addListener(function(message,sender,sendResponse){
  if(!message||typeof message!=='object')return false;
  if(message.type==='PING'){sendResponse({ok:true,version:chrome.runtime.getManifest().version,mode:'unified',nativeMessaging:false,githubAuthorized:!!githubToken});return false;}
  if(message.type==='SAVE_FILE'){saveBase64(message,sendResponse);return true;}
  if(message.type==='GITHUB_AUTH_STATUS'){sendResponse({ok:true,authorized:!!githubToken,automaticPublication:!!githubToken});return false;}
  if(message.type==='GITHUB_AUTHORIZE'){
    const token=String(message.token||'').trim();
    if(!token){sendResponse({ok:false,error:'Token vazio.'});return false;}
    githubToken=token;
    chrome.storage.local.set({fsncAutoPublish:true}).then(function(){sendResponse({ok:true,authorized:true,automaticPublication:true});}).catch(function(e){sendResponse({ok:false,error:String(e&&e.message||e)});});
    return true;
  }
  if(message.type==='GITHUB_REVOKE'){
    githubToken=null;
    chrome.storage.local.set({fsncAutoPublish:false}).then(function(){sendResponse({ok:true,authorized:false});});
    return true;
  }
  if(message.type==='GITHUB_PUBLISH_CAPTURE'){
    chrome.storage.local.get({lastRepositoryUrl:'',upperGithubTarget:''}).then(async function(s){
      try{
        const repo=String(message.repository||s.upperGithubTarget||s.lastRepositoryUrl||'').trim();
        const out=await publishCapture(message.capture,repo,message.branch||'main');
        sendResponse({ok:true,publication:out});
      }catch(e){sendResponse({ok:false,error:String(e&&e.message||e)});}
    });
    return true;
  }
  if(message.type==='FSNC_CAPTURE'){
    try{
      const c=message.conversation;
      if(!c||!c.latest_turn||!c.url){sendResponse({ok:false,error:'Captura F-SNC inválida.'});return false;}
      chrome.storage.local.set({fsncLastCapture:c,fsncLastCaptureAt:new Date().toISOString()}).then(async function(){
        const s=await chrome.storage.local.get({fsncAutoPublish:false,lastRepositoryUrl:'',upperGithubTarget:''});
        let publication=null;
        if(s.fsncAutoPublish&&githubToken&&(s.upperGithubTarget||s.lastRepositoryUrl)){
          try{publication=await publishCapture(c,s.upperGithubTarget||s.lastRepositoryUrl,'main');}
          catch(e){sendResponse({ok:true,stored:true,requiresExplicitPublish:true,publicationError:String(e&&e.message||e)});return;}
        }
        sendResponse({ok:true,stored:true,requiresExplicitPublish:!publication,publication:publication});
      }).catch(function(e){sendResponse({ok:false,error:String(e&&e.message||e)});});
      return true;
    }catch(e){sendResponse({ok:false,error:String(e&&e.message||e)});return false;}
  }
  if(message.type==='GET_FSNC_CAPTURE'){
    chrome.storage.local.get({fsncLastCapture:null}).then(function(r){sendResponse({ok:true,capture:r.fsncLastCapture});}).catch(function(e){sendResponse({ok:false,error:String(e&&e.message||e)});});
    return true;
  }
  if(message.type==='GET_MODE'){chrome.storage.local.get({operationMode:'unified'}).then(function(r){sendResponse({ok:true,operationMode:r.operationMode});}).catch(function(e){sendResponse({ok:false,error:String(e&&e.message||e)});});return true;}
  if(message.type==='SET_MODE'){
    const allowed=['unified','controlled','ultra'];
    const value=allowed.indexOf(message.operationMode)>=0?message.operationMode:'unified';
    chrome.storage.local.set({operationMode:value}).then(function(){sendResponse({ok:true,operationMode:value});}).catch(function(e){sendResponse({ok:false,error:String(e&&e.message||e)});});
    return true;
  }
  if(message.type==='GET_INTEGRATION_STATUS'){
    sendResponse({ok:true,nativeMessaging:{enabled:false,required:false},integrations:['SONPEF','CONV-D','KIT_UNICO','CHAT_HISTORY','UPPER URL','F-SNC'],assistants:['Júlia','Ayella','IZART'],operationMode:'unified'});
    return false;
  }
  return false;
});
