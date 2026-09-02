#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import platform
import subprocess
import sys
from pathlib import Path

HOST_NAME = "com.izgith.host"


def chrome_extension_origin(extension_id: str) -> str:
    value = extension_id.strip().lower()
    if len(value) != 32 or any(ch not in "abcdefghijklmnop" for ch in value):
        raise ValueError("Chrome extension ID must contain 32 characters in the range a-p")
    return f"chrome-extension://{value}/"


def write_launcher(root: Path) -> Path:
    if os.name == "nt":
        launcher = root / "izgith_host.bat"
        launcher.write_text(f'@echo off\r\n"{sys.executable}" "{root / "ext_host.py"}"\r\n', encoding="utf-8")
    else:
        launcher = root / "izgith_host.sh"
        launcher.write_text(f'#!/bin/sh\nexec "{sys.executable}" "{root / "ext_host.py"}"\n', encoding="utf-8")
        launcher.chmod(0o755)
    return launcher


def install(extension_id: str, browser: str) -> Path:
    root = Path(__file__).resolve().parent
    origin = chrome_extension_origin(extension_id)
    launcher = write_launcher(root)
    manifest = {
        "name": HOST_NAME,
        "description": "IZGITH local native messaging host",
        "path": str(launcher),
        "type": "stdio",
        "allowed_origins": [origin],
    }
    system = platform.system()
    browser = browser.lower()

    if system == "Windows":
        manifest_dir = Path(os.environ.get("LOCALAPPDATA", str(root))) / "IZGITH"
        manifest_dir.mkdir(parents=True, exist_ok=True)
        manifest_path = manifest_dir / f"{HOST_NAME}.json"
        manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
        registry_roots = {
            "chrome": r"HKCU\Software\Google\Chrome\NativeMessagingHosts",
            "edge": r"HKCU\Software\Microsoft\Edge\NativeMessagingHosts",
        }
        registry_root = registry_roots.get(browser)
        if not registry_root:
            raise ValueError("Windows installer currently supports chrome or edge")
        subprocess.run(["reg", "add", f"{registry_root}\\{HOST_NAME}", "/ve", "/t", "REG_SZ", "/d", str(manifest_path), "/f"], check=True)
        return manifest_path

    home = Path.home()
    if system == "Darwin":
        roots = {
            "chrome": home / "Library/Application Support/Google/Chrome/NativeMessagingHosts",
            "edge": home / "Library/Application Support/Microsoft Edge/NativeMessagingHosts",
            "brave": home / "Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts",
        }
    else:
        roots = {
            "chrome": home / ".config/google-chrome/NativeMessagingHosts",
            "chromium": home / ".config/chromium/NativeMessagingHosts",
            "edge": home / ".config/microsoft-edge/NativeMessagingHosts",
            "brave": home / ".config/BraveSoftware/Brave-Browser/NativeMessagingHosts",
        }
    manifest_dir = roots.get(browser)
    if not manifest_dir:
        raise ValueError(f"unsupported browser {browser!r} on {system}")
    manifest_dir.mkdir(parents=True, exist_ok=True)
    manifest_path = manifest_dir / f"{HOST_NAME}.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    return manifest_path


def main() -> int:
    parser = argparse.ArgumentParser(description="Register the IZGITH native messaging host")
    parser.add_argument("--extension-id", required=True, help="ID shown on chrome://extensions")
    parser.add_argument("--browser", default="chrome", choices=["chrome", "chromium", "edge", "brave"])
    args = parser.parse_args()
    try:
        path = install(args.extension_id, args.browser)
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    print(f"Native host registered: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
