import os
import shutil
import zipfile
from pathlib import Path
from datetime import datetime
import glob
from fpdf import FPDF
import graphviz

# ===============================
# CONFIGURAÇÃO DE PASTAS E VERSÃO
# ===============================
VERSAO_FULLONE = "FULLONEv14fixed3"
PASTA_OFICIAL = r"C:\SCRIPTS\FULL ONE\OFFICIAL"
PASTA_EXEC = r"C:\SCRIPTS\FULL ONE\FULL ONE GENERATOR"
PASTA_UNIFICADOS = r"C:\SCRIPTS\FULL ONE\ARQUIVOS .PS1 UNIFICADOS"
PASTA_PACKAGE = r"C:\SCRIPTS\FULL ONE\PACKAGE"
PASTA_COMPILADOS = r"C:\SCRIPTS\FULL ONE\COMPILADOS"
PASTA_DIAGRAMA = r"C:\SCRIPTS\FULL ONE\DIAGRAMA VISUAL"

# Pastas para buscar arquivos
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

NOME_UNIFICADO = "ONEFULL.ps1"

# ===============================
# FUNÇÕES
# ===============================

def atualizar_script_oficial():
    """Atualiza o script oficial e cria backup automático"""
    arquivo_oficial = Path(PASTA_OFICIAL) / "criar-pacotes.py"
    if not arquivo_oficial.exists():
        print(f"[AVISO] Nenhum arquivo oficial encontrado em: {PASTA_OFICIAL}")
        return
    arquivos_exec = sorted(Path(PASTA_EXEC).glob("criar-pacotes*.py"))
    # Backup dos antigos
    for arq in arquivos_exec:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = arq.with_name(f"{arq.stem}_backup_{timestamp}.py")
        shutil.move(arq, backup_path)
        print(f"[INFO] Backup do script antigo salvo: {backup_path}")
    # Copia arquivo oficial como novo
    novo_nome = f"criar-pacotes{len(arquivos_exec)+1:04d}.py"
    shutil.copy2(arquivo_oficial, Path(PASTA_EXEC) / novo_nome)
    print(f"[INFO] Script atualizado automaticamente: {novo_nome}")

def buscar_arquivos():
    """Busca arquivos .PS1 e .PY, priorizando os mais recentes"""
    todos_arquivos = []
    for pasta in PASTAS_PROCURA:
        if Path(pasta).exists():
            for ext in ("*.ps1", "*.py"):
                todos_arquivos.extend(Path(pasta).rglob(ext))
    # Remover duplicados mantendo o mais recente
    arquivos_dict = {}
    for f in todos_arquivos:
        key = f.name.lower()
        if key not in arquivos_dict or f.stat().st_mtime > arquivos_dict[key].stat().st_mtime:
            arquivos_dict[key] = f
    return list(arquivos_dict.values())

def criar_unificado(arquivos, pasta_saida):
    """Cria PS1 unificado com backup automático"""
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
        for arquivo in glob.glob(os.path.join(PASTA_EXEC, "*")):
            zf.write(arquivo, arcname=os.path.basename(arquivo))
    print(f"[INFO] ZIP criado: {zip_path}")
    return zip_path

def gerar_fluxograma():
    """Gera fluxograma Graphviz"""
    dot = graphviz.Digraph(comment='FULLONE Fluxograma')
    dot.node('A', 'Início')
    dot.node('B', 'Busca arquivos')
    dot.node('C', 'Unifica PS1')
    dot.node('D', 'Cria ZIP')
    dot.node('E', 'Gera PDF')
    dot.edges(['AB', 'BC', 'CD', 'DE'])
    diagram_path = Path(PASTA_DIAGRAMA) / f"FULLONE_Fluxograma_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    os.makedirs(PASTA_DIAGRAMA, exist_ok=True)
    dot.render(str(diagram_path), format='png', cleanup=True)
    return str(diagram_path) + ".png"

def gerar_pdf(todos_arquivos, unificado_path, zip_path, fluxograma_path):
    """Gera PDF detalhado e salva scripts como TXT para referência"""
    os.makedirs(PASTA_DIAGRAMA, exist_ok=True)
    pdf_path = Path(PASTA_DIAGRAMA) / f"{VERSAO_FULLONE}_relatorio_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", "B", 16)
    pdf.set_text_color(0,0,128)
    pdf.cell(0,10,f"FULLONE Relatório - {VERSAO_FULLONE}",ln=True,align="C")
    pdf.ln(5)

    # Estatísticas completas
    ps1_total = len([f for f in todos_arquivos if f.suffix.lower() == ".ps1"])
    py_total = len([f for f in todos_arquivos if f.suffix.lower() == ".py"])
    ps1_unificados = ps1_total
    py_unificados = py_total
    pdf.set_font("Arial","",12)
    pdf.set_text_color(0,0,0)
    pdf.multi_cell(0,6,f"Total de arquivos encontrados: {len(todos_arquivos)}\n"
                          f"Arquivos .PS1: {ps1_total}\n"
                          f"Arquivos .PY: {py_total}\n"
                          f"Arquivos PS1 unificados: {ps1_unificados}\n"
                          f"Arquivos PY unificados: {py_unificados}\n"
                          f"Arquivo PS1 unificado: {unificado_path}\n"
                          f"ZIP gerado: {zip_path}\n")
    pdf.ln(5)

    # Fluxograma
    pdf.set_font("Arial","B",14)
    pdf.set_text_color(0,128,0)
    pdf.cell(0,10,"Fluxograma do processo",ln=True)
    pdf.image(fluxograma_path,w=180)
    pdf.ln(5)

    # Lista de arquivos
    pdf.set_font("Arial","B",12)
    pdf.set_text_color(128,0,0)
    pdf.cell(0,8,"Lista de arquivos encontrados:",ln=True)
    pdf.set_font("Arial","",10)
    for f in todos_arquivos:
        pdf.multi_cell(0,5,str(f))

    # Salvar scripts como TXT para referência
    txt_dir = Path(PASTA_DIAGRAMA) / "scripts_txt"
    os.makedirs(txt_dir, exist_ok=True)
    for arquivo in todos_arquivos:
        try:
            txt_path = txt_dir / f"{arquivo.name}.txt"
            shutil.copy2(arquivo, txt_path)
        except:
            continue

    pdf.output(pdf_path)
    print(f"[INFO] PDF gerado: {pdf_path}")
    return pdf_path

# ===============================
# EXECUÇÃO PRINCIPAL
# ===============================
if __name__ == "__main__":
    print("=== FULLONE - GERADOR AUTÔNOMO AVANÇADO ===\n")

    # Atualiza script oficial
    atualizar_script_oficial()

    # Buscar arquivos
    todos_arquivos = buscar_arquivos()
    print(f"[INFO] Total de arquivos encontrados: {len(todos_arquivos)}")
    print(f"[INFO] Arquivos .PS1: {len([f for f in todos_arquivos if f.suffix.lower()=='.ps1'])}")
    print(f"[INFO] Arquivos .PY: {len([f for f in todos_arquivos if f.suffix.lower()=='.py'])}")

    # Criar PS1 unificado
    unificado_path = criar_unificado(todos_arquivos, PASTA_UNIFICADOS)

    # Criar ZIP incremental
    zip_path = criar_zip(unificado_path)

    # Gerar fluxograma
    fluxograma_path = gerar_fluxograma()

    # Gerar PDF completo
    pdf_path = gerar_pdf(todos_arquivos, unificado_path, zip_path, fluxograma_path)

    print("\n=== FULLONE - Processo concluído com sucesso! ===")