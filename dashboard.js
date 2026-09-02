const $ = (id) => document.getElementById(id);
const $$ = (selector) => Array.from(document.querySelectorAll(selector));

const THEMES = [
  ['cyber-neon','#071018','#0d1826cc','#5aa7ff','#9c6dff'],['cyber-aqua','#061519','#0b2025dd','#37e6d3','#4a8dff'],['cyber-rose','#170b17','#241126dd','#ff5bbd','#8f6cff'],['cyber-lime','#0b140a','#142113dd','#9cff57','#31d8a4'],['cyber-amber','#151008','#22180ddd','#ffb44a','#ff6c52'],['cyber-ice','#07131a','#0e2029dd','#67d8ff','#78a0ff'],['cyber-violet','#10091a','#1b102bdd','#b36cff','#5b8cff'],['cyber-red','#17080b','#270e15dd','#ff536e','#ff8c42'],['cyber-mono','#0a0d11','#121820dd','#d7e2ed','#70859c'],
  ['premium-dark','#0b0b0d','#17171add','#f4f4f5','#8b8b92'],['premium-blue','#0b1018','#141c28dd','#8bbcff','#526dff'],['premium-gold','#13100b','#201b12dd','#f2cf72','#b68a31'],['premium-silver','#111315','#1c2024dd','#d8e0e8','#7f96aa'],['premium-forest','#0b130f','#132019dd','#77d49d','#3f8865'],['premium-wine','#160b10','#24121add','#e986a7','#8f405c'],['premium-cocoa','#15100d','#231914dd','#d6a980','#8c6548'],['premium-navy','#08101b','#111d2ddd','#6fa4ea','#395a91'],['premium-pearl','#14171a','#20252bdd','#f6f8fa','#a8b3bf'],
  ['matrix-classic','#020b05','#05180bdd','#45ff79','#0ba34b'],['matrix-toxic','#071002','#101e05dd','#b3ff45','#63b80d'],['matrix-teal','#02100e','#061f1bdd','#42ffd4','#10a88a'],['matrix-blue','#020810','#061527dd','#45a6ff','#1b5ea4'],['matrix-purple','#090310','#180824dd','#c15cff','#6e20aa'],['matrix-red','#100203','#240608dd','#ff4e5d','#a71929'],['matrix-amber','#100b02','#241806dd','#ffc247','#b36e10'],['matrix-white','#090b0a','#151918dd','#e7fff0','#6e8b78'],['matrix-night','#010403','#07100cdd','#2bbd63','#174f31'],
  ['glass-ocean','#08131b','#12304799','#49c7ff','#4f72ff'],['glass-violet','#100b1b','#2b1b4699','#b984ff','#6e73ff'],['glass-sunset','#1a0e12','#4a203099','#ff8974','#d359ff'],['glass-mint','#071613','#153d3699','#61f0ca','#48a4d8'],['glass-ice','#0c141b','#21364799','#d0efff','#6ab7ff'],['glass-berry','#180a16','#43213d99','#ff80db','#9f65ff'],['glass-amber','#171007','#432e1599','#ffd06f','#ff864e'],['glass-lime','#0e1608','#2c411999','#b6f573','#51c995'],['glass-mono','#0e1114','#2a303699','#dbe7f2','#74889c']
];

const TITLES = {overview:'Visão geral',install:'Instalar',queue:'Fila',github:'GitHub Monitor',security:'Secure Lab',themes:'Temas',settings:'Configurações'};

function openTab(id) {
  $$('.tab').forEach((el) => el.classList.toggle('active', el.id === id));
  $$('.nav').forEach((el) => el.classList.toggle('active', el.dataset.tab === id));
  $('pageTitle').textContent = TITLES[id] || 'IZGITH';
  history.replaceState(null, '', `#${id}`);
}

$$('.nav').forEach((button) => button.addEventListener('click', () => openTab(button.dataset.tab)));

function applyTheme(name) {
  const theme = THEMES.find((item) => item[0] === name) || THEMES[0];
  const [, bg, panel, a, b] = theme;
  const root = document.documentElement;
  root.dataset.theme = name;
  root.style.setProperty('--bg', bg);
  root.style.setProperty('--panel', panel);
  root.style.setProperty('--a', a);
  root.style.setProperty('--b', b);
  $$('.theme').forEach((el) => el.classList.toggle('active', el.dataset.theme === name));
  chrome.storage.local.set({ theme: name });
}

function buildThemeGrid() {
  const nodes = THEMES.map(([name,, ,a,b]) => {
    const button = document.createElement('button');
    button.className = 'theme';
    button.dataset.theme = name;
    button.style.setProperty('--sw1', a);
    button.style.setProperty('--sw2', b);
    const swatch = document.createElement('i');
    const label = document.createElement('span');
    label.textContent = name.replaceAll('-', ' ');
    button.append(swatch, label);
    button.addEventListener('click', () => applyTheme(name));
    return button;
  });
  $('themeGrid').replaceChildren(...nodes);
}

async function renderQueue() {
  const { izgithQueue = [] } = await chrome.storage.local.get('izgithQueue');
  $('statQueue').textContent = String(izgithQueue.length);
  const target = $('dashboardQueue');
  if (!izgithQueue.length) {
    target.className = 'list muted';
    target.textContent = 'Fila vazia.';
    return;
  }
  target.className = 'list';
  target.replaceChildren(...izgithQueue.map((item) => {
    const row = document.createElement('div');
    row.className = 'list-item';
    row.textContent = `${item.name} · ${(item.size / 1024).toFixed(1)} KB`;
    return row;
  }));
}

$('clearQueue').addEventListener('click', async () => {
  await chrome.storage.local.set({ izgithQueue: [] });
  await renderQueue();
});

$('copyExtensionsUrl').addEventListener('click', async () => {
  await navigator.clipboard.writeText('chrome://extensions');
  $('copyExtensionsUrl').textContent = 'Copiado ✓';
  setTimeout(() => $('copyExtensionsUrl').textContent = 'Copiar chrome://extensions', 1400);
});

$('checkRepo').addEventListener('click', async () => {
  const repo = $('repoInput').value.trim();
  const target = $('repoResult');
  if (!/^[\w.-]+\/[\w.-]+$/.test(repo)) {
    target.textContent = 'Use o formato owner/repository.';
    return;
  }
  target.textContent = 'Consultando GitHub…';
  try {
    const response = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, { headers: { Accept: 'application/vnd.github+json' } });
    if (response.status === 404) throw new Error('Nenhuma release pública encontrada');
    if (!response.ok) throw new Error(`GitHub respondeu ${response.status}`);
    const data = await response.json();
    const published = data.published_at ? new Date(data.published_at).toLocaleString('pt-BR') : 'data desconhecida';
    target.textContent = `${data.tag_name || data.name || 'release'} · publicada em ${published}`;
  } catch (error) {
    target.textContent = `Falha: ${error.message}`;
  }
});

$('randomTheme').addEventListener('click', () => applyTheme(THEMES[Math.floor(Math.random() * THEMES.length)][0]));
$('autoMode').addEventListener('change', async (event) => {
  await chrome.storage.local.set({ autoMode: event.target.value });
  $('statMode').textContent = event.target.selectedOptions[0].textContent.replace('Auto com ', '');
});
$('performanceMode').addEventListener('change', async (event) => {
  const enabled = event.target.checked;
  document.body.classList.toggle('reduce-motion', enabled);
  await chrome.storage.local.set({ performanceMode: enabled });
});

document.addEventListener('pointermove', (event) => {
  const glow = $('cursorGlow');
  glow.style.left = `${event.clientX}px`;
  glow.style.top = `${event.clientY}px`;
  const hero = document.querySelector('.tilt');
  if (!hero || document.body.classList.contains('reduce-motion')) return;
  const rect = hero.getBoundingClientRect();
  const x = (event.clientX - rect.left) / rect.width - .5;
  const y = (event.clientY - rect.top) / rect.height - .5;
  hero.style.transform = `perspective(1000px) rotateX(${-y * 3}deg) rotateY(${x * 4}deg)`;
});

document.addEventListener('pointerleave', () => {
  const hero = document.querySelector('.tilt');
  if (hero) hero.style.transform = '';
});

(async function init() {
  buildThemeGrid();
  const settings = await chrome.storage.local.get(['theme','autoMode','performanceMode']);
  applyTheme(settings.theme || 'cyber-neon');
  $('autoMode').value = settings.autoMode || 'confirm';
  $('performanceMode').checked = Boolean(settings.performanceMode);
  document.body.classList.toggle('reduce-motion', Boolean(settings.performanceMode));
  $('statMode').textContent = $('autoMode').selectedOptions[0].textContent.replace('Auto com ', '');
  await renderQueue();
  openTab(location.hash.slice(1) in TITLES ? location.hash.slice(1) : 'overview');
})();
