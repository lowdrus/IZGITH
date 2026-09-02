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
PASTA_OFICIAL = r"C:\SCRIPTS\FULL ONE\OFFICIAL"
PASTA_DIAGRAMA = r"C:\SCRIPTS\FULL ONE\DIAGRAMA VISUAL"

VERSAO_FULLONE = "FULLONEv14fixed2"

# --------------------------
# CRIAR PASTAS SE NÃO EXISTIREM
# --------------------------
for pasta in [PASTA_SOLTOS, PASTA_UNIFICADO, PASTA_COMPILADOS, PASTA_PACKAGE, PASTA_DIAGRAMA]:
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
    arquivos_ps1 = []
    arquivos_py = []
    for pasta in PASTAS_PROCURAR:
        base = Path(pasta)
        if base.exists():
            for ext in ("*.ps1", "*.py"):
                encontrados = list(base.rglob(ext))
                todos_arquivos.extend(encontrados)
                if ext == "*.ps1":
                    arquivos_ps1.extend(encontrados)
                else:
                    arquivos_py.extend(encontrados)
    return todos_arquivos, arquivos_ps1, arquivos_py

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
    cont_ps1 = 0
    cont_py = 0
    with open(unificado_path, 'w', encoding='utf-8') as f:
        f.write(cabecalho)
        for arquivo in arquivos:
            try:
                with open(arquivo, 'r', encoding='utf-8') as af:
                    f.write(f"\n# ===== INICIO {arquivo.name} =====\n")
                    f.write(af.read() + "\n")
                    f.write(f"# ===== FIM {arquivo.name} =====\n")
                    if arquivo.suffix.lower() == ".ps1":
                        cont_ps1 += 1
                    elif arquivo.suffix.lower() == ".py":
                        cont_py += 1
            except Exception as e:
                print(f"[ERRO] Não foi possível ler {arquivo}: {e}")

    print(f"[INFO] PS1 unificado criado em: {unificado_path}")
    return unificado_path, cont_ps1, cont_py

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

def gerar_pdf(todos_arquivos, zip_path, cont_ps1, cont_py, unificado_ps1, unificado_py):
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
    pdf.cell(0,10,f"Arquivos .PS1 encontrados: {cont_ps1}", ln=True)
    pdf.cell(0,10,f"Arquivos .PY encontrados: {cont_py}", ln=True)
    pdf.cell(0,10,f"Arquivos .PS1 unificados: {unificado_ps1}", ln=True)
    pdf.cell(0,10,f"Arquivos .PY unificados: {unificado_py}", ln=True)
    pdf.ln(5)

    pdf.set_font("Arial", "B", 12)
    pdf.set_fill_color(200, 220, 255)
    pdf.cell(0, 8, "Pastas pesquisadas", ln=True, fill=True)
    pdf.set_font("Arial", "", 10)
    for p in PASTAS_PROCURAR:
        pdf.cell(0, 6, str(p), ln=True)

    pdf.ln(5)
        # Tabela de arquivos encontrados
    pdf.ln(5)
    pdf.set_font("Arial", "B", 12)
    pdf.cell(0, 8, "Arquivos encontrados (.PS1 e .PY)", ln=True, fill=True)
    pdf.set_font("Arial", "", 10)
    for f in todos_arquivos:
        pdf.cell(0, 6, str(f), ln=True)

    # Salvar PDF
    os.makedirs(PASTA_DIAGRAMA, exist_ok=True)
    pdf_path = Path(PASTA_DIAGRAMA) / f"FULLONEv14fixed2_info_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    pdf.output(pdf_path)
    print(f"[INFO] PDF gerado em: {pdf_path}")
    return pdf_path

def gerar_fluxograma():
    """Gera fluxograma do processo com Graphviz"""
    dot = Digraph(comment='FULLONE Fluxograma')
    dot.attr(rankdir='LR', size='10')
    dot.node('A', 'Início')
    dot.node('B', 'Busca arquivos .PS1 e .PY')
    dot.node('C', 'Unificação em ONEFULL.ps1')
    dot.node('D', 'Criação do ZIP')
    dot.node('E', 'Geração PDF')
    dot.node('F', 'Fim')

    dot.edges(['AB', 'BC', 'CD', 'DE', 'EF'])

    os.makedirs(PASTA_DIAGRAMA, exist_ok=True)
    diagram_path = Path(PASTA_DIAGRAMA) / f"FULLONEv14fixed2_fluxograma"
    dot.render(str(diagram_path), format='png', cleanup=True)
    print(f"[INFO] Fluxograma gerado em: {diagram_path}.png")
    return diagram_path.with_suffix('.png')

# --------------------------
# EXECUÇÃO
# --------------------------
if __name__ == "__main__":
    print("=== FULLONE - Gerador Automático v14fixed2 ===\n")

    # Atualizar script oficial
    atualizar_script_oficial()

    # Buscar arquivos
    todos_arquivos, arquivos_ps1, arquivos_py = buscar_arquivos()
    print(f"[INFO] Total arquivos encontrados: {len(todos_arquivos)}")
    print(f"[INFO] Arquivos .PS1: {len(arquivos_ps1)}, Arquivos .PY: {len(arquivos_py)}")

    # Criar PS1 unificado
    unificado_path, cont_ps1_unificado, cont_py_unificado = criar_unificado(todos_arquivos)
    print(f"[INFO] Arquivos unificados - PS1: {cont_ps1_unificado}, PY: {cont_py_unificado}")

    # Criar ZIP
    zip_path = criar_zip(unificado_path)

    # Gerar PDF detalhado
    pdf_path = gerar_pdf(todos_arquivos, zip_path, len(arquivos_ps1), len(arquivos_py),
                         cont_ps1_unificado, cont_py_unificado)

    # Gerar fluxograma visual
    fluxograma_path = gerar_fluxograma()

    print("\n=== PROCESSO FINALIZADO COM SUCESSO ✅ ===")