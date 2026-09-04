(() => {
  const $ = id => document.getElementById(id);
  const result = text => { $('result').textContent = text; };
  const profile = () => ({name:$('serverName').value,host:$('serverHost').value,port:$('serverPort').value,notes:$('serverNotes').value});
  const download = (content, filename, mime) => { const u=URL.createObjectURL(new Blob([content],{type:mime})); const a=document.createElement('a'); a.href=u; a.download=filename; a.click(); setTimeout(()=>URL.revokeObjectURL(u),1000); };

  function installMaximizeControl() {
    const head = document.querySelector('.head');
    const title = document.querySelector('.title');
    if (!head || !title || document.getElementById('enshroudedOpenScreen')) return;
    const button = document.createElement('button');
    button.id = 'enshroudedOpenScreen';
    button.type = 'button';
    button.className = 'btn';
    button.title = 'Abrir ENSHROUDED MANAGER em nova tela';
    button.setAttribute('aria-label', 'Abrir ENSHROUDED MANAGER em nova tela');
    button.style.cssText = 'display:inline-grid;place-items:center;width:40px;height:36px;padding:0;margin-left:8px;vertical-align:middle;';
    button.innerHTML = '<svg viewBox="0 0 24 24" width="19" height="19" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 3h6v6"></path><path d="M10 14 21 3"></path><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path></svg>';
    title.appendChild(button);
    button.addEventListener('click', () => {
      const url = chrome.runtime.getURL('ui/enshrouded.html?fullscreen=1');
      window.open(url, '_blank', 'popup,width=1280,height=850,resizable=yes,scrollbars=yes');
    });
  }

  const actions=[['verify','Verificar'],['install','Preparar Instalação'],['start','Preparar Início'],['stop','Preparar Parada'],['backup','Backup'],['restore','Restaurar'],['prune','Retenção'],['mods','Mods'],['resources','Recursos'],['version','Versão']];
  actions.forEach(([action,label])=>{const b=document.createElement('button');b.className='btn';b.type='button';b.textContent=label;b.onclick=async()=>{const p=profile(),v=IZGITHEnshrouded.validate(p);if(!v.ok){result('Informe host e porta válidos.');return}try{const plan=await IZGITHEnshrouded.prepare(p,action);result(`ENSHROUDED MANAGER · ${label}\n${plan.steps.map(s=>`${s.order}. ${s.description}`).join('\n')}\n\nNenhum processo externo foi iniciado.`)}catch(e){result('Falha: '+e.message)}};$('actions').appendChild(b)});
  $('save').onclick=async()=>{try{const item=await IZGITHEnshrouded.upsert(profile());$('serverName').value=item.name;$('serverPort').value=item.port;result(`Perfil salvo: ${item.name} · ${IZGITHEnshrouded.address(item)}`)}catch(e){result('Falha: '+e.message)}};
  $('validate').onclick=()=>{const v=IZGITHEnshrouded.validate(profile());result(v.ok?`Endpoint válido: ${v.host}:${v.port}`:`Endpoint inválido: ${v.errors.join('; ')}`)};
  $('clear').onclick=()=>{['serverName','serverHost','serverNotes'].forEach(id=>$(id).value='');$('serverPort').value='15636';result('Formulário limpo.')};
  $('config').onclick=()=>{const p=profile(),v=IZGITHEnshrouded.validate(p);if(!v.ok){result('Informe host e porta válidos.');return}download(JSON.stringify(IZGITHEnshrouded.config(p),null,2),'enshrouded-server-config.json','application/json');result('Configuração gerada localmente.')};
  $('compose').onclick=()=>{const p=profile(),v=IZGITHEnshrouded.validate(p);if(!v.ok){result('Informe host e porta válidos.');return}download(IZGITHEnshrouded.compose(p),'docker-compose.enshrouded.yml','text/yaml');result('Compose gerado localmente.')};
  $('plan').onclick=()=>{const p=profile(),v=IZGITHEnshrouded.validate(p);if(!v.ok){result('Informe host e porta válidos.');return}download(JSON.stringify(IZGITHEnshrouded.plan(p,'verify'),null,2),'enshrouded-manager-plan.json','application/json');result('Plano gerado localmente.')};

  installMaximizeControl();
})();
