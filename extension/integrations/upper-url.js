(function () {
  'use strict';

  const BUTTON_ID = 'izgith-f-snc';
  const SUPPORTED_HOSTS = [
    /(^|\.)chatgpt\.com$/i,
    /(^|\.)claude\.ai$/i,
    /(^|\.)gemini\.google\.com$/i,
    /(^|\.)copilot\.microsoft\.com$/i,
    /(^|\.)perplexity\.ai$/i,
    /(^|\.)grok\.com$/i,
    /(^|\.)chat\.deepseek\.com$/i,
    /(^|\.)poe\.com$/i,
    /(^|\.)chat\.mistral\.ai$/i,
    /(^|\.)you\.com$/i,
    /(^|\.)meta\.ai$/i,
    /(^|\.)chat\.qwen\.ai$/i,
    /(^|\.)huggingface\.co$/i,
    /(^|\.)character\.ai$/i
  ];

  function supported() {
    return SUPPORTED_HOSTS.some((rx) => rx.test(location.hostname));
  }

  function remove() {
    document.getElementById(BUTTON_ID)?.remove();
  }

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
        await chrome.storage.local.set({
          upperUrlLastSync: {
            url: location.href,
            host: location.hostname,
            at: new Date().toISOString()
          }
        });
        button.dataset.synced = '1';
        button.textContent = 'F-SNC ✓';
        setTimeout(() => {
          if (button.isConnected) button.textContent = 'F-SNC';
        }, 1200);
      } catch (error) {
        console.warn('[IZGITH UPPER URL]', error);
      }
    });
    document.body.appendChild(button);
  }

  function apply(enabled) {
    if (enabled) mount(); else remove();
  }

  chrome.storage.local.get({ upperUrlEnabled: false }, (state) => apply(state.upperUrlEnabled === true));
  chrome.storage.onChanged.addListener((changes, area) => {
    if (area === 'local' && changes.upperUrlEnabled) {
      apply(changes.upperUrlEnabled.newValue === true);
    }
  });

  mount();
  new MutationObserver(mount).observe(document.documentElement, { childList: true, subtree: true });
})();
