import os
import shutil
import zipfile
from pathlib import Path
from datetime import datetime
from fpdf import FPDF
from graphviz import Digraph

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
PASTA_DIAGRAMA = r"C:\SCRIPTS\FULL ONE\DIAGRAMA VISUAL"
PASTA_OFICIAL = r"C:\SCRIPTS\FULL ONE\OFFICIAL"

VERSAO_FULLONE = "FULLONEv14fixed2"

# --------------------------
# CRIAR PASTAS SE NÃO EXISTIREM
# --------------------------
for pasta in [PASTA_SOLTOS, PASTA_UNIFICADO, PASTA_COMPILADOS, PASTA_PACKAGE, PASTA_DIAGRAMA]:
    os.makedirs(pasta, exist_ok=True)

# --------------------------
# FUNÇÕES
# --------------------------
def gerar_nome_script():
    """Gera nome incremental para criar-pacotes"""
    contador = 1
    while True:
        nome = f"criar-pacotes{str(contador).zfill(4)}.py"
        caminho = Path(PASTA_SOLTOS) / nome
        if not caminho.exists():
            return caminho
        contador += 1

def atualizar_script_oficial():
    """Atualiza o script principal automaticamente"""
    oficial = Path(PASTA_OFICIAL) / "criar-pacotes.py"
    if not oficial.exists():
        print("[AVISO] Nenhum arquivo oficial encontrado.")
        return None

    script_atual = gerar_nome_script()
    if script_atual.exists():
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup = script_atual.with_name(f"{script_atual.stem}-backup_{timestamp}.py")
        shutil.move(script_atual, backup)
        print(f"[INFO] Backup do script antigo salvo: {backup}")

    shutil.copy2(oficial, script_atual)
    print(f"[INFO] Script atualizado automaticamente para: {script_atual}")
    return script_atual

def buscar_arquivos():
    """Busca todos os arquivos .PS1 e .PY"""
    todos, ps1, py = [], [], []
    for pasta in PASTAS_PROCURAR:
        base = Path(pasta)
        if base.exists():
            for ext in ("*.ps1", "*.py"):
                encontrados = list(base.rglob(ext))
                todos.extend(encontrados)
                ps1.extend([f for f in encontrados if f.suffix.lower() == ".ps1"])
                py.extend([f for f in encontrados if f.suffix.lower() == ".py"])
    return todos, ps1, py

def criar_unificado(todos):
    """Cria ONEFULL.ps1 unificado e gera contagens"""
    Path(PASTA_UNIFICADO).mkdir(exist_ok=True)
    unificado = Path(PASTA_UNIFICADO) / "ONEFULL.ps1"

    if unificado.exists():
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup = unificado.with_name(f"{unificado.stem}_backup_{timestamp}.ps1")
        shutil.move(unificado, backup)
        print(f"[INFO] Backup PS1 antigo: {backup}")

    cabecalho = f"# {VERSAO_FULLONE} - PS1 Unificado\n# Gerado: {datetime.now()}\n"
    cont_ps1, cont_py = 0, 0
    with open(unificado, 'w', encoding='utf-8') as f:
        f.write(cabecalho + "\n")
        for arquivo in todos:
            try:
                with open(arquivo, 'r', encoding='utf-8') as af:
                    conteudo = af.read()
                f.write(f"\n# ===== INICIO {arquivo.name} =====\n")
                f.write(conteudo)
                f.write(f"\n# ===== FIM {arquivo.name} =====\n")
                if arquivo.suffix.lower() == ".ps1":
                    cont_ps1 += 1
                else:
                    cont_py += 1
            except Exception as e:
                print(f"[ERRO] Não foi possível ler {arquivo}: {e}")
    print(f"[INFO] PS1 unificado criado: {unificado}")
    return unificado, cont_ps1, cont_py

def criar_zip(unificado):
    """Cria ZIP incremental"""
    Path(PASTA_PACKAGE).mkdir(exist_ok=True)
    contador = 1
    while True:
        zip_name = f"{VERSAO_FULLONE}_{str(contador).zfill(4)}.zip"
        zip_path = Path(PASTA_PACKAGE) / zip_name
        if not zip_path.exists():
            break
        contador += 1
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        zipf.write(unificado, arcname=unificado.name)
        for arquivo in Path(PASTA_SOLTOS).glob("*"):
            zipf.write(arquivo, arcname=arquivo.name)
    print(f"[INFO] ZIP criado: {zip_path}")
    return zip_path

def gerar_pdf(todos, zip_path, qtd_ps1, qtd_py, cont_ps1, cont_py):
    """Gera relatório PDF detalhado"""
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", "B", 14)
    pdf.set_text_color(0, 102, 204)
    pdf.cell(0, 10, f"{VERSAO_FULLONE} - Relatório", ln=True, align="C")

    pdf.set_font("Arial", "", 11)
    pdf.ln(5)
    pdf.multi_cell(0, 6, f"ZIP: {zip_path}\nData: {datetime.now()}\n")

    pdf.ln(5)
    pdf.set_font("Arial", "B", 12)
    pdf.set_fill_color(200, 220, 255)
    pdf.cell(0, 8, "Resumo de Arquivos", ln=True, fill=True)
    pdf.set_font("Arial", "", 10)
    pdf.cell(0, 6, f"Total arquivos encontrados: {len(todos)}", ln=True)
    pdf.cell(0, 6, f"Arquivos .PS1 encontrados: {qtd_ps1}", ln=True)
    pdf.cell(0, 6, f"Arquivos .PY encontrados: {qtd_py}", ln=True)
    pdf.cell(0, 6, f"Arquivos .PS1 unificados: {cont_ps1}", ln=True)
    pdf.cell(0, 6, f"Arquivos .PY unificados: {cont_py}", ln=True)

    pdf.ln(5)
    pdf.set_font("Arial", "B", 12)
    pdf.cell(0, 8, "Arquivos Detalhados", ln=True, fill=True)
    pdf.set_font("Arial", "", 10)
    for f in todos:
        pdf.cell(0, 6, str(f), ln=True)

    Path(PASTA_DIAGRAMA).mkdir(exist_ok=True)
    pdf_path = Path(PASTA_DIAGRAMA) / f"{VERSAO_FULLONE}_relatorio_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    pdf.output(pdf_path)
    print(f"[INFO] PDF gerado: {pdf_path}")
    return pdf_path

def gerar_fluxograma():
    """Gera fluxograma visual do processo"""
    dot = Digraph(comment='FULLONE Fluxograma')
    dot.attr(rankdir='LR', size='10')
    dot.node('A', 'Início')
    dot.node('B', 'Busca arquivos .PS1 e .PY')
    dot.node('C', 'Unificação ONEFULL.ps1')
    dot.node('D', 'Criação ZIP')
    dot.node('E', 'Geração PDF')
    dot.node('F', 'Fim')
    dot.edges(['AB', 'BC', 'CD', 'DE', 'EF'])

    Path(PASTA_DIAGRAMA).mkdir(exist_ok=True)
    diagram_path = Path(PASTA_DIAGRAMA) / f"{VERSAO_FULLONE}_fluxograma"
    dot.render(str(diagram_path), format='png', cleanup=True)
    print(f"[INFO] Fluxograma gerado: {diagram_path}.png")
    return diagram_path.with_suffix('.png')

# --------------------------
# EXECUÇÃO PRINCIPAL
# --------------------------
if __name__ == "__main__":
    print("=== FULLONE Autônomo Avançado ===\n")
    atualizar_script_oficial()
    todos, ps1, py = buscar_arquivos()
    print(f"[INFO] Total arquivos encontrados: {len(todos)} | PS1: {len(ps1)} | PY: {len(py)}")
    unificado, cont_ps1, cont_py = criar_unificado(todos)
    zip_path = criar_zip(unificado)
    gerar_pdf(todos, zip_path, len(ps1), len(py), cont_ps1, cont_py)
    gerar_fluxograma()
    print("\n=== PROCESSO FINALIZADO ✅ ===")