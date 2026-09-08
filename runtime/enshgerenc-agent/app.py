#!/usr/bin/env python3
"""Minimal authenticated runtime boundary for ENSH-GERENC.

The agent exposes only allow-listed Docker Compose operations. It never accepts
arbitrary shell commands, Docker arguments, or a compose file from the client.
Keep the bearer token outside the repository and place the agent behind TLS,
VPN, or another trusted network boundary before exposing it remotely.
"""
from __future__ import annotations

import json
import os
import secrets
import subprocess
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HOST = os.getenv("IZGITH_RUNTIME_BIND", "127.0.0.1")
PORT = int(os.getenv("IZGITH_RUNTIME_PORT", "38751"))
TOKEN = os.getenv("IZGITH_RUNTIME_TOKEN", "")
COMPOSE_FILE = Path(os.getenv("IZGITH_ENSHROUDED_COMPOSE", "./docker-compose.yml")).resolve()
SERVICE = "enshrouded"
MAX_BODY = 32 * 1024


def json_response(handler: BaseHTTPRequestHandler, status: int, payload: dict) -> None:
    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(data)))
    handler.send_header("Cache-Control", "no-store")
    handler.end_headers()
    handler.wfile.write(data)


def authorized(handler: BaseHTTPRequestHandler) -> bool:
    if not TOKEN:
        return False
    supplied = handler.headers.get("Authorization", "")
    expected = f"Bearer {TOKEN}"
    return secrets.compare_digest(supplied, expected)


def docker(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["docker", *args],
        capture_output=True,
        text=True,
        timeout=120,
        check=False,
    )


def compose(*args: str) -> subprocess.CompletedProcess[str]:
    if not COMPOSE_FILE.is_file():
        raise FileNotFoundError(f"Compose file not found: {COMPOSE_FILE}")
    return docker("compose", "-f", str(COMPOSE_FILE), *args)


def run_operation(operation: str) -> dict:
    started = time.time()
    if operation == "health":
        p = docker("info", "--format", "{{json .ServerVersion}}")
        return {"ok": p.returncode == 0, "docker": p.stdout.strip() or p.stderr.strip()}
    if operation == "servers.list":
        p = docker("ps", "--filter", "label=izgith.enshgerenc=true", "--format", "{{.Names}}|{{.Status}}|{{.Image}}")
        rows = [x for x in p.stdout.splitlines() if x.strip()]
        return {"ok": p.returncode == 0, "servers": rows, "stderr": p.stderr.strip()}
    if operation not in {"server.start", "server.stop", "server.restart", "server.update"}:
        return {"ok": False, "supported": ["health", "servers.list", "server.start", "server.stop", "server.restart", "server.update"], "error": "operation_not_enabled"}

    command = {
        "server.start": ("up", "-d", SERVICE),
        "server.stop": ("stop", SERVICE),
        "server.restart": ("restart", SERVICE),
        "server.update": ("pull", SERVICE),
    }[operation]
    p = compose(*command)
    if operation == "server.update" and p.returncode == 0:
        p = compose("up", "-d", SERVICE)
    return {
        "ok": p.returncode == 0,
        "operation": operation,
        "stdout": p.stdout[-6000:],
        "stderr": p.stderr[-6000:],
        "elapsed_ms": round((time.time() - started) * 1000),
    }


class Handler(BaseHTTPRequestHandler):
    server_version = "IZGITH-ENSH-GERENC/1.0"

    def log_message(self, fmt: str, *args: object) -> None:
        print(f"[ENSH-GERENC] {self.address_string()} {fmt % args}")

    def _cors(self) -> None:
        origin = os.getenv("IZGITH_RUNTIME_CORS", "")
        if origin:
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Vary", "Origin")

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self._cors()
        self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.end_headers()

    def do_GET(self) -> None:
        if self.path == "/health":
            if not TOKEN:
                json_response(self, 503, {"ok": False, "error": "IZGITH_RUNTIME_TOKEN is not configured"})
                return
            try:
                result = run_operation("health")
                json_response(self, 200 if result.get("ok") else 503, result)
            except Exception as exc:
                json_response(self, 503, {"ok": False, "error": str(exc)})
            return
        json_response(self, 404, {"error": "not_found"})

    def do_POST(self) -> None:
        if not authorized(self):
            json_response(self, 401, {"error": "unauthorized"})
            return
        prefix = "/v1/operations/"
        if not self.path.startswith(prefix):
            json_response(self, 404, {"error": "not_found"})
            return
        operation = self.path[len(prefix):]
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length > MAX_BODY:
                raise ValueError("request_too_large")
            if length:
                self.rfile.read(length)
            result = run_operation(operation)
            status = 200 if result.get("ok") else 400
            if status == 200 and operation.startswith("server."):
                result["job_id"] = str(uuid.uuid4())
            json_response(self, status, result)
        except subprocess.TimeoutExpired:
            json_response(self, 504, {"ok": False, "error": "runtime_timeout"})
        except Exception as exc:
            json_response(self, 400, {"ok": False, "error": str(exc)})


if __name__ == "__main__":
    if not TOKEN:
        raise SystemExit("Set IZGITH_RUNTIME_TOKEN before starting the agent.")
    print(f"ENSH-GERENC runtime listening on {HOST}:{PORT}; compose={COMPOSE_FILE}")
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
