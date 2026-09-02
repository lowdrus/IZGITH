import os
import glob
import zipfile
from datetime import datetime

# ===================== CONFIGURAÇÃO =====================
# Pastas a vasculhar
PASTAS = [
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
    r"C:\CONAV TRADER\CONAV_TRADER\build\Desinstalar\localpycs",
    r"C:\CONAV TRADER\CONAV_TRADER\build\Desinstalar\base_library.zip",
    r"C:\MAGIC QUANTIC TRADER",
    r"C:\MAGIC QUANTIC TRADER\MQT PACKAGE COMPLETE 001",
    r"C:\MAGIC QUANTIC TRADER\MQT PACKAGE COMPLETE 002",
    r"C:\MAGIC QUANTIC TRADER\MQT PACKAGE COMPLETE 003",
    r"C:\MAGIC QUANTIC TRADER\MQT PACKAGE COMPLETE ALL IN ONE 004",
    r"C:\USERAT",
    r"C:\USERAT\scripts",
    r"C:\TESTEE 2",
    r"C:\TESTEE 3",
    r"C:\UNIC QUANTIC",
]

# Pastas de saída
PASTA_SAIDA_SOLTA = r"C:\SCRIPTS\FULL ONE\FULL ONE GENERATOR"
PASTA_UNIFICADOS = r"C:\SCRIPTS\FULL ONE\ARQUIVOS .PS1 UNIFICADOS"
PASTA_COMPILADOS = r"C:\SCRIPTS\FULL ONE\COMPILADOS"

VERSAO = "FULLONEv14fixed2"
NOME_UNIFICADO = "ONEFULL.ps1"


# ===================== FUNÇÕES =====================
def buscar_arquivos(extensoes=("*.ps1", "*.py")):
    todos_arquivos = []
    for pasta in PASTAS:
        for ext in extensoes:
            encontrados = glob.glob(os.path.join(pasta, "**", ext), recursive=True)
            todos_arquivos.extend(encontrados)
    return todos_arquivos


def criar_unificado(arquivos, pasta_saida):
    if not os.path.exists(pasta_saida):
        os.makedirs(pasta_saida)
    unificado_path = os.path.join(pasta_saida, NOME_UNIFICADO)

    with open(unificado_path, "w", encoding="utf-8") as unificado:
        unificado.write(f"# Cabeçalho versão {VERSAO}\n\n")
        for arquivo in arquivos:
            try:
                with open(arquivo, "r", encoding="utf-8") as f:
                    unificado.write(f"# ===== Arquivo: {arquivo} =====\n")
                    unificado.write(f.read() + "\n\n")
            except UnicodeDecodeError:
                print(f"[WARN] Não foi possível ler {arquivo} (encoding diferente).")
            except Exception as e:
                print(f"[ERROR] Erro lendo {arquivo}: {e}")

    print(f"[INFO] Arquivo unificado criado: {unificado_path}")
    return unificado_path


def criar_zip(arq_unificado):
    pasta_zip = input("Informe a pasta onde deseja salvar o ZIP (ex: C:\\SCRIPTS\\FULL ONE\\PACKAGE): ").strip()
    if not os.path.exists(pasta_zip):
        os.makedirs(pasta_zip)

    # Gerar nome sequencial
    base_zip = os.path.join(pasta_zip, VERSAO)
    contador = 1
    zip_path = f"{base_zip}.zip"
    while os.path.exists(zip_path):
        contador += 1
        zip_path = f"{base_zip}{str(contador).zfill(4)}.zip"

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        # Adicionar arquivo unificado
        zf.write(arq_unificado, arcname=os.path.basename(arq_unificado))
        # Adicionar arquivos soltos
        for arquivo in glob.glob(os.path.join(PASTA_SAIDA_SOLTA, "*")):
            zf.write(arquivo, arcname=os.path.basename(arquivo))

    print(f"[INFO] ZIP criado em: {zip_path}")


# ===================== EXECUÇÃO =====================
if __name__ == "__main__":
    print("Buscando arquivos .ps1 e .py nas pastas configuradas...")
    arquivos = buscar_arquivos()
    print(f"Total de arquivos encontrados: {len(arquivos)}")

    for a in arquivos:
        print(f" - {a}")

    # Criar arquivo unificado
    unificado = criar_unificado(arquivos, PASTA_UNIFICADOS)

    # Criar ZIP
    criar_zip(unificado)