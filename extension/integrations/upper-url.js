(function () {
  'use strict';

  const BUTTON_ID = 'izgith-f-snc';
  const SUPPORTED_HOSTS = [
    /(^|\.)chatgpt\.com$/i,/^chatgpt\.com$/i,
    /(^|\.)claude\.ai$/i,/^claude\.ai$/i,
    /(^|\.)gemini\.google\.com$/i,/^gemini\.google\.com$/i,
    /(^|\.)copilot\.microsoft\.com$/i,/^copilot\.microsoft\.com$/i,
    /(^|\.)perplexity\.ai$/i,/^www\.perplexity\.ai$/i,
    /(^|\.)grok\.com$/i,/^grok\.com$/i,
    /(^|\.)chat\.deepseek\.com$/i,/^chat\.deepseek\.com$/i,
    /(^|\.)poe\.com$/i,/^poe\.com$/i,
    /(^|\.)chat\.mistral\.ai$/i,/^chat\.mistral\.ai$/i,
    /(^|\.)you\.com$/i,/^you\.com$/i,
    /(^|\.)meta\.ai$/i,/^www\.meta\.ai$/i,
    /(^|\.)chat\.qwen\.ai$/i,/^chat\.qwen\.ai$/i,
    /(^|\.)huggingface\.co$/i,/^huggingface\.co$/i,
    /(^|\.)character\.ai$/i,/^character\.ai$/i
  ];

  function supported() { return SUPPORTED_HOSTS.some((rx) => rx.test(location.hostname)); }
  function remove() { document.getElementById(BUTTON_ID)?.remove(); }

  function textOf(el) {
    return String(el?.innerText || el?.textContent || '').replace(/\s+/g, ' ').trim();
  }

  function extractConversation() {
    const host = location.hostname;
    const turns = [];
    const seen = new Set();
    const add = (role, node) => {
      const text = textOf(node);
      if (!text || text.length < 2 || seen.has(text)) return;
      seen.add(text); turns.push({role, text});
    };
    if (/chatgpt\.com$/i.test(host)) {
      document.querySelectorAll('[data-message-author-role]').forEach((n) => add(n.getAttribute('data-message-author-role') === 'user' ? 'user' : 'assistant', n));
    }
    if (!turns.length) {
      document.querySelectorAll('[data-testid*="message"], [data-testid*="conversation-turn"], [data-is-streaming], main article, main [role="article"]').forEach((n) => add('unknown', n));
    }
    if (!turns.length) {
      const main = document.querySelector('main') || document.body;
      add('unknown', main);
    }
    return {
      schema: 'izgith.upper-url.conversation.v1',
      url: location.href,
      host,
      title: document.title,
      captured_at: new Date().toISOString(),
      turns
    };
  }

  chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (!message || !['UPPER_URL_CAPTURE','SET_UPPER_URL_ENABLED'].includes(message.type)) return false;
    try {
      if (message.type === 'SET_UPPER_URL_ENABLED') {
        apply(message.enabled === true);
        sendResponse({ok: true, enabled: message.enabled === true});
      } else {
        sendResponse({ok: true, conversation: extractConversation()});
      }
    } catch (error) { sendResponse({ok: false, error: String(error?.message || error)}); }
    return false;
  });

  function mount() {
    if (!supported() || document.getElementById(BUTTON_ID)) return;
    const button = document.createElement('button');
    button.id = BUTTON_ID;
    button.type = 'button';
    button.textContent = 'F-SNC';
    button.title = 'UPPER URL · sincronização de referência';
    button.setAttribute('aria-label', 'F-SNC · UPPER URL');
    button.addEventListener('click', async () => {
      try {
        await chrome.storage.local.set({upperUrlLastSync:{url:location.href,host:location.hostname,at:new Date().toISOString()}});
        button.dataset.synced = '1'; button.textContent = 'F-SNC ✓';
        setTimeout(() => { if (button.isConnected) button.textContent = 'F-SNC'; }, 1200);
      } catch (error) { console.warn('[IZGITH UPPER URL]', error); }
    });
    document.body.appendChild(button);
  }

  function apply(enabled) { if (enabled) mount(); else remove(); }
  chrome.storage.local.get({upperUrlEnabled:false}, (state) => apply(state.upperUrlEnabled === true));
  chrome.storage.onChanged.addListener((changes, area) => { if (area === 'local' && changes.upperUrlEnabled) apply(changes.upperUrlEnabled.newValue === true); });
  mount();
  new MutationObserver(mount).observe(document.documentElement, {childList:true, subtree:true});
})();
