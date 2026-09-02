import os
import shutil
import zipfile
from pathlib import Path
from datetime import datetime

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

VERSAO_FULLONE = "FULLONEv14fixed2"
NOME_UNIFICADO = "ONEFULL.ps1"

# --------------------------
# FUNÇÕES AUXILIARES
# --------------------------
def criar_pastas(*pastas):
    for p in pastas:
        os.makedirs(p, exist_ok=True)

def buscar_arquivos(extensoes=(".ps1", ".py")):
    arquivos = []
    for pasta in PASTAS_PROCURAR:
        base = Path(pasta)
        if base.exists():
            for ext in extensoes:
                arquivos.extend(list(base.rglob(f"*{ext}")))
    return arquivos

def salvar_unificado(arquivos, pasta_saida):
    criar_pastas(pasta_saida)
    ps1_unificado_path = Path(pasta_saida) / NOME_UNIFICADO

    if ps1_unificado_path.exists():
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup = ps1_unificado_path.with_name(f"{ps1_unificado_path.stem}_backup_{timestamp}.ps1")
        shutil.move(ps1_unificado_path, backup)
        print(f"[INFO] Backup do PS1 unificado antigo salvo em: {backup}")

    cabecalho = f"# =============================================\n" \
                 f"# {VERSAO_FULLONE} - PS1 Unificado (ONEFULL)\n" \
                 f"# Gerado em {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n" \
                 f"# =============================================\n\n"

    with open(ps1_unificado_path, 'w', encoding='utf-8') as f:
        f.write(cabecalho)
        for arq in arquivos:
            try:
                with open(arq, 'r', encoding='utf-8') as a:
                    conteudo = a.read()
                f.write(f"# ===== INICIO {arq.name} =====\n")
                f.write(conteudo + "\n")
                f.write(f"# ===== FIM {arq.name} =====\n\n")
            except Exception as e:
                print(f"[ERRO] Não foi possível ler {arq}: {e}")

    print(f"[INFO] PS1 unificado criado: {ps1_unificado_path}")
    return ps1_unificado_path

def gerar_zip(unificado_path):
    criar_pastas(PASTA_PACKAGE)
    contador = 1
    while True:
        zip_name = f"{VERSAO_FULLONE}_{contador:04d}.zip"
        zip_path = Path(PASTA_PACKAGE) / zip_name
        if not zip_path.exists():
            break
        contador += 1

    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        zipf.write(unificado_path, arcname=NOME_UNIFICADO)
        for arq in Path(PASTA_SOLTOS).glob("*"):
            zipf.write(arq, arcname=arq.name)

    print(f"[INFO] ZIP criado: {zip_path}")
    return zip_path

def atualizar_script_oficial():
    arquivo_oficial = Path(PASTA_OFICIAL) / "criar-pacotes.py"
    arquivo_exec = Path(PASTA_SOLTOS) / "criar-pacotes.py"

    if not arquivo_oficial.exists():
        print(f"[AVISO] Nenhum arquivo oficial encontrado em {PASTA_OFICIAL}")
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
            backup_name = arquivo_exec.with_name(f"{arquivo_exec.stem}_backup_{timestamp}.py")
            shutil.move(arquivo_exec, backup_name)
            print(f"[INFO] Backup do script antigo salvo em: {backup_name}")

        # Versionamento automático
        n = 1
        while True:
            novo_nome = Path(PASTA_SOLTOS) / f"criar-pacotes{str(n).zfill(4)}.py"
            if not novo_nome.exists():
                break
            n += 1
        shutil.copy2(arquivo_oficial, novo_nome)
        print(f"[INFO] Script atualizado/versão nova salva como: {novo_nome}")

# --------------------------
# EXECUÇÃO
# --------------------------
if __name__ == "__main__":
    print(f"=== GERADOR FULLONE {VERSAO_FULLONE} ===\n")

    criar_pastas(PASTA_SOLTOS, PASTA_UNIFICADO, PASTA_COMPILADOS, PASTA_PACKAGE)

    # Atualiza o script oficial
    atualizar_script_oficial()

    # Buscar arquivos
    arquivos_encontrados = buscar_arquivos()
    print(f"[INFO] Total de arquivos encontrados: {len(arquivos_encontrados)}")
    for arq in arquivos_encontrados:
        print(f" - {arq}")

    # Criar PS1 unificado
    unificado = salvar_unificado(arquivos_encontrados, PASTA_UNIFICADO)

    # Criar ZIP incremental
    gerar_zip(unificado)

    print("\n=== FIM DO PROCESSO ===")