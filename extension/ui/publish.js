(() => {
  const id=location.hash.slice(1),client=new NativePublisher();let pending,busy=false;
  const button=document.getElementById('publish'),consent=document.getElementById('consent');
  button.prepend(IZGITH_UI.icon('send'));
  chrome.storage.session.get(id).then(s=>{pending=s[id];if(!pending?.forse||Date.now()-pending.created>=600000)throw new Error('Revisão ausente ou expirada. Volte à conversa e clique em FORSE-SINC.');document.getElementById('destination').textContent='Destino: '+pending.repository;document.getElementById('forsePreview').textContent=JSON.stringify(pending.payload,null,2);}).catch(e=>IZGITH_UI.error(e));
  consent.onchange=()=>{button.disabled=!consent.checked||!pending||busy;};
  document.getElementById('cancel').onclick=async()=>{if(busy)return;await chrome.storage.session.remove(id);client.close();window.close();};
  button.onclick=async()=>{
    if(!consent.checked||!pending||busy)return;busy=true;button.disabled=true;
    try{
      await client.open();
      const config=(await chrome.storage.local.get('forseConfig')).forseConfig;
      if(!config?.enabled||config.repository!==pending.repository||config.conversation!==pending.payload.conversation)throw new Error('Configuração mudou ou o módulo foi desativado. Crie uma nova revisão.');
      await client.call('publish_conversation',{payload:pending.payload});
      document.getElementById('publishStatus').textContent='Preparando Git/LFS. Confirme o destino na janela do host.';
      const r=await client.call('publish_send',{repository:pending.repository});
      if(r.cancelled){document.getElementById('publishStatus').textContent='Publicação cancelada.';return;}
      if(!r.ok||!r.commit)throw new Error('Commit remoto não confirmado.');
      IZGITH_UI.success('O conteúdo foi publicado no GitHub!');document.getElementById('publishStatus').textContent='Commit confirmado: '+r.commit;
      await chrome.storage.session.remove(id);
      try{await chrome.tabs.sendMessage(pending.tabId,{type:'FORSE_PUBLISHED',conversation:pending.payload.conversation});}catch(_){/* conversa pode ter sido fechada; commit já confirmado */}
      pending=null;client.close();
    }catch(e){IZGITH_UI.error(e);document.getElementById('publishStatus').textContent='Envio não confirmado. Confira o GitHub antes de repetir.';}finally{busy=false;button.disabled=!pending||!consent.checked;}
  };
  addEventListener('pagehide',()=>{client.close();if(!busy)chrome.storage.session.remove(id);});
})();
