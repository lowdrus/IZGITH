
import os
import shutil
import zipfile
from pathlib import Path
from datetime import datetime
import glob
from fpdf import FPDF
import graphviz

# -- Configuração de pastas e versão --
VERSAO_FULLONE = "FULLONEv14fixed2"
PASTA_OFICIAL = r"C:\SCRIPTS\FULL ONE\OFFICIAL"
PASTA_EXEC = r"C:\SCRIPTS\FULL ONE\FULL ONE GENERATOR"
PASTA_UNIFICADOS = r"C:\SCRIPTS\FULL ONE\ARQUIVOS .PS1 UNIFICADOS"
PASTA_PACKAGE = r"C:\SCRIPTS\FULL ONE\PACKAGE"
PASTA_DIAGRAMA = r"C:\SCRIPTS\FULL ONE\DIAGRAMA VISUAL"

PASTAS_PROCURA = [
    r"C:\CONAV TRADER\",
    r"C:\USERAT\",
    r"C:\UNIC QUANTIC\",
]

NOME_UNIFICADO = "ONEFULL.ps1"

def atualizar_script_oficial():
    arquivo_oficial = os.path.join(PASTA_OFICIAL, "criar-pacotes.py")
    arquivo_exec = os.path.join(PASTA_EXEC, "criar-pacotes.py")

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
            backup_path = arquivo_exec.replace(".py", f"_backup_{timestamp}.py")
            shutil.copy2(arquivo_exec, backup_path)
            print(f"[INFO] Backup do script antigo salvo: {backup_path}")
        shutil.copy2(arquivo_oficial, arquivo_exec)
        print("[INFO] Script atualizado automaticamente.")

def buscar_arquivos():
    todos_arquivos = {}
    for pasta in PASTAS_PROCURA:
        if os.path.exists(pasta):
            for ext in ("*.ps1", "*.py"):
                for arquivo in Path(pasta).rglob(ext):
                    key = arquivo.name.lower()
                    if key in todos_arquivos:
                        if arquivo.stat().st_mtime > todos_arquivos[key].stat().st_mtime:
                            todos_arquivos[key] = arquivo
                    else:
                        todos_arquivos[key] = arquivo
    return list(todos_arquivos.values())

def criar_unificado(arquivos, pasta_saida):
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
    dot = graphviz.Digraph(comment='FULLONE Fluxograma')
    dot.node('A', 'Início')
    dot.node('B', 'Busca arquivos')
    dot.node('C', 'Unifica PS1')
    dot.node('D', 'Cria ZIP')
    dot.node('E', 'Gera PDF')
    dot.edges(['AB','BC','CD','DE'])
    diagram_path = Path(PASTA_DIAGRAMA) / f"FULLONE_Fluxograma_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    os.makedirs(PASTA_DIAGRAMA, exist_ok=True)
    dot.render(str(diagram_path), format='png', cleanup=True)
    return str(diagram_path) + ".png"

def gerar_pdf(todos_arquivos, unificado_path, zip_path, fluxograma_path):
    os.makedirs(PASTA_DIAGRAMA, exist_ok=True)
    pdf_path = Path(PASTA_DIAGRAMA) / f"{VERSAO_FULLONE}_relatorio_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", "B", 16)
    pdf.set_text_color(0, 0, 128)
    pdf.cell(0, 10, f"FULLONE Relatório - {VERSAO_FULLONE}", ln=True, align="C")
    pdf.ln(5)

    ps1_count = len([f for f in todos_arquivos if f.suffix.lower() == ".ps1"])
    py_count = len([f for f in todos_arquivos if f.suffix.lower() == ".py"])

    pdf.set_font("Arial", "", 12)
    pdf.set_text_color(0,0,0)
    pdf.multi_cell(0, 6, f"Total de arquivos encontrados: {len(todos_arquivos)}\nArquivos .PS1: {ps1_count}\nArquivos .PY: {py_count}\nArquivo PS1 unificado: {unificado_path}\nZIP gerado: {zip_path}")

    pdf.set_font("Arial", "B", 14)
    pdf.set_text_color(0,128,0)
    pdf.cell(0,10,"Fluxograma do processo", ln=True)
    pdf.image(fluxograma_path, w=180)
    pdf.output(pdf_path)
    print(f"[INFO] PDF gerado: {pdf_path}")
    return pdf_path

if __name__ == "__main__":
    print("=== FULLONE - GERADOR AUTÔNOMO AVANÇADO ===\n")
    atualizar_script_oficial()
    todos_arquivos = buscar_arquivos()
    print(f"[INFO] Total arquivos encontrados: {len(todos_arquivos)}")
    unificado_path = criar_unificado(todos_arquivos, PASTA_UNIFICADOS)
    zip_path = criar_zip(unificado_path)
    fluxograma_path = gerar_fluxograma()
    gerar_pdf(todos_arquivos, unificado_path, zip_path, fluxograma_path)
