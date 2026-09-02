const el=(id)=>document.getElementById(id);let selected=null;
el('btnDownload').onclick=()=>{alert('Download simulado')};
el('btnPickAny').onclick=()=>{selected='samples/webextensions-examples-main.zip';el('picked').textContent=selected;el('btnInstall').disabled=false;el('scoreText').textContent='92';el('checks').textContent='Permissão tabs (risco 15)'};
el('btnInstall').onclick=()=>{if(selected) alert('Instalando '+selected)};
const dz=el('dropzone');dz.addEventListener('dragover',e=>{e.preventDefault();dz.style.borderColor='#6aa6ff'});
dz.addEventListener('dragleave',e=>{dz.style.borderColor='#2a354a'});dz.addEventListener('drop',e=>{e.preventDefault();alert('Drop detectado')});