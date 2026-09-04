(() => {
  'use strict';

  function installMenuLayout() {
    if (document.getElementById('izgithMenuLayoutFix')) return;
    const style = document.createElement('style');
    style.id = 'izgithMenuLayoutFix';
    style.textContent = [
      '.tool-card{overflow:visible!important}',
      '.tool-grid{overflow:visible!important}',
      '.tool-card .tool-body{position:relative}',
      '.provider-menu{position:relative;z-index:40}',
      '.provider-list{z-index:100;max-height:60vh;overflow:auto}',
      '.upper-github-menu{position:absolute;right:0;left:auto;top:34px;z-index:100}'
    ].join('');
    document.head.appendChild(style);
  }

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
    document.addEventListener('keydown', event => {
      if (event.key !== 'Escape') return;
      for (const [buttonId, menuId] of [
        ['providerMenuButton', 'providerMenu'],
        ['githubMenuButton', 'githubMenu']
      ]) {
        const button = document.getElementById(buttonId);
        const menu = document.getElementById(menuId);
        if (!button || !menu || menu.hidden) continue;
        menu.hidden = true;
        button.setAttribute('aria-expanded', 'false');
        button.dataset.menuOpen = '0';
      }
    });
  }

  function init() {
    installMenuLayout();
    bindMenu('providerMenuButton', 'providerMenu');
    bindMenu('githubMenuButton', 'githubMenu');
    bindOutsideClose();
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init, { once: true });
  else init();
})();
