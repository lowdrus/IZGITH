(() => {
  'use strict';
  const BUTTON_ID = 'izgith-convgpt-export';
  const MENU_ID = 'izgith-convgpt-menu';
  const FORMATS = ['pdf','doc','txt','md','json','xls'];
  const clean = value => String(value || '').replace(/\u00a0/g, ' ').trim();
  const safeName = value => clean(value).replace(/[\\/:*?"<>|]+/g, '_').slice(0, 90) || 'conversa-chatgpt';
  const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

  function collect() {
    const nodes = [...document.querySelectorAll('[data-message-author-role]')];
    const messages = nodes.map((node, index) => ({
      index: index + 1,
      role: node.getAttribute('data-message-author-role') || 'unknown',
      text: clean(node.innerText)
    })).filter(message => message.text);
    return {
      schema: 'izgith.convgpt.v2',
      title: clean(document.querySelector('h1')?.innerText || document.title.replace(/\s*[-|]\s*ChatGPT.*$/i, '')),
      url: location.href,
      exportedAt: new Date().toISOString(),
      messageCount: messages.length,
      messages
    };
  }

  async function collectCurrentConversation() {
    const previousY = window.scrollY;
    let last = -1, stable = 0;
    for (let i = 0; i < 24; i++) {
      const count = document.querySelectorAll('[data-message-author-role]').length;
      if (count === last) stable++; else stable = 0;
      last = count;
      window.scrollTo(0, document.body.scrollHeight);
      await sleep(180);
      window.scrollTo(0, 0);
      await sleep(180);
      if (stable >= 2) break;
    }
    const data = collect();
    window.scrollTo(0, previousY);
    return data;
  }

  function markdown(data) {
    const body = data.messages.map(item => `## ${item.index}. ${item.role}\n\n${item.text}`).join('\n\n---\n\n');
    return `# ${data.title || 'Conversa ChatGPT'}\n\n- URL: ${data.url}\n- Exportado: ${data.exportedAt}\n- Mensagens: ${data.messageCount}\n\n${body}\n`;
  }

  function text(data) {
    return data.messages.map(item => `[${item.index}] ${item.role}\n${item.text}`).join('\n\n' + '='.repeat(72) + '\n\n') + '\n';
  }

  function html(data) {
    const esc = value => String(value).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
    const body = data.messages.map(item => `<article><h2>${item.index}. ${esc(item.role)}</h2><pre>${esc(item.text)}</pre></article>`).join('');
    return `<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>${esc(data.title)}</title><style>body{font-family:Arial,sans-serif;margin:40px;line-height:1.45}article{break-inside:avoid;border-bottom:1px solid #ccc;padding:12px 0}pre{white-space:pre-wrap;font:inherit}h1{font-size:22px}h2{font-size:16px}</style></head><body><h1>${esc(data.title || 'Conversa ChatGPT')}</h1><p>${data.messageCount} mensagens · ${esc(data.exportedAt)}</p>${body}</body></html>`;
  }

  function pdfBytes(data) {
    const normalize = value => String(value).normalize('NFKD').replace(/[\u0300-\u036f]/g,'').replace(/[^\x20-\x7E\xA0-\xFF]/g,'?');
    const escape = value => normalize(value).replace(/\\/g,'\\\\').replace(/\(/g,'\\(').replace(/\)/g,'\\)');
    const lines = [`${data.title || 'Conversa ChatGPT'}`, `URL: ${data.url}`, `Exportado: ${data.exportedAt}`, `Mensagens: ${data.messageCount}`, ''];
    for (const item of data.messages) {
      lines.push(`${item.index}. ${item.role}`);
      for (const raw of String(item.text).split(/\r?\n/)) {
        let s = raw || ' ';
        while (s.length > 92) { lines.push(s.slice(0,92)); s = s.slice(92); }
        lines.push(s);
      }
      lines.push('');
    }
    const pages = [];
    for (let i=0;i<lines.length;i+=52) pages.push(lines.slice(i,i+52));
    const objects = [
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [' + pages.map((_,i)=>`${4+i*2} 0 R`).join(' ') + `] /Count ${pages.length} >>`,
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>'
    ];
    for (let i=0;i<pages.length;i++) {
      const pageObj = 4 + i*2;
      const contentObj = 5 + i*2;
      const content = ['BT','/F1 9 Tf','12 TL','50 750 Td',...pages[i].map((line,n)=>`(${escape(line)}) Tj ${n===pages[i].length-1?'':'T*'}`),'ET'].join('\n');
      objects[pageObj-1] = `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 3 0 R >> >> /Contents ${contentObj} 0 R >>`;
      objects[contentObj-1] = `<< /Length ${content.length} >>\nstream\n${content}\nendstream`;
    }
    let pdf = '%PDF-1.4\n%\xFF\xFF\n';
    const offsets = [0];
    for (let i=0;i<objects.length;i++) { offsets[i+1]=pdf.length; pdf += `${i+1} 0 obj\n${objects[i]}\nendobj\n`; }
    const xref = pdf.length;
    pdf += `xref\n0 ${objects.length+1}\n0000000000 65535 f \n`;
    for (let i=1;i<offsets.length;i++) pdf += `${String(offsets[i]).padStart(10,'0')} 00000 n \n`;
    pdf += `trailer\n<< /Size ${objects.length+1} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF`;
    return new TextEncoder().encode(pdf);
  }

  function excel(data) {
    const esc = value => String(value).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
    const rows = data.messages.map(item => `<Row><Cell><Data ss:Type="Number">${item.index}</Data></Cell><Cell><Data ss:Type="String">${esc(item.role)}</Data></Cell><Cell><Data ss:Type="String">${esc(item.text)}</Data></Cell></Row>`).join('');
    return `<?xml version="1.0"?><Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"><Worksheet ss:Name="Conversa"><Table><Row><Cell><Data ss:Type="String">Indice</Data></Cell><Cell><Data ss:Type="String">Papel</Data></Cell><Cell><Data ss:Type="String">Mensagem</Data></Cell></Row>${rows}</Table></Worksheet></Workbook>`;
  }

  function download(name, content, type) {
    const blob = new Blob([content], {type});
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a'); link.href = url; link.download = name; link.click();
    setTimeout(() => URL.revokeObjectURL(url), 2000);
  }

  function exportOne(data, format) {
    const base = safeName(data.title);
    if (format === 'md') return download(`${base}.md`, markdown(data), 'text/markdown;charset=utf-8');
    if (format === 'txt') return download(`${base}.txt`, text(data), 'text/plain;charset=utf-8');
    if (format === 'json') return download(`${base}.json`, JSON.stringify(data, null, 2), 'application/json;charset=utf-8');
    if (format === 'doc') return download(`${base}.doc`, html(data), 'application/msword;charset=utf-8');
    if (format === 'xls') return download(`${base}.xls`, excel(data), 'application/vnd.ms-excel;charset=utf-8');
    if (format === 'pdf') return download(`${base}.pdf`, pdfBytes(data), 'application/pdf');
    throw new Error(`Formato não suportado: ${format}`);
  }

  async function exportConversation(format = 'all') {
    const button = document.getElementById(BUTTON_ID);
    if (button) { button.disabled = true; button.textContent = 'Exportando…'; }
    try {
      const data = await collectCurrentConversation();
      if (!data.messages.length) throw new Error('Nenhuma mensagem carregada nesta conversa.');
      for (const item of (format === 'all' ? FORMATS : [format])) exportOne(data, item);
      if (button) button.textContent = `CONVGPT ✓ ${data.messageCount} mensagens`;
    } catch (error) {
      if (button) button.textContent = `CONVGPT: ${error.message}`;
      console.error('[IZGITH CONVGPT]', error);
    } finally {
      setTimeout(() => { if (button) { button.disabled = false; button.textContent = 'Baixar conversa · CONVGPT'; } }, 3500);
    }
  }

  function mount() {
    if (document.getElementById(BUTTON_ID)) return;
    const wrap = document.createElement('div'); wrap.id = MENU_ID;
    const button = document.createElement('button'); button.id = BUTTON_ID; button.type = 'button'; button.textContent = 'Baixar conversa · CONVGPT';
    const menu = document.createElement('div'); menu.hidden = true;
    for (const format of [...FORMATS, 'all']) {
      const item = document.createElement('button'); item.type='button'; item.dataset.format=format; item.textContent = format === 'all' ? 'Baixar todos os formatos' : `Baixar .${format}`;
      item.addEventListener('click', () => { menu.hidden = true; exportConversation(format); }); menu.appendChild(item);
    }
    button.addEventListener('click', () => { menu.hidden = !menu.hidden; });
    wrap.append(button, menu); document.body.appendChild(wrap);
  }
  mount(); new MutationObserver(mount).observe(document.documentElement, {childList:true,subtree:true});
})();
