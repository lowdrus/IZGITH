(() => {
  let config={enabled:false}, button=null, busy=false;
  const canonical=()=>location.origin+location.pathname.replace(/\/$/,'');
  async function refresh(){
    config=(await chrome.storage.local.get({forseConfig:{enabled:false}})).forseConfig;
    if(!config.enabled||config.conversation!==canonical()){button?.remove();button=null;return;}
    if(button)return;
    button=document.createElement('button');button.textContent='FORSE-SINC';button.title=`${config.conversation}\nDestino: ${config.repository}\nClique para revisar antes de publicar.`;
    Object.assign(button.style,{position:'fixed',bottom:'92px',right:'24px',zIndex:'2147483646',background:'#10251b',color:'#a5ffc4',border:'1px solid #89ffb1',borderRadius:'12px',padding:'14px',cursor:'pointer'});
    button.onclick=async event=>{
      if(!event.isTrusted||busy)return;busy=true;button.disabled=true;
      try{
        const messages=[...document.querySelectorAll('[data-message-author-role]')].filter(el=>['user','assistant'].includes(el.dataset.messageAuthorRole)&&!el.closest('[hidden],[aria-hidden="true"]')&&el.getClientRects().length).map(el=>({role:el.dataset.messageAuthorRole,text:el.innerText})).filter(x=>x.text.trim());
        if(!messages.length)throw new Error('Nenhuma mensagem carregada foi encontrada. Abra a conversa e aguarde.');
        const payload={schema:'izgith.forse-sinc.v1',conversation:canonical(),scope:'mensagens carregadas e visíveis no DOM; não inclui histórico oculto',messages};
        if(new TextEncoder().encode(JSON.stringify(payload)).length>4*1024*1024)throw new Error('Conversa maior que 4 MiB; exporte localmente pelo CONV-D.');
        const r=await chrome.runtime.sendMessage({type:'FORSE_PREVIEW',payload});
        if(!r?.ok)throw new Error(r?.error||'Não foi possível abrir a revisão.');
      }catch(e){IZGITH_UI.error(e);}finally{busy=false;if(button)button.disabled=false;}
    };
    document.body.append(button);
  }
  chrome.runtime.onMessage.addListener((m,sender)=>{if(sender.id===chrome.runtime.id&&m.type==='FORSE_PUBLISHED'&&m.conversation===canonical())IZGITH_UI.success('O conteúdo foi publicado no GitHub!');});
  chrome.storage.onChanged.addListener((changes,area)=>{if(area==='local'&&changes.forseConfig)refresh().catch(e=>IZGITH_UI.error(e));});
  let last=location.href;setInterval(()=>{if(last!==location.href){last=location.href;refresh().catch(e=>IZGITH_UI.error(e));}},1000);
  refresh().catch(e=>IZGITH_UI.error(e));
})();
