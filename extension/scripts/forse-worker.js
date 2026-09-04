chrome.runtime.onMessage.addListener((message,sender,respond)=>{
  if(message?.type!=='FORSE_PREVIEW')return false;
  (async()=>{
    if(sender.id!==chrome.runtime.id||!sender.tab||sender.frameId!==0)throw new Error('Origem não autorizada.');
    const config=(await chrome.storage.local.get('forseConfig')).forseConfig;
    const url=new URL(sender.url||'');const conversation=url.origin+url.pathname.replace(/\/$/,'');
    if(url.origin!=='https://chatgpt.com'||!config?.enabled||config.conversation!==conversation)throw new Error('Esta conversa não está autorizada.');
    const p=message.payload;
    if(p?.schema!=='izgith.forse-sinc.v1'||p.conversation!==conversation||!Array.isArray(p.messages)||!p.messages.length||p.messages.some(m=>!['user','assistant'].includes(m.role)||typeof m.text!=='string'))throw new Error('Exportação inválida.');
    if(new TextEncoder().encode(JSON.stringify(p)).length>4*1024*1024)throw new Error('Exportação grande demais.');
    const pending=await chrome.storage.session.get(null);
    if(Object.values(pending).some(x=>x?.forse&&x.tabId===sender.tab.id&&Date.now()-x.created<600000))throw new Error('Já existe uma revisão aberta para esta conversa. Feche ou conclua a revisão antes de repetir.');
    for(const [key,value] of Object.entries(pending))if(value?.forse&&Date.now()-value.created>=600000)await chrome.storage.session.remove(key);
    const id='forse_'+crypto.randomUUID();
    await chrome.storage.session.set({[id]:{forse:true,created:Date.now(),tabId:sender.tab.id,repository:config.repository,payload:p}});
    await chrome.tabs.create({url:chrome.runtime.getURL('ui/publish.html')+'#'+id});return {ok:true};
  })().then(respond).catch(e=>respond({ok:false,error:e.message}));return true;
});
