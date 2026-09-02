#!/usr/bin/env python3
"""Cria o ZIP instalável contendo somente extension/."""
from __future__ import annotations
import json
import zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1];EXT=ROOT/'extension';DIST=ROOT/'dist'
version=json.loads((EXT/'manifest.json').read_text(encoding='utf-8'))['version']
DIST.mkdir(exist_ok=True);target=DIST/f'IZGITH-extension-v{version}.zip'
with zipfile.ZipFile(target,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
    for path in sorted(EXT.rglob('*')):
        if path.is_file():archive.write(path,path.relative_to(EXT))
print(target)
