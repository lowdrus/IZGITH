from fpdf import FPDF
from datetime import datetime

# --------------------------
# Configurações
# --------------------------
pdf_path = r"C:\SCRIPTS\FULL ONE\DIAGRAMA VISUAL\FULLONEv14fixed2_fluxo.pdf"
titulo = "FULLONEv14fixed2 - Fluxo de Pacotes"

# Criação do PDF
pdf = FPDF()
pdf.add_page()

# Título
pdf.set_font("Arial", "B", 16)
pdf.set_text_color(0, 51, 102)
pdf.cell(0, 10, titulo, 0, 1, 'C')
pdf.ln(5)

# Data de geração
pdf.set_font("Arial", "", 12)
pdf.set_text_color(0, 0, 0)
pdf.cell(0, 10, f"Gerado em: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", 0, 1)
pdf.ln(5)

# Seções do fluxo
pdf.set_font("Arial", "B", 14)
pdf.set_text_color(255, 102, 0)
pdf.cell(0, 10, "Fluxo do Script Criar-Pacotes", 0, 1)
pdf.ln(3)

# Etapas
pdf.set_font("Arial", "", 12)
etapas = [
    "1. Verificação de atualização do script na pasta OFFICIAL",
    "2. Backup do script e do PS1 unificado anterior",
    "3. Busca de arquivos .PS1 e .PY em todas as pastas configuradas",
    "4. Contagem total de arquivos encontrados (.PS1, .PY)",
    "5. Criação do arquivo unificado ONEFULL.ps1",
    "6. Criação de ZIP incremental com arquivos unificados e soltos",
    "7. Geração de PDF detalhado com:",
    "   - Contagem de arquivos",
    "   - Lista de pastas pesquisadas",
    "   - Tabela de versões e mudanças",
    "   - Fluxograma visual do projeto"
]

for i, etapa in enumerate(etapas, 1):
    pdf.set_text_color(0, 0, 128)
    pdf.multi_cell(0, 8, f"{i}. {etapa}")
    pdf.ln(1)

# Observações
pdf.set_font("Arial", "I", 11)
pdf.set_text_color(128, 0, 0)
pdf.ln(5)
pdf.multi_cell(0, 7, "- O script mantém backups automáticos e versões incrementais.\n- PDF e ZIP sempre atualizados.\n- Fluxograma gerado automaticamente via Graphviz.")

# Salvar PDF
pdf.output(pdf_path)
print(f"PDF gerado em: {pdf_path}")