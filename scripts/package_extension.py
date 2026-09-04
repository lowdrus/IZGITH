#!/usr/bin/env python3
from __future__ import annotations
import json, shutil, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXT = ROOT / 'extension'
DIST = ROOT / 'dist'

manifest = json.loads((EXT / 'manifest.json').read_text(encoding='utf-8'))
label = manifest.get('version_name', manifest['version']).split()[0]
DIST.mkdir(exist_ok=True)
full = DIST / f'IZGITH_v{label}_FULL'
if full.exists():
    shutil.rmtree(full)

# The unpacked package itself is directly loadable in Chromium.
shutil.copytree(EXT, full)

# The ZIP root is also directly loadable: manifest.json is at the ZIP root.
archive = DIST / f'IZGITH_v{label}_FULL.zip'
if archive.exists():
    archive.unlink()
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for p in sorted(full.rglob('*')):
        if p.is_file():
            z.write(p, p.relative_to(full))

print(archive)
