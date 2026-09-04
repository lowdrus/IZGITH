(() => {
  'use strict';

  function bindMenu(buttonId, menuId) {
    const button = document.getElementById(buttonId);
    const menu = document.getElementById(menuId);
    if (!button || !menu || button.dataset.hardenedMenu === '1') return;
    button.dataset.hardenedMenu = '1';

    const sync = open => {
      menu.hidden = !open;
      button.setAttribute('aria-expanded', String(open));
      button.dataset.menuOpen = open ? '1' : '0';
    };

    // Capture phase prevents the legacy bubble listener from toggling twice.
    button.addEventListener('click', event => {
      event.preventDefault();
      event.stopImmediatePropagation();
      sync(menu.hidden);
    }, true);

    menu.addEventListener('click', event => event.stopPropagation(), true);
    sync(false);
  }

  function bindOutsideClose() {
    if (document.documentElement.dataset.menuOutsideBound === '1') return;
    document.documentElement.dataset.menuOutsideBound = '1';
    document.addEventListener('click', event => {
      for (const [buttonId, menuId] of [
        ['providerMenuButton', 'providerMenu'],
        ['githubMenuButton', 'githubMenu']
      ]) {
        const button = document.getElementById(buttonId);
        const menu = document.getElementById(menuId);
        if (!button || !menu || menu.hidden) continue;
        if (!button.contains(event.target) && !menu.contains(event.target)) {
          menu.hidden = true;
          button.setAttribute('aria-expanded', 'false');
          button.dataset.menuOpen = '0';
        }
      }
    });
  }

  function init() {
    bindMenu('providerMenuButton', 'providerMenu');
    bindMenu('githubMenuButton', 'githubMenu');
    bindOutsideClose();
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init, { once: true });
  else init();
})();
