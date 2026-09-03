(function () {
  'use strict';
  var BUTTON_ID = 'izgith-conv-d-export';
  var FORMATS = ['pdf', 'doc', 'txt', 'md', 'json', 'xls'];
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
  function provider() {
    for (var i=0;i<PROVIDERS.length;i++) if (PROVIDERS[i].host.test(location.hostname)) return PROVIDERS[i];
    return {name:location.hostname,selectors:['[data-message-author-role]','article','main [role="article"]']};
  }
  var currentProvider = provider();
  function clean(v) { return String(v || '').replace(/\u00a0/g,' ').trim(); }
  function safe(v) { var s=clean(v).replace(/[\\/:*?"<>|]+/g,'_').slice(0,90); return s || 'conversa-ai'; }
  function getNodes() {
    for (var i=0;i<currentProvider.selectors.length;i++) {
      var list=Array.prototype.slice.call(document.querySelectorAll(currentProvider.selectors[i]));
      list=list.filter(function (n) { return clean(n.innerText); });
      if (list.length>=2) return list;
    }
    return [];
  }
  function getRole(n) {
    var r=n.getAttribute('data-message-author-role');
    if (r) return r;
    if (n.matches && n.matches('[data-testid="user-message"]')) return 'user';
    if (n.matches && n.matches('[data-testid="assistant-message"]')) return 'assistant';
    var sender=(n.getAttribute('data-sender') || '').toLowerCase();
    if (sender) return sender.indexOf('user')>=0 ? 'user' : 'assistant';
    return 'unknown';
  }
  function collect() {
    var nodes=getNodes(), seen={}, messages=[];
    nodes.forEach(function (n) {
      var text=clean(n.innerText);
      if (!text || seen[text]) return;
      seen[text]=true;
      messages.push({index:messages.length+1,role:getRole(n),text:text});
    });
    return {schema:'izgith.conv-d.v1',provider:currentProvider.name,host:location.hostname,title:clean((document.querySelector('h1') || {}).innerText || document.title),url:location.href,exportedAt:new Date().toISOString(),messageCount:messages.length,messages:messages};
  }
  function wait(ms) { return new Promise(function (resolve) { setTimeout(resolve,ms); }); }
  async function collectAll() {
    var oldY=window.scrollY,last=-1,stable=0;
    for (var i=0;i<24;i++) {
      var count=getNodes().length;
      if (count===last) stable++; else stable=0;
      last=count;
      window.scrollTo(0,document.body.scrollHeight);
      await wait(130);
      if (stable>=2) break;
    }
    window.scrollTo(0,oldY);
    return collect();
  }
  function escapeHtml(v) { return String(v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
  function markdown(d) { return '# '+(d.title || 'Conversa AI')+'\n\n- Provedor: '+d.provider+'\n- URL: '+d.url+'\n- Exportado: '+d.exportedAt+'\n- Mensagens: '+d.messageCount+'\n\n'+d.messages.map(function(m){return '## '+m.index+'. '+m.role+'\n\n'+m.text;}).join('\n\n---\n\n')+'\n'; }
  function text(d) { return d.messages.map(function(m){return '['+m.index+'] '+m.role+'\n'+m.text;}).join('\n\n'+'='.repeat(72)+'\n\n')+'\n'; }
  function html(d) { return '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>'+escapeHtml(d.title)+'</title></head><body><h1>'+escapeHtml(d.title)+'</h1><p>Provedor: '+escapeHtml(d.provider)+' · '+d.messageCount+' mensagens</p>'+d.messages.map(function(m){return '<article><h2>'+m.index+'. '+escapeHtml(m.role)+'</h2><pre>'+escapeHtml(m.text)+'</pre></article>';}).join('')+'</body></html>'; }
  function pdf(d) {
    function p(v){return String(v).replace(/\\/g,'\\\\').replace(/\(/g,'\\(').replace(/\)/g,'\\)');}
    var lines=[d.title || 'Conversa AI','Provedor: '+d.provider,'URL: '+d.url,'Exportado: '+d.exportedAt,'Mensagens: '+d.messageCount,''];
    d.messages.forEach(function(m){ lines.push(m.index+'. '+m.role); String(m.text).split(/\r?\n/).forEach(function(line){while(line.length>90){lines.push(line.slice(0,90));line=line.slice(90);}lines.push(line || ' ');}); lines.push(''); });
    var pages=[]; for(var i=0;i<lines.length;i+=48) pages.push(lines.slice(i,i+48));
    var objects=['<< /Type /Catalog /Pages 2 0 R >>','<< /Type /Pages /Kids [] /Count 0 >>','<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'];
    var kids=[];
    pages.forEach(function(page,index){var pageNo=4+index*2,contentNo=pageNo+1;var body='BT\n/F1 9 Tf\n12 TL\n50 750 Td\n';page.forEach(function(line){body+='('+p(line)+') Tj\nT*\n';});body+='ET';objects.push('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 3 0 R >> >> /Contents '+contentNo+' 0 R >>');objects.push('<< /Length '+body.length+' >>\nstream\n'+body+'\nendstream');kids.push(pageNo+' 0 R');});
    objects[1]='<< /Type /Pages /Kids ['+kids.join(' ')+'] /Count '+pages.length+' >>';
    var out='%PDF-1.4\n',offsets=[0];objects.forEach(function(o,i){offsets.push(out.length);out+=(i+1)+' 0 obj\n'+o+'\nendobj\n';});var xref=out.length;out+='xref\n0 '+(objects.length+1)+'\n0000000000 65535 f \n';for(var j=1;j<offsets.length;j++)out+=String(offsets[j]).padStart(10,'0')+' 00000 n \n';out+='trailer\n<< /Size '+(objects.length+1)+' /Root 1 0 R >>\nstartxref\n'+xref+'\n%%EOF';return new TextEncoder().encode(out);
  }
  function download(name,data,type){var url=URL.createObjectURL(new Blob([data],{type:type}));var a=document.createElement('a');a.href=url;a.download=name;a.click();setTimeout(function(){URL.revokeObjectURL(url);},1500);}
  function exportAll(d){var base=safe(d.title);download(base+'.pdf',pdf(d),'application/pdf');download(base+'.doc',html(d),'application/msword;charset=utf-8');download(base+'.txt',text(d),'text/plain;charset=utf-8');download(base+'.md',markdown(d),'text/markdown;charset=utf-8');download(base+'.json',JSON.stringify(d,null,2),'application/json;charset=utf-8');download(base+'.xls','<?xml version="1.0"?><Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"><Worksheet ss:Name="Conversa"><Table><Row><Cell><Data ss:Type="String">Indice</Data></Cell><Cell><Data ss:Type="String">Papel</Data></Cell><Cell><Data ss:Type="String">Mensagem</Data></Cell></Row>'+d.messages.map(function(m){return '<Row><Cell><Data ss:Type="Number">'+m.index+'</Data></Cell><Cell><Data ss:Type="String">'+escapeHtml(m.role)+'</Data></Cell><Cell><Data ss:Type="String">'+escapeHtml(m.text)+'</Data></Cell></Row>';}).join('')+'</Table></Worksheet></Workbook>','application/vnd.ms-excel;charset=utf-8');}
  async function run(){var b=document.getElementById(BUTTON_ID);if(b){b.disabled=true;b.textContent='CONV-D: lendo conversa…';}try{var d=await collectAll();if(!d.messages.length)throw new Error('Nenhuma mensagem detectada em '+d.provider+'.');exportAll(d);if(b)b.textContent='CONV-D ✓ '+d.provider+' · '+d.messageCount;}catch(e){console.error('[IZGITH CONV-D]',e);if(b)b.textContent='CONV-D: '+e.message;}finally{setTimeout(function(){if(b){b.disabled=false;b.textContent='Baixar Conversa · CONV-D';}},3500);}}
  function mount(){if(document.getElementById(BUTTON_ID))return;var b=document.createElement('button');b.id=BUTTON_ID;b.type='button';b.textContent='Baixar Conversa · CONV-D';b.addEventListener('click',run);document.body.appendChild(b);}
  if (typeof chrome !== 'undefined' && chrome.runtime && chrome.runtime.onMessage) chrome.runtime.onMessage.addListener(function(m,_s,sendResponse){if(!m || m.type!=='CONV_D_EXPORT')return;run().then(function(){sendResponse({ok:true});},function(e){sendResponse({ok:false,error:String(e)});});return true;});
  mount();
  new MutationObserver(function(){mount();}).observe(document.documentElement,{childList:true,subtree:true});
})();
