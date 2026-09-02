import os
import shutil
import zipfile
import glob
from datetime import datetime
from fpdf import FPDF
from pathlib import Path
import subprocess

# -----------------------------
# CONFIGURAÇÕES DE PASTAS
# -----------------------------
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
    r"C:\MAGIC QUANTIC TRADER\MQT PACKAGE COMPLETE ALL IN ONE 004",
    r"C:\USERAT",
    r"C:\USERAT\scripts",
    r"C:\TESTEE 2\AI_Trade_Suite",
    r"C:\UNIC QUANTIC",
]

PASTA_OFICIAL = r"C:\SCRIPTS\FULL ONE\OFFICIAL"
PASTA_SOLTOS = r"C:\SCRIPTS\FULL ONE\FULL ONE GENERATOR"
PASTA_UNIFICADO = r"C:\SCRIPTS\FULL ONE\ARQUIVOS .PS1 UNIFICADOS"
PASTA_COMPILADOS = r"C:\SCRIPTS\FULL ONE\COMPILADOS"
PASTA_PACKAGE = r"C:\SCRIPTS\FULL ONE\PACKAGE"
PASTA_PDF = r"C:\SCRIPTS\FULL ONE\DIAGRAMA VISUAL"

VERSAO = "FULLONEv14fixed2"
NOME_UNIFICADO = "ONEFULL.ps1"

# -----------------------------
# CRIAR PASTAS SE NÃO EXISTIREM
# -----------------------------
for pasta in [PASTA_SOLTOS, PASTA_UNIFICADO, PASTA_COMPILADOS, PASTA_PACKAGE, PASTA_PDF]:
    os.makedirs(pasta, exist_ok=True)

# -----------------------------
# FUNÇÕES
# -----------------------------

def atualizar_script():
    """Atualiza automaticamente a versão do criar-pacotes se houver oficial"""
    oficial = os.path.join(PASTA_OFICIAL, "criar-pacotes.py")
    destino = os.path.join(PASTA_SOLTOS, "criar-pacotes.py")

    if not os.path.exists(oficial):
        print(f"[AVISO] Nenhum script oficial encontrado em: {PASTA_OFICIAL}")
        return

    atualizar = False
    if not os.path.exists(destino):
        atualizar = True
    else:
        with open(oficial, "rb") as f1, open(destino, "rb") as f2:
            if f1.read() != f2.read():
                atualizar = True

    if atualizar:
        if os.path.exists(destino):
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup = destino.replace(".py", f"_backup_{timestamp}.py")
            shutil.move(destino, backup)
            print(f"[INFO] Backup do script antigo: {backup}")
        shutil.copy2(oficial, destino)
        print(f"[INFO] Script atualizado para versão oficial.")

def buscar_arquivos(exts=(".ps1", ".py")):
    todos = []
    for pasta in PASTAS_PROCURA:
        if os.path.exists(pasta):
            for ext in exts:
                todos.extend(Path(pasta).rglob(f"*{ext}"))
    return todos

def criar_unificado(arquivos):
    unificado_path = Path(PASTA_UNIFICADO) / NOME_UNIFICADO
    if unificado_path.exists():
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup = unificado_path.with_name(f"{unificado_path.stem}_backup_{timestamp}.ps1")
        shutil.move(unificado_path, backup)
        print(f"[INFO] Backup do PS1 unificado antigo: {backup}")

    total_ps1 = total_py = 0
    with open(unificado_path, "w", encoding="utf-8") as f:
        f.write(f"# {VERSAO} - ONEFULL Unificado\n# Gerado: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        for arquivo in arquivos:
            try:
                conteudo = arquivo.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                conteudo = arquivo.read_text(encoding="latin-1")
            f.write(f"# ===== {arquivo.name} =====\n")
            f.write(conteudo + "\n# ===== FIM {arquivo.name} =====\n\n")
            if arquivo.suffix.lower() == ".ps1":
                total_ps1 += 1
            elif arquivo.suffix.lower() == ".py":
                total_py += 1
    print(f"[INFO] PS1 unificado criado: {unificado_path}")
    return unificado_path, total_ps1, total_py

def criar_zip(unificado_path):
    i = 1
    while True:
        zip_name = f"{VERSAO}_{i:04d}.zip"
        zip_path = Path(PASTA_PACKAGE) / zip_name
        if not zip_path.exists():
            break
        i += 1

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.write(unificado_path, arcname=NOME_UNIFICADO)
        for arquivo in Path(PASTA_SOLTOS).iterdir():
            if arquivo.is_file():
                zf.write(arquivo, arcname=arquivo.name)
    print(f"[INFO] ZIP criado: {zip_path}")
    return zip_path

def gerar_pdf(todos_arquivos, total_ps1, total_py):
    pdf_path = Path(PASTA_PDF) / f"{VERSAO}_relatorio_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    pdf = FPDF()
    pdf.add_page()

    pdf.set_font("Arial", "B", 16)
    pdf.set_text_color(0, 51, 102)
    pdf.cell(0, 10, f"{VERSAO} - Relatório Completo", 0, 1, 'C')
    pdf.ln(5)

    pdf.set_font("Arial", "", 12)
    pdf.set_text_color(0, 0, 0)
    pdf.multi_cell(0, 7, f"Data de geração: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    pdf.ln(5)

    pdf.set_font("Arial", "B", 14)
    pdf.set_text_color(255, 102, 0)
    pdf.cell(0, 10, "Resumo de Arquivos", 0, 1)
    pdf.set_font("Arial", "", 12)
    pdf.multi_cell(0, 7, f"Total arquivos encontrados: {len(todos_arquivos)}\nArquivos .PS1: {total_ps1}\nArquivos .PY: {total_py}\nArquivos unificados .PS1: {total_ps1}\nArquivos unificados .PY: {total_py}")
    pdf.ln(5)

    pdf.set_font("Arial", "B", 14)
    pdf.set_text_color(0, 102, 51)
    pdf.cell(0, 10, "Pastas Pesquisadas", 0, 1)
    pdf.set_font("Arial", "", 12)
    for p in PASTAS_PROCURA:
        pdf.multi_cell(0, 6, f"- {p}")

    pdf.output(pdf_path)
    print(f"[INFO] PDF gerado: {pdf_path}")
    return pdf_path

# -----------------------------
# EXECUÇÃO PRINCIPAL
# -----------------------------
if __name__ == "__main__":
    print(f"=== FULLONE - AUTÔNOMO AVANÇADO ({VERSAO}) ===\n")

    atualizar_script()

    todos_arquivos = buscar_arquivos()
    print(f"[INFO] Total arquivos encontrados: {len(todos_arquivos)}")

    unificado_path, total_ps1, total_py = criar_unificado(todos_arquivos)
    zip_path = criar_zip(unificado_path)
    pdf_path = gerar_pdf(todos_arquivos, total_ps1, total_py)

    print("\n=== PROCESSO COMPLETO CONCLUÍDO ✅ ===")