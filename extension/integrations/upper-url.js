(function () {
  'use strict';

  const BUTTON_ID = 'izgith-f-snc';
  const SUPPORTED_HOSTS = [
    'chatgpt.com','claude.ai','gemini.google.com','copilot.microsoft.com','perplexity.ai',
    'www.perplexity.ai','grok.com','chat.deepseek.com','poe.com','chat.mistral.ai','you.com',
    'www.meta.ai','meta.ai','chat.qwen.ai','huggingface.co','character.ai'
  ];

  function supported() { return SUPPORTED_HOSTS.includes(location.hostname); }
  function textOf(el) { return String(el?.innerText || el?.textContent || '').replace(/\s+/g, ' ').trim(); }
  function uniquePush(list, role, node) {
    const text = textOf(node);
    if (!text || text.length < 2) return;
    const last = list[list.length - 1];
    if (last && last.role === role && last.text === text) return;
    if (list.some((x) => x.text === text && x.role === role)) return;
    list.push({ role, text });
  }

  function extractTurns() {
    const host = location.hostname;
    const turns = [];
    if (/^chatgpt\.com$/i.test(host)) {
      document.querySelectorAll('[data-message-author-role]').forEach((node) => {
        uniquePush(turns, node.getAttribute('data-message-author-role') === 'user' ? 'user' : 'assistant', node);
      });
    }
    if (!turns.length) {
      const selectors = [
        '[data-testid*="conversation-turn"]', '[data-testid*="message"]',
        '[data-is-streaming]', 'main article', 'main [role="article"]'
      ];
      for (const selector of selectors) document.querySelectorAll(selector).forEach((node) => uniquePush(turns, 'unknown', node));
    }
    return turns;
  }

  function capture() {
    const turns = extractTurns();
    const latest = turns.length ? turns[turns.length - 1] : null;
    return {
      schema: 'izgith.f-snc.capture.v2',
      url: location.href,
      host: location.hostname,
      title: document.title,
      captured_at: new Date().toISOString(),
      latest_turn: latest,
      turn_count: turns.length
    };
  }

  async function sendCapture(button) {
    const conversation = capture();
    if (!conversation.latest_turn) throw new Error('Nenhum conteúdo de conversa foi encontrado na página.');
    const response = await new Promise((resolve, reject) => {
      try {
        chrome.runtime.sendMessage({ type: 'FSNC_CAPTURE', conversation }, (result) => {
          const err = chrome.runtime.lastError;
          if (err) reject(new Error(err.message));
          else resolve(result);
        });
      } catch (error) { reject(error); }
    });
    if (!response?.ok) throw new Error(response?.error || 'Falha ao registrar captura.');
    button.textContent = 'F-SNC ✓';
    button.dataset.synced = '1';
    button.title = `Último conteúdo capturado · ${conversation.latest_turn.role}`;
    setTimeout(() => { if (button.isConnected) button.textContent = 'F-SNC'; }, 1600);
  }

  function remove() { document.getElementById(BUTTON_ID)?.remove(); }

  function mount() {
    if (!supported() || document.getElementById(BUTTON_ID)) return;
    const button = document.createElement('button');
    button.id = BUTTON_ID;
    button.type = 'button';
    button.textContent = 'F-SNC';
    button.title = 'Capturar o último conteúdo desta conversa';
    button.setAttribute('aria-label', 'F-SNC · capturar último conteúdo da conversa');
    button.addEventListener('click', async () => {
      button.disabled = true;
      try { await sendCapture(button); }
      catch (error) { console.warn('[IZGITH F-SNC]', error); button.title = `F-SNC: ${error.message}`; }
      finally { button.disabled = false; }
    });
    document.body.appendChild(button);
  }

  function apply(enabled) { if (enabled) mount(); else remove(); }
  chrome.storage.local.get({ upperUrlEnabled: false }, (state) => apply(state.upperUrlEnabled === true));
  chrome.storage.onChanged.addListener((changes, area) => {
    if (area === 'local' && changes.upperUrlEnabled) apply(changes.upperUrlEnabled.newValue === true);
  });
  mount();
  new MutationObserver(mount).observe(document.documentElement, { childList: true, subtree: true });
})();
