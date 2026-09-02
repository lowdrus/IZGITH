import os
import shutil
import glob
import zipfile
from pathlib import Path
from datetime import datetime
from fpdf import FPDF

# ----------------------------
# CONFIGURAÇÕES DE PASTAS
# ----------------------------
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

PASTA_SOLTOS = r"C:\SCRIPTS\FULL ONE\FULL ONE GENERATOR"
PASTA_UNIFICADO = r"C:\SCRIPTS\FULL ONE\ARQUIVOS .PS1 UNIFICADOS"
PASTA_COMPILADOS = r"C:\SCRIPTS\FULL ONE\COMPILADOS"
PASTA_PACKAGE = r"C:\SCRIPTS\FULL ONE\PACKAGE"
PASTA_PDF = r"C:\SCRIPTS\FULL ONE\DIAGRAMA VISUAL"
PASTA_OFFICIAL = r"C:\SCRIPTS\FULL ONE\OFFICIAL"

VERSAO_FULLONE = "FULLONEv14fixed2"

# ----------------------------
# CRIAR PASTAS SE NÃO EXISTIREM
# ----------------------------
for pasta in [PASTA_SOLTOS, PASTA_UNIFICADO, PASTA_COMPILADOS, PASTA_PACKAGE, PASTA_PDF]:
    os.makedirs(pasta, exist_ok=True)

# ----------------------------
# FUNÇÕES
# ----------------------------
def atualizar_script():
    """Atualiza o script atual com a versão oficial, mantendo backup"""
    arquivos_oficiais = glob.glob(os.path.join(PASTA_OFFICIAL, "criar-pacotes*.py"))
    if not arquivos_oficiais:
        print(f"[AVISO] Nenhum arquivo oficial encontrado em: {PASTA_OFFICIAL}")
        return
    arquivo_oficial = max(arquivos_oficiais, key=os.path.getmtime)
    arquivo_exec = os.path.join(PASTA_SOLTOS, os.path.basename(arquivo_oficial))
    if os.path.exists(arquivo_exec):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = arquivo_exec.replace(".py", f"_backup_{timestamp}.py")
        shutil.move(arquivo_exec, backup_path)
        print(f"[INFO] Backup do script antigo salvo em: {backup_path}")
    shutil.copy2(arquivo_oficial, arquivo_exec)
    print(f"[INFO] Script atualizado automaticamente para a versão oficial.")

def buscar_arquivos(extensoes=("*.ps1","*.py")):
    todos_arquivos = []
    for pasta in PASTAS_PROCURA:
        if os.path.exists(pasta):
            for ext in extensoes:
                encontrados = list(Path(pasta).rglob(ext))
                todos_arquivos.extend(encontrados)
    return todos_arquivos

def criar_unificado(arquivos):
    unificado_path = Path(PASTA_UNIFICADO) / "ONEFULL.ps1"
    if unificado_path.exists():
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = unificado_path.with_name(f"{unificado_path.stem}_backup_{timestamp}.ps1")
        shutil.move(unificado_path, backup_path)
        print(f"[INFO] Backup do PS1 unificado antigo: {backup_path}")
    with open(unificado_path, "w", encoding="utf-8") as f:
        f.write(f"# {VERSAO_FULLONE} - PS1 Unificado (ONEFULL)\n")
        f.write(f"# Gerado em {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        for arq in arquivos:
            try:
                with open(arq, "r", encoding="utf-8") as a:
                    f.write(f"# ===== {arq.name} =====\n")
                    f.write(a.read()+"\n")
                    f.write(f"# ===== FIM {arq.name} =====\n\n")
            except Exception as e:
                print(f"[ERRO] Não foi possível ler {arq}: {e}")
    print(f"[INFO] PS1 unificado criado: {unificado_path}")
    return unificado_path

def criar_zip(arq_unificado, arquivos):
    i = 1
    while True:
        zip_name = f"{VERSAO_FULLONE}_{str(i).zfill(4)}.zip"
        zip_path = Path(PASTA_PACKAGE) / zip_name
        if not zip_path.exists():
            break
        i += 1
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zipf:
        zipf.write(arq_unificado, arcname=arq_unificado.name)
        for a in arquivos:
            zipf.write(a, arcname=a.name)
    print(f"[INFO] ZIP criado: {zip_path}")
    return zip_path

def gerar_pdf(total, total_ps1, total_py, unificados_ps1, unificados_py):
    pdf_path = Path(PASTA_PDF) / f"{VERSAO_FULLONE}_relatorio_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", 'B', 16)
    pdf.set_text_color(0,0,128)
    pdf.cell(0,10,"FULLONE Autônomo Avançado - Relatório", ln=True)
    pdf.ln(5)
    pdf.set_font("Arial", '', 12)
    pdf.set_text_color(0,0,0)
    pdf.multi_cell(0,6,f"Versão: {VERSAO_FULLONE}\nTotal arquivos: {total}\nArquivos .PS1: {total_ps1}\nArquivos .PY: {total_py}\nArquivos .PS1 unificados: {unificados_ps1}\nArquivos .PY unificados: {unificados_py}")
    pdf.ln(5)
    pdf.set_fill_color(200,220,255)
    pdf.cell(60,8,"Arquivo",1,0,'C',True)
    pdf.cell(60,8,"Status",1,1,'C',True)
    pdf.set_fill_color(255,255,255)
    for f in Path(PASTA_UNIFICADO).glob("*.ps1"):
        pdf.cell(60,6,f.name,1,0,'C',True)
        pdf.cell(60,6,"Unificado",1,1,'C',True)
    pdf.output(pdf_path)
    print(f"[INFO] PDF gerado: {pdf_path}")

# ----------------------------
# EXECUÇÃO
# ----------------------------
if __name__ == "__main__":
    print("=== FULLONE - Gerador Automático Avançado ===\n")
    atualizar_script()
    arquivos = buscar_arquivos()
    total = len(arquivos)
    total_ps1 = len([a for a in arquivos if a.suffix.lower() == ".ps1"])
    total_py = len([a for a in arquivos if a.suffix.lower() == ".py"])
    print(f"[INFO] Total arquivos encontrados: {total} (.PS1: {total_ps1}, .PY: {total_py})")
    unificado = criar_unificado(arquivos)
    zip_path = criar_zip(unificado, arquivos)
    unificados_ps1 = len([a for a in Path(PASTA_UNIFICADO).glob("*.ps1")])
    unificados_py = len([a for a in Path(PASTA_UNIFICADO).glob("*.py")])
    gerar_pdf(total, total_ps1, total_py, unificados_ps1, unificados_py)
    print("\n=== FIM DO PROCESSO ===")