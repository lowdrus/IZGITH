(function () {
  'use strict';

  var BUTTON_ID = 'izgith-conv-d-export';
  var MENU_ID = 'izgith-conv-d-menu';
  var PROVIDERS = [
    {name:'ChatGPT', host:/(^|\.)chatgpt\.com$/i, selectors:['[data-message-author-role]']},
    {name:'Claude', host:/(^|\.)claude\.ai$/i, selectors:['[data-testid="user-message"]','[data-testid="assistant-message"]']},
    {name:'Gemini', host:/(^|\.)gemini\.google\.com$/i, selectors:['user-query','model-response','message-content']},
    {name:'Copilot', host:/(^|\.)copilot\.microsoft\.com$/i, selectors:['[data-message-author-role]','[data-content]']},
    {name:'Perplexity', host:/(^|\.)perplexity\.ai$/i, selectors:['[data-testid="conversation-turn"]','[data-message-author-role]']},
    {name:'Grok', host:/(^|\.)grok\.com$/i, selectors:['[data-testid="message"]','[data-message-author-role]']},
    {name:'DeepSeek', host:/(^|\.)chat\.deepseek\.com$/i, selectors:['[class*="message"]']},
    {name:'Poe', host:/(^|\.)poe\.com$/i, selectors:['[data-message-id]']},
    {name:'Le Chat', host:/(^|\.)chat\.mistral\.ai$/i, selectors:['[data-message-author-role]','[class*="message"]']},
    {name:'You.com', host:/(^|\.)you\.com$/i, selectors:['[data-testid*="message"]','[data-message-author-role]']}
  ];

  function clean(v) { return String(v || '').replace(/\u00a0/g, ' ').trim(); }
  function safe(v) { var s=clean(v).replace(/[\\/:*?"<>|]+/g,'_').slice(0,90); return s || 'conversa-ai'; }
  function getProvider() {
    for (var i=0;i<PROVIDERS.length;i++) if (PROVIDERS[i].host.test(location.hostname)) return PROVIDERS[i];
    return {name:location.hostname,selectors:['[data-message-author-role]','article','main [role="article"]']};
  }
  var currentProvider = getProvider();

  function getNodes() {
    for (var i=0;i<currentProvider.selectors.length;i++) {
      var list=Array.prototype.slice.call(document.querySelectorAll(currentProvider.selectors[i]));
      list=list.filter(function(n){return clean(n.innerText);});
      if(list.length>=2) return list;
    }
    return [];
  }

  function attr(n,names){
    for(var i=0;i<names.length;i++){var v=n.getAttribute(names[i]);if(v)return v;}
    return '';
  }
  function getRole(n){
    var r=(n.getAttribute('data-message-author-role')||'').toLowerCase();
    if(r)return r;
    if(n.matches && n.matches('[data-testid="user-message"]'))return 'user';
    if(n.matches && n.matches('[data-testid="assistant-message"]'))return 'assistant';
    var sender=attr(n,['data-sender','data-author','aria-label']).toLowerCase();
    if(sender){if(sender.indexOf('user')>=0||sender.indexOf('you')>=0||sender.indexOf('usuario')>=0)return 'user';if(sender.indexOf('assistant')>=0||sender.indexOf('assistant')>=0||sender.indexOf('model')>=0||sender.indexOf('ia')>=0)return 'assistant';}
    return 'unknown';
  }
  function getActorId(n){return attr(n,['data-user-id','data-author-id','data-sender-id','data-message-author-id','data-author']);}
  function actorLabel(role){return role==='user'?'Você':role==='assistant'?'IA['+currentProvider.name+']':'Participante';}

  function collect(){
    var nodes=getNodes(),seen={},messages=[];
    nodes.forEach(function(n){
      var text=clean(n.innerText);if(!text)return;
      var role=getRole(n), id=getActorId(n), key=role+'|'+text;
      if(seen[key])return;seen[key]=true;
      messages.push({index:messages.length+1,role:role,actor:actorLabel(role),actorId:id||null,text:text});
    });
    return {schema:'izgith.conv-d.v2',provider:currentProvider.name,host:location.hostname,title:clean((document.querySelector('h1')||{}).innerText||document.title),url:location.href,exportedAt:new Date().toISOString(),messageCount:messages.length,messages:messages};
  }
  function wait(ms){return new Promise(function(r){setTimeout(r,ms);});}
  async function collectAll(){
    var oldY=window.scrollY,last=-1,stable=0;
    for(var i=0;i<30;i++){
      var count=getNodes().length;if(count===last)stable++;else stable=0;last=count;
      window.scrollTo(0,document.body.scrollHeight);await wait(150);if(stable>=3)break;
    }
    window.scrollTo(0,oldY);return collect();
  }
  function esc(v){return String(v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');}
  function markdown(d){return '# '+(d.title||'Conversa AI')+'\n\n- Provedor: '+d.provider+'\n- URL: '+d.url+'\n- Exportado: '+d.exportedAt+'\n- Mensagens: '+d.messageCount+'\n\n'+d.messages.map(function(m){return '## '+m.index+'. '+m.actor+(m.actorId?' (id: '+m.actorId+')':'')+'\n\n'+m.text;}).join('\n\n---\n\n')+'\n';}
  function text(d){return d.messages.map(function(m){return '['+m.index+'] '+m.actor+(m.actorId?' [id='+m.actorId+']':'')+'\n'+m.text;}).join('\n\n'+'='.repeat(72)+'\n\n')+'\n';}
  function html(d){return '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>'+esc(d.title)+'</title></head><body><h1>'+esc(d.title)+'</h1><p>Provedor: '+esc(d.provider)+' | Mensagens: '+d.messageCount+'</p>'+d.messages.map(function(m){return '<article><h2>'+m.index+'. '+esc(m.actor)+(m.actorId?' [id='+esc(m.actorId)+']':'')+'</h2><pre>'+esc(m.text)+'</pre></article>';}).join('')+'</body></html>';}
  function pdf(d){
    function p(v){return String(v).replace(/\\/g,'\\\\').replace(/\(/g,'\\(').replace(/\)/g,'\\)');}
    var lines=[d.title||'Conversa AI','Provedor: '+d.provider,'URL: '+d.url,'Exportado: '+d.exportedAt,'Mensagens: '+d.messageCount,''];
    d.messages.forEach(function(m){lines.push(m.index+'. '+m.actor+(m.actorId?' [id='+m.actorId+']':''));String(m.text).split(/\r?\n/).forEach(function(line){while(line.length>88){lines.push(line.slice(0,88));line=line.slice(88);}lines.push(line||' ');});lines.push('');});
    var pages=[];for(var i=0;i<lines.length;i+=48)pages.push(lines.slice(i,i+48));
    var objects=['<< /Type /Catalog /Pages 2 0 R >>','<< /Type /Pages /Kids [] /Count 0 >>','<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'];var kids=[];
    pages.forEach(function(page,index){var pageNo=4+index*2,contentNo=pageNo+1,body='BT\n/F1 9 Tf\n12 TL\n50 750 Td\n';page.forEach(function(line){body+='('+p(line)+') Tj\nT*\n';});body+='ET';objects.push('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 3 0 R >> >> /Contents '+contentNo+' 0 R >>');objects.push('<< /Length '+body.length+' >>\nstream\n'+body+'\nendstream');kids.push(pageNo+' 0 R');});
    objects[1]='<< /Type /Pages /Kids ['+kids.join(' ')+'] /Count '+pages.length+' >>';var out='%PDF-1.4\n',offsets=[0];objects.forEach(function(o,i){offsets.push(out.length);out+=(i+1)+' 0 obj\n'+o+'\nendobj\n';});var xref=out.length;out+='xref\n0 '+(objects.length+1)+'\n0000000000 65535 f \n';for(var j=1;j<offsets.length;j++)out+=String(offsets[j]).padStart(10,'0')+' 00000 n \n';out+='trailer\n<< /Size '+(objects.length+1)+' /Root 1 0 R >>\nstartxref\n'+xref+'\n%%EOF';return new TextEncoder().encode(out);
  }
  function xls(d){
    var rows=d.messages.map(function(m){return '<Row><Cell><Data ss:Type="Number">'+m.index+'</Data></Cell><Cell><Data ss:Type="String">'+esc(m.actor)+'</Data></Cell><Cell><Data ss:Type="String">'+esc(m.actorId||'')+'</Data></Cell><Cell><Data ss:Type="String">'+esc(m.text)+'</Data></Cell></Row>';}).join('');
    return '<?xml version="1.0" encoding="UTF-8"?><Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"><Worksheet ss:Name="Conversa"><Table><Row><Cell><Data ss:Type="String">Indice</Data></Cell><Cell><Data ss:Type="String">Participante</Data></Cell><Cell><Data ss:Type="String">ID</Data></Cell><Cell><Data ss:Type="String">Mensagem</Data></Cell></Row>'+rows+'</Table></Worksheet></Workbook>';
  }
  function download(name,data,type){var url=URL.createObjectURL(new Blob([data],{type:type})),a=document.createElement('a');a.href=url;a.download=name;document.body.appendChild(a);a.click();a.remove();setTimeout(function(){URL.revokeObjectURL(url);},1500);}
  function doExport(d,format){var base=safe(d.title);if(format==='pdf')download(base+'.pdf',pdf(d),'application/pdf');else if(format==='doc')download(base+'.doc',html(d),'application/msword;charset=utf-8');else if(format==='txt')download(base+'.txt',text(d),'text/plain;charset=utf-8');else if(format==='md')download(base+'.md',markdown(d),'text/markdown;charset=utf-8');else if(format==='json')download(base+'.json',JSON.stringify(d,null,2),'application/json;charset=utf-8');else if(format==='xls')download(base+'.xls',xls(d),'application/vnd.ms-excel;charset=utf-8');}

  function closeMenu(){var m=document.getElementById(MENU_ID);if(m)m.remove();}
  function showMenu(){
    closeMenu();var m=document.createElement('div');m.id=MENU_ID;m.setAttribute('role','dialog');m.innerHTML='<div class="izgith-cd-title">Escolha o formato</div><div class="izgith-cd-info">A conversa não será baixada até você escolher.</div><div class="izgith-cd-grid">'+[['pdf','📄 PDF'],['doc','📝 Word .doc'],['txt','📃 TXT'],['md','📘 Markdown .md'],['json','🧩 JSON estruturado'],['xls','📊 Excel .xls']].map(function(x){return '<button type="button" data-format="'+x[0]+'">'+x[1]+'</button>';}).join('')+'</div><button type="button" class="izgith-cd-cancel">Cancelar</button>';document.body.appendChild(m);
    m.addEventListener('click',async function(e){var f=e.target.getAttribute('data-format');if(!f){if(e.target.classList.contains('izgith-cd-cancel'))closeMenu();return;}var b=document.getElementById(BUTTON_ID);try{closeMenu();if(b){b.disabled=true;b.textContent='Lendo conversa…';}var d=await collectAll();if(!d.messages.length)throw new Error('Nenhuma mensagem detectada em '+d.provider+'.');doExport(d,f);if(b)b.textContent='Download concluído ✓';}catch(err){console.error('[IZGITH CONV-D]',err);if(b)b.textContent='Erro: '+err.message;}finally{setTimeout(function(){if(b){b.disabled=false;b.textContent='Baixar Conversa';}},2500);}});
  }
  function mount(){if(!document.body||document.getElementById(BUTTON_ID))return;var b=document.createElement('button');b.id=BUTTON_ID;b.type='button';b.textContent='Baixar Conversa';b.title='Exportar esta conversa';b.addEventListener('click',showMenu);document.body.appendChild(b);}
  mount();
  new MutationObserver(function(){mount();}).observe(document.documentElement,{childList:true,subtree:true});
})();
