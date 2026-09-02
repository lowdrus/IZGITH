#!/usr/bin/env python3
"""Extract readable Markdown and fenced code blocks from a ChatGPT conversations.json export."""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import shutil
from pathlib import Path
from typing import Any


def sanitize(name: str | None) -> str:
    value = (name or "conversation").strip()
    value = re.sub(r'[\\/*?:"<>|]', "_", value)
    value = re.sub(r"\s+", " ", value).strip(" .")
    return (value or "conversation")[:160]


def detect_ext(code: str, declared_lang: str | None) -> str:
    mapping = {
        "python": "py", "py": "py", "powershell": "ps1", "ps1": "ps1", "ps": "ps1",
        "bash": "sh", "sh": "sh", "shell": "sh", "javascript": "js", "js": "js",
        "typescript": "ts", "ts": "ts", "html": "html", "css": "css", "json": "json",
        "xml": "xml", "sql": "sql", "java": "java", "cs": "cs", "rust": "rs", "c": "c", "cpp": "cpp",
    }
    if declared_lang and declared_lang.lower() in mapping:
        return mapping[declared_lang.lower()]
    stripped = (code or "").lstrip()
    first = stripped.splitlines()[0].lower() if stripped else ""
    if first.startswith("#!") and "python" in first:
        return "py"
    if re.search(r"(^|\n)\s*(def|class)\s+\w+", stripped) or re.search(r"(^|\n)\s*(from|import)\s+\w+", stripped):
        return "py"
    if "Get-ChildItem" in stripped or "Write-Host" in stripped or re.search(r"\bparam\s*\(", stripped, re.I):
        return "ps1"
    if stripped.startswith("<") and "html" in stripped.lower():
        return "html"
    return "txt"


def parse_nodes(conv: dict[str, Any]) -> list[dict[str, Any]]:
    mapping = conv.get("mapping") or {}
    nodes = [node for node in mapping.values() if isinstance(node, dict) and node.get("id")]
    by_id = {node["id"]: node for node in nodes}
    roots = [node for node in nodes if not node.get("parent")]
    ordered: list[dict[str, Any]] = []
    visited: set[str] = set()

    def dfs(node: dict[str, Any]) -> None:
        node_id = node["id"]
        if node_id in visited:
            return
        visited.add(node_id)
        if node.get("message", {}).get("content"):
            ordered.append(node)
        for child_id in node.get("children") or []:
            child = by_id.get(child_id)
            if child:
                dfs(child)

    for root in roots:
        dfs(root)
    if not ordered:
        ordered = [node for node in nodes if node.get("message")]
    return ordered


def extract_conversation(conv: dict[str, Any], outbase: Path) -> Path:
    title = conv.get("title") or "conversation"
    safe_title = sanitize(title)
    outdir = outbase / f"extracted_{safe_title}"
    if outdir.exists():
        shutil.rmtree(outdir)
    outdir.mkdir(parents=True)

    markdown = [f"# {title}", f"- extracted_at: {dt.datetime.now(dt.timezone.utc).isoformat()}", ""]
    summary: dict[str, Any] = {"title": title, "files": []}
    code_counter = 0

    for index, node in enumerate(parse_nodes(conv), start=1):
        message = node.get("message") or {}
        author = (message.get("author") or {}).get("role") or "unknown"
        timestamp = message.get("create_time") or message.get("update_time") or ""
        content = message.get("content") or {}
        parts = content.get("parts") or [] if isinstance(content, dict) else []
        text = "\n\n".join(part for part in parts if isinstance(part, str))
        markdown.extend(["---", f"**{index}. {author}**  ", f"*{timestamp}*  "])

        def replace_code(match: re.Match[str]) -> str:
            nonlocal code_counter
            language = (match.group(1) or "").strip().lower()
            code = match.group(2) or ""
            code_counter += 1
            extension = detect_ext(code, language)
            filename = f"code_{index:03d}_{code_counter:03d}.{extension}"
            (outdir / filename).write_text(code, encoding="utf-8")
            summary["files"].append({"file": filename, "lang": language or None, "size": len(code)})
            return f"[Código extraído: {filename}]"

        markdown.append(re.sub(r"```([\w+-]*)\n(.*?)```", replace_code, text, flags=re.S))

    (outdir / f"{safe_title}.md").write_text("\n".join(markdown), encoding="utf-8")
    (outdir / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    return outdir


def load_conversations(path: Path) -> list[dict[str, Any]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    conversations = data if isinstance(data, list) else data.get("conversations") or []
    return [item for item in conversations if isinstance(item, dict)]


def main() -> int:
    parser = argparse.ArgumentParser(description="Extrair conversas de conversations.json")
    parser.add_argument("--input", "-i", default="conversations.json")
    parser.add_argument("--outdir", "-o", default="extracted")
    parser.add_argument("--title", "-t", help="nome completo ou parcial da conversa")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--zip", action="store_true")
    args = parser.parse_args()

    source = Path(args.input)
    if not source.is_file():
        parser.error(f"arquivo não encontrado: {source}")
    conversations = load_conversations(source)

    if args.all:
        selected = conversations
    elif args.title:
        query = args.title.casefold()
        selected = [conv for conv in conversations if query in (conv.get("title") or "").casefold()]
    else:
        print("Conversas encontradas:")
        for index, conv in enumerate(conversations, start=1):
            print(f"{index:03d}: {conv.get('title') or 'Sem título'}")
        choice = input("Digite número, título parcial ou 'all':\n> ").strip()
        if choice.casefold() == "all":
            selected = conversations
        elif choice.isdigit() and 1 <= int(choice) <= len(conversations):
            selected = [conversations[int(choice) - 1]]
        else:
            query = choice.casefold()
            selected = [conv for conv in conversations if query in (conv.get("title") or "").casefold()]

    if not selected:
        print("Nenhuma conversa correspondente encontrada.", file=sys.stderr)
        return 1

    outbase = Path(args.outdir)
    outbase.mkdir(parents=True, exist_ok=True)
    for conversation in selected:
        print("Extraído para", extract_conversation(conversation, outbase))

    if args.zip:
        archive = shutil.make_archive(str(outbase), "zip", root_dir=outbase)
        print("Zip criado:", archive)
    return 0


if __name__ == "__main__":
    import sys
    raise SystemExit(main())
