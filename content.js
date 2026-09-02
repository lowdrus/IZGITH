(() => {
  function getMessages() {
    const nodes = document.querySelectorAll('[data-message-author-role], article, div.markdown');
    const out = []; let idx = 0;
    nodes.forEach(n => {
      const role = n.getAttribute('data-message-author-role') ||
                   (n.closest('[data-message-author-role]')?.getAttribute('data-message-author-role')) ||
                   (/assistant/i.test(n.className) ? 'assistant' : (/user|you/i.test(n.className) ? 'user' : 'unknown'));
      let text = n.innerText || n.textContent || '';
      text = text.replace(/\u00A0/g, ' ').trim();
      if (text && text.length > 3) { out.push({role, content: {parts:[text]}, idx: ++idx}); }
    });
    return out;
  }
  chrome.runtime.onMessage.addListener((msg, sender, respond) => {
    if (msg?.fn === 'SCRAPE_CHAT') {
      const messages = getMessages();
      respond({ok:true, messages});
    }
  });
})();