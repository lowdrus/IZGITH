import os
import shutil
import zipfile
from pathlib import Path
from datetime import datetime
from fpdf import FPDF

# --------------------------
# CONFIGURAÇÕES DE PASTAS
# --------------------------
PASTAS_PROCURAR = [
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

PASTA_SOLTOS = r"C:\SCRIPTS\FULL ONE\FULL ONE GENERATOR"
PASTA_UNIFICADO = r"C:\SCRIPTS\FULL ONE\ARQUIVOS .PS1 UNIFICADOS"
PASTA_COMPILADOS = r"C:\SCRIPTS\FULL ONE\COMPILADOS"
PASTA_PACKAGE = r"C:\SCRIPTS\FULL ONE\PACKAGE"
PASTA_OFICIAL = r"C:\SCRIPTS\FULL ONE\OFFICIAL"

VERSAO_FULLONE = "FULLONEv14fixed2"

# --------------------------
# CRIAR PASTAS SE NÃO EXISTIREM
# --------------------------
for pasta in [PASTA_SOLTOS, PASTA_UNIFICADO, PASTA_COMPILADOS, PASTA_PACKAGE]:
    os.makedirs(pasta, exist_ok=True)

# --------------------------
# FUNÇÕES
# --------------------------
def atualizar_script_oficial():
    """Atualiza o criar-pacotes.py com a última versão oficial"""
    oficiais = list(Path(PASTA_OFICIAL).glob("criar-pacotes*.py"))
    if not oficiais:
        return None
    ultima_oficial = max(oficiais, key=os.path.getmtime)
    scripts_exec = list(Path(PASTA_SOLTOS).glob("criar-pacotes*.py"))

    # Determina nome incremental
    if scripts_exec:
        numeros = [int(s.stem.replace("criar-pacotes", "")) for s in scripts_exec if s.stem.replace("criar-pacotes","").isdigit()]
        next_num = max(numeros) + 1 if numeros else 1
    else:
        next_num = 1
    novo_nome = Path(PASTA_SOLTOS) / f"criar-pacotes{str(next_num).zfill(4)}.py"

    # Backup antigo
    for s in scripts_exec:
        backup_nome = s.with_name(s.stem + "_backup.py")
        shutil.move(s, backup_nome)

    # Copia oficial
    shutil.copy2(ultima_oficial, novo_nome)
    print(f"[INFO] Script atualizado automaticamente para: {novo_nome}")
    return novo_nome

def buscar_arquivos():
    """Busca arquivos .ps1 e .py nas pastas definidas"""
    todos_arquivos = []
    for pasta in PASTAS_PROCURAR:
        base = Path(pasta)
        if base.exists():
            for ext in ("*.ps1", "*.py"):
                encontrados = list(base.rglob(ext))
                todos_arquivos.extend(encontrados)
    return todos_arquivos

def criar_unificado(arquivos):
    """Cria arquivo ONEFULL.ps1 unificado"""
    os.makedirs(PASTA_UNIFICADO, exist_ok=True)
    unificado_path = Path(PASTA_UNIFICADO) / "ONEFULL.ps1"

    # Backup antigo
    if unificado_path.exists():
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = unificado_path.with_name(f"{unificado_path.stem}_backup_{timestamp}.ps1")
        shutil.move(unificado_path, backup_path)

    cabecalho = f"# =============================================\n# {VERSAO_FULLONE} - PS1 Unificado (ONEFULL)\n# Gerado em {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n# =============================================\n"
    with open(unificado_path, 'w', encoding='utf-8') as f:
        f.write(cabecalho)
        for arquivo in arquivos:
            try:
                with open(arquivo, 'r', encoding='utf-8') as af:
                    f.write(f"\n# ===== INICIO {arquivo.name} =====\n")
                    f.write(af.read() + "\n")
                    f.write(f"# ===== FIM {arquivo.name} =====\n")
            except Exception as e:
                print(f"[ERRO] Não foi possível ler {arquivo}: {e}")

    print(f"[INFO] PS1 unificado criado em: {unificado_path}")
    return unificado_path

def criar_zip(unificado_path):
    """Cria ZIP do pacote completo, incrementando o nome"""
    os.makedirs(PASTA_PACKAGE, exist_ok=True)
    i = 1
    while True:
        zip_name = f"{VERSAO_FULLONE}_{i:04d}.zip"
        zip_path = Path(PASTA_PACKAGE) / zip_name
        if not zip_path.exists():
            break
        i += 1

    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        zf.write(unificado_path, arcname=unificado_path.name)
        for arquivo in Path(PASTA_SOLTOS).glob("*"):
            zf.write(arquivo, arcname=arquivo.name)

    print(f"[INFO] ZIP criado em: {zip_path}")
    return zip_path

def gerar_pdf(todos_arquivos, zip_path):
    """Gera PDF detalhado do pacote"""
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", "B", 16)
    pdf.set_text_color(0, 0, 128)
    pdf.cell(0, 10, f"FULLONE - Pacote {VERSAO_FULLONE}", ln=True, align="C")
    pdf.set_font("Arial", "", 12)
    pdf.set_text_color(0,0,0)
    pdf.ln(5)
    pdf.cell(0,10,f"Gerado em: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", ln=True)
    pdf.cell(0,10,f"ZIP: {zip_path.name}", ln=True)
    pdf.cell(0,10,f"Total de arquivos encontrados: {len(todos_arquivos)}", ln=True)
    pdf.ln(5)

    pdf.set_font("Arial", "B", 12)
    pdf.set_fill_color(200, 220, 255)
    pdf.cell(0, 8, "Pastas pesquisadas", ln=True, fill=True)
    pdf.set_font("Arial", "", 10)
    for p in PASTAS_PROCURAR:
        pdf.cell(0, 6, str(p), ln=True)

    pdf.ln(5)
    pdf.set_font("Arial", "B", 12)
    pdf.set_fill_color(255, 220, 200)
    pdf.cell(0, 8, "Arquivos encontrados", ln=True, fill=True)
    pdf.set_font("Arial", "", 10)
    for f in todos_arquivos:
        pdf.cell(0, 6, str(f), ln=True)

    pdf_output = Path(PASTA_PACKAGE) / f"{VERSAO_FULLONE}_info.pdf"
    pdf.output(pdf_output)
    print(f"[INFO] PDF gerado em: {pdf_output}")
    return pdf_output

# --------------------------
# EXECUÇÃO
# --------------------------
if __name__ == "__main__":
    print(f"=== GERADOR AUTOMÁTICO {VERSAO_FULLONE} ===\n")

    # Atualiza script automaticamente
    atualizar_script_oficial()

    # Busca arquivos .ps1 e .py
    todos_arquivos = buscar_arquivos()
    print(f"[INFO] Total de arquivos encontrados: {len(todos_arquivos)}")

    # Cria arquivo unificado
    unificado = criar_unificado(todos_arquivos)

    # Cria ZIP incremental
    zip_path = criar_zip(unificado)

    # Gera PDF detalhado
    gerar_pdf(todos_arquivos, zip_path)

    print("\n=== PROCESSO CONCLUÍDO ✅ ===")