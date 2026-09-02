#!/usr/bin/env python3
"""Validação sem dependências do produto distribuível IZGITH."""
from __future__ import annotations
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
EXT=ROOT/'extension'

def fail(message:str)->None:
    raise SystemExit(f'ERRO: {message}')

def main()->int:
    manifest=json.loads((EXT/'manifest.json').read_text(encoding='utf-8'))
    if manifest.get('manifest_version')!=3:fail('manifest_version deve ser 3')
    if manifest.get('name')!='IZGITH':fail('nome da extensão deve ser IZGITH')
    required=[manifest['action']['default_popup'],manifest['background']['service_worker'],*manifest['icons'].values()]
    for relative in required:
        if not (EXT/relative).is_file():fail(f'arquivo ausente no manifesto: {relative}')
    html_files=list(EXT.glob('*.html'))
    for html in html_files:
        text=html.read_text(encoding='utf-8')
        ids=set(re.findall(r'\bid=["\']([^"\']+)',text))
        for script_match in re.findall(r'<script[^>]+src=["\']([^"\']+)',text):
            if '://' in script_match:fail(f'script remoto proibido em {html.name}')
            if not (EXT/script_match).is_file():fail(f'script ausente em {html.name}: {script_match}')
        for script in re.findall(r'<script[^>]+src=["\']([^"\']+\.js)',text):
            source=(EXT/script).read_text(encoding='utf-8')
            referenced=set(re.findall(r"(?<!\$)\$\(['\"]([^'\"]+)",source))
            missing=referenced-ids
            if missing:fail(f'IDs ausentes em {html.name}: {sorted(missing)}')
    for source in EXT.glob('*.js'):
        subprocess.run(['node','--check',str(source)],check=True)
    package=json.loads((ROOT/'package.json').read_text(encoding='utf-8'))
    if package.get('version')!=manifest.get('version'):fail('versões de package.json e manifest.json divergem')
    forbidden=[]
    for pattern in ('*.pem','*.key','*.p12','*.pfx'):
        forbidden.extend(ROOT.rglob(pattern))
    if forbidden:fail('chaves privadas encontradas: '+', '.join(str(p.relative_to(ROOT)) for p in forbidden))
    print(f"IZGITH {manifest['version']}: manifesto, HTML, JavaScript e arquivos validados")
    return 0

if __name__=='__main__':raise SystemExit(main())
