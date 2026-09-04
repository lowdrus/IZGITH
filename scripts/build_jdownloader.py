"""Gera o módulo a partir das fontes preservadas do RAR, sem executar as fontes."""
from pathlib import Path
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'MYJDOWNLOADER'
TARGET = ROOT / 'extension/modules/jdownloader'
PREFIX = 'modules/jdownloader/'
FOLDERS = {'vendor', 'styles', 'images', 'scripts', 'contentscripts', 'partials'}
FILES = {'background.js', 'offscreen.js', 'offscreen.html', 'popup.html', 'toolbar.html',
         'loginNeeded.html', 'autograbber-indicator.html', 'buildMeta.json', 'LICENSE'}


def build():
    for source in SOURCE.rglob('*'):
        if not source.is_file():
            continue
        relative = source.relative_to(SOURCE)
        if relative.parts[0] not in FOLDERS and str(relative) not in FILES:
            continue
        if '__tests__' in relative.parts or 'dev' in relative.parts or source.name.endswith('.test.js'):
            continue
        destination = TARGET / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        if source.suffix not in {'.js', '.html'} or relative.parts[0] == 'vendor':
            shutil.copyfile(source, destination)
            continue
        text = source.read_text('utf-8')
        text = re.sub(r'(\.getURL\(\s*)([\'\"])([^\'\"]+)\2',
                      lambda m: m[1] + m[2] + PREFIX + m[3].replace('../', '') + m[2], text)
        text = text.replace('/images/', '/' + PREFIX + 'images/')
        text = text.replace("files: ['contentscripts/toolbarContentscript.js']", "files: ['modules/jdownloader/contentscripts/toolbarContentscript.js']")
        if source.name == 'background.js':
            text = text.replace("let offscreenDocumentPath = 'offscreen.html';", "let offscreenDocumentPath = 'modules/jdownloader/offscreen.html';")
            text = text.replace("chrome.storage.session.setAccessLevel({ accessLevel: 'TRUSTED_AND_UNTRUSTED_CONTEXTS' });", "// Sessões de publicação não são expostas aos content scripts.")
            text = text.replace('https://api.github.com/repos/magnetgrouplabs/myjdownloader-extension-mv3/releases/latest', 'https://api.github.com/repos/lowdrus/IZGITH/releases/latest')
            text = text.replace('https://github.com/magnetgrouplabs/myjdownloader-extension-mv3/releases/latest', 'https://github.com/lowdrus/IZGITH/releases/latest')
            text = text.replace('?? true;', '?? false;')
            text = text.replace('let text = state.isConnected ? "" : "!";', 'let text = ""; // módulo opcional não altera a saúde global do IZGITH')
            marker = ' const action = request.action;'
            gate = '''
 const trustedPage = (sender.url || '').startsWith(chrome.runtime.getURL('modules/jdownloader/'));
 const contentActions = new Set(['wake','tab-contentscript-injected','cnl-captured','is-active-on-tab','new-selection','selection-result','captcha-tab-detected','captcha-solved','captcha-skip','captcha-can-close','myjd-captcha-execute','myjd-get-captcha-job']);
 if (!trustedPage && !contentActions.has(request.action)) return false;
 if (request.action === 'myjd-get-captcha-job') {
  const active = sender.tab && activeCaptchaTabs[sender.tab.id];
  if (!active) { sendResponse({}); return false; }
  chrome.storage.session.get('myjd_captcha_job').then(result => {
   const job = result.myjd_captcha_job;
   sendResponse(job && job.captchaId === active.captchaId ? {myjd_captcha_job:job} : {});
  }).catch(() => sendResponse({}));
  return true;
 }
 if (request.data && request.data.callbackUrl && request.data.callbackUrl !== 'MYJD') {
  try {
   const callback = new URL(request.data.callbackUrl);
   if (callback.protocol !== 'http:' || !['localhost','127.0.0.1'].includes(callback.hostname) || callback.port !== '9666' || callback.username || callback.password) throw new Error('Callback não autorizado.');
  } catch (error) { sendResponse({error:'Callback não autorizado.'}); return false; }
 }
'''
            if marker not in text:
                raise ValueError('Contrato do worker MyJDownloader mudou; reveja o adaptador.')
            text = text.replace(marker, gate + marker)
            text = text.replace('initSettings();\nconsole.log', 'initSettings().catch(error => console.error("JDOWNLOADER:", error));\nconsole.log')
            text = '/* Adaptado para IZGITH; fonte e licença em MYJDOWNLOADER. */\n(() => {\n' + text + '\n})();\n'
        if source.name == 'offscreen.js':
            text = text.replace("if (!request || request.target !== 'offscreen') {", "if (!request || request.target !== 'offscreen' || sender.id !== chrome.runtime.id || sender.tab || (sender.url && sender.url !== chrome.runtime.getURL('sw.js'))) {")
        if source.name == 'myjdCaptchaSolver.js':
            text = text.replace("chrome.storage.session.get('myjd_captcha_job', function(result)", "chrome.runtime.sendMessage({action:'myjd-get-captcha-job'}, function(result)")
        if source.name == 'popup.html':
            text = text.replace('<title>MyJDownloader</title>', '<title>IZGITH — JDOWNLOADER</title>')
            text = text.replace('<meta charset="utf-8">', '<meta charset="utf-8"><link rel="stylesheet" href="../../ui/modules.css"><script src="../../scripts/notifications.js"></script>')
        if source.name == 'autograbber-indicator.html':
            text = '<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>IZGITH — captura</title><body><p>JDOWNLOADER: confira os links no painel antes de enviar.</p><a href="popup.html" target="_blank">Abrir JDOWNLOADER</a></body></html>'
        destination.write_text('\n'.join(line.rstrip() for line in text.splitlines()).rstrip()+'\n', encoding='utf-8')
    original = json.loads((SOURCE / 'manifest.json').read_text('utf-8'))
    configs = []
    for i, item in enumerate(original['content_scripts']):
        # selectionContentscript.js está vazio no RAR: não fingir que seleciona texto.
        if any((SOURCE / p).stat().st_size == 0 for p in item['js']):
            continue
        configs.append({'id': f'izgith-jd-{i}', 'matches': item['matches'],
                        'js': [PREFIX + p for p in item['js']],
                        'allFrames': item.get('all_frames', False),
                        'runAt': item['run_at'], 'world': item.get('world', 'ISOLATED'),
                        'persistAcrossSessions': True})
    (TARGET / 'content-scripts.json').write_text(json.dumps(configs, indent=2) + '\n', encoding='utf-8')
    for locale in ('en', 'ptBR', 'de', 'es'):
        destination = ROOT / 'extension/_locales' / ('pt_BR' if locale == 'ptBR' else locale) / 'messages.json'
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(SOURCE / '_locales' / locale / 'messages.json', destination)
    print('JDOWNLOADER: fontes copiadas, caminhos adaptados e identidade IZGITH preservada.')


if __name__ == '__main__':
    build()
