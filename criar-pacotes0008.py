import os
import shutil
import glob
import zipfile
from pathlib import Path
from datetime import datetime
from fpdf import FPDF
import graphviz

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
PASTA_DIAGRAMA = r"C:\SCRIPTS\FULL ONE\DIAGRAMA VISUAL"
PASTA_OFICIAL = r"C:\SCRIPTS\FULL ONE\OFFICIAL"

VERSAO_FULLONE = "FULLONEv14fixed2"
NOME_UNIFICADO = "ONEFULL.ps1"

# ----------------------------
# CRIAR PASTAS SE NÃO EXISTIREM
# ----------------------------
for pasta in [PASTA_SOLTOS, PASTA_UNIFICADO, PASTA_COMPILADOS, PASTA_PACKAGE, PASTA_DIAGRAMA]:
    os.makedirs(pasta, exist_ok=True)

# ----------------------------
# FUNÇÕES
# ----------------------------
def atualizar_script_oficial():
    """Atualiza o script a partir da versão oficial."""
    arquivo_oficial = os.path.join(PASTA_OFICIAL, "criar-pacotes.py")
    arquivo_exec = os.path.join(PASTA_SOLTOS, "criar-pacotes-autonomo.py")
    if not os.path.exists(arquivo_oficial):
        print(f"[AVISO] Nenhum arquivo oficial encontrado em: {PASTA_OFICIAL}")
        return
    atualizar = False
    if not os.path.exists(arquivo_exec):
        atualizar = True
    else:
        with open(arquivo_oficial, "rb") as f1, open(arquivo_exec, "rb") as f2:
            if f1.read() != f2.read():
                atualizar = True
    if atualizar:
        if os.path.exists(arquivo_exec):
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_path = os.path.join(PASTA_SOLTOS, f"criar-pacotes_backup_{timestamp}.py")
            shutil.copy2(arquivo_exec, backup_path)
            print(f"[INFO] Backup do script antigo salvo em: {backup_path}")
        shutil.copy2(arquivo_oficial, arquivo_exec)
        print(f"[INFO] Script atualizado automaticamente para a versão oficial.")

def buscar_arquivos():
    """Busca todos os arquivos .PS1 e .PY nas pastas definidas"""
    todos_arquivos = []
    ps1_count = 0
    py_count = 0
    for pasta in PASTAS_PROCURA:
        if not os.path.exists(pasta):
            continue
        for root, dirs, files in os.walk(pasta):
            for file in files:
                if file.lower().endswith(".ps1"):
                    todos_arquivos.append(os.path.join(root, file))
                    ps1_count += 1
                elif file.lower().endswith(".py"):
                    todos_arquivos.append(os.path.join(root, file))
                    py_count += 1
    return todos_arquivos, ps1_count, py_count

def criar_unificado(arquivos):
    """Cria o PS1 unificado e faz backup automático"""
    unificado_path = os.path.join(PASTA_UNIFICADO, NOME_UNIFICADO)
    if os.path.exists(unificado_path):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = os.path.join(PASTA_UNIFICADO, f"ONEFULL_backup_{timestamp}.ps1")
        shutil.move(unificado_path, backup_path)
        print(f"[INFO] Backup do PS1 unificado antigo: {backup_path}")
    ps1_total = 0
    py_total = 0
    with open(unificado_path, "w", encoding="utf-8") as f:
        f.write(f"# FULLONE Unificado - Versão {VERSAO_FULLONE}\n# Gerado em {datetime.now()}\n\n")
        for arq in arquivos:
            try:
                with open(arq, "r", encoding="utf-8") as af:
                    conteudo = af.read()
                f.write(f"\n# ===== INICIO {os.path.basename(arq)} =====\n")
                f.write(conteudo)
                f.write(f"\n# ===== FIM {os.path.basename(arq)} =====\n")
                if arq.lower().endswith(".ps1"):
                    ps1_total += 1
                elif arq.lower().endswith(".py"):
                    py_total += 1
            except Exception as e:
                print(f"[ERRO] Não foi possível ler {arq}: {e}")
    print(f"[INFO] PS1 unificado criado: {unificado_path}")
    return unificado_path, ps1_total, py_total

def criar_zip(unificado_path):
    """Cria ZIP incremental"""
    contador = 1
    while True:
        zip_name = f"{VERSAO_FULLONE}_{contador:04d}.zip"
        zip_path = os.path.join(PASTA_PACKAGE, zip_name)
        if not os.path.exists(zip_path):
            break
        contador += 1
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.write(unificado_path, os.path.basename(unificado_path))
        for arquivo in glob.glob(os.path.join(PASTA_SOLTOS, "*")):
            zf.write(arquivo, os.path.basename(arquivo))
    print(f"[INFO] ZIP criado: {zip_path}")
    return zip_path

def gerar_fluxograma():
    """Gera diagrama visual via Graphviz"""
    diagram_path = Path(PASTA_DIAGRAMA) / f"{VERSAO_FULLONE}_fluxograma"
    dot = graphviz.Digraph(comment="FULLONE Fluxograma")
    dot.node('A', 'Início')
    dot.node('B', 'Busca arquivos')
    dot.node('C', 'Unificação')
    dot.node('D', 'Criação ZIP')
    dot.node('E', 'PDF Relatório')
    dot.edges(['AB', 'BC', 'CD', 'DE'])
    dot.render(str(diagram_path), format='png', cleanup=True)
    print(f"[INFO] Fluxograma gerado: {diagram_path}.png")
    return diagram_path.with_suffix(".png")

def gerar_pdf(arquivos, ps1_total, py_total, unificado_path, fluxograma_path):
    """Gera PDF detalhado"""
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", "B", 16)
    pdf.set_text_color(0, 0, 128)
    pdf.cell(0, 10, f"FULLONE Relatório - {VERSAO_FULLONE}", ln=True, align="C")
    pdf.ln(10)
    
    pdf.set_font("Arial", "", 12)
    pdf.set_text_color(0, 0, 0)
    pdf.multi_cell(0, 6, f"Data de geração: {datetime.now()}")
    pdf.multi_cell(0, 6, f"Total arquivos encontrados: {len(arquivos)}")
    pdf.multi_cell(0, 6, f"Arquivos .PS1: {ps1_total}")
    pdf.multi_cell(0, 6, f"Arquivos .PY: {py_total}")
    
    pdf.ln(5)
    pdf.multi_cell(0, 6, f"Arquivo unificado: {unificado_path}")
    pdf.ln(5)
    
    # Inserir fluxograma
    if fluxograma_path.exists():
        pdf.image(str(fluxograma_path), w=180)
    
    pdf_path = Path(PASTA_DIAGRAMA) / f"{VERSAO_FULLONE}_relatorio_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    pdf.output(str(pdf_path))
    print(f"[INFO] PDF gerado: {pdf_path}")
    return pdf_path

# ----------------------------
# EXECUÇÃO
# ----------------------------
if __name__ == "__main__":
    print(f"=== FULLONE Autônomo Avançado {VERSAO_FULLONE} ===\n")
    
    atualizar_script_oficial()
    
    arquivos, ps1_count, py_count = buscar_arquivos()
    print(f"[INFO] Total arquivos encontrados: {len(arquivos)}")
    print(f"[INFO] Arquivos .PS1: {ps1_count}, Arquivos .PY: {py_count}")
    
    unificado_path, ps1_total, py_total = criar_unificado(arquivos)
    
    zip_path = criar_zip(unificado_path)
    
    fluxograma_path = gerar_fluxograma()
    
    pdf_path = gerar_pdf(arquivos, ps1_total, py_total, unificado_path, fluxograma_path)
    
    print("\n=== PROCESSO CONCLUÍDO COM SUCESSO ✅ ===")