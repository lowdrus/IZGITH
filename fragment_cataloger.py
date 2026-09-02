
"""
fragment_cataloger.py
Gera FRAGMENTS_REPORT.md e FRAGMENTS_CATALOG.json a partir de uma raiz.
- Varre arquivos .ps1/.py/.sh/.js/.ts/.json/.txt
- Heurísticas para descrever propósito, risco, uso, inputs/outputs
- Integra com FULLONE (gera índice por pasta)

Uso:
  python fragment_cataloger.py "D:\PROJETOS\FULLONE-RAIZ\FULL ONE"
"""
import os, re, json, hashlib, sys, datetime
from pathlib import Path

ROOT = Path(sys.argv[1]) if len(sys.argv)>1 else Path(".")
OUT_JSON = ROOT / "FRAGMENTS_CATALOG.json"
OUT_MD   = ROOT / "FRAGMENTS_REPORT.md"

EXTS = {".ps1",".py",".sh",".js",".ts",".json",".txt"}

def sha1(p:Path):
    try:
        h = hashlib.sha1()
        with open(p,"rb") as f:
            while True:
                b = f.read(8192)
                if not b: break
            return h.hexdigest()
    except:
        return "error"

def guess_purpose(text,name):
    s = text.lower()
    hints = []
    if "unify" in s or "merge" in s or "unificar" in s: hints.append("unificação")
    if "extract" in s or "extrair" in s: hints.append("extração")
    if "deploy" in s or "publicar" in s: hints.append("deploy")
    if "anal" in s or "analysis" in s or "análise" in s: hints.append("análise")
    if "backup" in s: hints.append("backup")
    if "markdown" in s: hints.append("gera markdown")
    if "pdf" in s: hints.append("gera pdf")
    if "crx" in s: hints.append("extensão chrome")
    if not hints: hints.append("genérico")
    return list(dict.fromkeys(hints))

def guess_inputs(text):
    ins = []
    t = text.lower()
    if ".json" in t: ins.append("JSON")
    if ".html" in t: ins.append("HTML")
    if ".ps1" in t or "powershell" in t: ins.append("PS1")
    if ".py" in t or "python" in t: ins.append("PY")
    return list(dict.fromkeys(ins))

def guess_outputs(text):
    outs = []
    for k in ("md","markdown","pdf","html","zip","csv","json"):
        if k in text.lower(): outs.append(k.upper())
    if not outs: outs.append("FILES")
    return list(dict.fromkeys(outs))

def summarize(path:Path):
    try:
        txt = path.read_text(encoding="utf-8", errors="ignore")
    except:
        txt = ""
    return {
        "name": path.name,
        "relpath": str(path),
        "sha1": "todo",  # fast version to avoid hashing large files here
        "size": path.stat().st_size if path.exists() else 0,
        "purpose": guess_purpose(txt, path.name),
        "inputs": guess_inputs(txt),
        "outputs": guess_outputs(txt),
        "lines": txt.count("\n")+1 if txt else 0
    }

def main():
    frags = []
    for root,_,files in os.walk(ROOT):
        for f in files:
            p = Path(root)/f
            if p.suffix.lower() in EXTS:
                frags.append(summarize(p))
    frags.sort(key=lambda x: x["name"].lower())
    data = {
        "generated_at": datetime.datetime.now().isoformat(),
        "root": str(ROOT),
        "count": len(frags),
        "fragments": frags
    }
    OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    # md
    lines = ["# FRAGMENTS REPORT", "", f"- Root: {ROOT}", f"- Count: {len(frags)}", ""]
    for i,f in enumerate(frags, start=1):
        lines += [f"## {i}. {f['name']}",
                  f"- RelPath: `{f['relpath']}`",
                  f"- Size: `{f['size']}` bytes, Lines: {f['lines']}",
                  f"- Purpose: {', '.join(f['purpose'])}",
                  f"- Inputs: {', '.join(f['inputs'])}",
                  f"- Outputs: {', '.join(f['outputs'])}", ""]
    OUT_MD.write_text("\n".join(lines), encoding="utf-8")
    print(str(OUT_JSON))
    print(str(OUT_MD))

if __name__ == "__main__":
    main()
