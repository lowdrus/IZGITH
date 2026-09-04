/* Ícones Lucide, ISC — licença em assets/LUCIDE-LICENSE.txt. */
(() => {
  const paths = {
    info: '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/>',
    send: '<path d="m22 2-7 20-4-9-9-4Z"/><path d="M22 2 11 13"/>',
    'circle-check': '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>',
    bomb: '<circle cx="11" cy="13" r="9"/><path d="m19.5 9.5 1-1a2.1 2.1 0 0 0-3-3l-1 1M22 2l-1 1M21 7h1M17 2V1"/>',
    search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>'
  };
  function icon(name) {
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    for (const [key, value] of Object.entries({viewBox:'0 0 24 24',width:'20',height:'20',fill:'none',stroke:'currentColor','stroke-width':'2','stroke-linecap':'round','stroke-linejoin':'round','aria-hidden':'true'})) svg.setAttribute(key,value);
    svg.innerHTML = paths[name] || paths.info; // somente constantes locais
    return svg;
  }
  function notify(error, message) {
    const box=document.createElement('div');box.className='izgith-notice';box.setAttribute('role',error?'alert':'status');
    box.append(icon(error?'bomb':'circle-check'),document.createTextNode(error?'Algo deu errado.':message));
    if(error){const b=document.createElement('button');b.title='Ver erro e como corrigir';b.setAttribute('aria-label',b.title);b.append(icon('search'));b.onclick=()=>{
      const d=document.createElement('dialog'),p=document.createElement('pre'),close=document.createElement('button');
      p.textContent=String(error.message||error).replace(/github_pat_[\w]+|gh[pousr]_[\w]+/g,'[SEGREDO REMOVIDO]')+'\n\nComo corrigir: confira a conexão, o host instalado, a autenticação Git e as permissões do destino. Se houve conflito, revise o repositório antes de repetir. Não envie tokens pelo chat.';
      close.textContent='Fechar';close.onclick=()=>d.close();d.addEventListener('close',()=>d.remove());d.append(p,close);document.body.append(d);d.showModal();
    };box.append(b);}
    const close=document.createElement('button');close.textContent='×';close.setAttribute('aria-label','Fechar notificação');close.onclick=()=>box.remove();box.append(close);
    document.body.append(box);
  }
  globalThis.IZGITH_UI={icon,error:e=>notify(e),success:(m='O conteúdo foi publicado com sucesso!')=>notify(null,m)};
  addEventListener('unhandledrejection',e=>IZGITH_UI.error(e.reason||'Falha assíncrona.'));
  addEventListener('error',e=>IZGITH_UI.error(e.error||e.message||'Falha ao carregar recurso.'));
})();
