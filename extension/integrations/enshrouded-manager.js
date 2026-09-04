(() => {
  'use strict';

  const PROFILE_KEY = 'izgith.enshrouded.profiles';
  const STATE_KEY = 'izgith.enshrouded.manager.state';
  const ACTIONS = ['verify', 'install', 'start', 'stop', 'backup', 'restore', 'prune', 'mods', 'resources', 'version'];
  const $ = id => document.getElementById(id);

  async function loadProfiles() {
    const s = await chrome.storage.local.get({ [PROFILE_KEY]: [] });
    return Array.isArray(s[PROFILE_KEY]) ? s[PROFILE_KEY] : [];
  }
  async function saveProfiles(profiles) {
    return chrome.storage.local.set({ [PROFILE_KEY]: profiles });
  }

  function normalizeProfile(profile) {
    return {
      id: profile.id || crypto.randomUUID(),
      name: String(profile.name || 'Servidor Enshrouded').trim() || 'Servidor Enshrouded',
      host: String(profile.host || '').trim(),
      port: Number(profile.port) || 15636,
      notes: String(profile.notes || '').trim(),
      version: String(profile.version || 'latest').trim() || 'latest',
      backupCron: String(profile.backupCron || '*/60 * * * *').trim(),
      backupFormat: String(profile.backupFormat || 'zstd').trim(),
      backupKeepLast: Number.isInteger(Number(profile.backupKeepLast)) ? Number(profile.backupKeepLast) : 24,
      modsEnabled: profile.modsEnabled !== false,
      resourcePollInterval: Number(profile.resourcePollInterval) || 60,
      updatedAt: new Date().toISOString()
    };
  }

  function validate(profile) {
    const host = String(profile.host || '').trim();
    const port = Number(profile.port);
    const hostOk = /^(?=.{1,253}$)[a-zA-Z0-9.-]+$/.test(host) || /^\[[0-9a-fA-F:]+\]$/.test(host);
    const portOk = Number.isInteger(port) && port >= 1 && port <= 65535;
    return { ok: hostOk && portOk, host, port, errors: [].concat(hostOk ? [] : ['host inválido']).concat(portOk ? [] : ['porta deve ser 1–65535']) };
  }

  async function upsert(profile) {
    const item = normalizeProfile(profile);
    const validation = validate(item);
    if (!validation.ok) throw new Error(validation.errors.join('; '));
    const profiles = await loadProfiles();
    const index = profiles.findIndex(x => x.id === item.id);
    if (index >= 0) profiles[index] = item; else profiles.unshift(item);
    await saveProfiles(profiles);
    return item;
  }

  async function remove(id) {
    await saveProfiles((await loadProfiles()).filter(x => x.id !== id));
  }

  function address(profile) {
    return `${profile.host}:${profile.port || 15636}`;
  }

  function configFromProfile(profile) {
    const p = normalizeProfile(profile);
    return {
      ENSHROUDED_NAME: p.name,
      ENSHROUDED_QUERY_PORT: 15637,
      VERSION: p.version,
      BACKUP_CRON: p.backupCron,
      BACKUP_FORMAT: p.backupFormat,
      BACKUP_KEEP_LAST: p.backupKeepLast,
      BACKUP_LIVE: true,
      BACKUP_COLD: true,
      BACKUP_EMERGENCY: true,
      RESOURCE_POLL_INTERVAL: p.resourcePollInterval,
      LOG_TAIL: false,
      MODS_ENABLED: p.modsEnabled
    };
  }

  function composeFromProfile(profile) {
    const p = normalizeProfile(profile);
    const c = configFromProfile(p);
    const lines = [
      'services:',
      '  enshrouded:',
      '    image: ghcr.io/lincolnthalles/enshrouded-container:latest',
      '    restart: unless-stopped',
      '    environment:',
      ...Object.entries(c).map(([k, v]) => `      ${k}: ${JSON.stringify(v)}`),
      '    volumes:',
      '      - ./data/manifests:/data/manifests',
      '      - ./data/wineprefix:/data/wineprefix',
      '      - ./data/mods:/data/mods',
      '      - ./data/saves:/data/saves',
      '      - ./data/backups:/data/backups',
      '      - ./data/config:/data/config',
      '      - ./data/logs:/data/logs',
      '    ports:',
      '      - "15636:15636/udp"',
      '      - "15637:15637/udp"',
      '      - "27015:27015/tcp"',
      '      - "27015:27015/udp"'
    ];
    return lines.join('\n') + '\n';
  }

  function buildPlan(profile, action) {
    const p = normalizeProfile(profile);
    if (!ACTIONS.includes(action)) throw new Error('Ação Enshrouded não suportada.');
    const plan = {
      schema: 'izgith.enshrouded.plan.v1',
      action,
      profile: p,
      generatedAt: new Date().toISOString(),
      source: 'ENSHROUDED MANAGER / enshctl-inspired',
      execution: 'browser-plan-only',
      externalProcessStarted: false,
      steps: []
    };
    const common = {
      verify: ['validar endpoint e parâmetros', 'verificar configuração e diretórios'],
      install: ['validar versão', 'preparar diretórios de manifests', 'preparar configuração'],
      start: ['validar configuração', 'verificar portas 15636/15637/27015', 'preparar inicialização'],
      stop: ['preparar encerramento gracioso', 'programar backup cold'],
      backup: ['preparar backup live/cold', 'aplicar retenção', 'registrar destino'],
      restore: ['selecionar backup', 'validar integridade do pacote', 'preparar restauração'],
      prune: ['calcular retenção', 'selecionar backups antigos', 'preparar remoção'],
      mods: ['validar diretório de mods', 'preparar overlay', 'verificar DLL override quando aplicável'],
      resources: ['configurar polling de CPU/RSS', 'registrar intervalo', 'preparar relatório'],
      version: ['consultar versão desejada', 'registrar manifest/build', 'preparar atualização determinística']
    };
    plan.steps = common[action].map((description, index) => ({ order: index + 1, description, status: 'prepared' }));
    return plan;
  }

  async function persistState(patch) {
    const current = await chrome.storage.local.get({ [STATE_KEY]: {} });
    await chrome.storage.local.set({ [STATE_KEY]: { ...(current[STATE_KEY] || {}), ...patch, updatedAt: new Date().toISOString() } });
  }

  window.IZGITHEnshrouded = {
    list: loadProfiles,
    upsert,
    remove,
    validate,
    address,
    actions: ACTIONS.slice(),
    config: configFromProfile,
    compose: composeFromProfile,
    plan: buildPlan,
    async prepare(profile, action) {
      const plan = buildPlan(profile, action);
      await persistState({ lastAction: action, lastPlan: plan });
      return plan;
    },
    async getState() {
      const s = await chrome.storage.local.get({ [STATE_KEY]: {} });
      return s[STATE_KEY] || {};
    }
  };

  function svgPower() {
    return '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2v10"></path><path d="M6.2 5.5a8 8 0 1 0 11.6 0"></path></svg>';
  }
  function svgMenu() {
    return '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 6h16M4 12h16M4 18h16"></path></svg>';
  }
  function svgInfo() {
    return '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9"></circle><path d="M12 10v6M12 7h.01"></path></svg>';
  }
  function svgBookmark() {
    return '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 4h12v16l-6-3-6 3z"></path></svg>';
  }

  function replaceButton(button, content, title) {
    if (!button) return button;
    const clone = button.cloneNode(false);
    clone.innerHTML = content;
    clone.title = title;
    clone.setAttribute('aria-label', title);
    button.replaceWith(clone);
    return clone;
  }

  function patchToolMenus() {
    const conv = $('providerMenuButton');
    if (conv && !conv.dataset.hardened) {
      conv.dataset.hardened = '1';
      const next = replaceButton(conv, svgMenu(), 'Plataformas suportadas');
      next.addEventListener('click', event => {
        event.preventDefault(); event.stopPropagation();
        const menu = $('providerMenu');
        const open = !!menu && menu.hidden;
        if (menu) menu.hidden = !open;
        next.setAttribute('aria-expanded', String(open));
      });
    }

    const gh = $('githubMenuButton');
    const ghMenu = $('githubMenu');
    if (gh && ghMenu && !gh.dataset.hardened) {
      gh.dataset.hardened = '1';
      const next = replaceButton(gh, svgMenu(), 'MENU DE AÇÕES DO UPPER GITHUB');
      const actions = ['githubFiles', 'githubFolders', 'githubCheck', 'githubConfig'];
      actions.forEach(id => { const b = $(id); if (b) b.hidden = true; });
      next.addEventListener('click', event => {
        event.preventDefault(); event.stopPropagation();
        const open = ghMenu.hidden;
        ghMenu.hidden = !open;
        next.setAttribute('aria-expanded', String(open));
      });
      ghMenu.replaceChildren(...[
        ['githubFiles', 'ARQUIVOS'],
        ['githubFolders', 'PASTAS'],
        ['githubCheck', 'CHECK HOST/GIT'],
        ['githubConfig', 'DOWNLOAD CONFIG HOST']
      ].map(([id, label], i) => {
        const row = document.createElement('button');
        row.type = 'button'; row.className = 'provider-row upper-menu-action';
        row.style.cssText = `display:flex;width:100%;border:0;background:transparent;text-align:left;align-items:center;gap:6px;padding:6px;color:inherit;--mark:hsl(${i * 85} 85% 60%)`;
        const mark = document.createElement('span'); mark.className = 'bookmark'; mark.innerHTML = svgBookmark(); mark.style.color = 'var(--mark)';
        const text = document.createElement('span'); text.textContent = label; row.append(mark, text);
        row.addEventListener('click', () => $(id)?.click());
        return row;
      }));
    }

    const convStatus = $('convDStatus');
    const convPower = $('toolConvgpt');
    if (convPower && !convPower.dataset.hardened) {
      const next = replaceButton(convPower, svgPower(), 'Ativar ou desativar CONV-D');
      next.id = 'toolConvgpt'; next.dataset.hardened = '1';
      next.addEventListener('click', async () => {
        const s = await chrome.storage.local.get({ convDEnabled: true });
        const on = s.convDEnabled === false;
        await chrome.storage.local.set({ convDEnabled: on });
        if (convStatus) convStatus.textContent = on ? 'Ativo' : 'OFF';
        next.title = on ? 'Desativar CONV-D' : 'Ativar CONV-D';
      });
    }

    const upperPower = $('toggleForceSync');
    const upperStatus = $('forceSyncStatus');
    if (upperPower && !upperPower.dataset.hardened) {
      const next = replaceButton(upperPower, svgPower(), 'Ativar ou desativar UPPER URL');
      next.id = 'toggleForceSync'; next.dataset.hardened = '1';
      next.addEventListener('click', async () => {
        const s = await chrome.storage.local.get({ forceSync: false });
        const on = !s.forceSync;
        await chrome.storage.local.set({ forceSync: on });
        if (upperStatus) upperStatus.textContent = on ? 'ON' : 'OFF';
      });
    }

    ['downloadByUrl', 'toolSonpef', 'toolKit', 'selectPackage'].forEach(id => {
      const b = $(id); if (!b) return;
      if (id === 'downloadByUrl') b.innerHTML = '<svg viewBox="0 0 24 24"><path d="M12 3v12M7 10l5 5 5-5M5 21h14"></path></svg>';
      b.dataset.hardened = '1';
    });

    document.querySelectorAll('.tool-card').forEach(card => {
      card.style.minHeight = '68px';
      card.style.height = 'auto';
      card.style.padding = '9px';
    });
  }

  function patchServerPanel() {
    const panel = document.querySelector('#servers .panel');
    if (!panel || panel.dataset.enshroudedHardened) return;
    panel.dataset.enshroudedHardened = '1';
    const box = document.createElement('div');
    box.className = 'enshrouded-manager-actions';
    box.style.cssText = 'display:flex;flex-wrap:wrap;gap:6px;margin:10px 0;padding:9px;border:1px solid rgba(255,255,255,.08);border-radius:10px;background:rgba(0,0,0,.12)';
    const actions = [
      ['verify', 'Verificar'], ['install', 'Preparar Instalação'], ['start', 'Preparar Início'],
      ['stop', 'Preparar Parada'], ['backup', 'Backup'], ['restore', 'Restaurar'],
      ['prune', 'Retenção'], ['mods', 'Mods'], ['resources', 'Recursos'], ['version', 'Versão']
    ];
    actions.forEach(([action, label]) => {
      const b = document.createElement('button'); b.className = 'btn ghost'; b.type = 'button'; b.textContent = label;
      b.title = `Preparar ação ${label} sem iniciar processo externo`;
      b.addEventListener('click', async () => {
        const profile = { name: $('serverName')?.value, host: $('serverHost')?.value, port: $('serverPort')?.value, notes: $('serverNotes')?.value };
        const v = validate(profile);
        const result = $('hostResult');
        if (!v.ok) { if (result) result.textContent = 'Informe host e porta válidos antes de preparar a ação.'; return; }
        try {
          const plan = await window.IZGITHEnshrouded.prepare(profile, action);
          if (result) result.textContent = `ENSHROUDED MANAGER: ${label} preparado (${plan.steps.length} etapa(s)); nenhum processo externo foi iniciado.`;
        } catch (error) { if (result) result.textContent = `Falha: ${error.message}`; }
      });
      box.appendChild(b);
    });
    panel.insertBefore(box, $('serverList'));

    const exportRow = document.createElement('div');
    exportRow.style.cssText = 'display:flex;gap:6px;flex-wrap:wrap;margin:6px 0';
    [['config', 'Baixar Config'], ['compose', 'Baixar Compose'], ['plan', 'Baixar Plano']].forEach(([kind, label]) => {
      const b = document.createElement('button'); b.className = 'btn'; b.type = 'button'; b.textContent = label;
      b.addEventListener('click', () => {
        const profile = { name: $('serverName')?.value, host: $('serverHost')?.value, port: $('serverPort')?.value, notes: $('serverNotes')?.value };
        const v = validate(profile); if (!v.ok) { $('hostResult').textContent = 'Informe host e porta válidos.'; return; }
        let content, filename, mime;
        if (kind === 'config') { content = JSON.stringify(configFromProfile(profile), null, 2); filename = 'enshrouded-server-config.json'; mime = 'application/json'; }
        else if (kind === 'compose') { content = composeFromProfile(profile); filename = 'docker-compose.enshrouded.yml'; mime = 'text/yaml'; }
        else { content = JSON.stringify(buildPlan(profile, 'verify'), null, 2); filename = 'enshrouded-manager-plan.json'; mime = 'application/json'; }
        const url = URL.createObjectURL(new Blob([content], { type: mime })); const a = document.createElement('a'); a.href = url; a.download = filename; a.click(); setTimeout(() => URL.revokeObjectURL(url), 1000);
        $('hostResult').textContent = `${label} gerado localmente.`;
      });
      exportRow.appendChild(b);
    });
    panel.insertBefore(exportRow, box);
  }

  function patchWhenReady() {
    patchToolMenus();
    patchServerPanel();
    const splash = $('splash'); if (splash) splash.classList.add('hidden');
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', patchWhenReady, { once: true });
  else patchWhenReady();
})();
