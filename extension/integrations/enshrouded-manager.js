(() => {
  const KEY='izgith.enshrouded.profiles';
  const load=async()=>{const s=await chrome.storage.local.get({[KEY]:[]});return Array.isArray(s[KEY])?s[KEY]:[]};
  const save=async p=>chrome.storage.local.set({[KEY]:p});
  window.IZGITHEnshrouded={
    async list(){return load()},
    async upsert(profile){
      const p=await load();
      const item={id:profile.id||crypto.randomUUID(),name:String(profile.name||'Servidor Enshrouded').trim(),host:String(profile.host||'').trim(),port:Number(profile.port)||15636,notes:String(profile.notes||'').trim(),updatedAt:new Date().toISOString()};
      const i=p.findIndex(x=>x.id===item.id); if(i>=0)p[i]=item; else p.unshift(item); await save(p); return item;
    },
    async remove(id){await save((await load()).filter(x=>x.id!==id))},
    validate(profile){
      const host=String(profile.host||'').trim(); const port=Number(profile.port);
      return {ok:/^[a-zA-Z0-9.-]+$/.test(host)&&host.length>0&&Number.isInteger(port)&&port>=1&&port<=65535,host,port};
    },
    address(profile){return `${profile.host}:${profile.port||15636}`}
  };
})();
