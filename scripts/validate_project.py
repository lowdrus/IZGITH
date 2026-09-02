#!/usr/bin/env python3
from __future__ import annotations
import json, re, subprocess, sys, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXT = ROOT / 'extension'
checks = []

def check(label, condition, detail=''):
    ok = bool(condition)
    checks.append(ok)
    print(f'[{len(checks):02d}] {label:.<34} {"OK" if ok else "FALHA"} {detail}')
    if not ok:
        raise SystemExit(1)

def main():
    check('pasta raiz', ROOT.is_dir())
    mp = EXT / 'manifest.json'
    check('manifest.json', mp.is_file())
    try:
        m = json.loads(mp.read_text(encoding='utf-8'))
        valid = True
    except Exception as exc:
        valid = False
        m = {}
        print('manifest parse:', exc)
    check('JSON Manifest V3 válido', valid and m.get('manifest_version') == 3)

    worker_rel = m.get('background', {}).get('service_worker')
    check('background/service worker declarado', isinstance(worker_rel, str) and bool(worker_rel))
    worker = EXT / worker_rel if isinstance(worker_rel, str) else EXT / '__missing__'
    check('background/service worker existe', worker.is_file())
    if worker.is_file():
        check('service worker nao vazio', worker.stat().st_size > 0)

    js = list(EXT.rglob('*.js'))
    node = None
    try:
        node = subprocess.run(['node', '--version'], capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.SubprocessError):
        node = None
    if js and node and node.returncode == 0:
        results = [subprocess.run(['node', '--check', str(p)], capture_output=True).returncode == 0 for p in js]
        check('JavaScript syntax', all(results))
    else:
        check('JavaScript encontrado', bool(js))
        print('Node.js ausente: syntax-check do JS foi omitido.')

    html = list(EXT.rglob('*.html'))
    check('HTML', bool(html) and all('<html' in p.read_text(encoding='utf-8').lower() for p in html))
    css = list(EXT.rglob('*.css'))
    check('CSS', bool(css) and all(p.read_text(encoding='utf-8').count('{') == p.read_text(encoding='utf-8').count('}') for p in css))

    for size in (16, 32, 48, 128):
        icon = EXT / f'assets/icons/icon{size}.png'
        check(f'icon{size}.png', icon.is_file() and icon.stat().st_size > 0)

    refs = [m.get('action', {}).get('default_popup', ''), worker_rel or '', *m.get('icons', {}).values()]
    check('referências de arquivos', all(x and (EXT / x).is_file() for x in refs))

    themes_path = EXT / 'themes/catalog.json'
    if themes_path.is_file():
        themes = json.loads(themes_path.read_text(encoding='utf-8'))
        check('36 temas', themes.get('total') == 36 and sum(map(len, themes.get('families', {}).values())) == 36)
    else:
        check('catalogo de temas', False)

    dash_path = EXT / 'ui/dashboard.html'
    dash = dash_path.read_text(encoding='utf-8') if dash_path.is_file() else ''
    check('EULA', 'EULA' in dash or (ROOT / 'docs/EULA.md').is_file())
    check('Guia Rápido', 'Guia Rápido' in dash or (ROOT / 'docs/GUIA_RAPIDO.md').is_file())

    for name in ('SONPEF', 'CONVGPT', 'KIT_UNICO'):
        check(name, (ROOT / f'integrations/{name}/integration.json').is_file())

    assistants_path = EXT / 'scripts/assistants.js'
    assistants = assistants_path.read_text(encoding='utf-8') if assistants_path.is_file() else ''
    canonical = ('Júlia', 'Ayella', 'IZART')
    check('IA/assistentes', all(x in assistants for x in canonical) and 'Ayelle' not in assistants and 'alias Ayella' not in assistants)

    package = json.loads((ROOT / 'package.json').read_text(encoding='utf-8'))
    manifest_version = str(m.get('version', ''))
    package_version = str(package.get('version', ''))
    match = re.fullmatch(r'(\d+\.\d+\.\d+)\.(\d+)', manifest_version)
    expected_package = f'{match.group(1)}-{int(match.group(2)):05d}' if match else ''
    check('versões sincronizadas', bool(match) and package_version == expected_package)

    print('BUILD PASS')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
