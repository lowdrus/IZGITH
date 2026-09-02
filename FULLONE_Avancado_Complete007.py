import os
import shutil
import zipfile
from pathlib import Path
from datetime import datetime
from fpdf import FPDF, XPos, YPos
import graphviz

# ===============================
# CONFIGURAÇÃO DE PASTAS E VERSÃO
# ===============================
VERSAO_FULLONE = "FULLONEv14fixed4"
PASTA_OFICIAL = r"C:\SCRIPTS\FULL ONE\OFFICIAL"
PASTA_EXEC = r"C:\SCRIPTS\FULL ONE\FULL ONE GENERATOR"
PASTA_UNIFICADOS = r"C:\SCRIPTS\FULL ONE\ARQUIVOS .PS1 UNIFICADOS"
PASTA_PACKAGE = r"C:\SCRIPTS\FULL ONE\PACKAGE"
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
    r"C:\USERAT",
    r"C:\USERAT\scripts",
    r"C:\TESTEE 2\AI_Trade_Suite",
    r"C:\UNIC QUANTIC\scripts",
]

NOME_UNIFICADO = "ONEFULL.ps1"

# ===============================
# FUNÇÕES
# ===============================

def atualizar_script_oficial():
    """Atualiza o script a partir da versão oficial"""
    arquivo_oficial = Path(PASTA_OFICIAL) / "criar-pacotes.py"
    arquivo_exec = Path(PASTA_EXEC) / "criar-pacotes.py"

    if not arquivo_oficial.exists():
        print(f"[AVISO] Nenhum arquivo oficial encontrado em: {PASTA_OFICIAL}")
        Path(PASTA_OFICIAL).mkdir(parents=True, exist_ok=True)
        arquivo_oficial.touch()
        print(f"[INFO] Arquivo oficial criado: {arquivo_oficial}")
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
    """Busca arquivos .PS1 e .PY em todas as pastas"""
    todos_arquivos = []
    for pasta in PASTAS_PROCURA:
        path_pasta = Path(pasta)
        if path_pasta.exists():
            for ext in ("*.ps1", "*.py"):
                encontrados = list(path_pasta.rglob(ext))
                todos_arquivos.extend(encontrados)
    return todos_arquivos

def selecionar_versao_recente(arquivos):
    """Seleciona a versão mais recente dos arquivos com mesmo nome"""
    arquivos_dict = {}
    for arquivo in arquivos:
        nome = arquivo.name
        if nome not in arquivos_dict:
            arquivos_dict[nome] = arquivo
        else:
            if arquivo.stat().st_mtime > arquivos_dict[nome].stat().st_mtime:
                arquivos_dict[nome] = arquivo
    return list(arquivos_dict.values())

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

def criar_zip(unificado_path, todos_arquivos):
    """Cria ZIP incremental com scripts anexados como .txt"""
    os.makedirs(PASTA_PACKAGE, exist_ok=True)
    contador = 1
    while True:
        zip_name = f"{VERSAO_FULLONE}_{contador:04d}.zip"
        zip_path = Path(PASTA_PACKAGE) / zip_name
        if not zip_path.exists():
            break
        contador += 1

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        # Adiciona PS1 unificado
        zf.write(unificado_path, arcname=unificado_path.name)
        # Adiciona cada script como .txt
        for arquivo in todos_arquivos:
            try:
                with open(arquivo, "r", encoding="utf-8") as f:
                    conteudo = f.read()
                txt_name = f"{arquivo.stem}.txt"
                zf.writestr(txt_name, conteudo)
            except Exception as e:
                print(f"[ERRO] Não foi possível anexar {arquivo} ao ZIP: {e}")
    print(f"[INFO] ZIP criado: {zip_path}")
    return zip_path

def gerar_fluxograma():
    """Gera fluxograma do processo"""
    dot = graphviz.Digraph(comment='FULLONE Fluxograma')
    dot.node('A', 'Início')
    dot.node('B', 'Busca arquivos')
    dot.node('C', 'Seleciona versão recente')
    dot.node('D', 'Unifica PS1')
    dot.node('E', 'Cria ZIP')
    dot.node('F', 'Gera PDF')
    dot.edges(['AB', 'BC', 'CD', 'DE', 'DF'])
    diagram_path = Path(PASTA_DIAGRAMA) / f"FULLONE_Fluxograma_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    os.makedirs(PASTA_DIAGRAMA, exist_ok=True)
    dot.render(str(diagram_path), format='png', cleanup=True)
    return str(diagram_path) + ".png"

def gerar_pdf(todos_arquivos, unificado_path, zip_path, fluxograma_path):
    """Gera PDF detalhado"""
    os.makedirs(PASTA_DIAGRAMA, exist_ok=True)
    pdf_path = Path(PASTA_DIAGRAMA) / f"{VERSAO_FULLONE}_relatorio_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Helvetica", "B", 16)
    pdf.set_text_color(0, 0, 128)
    pdf.cell(0, 10, f"FULLONE Relatório - {VERSAO_FULLONE}", ln=True, align="C")
    pdf.ln(5)

    ps1_count = len([f for f in todos_arquivos if f.suffix.lower() == ".ps1"])
    py_count = len([f for f in todos_arquivos if f.suffix.lower() == ".py"])
    pdf.set_font("Helvetica", "", 12)
    pdf.set_text_color(0, 0, 0)
    pdf.multi_cell(0, 6, f"Total de arquivos encontrados: {len(todos_arquivos)}\n"
                          f"Arquivos .PS1: {ps1_count}\n"
                          f"Arquivos .PY: {py_count}\n"
                          f"Arquivo PS1 unificado: {unificado_path}\n"
                          f"ZIP gerado: {zip_path}\n")
    pdf.ln(5)

    pdf.set_font("Helvetica", "B", 14)
    pdf.set_text_color(0, 128, 0)
    pdf.cell(0, 10, "Fluxograma do processo", ln=True)
    pdf.image(fluxograma_path, w=180)
    pdf.ln(5)

    pdf.set_font("Helvetica", "B", 12)
    pdf.set_text_color(128, 0, 0)
    pdf.cell(0, 8, "Lista de arquivos encontrados:", ln=True)
    pdf.set_font("Helvetica", "", 10)

    for f in todos_arquivos:
        caminho = str(f)
        while len(caminho) > 95:
            pdf.multi_cell(0, 5, caminho[:95])
            caminho = caminho[95:]
        pdf.multi_cell(0, 5, caminho)

    pdf.output(pdf_path)
    print(f"[INFO] PDF gerado: {pdf_path}")
    return pdf_path

# ===============================
# EXECUÇÃO PRINCIPAL
# ===============================
if __name__ == "__main__":
    print("=== FULLONE - GERADOR AUTÔNOMO AVANÇADO ===\n")
    atualizar_script_oficial()

    todos_arquivos = buscar_arquivos()
    print(f"[INFO] Total arquivos encontrados: {len(todos_arquivos)}")
    print(f"[INFO] Arquivos .PS1: {len([f for f in todos_arquivos if f.suffix.lower()=='.ps1'])}")
    print(f"[INFO] Arquivos .PY: {len([f for f in todos_arquivos if f.suffix.lower()=='.py'])}")

    arquivos_recente = selecionar_versao_recente(todos_arquivos)
    print(f"[INFO] Arquivos selecionados (versão recente): {len(arquivos_recente)}")

    unificado_path = criar_unificado(arquivos_recente, PASTA_UNIFICADOS)
    zip_path = criar_zip(unificado_path, arquivos_recente)
    fluxograma_path = gerar_fluxograma()
    pdf_path = gerar_pdf(arquivos_recente, unificado_path, zip_path, fluxograma_path)

    print("=== FULLONE finalizado com sucesso! ===")