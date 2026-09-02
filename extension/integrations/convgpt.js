(() => {
  'use strict';
  const BUTTON_ID = 'izgith-convgpt-export';
  const clean = value => String(value || '').replace(/\u00a0/g, ' ').trim();
  const safeName = value => clean(value).replace(/[\\/:*?"<>|]+/g, '_').slice(0, 90) || 'conversa-chatgpt';

  function collect() {
    const nodes = [...document.querySelectorAll('[data-message-author-role]')];
    const messages = nodes.map((node, index) => ({
      index: index + 1,
      role: node.getAttribute('data-message-author-role') || 'unknown',
      text: clean(node.innerText)
    })).filter(message => message.text);
    return {
      schema: 'izgith.convgpt.v1',
      title: clean(document.querySelector('h1')?.innerText || document.title.replace(/\s*[-|]\s*ChatGPT.*$/i, '')),
      url: location.href,
      exportedAt: new Date().toISOString(),
      messageCount: messages.length,
      messages
    };
  }

  function markdown(data) {
    const body = data.messages.map(item => `## ${item.index}. ${item.role}\n\n${item.text}`).join('\n\n---\n\n');
    return `# ${data.title || 'Conversa ChatGPT'}\n\n- URL: ${data.url}\n- Exportado: ${data.exportedAt}\n- Mensagens: ${data.messageCount}\n\n${body}\n`;
  }

  function download(name, content, type) {
    const url = URL.createObjectURL(new Blob([content], {type}));
    const link = document.createElement('a'); link.href = url; link.download = name; link.click();
    setTimeout(() => URL.revokeObjectURL(url), 1500);
  }

  function exportConversation() {
    const button = document.getElementById(BUTTON_ID); button.disabled = true; button.textContent = 'Exportando…';
    try {
      const data = collect();
      if (!data.messages.length) throw new Error('Nenhuma mensagem carregada nesta conversa.');
      const base = safeName(data.title);
      download(`${base}.md`, markdown(data), 'text/markdown;charset=utf-8');
      download(`${base}.json`, JSON.stringify(data, null, 2), 'application/json;charset=utf-8');
      button.textContent = `CONVGPT ✓ ${data.messageCount} mensagens`;
    } catch (error) { button.textContent = `CONVGPT: ${error.message}`; }
    finally { setTimeout(() => { button.disabled = false; button.textContent = 'Baixar conversa · CONVGPT'; }, 3500); }
  }

  function mount() {
    if (document.getElementById(BUTTON_ID)) return;
    const button = document.createElement('button'); button.id = BUTTON_ID; button.type = 'button';
    button.textContent = 'Baixar conversa · CONVGPT'; button.addEventListener('click', exportConversation);
    document.body.appendChild(button);
  }
  mount(); new MutationObserver(mount).observe(document.documentElement, {childList:true,subtree:true});
})();
