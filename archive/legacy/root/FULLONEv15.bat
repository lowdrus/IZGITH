<#
.SYNOPSIS
FULLONEv15 - Unifica e compila todos os scripts .ps1 e .py de várias pastas
.DESCRIPTION
Busca em todas as pastas definidas os arquivos .ps1 e .py, lista, conta, organiza, cria backup, gera relatórios e empacota em ZIP.
#>

# Configurações principais
$Global:FULLONE_VERSION = "FULLONEv15"
$Global:PACKAGE_DIR = "C:\SCRIPTS\PACKAGE"
$Global:LOG_FILE = Join-Path $Global:PACKAGE_DIR "$Global:FULLONE_VERSION`_log.txt"
$Global:COMBINED_SCRIPT = Join-Path $Global:PACKAGE_DIR "$Global:FULLONE_VERSION`_combined.ps1"
$Global:ZIP_FILE = Join-Path $Global:PACKAGE_DIR "$Global:FULLONE_VERSION`_package.zip"

# Lista de pastas para busca
$SearchPaths = @(
    "C:\CONAV TRADER",
    "C:\CONAV TRADER\CONAV_TRADER\automation",
    "C:\CONAV TRADER\CONAV_TRADER\build",
    "C:\CONAV TRADER\CONAV_TRADER\dashboard",
    "C:\CONAV TRADER\CONAV_TRADER\data",
    "C:\CONAV TRADER\CONAV_TRADER\database",
    "C:\CONAV TRADER\CONAV_TRADER\Desinstalar",
    "C:\CONAV TRADER\CONAV_TRADER\dist",
    "C:\CONAV TRADER\CONAV_TRADER\docs",
    "C:\CONAV TRADER\CONAV_TRADER\emails",
    "C:\CONAV TRADER\CONAV_TRADER\icons",
    "C:\CONAV TRADER\CONAV_TRADER\logs",
    "C:\CONAV TRADER\CONAV_TRADER\relatórios",
    "C:\CONAV TRADER\CONAV_TRADER\resources",
    "C:\CONAV TRADER\CONAV_TRADER\scripts",
    "C:\CONAV TRADER\CONAV_TRADER\tools",
    "C:\CONAV TRADER\CONAV_TRADER\automation\autocorrector",
    "C:\MAGIC QUANTIC TRADER\MEGA SUITE 001",
    "C:\MAGIC QUANTIC TRADER\MQT PACKAGE COMPLETE 002",
    "C:\MAGIC QUANTIC TRADER\MQT PACKAGE COMPLETE 003",
    "C:\MAGIC QUANTIC TRADER\MQT PACKAGE COMPLETE ALL IN ONE 004"
    # ... adicione as outras pastas conforme necessário
)

# Cria pasta de package se não existir
if (-not (Test-Path -Path $Global:PACKAGE_DIR)) { New-Item -ItemType Directory -Path $Global:PACKAGE_DIR -Force }

# Inicializa lista e contador
$AllFiles = @()
$TotalFiles = 0

# Busca arquivos .ps1 e .py
foreach ($path in $SearchPaths) {
    if (Test-Path $path) {
        $files = Get-ChildItem -Path $path -Recurse -Include *.ps1, *.py -ErrorAction SilentlyContinue
        $AllFiles += $files
        $TotalFiles += $files.Count
    } else {
        Write-Warning "Pasta não encontrada: $path (skipped)"
    }
}

# Salva log completo
$AllFiles | Select-Object FullName | Out-File -FilePath $Global:LOG_FILE -Encoding UTF8

Write-Host "Total de arquivos encontrados: $TotalFiles"

# Cria script combinado (organizado)
$CombinedContent = ""
foreach ($file in $AllFiles) {
    $CombinedContent += "`n`n# --- INICIO DO ARQUIVO: $($file.Name) ---`n"
    $CombinedContent += Get-Content -Path $file.FullName -Raw
    $CombinedContent += "`n# --- FIM DO ARQUIVO: $($file.Name) ---`n"
}
$CombinedContent | Out-File -FilePath $Global:COMBINED_SCRIPT -Encoding UTF8 -Force

Write-Host "Script combinado criado em: $Global:COMBINED_SCRIPT"

# Gerar ZIP final
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path $Global:ZIP_FILE) { Remove-Item $Global:ZIP_FILE -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($Global:PACKAGE_DIR, $Global:ZIP_FILE)
Write-Host "ZIP final criado em: $Global:ZIP_FILE"

# Mensagem final
Write-Host "$Global:FULLONE_VERSION concluído com sucesso!"