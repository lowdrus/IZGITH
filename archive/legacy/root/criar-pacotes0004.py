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
NOME_PS1_UNIFICADO = "ONEFULL.ps1"

# --------------------------
# CRIAR PASTAS SE NÃO EXISTIREM
# --------------------------
for pasta in [PASTA_SOLTOS, PASTA_UNIFICADO, PASTA_COMPILADOS, PASTA_PACKAGE, PASTA_DIAGRAMA]:
    os.makedirs(pasta, exist_ok=True)

# --------------------------
# FUNÇÕES
# --------------------------

def atualizar_script_oficial():
    """Atualiza o criar-pacotes.py a partir da versão oficial"""
    arquivo_oficial = os.path.join(PASTA_OFICIAL, "criar-pacotes.py")
    arquivo_exec = os.path.join(PASTA_SOLTOS, "criar-pacotes.py")

    if not os.path.exists(arquivo_oficial):
        print(f"[AVISO] Nenhum arquivo oficial encontrado em: {PASTA_OFICIAL}")
        return

    atualizar = False
    if not os.path.exists(arquivo_exec):
        atualizar = True
    else:
        # Comparar conteúdo
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
    """Busca todos os arquivos .PS1 e .PY"""
    todos_arquivos, arquivos_ps1, arquivos_py = [], [], []
    for pasta in PASTAS_PROCURAR:
        base_path = Path(pasta)
        if base_path.exists():
            for ext in ("*.ps1", "*.py"):
                encontrados = list(base_path.rglob(ext))
                todos_arquivos.extend(encontrados)
                if ext == "*.ps1":
                    arquivos_ps1.extend(encontrados)
                else:
                    arquivos_py.extend(encontrados)
    return todos_arquivos, arquivos_ps1, arquivos_py

def criar_unificado(todos_arquivos):
    """Cria arquivo ONEFULL.ps1 unificado"""
    os.makedirs(PASTA_UNIFICADO, exist_ok=True)
    ps1_path = Path(PASTA_UNIFICADO) / NOME_PS1_UNIFICADO

    if ps1_path.exists():
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = ps1_path.with_name(f"{ps1_path.stem}_backup_{timestamp}.ps1")
        shutil.move(ps1_path, backup_path)
        print(f"[INFO] Backup do PS1 unificado antigo: {backup_path}")

    cabecalho = f"# =============================================\n" \
                 f"# {VERSAO_FULLONE} - PS1 Unificado (ONEFULL)\n" \
                 f"# Gerado em {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n" \
                 f"# =============================================\n"

    cont_ps1, cont_py = 0, 0
    with open(ps1_path, 'w', encoding='utf-8') as f:
        f.write(cabecalho + "\n")
        for arquivo in todos_arquivos:
            try:
                with open(arquivo, 'r', encoding='utf-8') as af:
                    conteudo = af.read()
                f.write(f"\n\n# ===== INICIO {arquivo.name} =====\n")
                f.write(conteudo)
                f.write(f"\n# ===== FIM {arquivo.name} =====\n")
                if arquivo.suffix.lower() == ".ps1":
                    cont_ps1 += 1
                else:
                    cont_py += 1
            except Exception as e:
                print(f"[ERRO] Não foi possível ler {arquivo}: {e}")

    print(f"[INFO] PS1 unificado criado: {ps1_path}")
    return ps1_path, cont_ps1, cont_py

def criar_zip(unificado_path):
    """Cria ZIP incremental do pacote"""
    os.makedirs(PASTA_PACKAGE, exist_ok=True)
    contador = 1
    while True:
        zip_name = f"{VERSAO_FULLONE}_{contador:04d}.zip"
        zip_path = Path(PASTA_PACKAGE) / zip_name
        if not zip_path.exists():
            break
        contador += 1

    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        zipf.write(unificado_path, arcname=NOME_PS1_UNIFICADO)
        for arquivo in Path(PASTA_SOLTOS).glob("*"):
            zipf.write(arquivo, arcname=arquivo.name)

    print(f"[INFO] ZIP criado: {zip_path}")
    return zip_path

def gerar_pdf(todos_arquivos, zip_path, qtd_ps1, qtd_py, cont_ps1_unificado, cont_py_unificado):
    """Gera PDF com relatório detalhado"""
    from fpdf import FPDF
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", "B", 14)
    pdf.set_text_color(0, 102, 204)
    pdf.cell(0, 10, f"{VERSAO_FULLONE} - Relatório de Pacote", ln=True, align="C")

    pdf.set_font("Arial", "", 11)
    pdf.ln(5)
    pdf.multi_cell(0, 6, f"ZIP: {zip_path}\nData: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

    pdf.ln(5)
    pdf.set_font("Arial", "B", 12)
    pdf.set_fill_color(200, 220, 255)
    pdf.cell(0, 8, "Resumo de Arquivos", ln=True, fill=True)
    pdf.set_font("Arial", "", 10)
    pdf.cell(0, 6, f"Total arquivos encontrados: {len(todos_arquivos)}", ln=True)
    pdf.cell(0, 6, f"Arquivos .PS1 encontrados: {qtd_ps1}", ln=True)
    pdf.cell(0, 6, f"Arquivos .PY encontrados: {qtd_py}", ln=True)
    pdf.cell(0, 6, f"Arquivos .PS1 unificados: {cont_ps1_unificado}", ln=True)
    pdf.cell(0, 6, f"Arquivos .PY unificados: {cont_py_unificado}", ln=True)

    pdf.ln(5)
    pdf.set_font("Arial", "B", 12)
    pdf.cell(0, 8, "Arquivos Detalhados", ln=True, fill=True)
    pdf.set_font("Arial", "", 10)
    for f in todos_arquivos:
        pdf.cell(0, 6, str(f), ln=True)

    os.makedirs(PASTA_DIAGRAMA, exist_ok=True)
    pdf_path = Path(PASTA_DIAGRAMA) / f"{VERSAO_FULLONE}_relatorio_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    pdf.output(pdf_path)
    print(f"[INFO] PDF gerado: {pdf_path}")
    return pdf_path

def gerar_fluxograma():
    """Gera fluxograma do processo"""
    dot = Digraph(comment='FULLONE Fluxograma')
    dot.attr(rankdir='LR', size='10')
    dot.node('A', 'Início')
    dot.node('B', 'Busca arquivos .PS1 e .PY')
    dot.node('C', 'Unificação ONEFULL.ps1')
    dot.node('D', 'Criação do ZIP')
    dot.node('E', 'Geração PDF')
    dot.node('F', 'Fim')

    dot.edges(['AB', 'BC', 'CD', 'DE', 'EF'])

    os.makedirs(PASTA_DIAGRAMA, exist_ok=True)
    diagram_path = Path(PASTA_DIAGRAMA) / f"{VERSAO_FULLONE}_fluxograma"
    dot.render(str(diagram_path), format='png', cleanup=True)
    print(f"[INFO] Fluxograma gerado: {diagram_path}.png")
    return diagram_path.with_suffix('.png')

# --------------------------
# EXECUÇÃO PRINCIPAL
# --------------------------
if __name__ == "__main__":
    print("=== FULLONE - Gerador Automático v14fixed2 ===\n")

    atualizar_script_oficial()
    todos_arquivos, arquivos_ps1, arquivos_py = buscar_arquivos()

    print(f"[INFO] Total arquivos encontrados: {len(todos_arquivos)}")
    print(f"[INFO] Arquivos .PS1: {len(arquivos_ps1)}, Arquivos .PY: {len(arquivos_py)}")

    unificado_path, cont_ps1_unificado, cont_py_unificado = criar_unificado(todos_arquivos)

    zip_path = criar_zip(unificado_path)

    gerar_pdf(todos_arquivos, zip_path, len(arquivos_ps1), len(arquivos_py),
               cont_ps1_unificado, cont_py_unificado)

    gerar_fluxograma()

    print("\n=== PROCESSO FINALIZADO COM SUCESSO ✅ ===")