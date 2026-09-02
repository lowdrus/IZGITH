const $ = (id) => document.getElementById(id);
const state = {
  files: []
};

function setStatus(message, type = 'neutral') {
  const el = $('status');
  el.textContent = message;
  el.className = `status ${type}`;
}

function renderQueue() {
  const queue = $('queue');
  $('count').textContent = String(state.files.length);
  if (!state.files.length) {
    queue.className = 'queue empty';
    queue.textContent = 'Nenhum pacote selecionado.';
    $('score').textContent = '—';
    return;
  }
  queue.className = 'queue';
  queue.replaceChildren(...state.files.map(file => {
    const row = document.createElement('div');
    row.className = 'queue-item';
    const name = document.createElement('span');
    name.textContent = file.name;
    const size = document.createElement('small');
    size.textContent = `${(file.size/1024).toFixed(1)} KB`;
    row.append(name, size);
    return row;
  }));
  const supported = state.files.filter(f => /\.(zip|crx)$/i.test(f.name)).length;
  $('score').textContent = `${supported}/${state.files.length}`;
  setStatus(supported === state.files.length ? 'Pacotes reconhecidos' : 'Há arquivos não suportados', supported === state.files.length ? 'ok' : 'warn');
}

function addFiles(fileList) {
  const incoming = Array.from(fileList || []);
  const seen = new Set(state.files.map(f => `${f.name}:${f.size}:${f.lastModified}`));
  for (const file of incoming) {
    const key = `${file.name}:${file.size}:${file.lastModified}`;
    if (!seen.has(key)) {
      state.files.push(file);
      seen.add(key);
    }
  }
  renderQueue();
}
$('btnDownload').addEventListener('click', async () => {
  const raw = $('url').value.trim();
  let url;
  try {
    url = new URL(raw);
    if (!['http:', 'https:'].includes(url.protocol)) throw new Error('protocol');
  } catch {
    setStatus('Informe um link HTTP/HTTPS válido', 'error');
    return;
  }
  setStatus('Abrindo “Salvar como…”', 'busy');
  try {
    const id = await chrome.downloads.download({
      url: url.href,
      saveAs: true
    });
    setStatus(`Download iniciado (#${id})`, 'ok');
  } catch (error) {
    setStatus(`Falha no download: ${error.message}`, 'error');
  }
});
$('btnPick').addEventListener('click', () => $('packages').click());
$('packages').addEventListener('change', e => addFiles(e.target.files));
const dz = $('dropzone');
for (const name of ['dragenter', 'dragover']) dz.addEventListener(name, e => {
  e.preventDefault();
  dz.classList.add('active');
});
for (const name of ['dragleave', 'drop']) dz.addEventListener(name, e => {
  e.preventDefault();
  dz.classList.remove('active');
});
dz.addEventListener('drop', e => addFiles(e.dataTransfer.files));
dz.addEventListener('keydown', e => {
  if (e.key === 'Enter' || e.key === ' ') $('packages').click();
});
$('openDashboard').addEventListener('click', () => chrome.tabs.create({
  url: chrome.runtime.getURL('ui/dashboard.html')
}));
$('btnGuide').addEventListener('click', async () => {
  await chrome.storage.local.set({
    izgithQueue: state.files.map(({
      name,
      size,
      lastModified
    }) => ({
      name,
      size,
      lastModified
    }))
  });
  chrome.tabs.create({
    url: chrome.runtime.getURL('ui/dashboard.html#install')
  });
});
renderQueue();
