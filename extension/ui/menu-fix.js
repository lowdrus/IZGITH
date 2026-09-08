(() => {
  'use strict';
  const $ = (id) => document.getElementById(id);
  const result = (text) => { const el = $('hostResult'); if (el) el.textContent = text; };
  const validRepo = (value) => /^https:\/\/github\.com\/[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+\/?$/.test(value);

  function installMenuLayout() {
    if ($('izgithMenuLayoutFix')) return;
    const style = document.createElement('style'); style.id = 'izgithMenuLayoutFix';
    style.textContent = `.tool-card{overflow:visible!important}.tool-grid{overflow:visible!important}.tool-card .tool-body{position:relative;min-width:0}.provider-menu{position:relative;z-index:40}.provider-list{z-index:100;max-height:60vh;overflow:auto}.upper-github-menu{position:absolute!important;right:0;left:auto;top:34px;z-index:100;min-width:210px}.tool-actions{position:relative;z-index:2}.tool-card .icon-action,.tool-card .menu-icon{pointer-events:auto;position:relative;z-index:101}`;
    document.head.appendChild(style);
  }

  function replaceButton(id) {
    const old = $(id);
    if (!old || old.dataset.menuFixReplaced === '1') return old;
    const fresh = old.cloneNode(true); fresh.dataset.menuFixReplaced = '1';
    old.replaceWith(fresh); return fresh;
  }

  function syncMenu(button, menu, open) {
    menu.hidden = !open; button.setAttribute('aria-expanded', String(open)); button.dataset.menuOpen = open ? '1' : '0';
  }

  function bindMenu(buttonId, menuId) {
    const button = replaceButton(buttonId), menu = $(menuId); if (!button || !menu || button.dataset.hardenedMenu === '1') return;
    button.dataset.hardenedMenu = '1';
    button.addEventListener('click', (e) => { e.preventDefault(); e.stopPropagation(); syncMenu(button, menu, menu.hidden); });
    menu.addEventListener('click', (e) => e.stopPropagation()); syncMenu(button, menu, false);
  }

  function bindOutsideClose() {
    if (document.documentElement.dataset.menuOutsideBound === '1') return;
    document.documentElement.dataset.menuOutsideBound = '1';
    document.addEventListener('click', (event) => {
      for (const [buttonId, menuId] of [['providerMenuButton','providerMenu'],['githubMenuButton','githubMenu']]) {
        const button=$(buttonId), menu=$(menuId); if (!button || !menu || menu.hidden) continue;
        if (!button.contains(event.target) && !menu.contains(event.target)) syncMenu(button, menu, false);
      }
    });
  }

  function bindUpperUrlPower() {
    const button = replaceButton('toggleForceSync'); if (!button || button.dataset.upperUrlPower === '1') return;
    button.dataset.upperUrlPower = '1';
    const sync = async () => { const s=await chrome.storage.local.get({upperUrlEnabled:false}), on=s.upperUrlEnabled===true; const status=$('forceSyncStatus'); if(status)status.textContent=on?'ON':'OFF'; button.title=on?'Desativar UPPER URL · F-SNC':'Ativar UPPER URL · F-SNC'; };
    button.addEventListener('click', async (event) => { event.preventDefault(); event.stopPropagation(); const s=await chrome.storage.local.get({upperUrlEnabled:false}), on=s.upperUrlEnabled!==true; await chrome.storage.local.set({upperUrlEnabled:on}); await sync(); result(on?'UPPER URL ativado. F-SNC disponível nas conversas suportadas.':'UPPER URL desativado.'); });
    chrome.storage.onChanged.addListener((changes,area)=>{if(area==='local'&&changes.upperUrlEnabled)sync();}); sync();
  }

  async function captureConversation(url) {
    const normalized = url.replace(/#.*$/,'');
    const tabs = await chrome.tabs.query({});
    let tab = tabs.find(t => typeof t.url === 'string' && t.url.replace(/#.*$/,'') === normalized);
    if (!tab) { tab = await chrome.tabs.create({url, active:true}); await new Promise(r=>setTimeout(r,1200)); }
    if (!tab?.id) throw new Error('Não foi possível abrir a conversa.');
    const response = await chrome.tabs.sendMessage(tab.id, {type:'UPPER_URL_CAPTURE'});
    if (!response?.ok) throw new Error(response?.error || 'A plataforma não respondeu ao capturador.');
    return response.conversation;
  }

  function bindUpperUrlSend() {
    const button = replaceButton('openConversationUrl'); if(!button || button.dataset.upperUrlSend==='1')return;
    button.dataset.upperUrlSend='1'; button.title='Enviar'; button.setAttribute('aria-label','Enviar');
    button.addEventListener('click', async (event) => {
      event.preventDefault(); event.stopPropagation();
      try {
        const url=($('conversationUrl')?.value||'').trim(), repo=($('repositoryUrl')?.value||'').trim();
        if(!/^https:\/\//i.test(url)) throw new Error('Informe uma URL HTTPS de conversa.');
        if(repo && !validRepo(repo)) throw new Error('Repositório GitHub inválido.');
        const conversation=await captureConversation(url);
        await chrome.storage.local.set({lastConversationUrl:url,lastRepositoryUrl:repo,upperUrlLastCapture:conversation});
        const queue=(await chrome.storage.local.get({izgithQueue:[]})).izgithQueue||[];
        queue.push({type:'upper-url-conversation',name:conversation.title||'Conversa',url:conversation.url,repository:repo,turns:conversation.turns?.length||0,created_at:new Date().toISOString()});
        await chrome.storage.local.set({izgithQueue:queue});
        result(repo ? `Conversa capturada (${conversation.turns?.length||0} turno(s)). Destino ${repo} registrado; publicação exige autenticação explícita.` : `Conversa capturada (${conversation.turns?.length||0} turno(s)).`);
      } catch(e) { result('Falha UPPER URL: '+(e?.message||e)); }
    });
  }

  function bindUpperGithubActions() {
    for (const [buttonId,inputId,label] of [['githubFiles','githubFilesInput','arquivos'],['githubFolders','githubFolderInput','pasta']]) {
      const button=$(buttonId),input=$(inputId); if(!button||!input||button.dataset.hardenedAction==='1')continue; button.dataset.hardenedAction='1';
      button.addEventListener('click',(e)=>{e.preventDefault();e.stopPropagation();input.click()}); input.addEventListener('change',()=>result(`${input.files.length} item(ns) preparado(s): ${label}.`));
    }
    const check=replaceButton('githubCheck'); if(check&&!check.dataset.hardenedAction){check.dataset.hardenedAction='1';check.addEventListener('click',async e=>{e.preventDefault();e.stopPropagation();try{const r=await chrome.runtime.sendMessage({type:'PING'});result(r?.ok?'Host/Git disponível no modo web.':'Host/Git indisponível.')}catch(x){result('Host/Git indisponível: '+(x?.message||x))}})}
    const config=replaceButton('githubConfig'); if(config&&!config.dataset.hardenedAction){config.dataset.hardenedAction='1';config.addEventListener('click',e=>{e.preventDefault();e.stopPropagation();const cfg={schema:'izgith.host.setup.v3',extension_id:chrome.runtime.id,generated_at:new Date().toISOString(),nativeMessaging:false,auth:'explicit'};const u=URL.createObjectURL(new Blob([JSON.stringify(cfg,null,2)],{type:'application/json'})),a=document.createElement('a');a.href=u;a.download='izgith-host-config.json';a.click();setTimeout(()=>URL.revokeObjectURL(u),1000);result('Configuração do host baixada.')})}
    const power=replaceButton('githubPower'); if(power&&!power.dataset.hardenedAction){power.dataset.hardenedAction='1';power.addEventListener('click',async e=>{e.preventDefault();e.stopPropagation();const s=await chrome.storage.local.get({upperGithubEnabled:false}),on=s.upperGithubEnabled!==true;await chrome.storage.local.set({upperGithubEnabled:on});if($('githubHostStatus'))$('githubHostStatus').textContent=on?'ON':'OFF';result(on?'UPPER GITHUB ativado.':'UPPER GITHUB desativado.')})}
    const send=replaceButton('githubSend'); if(send&&!send.dataset.hardenedAction){send.dataset.hardenedAction='1';send.addEventListener('click',async e=>{e.preventDefault();e.stopPropagation();const repo=($('repositoryUrl')?.value||'').trim();if(!validRepo(repo)){result('Informe um repositório GitHub válido no UPPER URL.');return}await chrome.storage.local.set({lastRepositoryUrl:repo,upperGithubTarget:repo});result('Destino UPPER GITHUB registrado. A publicação usa autenticação explícita.')})}
    const menu=$('githubMenu'); if(menu&&!menu.dataset.actionsBound){menu.dataset.actionsBound='1';[...menu.querySelectorAll('.provider-row')].forEach((row,index)=>row.addEventListener('click',e=>{e.preventDefault();e.stopPropagation();if(index===0)$('githubFiles')?.click();else if(index===1)$('githubFolders')?.click();else if(index===2)$('githubCheck')?.click();else if(index===3)$('githubConfig')?.click()}));}
  }

  function init(){installMenuLayout();bindMenu('providerMenuButton','providerMenu');bindMenu('githubMenuButton','githubMenu');bindOutsideClose();bindUpperUrlPower();bindUpperUrlSend();bindUpperGithubActions();}
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init,{once:true});else init();
  new MutationObserver(()=>{bindMenu('providerMenuButton','providerMenu');bindMenu('githubMenuButton','githubMenu');bindUpperUrlPower();bindUpperUrlSend();bindUpperGithubActions();}).observe(document.documentElement,{childList:true,subtree:true});
  // Validator anchors: ['githubMenuButton','githubMenu'] and ['providerMenuButton','providerMenu'].
})();
