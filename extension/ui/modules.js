(() => {
  const ui=IZGITH_UI, publisher=new NativePublisher();
  const grid=document.querySelector('.tool-grid');
  const run=fn=>async()=>{try{await fn();}catch(e){ui.error(e);}};
  function card(title, explanation, html){
    const article=document.createElement('article');article.className='tool-card';
    article.innerHTML='<div class="tool-body"><div class="tool-title"><h3></h3><button class="info-icon" type="button"></button></div>'+html+'</div>';
    article.querySelector('h3').textContent=title;const info=article.querySelector('.info-icon');info.title=explanation;info.setAttribute('aria-label',explanation);info.append(ui.icon('info'));info.onclick=()=>{const d=document.createElement('dialog');d.textContent=explanation;const b=document.createElement('button');b.textContent='Fechar';b.onclick=()=>d.close();d.append(document.createElement('br'),b);d.onclose=()=>d.remove();document.body.append(d);d.showModal();};grid.append(article);return article;
  }
  const jd=card('JDOWNLOADER','Cliente MyJDownloader integrado ao IZGITH. Entre com sua conta MyJDownloader e mantenha um dispositivo JDownloader conectado. A captura de páginas é opcional; exige acesso aos sites. As credenciais MyJDownloader não são credenciais GitHub.', '<div class="module-actions"><button class="btn" id="jdOpen">Abrir JDOWNLOADER</button><button class="btn ghost" id="jdCapture">Ativar captura de páginas</button></div><p class="module-note">Conta MyJDownloader necessária. Não instala o aplicativo JDownloader no computador.</p>');
  jd.querySelector('#jdOpen').onclick=run(()=>chrome.tabs.create({url:chrome.runtime.getURL('modules/jdownloader/popup.html')}));
  let captureEnabled=false;
  chrome.scripting.getRegisteredContentScripts({ids:['izgith-jd-0']}).then(entries=>{captureEnabled=entries.length>0;jd.querySelector('#jdCapture').textContent=captureEnabled?'Desativar captura de páginas':'Ativar captura de páginas';}).catch(e=>ui.error(e));
  jd.querySelector('#jdCapture').onclick=run(async()=>{
    if(captureEnabled){const entries=await chrome.scripting.getRegisteredContentScripts();await chrome.scripting.unregisterContentScripts({ids:entries.filter(x=>x.id.startsWith('izgith-jd-')).map(x=>x.id)});await chrome.storage.local.set({CLICKNLOAD_ACTIVE:false,CONTEXT_MENU_SIMPLE:false});captureEnabled=false;jd.querySelector('#jdCapture').textContent='Ativar captura de páginas';return;}
    if(!await chrome.permissions.request({origins:['<all_urls>']}))throw new Error('Acesso aos sites não autorizado. O painel JDOWNLOADER continua disponível.');
    const config=await (await fetch(chrome.runtime.getURL('modules/jdownloader/content-scripts.json'))).json();
    await chrome.scripting.registerContentScripts(config);await chrome.storage.local.set({CLICKNLOAD_ACTIVE:true,CONTEXT_MENU_SIMPLE:true});captureEnabled=true;jd.querySelector('#jdCapture').textContent='Desativar captura de páginas';
  });
  const upper=card('UPPER GITHUB','Seleciona arquivos ou uma pasta pelo host local. Git LFS é aplicado automaticamente a arquivos a partir de 100 MiB. Git e Git LFS devem estar instalados, com autenticação no Git Credential Manager. Nenhum token é solicitado pelo IZGITH. O host pede confirmação do destino antes do push.', '<label>Repositório<input class="tool-url" id="upperRepo" type="url" placeholder="https://github.com/usuario/repositorio"></label><div class="module-actions"><button class="btn ghost" id="upperFiles">Selecionar arquivos</button><button class="btn ghost" id="upperFolder">Selecionar pasta</button><button class="btn" id="upperSend" disabled>Enviar</button></div><p id="upperSelection" class="module-note">Nenhuma seleção. Host local necessário somente para publicação.</p>');
  const send=upper.querySelector('#upperSend');send.prepend(ui.icon('send'));let busy=false;
  const pick=kind=>run(async()=>{if(busy)return;busy=true;send.disabled=true;try{await publisher.open();const r=await publisher.call('publish_pick',{kind});if(r.cancelled)return;upper.querySelector('#upperSelection').textContent=`${r.count} arquivo(s), ${r.bytes} bytes\n${r.files.join('\n')}`;send.disabled=false;}finally{busy=false;}});
  upper.querySelector('#upperFiles').onclick=pick('files');upper.querySelector('#upperFolder').onclick=pick('folder');
  const setup=document.createElement('button');setup.className='btn ghost';setup.textContent='Baixar configuração do host';
  setup.onclick=run(async()=>{const config={schema:'izgith.host.setup.v1',extension_id:chrome.runtime.id};const url=URL.createObjectURL(new Blob([JSON.stringify(config,null,2)],{type:'application/json'}));try{await chrome.downloads.download({url,filename:'izgith-host-config.json',saveAs:true,conflictAction:'overwrite'});}finally{setTimeout(()=>URL.revokeObjectURL(url),60000);}});
  const diagnose=document.createElement('button');diagnose.className='btn ghost';diagnose.textContent='Verificar host/Git';
  diagnose.onclick=run(async()=>{if(busy)return;busy=true;try{await publisher.open();const result=await publisher.call('git_diagnostics',{},60000);const t=result.tools;upper.querySelector('#upperSelection').textContent=`Host conectado.\nGit: ${t.git?'OK':'não encontrado'}\nGit LFS: ${t.lfs?'OK':'não encontrado'}\nGitHub CLI: ${t.github_cli?'OK':'não encontrado'}\nLogin no GitHub CLI: ${t.github_cli_authenticated?'OK':'não confirmado; outro autenticador Git pode estar configurado'}\nPermissão de escrita: será verificada no destino durante o envio.`;}finally{busy=false;}});
  upper.querySelector('.module-actions').append(setup,diagnose);
  send.onclick=run(async()=>{if(busy)return;const repo=upper.querySelector('#upperRepo').value.trim();if(!/^https:\/\/github\.com\/[A-Za-z0-9-]+\/[A-Za-z0-9_.-]+\/?$/.test(repo))throw new Error('Informe uma URL válida de repositório GitHub.');busy=true;send.disabled=true;try{const r=await publisher.call('publish_send',{repository:repo});if(r.cancelled){send.disabled=false;return;}if(!r.ok||!r.commit)throw new Error('O commit remoto não foi confirmado.');ui.success(r.unchanged?'O conteúdo já está publicado, sem alterações.':'O conteúdo foi publicado com sucesso!');upper.querySelector('#upperSelection').textContent=`Commit confirmado: ${r.commit}\n${r.repository}/tree/${r.branch}`;}catch(e){send.disabled=false;throw e;}finally{busy=false;}});
  const body=document.getElementById('conversationUrl').parentElement;
  const toggle=document.createElement('button');toggle.className='btn';toggle.textContent='Ativar FORSE-SINC';body.append(toggle);
  const note=document.createElement('p');note.className='module-note';note.textContent='FORSE-SINC: ChatGPT, conversa exata, revisão e confirmação antes de cada publicação. Somente mensagens carregadas e visíveis; não recupera histórico oculto.';body.append(note);
  let config={enabled:false};
  chrome.storage.local.get({forseConfig:{enabled:false}}).then(s=>{config=s.forseConfig;if(config.conversation)document.getElementById('conversationUrl').value=config.conversation;if(config.repository)document.getElementById('repositoryUrl').value=config.repository;toggle.textContent=config.enabled?'Desativar FORSE-SINC':'Ativar FORSE-SINC';});
  toggle.onclick=run(async()=>{
    if(config.enabled){config={...config,enabled:false};await chrome.storage.local.set({forseConfig:config});toggle.textContent='Ativar FORSE-SINC';return;}
    const u=new URL(document.getElementById('conversationUrl').value.trim()),repo=document.getElementById('repositoryUrl').value.trim();
    if(u.origin!=='https://chatgpt.com'||!/^\/(c|gg)\/[a-zA-Z0-9-]+\/?$/.test(u.pathname)||u.search||u.hash||u.username||u.password)throw new Error('Use o endereço HTTPS exato de uma conversa ChatGPT, sem parâmetros.');
    if(!/^https:\/\/github\.com\/[A-Za-z0-9-]+\/[A-Za-z0-9_.-]+\/?$/.test(repo))throw new Error('Informe o repositório GitHub de destino.');
    config={enabled:true,conversation:u.href.replace(/\/$/,''),repository:repo.replace(/\/$/,'')};await chrome.storage.local.set({forseConfig:config});toggle.textContent='Desativar FORSE-SINC';await chrome.tabs.create({url:config.conversation});
  });
  document.querySelector('#tools .badge').textContent='8 módulos';
  document.querySelector('#tools .section-head p').textContent='Ferramentas locais e publicação confirmada com Git/LFS.';
  const originalInfo=body.querySelector('.info-icon');originalInfo.title=note.textContent;originalInfo.setAttribute('aria-label',note.textContent);
  const result=document.getElementById('hostResult');new MutationObserver(()=>{if(/^(Falha|URL inválida|Repositório deve)/.test(result.textContent))ui.error(result.textContent);}).observe(result,{childList:true,subtree:true,characterData:true});
  addEventListener('pagehide',()=>publisher.close());
})();
