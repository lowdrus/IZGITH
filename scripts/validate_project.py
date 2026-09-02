#!/usr/bin/env python3
from __future__ import annotations
import json, re, subprocess, sys
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


def read_json(path: Path):
    try:
        return json.loads(path.read_text(encoding='utf-8'))
    except Exception as exc:
        print(f'JSON parse {path}: {exc}')
        return None


def main():
    check('pasta raiz', ROOT.is_dir())
    mp = EXT / 'manifest.json'
    check('manifest.json', mp.is_file())
    m = read_json(mp) if mp.is_file() else None
    valid = isinstance(m, dict) and m.get('manifest_version') == 3
    check('JSON Manifest V3 válido', valid)

    worker_rel = m.get('background', {}).get('service_worker') if isinstance(m, dict) else None
    check('background/service worker declarado', isinstance(worker_rel, str) and bool(worker_rel))
    worker = EXT / worker_rel if isinstance(worker_rel, str) else EXT / '__missing__'
    check('background/service worker existe', worker.is_file())
    if worker.is_file():
        check('service worker nao vazio', worker.stat().st_size > 0)

    js = list(EXT.rglob('*.js'))
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
        themes = read_json(themes_path) or {}
        families = themes.get('families', {})
        check('36 temas', themes.get('total') == 36 and sum(map(len, families.values())) == 36)
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
    forbidden = ('Ayelle', 'alias Ayella', 'Alias: Ayella')
    check('IA/assistentes', all(x in assistants for x in canonical) and not any(x in assistants for x in forbidden))

    # Keep the service worker under the same naming contract as the assistant registry.
    worker_text = worker.read_text(encoding='utf-8') if worker.is_file() else ''
    check('service worker sem alias proibido', not any(x in worker_text for x in forbidden))

    registry_path = ROOT / 'integrations/assistant_registry.json'
    registry = read_json(registry_path) if registry_path.is_file() else None
    registry_names = []
    if isinstance(registry, dict):
        registry_names = [item.get('name') for item in registry.get('canonical_assistants', []) if isinstance(item, dict)]
    registry_policy = registry.get('naming_policy', {}) if isinstance(registry, dict) else {}
    check('registry IA canônico', registry_names == ['Júlia', 'Ayella', 'IZART'] and registry_policy.get('ayella_is_alias') is False)
    check('registry sem aliases proibidos', not any(x in registry_names for x in ('Ayelle', 'alias Ayella', 'Alias: Ayella')))

    package_path = ROOT / 'package.json'
    package = read_json(package_path) if package_path.is_file() else None
    package = package or {}
    manifest_version = str(m.get('version', '')) if isinstance(m, dict) else ''
    package_version = str(package.get('version', ''))
    match = re.fullmatch(r'(\d+\.\d+\.\d+)\.(\d+)', manifest_version)
    expected_package = f'{match.group(1)}-{int(match.group(2)):05d}' if match else ''
    check('versões sincronizadas', bool(match) and package_version == expected_package)

    registry_version = registry.get('version', '') if isinstance(registry, dict) else ''
    expected_registry = f'6.0.0.{int(match.group(2)):05d}' if match else ''
    check('versão registry sincronizada', registry_version == expected_registry)

    print('BUILD PASS')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
