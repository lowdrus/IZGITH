#!/usr/bin/env python3
# FULLONE Autônomo Avançado - FULLONEv14fixed2
# Save as: FULLONEv14fixed2_AutonomoAvancado.py
# Usage: python FULLONEv14fixed2_AutonomoAvancado.py [--test]
# - --test -> runs a small local test, will not scan your real folders
import os
import sys
import shutil
import zipfile
import glob
import re
from pathlib import Path
from datetime import datetime
# External libs
try:
from fpdf import FPDF
except Exception as e:
print("Missing dependency: fpdf. Install: pip install fpdf")
raise
try:
import graphviz
HAVE_GRAPHVIZ = True
except Exception:
HAVE_GRAPHVIZ = False
try:
from PIL import Image, ImageDraw, ImageFont
HAVE_PIL = True
except Exception:
HAVE_PIL = False
# -------------------------
# Configuration (updateable)
# -------------------------
VERSAO_FULLONE = "FULLONEv14fixed2"
# Output folders
BASE_OUTPUT = Path(r"C:\SCRIPTS\FULL ONE")
PASTA_EXEC = BASE_OUTPUT / "FULL ONE GENERATOR"
PASTA_UNIFICADOS = BASE_OUTPUT / "ARQUIVOS .PS1 UNIFICADOS"
PASTA_PACKAGE = BASE_OUTPUT / "PACKAGE"
PASTA_COMPILADOS = BASE_OUTPUT / "COMPILADOS"
PASTA_DIAGRAMA = BASE_OUTPUT / "DIAGRAMA VISUAL"
PASTA_TXT_REF = PASTA_DIAGRAMA / "SCRIPTS_TXT_REF"
PASTA_LOGS = BASE_OUTPUT / "LOGS"
PASTA_OFFICIAL = BASE_OUTPUT / "OFFICIAL" # if you keep an 'official' generator
here, script can auto-update
# create outputs if missing
for p in (PASTA_EXEC, PASTA_UNIFICADOS, PASTA_PACKAGE, PASTA_COMPILADOS,
PASTA_DIAGRAMA, PASTA_TXT_REF, PASTA_LOGS, PASTA_OFFICIAL):
try:
p.mkdir(parents=True, exist_ok=True)
except Exception:
pass
# -------------------------
# The full list of search paths you provided
# -------------------------
SEARCH_PATHS = [
r"C:\CONAV TRADER",
r"C:\CONAV TRADER\CONAV_TRADER\automation",
r"C:\CONAV TRADER\CONAV_TRADER\build",
r"C:\CONAV TRADER\CONAV_TRADER\dashboard",
r"C:\CONAV TRADER\CONAV_TRADER\data",
r"C:\CONAV TRADER\CONAV_TRADER\database",
r"C:\CONAV TRADER\CONAV_TRADER\Desinstalar",
r"C:\CONAV TRADER\CONAV_TRADER\dist",
r"C:\CONAV TRADER\CONAV_TRADER\docs",
r"C:\CONAV TRADER\CONAV_TRADER\emails",
r"C:\CONAV TRADER\CONAV_TRADER\icons",
r"C:\CONAV TRADER\CONAV_TRADER\logs",
r"C:\CONAV TRADER\CONAV_TRADER\relatórios",
r"C:\CONAV TRADER\CONAV_TRADER\resources",
r"C:\CONAV TRADER\CONAV_TRADER\scripts",
r"C:\CONAV TRADER\CONAV_TRADER\tools",
r"C:\CONAV TRADER\CONAV_TRADER\automation\autocorrector",
r"C:\CONAV TRADER\CONAV_TRADER\build\Desinstalar",
r"C:\CONAV TRADER\CONAV_TRADER\build\Desinstalar\localpycs",
r"C:\CONAV TRADER\CONAV_TRADER\build\Desinstalar\base_library.zip",
r"C:\CONAV TRADER\CONAV_TRADER\build\Desinstalar\base_library.zip\collections",
r"C:\CONAV TRADER\CONAV_TRADER\build\Desinstalar\base_library.zip\encodings",
r"C:\CONAV TRADER\CONAV_TRADER\build\Desinstalar\base_library.zip\re",
r"C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard",
r"C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\localpycs",
r"C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\base_library.zip",
r"C:\CONAV TRADER\CONAV_TRADER\build\uninstall_wrapper",
r"C:\CONAV TRADER\CONAV_TRADER\build\uninstall_wrapper\localpycs",
r"C:\CONAV TRADER\CONAV_TRADER\build\uninstall_wrapper\base_library.zip",
r"C:\CONAV
TRADER\CONAV_TRADER\build\uninstall_wrapper\base_library.zip\collections",
r"C:\CONAV TRADER\CONAV_TRADER\build\uninstall_wrapper\base_library.zip\re",
r"C:\CONAV
TRADER\CONAV_TRADER\build\uninstall_wrapper\base_library.zip\encodings",
r"C:\CONAV TRADER\CONAV_TRADER\Desinstalar\build",
r"C:\CONAV TRADER\CONAV_TRADER\mapas de fluxograma",
r"C:\CONAV TRADER\CONAV_TRADER\PACKAGES OFICIAIS",
r"C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE",
r"C:\CONAV TRADER\CONAV_TRADER\scripts\0001",
r"C:\CONAV TRADER\CONAV_TRADER\scripts\0002",
r"C:\CONAV TRADER\CONAV_TRADER\scripts\0003",
r"C:\CONAV TRADER\CONAV_TRADER\scripts\004",
r"C:\CONAV TRADER\CONAV_TRADER\scripts\aleatorios versoes 1.30+",
r"C:\CONAV TRADER\CONAV_TRADER\scripts\PACKAGES OFICIAIS",
r"C:\CONAV TRADER\CONAV_TRADER\scripts\SCRIPTS BASE OFICIAIS",
r"C:\CONAV TRADER\CONAV_TRADER\scripts\SCRIPTS DE LISTAGEM",
r"C:\CONAV TRADER\CONAV_TRADER\scripts\uninstall versoes 1.30+",
r"C:\CONAV TRADER\CONAV_TRADER\SCRIPTS DE LISTAGEM",
r"C:\CONAV TRADER\CONAV_TRADER\SCRIPTS BASE OFICIAIS",
r"C:\CONAV TRADER\CONAV_TRADER\tools",
r"C:\CONAV TRADER\CONAV_TRADER\TUTORIAL GERAL",
r"C:\CONAV TRADER\CONAV_TRADER\CONAV MASTER FULL",
r"C:\CONAV TRADER\dist",
r"C:\CONAV TRADER\logs",
r"C:\CONAV TRADER\PASTA DO BACKUP\CONAV TRADES ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV-ZIP_20250911_160904",
r"C:\CONAV TRADER\PASTA DO BACKUP\CONAV TRADES ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV-ZIP_20250911_161555",
r"C:\CONAV TRADER\PASTAS DO BACKUP",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADER TESTER ONE CLICK",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS ATUALIZADOS",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV_TRADER_FULL2",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\INSTALL CONAV TRADERFULL",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\INSTALL SETUP CONAV ICONS",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\UNINSTALL CONAV TRADER",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV_TRADER_FULL1",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV_TRADER_FULL2",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV_TRADER_OneClick-CONTEM ERROS",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV TRADER FULL 1.44",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV TRADER FULL 1.44\fix 1.44",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV_FULL_PROFESSIONAL_v1.45",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV_FULL_PROFESSIONAL_v1.45\fix 1.45",
r"C:\MAGIC QUANTIC TRADER\ZIPS E VERSOES\MEGA SUITE 001",
r"C:\MAGIC QUANTIC TRADER\ZIPS E VERSOES\MQT PACKAGE COMPLETE 002",
r"C:\MAGIC QUANTIC TRADER\ZIPS E VERSOES\MQT PACKAGE COMPLETE 003",
r"C:\MAGIC QUANTIC TRADER\ZIPS E VERSOES\MQT PACKAGE COMPLETE ALL IN
ONE 004",
r"C:\MAGIC QUANTIC TRADER\ZIPS E VERSOES\MQT NEW MEGA SUITE ALL 005",
r"C:\CONAV TRADER\CONAV_TRADER\CONAV MASTER
FULL\FULLONEMASTER-INSTALL",
r"C:\CONAV TRADER\CONAV_TRADER\CONAV MASTER
FULL\FULLONEMASTER\FULLONE-MESTER",
r"C:\CONAV TRADER\CONAV_TRADER\scripts\CONAV MASTER FULL
FIX4\CONAVMASTER FIX4",
r"C:\CONAV TRADER\CONAV_TRADER\PACKAGES
OFICIAIS\CONAV_FULL_PROFESSIONAL_v1.45_fix3_pkg",
r"C:\CONAV TRADER\CONAV_TRADER\PACKAGES
OFICIAIS\CONAV_FULL_PROFESSIONAL_v1.45_fix3_pkg_1",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV_TRADER_ADVANCED_PRODUCTION\CONAV_TR
ADER",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV_TRADER_ADVANCED_PRODUCTION",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV_TRADER_FULL_1.29\INSTALL_CONAV_TRADER_
FULL1.29",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV_TRADER_FULL_1.30",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV_TRADER_FULL_1.30\CONAV_TRADER_1_30_fixed
",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV_TRADER_FULL_1.30\CONAV_TRADER_1_30_01fix
ed",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV_TRADER_FULL_1.31",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV_TRADER_FULL_1.32",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV_TRADER_FULL_1.33",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV_TRADER_FULL_1.34\CONAV_TRADER",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV_TRADER_FULL_1.34.1",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\CONAV-ZIPS\CONAV_TRADER_PRODUCTION_TEST",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\INSTALL CONAV TRADERFULL",
r"C:\CONAV TRADER\PASTAS DO BACKUP\CONAV TRADERS ZIPS
ATUALIZADOS\BACKUP DO 1 PS1",
r"C:\CONAV TRADER\PASTAS DO BACKUP\SCRIPTS OPCIONAIS E FUNCIONAIS",
r"C:\USERAT",
r"C:\USERAT\scripts",
r"C:\USERAT\scripts\scripts 2",
r"C:\USERAT\scripts\scripts 2\compiladao",
r"C:\USERAT\USERAT_Projeto_Completo",
r"C:\USERAT\USERAT_Projeto_Completo\scripts",
r"C:\USERAT\USERAT_Projeto_Completo\scripts\scripts 2",
r"C:\USERAT\USERAT_Projeto_Completo\scripts\scripts 2\compiladao",
r"C:\USERAT\USERAT_Projeto_Completo\tutoriais",
r"C:\USERAT1",
r"C:\ACESSO A PASTA WINAPP\1",
r"C:\USERAT1\USERAT_Final_Atualizado",
r"C:\USERAT1\USERAT_Final_Atualizado\scripts",
r"C:\USERAT2",
r"C:\USERAT2\RAR USERASTS\USERAT_Final_Atualizado",
r"C:\USERAT2\RAR USERASTS\USERAT_Final_Atualizado\scripts",
r"C:\USERAT2\scripts",
r"C:\USERAT2\SCRPITS PS1",
r"C:\USERAT2\USERAT_Final_Atualizado",
r"C:\TESTEE 2",
r"C:\TESTEE 2\A3",
r"C:\TESTEE 2\AI_Trade_Suite",
r"C:\TESTEE 2\ARQUIVOS",
r"C:\TESTEE 2\ARQUIVOS\2 ADVANCED",
r"C:\TESTEE 3\AI_Trade_Suite_Full_Deliverable",
r"C:\TST DE API E SOFT\ai trade suite\AI_Trade_Suite",
r"C:\AAAAAAAA",
r"C:\AAAAAAAA\AI_Trade_Suite_Expanded (3)",
r"C:\UNIC QUANTIC",
r"C:\UNIC QUANTIC\$",
r"C:\UNIC QUANTIC\backend",
r"C:\UNIC QUANTIC\database",
r"C:\UNIC QUANTIC\frontend",
r"C:\UNIC QUANTIC\logs",
r"C:\UNIC QUANTIC\pdfs",
r"C:\UNIC QUANTIC\scripts",
r"C:\UNIC QUANTIC\scripts\SCRIPTS OPCIONAIS",
r"C:\UNIC QUANTIC\scripts\SETUP UNIC PARTE 1",
r"C:\UNIC QUANTIC\tools",
r"C:\Users\arati\OneDrive\Área de Trabalho\1",
]
# -------------------------
# Helpers
# -------------------------
LOGFILE = PASTA_LOGS /
f"fullone_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
def log(msg, level="INFO"):
ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
line = f"[{ts}][{level}] {msg}"
print(line)
try:
with open(LOGFILE, "a", encoding="utf-8") as lf:
lf.write(line + "\n")
except Exception:
pass
def ensure_dir(p: Path):
try:
p.mkdir(parents=True, exist_ok=True)
except Exception:
pass
def read_text_try_encodings(path: Path):
for enc in ("utf-8","cp1252","latin-1"):
try:
return path.read_text(encoding=enc), enc
except Exception:
continue
try:
data = path.read_bytes()
return data.decode("utf-8", errors="ignore"), "utf-8-ignore"
except Exception:
return None, None
def extract_version(text: str):
if not text:
return None
patterns = [
r'(?i)version\s*[:=]\s*([\w\.\-]+)',
r'(?i)vers[oã]o\s*[:=]\s*([\w\.\-]+)',
r'(?i)\bv\s?(\d+\.\d+(?:\.\d+)*)\b'
]
for p in patterns:
m = re.search(p, text)
if m:
return m.group(1)
return None
def cmp_versions(a, b):
# returns 1 if a>b, -1 if a<b, 0 equal (numeric parts)
if a is None and b is None: return 0
if a is None: return -1
if b is None: return 1
parts_a = [int(x) for x in re.findall(r'\d+', a)]
parts_b = [int(x) for x in re.findall(r'\d+', b)]
la, lb = len(parts_a), len(parts_b)
for i in range(max(la, lb)):
va = parts_a[i] if i < la else 0
vb = parts_b[i] if i < lb else 0
if va > vb: return 1
if va < vb: return -1
return 0
# -------------------------
# Core functions
# -------------------------
def find_scripts(paths):
found = []
for p in paths:
pth = Path(p)
if not pth.exists():
log(f"Search path not found (skipped): {p}", "WARN")
continue
for ext in ("*.ps1","*.py"):
for f in pth.rglob(ext):
if f.is_file():
found.append(f.resolve())
return found
def choose_latest_by_name(files):
byname = {}
for f in files:
key = f.name.lower()
txt, enc = read_text_try_encodings(f)
ver = extract_version(txt) if txt else None
mtime = f.stat().st_mtime
if key not in byname:
byname[key] = (f, ver, mtime)
else:
existing = byname[key]
# prefer explicit version
if ver and existing[1]:
c = cmp_versions(ver, existing[1])
if c > 0:
byname[key] = (f, ver, mtime)
elif c == 0 and mtime > existing[2]:
byname[key] = (f, ver, mtime)
elif ver and not existing[1]:
byname[key] = (f, ver, mtime)
elif not ver and existing[1]:
# keep existing which has explicit version
pass
else:
# no version info on both, pick latest mtime
if mtime > existing[2]:
byname[key] = (f, ver, mtime)
selected = [v[0] for v in byname.values()]
return selected, byname
def create_unified(selected_files, out_dir: Path):
ensure_dir(out_dir)
ts = datetime.now().strftime("%Y%m%d_%H%M%S")
unified_name = f"ONEFULL_{VERSAO_FULLONE}_{ts}.ps1"
unified_path = out_dir / unified_name
try:
with open(unified_path, "w", encoding="utf-8") as out:
out.write(f"# ONEFULL unified - {VERSAO_FULLONE}\n")
out.write(f"# Generated: {datetime.now().isoformat()}\n\n")
for f in selected_files:
txt, enc = read_text_try_encodings(f)
out.write("#" * 70 + "\n")
out.write(f"# START: {f}\n")
out.write("#" * 70 + "\n")
if f.suffix.lower() == ".py":
out.write(f"<# PYTHON SOURCE START: {f.name} #>\n")
out.write(txt if txt else "")
out.write(f"\n<# PYTHON SOURCE END: {f.name} #>\n\n")
else:
out.write(txt if txt else "")
out.write("\n\n")
# create stable copy ONEFULL.ps1
stable = out_dir / "ONEFULL.ps1"
try:
shutil.copy2(unified_path, stable)
except Exception:
pass
log(f"Unified created: {unified_path}", "OK")
return unified_path, stable
except Exception as e:
log(f"Failed to create unified: {e}", "ERROR")
return None, None
def write_txt_refs(selected_files, txt_dir: Path):
ensure_dir(txt_dir)
txt_paths = []
for f in selected_files:
try:
txt, enc = read_text_try_encodings(f)
dest = txt_dir / (f.name + ".txt")
with open(dest, "w", encoding="utf-8") as w:
w.write(f"# Reference of: {f}\n# encoding: {enc}\n\n")
if txt:
w.write(txt)
txt_paths.append(dest)
except Exception as e:
log(f"Failed txt ref for {f}: {e}", "WARN")
return txt_paths
def make_zip(unified_file: Path, txt_refs, extras, out_dir: Path):
ensure_dir(out_dir)
ts = datetime.now().strftime("%Y%m%d_%H%M%S")
zip_name = f"{VERSAO_FULLONE}_{ts}.zip"
zip_path = out_dir / zip_name
try:
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
if unified_file and unified_file.exists():
zf.write(unified_file, arcname=f"UNIFIED/{unified_file.name}")
for t in txt_refs or []:
if t.exists(): zf.write(t, arcname=f"REFERENCE_TXT/{t.name}")
for e in extras or []:
if e.exists(): zf.write(e, arcname=f"EXTRAS/{e.name}")
# include the generator itself if available
try:
selfpath = Path(__file__).resolve()
zf.write(selfpath, arcname=f"TOOLS/{selfpath.name}")
except Exception:
pass
log(f"ZIP created: {zip_path}", "OK")
return zip_path
except Exception as e:
log(f"ZIP failed: {e}", "ERROR")
return None
def generate_diagram(png_out_dir: Path):
ensure_dir(png_out_dir)
base = png_out_dir / ("flow_" + datetime.now().strftime("%Y%m%d_%H%M%S"))
png_path = base.with_suffix(".png")
if HAVE_GRAPHVIZ:
try:
dot = graphviz.Digraph(comment='FULLONE Flow')
dot.attr(rankdir='LR', size='8,3')
dot.node('start','Start', shape='ellipse')
dot.node('scan','Scan .ps1 & .py', shape='box')
dot.node('dedup','Deduplicate / Select latest', shape='box')
dot.node('unify','Unify into ONEFULL', shape='box')
dot.node('txt','Create .txt refs', shape='box')
dot.node('zip','Create ZIP package', shape='box')
dot.node('pdf','Generate PDF report', shape='box')
dot.edges([('start','scan'),('scan','dedup'),('dedup','unify'),('unify','txt'),('txt','zip'),('zip','pdf')])
dot.render(str(base), format='png', cleanup=True)
if png_path.exists():
log("Diagram generated via Graphviz", "OK")
return png_path
except Exception as e:
log(f"Graphviz render failed: {e}", "WARN")
# fallback to simple PIL drawing
if HAVE_PIL:
try:
img = Image.new('RGB', (1200, 250), color=(18,18,30))
draw = ImageDraw.Draw(img)
try:
fnt = ImageFont.truetype("arial.ttf", 16)
except Exception:
fnt = ImageFont.load_default()
text = "FULLONE Flow: Scan -> Dedup -> Unify -> TXT -> ZIP -> PDF"
draw.text((20,20), text, fill=(220,220,255), font=fnt)
# simple boxes
steps = ["Scan", "Dedup", "Unify", "TXT", "ZIP", "PDF"]
x = 20
y = 80
for s in steps:
draw.rectangle([x,y,x+160,y+50], outline=(100,200,250))
w,h = draw.textsize(s, font=fnt)
draw.text((x+80-w/2, y+25-h/2), s, fill=(200,240,255), font=fnt)
x += 180
img.save(png_path)
log("Diagram generated via PIL fallback", "OK")
return png_path
except Exception as e:
log(f"PIL diagram failed: {e}", "WARN")
# last resort: create empty file
try:
png_path.write_bytes(b"")
except Exception:
pass
return png_path
def generate_pdf(all_files, selected_files, unified_file: Path, zip_file: Path, diagram_png:
Path, txt_refs, out_dir: Path):
ensure_dir(out_dir)
pdf_name =
f"{VERSAO_FULLONE}_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
pdf_path = out_dir / pdf_name
pdf = FPDF(orientation='P', unit='mm', format='A4')
pdf.set_auto_page_break(auto=True, margin=12)
pdf.add_page()
pdf.set_font("Arial", "B", 16)
pdf.cell(0, 10, f"FULLONE Report - {VERSAO_FULLONE}", ln=True, align="C")
pdf.ln(4)
total = len(all_files)
ps1_total = len([x for x in all_files if x.suffix.lower() == ".ps1"])
py_total = len([x for x in all_files if x.suffix.lower() == ".py"])
sel_total = len(selected_files)
pdf.set_font("Arial", "", 11)
pdf.multi_cell(0, 6, (f"Scan summary:\nTotal files found: {total}\n"
f"PS1 found: {ps1_total}\nPY found: {py_total}\n"
f"Selected (latest per name): {sel_total}\n\n"
f"Unified: {unified_file.name if unified_file else 'N/A'}\n"
f"ZIP: {zip_file.name if zip_file else 'N/A'}\n"))
pdf.ln(4)
# Diagram
try:
if diagram_png and diagram_png.exists():
pdf.set_font("Arial", "B", 12)
pdf.cell(0, 6, "Process Diagram", ln=True)
pdf.image(str(diagram_png), w=170)
pdf.ln(3)
except Exception:
pdf.set_font("Arial", "", 10)
pdf.cell(0, 6, "(diagram not available)", ln=True)
# Sample selected file names
pdf.set_font("Arial", "B", 12)
pdf.cell(0, 6, "Selected files (sample):", ln=True)
pdf.set_font("Arial", "", 10)
sample_names = [s.name for s in selected_files[:60]]
pdf.multi_cell(0, 5, " ; ".join(sample_names))
pdf.ln(4)
# Quick tutorial
pdf.set_font("Arial", "B", 12)
pdf.cell(0, 6, "Quick tutorial", ln=True)
pdf.set_font("Arial", "", 10)
pdf.multi_cell(0, 5, ("This tool searches configured folders for .ps1 and .py files, chooses
the latest version\n"
"for each filename (preferring embedded version stamps when present),
unifies them into a\n"
"ONEFULL.ps1, produces .txt reference copies and packages everything into
a ZIP.\n"))
pdf.add_page()
# Appendix: snippets
pdf.set_font("Arial", "B", 12)
pdf.cell(0, 6, "Appendix: file snippets (first ~1200 chars)", ln=True)
pdf.set_font("Arial", "", 9)
for f in selected_files[:40]:
try:
txt, enc = read_text_try_encodings(f)
snippet = (txt[:1200] + "...") if txt and len(txt) > 1200 else (txt or "")
pdf.set_font("Arial", "B", 10)
pdf.cell(0, 5, f"{f.name} ({enc})", ln=True)
pdf.set_font("Arial", "", 8)
pdf.multi_cell(0, 4, snippet)
pdf.ln(2)
except Exception:
continue
# Save PDF
try:
pdf.output(str(pdf_path))
log(f"PDF generated: {pdf_path}", "OK")
except Exception as e:
log(f"PDF generation failed: {e}", "WARN")
return pdf_path
# -------------------------
# Auto-update generator from OFFICIAL folder (optional)
# -------------------------
def auto_update_generator():
official = PASTA_OFFICIAL / "criar-pacotes.py"
exec_target = PASTA_EXEC / "criar-pacotes.py"
if not official.exists():
log("No official creator found (auto-update skip).", "INFO")
return
try:
if not exec_target.exists() or official.read_bytes() != exec_target.read_bytes():
# backup existing
if exec_target.exists():
bkp = exec_target.with_name(exec_target.stem + "_backup_" +
datetime.now().strftime("%Y%m%d_%H%M%S") + exec_target.suffix)
shutil.copy2(exec_target, bkp)
log(f"Backup of generator saved: {bkp}", "OK")
shutil.copy2(official, exec_target)
log("Generator auto-updated from OFFICIAL.", "OK")
except Exception as e:
log(f"Auto-update failed: {e}", "WARN")
# -------------------------
# Main
# -------------------------
def main(test_mode=False):
log(f"FULLONE started. Mode test={test_mode}", "INFO")
if not test_mode:
auto_update_generator()
# find scripts
all_files = find_scripts(SEARCH_PATHS)
else:
# create local sample for testing
tmp = Path.cwd() / "fullone_sample"
ensure_dir(tmp)
(tmp / "alpha.ps1").write_text("# version: 1.0\nWrite-Host 'alpha v1.0'\n",
encoding="utf-8")
(tmp / "alpha.py").write_text("# v1.1\nprint('alpha py v1.1')\n", encoding="utf-8")
(tmp / "beta.ps1").write_text("# version: 0.9\nWrite-Host 'beta v0.9'\n", encoding="utf-8")
all_files = list(tmp.rglob("*.ps1")) + list(tmp.rglob("*.py"))
# stats
total_count = len(all_files)
ps1_count = len([f for f in all_files if f.suffix.lower() == ".ps1"])
py_count = len([f for f in all_files if f.suffix.lower() == ".py"])
log(f"Total scripts found across all search paths: {total_count}", "INFO")
log(f"PS1: {ps1_count}, PY: {py_count}", "INFO")
# pick latest per name
selected, byname = choose_latest_by_name(all_files)
log(f"Selected {len(selected)} files for unification (one per filename).", "INFO")
# create unified ps1
unified, stable = create_unified(selected, PASTA_UNIFICADOS if not test_mode else
Path.cwd() / "out_unified")
# write txt refs
txt_refs = write_txt_refs(selected, PASTA_TXT_REF if not test_mode else Path.cwd() /
"out_txts")
# extras: add tutorial PDFs if exist in PASTA_EXEC
extras = []
for pdfn in ("TUTORIAL.pdf","GUIA-RÁPIDO.pdf","MANUAL.pdf"):
p = PASTA_EXEC / pdfn
if test_mode:
# skip
pass
else:
if p.exists(): extras.append(p)
# make zip
zipf = make_zip(unified, txt_refs, extras, PASTA_PACKAGE if not test_mode else
Path.cwd() / "out_package")
# generate diagram
diagram = generate_diagram(PASTA_DIAGRAMA if not test_mode else Path.cwd() /
"out_diagram")
# generate PDF
pdf = generate_pdf(all_files, selected, unified, zipf, diagram, txt_refs, PASTA_DIAGRAMA
if not test_mode else Path.cwd() / "out_pdf")
# final summary
log("FULLONE finished.", "OK")
log(f"Artifacts:\n - unified: {unified}\n - stable: {stable}\n - zip: {zipf}\n - pdf: {pdf}", "INFO")
return {
"unified": unified, "stable": stable, "zip": zipf, "pdf": pdf,
"total": total_count, "ps1": ps1_count, "py": py_count, "selected": len(selected)
}
if __name__ == "__main__":
TEST = "--test" in sys.argv
res = main(test_mode=TEST)
# print a small console summary
print("\n==== SUMMARY ====")
print(f"Total scanned: {res['total']}")
print(f".ps1 found: {res['ps1']}")
print(f".py found: {res['py']}")
print(f"Files selected for unify: {res['selected']}")
print(f"Unified file: {res['unified']}")
print(f"ZIP: {res['zip']}")
print(f"PDF: {res['pdf']}")
print("=================\n")