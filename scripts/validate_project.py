#!/usr/bin/env python3
from __future__ import annotations
import json,re,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; EXT=ROOT/'extension'; checks=[]
def check(label,condition,detail=''):
    ok=bool(condition);checks.append(ok);print(f'[{len(checks):02d}] {label:.<34} {"OK" if ok else "FALHA"} {detail}')
    if not ok: raise SystemExit(1)
def read_json(path):
    try:return json.loads(path.read_text(encoding='utf-8'))
    except Exception as exc: print(f'JSON parse {path}: {exc}');return None
def main():
    check('pasta raiz',ROOT.is_dir());mp=EXT/'manifest.json';check('manifest.json',mp.is_file());m=read_json(mp);check('JSON Manifest V3 válido',isinstance(m,dict) and m.get('manifest_version')==3)
    worker_rel=m.get('background',{}).get('service_worker') if isinstance(m,dict) else None;check('background/service worker declarado',isinstance(worker_rel,str) and worker_rel);worker=EXT/worker_rel if worker_rel else EXT/'missing';check('background/service worker existe',worker.is_file());check('service worker nao vazio',worker.is_file() and worker.stat().st_size>0)
    js=list(EXT.rglob('*.js'))
    try: node=subprocess.run(['node','--version'],capture_output=True,text=True,timeout=10)
    except Exception: node=None
    if js and node and node.returncode==0: check('JavaScript syntax',all(subprocess.run(['node','--check',str(p)],capture_output=True).returncode==0 for p in js))
    else: check('JavaScript encontrado',bool(js))
    html=list(EXT.rglob('*.html'));css=list(EXT.rglob('*.css'));check('HTML',bool(html));check('CSS',bool(css) and all((lambda t:t.count('{')==t.count('}'))(p.read_text(encoding='utf-8')) for p in css))
    for size in (16,32,48,128): check(f'icon{size}.png',(EXT/f'assets/icons/icon{size}.png').is_file() and (EXT/f'assets/icons/icon{size}.png').stat().st_size>0)
    refs=[m.get('action',{}).get('default_popup',''),worker_rel or '',*m.get('icons',{}).values()];check('referências de arquivos',all((EXT/x).is_file() for x in refs if x))
    themes=read_json(EXT/'themes/catalog.json');families=themes.get('families',{}) if isinstance(themes,dict) else {};check('36 temas',isinstance(themes,dict) and themes.get('total')==36 and sum(map(len,families.values()))==36)
    dash=(EXT/'ui/dashboard.html').read_text(encoding='utf-8');check('EULA','EULA' in dash or (ROOT/'docs/EULA.md').is_file());check('Guia Rápido','Guia Rápido' in dash or (ROOT/'docs/GUIA_RAPIDO.md').is_file())
    check('SONPEF',(ROOT/'integrations/SONPEF/integration.json').is_file());check('CONV-D',(ROOT/'integrations/CONV-D/integration.json').is_file());check('KIT_UNICO',(ROOT/'integrations/KIT_UNICO/integration.json').is_file())
    conv=EXT/'integrations/conv-d.js';ct=conv.read_text(encoding='utf-8') if conv.is_file() else '';wt=worker.read_text(encoding='utf-8')
    conv_required=['izgith.conv-d.v3','ChatGPT','Claude','Gemini','pdf','doc','txt','md','json','xls','Baixar Conversa','Tudo — início até o final','Rodada','SAVE_FILE']
    check('CONV-D export contract',all(x in ct for x in conv_required) and 'saveAs:true' in wt)
    registry=read_json(ROOT/'integrations/assistant_registry.json');names=[x.get('name') for x in registry.get('canonical_assistants',[]) if isinstance(x,dict)] if isinstance(registry,dict) else [];forbidden=('Ayelle','alias Ayella','Alias: Ayella');check('IA/assistentes',names==['Júlia','Ayella','IZART'] and not any(x in str(names) for x in forbidden))
    check('service worker sem alias proibido',not any(x in wt for x in forbidden));check('registry IA canônico',names==['Júlia','Ayella','IZART'] and registry.get('naming_policy',{}).get('ayella_is_alias') is False);check('registry sem aliases proibidos',not any(x in names for x in forbidden))
    mv=str(m.get('version',''));pv=str((read_json(ROOT/'package.json') or {}).get('version',''));mm=re.fullmatch(r'(\d+\.\d+\.\d+)\.(\d+)',mv);expected=f'{mm.group(1)}-{int(mm.group(2)):05d}' if mm else '';expected_registry=f'{mm.group(1)}.{int(mm.group(2)):05d}' if mm else '';check('versões sincronizadas',bool(mm) and pv==expected);check('versão registry sincronizada',registry.get('version')==expected_registry)
    perms=m.get('permissions',[]);check('baseline sem Native Messaging','nativeMessaging' not in perms);check('CONV-D sem botão abrir','Abrir CONV-D' not in dash and 'Abrir CONVGPT' not in dash and 'Abrir ChatGPT' not in dash);check('SONPEF autônomo','sonpefFiles' in dash and 'Selecionar scripts' in dash);check('IZART interativo','izartChat' in dash and 'izartSend' in dash)
    providers=read_json(ROOT/'integrations/CONV-D/integration.json').get('providers',[]);check('CONV-D providers',len(providers)>=10 and 'ChatGPT' in providers and 'Claude' in providers)
    print('BUILD PASS');return 0
if __name__=='__main__':raise SystemExit(main())
