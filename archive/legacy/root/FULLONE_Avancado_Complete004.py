import os
import shutil
import zipfile
import difflib
from fpdf import FPDF
from datetime import datetime

# Função para buscar arquivos nas pastas especificadas
def buscar_arquivos(pastas):
    arquivos = []
    for pasta in pastas:
        for root, dirs, files in os.walk(pasta):
            for file in files:
                if file.endswith(('.ps1', '.py')):
                    arquivos.append(os.path.join(root, file))
    return arquivos

# Função para comparar dois arquivos e retornar as diferenças
def comparar_arquivos(arquivo1, arquivo2):
    with open(arquivo1, 'r', encoding='utf-8') as f1, open(arquivo2, 'r', encoding='utf-8') as f2:
        diff = difflib.unified_diff(f1.readlines(), f2.readlines(), fromfile=arquivo1, tofile=arquivo2)
        return ''.join(diff)

# Função para gerar o PDF com os comparativos
def gerar_pdf(comparativos, output_pdf):
    pdf = FPDF()
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()
    pdf.set_font("Arial", size=12)
    for comparativo in comparativos:
        pdf.multi_cell(0, 10, comparativo)
    pdf.output(output_pdf)

# Função para criar o arquivo ZIP com o script unificado e backups
def criar_zip(arquivos, output_zip):
    with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for arquivo in arquivos:
            zipf.write(arquivo, os.path.basename(arquivo))

# Função principal
def main():
    pastas = [
        r"C:\CONAV TRADER",
        r"C:\CONAV TRADER\CONAV_TRADER\automation",
        r"C:\CONAV TRADER\CONAV_TRADER\build",
        r"C:\CONAV TRADER\CONAV_TRADER\build\automation",
        r"C:\CONAV TRADER\CONAV_TRADER\build\build",
        r"C:\CONAV TRADER\CONAV_TRADER\build\build\automation",
        r"C:\CONAV TRADER\CONAV_TRADER\build\build\build",
        r"C:\CONAV TRADER\CONAV_TRADER\build\build\build\automation",
        r"C:\CONAV TRADER\CONAV_TRADER\build\build\build\build",
        r"C:\CONAV TRADER\CONAV_TRADER\build\build\build\build\automation"
    ]
    arquivos = buscar_arquivos(pastas)
    comparativos = []
    for i in range(len(arquivos)):
        for j in range(i + 1, len(arquivos)):
            diff = comparar_arquivos(arquivos[i], arquivos[j])
            if diff:
                comparativos.append(diff)
    gerar_pdf(comparativos, "comparativos.pdf")
    criar_zip(arquivos, "arquivos.zip")

if __name__ == "__main__":
    main()