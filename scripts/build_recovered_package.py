#!/usr/bin/env python3
"""Build a complete recovery ZIP from sources actually present in the repository.

The script deliberately does not invent missing historical attachments. It packages
active sources plus the preserved legacy archive and integration metadata.
"""
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
PROFILE = ROOT / "BUILD_PROFILE.json"
OUT = ROOT / "dist"

INCLUDE = [
    "extension",
    "host",
    "scripts",
    "tests",
    "docs",
    "integrations",
    "archive/legacy/root",
    "README.md",
    "LICENSE",
    "SECURITY.md",
    "BUILD_PROFILE.json",
]

def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    profile = json.loads(PROFILE.read_text(encoding="utf-8"))
    version = profile.get("version", "recovered")
    stage = OUT / f"IZGITH_{version}_FULL_RECOVERED"
    if stage.exists():
        shutil.rmtree(stage)
    stage.mkdir(parents=True)

    copied = 0
    for item in INCLUDE:
        src = ROOT / item
        if not src.exists():
            continue
        dst = stage / item
        if src.is_dir():
            shutil.copytree(src, dst)
            copied += sum(1 for p in src.rglob("*") if p.is_file())
        else:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            copied += 1

    manifest = {
        "version": version,
        "copied_files": copied,
        "historical_source": "archive/legacy/root",
        "note": "Historical attachments unavailable as bytes are not fabricated; repository sources are preserved verbatim where available.",
    }
    (stage / "RECOVERY_MANIFEST.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    zip_path = OUT / f"IZGITH_{version}_FULL_RECOVERED.zip"
    if zip_path.exists():
        zip_path.unlink()
    with ZipFile(zip_path, "w", ZIP_DEFLATED) as zf:
        for path in stage.rglob("*"):
            if path.is_file():
                zf.write(path, path.relative_to(stage.parent).as_posix())
    print(f"Created: {zip_path}")
    print(f"Files: {copied + 1}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
