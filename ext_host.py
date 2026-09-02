#!/usr/bin/env python3
"""IZGITH native host.

The host deliberately does not install extensions into a user's main browser profile.
It can inspect manifests, safely extract ZIP archives, open native folder pickers, and
launch an isolated Chromium profile with an unpacked extension for testing.
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path
from typing import Any

HOST_NAME = "com.izgith.host"


def _safe_extract(zip_path: Path, destination: Path) -> Path:
    destination = destination.resolve()
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path) as archive:
        for member in archive.infolist():
            target = (destination / member.filename).resolve()
            if destination != target and destination not in target.parents:
                raise ValueError(f"unsafe ZIP member: {member.filename}")
        archive.extractall(destination)
    return destination


def _find_manifest(root: Path) -> Path | None:
    direct = root / "manifest.json"
    if direct.is_file():
        return direct
    candidates = list(root.glob("*/manifest.json"))
    return candidates[0] if len(candidates) == 1 else None


def pick_directory(title: str = "Selecione a pasta da extensão") -> str | None:
    try:
        import tkinter as tk
        from tkinter import filedialog
    except ImportError as exc:
        raise RuntimeError("tkinter is required for the native folder picker") from exc
    root = tk.Tk()
    root.withdraw()
    root.attributes("-topmost", True)
    try:
        selected = filedialog.askdirectory(title=title, mustexist=True)
    finally:
        root.destroy()
    return selected or None


def analyze_manifest(path: str) -> dict[str, Any]:
    target = Path(path).expanduser().resolve()
    manifest_path = target if target.name == "manifest.json" else _find_manifest(target)
    if not manifest_path or not manifest_path.is_file():
        return {"ok": False, "error": "manifest.json not found"}
    try:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return {"ok": False, "error": f"invalid manifest: {exc}"}

    permissions = list(data.get("permissions") or [])
    host_permissions = list(data.get("host_permissions") or [])
    risk = 0
    findings: list[str] = []
    weighted = {"debugger": 35, "proxy": 25, "webRequestBlocking": 25, "history": 15, "tabs": 8, "cookies": 12}
    for permission, weight in weighted.items():
        if permission in permissions:
            risk += weight
            findings.append(f"permission:{permission}")
    if "<all_urls>" in host_permissions:
        risk += 25
        findings.append("host:<all_urls>")
    if any(value.startswith("http://") or value.startswith("https://") for value in host_permissions):
        risk += 5
    score = max(0, 100 - min(risk, 100))
    return {
        "ok": True,
        "manifest": str(manifest_path),
        "name": data.get("name", "unnamed"),
        "version": data.get("version", "unknown"),
        "manifest_version": data.get("manifest_version"),
        "score": score,
        "findings": findings,
    }


def detect_browser() -> str | None:
    candidates: list[Path] = []
    if sys.platform == "win32":
        roots = [os.environ.get("PROGRAMFILES"), os.environ.get("PROGRAMFILES(X86)"), os.environ.get("LOCALAPPDATA")]
        for root in filter(None, roots):
            base = Path(root)
            candidates.extend([
                base / "Google/Chrome/Application/chrome.exe",
                base / "Microsoft/Edge/Application/msedge.exe",
                base / "BraveSoftware/Brave-Browser/Application/brave.exe",
            ])
    elif sys.platform == "darwin":
        candidates.extend([
            Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"),
            Path("/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"),
            Path("/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"),
        ])
    else:
        for binary in ("google-chrome", "google-chrome-stable", "chromium", "chromium-browser", "microsoft-edge", "brave-browser"):
            found = shutil.which(binary)
            if found:
                return found
    return next((str(path) for path in candidates if path.is_file()), None)


def launch_sandbox(extension_path: str, browser: str | None = None) -> dict[str, Any]:
    extension = Path(extension_path).expanduser().resolve()
    manifest = _find_manifest(extension) if extension.is_dir() else None
    if not manifest:
        return {"ok": False, "error": "sandbox requires an unpacked directory containing manifest.json"}
    analysis = analyze_manifest(str(manifest.parent))
    browser_path = browser or detect_browser()
    if not browser_path:
        return {"ok": False, "error": "no supported Chromium browser found", "analysis": analysis}
    profile = Path(tempfile.mkdtemp(prefix="izgith-sandbox-"))
    args = [browser_path, f"--user-data-dir={profile}", f"--load-extension={manifest.parent}", "--no-first-run", "about:blank"]
    subprocess.Popen(args, close_fds=(sys.platform != "win32"))
    return {"ok": True, "profile": str(profile), "browser": browser_path, "extension": str(manifest.parent), "analysis": analysis}


def handle(message: dict[str, Any]) -> dict[str, Any]:
    command = message.get("command")
    if command == "ping":
        return {"ok": True, "host": HOST_NAME, "python": sys.version.split()[0]}
    if command == "pick_directory":
        selected = pick_directory(str(message.get("title") or "Selecione a pasta da extensão"))
        return {"ok": bool(selected), "path": selected, "cancelled": not bool(selected)}
    if command == "pick_and_analyze":
        selected = pick_directory("Selecione a pasta da extensão para auditoria")
        if not selected:
            return {"ok": False, "cancelled": True}
        return analyze_manifest(selected)
    if command == "pick_and_sandbox":
        selected = pick_directory("Selecione a pasta da extensão para abrir no sandbox")
        if not selected:
            return {"ok": False, "cancelled": True}
        return launch_sandbox(selected, message.get("browser"))
    if command == "analyze_manifest":
        return analyze_manifest(str(message.get("path", "")))
    if command == "extract_zip":
        source = Path(str(message.get("path", ""))).expanduser().resolve()
        if not source.is_file() or source.suffix.lower() != ".zip":
            return {"ok": False, "error": "a .zip file is required"}
        destination = Path(str(message.get("destination") or tempfile.mkdtemp(prefix="izgith-extract-")))
        try:
            extracted = _safe_extract(source, destination)
            return {"ok": True, "path": str(extracted), "analysis": analyze_manifest(str(extracted))}
        except (OSError, zipfile.BadZipFile, ValueError) as exc:
            return {"ok": False, "error": str(exc)}
    if command == "launch_sandbox":
        return launch_sandbox(str(message.get("path", "")), message.get("browser"))
    return {"ok": False, "error": f"unknown command: {command}"}


def read_message() -> dict[str, Any] | None:
    raw_length = sys.stdin.buffer.read(4)
    if not raw_length:
        return None
    length = struct.unpack("<I", raw_length)[0]
    payload = sys.stdin.buffer.read(length)
    return json.loads(payload.decode("utf-8"))


def write_message(message: dict[str, Any]) -> None:
    payload = json.dumps(message, ensure_ascii=False).encode("utf-8")
    sys.stdout.buffer.write(struct.pack("<I", len(payload)))
    sys.stdout.buffer.write(payload)
    sys.stdout.buffer.flush()


def native_loop() -> None:
    while True:
        message = read_message()
        if message is None:
            break
        try:
            write_message(handle(message))
        except Exception as exc:
            write_message({"ok": False, "error": f"host error: {exc}"})


def main() -> int:
    parser = argparse.ArgumentParser(description="IZGITH native host")
    parser.add_argument("--analyze", metavar="PATH", help="analyze an unpacked extension")
    parser.add_argument("--sandbox", metavar="PATH", help="launch an unpacked extension in an isolated browser profile")
    args = parser.parse_args()
    if args.analyze:
        print(json.dumps(analyze_manifest(args.analyze), ensure_ascii=False, indent=2))
        return 0
    if args.sandbox:
        result = launch_sandbox(args.sandbox)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0 if result.get("ok") else 1
    native_loop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
