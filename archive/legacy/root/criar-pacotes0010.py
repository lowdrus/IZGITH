import os
import shutil
import zipfile
from pathlib import Path
from datetime import datetime
import glob
from fpdf import FPDF
import graphviz

# ----------------------
# CONFIGURAÇÃO
# ----------------------
VERSAO_FULLONE = "FULLONEv14fixed2_FINAL"
PASTA_OFICIAL = r"C:\SCRIPTS\FULL ONE\OFFICIAL"
PASTA_EXEC = r"C:\SCRIPTS\FULL ONE\FULL ONE GENERATOR"
PASTA_UNIFICADOS = r"C:\SCRIPTS\FULL ONE\ARQUIVOS .PS1 UNIFICADOS"
PASTA_PACKAGE = r"C:\SCRIPTS\FULL ONE\PACKAGE"
PASTA_COMPILADOS = r"C:\SCRIPTS\FULL ONE\COMPILADOS"
PASTA_DIAGRAMA = r"C:\SCRIPTS\FULL ONE\DIAGRAMA VISUAL"
PASTA_TXT_SCRIPTS = r"C:\SCRIPTS\FULL ONE\TXT_SCRIPTS"  # nova pasta para salvar scripts como .txt

NOME_UNIFICADO = "ONEFULL.ps1"

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
    r"C:\UNIC QUANTIC\scripts",
]

# ----------------------
# FUNÇÕES
# ----------------------

def atualizar_script_oficial():
    """Atualiza script oficial mantendo backup e versão anterior"""
    arquivo_oficial = Path(PASTA_OFICIAL) / "criar-pacotes.py"
    arquivo_exec = Path(PASTA_EXEC) / "criar-pacotes.py"

    if not arquivo_oficial.exists():
        print(f"[AVISO] Nenhum arquivo oficial encontrado em: {PASTA_OFICIAL}")
        return

    atualizar = False
    if not arquivo_exec.exists():
        atualizar = True
    else:
        if arquivo_oficial.read_bytes() != arquivo_exec.read_bytes():
            atualizar = True

    if atualizar:
        if arquivo_exec.exists():
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_path = arquivo_exec.with_name(f"{arquivo_exec.stem}_backup_{timestamp}.py")
            shutil.copy2(arquivo_exec, backup_path)
            print(f"[INFO] Backup do script antigo salvo: {backup_path}")
        shutil.copy2(arquivo_oficial, arquivo_exec)
        print("[INFO] Script atualizado automaticamente.")

def buscar_arquivos():
    """Busca arquivos .PS1 e .PY"""
    todos_arquivos = []
    for pasta in PASTAS_PROCURA:
        if Path(pasta).exists():
            for ext in ("*.ps1", "*.py"):
                encontrados = list(Path(pasta).rglob(ext))
                todos_arquivos.extend(encontrados)
    return todos_arquivos

def criar_unificado(arquivos, pasta_saida):
    """Cria arquivo PS1 unificado"""
    os.makedirs(pasta_saida, exist_ok=True)
    unificado_path = Path(pasta_saida) / NOME_UNIFICADO

    if unificado_path.exists():
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = unificado_path.with_name(f"{unificado_path.stem}_backup_{timestamp}.ps1")
        shutil.move(unificado_path, backup_path)
        print(f"[INFO] Backup do PS1 unificado antigo: {backup_path}")

    with open(unificado_path, "w", encoding="utf-8") as f:
        f.write(f"# FULLONE Unificado - Versão {VERSAO_FULLONE}\n")
        f.write(f"# Gerado em {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        for arquivo in arquivos:
            try:
                with open(arquivo, "r", encoding="utf-8") as af:
                    conteudo = af.read()
                f.write(f"# ===== INICIO {arquivo.name} =====\n")
                f.write(conteudo + "\n")
                f.write(f"# ===== FIM {arquivo.name} =====\n\n")
            except Exception as e:
                print(f"[ERRO] Não foi possível ler {arquivo}: {e}")

    print(f"[INFO] PS1 unificado criado: {unificado_path}")
    return unificado_path

def criar_zip(unificado_path):
    """Cria ZIP incremental"""
    os.makedirs(PASTA_PACKAGE, exist_ok=True)
    contador = 1
    while True:
        zip_name = f"{VERSAO_FULLONE}_{contador:04d}.zip"
        zip_path = Path(PASTA_PACKAGE) / zip_name
        if not zip_path.exists():
            break
        contador += 1

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.write(unificado_path, arcname=unificado_path.name)
        # Adiciona arquivos soltos
        for arquivo in glob.glob(os.path.join(PASTA_EXEC, "*")):
            zf.write(arquivo, arcname=os.path.basename(arquivo))

    print(f"[INFO] ZIP criado: {zip_path}")
    return zip_path

def salvar_scripts_txt(arquivos):
    """Salva todos os scripts como .txt para referência no PDF"""
    os.makedirs(PASTA_TXT_SCRIPTS, exist_ok=True)
    txt_arquivos = []
    for arq in arquivos:
        try:
            txt_path = Path(PASTA_TXT_SCRIPTS) / f"{arq.stem}.txt"
            shutil.copy2(arq, txt_path)
            txt_arquivos.append(txt_path)
        except Exception as e:
            print(f"[ERRO] Não foi possível salvar {arq} como .txt: {e}")
    return txt_arquivos

def gerar_fluxograma():
    """Gera fluxograma Graphviz"""
    dot = graphviz.Digraph(comment='FULLONE Fluxograma')
    dot.node('A', 'Início')
    dot.node('B', 'Busca arquivos')
    dot.node('C', 'Unifica PS1')
    dot.node('D', 'Cria ZIP')
    dot.node('E', 'Gera PDF')
    dot.edges(['AB', 'BC', 'CD', 'DE'])
    os.makedirs(PASTA_DIAGRAMA, exist_ok=True)
    diagram_path = Path(PASTA_DIAGRAMA) / f"FULLONE_Fluxograma_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    dot.render(str(diagram_path), format='png', cleanup=True)
    return str(diagram_path) + ".png"

def gerar_pdf(todos_arquivos, unificado_path, zip_path, fluxograma_path, txt_scripts):
    """Gera PDF detalhado com anexos .txt dos scripts"""
    os.makedirs(PASTA_DIAGRAMA, exist_ok=True)
    pdf_path = Path(PASTA_DIAGRAMA) / f"{VERSAO_FULLONE}_relatorio_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", "B", 16)
    pdf.set_text_color(0,0,128)
    pdf.cell(0,10,f"FULLONE Relatório - {VERSAO_FULLONE}", ln=True, align="C")
    pdf.ln(5)

    # Estatísticas
    ps1_count = len([f for f in todos_arquivos if f.suffix.lower() == ".ps1"])
    py_count = len([f for f in todos_arquivos if f.suffix.lower() == ".py"])
    pdf.set_font("Arial","",12)
    pdf.set_text_color(0,0,0)
    pdf.multi_cell(0,6,f"Total de arquivos encontrados: {len(todos_arquivos)}\n"
                          f"Arquivos .PS1: {ps1_count}\n"
                          f"Arquivos .PY: {py_count}\n"
                          f"Arquivo PS1 unificado: {unificado_path}\n"
                          f"ZIP gerado: {zip_path}\n")
    pdf.ln(5)

    # Fluxograma
    pdf.set_font("Arial","B",14)
    pdf.set_text_color(0,128,0)
    pdf.cell(0,10,"Fluxograma do processo", ln=True)
    pdf.image(fluxograma_path, w=180)
    pdf.ln(5)

    # Lista de arquivos
    pdf.set_font("Arial","B",12)
    pdf.set_text_color(128,0,0)
    pdf.cell(0,8,"Lista de arquivos encontrados:", ln=True)
    pdf.set_font("Arial","",10)
    for f in todos_arquivos:
        pdf.multi_cell(0,5,str(f))
    pdf.ln(5)

    # Anexa scripts como referência
    pdf.set_font("Arial","B",12)
    pdf.set_text_color(0,0,0)
    pdf.cell(0,8,"Scripts anexados como .TXT:", ln=True)
    pdf.set_font("Arial","",10)
    for txt in txt_scripts:
        pdf.multi_cell(0,5,str(txt))
    pdf.output(pdf_path)
    print(f"[INFO] PDF gerado: {pdf_path}")
    return pdf_path

# ===============================
# EXECUÇÃO PRINCIPAL
# ===============================
if __name__ == "__main__":
    print("=== FULLONE - AUTÔNOMO AVANÇADO FINAL ===\n")
    atualizar_script_oficial()
    todos_arquivos = buscar_arquivos()
    print(f"[INFO] Total arquivos encontrados: {len(todos_arquivos)}")
    print(f"[INFO] Arquivos .PS1: {len([f for f in todos_arquivos if f.suffix.lower()=='.ps1'])}")
    print(f"[INFO] Arquivos .PY: {len([f for f in todos_arquivos if f.suffix.lower()=='.py'])}")

    unificado_path = criar_unificado(todos_arquivos, PASTA_UNIFICADOS)
    zip_path = criar_zip(unificado_path)
    txt_scripts = salvar_scripts_txt(todos_arquivos)
    fluxograma_path = gerar_fluxograma()
    pdf_path = gerar_pdf(todos_arquivos, unificado_path, zip_path, fluxograma_path, txt_scripts)

    print("\n=== PROCESSO COMPLETO FINALIZADO ===")