def gerar_pdf(todos_arquivos, unificado_path, zip_path, fluxograma_path):
    """Gera PDF detalhado"""
    os.makedirs(PASTA_DIAGRAMA, exist_ok=True)
    pdf_path = Path(PASTA_DIAGRAMA) / f"{VERSAO_FULLONE}_relatorio_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Helvetica", "B", 16)
    pdf.set_text_color(0, 0, 128)
    pdf.cell(0, 10, f"FULLONE Relatório - {VERSAO_FULLONE}", new_x=XPos.LMARGIN, new_y=YPos.NEXT, align="C")
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
    pdf.cell(0, 10, "Fluxograma do processo", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    if os.path.exists(fluxograma_path):
        pdf.image(fluxograma_path, w=180)
    pdf.ln(5)

    pdf.set_font("Helvetica", "B", 12)
    pdf.set_text_color(128, 0, 0)
    pdf.cell(0, 8, "Lista de arquivos encontrados:", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("Helvetica", "", 10)

    # Quebra de linha segura para caminhos longos
    max_len = 95
    for f in todos_arquivos:
        caminho = str(f)
        while len(caminho) > max_len:
            pdf.multi_cell(0, 5, caminho[:max_len])
            caminho = caminho[max_len:]
        pdf.multi_cell(0, 5, caminho)

    pdf.output(pdf_path)
    print(f"[INFO] PDF gerado: {pdf_path}")
    return pdf_path