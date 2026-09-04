#!/usr/bin/env python3
from __future__ import annotations
import json,shutil,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];EXT=ROOT/'extension';DIST=ROOT/'dist'
m=json.loads((EXT/'manifest.json').read_text('utf-8'));label=m.get('version_name',m['version']).split()[0]
DIST.mkdir(exist_ok=True);full=DIST/f'IZGITH_v{label}_FULL';target=full/'extension'
if full.exists():shutil.rmtree(full)
shutil.copytree(EXT,target)
shutil.copytree(ROOT/'host',full/'host',ignore=shutil.ignore_patterns('__pycache__','*.pyc','dist','build','*.spec'))
shutil.copy2(ROOT/'docs/GUIA_INTEGRACAO_00065.md',full/'LEIA_PRIMEIRO.md')
archive=DIST/f'IZGITH_v{label}_FULL.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for p in sorted(full.rglob('*')):
        if p.is_file():z.write(p,p.relative_to(DIST))
print(archive)
