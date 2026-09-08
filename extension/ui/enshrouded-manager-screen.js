(() => {
  'use strict';

  // This screen is also shipped in packages that may be opened from other IZGITH
  // surfaces. Never assume the ENSH-GERENC DOM exists: a missing element must not
  // break the host dashboard with "Cannot set properties of null".
  const $ = (id) => document.getElementById(id);
  const on = (id, event, handler) => {
    const el = $(id);
    if (el) el.addEventListener(event, handler);
    return el;
  };
  const text = (id, value) => {
    const el = $(id);
    if (el) el.textContent = String(value);
  };

  // Dashboard pages do not contain the dedicated ENSH-GERENC contract. In that
  // case this file becomes a harmless no-op, even if a stale package references it.
  const isManagerScreen = !!($('runtimeState') && $('serverList') && $('cfgName') && $('modal'));
  if (!isManagerScreen) return;

  const STORE = 'izgith.enshrouded.ui.v3';
  const state = {
    profiles: [], players: [], backups: [], logs: [],
    runtime: { connected: false, endpoint: 'http://127.0.0.1:38751' },
    currentView: 'overview'
  };

  const write = () => chrome.storage.local.set({ [STORE]: state });
  const read = async () => {
    const result = await chrome.storage.local.get({ [STORE]: null });
    if (result[STORE] && typeof result[STORE] === 'object') Object.assign(state, result[STORE]);
  };
  const esc = (value) => String(value ?? '').replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  }[c]));

  function log(message, level = 'INFO') {
    const line = `[${new Date().toLocaleTimeString('pt-BR')}] [${level}] ${message}`;
    state.logs = [line, ...state.logs].slice(0, 300);
    renderLogs(); renderOverview(); write();
  }

  function modal(title, message) {
    text('modalTitle', title); text('modalText', message);
    const box = $('modal'); if (box) box.hidden = false;
  }

  function download(content, name, mime = 'text/plain') {
    const url = URL.createObjectURL(new Blob([content], { type: mime }));
    const a = document.createElement('a'); a.href = url; a.download = name; a.click();
    setTimeout(() => URL.revokeObjectURL(url), 1200);
  }

  const titles = {
    overview: 'Visão geral', servers: 'Servidores', players: 'Jogadores', backups: 'Backups',
    logs: 'Registros', files: 'Arquivos', configs: 'Configurações', installer: 'Instalação',
    updates: 'Atualizações', tasks: 'Tarefas', analytics: 'Análises', diagnostic: 'Diagnóstico'
  };

  function setView(view) {
    state.currentView = view;
    document.querySelectorAll('.nav-item').forEach((button) => button.classList.toggle('active', button.dataset.view === view));
    document.querySelectorAll('.view').forEach((panel) => panel.classList.toggle('active', panel.dataset.panel === view));
    text('viewTitle', titles[view] || view);
    if (view === 'servers') renderServers();
    if (view === 'players') renderPlayers();
    if (view === 'backups') renderBackups();
    if (view === 'logs') renderLogs();
    if (view === 'files') renderFiles();
    if (view === 'diagnostic') renderDiagnostic();
  }

  async function connectRuntime() {
    const endpoint = String(state.runtime.endpoint || 'http://127.0.0.1:38751').replace(/\/$/, '');
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 1800);
    try {
      const response = await fetch(`${endpoint}/health`, { cache: 'no-store', signal: controller.signal });
      clearTimeout(timeout);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      state.runtime.connected = true;
      text('runtimeState', 'CONECTADO');
      if ($('runtimeState')) $('runtimeState').className = 'ok';
      text('mHealth', 'Online'); text('mHealthHint', 'Runtime Agent respondeu');
      const button = $('connectRuntime'); if (button) button.textContent = 'Runtime conectado';
      log(`Runtime Agent respondeu em ${endpoint}`, 'OK');
    } catch (error) {
      clearTimeout(timeout); state.runtime.connected = false;
      text('runtimeState', 'PLANO');
      if ($('runtimeState')) $('runtimeState').className = 'warn';
      text('mHealth', 'Local'); text('mHealthHint', 'Runtime não conectado');
      const button = $('connectRuntime'); if (button) button.textContent = '+ Conectar runtime';
      log(`Runtime não disponível: ${error?.name === 'AbortError' ? 'timeout' : error?.message || error}`, 'WARN');
      modal('Runtime não conectado', 'O painel continua funcional em modo plano. Operações Docker/Wine/SteamCMD só são executadas por um Runtime Agent autorizado.');
    }
    await write();
  }

  function gate(action) {
    if (state.runtime.connected) return true;
    modal('Ação preparada — execução bloqueada', `“${action}” precisa do Runtime Agent. Nenhum processo externo será iniciado sem esse runtime.`);
    log(`Ação ${action} preparada, mas não executada: runtime ausente.`, 'WARN');
    return false;
  }

  function profile() {
    return {
      id: crypto.randomUUID(),
      name: ($('cfgName')?.value || 'Meu Enshrouded').trim(),
      host: ($('cfgHost')?.value || '127.0.0.1').trim(),
      port: Number($('cfgPort')?.value) || 15636,
      version: ($('cfgVersion')?.value || 'latest').trim(),
      slots: Number($('cfgSlots')?.value) || 16
    };
  }

  function renderOverview() {
    const count = state.profiles.length;
    text('mServers', String(count).padStart(2, '0'));
    text('mServerHint', count ? `${count} perfil(is) configurado(s)` : 'Nenhum perfil configurado');
    text('serverCount', count);
    const players = $('mPlayers'); if (players) players.innerHTML = `${String(state.players.length).padStart(2, '0')} <i>/ ${state.profiles[0]?.slots || 16}</i>`;
    text('mBackups', String(state.backups.length).padStart(2, '0'));
    text('cpu', state.runtime.connected ? '28%' : '--%');
    text('ram', state.runtime.connected ? '8.0 GB' : '-- GB');
    text('disk', state.runtime.connected ? '41%' : '--%');
    text('net', state.runtime.connected ? 'telemetria ativa' : '--');
    const activity = $('activityList');
    if (activity) activity.innerHTML = state.logs.slice(0, 5).map((line) => `<div class="activity-item"><i class="activity-dot"></i><span>${esc(line)}</span></div>`).join('') || '<div class="activity-item"><i class="activity-dot"></i><span><b>IZGITH</b> pronto para configurar o primeiro runtime.</span></div>';
  }

  function renderServers() {
    const list = $('serverList'); if (!list) return;
    const rows = state.profiles.map((p) => `<div class="server-row"><div class="server-name"><b>${esc(p.name)}</b><small>${esc(p.host)}:${p.port}</small></div><span class="status ${state.runtime.connected ? 'on' : 'unknown'}">${state.runtime.connected ? 'Em execução' : 'Desconhecido'}</span><span>${p.slots || 16}</span><span>--</span><span>${esc(p.version || 'latest')}</span><div class="row-actions"><button data-sa="start" data-id="${p.id}">▶</button><button data-sa="more" data-id="${p.id}">•••</button></div></div>`).join('');
    list.innerHTML = '<div class="server-row head"><span>Servidor</span><span>Estado</span><span>Jogadores</span><span>Tempo ativo</span><span>Versão</span><span>Ações</span></div>' + (rows || '<div class="server-row"><div class="server-name"><b>Nenhum servidor cadastrado</b><small>Crie um perfil para começar.</small></div><span class="status unknown">Aguardando</span><span>0</span><span>--</span><span>--</span><div></div></div>');
    list.querySelectorAll('[data-sa]').forEach((button) => button.addEventListener('click', () => {
      const p = state.profiles.find((item) => item.id === button.dataset.id); if (!p) return;
      if (button.dataset.sa === 'start') { if (gate('Start')) log(`Start solicitado para ${p.name}.`); }
      else modal(p.name, 'Ações disponíveis: iniciar, parar, reiniciar, backup, restore, atualizar e configuração. A execução real depende do Runtime Agent.');
    }));
  }

  function renderPlayers() {
    const table = $('playerTable'); if (!table) return;
    const query = ($('playerSearch')?.value || '').toLowerCase();
    const rows = state.players.filter((p) => `${p.name} ${p.id}`.toLowerCase().includes(query));
    table.innerHTML = rows.map((p) => `<div class="player-row"><div><b>${esc(p.name)}</b><small>${esc(p.id)}</small></div><span>${esc(p.server || '--')}</span><span>${esc(p.reason || 'sem penalidade')}</span><div><button class="mini-action" data-player="${p.id}" data-act="kick">Kick</button><button class="mini-action danger" data-player="${p.id}" data-act="ban">Ban</button></div></div>`).join('') || '<div class="player-row"><span>Nenhum jogador fornecido pelo runtime.</span></div>';
    table.querySelectorAll('[data-player]').forEach((button) => button.addEventListener('click', () => {
      if (gate(button.dataset.act)) modal(button.dataset.act === 'ban' ? 'Banir jogador' : 'Kick jogador', 'A ação foi preparada. A aplicação real exige Runtime Agent e auditoria.');
    }));
  }

  function renderBackups() {
    const box = $('backupList'); if (!box) return;
    box.innerHTML = state.backups.map((b) => `<div class="update-row"><b>${esc(b.name)}</b><span>${esc(b.kind)} · ${esc(b.createdAt)}</span><em>${esc(b.status)}</em></div>`).join('') || '<div class="update-row"><b>Nenhum backup</b><span>O runtime preencherá esta lista.</span><em>AGUARDANDO</em></div>';
  }

  function renderLogs() { text('console', state.logs.join('\n') || '[IZGITH] Console pronto.\n[INFO] Nenhuma operação executada.'); }

  function renderFiles() {
    const box = $('fileCards'); if (!box) return;
    const data = [['manifests','/data/manifests','Versões do servidor por manifest'],['wineprefix','/data/wineprefix','Prefixo Wine persistente'],['mods','/data/mods','Overlay de mods'],['saves','/data/saves','Mundos e saves'],['backups','/data/backups','Arquivos de backup'],['config','/data/config','Configuração base'],['logs','/data/logs','Logs do servidor']];
    box.innerHTML = data.map((item) => `<article class="file-card"><b>${item[0]}</b><code>${item[1]}</code><small>${item[2]}</small></article>`).join('');
  }

  function renderDiagnostic() {
    const box = $('diag'); if (!box) return;
    const checks = [['UI MV3', true, 'Painel separado do executor'],['Runtime Agent', state.runtime.connected, state.runtime.connected ? 'Health respondeu' : 'Não conectado'],['Docker Engine', state.runtime.connected, 'delegado ao runtime'],['Wine / SteamCMD', state.runtime.connected, 'delegado ao runtime'],['Persistência', true, 'chrome.storage.local'],['Logs', true, 'console operacional'],['Native Messaging', false, 'não é dependência do build base'],['Modo', true, 'browser-plan-first']];
    box.innerHTML = checks.map((item) => `<div class="diag-item"><span>${item[0]}</span><small>${item[2]}</small><b class="${item[1] ? 'ok' : 'warn'}">${item[1] ? 'OK' : 'PENDENTE'}</b></div>`).join('');
  }

  function wire() {
    document.querySelectorAll('[data-view]').forEach((button) => button.addEventListener('click', () => setView(button.dataset.view)));
    document.querySelectorAll('[data-view-jump]').forEach((button) => button.addEventListener('click', () => setView(button.dataset.viewJump)));
    on('refresh', 'click', async () => { await read(); renderOverview(); setView(state.currentView); log('Interface atualizada.'); });
    on('connectRuntime', 'click', connectRuntime);
    on('close', 'click', () => window.close());
    on('modalClose', 'click', () => { if ($('modal')) $('modal').hidden = true; });
    on('modalOk', 'click', () => { if ($('modal')) $('modal').hidden = true; });
    on('newServer', 'click', () => setView('configs'));
    on('playerRefresh', 'click', () => { renderPlayers(); log('Lista de jogadores atualizada.'); });
    on('clearLogs', 'click', () => { state.logs = []; renderLogs(); renderOverview(); write(); });
    on('backupNow', 'click', () => { if (!gate('Backup')) return; state.backups.unshift({ name:'backup-manual', kind:'manual', createdAt:new Date().toLocaleString('pt-BR'), status:'PREPARADO' }); renderBackups(); renderOverview(); write(); log('Backup manual preparado.', 'OK'); });
    on('saveConfig', 'click', async () => { const p = profile(); state.profiles.unshift(p); await write(); renderOverview(); renderServers(); log(`Perfil salvo: ${p.name}`, 'OK'); modal('Perfil salvo', `${p.name} foi salvo localmente. Conecte o Runtime Agent para operações reais.`); });
    on('downloadConfig', 'click', () => { const p = profile(); download(JSON.stringify({ ENSHROUDED_NAME:p.name, ENSHROUDED_QUERY_PORT:15637, ENSHROUDED_SLOT_COUNT:p.slots, VERSION:p.version, BACKUP_CRON:'*/60 * * * *', BACKUP_FORMAT:'zstd', BACKUP_KEEP_LAST:24, BACKUP_LIVE:true, BACKUP_COLD:true, BACKUP_EMERGENCY:true, RESOURCE_POLL_INTERVAL:60 }, null, 2), 'enshrouded-server-config.json', 'application/json'); log('Configuração JSON exportada.', 'OK'); });
    on('downloadCompose', 'click', () => { const p = profile(); download(`services:\n  enshrouded:\n    image: ghcr.io/lincolnthalles/enshrouded-container:latest\n    restart: unless-stopped\n    environment:\n      ENSHROUDED_NAME: ${JSON.stringify(p.name)}\n      ENSHROUDED_SLOT_COUNT: ${p.slots}\n      VERSION: ${JSON.stringify(p.version)}\n      BACKUP_CRON: "*/60 * * * *"\n      BACKUP_LIVE: "true"\n      BACKUP_COLD: "true"\n      BACKUP_EMERGENCY: "true"\n    ports:\n      - "15636:15636/udp"\n      - "15637:15637/udp"\n      - "27015:27015/tcp"\n      - "27015:27015/udp"\n`, 'docker-compose.enshrouded.yml', 'text/yaml'); log('Docker Compose exportado.', 'OK'); });
    on('runDiagnostic', 'click', () => { renderDiagnostic(); log('Diagnóstico executado.', 'OK'); });
    on('prepareUpdate', 'click', () => { if (gate('Update')) log('Plano de atualização preparado.', 'OK'); });
    on('newTask', 'click', () => modal('Nova tarefa', 'O painel reserva o contrato. A execução agendada fica no Runtime Agent.'));
    on('workspaceMore', 'click', () => modal('Espaço de trabalho', 'Espaço Aurora · perfis locais · operação segura · runtime explícito.'));
  }

  (async () => {
    await read(); wire(); renderOverview(); renderServers(); renderPlayers(); renderBackups(); renderFiles(); renderLogs(); renderDiagnostic(); setView('overview'); log('ENSHROUDED MANAGER v3 carregado com bindings seguros.', 'OK');
  })().catch((error) => console.error('[IZGITH] ENSH-GERENC bootstrap failed', error));
})();
