(function () {
  'use strict';
  var BUTTON_ID='izgith-conv-d-export', MENU_ID='izgith-conv-d-menu';
  var PROVIDERS=[
    {name:'ChatGPT',host:/(^|\.)chatgpt\.com$/i,selectors:['[data-message-author-role]']},
    {name:'Claude',host:/(^|\.)claude\.ai$/i,selectors:['[data-testid="user-message"]','[data-testid="assistant-message"]']},
    {name:'Gemini',host:/(^|\.)gemini\.google\.com$/i,selectors:['user-query','model-response','message-content']},
    {name:'Copilot',host:/(^|\.)copilot\.microsoft\.com$/i,selectors:['[data-message-author-role]','[data-content]']},
    {name:'Perplexity',host:/(^|\.)perplexity\.ai$/i,selectors:['[data-testid="conversation-turn"]','[data-message-author-role]']},
    {name:'Grok',host:/(^|\.)grok\.com$/i,selectors:['[data-testid="message"]','[data-message-author-role]']},
    {name:'DeepSeek',host:/(^|\.)chat\.deepseek\.com$/i,selectors:['[class*="message"]']},
    {name:'Poe',host:/(^|\.)poe\.com$/i,selectors:['[data-message-id]']},
    {name:'Le Chat',host:/(^|\.)chat\.mistral\.ai$/i,selectors:['[data-message-author-role]','[class*="message"]']},
    {name:'You.com',host:/(^|\.)you\.com$/i,selectors:['[data-testid*="message"]','[data-message-author-role]']}
  ];
  function clean(v){return String(v||'').replace(/\u00a0/g,' ').trim();}
  function safe(v){var s=clean(v).replace(/[\\/:*?"<>|]+/g,'_').slice(0,90);return s||'conversa-ai';}
  function provider(){for(var i=0;i<PROVIDERS.length;i++)if(PROVIDERS[i].host.test(location.hostname))return PROVIDERS[i];return {name:location.hostname,selectors:['[data-message-author-role]','article','main [role="article"]']};}
  var currentProvider=provider();
  function nodes(){
    var out=[],seen=[];
    currentProvider.selectors.forEach(function(sel){Array.prototype.forEach.call(document.querySelectorAll(sel),function(n){if(clean(n.innerText)&&seen.indexOf(n)<0){seen.push(n);out.push(n);}});});
    out.sort(function(a,b){return a.compareDocumentPosition(b)&Node.DOCUMENT_POSITION_FOLLOWING?-1:1;});
    return out;
  }
  function attr(n,names){for(var i=0;i<names.length;i++){var v=n.getAttribute(names[i]);if(v)return v;}return '';}
  function role(n){var r=(n.getAttribute('data-message-author-role')||'').toLowerCase();if(r)return r;if(n.matches&&n.matches('[data-testid="user-message"]'))return'user';if(n.matches&&n.matches('[data-testid="assistant-message"]'))return'assistant';var s=attr(n,['data-sender','data-author','aria-label']).toLowerCase();if(s.indexOf('user')>=0||s.indexOf('you')>=0||s.indexOf('usuario')>=0)return'user';if(s.indexOf('assistant')>=0||s.indexOf('model')>=0||s.indexOf('ia')>=0)return'assistant';return'unknown';}
  function actorId(n){return attr(n,['data-user-id','data-author-id','data-sender-id','data-message-author-id']);}
  function actor(r){return r==='user'?'Você':r==='assistant'?'IA['+currentProvider.name+']':'Participante';}
  function readVisible(store){nodes().forEach(function(n){var text=clean(n.innerText);if(!text)return;var r=role(n),id=actorId(n),key=r+'|'+text;if(!store[key])store[key]={role:r,actor:actor(r),actorId:id||null,text:text};});}
  function scroller(){var best=null,bestArea=0;Array.prototype.forEach.call(document.querySelectorAll('body *'),function(e){if(e.scrollHeight>e.clientHeight+300){var r=e.getBoundingClientRect(),a=r.width*r.height;if(a>bestArea){best=e;bestArea=a;}}});return best||document.scrollingElement||document.documentElement;}
  function wait(ms){return new Promise(function(r){setTimeout(r,ms);});}
  async function collectAll(){
    var store={},s=scroller(),old=s.scrollTop;
    s.scrollTop=0;await wait(250);readVisible(store);
    var stable=0,last=-1;
    for(var i=0;i<100;i++){
      readVisible(store);var before=Object.keys(store).length,max=Math.max(0,s.scrollHeight-s.clientHeight);s.scrollTop=Math.min(max,s.scrollTop+Math.max(300,Math.floor(s.clientHeight*.82)));await wait(180);readVisible(store);var after=Object.keys(store).length;
      if(s.scrollTop>=max){if(after===last)stable++;else stable=0;last=after;if(stable>=4)break;}
      else if(after===before)stable++;else stable=0;
      if(stable>=8)break;
    }
    s.scrollTop=old;var messages=Object.keys(store).map(function(k){return store[k];});messages.forEach(function(m,i){m.index=i+1;});
    return {schema:'izgith.conv-d.v3',provider:currentProvider.name,host:location.hostname,title:clean((document.querySelector('h1')||{}).innerText||document.title),url:location.href,exportedAt:new Date().toISOString(),messageCount:messages.length,messages:messages};
  }
  function rounds(d){var out=[],cur=null;d.messages.forEach(function(m){if(m.role==='user'||!cur){cur={number:out.length+1,messages:[]};out.push(cur);}cur.messages.push(m);});return out;}
  function esc(v){return String(v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');}
  function md(d){return '# '+(d.title||'Conversa AI')+'\n\n- Provedor: '+d.provider+'\n- URL: '+d.url+'\n- Exportado: '+d.exportedAt+'\n- Mensagens: '+d.messageCount+'\n\n'+d.messages.map(function(m){return '## '+m.index+'. '+m.actor+(m.actorId?' (id: '+m.actorId+')':'')+'\n\n'+m.text;}).join('\n\n---\n\n')+'\n';}
  function txt(d){return d.messages.map(function(m){return '['+m.index+'] '+m.actor+(m.actorId?' [id='+m.actorId+']':'')+'\n'+m.text;}).join('\n\n'+'='.repeat(72)+'\n\n')+'\n';}
  function html(d){return '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>'+esc(d.title)+'</title></head><body><h1>'+esc(d.title)+'</h1><p>Provedor: '+esc(d.provider)+' | Mensagens: '+d.messageCount+'</p>'+d.messages.map(function(m){return '<article><h2>'+m.index+'. '+esc(m.actor)+(m.actorId?' [id='+esc(m.actorId)+']':'')+'</h2><pre>'+esc(m.text)+'</pre></article>';}).join('')+'</body></html>';}
  function pdf(d){function p(v){return String(v).replace(/\\/g,'\\\\').replace(/\(/g,'\\(').replace(/\)/g,'\\)');}var lines=[d.title||'Conversa AI','Provedor: '+d.provider,'URL: '+d.url,'Exportado: '+d.exportedAt,'Mensagens: '+d.messageCount,''];d.messages.forEach(function(m){lines.push(m.index+'. '+m.actor+(m.actorId?' [id='+m.actorId+']':''));String(m.text).split(/\r?\n/).forEach(function(line){while(line.length>88){lines.push(line.slice(0,88));line=line.slice(88);}lines.push(line||' ');});lines.push('');});var pages=[];for(var i=0;i<lines.length;i+=48)pages.push(lines.slice(i,i+48));var objs=['<< /Type /Catalog /Pages 2 0 R >>','<< /Type /Pages /Kids [] /Count 0 >>','<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'],kids=[];pages.forEach(function(pg,idx){var pn=4+idx*2,cn=pn+1,b='BT\n/F1 9 Tf\n12 TL\n50 750 Td\n';pg.forEach(function(line){b+='('+p(line)+') Tj\nT*\n';});b+='ET';objs.push('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 3 0 R >> >> /Contents '+cn+' 0 R >>');objs.push('<< /Length '+b.length+' >>\nstream\n'+b+'\nendstream');kids.push(pn+' 0 R');});objs[1]='<< /Type /Pages /Kids ['+kids.join(' ')+'] /Count '+pages.length+' >>';var out='%PDF-1.4\n',off=[0];objs.forEach(function(o,i){off.push(out.length);out+=(i+1)+' 0 obj\n'+o+'\nendobj\n';});var x=out.length;out+='xref\n0 '+(objs.length+1)+'\n0000000000 65535 f \n';for(var j=1;j<off.length;j++)out+=String(off[j]).padStart(10,'0')+' 00000 n \n';out+='trailer\n<< /Size '+(objs.length+1)+' /Root 1 0 R >>\nstartxref\n'+x+'\n%%EOF';return new TextEncoder().encode(out);}
  function xls(d){var rows=d.messages.map(function(m){return '<Row><Cell><Data ss:Type="Number">'+m.index+'</Data></Cell><Cell><Data ss:Type="String">'+esc(m.actor)+'</Data></Cell><Cell><Data ss:Type="String">'+esc(m.actorId||'')+'</Data></Cell><Cell><Data ss:Type="String">'+esc(m.text)+'</Data></Cell></Row>';}).join('');return '<?xml version="1.0" encoding="UTF-8"?><Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"><Worksheet ss:Name="Conversa"><Table><Row><Cell><Data ss:Type="String">Indice</Data></Cell><Cell><Data ss:Type="String">Participante</Data></Cell><Cell><Data ss:Type="String">ID</Data></Cell><Cell><Data ss:Type="String">Mensagem</Data></Cell></Row>'+rows+'</Table></Worksheet></Workbook>';}
  function bytes(v){if(v instanceof Uint8Array)return v;return new TextEncoder().encode(v);}
  function b64(u){var s='';for(var i=0;i<u.length;i+=0x8000)s+=String.fromCharCode.apply(null,u.subarray(i,i+0x8000));return btoa(s);}
  function save(name,data,mime){return new Promise(function(resolve,reject){chrome.runtime.sendMessage({type:'SAVE_FILE',filename:name,base64:b64(bytes(data)),mime:mime},function(r){if(chrome.runtime.lastError)reject(new Error(chrome.runtime.lastError.message));else if(!r||!r.ok)reject(new Error(r&&r.error||'Falha ao abrir o diálogo de salvamento.'));else resolve(r);});});}
  function exportData(d,f){var base=safe(d.title),ext=f==='doc'?'doc':f,mime=f==='pdf'?'application/pdf':f==='doc'?'application/msword':f==='txt'?'text/plain;charset=utf-8':f==='md'?'text/markdown;charset=utf-8':f==='json'?'application/json;charset=utf-8':'application/vnd.ms-excel;charset=utf-8',data=f==='pdf'?pdf(d):f==='doc'?html(d):f==='txt'?txt(d):f==='md'?md(d):f==='json'?JSON.stringify(d,null,2):xls(d);return save(base+'.'+ext,data,mime);}
  function closeMenu(){var m=document.getElementById(MENU_ID);if(m)m.remove();}
  function showMenu(){
    closeMenu();var m=document.createElement('div');m.id=MENU_ID;m.innerHTML='<div class="izgith-cd-title">CONV-D · Exportar conversa</div><div class="izgith-cd-info">Escolha o escopo. "Tudo" percorre a conversa inteira; "Rodada" permite selecionar uma rodada após a leitura.</div><label>Escopo<select id="izgith-cd-scope"><option value="all">Tudo — início até o final</option><option value="round">Rodada — escolher depois de ler</option></select></label><label>Formato<select id="izgith-cd-format"><option value="pdf">📄 PDF</option><option value="doc">📝 Word .doc</option><option value="txt">📃 TXT</option><option value="md">📘 Markdown .md</option><option value="json">🧩 JSON estruturado</option><option value="xls">📊 Excel .xls</option></select></label><button type="button" id="izgith-cd-go">Ler conversa</button><button type="button" class="izgith-cd-cancel">Cancelar</button>';document.body.appendChild(m);
    m.addEventListener('click',async function(e){if(e.target.id!=='izgith-cd-go'){if(e.target.classList.contains('izgith-cd-cancel'))closeMenu();return;}var scope=m.querySelector('#izgith-cd-scope').value,format=m.querySelector('#izgith-cd-format').value,b=e.target;try{b.disabled=true;b.textContent='Lendo do início ao fim…';var d=await collectAll();if(!d.messages.length)throw new Error('Nenhuma mensagem detectada em '+d.provider+'.');if(scope==='round'){var rs=rounds(d),select=document.createElement('select');select.id='izgith-cd-round';select.innerHTML=rs.map(function(r){return '<option value="'+r.number+'">Rodada '+r.number+' — '+r.messages.length+' mensagem(ns)</option>';}).join('');var box=document.createElement('div');box.className='izgith-cd-round-box';box.innerHTML='<strong>Escolha a rodada</strong>';box.appendChild(select);m.insertBefore(box,b);b.textContent='Baixar rodada';b.disabled=false;b.onclick=async function(){var n=Number(select.value),chosen=rs[n-1];if(!chosen)return;var out=Object.assign({},d,{scope:'round',round:n,messageCount:chosen.messages.length,messages:chosen.messages});b.disabled=true;b.textContent='Abrindo local para salvar…';await exportData(out,format);closeMenu();};}else{d.scope='all';b.textContent='Abrindo local para salvar…';await exportData(d,format);closeMenu();}}catch(err){console.error('[IZGITH CONV-D]',err);b.disabled=false;b.textContent='Tentar novamente';var info=m.querySelector('.izgith-cd-info');if(info)info.textContent='Erro: '+err.message;}});
  }
  function mount(){if(!document.body||document.getElementById(BUTTON_ID))return;var b=document.createElement('button');b.id=BUTTON_ID;b.type='button';b.textContent='Baixar Conversa';b.title='Exportar a conversa inteira ou uma rodada';b.addEventListener('click',showMenu);document.body.appendChild(b);}
  mount();new MutationObserver(function(){mount();}).observe(document.documentElement,{childList:true,subtree:true});
})();
