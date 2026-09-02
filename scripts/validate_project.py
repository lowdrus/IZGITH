#!/usr/bin/env python3
from __future__ import annotations
import json,re,subprocess,sys,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; EXT=ROOT/'extension'; checks=[]
def check(label,condition,detail=''):
    ok=bool(condition);checks.append(ok);print(f'[{len(checks):02d}] {label:.<30} {"OK" if ok else "FALHA"} {detail}')
    if not ok: raise SystemExit(1)
def main():
    check('pasta raiz',ROOT.is_dir())
    mp=EXT/'manifest.json';check('manifest.json',mp.is_file())
    try:m=json.loads(mp.read_text('utf-8'));valid=True
    except Exception:valid=False;m={}
    check('JSON válido',valid and m.get('manifest_version')==3)
    worker=EXT/m.get('background',{}).get('service_worker','');check('background/service worker',worker.is_file())
    js=list(EXT.rglob('*.js'));ok=all(subprocess.run(['node','--check',str(p)],capture_output=True).returncode==0 for p in js);check('JavaScript syntax',ok)
    html=list(EXT.rglob('*.html'));check('HTML',html and all('<html' in p.read_text('utf-8').lower() for p in html))
    css=list(EXT.rglob('*.css'));check('CSS',css and all(p.read_text('utf-8').count('{')==p.read_text('utf-8').count('}') for p in css))
    for size in (16,32,48,128):check(f'icon{size}.png',(EXT/f'assets/icons/icon{size}.png').is_file())
    refs=[m.get('action',{}).get('default_popup',''),m.get('background',{}).get('service_worker',''),*m.get('icons',{}).values()];check('referências de arquivos',all(x and (EXT/x).is_file() for x in refs))
    themes=json.loads((EXT/'themes/catalog.json').read_text('utf-8'));check('36 temas',themes.get('total')==36 and sum(map(len,themes['families'].values()))==36)
    dash=(EXT/'ui/dashboard.html').read_text('utf-8');check('EULA','EULA' in dash or (ROOT/'docs/EULA.md').is_file())
    check('Guia Rápido','Guia Rápido' in dash or (ROOT/'docs/GUIA_RAPIDO.md').is_file())
    for name in ('SONPEF','CONVGPT','KIT_UNICO'):check(name,(ROOT/f'integrations/{name}/integration.json').is_file())
    assistants=(EXT/'scripts/assistants.js').read_text('utf-8');check('IA/assistentes',all(x in assistants for x in ('Júlia','Ayelle','Ayella','IZART')))
    subprocess.run([sys.executable,str(ROOT/'scripts/package_extension.py')],check=True,capture_output=True);zips=list((ROOT/'dist').glob('IZGITH_v*_FULL.zip'));check('pacote ZIP',zips and zipfile.is_zipfile(zips[-1]))
    package=json.loads((ROOT/'package.json').read_text('utf-8'))
    if package['version'].replace('-00039','.39')!=m['version']:raise SystemExit('Versões divergentes')
    print('BUILD PASS ✅');return 0
if __name__=='__main__':raise SystemExit(main())
