(() => {
  'use strict';
  const $ = (id) => document.getElementById(id);
  const state = { endpoint: 'http://127.0.0.1:38751', connected: false };
  const tokenKey = 'izgith.enshrouded.runtime.session.token';

  const notify = (title, message) => {
    const titleEl = $('modalTitle'); const textEl = $('modalText'); const modal = $('modal');
    if (titleEl) titleEl.textContent = title;
    if (textEl) textEl.textContent = message;
    if (modal) modal.hidden = false;
  };

  const log = (message) => {
    const consoleEl = $('console');
    if (consoleEl) consoleEl.textContent = `[${new Date().toLocaleTimeString('pt-BR')}] ${message}\n${consoleEl.textContent || ''}`.slice(0, 20000);
  };

  const endpoint = () => String($('runtimeEndpoint')?.value || state.endpoint).trim().replace(/\/$/, '');
  const sessionToken = () => String(sessionStorage.getItem(tokenKey) || $('runtimeToken')?.value || '').trim();

  async function runtimeRequest(operation, payload = {}) {
    const url = `${endpoint()}/v1/operations/${operation}`;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 6000);
    const headers = { 'Content-Type': 'application/json', 'Accept': 'application/json' };
    const token = sessionToken();
    if (token) headers.Authorization = `Bearer ${token}`;
    try {
      const response = await fetch(url, { method: 'POST', headers, body: JSON.stringify(payload), cache: 'no-store', signal: controller.signal });
      const text = await response.text();
      let body = null; try { body = text ? JSON.parse(text) : {}; } catch (_) { body = { raw: text }; }
      if (!response.ok) throw new Error(`HTTP ${response.status}: ${body?.message || body?.error || text || 'runtime error'}`);
      state.connected = true;
      $('runtimeState')?.classList.remove('warn');
      if ($('runtimeState')) $('runtimeState').textContent = 'CONECTADO';
      if ($('runtimeBadge')) $('runtimeBadge').textContent = 'CONECTADO';
      return body;
    } finally { clearTimeout(timeout); }
  }

  async function health() {
    const base = endpoint();
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 2500);
    try {
      const token = sessionToken();
      const headers = token ? { Authorization: `Bearer ${token}` } : {};
      const response = await fetch(`${base}/health`, { headers, cache: 'no-store', signal: controller.signal });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      state.connected = true;
      state.endpoint = base;
      if ($('runtimeState')) $('runtimeState').textContent = 'CONECTADO';
      if ($('runtimeBadge')) $('runtimeBadge').textContent = 'CONECTADO';
      log(`Runtime Agent saudável: ${base}`);
      return true;
    } catch (error) {
      state.connected = false;
      if ($('runtimeState')) $('runtimeState').textContent = 'PLANO';
      if ($('runtimeBadge')) $('runtimeBadge').textContent = 'PLANO';
      log(`Runtime indisponível: ${error?.name === 'AbortError' ? 'timeout' : error?.message || error}`);
      return false;
    } finally { clearTimeout(timeout); }
  }

  function profilePayload() {
    return {
      name: ($('cfgName')?.value || 'Meu Enshrouded').trim(),
      host: ($('cfgHost')?.value || '127.0.0.1').trim(),
      port: Number($('cfgPort')?.value) || 15636,
      version: ($('cfgVersion')?.value || 'latest').trim(),
      slots: Number($('cfgSlots')?.value) || 16
    };
  }

  function download(content, name, mime) {
    const blob = new Blob([content], { type: mime });
    const url = URL.createObjectURL(blob); const a = document.createElement('a');
    a.href = url; a.download = name; a.click(); setTimeout(() => URL.revokeObjectURL(url), 1200);
  }

  async function action(kind) {
    const p = profilePayload();
    const local = {
      'save-profile': ['Perfil preparado', 'O perfil está pronto para persistência pelo painel.'],
      'clear': ['Limpeza preparada', 'Os campos do perfil podem ser limpos sem tocar no runtime.'],
      'download-config': ['Configuração', 'Baixando configuração JSON.'],
      'download-compose': ['Compose', 'Baixando Docker Compose.'],
      'download-plan': ['Plano', 'Baixando plano operacional.'],
      'validate': ['Validação', 'Validação local concluída: campos e contrato básicos estão disponíveis.'],
      'verify': ['Verificação', 'Use Verificar após conectar o Runtime Agent para confirmar health e operações allow-listed.'],
      'prepare-install': ['Instalação preparada', 'Plano de instalação criado; nenhum processo externo foi iniciado.'],
      'prepare-start': ['Início preparado', 'Plano de início criado; execução depende do Runtime Agent.'],
      'prepare-stop': ['Parada preparada', 'Plano de parada criado; execução depende do Runtime Agent.']
    };
    if (kind === 'clear') { ['cfgName','cfgHost','cfgPort','cfgVersion','cfgSlots'].forEach((id) => { const el = $(id); if (el) el.value = ''; }); notify('Limpo', 'Campos do perfil foram limpos.'); return; }
    if (kind === 'download-config') { download(JSON.stringify({ ENSHROUDED_NAME:p.name, ENSHROUDED_SLOT_COUNT:p.slots, ENSHROUDED_QUERY_PORT:15637, VERSION:p.version, BACKUP_CRON:'*/60 * * * *', BACKUP_FORMAT:'zstd', BACKUP_KEEP_LAST:24, BACKUP_LIVE:true, BACKUP_COLD:true, BACKUP_EMERGENCY:true, RESOURCE_POLL_INTERVAL:60 }, null, 2), 'enshrouded-server-config.json', 'application/json'); return; }
    if (kind === 'download-compose') { download(`services:\n  enshrouded:\n    image: ghcr.io/lincolnthalles/enshrouded-container:latest\n    restart: unless-stopped\n    environment:\n      ENSHROUDED_NAME: ${JSON.stringify(p.name)}\n      ENSHROUDED_SLOT_COUNT: ${p.slots}\n      VERSION: ${JSON.stringify(p.version)}\n      BACKUP_CRON: "*/60 * * * *"\n      BACKUP_LIVE: "true"\n      BACKUP_COLD: "true"\n      BACKUP_EMERGENCY: "true"\n    ports:\n      - "15636:15636/udp"\n      - "15637:15637/udp"\n`, 'docker-compose.enshrouded.yml', 'text/yaml'); return; }
    if (kind === 'download-plan') { download(JSON.stringify({ schema:'izgith.enshrouded.plan.v1', profile:p, steps:['validate','prepare-install','prepare-start','verify'], external_execution:'runtime-agent-only' }, null, 2), 'enshrouded-operation-plan.json', 'application/json'); return; }
    const operationMap = { 'prepare-install':'server.prepare-install', 'prepare-start':'server.start', 'prepare-stop':'server.stop', backup:'backup.create', restore:'backup.restore', retention:'backup.prune', mods:'mods.list', resources:'resources.read', version:'server.version', verify:'health', validate:'servers.validate', 'save-profile':'profiles.save' };
    const operation = operationMap[kind];
    if (!operation) { notify('ENSHGERENC', 'Ação reconhecida, mas sem executor configurado.'); return; }
    if (!state.connected && !(await health())) { notify('Modo plano', `“${kind}” foi preparado, mas o Runtime Agent não está conectado. Nenhum processo externo foi executado.`); return; }
    try {
      const result = await runtimeRequest(operation, { profile:p });
      notify('Runtime Agent', `${kind} concluído pelo endpoint allow-listed.`);
      log(`${operation}: ${JSON.stringify(result).slice(0, 500)}`);
    } catch (error) { notify('Falha no runtime', error?.message || String(error)); log(`Falha ${operation}: ${error?.message || error}`); }
  }

  function wire() {
    document.querySelectorAll('[data-ens-action]').forEach((button) => button.addEventListener('click', () => action(button.dataset.ensAction)));
    const token = $('runtimeToken');
    token?.addEventListener('input', () => sessionStorage.setItem(tokenKey, token.value));
    $('runtimeEndpoint')?.addEventListener('change', () => { state.endpoint = endpoint(); health(); });
    $('connectRuntime')?.addEventListener('click', () => health());
    $('refresh')?.addEventListener('click', () => health());
    health();
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', wire, { once:true }); else wire();
})();
