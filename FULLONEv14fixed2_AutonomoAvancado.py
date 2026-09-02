#!/usr/bin/env python3
# FULLONE Autônomo Avançado - FULLONEv14fixed2
# Busca, analisa, unifica, faz backup, gera ZIP e PDF com fluxograma e relatórios.
# Gera arquivos .txt de referência dos scripts e inclui tudo no ZIP.
# Requisitos: Python 3.8+, packages: fpdf, graphviz, pillow (for future image work)
# Graphviz ("dot") must be installed and available on PATH for fluxograma rendering.

import os
import shutil
import zipfile
import glob
import re
from pathlib import Path
from datetime import datetime
from fpdf import FPDF
import graphviz

# -------------------------
# Configurações (personalize se precisar)
# -------------------------
VERSAO_FULLONE = "FULLONEv14fixed2"
# NOTE: these are Windows-style folders. Adjust if necessary.
PASTA_OFICIAL = Path(r"C:\SCRIPTS\FULL ONE\OFFICIAL")
PASTA_EXEC = Path(r"C:\SCRIPTS\FULL ONE\FULL ONE GENERATOR")
PASTA_UNIFICADOS = Path(r"C:\SCRIPTS\FULL ONE\ARQUIVOS .PS1 UNIFICADOS")
PASTA_PACKAGE = Path(r"C:\SCRIPTS\FULL ONE\PACKAGE")
PASTA_COMPILADOS = Path(r"C:\SCRIPTS\FULL ONE\COMPILADOS")
PASTA_DIAGRAMA = Path(r"C:\SCRIPTS\FULL ONE\DIAGRAMA VISUAL")
PASTA_TXT_REF = PASTA_DIAGRAMA / "SCRIPTS_TXT_REF"
PASTA_TUTORIALS = Path(r"C:\SCRIPTS\FULL ONE\FULL ONE GENERATOR")  # where Tutorial.pdf may be placed

# Lista completa de pastas a procurar (adicionadas conforme solicitado)
PASTAS_PROCURA = [
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
    r"C:\CONAV TRADER\CONAV_TRADER\build\uninstall_wrapper\base_library.zip\collections",
    r"C:\CONAV TRADER\CONAV_TRADER\build\uninstall_wrapper\base_library.zip\re",
    r"C:\CONAV TRADER\CONAV_TRADER\build\uninstall_wrapper\base_library.zip\encodings",
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
    r"C:\CONAV TRADER\PASTA DO BACKUP\\CONAV TRADES ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV-ZIP_20250911_160904",
    r"C:\CONAV TRADER\PASTA DO BACKUP\\CONAV TRADES ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV-ZIP_20250911_161555",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADER TESTER ONE CLICK",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV_TRADER_FULL2",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\INSTALL CONAV  TRADERFULL",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\INSTALL SETUP CONAV ICONS",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\UNINSTALL CONAV TRADER",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV_TRADER_FULL1",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV_TRADER_FULL2",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV_TRADER_OneClick-CONTEM ERROS",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV TRADER FULL 1.44",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV TRADER FULL 1.44\\fix 1.44",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV_FULL_PROFESSIONAL_v1.45",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV_FULL_PROFESSIONAL_v1.45\\fix 1.45",
    r"C:\MAGIC QUANTIC TRADER\\MEGA SUITE 001",
    r"C:\MAGIC QUANTIC TRADER\\MQT PACKAGE COMPLETE 002",
    r"C:\MAGIC QUANTIC TRADER\\MQT PACKAGE COMPLETE 003",
    r"C:\MAGIC QUANTIC TRADER\\MQT PACKAGE COMPLETE ALL IN ONE 004",
    r"C:\CONAV TRADER\CONAV_TRADER\CONAV MASTER FULL\\FULLONEMASTER-INSTALL",
    r"C:\CONAV TRADER\CONAV_TRADER\CONAV MASTER FULL\\FULLONEMASTER\\FULLONE-MESTER",
    r"C:\CONAV TRADER\CONAV_TRADER\scripts\\CONAV MASTER FULL FIX4\\CONAVMASTER FIX4",
    r"C:\CONAV TRADER\CONAV_TRADER\PACKAGES OFICIAIS\\CONAV_FULL_PROFESSIONAL_v1.45_fix3_pkg",
    r"C:\CONAV TRADER\CONAV_TRADER\PACKAGES OFICIAIS\\CONAV_FULL_PROFESSIONAL_v1.45_fix3_pkg_1",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV_TRADER_ADVANCED_PRODUCTION\\CONAV_TRADER",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV_TRADER_ADVANCED_PRODUCTION",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV_TRADER_FULL_1.29\\INSTALL_CONAV_TRADER_FULL1.29",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV_TRADER_FULL_1.30",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV_TRADER_FULL_1.30\\CONAV_TRADER_1_30_fixed",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV_TRADER_FULL_1.30\\CONAV_TRADER_1_30_01fixed",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV_TRADER_FULL_1.31",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV_TRADER_FULL_1.32",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV_TRADER_FULL_1.33",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV_TRADER_FULL_1.34\\CONAV_TRADER",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV_TRADER_FULL_1.34.1",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\CONAV-ZIPS\\CONAV_TRADER_PRODUCTION_TEST",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\INSTALL CONAV  TRADERFULL",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\CONAV TRADERS ZIPS ATUALIZADOS\\BACKUP DO 1 PS1",
    r"C:\CONAV TRADER\PASTAS DO  BACKUP\\SCRIPTS OPCIONAIS E FUNCIONAIS",
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
    r"C:\TESTEE 2\ARQUIVOS\Output",
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
]

# Utility functions
def ensure_dirs():
    for p in [PASTA_EXEC, PASTA_UNIFICADOS, PASTA_PACKAGE, PASTA_COMPILADOS, PASTA_DIAGRAMA, PASTA_TXT_REF]:
        try:
            p.mkdir(parents=True, exist_ok=True)
        except Exception:
            pass

def read_text_file_try_encodings(path):
    # try utf-8 then cp1252
    for enc in ("utf-8", "cp1252", "latin-1"):
        try:
            with open(path, "r", encoding=enc, errors="strict") as f:
                return f.read(), enc
        except UnicodeDecodeError:
            continue
        except Exception:
            break
    # last resort, binary read and decode ignoring errors
    try:
        with open(path, "rb") as f:
            data = f.read()
        return data.decode("utf-8", errors="ignore"), "utf-8-ignored"
    except Exception as e:
        return None, None

def extract_version_from_text(text):
    # common patterns: "version: 1.2.3", "versão: 1.2", "v1.2.3"
    if not text:
        return None
    patterns = [
        r"(?i)version\s*[:=]\s*([\w\.\-]+)",
        r"(?i)vers[oã]o\s*[:=]\s*([\w\.\-]+)",
        r"(?i)\bv\s?(\d+\.\d+(?:\.\d+)*)\b"
    ]
    for p in patterns:
        m = re.search(p, text)
        if m:
            return m.group(1)
    return None

def compare_versions(a, b):
    # try to compare semantic-like versions, else compare lexicographically
    def norm(v):
        parts = re.findall(r"\d+", v) if v else []
        return [int(x) for x in parts]
    na = norm(a); nb = norm(b)
    return (na > nb) - (na < nb)  # 1 if a>b, -1 if a<b, 0 equal

# Main operations
def find_all_scripts():
    all_found = []
    for root in PASTAS_PROCURA:
        try:
            p = Path(root)
            if not p.exists():
                print(f"[WARN] Search path not found (skipped): {root}")
                continue
            for ext in ("*.ps1", "*.py"):
                for f in p.rglob(ext):
                    # skip directories inside zips etc (rglob handles files)
                    if f.is_file():
                        all_found.append(f.resolve())
        except Exception as ex:
            print(f"[WARN] Error scanning {root}: {ex}")
    return all_found

def pick_latest_versions(files):
    # Build mapping by filename (lowercase); choose latest by embedded version if available, otherwise mtime
    byname = {}
    for f in files:
        key = f.name.lower()
        txt, enc = read_text_file_try_encodings(f)
        ver = extract_version_from_text(txt) if txt else None
        mtime = f.stat().st_mtime
        existing = byname.get(key)
        if existing is None:
            byname[key] = (f, ver, mtime)
        else:
            # compare versions if both have versions
            if ver and existing[1]:
                cmp = compare_versions(ver, existing[1])
                if cmp > 0:
                    byname[key] = (f, ver, mtime)
                elif cmp == 0 and mtime > existing[2]:
                    byname[key] = (f, ver, mtime)
            elif ver and not existing[1]:
                byname[key] = (f, ver, mtime)
            elif not ver and existing[1]:
                # keep existing which had explicit version
                pass
            else:
                # compare by mtime
                if mtime > existing[2]:
                    byname[key] = (f, ver, mtime)
    # return list of files selected plus map of duplicates for report
    duplicates = {}
    selected = []
    for key, val in byname.items():
        selected.append(val[0])
    return selected, byname

def create_unified_ps1(selected_files):
    ensure_dirs()
    unified = PASTA_UNIFICADOS / f"ONEFULL_{VERSAO_FULLONE}.ps1"
    # backup previous if exists (without version in name)
    fallback = PASTA_UNIFICADOS / "ONEFULL.ps1"
    if fallback.exists():
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        bak = PASTA_UNIFICADOS / f"ONEFULL_backup_{ts}.ps1"
        shutil.move(str(fallback), str(bak))
        print(f"[INFO] Old ONEFULL.ps1 moved to backup: {bak}")
    # write unified file
    with open(unified, "w", encoding="utf-8") as out:
        out.write(f"# ONEFULL unified - {VERSAO_FULLONE}\\n")
        out.write(f"# Generated: {datetime.now().isoformat()}\\n\\n")
        for f in selected_files:
            try:
                txt, enc = read_text_file_try_encodings(f)
                out.write("#" + "="*78 + "\\n")
                out.write(f"# START: {f}\\n")
                out.write("#" + "="*78 + "\\n")
                if f.suffix.lower() == ".py":
                    out.write("<# PYTHON SOURCE - START {0} #>\\n".format(f.name))
                    out.write(txt if txt else "") 
                    out.write("\\n<# PYTHON SOURCE - END {0} #>\\n\\n".format(f.name))
                else:
                    out.write(txt if txt else "")
                    out.write("\\n\\n")
            except Exception as ex:
                print(f"[WARN] Could not include {f}: {ex}")
    # create a stable copy named ONEFULL.ps1 (for backwards compat)
    shutil.copy2(unified, PASTA_UNIFICADOS / "ONEFULL.ps1")
    print(f"[OK] Unified PS1 created: {unified}")
    return unified

def write_txt_references(selected_files):
    ensure_dirs()
    PASTA_TXT_REF.mkdir(parents=True, exist_ok=True)
    txt_files = []
    for f in selected_files:
        try:
            txt, enc = read_text_file_try_encodings(f)
            outp = PASTA_TXT_REF / (f.name + ".txt")
            with open(outp, "w", encoding="utf-8") as w:
                w.write(f"# Reference copy of {f}\\n# source encoding used: {enc}\\n\\n")
                # write only first 2000 chars to avoid huge files, but save full in package if requested
                if txt is None:
                    w.write("# (could not read file)\\n")
                else:
                    # write full content but it's okay — user asked for text refs; in practice many files small
                    w.write(txt)
            txt_files.append(outp)
        except Exception as ex:
            print(f"[WARN] writing txt ref for {f}: {ex}")
    return txt_files

def create_zip_package(unified_file, txt_refs, extras=None):
    ensure_dirs()
    PASTA_PACKAGE.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    zipname = f"{VERSAO_FULLONE}_{ts}.zip"
    zippath = PASTA_PACKAGE / zipname
    with zipfile.ZipFile(zippath, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.write(unified_file, arcname=Path("UNIFIED") / unified_file.name)
        for t in txt_refs:
            zf.write(t, arcname=Path("REFERENCE_TXT") / t.name)
        # include tutorial files if present
        for pdfname in ("TUTORIAL.pdf","GUIA-RÁPIDO.pdf","MANUAL.pdf"):
            candidate = PASTA_TUTORIALS / pdfname
            if candidate.exists():
                zf.write(candidate, arcname=Path("TUTORIALS") / candidate.name)
        # include the generator script itself for traceability
        thisfile = Path(__file__).resolve()
        try:
            zf.write(thisfile, arcname=Path("TOOLS") / thisfile.name)
        except Exception:
            pass
    print(f"[OK] Package ZIP created: {zippath}")
    return zippath

def generate_flow_diagram():
    ensure_dirs()
    dot = graphviz.Digraph(comment='FULLONE Flow')
    dot.attr(rankdir='LR', fontsize='10')
    dot.node('start', 'Start')
    dot.node('scan', 'Scan folders for .ps1/.py')
    dot.node('dedup', 'Detect duplicates\npick latest')
    dot.node('unify', 'Unify scripts\ncreate ONEFULL.ps1')
    dot.node('txt', 'Create .txt refs')
    dot.node('zip', 'Create ZIP package')
    dot.node('pdf', 'Generate PDF report')
    dot.edges([('start','scan'),('scan','dedup'),('dedup','unify'),('unify','txt'),('txt','zip'),('zip','pdf')])
    diagram_base = PASTA_DIAGRAMA / f"fullone_flow_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    dot.render(str(diagram_base), format='png', cleanup=True)
    png = str(diagram_base) + ".png"
    print(f"[OK] Flow diagram generated: {png}")
    return png

def generate_pdf_report(all_files, selected_files, unified_file, zip_file, diagram_png, txt_refs):
    ensure_dirs()
    pdf_path = PASTA_DIAGRAMA / f"{VERSAO_FULLONE}_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    pdf = FPDF(orientation='P', unit='mm', format='A4')
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()
    pdf.set_font("Arial", "B", 16)
    pdf.set_text_color(10, 30, 80)
    pdf.cell(0, 10, f"FULLONE Report - {VERSAO_FULLONE}", ln=True, align="C")
    pdf.ln(6)
    pdf.set_font("Arial", "", 11)
    pdf.set_text_color(0,0,0)
    total = len(all_files)
    ps1_total = len([x for x in all_files if x.suffix.lower()==".ps1"])
    py_total = len([x for x in all_files if x.suffix.lower()==".py"])
    pdf.multi_cell(0,6, f"Scan summary:\\nTotal files found: {total}\\nPS1 found: {ps1_total}\\nPY found: {py_total}\\nSelected for unification (latest versions): {len(selected_files)}")
    pdf.ln(4)
    pdf.set_font("Arial","B",12)
    pdf.cell(0,6,"Flow Diagram", ln=True)
    try:
        pdf.image(diagram_png, w=180)
    except Exception:
        pdf.set_font("Arial","",10); pdf.cell(0,6,"(diagram image not available)", ln=True)
    pdf.ln(4)
    pdf.set_font("Arial","B",12); pdf.cell(0,6,"Files included (selected latest):", ln=True)
    pdf.set_font("Arial","",9)
    for f in selected_files[:200]:  # only first 200 to avoid huge PDF; full list saved as TXT refs.
        pdf.multi_cell(0,5,str(f))
    pdf.ln(4)
    pdf.set_font("Arial","B",12); pdf.cell(0,6,"Notes and quick tutorial:", ln=True)
    pdf.set_font("Arial","",10)
    pdf.multi_cell(0,5,"This report lists files found, picks the latest versions (by embedded version string or modification date), unifies PS1/PY into a single ONEFULL ps1 file, creates reference .txt copies, and packages everything into a ZIP. Use the ZIP contents for distribution or archival.")
    pdf.ln(6)
    pdf.set_font("Arial","B",11); pdf.cell(0,6,"Where to find the reference .txt files and artifacts:", ln=True)
    pdf.set_font("Arial","",10)
    pdf.multi_cell(0,5, f"Reference text files location: {PASTA_TXT_REF}\\nUnified PS1: {unified_file}\\nZIP: {zip_file}")
    pdf.output(str(pdf_path))
    print(f"[OK] PDF report created: {pdf_path}")
    return pdf_path

def main():
    print(f"=== FULLONE Autônomo Avançado ({VERSAO_FULLONE}) ===")
    ensure_dirs()
    # Update self if official copy exists (optional)
    try:
        atualizar_script_oficial()
    except Exception as ex:
        print(f"[WARN] update step failed: {ex}")
    # find all scripts
    all_files = find_all_scripts()
    print(f"[INFO] Total scripts found across all search paths: {len(all_files)}")
    # select latest versions
    selected_files, byname = pick_latest_versions(all_files)
    print(f"[INFO] Selected files for unification (latest per name): {len(selected_files)}")
    # create unified ps1
    unified = create_unified_ps1(selected_files)
    # write txt references
    txts = write_txt_references(selected_files)
    # create zip
    z = create_zip_package(unified, txts)
    # flow diagram
    diag = generate_flow_diagram()
    # generate pdf
    pdf = generate_pdf_report(all_files, selected_files, unified, z, diag, txts)
    print(\"=== FULLONE finished ===\")

if __name__ == '__main__':
    main()
