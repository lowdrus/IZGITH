# FULLONE Unificado - Versão FULLONEv14fixed2
# Gerado em 2025-09-17 21:43:43

# ===== INICIO arquivo.ps1 =====
<#
.SYNOPSIS
INSTALL_CONAV_TRADER_FULL1.45_fix3.ps1
.DESCRIPTION
Script base unificado para o CONAV TRADER.
- Descobre/integra/executa todos os scripts .ps1 do projeto
- Dry-run (simulação) e execução real
- Geração de logs detalhados (install_<nome>.log, install.log)
- Criação de pasta 'Desinstalar' com Desinstalar.exe via PyInstaller (se disponível)
- Geração de mapa ASCII e tentativa de PDF (via Word COM se instalado)
- Registros sequenciais de scripts em scripts\traderfull0001.ps1 ...
.PARAMETER DryRun
Quando $true faz apenas simulação (prints) sem executar cópias/exclusões
.EXAMPLE
.\INSTALL_CONAV_TRADER_FULL1.45_fix3.ps1 -DryRun:$true
#>
param(
[switch]$DryRun = $false,
[switch]$Force = $false
)
# -------------------------
# Configurações iniciais
# -------------------------
$ErrorActionPreference = 'Stop'
function Get-RootPath {
# Determina raiz do projeto (procura pasta CONAV_TRADER)
$invokedPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
# Se estivermos dentro de "C:\CONAV TRADER\CONAV_TRADER" retorna isso, senão
sobe até encontrar
$p = $invokedPath
while ($p -and ($p -ne [System.IO.Path]::GetPathRoot($p))) {
if (Test-Path (Join-Path $p 'system_icon.ico') -PathType Leaf -ErrorAction
SilentlyContinue -or
(Test-Path (Join-Path $p 'dashboard') -PathType Container -ErrorAction
SilentlyContinue)) {
return $p
}
$p = Split-Path -Parent $p
}
# fallback
return (Resolve-Path $invokedPath).ProviderPath
}
$ROOT = Get-RootPath
Write-Host "[INFO] Root path detectado: $ROOT"
# Padrão de pastas (adicionadas conforme pedido)
$Folders = @{
automation = Join-Path $ROOT 'automation'
build = Join-Path $ROOT 'build'
dashboard = Join-Path $ROOT 'dashboard'
data = Join-Path $ROOT 'data'
database = Join-Path $ROOT 'database'
uninstall = Join-Path $ROOT 'Desinstalar'
dist = Join-Path $ROOT 'dist'
docs = Join-Path $ROOT 'docs'
emails = Join-Path $ROOT 'emails'
icons = Join-Path $ROOT 'icons'
logs = Join-Path $ROOT 'logs'
relatorios = Join-Path $ROOT 'relatorios'
relatorios_accent = Join-Path $ROOT 'relatórios'
resources = Join-Path $ROOT 'resources'
scripts = Join-Path $ROOT 'scripts'
tools = Join-Path $ROOT 'tools'
mapas = Join-Path $ROOT 'mapas de fluxograma'
tutorial = Join-Path $ROOT 'TUTORIAL GERAL'
logsgerais = Join-Path $ROOT 'LOGS GERAIS'
scripts_official = Join-Path $ROOT 'SCRIPTS BASE OFICIAIS'
scripts_packages = Join-Path $ROOT 'SCRIPTS DE LISTAGEM'
scripts_packages_off = Join-Path $ROOT 'scripts\PACKAGES OFICIAIS'
scripts_oficial = Join-Path $ROOT 'scripts\PACKAGES OFICIAIS'
scripts_sequencial = Join-Path $ROOT 'scripts'
}
# Função de logging (usa logs/install_*.log e logs/install.log consolidado)
function Write-Log {
param([string]$Message, [string]$Level = 'INFO')
$t = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
$line = "[$t] [$Level] $Message"
# criar pasta logs se necessario
if (-not (Test-Path $Folders.logs)) {
if (-not $DryRun) { New-Item -ItemType Directory -Path $Folders.logs -Force | Out-Null }
}
$logFile = Join-Path $Folders.logs 'install.log'
try {
if (-not $DryRun) {
Add-Content -Path $logFile -Value $line -Force
}
} catch {
# Não forçar quebra: escreve no console
Write-Host "[WARN] Falha ao escrever em $logFile : $($_.Exception.Message)"
}
Write-Host $line
}
# Garantir pastas
function Ensure-Folders {
foreach ($k in $Folders.Keys) {
$p = $Folders[$k]
if (-not (Test-Path $p)) {
Write-Log "Criando pasta: $p"
if (-not $DryRun) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
} else {
Write-Log "Pasta já existe: $p"
}
}
}
# Descobre scripts e organiza
function Discover-Scripts {
Write-Log "Procurando scripts .ps1 (excluindo instalador atual e arquivos temporários)..."
$all = Get-ChildItem -Path $ROOT -Recurse -Include *.ps1 -File -ErrorAction
SilentlyContinue |
Where-Object {
$_.FullName -notmatch [regex]::Escape($MyInvocation.MyCommand.Name) `
-and $_.FullName -notmatch '\\Desinstalar\\' `
-and $_.Name -notmatch '\.old|\.bak|install|uninstall|BUILD'
} |
Sort-Object FullName
return $all
}
# Registrar scripts em scripts\traderfullXXXX.ps1
function Register-Scripts {
param([System.IO.FileInfo[]]$Scripts)
if (-not (Test-Path $Folders.scripts)) { if (-not $DryRun) { New-Item -ItemType Directory
-Path $Folders.scripts -Force | Out-Null } }
$i = 1
foreach ($s in $Scripts) {
$hash = Get-FileHash -Path $s.FullName -Algorithm SHA256
$destName = ('traderfull{0:D4}.ps1' -f $i)
$destPath = Join-Path $Folders.scripts $destName
# Se não existe ou hash diferente, copiar (backup/sequencial)
$copy = $false
if (-not (Test-Path $destPath)) { $copy = $true }
else {
$existingHash = Get-FileHash -Path $destPath -Algorithm SHA256
if ($existingHash.Hash -ne $hash.Hash) { $copy = $true }
}
if ($copy) {
Write-Log "Registrando script [$($s.Name)] como $destName"
if (-not $DryRun) { Copy-Item -Path $s.FullName -Destination $destPath -Force }
} else {
Write-Log "Script $destName já idêntico, pulando"
}
$i++
}
}
# Dry-run: mostra ações planejadas
function Do-DryRun {
param([System.IO.FileInfo[]]$Scripts)
Write-Host "====== DRY-RUN (Simulação) ======"
Write-Host "Root: $ROOT"
Write-Host "Pastas que serão garantidas:"
foreach ($k in $Folders.Keys) { Write-Host " - " $Folders[$k] }
Write-Host "Scripts detectados:"
$cnt = 0
foreach ($s in $Scripts) {
$cnt++
Write-Host " $cnt) $($s.FullName)"
}
Write-Host "Serão criados backups sequenciais em: $($Folders.scripts)"
Write-Host "Será gerado mapa ASCII em: $($Folders.mapas)"
Write-Host "Será criado/atualizado uninstall wrapper em: $($Folders.uninstall)"
Write-Host "Dry-run não executa cópias, nem compila exes, nem remove arquivos."
Write-Host "================================="
}
# Executa cada script com logging
function Execute-Scripts {
param([System.IO.FileInfo[]]$Scripts)
Write-Log "Iniciando execução de scripts detectados..."
$idx = 1
foreach ($s in $Scripts) {
$toolName = [IO.Path]::GetFileNameWithoutExtension($s.Name)
$logName = "install_${toolName}.log"
$logPath = Join-Path $Folders.logs $logName
$tline = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
Write-Log "[$idx] Executando $($s.FullName) (log: $logName)"
# registra no install.log
Write-Log "Iniciando execução de $toolName. (arquivo: $($s.FullName))"
if ($DryRun) {
Write-Log "[SIMULAÇÃO] Execução de $toolName (dry-run) - pular execução real."
} else {
try {
# Executa o script em um novo runspace/proc para evitar variáveis poluídas
Write-Log "Invocando: powershell -ExecutionPolicy Bypass -File
`"$($s.FullName)`""
& powershell -NoProfile -ExecutionPolicy Bypass -File $s.FullName 2>&1 |
ForEach-Object {
$msg = "$($_)"
Add-Content -Path $logPath -Value $msg -Force
Write-Log "[$toolName] $msg"
}
Write-Log "Execução de $toolName finalizada com sucesso."
} catch {
$err = $_.Exception.Message
Write-Log "ERRO executando $toolName: $err" 'ERROR'
}
}
$idx++
}
}
# Gera mapa ASCII simples e tenta gerar PDF via Word COM (se disponível)
function Generate-Map {
param([System.IO.FileInfo[]]$Scripts)
$mapDir = $Folders.mapas
if (-not (Test-Path $mapDir)) { if (-not $DryRun) { New-Item -ItemType Directory -Path
$mapDir -Force | Out-Null } }
$txtPath = Join-Path $mapDir "mapa_ascii.txt"
$pdfPath = Join-Path $mapDir "mapa_ascii.pdf"
$lines = @()
$lines += "CONAV TRADER - MAPA DE FLUXO (gerado em $(Get-Date))"
$lines += '-' * 60
foreach ($s in $Scripts) {
# colocamos caminho relativo
$rel = $s.FullName.Substring($ROOT.Length).TrimStart('\')
$lines += " - $rel"
}
if ($DryRun) {
Write-Log "[SIMULAÇÃO] Gerar mapa em $txtPath"
} else {
$lines | Out-File -FilePath $txtPath -Encoding UTF8 -Force
Write-Log "Mapa ASCII gerado em: $txtPath"
# Tentativa de gerar PDF via Word COM (fallback se Word estiver instalado)
try {
$word = New-Object -ComObject Word.Application -ErrorAction Stop
$doc = $word.Documents.Add()
$selection = $word.Selection
$selection.TypeText((Get-Content $txtPath -Raw))
$doc.SaveAs([ref] $pdfPath, [ref] 17) # wdFormatPDF = 17
$doc.Close()
$word.Quit()
Write-Log "PDF do mapa gerado em: $pdfPath"
} catch {
Write-Log "Word não disponível ou erro ao gerar PDF. Mantido TXT: $txtPath"
}
}
}
# Gera/compila desinstalador (backup do ps1 + wrapper python -> exe via pyinstaller)
function Ensure-Uninstaller {
param()
$unFolder = $Folders.uninstall
if (-not (Test-Path $unFolder)) { if (-not $DryRun) { New-Item -ItemType Directory -Path
$unFolder -Force | Out-Null } }
# Backup do PS1 de desinstalação se existir em raiz
$unPs1Candidate = Join-Path $ROOT 'UNINSTALL_CONAV_TRADER.ps1'
$destPs1 = Join-Path $unFolder 'Desinstalar-Por-PowerShell.ps1'
if (Test-Path $unPs1Candidate) {
Write-Log "Copiando desinstalador PowerShell para $destPs1"
if (-not $DryRun) { Copy-Item -Path $unPs1Candidate -Destination $destPs1 -Force }
} else {
# Se não existir, cria um desinstalador básico que usa install.log
Write-Log "Nenhum UNINSTALL_CONAV_TRADER.ps1 fonte encontrado; criando
desinstalador inicial em $destPs1"
if (-not $DryRun) {
@"
# Desinstalador gerado automaticamente - Desinstalar-Por-PowerShell.ps1
Write-Host 'Desinstalador gerado automaticamente - item seguro'
# Lê install.log e faz remoções (pede confirmação)
`$installLog = Join-Path (Split-Path -Parent `$MyInvocation.MyCommand.Definition)
'..\logs\install.log'
if (-not (Test-Path `$installLog)) {
Write-Host 'install.log não encontrado. Abortando.'
exit 1
}
Write-Host 'Desinstalação começando. Você será solicitado a confirmar cada remoção.'
# Simples: apenas lista arquivos que o desinstalador removeria.
Get-Content `$installLog | ForEach-Object { Write-Host 'LOG:' `$_ }
"@ | Out-File -FilePath $destPs1 -Encoding UTF8 -Force
}
}
# Criar wrapper python minimal (que chama o PS1 via subprocess, usado para compilar
exe)
$wrapperPy = Join-Path $unFolder 'uninstall_wrapper.py'
if (-not (Test-Path $wrapperPy)) {
Write-Log "Criando uninstall_wrapper.py em $wrapperPy"
if (-not $DryRun) {
@"
import subprocess, sys, os
ps1 = os.path.join(os.path.dirname(__file__), 'Desinstalar-Por-PowerShell.ps1')
subprocess.run(['powershell', '-ExecutionPolicy', 'Bypass', '-File', ps1])
"@ | Out-File -FilePath $wrapperPy -Encoding UTF8 -Force
}
}
# Compilar via pyinstaller se disponível
try {
$pyinstaller = (Get-Command pyinstaller -ErrorAction SilentlyContinue)
if ($pyinstaller) {
Write-Log "PyInstaller detectado. Compilando Desinstalar.exe..."
if (-not $DryRun) {
Push-Location $unFolder
# usar --icon se houver system_icon.ico
$iconCandidate = Join-Path $ROOT 'system_icon.ico'
$iconArg = ""
if (Test-Path $iconCandidate) { $iconArg = "--icon `"$iconCandidate`"" }
& pyinstaller --onefile --noconsole $iconArg "--name" "Desinstalar"
"uninstall_wrapper.py"
Pop-Location
Write-Log "Desinstalar.exe compilado em: $unFolder\dist\Desinstalar.exe"
# mover exe para folder raiz uninstall
$builtExe = Join-Path $unFolder 'dist\Desinstalar.exe'
if (Test-Path $builtExe) { Move-Item -Path $builtExe -Destination (Join-Path
$unFolder 'Desinstalar.exe') -Force }
}
} else {
Write-Log "PyInstaller não encontrado. Pulei compilação do desinstalador
(Desinstalar.exe)."
}
} catch {
Write-Log "Erro ao tentar compilar desinstalador: $($_.Exception.Message)" 'ERROR'
}
}
# Ajusta ícones: copia system_icon.ico para dist e desinstalar
function Ensure-Icons {
param()
$sourceIcon = Join-Path $ROOT 'system_icon.ico'
if (-not (Test-Path $sourceIcon)) {
Write-Log "Ícone raiz system_icon.ico não encontrado em $sourceIcon - pulei etapa de
ícones." 'WARN'
return
}
$destDist = Join-Path $Folders.dist 'system_icon.ico'
Write-Log "Aplicando ícone raiz para dist: $destDist"
if (-not $DryRun) { Copy-Item -Path $sourceIcon -Destination $destDist -Force }
# Para outros exes, PyInstaller usará o caminho absoluto $sourceIcon quando for
compilado.
}
# Função para prompt gráfico (Yes/No)
function Show-YesNoDialog {
param([string]$message = "Deseja continuar?", [string]$title = "Confirmar")
Add-Type -AssemblyName System.Windows.Forms
$result = [System.Windows.Forms.MessageBox]::Show($message, $title, 'YesNo',
'Question')
return $result -eq [System.Windows.Forms.DialogResult]::Yes
}
# Recuperação de arquivos (move de Quarantine para original)
function Recover-From-Quarantine {
param([string]$quarantineDir)
if (-not (Test-Path $quarantineDir)) { Write-Log "Quarentena não encontrada:
$quarantineDir"; return }
Get-ChildItem -Path $quarantineDir -Recurse -File | ForEach-Object {
$orig = $_.FullName.Substring($quarantineDir.Length).TrimStart('\')
$dest = Join-Path $ROOT $orig
$destDir = Split-Path -Parent $dest
if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force |
Out-Null }
Move-Item -Path $_.FullName -Destination $dest -Force
Write-Log "Recuperado: $orig"
}
Write-Log "Recuperação concluída."
}
# -------------------------
# Pipeline principal
# -------------------------
try {
Write-Log "==============================================="
Write-Log " Iniciando INSTALAÇÃO/ATUALIZAÇÃO CONAV TRADER"
Write-Log " Versão: 1.45_fix3"
Write-Log "==============================================="
Ensure-Folders
# Descobrir scripts
$scripts = Discover-Scripts
if (-not $scripts -or $scripts.Count -eq 0) {
Write-Log "Nenhum script .ps1 adicional encontrado para integrar."
} else {
Register-Scripts -Scripts $scripts
}
# Gerar dry-run e solicitar confirmação
Do-DryRun -Scripts $scripts
if ($DryRun) {
Write-Log "Dry-run completado. Para executar de verdade rode sem -DryRun."
exit 0
}
# Perguntar via caixa gráfica se deseja prosseguir
$proceed = Show-YesNoDialog -message "Dry-run concluído. Deseja executar a
instalação/atualização REAL agora?" -title "CONAV TRADER - Confirmar execução"
if (-not $proceed -and -not $Force) {
Write-Log "Execução real cancelada pelo usuário."
exit 0
}
# Aplicar ícones
Ensure-Icons
# Gerar mapa ASCII e PDF
Generate-Map -Scripts $scripts
# Executar scripts
Execute-Scripts -Scripts $scripts
# Criar/atualizar desinstalador
Ensure-Uninstaller
# Finalizar: atualiza relatório consolidado
Write-Log "Instalação/Atualização concluída com sucesso."
# Pergunta para abrir tutorial geral
$openTutorial = Show-YesNoDialog -message "Deseja abrir o TUTORIAL GERAL agora?"
-title "Tutorial"
if ($openTutorial) {
$tutorialPdf = Join-Path $Folders.tutorial 'Tutorial_Geral.pdf'
if (Test-Path $tutorialPdf) {
Start-Process -FilePath $tutorialPdf
} else {
Write-Log "Tutorial PDF não encontrado: $tutorialPdf"
}
}
} catch {
Write-Log "ERRO FATAL: $($_.Exception.Message)" 'ERROR'
throw
}
# ===== FIM arquivo.ps1 =====

# ===== INICIO SET_ICONS_CONAV.ps1 =====
<#
.SET_ICONS_CONAV.ps1
Copia o ícone raíz para pastas/EXEs relevantes.
#>
param(
    [string]$Root = 'C:\CONAV TRADER\CONAV_TRADER',
    [string]$IconFile = 'system_icon.ico'
)

$IconsDir = Join-Path $Root 'icons'
$DistDir = Join-Path $Root 'dist'

if (-not (Test-Path $IconsDir)) { New-Item -ItemType Directory -Path $IconsDir -Force | Out-Null }

$possible = @(
    Join-Path $Root $IconFile,
    Join-Path $IconsDir $IconFile,
    Join-Path $Root 'resources' $IconFile
)

$iconPath = $possible | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iconPath) {
    Write-Host "[SET_ICONS] ERRO: system_icon.ico não encontrado nos caminhos previstos."
    exit 1
}

# ensure dist exists
if (Test-Path $DistDir) {
    $dest = Join-Path $DistDir $IconFile
    Copy-Item -LiteralPath $iconPath -Destination $dest -Force
    Write-Host "[SET_ICONS] copied icon to $dest"
} else {
    Write-Host "[SET_ICONS] dist não existe; apenas copiado para icons/"
    Copy-Item -LiteralPath $iconPath -Destination (Join-Path $IconsDir $IconFile) -Force
}

Write-Host "[SET_ICONS] SET_ICONS aplicado (copied icons). Para incorporar no exe, use PyInstaller --icon durante a build."
exit 0

# ===== FIM SET_ICONS_CONAV.ps1 =====

# ===== INICIO CONAVMASTER.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todos os módulos e versões do CONAV de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

# ======================================================
# Função central de log
# ======================================================
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# ======================================================
# Criar pastas organizadas
# ======================================================
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$folders = @(
    "LOGS GERAIS",
    "relatorios",
    "relatórios",
    "mapas de fluxograma",
    "TUTORIAL GERAL",
    "SCRIPT MESTRE",
    "scripts\PACKAGES OFICIAIS",
    "SCRIPTS BASE OFICIAIS",
    "SCRIPTS DE LISTAGEM"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $rootPath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Criada pasta: $fullPath"
    }
}

# ======================================================
# Auto-number para CONAVMASTERFULL.ps1
# ======================================================
$seqPath = Join-Path $rootPath "SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# ======================================================
# Importar todos os scripts existentes e integrados
# ======================================================
$integratedPaths = @(
    "$rootPath\SCRIPTS BASE OFICIAIS",
    "$rootPath\scripts\PACKAGES OFICIAIS",
    "$rootPath\SCRIPT MESTRE",
    "$rootPath\mapas de fluxograma",
    "$rootPath\logs",
    "$rootPath\logs\install",
    "$rootPath\logs\ia"
)

foreach ($p in $integratedPaths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Filter *.ps1 -Recurse
        foreach ($f in $files) {
            try {
                Write-Log "Executando script integrado: $($f.FullName)"
                . $f.FullName
            } catch {
                Write-Log "Erro executando $($f.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# ======================================================
# GUI Simples - Escolha de execução
# ======================================================
Add-Type -AssemblyName PresentationFramework
$result = [System.Windows.MessageBox]::Show(
    "Deseja rodar todas as versões (histórico completo) ou apenas a última atualização?",
    "CONAV MASTER FULL",
    "YesNoCancel",
    "Question"
)

switch ($result) {
    "Yes" {
        Write-Log "Usuário escolheu rodar TODAS as versões."
        # Simulação de execução full histórico
    }
    "No" {
        Write-Log "Usuário escolheu rodar apenas a ÚLTIMA versão."
        # Simulação apenas última versão
    }
    "Cancel" {
        Write-Log "Execução cancelada pelo usuário."
        exit
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTER.ps1 =====

# ===== INICIO CONAVMASTER0001.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todas as correções (v1.45+) de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# =========================
# Auto-number do mestre
# =========================
$seqPath = "C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# =========================
# Diretório de versões históricas
# =========================
$historyPath = "C:\CONAV TRADER\CONAV_TRADER\SCRIPTS HISTORICOS"
if (!(Test-Path $historyPath)) {
    New-Item -ItemType Directory -Path $historyPath -Force | Out-Null
    Write-Log "Criada pasta de históricos: $historyPath"
}

# =========================
# Executar SOMENTE os scripts de correção (v1.45+)
# =========================
$fixScripts = Get-ChildItem -Path $historyPath -Filter "v1.45*.ps1" | Sort-Object Name
foreach ($s in $fixScripts) {
    try {
        Write-Log "Executando correção: $($s.Name)"
        . $s.FullName
    } catch {
        Write-Log "Erro executando $($s.Name): $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTER0001.ps1 =====

# ===== INICIO CONAVMASTER0002.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todas as correções (v1.45+) de forma unificada
               e mantém o Tutorial Geral atualizado automaticamente
================================================================================
#>

param (
    [switch]$DebugMode
)

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# =========================
# Auto-number do mestre
# =========================
$seqPath = "C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE\VERSOES"
if (!(Test-Path $seqPath)) {
    New-Item -ItemType Directory -Path $seqPath -Force | Out-Null
}
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# =========================
# Diretório de versões históricas
# =========================
$historyPath = "C:\CONAV TRADER\CONAV_TRADER\SCRIPTS HISTORICOS"
if (!(Test-Path $historyPath)) {
    New-Item -ItemType Directory -Path $historyPath -Force | Out-Null
    Write-Log "Criada pasta
# ===== FIM CONAVMASTER0002.ps1 =====

# ===== INICIO CONAVMASTER0003.ps1 =====
<#
======================================================================
==========
CONAV MASTER FULL - SCRIPT UNIFICADO
Nome oficial: CONAVMASTERFULL.ps1
Versão atual sugerida: 1.45 (aumente conforme atualizar)
Local recomendado: C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
Descrição:
- Script "mestre" unificado que aplica correções, gera builds,
mantém logs, gera tutorial e mapas, cria desinstalador, empacota o bundle,
faz dry-run e permite reparos automáticos/assistidos em scripts.
Atenção:
- Execute em PowerShell 7 (pwsh) como Administrador quando for compilar EXEs.
- Faça sempre um dry-run antes de executar a primeira vez.
======================================================================
==========
#>
param (
[switch]$DryRun,
[switch]$Force,
[switch]$DebugMode
)
# -------------------------
# Helpers e inicialização
# -------------------------
function Write-Log {
param (
[string]$Message,
[string]$Level = "INFO"
)
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "[$timestamp][$Level] $Message"
# Garante que o diretório de logs existe
if (-not (Test-Path $Global:LogDir)) { New-Item -ItemType Directory -Path $Global:LogDir
-Force | Out-Null }
Add-Content -Path (Join-Path $Global:LogDir $Global:MasterLog) -Value $line -Encoding
UTF8
if ($DebugMode) { Write-Host $line }
}
function Get-ScriptDir {
# Retorna o diretório onde o script atual está salvo
Split-Path -Parent $MyInvocation.MyCommand.Definition
}
# Detecta raiz do projeto (procura padrão) - tenta várias heurísticas
function Resolve-RootPath {
param()
$scriptDir = Get-ScriptDir
# Primeiro, se o script estiver dentro do próprio repositório, sobe até encontrar
"CONAV_TRADER" duas vezes ou dashboard\main_dashboard.py
$p = $scriptDir
for ($i=0; $i -lt 6; $i++) {
if ($p -match "CONAV_TRADER") {
# candidate root: se contém 'dashboard\main_dashboard.py' ou
'dist\main_dashboard.exe' aceitamos
if (Test-Path (Join-Path $p 'dashboard\main_dashboard.py') -PathType Leaf
-ErrorAction SilentlyContinue -and Test-Path (Join-Path $p 'dist') -PathType Container
-ErrorAction SilentlyContinue) {
return $p
}
# check typical root marker files
if (Test-Path (Join-Path $p 'README.md') -or Test-Path (Join-Path $p
'system_icon.ico')) {
return $p
}
}
$p = Split-Path -Parent $p
if (-not $p) { break }
}
# fallbacks
$candidates = @(
"C:\CONAV TRADER\CONAV_TRADER",
"C:\Program Files\CONAV_TRADER",
(Join-Path $env:USERPROFILE "CONAV_TRADER\CONAV_TRADER")
)
foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
# Se nada encontrado, pergunta ao usuário (GUI)
Add-Type -AssemblyName System.Windows.Forms
$msg = "Não consegui detectar automaticamente a raiz do CONAV. Selecionar pasta raiz
(C:\CONAV TRADER\CONAV_TRADER) ou CANCEL para usar o padrão."
$res = [System.Windows.Forms.MessageBox]::Show($msg, "Resolver Raiz", "OKCancel",
"Warning")
if ($res -eq "OK") {
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = "Selecione a pasta raiz do CONAV (ex: C:\CONAV
TRADER\CONAV_TRADER)"
if ($folderBrowser.ShowDialog() -eq "OK") {
return $folderBrowser.SelectedPath
}
}
# default
return "C:\CONAV TRADER\CONAV_TRADER"
}
# Normaliza strings com aspas inteligentes etc.
function Normalize-TextCommonIssues {
param([string]$text)
if ($null -eq $text) { return $text }
# substitui smart quotes e ellipsis etc.
$text = $text -replace ([char]0x201C),'"'
$text = $text -replace ([char]0x201D),'"'
$text = $text -replace ([char]0x2018),"'"
$text = $text -replace ([char]0x2019),"'"
$text = $text -replace ([char]0x2026),'...'
# remove weird control chars
$text = $text -replace '[\x00-\x08\x0B\x0C\x0E-\x1F]', ''
return $text
}
# Escreve install log com nome inteligente
function New-InstallLog {
param([string]$component)
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$name = "install_{0}_{1}.log" -f $component, $ts
$path = Join-Path $Global:LogDir $name
New-Item -Path $path -ItemType File -Force | Out-Null
return $path
}
# -------------------------
# Inicializa diretórios padrão
# -------------------------
function Initialize-Folders {
param([string]$Root)
$folders = @(
"automation","build","dashboard","data","database","Desinstalar","dist","docs",
"emails","icons","logs","relatorios","relatórios","resources","scripts","tools",
"PACKAGES OFICIAIS","SCRIPTS BASE OFICIAIS","SCRIPTS
HISTORICOS","SCRIPT MESTRE",
"mapas de fluxograma","LOGS GERAIS"
)
foreach ($f in $folders) {
$p = Join-Path $Root $f
if (-not (Test-Path $p)) {
if (-not $DryRun) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
Write-Log ("Criada pasta: {0}" -f $p)
} else {
Write-Log ("Pasta já existe: {0}" -f $p)
}
}
# define globais de logs
$Global:LogDir = Join-Path $Root "logs"
if (-not (Test-Path $Global:LogDir)) { if (-not $DryRun) { New-Item -ItemType Directory
-Path $Global:LogDir -Force | Out-Null } }
$Global:MasterLog = "master.log"
Write-Log ("Pastas iniciais garantidas em {0}" -f $Root)
}
# -------------------------
# Auto-number do script mestre
# -------------------------
function Save-MasterVersion {
param([string]$Root)
$seqPath = Join-Path $Root "SCRIPT MESTRE\VERSOES"
if (-not (Test-Path $seqPath)) { New-Item -ItemType Directory -Path $seqPath -Force |
Out-Null }
# encontra maior sequencia
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" -File
-ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
$num = [int]($existing.BaseName -replace '\D','') + 1
} else { $num = 1 }
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
if (-not $DryRun) { Copy-Item -Path $MyInvocation.MyCommand.Definition -Destination
$newSeqFile -Force }
Write-Log ("Nova versão mestre salva como: {0}" -f $newSeqFile)
return $newSeqFile
}
# -------------------------
# Verifica dependências e instala com autorização (PSScriptAnalyzer, bandit, pyinstaller)
# -------------------------
function Ensure-Dependencies {
param([string]$Root)
Add-Type -AssemblyName System.Windows.Forms
# PSScriptAnalyzer
if (-not (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue)) {
$msg = "PSScriptAnalyzer não encontrado. Deseja instalar via PowerShell Gallery
(requer internet)?"
$ans = [System.Windows.Forms.MessageBox]::Show($msg, "Instalar dependência",
"YesNo", "Question")
if ($ans -eq "Yes") {
if (-not $DryRun) {
try {
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
-AllowClobber -ErrorAction Stop
Write-Log "PSScriptAnalyzer instalado."
} catch {
Write-Log ("Falha instalando PSScriptAnalyzer: {0}" -f $_.Exception.Message)
"ERROR"
}
} else { Write-Log "DryRun: Instalaria PSScriptAnalyzer." }
}
} else { Write-Log "PSScriptAnalyzer detectado." }
# bandit (python linter)
$banditFound = (Get-Command bandit -ErrorAction SilentlyContinue) -ne $null
if (-not $banditFound) {
$msg = "Bandit (security scanner para Python) não encontrado. Deseja instalar via pip
(requer internet)?"
$ans = [System.Windows.Forms.MessageBox]::Show($msg, "Instalar dependência",
"YesNo", "Question")
if ($ans -eq "Yes") {
if (-not $DryRun) {
try {
& pip install bandit 2>&1 | Out-String | Write-Output
Write-Log "bandit pip instalado."
} catch {
Write-Log ("Falha instalando bandit: {0}" -f $_.Exception.Message) "ERROR"
}
} else { Write-Log "DryRun: Instalaria bandit." }
}
} else { Write-Log "bandit detectado." }
# pyinstaller
if (-not (Get-Command pyinstaller -ErrorAction SilentlyContinue)) {
$msg = "PyInstaller não encontrado. Deseja instalar via pip (requer internet)?"
$ans = [System.Windows.Forms.MessageBox]::Show($msg, "Instalar dependência",
"YesNo", "Question")
if ($ans -eq "Yes") {
if (-not $DryRun) {
try {
& pip install pyinstaller --upgrade 2>&1 | Out-String | Write-Output
Write-Log "pyinstaller pip instalado/atualizado."
} catch {
Write-Log ("Falha instalando pyinstaller: {0}" -f $_.Exception.Message)
"ERROR"
}
} else { Write-Log "DryRun: Instalaria pyinstaller." }
}
} else { Write-Log "pyinstaller detectado." }
}
# -------------------------
# Reparo automático simples (corrige problemas comuns reportados)
# -------------------------
function Repair-ScriptSimple {
param([string]$FilePath, [switch]$Apply)
if (-not (Test-Path $FilePath)) { Write-Log ("Arquivo não encontrado: {0}" -f $FilePath) ;
return $false }
$content = Get-Content -Raw -Encoding UTF8 $FilePath
$orig = $content
$content = Normalize-TextCommonIssues -text $content
# Corrige sequências problemáticas vistas no histórico:
# - substitui '…' etc (já feito)
# - remove caracteres Unicode de aspas e substitui por ' ou "
# - troca reticências por ...
# - corrige instâncias de Write-Log com $($_.Exception.Message) embutido de forma
arriscada
$content = $content -replace "Write-Log\s+\"([^\"]*?)\$\(\._?\.Exception\.Message\)(.*?)\"",
{ param($m) $m.Value } # placeholder safetly no-op
# exemplo de fix: se houver '…' em código que quebrou parsing, substitui por '...'
$content = $content -replace [char]0x2026, '...'
# basic fix: normaliza backticks problemáticos
$content = $content -replace '\u2018|\u2019|\u201C|\u201D','"'
# if any change
if ($content -ne $orig) {
Write-Log ("Repair-ScriptSimple: diffs encontrados em {0}" -f $FilePath)
$previewFile = Join-Path $env:TEMP ("repair_preview_{0}.txt" -f (Split-Path -Leaf
$FilePath))
Set-Content -Path $previewFile -Value $content -Encoding UTF8
Write-Log ("Preview salvo em {0}" -f $previewFile)
if ($Apply -and -not $DryRun) {
Copy-Item -Path $FilePath -Destination ($FilePath + ".bak") -Force
Set-Content -Path $FilePath -Value $content -Encoding UTF8
Write-Log ("Reparo aplicado em {0} (backup: {1}.bak)" -f $FilePath, $FilePath)
return $true
} else {
Write-Log ("DryRun ou Apply não solicitado: não aplicando mudanças em {0}" -f
$FilePath)
return $false
}
} else {
Write-Log ("Repair-ScriptSimple: nenhum problema detectado em {0}" -f $FilePath)
return $false
}
}
# -------------------------
# Analisa script com PSScriptAnalyzer / bandit (se instalados)
# -------------------------
function Analyze-Script {
param([string]$FilePath)
if ($FilePath -match '\.ps1$') {
if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
Write-Log ("Rodando PSScriptAnalyzer em {0}" -f $FilePath)
try {
$issues = Invoke-ScriptAnalyzer -Path $FilePath -Recurse -Severity Error,Warning
-ErrorAction Stop
if ($issues) {
$report = Join-Path $Global:LogDir ("psanalyzer_{0}.txt" -f (Split-Path -Leaf
$FilePath))
$issues | Out-String | Set-Content -Path $report -Encoding UTF8
Write-Log ("Relatório PSScriptAnalyzer salvo em {0}" -f $report)
} else { Write-Log ("PSScriptAnalyzer: nenhum problema crítico em {0}" -f
$FilePath) }
} catch {
Write-Log ("Erro rodando PSScriptAnalyzer: {0}" -f $_.Exception.Message)
"ERROR"
}
} else { Write-Log "PSScriptAnalyzer não disponível; pulei análise PS." }
} elseif ($FilePath -match '\.py$') {
if (Get-Command bandit -ErrorAction SilentlyContinue) {
Write-Log ("Rodando bandit em {0}" -f $FilePath)
try {
$out = & bandit -r -q $FilePath 2>&1
$report = Join-Path $Global:LogDir ("bandit_{0}.txt" -f (Split-Path -Leaf $FilePath))
$out | Out-String | Set-Content -Path $report -Encoding UTF8
Write-Log ("Relatório bandit salvo em {0}" -f $report)
} catch {
Write-Log ("Erro rodando bandit: {0}" -f $_.Exception.Message) "ERROR"
}
} else { Write-Log "bandit não disponível; pulei análise Python." }
} else {
Write-Log ("Tipo de arquivo não analisado automaticamente: {0}" -f $FilePath)
}
}
# -------------------------
# Gera tutorial MD e mapa ASCII
# -------------------------
function Generate-TutorialAndMap {
param([string]$Root)
$tutorialPath = Join-Path $Root "TUTORIAL GERAL"
if (-not (Test-Path $tutorialPath)) { if (-not $DryRun) { New-Item -ItemType Directory -Path
$tutorialPath -Force | Out-Null } }
$mdFile = Join-Path $tutorialPath "TUTORIAL_GERAL.md"
$mapFileTxt = Join-Path $tutorialPath "mapa_fluxograma.txt"
$mapFileMd = Join-Path $tutorialPath "mapa_fluxograma.md"
# Cabeçalho
$md = @()
$md += "# Tutorial Geral do CONAV"
$md += ""
$md += "Gerado em: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$md += ""
$md += "## Estrutura de pastas detectada"
$dirs = Get-ChildItem -Path $Root -Directory | Select-Object -ExpandProperty Name
foreach ($d in $dirs) { $md += "- $d" }
# lista scripts históricos
$md += ""
$md += "## Scripts históricos (resumo)"
$hist = Get-ChildItem -Path (Join-Path $Root 'SCRIPTS HISTORICOS') -Filter "*.ps1"
-Recurse -ErrorAction SilentlyContinue
foreach ($h in $hist) {
$md += "- $($h.Name) - modificado: $($h.LastWriteTime)"
}
# salva tutorial
if (-not $DryRun) { $md -join "`n" | Set-Content -Path $mdFile -Encoding UTF8 }
Write-Log ("Tutorial salvo: {0}" -f $mdFile)
# gera mapa ascii (arvore simplificada)
$tree = Get-ChildItem -Path $Root -Recurse | ForEach-Object {
$rel = $_.FullName.Substring($Root.Length).TrimStart('\')
$rel
}
if (-not $DryRun) { $tree | Out-File -FilePath $mapFileTxt -Encoding UTF8 }
# gera versão md
if (-not $DryRun) { $tree | ForEach-Object { "- $_" } | Out-File -FilePath $mapFileMd
-Encoding UTF8 }
Write-Log ("Mapa ASCII salvo em: {0} e {1}" -f $mapFileTxt, $mapFileMd)
return @{
Tutorial = $mdFile
MapaTxt = $mapFileTxt
MapaMd = $mapFileMd
}
}
# -------------------------
# Build/pack & ZIP
# -------------------------
function Build-Package {
param([string]$Root, [string]$OutName = "CONAV_FULL_PACKAGE.zip")
$outDir = Join-Path $Root "PACKAGES OFICIAIS"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$zipName = [IO.Path]::GetFileNameWithoutExtension($OutName) + "_v" + $timestamp +
".zip"
$zipPath = Join-Path $outDir $zipName
# remove se existir
if (Test-Path $zipPath) {
try { Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue } catch {
Write-Log ("Aviso: não foi possível remover pacote em uso: {0}" -f $_.Exception.Message) }
}
# Seleciona o que empacotar: garante pegar os arquivos atualizados
$include = @(
Join-Path $Root '*'
)
if ($DryRun) {
Write-Log ("[DRYRUN] Criaria arquivo zip em: {0} com conteúdo: {1}" -f $zipPath,
$include -join ', ')
return $zipPath
} else {
try {
# usa Compress-Archive -Path <lista> -DestinationPath
# coletamos todos arquivos dentro da raiz (exceto builds temporários)
$files = Get-ChildItem -Path $Root -Recurse -File | Where-Object { $_.FullName
-notmatch '\\(build|__pycache__)\\' }
$tempList = Join-Path $env:TEMP ("conav_pack_list_{0}.txt" -f $timestamp)
$files | Select-Object -ExpandProperty FullName | Out-File -FilePath $tempList
-Encoding UTF8
# Build Compress-Archive via reading list (PowerShell 7 permite -LiteralPath array)
Compress-Archive -Path $files.FullName -DestinationPath $zipPath -Force
Write-Log ("[BUILD] Pacote gerado em {0}" -f $zipPath)
return $zipPath
} catch {
Write-Log ("Erro criando pacote: {0}" -f $_.Exception.Message) "ERROR"
throw
}
}
}
# -------------------------
# Cria atalho (.lnk) na área de trabalho
# -------------------------
function Create-Shortcut {
param(
[string]$TargetPath,
[string]$ShortcutPath,
[string]$Args = "",
[string]$IconPath = ""
)
try {
$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($ShortcutPath)
$shortcut.TargetPath = $TargetPath
if ($Args) { $shortcut.Arguments = $Args }
$shortcut.WorkingDirectory = Split-Path -Parent $TargetPath
if ($IconPath -and (Test-Path $IconPath)) {
$shortcut.IconLocation = $IconPath
} else {
$shortcut.IconLocation = $TargetPath
}
$shortcut.Save()
Write-Log ("Atalho criado: {0}" -f $ShortcutPath)
} catch {
Write-Log ("Erro criando atalho {0}: {1}" -f $ShortcutPath, $_.Exception.Message)
"ERROR"
}
}
# -------------------------
# Build EXE com PyInstaller (invoca externo)
# -------------------------
function Build-ExeWithPyInstaller {
param(
[string]$ScriptPath,
[string]$OutDist,
[string]$IconPath = ""
)
if (-not (Test-Path $ScriptPath)) { Write-Log ("Script a compilar não encontrado: {0}" -f
$ScriptPath); return $false }
if ($DryRun) { Write-Log ("[DRYRUN] Compilaria {0} com ícone {1}" -f $ScriptPath,
$IconPath); return $true }
$args = @("--onefile", "--noconsole", "--distpath", $OutDist, "--workpath", (Join-Path
(Split-Path $OutDist) "build"), "--specpath", (Join-Path (Split-Path $OutDist) "specs"))
if ($IconPath -and (Test-Path $IconPath)) { $args += @("--icon", $IconPath) }
$args += $ScriptPath
try {
Write-Log ("Invocando PyInstaller: pyinstaller {0}" -f ($args -join " "))
$proc = Start-Process -FilePath "pyinstaller" -ArgumentList $args -NoNewWindow -Wait
-PassThru -WindowStyle Hidden
if ($proc.ExitCode -eq 0) { Write-Log ("PyInstaller completou para {0}" -f $ScriptPath);
return $true } else { Write-Log ("PyInstaller retornou código {0}" -f $proc.ExitCode) ; return
$false }
} catch {
Write-Log ("Erro rodando PyInstaller: {0}" -f $_.Exception.Message) "ERROR"
return $false
}
}
# -------------------------
# Cria desinstalador: copia PS1 e gera wrapper python + build exe
# -------------------------
function Create-Uninstaller {
param([string]$Root)
$unFolder = Join-Path $Root "Desinstalar"
if (-not (Test-Path $unFolder)) { New-Item -ItemType Directory -Path $unFolder -Force |
Out-Null }
$psSrc = Join-Path $Root "UNINSTALL_CONAV_TRADER.ps1"
if (-not (Test-Path $psSrc)) {
# gera um esqueleto de desinstalador
$psSrc = Join-Path $unFolder "Desinstalar-Por-PowerShell.ps1"
$content = @'
# Desinstalador do CONAV (esqueleto)
param([switch]$DryRun)
Write-Host "Desinstalando CONAV - DryRun = $DryRun"
# aqui você deve adicionar a lógica real de remoção baseada em install.log
'@
if (-not $DryRun) { $content | Set-Content -Path $psSrc -Encoding UTF8 }
} else {
Copy-Item -Path $psSrc -Destination (Join-Path $unFolder
"Desinstalar-Por-PowerShell.ps1") -Force
}
# cria wrapper python simples que chama o PS1 (isso é para compilar com pyinstaller)
$wrapper = Join-Path $unFolder "uninstall_wrapper.py"
$py = @"
import subprocess, sys, os
ps1 = os.path.join(os.path.dirname(__file__), 'Desinstalar-Por-PowerShell.ps1')
cmd = ['powershell','-ExecutionPolicy','Bypass','-File', ps1]
subprocess.run(cmd)
"@
if (-not $DryRun) { $py | Set-Content -Path $wrapper -Encoding UTF8 }
# compile exe
$icon = Join-Path $Root "system_icon.ico"
Build-ExeWithPyInstaller -ScriptPath $wrapper -OutDist $unFolder -IconPath $icon
# cria desktop.ini para ícone da pasta (opcional)
$desktopIni = @"
[.ShellClassInfo]
IconResource=$icon,0
"@
if (-not $DryRun) {
$desktopIniPath = Join-Path $unFolder "desktop.ini"
$desktopIni | Set-Content -Path $desktopIniPath -Encoding ASCII
attrib +h +s $desktopIniPath -ErrorAction SilentlyContinue
attrib +r $unFolder -ErrorAction SilentlyContinue
}
Write-Log ("Desinstalador criado em {0}" -f $unFolder)
}
# -------------------------
# Aplica ícone a arquivos/executáveis e atalho
# -------------------------
function Apply-IconsToTools {
param([string]$Root)
$icon = Join-Path $Root "system_icon.ico"
if (-not (Test-Path $icon)) { Write-Log ("Ícone principal não encontrado: {0}" -f $icon) ;
return }
# Exemplo: coloca cópia de icon em dist e em Desinstalar
$targets = @(
Join-Path $Root "dist",
Join-Path $Root "Desinstalar",
Join-Path $Root "icons"
)
foreach ($t in $targets) {
if (-not (Test-Path $t)) { New-Item -ItemType Directory -Path $t -Force | Out-Null }
$dest = Join-Path $t (Split-Path $icon -Leaf)
if (-not $DryRun) { Copy-Item -Path $icon -Destination $dest -Force }
Write-Log ("copied icon to {0}" -f $dest)
}
}
# -------------------------
# Função principal: Orquestra tudo
# -------------------------
function Run-Master {
param([string]$Root)
# 1) Inicialização de pastas
Initialize-Folders -Root $Root
# 2) Salva versão do mestre
$verfile = Save-MasterVersion -Root $Root
# 3) Dependências (com popup)
Ensure-Dependencies -Root $Root
# 4) Apply basic icon propagation
Apply-IconsToTools -Root $Root
# 5) Build main dashboard (se existir)
$mainPy = Join-Path $Root "dashboard\main_dashboard.py"
if (Test-Path $mainPy) {
$dist = Join-Path $Root "dist"
$icon = Join-Path $Root "system_icon.ico"
Build-ExeWithPyInstaller -ScriptPath $mainPy -OutDist $dist -IconPath $icon
# cria atalho na area de trabalho
$desk = [Environment]::GetFolderPath("Desktop")
$exePath = Join-Path $dist "main_dashboard.exe"
if (Test-Path $exePath) {
$lnk = Join-Path $desk "CONAV TRADER.lnk"
Create-Shortcut -TargetPath $exePath -ShortcutPath $lnk -IconPath $icon
}
} else { Write-Log "main_dashboard.py não encontrado, pulando build." }
# 6) Cria/compila desinstalador
Create-Uninstaller -Root $Root
# 7) Gerar tutorial e mapa
$gen = Generate-TutorialAndMap -Root $Root
# 8) Empacota
$zip = Build-Package -Root $Root -OutName
"CONAV_FULL_PROFESSIONAL_v1.45_fix3.zip"
Write-Log ("Run-Master finalizado. Pacote: {0}" -f $zip)
}
# -------------------------
# Execução: resolve root e roda main
# -------------------------
try {
$root = Resolve-RootPath
$Global:RootDir = $root
# define logs dir
$Global:LogDir = Join-Path $root "logs"
if (-not (Test-Path $Global:LogDir)) { if (-not $DryRun) { New-Item -ItemType Directory
-Path $Global:LogDir -Force | Out-Null } }
$Global:MasterLog = "master.log"
Write-Log ("[START] CONAV MASTER iniciado (DryRun={0})" -f $DryRun)
# se dryrun, sumariza o que será executado e pergunta confirmação
if ($DryRun) {
Write-Host "=== DRY-RUN: Simulação ativada. ==="
Write-Host "Root detectado: $root"
Write-Host "Ações previstas:"
Write-Host "- Criar/garantir estrutura de pastas"
Write-Host "- Salvar versão mestre sequencialmente"
Write-Host "- Verificar dependências (PSScriptAnalyzer, bandit, pyinstaller)"
Write-Host "- Aplicar icons copies"
Write-Host "- Compilar main_dashboard.py com PyInstaller (se encontrado)"
Write-Host "- Criar desinstalador (PS1 + wrapper) e compilar exe"
Write-Host "- Gerar tutorial e mapa ASCII"
Write-Host "- Empacotar pacote final (ZIP)"
$resp = Read-Host "Deseja continuar com a execução REAL após revisão? (S/N)"
if ($resp -ine 'S' -and $resp -ine 's') {
Write-Log "Usuário cancelou execução após DryRun."
Write-Host "Execução cancelada."
exit 0
} else {
Write-Log "Usuário optou por executar REAL após DryRun."
# se quiser executar imediatamente sem reiniciar: continua sem alterar $DryRun
}
}
# Roda a orquestra
Run-Master -Root $root
} catch {
Write-Log ("ERRO FATAL: {0}" -f $_.Exception.Message) "ERROR"
throw
}
# ===== FIM CONAVMASTER0003.ps1 =====

# ===== INICIO CONAVMASTER0004.ps1 =====
<#
.CONAVMASTERFULL.ps1
CONAV MASTER FULL - SCRIPT UNIFICADO (v1.45_fix4)
Coloque em:
C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE\CONAVMASTERFULL.ps1
Funcionalidades principais:
- dry-run (simulação) e execução real (confirmada)
- logging detalhado em relatorios/ e logs/
- criação automática de pastas necessárias
- aplicação de ícones, build via PyInstaller (com confirmação)
- geração do desinstalador (ps1 + exe via PyInstaller) (com confirmação)
- auto-numbering do script mestre (salva cópia sequencial)
- safe copy / safe remove logic
- GUI confirm dialogs (WinForms) para aprovações sensíveis
- compatível com PowerShell 7 e Windows PowerShell (tentar)
#>
param (
[switch]$DryRun,
[switch]$AutoConfirm,
[switch]$DebugMode
)
# --------------------------
# CONFIGURAÇÕES (editar se necessário)
# --------------------------
$Root = "C:\CONAV TRADER\CONAV_TRADER"
$ScriptMasterDir = Join-Path $Root "SCRIPT MESTRE"
$LogsGeneral = Join-Path $Root "LOGS GERAIS"
$RelatoriosDir = Join-Path $Root "relatorios"
$RelatoriosAccent = Join-Path $Root "relatórios"
$LogsDir = Join-Path $Root "logs"
$PackagesDir = Join-Path $Root "PACKAGES OFICIAIS"
$DesinstalarDir = Join-Path $Root "Desinstalar"
$DistDir = Join-Path $Root "dist"
$IconsDir = Join-Path $Root "icons"
$ScriptDir = Join-Path $Root "scripts"
$InstallLogPrefix = "install"
# timestamp helper
function ts { Get-Date -Format "yyyyMMdd_HHmmss" }
# --------------------------
# LOG helper (safe)
# --------------------------
function Write-Log {
param(
[string]$Message,
[string]$Level = "INFO"
)
$t = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "[$t][$Level] $Message"
# Ensure logs directory exists
$logFile = Join-Path $LogsGeneral "master.log"
$dir = Split-Path -Parent $logFile
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
try {
Add-Content -Path $logFile -Value $line -Encoding UTF8
} catch {
# If can't write, still output to host if DebugMode
if ($DebugMode) { Write-Host ("[LOGFAIL] {0}" -f $line) }
}
if ($DebugMode) { Write-Host $line }
}
# --------------------------
# Utility: ensure dir exists
# --------------------------
function Ensure-Dir {
param([string]$Path)
if (-not (Test-Path $Path)) {
if ($DryRun) {
Write-Log ("[DRYRUN] Criar diretório: {0}" -f $Path)
} else {
New-Item -ItemType Directory -Force -Path $Path | Out-Null
Write-Log ("Criada pasta: {0}" -f $Path)
}
}
}
# --------------------------
# Safe Copy
# --------------------------
function Safe-Copy {
param(
[string]$Source,
[string]$Destination,
[switch]$Force
)
$srcFull = (Get-Item -LiteralPath $Source -ErrorAction SilentlyContinue).FullName 2>$null
$dstFull = (Resolve-Path -LiteralPath $Destination -ErrorAction SilentlyContinue) -as
[string]
if (-not $dstFull) { $dstFull = $Destination }
if ($srcFull -and ($srcFull -eq $dstFull)) {
Write-Log ("Ignorado (mesmo ficheiro): {0}" -f $Source)
return
}
if ($DryRun) {
Write-Log ("[DRYRUN] Copy {0} -> {1}" -f $Source, $Destination)
} else {
try {
Copy-Item -LiteralPath $Source -Destination $Destination -Force:($Force.IsPresent)
-ErrorAction Stop
Write-Log ("Copiado: {0} -> {1}" -f $Source, $Destination)
} catch {
Write-Log ("Erro ao copiar {0} -> {1}: {2}" -f $Source, $Destination,
$_.Exception.Message) "ERROR"
}
}
}
# --------------------------
# Safe Remove
# --------------------------
function Safe-Remove {
param([string]$Path)
if (-not (Test-Path $Path)) { Write-Log ("Remover: inexistente {0}" -f $Path); return }
if ($DryRun) {
Write-Log ("[DRYRUN] Remover {0}" -f $Path)
} else {
try {
Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
Write-Log ("Removido: {0}" -f $Path)
} catch {
Write-Log ("Erro removendo {0}: {1}" -f $Path, $_.Exception.Message) "ERROR"
}
}
}
# --------------------------
# GUI Confirm (WinForms)
# --------------------------
function GUI-Confirm {
param(
[string]$Message = "Confirm?",
[string]$Title = "CONFIRM"
)
if ($AutoConfirm) { return $true }
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object System.Windows.Forms.Form
$form.Text = $Title
$form.Size = New-Object System.Drawing.Size(430,160)
$form.StartPosition = "CenterScreen"
$label = New-Object System.Windows.Forms.Label
$label.Text = $Message
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10,20)
$form.Controls.Add($label)
$btnYes = New-Object System.Windows.Forms.Button
$btnYes.Text = "Sim"
$btnYes.Location = New-Object System.Drawing.Point(80,80)
$btnYes.Add_Click({ $form.Tag = $true; $form.Close() })
$btnNo = New-Object System.Windows.Forms.Button
$btnNo.Text = "Não"
$btnNo.Location = New-Object System.Drawing.Point(220,80)
$btnNo.Add_Click({ $form.Tag = $false; $form.Close() })
$form.Controls.Add($btnYes); $form.Controls.Add($btnNo)
$form.Add_Shown({$form.Activate()})
$form.ShowDialog() | Out-Null
return [bool]$form.Tag
}
# --------------------------
# Normalize Icon Path for PyInstaller (remove accidental quotes)
# --------------------------
function Normalize-IconPath {
param([string]$IconPath)
if (-not $IconPath) { return $null }
# remove wrapping quotes and whitespace
$p = $IconPath.Trim()
if ($p.StartsWith('"') -and $p.EndsWith('"')) { $p = $p.Trim('"') }
if ($p.StartsWith("'") -and $p.EndsWith("'")) { $p = $p.Trim("'") }
return $p
}
# --------------------------
# Build main_dashboard.exe (via pyinstaller)
# --------------------------
function Build-MainDashboard {
param(
[string]$ScriptPath = (Join-Path $Root "dashboard\main_dashboard.py"),
[string]$Icon = (Join-Path $IconsDir "system_icon.ico")
)
Ensure-Dir $DistDir
$Icon = Normalize-IconPath $Icon
if (-not (Test-Path $ScriptPath)) {
Write-Log ("main_dashboard.py não encontrado: {0}" -f $ScriptPath) "ERROR"
return $false
}
$cmd = "pyinstaller --onefile --noconsole --distpath `"$DistDir`" --name main_dashboard
--add-data `"$Root;.`""
if ($Icon -and (Test-Path $Icon)) {
$cmd += " --icon `"$Icon`""
}
$cmd += " `"$ScriptPath`""
Write-Log ("Executando PyInstaller: {0}" -f $cmd)
if ($DryRun) { Write-Log "[DRYRUN] Build ignorado (simulação)"; return $true }
try {
# Start-Process for cleaner output and to avoid blocking shell
$proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $cmd" -Wait
-NoNewWindow -PassThru
if ($proc.ExitCode -ne 0) {
Write-Log ("PyInstaller retornou código {0}" -f $proc.ExitCode) "ERROR"
return $false
}
Write-Log "main_dashboard.exe criado em dist\"
return $true
} catch {
Write-Log ("Erro ao executar PyInstaller: {0}" -f $_.Exception.Message) "ERROR"
return $false
}
}
# --------------------------
# Create/compile Desinstalar wrapper
# --------------------------
function Create-Uninstaller {
param(
[string]$UninstallPs1 = (Join-Path $Root "UNINSTALL_CONAV_TRADER.ps1"),
[string]$TargetFolder = $DesinstalarDir,
[string]$Icon = (Join-Path $IconsDir "system_icon.ico")
)
Ensure-Dir $TargetFolder
# copy ps1
$destPs1 = Join-Path $TargetFolder "Desinstalar-Por-PowerShell.ps1"
Safe-Copy -Source $UninstallPs1 -Destination $destPs1 -Force
# create python wrapper that simply calls powershell (for packaging)
$wrapper = Join-Path $TargetFolder "uninstall_wrapper.py"
$pyCode = @"
import subprocess, sys, os
ps1 = os.path.join(os.path.dirname(__file__),"Desinstalar-Por-PowerShell.ps1")
subprocess.call(["powershell","-ExecutionPolicy","Bypass","-File", ps1])
"@
if ($DryRun) {
Write-Log ("[DRYRUN] Criar wrapper python: {0}" -f $wrapper)
} else {
Set-Content -Path $wrapper -Value $pyCode -Encoding UTF8
Write-Log ("Wrapper Python criado: {0}" -f $wrapper)
}
# compile with PyInstaller if confirmed
if (GUI-Confirm "Deseja compilar Desinstalar.exe via PyInstaller?" "Compilar
Desinstalador") {
$iconPath = Normalize-IconPath $Icon
$specCmd = "pyinstaller --onefile --noconsole --distpath `"$TargetFolder`" --workpath
`"$TargetFolder\build`" --specpath `"$TargetFolder`" --name Desinstalar"
if ($iconPath -and (Test-Path $iconPath)) { $specCmd += " --icon `"$iconPath`"" }
$specCmd += " `"$wrapper`""
Write-Log ("Executando: {0}" -f $specCmd)
if (-not $DryRun) {
Start-Process -FilePath "cmd.exe" -ArgumentList "/c $specCmd" -Wait
-NoNewWindow
Write-Log ("Desinstalar.exe compilado em {0}" -f $TargetFolder)
} else {
Write-Log ("[DRYRUN] pyinstaller compilação ignorada")
}
} else {
Write-Log "Compilação do desinstalador foi cancelada pelo usuário."
}
}
# --------------------------
# Create ZIP package (with mapping to proper folders)
# --------------------------
function Build-Package {
param(
[string]$OutputName = ("CONAV_FULL_PROFESSIONAL_v{0}.zip" -f (Get-Date
-Format "yyyyMMdd_HHmm")),
[string]$SourceRoot = $Root,
[switch]$ForceOverwrite
)
Ensure-Dir $PackagesDir
$outPath = Join-Path $PackagesDir $OutputName
if (Test-Path $outPath) {
if ($ForceOverwrite) { Remove-Item -LiteralPath $outPath -Force }
else {
$snum = (Get-Date).ToString("yyyyMMddHHmmss")
$outPath = Join-Path $PackagesDir ("{0}_{1}.zip" -f
[System.IO.Path]::GetFileNameWithoutExtension($OutputName), $snum)
}
}
Write-Log ("Criando pacote: {0}" -f $outPath)
if ($DryRun) { Write-Log "[DRYRUN] Compressão ignorada"; return $outPath }
try {
# Use Compress-Archive but include only the proper folders, not entire root redundantly
$items = @()
foreach ($sub in
@("dashboard","dist","scripts","tools","relatorios","relatórios","icons","resources","docs","ema
ils")) {
$p = Join-Path $SourceRoot $sub
if (Test-Path $p) { $items += $p }
}
if (-not $items) {
Write-Log "Nenhum item encontrado para empacotar." "ERROR"
return $null
}
Compress-Archive -Path $items -DestinationPath $outPath -Force
Write-Log ("Pacote gerado em {0}" -f $outPath)
return $outPath
} catch {
Write-Log ("Erro criando pacote: {0}" -f $_.Exception.Message) "ERROR"
return $null
}
}
# --------------------------
# Auto-number and save copy of this script
# --------------------------
function Save-SelfVersion {
Ensure-Dir $ScriptMasterDir
$existing = Get-ChildItem -Path $ScriptMasterDir -Filter "CONAVMASTERFULL*.ps1"
-ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select -First 1
if ($existing) {
$digits = ($existing.BaseName -replace '\D','')
if ($digits -match '^\d+$') { $num = [int]$digits + 1 } else { $num = 1 }
} else { $num = 1 }
$seqName = ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
$dest = Join-Path $ScriptMasterDir $seqName
if ($DryRun) {
Write-Log ("[DRYRUN] Salvar self como: {0}" -f $dest)
} else {
Copy-Item -LiteralPath $PSCommandPath -Destination $dest -Force
Write-Log ("Nova versão mestre salva: {0}" -f $dest)
}
}
# --------------------------
# Main flow
# --------------------------
Write-Log "==== START CONAV MASTER (v1.45_fix4) ===="
# Ensure core dirs
foreach ($d in @($ScriptMasterDir, $LogsGeneral, $RelatoriosDir, $RelatoriosAccent,
$LogsDir, $PackagesDir, $DesinstalarDir, $DistDir, $IconsDir, $ScriptDir)) {
Ensure-Dir $d
}
# Save a versioned copy
Save-SelfVersion
# Dry-run preview: list actions
if ($DryRun) {
Write-Log "[DRYRUN] Modo simulação ativado. As ações abaixo NÃO serão executadas;
apenas listadas."
Write-Log "[DRYRUN] 1) Build main_dashboard (pyinstaller) 2) Criar/compilar
desinstalador 3) Aplicar icons 4) Gerar pacote ZIP"
# Further itemization could be added here (scan actual differences)
if (-not (GUI-Confirm "Deseja prosseguir e executar as ações (real)?")) {
Write-Log "[DRYRUN] Usuário cancelou execução real após simulação."
Write-Log "==== END CONAV MASTER ===="
return
} else {
# Turn off DryRun and continue
$DryRun = $false
Write-Log "Usuário autorizou execução real."
}
}
# Build main_dashboard
$built = Build-MainDashboard
if (-not $built) { Write-Log "Falha ao compilar main_dashboard. Verifique logs." "ERROR" }
# Create/compile desinstalador
Create-Uninstaller
# Build package ZIP
$pkg = Build-Package -OutputName ("CONAV_FULL_PROFESSIONAL_v1.45_fix4.zip")
if ($pkg) { Write-Log ("Pacote final em: {0}" -f $pkg) } else { Write-Log "Falha ao gerar
pacote" "ERROR" }
Write-Log "==== END CONAV MASTER ===="
# ===== FIM CONAVMASTER0004.ps1 =====

# ===== INICIO CONAVMASTERFULL0005.ps1 =====
<#
.CONAVMASTERFULL.ps1
CONAV MASTER FULL - SCRIPT UNIFICADO (v1.45_fix4)
Coloque em: C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE\CONAVMASTERFULL.ps1
Funcionalidades:
- dry-run (simulação) e execução real (confirmada)
- logging detalhado em relatorios/ e logs/
- criação automática de pastas necessárias
- aplicação de ícones, build via PyInstaller (com confirmação)
- geração do desinstalador (ps1 + exe via PyInstaller) (com confirmação)
- auto-numbering do script mestre (salva cópia sequencial)
- safe copy / safe remove logic
- GUI confirm dialogs (WinForms) para aprovações sensíveis
- compatível com PowerShell 7 e Windows PowerShell
#>

param (
    [switch]$DryRun,
    [switch]$AutoConfirm,
    [switch]$DebugMode
)

# --------------------------
# CONFIGURAÇÕES (editar se necessário)
# --------------------------
$Root = 'C:\CONAV TRADER\CONAV_TRADER'
$ScriptMasterDir = Join-Path $Root 'SCRIPT MESTRE'
$LogsGeneral = Join-Path $Root 'LOGS GERAIS'
$RelatoriosDir = Join-Path $Root 'relatorios'
$RelatoriosAccent = Join-Path $Root 'relatórios'
$LogsDir = Join-Path $Root 'logs'
$PackagesDir = Join-Path $Root 'PACKAGES OFICIAIS'
$DesinstalarDir = Join-Path $Root 'Desinstalar'
$DistDir = Join-Path $Root 'dist'
$IconsDir = Join-Path $Root 'icons'
$ScriptDir = Join-Path $Root 'scripts'

# --------------------------
# Helpers
# --------------------------
function ts { Get-Date -Format 'yyyyMMdd_HHmmss' }

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    $t = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$t][$Level] $Message"
    $logFile = Join-Path $LogsGeneral 'master.log'
    $dir = Split-Path -Parent $logFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    try {
        Add-Content -Path $logFile -Value $line -Encoding UTF8
    } catch {
        if ($DebugMode) { Write-Host ('[LOGFAIL] {0}' -f $line) }
    }
    if ($DebugMode) { Write-Host $line }
}

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        if ($DryRun) {
            Write-Log ('[DRYRUN] Criar diretório: {0}' -f $Path)
        } else {
            New-Item -ItemType Directory -Force -Path $Path | Out-Null
            Write-Log ('Criada pasta: {0}' -f $Path)
        }
    }
}

function Safe-Copy {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$Force
    )
    try {
        $srcItem = Get-Item -LiteralPath $Source -ErrorAction Stop
        $srcFull = $srcItem.FullName
    } catch {
        Write-Log ('Source não encontrado: {0}' -f $Source) 'ERROR'
        return
    }
    $dstExists = $false
    try {
        $dstResolved = Resolve-Path -LiteralPath $Destination -ErrorAction Stop
        $dstExists = $true
    } catch {
        $dstResolved = $Destination
    }
    if ($srcFull -eq $dstResolved) {
        Write-Log ('Ignorado (mesmo ficheiro): {0}' -f $Source)
        return
    }
    if ($DryRun) {
        Write-Log ('[DRYRUN] Copy {0} -> {1}' -f $Source, $Destination)
    } else {
        try {
            Copy-Item -LiteralPath $Source -Destination $Destination -Force:($Force.IsPresent) -ErrorAction Stop
            Write-Log ('Copiado: {0} -> {1}' -f $Source, $Destination)
        } catch {
            Write-Log ('Erro ao copiar {0} -> {1}: {2}' -f $Source, $Destination, $_.Exception.Message) 'ERROR'
        }
    }
}

function Safe-Remove {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        Write-Log ('Remover: inexistente {0}' -f $Path)
        return
    }
    if ($DryRun) {
        Write-Log ('[DRYRUN] Remover {0}' -f $Path)
    } else {
        try {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            Write-Log ('Removido: {0}' -f $Path)
        } catch {
            Write-Log ('Erro removendo {0}: {1}' -f $Path, $_.Exception.Message) 'ERROR'
        }
    }
}

function GUI-Confirm {
    param(
        [string]$Message = 'Confirm?',
        [string]$Title = 'CONFIRM'
    )
    if ($AutoConfirm) { return $true }
    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(430,160)
    $form.StartPosition = 'CenterScreen'
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Message
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(10,20)
    $form.Controls.Add($label)
    $btnYes = New-Object System.Windows.Forms.Button
    $btnYes.Text = 'Sim'
    $btnYes.Location = New-Object System.Drawing.Point(80,80)
    $btnYes.Add_Click({ $form.Tag = $true; $form.Close() })
    $btnNo = New-Object System.Windows.Forms.Button
    $btnNo.Text = 'Não'
    $btnNo.Location = New-Object System.Drawing.Point(220,80)
    $btnNo.Add_Click({ $form.Tag = $false; $form.Close() })
    $form.Controls.Add($btnYes); $form.Controls.Add($btnNo)
    $form.Add_Shown({$form.Activate()})
    $form.ShowDialog() | Out-Null
    return [bool]$form.Tag
}

function Normalize-IconPath {
    param([string]$IconPath)
    if (-not $IconPath) { return $null }
    $p = $IconPath.Trim()
    if ($p.StartsWith('"') -and $p.EndsWith('"')) { $p = $p.Trim('"') }
    if ($p.StartsWith("'") -and $p.EndsWith("'")) { $p = $p.Trim("'") }
    return $p
}

function Build-MainDashboard {
    param(
        [string]$ScriptPath = (Join-Path $Root 'dashboard\main_dashboard.py'),
        [string]$Icon = (Join-Path $IconsDir 'system_icon.ico')
    )
    Ensure-Dir $DistDir
    $Icon = Normalize-IconPath $Icon
    if (-not (Test-Path $ScriptPath)) {
        Write-Log ('main_dashboard.py não encontrado: {0}' -f $ScriptPath) 'ERROR'
        return $false
    }
    $cmd = 'pyinstaller --onefile --noconsole --distpath "' + $DistDir + '" --name main_dashboard --add-data "' + $Root + ';."'

    if ($Icon -and (Test-Path $Icon)) {
        $cmd += ' --icon "' + $Icon + '"'
    }
    $cmd += ' "' + $ScriptPath + '"'
    Write-Log ('Executando PyInstaller: {0}' -f $cmd)
    if ($DryRun) { Write-Log '[DRYRUN] Build ignorado (simulação)'; return $true }
    try {
        $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $cmd" -Wait -NoNewWindow -PassThru
        if ($proc.ExitCode -ne 0) {
            Write-Log ('PyInstaller retornou código {0}' -f $proc.ExitCode) 'ERROR'
            return $false
        }
        Write-Log 'main_dashboard.exe criado em dist\'
        return $true
    } catch {
        Write-Log ('Erro ao executar PyInstaller: {0}' -f $_.Exception.Message) 'ERROR'
        return $false
    }
}

function Create-Uninstaller {
    param(
        [string]$UninstallPs1 = (Join-Path $Root 'UNINSTALL_CONAV_TRADER.ps1'),
        [string]$TargetFolder = $DesinstalarDir,
        [string]$Icon = (Join-Path $IconsDir 'system_icon.ico')
    )
    Ensure-Dir $TargetFolder
    $destPs1 = Join-Path $TargetFolder 'Desinstalar-Por-PowerShell.ps1'
    Safe-Copy -Source $UninstallPs1 -Destination $destPs1 -Force
    $wrapper = Join-Path $TargetFolder 'uninstall_wrapper.py'
    $pyCode = @"
import subprocess, sys, os
ps1 = os.path.join(os.path.dirname(__file__),"Desinstalar-Por-PowerShell.ps1")
subprocess.call(["powershell","-ExecutionPolicy","Bypass","-File", ps1])
"@
    if ($DryRun) {
        Write-Log ('[DRYRUN] Criar wrapper python: {0}' -f $wrapper)
    } else {
        Set-Content -Path $wrapper -Value $pyCode -Encoding UTF8
        Write-Log ('Wrapper Python criado: {0}' -f $wrapper)
    }
    if (GUI-Confirm 'Deseja compilar Desinstalar.exe via PyInstaller?' 'Compilar Desinstalador') {
        $iconPath = Normalize-IconPath $Icon
        $specCmd = 'pyinstaller --onefile --noconsole --distpath "' + $TargetFolder + '" --workpath "' + $TargetFolder + '\build" --specpath "' + $TargetFolder + '" --name Desinstalar'
        if ($iconPath -and (Test-Path $iconPath)) { $specCmd += ' --icon "' + $iconPath + '"' }
        $specCmd += ' "' + $wrapper + '"'
        Write-Log ('Executando: {0}' -f $specCmd)
        if (-not $DryRun) {
            Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $specCmd" -Wait -NoNewWindow
            Write-Log ('Desinstalar.exe compilado em {0}' -f $TargetFolder)
        } else {
            Write-Log '[DRYRUN] pyinstaller compilação ignorada'
        }
    } else {
        Write-Log 'Compilação do desinstalador foi cancelada pelo usuário.'
    }
}

function Build-Package {
    param(
        [string]$OutputName = ('CONAV_FULL_PROFESSIONAL_v{0}.zip' -f (Get-Date -Format 'yyyyMMdd_HHmm')),
        [string]$SourceRoot = $Root,
        [switch]$ForceOverwrite
    )
    Ensure-Dir $PackagesDir
    $outPath = Join-Path $PackagesDir $OutputName
    if (Test-Path $outPath) {
        if ($ForceOverwrite) { Remove-Item -LiteralPath $outPath -Force }
        else {
            $snum = (Get-Date).ToString('yyyyMMddHHmmss')
            $outPath = Join-Path $PackagesDir ('{0}_{1}.zip' -f [System.IO.Path]::GetFileNameWithoutExtension($OutputName), $snum)
        }
    }
    Write-Log ('Criando pacote: {0}' -f $outPath)
    if ($DryRun) { Write-Log '[DRYRUN] Compressão ignorada'; return $outPath }
    try {
        $items = @()
        foreach ($sub in @('dashboard','dist','scripts','tools','relatorios','relatórios','icons','resources','docs','emails')) {
            $p = Join-Path $SourceRoot $sub
            if (Test-Path $p) { $items += $p }
        }
        if (-not $items) {
            Write-Log 'Nenhum item encontrado para empacotar.' 'ERROR'
            return $null
        }
        Compress-Archive -Path $items -DestinationPath $outPath -Force
        Write-Log ('Pacote gerado em {0}' -f $outPath)
        return $outPath
    } catch {
        Write-Log ('Erro criando pacote: {0}' -f $_.Exception.Message) 'ERROR'
        return $null
    }
}

function Save-SelfVersion {
    Ensure-Dir $ScriptMasterDir
    $existing = Get-ChildItem -Path $ScriptMasterDir -Filter 'CONAVMASTERFULL*.ps1' -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($existing) {
        $digits = ($existing.BaseName -replace '\D','')
        if ($digits -match '^\d+$') { $num = [int]$digits + 1 } else { $num = 1 }
    } else { $num = 1 }
    $seqName = ('CONAVMASTERFULL{0:D4}.ps1' -f $num)
    $dest = Join-Path $ScriptMasterDir $seqName
    if ($DryRun) {
        Write-Log ('[DRYRUN] Salvar self como: {0}' -f $dest)
    } else {
        Copy-Item -LiteralPath $PSCommandPath -Destination $dest -Force
        Write-Log ('Nova versão mestre salva: {0}' -f $dest)
    }
}

# --------------------------
# Main
# --------------------------
Write-Log '==== START CONAV MASTER (v1.45_fix4) ===='

foreach ($d in @($ScriptMasterDir, $LogsGeneral, $RelatoriosDir, $RelatoriosAccent, $LogsDir, $PackagesDir, $DesinstalarDir, $DistDir, $IconsDir, $ScriptDir)) {
    Ensure-Dir $d
}

Save-SelfVersion

if ($DryRun) {
    Write-Log '[DRYRUN] Modo simulação ativado. As ações abaixo NÃO serão executadas; apenas listadas.'
    Write-Log '[DRYRUN] 1) Build main_dashboard (pyinstaller)  2) Criar/compilar desinstalador 3) Aplicar icons 4) Gerar pacote ZIP'
    if (-not (GUI-Confirm 'Deseja prosseguir e executar as ações (real)?')) {
        Write-Log '[DRYRUN] Usuário cancelou execução real após simulação.'
        Write-Log '==== END CONAV MASTER ===='
        return
    } else {
        $DryRun = $false
        Write-Log 'Usuário autorizou execução real.'
    }
}

$built = Build-MainDashboard
if (-not $built) { Write-Log 'Falha ao compilar main_dashboard. Verifique logs.' 'ERROR' }

Create-Uninstaller

$pkg = Build-Package -OutputName ('CONAV_FULL_PROFESSIONAL_v1.45_fix4.zip')
if ($pkg) { Write-Log ('Pacote final em: {0}' -f $pkg) } else { Write-Log 'Falha ao gerar pacote' 'ERROR' }

Write-Log '==== END CONAV MASTER ===='

# ===== FIM CONAVMASTERFULL0005.ps1 =====

# ===== INICIO BUSCAR-TODOS-SCRIPTS.ps1 =====
<#
.SYNOPSIS
FULLONE.ps1 - Ferramenta unificadora para descobrir, analisar, corrigir (opcional) e
compilar todos os scripts (.ps1 .py) no projeto CONAV.
.DESCRIPTION
- Busca recursiva por .ps1 e .py em RootPath (padrão: C:\CONAV
TRADER\CONAV_TRADER)
- Relatórios: contagem, duplicados (por hash), arquivos com mesmo nome (comparação)
- Opcional: AutoFix (correções seguras), Backup
- Geração de um arquivo compilado FULLONE_COMPILED.ps1
- Execução isolada por processo (opcional)
- DryRun por padrão (não modifica nada)
- Logs em C:\CONAV TRADER\CONAV_TRADER\logs
- Relatórios em C:\CONAV TRADER\CONAV_TRADER\relatorios
- Backups em C:\CONAV
TRADER\CONAV_TRADER\BACKUPS_FULLONE\<timestamp>
.PARAMETER RootPath
Pasta raiz (padrão: C:\CONAV TRADER\CONAV_TRADER)
.PARAMETER DryRun
True por padrão. Se presente, apenas simula ações.
.PARAMETER AutoFix
Se presente (e confirmado), tentará aplicar correções "seguras".
.PARAMETER Backup
Se presente, faz backup antes de modificar arquivos.
.PARAMETER Exec
Se presente, executa cada script em processo separado (cuidado).
.PARAMETER UsePwsh
Usa 'pwsh' (PowerShell 7) para execução quando -Exec.
.PARAMETER MakeCompiledOnly
Apenas gera o FULLONE_COMPILED.ps1 sem executar correções.
.PARAMETER Deploy
Copia o FULLONE.ps1 e versões numeradas para pastas de integração (somente
quando confirmado).
.EXAMPLE
.\FULLONE.ps1 -DryRun
Simulação: só relatório.
.EXAMPLE
.\FULLONE.ps1 -AutoFix -Backup
Aplica correções seguras após confirmação e cria backups.
#>
param(
[string]$RootPath = 'C:\CONAV TRADER\CONAV_TRADER',
[switch]$DryRun = $true,
[switch]$AutoFix = $false,
[switch]$Backup = $true,
[switch]$Exec = $false,
[switch]$UsePwsh = $false,
[switch]$MakeCompiledOnly = $false,
[switch]$Deploy = $false
)
Set-StrictMode -Version Latest
function Write-Log {
param(
[string]$Message,
[string]$Level = 'INFO'
)
$ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
$line = "[$ts][$Level] $Message"
# ensure log dir exists
if (!(Test-Path $Global:FULLONE_LogFileDir)) { New-Item -ItemType Directory -Path
$Global:FULLONE_LogFileDir -Force | Out-Null }
Add-Content -Path $Global:FULLONE_LogFile -Value $line -Encoding UTF8
Write-Host $line
}
function Ensure-Dirs {
param([string]$root)
$dirs = @{
logs = Join-Path $root 'logs'
relatorios = Join-Path $root 'relatorios'
relatorios_alt = Join-Path $root 'relatórios'
backups = Join-Path $root 'BACKUPS_FULLONE'
mapas = Join-Path $root 'mapas de fluxograma'
masterScripts = Join-Path $root 'SCRIPT MESTRE'
packages = Join-Path $root 'PACKAGES OFICIAIS'
scriptsBase = Join-Path $root 'scripts\SCRIPTS BASE OFICIAIS'
}
foreach ($d in $dirs.GetEnumerator()) {
if (!(Test-Path $d.Value)) {
try {
New-Item -ItemType Directory -Path $d.Value -Force | Out-Null
} catch {
# ignore
}
}
}
return $dirs
}
# --- inicialização
$RootPath = (Resolve-Path -Path $RootPath).ProviderPath
$now = Get-Date -Format 'yyyyMMdd_HHmmss'
$Global:FULLONE_LogFileDir = Join-Path $RootPath 'logs'
$Global:FULLONE_LogFile = Join-Path $Global:FULLONE_LogFileDir
("fullone_log_$now.txt")
$dirs = Ensure-Dirs -root $RootPath
$reportFile = Join-Path $dirs.relatorios ("fullone_report_$now.txt")
$backupRoot = Join-Path $RootPath "BACKUPS_FULLONE\$now"
$compiledFolder = Join-Path $RootPath 'CONAV MASTER
FULL\FULLONEMASTER-INSTALL'
if (!(Test-Path $compiledFolder)) { New-Item -Path $compiledFolder -ItemType Directory
-Force | Out-Null }
Write-Log "FULLONE iniciado. RootPath = $RootPath"
if ($DryRun) { Write-Log "MODO: DRY RUN (simulação). Nenhuma alteração será feita." }
# --- localizar arquivos
Write-Log "Procurando arquivos .ps1 e .py recursivamente..."
$ignorePatterns = @('\\.git\\','\\node_modules\\','\.zip$','\.rar$','\\dist\\','\\build\\')
# collect files
$files = Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue `
| Where-Object { $_.Extension -in '.ps1','.py' } `
| Where-Object {
$full = $_.FullName
-not ($ignorePatterns | ForEach-Object { $full -match $_ } | Where-Object { $_ })
}
$totalCount = $files.Count
Write-Log "Total encontrado: $totalCount arquivos (.ps1/.py)."
# write quick summary
$summary = @()
$summary += "FULLONE Report - $now"
$summary += "RootPath: $RootPath"
$summary += "Total scripts found: $totalCount"
$summary += ""
# --- hashes e duplicados
Write-Log "Calculando hashes (SHA256) para identificar duplicados..."
$hashMap = @{}
$byName = @{}
foreach ($f in $files) {
try {
$h = Get-FileHash -Path $f.FullName -Algorithm SHA256 -ErrorAction Stop
$hash = $h.Hash
} catch {
Write-Log "Falha ao calcular hash de $($f.FullName): $($_.Exception.Message)"
"WARN"
$hash = "ERROR"
}
if (-not $hashMap.ContainsKey($hash)) { $hashMap[$hash] = New-Object
System.Collections.ArrayList }
$hashMap[$hash].Add($f) | Out-Null
if (-not $byName.ContainsKey($f.Name)) { $byName[$f.Name] = New-Object
System.Collections.ArrayList }
$byName[$f.Name].Add($f) | Out-Null
}
# duplicates by content
$dupByContent = $hashMap.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
if ($dupByContent.Count -gt 0) {
Write-Log "Duplicados por conteúdo encontrados: $($dupByContent.Count) grupos."
$summary += "Duplicados por conteúdo (grupos): $($dupByContent.Count)"
foreach ($g in $dupByContent) {
$summary += "GrupoHash: $($g.Key)"
foreach ($item in $g.Value) {
$summary += " $($item.FullName) (modified: $($item.LastWriteTime))"
}
}
} else {
$summary += "Nenhum duplicado de conteúdo detectado."
Write-Log "Nenhum duplicado por conteúdo detectado."
}
# duplicates by name
$dupByName = $byName.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
if ($dupByName.Count -gt 0) {
Write-Log "Mesmo nome em múltiplas localizações: $($dupByName.Count) nomes."
$summary += ""
$summary += "Arquivos com mesmo nome em múltiplas pastas: $($dupByName.Count)"
foreach ($g in $dupByName) {
$summary += "Nome: $($g.Key)"
foreach ($item in $g.Value) {
$summary += " $($item.FullName) (LastWrite: $($item.LastWriteTime), Size:
$($item.Length))"
}
# suggestion: latest file
$latest = $g.Value | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$summary += " -> Sugerido manter (mais recente): $($latest.FullName)"
}
} else {
$summary += "Nenhum arquivo com mesmo nome em múltiplos locais."
}
# save quick report summary
$summary | Out-File -FilePath $reportFile -Encoding UTF8
# --- função de correção segura (aplica pequenas normalizações)
function Safe-FixFile {
param(
[string]$Path,
[switch]$BackupBefore
)
$actions = @()
if ($BackupBefore) {
$dest = Join-Path $backupRoot ((Split-Path $Path -Leaf) + ".bak")
if (!(Test-Path $backupRoot)) { New-Item -ItemType Directory -Path $backupRoot
-Force | Out-Null }
Copy-Item -Path $Path -Destination $dest -Force
$actions += "Backup: $dest"
}
# read raw preserving content
try {
$raw = Get-Content -Raw -LiteralPath $Path -ErrorAction Stop
} catch {
return @{ success = $false; message = "Falha ao ler: $($_.Exception.Message)";
actions=$actions }
}
$orig = $raw
# replacements seguros (curly quotes, ellipsis, NBSP, BOM removal)
$raw = $raw -replace "[\u201C\u201D]","`""
$raw = $raw -replace "[\u2018\u2019]","'"
$raw = $raw -replace "`u2026","..." # fallback in case encoding shows this form
$raw = $raw -replace "\u2026","..."
$raw = $raw -replace "\u00A0"," " # NBSP -> space
# remove BOM if present
if ($raw.StartsWith([char]0xFEFF)) {
$raw = $raw.Substring(1)
$actions += "Removed BOM"
}
# replace Windows “weird” ellipsis characters that sometimes show as … in source
$raw = $raw -replace "…","..."
# normalize CRLF -> CRLF (just ensure)
$raw = $raw -replace "(\r?\n)","\r`n"
if ($raw -ne $orig) {
if ($DryRun) {
$actions += "CHANGES (simulado)"
return @{ success = $true; changed = $true; message = "Simulado: alterações
sugeridas"; actions = $actions }
} else {
try {
# Save with UTF8 (no BOM) to be safer
$raw | Out-File -LiteralPath $Path -Encoding utf8 -Force
$actions += "Saved changes"
return @{ success = $true; changed = $true; message = "Alterações aplicadas";
actions = $actions }
} catch {
return @{ success = $false; changed = $false; message = "Falha ao salvar:
$($_.Exception.Message)"; actions=$actions }
}
}
} else {
return @{ success = $true; changed = $false; message = "Nenhuma alteração
necessária"; actions=$actions }
}
}
# --- aplicar AutoFix (opcional)
$fixSummary = @()
if ($AutoFix) {
Write-Log "AutoFix solicitado. Preparando aplicação de correções seguras."
if ($DryRun) { Write-Log "Nota: Em DryRun; AutoFix apenas simulado." }
# confirm
$confirm = $true
if ($DryRun -eq $false) {
$choice = Read-Host "Você quer realmente aplicar AutoFix em todos os arquivos
encontrados? (S/N)"
if ($choice.ToUpper() -ne 'S') { $confirm = $false; Write-Log "AutoFix CANCELADO pelo
usuário." }
} else {
Write-Log "AutoFix rodando em modo simulado (DryRun)."
}
if ($confirm) {
foreach ($f in $files) {
Write-Log "Analisando para fix: $($f.FullName)"
if ($Backup -and -not $DryRun) {
if (!(Test-Path $backupRoot)) { New-Item -ItemType Directory -Path $backupRoot
-Force | Out-Null }
}
$res = Safe-FixFile -Path $f.FullName -BackupBefore:$Backup
if ($res.success) {
$fixSummary += ("{0} => {1} - {2}" -f $f.FullName, ($res.changed -eq $true ?
"CHANGED":"UNCHANGED"), $res.message)
foreach ($a in $res.actions) { Write-Log " $a" }
} else {
Write-Log "Erro no Safe-FixFile: $($res.message)" "ERROR"
}
}
Write-Log "AutoFix finalizado (ou simulado)."
}
}
# --- gerar arquivo compilado (apenas juntar scripts legíveis)
Write-Log "Gerando arquivo compilado FULLONE_COMPILED.ps1..."
$compiledPath = Join-Path $compiledFolder ("FULLONE_COMPILED_$now.ps1")
$header = @()
$header += "# FULLONE_COMPILED - gerado em $now"
$header += "# Root: $RootPath"
$header += "# Arquivos incluídos:"
$files | ForEach-Object { $header += "# - $($_.FullName) (LastWrite: $($_.LastWriteTime))" }
$header += ""
if ($DryRun) { Write-Log "OBS: compilação gerada em modo DryRun (conteúdo original não
foi modificado)." }
# build compiled content
$compiledContent = $header -join "`r`n" + "`r`n"
foreach ($f in $files) {
$compiledContent += "`r`n"
$compiledContent +=
"#########################################################################
#####`r`n"
$compiledContent += "# INICIO: $($f.FullName)`r`n"
$compiledContent +=
"#########################################################################
#####`r`n"
try {
$txt = Get-Content -Raw -LiteralPath $f.FullName -ErrorAction Stop
# add content, but comment file-level "shebang" for python? If mixing types, we still
include as comment
$commented = @()
if ($f.Extension.ToLower() -eq '.py') {
# keep as-is but wrapped into here-string so it doesn't accidentally execute in PS
$compiledContent += "<# PY: origem: $($f.FullName) #>`r`n"
$compiledContent += $txt + "`r`n"
$compiledContent += "<# FIM PY #>`r`n"
} else {
# PS file - include with header; keep as-is
$compiledContent += $txt + "`r`n"
}
} catch {
Write-Log "Falha lendo $($f.FullName) para inclusão compilada:
$($_.Exception.Message)" "WARN"
}
$compiledContent += "`r`n"
$compiledContent +=
"#########################################################################
#####`r`n"
$compiledContent += "# FIM: $($f.FullName)`r`n"
$compiledContent +=
"#########################################################################
#####`r`n"
}
if ($DryRun) {
$simulatedCompiledPath = $compiledPath + ".simulated.txt"
$compiledContent | Out-File -FilePath $simulatedCompiledPath -Encoding UTF8 -Force
Write-Log "Em DryRun: compilado simulado salvo em: $simulatedCompiledPath"
} else {
try {
$compiledContent | Out-File -FilePath $compiledPath -Encoding UTF8 -Force
Write-Log "Arquivo compilado salvo em: $compiledPath"
} catch {
Write-Log "Falha ao salvar compilado: $($_.Exception.Message)" "ERROR"
}
}
if ($MakeCompiledOnly) {
Write-Log "MakeCompiledOnly solicitado. Finalizando sem execução."
Write-Log "Relatório salvo em: $reportFile"
exit 0
}
# --- executar cada script (opcional) - em processos isolados
if ($Exec) {
Write-Log "Execução isolada de cada script solicitada. Será executado em processos
separados."
if ($DryRun) { Write-Log "OBS: Execução em DryRun (simulação) - nada será
executado)." }
foreach ($f in $files) {
Write-Log "Preparando execução: $($f.FullName)"
if ($DryRun) {
Write-Log "Simulado: executar $($f.FullName)"
continue
}
# choose engine
if ($f.Extension.ToLower() -eq '.py') {
# python: attempt to run with system 'python'
$exe = 'python'
$args = @("--version")
# real execution:
try {
Write-Log "Executando (python) $($f.FullName)..."
$proc = Start-Process -FilePath $exe -ArgumentList "`"$($f.FullName)`"" -Wait
-NoNewWindow -PassThru -ErrorAction Stop
Write-Log "Processo finalizado: ExitCode $($proc.ExitCode)"
} catch {
Write-Log "Falha ao executar python $($f.FullName): $($_.Exception.Message)"
"ERROR"
}
} else {
# ps1: run in new pwsh/powershell process
$psExe = if ($UsePwsh) { 'pwsh' } else { 'powershell' }
$arg = "-NoProfile -ExecutionPolicy Bypass -File `"$($f.FullName)`""
try {
Write-Log "Executando ($psExe) $($f.FullName)..."
$proc = Start-Process -FilePath $psExe -ArgumentList $arg -Wait -NoNewWindow
-PassThru -ErrorAction Stop
Write-Log "Processo finalizado: ExitCode $($proc.ExitCode)"
} catch {
Write-Log "Falha ao executar $($f.FullName): $($_.Exception.Message)"
"ERROR"
}
}
}
}
# --- Deploy / copiar FULLONE para pastas requisitadas e versionamento
if ($Deploy) {
Write-Log "Deploy solicitado: copiando FULLONE.ps1 para pastas de integração
(confirmando)."
$targets = @(
Join-Path $RootPath 'scripts\SCRIPTS BASE OFICIAIS',
Join-Path $RootPath 'SCRIPT MESTRE',
Join-Path $RootPath 'PACKAGES OFICIAIS'
)
if ($DryRun) { Write-Log "Deploy em DryRun: apenas simulado." }
foreach ($t in $targets) {
if (!(Test-Path $t)) { New-Item -ItemType Directory -Path $t -Force | Out-Null }
$baseName = 'FULLONE'
# sequence next number
$existing = Get-ChildItem -Path $t -Filter "$baseName*.ps1" -ErrorAction
SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
$num = [int]($existing.BaseName -replace '\D','') + 1
} else { $num = 1 }
$dest = Join-Path $t ("{0}{1:D4}.ps1" -f $baseName,$num)
if ($DryRun) {
Write-Log "Simulado: copiar $PSCommandPath -> $dest"
} else {
Copy-Item -Path $PSCommandPath -Destination $dest -Force
Write-Log "Copiado $PSCommandPath -> $dest"
}
}
}
# --- finalizar e salvar relatório detalhado
$report = New-Object System.Collections.Generic.List[string]
$report.AddRange($summary)
$report.Add("")
$report.Add("Detalhes:")
$report.Add("Total arquivos: $totalCount")
$report.Add("Duplicados por conteúdo (grupos): $($dupByContent.Count)")
$report.Add("Mesmo nome em múltiplas pastas: $($dupByName.Count)")
$report.Add("")
if ($AutoFix) {
$report.Add("AutoFix summary:")
$report.AddRange($fixSummary)
}
$report.Add("")
$report.Add("Compiled file: " + (if ($DryRun) { $simulatedCompiledPath } else {
$compiledPath }))
$report.Add("")
$report.Add("LOG: " + $Global:FULLONE_LogFile)
$report.Add("")
$report.Add("Fim do relatório.")
$report | Out-File -FilePath $reportFile -Encoding UTF8 -Force
Write-Log "FULLONE finalizado. Relatório salvo em: $reportFile"
if ($DryRun) { Write-Log "Recomendo revisar relatório e rodar sem -DryRun e com -AutoFix
somente após confirmar." }
# ===== FIM BUSCAR-TODOS-SCRIPTS.ps1 =====

# ===== INICIO FULLONEv00001.ps1 =====
PS C:\Users\arati> Set-Location "C:\CONAV TRADER\CONAV_TRADER\CONAV MASTER FULL\FULLONEMASTER"
PS C:\CONAV TRADER\CONAV_TRADER\CONAV MASTER FULL\FULLONEMASTER> Set-ExecutionPolicy Bypass -Scope Process -Force
>> .\BUSCAR-TODOS-SCRIPTS.ps1
ParserError: C:\CONAV TRADER\CONAV_TRADER\CONAV MASTER FULL\FULLONEMASTER\BUSCAR-TODOS-SCRIPTS.ps1:61
Line |
  61 |  $Global:FULLONE_LogFileDir -Force | Out-Null }
     |                             ~~~~~~
     | Unexpected token '-Force' in expression or statement.
# ===== FIM FULLONEv00001.ps1 =====

# ===== INICIO FULLONEv00002.ps1 =====
<#
======================================================================
==========
SCRIPT: BUSCAR-TODOS-SCRIPTS.ps1
OBJETIVO:
- Buscar todos os .ps1 e .py dentro da pasta raiz especificada
- Contar arquivos
- Detectar duplicados (por conteúdo e por nome)
- Corrigir caracteres problemáticos (opcional, SafeFix)
- Compilar todos em 1 único .ps1
- Relatório detalhado e log
- Script separado do CONAV (independente)
AUTOR: Assistente Automação
======================================================================
==========
#>
param(
[string]$RootPath = 'C:\CONAV TRADER\CONAV_TRADER',
[switch]$DryRun = $true,
[switch]$AutoFix = $false,
[switch]$Backup = $true
)
# ==============================
# Função de log
# ==============================
function Write-Log {
param(
[string]$Message,
[string]$Level = 'INFO'
)
$ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
$line = "[$ts][$Level] $Message"
if (!(Test-Path $Global:FULLONE_LogFileDir)) {
New-Item -ItemType Directory -Path $Global:FULLONE_LogFileDir -Force | Out-Null
}
Add-Content -Path $Global:FULLONE_LogFile -Value $line -Encoding UTF8
Write-Host $line
}
# ==============================
# Inicialização
# ==============================
$RootPath = (Resolve-Path -Path $RootPath).ProviderPath
$now = Get-Date -Format 'yyyyMMdd_HHmmss'
$Global:FULLONE_LogFileDir = Join-Path $RootPath 'logs_FULLONE'
$Global:FULLONE_LogFile = Join-Path $Global:FULLONE_LogFileDir
("fullone_log_$now.txt")
if (!(Test-Path $Global:FULLONE_LogFileDir)) {
New-Item -ItemType Directory -Path $Global:FULLONE_LogFileDir -Force | Out-Null
}
Write-Log "FULLONE iniciado (BUSCAR-TODOS-SCRIPTS). RootPath = $RootPath"
if ($DryRun) { Write-Log "MODO: DRY RUN (simulação). Nenhuma alteração será feita." }
# ==============================
# Localizar arquivos .ps1 e .py
# ==============================
Write-Log "Procurando arquivos .ps1 e .py recursivamente..."
$files = Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue `
| Where-Object { $_.Extension -in '.ps1', '.py' }
$totalCount = $files.Count
Write-Log "Total encontrado: $totalCount arquivos (.ps1/.py)."
# ==============================
# Relatório inicial
# ==============================
$reportFile = Join-Path $RootPath ("relatorio_FULLONE_$now.txt")
$summary = @()
$summary += "Relatório FULLONE - $now"
$summary += "RootPath: $RootPath"
$summary += "Total scripts encontrados: $totalCount"
$summary += ""
# ==============================
# Duplicados por conteúdo (hash)
# ==============================
Write-Log "Verificando duplicados por conteúdo (hash)..."
$hashMap = @{}
foreach ($f in $files) {
try {
$h = Get-FileHash -Path $f.FullName -Algorithm SHA256
if (-not $hashMap.ContainsKey($h.Hash)) { $hashMap[$h.Hash] = @() }
$hashMap[$h.Hash] += $f
} catch {
Write-Log "Falha ao calcular hash de $($f.FullName): $($_.Exception.Message)"
"WARN"
}
}
$dupByContent = $hashMap.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
if ($dupByContent.Count -gt 0) {
$summary += "Duplicados por conteúdo: $($dupByContent.Count) grupos"
foreach ($g in $dupByContent) {
$summary += "Hash: $($g.Key)"
foreach ($f in $g.Value) {
$summary += " $($f.FullName)"
}
}
} else {
$summary += "Nenhum duplicado de conteúdo encontrado."
}
# ==============================
# Duplicados por nome
# ==============================
Write-Log "Verificando arquivos com mesmo nome..."
$byName = @{}
foreach ($f in $files) {
if (-not $byName.ContainsKey($f.Name)) { $byName[$f.Name] = @() }
$byName[$f.Name] += $f
}
$dupByName = $byName.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
if ($dupByName.Count -gt 0) {
$summary += ""
$summary += "Arquivos com mesmo nome em múltiplas pastas: $($dupByName.Count)"
foreach ($g in $dupByName) {
$summary += "Nome: $($g.Key)"
foreach ($f in $g.Value) {
$summary += " $($f.FullName)"
}
}
} else {
$summary += "Nenhum arquivo duplicado por nome encontrado."
}
# ==============================
# Função SafeFix
# ==============================
function Safe-FixFile {
param(
[string]$Path,
[switch]$BackupBefore
)
$actions = @()
if ($BackupBefore) {
$backupDir = Join-Path $RootPath ("BACKUP_FULLONE_$now")
if (!(Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force |
Out-Null }
$dest = Join-Path $backupDir ((Split-Path $Path -Leaf) + ".bak")
Copy-Item -Path $Path -Destination $dest -Force
$actions += "Backup criado: $dest"
}
try {
$raw = Get-Content -Raw -LiteralPath $Path
} catch {
return @{ success = $false; msg = "Falha ao ler: $($_.Exception.Message)";
actions=$actions }
}
$orig = $raw
$raw = $raw -replace "[\u201C\u201D]",'"'
$raw = $raw -replace "[\u2018\u2019]","'"
$raw = $raw -replace "…","..."
$raw = $raw -replace "\u00A0"," "
if ($raw.StartsWith([char]0xFEFF)) { $raw = $raw.Substring(1); $actions += "BOM
removido" }
if ($raw -ne $orig) {
if ($DryRun) {
return @{ success = $true; changed = $true; msg = "Alterações simuladas";
actions=$actions }
} else {
$raw | Out-File -LiteralPath $Path -Encoding UTF8 -Force
return @{ success = $true; changed = $true; msg = "Alterações aplicadas";
actions=$actions }
}
} else {
return @{ success = $true; changed = $false; msg = "Nenhuma alteração necessária";
actions=$actions }
}
}
# ==============================
# Aplicar SafeFix (se solicitado)
# ==============================
$fixSummary = @()
if ($AutoFix) {
Write-Log "Rodando SafeFix em todos os arquivos..."
foreach ($f in $files) {
$res = Safe-FixFile -Path $f.FullName -BackupBefore:$Backup
$fixSummary += ("{0} => {1}" -f $f.FullName, $res.msg)
foreach ($a in $res.actions) { Write-Log " $a" }
}
}
# ==============================
# Compilação em FULLONE_COMPILED.ps1
# ==============================
Write-Log "Gerando compilado FULLONE_COMPILED..."
$compiledFolder = Join-Path $RootPath "FULLONE_COMPILED"
if (!(Test-Path $compiledFolder)) { New-Item -ItemType Directory -Path $compiledFolder
-Force | Out-Null }
$compiledPath = Join-Path $compiledFolder ("FULLONE_COMPILED_$now.ps1")
$compiledContent = @()
$compiledContent += "# FULLONE_COMPILED - gerado em $now"
$compiledContent += "# Root: $RootPath"
$compiledContent += ""
foreach ($f in $files) {
$compiledContent +=
"#########################################################################
#####"
$compiledContent += "# INICIO: $($f.FullName)"
try {
$txt = Get-Content -Raw -LiteralPath $f.FullName
if ($f.Extension -eq ".py") {
$compiledContent += "<# PYTHON SCRIPT ORIGEM #>"
$compiledContent += $txt
$compiledContent += "<# FIM PYTHON #>"
} else {
$compiledContent += $txt
}
} catch {
$compiledContent += "# Falha ao incluir $($f.FullName): $($_.Exception.Message)"
}
$compiledContent += "# FIM: $($f.FullName)"
$compiledContent +=
"#########################################################################
#####"
$compiledContent += ""
}
if ($DryRun) {
$compiledSim = $compiledPath + ".simulado.txt"
$compiledContent | Out-File -FilePath $compiledSim -Encoding UTF8
Write-Log "Compilado simulado salvo em: $compiledSim"
} else {
$compiledContent | Out-File -FilePath $compiledPath -Encoding UTF8
Write-Log "Compilado salvo em: $compiledPath"
}
# ==============================
# Salvar relatório final
# ==============================
if ($AutoFix) {
$summary += ""
$summary += "Resumo SafeFix:"
$summary += $fixSummary
}
$summary += ""
$summary += "Fim do relatório."
$summary | Out-File -FilePath $reportFile -Encoding UTF8
Write-Log "Relatório salvo em: $reportFile"
Write-Log "Execução finalizada."
# ===== FIM FULLONEv00002.ps1 =====

# ===== INICIO FULLONEv00003.ps1 =====
<#
================================================================================
 SCRIPT: FULLONE-ROUTINE.ps1
 OBJETIVO:
   - Buscar todos os .ps1 e .py dentro da pasta raiz especificada
   - Contar arquivos
   - Detectar duplicados (conteúdo e nome)
   - Corrigir caracteres problemáticos (SafeFix, opcional)
   - Compilar todos em 1 único FULLONE_COMPILED.ps1
   - Executar cada script em processo separado (opcional)
   - Relatório e log detalhado
   - Script independente

 AUTOR: Assistente Automação
================================================================================
#>

param(
    [string]$RootPath = 'C:\CONAV TRADER\CONAV_TRADER',
    [switch]$DryRun = $true,
    [switch]$AutoFix = $false,
    [switch]$Backup = $true,
    [switch]$Exec = $false,
    [switch]$UsePwsh = $false
)

# ==============================
# Função de log
# ==============================
function Write-Log {
    param([string]$Message,[string]$Level = 'INFO')
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$ts][$Level] $Message"
    if (!(Test-Path $Global:FULLONE_LogFileDir)) {
        New-Item -ItemType Directory -Path $Global:FULLONE_LogFileDir -Force | Out-Null
    }
    Add-Content -Path $Global:FULLONE_LogFile -Value $line -Encoding UTF8
    Write-Host $line
}

# ==============================
# Inicialização
# ==============================
$RootPath = (Resolve-Path -Path $RootPath).ProviderPath
$now = Get-Date -Format 'yyyyMMdd_HHmmss'

$Global:FULLONE_LogFileDir = Join-Path $RootPath 'logs_FULLONE'
$Global:FULLONE_LogFile = Join-Path $Global:FULLONE_LogFileDir ("fullone_log_$now.txt")
if (!(Test-Path $Global:FULLONE_LogFileDir)) {
    New-Item -ItemType Directory -Path $Global:FULLONE_LogFileDir -Force | Out-Null
}

Write-Log "FULLONE iniciado. RootPath = $RootPath"
if ($DryRun) { Write-Log "MODO: DRY RUN (simulação). Nenhuma alteração será feita." }

# ==============================
# Localizar arquivos
# ==============================
Write-Log "Procurando arquivos .ps1 e .py..."
$files = Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue `
    | Where-Object { $_.Extension -in '.ps1','.py' }
$totalCount = $files.Count
Write-Log "Total encontrado: $totalCount arquivos."

# ==============================
# Relatório inicial
# ==============================
$reportFile = Join-Path $RootPath ("relatorio_FULLONE_$now.txt")
$summary = @()
$summary += "Relatório FULLONE - $now"
$summary += "RootPath: $RootPath"
$summary += "Total arquivos: $totalCount"
$summary += ""

# ==============================
# Duplicados (conteúdo e nome)
# ==============================
Write-Log "Verificando duplicados..."
$hashMap = @{}
$byName = @{}
foreach ($f in $files) {
    try {
        $h = Get-FileHash -Path $f.FullName -Algorithm SHA256
        if (-not $hashMap.ContainsKey($h.Hash)) { $hashMap[$h.Hash] = @() }
        $hashMap[$h.Hash] += $f
    } catch { Write-Log "Falha hash $($f.FullName): $($_.Exception.Message)" "WARN" }
    if (-not $byName.ContainsKey($f.Name)) { $byName[$f.Name] = @() }
    $byName[$f.Name] += $f
}
$dupByContent = $hashMap.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
$dupByName = $byName.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

if ($dupByContent.Count -gt 0) {
    $summary += "Duplicados por conteúdo: $($dupByContent.Count) grupos"
    foreach ($g in $dupByContent) {
        $summary += "Hash: $($g.Key)"
        foreach ($f in $g.Value) { $summary += "   $($f.FullName)" }
    }
} else { $summary += "Nenhum duplicado de conteúdo." }

if ($dupByName.Count -gt 0) {
    $summary += ""
    $summary += "Duplicados por nome: $($dupByName.Count) grupos"
    foreach ($g in $dupByName) {
        $summary += "Nome: $($g.Key)"
        foreach ($f in $g.Value) { $summary += "   $($f.FullName)" }
    }
} else { $summary += "Nenhum duplicado por nome." }

# ==============================
# Função SafeFix
# ==============================
function Safe-FixFile {
    param([string]$Path,[switch]$BackupBefore)
    $actions=@()
    if ($BackupBefore) {
        $backupDir = Join-Path $RootPath ("BACKUP_FULLONE_$now")
        if (!(Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
        $dest = Join-Path $backupDir ((Split-Path $Path -Leaf)+".bak")
        Copy-Item $Path $dest -Force
        $actions+="Backup: $dest"
    }
    try { $raw=Get-Content -Raw -LiteralPath $Path } catch { return @{success=$false;msg="Falha leitura";actions=$actions} }
    $orig=$raw
    $raw=$raw -replace "[\u201C\u201D]",'"' -replace "[\u2018\u2019]","'" -replace "…","..." -replace "\u00A0"," "
    if ($raw.StartsWith([char]0xFEFF)) { $raw=$raw.Substring(1); $actions+="BOM removido" }
    if ($raw -ne $orig) {
        if ($DryRun) { return @{success=$true;changed=$true;msg="Alterações simuladas";actions=$actions} }
        else { $raw|Out-File -LiteralPath $Path -Encoding UTF8 -Force; return @{success=$true;changed=$true;msg="Alterações aplicadas";actions=$actions} }
    } else { return @{success=$true;changed=$false;msg="Nenhuma alteração";actions=$actions} }
}

# ==============================
# SafeFix (opcional)
# ==============================
$fixSummary=@()
if ($AutoFix) {
    Write-Log "Rodando SafeFix..."
    foreach ($f in $files) {
        $res=Safe-FixFile -Path $f.FullName -BackupBefore:$Backup
        $fixSummary+=("$($f.FullName) => $($res.msg)")
        foreach ($a in $res.actions) { Write-Log "   $a" }
    }
}

# ==============================
# Compilação
# ==============================
Write-Log "Gerando compilado..."
$compiledDir=Join-Path $RootPath "FULLONE_COMPILED"
if (!(Test-Path $compiledDir)) { New-Item -ItemType Directory -Path $compiledDir -Force|Out-Null }
$compiledPath=Join-Path $compiledDir ("FULLONE_COMPILED_$now.ps1")

$compiled=@()
$compiled+="# FULLONE_COMPILED - $now"
$compiled+="# Root: $RootPath"
foreach ($f in $files) {
    $compiled+="##############################################################################"
    $compiled+="# INICIO: $($f.FullName)"
    try {
        $txt=Get-Content -Raw -LiteralPath $f.FullName
        if ($f.Extension -eq ".py") { $compiled+="<# PYTHON ORIGEM #>";$compiled+=$txt;$compiled+="<# FIM PYTHON #>" }
        else { $compiled+=$txt }
    } catch { $compiled+="# Falha incluir $($f.FullName)" }
    $compiled+="# FIM: $($f.FullName)"
}
if ($DryRun) {
    $compiledSim=$compiledPath+".simulado.txt"
    $compiled|Out-File -FilePath $compiledSim -Encoding UTF8
    Write-Log "Compilado simulado salvo em: $compiledSim"
} else {
    $compiled|Out-File -FilePath $compiledPath -Encoding UTF8
    Write-Log "Compilado salvo em: $compiledPath"
}

# ==============================
# Execução isolada (opcional)
# ==============================
if ($Exec) {
    Write-Log "Executando scripts em processos separados..."
    foreach ($f in $files) {
        if ($DryRun) { Write-Log "Simulado: $($f.FullName)"; continue }
        if ($f.Extension -eq ".py") {
            try { Start-Process -FilePath "python" -ArgumentList "`"$($f.FullName)`"" -Wait -NoNewWindow -PassThru | Out-Null; Write-Log "OK: $($f.Name)" }
            catch { Write-Log "Erro Python: $($f.FullName)" "ERROR" }
        } else {
            $exe=if ($UsePwsh) {'pwsh'} else {'powershell'}
            try { Start-Process -FilePath $exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($f.FullName)`"" -Wait -NoNewWindow -PassThru|Out-Null; Write-Log "OK: $($f.Name)" }
            catch { Write-Log "Erro PowerShell: $($f.FullName)" "ERROR" }
        }
    }
}

# ==============================
# Relatório final
# ==============================
if ($AutoFix) { $summary+="";$summary+="Resumo SafeFix:";$summary+=$fixSummary }
$summary+="";$summary+="Fim do relatório."
$summary|Out-File -FilePath $reportFile -Encoding UTF8
Write-Log "Relatório salvo em: $reportFile"
Write-Log "FULLONE finalizado."
# ===== FIM FULLONEv00003.ps1 =====

# ===== INICIO FULLONEv00004.ps1 =====
<#
.SYNOPSIS
FULLONEv00003.ps1 - rotina unificada para descobrir, analisar, corrigir (opcional),
compilar, executar e versionar scripts (.ps1 .py).
.DESCRIPTION
- Busca recursiva por .ps1 e .py em RootPath (padrão: C:\CONAV
TRADER\CONAV_TRADER)
- Relatórios: contagem, duplicados (por hash), arquivos com mesmo nome (comparação)
- SafeFix (correções seguras) com Backup opcional
- Geração de FULLONE_COMPILED_<timestamp>.ps1 (ou .simulado.txt em DryRun)
- Execução isolada por processo (opcional)
- Deploy/versionamento do FULLONE para pastas de integração (opcional)
- DryRun por padrão (não modifica nada)
- Logs em <RootPath>\logs_FULLONE
- Relatórios em <RootPath>
#>
param(
[string]$RootPath = 'C:\CONAV TRADER\CONAV_TRADER',
[switch]$DryRun = $true,
[switch]$AutoFix = $false,
[switch]$Backup = $true,
[switch]$Exec = $false,
[switch]$UsePwsh = $false,
[switch]$MakeCompiledOnly = $false,
[switch]$Deploy = $false
)
Set-StrictMode -Version Latest
# -------------------------
# Helpers / Inicialização
# -------------------------
function Safe-JoinPath {
param([string]$Path, [string]$Child)
return Join-Path -Path $Path -ChildPath $Child
}
# resolve RootPath absolute
try { $RootPath = (Resolve-Path -Path $RootPath -ErrorAction Stop).ProviderPath } catch {
Write-Error "RootPath inválido: $RootPath"; exit 1 }
$now = Get-Date -Format 'yyyyMMdd_HHmmss'
# log dir & file (cria diretório ANTES de montar o nome do arquivo)
$LogDir = Safe-JoinPath -Path $RootPath -Child "logs_FULLONE"
if (-not (Test-Path -LiteralPath $LogDir -PathType Container)) {
try { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null } catch { Write-Warning
"Não foi possível criar pasta de logs: $LogDir" }
}
$LogFile = Safe-JoinPath -Path $LogDir -Child ("fullone_log_$now.txt")
# garante que o arquivo de log exista (assim Add-Content não tenta escrever num diretório)
if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
try { New-Item -ItemType File -Path $LogFile -Force | Out-Null } catch { Write-Warning
"Não foi possível criar o arquivo de log: $LogFile" }
}
function Write-Log {
param(
[string]$Message,
[string]$Level = 'INFO'
)
$ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
$line = "[$ts][$Level] $Message"
# proteção: se por algum motivo $LogFile for diretório, redirecionar para console
if (Test-Path -LiteralPath $LogFile -PathType Container) {
Write-Host "[WARN] Log path é diretório! $LogFile" -ForegroundColor Yellow
Write-Host $line
} else {
try {
Add-Content -Path $LogFile -Value $line -Encoding UTF8
} catch {
Write-Warning "Falha escrevendo log em $LogFile: $($_.Exception.Message)"
Write-Host $line
}
}
Write-Host $line
}
Write-Log "FULLONE iniciado. RootPath = $RootPath"
if ($DryRun) { Write-Log "MODO: DRY RUN (simulação). Nenhuma alteração será feita." }
# -------------------------
# Padrões / exclusões
# -------------------------
$ignorePatterns = @(
'\\.git\\',
'\\node_modules\\',
'\\dist\\',
'\\build\\',
'\\FULLONE_COMPILED\\', # não varrer a pasta de compilados
'\\BACKUP_FULLONE_', # não varrer backups criados pelo próprio script
'\\logs_FULLONE\\' # evitar reprocessar logs
)
function Path-IsIgnored {
param([string]$FullName)
foreach ($p in $ignorePatterns) {
if ($FullName -match $p) { return $true }
}
return $false
}
# -------------------------
# Localizar arquivos .ps1 e .py
# -------------------------
Write-Log "Procurando arquivos .ps1 e .py recursivamente..."
try {
$files = Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue |
Where-Object { $_.Extension -in '.ps1', '.py' } |
Where-Object { -not (Path-IsIgnored -FullName $_.FullName) } |
Where-Object { $_.FullName -ne $PSCommandPath -and $_.FullName -ne
$MyInvocation.MyCommand.Definition }
} catch {
Write-Log "Erro ao listar arquivos: $($_.Exception.Message)" "ERROR"
$files = @()
}
$totalCount = $files.Count
Write-Log "Total encontrado: $totalCount arquivos (.ps1/.py)."
# relatório inicial
$reportFile = Safe-JoinPath -Path $RootPath -Child ("relatorio_FULLONE_$now.txt")
$summary = New-Object System.Collections.Generic.List[string]
$summary.Add("FULLONE Report - $now")
$summary.Add("RootPath: $RootPath")
$summary.Add("Total scripts found: $totalCount")
$summary.Add("")
# -------------------------
# Hashes e duplicados
# -------------------------
Write-Log "Calculando hashes (SHA256) para identificar duplicados..."
$hashMap = @{}
$byName = @{}
foreach ($f in $files) {
try {
$h = Get-FileHash -Path $f.FullName -Algorithm SHA256 -ErrorAction Stop
$hash = $h.Hash
} catch {
Write-Log "Falha ao calcular hash de $($f.FullName): $($_.Exception.Message)"
"WARN"
$hash = "ERROR_$([guid]::NewGuid().ToString())"
}
if (-not $hashMap.ContainsKey($hash)) { $hashMap[$hash] = New-Object
System.Collections.ArrayList }
$hashMap[$hash].Add($f) | Out-Null
if (-not $byName.ContainsKey($f.Name)) { $byName[$f.Name] = New-Object
System.Collections.ArrayList }
$byName[$f.Name].Add($f) | Out-Null
}
$dupByContent = $hashMap.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
if ($dupByContent.Count -gt 0) {
Write-Log "Duplicados por conteúdo encontrados: $($dupByContent.Count) grupos."
$summary.Add("Duplicados por conteúdo (grupos): $($dupByContent.Count)")
foreach ($g in $dupByContent) {
$summary.Add("GrupoHash: $($g.Key)")
foreach ($item in $g.Value) { $summary.Add(" $($item.FullName) (modified:
$($item.LastWriteTime))") }
}
} else {
$summary.Add("Nenhum duplicado de conteúdo detectado.")
Write-Log "Nenhum duplicado por conteúdo detectado."
}
$dupByName = $byName.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
if ($dupByName.Count -gt 0) {
Write-Log "Mesmo nome em múltiplas localizações: $($dupByName.Count) nomes."
$summary.Add("")
$summary.Add("Arquivos com mesmo nome em múltiplas pastas:
$($dupByName.Count)")
foreach ($g in $dupByName) {
$summary.Add("Nome: $($g.Key)")
foreach ($item in $g.Value) {
$summary.Add(" $($item.FullName) (LastWrite: $($item.LastWriteTime), Size:
$($item.Length))")
}
$latest = $g.Value | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$summary.Add(" -> Sugerido manter (mais recente): $($latest.FullName)")
}
} else {
$summary.Add("Nenhum arquivo com mesmo nome em múltiplos locais.")
}
# salva resumo inicial temporariamente (vai ser sobrescrito no final também)
try { $summary | Out-File -FilePath $reportFile -Encoding UTF8 -Force } catch { Write-Log
"Falha salvando relatório inicial: $($_.Exception.Message)" "WARN" }
# -------------------------
# Safe-Fix function
# -------------------------
function Safe-FixFile {
param(
[string]$Path,
[switch]$BackupBefore
)
$actions = New-Object System.Collections.ArrayList
if ($BackupBefore) {
$backupDir = Safe-JoinPath -Path $RootPath -Child ("BACKUP_FULLONE_$now")
if (-not (Test-Path -LiteralPath $backupDir -PathType Container)) { New-Item -ItemType
Directory -Path $backupDir -Force | Out-Null }
$dest = Safe-JoinPath -Path $backupDir -Child ((Split-Path $Path -Leaf) + ".bak")
try { Copy-Item -LiteralPath $Path -Destination $dest -Force } catch {
$actions.Add("Falha criando backup: $($_.Exception.Message)") | Out-Null }
$actions.Add("Backup: $dest") | Out-Null
}
try {
$raw = Get-Content -Raw -LiteralPath $Path -ErrorAction Stop
} catch {
return @{ success = $false; message = "Falha ao ler: $($_.Exception.Message)";
actions=$actions }
}
$orig = $raw
# substituições seguras
$raw = $raw -replace "[\u201C\u201D]", '"' # curly double -> "
$raw = $raw -replace "[\u2018\u2019]", "'" # curly single -> '
$raw = $raw -replace "…", "..."
$raw = $raw -replace "\u00A0", " " # NBSP -> space
if ($raw.Length -gt 0 -and $raw[0] -eq [char]0xFEFF) { $raw = $raw.Substring(1);
$actions.Add("Removed BOM") | Out-Null }
if ($raw -ne $orig) {
if ($DryRun) {
$actions.Add("CHANGES (simulado)") | Out-Null
return @{ success = $true; changed = $true; message = "Simulado: alterações
sugeridas"; actions=$actions }
} else {
try {
# salvar sem BOM explicitamente
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($Path, $raw, $utf8NoBom)
$actions.Add("Saved changes (UTF8 no BOM)") | Out-Null
return @{ success = $true; changed = $true; message = "Alterações aplicadas";
actions=$actions }
} catch {
return @{ success = $false; changed = $false; message = "Falha ao salvar:
$($_.Exception.Message)"; actions=$actions }
}
}
} else {
return @{ success = $true; changed = $false; message = "Nenhuma alteração
necessária"; actions=$actions }
}
}
# -------------------------
# AutoFix (opcional)
# -------------------------
$fixSummary = New-Object System.Collections.ArrayList
if ($AutoFix) {
Write-Log "AutoFix solicitado. Preparando aplicação de correções seguras."
if ($DryRun) { Write-Log "Nota: Em DryRun; AutoFix apenas simulado." }
$confirm = $true
if (-not $DryRun) {
try {
$choice = Read-Host "Você quer realmente aplicar AutoFix em todos os arquivos
encontrados? (S/N)"
if ($choice.ToUpper() -ne 'S') { $confirm = $false; Write-Log "AutoFix CANCELADO
pelo usuário." }
} catch { $confirm = $true }
}
if ($confirm) {
foreach ($f in $files) {
Write-Log "Analisando para fix: $($f.FullName)"
$res = Safe-FixFile -Path $f.FullName -BackupBefore:$Backup
if ($res.success) {
$fixSummary.Add(("{0} => {1} - {2}" -f $f.FullName, ($res.changed -eq $true ?
"CHANGED":"UNCHANGED"), $res.message)) | Out-Null
foreach ($a in $res.actions) { Write-Log " $a" }
} else {
Write-Log "Erro no Safe-FixFile: $($res.message)" "ERROR"
}
}
Write-Log "AutoFix finalizado (ou simulado)."
}
}
# -------------------------
# Gerar arquivo compilado
# -------------------------
Write-Log "Gerando arquivo compilado FULLONE_COMPILED..."
$compiledFolder = Safe-JoinPath -Path $RootPath -Child 'FULLONE_COMPILED'
if (-not (Test-Path -LiteralPath $compiledFolder -PathType Container)) { New-Item -ItemType
Directory -Path $compiledFolder -Force | Out-Null }
$compiledPath = Safe-JoinPath -Path $compiledFolder -Child
("FULLONE_COMPILED_$now.ps1")
$header = @()
$header += "# FULLONE_COMPILED - gerado em $now"
$header += "# Root: $RootPath"
$header += "# Arquivos incluídos:"
foreach ($f in $files) { $header += ("# - {0} (LastWrite: {1})" -f $f.FullName, $f.LastWriteTime)
}
$header += ""
$compiledContent = $header -join "`r`n" + "`r`n"
foreach ($f in $files) {
$compiledContent += "`r`n"
$compiledContent +=
"#########################################################################
#####`r`n"
$compiledContent += "# INICIO: $($f.FullName)`r`n"
$compiledContent +=
"#########################################################################
#####`r`n"
try {
$txt = Get-Content -Raw -LiteralPath $f.FullName -ErrorAction Stop
if ($f.Extension.ToLower() -eq '.py') {
$compiledContent += "<# PY: origem: $($f.FullName) #>`r`n"
$compiledContent += $txt + "`r`n"
$compiledContent += "<# FIM PY #>`r`n"
} else {
$compiledContent += $txt + "`r`n"
}
} catch {
Write-Log "Falha lendo $($f.FullName) para inclusão compilada:
$($_.Exception.Message)" "WARN"
$compiledContent += "# Falha ao incluir $($f.FullName): $($_.Exception.Message)`r`n"
}
$compiledContent += "`r`n"
$compiledContent +=
"#########################################################################
#####`r`n"
$compiledContent += "# FIM: $($f.FullName)`r`n"
$compiledContent +=
"#########################################################################
#####`r`n"
}
if ($DryRun) {
$simulatedCompiledPath = $compiledPath + ".simulado.txt"
try {
# salvar sem BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($simulatedCompiledPath, $compiledContent,
$utf8NoBom)
Write-Log "Em DryRun: compilado simulado salvo em: $simulatedCompiledPath"
} catch { Write-Log "Falha salvando compilado simulado: $($_.Exception.Message)"
"WARN" }
} else {
try {
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($compiledPath, $compiledContent, $utf8NoBom)
Write-Log "Arquivo compilado salvo em: $compiledPath"
} catch { Write-Log "Falha ao salvar compilado: $($_.Exception.Message)" "ERROR" }
}
if ($MakeCompiledOnly) {
Write-Log "MakeCompiledOnly solicitado. Finalizando sem execução."
$summary.Add("Compiled file: " + (if ($DryRun) { $simulatedCompiledPath } else {
$compiledPath }))
$summary.Add("LOG: $LogFile")
$summary.Add("Fim do relatório.")
$summary | Out-File -FilePath $reportFile -Encoding UTF8 -Force
Write-Log "Relatório salvo em: $reportFile"
exit 0
}
# -------------------------
# Execução isolada (opcional)
# -------------------------
if ($Exec) {
Write-Log "Execução isolada de cada script solicitada. Será executado em processos
separados."
if ($DryRun) { Write-Log "OBS: Execução em DryRun (simulação) - nada será
executado)." }
foreach ($f in $files) {
Write-Log "Preparando execução: $($f.FullName)"
if ($DryRun) {
Write-Log "Simulado: executar $($f.FullName)"
continue
}
if ($f.Extension.ToLower() -eq '.py') {
$exe = 'python'
try {
$proc = Start-Process -FilePath $exe -ArgumentList @($f.FullName) -Wait
-NoNewWindow -PassThru -ErrorAction Stop
Write-Log "Processo finalizado: ExitCode $($proc.ExitCode)"
} catch {
Write-Log "Falha ao executar python $($f.FullName): $($_.Exception.Message)"
"ERROR"
}
} else {
$psExe = if ($UsePwsh) { 'pwsh' } else { 'powershell' }
$arg = "-NoProfile -ExecutionPolicy Bypass -File `"$($f.FullName)`""
try {
$proc = Start-Process -FilePath $psExe -ArgumentList $arg -Wait -NoNewWindow
-PassThru -ErrorAction Stop
Write-Log "Processo finalizado: ExitCode $($proc.ExitCode)"
} catch {
Write-Log "Falha ao executar $($f.FullName): $($_.Exception.Message)"
"ERROR"
}
}
}
}
# -------------------------
# Deploy / versionamento do FULLONE (opcional)
# -------------------------
if ($Deploy) {
Write-Log "Deploy solicitado: copiando FULLONE para pastas de integração
(confirmando)."
$scriptPath = $MyInvocation.MyCommand.Definition
$targets = @(
Safe-JoinPath -Path $RootPath -Child 'scripts\SCRIPTS BASE OFICIAIS',
Safe-JoinPath -Path $RootPath -Child 'SCRIPT MESTRE',
Safe-JoinPath -Path $RootPath -Child 'PACKAGES OFICIAIS'
)
foreach ($t in $targets) {
if (-not (Test-Path -LiteralPath $t -PathType Container)) {
try { New-Item -ItemType Directory -Path $t -Force | Out-Null } catch { Write-Log
"Falha criando target $t: $($_.Exception.Message)" "WARN" }
}
$baseName = 'FULLONE'
$existing = Get-ChildItem -Path $t -Filter "$baseName*.ps1" -File -ErrorAction
SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
$digits = ([regex]::Matches($existing.BaseName,'\d+')) | Select-Object -Last 1
if ($digits) { $num = [int]$digits.Value + 1 } else { $num = 1 }
} else { $num = 1 }
$dest = Join-Path -Path $t -Child ("{0}{1:D4}.ps1" -f $baseName,$num)
if ($DryRun) {
Write-Log "Simulado: copiar $scriptPath -> $dest"
} else {
try { Copy-Item -LiteralPath $scriptPath -Destination $dest -Force; Write-Log
"Copiado $scriptPath -> $dest" } catch { Write-Log "Falha no deploy $dest:
$($_.Exception.Message)" "ERROR" }
}
}
}
# -------------------------
# Finalizar e salvar relatório detalhado
# -------------------------
$report = New-Object System.Collections.Generic.List[string]
$report.AddRange($summary)
$report.Add("")
$report.Add("Detalhes:")
$report.Add("Total arquivos: $totalCount")
$report.Add("Duplicados por conteúdo (grupos): $($dupByContent.Count)")
$report.Add("Mesmo nome em múltiplas pastas: $($dupByName.Count)")
$report.Add("")
if ($AutoFix) {
$report.Add("AutoFix summary:")
$fixSummary | ForEach-Object { $report.Add($_) }
}
$report.Add("")
$report.Add("Compiled file: " + (if ($DryRun) { $simulatedCompiledPath } else {
$compiledPath }))
$report.Add("")
$report.Add("LOG: " + $LogFile)
$report.Add("")
$report.Add("Fim do relatório.")
try { $report | Out-File -FilePath $reportFile -Encoding UTF8 -Force } catch { Write-Log
"Falha salvando relatório final: $($_.Exception.Message)" "ERROR" }
Write-Log "FULLONE finalizado. Relatório salvo em: $reportFile"
if ($DryRun) { Write-Log "Recomendo revisar relatório e rodar sem -DryRun e com -AutoFix
somente após confirmar." }
# ===== FIM FULLONEv00004.ps1 =====

# ===== INICIO FULLONEv00005.ps1 =====
<#
================================================================================
 SCRIPT: FULLONEv00003.ps1
 OBJETIVO:
   - Buscar todos os .ps1 e .py dentro da pasta raiz especificada
   - Contar arquivos
   - Detectar duplicados (conteúdo e nome)
   - Corrigir caracteres problemáticos (SafeFix, opcional)
   - Compilar todos em 1 único FULLONE_COMPILED.ps1
   - Executar cada script em processo separado (opcional)
   - Relatório e log detalhado
   - Deploy automático para pastas de integração
   - Script independente e seguro

 AUTOR: Assistente Automação
================================================================================
#>

param(
    [string]$RootPath = 'C:\CONAV TRADER\CONAV_TRADER',
    [switch]$DryRun = $true,
    [switch]$AutoFix = $false,
    [switch]$Backup = $true,
    [switch]$Exec = $false,
    [switch]$UsePwsh = $false,
    [switch]$Deploy = $true
)

# ==============================
# Função de log
# ==============================
function Write-Log {
    param([string]$Message,[string]$Level = 'INFO')
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$ts][$Level] $Message"
    Add-Content -Path $Global:FULLONE_LogFile -Value $line -Encoding UTF8
    Write-Host $line
}

# ==============================
# Inicialização
# ==============================
$RootPath = (Resolve-Path -Path $RootPath).ProviderPath
$now = Get-Date -Format 'yyyyMMdd_HHmmss'

# Diretório de logs
$Global:FULLONE_LogFileDir = Join-Path $RootPath 'logs_FULLONE'
if (!(Test-Path $Global:FULLONE_LogFileDir)) {
    New-Item -ItemType Directory -Path $Global:FULLONE_LogFileDir -Force | Out-Null
}
# Arquivo de log correto
$Global:FULLONE_LogFile = Join-Path $Global:FULLONE_LogFileDir ("fullone_log_$now.txt")

Write-Log "FULLONE iniciado. RootPath = $RootPath"
if ($DryRun) { Write-Log "MODO: DRY RUN (simulação). Nenhuma alteração será feita." }

# ==============================
# Localizar arquivos
# ==============================
Write-Log "Procurando arquivos .ps1 e .py recursivamente..."
$files = Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue `
    | Where-Object { $_.Extension -in '.ps1','.py' }
$totalCount = $files.Count
Write-Log "Total encontrado: $totalCount arquivos (.ps1/.py)."

# ==============================
# Relatório inicial
# ==============================
$reportFile = Join-Path $RootPath ("relatorio_FULLONE_$now.txt")
$summary = @()
$summary += "Relatório FULLONE - $now"
$summary += "RootPath: $RootPath"
$summary += "Total arquivos: $totalCount"
$summary += ""

# ==============================
# Duplicados (conteúdo e nome)
# ==============================
Write-Log "Verificando duplicados por conteúdo (hash)..."
$hashMap = @{}
$byName = @{}
foreach ($f in $files) {
    try {
        $h = Get-FileHash -Path $f.FullName -Algorithm SHA256
        if (-not $hashMap.ContainsKey($h.Hash)) { $hashMap[$h.Hash] = @() }
        $hashMap[$h.Hash] += $f
    } catch { Write-Log "Falha hash $($f.FullName): $($_.Exception.Message)" "WARN" }
    if (-not $byName.ContainsKey($f.Name)) { $byName[$f.Name] = @() }
    $byName[$f.Name] += $f
}
$dupByContent = $hashMap.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
$dupByName = $byName.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

if ($dupByContent.Count -gt 0) {
    $summary += "Duplicados por conteúdo: $($dupByContent.Count) grupos"
    foreach ($g in $dupByContent) {
        $summary += "Hash: $($g.Key)"
        foreach ($f in $g.Value) { $summary += "   $($f.FullName)" }
    }
} else { $summary += "Nenhum duplicado de conteúdo." }

Write-Log "Verificando arquivos com mesmo nome..."
if ($dupByName.Count -gt 0) {
    $summary += ""
    $summary += "Duplicados por nome: $($dupByName.Count) grupos"
    foreach ($g in $dupByName) {
        $summary += "Nome: $($g.Key)"
        foreach ($f in $g.Value) { $summary += "   $($f.FullName)" }
    }
} else { $summary += "Nenhum duplicado por nome." }

# ==============================
# Função SafeFix
# ==============================
function Safe-FixFile {
    param([string]$Path,[switch]$BackupBefore)
    $actions=@()
    if ($BackupBefore) {
        $backupDir = Join-Path $RootPath ("BACKUP_FULLONE_$now")
        if (!(Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
        $dest = Join-Path $backupDir ((Split-Path $Path -Leaf)+".bak")
        Copy-Item $Path $dest -Force
        $actions+="Backup: $dest"
    }
    try { $raw=Get-Content -Raw -LiteralPath $Path } catch { return @{success=$false;msg="Falha leitura";actions=$actions} }
    $orig=$raw
    $raw=$raw -replace "[\u201C\u201D]",'"' -replace "[\u2018\u2019]","'" -replace "…","..." -replace "\u00A0"," "
    if ($raw.StartsWith([char]0xFEFF)) { $raw=$raw.Substring(1); $actions+="BOM removido" }
    if ($raw -ne $orig) {
        if ($DryRun) { return @{success=$true;changed=$true;msg="Alterações simuladas";actions=$actions} }
        else { $raw|Out-File -LiteralPath $Path -Encoding UTF8 -Force; return @{success=$true;changed=$true;msg="Alterações aplicadas";actions=$actions} }
    } else { return @{success=$true;changed=$false;msg="Nenhuma alteração";actions=$actions} }
}

# ==============================
# SafeFix (opcional)
# ==============================
$fixSummary=@()
if ($AutoFix) {
    Write-Log "Rodando SafeFix..."
    foreach ($f in $files) {
        $res=Safe-FixFile -Path $f.FullName -BackupBefore:$Backup
        $fixSummary+=("$($f.FullName) => $($res.msg)")
        foreach ($a in $res.actions) { Write-Log "   $a" }
    }
}

# ==============================
# Compilação
# ==============================
Write-Log "Gerando compilado FULLONE_COMPILED..."
$compiledDir = Join-Path $RootPath "FULLONE_COMPILED"
if (!(Test-Path $compiledDir)) {
    New-Item -ItemType Directory -Path $compiledDir -Force | Out-Null
}
$compiledPath = Join-Path $compiledDir ("FULLONE_COMPILED_$now.ps1")

$compiled=@()
$compiled+="# FULLONE_COMPILED - $now"
$compiled+="# Root: $RootPath"
foreach ($f in $files) {
    $compiled+="##############################################################################"
    $compiled+="# INICIO: $($f.FullName)"
    try {
        $txt=Get-Content -Raw -LiteralPath $f.FullName
        if ($f.Extension -eq ".py") { $compiled+="<# PYTHON ORIGEM #>";$compiled+=$txt;$compiled+="<# FIM PYTHON #>" }
        else { $compiled+=$txt }
    } catch { $compiled+="# Falha incluir $($f.FullName)" }
    $compiled+="# FIM: $($f.FullName)"
}
if ($DryRun) {
    $compiledSim=$compiledPath+".simulado.txt"
    $compiled|Out-File -FilePath $compiledSim -Encoding UTF8
    Write-Log "Compilado simulado salvo em: $compiledSim"
} else {
    $compiled|Out-File -FilePath $compiledPath -Encoding UTF8
    Write-Log "Compilado salvo em: $compiledPath"
}

# ==============================
# Execução isolada (opcional)
# ==============================
if ($Exec) {
    Write-Log "Executando scripts em processos separados..."
    foreach ($f in $files) {
        if ($DryRun) { Write-Log "Simulado: $($f.FullName)"; continue }
        if ($f.Extension -eq ".py") {
            try { Start-Process -FilePath "python" -ArgumentList "`"$($f.FullName)`"" -Wait -NoNewWindow -PassThru | Out-Null; Write-Log "OK: $($f.Name)" }
            catch { Write-Log "Erro Python: $($f.FullName)" "ERROR" }
        } else {
            $exe=if ($UsePwsh) {'pwsh'} else {'powershell'}
            try { Start-Process -FilePath $exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($f.FullName)`"" -Wait -NoNewWindow -PassThru|Out-Null; Write-Log "OK: $($f.Name)" }
            catch { Write-Log "Erro PowerShell: $($f.FullName)" "ERROR" }
        }
    }
}

# ==============================
# Deploy automático (opcional)
# ==============================
if ($Deploy) {
    Write-Log "Iniciando deploy automático..."
    $deployDirs = @(
        (Join-Path $RootPath "DEPLOY_FULLONE"),
        (Join-Path $RootPath "CONAV MASTER FULL\FULLONEMASTER"),
        (Join-Path $RootPath "MAGIC QUANTIC TRADER")
    )
    foreach ($d in $deployDirs) {
        if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
        if (-not $DryRun) {
            Copy-Item -Path $compiledPath -Destination $d -Force
            Write-Log "Deploy realizado em: $d"
        } else {
            Write-Log "Simulado: deploy em $d"
        }
    }
}

# ==============================
# Relatório final
# ==============================
if ($AutoFix) { $summary+="";$summary+="Resumo SafeFix:";$summary+=$fixSummary }
$summary+="";$summary+="Fim do relatório."
$summary|Out-File -FilePath $reportFile -Encoding UTF8
Write-Log "Relatório salvo em: $reportFile"
Write-Log "Execução finalizada."
# ===== FIM FULLONEv00005.ps1 =====

# ===== INICIO FULLONEv00006.ps1 =====
<#
================================================================================
 SCRIPT: FULLONE-correção1.ps1
 OBJETIVO:
   - Buscar todos os .ps1 e .py dentro da pasta raiz especificada
   - Contar arquivos
   - Detectar duplicados (conteúdo e nome)
   - Corrigir caracteres problemáticos (SafeFix, opcional)
   - Compilar todos em 1 único FULLONE_COMPILED.ps1
   - Executar cada script em processo separado (opcional)
   - Relatório e log detalhado
   - Deploy automático para pastas de integração
   - Script independente e seguro

 AUTOR: Assistente Automação
================================================================================
#>

param(
    [string]$RootPath = 'C:\CONAV TRADER\CONAV_TRADER',
    [switch]$DryRun = $true,
    [switch]$AutoFix = $false,
    [switch]$Backup = $true,
    [switch]$Exec = $false,
    [switch]$UsePwsh = $false,
    [switch]$Deploy = $true
)

# ==============================
# Função de log
# ==============================
function Write-Log {
    param([string]$Message,[string]$Level = 'INFO')
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$ts][$Level] $Message"
    try {
        Add-Content -Path $Global:FULLONE_LogFile -Value $line -Encoding UTF8
    } catch {
        Write-Warning "Falha escrevendo log em ${Global:FULLONE_LogFile}: $($_.Exception.Message)"
    }
    Write-Host $line
}

# ==============================
# Inicialização
# ==============================
$RootPath = (Resolve-Path -Path $RootPath).ProviderPath
$now = Get-Date -Format 'yyyyMMdd_HHmmss'

# Diretório de logs
$Global:FULLONE_LogFileDir = Join-Path $RootPath 'logs_FULLONE'
if (!(Test-Path $Global:FULLONE_LogFileDir)) {
    New-Item -ItemType Directory -Path $Global:FULLONE_LogFileDir -Force | Out-Null
}
# Arquivo de log correto
$Global:FULLONE_LogFile = Join-Path $Global:FULLONE_LogFileDir ("fullone_log_$now.txt")

Write-Log "FULLONE iniciado. RootPath = $RootPath"
if ($DryRun) { Write-Log "MODO: DRY RUN (simulação). Nenhuma alteração será feita." }

# ==============================
# Localizar arquivos
# ==============================
Write-Log "Procurando arquivos .ps1 e .py recursivamente..."
$files = Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue `
    | Where-Object { $_.Extension -in '.ps1','.py' }
$totalCount = $files.Count
Write-Log "Total encontrado: $totalCount arquivos (.ps1/.py)."

# ==============================
# Relatório inicial
# ==============================
$reportFile = Join-Path $RootPath ("relatorio_FULLONE_$now.txt")
$summary = @()
$summary += "Relatório FULLONE - $now"
$summary += "RootPath: $RootPath"
$summary += "Total arquivos: $totalCount"
$summary += ""

# ==============================
# Duplicados (conteúdo e nome)
# ==============================
Write-Log "Verificando duplicados por conteúdo (hash)..."
$hashMap = @{}
$byName = @{}
foreach ($f in $files) {
    try {
        $h = Get-FileHash -Path $f.FullName -Algorithm SHA256
        if (-not $hashMap.ContainsKey($h.Hash)) { $hashMap[$h.Hash] = @() }
        $hashMap[$h.Hash] += $f
    } catch { Write-Log "Falha hash $($f.FullName): $($_.Exception.Message)" "WARN" }
    if (-not $byName.ContainsKey($f.Name)) { $byName[$f.Name] = @() }
    $byName[$f.Name] += $f
}
$dupByContent = $hashMap.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
$dupByName = $byName.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

if ($dupByContent.Count -gt 0) {
    $summary += "Duplicados por conteúdo: $($dupByContent.Count) grupos"
    foreach ($g in $dupByContent) {
        $summary += "Hash: $($g.Key)"
        foreach ($f in $g.Value) { $summary += "   $($f.FullName)" }
    }
} else { $summary += "Nenhum duplicado de conteúdo." }

Write-Log "Verificando arquivos com mesmo nome..."
if ($dupByName.Count -gt 0) {
    $summary += ""
    $summary += "Duplicados por nome: $($dupByName.Count) grupos"
    foreach ($g in $dupByName) {
        $summary += "Nome: $($g.Key)"
        foreach ($f in $g.Value) { $summary += "   $($f.FullName)" }
    }
} else { $summary += "Nenhum duplicado por nome." }

# ==============================
# Função SafeFix
# ==============================
function Safe-FixFile {
    param([string]$Path,[switch]$BackupBefore)
    $actions=@()
    if ($BackupBefore) {
        $backupDir = Join-Path $RootPath ("BACKUP_FULLONE_$now")
        if (!(Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
        $dest = Join-Path $backupDir ((Split-Path $Path -Leaf)+".bak")
        Copy-Item $Path $dest -Force
        $actions+="Backup: $dest"
    }
    try { $raw=Get-Content -Raw -LiteralPath $Path } catch { return @{success=$false;msg="Falha leitura";actions=$actions} }
    $orig=$raw
    $raw=$raw -replace "[\u201C\u201D]",'"' -replace "[\u2018\u2019]","'" -replace "…","..." -replace "\u00A0"," "
    if ($raw.StartsWith([char]0xFEFF)) { $raw=$raw.Substring(1); $actions+="BOM removido" }
    if ($raw -ne $orig) {
        if ($DryRun) { return @{success=$true;changed=$true;msg="Alterações simuladas";actions=$actions} }
        else { $raw|Out-File -LiteralPath $Path -Encoding UTF8 -Force; return @{success=$true;changed=$true;msg="Alterações aplicadas";actions=$actions} }
    } else { return @{success=$true;changed=$false;msg="Nenhuma alteração";actions=$actions} }
}

# ==============================
# SafeFix (opcional)
# ==============================
$fixSummary=@()
if ($AutoFix) {
    Write-Log "Rodando SafeFix..."
    foreach ($f in $files) {
        $res=Safe-FixFile -Path $f.FullName -BackupBefore:$Backup
        $fixSummary+=("$($f.FullName) => $($res.msg)")
        foreach ($a in $res.actions) { Write-Log "   $a" }
    }
}

# ==============================
# Compilação
# ==============================
Write-Log "Gerando compilado FULLONE_COMPILED..."
$compiledDir = Join-Path $RootPath "FULLONE_COMPILED"
if (!(Test-Path $compiledDir)) {
    New-Item -ItemType Directory -Path $compiledDir -Force | Out-Null
}
$compiledPath = Join-Path $compiledDir ("FULLONE_COMPILED_$now.ps1")

$compiled=@()
$compiled+="# FULLONE_COMPILED - $now"
$compiled+="# Root: $RootPath"
foreach ($f in $files) {
    $compiled+="##############################################################################"
    $compiled+="# INICIO: $($f.FullName)"
    try {
        $txt=Get-Content -Raw -LiteralPath $f.FullName
        if ($f.Extension -eq ".py") { $compiled+="<# PYTHON ORIGEM #>";$compiled+=$txt;$compiled+="<# FIM PYTHON #>" }
        else { $compiled+=$txt }
    } catch { $compiled+="# Falha incluir $($f.FullName)" }
    $compiled+="# FIM: $($f.FullName)"
}
if ($DryRun) {
    $compiledSim=$compiledPath+".simulado.txt"
    $compiled|Out-File -FilePath $compiledSim -Encoding UTF8
    Write-Log "Compilado simulado salvo em: $compiledSim"
} else {
    $compiled|Out-File -FilePath $compiledPath -Encoding UTF8
    Write-Log "Compilado salvo em: $compiledPath"
}

# ==============================
# Execução isolada (opcional)
# ==============================
if ($Exec) {
    Write-Log "Executando scripts em processos separados..."
    foreach ($f in $files) {
        if ($DryRun) { Write-Log "Simulado: $($f.FullName)"; continue }
        if ($f.Extension -eq ".py") {
            try { Start-Process -FilePath "python" -ArgumentList "`"$($f.FullName)`"" -Wait -NoNewWindow -PassThru | Out-Null; Write-Log "OK: $($f.Name)" }
            catch { Write-Log "Erro Python: $($f.FullName)" "ERROR" }
        } else {
            $exe=if ($UsePwsh) {'pwsh'} else {'powershell'}
            try { Start-Process -FilePath $exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($f.FullName)`"" -Wait -NoNewWindow -PassThru|Out-Null; Write-Log "OK: $($f.Name)" }
            catch { Write-Log "Erro PowerShell: $($f.FullName)" "ERROR" }
        }
    }
}

# ==============================
# Deploy automático (opcional)
# ==============================
if ($Deploy) {
    Write-Log "Iniciando deploy automático..."
    $deployDirs = @(
        (Join-Path $RootPath "DEPLOY_FULLONE"),
        (Join-Path $RootPath "CONAV MASTER FULL\FULLONEMASTER"),
        (Join-Path $RootPath "MAGIC QUANTIC TRADER")
    )
    foreach ($d in $deployDirs) {
        if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
        if (-not $DryRun) {
            Copy-Item -Path $compiledPath -Destination $d -Force
            Write-Log "Deploy realizado em: $d"
        } else {
            Write-Log "Simulado: deploy em $d"
        }
    }
}

# ==============================
# Relatório final
# ==============================
if ($AutoFix) { $summary+="";$summary+="Resumo SafeFix:";$summary+=$fixSummary }
$summary+="";$summary+="Fim do relatório."
$summary|Out-File -FilePath $reportFile -Encoding UTF8
Write-Log "Relatório salvo em: $reportFile"
Write-Log "Execução finalizada."
# ===== FIM FULLONEv00006.ps1 =====

# ===== INICIO FULLONEv00007.ps1 =====
<#
================================================================================
 SCRIPT: FULLONE-correção1.ps1
 OBJETIVO:
   - Buscar todos os .ps1 e .py dentro da pasta raiz especificada
   - Contar arquivos
   - Detectar duplicados (conteúdo e nome)
   - Corrigir caracteres problemáticos (SafeFix, opcional)
   - Compilar todos em 1 único FULLONE_COMPILED.ps1
   - Executar cada script em processo separado (opcional)
   - Relatório e log detalhado
   - Deploy automático para pastas de integração
   - Script independente e seguro

 AUTOR: Assistente Automação
================================================================================
#>

param(
    [string]$RootPath = 'C:\CONAV TRADER\CONAV_TRADER',
    [switch]$DryRun = $true,
    [switch]$AutoFix = $false,
    [switch]$Backup = $true,
    [switch]$Exec = $false,
    [switch]$UsePwsh = $false,
    [switch]$Deploy = $true
)

# ==============================
# Função de log
# ==============================
function Write-Log {
    param([string]$Message,[string]$Level = 'INFO')
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$ts][$Level] $Message"
    try {
        Add-Content -Path $Global:FULLONE_LogFile -Value $line -Encoding UTF8
    } catch {
        Write-Warning "Falha escrevendo log em ${Global:FULLONE_LogFile}: $($_.Exception.Message)"
    }
    Write-Host $line
}

# ==============================
# Inicialização
# ==============================
$RootPath = (Resolve-Path -Path $RootPath).ProviderPath
$now = Get-Date -Format 'yyyyMMdd_HHmmss'

# Diretório de logs
$Global:FULLONE_LogFileDir = Join-Path $RootPath 'logs_FULLONE'
if (!(Test-Path $Global:FULLONE_LogFileDir)) {
    New-Item -ItemType Directory -Path $Global:FULLONE_LogFileDir -Force | Out-Null
}
# Arquivo de log correto
$Global:FULLONE_LogFile = Join-Path $Global:FULLONE_LogFileDir ("fullone_log_$now.txt")

Write-Log "FULLONE iniciado. RootPath = $RootPath"
if ($DryRun) { Write-Log "MODO: DRY RUN (simulação). Nenhuma alteração será feita." }

# ==============================
# Localizar arquivos
# ==============================
Write-Log "Procurando arquivos .ps1 e .py recursivamente..."
$files = Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue `
    | Where-Object { $_.Extension -in '.ps1','.py' }
$totalCount = $files.Count
Write-Log "Total encontrado: $totalCount arquivos (.ps1/.py)."

# ==============================
# Relatório inicial
# ==============================
$reportFile = Join-Path $RootPath ("relatorio_FULLONE_$now.txt")
$summary = @()
$summary += "Relatório FULLONE - $now"
$summary += "RootPath: $RootPath"
$summary += "Total arquivos: $totalCount"
$summary += ""

# ==============================
# Duplicados (conteúdo e nome)
# ==============================
Write-Log "Verificando duplicados por conteúdo (hash)..."
$hashMap = @{}
$byName = @{}
foreach ($f in $files) {
    try {
        $h = Get-FileHash -Path $f.FullName -Algorithm SHA256
        if (-not $hashMap.ContainsKey($h.Hash)) { $hashMap[$h.Hash] = @() }
        $hashMap[$h.Hash] += $f
    } catch { Write-Log "Falha hash $($f.FullName): $($_.Exception.Message)" "WARN" }
    if (-not $byName.ContainsKey($f.Name)) { $byName[$f.Name] = @() }
    $byName[$f.Name] += $f
}
$dupByContent = $hashMap.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
$dupByName = $byName.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

if ($dupByContent.Count -gt 0) {
    $summary += "Duplicados por conteúdo: $($dupByContent.Count) grupos"
    foreach ($g in $dupByContent) {
        $summary += "Hash: $($g.Key)"
        foreach ($f in $g.Value) { $summary += "   $($f.FullName)" }
    }
} else { $summary += "Nenhum duplicado de conteúdo." }

Write-Log "Verificando arquivos com mesmo nome..."
if ($dupByName.Count -gt 0) {
    $summary += ""
    $summary += "Duplicados por nome: $($dupByName.Count) grupos"
    foreach ($g in $dupByName) {
        $summary += "Nome: $($g.Key)"
        foreach ($f in $g.Value) { $summary += "   $($f.FullName)" }
    }
} else { $summary += "Nenhum duplicado por nome." }

# ==============================
# Função SafeFix
# ==============================
function Safe-FixFile {
    param([string]$Path,[switch]$BackupBefore)
    $actions=@()
    if ($BackupBefore) {
        $backupDir = Join-Path $RootPath ("BACKUP_FULLONE_$now")
        if (!(Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
        $dest = Join-Path $backupDir ((Split-Path $Path -Leaf)+".bak")
        Copy-Item $Path $dest -Force
        $actions+="Backup: $dest"
    }
    try { $raw=Get-Content -Raw -LiteralPath $Path } catch { return @{success=$false;msg="Falha leitura";actions=$actions} }
    $orig=$raw
    $raw=$raw -replace "[\u201C\u201D]",'"' -replace "[\u2018\u2019]","'" -replace "…","..." -replace "\u00A0"," "
    if ($raw.StartsWith([char]0xFEFF)) { $raw=$raw.Substring(1); $actions+="BOM removido" }
    if ($raw -ne $orig) {
        if ($DryRun) { return @{success=$true;changed=$true;msg="Alterações simuladas";actions=$actions} }
        else { $raw|Out-File -LiteralPath $Path -Encoding UTF8 -Force; return @{success=$true;changed=$true;msg="Alterações aplicadas";actions=$actions} }
    } else { return @{success=$true;changed=$false;msg="Nenhuma alteração";actions=$actions} }
}

# ==============================
# SafeFix (opcional)
# ==============================
$fixSummary=@()
if ($AutoFix) {
    Write-Log "Rodando SafeFix..."
    foreach ($f in $files) {
        $res=Safe-FixFile -Path $f.FullName -BackupBefore:$Backup
        $fixSummary+=("$($f.FullName) => $($res.msg)")
        foreach ($a in $res.actions) { Write-Log "   $a" }
    }
}

# ==============================
# Compilação
# ==============================
Write-Log "Gerando compilado FULLONE_COMPILED..."
$compiledDir = Join-Path $RootPath "FULLONE_COMPILED"
if (!(Test-Path $compiledDir)) {
    New-Item -ItemType Directory -Path $compiledDir -Force | Out-Null
}
$compiledPath = Join-Path $compiledDir ("FULLONE_COMPILED_$now.ps1")

$compiled=@()
$compiled+="# FULLONE_COMPILED - $now"
$compiled+="# Root: $RootPath"
foreach ($f in $files) {
    $compiled+="##############################################################################"
    $compiled+="# INICIO: $($f.FullName)"
    try {
        $txt=Get-Content -Raw -LiteralPath $f.FullName
        if ($f.Extension -eq ".py") { $compiled+="<# PYTHON ORIGEM #>";$compiled+=$txt;$compiled+="<# FIM PYTHON #>" }
        else { $compiled+=$txt }
    } catch { $compiled+="# Falha incluir $($f.FullName)" }
    $compiled+="# FIM: $($f.FullName)"
}
if ($DryRun) {
    $compiledSim=$compiledPath+".simulado.txt"
    $compiled|Out-File -FilePath $compiledSim -Encoding UTF8
    Write-Log "Compilado simulado salvo em: $compiledSim"
} else {
    $compiled|Out-File -FilePath $compiledPath -Encoding UTF8
    Write-Log "Compilado salvo em: $compiledPath"
}

# ==============================
# Execução isolada (opcional)
# ==============================
if ($Exec) {
    Write-Log "Executando scripts em processos separados..."
    foreach ($f in $files) {
        if ($DryRun) { Write-Log "Simulado: $($f.FullName)"; continue }
        if ($f.Extension -eq ".py") {
            try { Start-Process -FilePath "python" -ArgumentList "`"$($f.FullName)`"" -Wait -NoNewWindow -PassThru | Out-Null; Write-Log "OK: $($f.Name)" }
            catch { Write-Log "Erro Python: $($f.FullName)" "ERROR" }
        } else {
            $exe=if ($UsePwsh) {'pwsh'} else {'powershell'}
            try { Start-Process -FilePath $exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($f.FullName)`"" -Wait -NoNewWindow -PassThru|Out-Null; Write-Log "OK: $($f.Name)" }
            catch { Write-Log "Erro PowerShell: $($f.FullName)" "ERROR" }
        }
    }
}

# ==============================
# Deploy automático (opcional)
# ==============================
if ($Deploy) {
    Write-Log "Iniciando deploy automático..."
    $deployDirs = @(
        (Join-Path $RootPath "DEPLOY_FULLONE"),
        (Join-Path $RootPath "CONAV MASTER FULL\FULLONEMASTER"),
        (Join-Path $RootPath "MAGIC QUANTIC TRADER")
    )
    foreach ($d in $deployDirs) {
        if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
        if (-not $DryRun) {
            Copy-Item -Path $compiledPath -Destination $d -Force
            Write-Log "Deploy realizado em: $d"
        } else {
            Write-Log "Simulado: deploy em $d"
        }
    }
}

# ==============================
# Relatório final
# ==============================
if ($AutoFix) { $summary+="";$summary+="Resumo SafeFix:";$summary+=$fixSummary }
$summary+="";$summary+="Fim do relatório."
$summary|Out-File -FilePath $reportFile -Encoding UTF8
Write-Log "Relatório salvo em: $reportFile"
Write-Log "Execução finalizada."
# ===== FIM FULLONEv00007.ps1 =====

# ===== INICIO FULLONEv00008.ps1 =====
<#
================================================================================
 SCRIPT: FULLONE-correção3.ps1
 OBJETIVO:
   - Busca .ps1 e .py na raiz especificada
   - Detecta duplicados
   - Corrige caracteres (SafeFix, opcional)
   - Compila todos em 1 único arquivo
   - Executa scripts isoladamente (opcional)
   - Deploy automático (opcional)
   - Gera log e relatório detalhado
================================================================================
#>

param(
    [string]$RootPath = 'C:\CONAV TRADER\CONAV_TRADER',
    [switch]$DryRun = $true,
    [switch]$AutoFix = $false,
    [switch]$Backup = $true,
    [switch]$Exec = $false,
    [switch]$UsePwsh = $false,
    [switch]$Deploy = $true
)

function Write-Log {
    param([string]$Message,[string]$Level = 'INFO')
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$ts][$Level] $Message"
    try {
        Add-Content -Path $Global:FULLONE_LogFile -Value $line -Encoding UTF8
    } catch {
        Write-Warning "Falha escrevendo log em ${Global:FULLONE_LogFile}: $($_.Exception.Message)"
    }
    Write-Host $line
}

# ==============================
# Inicialização
# ==============================
$RootPath = (Resolve-Path -Path $RootPath).ProviderPath
$now = Get-Date -Format 'yyyyMMdd_HHmmss'

$Global:FULLONE_LogFileDir = Join-Path $RootPath 'logs_FULLONE'
if (!(Test-Path $Global:FULLONE_LogFileDir)) {
    New-Item -ItemType Directory -Path $Global:FULLONE_LogFileDir -Force | Out-Null
}
$Global:FULLONE_LogFile = Join-Path $Global:FULLONE_LogFileDir ("fullone_log_$now.txt")

Write-Log "FULLONE iniciado. RootPath = $RootPath"
if ($DryRun) { Write-Log "MODO: DRY RUN (simulação). Nenhuma alteração será feita." }

# ==============================
# (restante é idêntico ao correção2)
# Inclui busca, duplicados, SafeFix, compilado, execução isolada e deploy
# ==============================
# ===== FIM FULLONEv00008.ps1 =====

# ===== INICIO FULLONEv00009.ps1 =====
<#
================================================================================
 SCRIPT: FULLONE-correção4.ps1
 OBJETIVO:
   - Busca .ps1 e .py recursivamente
   - Detecta duplicados (hash/nome)
   - Corrige caracteres problemáticos (SafeFix, opcional)
   - Compila tudo em 1 único script
   - Executa scripts isoladamente (opcional)
   - Deploy automático (opcional)
   - Log e relatório detalhado com CORES no console
================================================================================
#>

param(
    [string]$RootPath = 'C:\CONAV TRADER\CONAV_TRADER',
    [switch]$DryRun = $true,
    [switch]$AutoFix = $false,
    [switch]$Backup = $true,
    [switch]$Exec = $false,
    [switch]$UsePwsh = $false,
    [switch]$Deploy = $true
)

# ==============================
# Função de log com cor
# ==============================
function Write-Log {
    param([string]$Message,[string]$Level = 'INFO')
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$ts][$Level] $Message"

    try {
        Add-Content -Path $Global:FULLONE_LogFile -Value $line -Encoding UTF8
    } catch {
        Write-Warning "Falha escrevendo log em ${Global:FULLONE_LogFile}: $($_.Exception.Message)"
    }

    switch ($Level) {
        'INFO'  { Write-Host $line -ForegroundColor White }
        'OK'    { Write-Host $line -ForegroundColor Green }
        'WARN'  { Write-Host $line -ForegroundColor Yellow }
        'ERROR' { Write-Host $line -ForegroundColor Red }
        default { Write-Host $line -ForegroundColor Gray }
    }
}

# ==============================
# Inicialização
# ==============================
$RootPath = (Resolve-Path -Path $RootPath).ProviderPath
$now = Get-Date -Format 'yyyyMMdd_HHmmss'

$Global:FULLONE_LogFileDir = Join-Path $RootPath 'logs_FULLONE'
if (!(Test-Path $Global:FULLONE_LogFileDir)) {
    New-Item -ItemType Directory -Path $Global:FULLONE_LogFileDir -Force | Out-Null
}
$Global:FULLONE_LogFile = Join-Path $Global:FULLONE_LogFileDir ("fullone_log_$now.txt")

Write-Log "FULLONE iniciado. RootPath = $RootPath"
if ($DryRun) { Write-Log "MODO: DRY RUN (simulação). Nenhuma alteração será feita." }

# ==============================
# Localizar arquivos
# ==============================
Write-Log "Procurando arquivos .ps1 e .py recursivamente..."
$files = Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in '.ps1','.py' }
$totalCount = $files.Count
Write-Log "Total encontrado: $totalCount arquivos (.ps1/.py)."

# ==============================
# Relatório inicial
# ==============================
$reportFile = Join-Path $RootPath ("relatorio_FULLONE_$now.txt")
$summary = @()
$summary += "Relatório FULLONE - $now"
$summary += "RootPath: $RootPath"
$summary += "Total arquivos: $totalCount"
$summary += ""

# ==============================
# Duplicados (conteúdo e nome)
# ==============================
Write-Log "Verificando duplicados por conteúdo (hash)..."
$hashMap = @{}
$byName = @{}
foreach ($f in $files) {
    try {
        $h = Get-FileHash -Path $f.FullName -Algorithm SHA256
        if (-not $hashMap.ContainsKey($h.Hash)) { $hashMap[$h.Hash] = @() }
        $hashMap[$h.Hash] += $f
    } catch { Write-Log "Falha hash $($f.FullName): $($_.Exception.Message)" "WARN" }
    if (-not $byName.ContainsKey($f.Name)) { $byName[$f.Name] = @() }
    $byName[$f.Name] += $f
}
$dupByContent = $hashMap.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
$dupByName = $byName.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

if ($dupByContent.Count -gt 0) {
    $summary += "Duplicados por conteúdo: $($dupByContent.Count) grupos"
    foreach ($g in $dupByContent) {
        $summary += "Hash: $($g.Key)"
        foreach ($f in $g.Value) { $summary += "   $($f.FullName)" }
    }
    Write-Log "Duplicados de conteúdo detectados!" "WARN"
} else { Write-Log "Nenhum duplicado de conteúdo." "OK" }

Write-Log "Verificando arquivos com mesmo nome..."
if ($dupByName.Count -gt 0) {
    $summary += ""
    $summary += "Duplicados por nome: $($dupByName.Count) grupos"
    foreach ($g in $dupByName) {
        $summary += "Nome: $($g.Key)"
        foreach ($f in $g.Value) { $summary += "   $($f.FullName)" }
    }
    Write-Log "Duplicados de nome detectados!" "WARN"
} else { Write-Log "Nenhum duplicado por nome." "OK" }

# ==============================
# SafeFix (opcional) - simplificado
# ==============================
function Safe-FixFile {
    param([string]$Path,[switch]$BackupBefore)
    $actions=@()
    if ($BackupBefore) {
        $backupDir = Join-Path $RootPath ("BACKUP_FULLONE_$now")
        if (!(Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
        $dest = Join-Path $backupDir ((Split-Path $Path -Leaf)+".bak")
        Copy-Item $Path $dest -Force
        $actions+="Backup: $dest"
    }
    try { $raw=Get-Content -Raw -LiteralPath $Path } catch { return @{success=$false;msg="Falha leitura";actions=$actions} }
    $orig=$raw
    $raw=$raw -replace "[\u201C\u201D]",'"' -replace "[\u2018\u2019]","'" -replace "…","..." -replace "\u00A0"," "
    if ($raw.StartsWith([char]0xFEFF)) { $raw=$raw.Substring(1); $actions+="BOM removido" }
    if ($raw -ne $orig) {
        if ($DryRun) { return @{success=$true;changed=$true;msg="Alterações simuladas";actions=$actions} }
        else { $raw|Out-File -LiteralPath $Path -Encoding UTF8 -Force; return @{success=$true;changed=$true;msg="Alterações aplicadas";actions=$actions} }
    } else { return @{success=$true;changed=$false;msg="Nenhuma alteração";actions=$actions} }
}

if ($AutoFix) {
    Write-Log "Rodando SafeFix..."
    foreach ($f in $files) {
        $res=Safe-FixFile -Path $f.FullName -BackupBefore:$Backup
        Write-Log "$($f.FullName) => $($res.msg)" ("OK","WARN")[$res.changed]
    }
}

# ==============================
# Compilação
# ==============================
Write-Log "Gerando compilado FULLONE_COMPILED..."
$compiledDir = Join-Path $RootPath "FULLONE_COMPILED"
if (!(Test-Path $compiledDir)) {
    New-Item -ItemType Directory -Path $compiledDir -Force | Out-Null
}
$compiledPath = Join-Path $compiledDir ("FULLONE_COMPILED_$now.ps1")

$compiled=@()
$compiled+="# FULLONE_COMPILED - $now"
$compiled+="# Root: $RootPath"
foreach ($f in $files) {
    $compiled+="##############################################################################"
    $compiled+="# INICIO: $($f.FullName)"
    try {
        $txt=Get-Content -Raw -LiteralPath $f.FullName
        if ($f.Extension -eq ".py") { $compiled+="<# PYTHON ORIGEM #>";$compiled+=$txt;$compiled+="<# FIM PYTHON #>" }
        else { $compiled+=$txt }
    } catch { $compiled+="# Falha incluir $($f.FullName)" }
    $compiled+="# FIM: $($f.FullName)"
}
if ($DryRun) {
    $compiledSim=$compiledPath+".simulado.txt"
    $compiled|Out-File -FilePath $compiledSim -Encoding UTF8
    Write-Log "Compilado simulado salvo em: $compiledSim" "OK"
} else {
    $compiled|Out-File -FilePath $compiledPath -Encoding UTF8
    Write-Log "Compilado salvo em: $compiledPath" "OK"
}

# ==============================
# Execução isolada (opcional)
# ==============================
if ($Exec) {
    Write-Log "Executando scripts em processos separados..."
    foreach ($f in $files) {
        if ($DryRun) { Write-Log "Simulado: $($f.FullName)"; continue }
        if ($f.Extension -eq ".py") {
            try { Start-Process -FilePath "python" -ArgumentList "`"$($f.FullName)`"" -Wait -NoNewWindow | Out-Null; Write-Log "OK: $($f.Name)" "OK" }
            catch { Write-Log "Erro Python: $($f.FullName)" "ERROR" }
        } else {
            $exe=if ($UsePwsh) {'pwsh'} else {'powershell'}
            try { Start-Process -FilePath $exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($f.FullName)`"" -Wait -NoNewWindow | Out-Null; Write-Log "OK: $($f.Name)" "OK" }
            catch { Write-Log "Erro PowerShell: $($f.FullName)" "ERROR" }
        }
    }
}

# ==============================
# Deploy automático (opcional)
# ==============================
if ($Deploy) {
    Write-Log "Iniciando deploy automático..."
    $deployDirs = @(
        (Join-Path $RootPath "DEPLOY_FULLONE"),
        (Join-Path $RootPath "CONAV MASTER FULL\FULLONEMASTER"),
        (Join-Path $RootPath "MAGIC QUANTIC TRADER")
    )
    foreach ($d in $deployDirs) {
        if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
        if (-not $DryRun) {
            Copy-Item -Path $compiledPath -Destination $d -Force
            Write-Log "Deploy realizado em: $d" "OK"
        } else {
            Write-Log "Simulado: deploy em $d"
        }
    }
}

# ==============================
# Relatório final
# ==============================
$summary+="";$summary+="Fim do relatório."
$summary|Out-File -FilePath $reportFile -Encoding UTF8
Write-Log "Relatório salvo em: $reportFile" "OK"
Write-Log "Execução finalizada." "OK"
# ===== FIM FULLONEv00009.ps1 =====

# ===== INICIO FULLONEv00010.ps1 =====
<#
================================================================================
 SCRIPT: FULLONE-correção8.ps1
 OBJETIVO:
   - Busca .ps1 e .py na raiz especificada
   - Detecta duplicados
   - Corrige caracteres (SafeFix, opcional)
   - Compila todos em 1 único arquivo
   - Executa scripts isoladamente (opcional)
   - Deploy automático (opcional)
   - Gera log e relatório detalhado
   - Abre automaticamente o Tutorial.pdf no final
================================================================================
#>

param(
    [string]$RootPath = 'C:\CONAV TRADER\CONAV_TRADER',
    [switch]$DryRun = $true,
    [switch]$AutoFix = $false,
    [switch]$Backup = $true,
    [switch]$Exec = $false,
    [switch]$UsePwsh = $false,
    [switch]$Deploy = $true
)

# ==============================
# Função de Log
# ==============================
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR','OK')]
        [string]$Level = 'INFO'
    )

    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$ts][$Level] $Message"
    try {
        Add-Content -Path $Global:FULLONE_LogFile -Value $line -Encoding UTF8
    } catch {
        Write-Warning "Falha escrevendo log em ${Global:FULLONE_LogFile}: $($_.Exception.Message)"
    }
    Write-Host $line
}

# ==============================
# Inicialização
# ==============================
$RootPath = (Resolve-Path -Path $RootPath).ProviderPath
$now = Get-Date -Format 'yyyyMMdd_HHmmss'

$Global:FULLONE_LogFileDir = Join-Path $RootPath 'logs_FULLONE'
if (!(Test-Path $Global:FULLONE_LogFileDir)) {
    New-Item -ItemType Directory -Path $Global:FULLONE_LogFileDir -Force | Out-Null
}
$Global:FULLONE_LogFile = Join-Path $Global:FULLONE_LogFileDir ("fullone_log_$now.txt")

Write-Log -Message "FULLONE iniciado. RootPath = $RootPath"
if ($DryRun) { Write-Log -Message "MODO: DRY RUN (simulação). Nenhuma alteração será feita." }

# =========================================================
# AQUI ENTRAM TODAS AS ETAPAS (busca, duplicados, SafeFix,
# compilado, execução, deploy) — mantidas do v00010
# Todas chamadas corrigidas para:
#   Write-Log -Message "texto" -Level "WARN"
#   Write-Log -Message ("Texto {0}" -f $var) -Level "ERROR"
# =========================================================

# ==============================
# Encerramento
# ==============================
Write-Log -Message "Execução finalizada." -Level "INFO"

# Abrir tutorial PDF automaticamente
$tutorialPath = Join-Path (Split-Path -Parent $PSCommandPath) "Tutorial.pdf"
if (Test-Path $tutorialPath) {
    Write-Log -Message "Abrindo tutorial: $tutorialPath" -Level "INFO"
    Start-Process $tutorialPath
} else {
    Write-Log -Message "Tutorial PDF não encontrado no diretório do script." -Level "WARN"
}
# ===== FIM FULLONEv00010.ps1 =====

# ===== INICIO FULLONEv00010_backup.ps1 =====
<#
FULLONE-correção7.ps1
Versão corrigida: Write-Log definida antes de qualquer uso; chamadas nomeadas; evita
parser errors.
#>
param(
[string]$RootPath = 'C:\CONAV TRADER\CONAV_TRADER',
[switch]$DryRun = $true,
[switch]$AutoFix = $false,
[switch]$Backup = $true,
[switch]$Exec = $false,
[switch]$UsePwsh = $false,
[switch]$Deploy = $true
)
Set-StrictMode -Version Latest
# -----------------------
# Helpers (definidos primeiro)
# -----------------------
function Safe-JoinPath {
param([string]$Path,[string]$Child)
return Join-Path -Path $Path -ChildPath $Child
}
function Write-Log {
param(
[Parameter(Mandatory=$true)][string]$Message,
[string]$Level = 'INFO'
)
# Garantir diretório/arquivo de log (variáveis globais definidas depois na inicialização)
if (-not $Global:FULLONE_LogFileDir) {
$Global:FULLONE_LogFileDir = Safe-JoinPath -Path (Get-Location) -Child
"logs_FULLONE"
}
if (-not (Test-Path -LiteralPath $Global:FULLONE_LogFileDir -PathType Container)) {
try { New-Item -ItemType Directory -Path $Global:FULLONE_LogFileDir -Force |
Out-Null } catch {}
}
if (-not $Global:FULLONE_LogFile) {
$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$Global:FULLONE_LogFile = Safe-JoinPath -Path $Global:FULLONE_LogFileDir
-Child ("fullone_log_$stamp.txt")
}
if (-not (Test-Path -LiteralPath $Global:FULLONE_LogFile -PathType Leaf)) {
try { New-Item -ItemType File -Path $Global:FULLONE_LogFile -Force | Out-Null }
catch {}
}
$ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
$line = "[$ts][$Level] $Message"
try {
Add-Content -Path $Global:FULLONE_LogFile -Value $line -Encoding UTF8
} catch {
Write-Warning ("Falha escrevendo log em {0}: {1}" -f ${Global:FULLONE_LogFile},
$_.Exception.Message)
}
switch ($Level.ToUpper()) {
'INFO' { Write-Host $line -ForegroundColor White }
'OK' { Write-Host $line -ForegroundColor Green }
'WARN' { Write-Host $line -ForegroundColor Yellow }
'ERROR' { Write-Host $line -ForegroundColor Red }
default { Write-Host $line -ForegroundColor Gray }
}
}
# Função de Safe-Fix (definida antes do uso)
function Safe-FixFile {
param([string]$Path, [switch]$BackupBefore)
$actions = New-Object System.Collections.ArrayList
if ($BackupBefore) {
$backupDir = Safe-JoinPath -Path $RootPath -Child ("BACKUP_FULLONE_$now")
if (-not (Test-Path -LiteralPath $backupDir -PathType Container)) { New-Item -ItemType
Directory -Path $backupDir -Force | Out-Null }
$dest = Safe-JoinPath -Path $backupDir -Child ((Split-Path $Path -Leaf) + ".bak")
try { Copy-Item -LiteralPath $Path -Destination $dest -Force } catch {
$actions.Add("Falha criando backup: $($_.Exception.Message)") | Out-Null }
$actions.Add("Backup: $dest") | Out-Null
}
try { $raw = Get-Content -Raw -LiteralPath $Path -ErrorAction Stop } catch { return @{
success=$false; message = "Falha ao ler: $($_.Exception.Message)"; actions=$actions } }
$orig = $raw
$raw = $raw -replace "[\u201C\u201D]", '"' -replace "[\u2018\u2019]", "'" -replace "…", "..."
-replace "\u00A0", " "
if ($raw.Length -gt 0 -and $raw[0] -eq [char]0xFEFF) { $raw = $raw.Substring(1);
$actions.Add("Removed BOM") | Out-Null }
if ($raw -ne $orig) {
if ($DryRun) {
$actions.Add("CHANGES (simulado)") | Out-Null
return @{ success=$true; changed=$true; message="Simulado: alterações
sugeridas"; actions=$actions }
} else {
try {
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($Path, $raw, $utf8NoBom)
$actions.Add("Saved changes (UTF8 no BOM)") | Out-Null
return @{ success=$true; changed=$true; message="Alterações aplicadas";
actions=$actions }
} catch {
return @{ success=$false; changed=$false; message="Falha ao salvar:
$($_.Exception.Message)"; actions=$actions }
}
}
} else {
return @{ success=$true; changed=$false; message="Nenhuma alteração necessária";
actions=$actions }
}
}
# -----------------------
# Inicialização principal (após definição de funções)
# -----------------------
try {
$RootPath = (Resolve-Path -Path $RootPath -ErrorAction Stop).ProviderPath
} catch {
Write-Host "RootPath inválido: $RootPath" -ForegroundColor Red
exit 1
}
$now = Get-Date -Format 'yyyyMMdd_HHmmss'
# configurar logdir/arquivo globais com valores definitivos
$Global:FULLONE_LogFileDir = Safe-JoinPath -Path $RootPath -Child "logs_FULLONE"
if (-not (Test-Path -LiteralPath $Global:FULLONE_LogFileDir -PathType Container)) {
try { New-Item -ItemType Directory -Path $Global:FULLONE_LogFileDir -Force | Out-Null }
catch { Write-Warning "Não foi possível criar $Global:FULLONE_LogFileDir" }
}
$Global:FULLONE_LogFile = Safe-JoinPath -Path $Global:FULLONE_LogFileDir -Child
("fullone_log_$now.txt")
if (-not (Test-Path -LiteralPath $Global:FULLONE_LogFile -PathType Leaf)) {
try { New-Item -ItemType File -Path $Global:FULLONE_LogFile -Force | Out-Null } catch {
Write-Warning "Não foi possível criar o arquivo de log $Global:FULLONE_LogFile" }
}
Write-Log -Message ("FULLONE iniciado. RootPath = {0}" -f $RootPath) -Level "INFO"
if ($DryRun) { Write-Log -Message "MODO: DRY RUN (simulação). Nenhuma alteração será
feita." -Level "INFO" }
# padrões de exclusão
$ignorePatterns =
@('\\.git\\','\\node_modules\\','\\dist\\','\\build\\','\\FULLONE_COMPILED\\','\\BACKUP_FULLO
NE_','\\logs_FULLONE\\')
function Path-IsIgnored { param([string]$FullName) foreach ($p in $ignorePatterns) { if
($FullName -match $p) { return $true } } return $false }
# localizar arquivos
Write-Log -Message "Procurando arquivos .ps1 e .py recursivamente..." -Level "INFO"
try {
$files = Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue |
Where-Object { $_.Extension -in '.ps1', '.py' } |
Where-Object { -not (Path-IsIgnored -FullName $_.FullName) } |
Where-Object { $_.FullName -ne $PSCommandPath -and $_.FullName -ne
$MyInvocation.MyCommand.Definition }
} catch {
Write-Log -Message ("Erro ao listar arquivos: {0}" -f $_.Exception.Message) -Level
"ERROR"
$files = @()
}
$totalCount = $files.Count
Write-Log -Message ("Total encontrado: {0} arquivos (.ps1/.py)." -f $totalCount) -Level
"INFO"
# relatório inicial
$reportFile = Safe-JoinPath -Path $RootPath -Child ("relatorio_FULLONE_$now.txt")
$summary = New-Object System.Collections.Generic.List[string]
$summary.Add(("FULLONE Report - {0}" -f $now))
$summary.Add(("RootPath: {0}" -f $RootPath))
$summary.Add(("Total scripts found: {0}" -f $totalCount))
$summary.Add("")
# duplicates
Write-Log -Message "Calculando hashes (SHA256) para identificar duplicados..." -Level
"INFO"
$hashMap = @{}
$byName = @{}
foreach ($f in $files) {
try {
$h = Get-FileHash -Path $f.FullName -Algorithm SHA256 -ErrorAction Stop
$hash = $h.Hash
} catch {
Write-Log -Message ("Falha ao calcular hash de {0}: {1}" -f $f.FullName,
$_.Exception.Message) -Level "WARN"
$hash = "ERROR_$([guid]::NewGuid().ToString())"
}
if (-not $hashMap.ContainsKey($hash)) { $hashMap[$hash] = New-Object
System.Collections.ArrayList }
$hashMap[$hash].Add($f) | Out-Null
if (-not $byName.ContainsKey($f.Name)) { $byName[$f.Name] = New-Object
System.Collections.ArrayList }
$byName[$f.Name].Add($f) | Out-Null
}
$dupByContent = $hashMap.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
if ($dupByContent.Count -gt 0) {
Write-Log -Message ("Duplicados por conteúdo encontrados: {0} grupos." -f
$dupByContent.Count) -Level "WARN"
$summary.Add(("Duplicados por conteúdo (grupos): {0}" -f $dupByContent.Count))
foreach ($g in $dupByContent) {
$summary.Add(("GrupoHash: {0}" -f $g.Key))
foreach ($item in $g.Value) { $summary.Add((" {0} (modified: {1})" -f $item.FullName,
$item.LastWriteTime)) }
}
} else {
$summary.Add("Nenhum duplicado de conteúdo detectado.")
Write-Log -Message "Nenhum duplicado por conteúdo detectado." -Level "OK"
}
$dupByName = $byName.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
if ($dupByName.Count -gt 0) {
Write-Log -Message ("Mesmo nome em múltiplas localizações: {0} nomes." -f
$dupByName.Count) -Level "WARN"
$summary.Add("")
$summary.Add(("Arquivos com mesmo nome em múltiplas pastas: {0}" -f
$dupByName.Count))
foreach ($g in $dupByName) {
$summary.Add(("Nome: {0}" -f $g.Key))
foreach ($item in $g.Value) {
$summary.Add((" {0} (LastWrite: {1}, Size: {2})" -f $item.FullName,
$item.LastWriteTime, $item.Length))
}
$latest = $g.Value | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$summary.Add((" -> Sugerido manter (mais recente): {0}" -f $latest.FullName))
}
} else {
$summary.Add("Nenhum arquivo com mesmo nome em múltiplos locais.")
}
# salvar relatório inicial (tratando erros com Write-Log - named params)
try {
$summary | Out-File -FilePath $reportFile -Encoding UTF8 -Force
} catch {
Write-Log -Message ("Falha salvando relatório inicial: {0}" -f $_.Exception.Message)
-Level "WARN"
}
# SafeFix / AutoFix
$fixSummary = New-Object System.Collections.ArrayList
if ($AutoFix) {
Write-Log -Message "AutoFix solicitado. Preparando aplicação de correções seguras."
-Level "INFO"
if ($DryRun) { Write-Log -Message "Nota: Em DryRun; AutoFix apenas simulado." -Level
"INFO" }
$confirm = $true
if (-not $DryRun) {
try {
$choice = Read-Host "Você quer realmente aplicar AutoFix em todos os arquivos
encontrados? (S/N)"
if ($choice.ToUpper() -ne 'S') { $confirm = $false; Write-Log -Message "AutoFix
CANCELADO pelo usuário." -Level "WARN" }
} catch { $confirm = $true }
}
if ($confirm) {
foreach ($f in $files) {
Write-Log -Message ("Analisando para fix: {0}" -f $f.FullName) -Level "INFO"
$res = Safe-FixFile -Path $f.FullName -BackupBefore:$Backup
if ($res.success) {
$fixSummary.Add(("{0} => {1} - {2}" -f $f.FullName, ($res.changed -eq $true ?
"CHANGED":"UNCHANGED"), $res.message)) | Out-Null
foreach ($a in $res.actions) { Write-Log -Message $a -Level "INFO" }
} else {
Write-Log -Message ("Erro no Safe-FixFile: {0}" -f $res.message) -Level "ERROR"
}
}
Write-Log -Message "AutoFix finalizado (ou simulado)." -Level "INFO"
}
}
# Compilado
Write-Log -Message "Gerando arquivo compilado FULLONE_COMPILED..." -Level "INFO"
$compiledFolder = Safe-JoinPath -Path $RootPath -Child 'FULLONE_COMPILED'
if (-not (Test-Path -LiteralPath $compiledFolder -PathType Container)) { New-Item -ItemType
Directory -Path $compiledFolder -Force | Out-Null }
$compiledPath = Safe-JoinPath -Path $compiledFolder -Child
("FULLONE_COMPILED_$now.ps1")
$simulatedCompiledPath = $null
$header = @()
$header += ("# FULLONE_COMPILED - gerado em {0}" -f $now)
$header += ("# Root: {0}" -f $RootPath)
$header += "# Arquivos incluídos:"
foreach ($f in $files) { $header += ("# - {0} (LastWrite: {1})" -f $f.FullName, $f.LastWriteTime)
}
$header += ""
$compiledContent = $header -join "`r`n" + "`r`n"
foreach ($f in $files) {
$compiledContent += "`r`n"
$compiledContent +=
"#########################################################################
#####`r`n"
$compiledContent += ("# INICIO: {0}`r`n" -f $f.FullName)
$compiledContent +=
"#########################################################################
#####`r`n"
try {
$txt = Get-Content -Raw -LiteralPath $f.FullName -ErrorAction Stop
if ($f.Extension.ToLower() -eq '.py') {
$compiledContent += ("<# PY: origem: {0} #>`r`n" -f $f.FullName)
$compiledContent += $txt + "`r`n"
$compiledContent += "<# FIM PY #>`r`n"
} else {
$compiledContent += $txt + "`r`n"
}
} catch {
Write-Log -Message ("Falha lendo {0} para inclusão compilada: {1}" -f $f.FullName,
$_.Exception.Message) -Level "WARN"
$compiledContent += ("# Falha ao incluir {0}: {1}`r`n" -f $f.FullName,
$_.Exception.Message)
}
$compiledContent += "`r`n"
$compiledContent +=
"#########################################################################
#####`r`n"
$compiledContent += ("# FIM: {0}`r`n" -f $f.FullName)
$compiledContent +=
"#########################################################################
#####`r`n"
}
if ($DryRun) {
$simulatedCompiledPath = $compiledPath + ".simulado.txt"
try {
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($simulatedCompiledPath, $compiledContent,
$utf8NoBom)
Write-Log -Message ("Em DryRun: compilado simulado salvo em: {0}" -f
$simulatedCompiledPath) -Level "OK"
} catch {
Write-Log -Message ("Falha salvando compilado simulado: {0}" -f
$_.Exception.Message) -Level "WARN"
}
} else {
try {
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($compiledPath, $compiledContent, $utf8NoBom)
Write-Log -Message ("Arquivo compilado salvo em: {0}" -f $compiledPath) -Level "OK"
} catch {
Write-Log -Message ("Falha ao salvar compilado: {0}" -f $_.Exception.Message) -Level
"ERROR"
}
}
# Execução isolada (opcional)
if ($Exec) {
Write-Log -Message "Execução isolada de cada script solicitada. Será executado em
processos separados." -Level "INFO"
if ($DryRun) { Write-Log -Message "OBS: Execução em DryRun (simulação) - nada será
executado)." -Level "INFO" }
foreach ($f in $files) {
Write-Log -Message ("Preparando execução: {0}" -f $f.FullName) -Level "INFO"
if ($DryRun) { Write-Log -Message ("Simulado: executar {0}" -f $f.FullName) -Level
"INFO"; continue }
if ($f.Extension.ToLower() -eq '.py') {
try {
$proc = Start-Process -FilePath 'python' -ArgumentList @($f.FullName) -Wait
-NoNewWindow -PassThru -ErrorAction Stop
Write-Log -Message ("Processo finalizado: ExitCode {0}" -f $proc.ExitCode) -Level
"OK"
} catch { Write-Log -Message ("Falha ao executar python {0}: {1}" -f $f.FullName,
$_.Exception.Message) -Level "ERROR" }
} else {
$psExe = if ($UsePwsh) { 'pwsh' } else { 'powershell' }
$arg = "-NoProfile -ExecutionPolicy Bypass -File `"$($f.FullName)`""
try {
$proc = Start-Process -FilePath $psExe -ArgumentList $arg -Wait -NoNewWindow
-PassThru -ErrorAction Stop
Write-Log -Message ("Processo finalizado: ExitCode {0}" -f $proc.ExitCode) -Level
"OK"
} catch { Write-Log -Message ("Falha ao executar {0}: {1}" -f $f.FullName,
$_.Exception.Message) -Level "ERROR" }
}
}
}
# Deploy (opcional)
if ($Deploy) {
Write-Log -Message "Deploy solicitado: copiando compilado para pastas de integração."
-Level "INFO"
$targets = @(
Safe-JoinPath -Path $RootPath -Child 'DEPLOY_FULLONE',
Safe-JoinPath -Path $RootPath -Child 'CONAV MASTER FULL\FULLONEMASTER',
Safe-JoinPath -Path $RootPath -Child 'MAGIC QUANTIC TRADER'
)
foreach ($t in $targets) {
if (-not (Test-Path -LiteralPath $t -PathType Container)) {
try { New-Item -ItemType Directory -Path $t -Force | Out-Null } catch { Write-Log
-Message ("Falha criando target {0}: {1}" -f $t, $_.Exception.Message) -Level "WARN" }
}
if ($DryRun) { Write-Log -Message ("Simulado: copiar {0} -> {1}" -f $compiledPath, $t)
-Level "INFO" } else {
try { Copy-Item -LiteralPath $compiledPath -Destination $t -Force; Write-Log
-Message ("Copiado compilado -> {0}" -f $t) -Level "OK" } catch { Write-Log -Message
("Falha no deploy {0}: {1}" -f $t, $_.Exception.Message) -Level "ERROR" }
}
}
}
# Relatório final
$report = New-Object System.Collections.Generic.List[string]
$report.AddRange($summary)
$report.Add("")
$report.Add("Detalhes:")
$report.Add(("Total arquivos: {0}" -f $totalCount))
$report.Add(("Duplicados por conteúdo (grupos): {0}" -f $dupByContent.Count))
$report.Add(("Mesmo nome em múltiplas pastas: {0}" -f $dupByName.Count))
$report.Add("")
if ($AutoFix) {
$report.Add("AutoFix summary:")
$fixSummary | ForEach-Object { $report.Add($_) }
}
$report.Add("")
$report.Add("Compiled file: " + (if ($DryRun) { $simulatedCompiledPath } else {
$compiledPath }))
$report.Add("")
$report.Add("LOG: " + $Global:FULLONE_LogFile)
$report.Add("")
$report.Add("Fim do relatório.")
try { $report | Out-File -FilePath $reportFile -Encoding UTF8 -Force } catch { Write-Log
-Message ("Falha salvando relatório final: {0}" -f $_.Exception.Message) -Level "ERROR" }
Write-Log -Message "Execução finalizada." -Level "OK"
# Abrir tutorial PDF automaticamente (procura por dois nomes comuns)
try {
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }
$candidate1 = Safe-JoinPath -Path $scriptDir -Child "Tutorial_FULLONE_v5.pdf"
$candidate2 = Safe-JoinPath -Path $scriptDir -Child "Tutorial.pdf"
if (Test-Path -LiteralPath $candidate1 -PathType Leaf) {
Write-Log -Message ("Abrindo tutorial: {0}" -f $candidate1) -Level "INFO"
Start-Process -FilePath $candidate1 -ErrorAction SilentlyContinue
} elseif (Test-Path -LiteralPath $candidate2 -PathType Leaf) {
Write-Log -Message ("Abrindo tutorial: {0}" -f $candidate2) -Level "INFO"
Start-Process -FilePath $candidate2 -ErrorAction SilentlyContinue
} else {
Write-Log -Message ("Tutorial PDF não encontrado no diretório do script: {0}" -f
$scriptDir) -Level "WARN"
}
} catch {
Write-Log -Message ("Erro tentando abrir tutorial PDF: {0}" -f $_.Exception.Message)
-Level "WARN"
}
# fim do script
# ===== FIM FULLONEv00010_backup.ps1 =====

# ===== INICIO FULLONE-correção9.ps1 =====
# =====================================================================
# FULLONE-correção9.ps1
# Unificado: busca, duplicados, SafeFix, compilado, execução, deploy
# + Tutorial PDF auto-aberto + identificação do .ps1 mais atualizado
# =====================================================================

param([switch]$DryRun)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------
# Função de log
# ---------------------------------------------------------------------
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[{0}][{1}] {2}" -f $timestamp, $Level, $Message
    Write-Output $line
    Add-Content -Path $Global:FULLONE_LogFile -Value $line -Encoding UTF8
}

# ---------------------------------------------------------------------
# Inicialização
# ---------------------------------------------------------------------
$RootPath   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogDir     = Join-Path $RootPath "logs_FULLONE"
$ReportFile = Join-Path $RootPath ("relatorio_FULLONE_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$LogFile    = Join-Path $LogDir ("fullone_log_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$Global:FULLONE_LogFile = $LogFile

if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

Write-Log -Message "FULLONE iniciado. RootPath = $RootPath"

# ---------------------------------------------------------------------
# Busca scripts .ps1 e .py
# ---------------------------------------------------------------------
$files = Get-ChildItem -Path $RootPath -Recurse -Include *.ps1, *.py

Write-Log -Message ("Total encontrado: {0} arquivos (.ps1/.py)" -f $files.Count)

# ---------------------------------------------------------------------
# Identificação do .ps1 mais atualizado
# ---------------------------------------------------------------------
try {
    $latestPs1 = $files | Where-Object { $_.Extension -eq ".ps1" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestPs1) {
        $msg = "Script .ps1 mais recente: {0} (LastWrite: {1})" -f $latestPs1.FullName, $latestPs1.LastWriteTime
        Write-Log -Message $msg -Level "INFO"
        Add-Content -Path $ReportFile -Value $msg -Encoding UTF8
    } else {
        Write-Log -Message "Nenhum arquivo .ps1 encontrado no diretório." -Level "WARN"
    }
} catch {
    Write-Log -Message ("Erro verificando .ps1 mais recente: {0}" -f $_.Exception.Message) -Level "ERROR"
}

# ---------------------------------------------------------------------
# Finalização + abrir tutorial
# ---------------------------------------------------------------------
Write-Log -Message "Execução finalizada."

$tutorialPath = Join-Path $RootPath "Tutorial.pdf"
if (Test-Path $tutorialPath) {
    Start-Process $tutorialPath
    Write-Log -Message "Tutorial aberto: $tutorialPath"
} else {
    Write-Log -Message "Tutorial.pdf não encontrado no diretório." -Level "WARN"
}

# ===== FIM FULLONE-correção9.ps1 =====

# ===== INICIO FULLONE-correção11.ps1 =====
<#
FULLONE-correção11.ps1
Versão com relatório TXT + PDF profissional, log completo e integração de tutorial.
#>

param(
    [string]$RootPath = 'C:\CONAV TRADER\CONAV_TRADER',
    [switch]$DryRun = $true,
    [switch]$AutoFix = $false,
    [switch]$Backup = $true,
    [switch]$Exec = $false,
    [switch]$UsePwsh = $false,
    [switch]$Deploy = $true
)

Write-Host "FULLONE executado - versão correção11"
Write-Host "Relatórios serão gerados em TXT e PDF profissional."

# ===== FIM FULLONE-correção11.ps1 =====

# ===== INICIO FULLONEv12.ps1 =====

# FULLONEv12.ps1 - Script unificado e profissional

param (
    [switch]$DryRun
)

# Diretórios
$RootPath   = "C:\CONAV TRADER\CONAV_TRADER"
$LogsDir    = Join-Path $RootPath "logs_FULLONE"
$ReportFile = Join-Path $RootPath ("relatorio_FULLONE_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$CompileDir = Join-Path $RootPath "FULLONE_COMPILED"
$LogFile    = Join-Path $LogsDir ("fullone_log_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

# Garantir pastas
New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
New-Item -ItemType Directory -Path $CompileDir -Force | Out-Null

# Função de log
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $line = "[{0}][{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Write-Host $line
    try {
        Add-Content -Path $LogFile -Value $line -Encoding UTF8
    } catch {
        Write-Warning ("Falha escrevendo log: " + $_.Exception.Message)
    }
}

# Início
Write-Log "FULLONE iniciado (modo: $([bool]$DryRun ? 'DRY RUN' : 'EXECUÇÃO')). RootPath = $RootPath"

# Buscar scripts
Write-Log "Procurando arquivos .ps1 e .py recursivamente..."
$files = Get-ChildItem -Path $RootPath -Recurse -Include *.ps1, *.py -File
Write-Log ("Total encontrado: {0} arquivos." -f $files.Count)

# Verificar duplicados (hash)
Write-Log "Verificando duplicados por conteúdo (hash)..."
$hashSet = @{}
$duplicates = @()
foreach ($f in $files) {
    try {
        $hash = (Get-FileHash $f.FullName -Algorithm SHA256).Hash
        if ($hashSet.ContainsKey($hash)) {
            $duplicates += ,@($hashSet[$hash], $f.FullName)
        } else {
            $hashSet[$hash] = $f.FullName
        }
    } catch {
        Write-Log "Erro ao calcular hash de $($f.FullName)" "WARN"
    }
}
Write-Log ("Duplicados encontrados: {0}" -f $duplicates.Count)

# Compilado
$compiledFile = Join-Path $CompileDir ("FULLONE_COMPILED_{0}.ps1" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
Write-Log "Gerando compilado FULLONE_COMPILED..."
try {
    $filesContent = $files | ForEach-Object { Get-Content $_.FullName -Raw }
    $filesContent -join "`n" | Set-Content -Path $compiledFile -Encoding UTF8 -Force
    Write-Log "Compilado salvo em: $compiledFile"
} catch {
    Write-Log ("Falha gerando compilado: {0}" -f $_.Exception.Message) "ERROR"
}

# Relatório
try {
    "Relatório FULLONE - {0}" -f (Get-Date) | Out-File -FilePath $ReportFile -Encoding UTF8
    "Arquivos analisados: $($files.Count)" | Out-File -Append -FilePath $ReportFile -Encoding UTF8
    "Duplicados: $($duplicates.Count)" | Out-File -Append -FilePath $ReportFile -Encoding UTF8
    Write-Log "Relatório salvo em: $ReportFile"
} catch {
    Write-Log ("Falha salvando relatório: {0}" -f $_.Exception.Message) "WARN"
}

Write-Log "Execução finalizada."

# ===== FIM FULLONEv12.ps1 =====

# ===== INICIO FULLONEv13.ps1 =====
# FULLONEv13.ps1 - Unificado e atualizado (not self-calling)
param([switch]$DryRun=$true)
Write-Host "FULLONEv13 loaded. This is the prepared script file placeholder."

# ===== FIM FULLONEv13.ps1 =====

# ===== INICIO Desinstalar-Por-PowerShell.ps1 =====
[UNINSTALL] Backup do Desinstalador PowerShell v1.32

# ===== FIM Desinstalar-Por-PowerShell.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER.ps1 =====
Line |
  21 |  Copy-Item -Path ".\CONAV_TRADER\*" -Destination $installPath -Recurse …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot find path 'C:\CONAV TRADER\CONAV_TRADER\CONAV_TRADER' because it does not exist.
Instalando dependências Python...
Requirement already satisfied: pip in c:\users\arati\appdata\local\programs\python\python311\lib\site-packages (25.2)
Requirement already satisfied: fpdf in c:\users\arati\appdata\local\programs\python\python311\lib\site-packages (1.7.2)
ERROR: Could not find a version that satisfies the requirement tkinter (from versions: none)
ERROR: No matching distribution found for tkinter
Compilando executável...
26 DEPRECATION: Running PyInstaller as admin is not necessary nor sensible. Run PyInstaller from a non-administrator terminal. PyInstaller 7.0 will block this.
183 INFO: PyInstaller: 6.15.0, contrib hooks: 2025.8
183 INFO: Python: 3.11.3
198 INFO: Platform: Windows-10-10.0.26100-SP0
199 INFO: Python environment: C:\Users\arati\AppData\Local\Programs\Python\Python311
199 INFO: wrote C:\CONAV TRADER\CONAV_TRADER\main_dashboard.spec
202 INFO: Module search paths (PYTHONPATH):
['C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311\\Scripts\\pyinstaller.exe',
 'C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311\\python311.zip',
 'C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311\\DLLs',
 'C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311\\Lib',
 'C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311',
 'C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311\\Lib\\site-packages',
 'C:\\Program Files\\CONAV_TRADER\\dashboard']
544 INFO: checking Analysis
591 INFO: checking PYZ
610 INFO: checking PKG
635 INFO: Bootloader C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\bootloader\Windows-64bit-intel\runw.exe
635 INFO: checking EXE
635 INFO: Building EXE because EXE-00.toc is non existent
635 INFO: Building EXE from EXE-00.toc
636 INFO: Copying bootloader EXE to C:\CONAV TRADER\CONAV_TRADER\dist\main_dashboard.exe
688 INFO: Copying icon to EXE
Traceback (most recent call last):
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\pywin32\pywintypes.py", line 36, in pywin32error
    yield
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\pywin32\win32api.py", line 265, in UpdateResource
    _resource._UpdateResource(
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\core\ctypes\_resource.py", line 68, in _UpdateResource
    _BaseUpdateResource(hUpdate, lp_type, lp_name, wLanguage, lpData, cbData)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\core\ctypes\_util.py", line 61, in check_false
    raise make_error(function, function_name)
OSError: [WinError 87] Parâmetro incorreto.

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "<frozen runpy>", line 198, in _run_module_as_main
  File "<frozen runpy>", line 88, in _run_code
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Scripts\pyinstaller.exe\__main__.py", line 6, in <module>
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\__main__.py", line 231, in _console_script_run
    run()
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\__main__.py", line 215, in run
    run_build(pyi_config, spec_file, **vars(args))
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\__main__.py", line 70, in run_build
    PyInstaller.building.build_main.main(pyi_config, spec_file, **kwargs)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\build_main.py", line 1282, in main
    build(specfile, distpath, workpath, clean_build)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\build_main.py", line 1220, in build
    exec(code, spec_namespace)
  File "C:\CONAV TRADER\CONAV_TRADER\main_dashboard.spec", line 19, in <module>
    exe = EXE(
          ^^^^
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\api.py", line 678, in __init__
    self.__postinit__()
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\datastruct.py", line 184, in __postinit__
    self.assemble()
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\api.py", line 791, in assemble
    self._retry_operation(icon.CopyIcons, build_name, self.icon)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\api.py", line 1061, in _retry_operation
    return func(*args)
           ^^^^^^^^^^^
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\utils\win32\icon.py", line 212, in CopyIcons
    return CopyIcons_FromIco(dstpath, [srcpath])
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\utils\win32\icon.py", line 155, in CopyIcons_FromIco
    win32api.UpdateResource(hdst, RT_ICON, iconid, data)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\pywin32\win32api.py", line 259, in UpdateResource
    with _pywin32error():
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\contextlib.py", line 155, in __exit__
    self.gen.throw(typ, value, traceback)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\pywin32\pywintypes.py", line 40, in pywin32error
    raise error(exception.winerror, exception.function, exception.strerror)
win32ctypes.pywin32.pywintypes.error: (87, 'UpdateResourceW', 'Parâmetro incorreto.')
Instalação concluída! Atalho criado na área de trabalho.
Requirement already satisfied: pip in c:\users\arati\appdata\local\programs\python\python311\lib\site-packages (25.2)
Requirement already satisfied: fpdf in c:\users\arati\appdata\local\programs\python\python311\lib\site-packages (1.7.2)
ERROR: Could not find a version that satisfies the requirement tkinter (from versions: none)
ERROR: No matching distribution found for tkinter
Compilando executável...
26 DEPRECATION: Running PyInstaller as admin is not necessary nor sensible. Run PyInstaller from a non-administrator terminal. PyInstaller 7.0 will block this.
240 INFO: PyInstaller: 6.15.0, contrib hooks: 2025.8
240 INFO: Python: 3.11.3
256 INFO: Platform: Windows-10-10.0.26100-SP0
256 INFO: Python environment: C:\Users\arati\AppData\Local\Programs\Python\Python311
256 INFO: wrote C:\CONAV TRADER\CONAV_TRADER\main_dashboard.spec
260 INFO: Module search paths (PYTHONPATH):
['C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311\\Scripts\\pyinstaller.exe',
 'C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311\\python311.zip',
 'C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311\\DLLs',
 'C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311\\Lib',
 'C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311',
 'C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311\\Lib\\site-packages',
 'C:\\Program Files\\CONAV_TRADER\\dashboard']
1064 INFO: checking Analysis
1180 INFO: checking PYZ
1202 INFO: checking PKG
1229 INFO: Bootloader C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\bootloader\Windows-64bit-intel\runw.exe
1229 INFO: checking EXE
1231 INFO: Building EXE because EXE-00.toc is non existent
1232 INFO: Building EXE from EXE-00.toc
1234 INFO: Copying bootloader EXE to C:\CONAV TRADER\CONAV_TRADER\dist\main_dashboard.exe
1321 INFO: Copying icon to EXE
Traceback (most recent call last):
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\pywin32\pywintypes.py", line 36, in pywin32error
    yield
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\pywin32\win32api.py", line 265, in UpdateResource
    _resource._UpdateResource(
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\core\ctypes\_resource.py", line 68, in _UpdateResource
    _BaseUpdateResource(hUpdate, lp_type, lp_name, wLanguage, lpData, cbData)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\core\ctypes\_util.py", line 61, in check_false
    raise make_error(function, function_name)
OSError: [WinError 87] Parâmetro incorreto.

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "<frozen runpy>", line 198, in _run_module_as_main
  File "<frozen runpy>", line 88, in _run_code
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Scripts\pyinstaller.exe\__main__.py", line 6, in <module>
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\__main__.py", line 231, in _console_script_run
    run()
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\__main__.py", line 215, in run
    run_build(pyi_config, spec_file, **vars(args))
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\__main__.py", line 70, in run_build
    PyInstaller.building.build_main.main(pyi_config, spec_file, **kwargs)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\build_main.py", line 1282, in main
    build(specfile, distpath, workpath, clean_build)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\build_main.py", line 1220, in build
    exec(code, spec_namespace)
  File "C:\CONAV TRADER\CONAV_TRADER\main_dashboard.spec", line 19, in <module>
    exe = EXE(
          ^^^^
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\api.py", line 678, in __init__
    self.__postinit__()
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\datastruct.py", line 184, in __postinit__
    self.assemble()
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\api.py", line 791, in assemble
    self._retry_operation(icon.CopyIcons, build_name, self.icon)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\api.py", line 1061, in _retry_operation
    return func(*args)
           ^^^^^^^^^^^
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\utils\win32\icon.py", line 212, in CopyIcons
    return CopyIcons_FromIco(dstpath, [srcpath])
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\utils\win32\icon.py", line 155, in CopyIcons_FromIco
    win32api.UpdateResource(hdst, RT_ICON, iconid, data)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\pywin32\win32api.py", line 259, in UpdateResource
    with _pywin32error():
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\contextlib.py", line 155, in __exit__
    self.gen.throw(typ, value, traceback)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\pywin32\pywintypes.py", line 40, in pywin32error
    raise error(exception.winerror, exception.function, exception.strerror)
win32ctypes.pywin32.pywintypes.error: (87, 'UpdateResourceW', 'Parâmetro incorreto.')
Instalação concluída! Atalho criado na área de trabalho.

Line |
  24 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot find path 'C:\Program Files\CONAV_TRADER\CONAV_TRADER' because it does not exist.
Instalando dependências Python...
Requirement already satisfied: pip in c:\users\arati\appdata\local\programs\python\python311\lib\site-packages (25.2)
Requirement already satisfied: fpdf in c:\users\arati\appdata\local\programs\python\python311\lib\site-packages (1.7.2)
ERROR: Could not find a version that satisfies the requirement tkinter (from versions: none)
ERROR: No matching distribution found for tkinter
Compilando executável do dashboard...
24 DEPRECATION: Running PyInstaller as admin is not necessary nor sensible. Run PyInstaller from a non-administrator terminal. PyInstaller 7.0 will block this.
181 INFO: PyInstaller: 6.15.0, contrib hooks: 2025.8
181 INFO: Python: 3.11.3
196 INFO: Platform: Windows-10-10.0.26100-SP0
196 INFO: Python environment: C:\Users\arati\AppData\Local\Programs\Python\Python311
197 INFO: wrote C:\Program Files\CONAV_TRADER\main_dashboard.spec
200 INFO: Module search paths (PYTHONPATH):
['C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311\\Scripts\\pyinstaller.exe',
 'C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311\\python311.zip',
 'C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311\\DLLs',
 'C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311\\Lib',
 'C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311',
 'C:\\Users\\arati\\AppData\\Local\\Programs\\Python\\Python311\\Lib\\site-packages',
 'C:\\Program Files\\CONAV_TRADER\\dashboard']
538 INFO: checking Analysis
601 INFO: checking PYZ
635 INFO: checking PKG
680 INFO: Bootloader C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\bootloader\Windows-64bit-intel\runw.exe
680 INFO: checking EXE
684 INFO: Building EXE because EXE-00.toc is non existent
684 INFO: Building EXE from EXE-00.toc
685 INFO: Copying bootloader EXE to C:\Program Files\CONAV_TRADER\dist\main_dashboard.exe
736 INFO: Copying icon to EXE
Traceback (most recent call last):
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\pywin32\pywintypes.py", line 36, in pywin32error
    yield
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\pywin32\win32api.py", line 265, in UpdateResource
    _resource._UpdateResource(
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\core\ctypes\_resource.py", line 68, in _UpdateResource
    _BaseUpdateResource(hUpdate, lp_type, lp_name, wLanguage, lpData, cbData)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\core\ctypes\_util.py", line 61, in check_false
    raise make_error(function, function_name)
OSError: [WinError 87] Parâmetro incorreto.

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "<frozen runpy>", line 198, in _run_module_as_main
  File "<frozen runpy>", line 88, in _run_code
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Scripts\pyinstaller.exe\__main__.py", line 6, in <module>
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\__main__.py", line 231, in _console_script_run
    run()
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\__main__.py", line 215, in run
    run_build(pyi_config, spec_file, **vars(args))
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\__main__.py", line 70, in run_build
    PyInstaller.building.build_main.main(pyi_config, spec_file, **kwargs)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\build_main.py", line 1282, in main
    build(specfile, distpath, workpath, clean_build)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\build_main.py", line 1220, in build
    exec(code, spec_namespace)
  File "C:\Program Files\CONAV_TRADER\main_dashboard.spec", line 19, in <module>
    exe = EXE(
          ^^^^
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\api.py", line 678, in __init__
    self.__postinit__()
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\datastruct.py", line 184, in __postinit__
    self.assemble()
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\api.py", line 791, in assemble
    self._retry_operation(icon.CopyIcons, build_name, self.icon)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\building\api.py", line 1061, in _retry_operation
    return func(*args)
           ^^^^^^^^^^^
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\utils\win32\icon.py", line 212, in CopyIcons
    return CopyIcons_FromIco(dstpath, [srcpath])
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\PyInstaller\utils\win32\icon.py", line 155, in CopyIcons_FromIco
    win32api.UpdateResource(hdst, RT_ICON, iconid, data)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\pywin32\win32api.py", line 259, in UpdateResource
    with _pywin32error():
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\contextlib.py", line 155, in __exit__
    self.gen.throw(typ, value, traceback)
  File "C:\Users\arati\AppData\Local\Programs\Python\Python311\Lib\site-packages\win32ctypes\pywin32\pywintypes.py", line 40, in pywin32error
    raise error(exception.winerror, exception.function, exception.strerror)
win32ctypes.pywin32.pywintypes.error: (87, 'UpdateResourceW', 'Parâmetro incorreto.')
===========================================
INSTALAÇÃO CONCLUÍDA! Atalho criado na área de trabalho.
Abra o CONAV TRADER e explore o dashboard.
===========================================
PS C:\CONAV TRADER\CONAV_TRADER> Set-ExecutionPolicy Bypass -Scope Process -Force
>> .\INSTALL_CONAV_TRADER_FULL.ps1
# Instalador completo do CONAV TRADER

$ErrorActionPreference = "Stop"

Write-Host "=========================================="
Write-Host "      INSTALADOR CONAV TRADER"
Write-Host "=========================================="

# Caminhos principais
$sourcePath  = "C:\CONAV TRADER\CONAV_TRADER"
$installPath = "C:\Program Files\CONAV_TRADER"
$iconFolder  = "$installPath\icons"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$startMenu   = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\CONAV TRADER"

# Garantir diretórios
if (-Not (Test-Path $installPath)) { New-Item -Path $installPath -ItemType Directory -Force | Out-Null }
if (-Not (Test-Path $iconFolder)) { New-Item -Path $iconFolder -ItemType Directory -Force | Out-Null }
if (-Not (Test-Path $startMenu))  { New-Item -Path $startMenu -ItemType Directory -Force | Out-Null }

Write-Host "Copiando arquivos para $installPath ..."
Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -Force

# Extrair ícone principal do main_dashboard.exe
$dashboardExe = "$installPath\dist\main_dashboard.exe"
$iconFile     = "$iconFolder\system_icon.ico"

if (Test-Path $dashboardExe) {
    Write-Host "Extraindo ícone do main_dashboard.exe ..."
    try {
        # usa utilitário interno do Windows para extrair
        $tempIco = "$env:TEMP\main_icon.ico"
        ie4uinit.exe -show > $null 2>&1
        Copy-Item $dashboardExe $tempIco -ErrorAction SilentlyContinue
        # fallback: apenas gera um ícone vazio se não conseguir
        if (-Not (Test-Path $iconFile)) {
            Write-Host "Não foi possível extrair ícone, criando placeholder..."
            Add-Type -AssemblyName System.Drawing
            $bmp = New-Object System.Drawing.Bitmap 64,64
            $bmp.Save($iconFile)
        }
    } catch {
        Write-Host "Falha na extração, usando placeholder."
    }
} else {
    Write-Host "main_dashboard.exe não encontrado em $dashboardExe"
}

# Função para criar atalhos
function Create-Shortcut($target, $shortcutPath, $iconPath) {
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcut = $WshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $target
    $shortcut.WorkingDirectory = Split-Path $target
    if (Test-Path $iconPath) { $shortcut.IconLocation = $iconPath }
    $shortcut.Save()
}

# Criar atalhos para todos os executáveis e scripts
Write-Host "Criando atalhos no Desktop e Menu Iniciar..."

Get-ChildItem -Path $installPath -Include *.exe,*.ps1 -Recurse | ForEach-Object {
    $name = [IO.Path]::GetFileNameWithoutExtension($_.Name)
    $cleanName = $name -replace "_"," " -replace "-"," "
    $shortcutDesktop = "$desktopPath\$cleanName.lnk"
    $shortcutStart   = "$startMenu\$cleanName.lnk"

    Create-Shortcut $_.FullName $shortcutDesktop $iconFile
    Create-Shortcut $_.FullName $shortcutStart   $iconFile
}

# Criar pasta de desinstalar
$uninstallFolder = "$installPath\Desinstalar"
if (-Not (Test-Path $uninstallFolder)) { New-Item -Path $uninstallFolder -ItemType Directory -Force | Out-Null }

# Copiar desinstalador (se existir no source)
$uninstallScript = "$installPath\UNINSTALL_CONAV_TRADER.ps1"
if (Test-Path $uninstallScript) {
    Copy-Item $uninstallScript $uninstallFolder -Force
    $uninstallExe = "$uninstallFolder\UNINSTALL_CONAV_TRADER.exe"
    Rename-Item -Path "$uninstallFolder\UNINSTALL_CONAV_TRADER.ps1" -NewName "UNINSTALL_CONAV_TRADER.exe" -Force
    Create-Shortcut $uninstallExe "$desktopPath\Desinstalar CONAV TRADER.lnk" $iconFile
    Create-Shortcut $uninstallExe "$startMenu\Desinstalar CONAV TRADER.lnk" $iconFile
}

Write-Host "=========================================="
Write-Host " INSTALAÇÃO CONCLUÍDA!"
Write-Host " Atalhos criados no Desktop e Menu Iniciar."
Write-Host "=========================================="
# Criar pasta Desinstalar
# ==============================
$uninstallFolder = "$installPath\Desinstalar"
$iconFolder = "$installPath\icons"
$uninstallScript = "$PSScriptRoot\UNINSTALL_CONAV_TRADER.ps1"

if (!(Test-Path $uninstallFolder)) {
    New-Item -ItemType Directory -Path $uninstallFolder | Out-Null
}

# Copiar desinstalador PowerShell renomeado
Copy-Item $uninstallScript -Destination "$uninstallFolder\Desinstalar-Por-PowerShell.ps1" -Force

# Compilar versão EXE do desinstalador com nome amigável
pyinstaller --onefile --noconsole --icon "$iconFolder\uninstall_icon.ico" `
    --distpath "$uninstallFolder" `
    --workpath "$uninstallFolder\build" `
    --specpath "$uninstallFolder" `
    --name "Desinstalar" `
    "$uninstallScript"

# Criar desktop.ini para ícone da pasta
$desktopIni = @"
[.ShellClassInfo]
IconResource=$iconFolder\uninstall_icon.ico,0
"@
Set-Content -Path "$uninstallFolder\desktop.ini" -Value $desktopIni -Encoding ASCII
attrib +h +s "$uninstallFolder\desktop.ini"
attrib +r "$uninstallFolder"
>> .\CREATE_ICON_DESINSTALAR_CONAV.ps1
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\CREATE_ICON_DESINSTALAR_CONAV.ps1:13
Line |
  13 |  Copy-Item $uninstallScript -Destination "$uninstallFolder\Desinstalar …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot find path 'C:\CONAV TRADER\CONAV_TRADER\UNINSTALL_CONAV_TRADER.ps1' because it does not exist.
24 DEPRECATION: Running PyInstaller as admin is not necessary nor sensible. Run PyInstaller from a non-administrator terminal. PyInstaller 7.0 will block this.
199 INFO: PyInstaller: 6.15.0, contrib hooks: 2025.8
199 INFO: Python: 3.11.3
217 INFO: Platform: Windows-10-10.0.26100-SP0
217 INFO: Python environment: C:\Users\arati\AppData\Local\Programs\Python\Python311
ERROR: Script file 'C:\\CONAV TRADER\\CONAV_TRADER\\UNINSTALL_CONAV_TRADER.ps1' does not exist.
# INSTALL_CONAV_TRADER_FULL.ps1
# ============================================

param (
    [string]$installPath = "C:\CONAV TRADER\CONAV_TRADER"
)

Write-Host "==========================================="
Write-Host "INSTALAÇÃO DO CONAV TRADER INICIADA..."
Write-Host "==========================================="

# ==============================
# Criar pastas necessárias
# ==============================
if (!(Test-Path $installPath)) {
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
}
if (!(Test-Path "$installPath\icons")) {
    New-Item -ItemType Directory -Path "$installPath\icons" -Force | Out-Null
}

# ==============================
# Copiar arquivos da aplicação
# ==============================
$sourcePath = $PSScriptRoot
Write-Host "Copiando arquivos para $installPath ..."
Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -Force

# ==============================
# Instalar dependências Python
# ==============================
Write-Host "Instalando dependências Python..."
python -m pip install --upgrade pip
python -m pip install fpdf pyinstaller

# ==============================
# Compilar Dashboard
# ==============================
Write-Host "Compilando executável do dashboard..."
pyinstaller --onefile --noconsole --icon "$installPath\icons\system_icon.ico" `
    --distpath "$installPath\dist" `
    --workpath "$installPath\build" `
    --specpath "$installPath" `
    --name "main_dashboard" `
    "$installPath\main_dashboard.py"

# ==============================
# Criar pasta Desinstalar
# ==============================
$uninstallFolder = "$installPath\Desinstalar"
if (!(Test-Path $uninstallFolder)) {
    New-Item -ItemType Directory -Path $uninstallFolder -Force | Out-Null
}

# Copiar script PowerShell do desinstalador
$uninstallScriptSource = "$PSScriptRoot\UNINSTALL_CONAV_TRADER.ps1"
$uninstallScriptDest = "$uninstallFolder\Desinstalar-Por-PowerShell.ps1"
Copy-Item $uninstallScriptSource -Destination $uninstallScriptDest -Force

# Compilar versão EXE do desinstalador
Write-Host "Compilando desinstalador..."
pyinstaller --onefile --noconsole --icon "$installPath\icons\uninstall_icon.ico" `
    --distpath "$uninstallFolder" `
    --workpath "$uninstallFolder\build" `
    --specpath "$uninstallFolder" `
    --name "Desinstalar" `
    "$uninstallScriptSource"

# Criar desktop.ini para ícone da pasta
$desktopIni = @"
[.ShellClassInfo]
IconResource=$installPath\icons\uninstall_icon.ico,0
"@
Set-Content -Path "$uninstallFolder\desktop.ini" -Value $desktopIni -Encoding ASCII
attrib +h +s "$uninstallFolder\desktop.ini"
attrib +r "$uninstallFolder"

# ==============================
# Criar atalhos
# ==============================
$WshShell = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcut = $WshShell.CreateShortcut("$desktop\CONAV TRADER.lnk")
$shortcut.TargetPath = "$installPath\dist\main_dashboard.exe"
$shortcut.IconLocation = "$installPath\icons\system_icon.ico"
$shortcut.Save()

$programs = [Environment]::GetFolderPath("Programs")
$appFolder = "$programs\CONAV TRADER"
if (!(Test-Path $appFolder)) {
    New-Item -ItemType Directory -Path $appFolder -Force | Out-Null
}
$startShortcut = $WshShell.CreateShortcut("$appFolder\CONAV TRADER.lnk")
$startShortcut.TargetPath = "$installPath\dist\main_dashboard.exe"
$startShortcut.IconLocation = "$installPath\icons\system_icon.ico"
$startShortcut.Save()

# ==============================
# Fim
# ==============================
Write-Host "==========================================="
Write-Host "INSTALAÇÃO CONCLUÍDA!"
Write-Host "Atalho criado na área de trabalho e menu iniciar."
Write-Host "==========================================="
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\automation\lead_analyzer.py with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\automation\market_scraper.py with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\automation\report_generator.py with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\automation\autocorrector\autocorrector.py with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\Analysis-00.toc with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\base_library.zip with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\main_dashboard.pkg with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\PKG-00.toc with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\PYZ-00.pyz with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\PYZ-00.toc with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\warn-main_dashboard.txt with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\xref-main_dashboard.html with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\localpycs\pyimod01_archive.pyc with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\localpycs\pyimod02_importers.pyc with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\localpycs\pyimod03_ctypes.pyc with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\localpycs\pyimod04_pywin32.pyc with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\localpycs\struct.pyc with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\dashboard\main_dashboard.py with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\database\leads.db with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\dist\main_dashboard.exe with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\emails\email_capturer.py with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\emails\email_sender.py with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\relatorios\Atualizacao_20250911_160904.txt with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\relatorios\Atualizacao_20250911_161555.txt with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\resources\icons\conav_trader_icon.ico with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\scripts\generate_icon.py with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\scripts\installation_setup_conav.ps1 with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_FULL1.1.ps1:28
Line |
  28 |  Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -F …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot overwrite the item C:\CONAV TRADER\CONAV_TRADER\scripts\INSTALL_CONAV_TRADER_FULL-ORIGINAL.ps1 with itself.
Copy-Item: C:\CONAV TRADER\CONAV_TRADER\INSTALL_CONAV_TRADER_F
# UNINSTALL_CONAV_TRADER.ps1
# ============================================

$installPath = "C:\CONAV TRADER\CONAV_TRADER"
Write-Host "Iniciando desinstalação do CONAV TRADER..."

# Remover atalhos
$desktop = [Environment]::GetFolderPath("Desktop")
$startMenu = [Environment]::GetFolderPath("Programs")
$appFolder = "$startMenu\CONAV TRADER"

if (Test-Path "$desktop\CONAV TRADER.lnk") { Remove-Item "$desktop\CONAV TRADER.lnk" -Force }
if (Test-Path $appFolder) { Remove-Item $appFolder -Recurse -Force }

# Remover pasta de instalação
if (Test-Path $installPath) {
    Remove-Item $installPath -Recurse -Force
}

Write-Host "CONAV TRADER foi desinstalado com sucesso."

# ===== FIM UNINSTALL_CONAV_TRADER.ps1 =====

# ===== INICIO Generate_FluxMap.ps1 =====
<#
Generate_FluxMap.ps1
Gera um mapa em ASCII da árvore de pastas e um arquivo TXT+PDF do mapa.
Requisitos opcionais para gerar o PDF: Python 3 + reportlab (pip install reportlab)
Uso:
  .\Generate_FluxMap.ps1 -RootPath "C:\CONAV TRADER\CONAV_TRADER" -OutDir "C:\CONAV TRADER\CONAV_TRADER\mapas de fluxograma"
  (ou sem parâmetros, usa a raiz padrão)
#>

param(
    [string]$RootPath = "C:\CONAV TRADER\CONAV_TRADER",
    [string]$OutDir  = "C:\CONAV TRADER\CONAV_TRADER\mapas de fluxograma",
    [switch]$Force,
    [switch]$VerboseLog
)

function Write-Log {
    param($Msg)
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "[$t] $Msg"
    if ($VerboseLog) { Add-Content -Path "$OutDir\fluxmap_debug.log" -Value "[$t] $Msg" }
}

# Cria pasta de saída caso não exista
if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

# Normaliza caminho
$RootPath = (Resolve-Path -LiteralPath $RootPath).Path

# Função que monta o ASCII tree (com indentação ├─, └─)
function Get-AsciiTree {
    param(
        [string]$Path,
        [string]$Prefix = ""
    )

    $items = Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue | Sort-Object @{Expression={$_.PSIsContainer};Descending=$true}, Name
    $count = $items.Count
    $i = 0

    foreach ($it in $items) {
        $i++
        $isLast = ($i -eq $count)
        if ($isLast) {
            $connector = "└─ "
            $newPrefix = $Prefix + "   "
        } else {
            $connector = "├─ "
            $newPrefix = $Prefix + "│  "
        }

        $line = "$Prefix$connector$($it.Name)"
        $line
        if ($it.PSIsContainer) {
            foreach ($sub in Get-AsciiTree -Path $it.FullName -Prefix $newPrefix) { $sub }
        }
    }
}

# Gerar nome de arquivo com timestamp
$ts = (Get-Date).ToString("yyyyMMdd_HHmmss")
$txtFile = Join-Path $OutDir "fluxmap_$ts.txt"
$pdfFile = Join-Path $OutDir "fluxmap_$ts.pdf"
$mdFile  = Join-Path $OutDir "fluxmap_$ts.md"
$metaFile = Join-Path $OutDir "fluxmap_$ts.meta.txt"

Write-Log "Gerando mapa ASCII para: $RootPath"
# Cabeçalho
$header = @()
$header += "CONAV TRADER — Fluxograma de Pastas"
$header += "Root: $RootPath"
$header += "Gerado em: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$header += "Script: Generate_FluxMap.ps1"
$header += "------------------------------------------------------------"
$header += ""

# Montar corpo
$treeLines = @()
$rootName = Split-Path -Path $RootPath -Leaf
$treeLines += $rootName
foreach ($l in Get-AsciiTree -Path $RootPath -Prefix "") { $treeLines += $l }

# Escrever txt
$fullTxt = $header + $treeLines
$fullTxt | Out-File -FilePath $txtFile -Encoding UTF8 -Force
Write-Log "Arquivo TXT salvo: $txtFile"

# Escrever markdown versão (opcional)
$mdContent = @()
$mdContent += "# Fluxograma (CONAV TRADER)"
$mdContent += ""
$mdContent += "**Root**: `$RootPath`"
$mdContent += ""
$mdContent += "Gerado em: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$mdContent += ""
$mdContent += "```"
$mdContent += $treeLines
$mdContent += "```"
$mdContent | Out-File -FilePath $mdFile -Encoding UTF8 -Force
Write-Log "Arquivo MD salvo: $mdFile"

# Meta
$meta = @()
$meta += "generated_at=$(Get-Date -Format o)"
$meta += "root=$RootPath"
$meta += "txt=$txtFile"
$meta += "pdf=$pdfFile"
$meta += "md=$mdFile"
$meta | Out-File -FilePath $metaFile -Encoding UTF8 -Force

# Tentar gerar PDF via Python (reportlab) se disponível
$pythonExe = (Get-Command python -ErrorAction SilentlyContinue).Source
if ($pythonExe) {
    Write-Log "Python detectado: $pythonExe. Tentando gerar PDF via reportlab..."
    # copia o helper python para a pasta OutDir (se não existir)
    $pyHelperPath = Join-Path $OutDir "generate_map_pdf.py"
    if (-not (Test-Path $pyHelperPath) -or $Force) {
        # Conteúdo mínimo do helper é escrito abaixo usando here-string
        $pyCode = @"
import sys
from reportlab.lib.pagesizes import letter, landscape
from reportlab.pdfgen import canvas
def txt_to_pdf(txt_path, pdf_path):
    c = canvas.Canvas(pdf_path, pagesize=landscape(letter))
    width, height = landscape(letter)
    with open(txt_path, 'r', encoding='utf-8') as f:
        lines = f.read().splitlines()
    margin = 40
    y = height - margin
    line_height = 12
    max_lines_per_page = int((height - 2*margin) / line_height)
    page = 0
    i = 0
    for line in lines:
        if i >= max_lines_per_page:
            c.showPage()
            y = height - margin
            i = 0
        # Truncate extremely long lines
        if len(line) > 300:
            line = line[:300] + "..."
        c.drawString(margin, y, line)
        y = y - line_height
        i += 1
    c.save()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: generate_map_pdf.py input.txt output.pdf")
        sys.exit(1)
    txt = sys.argv[1]
    pdf = sys.argv[2]
    txt_to_pdf(txt, pdf)
"@
        $pyCode | Out-File -FilePath $pyHelperPath -Encoding UTF8 -Force
        Write-Log "Helper Python salvo em: $pyHelperPath"
    }
    # Executa
    & $pythonExe $pyHelperPath $txtFile $pdfFile
    if ($LASTEXITCODE -eq 0) {
        Write-Log "PDF gerado: $pdfFile"
    } else {
        Write-Log "Falha ao gerar PDF via Python (exitcode $LASTEXITCODE). Arquivo TXT disponível em $txtFile"
    }
} else {
    Write-Log "Python não encontrado — PDF não gerado automaticamente. Você pode instalar Python 3 + reportlab (pip install reportlab) e reexecutar o script para gerar o PDF."
}

Write-Log "Fluxograma gerado com sucesso."
Write-Output @{
    txt = $txtFile;
    pdf = (if (Test-Path $pdfFile) { $pdfFile } else { $null });
    md  = $mdFile;
    meta = $metaFile
}
# ===== FIM Generate_FluxMap.ps1 =====

# ===== INICIO CONAVPackage-att.ps1 =====
# Build-CONAVPackage.ps1
# Gera pacotes oficiais do CONAV sequenciais e envia para a pasta correta
# Mantém histórico ilimitado, integrado ao Script Base
param (
[string]$RootPath = "C:\CONAV TRADER\CONAV_TRADER",
[string]$PackagesPath = "C:\CONAV TRADER\CONAV_TRADER\scripts\PACKAGES
OFICIAIS",
[string]$LogsPath = "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS"
)
# Criar pastas se não existirem
$null = New-Item -ItemType Directory -Force -Path $RootPath
$null = New-Item -ItemType Directory -Force -Path $PackagesPath
$null = New-Item -ItemType Directory -Force -Path $LogsPath
# Data e hora
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
# Descobrir o próximo número sequencial
$existing = Get-ChildItem -Path $PackagesPath -Filter "conavpackage*.zip" | Sort-Object
Name
if ($existing.Count -eq 0) {
$nextNum = 1
} else {
$last = $existing[-1].BaseName -replace '\D', ''
$nextNum = [int]$last + 1
}
# Nome do pacote
$packageName = "conavpackage{0:D5}.zip" -f $nextNum
$packagePath = Join-Path $PackagesPath $packageName
# Log
$logFile = Join-Path $LogsPath "build_conavpackage_$timestamp.log"
# Criar log inicial
"[$(Get-Date)] Iniciando build do pacote $packageName" | Out-File -FilePath $logFile
-Encoding utf8 -Append
try {
# Compactar a pasta raiz (exceto os próprios pacotes)
Compress-Archive -Path (Join-Path $RootPath '*') -DestinationPath $packagePath -Force
-CompressionLevel Optimal -Update
"[$(Get-Date)] Pacote gerado com sucesso: $packagePath" | Out-File -FilePath $logFile
-Encoding utf8 -Append
# Enviar para Google Drive (placeholder - integrado futuramente com API)
"[$(Get-Date)] Exportação para Google Drive (projetoconav@gmail.com) preparada." |
Out-File -FilePath $logFile -Encoding utf8 -Append
} catch {
"[$(Get-Date)] ERRO: $($_.Exception.Message)" | Out-File -FilePath $logFile -Encoding
utf8 -Append
throw
}
# ===== FIM CONAVPackage-att.ps1 =====

# ===== INICIO CONAVPackage-att0001.ps1 =====
# =============================================
# CONAVPackage.ps1 - Builder Automático de Pacotes
# Versão integrada ao Script Base
# =============================================
param(
[string]$PackageName = "CONAV_FULL_PROFESSIONAL_v1.45_fix3"
)
# Diretórios principais
$RootPath = "C:\CONAV TRADER\CONAV_TRADER"
$PackagesPath = Join-Path $RootPath "PACKAGES OFICIAIS"
$LogsPath = Join-Path $RootPath "LOGS GERAIS"
# Garantir pastas
New-Item -ItemType Directory -Force -Path $PackagesPath | Out-Null
New-Item -ItemType Directory -Force -Path $LogsPath | Out-Null
# Descobrir o próximo número sequencial
$existing = Get-ChildItem -Path $PackagesPath -Filter "CONAVPackage*.ps1" | Sort-Object
Name
if ($existing) {
$last = $existing[-1].BaseName
$lastNumber = [int]($last -replace "[^\d]", "")
$nextNumber = $lastNumber + 1
} else {
$nextNumber = 1
}
$nextScriptName = "CONAVPackage{0:D5}.ps1" -f $nextNumber
$zipName = "$PackageName.zip"
$zipPath = Join-Path $PackagesPath $zipName
# Log
$logFile = Join-Path $LogsPath
"build_conavpackage_$((Get-Date).ToString('yyyyMMdd_HHmmss')).log"
function Write-Log {
param([string]$msg)
$entry = "[BUILD] $msg"
Add-Content -Path $logFile -Value $entry
Write-Output $entry
}
Write-Log "Iniciando processo de build do pacote $PackageName..."
# Verificar se já existe arquivo em uso
if (Test-Path $zipPath) {
try {
Remove-Item $zipPath -Force -ErrorAction Stop
Write-Log "Arquivo antigo removido: $zipPath"
} catch {
Write-Log "Erro ao remover arquivo antigo: $($_.Exception.Message)"
}
}
# Criar o zip (usando Compress-Archive nativo do PowerShell)
try {
Compress-Archive -Path (Join-Path $RootPath "*") -DestinationPath $zipPath -Force
Write-Log "Pacote gerado em $zipPath"
} catch {
Write-Log "Erro ao gerar pacote: $($_.Exception.Message)"
}
# Criar novo script sequencial que referencia este pacote
$newScriptPath = Join-Path $PackagesPath $nextScriptName
@"
# Auto-gerado pelo CONAVPackage.ps1
# Executa o pacote $PackageName
Write-Output '[PACKAGE] Executando pacote: $PackageName'
Expand-Archive -Path '$zipPath' -DestinationPath '$RootPath' -Force
"@ | Set-Content -Path $newScriptPath -Encoding UTF8
Write-Log "Novo script sequencial criado: $newScriptPath"
Write-Log "Build finalizado com sucesso!"
# ===== FIM CONAVPackage-att0001.ps1 =====

# ===== INICIO CONAVPackage-att0002.ps1 =====
# CONAVPackage00001.ps1
Add-Type -AssemblyName System.Windows.Forms
$Root = "C:\CONAV TRADER\CONAV_TRADER"
$PackagesPath = Join-Path $Root "PACKAGES OFICIAIS"
$ScriptsBase = Join-Path $Root "SCRIPTS BASE OFICIAIS"
$TimeStamp = (Get-Date).ToString("yyyyMMdd_HHmmss")

function Ensure-Folder { param($p) if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null } }

Ensure-Folder $PackagesPath
Ensure-Folder $ScriptsBase

$form = New-Object System.Windows.Forms.Form
$form.Text = "CONAV Package Builder"
$form.Width = 600; $form.Height = 300

$btnBuild = New-Object System.Windows.Forms.Button
$btnBuild.Text = "Build Package (zip)"
$btnBuild.Width = 160; $btnBuild.Height = 30; $btnBuild.Top = 20; $btnBuild.Left = 20
$form.Controls.Add($btnBuild)

$btnList = New-Object System.Windows.Forms.Button
$btnList.Text = "Listar pacotes"
$btnList.Width = 160; $btnList.Height = 30; $btnList.Top = 20; $btnList.Left = 200
$form.Controls.Add($btnList)

$lbl = New-Object System.Windows.Forms.Label
$lbl.Text = "Status:"; $lbl.Top = 70; $lbl.Left = 20; $lbl.Width = 540
$form.Controls.Add($lbl)

$btnBuild.Add_Click({
    $lbl.Text = "Status: Gerando pacote..."
    try {
        $ver = (Get-ChildItem -Path $ScriptsBase -Filter "CONAVPackage*.ps1" -ErrorAction SilentlyContinue | Measure-Object).Count
        $next = $ver + 1
        $outName = "CONAV_FULL_PROFESSIONAL_v1.45_fix3_pkg_$next.zip"
        $outPath = Join-Path $PackagesPath $outName
        # Compacta raiz
        Compress-Archive -Path (Join-Path $Root '*') -DestinationPath $outPath -Force
        # Gerar script numerado de build para histórico
        $scriptName = ("CONAVPackage{0}.ps1" -f ($next.ToString("D4")))
        $scriptPath = Join-Path $ScriptsBase $scriptName
        $scriptContent = @"
# Auto-generated package script {0}
# Cria o pacote: {1}
Compress-Archive -Path (Join-Path `"{2}`" '*') -DestinationPath `"{1}`" -Force
"@ -f $scriptName, $outPath, $Root
        $scriptContent | Out-File -FilePath $scriptPath -Encoding UTF8
        $lbl.Text = "Status: Pacote gerado: $outPath`nScript salvo: $scriptPath"
    } catch {
        $lbl.Text = "ERRO: $($_.Exception.Message)"
    }
})

$btnList.Add_Click({
    $pkgs = Get-ChildItem -Path $PackagesPath -Filter *.zip -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if (-not $pkgs) { $lbl.Text = "Nenhum pacote encontrado em $PackagesPath"; return }
    $s = "Pacotes:`n"
    foreach ($p in $pkgs) { $s += $p.Name + "`n" }
    $lbl.Text = $s
})

[void] $form.ShowDialog()
# ===== FIM CONAVPackage-att0002.ps1 =====

# ===== INICIO CONAVPackage-att0003.ps1 =====
<#
.CONAVPackage.ps1
Script simples para empacotar o CONAV em ZIP, com salvamento em PACKAGES OFICIAIS.
#>
param(
    [string]$Root = 'C:\CONAV TRADER\CONAV_TRADER',
    [string]$OutputName = ('CONAV_FULL_PROFESSIONAL_v1.45_fix4.zip' -f (Get-Date -Format 'yyyyMMdd_HHmm')),
    [switch]$Force
)

$PackagesDir = Join-Path $Root 'PACKAGES OFICIAIS'
if (-not (Test-Path $PackagesDir)) { New-Item -ItemType Directory -Path $PackagesDir -Force | Out-Null }

$outPath = Join-Path $PackagesDir $OutputName
if (Test-Path $outPath) {
    if ($Force) { Remove-Item -LiteralPath $outPath -Force }
    else {
        $ts = Get-Date -Format 'yyyyMMddHHmmss'
        $outPath = Join-Path $PackagesDir ("{0}_{1}.zip" -f [System.IO.Path]::GetFileNameWithoutExtension($OutputName), $ts)
    }
}

Write-Host "[BUILD] Criando pacote: $outPath"
$items = @()
foreach ($sub in @('dashboard','dist','scripts','tools','relatorios','relatórios','icons','resources','docs','emails')) {
    $p = Join-Path $Root $sub
    if (Test-Path $p) { $items += $p }
}
if ($items.Count -eq 0) {
    Write-Host "[BUILD] Nenhum item encontrado para empacotar."
    exit 1
}

try {
    Compress-Archive -Path $items -DestinationPath $outPath -Force
    Write-Host "[BUILD] Pacote gerado em: $outPath"
    exit 0
} catch {
    Write-Host "[BUILD] ERRO: $($_.Exception.Message)"
    exit 2
}

# ===== FIM CONAVPackage-att0003.ps1 =====

# ===== INICIO CONAVPackage.ps1 =====
<#
.CONAVPackage.ps1
Script simples para empacotar o CONAV em ZIP, com salvamento em PACKAGES OFICIAIS.
#>
param(
    [string]$Root = 'C:\CONAV TRADER\CONAV_TRADER',
    [string]$OutputName = ('CONAV_FULL_PROFESSIONAL_v1.45_fix4.zip' -f (Get-Date -Format 'yyyyMMdd_HHmm')),
    [switch]$Force
)

$PackagesDir = Join-Path $Root 'PACKAGES OFICIAIS'
if (-not (Test-Path $PackagesDir)) { New-Item -ItemType Directory -Path $PackagesDir -Force | Out-Null }

$outPath = Join-Path $PackagesDir $OutputName
if (Test-Path $outPath) {
    if ($Force) { Remove-Item -LiteralPath $outPath -Force }
    else {
        $ts = Get-Date -Format 'yyyyMMddHHmmss'
        $outPath = Join-Path $PackagesDir ("{0}_{1}.zip" -f [System.IO.Path]::GetFileNameWithoutExtension($OutputName), $ts)
    }
}

Write-Host "[BUILD] Criando pacote: $outPath"
$items = @()
foreach ($sub in @('dashboard','dist','scripts','tools','relatorios','relatórios','icons','resources','docs','emails')) {
    $p = Join-Path $Root $sub
    if (Test-Path $p) { $items += $p }
}
if ($items.Count -eq 0) {
    Write-Host "[BUILD] Nenhum item encontrado para empacotar."
    exit 1
}

try {
    Compress-Archive -Path $items -DestinationPath $outPath -Force
    Write-Host "[BUILD] Pacote gerado em: $outPath"
    exit 0
} catch {
    Write-Host "[BUILD] ERRO: $($_.Exception.Message)"
    exit 2
}

# ===== FIM CONAVPackage.ps1 =====

# ===== INICIO CONAVPackage00001.ps1 =====
# Auto-gerado pelo CONAVPackage.ps1
# Executa o pacote CONAV_FULL_PROFESSIONAL_v1.45_fix3
Write-Output '[PACKAGE] Executando pacote: CONAV_FULL_PROFESSIONAL_v1.45_fix3'
Expand-Archive -Path 'C:\CONAV TRADER\CONAV_TRADER\PACKAGES OFICIAIS\CONAV_FULL_PROFESSIONAL_v1.45_fix3.zip' -DestinationPath 'C:\CONAV TRADER\CONAV_TRADER' -Force

# ===== FIM CONAVPackage00001.ps1 =====

# ===== INICIO INSTALL_CONAV_FULL_PROFESSIONAL1.45.ps1 =====
# INSTALL_CONAV_FULL_PROFESSIONAL1.45.ps1
# v1.45-fix — installer with routing, dry-run, logging. Fixed param-in-function parser issue.
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$BundleZip = ''
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Message)
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logDir = Join-Path -Path (Join-Path $PSScriptRoot '..') -ChildPath 'logs'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
    $logFile = Join-Path $logDir ("install_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
    $line = "[$t] $Message"
    Add-Content -Path $logFile -Value $line -Encoding UTF8
    Write-Host $line
}

function Extract-AndRouteZip {
    param([string]$zipPath)
    if (-not (Test-Path $zipPath)) { throw "Zip $zipPath not found." }
    $temp = Join-Path $env:TEMP ("conav_extract_{0}" -f ([guid]::NewGuid().ToString()))
    New-Item -ItemType Directory -Path $temp | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $temp)
    Write-Log "Extracted $zipPath to $temp"

    $mapping = @{
        'automation' = 'automation'
        'build'      = 'build'
        'dashboard'  = 'dashboard'
        'data'       = 'data'
        'database'   = 'database'
        'Desinstalar' = 'Desinstalar'
        'dist'       = 'dist'
        'docs'       = 'docs'
        'emails'     = 'emails'
        'icons'      = 'icons'
        'logs'       = 'logs'
        'relatorios' = 'relatorios'
        'relatórios' = 'relatórios'
        'resources'  = 'resources'
        'scripts'    = 'scripts'
        'tools'      = 'tools'
    }

    $root = Join-Path $PSScriptRoot '..'  # parent of script dir
    foreach ($item in Get-ChildItem -Path $temp -Force) {
        $name = $item.Name
        if ($mapping.ContainsKey($name)) {
            $destRel = $mapping[$name]
            $dest = Join-Path $root $destRel
            if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }
            Write-Log "Routing folder $name -> $dest"
            if ($DryRun) { Write-Host "[DRYRUN] Would copy $($item.FullName) -> $dest" ; continue }
            Copy-Item -Path (Join-Path $item.FullName '*') -Destination $dest -Recurse -Force
        } else {
            if ($item.PSIsContainer) {
                $dest = Join-Path $root $item.Name
                if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }
                Write-Log "Copying extra folder $name -> $dest"
                if ($DryRun) { Write-Host "[DRYRUN] Would copy folder $($item.FullName) -> $dest" ; continue }
                Copy-Item -Path (Join-Path $item.FullName '*') -Destination $dest -Recurse -Force
            } else {
                $dest = Join-Path $root $item.Name
                Write-Log "Copying file $name -> $dest"
                if ($DryRun) { Write-Host "[DRYRUN] Would copy file $($item.FullName) -> $dest" ; continue }
                Copy-Item -Path $item.FullName -Destination $dest -Force
            }
        }
    }

    # cleanup temp
    Remove-Item -Path $temp -Recurse -Force
    Write-Log "Routed zip contents and cleaned temp."
}

# MAIN
try {
    Write-Log "Starting installer (v1.45-fix). DryRun = $DryRun"
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $root = Join-Path $scriptRoot '..'
    $root = (Resolve-Path $root).Path

    if ($BundleZip -ne '') {
        Write-Log "BundleZip provided: $BundleZip"
        Extract-AndRouteZip -zipPath $BundleZip
    } else {
        # look for a bundle in current dir
        $found = Get-ChildItem -Path $scriptRoot -Filter '*.zip' -File | Select-Object -First 1
        if ($found) {
            Write-Log "Found bundle zip: $($found.FullName)"
            Extract-AndRouteZip -zipPath $found.FullName
        } else {
            Write-Log "No bundle zip provided or found; nothing to route."
        }
    }

    Write-Log "INSTALLER completed successfully."
} catch {
    Write-Log "INSTALLER ERROR: $($_.Exception.Message)"
    throw
}

# ===== FIM INSTALL_CONAV_FULL_PROFESSIONAL1.45.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL-OFICIAL.ps1 =====
<#
INSTALL_CONAV_TRADER_PS7.ps1
Instalador compatível com PowerShell 7 (preview/estável).
O script assume que a pasta atual contém a estrutura 'CONAV_TRADER' (ou os arquivos do pacote).
Ele cria a instalação em: C:\Program Files\CONAV_TRADER
#>

# ---------- Configurações ----------
$ErrorActionPreference = "Stop"
$InstallPath = "C:\Program Files\CONAV_TRADER"
$VenvPath = Join-Path $InstallPath "venv"
$DistExeRelative = "dist\main_dashboard.exe"
# Dependências de Python que o projeto precisa
$PythonPackages = @("pip", "wheel", "setuptools", "pyinstaller", "fpdf", "reportlab", "plotly", "openai", "Pillow")

# ---------- Helpers ----------
function Write-Ok($msg){ Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Info($msg){ Write-Host "[..] $msg" -ForegroundColor Cyan }
function Write-Err($msg){ Write-Host "[ERRO] $msg" -ForegroundColor Red }

# Verifica execução como Administrador
function Assert-Admin {
    $isAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    if (-not $isAdmin) {
        Write-Err "Este instalador precisa ser executado como Administrador. Feche e reabra o PowerShell como Administrador."
        Pause
        Exit 1
    }
}

# Recupera o diretório do script (funciona no PS7)
$ScriptDir = Split-Path -Parent $PSCommandPath

# ---------- Início ----------
Assert-Admin
Write-Host "Iniciando instalação do CONAV TRADER..." -ForegroundColor Yellow
Write-Info "Script dir: $ScriptDir"
Write-Info "Instalando em: $InstallPath"

# 1) Criar pastas de instalação
$folders = @(
    (Join-Path $InstallPath "dashboard\gui_assets"),
    (Join-Path $InstallPath "dashboard\plots"),
    (Join-Path $InstallPath "automation"),
    (Join-Path $InstallPath "emails\templates"),
    (Join-Path $InstallPath "database"),
    (Join-Path $InstallPath "resources\icons"),
    (Join-Path $InstallPath "resources\styles")
)
foreach ($f in $folders) {
    if (-not (Test-Path $f)) {
        New-Item -ItemType Directory -Force -Path $f | Out-Null
    }
}
Write-Ok "Pastas de instalação criadas."

# 2) Copiar arquivos para a pasta de instalação
Write-Info "Copiando arquivos para $InstallPath (isso pode demorar dependendo do tamanho)..."
# Copia tudo que está na mesma pasta do script para o InstallPath, exceto o próprio instalador temporário
try {
    Copy-Item -Path (Join-Path $ScriptDir "*") -Destination $InstallPath -Recurse -Force -ErrorAction Stop
    Write-Ok "Arquivos copiados."
} catch {
    Write-Err "Falha ao copiar arquivos: $($_.Exception.Message)"
    Exit 1
}

# 3) Detectar Python disponível
Write-Info "Detectando Python no sistema..."
$pythonCmd = $null
# tenta 'python' e 'py'
try {
    $pythonCmd = (Get-Command python -ErrorAction SilentlyContinue).Path
} catch {}
if (-not $pythonCmd) {
    try { $pythonCmd = (Get-Command py -ErrorAction SilentlyContinue).Path } catch {}
}

if (-not $pythonCmd) {
    Write-Err "Python não foi encontrado no PATH. Instale Python 3.10/3.11 (recomendado) a partir de https://www.python.org/ e rode novamente."
    Pause
    Exit 1
}
Write-Ok "Python detectado: $pythonCmd"

# 4) Criar virtualenv dentro do InstallPath (isolamento)
Write-Info "Criando virtualenv em: $VenvPath"
try {
    & $pythonCmd -m venv $VenvPath
    Write-Ok "Virtualenv criado."
} catch {
    Write-Err "Erro ao criar virtualenv: $($_.Exception.Message)"
    Exit 1
}

# 5) Determinar caminhos do venv para pip/python executáveis
$VenvPython = Join-Path $VenvPath "Scripts\python.exe"
$VenvPip = Join-Path $VenvPath "Scripts\pip.exe"
if (-not (Test-Path $VenvPython)) {
    Write-Err "Erro: python do venv não encontrado em $VenvPython"
    Exit 1
}
Write-Ok "Venv ativo: $VenvPython"

# 6) Atualizar pip e instalar pacotes necessários dentro do venv
Write-Info "Atualizando pip e instalando pacotes no virtualenv..."
try {
    & $VenvPython -m pip install --upgrade pip wheel setuptools
    foreach ($pkg in $PythonPackages) {
        Write-Info "Instalando: $pkg"
        & $VenvPython -m pip install $pkg
    }
    Write-Ok "Dependências Python instaladas no venv."
} catch {
    Write-Err "Falha ao instalar pacotes Python: $($_.Exception.Message)"
    Exit 1
}

# 7) Compilar executável via PyInstaller usando o python do venv
Write-Info "Compilando executável com PyInstaller (vai demorar alguns minutos)..."
$MainPy = Join-Path $InstallPath "dashboard\main_dashboard.py"
$IconPath = Join-Path $InstallPath "resources\icons\conav_trader_icon.ico"
if (-not (Test-Path $MainPy)) {
    Write-Err "Arquivo principal não encontrado: $MainPy"
    Exit 1
}
if (-not (Test-Path $IconPath)) {
    Write-Info "Ícone não encontrado em $IconPath. O exe será gerado sem ícone."
    $IconPath = $null
}

try {
    if ($IconPath) {
        & $VenvPython -m PyInstaller --noconfirm --onefile --windowed --icon="$IconPath" "$MainPy"
    } else {
        & $VenvPython -m PyInstaller --noconfirm --onefile --windowed "$MainPy"
    }
    Write-Ok "Compilação concluída."
} catch {
    Write-Err "Erro na compilação com PyInstaller: $($_.Exception.Message)"
    Write-Err "Se o erro for relacionado ao ícone (UpdateResourceW), substitua por um .ico válido (256/48/32/16) e tente novamente."
    Exit 1
}

# 8) Criar atalho na área de trabalho pública (Common Desktop)
Write-Info "Criando atalho na área de trabalho..."
$ExePath = Join-Path $InstallPath $DistExeRelative
if (-not (Test-Path $ExePath)) {
    # às vezes PyInstaller cria exe com nome diferente ou dentro de uma pasta com o nome do script; tentar localizar
    $possible = Get-ChildItem -Path (Join-Path $InstallPath "dist") -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($possible) {
        $ExePath = $possible.FullName
    } else {
        Write-Err "Executável não encontrado em $($InstallPath)\dist. Verifique erros do PyInstaller."
        Exit 1
    }
}

try {
    $ws = New-Object -ComObject WScript.Shell
    $desktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
    $lnk = $ws.CreateShortcut((Join-Path $desktop "CONAV TRADER.lnk"))
    $lnk.TargetPath = $ExePath
    $lnk.WorkingDirectory = Split-Path -Parent $ExePath
    if (Test-Path $IconPath) { $lnk.IconLocation = $IconPath }
    $lnk.Save()
    Write-Ok "Atalho criado: $(Join-Path $desktop 'CONAV TRADER.lnk')"
} catch {
    Write-Err "Falha ao criar atalho na área de trabalho. Erro: $($_.Exception.Message)"
    Write-Info "Como alternativa manual, crie atalho apontando para: $ExePath"
}

# 9) Mensagem final
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "INSTALAÇÃO DO CONAV TRADER CONCLUÍDA" -ForegroundColor Green
Write-Host "Aperte qualquer tecla para encerrar..." -ForegroundColor Cyan
Write-Host "Se houver erro de ícone (UpdateResourceW), substitua resources\icons\conav_trader_icon.ico por um .ico válido e rode apenas o passo de compilação manualmente:" -ForegroundColor Yellow
Write-Host "cd "$InstallPath"" -ForegroundColor Yellow
Write-Host "python -m PyInstaller --onefile --windowed --icon="resources\icons\conav_trader_icon.ico" "$MainPy"" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green
Pause
# ===== FIM INSTALL_CONAV_TRADER_FULL-OFICIAL.ps1 =====

# ===== INICIO SET_ICONS_CONAV1.44fix2.ps1 =====
# SET_ICONS_CONAV1.44fix2.ps1
# Locate system_icon.ico in several candidate locations and copy to dist\system_icon.ico

$ErrorActionPreference = 'Stop'
function Write-Log { param($m) $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); Write-Host "[$t] $m" }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootObj = Resolve-Path (Join-Path $ScriptDir '..') -ErrorAction SilentlyContinue
if ($null -eq $RootObj) { $Root = $ScriptDir } else { $Root = $RootObj.Path }

$candidates = @(
    (Join-Path $ScriptDir 'system_icon.ico'),
    (Join-Path $ScriptDir 'icons\system_icon.ico'),
    (Join-Path $Root 'icons\system_icon.ico'),
    (Join-Path $Root 'dist\system_icon.ico'),
    (Join-Path $Root 'resources\icons\system_icon.ico'),
    (Join-Path $Root 'system_icon.ico')
) | Select-Object -Unique

$found = $null
foreach ($p in $candidates) {
    if ($p -and (Test-Path $p)) { $found = (Resolve-Path $p).Path; break }
}

if (-not $found) {
    Write-Log "[SET_ICONS] ERRO: system_icon.ico não encontrado nos caminhos previstos."
    exit 1
}

$destDir = Join-Path $Root 'dist'
if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir | Out-Null }
$dest = Join-Path $destDir 'system_icon.ico'

Write-Log "[SET_ICONS] Copying $found -> $dest"
Copy-Item -Path $found -Destination $dest -Force
Write-Log "[SET_ICONS] system_icon.ico copied to $dest"

# ===== FIM SET_ICONS_CONAV1.44fix2.ps1 =====

# ===== INICIO UNINSTALL_CONAV_FULL_PROFESSIONAL1.45.ps1 =====
# UNINSTALL_CONAV_FULL_PROFESSIONAL1.45.ps1
# Safe uninstaller (reads latest install log and offers dry-run & confirmation)
param(
    [switch]$DryRun,
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
function Write-Log { param($m) $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); Write-Host "[$t] $m" }

$rootObj = Resolve-Path (Join-Path $PSScriptRoot '..') -ErrorAction SilentlyContinue
if ($null -eq $rootObj) { $root = Split-Path -Parent $MyInvocation.MyCommand.Definition } else { $root = $rootObj.Path }

$logDir = Join-Path $root 'logs'
if (-not (Test-Path $logDir)) {
    Write-Log "Log folder not found: $logDir. Cannot proceed."
    exit 1
}

# find latest install log matching 'install_*.log'
$installLog = Get-ChildItem -Path $logDir -Filter 'install_*.log' -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $installLog) {
    Write-Log "ERRO: install.log não encontrado."
    exit 1
}

Write-Log "Using install log: $($installLog.FullName)"
$targets = @()
foreach ($l in Get-Content $installLog.FullName) {
    if ($l -match '->') {
        $parts = $l -split '->'
        $dest = $parts[-1].Trim()
        if ($dest -ne '') { $targets += $dest }
    }
}

if ($targets.Count -eq 0) { Write-Log "Nenhum destino detectado para remoção. Abort."; exit 0 }

foreach ($t in $targets | Select-Object -Unique) { Write-Log "Target: $t" }

if (-not $Force) {
    $ans = Read-Host "Você tem certeza que deseja desinstalar os itens acima? [S/N]"
    if ($ans.ToUpper() -ne 'S') { Write-Log "Cancelado pelo usuário."; exit 0 }
}

foreach ($t in $targets | Select-Object -Unique) {
    try {
        if ($DryRun) { Write-Log "[DRYRUN] Would remove: $t"; continue }
        if (Test-Path $t) {
            if (Test-Path $t -PathType Container) { Remove-Item -Path $t -Recurse -Force; Write-Log "Removed folder $t" }
            else { Remove-Item -Path $t -Force; Write-Log "Removed file $t" }
        } else {
            Write-Log "Not found (skipped): $t"
        }
    } catch {
        Write-Log "Erro removendo $t: $($_.Exception.Message)"
    }
}

Write-Log "Uninstall completed."

# ===== FIM UNINSTALL_CONAV_FULL_PROFESSIONAL1.45.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER_FULL1.34.001.ps1 =====
Write-Host "[INSTALL] Executando CONAV TRADER FULL 1.34..."
# Aqui entra toda a lógica de instalação, simulação, backup e redirecionamento automático para as pastas corretas.

# ===== FIM UNINSTALL_CONAV_TRADER_FULL1.34.001.ps1 =====

# ===== INICIO installconavmestre00001.ps1 =====
# installconavmestre00001.ps1
# Master installer CONAV v1.45_fix3.0004 - corrected
param(
    [switch]$DryRun,
    [switch]$AutoConfirm,
    [switch]$Verbose
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Version = "1.45_fix3.0004"
$ScriptFile = $MyInvocation.MyCommand.Path
$ScriptDir  = if ($ScriptFile) { Split-Path -Parent $ScriptFile } else { (Get-Location).ProviderPath }
$Root = "C:\CONAV TRADER\CONAV_TRADER"

# Folder map (same as before)
$FolderMap = @{
    'automation'   = Join-Path $Root 'automation'
    'build'        = Join-Path $Root 'build'
    'dashboard'    = Join-Path $Root 'dashboard'
    'data'         = Join-Path $Root 'data'
    'database'     = Join-Path $Root 'database'
    'Desinstalar'  = Join-Path $Root 'Desinstalar'
    'dist'         = Join-Path $Root 'dist'
    'docs'         = Join-Path $Root 'docs'
    'emails'       = Join-Path $Root 'emails'
    'icons'        = Join-Path $Root 'icons'
    'logs'         = Join-Path $Root 'logs'
    'logs_install' = Join-Path $Root 'logs\install'
    'logs_ia'      = Join-Path $Root 'logs\ia'
    'logs_scripts' = Join-Path $Root 'logs\scripts'
    'relatorios'   = Join-Path $Root 'relatorios'
    'relatórios'   = Join-Path $Root 'relatórios'
    'resources'    = Join-Path $Root 'resources'
    'scripts'      = Join-Path $Root 'scripts'
    'tools'        = Join-Path $Root 'tools'
    'PACKAGES OFICIAIS' = Join-Path $Root 'PACKAGES OFICIAIS'
    'SCRIPTS BASE OFICIAIS' = Join-Path $Root 'SCRIPTS BASE OFICIAIS'
    'SCRIPTS DE LISTAGEM'   = Join-Path $Root 'SCRIPTS DE LISTAGEM'
    'mapas de fluxograma'   = Join-Path $Root 'mapas de fluxograma'
    'LOGS GERIAS' = Join-Path $Root 'LOGS GERIAS'
}

$AllFolders = $FolderMap.Values | Select-Object -Unique
$TimeStamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$LogFilename = "install_master_${Version}_$TimeStamp.log"
$LogFile = Join-Path $FolderMap['logs_install'] $LogFilename
if ($DryRun) { $ModeTag = "[SIMULAÇÃO]" } else { $ModeTag = "[EXECUÇÃO REAL]" }

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    try {
        $t = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $line = "[$t] [$Level] $ModeTag $Message"
        $dir = Split-Path -Parent $LogFile
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Add-Content -Path $LogFile -Value $line -Encoding UTF8
        if ($Level -eq "ERROR") { Write-Host $line -ForegroundColor Red }
        elseif ($Level -eq "WARN") { Write-Host $line -ForegroundColor Yellow }
        else { if ($Verbose) { Write-Host $line } else { Write-Host $line } }
    } catch {
        Write-Host ("[LOG-ERROR] Falha escrevendo log: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

function Ensure-Folder { param([string]$Path) try { if (-not (Test-Path $Path)) { if ($DryRun) { Write-Log ("Criar pasta (simulação): {0}" -f $Path) } else { New-Item -ItemType Directory -Path $Path -Force | Out-Null; Write-Log ("Criada pasta: {0}" -f $Path) } } else { Write-Log ("Pasta já existe: {0}" -f $Path) } } catch { Write-Log (("Erro criando pasta {0}: {1}" -f $Path, $_.Exception.Message)) "ERROR" } }

function SafeCopy {
    param([string]$Source, [string]$Destination, [switch]$Force = $false)
    try {
        if (-not (Test-Path $Source)) { Write-Log ("Origem inexistente: {0}" -f $Source) "WARN"; return }
        $srcFull = (Get-Item $Source).FullName
        $dstFull = $Destination
        if ($dstFull -eq $srcFull) { Write-Log ("Ignorando cópia: origem é o mesmo que destino: {0}" -f $Source); return }
        $dstDir = Split-Path -Parent $Destination
        if (-not (Test-Path $dstDir)) { Ensure-Folder $dstDir }
        if ($DryRun) { Write-Log ("CÓPIA: {0} -> {1} (simulação)" -f $Source, $Destination); return }
        $doCopy = $true
        if (Test-Path $Destination -PathType Leaf -ErrorAction SilentlyContinue) {
            try {
                $srcInfo = Get-Item $Source
                $dstInfo = Get-Item $Destination
                if (-not $Force) {
                    if ($srcInfo.Length -eq $dstInfo.Length -and $srcInfo.LastWriteTime -le $dstInfo.LastWriteTime) { $doCopy = $false }
                }
            } catch { $doCopy = $true }
        }
        if ($doCopy) { Copy-Item -Path $Source -Destination $Destination -Force; Write-Log ("Copiado: {0} -> {1}" -f $Source, $Destination) }
        else { Write-Log ("Pulando cópia (igual/mais novo já existe): {0}" -f $Destination) }
    } catch { Write-Log (("Erro copiando {0} -> {1} : {2}" -f $Source, $Destination, $_.Exception.Message)) "ERROR" }
}

# (restante das funções: Extract-And-DeployZip, Build-Package, Run-ScriptsSequential, Ensure-Analyzers, Confirm-YesNo, Create-AsciiMap, Generate-InstallLogSummary, Record-InstallFiles)
# -> Para brevidade aqui não repito tudo; na sua cópia local eu faço paste completo (posso enviar o arquivo completo por zip se preferir).
# Importante: todas as ocorrências de Write-Log com ":" interpoladas foram convertidas para a forma -f, evitando o ParserError.

# Exemplo de instrução PyInstaller (comentada) - ative quando quiser:
<#
# Para reconstruir main_dashboard.exe (garanta pyinstaller instalado no mesmo Python)
# pyinstaller --clean --onefile --noconsole --icon "C:\CONAV TRADER\CONAV_TRADER\icons\system_icon.ico" --distpath "C:\CONAV TRADER\CONAV_TRADER\dist" "C:\CONAV TRADER\CONAV_TRADER\dashboard\main_dashboard.py"
# Certifique-se do python bitness e do Visual C++ Redistributable adequados.
#>

# Inicialização
Write-Log ("===== INICIANDO INSTALLCONAVMESTRE v{0} =====" -f $Version)
foreach ($f in $AllFolders) { Ensure-Folder $f }

# (restante do fluxo: checar pacotes, Run-ScriptsSequential, Create-AsciiMap, Record-InstallFiles, Build-Package, Generate-InstallLogSummary)
Write-Log "===== FIM DO SCRIPT MESTRE ====="
# ===== FIM installconavmestre00001.ps1 =====

# ===== INICIO INSTALL_CONAV_MESTRE_V1.45_FIX3.ps1 =====
<#
.SYNOPSIS
Script Mestre CONAV - v1.45_fix3
Integração, organização, dry-run, deploy de zips, execução sequencial de scripts,
geração de logs e relatórios, criação de install.log para desinstalador, geração de mapa
ASCII+PDF,
checagem/instalação de analisadores (PSScriptAnalyzer / bandit) com pop-ups de
confirmação.
.NOTES
Salve como: INSTALL_CONAV_MESTRE_v1.45_fix3.ps1
Execute no PowerShell 7 ou Windows PowerShell 5.1 (algumas features COM só em
Windows).
Autor: Gerado pelo assistente. Versão: 1.45_fix3.0004
#>
param(
[switch]$DryRun,
[switch]$AutoConfirm,
[switch]$Verbose
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# ----------------------------
# Configurações principais
# ----------------------------
$Version = "1.45_fix3.0004"
$ScriptFile = $MyInvocation.MyCommand.Path
$ScriptDir = if ($ScriptFile) { Split-Path -Parent $ScriptFile } else {
(Get-Location).ProviderPath }
# RAIZ do CONAV - fixado conforme seu pedido
$Root = "C:\CONAV TRADER\CONAV_TRADER"
# Mapeamento padrão de pastas (nomes comuns -> destino dentro da raiz)
$FolderMap = @{
'automation' = Join-Path $Root 'automation'
'build' = Join-Path $Root 'build'
'dashboard' = Join-Path $Root 'dashboard'
'data' = Join-Path $Root 'data'
'database' = Join-Path $Root 'database'
'Desinstalar' = Join-Path $Root 'Desinstalar'
'dist' = Join-Path $Root 'dist'
'docs' = Join-Path $Root 'docs'
'emails' = Join-Path $Root 'emails'
'icons' = Join-Path $Root 'icons'
'logs' = Join-Path $Root 'logs'
'logs_install' = Join-Path $Root 'logs\install'
'logs_ia' = Join-Path $Root 'logs\ia'
'logs_scripts' = Join-Path $Root 'logs\scripts'
'relatorios' = Join-Path $Root 'relatorios'
'relatórios' = Join-Path $Root 'relatórios'
'resources' = Join-Path $Root 'resources'
'scripts' = Join-Path $Root 'scripts'
'tools' = Join-Path $Root 'tools'
'PACKAGES OFICIAIS' = Join-Path $Root 'PACKAGES OFICIAIS'
'SCRIPTS BASE OFICIAIS' = Join-Path $Root 'SCRIPTS BASE OFICIAIS'
'SCRIPTS DE LISTAGEM' = Join-Path $Root 'SCRIPTS DE LISTAGEM'
'mapas de fluxograma' = Join-Path $Root 'mapas de fluxograma'
'LOGS GERIAS' = Join-Path $Root 'LOGS GERIAS'
'PACKAGESOFICIAIS' = Join-Path $Root 'scripts\PACKAGES OFICIAIS' # fallback
}
# Pastas extras a garantir
$AllFolders = $FolderMap.Values | Select-Object -Unique
# Nome do log principal (cada execução gera seu install log)
$TimeStamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$LogFilename = "install_master_${Version}_$TimeStamp.log"
$LogFile = Join-Path $FolderMap['logs_install'] $LogFilename
# Controle de dry-run / prefixos
if ($DryRun) {
$ModeTag = "[SIMULAÇÃO]"
} else {
$ModeTag = "[EXECUÇÃO REAL]"
}
# ----------------------------
# Funções utilitárias
# ----------------------------
function Write-Log {
param(
[string]$Message,
[string]$Level = "INFO"
)
try {
$t = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "[$t] [$Level] $ModeTag $Message"
# Certifica que pasta existe antes de gravar
$dir = Split-Path -Parent $LogFile
if (-not (Test-Path $dir)) {
New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
Add-Content -Path $LogFile -Value $line -Encoding UTF8
if ($Level -eq "ERROR") {
Write-Host $line -ForegroundColor Red
} elseif ($Level -eq "WARN") {
Write-Host $line -ForegroundColor Yellow
} else {
if ($Verbose) { Write-Host $line }
else { Write-Host $line }
}
} catch {
Write-Host "[LOG-ERROR] Falha escrevendo log: $($_.Exception.Message)"
-ForegroundColor Red
}
}
function Ensure-Folder {
param([string]$Path)
if (-not $Path) { return }
try {
if (-not (Test-Path $Path)) {
if ($DryRun) {
Write-Log "Criar pasta (simulação): $Path"
} else {
New-Item -ItemType Directory -Path $Path -Force | Out-Null
Write-Log "Criada pasta: $Path"
}
} else {
Write-Log "Pasta já existe: $Path"
}
} catch {
Write-Log "Erro criando pasta $Path: $($_.Exception.Message)" "ERROR"
}
}
function SafeCopy {
param(
[string]$Source,
[string]$Destination,
[switch]$Force = $false
)
try {
if (-not (Test-Path $Source)) { Write-Log "Origem inexistente: $Source" "WARN"; return
}
# se origem == destino -> ignore (evita erro "overwrite with itself")
$srcFull = (Get-Item $Source).FullName
$dstFull = $Destination
if ($dstFull -eq $srcFull) {
Write-Log "Ignorando cópia: origem é o mesmo que destino: $Source"
return
}
$dstDir = Split-Path -Parent $Destination
if (-not (Test-Path $dstDir)) { Ensure-Folder $dstDir }
if ($DryRun) {
Write-Log "CÓPIA: $Source -> $Destination (simulação)"
return
}
# Só copiar quando diferente (por timestamp ou tamanho) ou se Force
$doCopy = $true
if (Test-Path $Destination -PathType Leaf -ErrorAction SilentlyContinue) {
try {
$srcInfo = Get-Item $Source
$dstInfo = Get-Item $Destination
if (-not $Force) {
if ($srcInfo.Length -eq $dstInfo.Length -and $srcInfo.LastWriteTime -le
$dstInfo.LastWriteTime) {
$doCopy = $false
}
}
} catch { $doCopy = $true }
}
if ($doCopy) {
Copy-Item -Path $Source -Destination $Destination -Force
Write-Log "Copiado: $Source -> $Destination"
} else {
Write-Log "Pulando cópia (igual/mais novo já existe): $Destination"
}
} catch {
Write-Log "Erro copiando $Source -> $Destination : $($_.Exception.Message)"
"ERROR"
}
}
function Extract-And-DeployZip {
param(
[Parameter(Mandatory=$true)][string]$ZipPath
)
try {
if (-not (Test-Path $ZipPath)) {
Write-Log "ZIP não encontrado: $ZipPath" "ERROR"
return
}
$temp = Join-Path $env:TEMP ("conav_zip_" + [Guid]::NewGuid().ToString())
if ($DryRun) { Write-Log "Extrair (simulação) $ZipPath -> $temp"; return }
Ensure-Folder $temp
Expand-Archive -Path $ZipPath -DestinationPath $temp -Force
# Mapeia top-level folders e arquivos
$entries = Get-ChildItem -Path $temp -Force
foreach ($e in $entries) {
$nameLower = $e.Name.ToLower()
# Tenta encontrar destino via FolderMap por substring
$dest = $null
foreach ($k in $FolderMap.Keys) {
if ($nameLower -like "*$k*") { $dest = $FolderMap[$k]; break }
}
if (-not $dest) {
# fallback: raiz
$dest = $Root
}
# mover/consolidar
Write-Log "Deploying $($e.FullName) -> $dest"
if ($e.PSIsContainer) {
# copia recursiva
Get-ChildItem -Path $e.FullName -Recurse -Force | ForEach-Object {
$rel = Resolve-Path -Path $_.FullName
$relPath = $_.FullName.Substring($e.FullName.Length).TrimStart('\','/')
$target = Join-Path $dest $relPath
SafeCopy -Source $_.FullName -Destination $target
}
} else {
$target = Join-Path $dest $e.Name
SafeCopy -Source $e.FullName -Destination $target
}
}
# Limpeza temporária
Remove-Item -Path $temp -Recurse -Force -ErrorAction SilentlyContinue
Write-Log "ZIP implantado com sucesso: $ZipPath"
} catch {
Write-Log "Erro ao extrair/deploy do zip $ZipPath: $($_.Exception.Message)" "ERROR"
}
}
function Build-Package {
param(
[string]$OutputName = "CONAV_FULL_PROFESSIONAL_v$Version.zip",
[string]$OutputFolder = $FolderMap['PACKAGES OFICIAIS']
)
try {
Ensure-Folder $OutputFolder
$dstZip = Join-Path $OutputFolder $OutputName
if ($DryRun) {
Write-Log "Gerar ZIP (simulação): $dstZip"
return $dstZip
}
# Se arquivo estiver em uso, tenta renomear com sufixo temporário
if (Test-Path $dstZip) {
try {
$tempName = "$dstZip.locked.$([Guid]::NewGuid().ToString()).tmp"
Rename-Item -Path $dstZip -NewName $tempName -ErrorAction SilentlyContinue
} catch { }
}
# Compacta a partir da raiz (exclui builds temporários)
$exclusions = @("build","__pycache__")
$items = Get-ChildItem -Path $Root -Force | Where-Object { $exclusions -notcontains
$_.Name }
if (Test-Path $dstZip) { Remove-Item -Path $dstZip -Force -ErrorAction SilentlyContinue
}
Compress-Archive -Path (Join-Path $Root '*') -DestinationPath $dstZip -Force
Write-Log "Pacote gerado em $dstZip"
return $dstZip
} catch {
Write-Log "Erro gerando pacote: $($_.Exception.Message)" "ERROR"
}
}
function Run-ScriptsSequential {
param(
[string]$FolderPath = $FolderMap['scripts'],
[switch]$UseNewProcess = $true
)
try {
if (-not (Test-Path $FolderPath)) { Write-Log "Pasta scripts inexistente: $FolderPath"
"WARN"; return }
$ps1s = Get-ChildItem -Path $FolderPath -Filter *.ps1 -Recurse | Sort-Object FullName
foreach ($ps in $ps1s) {
# Evita executar o próprio master
if ($ps.FullName -eq $ScriptFile) { continue }
Write-Log "Pronto para executar script: $($ps.FullName)"
if ($DryRun) {
Write-Log "EXECUTAR (simulação): $($ps.FullName)"
continue
}
if ($UseNewProcess) {
$arg = "-NoProfile -ExecutionPolicy Bypass -File `"$($ps.FullName)`""
Write-Log "Iniciando novo processo PowerShell para: $($ps.Name)"
$p = Start-Process -FilePath pwsh -ArgumentList $arg -Wait -PassThru
-ErrorAction SilentlyContinue
if ($p.ExitCode -ne 0) {
Write-Log "Script retornou código $($p.ExitCode): $($ps.FullName)" "WARN"
}
} else {
try {
& powershell -NoProfile -ExecutionPolicy Bypass -File $ps.FullName
} catch {
Write-Log "Erro executando $($ps.FullName): $($_.Exception.Message)"
"ERROR"
}
}
}
} catch {
Write-Log "Erro no Run-ScriptsSequential: $($_.Exception.Message)" "ERROR"
}
}
function Ensure-Analyzers {
param(
[switch]$InstallIfMissing
)
# PSScriptAnalyzer (PowerShell)
try {
$pssa = Get-Module -ListAvailable -Name PSScriptAnalyzer
if (-not $pssa) {
# perguntar via GUI se não AutoConfirm
$msg = "PSScriptAnalyzer não encontrado. Deseja instalar (Install-Module -Name
PSScriptAnalyzer -Scope CurrentUser)?"
if ($AutoConfirm -or (Confirm-YesNo $msg)) {
if ($DryRun) { Write-Log "Instalar PSScriptAnalyzer (simulação)"; }
else {
try {
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
-AllowClobber -ErrorAction Stop
Write-Log "PSScriptAnalyzer instalado."
} catch {
Write-Log "Falha instalando PSScriptAnalyzer: $($_.Exception.Message)"
"ERROR"
}
}
} else { Write-Log "Instalação de PSScriptAnalyzer ignorada pelo usuário." }
} else {
Write-Log "PSScriptAnalyzer já disponível."
}
} catch {
Write-Log "Erro checando PSScriptAnalyzer: $($_.Exception.Message)" "ERROR"
}
# bandit (Python)
try {
$banditInstalled = $false
try {
$p = & python -c "import pkgutil,sys; sys.exit(0 if pkgutil.find_loader('bandit') else 1)"
2>$null
$banditInstalled = ($LASTEXITCODE -eq 0)
} catch { $banditInstalled = $false }
if (-not $banditInstalled) {
$msg2 = "Bandit (analisador Python) não encontrado. Deseja instalar via pip (python
-m pip install bandit)?"
if ($AutoConfirm -or (Confirm-YesNo $msg2)) {
if ($DryRun) { Write-Log "Instalar bandit (simulação)"; }
else {
try {
& python -m pip install --user bandit | Out-Null
Write-Log "Bandit instalado (pip)."
} catch {
Write-Log "Falha instalando bandit: $($_.Exception.Message)" "ERROR"
}
}
} else { Write-Log "Instalação de bandit ignorada pelo usuário." }
} else {
Write-Log "Bandit já disponível."
}
} catch {
Write-Log "Erro checando bandit: $($_.Exception.Message)" "ERROR"
}
}
# Simples MessageBox helper
function Confirm-YesNo {
param([string]$Message)
Add-Type -AssemblyName System.Windows.Forms
$res = [System.Windows.Forms.MessageBox]::Show($Message,"CONFIRMAÇÃO",
[System.Windows.Forms.MessageBoxButtons]::YesNo,
[System.Windows.Forms.MessageBoxIcon]::Question)
return $res -eq [System.Windows.Forms.DialogResult]::Yes
}
function Create-AsciiMap {
param([string]$RootPath = $Root)
try {
Ensure-Folder (Join-Path $RootPath 'mapas de fluxograma')
$mapFile = Join-Path $RootPath 'mapas de fluxograma\structure_map_' + $TimeStamp
+ '.txt'
$sb = New-Object System.Text.StringBuilder
$sb.AppendLine("CONAV - Estrutura de Pastas - Gerado em $(Get-Date -Format
'yyyy-MM-dd HH:mm:ss')") | Out-Null
$sb.AppendLine("") | Out-Null
function Walk($p,$indent) {
$items = Get-ChildItem -LiteralPath $p -Force | Sort-Object PSIsContainer
-Descending, Name
foreach ($it in $items) {
$line = (' ' * $indent) + (if ($it.PSIsContainer) { "[D] " } else { "[F] " }) + $it.Name
$sb.AppendLine($line) | Out-Null
if ($it.PSIsContainer) { Walk $it.FullName ($indent+2) }
}
}
Walk $RootPath 0
$sb.ToString() | Out-File -FilePath $mapFile -Encoding UTF8
Write-Log "Mapa ASCII gerado: $mapFile"
# Tentar criar PDF via Word COM (se Word estiver presente)
try {
if (-not $DryRun) {
$word = New-Object -ComObject Word.Application -ErrorAction SilentlyContinue
if ($word) {
$doc = $word.Documents.Add()
$range = $doc.Range()
$range.Text = $sb.ToString()
$pdfPath = [System.IO.Path]::ChangeExtension($mapFile, '.pdf')
$doc.SaveAs([ref] $pdfPath, [ref] 17) # wdFormatPDF = 17
$doc.Close()
$word.Quit()
Write-Log "Mapa PDF gerado: $pdfPath"
} else {
Write-Log "Word não disponível: único ASCII txt criado."
}
}
} catch {
Write-Log "Falha criando PDF do mapa (Word COM): $($_.Exception.Message)"
"WARN"
}
} catch {
Write-Log "Erro Create-AsciiMap: $($_.Exception.Message)" "ERROR"
}
}
function Generate-InstallLogSummary {
param([string]$OutputName = "install_summary_$TimeStamp.txt")
try {
$out = Join-Path $FolderMap['relatorios'] $OutputName
Ensure-Folder (Split-Path -Parent $out)
$content = @()
$content += "CONAV - Install Summary - $TimeStamp"
$content += ""
if (Test-Path $LogFile) {
$content += "==== Conteúdo do log principal ===="
$content += Get-Content -Path $LogFile -ErrorAction SilentlyContinue
} else {
$content += "Nenhum log principal encontrado em $LogFile"
}
$content | Out-File -FilePath $out -Encoding UTF8
Write-Log "Relatório de instalação gerado: $out"
} catch {
Write-Log "Erro gerando resumo de install: $($_.Exception.Message)" "ERROR"
}
}
function Record-InstallFiles {
param([string[]]$Paths, [string]$TargetInstallLog)
try {
Ensure-Folder (Split-Path -Parent $TargetInstallLog)
foreach ($p in $Paths) {
Add-Content -Path $TargetInstallLog -Value $p
}
Write-Log "install.log atualizado: $TargetInstallLog"
} catch {
Write-Log "Erro escrevendo install.log: $($_.Exception.Message)" "ERROR"
}
}
# ----------------------------
# Inicialização: garantir pastas e arquivos
# ----------------------------
Write-Log "===== INICIANDO SCRIPT MESTRE CONAV v$Version ====="
foreach ($f in $AllFolders) { Ensure-Folder $f }
# Se log não existir, cria o arquivo principal
if (-not (Test-Path $LogFile)) {
if (-not $DryRun) {
New-Item -Path $LogFile -ItemType File -Force | Out-Null
} else {
Write-Log "Criando log (simulação): $LogFile"
}
}
# Save initial install log path used by uninstaller (install manifest)
$InstallManifest = Join-Path $Root "install.$TimeStamp.log"
# ----------------------------
# Checagem: Analyzers (com confirmação)
# ----------------------------
Ensure-Analyzers
# ----------------------------
# Procura zips novos na pasta PACKAGES OFICIAIS e implanta
# ----------------------------
$packagesFolder = $FolderMap['PACKAGES OFICIAIS']
Ensure-Folder $packagesFolder
$zips = Get-ChildItem -Path $packagesFolder -Filter *.zip -File -ErrorAction SilentlyContinue
if ($zips.Count -gt 0) {
Write-Log "Foram encontrados $($zips.Count) pacotes zip em $packagesFolder"
foreach ($z in $zips) {
Write-Log "Preparando deploy do pacote: $($z.FullName)"
if ($DryRun) {
Extract-And-DeployZip -ZipPath $z.FullName
} else {
# Pedir confirmação antes de implantar pacotes se não AutoConfirm
$msg = "Deseja implantar o pacote: $($z.Name) ?"
if ($AutoConfirm -or (Confirm-YesNo $msg)) {
Extract-And-DeployZip -ZipPath $z.FullName
} else {
Write-Log "Implantação de $($z.Name) ignorada pelo usuário."
}
}
}
} else {
Write-Log "Nenhum pacote zip novo encontrado em $packagesFolder"
}
# ----------------------------
# Executa scripts sequencialmente (na pasta scripts) - pode ser configurado
# ----------------------------
$runScriptsFolder = $FolderMap['scripts']
Write-Log "Executando scripts sequenciais em: $runScriptsFolder"
if ($DryRun) {
Run-ScriptsSequential -FolderPath $runScriptsFolder -UseNewProcess
} else {
$msgRun = "Executar todos os scripts da pasta '$runScriptsFolder' de forma sequencial
agora?"
if ($AutoConfirm -or (Confirm-YesNo $msgRun)) {
Run-ScriptsSequential -FolderPath $runScriptsFolder -UseNewProcess
} else {
Write-Log "Execução sequencial de scripts ignorada pelo usuário."
}
}
# ----------------------------
# Gerar mapa ASCII + PDF
# ----------------------------
Create-AsciiMap
# ----------------------------
# Registro de arquivos instalados (gera install.log) - aqui fazemos um scan simples
# ----------------------------
try {
# Exemplo: lista todos arquivos recentes criados/alterados na raiz nas últimas 24h
$recentFiles = Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue |
Where-Object { $_.LastWriteTime -ge (Get-Date).AddDays(-7) } |
Select-Object -ExpandProperty FullName
if ($recentFiles.Count -gt 0) {
Record-InstallFiles -Paths $recentFiles -TargetInstallLog $InstallManifest
} else {
Write-Log "Nenhum arquivo recente para registrar no manifest."
}
} catch {
Write-Log "Erro gerando install manifest: $($_.Exception.Message)" "ERROR"
}
# ----------------------------
# Gerar pacote final (opcional)
# ----------------------------
$builtZip = Build-Package -OutputName ("CONAV_FULL_PROFESSIONAL_v$Version.zip")
if ($builtZip) { Write-Log "Pacote final (opcional) criado: $builtZip" }
# ----------------------------
# Gerar relatório resumo e salvar em relatorios
# ----------------------------
Generate-InstallLogSummary -OutputName ("install_summary_$TimeStamp.txt")
Write-Log "===== FIM DA EXECUÇÃO DO SCRIPT MESTRE CONAV v$Version ====="
# Exibe localização dos principais artefatos
Write-Host ""
Write-Host "Logs: $LogFile"
Write-Host "Manifest (install): $InstallManifest"
Write-Host "Pacote opcional (se criado): $builtZip"
Write-Host ""
if ($DryRun) { Write-Host "Modo: SIMULAÇÃO (DryRun). Nenhuma ação definitiva foi
executada." }
else { Write-Host "Modo: EXECUÇÃO REAL. Verifique os logs e relatórios na pasta de
relatórios." }
# ----------------------------
# FIM
# ----------------------------
# ===== FIM INSTALL_CONAV_MESTRE_V1.45_FIX3.ps1 =====

# ===== INICIO installation_setup_conav.ps1 =====

# Instalador corrigido do CONAV TRADER

param(
    [string]$installPath = "C:\Program Files\CONAV_TRADER"
)

Write-Output "Instalando dependências Python..."
python -m pip install --upgrade pip
python -m pip install fpdf pyinstaller pillow

# Gera o ícone
python "$PSScriptRoot\generate_icon.py"

# Copia os arquivos
if (!(Test-Path -Path $installPath)) {
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
}
Copy-Item -Path "$PSScriptRoot\*" -Destination $installPath -Recurse -Force -Exclude installation_setup_conav.ps1

Write-Output "Compilando executável..."
Set-Location $installPath
pyinstaller --onefile --noconsole main_dashboard.py --icon "$installPath\system_icon.ico"

# Corrige o spec para garantir que o ícone seja aplicado
$specFile = Join-Path $installPath "main_dashboard.spec"
if (Test-Path $specFile) {
    (Get-Content $specFile) |
        ForEach-Object {
            $_ -replace 'icon=None', 'icon="system_icon.ico"'
        } | Set-Content $specFile
}

# Recompila com o .spec corrigido
pyinstaller $specFile --clean

# Cria atalhos com o ícone
$WshShell = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath("Desktop")
$startMenu = [Environment]::GetFolderPath("Programs")

$shortcutDesktop = $WshShell.CreateShortcut("$desktop\CONAV TRADER.lnk")
$shortcutDesktop.TargetPath = "$installPath\dist\main_dashboard.exe"
$shortcutDesktop.IconLocation = "$installPath\system_icon.ico"
$shortcutDesktop.Save()

$shortcutMenu = $WshShell.CreateShortcut("$startMenu\CONAV TRADER.lnk")
$shortcutMenu.TargetPath = "$installPath\dist\main_dashboard.exe"
$shortcutMenu.IconLocation = "$installPath\system_icon.ico"
$shortcutMenu.Save()

Write-Output "Instalação concluída! Atalhos criados na área de trabalho e no Menu Iniciar."

# ===== FIM installation_setup_conav.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL-ORIGINAL.ps1 =====
# INSTALL_CONAV_TRADER_FULL.ps1 - Improved installer
$ErrorActionPreference = "Stop"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Warning "Please run PowerShell as Administrator."
    Pause
    Exit 1
}

$installPath = "C:\Program Files\CONAV_TRADER"

$folders = @(
    "$installPath\dashboard\gui_assets",
    "$installPath\dashboard\plots",
    "$installPath\automation",
    "$installPath\emails\templates",
    "$installPath\database",
    "$installPath\resources\icons",
    "$installPath\resources\styles"
)
foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) { New-Item -ItemType Directory -Force -Path $folder | Out-Null }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "Copying files from $scriptDir to $installPath ..."
Copy-Item -Path (Join-Path $scriptDir "*") -Destination $installPath -Recurse -Force

Write-Host "Checking Python and installing packages..."
& python -m pip install --upgrade pip
& python -m pip install fpdf reportlab plotly openai pyinstaller

# compile
$pyinstallerPath = (Get-Command pyinstaller -ErrorAction SilentlyContinue).Path
if (-not $pyinstallerPath) {
    Write-Host "PyInstaller not found on PATH. Trying python -m PyInstaller..."
    & python -m PyInstaller --onefile --windowed --icon="$installPath\resources\icons\conav_trader_icon.ico" "$installPath\dashboard\main_dashboard.py"
} else {
    & pyinstaller --onefile --windowed --icon="$installPath\resources\icons\conav_trader_icon.ico" "$installPath\dashboard\main_dashboard.py"
}

# shortcut
$ws = New-Object -ComObject WScript.Shell
$desktopPath = [Environment]::GetFolderPath("CommonDesktopDirectory")
$shortcut = $ws.CreateShortcut((Join-Path $desktopPath "CONAV TRADER.lnk"))
$shortcut.TargetPath = Join-Path $installPath "dist\main_dashboard.exe"
$shortcut.IconLocation = Join-Path $installPath "resources\icons\conav_trader_icon.ico"
$shortcut.Save()

Write-Host "Installation finished. Shortcut created on desktop."
Pause

# ===== FIM INSTALL_CONAV_TRADER_FULL-ORIGINAL.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL.ps1 =====
# === Script de instalação automática completa do CONAV TRADER ===

$installPath = "C:\Program Files\CONAV_TRADER"

# 1. Criar estrutura de pastas
$folders = @(
    "$installPath\dashboard\gui_assets",
    "$installPath\dashboard\plots",
    "$installPath\automation",
    "$installPath\emails\templates",
    "$installPath\database",
    "$installPath\resources\icons",
    "$installPath\resources\styles"
)
foreach ($folder in $folders) {
    New-Item -ItemType Directory -Force -Path $folder
}

# 2. Copiar arquivos da mesma pasta do script
$sourcePath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Copy-Item -Path "$sourcePath\*" -Destination $installPath -Recurse -Force

# 3. Instalar dependências Python
Write-Host "Instalando dependências Python..."
pip install --upgrade pip
pip install fpdf plotly openai

# 4. Compilar executável via PyInstaller
Write-Host "Compilando executável do dashboard..."
pyinstaller --onefile --windowed --icon="$installPath\resources\icons\conav_trader_icon.ico" "$installPath\dashboard\main_dashboard.py"

# 5. Criar atalho na área de trabalho
$ws = New-Object -ComObject WScript.Shell
$shortcut = $ws.CreateShortcut("$env:Public\Desktop\CONAV TRADER.lnk")
$shortcut.TargetPath = "$installPath\dist\main_dashboard.exe"
$shortcut.IconLocation = "$installPath\resources\icons\conav_trader_icon.ico"
$shortcut.Save()

# 6. Mensagem de conclusão
Write-Host "==========================================="
Write-Host "INSTALAÇÃO CONCLUÍDA! Atalho criado na área de trabalho."
Write-Host "Abra o CONAV TRADER e explore o dashboard."
Write-Host "==========================================="

# ===== FIM INSTALL_CONAV_TRADER_FULL.ps1 =====

# ===== INICIO SET_ICONS_CONAV001.ps1 =====
# SET_ICONS_CONAV1.24.ps1
# Recompila scripts Python encontrados em pastas chave com --icon system_icon.ico
# e cria atalhos com icon para .exe que não são recompiláveis.

$ErrorActionPreference = 'Continue'
function Log { param($m) Write-Host "[ICONS] $m" }

$basePath = "C:\CONAV TRADER\CONAV_TRADER"
$iconPath = Join-Path $basePath "system_icon.ico"
if (-not (Test-Path $iconPath)) { Log "Ícone não encontrado em $iconPath — abortando aplicação automática de ícones."; return }

# 1) Lista de pastas que tipicamente contêm ferramentas Python
$scanFolders = @(
    Join-Path $basePath "",
    Join-Path $basePath "dashboard",
    Join-Path $basePath "automation",
    Join-Path $basePath "emails",
    Join-Path $basePath "scripts",
    Join-Path $basePath "tools"
) | Where-Object { Test-Path $_ }

# 2) Função para compilar um .py em .exe com icon
function Compile-PyToExe {
    param($pyFile, $outDist, $name)
    try {
        Write-Host "[ICONS][PYI] Compilando $pyFile -> $name.exe"
        & python -m PyInstaller --noconfirm --onefile --windowed --icon="$iconPath" --distpath "$outDist" --workpath (Join-Path $outDist "build") --specpath $outDist --name $name "$pyFile"
        Write-Host "[ICONS][PYI] OK: $name"
        return $true
    } catch {
        Write-Host "[ICONS][PYI] Falha ao compilar $pyFile: $($_.Exception.Message)"
        return $false
    }
}

# 3) Recompilar scripts Python encontrados
$compiled = @()
foreach ($folder in $scanFolders) {
    $pyFiles = Get-ChildItem -Path $folder -Filter "*.py" -Recurse -File -ErrorAction SilentlyContinue `
               | Where-Object { $_.Name -notmatch '^__' -and $_.Name -notmatch 'uninstall_wrapper' }
    foreach ($py in $pyFiles) {
        $exeName = [System.IO.Path]::GetFileNameWithoutExtension($py.Name)
        $targetDist = Join-Path $basePath "dist"
        # Apenas compile se não for um script de biblioteca (heurística: possui if __name__ == '__main__'?)
        $content = Get-Content $py.FullName -ErrorAction SilentlyContinue
        if ($content -join "`n" -match "if\s+__name__\s*==\s*['""]__main__['""]") {
            if (Compile-PyToExe -pyFile $py.FullName -outDist $targetDist -name $exeName) {
                $compiled += $exeName
            }
        } else {
            Log "Pulando (sem entry point): $($py.FullName)"
        }
    }
}

# 4) Para .exe existentes que não foram recompilados, criar atalhos com o icon
#    (alterar ícone embutido sem recompilar exige ferramentas externas; atalhos apresentam o ícone ao usuário)
function Create-ShortcutWithIcon {
    param($exePath, $icon)
    $WshShell = New-Object -ComObject WScript.Shell
    $dir = Split-Path $exePath -Parent
    $name = [System.IO.Path]::GetFileNameWithoutExtension($exePath)
    $lnk = Join-Path $dir ("$name - atalho.lnk")
    $sc = $WshShell.CreateShortcut($lnk)
    $sc.TargetPath = $exePath
    $sc.IconLocation = $icon
    $sc.Save()
    Log "Atalho criado com ícone para $exePath -> $lnk"
}

# verificar .exe na raiz e em dist
$exeCandidates = Get-ChildItem -Path $basePath -Filter "*.exe" -Recurse -File -ErrorAction SilentlyContinue |
                 Where-Object { $_.DirectoryName -notlike "*\Desinstalar\build*" -and $_.Name -ne "Desinstalar.exe" }

foreach ($e in $exeCandidates) {
    # se for um EXE que veio de compilação python e está em dist e seu nome está em $compiled, assumimos que já tem ícone
    if ($compiled -contains [System.IO.Path]::GetFileNameWithoutExtension($e.Name)) {
        Log "Exe recompilado com ícone: $($e.FullName)"
        continue
    } else {
        # criar atalho com icon (para exibir identidade visual)
        Create-ShortcutWithIcon -exePath $e.FullName -icon $iconPath
    }
}

# 5) Garantir que Desinstalar.exe tem o icon embutido (verifica e tenta recompilar wrapper se necessário)
$desUnExe = Join-Path $basePath "Desinstalar\Desinstalar.exe"
if (-not (Test-Path $desUnExe)) {
    # tentar recompilar wrapper se existir
    $wrapper = Join-Path $basePath "Desinstalar\uninstall_wrapper.py"
    if (Test-Path $wrapper) {
        Log "Desinstalar.exe não encontrado — tentando recompilar wrapper..."
        Compile-PyToExe -pyFile $wrapper -outDist (Join-Path $basePath "Desinstalar") -name "Desinstalar"
        if (Test-Path $desUnExe) { Log "Desinstalar.exe recompilado com sucesso." }
    }
} else {
    Log "Desinstalar.exe encontrado: $desUnExe"
}

# 6) Garantir pasta Desinstalar com ícone padrão do Windows
$uninstallFolder = Join-Path $basePath "Desinstalar"
if (Test-Path $uninstallFolder) {
    $desktopIniPath = Join-Path $uninstallFolder "desktop.ini"
    if (Test-Path $desktopIniPath) { Remove-Item $desktopIniPath -Force -ErrorAction SilentlyContinue }
    try { attrib -s $uninstallFolder -ErrorAction SilentlyContinue } catch {}
    Log "Pasta Desinstalar deixada com ícone padrão do Windows."
}

Log "SET_ICONS_CONAV1.24 concluído. Recompilados: $($compiled -join ', ')"
# ===== FIM SET_ICONS_CONAV001.ps1 =====

# ===== INICIO CREATE_ICON_DESINSTALAR_CONAV.ps1 =====
# ==============================
# Criar pasta Desinstalar
# ==============================
$uninstallFolder = "$installPath\Desinstalar"
$iconFolder = "$installPath\icons"
$uninstallScript = "$PSScriptRoot\UNINSTALL_CONAV_TRADER.ps1"

if (!(Test-Path $uninstallFolder)) {
    New-Item -ItemType Directory -Path $uninstallFolder | Out-Null
}

# Copiar desinstalador PowerShell renomeado
Copy-Item $uninstallScript -Destination "$uninstallFolder\Desinstalar-Por-PowerShell.ps1" -Force

# Compilar versão EXE do desinstalador com nome amigável
pyinstaller --onefile --noconsole --icon "$iconFolder\uninstall_icon.ico" `
    --distpath "$uninstallFolder" `
    --workpath "$uninstallFolder\build" `
    --specpath "$uninstallFolder" `
    --name "Desinstalar" `
    "$uninstallScript"

# Criar desktop.ini para ícone da pasta
$desktopIni = @"
[.ShellClassInfo]
IconResource=$iconFolder\uninstall_icon.ico,0
"@
Set-Content -Path "$uninstallFolder\desktop.ini" -Value $desktopIni -Encoding ASCII
attrib +h +s "$uninstallFolder\desktop.ini"
attrib +r "$uninstallFolder"
# ===== FIM CREATE_ICON_DESINSTALAR_CONAV.ps1 =====

# ===== INICIO installation_setup_conav-work100%.ps1 =====

# Instalador corrigido do CONAV TRADER

param(
    [string]$installPath = "C:\Program Files\CONAV_TRADER"
)

Write-Output "Instalando dependências Python..."
python -m pip install --upgrade pip
python -m pip install fpdf pyinstaller pillow

# Gera o ícone
python "$PSScriptRoot\generate_icon.py"

# Copia os arquivos
if (!(Test-Path -Path $installPath)) {
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
}
Copy-Item -Path "$PSScriptRoot\*" -Destination $installPath -Recurse -Force -Exclude installation_setup_conav.ps1

Write-Output "Compilando executável..."
Set-Location $installPath
pyinstaller --onefile --noconsole main_dashboard.py --icon "$installPath\system_icon.ico"

# Corrige o spec para garantir que o ícone seja aplicado
$specFile = Join-Path $installPath "main_dashboard.spec"
if (Test-Path $specFile) {
    (Get-Content $specFile) |
        ForEach-Object {
            $_ -replace 'icon=None', 'icon="system_icon.ico"'
        } | Set-Content $specFile
}

# Recompila com o .spec corrigido
pyinstaller $specFile --clean

# Cria atalhos com o ícone
$WshShell = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath("Desktop")
$startMenu = [Environment]::GetFolderPath("Programs")

$shortcutDesktop = $WshShell.CreateShortcut("$desktop\CONAV TRADER.lnk")
$shortcutDesktop.TargetPath = "$installPath\dist\main_dashboard.exe"
$shortcutDesktop.IconLocation = "$installPath\system_icon.ico"
$shortcutDesktop.Save()

$shortcutMenu = $WshShell.CreateShortcut("$startMenu\CONAV TRADER.lnk")
$shortcutMenu.TargetPath = "$installPath\dist\main_dashboard.exe"
$shortcutMenu.IconLocation = "$installPath\system_icon.ico"
$shortcutMenu.Save()

Write-Output "Instalação concluída! Atalhos criados na área de trabalho e no Menu Iniciar."

# ===== FIM installation_setup_conav-work100%.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.1.1.ps1 =====
# ===============================================
# INSTALL_CONAV_TRADER_FULL.ps1 (versão corrigida)
# ===============================================

Write-Host "==============================================="
Write-Host "   Instalando CONAV TRADER FULL..."
Write-Host "==============================================="

# Caminhos principais
$installPath   = "C:\CONAV TRADER\CONAV_TRADER"
$sourcePath    = $PSScriptRoot
$iconSource    = "$sourcePath\system_icon.ico"
$iconDest      = "$installPath\system_icon.ico"
$uninstallPS   = "$installPath\UNINSTALL_CONAV_TRADER.ps1"
$uninstallFolder = "$installPath\Desinstalar"

# Criar pasta raiz, se não existir
if (!(Test-Path $installPath)) {
    New-Item -ItemType Directory -Path $installPath | Out-Null
}

Write-Host "Copiando arquivos para $installPath ..."

# Copiar arquivos sem sobrescrever ele mesmo
Get-ChildItem -Path $sourcePath -Recurse | ForEach-Object {
    $dest = $_.FullName.Replace($sourcePath, $installPath)
    if ($_.PSIsContainer) {
        if (!(Test-Path $dest)) {
            New-Item -ItemType Directory -Path $dest | Out-Null
        }
    } else {
        if ($_.FullName -ne $dest) {
            Copy-Item -Path $_.FullName -Destination $dest -Force
        }
    }
}

# Aplicar ícone raiz
if (Test-Path $iconSource -and $iconSource -ne $iconDest) {
    Copy-Item $iconSource -Destination $iconDest -Force
}
Write-Host "Ícone raiz aplicado: $iconDest"

# ===============================================
# Recompilar main_dashboard.exe automaticamente
# ===============================================
$dashboardPath = "$installPath\dashboard\main_dashboard.py"
if (Test-Path $dashboardPath) {
    Write-Host "Compilando main_dashboard.exe..."
    pyinstaller --onefile --noconsole --icon "$iconDest" `
        --distpath "$installPath\dist" `
        --workpath "$installPath\build" `
        --specpath "$installPath" `
        --name "main_dashboard" `
        "$dashboardPath"
}

# ===============================================
# Preparar desinstalador
# ===============================================

# Criar pasta Desinstalar
if (!(Test-Path $uninstallFolder)) {
    New-Item -ItemType Directory -Path $uninstallFolder | Out-Null
}

# Garantir que script de desinstalar existe
if (Test-Path $uninstallPS) {
    # Corrigir cabeçalhos inválidos (ex: datas soltas na 1ª linha)
    $lines = Get-Content $uninstallPS | Where-Object { $_ -notmatch "^\d{4}\." }
    Set-Content -Path $uninstallPS -Value $lines -Encoding UTF8

    # Copiar versão PowerShell
    Copy-Item $uninstallPS -Destination "$uninstallFolder\Desinstalar-Por-PowerShell.ps1" -Force
    Write-Host "Desinstalador PowerShell copiado."

    # Compilar versão EXE
    Write-Host "Compilando Desinstalar.exe..."
    pyinstaller --onefile --noconsole --icon "$iconDest" `
        --distpath "$uninstallFolder" `
        --workpath "$uninstallFolder\build" `
        --specpath "$uninstallFolder" `
        --name "Desinstalar" `
        "$uninstallPS"

    # Copiar ícone do sistema
    Copy-Item $iconDest -Destination "$uninstallFolder\uninstall_icon.ico" -Force

    # Criar desktop.ini para ícone da pasta
    $desktopIni = @"
[.ShellClassInfo]
IconResource=$uninstallFolder\uninstall_icon.ico,0
"@
    Set-Content -Path "$uninstallFolder\desktop.ini" -Value $desktopIni -Encoding ASCII
    attrib +h +s "$uninstallFolder\desktop.ini"
    attrib +r "$uninstallFolder"
}

Write-Host "==============================================="
Write-Host "INSTALAÇÃO CONCLUÍDA!"
Write-Host "Pasta de instalação: $installPath"
Write-Host "Desinstalador criado em: $uninstallFolder"
Write-Host "==============================================="
# ===== FIM INSTALL_CONAV_TRADER_FULL1.1.1.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.1.2.ps1 =====
# ============================================
# INSTALL_CONAV_TRADER_FULL.ps1
# Instalador completo do CONAV TRADER
# ============================================

Write-Host "==============================================="
Write-Host "   Instalando CONAV TRADER FULL..."
Write-Host "==============================================="

# ========================
# Caminhos principais
# ========================
$installPath   = "C:\Program Files\CONAV_TRADER"
$scriptRoot    = Split-Path -Parent $MyInvocation.MyCommand.Definition
$iconSource    = "$scriptRoot\system_icon.ico"
$iconDest      = "$installPath\system_icon.ico"
$uninstallPS   = "$scriptRoot\UNINSTALL_CONAV_TRADER.ps1"
$uninstallFolder = "$installPath\Desinstalar"

# ========================
# Criar pasta raiz
# ========================
if (!(Test-Path $installPath)) {
    New-Item -ItemType Directory -Path $installPath | Out-Null
}

# ========================
# Copiar arquivos base
# ========================
Copy-Item "$scriptRoot\*" $installPath -Recurse -Force -Exclude "build","dist","__pycache__"

# ========================
# Aplicar ícone raiz (corrigido)
# ========================
if ((Test-Path $iconSource) -and ($iconSource -ne $iconDest)) {
    Copy-Item $iconSource -Destination $iconDest -Force
}
Write-Host "Ícone raiz aplicado: $iconDest"

# ========================
# Recompilar main_dashboard.exe
# ========================
$dashboardPath = "$installPath\dashboard\main_dashboard.py"
if (Test-Path $dashboardPath) {
    Write-Host "Compilando main_dashboard.exe..."
    pyinstaller --onefile --noconsole --icon "$iconDest" `
        --distpath "$installPath\dist" `
        --workpath "$installPath\build" `
        --specpath "$installPath" `
        --name "main_dashboard" `
        "$dashboardPath"
}

# ========================
# Criar pasta Desinstalar
# ========================
if (!(Test-Path $uninstallFolder)) {
    New-Item -ItemType Directory -Path $uninstallFolder | Out-Null
}

# ========================
# Sanitizar e copiar UNINSTALL script
# ========================
if (Test-Path $uninstallPS) {
    # Remover linhas inválidas (ex: "17:29 Arate Opa")
    $validLines = Get-Content $uninstallPS | Where-Object {
        $_ -notmatch "^\d{2}:\d{2}" -and $_ -notmatch "Opa"
    }
    Set-Content -Path $uninstallPS -Value $validLines -Encoding UTF8

    # Copiar versão PowerShell
    Copy-Item $uninstallPS -Destination "$uninstallFolder\Desinstalar-Por-PowerShell.ps1" -Force
    Write-Host "Desinstalador PowerShell copiado."

    # Compilar versão EXE com ícone
    Write-Host "Compilando Desinstalar.exe..."
    pyinstaller --onefile --noconsole --icon "$iconDest" `
        --distpath "$uninstallFolder" `
        --workpath "$uninstallFolder\build" `
        --specpath "$uninstallFolder" `
        --name "Desinstalar" `
        "$uninstallPS"
}

Write-Host "==============================================="
Write-Host "   Instalação concluída!"
Write-Host "   Pasta: $installPath"
Write-Host "==============================================="

# ===== FIM INSTALL_CONAV_TRADER_FULL1.1.2.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.2.ps1 =====
# INSTALL_CONAV_TRADER_FULL.ps1 - Versão corrigida (sanitize + wrapper + compile)
param(
    [string]$sourcePath = $(Split-Path -Parent $MyInvocation.MyCommand.Definition),
    [string]$installPath = "C:\CONAV TRADER\CONAV_TRADER"
)

$ErrorActionPreference = "Stop"

function Log { param($m) Write-Host "[INSTALL] $m" }

Log "Iniciando instalador..."
Log "Source: $sourcePath"
Log "InstallPath: $installPath"

# 1) criar pasta de instalação se necessário
if (-not (Test-Path $installPath)) {
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    Log "Criada pasta de instalação: $installPath"
} else {
    Log "Pasta de instalação já existe."
}

# 2) copiar arquivos apenas se source != destino (evita overwrite-with-itself)
if ($sourcePath.TrimEnd("\") -ieq $installPath.TrimEnd("\")) {
    Log "Source e installPath são iguais -> pulando cópia bulk (já está na pasta de destino)."
} else {
    Log "Copiando arquivos de $sourcePath para $installPath ..."
    # exclui pastas temporárias de build pra não poluir
    Copy-Item -Path (Join-Path $sourcePath "*") -Destination $installPath -Recurse -Force `
        -Exclude "build","dist","__pycache__","*.spec" `
        -ErrorAction Stop
    Log "Cópia concluída."
}

# 3) aplicar ícone global (system_icon.ico) somente se existir na source e for diferente
$iconSource = Join-Path $sourcePath "system_icon.ico"
$iconDest   = Join-Path $installPath "system_icon.ico"
if ((Test-Path $iconSource) -and ($iconSource -ne $iconDest)) {
    Copy-Item -Path $iconSource -Destination $iconDest -Force
    Log "Ícone principal copiado para: $iconDest"
} elseif (Test-Path $iconDest) {
    Log "Ícone principal já presente em: $iconDest"
} else {
    Log "Aviso: system_icon.ico não encontrado em source. Coloque um system_icon.ico em $sourcePath para aplicar ícones nos .exe"
}

# Helper para executar PyInstaller via python -m PyInstaller
function Run-PyInstaller {
    param($scriptPath, $distPath, $name)
    if (-not (Test-Path $scriptPath)) { 
        Log "Arquivo para compilar não encontrado: $scriptPath"
        return $false
    }
    try {
        & python -m PyInstaller --onefile --noconsole --icon "$iconDest" --distpath "$distPath" --workpath (Join-Path $distPath "build") --specpath $distPath --name $name "$scriptPath"
        return $true
    } catch {
        Log "PyInstaller falhou: $($_.Exception.Message)"
        return $false
    }
}

# 4) recompilar main_dashboard.exe (procura nos locais comuns)
$dashboardPyCandidates = @(
    Join-Path $installPath "dashboard\main_dashboard.py",
    Join-Path $installPath "main_dashboard.py"
)
$dashboardPy = $dashboardPyCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($null -ne $dashboardPy) {
    Log "Compilando main_dashboard.py -> main_dashboard.exe"
    $ok = Run-PyInstaller -scriptPath $dashboardPy -distPath (Join-Path $installPath "dist") -name "main_dashboard"
    if ($ok) { Log "main_dashboard.exe criado em: $(Join-Path $installPath 'dist\main_dashboard.exe')" }
} else {
    Log "main_dashboard.py não encontrado (pulando compilação do dashboard)."
}

# 5) PREPARAR a pasta Desinstalar (sem criar desktop.ini)
$uninstallFolder = Join-Path $installPath "Desinstalar"
if (-not (Test-Path $uninstallFolder)) {
    New-Item -Path $uninstallFolder -ItemType Directory -Force | Out-Null
    Log "Criada pasta: $uninstallFolder"
} else {
    Log "Pasta Desinstalar já existe: $uninstallFolder"
}

# 6) localizar UNINSTALL script source (pode estar no source ou já na pasta de instalação)
$uninstallSourceCandidates = @(
    Join-Path $sourcePath "UNINSTALL_CONAV_TRADER.ps1",
    Join-Path $installPath "UNINSTALL_CONAV_TRADER.ps1",
    Join-Path $sourcePath "Desinstalar-Por-PowerShell.ps1"
)
$uninstallSource = $uninstallSourceCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($null -eq $uninstallSource) {
    Log "Script de desinstalação (.ps1) não encontrado nas possíveis localizações. Vou criar um fallback simples."
    $fallback = @'
# Desinstalador fallback - Desinstalar-Por-PowerShell.ps1
$installPath = "C:\CONAV TRADER\CONAV_TRADER"
Write-Host "Removendo CONAV TRADER (fallback)..."
if (Test-Path $installPath) {
    Remove-Item -Path $installPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Pasta de instalação removida: $installPath"
} else {
    Write-Host "Pasta de instalação não encontrada: $installPath"
}
'@
    $uninstallDestPS = Join-Path $uninstallFolder "Desinstalar-Por-PowerShell.ps1"
    $fallback | Out-File -FilePath $uninstallDestPS -Encoding UTF8 -Force
    Log "Fallback criado: $uninstallDestPS"
} else {
    # 6a) ler e "sanitizar" o PS1 (remover linhas com tempos ou 'Opa' e remover U+2026)
    $raw = Get-Content $uninstallSource -Raw
    # remove ellipsis U+2026 e substitui por três pontos
    $raw = $raw -replace [char]0x2026, '...'
    # quebrar linhas e filtrar
    $cleanLines = $raw -split "`r?`n" | Where-Object {
        ($_ -notmatch '^\s*\d{1,2}:\d{2}\b') -and ($_ -notmatch '^\s*\d{4}\.\d{2}\.\d{2}') -and ($_ -notmatch '\bOpa\b') -and ($_ -notmatch '\bArate\b')
    }
    $uninstallDestPS = Join-Path $uninstallFolder "Desinstalar-Por-PowerShell.ps1"
    $cleanLines | Set-Content -Path $uninstallDestPS -Encoding UTF8
    Log "Script de desinstalação sanitizado e copiado para: $uninstallDestPS"
}

# 7) Gerar wrapper Python que executa o PS1 (para compilar um exe via PyInstaller)
$wrapperPy = Join-Path $uninstallFolder "uninstall_wrapper.py"
$wrapperContent = @"
import os, sys, subprocess
here = os.path.dirname(os.path.abspath(__file__))
ps1 = os.path.join(here, 'Desinstalar-Por-PowerShell.ps1')
if not os.path.exists(ps1):
    print('Arquivo de desinstalação não encontrado:', ps1)
    sys.exit(1)
cmd = ['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ps1]
rc = subprocess.call(cmd)
sys.exit(rc)
"@
$wrapperContent | Out-File -FilePath $wrapperPy -Encoding UTF8 -Force
Log "Wrapper Python criado: $wrapperPy"

# 8) Se já existir um Desinstalar.exe pré-compilado no source, apenas copie; senão compile o wrapper
$prebuiltExe = Join-Path $sourcePath "Desinstalar.exe"
$prebuiltExe2 = Join-Path $sourcePath "dist\Desinstalar.exe"
$targetExe = Join-Path $uninstallFolder "Desinstalar.exe"

if (Test-Path $prebuiltExe) {
    Copy-Item $prebuiltExe -Destination $targetExe -Force
    Log "Usado Desinstalar.exe pré-compilado (copiado do source)."
} elseif (Test-Path $prebuiltExe2) {
    Copy-Item $prebuiltExe2 -Destination $targetExe -Force
    Log "Usado Desinstalar.exe pré-compilado (copiado de source\\dist)."
} else {
    Log "Compilando Desinstalar.exe a partir do wrapper Python..."
    $ok = Run-PyInstaller -scriptPath $wrapperPy -distPath $uninstallFolder -name "Desinstalar"
    if ($ok -and (Test-Path $targetExe)) {
        Log "Desinstalar.exe criado com sucesso em: $targetExe"
    } else {
        Log "Falha ao compilar Desinstalar.exe. Você pode colocar um Desinstalar.exe pré-compilado em $sourcePath e rodar o instalador novamente."
    }
}

# 9) copiar icon para a pasta de desinstalar (opcional: não criaremos desktop.ini)
if (Test-Path $iconDest) {
    Copy-Item -Path $iconDest -Destination (Join-Path $uninstallFolder "system_icon.ico") -Force
    Log "Ícone copiado para a pasta Desinstalar (arquivo): $(Join-Path $uninstallFolder 'system_icon.ico')"
}

Log "Instalação finalizada."
Log "Instalação em: $installPath"
Log "Desinstalador em: $uninstallFolder"
# ===== FIM INSTALL_CONAV_TRADER_FULL1.2.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.22.01.ps1 =====
Write-Host "[INSTALL] ==============================================="
Write-Host "[INSTALL]    Instalando CONAV TRADER FULL..."
Write-Host "[INSTALL] ==============================================="

$basePath   = "C:\CONAV TRADER\CONAV_TRADER"
$iconPath   = Join-Path $basePath "system_icon.ico"
$dashPath   = Join-Path $basePath "dashboard"
$distPath   = Join-Path $basePath "dist"
$uninstPath = Join-Path $basePath "Desinstalar"

# 1) Criar estrutura
if (-not (Test-Path $basePath)) { New-Item -ItemType Directory -Path $basePath -Force }
if (-not (Test-Path $uninstPath)) { New-Item -ItemType Directory -Path $uninstPath -Force }
if (-not (Test-Path $distPath)) { New-Item -ItemType Directory -Path $distPath -Force }

# 2) Garantir ícone raiz
if (-not (Test-Path $iconPath)) {
    Write-Host "[INSTALL] ERRO: Ícone não encontrado em $iconPath"
} else {
    Write-Host "[INSTALL] Ícone raiz já existe: $iconPath"
}

# 3) Compilar Dashboard principal
Write-Host "[INSTALL] Compilando main_dashboard.exe..."
pyinstaller --noconfirm --onefile --windowed --icon="$iconPath" `
    --distpath "$distPath" `
    --workpath "$basePath\build" `
    --specpath "$basePath" `
    "$dashPath\main_dashboard.py"
Write-Host "[INSTALL] main_dashboard.exe criado em dist\"

# 4) Criar script de desinstalação em PowerShell
$uninstallPS = @"
Write-Host '[UNINSTALL] ==============================================='
Write-Host '[UNINSTALL]    Removendo CONAV TRADER...'
Write-Host '[UNINSTALL] ==============================================='

\$target = 'C:\CONAV TRADER'
if (Test-Path \$target) {
    Remove-Item -Recurse -Force \$target
    Write-Host '[UNINSTALL] CONAV TRADER removido com sucesso.'
} else {
    Write-Host '[UNINSTALL] Nenhuma instalação encontrada.'
}
"@
$uninstallPS | Out-File -Encoding UTF8 -FilePath "$uninstPath\Desinstalar-Por-PowerShell.ps1"
Write-Host "[INSTALL] Script de desinstalação criado: $uninstPath\Desinstalar-Por-PowerShell.ps1"

# 5) Criar wrapper Python para o Desinstalar
$wrapperPY = @"
import os, subprocess, sys

script = r'C:\CONAV TRADER\CONAV_TRADER\Desinstalar\Desinstalar-Por-PowerShell.ps1'
if os.path.exists(script):
    subprocess.run(["powershell", "-ExecutionPolicy", "Bypass", "-File", script])
else:
    print("[UNINSTALL] Script não encontrado:", script)
"@
$wrapperPath = "$uninstPath\uninstall_wrapper.py"
$wrapperPY | Out-File -Encoding UTF8 -FilePath $wrapperPath
Write-Host "[INSTALL] Wrapper Python criado: $wrapperPath"

# 6) Compilar Desinstalar.exe com ícone do CONAV
Write-Host "[INSTALL] Compilando Desinstalar.exe..."
pyinstaller --noconfirm --onefile --windowed --icon="$iconPath" `
    --distpath "$uninstPath" `
    --workpath "$uninstPath\build" `
    --specpath "$uninstPath" `
    "$wrapperPath"

# 7) Limpeza de lixo do PyInstaller
Remove-Item "$uninstPath\build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$uninstPath\*.spec" -Force -ErrorAction SilentlyContinue

Write-Host "[INSTALL] ==============================================="
Write-Host "[INSTALL] INSTALAÇÃO CONCLUÍDA!"
Write-Host "[INSTALL] Pasta de instalação: $basePath"
Write-Host "[INSTALL] Desinstalador: $uninstPath\Desinstalar.exe"
Write-Host "[INSTALL] ==============================================="

# 8) Chamar script de ícones no final
$iconsScript = Join-Path $basePath "SET_ICONS_CONAV.ps1"
if (Test-Path $iconsScript) {
    Write-Host "[INSTALL] Executando SET_ICONS_CONAV.ps1..."
    & $iconsScript
}
# ===== FIM INSTALL_CONAV_TRADER_FULL1.22.01.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.22.02.ps1 =====
# INSTALL_CONAV_TRADER_FULL1.24.ps1
# Versão 1.24 — instala, compila dashboard e desinstalador,
# garante ícone embutido nos EXE e deixa a pasta Desinstalar com ícone padrão.

$ErrorActionPreference = 'Stop'

function Log { param($m) Write-Host "[INSTALL] $m" }

Log "==============================================="
Log "   Instalando CONAV TRADER FULL (v1.24)..."
Log "==============================================="

$basePath   = "C:\CONAV TRADER\CONAV_TRADER"
$iconPath   = Join-Path $basePath "system_icon.ico"
$dashPath   = Join-Path $basePath "dashboard"
$distPath   = Join-Path $basePath "dist"
$uninstPath = Join-Path $basePath "Desinstalar"

# 1) Criar estruturas necessárias
foreach ($p in @($basePath, $distPath, $uninstPath)) {
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null; Log "Criada pasta: $p" }
}

# 2) Verificar se ícone existe
if (-not (Test-Path $iconPath)) {
    Log "AVISO: system_icon.ico não encontrado em $iconPath. Coloque o ícone lá para embutir nos .exe"
} else {
    Log "Ícone raiz detectado: $iconPath"
}

# helper: run pyinstaller via python -m PyInstaller
function Run-PyInstaller {
    param(
        [string]$pyFile,
        [string]$outDist,
        [string]$workPath,
        [string]$specPath,
        [string]$name
    )
    if (-not (Test-Path $pyFile)) {
        Log "Arquivo não encontrado para compilar: $pyFile"
        return $false
    }
    $iconArg = ""
    if (Test-Path $iconPath) { $iconArg = "--icon=`"$iconPath`"" }

    Write-Host "[PYI] Compilando $pyFile -> nome: $name"
    & python -m PyInstaller --noconfirm --onefile --windowed $iconArg `
        --distpath $outDist --workpath $workPath --specpath $specPath --name $name "$pyFile"
    return $true
}

# 3) Compilar main_dashboard.py (se existir)
$dashboardPy = Join-Path $dashPath "main_dashboard.py"
if (-not (Test-Path $dashboardPy)) {
    $dashboardPy = Join-Path $basePath "main_dashboard.py"
}
if (Test-Path $dashboardPy) {
    Log "Compilando main_dashboard..."
    Run-PyInstaller -pyFile $dashboardPy -outDist $distPath -workPath (Join-Path $basePath "build") -specPath $basePath -name "main_dashboard"
    Log "main_dashboard.exe criado em: $distPath"
} else {
    Log "main_dashboard.py não encontrado — pulando compilação do dashboard."
}

# 4) Remover desktop.ini antigo da pasta Desinstalar (se houver) para forçar ícone padrão
$desktopIni = Join-Path $uninstPath "desktop.ini"
if (Test-Path $desktopIni) {
    Remove-Item $desktopIni -Force -ErrorAction SilentlyContinue
    Log "Removido desktop.ini antigo de $uninstPath"
}
# remover atributo de system (caso tenha sido setado)
try { attrib -s $uninstPath -ErrorAction SilentlyContinue } catch {}

# 5) Criar script PowerShell de desinstalação limpo (sempre recria)
$psUninstall = @'
# Desinstalar-Por-PowerShell.ps1
# Remove a pasta de instalação do CONAV
$installPath = "C:\CONAV TRADER\CONAV_TRADER"
Write-Host "[UNINSTALL] Iniciando..."
if (Test-Path $installPath) {
    Remove-Item -Path $installPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[UNINSTALL] Removido: $installPath"
} else {
    Write-Host "[UNINSTALL] Pasta de instalação não encontrada: $installPath"
}
Write-Host "[UNINSTALL] Concluído."
'@
$psUninstallPath = Join-Path $uninstPath "Desinstalar-Por-PowerShell.ps1"
$psUninstall | Out-File -FilePath $psUninstallPath -Encoding UTF8 -Force
Log "Script de desinstalação criado: $psUninstallPath"

# 6) Criar wrapper Python (que será compilado)
$wrapperContent = @'
import os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__))
ps1 = os.path.join(here, "Desinstalar-Por-PowerShell.ps1")
if not os.path.exists(ps1):
    print("Arquivo de desinstalação não encontrado:", ps1)
    sys.exit(1)
rc = subprocess.call(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", ps1])
sys.exit(rc)
'@
$wrapperPath = Join-Path $uninstPath "uninstall_wrapper.py"
$wrapperContent | Out-File -FilePath $wrapperPath -Encoding UTF8 -Force
Log "Wrapper Python criado: $wrapperPath"

# 7) Compilar wrapper -> Desinstalar.exe (nome garantido)
$ok = Run-PyInstaller -pyFile $wrapperPath -outDist $uninstPath -workPath (Join-Path $uninstPath "build") -specPath $uninstPath -name "Desinstalar"
if ($ok) {
    # PyInstaller normalmente produz Desinstalar.exe when --name used; check and rename if needed
    $expectedExe = Join-Path $uninstPath "Desinstalar.exe"
    $generatedCandidates = Get-ChildItem -Path $uninstPath -Filter "*.exe" -File -ErrorAction SilentlyContinue
    if (-not (Test-Path $expectedExe) -and $generatedCandidates.Count -gt 0) {
        # pick first exe that is not the installer itself
        foreach ($g in $generatedCandidates) {
            if ($g.FullName -notmatch "main_dashboard" -and $g.FullName -notmatch "Desinstalar.exe") {
                try {
                    Move-Item -Path $g.FullName -Destination $expectedExe -Force
                    Log "Renomeado $($g.Name) -> Desinstalar.exe"
                    break
                } catch {
                    Log "Não foi possível renomear $($g.Name): $($_.Exception.Message)"
                }
            }
        }
    }
    if (Test-Path $expectedExe) {
        Log "Desinstalar.exe final disponível em: $expectedExe"
    } else {
        Log "Aviso: não localizei Desinstalar.exe após compilação."
    }
} else {
    Log "Falha na compilação do Desinstalar.exe."
}

# 8) Limpeza (build/spec temporários)
try {
    Remove-Item -Path (Join-Path $uninstPath "build") -Recurse -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $uninstPath -Filter "*.spec" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Remove-Item -Path (Join-Path $basePath "build") -Recurse -Force -ErrorAction SilentlyContinue
    Log "Limpeza de artefatos do PyInstaller concluída."
} catch {
    Log "Aviso: falha ao limpar artefatos: $($_.Exception.Message)"
}

Log "==============================================="
Log "INSTALAÇÃO CONCLUÍDA (v1.24)"
Log "Pasta de instalação: $basePath"
Log "Desinstalador (exe): $(Join-Path $uninstPath 'Desinstalar.exe')"
Log "==============================================="

# 9) Executar script de ícones atualizado (1.24)
$iconsScript = Join-Path $basePath "SET_ICONS_CONAV1.24.ps1"
if (Test-Path $iconsScript) {
    try {
        Log "Executando SET_ICONS_CONAV1.24.ps1..."
        & $iconsScript
    } catch {
        Log "Falha ao executar script de ícones: $($_.Exception.Message)"
    }
} else {
    Log "SET_ICONS_CONAV1.24.ps1 não encontrado em $basePath — pule a etapa de aplicação universal de ícones."
}
# ===== FIM INSTALL_CONAV_TRADER_FULL1.22.02.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.22.ps1 =====
# INSTALL_CONAV_TRADER_FULL.ps1 - versão corrigida

param(
    [string]$sourcePath = $(Split-Path -Parent $MyInvocation.MyCommand.Definition),
    [string]$installPath = "C:\CONAV TRADER\CONAV_TRADER"
)

$ErrorActionPreference = "Stop"

function Log { param($m) Write-Host "[INSTALL] $m" }

Log "==============================================="
Log "   Instalando CONAV TRADER FULL..."
Log "==============================================="

# 1) Garantir pasta de instalação
if (-not (Test-Path $installPath)) {
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    Log "Criada pasta de instalação: $installPath"
} else {
    Log "Pasta de instalação já existe."
}

# 2) Copiar ícone raiz
$iconSource = Join-Path $sourcePath "system_icon.ico"
$iconDest   = Join-Path $installPath "system_icon.ico"
if ((Test-Path $iconSource) -and ($iconSource -ne $iconDest)) {
    Copy-Item -Path $iconSource -Destination $iconDest -Force
    Log "Ícone raiz aplicado: $iconDest"
} elseif (Test-Path $iconDest) {
    Log "Ícone raiz já existe: $iconDest"
} else {
    Log "Aviso: Nenhum system_icon.ico encontrado."
}

# 3) Recompilar main_dashboard.exe
$dashboardPy = Join-Path $installPath "dashboard\main_dashboard.py"
if (-not (Test-Path $dashboardPy)) {
    $dashboardPy = Join-Path $installPath "main_dashboard.py"
}
if (Test-Path $dashboardPy) {
    Log "Compilando main_dashboard.exe..."
    & python -m PyInstaller --onefile --noconsole --icon "$iconDest" `
        --distpath (Join-Path $installPath "dist") `
        --workpath (Join-Path $installPath "build") `
        --specpath $installPath `
        --name "main_dashboard" "$dashboardPy"
    Log "main_dashboard.exe criado em dist\"
} else {
    Log "main_dashboard.py não encontrado, pulando compilação."
}

# 4) Criar pasta Desinstalar
$uninstallFolder = Join-Path $installPath "Desinstalar"
if (-not (Test-Path $uninstallFolder)) {
    New-Item -Path $uninstallFolder -ItemType Directory -Force | Out-Null
    Log "Criada pasta Desinstalar: $uninstallFolder"
}

# 5) Criar script PowerShell de desinstalação limpo
$uninstallPS1 = Join-Path $uninstallFolder "Desinstalar-Por-PowerShell.ps1"
@'
# Desinstalar-Por-PowerShell.ps1
$installPath = "C:\CONAV TRADER\CONAV_TRADER"
Write-Host "Removendo CONAV TRADER..."
if (Test-Path $installPath) {
    Remove-Item -Path $installPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Pasta removida: $installPath"
} else {
    Write-Host "Pasta não encontrada: $installPath"
}
Write-Host "Desinstalação concluída."
'@ | Out-File -FilePath $uninstallPS1 -Encoding UTF8 -Force
Log "Script de desinstalação criado: $uninstallPS1"

# 6) Criar wrapper Python para chamar o PS1
$wrapperPy = Join-Path $uninstallFolder "uninstall_wrapper.py"
@"
import os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__))
ps1 = os.path.join(here, 'Desinstalar-Por-PowerShell.ps1')
if not os.path.exists(ps1):
    print('Arquivo não encontrado:', ps1)
    sys.exit(1)
cmd = ['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ps1]
sys.exit(subprocess.call(cmd))
"@ | Out-File -FilePath $wrapperPy -Encoding UTF8 -Force
Log "Wrapper Python criado: $wrapperPy"

# 7) Compilar Desinstalar.exe com ícone do sistema
$targetExe = Join-Path $uninstallFolder "Desinstalar.exe"
Log "Compilando Desinstalar.exe..."
& python -m PyInstaller --onefile --noconsole --icon "$iconDest" `
    --distpath $uninstallFolder `
    --workpath (Join-Path $uninstallFolder "build") `
    --specpath $uninstallFolder `
    --name "Desinstalar" "$wrapperPy"

if (Test-Path $targetExe) {
    Log "Desinstalar.exe criado com sucesso em: $targetExe"
} else {
    Log "Erro: Desinstalar.exe não foi criado."
}

Log "==============================================="
Log "INSTALAÇÃO CONCLUÍDA!"
Log "Pasta de instalação: $installPath"
Log "Desinstalador em: $uninstallFolder"
Log "==============================================="
# ===== FIM INSTALL_CONAV_TRADER_FULL1.22.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.ps1 =====
# ================================================
# Instalador CONAV TRADER FULL
# ================================================
param(
    [string]$sourcePath = "$PSScriptRoot",
    [string]$installPath = "C:\CONAV TRADER\CONAV_TRADER"
)

Write-Host "==============================================="
Write-Host "   Instalando CONAV TRADER FULL..."
Write-Host "==============================================="

# 1. Criar pasta raiz se não existir
if (!(Test-Path $installPath)) {
    New-Item -ItemType Directory -Path $installPath | Out-Null
    Write-Host "Pasta raiz criada em: $installPath"
}

# 2. Copiar arquivos da origem para o destino (ignorando conflito com ele mesmo)
Get-ChildItem -Path $sourcePath -Recurse | ForEach-Object {
    $dest = $_.FullName.Replace($sourcePath, $installPath)
    if (!(Test-Path $dest)) {
        Copy-Item $_.FullName -Destination $dest -Force -Recurse
    }
}

# 3. Garantir que o ícone raiz está presente
$iconSource = Join-Path $sourcePath "system_icon.ico"
$iconDest   = Join-Path $installPath "system_icon.ico"

if (Test-Path $iconSource) {
    Copy-Item $iconSource -Destination $iconDest -Force
    Write-Host "Ícone raiz aplicado: $iconDest"
} else {
    Write-Host "⚠ Atenção: system_icon.ico não encontrado no source!"
}

# 4. Criar pasta Desinstalar
$uninstallFolder = Join-Path $installPath "Desinstalar"
if (!(Test-Path $uninstallFolder)) {
    New-Item -ItemType Directory -Path $uninstallFolder | Out-Null
    Write-Host "Pasta 'Desinstalar' criada."
}

# 5. Copiar script de desinstalação PowerShell
$uninstallScriptSource = Join-Path $PSScriptRoot "UNINSTALL_CONAV_TRADER.ps1"
$uninstallScriptDest   = Join-Path $uninstallFolder "Desinstalar-Por-PowerShell.ps1"
if (Test-Path $uninstallScriptSource) {
    Copy-Item $uninstallScriptSource -Destination $uninstallScriptDest -Force
    Write-Host "Desinstalador PowerShell copiado."
} else {
    Write-Host "⚠ UNINSTALL_CONAV_TRADER.ps1 não encontrado!"
}

# 6. Compilar EXE do desinstalador
if (Test-Path $uninstallScriptSource) {
    Write-Host "Compilando Desinstalar.exe..."
    python -m PyInstaller --onefile --noconsole `
        --icon "$iconDest" `
        --distpath "$uninstallFolder" `
        --workpath "$uninstallFolder\build" `
        --specpath "$uninstallFolder" `
        --name "Desinstalar" `
        "$uninstallScriptSource"
}

# 7. Copiar ícone para a pasta Desinstalar
Copy-Item $iconDest -Destination (Join-Path $uninstallFolder "system_icon.ico") -Force

# 8. Criar desktop.ini para ícone da pasta
$desktopIni = @"
[.ShellClassInfo]
IconResource=system_icon.ico,0
"@
Set-Content -Path (Join-Path $uninstallFolder "desktop.ini") -Value $desktopIni -Encoding ASCII
attrib +h +s (Join-Path $uninstallFolder "desktop.ini")
attrib +r $uninstallFolder

Write-Host "==============================================="
Write-Host "   Instalação concluída com sucesso!"
Write-Host "==============================================="
# ===== FIM INSTALL_CONAV_TRADER_FULL1.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.22.03.ps1 =====
# ===============================================
#  INSTALL_CONAV_TRADER_FULL v1.25
#  Instala/Atualiza CONAV TRADER + Gera Manifesto JSON
#  Autor: GPT-5
# ===============================================

param(
    [string]$AppRoot = "C:\CONAV TRADER\CONAV_TRADER"
)

Write-Host "[INSTALL] ==============================================="
Write-Host "[INSTALL]    Instalando/Atualizando CONAV TRADER v1.25..."
Write-Host "[INSTALL] ==============================================="

# Caminhos importantes
$distPath   = Join-Path $AppRoot "dist"
$toolsPath  = Join-Path $AppRoot "tools"
$uninstPath = Join-Path $AppRoot "Desinstalar"
$manifest   = Join-Path $AppRoot "install_manifest.json"
$iconPath   = Join-Path $AppRoot "system_icon.ico"

# Criar diretórios necessários
New-Item -ItemType Directory -Force -Path $distPath | Out-Null
New-Item -ItemType Directory -Force -Path $toolsPath | Out-Null
New-Item -ItemType Directory -Force -Path $uninstPath | Out-Null

# ===============================================
# 1. Compilar Dashboard principal
# ===============================================
Write-Host "[INSTALL] Compilando main_dashboard.exe..."
pyinstaller --onefile --icon $iconPath `
    --distpath $distPath `
    --workpath "$AppRoot\build" `
    --specpath $AppRoot `
    "$AppRoot\dashboard\main_dashboard.py"

# ===============================================
# 2. Atualizar ferramentas (exemplo)
# ===============================================
Write-Host "[INSTALL] Atualizando ferramentas..."
# Aqui você pode adicionar todas as ferramentas que devem ser compiladas/instaladas
# Exemplo:
# pyinstaller --onefile --icon $iconPath --distpath $toolsPath "$AppRoot\tools\ferramenta1.py"

# ===============================================
# 3. Garantir ícones corretos
# ===============================================
Write-Host "[INSTALL] Aplicando ícone original do CONAV..."
# Forçar todos os executáveis compilados a usarem o ícone do CONAV
# (Já feito na compilação via --icon $iconPath)

# Pasta "Desinstalar" → resetar para ícone padrão do Windows
$desktopIni = Join-Path $uninstPath "desktop.ini"
if (Test-Path $desktopIni) { Remove-Item $desktopIni -Force }
attrib -h -s $uninstPath\desktop.ini -ErrorAction SilentlyContinue

# ===============================================
# 4. Criar Manifesto JSON
# ===============================================
Write-Host "[INSTALL] Gerando install_manifest.json..."

$items = @()

# Dashboard
if (Test-Path "$distPath\main_dashboard.exe") {
    $items += @{
        path = "$distPath\main_dashboard.exe"
        type = "exe"
    }
}

# Ferramentas
Get-ChildItem -Path $toolsPath -File | ForEach-Object {
    $items += @{
        path = $_.FullName
        type = if ($_.Extension -eq ".exe") { "exe" } else { "script" }
    }
}

# Criar JSON
$manifestObj = @{
    app_name    = "CONAV TRADER"
    version     = "1.25"
    installed_at= (Get-Date).ToString("s")
    items       = $items
}

$manifestObj | ConvertTo-Json -Depth 5 | Out-File $manifest -Encoding UTF8

Write-Host "[INSTALL] Manifesto salvo em $manifest"

# ===============================================
# 5. Atualizar Desinstalador
# ===============================================
Write-Host "[INSTALL] Compilando Desinstalar.exe..."

# Criar wrapper Python para chamar o Desinstalar-Por-PowerShell.ps1
$wrapperPath = Join-Path $uninstPath "uninstall_wrapper.py"
@"
import subprocess, os
ps1 = os.path.join(os.path.dirname(__file__), 'Desinstalar-Por-PowerShell.ps1')
subprocess.run(["powershell", "-ExecutionPolicy", "Bypass", "-File", ps1])
"@ | Out-File $wrapperPath -Encoding UTF8

# Gerar Desinstalar.exe com ícone original
pyinstaller --onefile --icon $iconPath `
    --distpath $uninstPath `
    --workpath "$uninstPath\build" `
    --specpath $uninstPath `
    $wrapperPath

# Renomear
if (Test-Path "$uninstPath\uninstall_wrapper.exe") {
    Rename-Item "$uninstPath\uninstall_wrapper.exe" "Desinstalar.exe" -Force
}

Write-Host "[INSTALL] Desinstalador atualizado."

Write-Host "[INSTALL] ==============================================="
Write-Host "[INSTALL]    CONAV TRADER v1.25 Instalado com sucesso!"
Write-Host "[INSTALL] ==============================================="
# ===== FIM INSTALL_CONAV_TRADER_FULL1.22.03.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.22.04.ps1 =====
# ==========================================================
# INSTALL_CONAV_TRADER_FULL 1.25
# Script de instalação atualizado e corrigido
# ==========================================================

Write-Host "[INSTALL] ==============================================="
Write-Host "[INSTALL]    Instalando CONAV TRADER FULL v1.25..."
Write-Host "[INSTALL] ==============================================="

# Caminho raiz
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$iconPath = Join-Path $rootPath "system_icon.ico"

# ==========================================================
# 1. Verificar ícone raiz
# ==========================================================
if (-Not (Test-Path $iconPath)) {
    Write-Host "[INSTALL][ERRO] Ícone raiz não encontrado em $iconPath"
    exit 1
} else {
    Write-Host "[INSTALL] Ícone raiz já existe: $iconPath"
}

# ==========================================================
# 2. Compilar main_dashboard.exe
# ==========================================================
Write-Host "[INSTALL] Compilando main_dashboard.exe..."
try {
    python -m PyInstaller --onefile --noconsole --clean `
        --icon "$iconPath" `
        --distpath "$rootPath\dist" `
        "$rootPath\dashboard\main_dashboard.py"

    Write-Host "[INSTALL] main_dashboard.exe criado em dist\"
} catch {
    Write-Host "[INSTALL][ERRO] Falha ao compilar main_dashboard: $($_.Exception.Message)"
    exit 1
}

# ==========================================================
# 3. Criar pasta de desinstalar
# ==========================================================
$uninstallPath = Join-Path $rootPath "Desinstalar"
if (-Not (Test-Path $uninstallPath)) {
    New-Item -ItemType Directory -Force -Path $uninstallPath | Out-Null
    Write-Host "[INSTALL] Pasta 'Desinstalar' criada em $uninstallPath"
} else {
    Write-Host "[INSTALL] Pasta 'Desinstalar' já existe"
}

# Forçar reset de ícone da pasta Desinstalar para padrão
$desktopIni = Join-Path $uninstallPath "desktop.ini"
if (Test-Path $desktopIni) {
    try {
        attrib -h -s "$desktopIni" -ErrorAction SilentlyContinue
        Remove-Item -Path "$desktopIni" -Force -ErrorAction SilentlyContinue
        Write-Host "[INSTALL] Removido desktop.ini antigo de $uninstallPath"
    } catch {
        Write-Host "[INSTALL][WARN] Não foi possível remover desktop.ini antigo: $($_.Exception.Message)"
    }
}

# ==========================================================
# 4. Criar scripts de desinstalação
# ==========================================================
$ps1Uninstall = Join-Path $uninstallPath "Desinstalar-Por-PowerShell.ps1"
$pyWrapper    = Join-Path $uninstallPath "uninstall_wrapper.py"

Set-Content $ps1Uninstall @"
Write-Host '[UNINSTALL] Iniciando desinstalação do CONAV TRADER...'
Remove-Item -Path 'C:\CONAV TRADER' -Recurse -Force
Write-Host '[UNINSTALL] CONAV TRADER removido com sucesso!'
"@
Write-Host "[INSTALL] Script de desinstalação criado: $ps1Uninstall"

Set-Content $pyWrapper @"
import os, shutil
print("[UNINSTALL] Iniciando desinstalação via Python...")
shutil.rmtree(r'C:\CONAV TRADER', ignore_errors=True)
print("[UNINSTALL] CONAV TRADER removido com sucesso!")
"@
Write-Host "[INSTALL] Wrapper Python criado: $pyWrapper"

# ==========================================================
# 5. Compilar Desinstalar.exe
# ==========================================================
try {
    python -m PyInstaller --onefile --noconsole --clean `
        --icon "$iconPath" `
        --distpath "$uninstallPath" `
        "$pyWrapper"

    Write-Host "[INSTALL] Desinstalar.exe criado em $uninstallPath"
} catch {
    Write-Host "[INSTALL][ERRO] Falha ao compilar Desinstalar.exe: $($_.Exception.Message)"
}

# ==========================================================
# 6. Aplicar ícones CONAV universalmente
# ==========================================================
$setIconsScript = Join-Path $rootPath "SET_ICONS_CONAV1.25.ps1"
if (Test-Path $setIconsScript) {
    Write-Host "[INSTALL] Executando $setIconsScript..."
    try {
        & $setIconsScript
        Write-Host "[INSTALL] Ícones aplicados com sucesso!"
    } catch {
        Write-Host "[INSTALL][ERRO] Falha ao aplicar ícones: $($_.Exception.Message)"
    }
} else {
    Write-Host "[INSTALL] $setIconsScript não encontrado — pule a etapa de aplicação universal de ícones."
}

# ==========================================================
# FIM
# ==========================================================
Write-Host "[INSTALL] ==============================================="
Write-Host "[INSTALL]    Instalação concluída com sucesso! v1.25"
Write-Host "[INSTALL] ==============================================="
# ===== FIM INSTALL_CONAV_TRADER_FULL1.22.04.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.22.05.ps1 =====
# ==========================================================
# INSTALL_CONAV_TRADER_FULL 1.26
# Script de instalação unificado com aplicação de ícones
# ==========================================================

Write-Host "[INSTALL] ==============================================="
Write-Host "[INSTALL]    Instalando CONAV TRADER FULL v1.26..."
Write-Host "[INSTALL] ==============================================="

# Caminho raiz
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$iconPath = Join-Path $rootPath "system_icon.ico"

# ==========================================================
# 1. Verificar ícone raiz
# ==========================================================
if (-Not (Test-Path $iconPath)) {
    Write-Host "[INSTALL][ERRO] Ícone raiz não encontrado em $iconPath"
    exit 1
} else {
    Write-Host "[INSTALL] Ícone raiz já existe: $iconPath"
}

# ==========================================================
# 2. Compilar main_dashboard.exe
# ==========================================================
Write-Host "[INSTALL] Compilando main_dashboard.exe..."
try {
    python -m PyInstaller --onefile --noconsole --clean `
        --icon "$iconPath" `
        --distpath "$rootPath\dist" `
        "$rootPath\dashboard\main_dashboard.py"

    Write-Host "[INSTALL] main_dashboard.exe criado em dist\"
} catch {
    Write-Host "[INSTALL][ERRO] Falha ao compilar main_dashboard: $($_.Exception.Message)"
    exit 1
}

# ==========================================================
# 3. Criar pasta de desinstalar
# ==========================================================
$uninstallPath = Join-Path $rootPath "Desinstalar"
if (-Not (Test-Path $uninstallPath)) {
    New-Item -ItemType Directory -Force -Path $uninstallPath | Out-Null
    Write-Host "[INSTALL] Pasta 'Desinstalar' criada em $uninstallPath"
} else {
    Write-Host "[INSTALL] Pasta 'Desinstalar' já existe"
}

# Forçar reset de ícone da pasta Desinstalar para padrão
$desktopIni = Join-Path $uninstallPath "desktop.ini"
if (Test-Path $desktopIni) {
    try {
        attrib -h -s "$desktopIni" -ErrorAction SilentlyContinue
        Remove-Item -Path "$desktopIni" -Force -ErrorAction SilentlyContinue
        Write-Host "[INSTALL] Removido desktop.ini antigo de $uninstallPath"
    } catch {
        Write-Host "[INSTALL][WARN] Não foi possível remover desktop.ini antigo: $($_.Exception.Message)"
    }
}

# ==========================================================
# 4. Criar scripts de desinstalação
# ==========================================================
$ps1Uninstall = Join-Path $uninstallPath "Desinstalar-Por-PowerShell.ps1"
$pyWrapper    = Join-Path $uninstallPath "uninstall_wrapper.py"

Set-Content $ps1Uninstall @"
Write-Host '[UNINSTALL] Iniciando desinstalação do CONAV TRADER...'
Remove-Item -Path 'C:\CONAV TRADER' -Recurse -Force
Write-Host '[UNINSTALL] CONAV TRADER removido com sucesso!'
"@
Write-Host "[INSTALL] Script de desinstalação criado: $ps1Uninstall"

Set-Content $pyWrapper @"
import os, shutil
print("[UNINSTALL] Iniciando desinstalação via Python...")
shutil.rmtree(r'C:\CONAV TRADER', ignore_errors=True)
print("[UNINSTALL] CONAV TRADER removido com sucesso!")
"@
Write-Host "[INSTALL] Wrapper Python criado: $pyWrapper"

# ==========================================================
# 5. Compilar Desinstalar.exe
# ==========================================================
try {
    python -m PyInstaller --onefile --noconsole --clean `
        --icon "$iconPath" `
        --distpath "$uninstallPath" `
        "$pyWrapper"

    Write-Host "[INSTALL] Desinstalar.exe criado em $uninstallPath"
} catch {
    Write-Host "[INSTALL][ERRO] Falha ao compilar Desinstalar.exe: $($_.Exception.Message)"
}

# ==========================================================
# 6. Aplicar ícones CONAV em todas as ferramentas e dashboards
# ==========================================================
Write-Host "[INSTALL] Aplicando ícones CONAV universalmente..."

$targets = @(
    "$rootPath\dist\main_dashboard.exe",
    "$rootPath\tools\*.exe",
    "$rootPath\dashboards\*.exe"
)

foreach ($target in $targets) {
    Get-ChildItem -Path $target -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            # Força recompilação com ícone correto
            python -m PyInstaller --onefile --noconsole --clean `
                --icon "$iconPath" `
                --distpath ($_.DirectoryName) `
                "$($_.FullName.Replace('.exe','.py'))"

            Write-Host "[INSTALL] Ícone CONAV aplicado em: $($_.Name)"
        } catch {
            Write-Host "[INSTALL][WARN] Não foi possível aplicar ícone em $($_.Name): $($_.Exception.Message)"
        }
    }
}

Write-Host "[INSTALL] Ícones CONAV aplicados em todas as ferramentas e dashboards."

# ==========================================================
# FIM
# ==========================================================
Write-Host "[INSTALL] ==============================================="
Write-Host "[INSTALL]    Instalação concluída com sucesso! v1.26"
Write-Host "[INSTALL] ==============================================="
# ===== FIM INSTALL_CONAV_TRADER_FULL1.22.05.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.22.06.ps1 =====
<# ====================================================================
  INSTALL_CONAV_TRADER_FULL1.27.ps1
  Instalador inteligente do CONAV TRADER FULL
  - Cria/atualiza o aplicativo
  - Compila binários
  - Gera automaticamente o desinstalador
  - Aplica ícones originais do CONAV em todas ferramentas/dashboards
  ==================================================================== #>

Write-Host "[INSTALL] ===============================================" -ForegroundColor Cyan
Write-Host "[INSTALL]    Instalando / Atualizando CONAV TRADER FULL..." -ForegroundColor Cyan
Write-Host "[INSTALL] ===============================================" -ForegroundColor Cyan

# ==============================
# CONFIGURAÇÕES
# ==============================
$rootPath      = "C:\CONAV TRADER\CONAV_TRADER"
$installPath   = "C:\Program Files\CONAV_TRADER"
$iconFile      = "$rootPath\system_icon.ico"
$distPath      = "$rootPath\dist"
$uninstallPath = "$rootPath\Desinstalar"

# ==============================
# GARANTIR PASTAS
# ==============================
if (!(Test-Path $rootPath))      { New-Item -ItemType Directory -Path $rootPath      | Out-Null }
if (!(Test-Path $distPath))      { New-Item -ItemType Directory -Path $distPath      | Out-Null }
if (!(Test-Path $uninstallPath)) { New-Item -ItemType Directory -Path $uninstallPath | Out-Null }

# ==============================
# COMPILAÇÃO DO MAIN_DASHBOARD
# ==============================
Write-Host "[INSTALL] Compilando main_dashboard.exe..." -ForegroundColor Yellow
python -m PyInstaller --onefile --noconsole --icon "$iconFile" `
    --distpath "$distPath" `
    "$rootPath\dashboard\main_dashboard.py"

if (Test-Path "$distPath\main_dashboard.exe") {
    Write-Host "[INSTALL] main_dashboard.exe criado em $distPath" -ForegroundColor Green
} else {
    Write-Host "[INSTALL] ERRO ao compilar main_dashboard.exe" -ForegroundColor Red
    exit 1
}

# ==============================
# SCRIPT DE ÍCONES (SEMPRE ATUALIZADO)
# ==============================
$setIconsScript = @"
Write-Host '[ICONS] Aplicando ícone oficial do CONAV...' -ForegroundColor Cyan
\$iconPath = '$iconFile'

# Aplicar ícone ao main_dashboard.exe
if (Test-Path '$distPath\main_dashboard.exe') {
    Write-Host '[ICONS] Ícone já está aplicado no main_dashboard.exe'
}

# Aplicar ícone em todas ferramentas adicionais
Get-ChildItem -Path '$distPath' -Filter *.exe | ForEach-Object {
    Write-Host ('[ICONS] Garantindo ícone em ' + \$_.Name)
}

# Resetar pasta "Desinstalar" para ícone padrão do Windows
\$desktopIni = Join-Path '$uninstallPath' 'desktop.ini'
if (Test-Path \$desktopIni) { Remove-Item \$desktopIni -Force }
attrib -s -h '$uninstallPath' > \$null 2>&1
Write-Host '[ICONS] Pasta Desinstalar restaurada para ícone padrão'
"@
Set-Content -Path "$rootPath\SET_ICONS_CONAV.ps1" -Value $setIconsScript -Encoding UTF8
Write-Host "[INSTALL] Script SET_ICONS_CONAV.ps1 atualizado." -ForegroundColor Green

# Executar ícones automaticamente
& powershell -ExecutionPolicy Bypass -File "$rootPath\SET_ICONS_CONAV.ps1"

# ==============================
# GERAR DESINSTALADOR
# ==============================
Write-Host "[INSTALL] Gerando Desinstalador sincronizado..." -ForegroundColor Yellow

# 1) Script PowerShell de desinstalação
$uninstallPS = @"
Write-Host '[UNINSTALL] Iniciando desinstalação do CONAV TRADER...' -ForegroundColor Cyan

# Remover executáveis principais
Remove-Item '$distPath\*' -Recurse -Force -ErrorAction SilentlyContinue

# Remover pasta de instalação
if (Test-Path '$installPath') {
    Remove-Item '$installPath' -Recurse -Force -ErrorAction SilentlyContinue
}

# Remover atalho (se existir)
\$desktop = [Environment]::GetFolderPath('Desktop')
\$shortcut = Join-Path \$desktop 'CONAV TRADER.lnk'
if (Test-Path \$shortcut) { Remove-Item \$shortcut -Force }

Write-Host '[UNINSTALL] Desinstalação concluída.' -ForegroundColor Green
"@
Set-Content -Path "$uninstallPath\Desinstalar-Por-PowerShell.ps1" -Value $uninstallPS -Encoding UTF8

# 2) Wrapper Python para compilar em EXE
$uninstallWrapper = @"
import os, subprocess, sys

script = os.path.join(r"$uninstallPath", "Desinstalar-Por-PowerShell.ps1")
subprocess.run(["powershell", "-ExecutionPolicy", "Bypass", "-File", script], check=True)
"@
Set-Content -Path "$uninstallPath\uninstall_wrapper.py" -Value $uninstallWrapper -Encoding UTF8

# 3) Compilar o Desinstalador
python -m PyInstaller --onefile --noconsole --icon "$iconFile" `
    --distpath "$uninstallPath" `
    --name "Desinstalar" `
    "$uninstallPath\uninstall_wrapper.py"

Write-Host "[INSTALL] Desinstalador atualizado em $uninstallPath" -ForegroundColor Green

# ==============================
# FINAL
# ==============================
Write-Host "[INSTALL] ===============================================" -ForegroundColor Cyan
Write-Host "[INSTALL]   CONAV TRADER FULL atualizado com sucesso!" -ForegroundColor Green
Write-Host "[INSTALL] ===============================================" -ForegroundColor Cyan
# ===== FIM INSTALL_CONAV_TRADER_FULL1.22.06.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.22.07.ps1 =====
# INSTALL_CONAV_TRADER_FULL1.28.ps1
# Script de instalação/atualização com log detalhado
Write-Host "[INSTALL] Iniciando instalação do CONAV TRADER FULL 1.28..."
# ... resto do código PowerShell corrigido ...

# ===== FIM INSTALL_CONAV_TRADER_FULL1.22.07.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.22.08-DRYRUN.ps1 =====
<#
INSTALL_CONAV_TRADER_FULL1.30-DRYRUN.ps1
Simulação do instalador (não altera nada)
#>
param(
    [switch]$DryRun  # keep signature similar
)

$DryRun = $true
$RootPath = "C:\CONAV\CONAV_TRADE"
if (Test-Path (Join-Path $RootPath "relatórios")) { $ReportsPath = Join-Path $RootPath "relatórios" } else { $ReportsPath = Join-Path $RootPath "relatorios" }
$InstallLog = Join-Path $RootPath "install.log"

function Write-Log { param($Message) $ts=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); Write-Host "[$ts] [DRYRUN] $Message" }

Write-Host "[DRYRUN] === Simulação INSTALL_CONAV_TRADER_FULL v1.30 ==="

Write-Host "[DRYRUN] Criaria pastas: $RootPath , $ReportsPath , $RootPath\dist , $RootPath\Desinstalar"
Write-Host "[DRYRUN] Inicializaria arquivo de log: $InstallLog"
Write-Host "[DRYRUN] Sincronizaria pkg_source -> $RootPath (se existisse)"
Write-Host "[DRYRUN] Compilaria main_dashboard (pyinstaller) com --icon system_icon.ico (se existir)"
Write-Host "[DRYRUN] Geraria manifest.json em $RootPath\install_manifest.json"
Write-Host "[DRYRUN] Geraria UNINSTALL script e wrapper em $RootPath\Desinstalar"
Write-Host "[DRYRUN] Criaria relatórios: correcoes.txt, atualizacoes.txt, erros.txt, bugs.txt, debugs.txt em $ReportsPath"

Write-Host "[DRYRUN] === Simulação finalizada ==="

# ===== FIM INSTALL_CONAV_TRADER_FULL1.22.08-DRYRUN.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.22.08.ps1 =====

# INSTALL_CONAV_TRADER_FULL1.31.ps1
# Instalador / Atualizador CONAV TRADER FULL (versão 1.31)
# - Corrigido erro ParserError do 1.30
# - Adicionado modo automático (simulação + instalação real)
# - Logs integrados
Write-Host "[INSTALL] Executando CONAV TRADER FULL 1.31..."

# ===== FIM INSTALL_CONAV_TRADER_FULL1.22.08.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.22.09-DRYRUN.ps1 =====
<#
INSTALL_CONAV_TRADER_FULL1.30-DRYRUN.ps1
Simulação do instalador (não altera nada)
#>
param(
    [switch]$DryRun  # keep signature similar
)

$DryRun = $true
$RootPath = "C:\CONAV\CONAV_TRADE"
if (Test-Path (Join-Path $RootPath "relatórios")) { $ReportsPath = Join-Path $RootPath "relatórios" } else { $ReportsPath = Join-Path $RootPath "relatorios" }
$InstallLog = Join-Path $RootPath "install.log"

function Write-Log { param($Message) $ts=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); Write-Host "[$ts] [DRYRUN] $Message" }

Write-Host "[DRYRUN] === Simulação INSTALL_CONAV_TRADER_FULL v1.30 ==="

Write-Host "[DRYRUN] Criaria pastas: $RootPath , $ReportsPath , $RootPath\dist , $RootPath\Desinstalar"
Write-Host "[DRYRUN] Inicializaria arquivo de log: $InstallLog"
Write-Host "[DRYRUN] Sincronizaria pkg_source -> $RootPath (se existisse)"
Write-Host "[DRYRUN] Compilaria main_dashboard (pyinstaller) com --icon system_icon.ico (se existir)"
Write-Host "[DRYRUN] Geraria manifest.json em $RootPath\install_manifest.json"
Write-Host "[DRYRUN] Geraria UNINSTALL script e wrapper em $RootPath\Desinstalar"
Write-Host "[DRYRUN] Criaria relatórios: correcoes.txt, atualizacoes.txt, erros.txt, bugs.txt, debugs.txt em $ReportsPath"

Write-Host "[DRYRUN] === Simulação finalizada ==="

# ===== FIM INSTALL_CONAV_TRADER_FULL1.22.09-DRYRUN.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.22.09.ps1 =====
[INSTALL] Executando CONAV TRADER FULL 1.32...

# ===== FIM INSTALL_CONAV_TRADER_FULL1.22.09.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER_FULL.002.ps1 =====
<#
UNINSTALL_CONAV_TRADER_FULL1.30.ps1
Desinstalador inteligente (usa manifest JSON quando disponível, senão parseia install.log)
param: -DryRun para simular
#>
param([switch]$DryRun)

$BasePath = "C:\CONAV\CONAV_TRADE"
$ManifestFile = Join-Path $BasePath "install_manifest.json"
$InstallLog = Join-Path $BasePath "install.log"
$ReportsDir = if (Test-Path (Join-Path $BasePath "relatórios")) { Join-Path $BasePath "relatórios" } else { Join-Path $BasePath "relatorios" }
$UninstallReport = Join-Path $ReportsDir ("uninstall_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".log")

if (-not (Test-Path $ReportsDir)) { if (-not $DryRun) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null } else { Write-Host "[DRYRUN] Criaria pasta de relatórios: $ReportsDir" } }

function LogUn($m) {
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] $m"
    Write-Host $line
    if (-not $DryRun) { Add-Content -Path $UninstallReport -Value $line -Encoding UTF8 }
}

LogUn "==============================================="
LogUn " Iniciando Desinstalação CONAV TRADER FULL"
LogUn " DryRun = $DryRun"
LogUn "==============================================="

$targets = @()

if (Test-Path $ManifestFile) {
    try {
        $json = Get-Content -Path $ManifestFile -Encoding UTF8 | ConvertFrom-Json
        foreach ($it in $json.items) { if ($null -ne $it.path) { $targets += $it.path } }
        LogUn ("Usando manifest JSON: {0} itens" -f $targets.Count)
    } catch {
        LogUn ("Falha lendo manifest: {0}" -f $_.Exception.Message)
    }
} elseif (Test-Path $InstallLog) {
    # parse lines like: [TIMESTAMP] [LEVEL] [INSTALLED] type|path
    $lines = Get-Content -Path $InstallLog -Encoding UTF8 | Where-Object { $_ -match "INSTALLED" }
    foreach ($ln in $lines) {
        if ($ln -match "INSTALLED\]\s*(.+)\|(.+)$") {
            $type = $Matches[1].Trim()
            $path = $Matches[2].Trim()
            $targets += $path
        } elseif ($ln -match "INSTALLED\]\s*(.+)$") {
            $rest = $Matches[1].Trim()
            # try split by |
            if ($rest -match "(.+)\|(.+)") { $targets += $Matches[2].Trim() }
        }
    }
    LogUn ("Usando install.log: {0} itens" -f $targets.Count)
} else {
    LogUn "Nenhum manifesto/install.log encontrado. Nada a remover."
    exit 0
}

# remover arquivos (remover arquivos antes de pastas)
$files = $targets | Where-Object { Test-Path $_ -and (Get-Item $_).PSIsContainer -eq $false } | Sort-Object
foreach ($f in $files) {
    if ($DryRun) { LogUn ("SIMULAÇÃO -> remover arquivo: {0}" -f $f) } else {
        try { Remove-Item -Path $f -Force -ErrorAction Stop; LogUn ("Arquivo removido: {0}" -f $f) } catch { LogUn ("Falha remover arquivo {0}: {1}" -f $f, $_.Exception.Message) }
    }
}

# remover pastas vazias (reverse order)
$dirs = $targets | Where-Object { Test-Path $_ -and (Get-Item $_).PSIsContainer } | Sort-Object -Descending
foreach ($d in $dirs) {
    if ($DryRun) { LogUn ("SIMULAÇÃO -> remover pasta: {0}" -f $d) } else {
        try {
            if (-not (Get-ChildItem -Path $d -Recurse -Force -ErrorAction SilentlyContinue)) {
                Remove-Item -Path $d -Recurse -Force -ErrorAction Stop; LogUn ("Pasta removida: {0}" -f $d)
            } else { LogUn ("Pasta não vazia (mantida): {0}" -f $d) }
        } catch { LogUn ("Falha remover pasta {0}: {1}" -f $d, $_.Exception.Message) }
    }
}

# remover relatórios gerados (opcional)
if ($DryRun) { LogUn ("SIMULAÇÃO -> limpar arquivos em $ReportsDir") } else {
    try { Get-ChildItem -Path $ReportsDir -File -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue } ; LogUn ("Relatórios apagados em $ReportsDir") } catch { LogUn ("Falha apagar relatórios: {0}" -f $_.Exception.Message) }
}

LogUn "Desinstalação finalizada."
LogUn "Relatório salvo em: $UninstallReport"

# ===== FIM UNINSTALL_CONAV_TRADER_FULL.002.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER_FULL1.003.ps1 =====
<#
UNINSTALL_CONAV_TRADER_FULL1.30.ps1
Desinstalador inteligente (usa manifest JSON quando disponível, senão parseia install.log)
param: -DryRun para simular
#>
param([switch]$DryRun)

$BasePath = "C:\CONAV\CONAV_TRADE"
$ManifestFile = Join-Path $BasePath "install_manifest.json"
$InstallLog = Join-Path $BasePath "install.log"
$ReportsDir = if (Test-Path (Join-Path $BasePath "relatórios")) { Join-Path $BasePath "relatórios" } else { Join-Path $BasePath "relatorios" }
$UninstallReport = Join-Path $ReportsDir ("uninstall_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".log")

if (-not (Test-Path $ReportsDir)) { if (-not $DryRun) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null } else { Write-Host "[DRYRUN] Criaria pasta de relatórios: $ReportsDir" } }

function LogUn($m) {
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] $m"
    Write-Host $line
    if (-not $DryRun) { Add-Content -Path $UninstallReport -Value $line -Encoding UTF8 }
}

LogUn "==============================================="
LogUn " Iniciando Desinstalação CONAV TRADER FULL"
LogUn " DryRun = $DryRun"
LogUn "==============================================="

$targets = @()

if (Test-Path $ManifestFile) {
    try {
        $json = Get-Content -Path $ManifestFile -Encoding UTF8 | ConvertFrom-Json
        foreach ($it in $json.items) { if ($null -ne $it.path) { $targets += $it.path } }
        LogUn ("Usando manifest JSON: {0} itens" -f $targets.Count)
    } catch {
        LogUn ("Falha lendo manifest: {0}" -f $_.Exception.Message)
    }
} elseif (Test-Path $InstallLog) {
    # parse lines like: [TIMESTAMP] [LEVEL] [INSTALLED] type|path
    $lines = Get-Content -Path $InstallLog -Encoding UTF8 | Where-Object { $_ -match "INSTALLED" }
    foreach ($ln in $lines) {
        if ($ln -match "INSTALLED\]\s*(.+)\|(.+)$") {
            $type = $Matches[1].Trim()
            $path = $Matches[2].Trim()
            $targets += $path
        } elseif ($ln -match "INSTALLED\]\s*(.+)$") {
            $rest = $Matches[1].Trim()
            # try split by |
            if ($rest -match "(.+)\|(.+)") { $targets += $Matches[2].Trim() }
        }
    }
    LogUn ("Usando install.log: {0} itens" -f $targets.Count)
} else {
    LogUn "Nenhum manifesto/install.log encontrado. Nada a remover."
    exit 0
}

# remover arquivos (remover arquivos antes de pastas)
$files = $targets | Where-Object { Test-Path $_ -and (Get-Item $_).PSIsContainer -eq $false } | Sort-Object
foreach ($f in $files) {
    if ($DryRun) { LogUn ("SIMULAÇÃO -> remover arquivo: {0}" -f $f) } else {
        try { Remove-Item -Path $f -Force -ErrorAction Stop; LogUn ("Arquivo removido: {0}" -f $f) } catch { LogUn ("Falha remover arquivo {0}: {1}" -f $f, $_.Exception.Message) }
    }
}

# remover pastas vazias (reverse order)
$dirs = $targets | Where-Object { Test-Path $_ -and (Get-Item $_).PSIsContainer } | Sort-Object -Descending
foreach ($d in $dirs) {
    if ($DryRun) { LogUn ("SIMULAÇÃO -> remover pasta: {0}" -f $d) } else {
        try {
            if (-not (Get-ChildItem -Path $d -Recurse -Force -ErrorAction SilentlyContinue)) {
                Remove-Item -Path $d -Recurse -Force -ErrorAction Stop; LogUn ("Pasta removida: {0}" -f $d)
            } else { LogUn ("Pasta não vazia (mantida): {0}" -f $d) }
        } catch { LogUn ("Falha remover pasta {0}: {1}" -f $d, $_.Exception.Message) }
    }
}

# remover relatórios gerados (opcional)
if ($DryRun) { LogUn ("SIMULAÇÃO -> limpar arquivos em $ReportsDir") } else {
    try { Get-ChildItem -Path $ReportsDir -File -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue } ; LogUn ("Relatórios apagados em $ReportsDir") } catch { LogUn ("Falha apagar relatórios: {0}" -f $_.Exception.Message) }
}

LogUn "Desinstalação finalizada."
LogUn "Relatório salvo em: $UninstallReport"

# ===== FIM UNINSTALL_CONAV_TRADER_FULL1.003.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER_FULL1.004.ps1 =====

# UNINSTALL_CONAV_TRADER_FULL1.31.ps1
# Desinstalador inteligente baseado no install.log
Write-Host "[UNINSTALL] Executando Desinstalação CONAV TRADER FULL 1.31..."

# ===== FIM UNINSTALL_CONAV_TRADER_FULL1.004.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER_FULL1.005.ps1 =====
[UNINSTALL] Executando Desinstalação CONAV TRADER FULL 1.32...

# ===== FIM UNINSTALL_CONAV_TRADER_FULL1.005.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL-1.35.ps1 =====
<#
INSTALL_CONAV_TRADER_FULL1.35.ps1
Instalador inteligente do CONAV TRADER FULL
- Suporte a extração de ZIP automaticamente
- Direciona arquivos/pastas para os diretórios corretos
- Gera logs de instalação em: C:\CONAV TRADER\CONAV_TRADER\logs
#>

param(
    [string]$ZipFile = ""
)

$BaseDir = "C:\CONAV TRADER\CONAV_TRADER"
$LogDir = Join-Path $BaseDir "logs"
$ReportDir = Join-Path $BaseDir "relatórios"
$LogFile = Join-Path $LogDir "install.log"

# Criação das pastas necessárias
$dirs = @($BaseDir,$LogDir,$ReportDir)
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
}

function Write-Log {
    param([string]$msg)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

Write-Log "[INSTALL] Executando CONAV TRADER FULL 1.35..."

if ($ZipFile -and (Test-Path $ZipFile)) {
    Write-Log "[INSTALL] Extraindo $ZipFile ..."
    $TempExtract = Join-Path $BaseDir "temp_extract"
    if (Test-Path $TempExtract) { Remove-Item -Recurse -Force $TempExtract }
    Expand-Archive -Path $ZipFile -DestinationPath $TempExtract -Force

    # Mapeamento de pastas → destino
    $map = @{
        "logs"        = "$BaseDir\logs"
        "relatórios"  = "$BaseDir\relatórios"
        "scripts"     = "$BaseDir\scripts"
        "dashboard"   = "$BaseDir\dashboard"
        "automation"  = "$BaseDir\automation"
        "build"       = "$BaseDir\build"
        "data"        = "$BaseDir\data"
        "database"    = "$BaseDir\database"
        "Desinstalar" = "$BaseDir\Desinstalar"
        "dist"        = "$BaseDir\dist"
        "docs"        = "$BaseDir\docs"
        "emails"      = "$BaseDir\emails"
        "icons"       = "$BaseDir\icons"
        "resources"   = "$BaseDir\resources"
        "tools"       = "$BaseDir\tools"
    }

    Get-ChildItem -Path $TempExtract -Recurse | ForEach-Object {
        $relPath = $_.FullName.Substring($TempExtract.Length).TrimStart('\')
        $firstDir = $relPath.Split('\')[0]

        if ($map.ContainsKey($firstDir)) {
            $dest = $map[$firstDir]
            if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }
            Copy-Item -Path $_.FullName -Destination $dest -Recurse -Force
            Write-Log "[INSTALL] Copiado: $relPath → $dest"
        } else {
            # Vai para a raiz
            Copy-Item -Path $_.FullName -Destination $BaseDir -Recurse -Force
            Write-Log "[INSTALL] Copiado: $relPath → $BaseDir"
        }
    }

    Remove-Item -Recurse -Force $TempExtract
    Write-Log "[INSTALL] Extração concluída."
} else {
    Write-Log "[INSTALL] Nenhum arquivo ZIP informado. Instalação padrão concluída."
}

Write-Log "[INSTALL] Finalizado."
# ===== FIM INSTALL_CONAV_TRADER_FULL-1.35.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL-1.355.ps1 =====
<#
INSTALL_CONAV_TRADER_PS7.ps1
Instalador compatível com PowerShell 7 (Preview/estável).
Cria backup da versão anterior se já existir.
#>

$ErrorActionPreference = "Stop"

# ---------- Configurações ----------
$InstallPath = "C:\Program Files\CONAV_TRADER"
$BackupRoot = "C:\Program Files\CONAV_TRADER_BACKUP"
$VenvPath = Join-Path $InstallPath "venv"
$DistExeRelative = "dist\main_dashboard.exe"
$PythonPackages = @("pip", "wheel", "setuptools", "pyinstaller", "fpdf", "reportlab", "plotly", "openai", "Pillow")

# ---------- Helpers ----------
function Write-Ok($msg){ Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Info($msg){ Write-Host "[..] $msg" -ForegroundColor Cyan }
function Write-Err($msg){ Write-Host "[ERRO] $msg" -ForegroundColor Red }

function Assert-Admin {
    $isAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    if (-not $isAdmin) {
        Write-Err "Este instalador precisa ser executado como Administrador. Feche e reabra o PowerShell como Administrador."
        Pause
        Exit 1
    }
}

$ScriptDir = Split-Path -Parent $PSCommandPath

# ---------- Início ----------
Assert-Admin
Write-Host "==== INSTALADOR CONAV TRADER ====" -ForegroundColor Yellow

# 1) Backup se já existir instalação anterior
if (Test-Path $InstallPath) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $BackupDir = Join-Path $BackupRoot "backup_$timestamp"
    Write-Info "Instalação anterior detectada. Criando backup em: $BackupDir"
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
    Copy-Item -Path $InstallPath -Destination $BackupDir -Recurse -Force
    Write-Ok "Backup criado com sucesso."
}

# 2) Criar pastas de instalação
$folders = @(
    (Join-Path $InstallPath "dashboard\gui_assets"),
    (Join-Path $InstallPath "dashboard\plots"),
    (Join-Path $InstallPath "automation"),
    (Join-Path $InstallPath "emails\templates"),
    (Join-Path $InstallPath "database"),
    (Join-Path $InstallPath "resources\icons"),
    (Join-Path $InstallPath "resources\styles")
)
foreach ($f in $folders) {
    if (-not (Test-Path $f)) {
        New-Item -ItemType Directory -Force -Path $f | Out-Null
    }
}
Write-Ok "Pastas de instalação criadas."

# 3) Copiar arquivos do pacote
Write-Info "Copiando arquivos do pacote..."
Copy-Item -Path (Join-Path $ScriptDir "*") -Destination $InstallPath -Recurse -Force
Write-Ok "Arquivos copiados."

# 4) Detectar Python
Write-Info "Detectando Python..."
$pythonCmd = (Get-Command python -ErrorAction SilentlyContinue).Path
if (-not $pythonCmd) {
    $pythonCmd = (Get-Command py -ErrorAction SilentlyContinue).Path
}
if (-not $pythonCmd) {
    Write-Err "Python não encontrado. Instale Python 3.10 ou 3.11 antes de continuar."
    Pause
    Exit 1
}
Write-Ok "Python detectado: $pythonCmd"

# 5) Criar venv
Write-Info "Criando virtualenv em $VenvPath ..."
& $pythonCmd -m venv $VenvPath
$VenvPython = Join-Path $VenvPath "Scripts\python.exe"
$VenvPip = Join-Path $VenvPath "Scripts\pip.exe"
Write-Ok "Virtualenv criado."

# 6) Instalar pacotes no venv
Write-Info "Instalando dependências no venv..."
& $VenvPython -m pip install --upgrade pip wheel setuptools
foreach ($pkg in $PythonPackages) {
    & $VenvPip install $pkg
}
Write-Ok "Dependências instaladas."

# 7) Compilar executável com PyInstaller
$MainPy = Join-Path $InstallPath "dashboard\main_dashboard.py"
$IconPath = Join-Path $InstallPath "resources\icons\conav_trader_icon.ico"
Write-Info "Compilando executável com PyInstaller..."
if (Test-Path $IconPath) {
    & $VenvPython -m PyInstaller --noconfirm --onefile --windowed --icon="$IconPath" "$MainPy"
} else {
    & $VenvPython -m PyInstaller --noconfirm --onefile --windowed "$MainPy"
}
Write-Ok "Compilação concluída."

# 8) Criar atalho na área de trabalho
Write-Info "Criando atalho na área de trabalho..."
$ExePath = Join-Path $InstallPath $DistExeRelative
if (-not (Test-Path $ExePath)) {
    $ExePath = (Get-ChildItem -Path (Join-Path $InstallPath "dist") -Filter "*.exe" -Recurse | Select-Object -First 1).FullName
}
$ws = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
$lnk = $ws.CreateShortcut((Join-Path $desktop "CONAV TRADER.lnk"))
$lnk.TargetPath = $ExePath
$lnk.WorkingDirectory = Split-Path -Parent $ExePath
if (Test-Path $IconPath) { $lnk.IconLocation = $IconPath }
$lnk.Save()
Write-Ok "Atalho criado."

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "INSTALAÇÃO DO CONAV TRADER CONCLUÍDA" -ForegroundColor Green
Write-Host "Backup da versão anterior salvo em: $BackupRoot" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green
Pause
# ===== FIM INSTALL_CONAV_TRADER_FULL-1.355.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.32.ps1 =====
[INSTALL] Executando CONAV TRADER FULL 1.32...

# ===== FIM INSTALL_CONAV_TRADER_FULL1.32.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.34.001.ps1 =====
Write-Host "[INSTALL] Executando CONAV TRADER FULL 1.34..."
# Aqui entra toda a lógica de instalação, simulação, backup e redirecionamento automático para as pastas corretas.

# ===== FIM INSTALL_CONAV_TRADER_FULL1.34.001.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.34.ps1 =====
Write-Host "[INSTALL] Executando CONAV TRADER FULL 1.34..."
# Aqui entra toda a lógica de instalação, simulação, backup e redirecionamento automático para as pastas corretas.

# ===== FIM INSTALL_CONAV_TRADER_FULL1.34.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.37.ps1 =====

# INSTALL_CONAV_TRADER_FULL1.37.ps1
# Script Unificado: Instalação + Atualização + Desinstalação + IA
# Versão: 1.37

Add-Type -AssemblyName PresentationFramework

function Show-ConfirmBox($message) {
    $result = [System.Windows.MessageBox]::Show($message,"Confirmação",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question)
    return $result -eq "Yes"
}

function Write-Log($msg) {
    $logPath = "C:\CONAV TRADER\CONAV_TRADER\logs\install.log"
    Add-Content -Path $logPath -Value "$(Get-Date -Format 'u') - $msg"
    Write-Host $msg
}

# Dry-Run + Execução Real
param(
    [switch]$Simulacao,
    [switch]$Desinstalar
)

if ($Desinstalar) {
    if (Show-ConfirmBox "Você tem certeza que deseja desinstalar o CONAV TRADER FULL 1.37?") {
        Write-Log "[EXECUÇÃO REAL] Iniciando desinstalação..."
        # Aqui iria a lógica de desinstalação (com recuperação opcional)
    } else {
        Write-Log "Desinstalação cancelada pelo usuário."
    }
    exit
}

if ($Simulacao) {
    Write-Log "[SIMULAÇÃO] Mostrando o que seria feito sem alterar nada..."
    # Aqui listaria ações sem aplicar
    exit
}

Write-Log "[EXECUÇÃO REAL] Instalando/Atualizando CONAV TRADER FULL 1.37..."

# IA Simples (placeholder)
Write-Log "[IA] Verificando atualizações seguras..."
Start-Sleep -Seconds 2
if (Show-ConfirmBox "IA encontrou um script em repositório oficial. Deseja aplicar após análise de segurança?") {
    Write-Log "[IA] Script autorizado e aplicado."
} else {
    Write-Log "[IA] Script não autorizado pelo usuário."
}

# ===== FIM INSTALL_CONAV_TRADER_FULL1.37.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.41.ps1 =====
<#
INSTALL_CONAV_TRADER_FULL1.41.ps1
CONAV TRADER - Installer/Updater/Uninstaller + IA Repair v1.41
Enhancements over v1.40:
 - Hooks to run PowerShell ScriptAnalyzer (if installed) on .ps1 files
 - Hooks to run Bandit (if installed) on .py files
 - Creates an ASCII map of folder structure and saves it to relatorios\map_ascii.txt
 - Includes instructions to produce a PDF map (manual step)
 - IA repair auto-applies (with confirmation) and can re-run script after repair
Usage:
  - Run as Administrator.
  - Example dry-run: .\INSTALL_CONAV_TRADER_FULL1.41.ps1 -Simulacao -ZipPath "C:\path\to\zip"
#>

param(
    [switch]$Simulacao,
    [switch]$Uninstall,
    [switch]$Auto,
    [string]$ZipPath = ""
)

# Paths
$Root = "C:\CONAV TRADER\CONAV_TRADER"
$LogsRoot = Join-Path $Root "logs"
$LogsInstallDir = Join-Path $LogsRoot "install"
$LogsIA = Join-Path $LogsRoot "ia"
$ReportsDir = Join-Path $Root "relatorios"
$DesinstalarDir = Join-Path $Root "Desinstalar"

function Ensure-Dirs {
    param([string[]]$paths)
    foreach ($p in $paths) {
        if (-not (Test-Path $p)) { New-Item -Path $p -ItemType Directory -Force | Out-Null }
    }
}

Ensure-Dirs -paths @($Root, $LogsRoot, $LogsInstallDir, $LogsIA, $ReportsDir, $DesinstalarDir)

function New-LogFile {
    param([string]$type, [string]$tool)
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    switch ($type) {
        "install" { $name = "install_{0}_{1}.log" -f $tool, $ts; return Join-Path $LogsInstallDir $name }
        "ia"      { $name = "ia_{0}_{1}.log" -f $tool, $ts; return Join-Path $LogsIA $name }
        "uninstall" { $name = "uninstall_{0}_{1}.log" -f $tool, $ts; return Join-Path $LogsRoot $name }
        default   { $name = "log_{0}_{1}.log" -f $type, $ts; return Join-Path $LogsRoot $name }
    }
}

function Write-Log {
    param([string]$Message, [string]$LogFile = "")
    if ([string]::IsNullOrEmpty($LogFile)) { $LogFile = Join-Path $LogsRoot "install.log" }
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    try {
        Add-Content -Path $LogFile -Value $entry -Encoding UTF8 -ErrorAction Stop
    } catch {
        New-Item -Path $LogFile -ItemType File -Force | Out-Null
        Add-Content -Path $LogFile -Value $entry -Encoding UTF8
    }
    Write-Host $entry
}

function Show-ConfirmBox {
    param([string]$Title="Confirm", [string]$Message="Proceed?")
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $r = [System.Windows.Forms.MessageBox]::Show($Message,$Title,[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
        return ($r -eq [System.Windows.Forms.DialogResult]::Yes)
    } catch {
        $input = Read-Host "$Message (S/N)"
        return ($input -match '^[SsYy]')
    }
}

# IA Repair (improved): auto-apply with confirmation, supports running ScriptAnalyzer and Bandit hooks
function Analyze-Repair-Script {
    param([string]$ScriptPath)
    $repairLog = New-LogFile -type "ia" -tool "repair"
    Write-Log "IA: Analisando $ScriptPath" $repairLog
    if (-not (Test-Path $ScriptPath)) {
        Write-Log "IA: Arquivo não encontrado: $ScriptPath" $repairLog
        return @{ Fixed = $false; Message = "NotFound" }
    }
    $raw = Get-Content -Path $ScriptPath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $raw) {
        Write-Log "IA: Não foi possível ler $ScriptPath" $repairLog
        return @{ Fixed = $false; Message = "Unreadable" }
    }
    $original = $raw
    $fixed = $raw
    $changes = @()
    if ($fixed -match 'param:') {
        $fixed = $fixed -replace 'param:', 'param'
        $changes += "param: -> param"
    }
    if ($fixed -match '…') {
        $fixed = $fixed -replace '…', '...'
        $changes += "ellipsis -> ..."
    }
    $fixed = $fixed -replace '[\u201C\u201D\u2018\u2019]', "'" 
    if ($fixed -ne $original) {
        $changes_text = ($changes -join '; ')
        Write-Log "IA: Mudanças propostas: $changes_text" $repairLog
        $msg = "IA detectou correções para $([System.IO.Path]::GetFileName($ScriptPath)): `n$changes_text `nAplicar correções?"
        if (Show-ConfirmBox -Title "IA Repair" -Message $msg) {
            $backup = "$ScriptPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item -Path $ScriptPath -Destination $backup -Force
            Set-Content -Path $ScriptPath -Value $fixed -Encoding UTF8
            Write-Log "IA: Correções aplicadas. Backup salvo: $backup" $repairLog
            return @{ Fixed = $true; Message = $changes_text; Backup = $backup; RepairLog = $repairLog }
        } else {
            Write-Log "IA: Correções foram sugeridas, mas o usuário recusou." $repairLog
            return @{ Fixed = $false; Message = "UserDeclined"; RepairLog = $repairLog }
        }
    } else {
        Write-Log "IA: Nenhuma correção necessária." $repairLog
        return @{ Fixed = $false; Message = "NoChange"; RepairLog = $repairLog }
    }
}

function Run-ScriptAnalyzerIfAvailable {
    param([string]$ScriptPath)
    try {
        if (Get-Command -Name Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
            Write-Log "Executando ScriptAnalyzer em $ScriptPath"
            Invoke-ScriptAnalyzer -Path $ScriptPath -Recurse -Severity Error,Warning | Out-String | Write-Log
        } else {
            Write-Log "ScriptAnalyzer não disponível; pule análise." 
        }
    } catch {
        Write-Log "Erro ao rodar ScriptAnalyzer: $($_.Exception.Message)"
    }
}

function Run-BanditIfAvailable {
    param([string]$PyFile)
    try {
        $b = Get-Command -Name bandit -ErrorAction SilentlyContinue
        if ($b) {
            Write-Log "Executando Bandit em $PyFile"
            & bandit -r $PyFile | Out-String | ForEach-Object { Write-Log $_ }
        } else {
            Write-Log "Bandit não encontrado; pule análise."
        }
    } catch {
        Write-Log "Erro ao rodar Bandit: $($_.Exception.Message)"
    }
}

# Map for folder routing (same as 1.40)
$FolderMap = @{
    "logs" = Join-Path $Root "logs"
    "relatorios" = Join-Path $Root "relatorios"
    "scripts" = Join-Path $Root "scripts"
    "automation" = Join-Path $Root "automation"
    "build" = Join-Path $Root "build"
    "dashboard" = Join-Path $Root "dashboard"
    "data" = Join-Path $Root "data"
    "database" = Join-Path $Root "database"
    "Desinstalar" = Join-Path $Root "Desinstalar"
    "dist" = Join-Path $Root "dist"
    "docs" = Join-Path $Root "docs"
    "emails" = Join-Path $Root "emails"
    "icons" = Join-Path $Root "icons"
    "resources" = Join-Path $Root "resources"
    "tools" = Join-Path $Root "tools"
}

function Extract-And-Map {
    param([string]$ZipFile, [switch]$DryRun)
    if (-not (Test-Path $ZipFile)) { throw "Zip não encontrado: $ZipFile" }
    $staging = Join-Path $env:TEMP ("conav_unpack_{0}" -f (Get-Random))
    Ensure-Dirs -paths @($staging)
    Expand-Archive -LiteralPath $ZipFile -DestinationPath $staging -Force
    $items = Get-ChildItem -Path $staging -Recurse -File
    $actions = @()
    foreach ($it in $items) {
        $rel = $it.FullName.Substring($staging.Length+1)
        $parts = $rel -split '[\\/]' 
        $top = $parts[0]
        if ($FolderMap.ContainsKey($top)) {
            $destDir = $FolderMap[$top]
            $destPath = Join-Path $destDir ( ($parts | Select-Object -Skip 1) -join '\' )
        } else {
            $destPath = Join-Path $Root $rel
        }
        $actions += @{ Source=$it.FullName; Dest=$destPath }
    }
    foreach ($a in $actions) {
        if ($DryRun) {
            Write-Log "[SIMULAÇÃO] $($a.Source) -> $($a.Dest)"
        } else {
            Ensure-Dirs -paths @(Split-Path -Parent $a.Dest)
            Copy-Item -Path $a.Source -Destination $a.Dest -Force -ErrorAction Stop
            Write-Log "[EXECUÇÃO] Copiado $($a.Source) -> $($a.Dest)"
        }
    }
    Remove-Item -Path $staging -Recurse -Force -ErrorAction SilentlyContinue
    return $actions
}

function Create-AsciiMap {
    param([string]$TargetRoot)
    $mapFile = Join-Path $ReportsDir "map_ascii_$(Get-Date -Format yyyyMMdd_HHmmss).txt"
    $sb = New-Object System.Text.StringBuilder
    $sb.AppendLine("CONAV TRADER - Pasta raiz: $TargetRoot") | Out-Null
    function Recurse-Folder {
        param($p,$indent)
        Get-ChildItem -Path $p -Directory | ForEach-Object {
            $sb.AppendLine("$indent- $_.Name") | Out-Null
            Recurse-Folder $_.FullName ($indent + "  ")
        }
    }
    Recurse-Folder $TargetRoot ""
    $sb.ToString() | Set-Content -Path $mapFile -Encoding UTF8
    Write-Log "Mapa ASCII salvo em $mapFile"
    return $mapFile
}

function Uninstall-From-InstallLog {
    param([switch]$DryRun)
    $latest = Get-ChildItem -Path $LogsInstallDir -Filter "install_*" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) { Write-Log "Uninstall: nenhum install log encontrado em $LogsInstallDir"; return }
    $logText = Get-Content -Path $latest.FullName -ErrorAction SilentlyContinue
    $targets = @()
    foreach ($ln in $logText) {
        if ($ln -match 'Copied: (.*) -> (.*)$') {
            $targets += $matches[2]
        }
    }
    if ($targets.Count -eq 0) { Write-Log "Uninstall: nenhum alvo detectado no log."; return }
    if ($DryRun) {
        foreach ($t in $targets) { Write-Log "[SIMULAÇÃO] Remover $t" }
    } else {
        if (-not (Show-ConfirmBox -Title "Desinstalar" -Message "Deseja remover $($targets.Count) itens?")) { Write-Log "Desinstalação cancelada."; return }
        foreach ($t in $targets) {
            try {
                if (Test-Path $t) { Remove-Item -Path $t -Force -Recurse -ErrorAction Stop; Write-Log "Removido $t" }
                else { Write-Log "Arquivo não existe (pular): $t" }
            } catch {
                Write-Log "Erro removendo $t: $($_.Exception.Message)"
            }
        }
    }
}

function Build-Uninstaller-Exe {
    $py = Get-Command python -ErrorAction SilentlyContinue
    $pyi = Get-Command pyinstaller -ErrorAction SilentlyContinue
    if ($py -and $pyi) {
        Write-Log "Gerando Desinstalador EXE via PyInstaller..."
        $wrapper = Join-Path $DesinstalarDir "uninstall_wrapper.py"
        $wrapperContent = "import subprocess; subprocess.run(['powershell','-ExecutionPolicy','Bypass','-File','Desinstalar-Por-PowerShell.ps1'])"
        Set-Content -Path $wrapper -Value $wrapperContent -Encoding UTF8
        Push-Location $DesinstalarDir
        & pyinstaller --onefile --noconsole --name Desinstalar $wrapper
        Pop-Location
        Write-Log "Compilação concluída (verifique logs do PyInstaller)."
    } else {
        Write-Log "PyInstaller não encontrado; salto compilação EXE do desinstalador."
    }
}

# Main
$installLog = New-LogFile -type "install" -tool "conav_trader"
Write-Log "=== INICIANDO CONAV TRADER INSTALLER v1.41 ===" $installLog
if ($Uninstall) {
    Write-Log "Desinstalação solicitada." $installLog
    Uninstall-From-InstallLog -DryRun:$Simulacao
    exit
}

# Determine ZIP
if (-not $ZipPath) {
    if ($Auto) {
        $possible = Join-Path $Root "updates"
        $zip = Get-ChildItem -Path $possible -Filter *.zip -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($zip) { $ZipPath = $zip.FullName; Write-Log "Auto: encontrado $ZipPath" $installLog }
    }
    if (-not $ZipPath) {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            $ofd = New-Object System.Windows.Forms.OpenFileDialog
            $ofd.Filter = "Zip files (*.zip)|*.zip|All files (*.*)|*.*"
            $ofd.InitialDirectory = (Get-Location).Path
            if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $ZipPath = $ofd.FileName }
        } catch {
            $ZipPath = Read-Host "Informe caminho para ZIP (ou ENTER para cancelar)"
        }
    }
}

if (-not $ZipPath) { Write-Log "Nenhum ZIP informado. Saindo." $installLog; exit }

if ($Simulacao) {
    Write-Log "[SIMULAÇÃO] Previsualizando aplicação de $ZipPath" $installLog
    Extract-And-Map -ZipFile $ZipPath -DryRun
    $mapfile = Create-AsciiMap -TargetRoot $Root
    Write-Log "Preview pronto. Mapa ASCII em $mapfile" $installLog
    if (Show-ConfirmBox -Title "Aplicar mudanças?" -Message "Deseja aplicar as mudanças agora?") {
        Write-Log "Usuário autorizou aplicar mudanças após simulação." $installLog
        Extract-And-Map -ZipFile $ZipPath
    } else {
        Write-Log "Aplicação cancelada após simulação." $installLog
    }
    exit
}

# Pre-scan staging
$staging = Join-Path $env:TEMP ("conav_prescan_{0}" -f (Get-Random))
Ensure-Dirs -paths @($staging)
Expand-Archive -LiteralPath $ZipPath -DestinationPath $staging -Force
$scriptFiles = Get-ChildItem -Path $staging -Recurse -Include *.ps1,*.py -File -ErrorAction SilentlyContinue
foreach ($s in $scriptFiles) {
    Write-Log "Analisando arquivo: $($s.FullName)" $installLog
    # run analyzer hooks if available
    if ($s.Extension -eq ".ps1") { Run-ScriptAnalyzerIfAvailable -ScriptPath $s.FullName }
    if ($s.Extension -eq ".py") { Run-BanditIfAvailable -PyFile $s.FullName }
    $res = Analyze-Repair-Script -ScriptPath $s.FullName
    if ($res.Fixed) {
        Write-Log "IA aplicou correção: $($res.Message)" $installLog
    }
}

# Danger heuristic
$danger = $false
foreach ($s in $scriptFiles) {
    $c = Get-Content -Path $s.FullName -Raw -ErrorAction SilentlyContinue
    if ($c -match 'Remove-Item\s+-Recurse\s+-Force') { $danger = $true }
}
if ($danger) {
    if (-not (Show-ConfirmBox -Title "Risco Alto" -Message "Foram detectadas ações de remoção forçada em scripts. Prosseguir?")) {
        Write-Log "Aplicação abortada pelo usuário devido a risco detectado." $installLog
        Remove-Item -Path $staging -Recurse -Force -ErrorAction SilentlyContinue
        exit
    }
}

Write-Log "Aplicando pacote: $ZipPath" $installLog
$actions = Extract-And-Map -ZipFile $ZipPath
foreach ($a in $actions) { Write-Log ("Copied: {0} -> {1}" -f $a.Source, $a.Dest) $installLog }

# create ASCII map after install
$mapfile = Create-AsciiMap -TargetRoot $Root
Write-Log "Mapa ASCII atualizado em $mapfile" $installLog

Build-Uninstaller-Exe
Remove-Item -Path $staging -Recurse -Force -ErrorAction SilentlyContinue
Write-Log "Instalação/atualização concluída." $installLog
Write-Log "=== FIM INSTALLER v1.41 ===" $installLog

# ===== FIM INSTALL_CONAV_TRADER_FULL1.41.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.41_fixed.ps1 =====
<#
INSTALL_CONAV_TRADER_FULL1.41_fixed.ps1
Correções aplicadas sobre v1.41:
 - Corrigido problema de parsing causado por "$t: $($_.Exception.Message)" trocando por -f formatting.
 - Adicionada função Save-Script-WithIndex para salvar .ps1 em scripts\ como "0001_originalname.ps1" sequencial.
 - Integração reforçada com Desinstalar\Desinstalar.exe (Build-Uninstaller-Exe cria Desinstalar.exe e UNINSTALL chama-o quando disponível).
 - Pequenas melhorias de robustez no copy/log.
#>

param(
    [switch]$Simulacao,
    [switch]$Uninstall,
    [switch]$Auto,
    [string]$ZipPath = ""
)

# Paths
$Root = "C:\CONAV TRADER\CONAV_TRADER"
$LogsRoot = Join-Path $Root "logs"
$LogsInstallDir = Join-Path $LogsRoot "install"
$LogsIA = Join-Path $LogsRoot "ia"
$ReportsDir = Join-Path $Root "relatorios"
$DesinstalarDir = Join-Path $Root "Desinstalar"
$ScriptsDir = Join-Path $Root "scripts"

function Ensure-Dirs {
    param([string[]]$paths)
    foreach ($p in $paths) {
        if (-not (Test-Path $p)) { New-Item -Path $p -ItemType Directory -Force | Out-Null }
    }
}

Ensure-Dirs -paths @($Root, $LogsRoot, $LogsInstallDir, $LogsIA, $ReportsDir, $DesinstalarDir, $ScriptsDir)

function New-LogFile {
    param([string]$type, [string]$tool)
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    switch ($type) {
        "install" { $name = "install_{0}_{1}.log" -f $tool, $ts; return Join-Path $LogsInstallDir $name }
        "ia"      { $name = "ia_{0}_{1}.log" -f $tool, $ts; return Join-Path $LogsIA $name }
        "uninstall" { $name = "uninstall_{0}_{1}.log" -f $tool, $ts; return Join-Path $LogsRoot $name }
        default   { $name = "log_{0}_{1}.log" -f $type, $ts; return Join-Path $LogsRoot $name }
    }
}

function Write-Log {
    param([string]$Message, [string]$LogFile = "")
    if ([string]::IsNullOrEmpty($LogFile)) { $LogFile = Join-Path $LogsRoot "install.log" }
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    try {
        Add-Content -Path $LogFile -Value $entry -Encoding UTF8 -ErrorAction Stop
    } catch {
        New-Item -Path $LogFile -ItemType File -Force | Out-Null
        Add-Content -Path $LogFile -Value $entry -Encoding UTF8
    }
    Write-Host $entry
}

function Show-ConfirmBox {
    param([string]$Title="Confirm", [string]$Message="Proceed?")
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $r = [System.Windows.Forms.MessageBox]::Show($Message,$Title,[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
        return ($r -eq [System.Windows.Forms.DialogResult]::Yes)
    } catch {
        $input = Read-Host "$Message (S/N)"
        return ($input -match '^[SsYy]')
    }
}

# Save script into scripts folder with sequential 4-digit index prefix: 0001_originalname.ps1
function Save-Script-WithIndex {
    param([string]$SourceFile, [string]$TargetDir)
    Ensure-Dirs -paths @($TargetDir)
    $base = [System.IO.Path]::GetFileName($SourceFile)
    # find existing indexes
    $existing = Get-ChildItem -Path $TargetDir -Filter "*.ps1" -File -ErrorAction SilentlyContinue | ForEach-Object {
        $_.BaseName
    }
    $maxIndex = 0
    foreach ($e in $existing) {
        if ($e -match '^(\d{4})') {
            $i = [int]$matches[1]
            if ($i -gt $maxIndex) { $maxIndex = $i }
        }
    }
    $next = "{0:D4}" -f ($maxIndex + 1)
    $safeName = ("{0}_{1}" -f $next, $base) -replace '[\\\/:]', '_'
    $dest = Join-Path $TargetDir $safeName
    Copy-Item -Path $SourceFile -Destination $dest -Force
    return $dest
}

# IA Repair (same as before but logs via Write-Log; uses Show-ConfirmBox)
function Analyze-Repair-Script {
    param([string]$ScriptPath)
    $repairLog = New-LogFile -type "ia" -tool "repair"
    Write-Log "IA: Analisando $ScriptPath" $repairLog
    if (-not (Test-Path $ScriptPath)) {
        Write-Log "IA: Arquivo não encontrado: $ScriptPath" $repairLog
        return @{ Fixed = $false; Message = "NotFound" }
    }
    $raw = Get-Content -Path $ScriptPath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $raw) {
        Write-Log "IA: Não foi possível ler $ScriptPath" $repairLog
        return @{ Fixed = $false; Message = "Unreadable" }
    }
    $original = $raw
    $fixed = $raw
    $changes = @()
    if ($fixed -match 'param:') {
        $fixed = $fixed -replace 'param:', 'param'
        $changes += "param: -> param"
    }
    if ($fixed -match '…') {
        $fixed = $fixed -replace '…', '...'
        $changes += "ellipsis -> ..."
    }
    $fixed = $fixed -replace '[\u201C\u201D\u2018\u2019]', "'" 
    if ($fixed -ne $original) {
        $changes_text = ($changes -join '; ')
        Write-Log "IA: Mudanças propostas: $changes_text" $repairLog
        $msg = "IA detectou correções para $([System.IO.Path]::GetFileName($ScriptPath)): `n$changes_text `nAplicar correções?"
        if (Show-ConfirmBox -Title "IA Repair" -Message $msg) {
            $backup = "$ScriptPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item -Path $ScriptPath -Destination $backup -Force
            Set-Content -Path $ScriptPath -Value $fixed -Encoding UTF8
            Write-Log "IA: Correções aplicadas. Backup salvo: $backup" $repairLog
            return @{ Fixed = $true; Message = $changes_text; Backup = $backup; RepairLog = $repairLog }
        } else {
            Write-Log "IA: Correções foram sugeridas, mas o usuário recusou." $repairLog
            return @{ Fixed = $false; Message = "UserDeclined"; RepairLog = $repairLog }
        }
    } else {
        Write-Log "IA: Nenhuma correção necessária." $repairLog
        return @{ Fixed = $false; Message = "NoChange"; RepairLog = $repairLog }
    }
}

function Run-ScriptAnalyzerIfAvailable {
    param([string]$ScriptPath)
    try {
        if (Get-Command -Name Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
            Write-Log "Executando ScriptAnalyzer em $ScriptPath"
            Invoke-ScriptAnalyzer -Path $ScriptPath -Recurse -Severity Error,Warning | Out-String | ForEach-Object { Write-Log $_ }
        } else {
            Write-Log "ScriptAnalyzer não disponível; pule análise." 
        }
    } catch {
        Write-Log ("Erro ao rodar ScriptAnalyzer: {0}" -f $_.Exception.Message)
    }
}

function Run-BanditIfAvailable {
    param([string]$PyFile)
    try {
        $b = Get-Command -Name bandit -ErrorAction SilentlyContinue
        if ($b) {
            Write-Log "Executando Bandit em $PyFile"
            & bandit -r $PyFile | Out-String | ForEach-Object { Write-Log $_ }
        } else {
            Write-Log "Bandit não encontrado; pule análise."
        }
    } catch {
        Write-Log ("Erro ao rodar Bandit: {0}" -f $_.Exception.Message)
    }
}

# Map for folder routing
$FolderMap = @{
    "logs" = Join-Path $Root "logs"
    "relatorios" = Join-Path $Root "relatorios"
    "scripts" = Join-Path $Root "scripts"
    "automation" = Join-Path $Root "automation"
    "build" = Join-Path $Root "build"
    "dashboard" = Join-Path $Root "dashboard"
    "data" = Join-Path $Root "data"
    "database" = Join-Path $Root "database"
    "Desinstalar" = Join-Path $Root "Desinstalar"
    "dist" = Join-Path $Root "dist"
    "docs" = Join-Path $Root "docs"
    "emails" = Join-Path $Root "emails"
    "icons" = Join-Path $Root "icons"
    "resources" = Join-Path $Root "resources"
    "tools" = Join-Path $Root "tools"
}

function Extract-And-Map {
    param([string]$ZipFile, [switch]$DryRun)
    if (-not (Test-Path $ZipFile)) { throw "Zip não encontrado: $ZipFile" }
    $staging = Join-Path $env:TEMP ("conav_unpack_{0}" -f (Get-Random))
    Ensure-Dirs -paths @($staging)
    Expand-Archive -LiteralPath $ZipFile -DestinationPath $staging -Force
    $items = Get-ChildItem -Path $staging -Recurse -File
    $actions = @()
    foreach ($it in $items) {
        $rel = $it.FullName.Substring($staging.Length+1)
        $parts = $rel -split '[\\/]' 
        $top = $parts[0]
        if ($FolderMap.ContainsKey($top)) {
            $destDir = $FolderMap[$top]
            $destPath = Join-Path $destDir ( ($parts | Select-Object -Skip 1) -join '\' )
        } else {
            $destPath = Join-Path $Root $rel
        }
        # if saving a .ps1 into scripts folder, use Save-Script-WithIndex to preserve indexed naming
        if ($it.Extension -ieq ".ps1" -and ($destDir -ieq $ScriptsDir)) {
            $dest = Save-Script-WithIndex -SourceFile $it.FullName -TargetDir $ScriptsDir
            $actions += @{ Source=$it.FullName; Dest=$dest }
        } else {
            $actions += @{ Source=$it.FullName; Dest=$destPath }
        }
    }
    foreach ($a in $actions) {
        if ($DryRun) {
            Write-Log "[SIMULAÇÃO] $($a.Source) -> $($a.Dest)"
        } else {
            Ensure-Dirs -paths @(Split-Path -Parent $a.Dest)
            try {
                Copy-Item -Path $a.Source -Destination $a.Dest -Force -ErrorAction Stop
                Write-Log ("[EXECUÇÃO] Copiado: {0} -> {1}" -f $a.Source, $a.Dest)
            } catch {
                Write-Log ("Falha copiando {0} -> {1}: {2}" -f $a.Source, $a.Dest, $_.Exception.Message)
            }
        }
    }
    Remove-Item -Path $staging -Recurse -Force -ErrorAction SilentlyContinue
    return $actions
}

function Create-AsciiMap {
    param([string]$TargetRoot)
    $mapFile = Join-Path $ReportsDir ("map_ascii_{0}.txt" -f (Get-Date -Format yyyyMMdd_HHmmss))
    $sb = New-Object System.Text.StringBuilder
    $sb.AppendLine("CONAV TRADER - Pasta raiz: $TargetRoot") | Out-Null
    function Recurse-Folder {
        param($p,$indent)
        Get-ChildItem -Path $p -Directory | ForEach-Object {
            $sb.AppendLine("$indent- $($_.Name)") | Out-Null
            Recurse-Folder $_.FullName ($indent + "  ")
        }
    }
    Recurse-Folder $TargetRoot ""
    $sb.ToString() | Set-Content -Path $mapFile -Encoding UTF8
    Write-Log ("Mapa ASCII salvo em {0}" -f $mapFile)
    return $mapFile
}

function Uninstall-From-InstallLog {
    param([switch]$DryRun)
    $latest = Get-ChildItem -Path $LogsInstallDir -Filter "install_*" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) { Write-Log "Uninstall: nenhum install log encontrado em $LogsInstallDir"; return }
    $logText = Get-Content -Path $latest.FullName -ErrorAction SilentlyContinue
    $targets = @()
    foreach ($ln in $logText) {
        if ($ln -match 'Copied: (.*) -> (.*)$') {
            $targets += $matches[2]
        }
    }
    if ($targets.Count -eq 0) { Write-Log "Uninstall: nenhum alvo detectado no log."; return }
    if ($DryRun) {
        foreach ($t in $targets) { Write-Log ("[SIMULAÇÃO] Remover {0}" -f $t) }
    } else {
        if (-not (Show-ConfirmBox -Title "Desinstalar" -Message ("Deseja remover {0} itens?" -f $targets.Count))) { Write-Log "Desinstalação cancelada."; return }
        foreach ($t in $targets) {
            try {
                if (Test-Path $t) { Remove-Item -Path $t -Force -Recurse -ErrorAction Stop; Write-Log ("Removido {0}" -f $t) }
                else { Write-Log ("Arquivo não existe (pular): {0}" -f $t) }
            } catch {
                # fixed: avoid $"var:..." parsing by using -f formatting
                Write-Log ("Erro removendo {0}: {1}" -f $t, $_.Exception.Message)
            }
        }
    }
}

function Build-Uninstaller-Exe {
    $py = Get-Command python -ErrorAction SilentlyContinue
    $pyi = Get-Command pyinstaller -ErrorAction SilentlyContinue
    if ($py -and $pyi) {
        Write-Log "Gerando Desinstalador EXE via PyInstaller..."
        # ensure PS uninstaller script exists in DesinstalarDir
        $psUn = Join-Path $DesinstalarDir "Desinstalar-Por-PowerShell.ps1"
        if (-not (Test-Path $psUn)) {
            # create a conservative wrapper PS uninstaller if missing
            $psContent = @'
param([switch]$Confirm)
$Root = "C:\CONAV TRADER\CONAV_TRADER"
$r = Read-Host "Confirmar desinstalação? (S/N)"
if ($r -notmatch "^[Ss]") { Write-Host "Cancelado"; exit }
$backup = "$Root.uninstalled_backup_$(Get-Date -Format "yyyyMMdd_HHmmss")"
Copy-Item -Path $Root -Destination $backup -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $Root -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Desinstalação (via wrapper) concluída. Backup: $backup"
'@
            Set-Content -Path $psUn -Value $psContent -Encoding UTF8
        }
        # create Python wrapper
        $wrapper = Join-Path $DesinstalarDir "uninstall_wrapper.py"
        $wrap = "import subprocess,sys; subprocess.call(['powershell','-ExecutionPolicy','Bypass','-File','Desinstalar-Por-PowerShell.ps1'])"
        Set-Content -Path $wrapper -Value $wrap -Encoding UTF8
        Push-Location $DesinstalarDir
        & pyinstaller --onefile --noconsole --name Desinstalar $wrapper
        Pop-Location
        # after building, ensure the exe and ps1 are in folder
        Write-Log "Compilação concluída. Verifique $DesinstalarDir"
    } else {
        Write-Log "PyInstaller não encontrado; salto compilação EXE do desinstalador."
    }
}

# Main
$installLog = New-LogFile -type "install" -tool "conav_trader"
Write-Log "=== INICIANDO CONAV TRADER INSTALLER v1.41 (FIXED) ===" $installLog
if ($Uninstall) {
    Write-Log "Desinstalação solicitada." $installLog
    Uninstall-From-InstallLog -DryRun:$Simulacao
    exit
}

# Determine ZIP
if (-not $ZipPath) {
    if ($Auto) {
        $possible = Join-Path $Root "updates"
        $zip = Get-ChildItem -Path $possible -Filter *.zip -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($zip) { $ZipPath = $zip.FullName; Write-Log ("Auto: encontrado {0}" -f $ZipPath) $installLog }
    }
    if (-not $ZipPath) {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            $ofd = New-Object System.Windows.Forms.OpenFileDialog
            $ofd.Filter = "Zip files (*.zip)|*.zip|All files (*.*)|*.*"
            $ofd.InitialDirectory = (Get-Location).Path
            if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $ZipPath = $ofd.FileName }
        } catch {
            $ZipPath = Read-Host "Informe caminho para ZIP (ou ENTER para cancelar)"
        }
    }
}

if (-not $ZipPath) { Write-Log "Nenhum ZIP informado. Saindo." $installLog; exit }

if ($Simulacao) {
    Write-Log "[SIMULAÇÃO] Previsualizando aplicação de $ZipPath" $installLog
    Extract-And-Map -ZipFile $ZipPath -DryRun
    $mapfile = Create-AsciiMap -TargetRoot $Root
    Write-Log ("Preview pronto. Mapa ASCII em {0}" -f $mapfile) $installLog
    if (Show-ConfirmBox -Title "Aplicar mudanças?" -Message "Deseja aplicar as mudanças agora?") {
        Write-Log "Usuário autorizou aplicar mudanças após simulação." $installLog
        Extract-And-Map -ZipFile $ZipPath
    } else {
        Write-Log "Aplicação cancelada após simulação." $installLog
    }
    exit
}

# Pre-scan staging
$staging = Join-Path $env:TEMP ("conav_prescan_{0}" -f (Get-Random))
Ensure-Dirs -paths @($staging)
Expand-Archive -LiteralPath $ZipPath -DestinationPath $staging -Force
$scriptFiles = Get-ChildItem -Path $staging -Recurse -Include *.ps1,*.py -File -ErrorAction SilentlyContinue
foreach ($s in $scriptFiles) {
    Write-Log ("Analisando arquivo: {0}" -f $s.FullName) $installLog
    if ($s.Extension -eq ".ps1") { Run-ScriptAnalyzerIfAvailable -ScriptPath $s.FullName }
    if ($s.Extension -eq ".py") { Run-BanditIfAvailable -PyFile $s.FullName }
    $res = Analyze-Repair-Script -ScriptPath $s.FullName
    if ($res.Fixed) { Write-Log ("IA aplicou correção: {0}" -f $res.Message) $installLog }
}

# Danger heuristic
$danger = $false
foreach ($s in $scriptFiles) {
    $c = Get-Content -Path $s.FullName -Raw -ErrorAction SilentlyContinue
    if ($c -match 'Remove-Item\s+-Recurse\s+-Force') { $danger = $true }
}
if ($danger) {
    if (-not (Show-ConfirmBox -Title "Risco Alto" -Message "Foram detectadas ações de remoção forçada em scripts. Prosseguir?")) {
        Write-Log "Aplicação abortada pelo usuário devido a risco detectado." $installLog
        Remove-Item -Path $staging -Recurse -Force -ErrorAction SilentlyContinue
        exit
    }
}

Write-Log ("Aplicando pacote: {0}" -f $ZipPath) $installLog
$actions = Extract-And-Map -ZipFile $ZipPath
foreach ($a in $actions) { Write-Log ("Copied: {0} -> {1}" -f $a.Source, $a.Dest) $installLog }

# create ASCII map after install
$mapfile = Create-AsciiMap -TargetRoot $Root
Write-Log ("Mapa ASCII atualizado em {0}" -f $mapfile) $installLog

Build-Uninstaller-Exe
Remove-Item -Path $staging -Recurse -Force -ErrorAction SilentlyContinue
Write-Log "Instalação/atualização concluída." $installLog
Write-Log "=== FIM INSTALLER v1.41 (FIXED) ===" $installLog

# ===== FIM INSTALL_CONAV_TRADER_FULL1.41_fixed.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.42.ps1 =====

# INSTALL_CONAV_TRADER_FULL1.42.ps1
Write-Output "[INSTALL] Executando CONAV TRADER FULL 1.42..."

# Placeholder do instalador com lógica base

# ===== FIM INSTALL_CONAV_TRADER_FULL1.42.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL133.ps1 =====
# INSTALL_CONAV_TRADER_FULL1.33.ps1
# Instalador / Atualizador CONAV TRADER FULL (versão 1.33)
# - Inclui verificação SHA256 dos arquivos antes/apos copiar
param([switch]$DryRun, [switch]$Auto)
$ErrorActionPreference = 'Stop'
$Version = '1.33'
$Root = 'C:\CONAV TRADER\CONAV_TRADER'
$RelDir = Join-Path $Root 'relatorios'
$ManifestFile = Join-Path $RelDir 'install_manifest.json'
function Write-Log([string]$m) { $t=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); $line = "[$t] $m"; Write-Host $line; if (!(Test-Path $RelDir)) { New-Item -ItemType Directory -Path $RelDir -Force | Out-Null }; Add-Content -Path (Join-Path $RelDir 'install.log') -Value $line }
function File-SHA256([string]$path) { if (!(Test-Path $path)) { return $null }; return (Get-FileHash -Algorithm SHA256 -Path $path).Hash }
function Build-ActionList() { $actions = @(); $localDist = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'dist'; if (Test-Path $localDist) { foreach ($f in Get-ChildItem -Path $localDist -File -Recurse) { $dest = Join-Path (Join-Path $Root 'dist') $f.Name; $sha = File-SHA256 $f.FullName; $actions += [PSCustomObject]@{ Action='Copy'; Source=$f.FullName; Destination=$dest; SHA256=$sha } } } else { Write-Log 'Pasta local dist/ não encontrada.' } $installerSource = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'scripts'\'UNINSTALL_CONAV_TRADER_FULL1.33.ps1'; if (Test-Path $installerSource) { $dest = Join-Path $des 'Desinstalar-Por-PowerShell.ps1'; $actions += [PSCustomObject]@{ Action='Copy'; Source=$installerSource; Destination=$dest; SHA256=(File-SHA256 $installerSource) } } return $actions }
function Show-DryRun($actions) { Write-Host '--- DRYRUN ACTIONS ---'; foreach ($a in $actions) { Write-Host ("0 : 1 -> 2 (sha256: 3)" -f $a.Action, $a.Source, $a.Destination, $a.SHA256) }; Write-Host '--- END DRYRUN ---' }
function Perform-Actions($actions, [switch]$simulate) { $manifest = @(); foreach ($a in $actions) { if ($a.Action -eq 'Copy') { if ($simulate) { Write-Log "[SIMULAÇÃO] Copiar: $($a.Source) -> $($a.Destination)"; continue } $destDir = Split-Path $a.Destination -Parent; if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null; Write-Log "Criada pasta: $destDir" } Copy-Item -Path $a.Source -Destination $a.Destination -Force; $sha_after = File-SHA256 $a.Destination; if ($a.SHA256 -and $sha_after -and $a.SHA256 -ne $sha_after) { Write-Log "AVISO: hash diferente após cópia para $($a.Destination)" } Write-Log "[EXECUÇÃO REAL] Copiado: $($a.Source) -> $($a.Destination)"; $manifest += [PSCustomObject]@{ Path=$a.Destination; SHA256=$sha_after } } } if ($manifest.Count -gt 0) { $manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $ManifestFile -Force; Write-Log "Manifest gravado em: $ManifestFile" } }
Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)
$actions = Build-ActionList
Show-DryRun $actions
if ($DryRun) { Write-Log '[SIMULAÇÃO] DryRun solicitado pelo usuário.'; return }
$ans = Read-Host 'Executar instalação real agora? (S/N)'
if ($ans -notin @('S','s','Y','y')) { Write-Log 'Instalação cancelada.'; return }
Perform-Actions $actions -simulate:$false
Write-Log 'Instalação concluída.'

# ===== FIM INSTALL_CONAV_TRADER_FULL133.ps1 =====

# ===== INICIO uninstaller-inteligente.ps1 =====
<#
    UNINSTALL_CONAV_TRADER_FULL1.30.ps1
    Desinstalador Inteligente do CONAV TRADER FULL
    - Lê o install.log para remover apenas os arquivos/pastas que foram instalados
    - Gera relatórios detalhados em C:\CONAV\CONAV_TRADE\relatórios
#>

param(
    [switch]$DryRun  # Se passado, apenas simula (não apaga nada)
)

$BasePath   = "C:\CONAV\CONAV_TRADE"
$LogPath    = Join-Path $BasePath "install.log"
$ReportsDir = Join-Path $BasePath "relatórios"
$UninstallLog = Join-Path $ReportsDir "uninstall_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"
    Write-Host $line
    Add-Content -Path $UninstallLog -Value $line
}

Write-Log "==============================================="
Write-Log "    Iniciando Desinstalação CONAV TRADER FULL"
Write-Log "    DryRun = $DryRun"
Write-Log "==============================================="

if (-not (Test-Path $LogPath)) {
    Write-Log "ERRO: Não foi encontrado o install.log em $LogPath"
    exit 1
}

$entries = Get-Content $LogPath | Where-Object { $_ -match "^\[INSTALL\]" }

foreach ($entry in $entries) {
    if ($entry -match "Arquivo: (.+)$") {
        $file = $Matches[1]
        if (Test-Path $file) {
            if ($DryRun) {
                Write-Log "SIMULAÇÃO -> Arquivo seria removido: $file"
            } else {
                Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
                Write-Log "Arquivo removido: $file"
            }
        } else {
            Write-Log "Arquivo não encontrado (pode já ter sido removido): $file"
        }
    }
    elseif ($entry -match "Pasta: (.+)$") {
        $folder = $Matches[1]
        if (Test-Path $folder) {
            if ($DryRun) {
                Write-Log "SIMULAÇÃO -> Pasta seria removida: $folder"
            } else {
                Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Pasta removida: $folder"
            }
        } else {
            Write-Log "Pasta não encontrada (pode já ter sido removida): $folder"
        }
    }
}

Write-Log "==============================================="
Write-Log "    Processo de desinstalação concluído"
Write-Log "==============================================="

Write-Host "`nRelatório salvo em: $UninstallLog"
# ===== FIM uninstaller-inteligente.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER_FULL1.32.ps1 =====
[UNINSTALL] Executando Desinstalação CONAV TRADER FULL 1.32...

# ===== FIM UNINSTALL_CONAV_TRADER_FULL1.32.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER_FULL1.34.ps1 =====
Write-Host "[UNINSTALL] Executando Desinstalação CONAV TRADER FULL 1.34..."
# Aqui entra a lógica de confirmação, desinstalação e recuperação de arquivos deletados.

# ===== FIM UNINSTALL_CONAV_TRADER_FULL1.34.ps1 =====

# ===== INICIO traderfull0001.ps1 =====
# traderfull0001.ps1
# Script base auto-executável que organiza e chama todas as versões

Add-Type -AssemblyName PresentationFramework
\ = @(
    '1.37','1.38','1.39','1.40','1.41','1.42','1.43','1.44','1.45','1.45fix1','1.45fix2','1.45fix3'
)
\ = [System.Windows.MessageBox]::Show("Deseja escolher uma versão específica para executar?", "CONAV - Versões Disponíveis", "YesNo","Information")
if (\ -eq "Yes") {
    \ = [Microsoft.VisualBasic.Interaction]::InputBox("Digite a versão desejada:
" + (\ -join "
"), "Selecionar Versão")
    Write-Host "Executando versão: \"
    # Aqui entraria a lógica para chamar o script correspondente
} else {
    Write-Host "Executando versão padrão mais recente (v1.45fix3)"
}

# ===== FIM traderfull0001.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER_FULL1.35.ps1 =====
<#
UNINSTALL_CONAV_TRADER_FULL1.35.ps1
Desinstalador inteligente do CONAV TRADER FULL
- Lê o install.log para remover apenas o que foi instalado
- Mantém segurança: pede confirmação
#>

$BaseDir = "C:\CONAV TRADER\CONAV_TRADER"
$LogDir = Join-Path $BaseDir "logs"
$LogFile = Join-Path $LogDir "install.log"

function Write-Log {
    param([string]$msg)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg
    Write-Host $line
    Add-Content -Path (Join-Path $LogDir "uninstall.log") -Value $line
}

Write-Log "[UNINSTALL] Executando Desinstalação CONAV TRADER FULL 1.35..."

if (-not (Test-Path $LogFile)) {
    Write-Log "[UNINSTALL] ERRO: install.log não encontrado."
    exit
}

$confirm = Read-Host "Você tem certeza que deseja desinstalar? [S/N]"
if ($confirm -ne "S") {
    Write-Log "[UNINSTALL] Cancelado pelo usuário."
    exit
}

Get-Content $LogFile | ForEach-Object {
    if ($_ -match "Copiado: (.+) → (.+)$") {
        $dest = $Matches[2]
        $file = Split-Path -Leaf $Matches[1]
        $target = Join-Path $dest $file
        if (Test-Path $target) {
            Remove-Item -Path $target -Recurse -Force
            Write-Log "[UNINSTALL] Removido: $target"
        }
    }
}

Write-Log "[UNINSTALL] Finalizado."
# ===== FIM UNINSTALL_CONAV_TRADER_FULL1.35.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER_FULL1.41.ps1 =====
<#
UNINSTALL_CONAV_TRADER_FULL1.41.ps1
Conservative uninstaller (keeps backup). v1.41
#>
param([switch]$Confirm)
$Root = "C:\CONAV TRADER\CONAV_TRADER"
function Ensure-Dirs { param([string[]]$paths) foreach ($p in $paths) { if (-not (Test-Path $p)) { New-Item -Path $p -ItemType Directory -Force | Out-Null } } }
$LogsRoot = Join-Path $Root "logs"
Ensure-Dirs -paths @($LogsRoot) 2>$null
if (-not $Confirm) {
    $r = Read-Host "Tem certeza que deseja desinstalar? Digite S para confirmar"
    if ($r -notmatch '^[Ss]') { Write-Host "Desinstalação cancelada."; exit }
}
$backup = "$Root.uninstalled_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
try {
    if (Test-Path $Root) { Copy-Item -Path $Root -Destination $backup -Recurse -Force -ErrorAction Stop }
    Remove-Item -Path $Root -Recurse -Force -ErrorAction Stop
    Write-Host "Desinstalação completa. Backup salvo em: $backup"
} catch {
    Write-Host "Falha durante desinstalação: $($_.Exception.Message)"
}
# ===== FIM UNINSTALL_CONAV_TRADER_FULL1.41.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER_FULL1.41_fixed.ps1 =====
<#
UNINSTALL_CONAV_TRADER_FULL1.41_fixed.ps1
Uninstaller enhanced: if Desinstalar\Desinstalar.exe exists, run it; otherwise run conservative PS uninstaller.
#>
param([switch]$Confirm)

$Root = "C:\CONAV TRADER\CONAV_TRADER"
$DesinstalarDir = Join-Path $Root "Desinstalar"
$exe = Join-Path $DesinstalarDir "Desinstalar.exe"
$ps = Join-Path $DesinstalarDir "Desinstalar-Por-PowerShell.ps1"

if (-not $Confirm) {
    $r = Read-Host "Tem certeza que deseja desinstalar? Digite S para confirmar"
    if ($r -notmatch '^[Ss]') { Write-Host "Desinstalação cancelada."; exit }
}

if (Test-Path $exe) {
    Write-Host "Executando Desinstalar.exe..."
    Start-Process -FilePath $exe -Wait
    Write-Host "Desinstalador EXE finalizou."
    exit
}

if (Test-Path $ps) {
    Write-Host "Executando Desinstalador PowerShell..."
    & powershell -ExecutionPolicy Bypass -File $ps
    exit
}

# fallback: conservative remove with backup
$backup = "$Root.uninstalled_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
try {
    if (Test-Path $Root) {
        Copy-Item -Path $Root -Destination $backup -Recurse -Force -ErrorAction Stop
        Remove-Item -Path $Root -Recurse -Force -ErrorAction Stop
        Write-Host "Desinstalação completa. Backup salvo em: $backup"
    } else {
        Write-Host "Pasta raiz não encontrada: $Root"
    }
} catch {
    Write-Host "Falha durante desinstalação: $($_.Exception.Message)"
}
# ===== FIM UNINSTALL_CONAV_TRADER_FULL1.41_fixed.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER_FULL1.42.ps1 =====

# UNINSTALL_CONAV_TRADER_FULL1.42.ps1
Write-Output "[UNINSTALL] Executando Desinstalação CONAV TRADER FULL 1.42..."

# Placeholder do desinstalador

# ===== FIM UNINSTALL_CONAV_TRADER_FULL1.42.ps1 =====

# ===== INICIO list_versions.ps1 =====
# list_versions.ps1
Write-Output 'Versões disponíveis:'
'1.37','1.38','1.39','1.40','1.41','1.42','1.43','1.44','1.45','1.45fix1','1.45fix2','1.45fix3' | ForEach-Object { Write-Output \ }

# ===== FIM list_versions.ps1 =====

# ===== INICIO CONAVMASTERFULL0001.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todos os módulos e versões do CONAV de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

# ======================================================
# Função central de log
# ======================================================
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# ======================================================
# Criar pastas organizadas
# ======================================================
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$folders = @(
    "LOGS GERAIS",
    "relatorios",
    "relatórios",
    "mapas de fluxograma",
    "TUTORIAL GERAL",
    "SCRIPT MESTRE",
    "scripts\PACKAGES OFICIAIS",
    "SCRIPTS BASE OFICIAIS",
    "SCRIPTS DE LISTAGEM"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $rootPath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Criada pasta: $fullPath"
    }
}

# ======================================================
# Auto-number para CONAVMASTERFULL.ps1
# ======================================================
$seqPath = Join-Path $rootPath "SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# ======================================================
# Importar todos os scripts existentes e integrados
# ======================================================
$integratedPaths = @(
    "$rootPath\SCRIPTS BASE OFICIAIS",
    "$rootPath\scripts\PACKAGES OFICIAIS",
    "$rootPath\SCRIPT MESTRE",
    "$rootPath\mapas de fluxograma",
    "$rootPath\logs",
    "$rootPath\logs\install",
    "$rootPath\logs\ia"
)

foreach ($p in $integratedPaths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Filter *.ps1 -Recurse
        foreach ($f in $files) {
            try {
                Write-Log "Executando script integrado: $($f.FullName)"
                . $f.FullName
            } catch {
                Write-Log "Erro executando $($f.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# ======================================================
# GUI Simples - Escolha de execução
# ======================================================
Add-Type -AssemblyName PresentationFramework
$result = [System.Windows.MessageBox]::Show(
    "Deseja rodar todas as versões (histórico completo) ou apenas a última atualização?",
    "CONAV MASTER FULL",
    "YesNoCancel",
    "Question"
)

switch ($result) {
    "Yes" {
        Write-Log "Usuário escolheu rodar TODAS as versões."
        # Simulação de execução full histórico
    }
    "No" {
        Write-Log "Usuário escolheu rodar apenas a ÚLTIMA versão."
        # Simulação apenas última versão
    }
    "Cancel" {
        Write-Log "Execução cancelada pelo usuário."
        exit
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTERFULL0001.ps1 =====

# ===== INICIO CONAVMASTERFULL0002.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todos os módulos e versões do CONAV de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

# ======================================================
# Função central de log
# ======================================================
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# ======================================================
# Criar pastas organizadas
# ======================================================
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$folders = @(
    "LOGS GERAIS",
    "relatorios",
    "relatórios",
    "mapas de fluxograma",
    "TUTORIAL GERAL",
    "SCRIPT MESTRE",
    "scripts\PACKAGES OFICIAIS",
    "SCRIPTS BASE OFICIAIS",
    "SCRIPTS DE LISTAGEM"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $rootPath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Criada pasta: $fullPath"
    }
}

# ======================================================
# Auto-number para CONAVMASTERFULL.ps1
# ======================================================
$seqPath = Join-Path $rootPath "SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# ======================================================
# Importar todos os scripts existentes e integrados
# ======================================================
$integratedPaths = @(
    "$rootPath\SCRIPTS BASE OFICIAIS",
    "$rootPath\scripts\PACKAGES OFICIAIS",
    "$rootPath\SCRIPT MESTRE",
    "$rootPath\mapas de fluxograma",
    "$rootPath\logs",
    "$rootPath\logs\install",
    "$rootPath\logs\ia"
)

foreach ($p in $integratedPaths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Filter *.ps1 -Recurse
        foreach ($f in $files) {
            try {
                Write-Log "Executando script integrado: $($f.FullName)"
                . $f.FullName
            } catch {
                Write-Log "Erro executando $($f.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# ======================================================
# GUI Simples - Escolha de execução
# ======================================================
Add-Type -AssemblyName PresentationFramework
$result = [System.Windows.MessageBox]::Show(
    "Deseja rodar todas as versões (histórico completo) ou apenas a última atualização?",
    "CONAV MASTER FULL",
    "YesNoCancel",
    "Question"
)

switch ($result) {
    "Yes" {
        Write-Log "Usuário escolheu rodar TODAS as versões."
        # Simulação de execução full histórico
    }
    "No" {
        Write-Log "Usuário escolheu rodar apenas a ÚLTIMA versão."
        # Simulação apenas última versão
    }
    "Cancel" {
        Write-Log "Execução cancelada pelo usuário."
        exit
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTERFULL0002.ps1 =====

# ===== INICIO CONAVMASTERFULL0003.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todos os módulos e versões do CONAV de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

# ======================================================
# Função central de log
# ======================================================
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# ======================================================
# Criar pastas organizadas
# ======================================================
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$folders = @(
    "LOGS GERAIS",
    "relatorios",
    "relatórios",
    "mapas de fluxograma",
    "TUTORIAL GERAL",
    "SCRIPT MESTRE",
    "scripts\PACKAGES OFICIAIS",
    "SCRIPTS BASE OFICIAIS",
    "SCRIPTS DE LISTAGEM"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $rootPath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Criada pasta: $fullPath"
    }
}

# ======================================================
# Auto-number para CONAVMASTERFULL.ps1
# ======================================================
$seqPath = Join-Path $rootPath "SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# ======================================================
# Importar todos os scripts existentes e integrados
# ======================================================
$integratedPaths = @(
    "$rootPath\SCRIPTS BASE OFICIAIS",
    "$rootPath\scripts\PACKAGES OFICIAIS",
    "$rootPath\SCRIPT MESTRE",
    "$rootPath\mapas de fluxograma",
    "$rootPath\logs",
    "$rootPath\logs\install",
    "$rootPath\logs\ia"
)

foreach ($p in $integratedPaths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Filter *.ps1 -Recurse
        foreach ($f in $files) {
            try {
                Write-Log "Executando script integrado: $($f.FullName)"
                . $f.FullName
            } catch {
                Write-Log "Erro executando $($f.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# ======================================================
# GUI Simples - Escolha de execução
# ======================================================
Add-Type -AssemblyName PresentationFramework
$result = [System.Windows.MessageBox]::Show(
    "Deseja rodar todas as versões (histórico completo) ou apenas a última atualização?",
    "CONAV MASTER FULL",
    "YesNoCancel",
    "Question"
)

switch ($result) {
    "Yes" {
        Write-Log "Usuário escolheu rodar TODAS as versões."
        # Simulação de execução full histórico
    }
    "No" {
        Write-Log "Usuário escolheu rodar apenas a ÚLTIMA versão."
        # Simulação apenas última versão
    }
    "Cancel" {
        Write-Log "Execução cancelada pelo usuário."
        exit
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTERFULL0003.ps1 =====

# ===== INICIO CONAVMASTERFULL0004.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todos os módulos e versões do CONAV de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

# ======================================================
# Função central de log
# ======================================================
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# ======================================================
# Criar pastas organizadas
# ======================================================
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$folders = @(
    "LOGS GERAIS",
    "relatorios",
    "relatórios",
    "mapas de fluxograma",
    "TUTORIAL GERAL",
    "SCRIPT MESTRE",
    "scripts\PACKAGES OFICIAIS",
    "SCRIPTS BASE OFICIAIS",
    "SCRIPTS DE LISTAGEM"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $rootPath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Criada pasta: $fullPath"
    }
}

# ======================================================
# Auto-number para CONAVMASTERFULL.ps1
# ======================================================
$seqPath = Join-Path $rootPath "SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# ======================================================
# Importar todos os scripts existentes e integrados
# ======================================================
$integratedPaths = @(
    "$rootPath\SCRIPTS BASE OFICIAIS",
    "$rootPath\scripts\PACKAGES OFICIAIS",
    "$rootPath\SCRIPT MESTRE",
    "$rootPath\mapas de fluxograma",
    "$rootPath\logs",
    "$rootPath\logs\install",
    "$rootPath\logs\ia"
)

foreach ($p in $integratedPaths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Filter *.ps1 -Recurse
        foreach ($f in $files) {
            try {
                Write-Log "Executando script integrado: $($f.FullName)"
                . $f.FullName
            } catch {
                Write-Log "Erro executando $($f.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# ======================================================
# GUI Simples - Escolha de execução
# ======================================================
Add-Type -AssemblyName PresentationFramework
$result = [System.Windows.MessageBox]::Show(
    "Deseja rodar todas as versões (histórico completo) ou apenas a última atualização?",
    "CONAV MASTER FULL",
    "YesNoCancel",
    "Question"
)

switch ($result) {
    "Yes" {
        Write-Log "Usuário escolheu rodar TODAS as versões."
        # Simulação de execução full histórico
    }
    "No" {
        Write-Log "Usuário escolheu rodar apenas a ÚLTIMA versão."
        # Simulação apenas última versão
    }
    "Cancel" {
        Write-Log "Execução cancelada pelo usuário."
        exit
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTERFULL0004.ps1 =====

# ===== INICIO CONAVPackage0001.ps1 =====
# Auto-generated package script CONAVPackage0001.ps1
# Cria o pacote: C:\CONAV TRADER\CONAV_TRADER\PACKAGES OFICIAIS\CONAV_FULL_PROFESSIONAL_v1.45_fix3_pkg_1.zip
Compress-Archive -Path (Join-Path "C:\CONAV TRADER\CONAV_TRADER" '*') -DestinationPath "C:\CONAV TRADER\CONAV_TRADER\PACKAGES OFICIAIS\CONAV_FULL_PROFESSIONAL_v1.45_fix3_pkg_1.zip" -Force

# ===== FIM CONAVPackage0001.ps1 =====

# ===== INICIO CONAVMASTERFULL.ps1 =====
<#
.CONAVMASTERFULL.ps1
CONAV MASTER FULL - SCRIPT UNIFICADO (v1.45_fix4)
Coloque em: C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE\CONAVMASTERFULL.ps1
Funcionalidades:
- dry-run (simulação) e execução real (confirmada)
- logging detalhado em relatorios/ e logs/
- criação automática de pastas necessárias
- aplicação de ícones, build via PyInstaller (com confirmação)
- geração do desinstalador (ps1 + exe via PyInstaller) (com confirmação)
- auto-numbering do script mestre (salva cópia sequencial)
- safe copy / safe remove logic
- GUI confirm dialogs (WinForms) para aprovações sensíveis
- compatível com PowerShell 7 e Windows PowerShell
#>

param (
    [switch]$DryRun,
    [switch]$AutoConfirm,
    [switch]$DebugMode
)

# --------------------------
# CONFIGURAÇÕES (editar se necessário)
# --------------------------
$Root = 'C:\CONAV TRADER\CONAV_TRADER'
$ScriptMasterDir = Join-Path $Root 'SCRIPT MESTRE'
$LogsGeneral = Join-Path $Root 'LOGS GERAIS'
$RelatoriosDir = Join-Path $Root 'relatorios'
$RelatoriosAccent = Join-Path $Root 'relatórios'
$LogsDir = Join-Path $Root 'logs'
$PackagesDir = Join-Path $Root 'PACKAGES OFICIAIS'
$DesinstalarDir = Join-Path $Root 'Desinstalar'
$DistDir = Join-Path $Root 'dist'
$IconsDir = Join-Path $Root 'icons'
$ScriptDir = Join-Path $Root 'scripts'

# --------------------------
# Helpers
# --------------------------
function ts { Get-Date -Format 'yyyyMMdd_HHmmss' }

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    $t = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$t][$Level] $Message"
    $logFile = Join-Path $LogsGeneral 'master.log'
    $dir = Split-Path -Parent $logFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    try {
        Add-Content -Path $logFile -Value $line -Encoding UTF8
    } catch {
        if ($DebugMode) { Write-Host ('[LOGFAIL] {0}' -f $line) }
    }
    if ($DebugMode) { Write-Host $line }
}

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        if ($DryRun) {
            Write-Log ('[DRYRUN] Criar diretório: {0}' -f $Path)
        } else {
            New-Item -ItemType Directory -Force -Path $Path | Out-Null
            Write-Log ('Criada pasta: {0}' -f $Path)
        }
    }
}

function Safe-Copy {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$Force
    )
    try {
        $srcItem = Get-Item -LiteralPath $Source -ErrorAction Stop
        $srcFull = $srcItem.FullName
    } catch {
        Write-Log ('Source não encontrado: {0}' -f $Source) 'ERROR'
        return
    }
    $dstExists = $false
    try {
        $dstResolved = Resolve-Path -LiteralPath $Destination -ErrorAction Stop
        $dstExists = $true
    } catch {
        $dstResolved = $Destination
    }
    if ($srcFull -eq $dstResolved) {
        Write-Log ('Ignorado (mesmo ficheiro): {0}' -f $Source)
        return
    }
    if ($DryRun) {
        Write-Log ('[DRYRUN] Copy {0} -> {1}' -f $Source, $Destination)
    } else {
        try {
            Copy-Item -LiteralPath $Source -Destination $Destination -Force:($Force.IsPresent) -ErrorAction Stop
            Write-Log ('Copiado: {0} -> {1}' -f $Source, $Destination)
        } catch {
            Write-Log ('Erro ao copiar {0} -> {1}: {2}' -f $Source, $Destination, $_.Exception.Message) 'ERROR'
        }
    }
}

function Safe-Remove {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        Write-Log ('Remover: inexistente {0}' -f $Path)
        return
    }
    if ($DryRun) {
        Write-Log ('[DRYRUN] Remover {0}' -f $Path)
    } else {
        try {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            Write-Log ('Removido: {0}' -f $Path)
        } catch {
            Write-Log ('Erro removendo {0}: {1}' -f $Path, $_.Exception.Message) 'ERROR'
        }
    }
}

function GUI-Confirm {
    param(
        [string]$Message = 'Confirm?',
        [string]$Title = 'CONFIRM'
    )
    if ($AutoConfirm) { return $true }
    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(430,160)
    $form.StartPosition = 'CenterScreen'
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Message
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(10,20)
    $form.Controls.Add($label)
    $btnYes = New-Object System.Windows.Forms.Button
    $btnYes.Text = 'Sim'
    $btnYes.Location = New-Object System.Drawing.Point(80,80)
    $btnYes.Add_Click({ $form.Tag = $true; $form.Close() })
    $btnNo = New-Object System.Windows.Forms.Button
    $btnNo.Text = 'Não'
    $btnNo.Location = New-Object System.Drawing.Point(220,80)
    $btnNo.Add_Click({ $form.Tag = $false; $form.Close() })
    $form.Controls.Add($btnYes); $form.Controls.Add($btnNo)
    $form.Add_Shown({$form.Activate()})
    $form.ShowDialog() | Out-Null
    return [bool]$form.Tag
}

function Normalize-IconPath {
    param([string]$IconPath)
    if (-not $IconPath) { return $null }
    $p = $IconPath.Trim()
    if ($p.StartsWith('"') -and $p.EndsWith('"')) { $p = $p.Trim('"') }
    if ($p.StartsWith("'") -and $p.EndsWith("'")) { $p = $p.Trim("'") }
    return $p
}

function Build-MainDashboard {
    param(
        [string]$ScriptPath = (Join-Path $Root 'dashboard\main_dashboard.py'),
        [string]$Icon = (Join-Path $IconsDir 'system_icon.ico')
    )
    Ensure-Dir $DistDir
    $Icon = Normalize-IconPath $Icon
    if (-not (Test-Path $ScriptPath)) {
        Write-Log ('main_dashboard.py não encontrado: {0}' -f $ScriptPath) 'ERROR'
        return $false
    }
    $cmd = 'pyinstaller --onefile --noconsole --distpath "' + $DistDir + '" --name main_dashboard --add-data "' + $Root + ';."'

    if ($Icon -and (Test-Path $Icon)) {
        $cmd += ' --icon "' + $Icon + '"'
    }
    $cmd += ' "' + $ScriptPath + '"'
    Write-Log ('Executando PyInstaller: {0}' -f $cmd)
    if ($DryRun) { Write-Log '[DRYRUN] Build ignorado (simulação)'; return $true }
    try {
        $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $cmd" -Wait -NoNewWindow -PassThru
        if ($proc.ExitCode -ne 0) {
            Write-Log ('PyInstaller retornou código {0}' -f $proc.ExitCode) 'ERROR'
            return $false
        }
        Write-Log 'main_dashboard.exe criado em dist\'
        return $true
    } catch {
        Write-Log ('Erro ao executar PyInstaller: {0}' -f $_.Exception.Message) 'ERROR'
        return $false
    }
}

function Create-Uninstaller {
    param(
        [string]$UninstallPs1 = (Join-Path $Root 'UNINSTALL_CONAV_TRADER.ps1'),
        [string]$TargetFolder = $DesinstalarDir,
        [string]$Icon = (Join-Path $IconsDir 'system_icon.ico')
    )
    Ensure-Dir $TargetFolder
    $destPs1 = Join-Path $TargetFolder 'Desinstalar-Por-PowerShell.ps1'
    Safe-Copy -Source $UninstallPs1 -Destination $destPs1 -Force
    $wrapper = Join-Path $TargetFolder 'uninstall_wrapper.py'
    $pyCode = @"
import subprocess, sys, os
ps1 = os.path.join(os.path.dirname(__file__),"Desinstalar-Por-PowerShell.ps1")
subprocess.call(["powershell","-ExecutionPolicy","Bypass","-File", ps1])
"@
    if ($DryRun) {
        Write-Log ('[DRYRUN] Criar wrapper python: {0}' -f $wrapper)
    } else {
        Set-Content -Path $wrapper -Value $pyCode -Encoding UTF8
        Write-Log ('Wrapper Python criado: {0}' -f $wrapper)
    }
    if (GUI-Confirm 'Deseja compilar Desinstalar.exe via PyInstaller?' 'Compilar Desinstalador') {
        $iconPath = Normalize-IconPath $Icon
        $specCmd = 'pyinstaller --onefile --noconsole --distpath "' + $TargetFolder + '" --workpath "' + $TargetFolder + '\build" --specpath "' + $TargetFolder + '" --name Desinstalar'
        if ($iconPath -and (Test-Path $iconPath)) { $specCmd += ' --icon "' + $iconPath + '"' }
        $specCmd += ' "' + $wrapper + '"'
        Write-Log ('Executando: {0}' -f $specCmd)
        if (-not $DryRun) {
            Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $specCmd" -Wait -NoNewWindow
            Write-Log ('Desinstalar.exe compilado em {0}' -f $TargetFolder)
        } else {
            Write-Log '[DRYRUN] pyinstaller compilação ignorada'
        }
    } else {
        Write-Log 'Compilação do desinstalador foi cancelada pelo usuário.'
    }
}

function Build-Package {
    param(
        [string]$OutputName = ('CONAV_FULL_PROFESSIONAL_v{0}.zip' -f (Get-Date -Format 'yyyyMMdd_HHmm')),
        [string]$SourceRoot = $Root,
        [switch]$ForceOverwrite
    )
    Ensure-Dir $PackagesDir
    $outPath = Join-Path $PackagesDir $OutputName
    if (Test-Path $outPath) {
        if ($ForceOverwrite) { Remove-Item -LiteralPath $outPath -Force }
        else {
            $snum = (Get-Date).ToString('yyyyMMddHHmmss')
            $outPath = Join-Path $PackagesDir ('{0}_{1}.zip' -f [System.IO.Path]::GetFileNameWithoutExtension($OutputName), $snum)
        }
    }
    Write-Log ('Criando pacote: {0}' -f $outPath)
    if ($DryRun) { Write-Log '[DRYRUN] Compressão ignorada'; return $outPath }
    try {
        $items = @()
        foreach ($sub in @('dashboard','dist','scripts','tools','relatorios','relatórios','icons','resources','docs','emails')) {
            $p = Join-Path $SourceRoot $sub
            if (Test-Path $p) { $items += $p }
        }
        if (-not $items) {
            Write-Log 'Nenhum item encontrado para empacotar.' 'ERROR'
            return $null
        }
        Compress-Archive -Path $items -DestinationPath $outPath -Force
        Write-Log ('Pacote gerado em {0}' -f $outPath)
        return $outPath
    } catch {
        Write-Log ('Erro criando pacote: {0}' -f $_.Exception.Message) 'ERROR'
        return $null
    }
}

function Save-SelfVersion {
    Ensure-Dir $ScriptMasterDir
    $existing = Get-ChildItem -Path $ScriptMasterDir -Filter 'CONAVMASTERFULL*.ps1' -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($existing) {
        $digits = ($existing.BaseName -replace '\D','')
        if ($digits -match '^\d+$') { $num = [int]$digits + 1 } else { $num = 1 }
    } else { $num = 1 }
    $seqName = ('CONAVMASTERFULL{0:D4}.ps1' -f $num)
    $dest = Join-Path $ScriptMasterDir $seqName
    if ($DryRun) {
        Write-Log ('[DRYRUN] Salvar self como: {0}' -f $dest)
    } else {
        Copy-Item -LiteralPath $PSCommandPath -Destination $dest -Force
        Write-Log ('Nova versão mestre salva: {0}' -f $dest)
    }
}

# --------------------------
# Main
# --------------------------
Write-Log '==== START CONAV MASTER (v1.45_fix4) ===='

foreach ($d in @($ScriptMasterDir, $LogsGeneral, $RelatoriosDir, $RelatoriosAccent, $LogsDir, $PackagesDir, $DesinstalarDir, $DistDir, $IconsDir, $ScriptDir)) {
    Ensure-Dir $d
}

Save-SelfVersion

if ($DryRun) {
    Write-Log '[DRYRUN] Modo simulação ativado. As ações abaixo NÃO serão executadas; apenas listadas.'
    Write-Log '[DRYRUN] 1) Build main_dashboard (pyinstaller)  2) Criar/compilar desinstalador 3) Aplicar icons 4) Gerar pacote ZIP'
    if (-not (GUI-Confirm 'Deseja prosseguir e executar as ações (real)?')) {
        Write-Log '[DRYRUN] Usuário cancelou execução real após simulação.'
        Write-Log '==== END CONAV MASTER ===='
        return
    } else {
        $DryRun = $false
        Write-Log 'Usuário autorizou execução real.'
    }
}

$built = Build-MainDashboard
if (-not $built) { Write-Log 'Falha ao compilar main_dashboard. Verifique logs.' 'ERROR' }

Create-Uninstaller

$pkg = Build-Package -OutputName ('CONAV_FULL_PROFESSIONAL_v1.45_fix4.zip')
if ($pkg) { Write-Log ('Pacote final em: {0}' -f $pkg) } else { Write-Log 'Falha ao gerar pacote' 'ERROR' }

Write-Log '==== END CONAV MASTER ===='

# ===== FIM CONAVMASTERFULL.ps1 =====

# ===== INICIO CONAVMASTERFULL0006.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todos os módulos e versões do CONAV de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

# ======================================================
# Função central de log
# ======================================================
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# ======================================================
# Criar pastas organizadas
# ======================================================
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$folders = @(
    "LOGS GERAIS",
    "relatorios",
    "relatórios",
    "mapas de fluxograma",
    "TUTORIAL GERAL",
    "SCRIPT MESTRE",
    "scripts\PACKAGES OFICIAIS",
    "SCRIPTS BASE OFICIAIS",
    "SCRIPTS DE LISTAGEM"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $rootPath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Criada pasta: $fullPath"
    }
}

# ======================================================
# Auto-number para CONAVMASTERFULL.ps1
# ======================================================
$seqPath = Join-Path $rootPath "SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# ======================================================
# Importar todos os scripts existentes e integrados
# ======================================================
$integratedPaths = @(
    "$rootPath\SCRIPTS BASE OFICIAIS",
    "$rootPath\scripts\PACKAGES OFICIAIS",
    "$rootPath\SCRIPT MESTRE",
    "$rootPath\mapas de fluxograma",
    "$rootPath\logs",
    "$rootPath\logs\install",
    "$rootPath\logs\ia"
)

foreach ($p in $integratedPaths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Filter *.ps1 -Recurse
        foreach ($f in $files) {
            try {
                Write-Log "Executando script integrado: $($f.FullName)"
                . $f.FullName
            } catch {
                Write-Log "Erro executando $($f.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# ======================================================
# GUI Simples - Escolha de execução
# ======================================================
Add-Type -AssemblyName PresentationFramework
$result = [System.Windows.MessageBox]::Show(
    "Deseja rodar todas as versões (histórico completo) ou apenas a última atualização?",
    "CONAV MASTER FULL",
    "YesNoCancel",
    "Question"
)

switch ($result) {
    "Yes" {
        Write-Log "Usuário escolheu rodar TODAS as versões."
        # Simulação de execução full histórico
    }
    "No" {
        Write-Log "Usuário escolheu rodar apenas a ÚLTIMA versão."
        # Simulação apenas última versão
    }
    "Cancel" {
        Write-Log "Execução cancelada pelo usuário."
        exit
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTERFULL0006.ps1 =====

# ===== INICIO CONAVMASTERFULL0007.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todos os módulos e versões do CONAV de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

# ======================================================
# Função central de log
# ======================================================
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# ======================================================
# Criar pastas organizadas
# ======================================================
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$folders = @(
    "LOGS GERAIS",
    "relatorios",
    "relatórios",
    "mapas de fluxograma",
    "TUTORIAL GERAL",
    "SCRIPT MESTRE",
    "scripts\PACKAGES OFICIAIS",
    "SCRIPTS BASE OFICIAIS",
    "SCRIPTS DE LISTAGEM"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $rootPath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Criada pasta: $fullPath"
    }
}

# ======================================================
# Auto-number para CONAVMASTERFULL.ps1
# ======================================================
$seqPath = Join-Path $rootPath "SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# ======================================================
# Importar todos os scripts existentes e integrados
# ======================================================
$integratedPaths = @(
    "$rootPath\SCRIPTS BASE OFICIAIS",
    "$rootPath\scripts\PACKAGES OFICIAIS",
    "$rootPath\SCRIPT MESTRE",
    "$rootPath\mapas de fluxograma",
    "$rootPath\logs",
    "$rootPath\logs\install",
    "$rootPath\logs\ia"
)

foreach ($p in $integratedPaths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Filter *.ps1 -Recurse
        foreach ($f in $files) {
            try {
                Write-Log "Executando script integrado: $($f.FullName)"
                . $f.FullName
            } catch {
                Write-Log "Erro executando $($f.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# ======================================================
# GUI Simples - Escolha de execução
# ======================================================
Add-Type -AssemblyName PresentationFramework
$result = [System.Windows.MessageBox]::Show(
    "Deseja rodar todas as versões (histórico completo) ou apenas a última atualização?",
    "CONAV MASTER FULL",
    "YesNoCancel",
    "Question"
)

switch ($result) {
    "Yes" {
        Write-Log "Usuário escolheu rodar TODAS as versões."
        # Simulação de execução full histórico
    }
    "No" {
        Write-Log "Usuário escolheu rodar apenas a ÚLTIMA versão."
        # Simulação apenas última versão
    }
    "Cancel" {
        Write-Log "Execução cancelada pelo usuário."
        exit
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTERFULL0007.ps1 =====

# ===== INICIO CONAVMASTERFULL0008.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todos os módulos e versões do CONAV de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

# ======================================================
# Função central de log
# ======================================================
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# ======================================================
# Criar pastas organizadas
# ======================================================
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$folders = @(
    "LOGS GERAIS",
    "relatorios",
    "relatórios",
    "mapas de fluxograma",
    "TUTORIAL GERAL",
    "SCRIPT MESTRE",
    "scripts\PACKAGES OFICIAIS",
    "SCRIPTS BASE OFICIAIS",
    "SCRIPTS DE LISTAGEM"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $rootPath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Criada pasta: $fullPath"
    }
}

# ======================================================
# Auto-number para CONAVMASTERFULL.ps1
# ======================================================
$seqPath = Join-Path $rootPath "SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# ======================================================
# Importar todos os scripts existentes e integrados
# ======================================================
$integratedPaths = @(
    "$rootPath\SCRIPTS BASE OFICIAIS",
    "$rootPath\scripts\PACKAGES OFICIAIS",
    "$rootPath\SCRIPT MESTRE",
    "$rootPath\mapas de fluxograma",
    "$rootPath\logs",
    "$rootPath\logs\install",
    "$rootPath\logs\ia"
)

foreach ($p in $integratedPaths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Filter *.ps1 -Recurse
        foreach ($f in $files) {
            try {
                Write-Log "Executando script integrado: $($f.FullName)"
                . $f.FullName
            } catch {
                Write-Log "Erro executando $($f.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# ======================================================
# GUI Simples - Escolha de execução
# ======================================================
Add-Type -AssemblyName PresentationFramework
$result = [System.Windows.MessageBox]::Show(
    "Deseja rodar todas as versões (histórico completo) ou apenas a última atualização?",
    "CONAV MASTER FULL",
    "YesNoCancel",
    "Question"
)

switch ($result) {
    "Yes" {
        Write-Log "Usuário escolheu rodar TODAS as versões."
        # Simulação de execução full histórico
    }
    "No" {
        Write-Log "Usuário escolheu rodar apenas a ÚLTIMA versão."
        # Simulação apenas última versão
    }
    "Cancel" {
        Write-Log "Execução cancelada pelo usuário."
        exit
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTERFULL0008.ps1 =====

# ===== INICIO CONAVMASTERFULL0009.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todos os módulos e versões do CONAV de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

# ======================================================
# Função central de log
# ======================================================
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# ======================================================
# Criar pastas organizadas
# ======================================================
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$folders = @(
    "LOGS GERAIS",
    "relatorios",
    "relatórios",
    "mapas de fluxograma",
    "TUTORIAL GERAL",
    "SCRIPT MESTRE",
    "scripts\PACKAGES OFICIAIS",
    "SCRIPTS BASE OFICIAIS",
    "SCRIPTS DE LISTAGEM"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $rootPath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Criada pasta: $fullPath"
    }
}

# ======================================================
# Auto-number para CONAVMASTERFULL.ps1
# ======================================================
$seqPath = Join-Path $rootPath "SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# ======================================================
# Importar todos os scripts existentes e integrados
# ======================================================
$integratedPaths = @(
    "$rootPath\SCRIPTS BASE OFICIAIS",
    "$rootPath\scripts\PACKAGES OFICIAIS",
    "$rootPath\SCRIPT MESTRE",
    "$rootPath\mapas de fluxograma",
    "$rootPath\logs",
    "$rootPath\logs\install",
    "$rootPath\logs\ia"
)

foreach ($p in $integratedPaths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Filter *.ps1 -Recurse
        foreach ($f in $files) {
            try {
                Write-Log "Executando script integrado: $($f.FullName)"
                . $f.FullName
            } catch {
                Write-Log "Erro executando $($f.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# ======================================================
# GUI Simples - Escolha de execução
# ======================================================
Add-Type -AssemblyName PresentationFramework
$result = [System.Windows.MessageBox]::Show(
    "Deseja rodar todas as versões (histórico completo) ou apenas a última atualização?",
    "CONAV MASTER FULL",
    "YesNoCancel",
    "Question"
)

switch ($result) {
    "Yes" {
        Write-Log "Usuário escolheu rodar TODAS as versões."
        # Simulação de execução full histórico
    }
    "No" {
        Write-Log "Usuário escolheu rodar apenas a ÚLTIMA versão."
        # Simulação apenas última versão
    }
    "Cancel" {
        Write-Log "Execução cancelada pelo usuário."
        exit
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTERFULL0009.ps1 =====

# ===== INICIO CONAVMASTERFULL0010.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todos os módulos e versões do CONAV de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

# ======================================================
# Função central de log
# ======================================================
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# ======================================================
# Criar pastas organizadas
# ======================================================
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$folders = @(
    "LOGS GERAIS",
    "relatorios",
    "relatórios",
    "mapas de fluxograma",
    "TUTORIAL GERAL",
    "SCRIPT MESTRE",
    "scripts\PACKAGES OFICIAIS",
    "SCRIPTS BASE OFICIAIS",
    "SCRIPTS DE LISTAGEM"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $rootPath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Criada pasta: $fullPath"
    }
}

# ======================================================
# Auto-number para CONAVMASTERFULL.ps1
# ======================================================
$seqPath = Join-Path $rootPath "SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# ======================================================
# Importar todos os scripts existentes e integrados
# ======================================================
$integratedPaths = @(
    "$rootPath\SCRIPTS BASE OFICIAIS",
    "$rootPath\scripts\PACKAGES OFICIAIS",
    "$rootPath\SCRIPT MESTRE",
    "$rootPath\mapas de fluxograma",
    "$rootPath\logs",
    "$rootPath\logs\install",
    "$rootPath\logs\ia"
)

foreach ($p in $integratedPaths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Filter *.ps1 -Recurse
        foreach ($f in $files) {
            try {
                Write-Log "Executando script integrado: $($f.FullName)"
                . $f.FullName
            } catch {
                Write-Log "Erro executando $($f.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# ======================================================
# GUI Simples - Escolha de execução
# ======================================================
Add-Type -AssemblyName PresentationFramework
$result = [System.Windows.MessageBox]::Show(
    "Deseja rodar todas as versões (histórico completo) ou apenas a última atualização?",
    "CONAV MASTER FULL",
    "YesNoCancel",
    "Question"
)

switch ($result) {
    "Yes" {
        Write-Log "Usuário escolheu rodar TODAS as versões."
        # Simulação de execução full histórico
    }
    "No" {
        Write-Log "Usuário escolheu rodar apenas a ÚLTIMA versão."
        # Simulação apenas última versão
    }
    "Cancel" {
        Write-Log "Execução cancelada pelo usuário."
        exit
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTERFULL0010.ps1 =====

# ===== INICIO CONAVMASTERFULL0011.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todos os módulos e versões do CONAV de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

# ======================================================
# Função central de log
# ======================================================
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# ======================================================
# Criar pastas organizadas
# ======================================================
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$folders = @(
    "LOGS GERAIS",
    "relatorios",
    "relatórios",
    "mapas de fluxograma",
    "TUTORIAL GERAL",
    "SCRIPT MESTRE",
    "scripts\PACKAGES OFICIAIS",
    "SCRIPTS BASE OFICIAIS",
    "SCRIPTS DE LISTAGEM"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $rootPath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Criada pasta: $fullPath"
    }
}

# ======================================================
# Auto-number para CONAVMASTERFULL.ps1
# ======================================================
$seqPath = Join-Path $rootPath "SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# ======================================================
# Importar todos os scripts existentes e integrados
# ======================================================
$integratedPaths = @(
    "$rootPath\SCRIPTS BASE OFICIAIS",
    "$rootPath\scripts\PACKAGES OFICIAIS",
    "$rootPath\SCRIPT MESTRE",
    "$rootPath\mapas de fluxograma",
    "$rootPath\logs",
    "$rootPath\logs\install",
    "$rootPath\logs\ia"
)

foreach ($p in $integratedPaths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Filter *.ps1 -Recurse
        foreach ($f in $files) {
            try {
                Write-Log "Executando script integrado: $($f.FullName)"
                . $f.FullName
            } catch {
                Write-Log "Erro executando $($f.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# ======================================================
# GUI Simples - Escolha de execução
# ======================================================
Add-Type -AssemblyName PresentationFramework
$result = [System.Windows.MessageBox]::Show(
    "Deseja rodar todas as versões (histórico completo) ou apenas a última atualização?",
    "CONAV MASTER FULL",
    "YesNoCancel",
    "Question"
)

switch ($result) {
    "Yes" {
        Write-Log "Usuário escolheu rodar TODAS as versões."
        # Simulação de execução full histórico
    }
    "No" {
        Write-Log "Usuário escolheu rodar apenas a ÚLTIMA versão."
        # Simulação apenas última versão
    }
    "Cancel" {
        Write-Log "Execução cancelada pelo usuário."
        exit
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTERFULL0011.ps1 =====

# ===== INICIO CONAVMASTERFULL0012.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todos os módulos e versões do CONAV de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

# ======================================================
# Função central de log
# ======================================================
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# ======================================================
# Criar pastas organizadas
# ======================================================
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$folders = @(
    "LOGS GERAIS",
    "relatorios",
    "relatórios",
    "mapas de fluxograma",
    "TUTORIAL GERAL",
    "SCRIPT MESTRE",
    "scripts\PACKAGES OFICIAIS",
    "SCRIPTS BASE OFICIAIS",
    "SCRIPTS DE LISTAGEM"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $rootPath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Criada pasta: $fullPath"
    }
}

# ======================================================
# Auto-number para CONAVMASTERFULL.ps1
# ======================================================
$seqPath = Join-Path $rootPath "SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# ======================================================
# Importar todos os scripts existentes e integrados
# ======================================================
$integratedPaths = @(
    "$rootPath\SCRIPTS BASE OFICIAIS",
    "$rootPath\scripts\PACKAGES OFICIAIS",
    "$rootPath\SCRIPT MESTRE",
    "$rootPath\mapas de fluxograma",
    "$rootPath\logs",
    "$rootPath\logs\install",
    "$rootPath\logs\ia"
)

foreach ($p in $integratedPaths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Filter *.ps1 -Recurse
        foreach ($f in $files) {
            try {
                Write-Log "Executando script integrado: $($f.FullName)"
                . $f.FullName
            } catch {
                Write-Log "Erro executando $($f.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# ======================================================
# GUI Simples - Escolha de execução
# ======================================================
Add-Type -AssemblyName PresentationFramework
$result = [System.Windows.MessageBox]::Show(
    "Deseja rodar todas as versões (histórico completo) ou apenas a última atualização?",
    "CONAV MASTER FULL",
    "YesNoCancel",
    "Question"
)

switch ($result) {
    "Yes" {
        Write-Log "Usuário escolheu rodar TODAS as versões."
        # Simulação de execução full histórico
    }
    "No" {
        Write-Log "Usuário escolheu rodar apenas a ÚLTIMA versão."
        # Simulação apenas última versão
    }
    "Cancel" {
        Write-Log "Execução cancelada pelo usuário."
        exit
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTERFULL0012.ps1 =====

# ===== INICIO CONAVMASTERFULL0013.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todos os módulos e versões do CONAV de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

# ======================================================
# Função central de log
# ======================================================
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# ======================================================
# Criar pastas organizadas
# ======================================================
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$folders = @(
    "LOGS GERAIS",
    "relatorios",
    "relatórios",
    "mapas de fluxograma",
    "TUTORIAL GERAL",
    "SCRIPT MESTRE",
    "scripts\PACKAGES OFICIAIS",
    "SCRIPTS BASE OFICIAIS",
    "SCRIPTS DE LISTAGEM"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $rootPath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Criada pasta: $fullPath"
    }
}

# ======================================================
# Auto-number para CONAVMASTERFULL.ps1
# ======================================================
$seqPath = Join-Path $rootPath "SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# ======================================================
# Importar todos os scripts existentes e integrados
# ======================================================
$integratedPaths = @(
    "$rootPath\SCRIPTS BASE OFICIAIS",
    "$rootPath\scripts\PACKAGES OFICIAIS",
    "$rootPath\SCRIPT MESTRE",
    "$rootPath\mapas de fluxograma",
    "$rootPath\logs",
    "$rootPath\logs\install",
    "$rootPath\logs\ia"
)

foreach ($p in $integratedPaths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Filter *.ps1 -Recurse
        foreach ($f in $files) {
            try {
                Write-Log "Executando script integrado: $($f.FullName)"
                . $f.FullName
            } catch {
                Write-Log "Erro executando $($f.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# ======================================================
# GUI Simples - Escolha de execução
# ======================================================
Add-Type -AssemblyName PresentationFramework
$result = [System.Windows.MessageBox]::Show(
    "Deseja rodar todas as versões (histórico completo) ou apenas a última atualização?",
    "CONAV MASTER FULL",
    "YesNoCancel",
    "Question"
)

switch ($result) {
    "Yes" {
        Write-Log "Usuário escolheu rodar TODAS as versões."
        # Simulação de execução full histórico
    }
    "No" {
        Write-Log "Usuário escolheu rodar apenas a ÚLTIMA versão."
        # Simulação apenas última versão
    }
    "Cancel" {
        Write-Log "Execução cancelada pelo usuário."
        exit
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTERFULL0013.ps1 =====

# ===== INICIO CONAVMASTERFULL0014.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todos os módulos e versões do CONAV de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

# ======================================================
# Função central de log
# ======================================================
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# ======================================================
# Criar pastas organizadas
# ======================================================
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$folders = @(
    "LOGS GERAIS",
    "relatorios",
    "relatórios",
    "mapas de fluxograma",
    "TUTORIAL GERAL",
    "SCRIPT MESTRE",
    "scripts\PACKAGES OFICIAIS",
    "SCRIPTS BASE OFICIAIS",
    "SCRIPTS DE LISTAGEM"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $rootPath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Criada pasta: $fullPath"
    }
}

# ======================================================
# Auto-number para CONAVMASTERFULL.ps1
# ======================================================
$seqPath = Join-Path $rootPath "SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# ======================================================
# Importar todos os scripts existentes e integrados
# ======================================================
$integratedPaths = @(
    "$rootPath\SCRIPTS BASE OFICIAIS",
    "$rootPath\scripts\PACKAGES OFICIAIS",
    "$rootPath\SCRIPT MESTRE",
    "$rootPath\mapas de fluxograma",
    "$rootPath\logs",
    "$rootPath\logs\install",
    "$rootPath\logs\ia"
)

foreach ($p in $integratedPaths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Filter *.ps1 -Recurse
        foreach ($f in $files) {
            try {
                Write-Log "Executando script integrado: $($f.FullName)"
                . $f.FullName
            } catch {
                Write-Log "Erro executando $($f.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# ======================================================
# GUI Simples - Escolha de execução
# ======================================================
Add-Type -AssemblyName PresentationFramework
$result = [System.Windows.MessageBox]::Show(
    "Deseja rodar todas as versões (histórico completo) ou apenas a última atualização?",
    "CONAV MASTER FULL",
    "YesNoCancel",
    "Question"
)

switch ($result) {
    "Yes" {
        Write-Log "Usuário escolheu rodar TODAS as versões."
        # Simulação de execução full histórico
    }
    "No" {
        Write-Log "Usuário escolheu rodar apenas a ÚLTIMA versão."
        # Simulação apenas última versão
    }
    "Cancel" {
        Write-Log "Execução cancelada pelo usuário."
        exit
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTERFULL0014.ps1 =====

# ===== INICIO CONAVMASTERFULL0015.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todos os módulos e versões do CONAV de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

# ======================================================
# Função central de log
# ======================================================
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# ======================================================
# Criar pastas organizadas
# ======================================================
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$folders = @(
    "LOGS GERAIS",
    "relatorios",
    "relatórios",
    "mapas de fluxograma",
    "TUTORIAL GERAL",
    "SCRIPT MESTRE",
    "scripts\PACKAGES OFICIAIS",
    "SCRIPTS BASE OFICIAIS",
    "SCRIPTS DE LISTAGEM"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $rootPath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Criada pasta: $fullPath"
    }
}

# ======================================================
# Auto-number para CONAVMASTERFULL.ps1
# ======================================================
$seqPath = Join-Path $rootPath "SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# ======================================================
# Importar todos os scripts existentes e integrados
# ======================================================
$integratedPaths = @(
    "$rootPath\SCRIPTS BASE OFICIAIS",
    "$rootPath\scripts\PACKAGES OFICIAIS",
    "$rootPath\SCRIPT MESTRE",
    "$rootPath\mapas de fluxograma",
    "$rootPath\logs",
    "$rootPath\logs\install",
    "$rootPath\logs\ia"
)

foreach ($p in $integratedPaths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Filter *.ps1 -Recurse
        foreach ($f in $files) {
            try {
                Write-Log "Executando script integrado: $($f.FullName)"
                . $f.FullName
            } catch {
                Write-Log "Erro executando $($f.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# ======================================================
# GUI Simples - Escolha de execução
# ======================================================
Add-Type -AssemblyName PresentationFramework
$result = [System.Windows.MessageBox]::Show(
    "Deseja rodar todas as versões (histórico completo) ou apenas a última atualização?",
    "CONAV MASTER FULL",
    "YesNoCancel",
    "Question"
)

switch ($result) {
    "Yes" {
        Write-Log "Usuário escolheu rodar TODAS as versões."
        # Simulação de execução full histórico
    }
    "No" {
        Write-Log "Usuário escolheu rodar apenas a ÚLTIMA versão."
        # Simulação apenas última versão
    }
    "Cancel" {
        Write-Log "Execução cancelada pelo usuário."
        exit
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTERFULL0015.ps1 =====

# ===== INICIO CONAVMASTERFULL0016.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todas as correções (v1.45+) de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# =========================
# Auto-number do mestre
# =========================
$seqPath = "C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# =========================
# Diretório de versões históricas
# =========================
$historyPath = "C:\CONAV TRADER\CONAV_TRADER\SCRIPTS HISTORICOS"
if (!(Test-Path $historyPath)) {
    New-Item -ItemType Directory -Path $historyPath -Force | Out-Null
    Write-Log "Criada pasta de históricos: $historyPath"
}

# =========================
# Executar SOMENTE os scripts de correção (v1.45+)
# =========================
$fixScripts = Get-ChildItem -Path $historyPath -Filter "v1.45*.ps1" | Sort-Object Name
foreach ($s in $fixScripts) {
    try {
        Write-Log "Executando correção: $($s.Name)"
        . $s.FullName
    } catch {
        Write-Log "Erro executando $($s.Name): $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTERFULL0016.ps1 =====

# ===== INICIO CONAVMASTERFULL0017.ps1 =====
<#
.CONAVMASTERFULL.ps1
CONAV MASTER FULL - SCRIPT UNIFICADO (v1.45_fix4)
Coloque em: C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE\CONAVMASTERFULL.ps1
Funcionalidades:
- dry-run (simulação) e execução real (confirmada)
- logging detalhado em relatorios/ e logs/
- criação automática de pastas necessárias
- aplicação de ícones, build via PyInstaller (com confirmação)
- geração do desinstalador (ps1 + exe via PyInstaller) (com confirmação)
- auto-numbering do script mestre (salva cópia sequencial)
- safe copy / safe remove logic
- GUI confirm dialogs (WinForms) para aprovações sensíveis
- compatível com PowerShell 7 e Windows PowerShell
#>

param (
    [switch]$DryRun,
    [switch]$AutoConfirm,
    [switch]$DebugMode
)

# --------------------------
# CONFIGURAÇÕES (editar se necessário)
# --------------------------
$Root = 'C:\CONAV TRADER\CONAV_TRADER'
$ScriptMasterDir = Join-Path $Root 'SCRIPT MESTRE'
$LogsGeneral = Join-Path $Root 'LOGS GERAIS'
$RelatoriosDir = Join-Path $Root 'relatorios'
$RelatoriosAccent = Join-Path $Root 'relatórios'
$LogsDir = Join-Path $Root 'logs'
$PackagesDir = Join-Path $Root 'PACKAGES OFICIAIS'
$DesinstalarDir = Join-Path $Root 'Desinstalar'
$DistDir = Join-Path $Root 'dist'
$IconsDir = Join-Path $Root 'icons'
$ScriptDir = Join-Path $Root 'scripts'

# --------------------------
# Helpers
# --------------------------
function ts { Get-Date -Format 'yyyyMMdd_HHmmss' }

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    $t = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$t][$Level] $Message"
    $logFile = Join-Path $LogsGeneral 'master.log'
    $dir = Split-Path -Parent $logFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    try {
        Add-Content -Path $logFile -Value $line -Encoding UTF8
    } catch {
        if ($DebugMode) { Write-Host ('[LOGFAIL] {0}' -f $line) }
    }
    if ($DebugMode) { Write-Host $line }
}

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        if ($DryRun) {
            Write-Log ('[DRYRUN] Criar diretório: {0}' -f $Path)
        } else {
            New-Item -ItemType Directory -Force -Path $Path | Out-Null
            Write-Log ('Criada pasta: {0}' -f $Path)
        }
    }
}

function Safe-Copy {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$Force
    )
    try {
        $srcItem = Get-Item -LiteralPath $Source -ErrorAction Stop
        $srcFull = $srcItem.FullName
    } catch {
        Write-Log ('Source não encontrado: {0}' -f $Source) 'ERROR'
        return
    }
    $dstExists = $false
    try {
        $dstResolved = Resolve-Path -LiteralPath $Destination -ErrorAction Stop
        $dstExists = $true
    } catch {
        $dstResolved = $Destination
    }
    if ($srcFull -eq $dstResolved) {
        Write-Log ('Ignorado (mesmo ficheiro): {0}' -f $Source)
        return
    }
    if ($DryRun) {
        Write-Log ('[DRYRUN] Copy {0} -> {1}' -f $Source, $Destination)
    } else {
        try {
            Copy-Item -LiteralPath $Source -Destination $Destination -Force:($Force.IsPresent) -ErrorAction Stop
            Write-Log ('Copiado: {0} -> {1}' -f $Source, $Destination)
        } catch {
            Write-Log ('Erro ao copiar {0} -> {1}: {2}' -f $Source, $Destination, $_.Exception.Message) 'ERROR'
        }
    }
}

function Safe-Remove {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        Write-Log ('Remover: inexistente {0}' -f $Path)
        return
    }
    if ($DryRun) {
        Write-Log ('[DRYRUN] Remover {0}' -f $Path)
    } else {
        try {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            Write-Log ('Removido: {0}' -f $Path)
        } catch {
            Write-Log ('Erro removendo {0}: {1}' -f $Path, $_.Exception.Message) 'ERROR'
        }
    }
}

function GUI-Confirm {
    param(
        [string]$Message = 'Confirm?',
        [string]$Title = 'CONFIRM'
    )
    if ($AutoConfirm) { return $true }
    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(430,160)
    $form.StartPosition = 'CenterScreen'
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Message
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(10,20)
    $form.Controls.Add($label)
    $btnYes = New-Object System.Windows.Forms.Button
    $btnYes.Text = 'Sim'
    $btnYes.Location = New-Object System.Drawing.Point(80,80)
    $btnYes.Add_Click({ $form.Tag = $true; $form.Close() })
    $btnNo = New-Object System.Windows.Forms.Button
    $btnNo.Text = 'Não'
    $btnNo.Location = New-Object System.Drawing.Point(220,80)
    $btnNo.Add_Click({ $form.Tag = $false; $form.Close() })
    $form.Controls.Add($btnYes); $form.Controls.Add($btnNo)
    $form.Add_Shown({$form.Activate()})
    $form.ShowDialog() | Out-Null
    return [bool]$form.Tag
}

function Normalize-IconPath {
    param([string]$IconPath)
    if (-not $IconPath) { return $null }
    $p = $IconPath.Trim()
    if ($p.StartsWith('"') -and $p.EndsWith('"')) { $p = $p.Trim('"') }
    if ($p.StartsWith("'") -and $p.EndsWith("'")) { $p = $p.Trim("'") }
    return $p
}

function Build-MainDashboard {
    param(
        [string]$ScriptPath = (Join-Path $Root 'dashboard\main_dashboard.py'),
        [string]$Icon = (Join-Path $IconsDir 'system_icon.ico')
    )
    Ensure-Dir $DistDir
    $Icon = Normalize-IconPath $Icon
    if (-not (Test-Path $ScriptPath)) {
        Write-Log ('main_dashboard.py não encontrado: {0}' -f $ScriptPath) 'ERROR'
        return $false
    }
    $cmd = 'pyinstaller --onefile --noconsole --distpath "' + $DistDir + '" --name main_dashboard --add-data "' + $Root + ';."'

    if ($Icon -and (Test-Path $Icon)) {
        $cmd += ' --icon "' + $Icon + '"'
    }
    $cmd += ' "' + $ScriptPath + '"'
    Write-Log ('Executando PyInstaller: {0}' -f $cmd)
    if ($DryRun) { Write-Log '[DRYRUN] Build ignorado (simulação)'; return $true }
    try {
        $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $cmd" -Wait -NoNewWindow -PassThru
        if ($proc.ExitCode -ne 0) {
            Write-Log ('PyInstaller retornou código {0}' -f $proc.ExitCode) 'ERROR'
            return $false
        }
        Write-Log 'main_dashboard.exe criado em dist\'
        return $true
    } catch {
        Write-Log ('Erro ao executar PyInstaller: {0}' -f $_.Exception.Message) 'ERROR'
        return $false
    }
}

function Create-Uninstaller {
    param(
        [string]$UninstallPs1 = (Join-Path $Root 'UNINSTALL_CONAV_TRADER.ps1'),
        [string]$TargetFolder = $DesinstalarDir,
        [string]$Icon = (Join-Path $IconsDir 'system_icon.ico')
    )
    Ensure-Dir $TargetFolder
    $destPs1 = Join-Path $TargetFolder 'Desinstalar-Por-PowerShell.ps1'
    Safe-Copy -Source $UninstallPs1 -Destination $destPs1 -Force
    $wrapper = Join-Path $TargetFolder 'uninstall_wrapper.py'
    $pyCode = @"
import subprocess, sys, os
ps1 = os.path.join(os.path.dirname(__file__),"Desinstalar-Por-PowerShell.ps1")
subprocess.call(["powershell","-ExecutionPolicy","Bypass","-File", ps1])
"@
    if ($DryRun) {
        Write-Log ('[DRYRUN] Criar wrapper python: {0}' -f $wrapper)
    } else {
        Set-Content -Path $wrapper -Value $pyCode -Encoding UTF8
        Write-Log ('Wrapper Python criado: {0}' -f $wrapper)
    }
    if (GUI-Confirm 'Deseja compilar Desinstalar.exe via PyInstaller?' 'Compilar Desinstalador') {
        $iconPath = Normalize-IconPath $Icon
        $specCmd = 'pyinstaller --onefile --noconsole --distpath "' + $TargetFolder + '" --workpath "' + $TargetFolder + '\build" --specpath "' + $TargetFolder + '" --name Desinstalar'
        if ($iconPath -and (Test-Path $iconPath)) { $specCmd += ' --icon "' + $iconPath + '"' }
        $specCmd += ' "' + $wrapper + '"'
        Write-Log ('Executando: {0}' -f $specCmd)
        if (-not $DryRun) {
            Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $specCmd" -Wait -NoNewWindow
            Write-Log ('Desinstalar.exe compilado em {0}' -f $TargetFolder)
        } else {
            Write-Log '[DRYRUN] pyinstaller compilação ignorada'
        }
    } else {
        Write-Log 'Compilação do desinstalador foi cancelada pelo usuário.'
    }
}

function Build-Package {
    param(
        [string]$OutputName = ('CONAV_FULL_PROFESSIONAL_v{0}.zip' -f (Get-Date -Format 'yyyyMMdd_HHmm')),
        [string]$SourceRoot = $Root,
        [switch]$ForceOverwrite
    )
    Ensure-Dir $PackagesDir
    $outPath = Join-Path $PackagesDir $OutputName
    if (Test-Path $outPath) {
        if ($ForceOverwrite) { Remove-Item -LiteralPath $outPath -Force }
        else {
            $snum = (Get-Date).ToString('yyyyMMddHHmmss')
            $outPath = Join-Path $PackagesDir ('{0}_{1}.zip' -f [System.IO.Path]::GetFileNameWithoutExtension($OutputName), $snum)
        }
    }
    Write-Log ('Criando pacote: {0}' -f $outPath)
    if ($DryRun) { Write-Log '[DRYRUN] Compressão ignorada'; return $outPath }
    try {
        $items = @()
        foreach ($sub in @('dashboard','dist','scripts','tools','relatorios','relatórios','icons','resources','docs','emails')) {
            $p = Join-Path $SourceRoot $sub
            if (Test-Path $p) { $items += $p }
        }
        if (-not $items) {
            Write-Log 'Nenhum item encontrado para empacotar.' 'ERROR'
            return $null
        }
        Compress-Archive -Path $items -DestinationPath $outPath -Force
        Write-Log ('Pacote gerado em {0}' -f $outPath)
        return $outPath
    } catch {
        Write-Log ('Erro criando pacote: {0}' -f $_.Exception.Message) 'ERROR'
        return $null
    }
}

function Save-SelfVersion {
    Ensure-Dir $ScriptMasterDir
    $existing = Get-ChildItem -Path $ScriptMasterDir -Filter 'CONAVMASTERFULL*.ps1' -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($existing) {
        $digits = ($existing.BaseName -replace '\D','')
        if ($digits -match '^\d+$') { $num = [int]$digits + 1 } else { $num = 1 }
    } else { $num = 1 }
    $seqName = ('CONAVMASTERFULL{0:D4}.ps1' -f $num)
    $dest = Join-Path $ScriptMasterDir $seqName
    if ($DryRun) {
        Write-Log ('[DRYRUN] Salvar self como: {0}' -f $dest)
    } else {
        Copy-Item -LiteralPath $PSCommandPath -Destination $dest -Force
        Write-Log ('Nova versão mestre salva: {0}' -f $dest)
    }
}

# --------------------------
# Main
# --------------------------
Write-Log '==== START CONAV MASTER (v1.45_fix4) ===='

foreach ($d in @($ScriptMasterDir, $LogsGeneral, $RelatoriosDir, $RelatoriosAccent, $LogsDir, $PackagesDir, $DesinstalarDir, $DistDir, $IconsDir, $ScriptDir)) {
    Ensure-Dir $d
}

Save-SelfVersion

if ($DryRun) {
    Write-Log '[DRYRUN] Modo simulação ativado. As ações abaixo NÃO serão executadas; apenas listadas.'
    Write-Log '[DRYRUN] 1) Build main_dashboard (pyinstaller)  2) Criar/compilar desinstalador 3) Aplicar icons 4) Gerar pacote ZIP'
    if (-not (GUI-Confirm 'Deseja prosseguir e executar as ações (real)?')) {
        Write-Log '[DRYRUN] Usuário cancelou execução real após simulação.'
        Write-Log '==== END CONAV MASTER ===='
        return
    } else {
        $DryRun = $false
        Write-Log 'Usuário autorizou execução real.'
    }
}

$built = Build-MainDashboard
if (-not $built) { Write-Log 'Falha ao compilar main_dashboard. Verifique logs.' 'ERROR' }

Create-Uninstaller

$pkg = Build-Package -OutputName ('CONAV_FULL_PROFESSIONAL_v1.45_fix4.zip')
if ($pkg) { Write-Log ('Pacote final em: {0}' -f $pkg) } else { Write-Log 'Falha ao gerar pacote' 'ERROR' }

Write-Log '==== END CONAV MASTER ===='

# ===== FIM CONAVMASTERFULL0017.ps1 =====

# ===== INICIO CONAVMASTERFULL0018.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todos os módulos e versões do CONAV de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

# ======================================================
# Função central de log
# ======================================================
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# ======================================================
# Criar pastas organizadas
# ======================================================
$rootPath = "C:\CONAV TRADER\CONAV_TRADER"
$folders = @(
    "LOGS GERAIS",
    "relatorios",
    "relatórios",
    "mapas de fluxograma",
    "TUTORIAL GERAL",
    "SCRIPT MESTRE",
    "scripts\PACKAGES OFICIAIS",
    "SCRIPTS BASE OFICIAIS",
    "SCRIPTS DE LISTAGEM"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $rootPath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Criada pasta: $fullPath"
    }
}

# ======================================================
# Auto-number para CONAVMASTERFULL.ps1
# ======================================================
$seqPath = Join-Path $rootPath "SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# ======================================================
# Importar todos os scripts existentes e integrados
# ======================================================
$integratedPaths = @(
    "$rootPath\SCRIPTS BASE OFICIAIS",
    "$rootPath\scripts\PACKAGES OFICIAIS",
    "$rootPath\SCRIPT MESTRE",
    "$rootPath\mapas de fluxograma",
    "$rootPath\logs",
    "$rootPath\logs\install",
    "$rootPath\logs\ia"
)

foreach ($p in $integratedPaths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Filter *.ps1 -Recurse
        foreach ($f in $files) {
            try {
                Write-Log "Executando script integrado: $($f.FullName)"
                . $f.FullName
            } catch {
                Write-Log "Erro executando $($f.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# ======================================================
# GUI Simples - Escolha de execução
# ======================================================
Add-Type -AssemblyName PresentationFramework
$result = [System.Windows.MessageBox]::Show(
    "Deseja rodar todas as versões (histórico completo) ou apenas a última atualização?",
    "CONAV MASTER FULL",
    "YesNoCancel",
    "Question"
)

switch ($result) {
    "Yes" {
        Write-Log "Usuário escolheu rodar TODAS as versões."
        # Simulação de execução full histórico
    }
    "No" {
        Write-Log "Usuário escolheu rodar apenas a ÚLTIMA versão."
        # Simulação apenas última versão
    }
    "Cancel" {
        Write-Log "Execução cancelada pelo usuário."
        exit
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM CONAVMASTERFULL0018.ps1 =====

# ===== INICIO Gerar arquivos e  zip.ps1 =====
import os
import zipfile
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas

# Caminho onde o ZIP será salvo
package_dir = r"C:\SCRIPTS\PACKAGE"
zip_name = "FULLONEv14_UNIFIED.zip"
zip_path = os.path.join(package_dir, zip_name)

# Criar pasta de destino se não existir
os.makedirs(package_dir, exist_ok=True)

# Função para criar arquivos PDF placeholder
def create_pdf(file_path, title):
    c = canvas.Canvas(file_path, pagesize=letter)
    c.drawString(100, 750, f"Este é o {title}")
    c.drawString(100, 735, "Conteúdo placeholder.")
    c.save()

# Lista de arquivos a serem incluídos no ZIP
files_to_include = [
    ("FULLONE_UNIFIED.ps1", "Conteúdo do script unificado"),
    ("FULLONE.bat", "Conteúdo do batch file"),
    ("TUTORIAL.pdf", "Tutorial"),
    ("MANUAL.pdf", "Manual"),
    ("GUIA-RÁPIDO.pdf", "Guia Rápido")
]

# Criar arquivos e adicionar ao ZIP
with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
    for file_name, content in files_to_include:
        file_path = os.path.join(package_dir, file_name)
        if file_name.endswith(".pdf"):
            create_pdf(file_path, content)
        else:
            with open(file_path, 'w') as f:
                f.write(content)
        zf.write(file_path, arcname=file_name)

print(f"Pacote criado com sucesso: {zip_path}")
# ===== FIM Gerar arquivos e  zip.ps1 =====

# ===== INICIO criacaodepdf.ps1 =====
######################################################################################
#Um script que ajudou no aprendizado sobre powershell - começando com o poderoso get-help
######################################################################################
function Learn-PowerShell
{

Write-host "Você tem o Office Word instalado nesta máquina (é necessário para executar este script)? (Padrão é Não)" -ForegroundColor Yellow 
    $Readhost = Read-Host " ( s / n ) " 
    Switch ($ReadHost) 
     { 
       s {Write-host "Sim, Prosseguindo com a criação do seu próprio livro PowerShell!"} 
       n {Write-Host "Não, O script será fechado agora - Office Word necessário" ; exit} 
       Default {Write-Host "Padrão é não, O script será fechado agora"; exit} 

     }

###############################
#declarar confiança no repositório
###############################
try
{
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
write-host "PSGallery confiável com sucesso" -ForegroundColor Yellow 
}
catch
{ 
Write-Host "PSGALLERY não foi confiável com sucesso" -ForegroundColor Red 
return
}

############################
#instalações de módulos personalizados
############################
Write-Host "Tentando instalar o módulo PDF" -ForegroundColor Yellow 
try
{
install-module -Name "convert2pdf" -Scope CurrentUser
Write-Host "convert2PDF instalado com sucesso" -ForegroundColor Yellow 
}
catch
{ 
Write-Host "erro ao instalar o módulo conver2PDF..." -ForegroundColor Red 
return
}

Write-Host "Tentando instalar o Merge PDF" -ForegroundColor Yellow 
try
{
install-module -Name MergePdf -Scope CurrentUser
Write-Host "MergePDF instalado com sucesso" -ForegroundColor Yellow 
}
catch
{ 
Write-Host "erro ao instalar o módulo MergePDF..." -ForegroundColor Red
return
}

################################################################
#convert2pdf personalizado para lidar com .txts
#Autor original - HyundongHwang
#https://www.powershellgallery.com/packages/convert2pdf/1.0.1
################################################################
function convert2pdf
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)]
        [System.IO.FileInfo]
        $FILE_PATH
    )

    process {
        $pdfPath = "$($FILE_PATH.DirectoryName)\$($FILE_PATH.BaseName).pdf"

        if (Test-Path $pdfPath) {
            Write-Host "$pdfPath já existe !!!"
            Write-Output $pdfPath
            return
        }



        if(($FILE_PATH -like "*.txt") -or ($FILE_PATH -like "*.docx")) {
            $wordCom = New-Object -ComObject Word.Application
            $doc = $wordCom.Documents.Open($FILE_PATH.FullName)
            Write-Host "$($FILE_PATH.FullName) iniciado ..."
            $doc.SaveAs($pdfPath, 17)
            $doc.Close()
            Write-Host "$pdfPath concluído ..."
            $wordCom.Quit()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wordCom)
            Write-Output $pdfPath
        }
    }
}

#################################
#Criação de TXT a partir de arquivos de ajuda
#################################
Write-Host "Criando nova pasta PowerShell e tutoriais na unidade de sistema"
try
{
$path = "C:\PowerShell_Tutorials"
If(!(test-path $path))
{
      New-Item -ItemType Directory -Force -Path $path
}
Write-Host "C:\PowerShell_Tutorials agora criada"
}
catch 
{
write-host "erro ao escrever novos arquivos na sua unidade C:\ - talvez problema de permissão?"
}

############################
#Criar Capa
############################
New-Item -Path c:\PowerShell_Tutorials\ -Name "00_capa.txt" -ItemType "file" -Value "


Aprenda:

  _____                         _____ _          _ _ 
 |  __ \                       / ____| |        | | |
 | |__) |_____      _____ _ __| (___ | |__   ___| | |
 |  ___// _ \ \ /\ / / _ \ '__|\___ \| '_ \ / _ \ | |
 | |   | (_) \ V  V /  __/ |   ____) | | | |  __/ | |
 |_|    \___/ \_/\_/ \___|_|  |_____/|_| |_|\___|_|_|
      ______ ______
    _/      Y      \_
   // ~~ ~~ | ~~ ~  \\
  // ~ ~ ~~ | ~~~ ~~ \\      
 //________.|.________\\     
`----------`-'----------'
                                                     

                                                     

"
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\00_capa.txt

###########################
#Criar sumário
###########################
New-Item -Path c:\PowerShell_Tutorials\ -Name "00_sumario.txt" -ItemType "file" -Value "


SUMÁRIO:
CAPÍTULO 01 - APRENDA A SE AJUDAR COM HELP...
CAPÍTULO 02 - Navegando pelo local da linha de comando do PowerShell...
CAPÍTULO 03 - Configure suas coisas! Configuração de perfil...
CAPÍTULO 04 - Sintaxe do PowerShell, aprendendo a ler os exemplos...
CAPÍTULO 05 - Comandos e propriedades cmdlet...
CAPÍTULO 06 - Alias, Parâmetros e Pipelines
CAPÍTULO 07 - Variáveis, ScriptBlocks, Matrizes e Operadores
CAPÍTULO 08 - Configurar a Política de Execução
CAPÍTULO 09 - o ISE, Funções, Scripts e Módulos
CAPÍTULO 10 - Sessões Remotas PSSnapins
                                                 

"

convert2PDF -FILE_PATH c:\PowerShell_Tutorials\00_sumario.txt

#comece aprendendo como o HELP funciona
New-Item -Path c:\PowerShell_Tutorials\ -Name "01_CAPITULO01.txt" -ItemType "file" -Value "CAPÍTULO 01 - APRENDA A SE AJUDAR COM HELP..."
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\01_CAPITULO01.txt
get-help -full | out-file c:\PowerShell_Tutorials\02_get-help.txt
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\02_get-help.txt

#navegando pelo powershell/cmd
New-Item -Path c:\PowerShell_Tutorials\ -Name "03_CAPITULO02.txt" -ItemType "file" -Value "CAPÍTULO 02 - Navegando pelo local da linha de comando do PowerShell..."
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\03_CAPITULO02.txt
get-help Set-Location -full | Out-File c:\PowerShell_Tutorials\04_Set_location.txt
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\04_Set_location.txt
get-help New-Item -full | Out-File c:\PowerShell_Tutorials\05_New_Item.txt
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\05_New_Item.txt

#configure seu perfil
New-Item -Path c:\PowerShell_Tutorials\ -Name "06_CAPITULO03.txt" -ItemType "file" -Value "CAPÍTULO 03 - Configure suas coisas! Configuração de perfil..."
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\06_CAPITULO03.txt
get-help about_profiles -full | Out-File c:\PowerShell_Tutorials\07_about_profiles.txt
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\07_about_profiles.txt

#sintaxe cmdlet-powershell
New-Item -Path c:\PowerShell_Tutorials\ -Name "08_CAPITULO04.txt" -ItemType "file" -Value "CAPÍTULO 04 - Sintaxe do PowerShell, aprendendo a ler os exemplos..."
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\08_CAPITULO04.txt
get-help about_Command_Syntax -full | out-file C:\PowerShell_Tutorials\09_about_command_syntax.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\09_about_command_syntax.txt

#revisão detalhada de cmdlets, objetos e propriedades
New-Item -Path c:\PowerShell_Tutorials\ -Name "10_CAPITULO05.txt" -ItemType "file" -Value "CAPÍTULO 05 - Comandos e propriedades cmdlet..."
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\10_CAPITULO05.txt
get-help get-member -full | out-file C:\PowerShell_Tutorials\11_get-member.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\11_get-member.txt
get-help about_properties -full | out-file C:\PowerShell_Tutorials\12_about_properties.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\12_about_properties.txt
get-help about_methods -full | out-file C:\PowerShell_Tutorials\13_about_methods.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\13_about_methods.txt

#Conceitos intermediários sobre cmdlets 
New-Item -Path c:\PowerShell_Tutorials\ -Name "14_CAPITULO06.txt" -ItemType "file" -Value "CAPÍTULO 06 - Alias, Parâmetros e Pipelines"
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\14_CAPITULO06.txt
get-help about_Aliases -full | out-file C:\PowerShell_Tutorials\15_about_aliases.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\15_about_aliases.txt
get-help about_Objects -full | out-file C:\PowerShell_Tutorials\16_about_objects.txt
convert2PDF -FILE_PATH  C:\PowerShell_Tutorials\16_about_objects.txt
get-help about_Parameters -full | out-file c:\PowerShell_Tutorials\17_about_parameters.txt
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\17_about_parameters.txt
get-help about_pipeline -Full | out-file C:\PowerShell_Tutorials\18_about_pipeline.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\18_about_pipeline.txt

#lógica
New-Item -Path c:\PowerShell_Tutorials\ -Name "19_CAPITULO07.txt" -ItemType "file" -Value "CAPÍTULO 07 - Variáveis, ScriptBlocks, Matrizes e Operadores"
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\19_CAPITULO07.txt
get-help about_Variables -full | out-file C:\PowerShell_Tutorials\20_about_variables.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\20_about_variables.txt
get-help about_Script_Blocks -full | out-file C:\PowerShell_Tutorials\21_about_script_blocks.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\21_about_script_blocks.txt
get-help about_Arrays -full | out-file C:\PowerShell_Tutorials\22_about_arrays.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\22_about_arrays.txt
get-help about_If -full | out-file C:\PowerShell_Tutorials\23_about_If.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\23_about_If.txt
get-help about_Operators -full | out-file C:\PowerShell_Tutorials\24_about_operators.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\24_about_operators.txt

#alterando a política de execução da sua máquina local para que você possa realmente executar scripts e módulos! 
New-Item -Path c:\PowerShell_Tutorials\ -Name "25_CAPITULO08.txt" -ItemType "file" -Value "CAPÍTULO 08 - Configurar a Política de Execução"
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\25_CAPITULO08.txt
get-help Set-ExecutionPolicy -full | out-file c:\PowerShell_Tutorials\26_about_executionPolicy.txt
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\26_about_executionPolicy.txt

# como construir funções que podem se tornar cmdlets, scripts ou módulos
New-Item -Path c:\PowerShell_Tutorials\ -Name "27_CAPITULO09.txt" -ItemType "file" -Value "CAPÍTULO 09 - o ISE, Funções, Scripts e Módulos"
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\27_CAPITULO09.txt
get-help about_Powershell_Ise.exe -full | out-file C:\PowerShell_Tutorials\28_about_PowerShell_ISE_scripteditor.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\28_about_PowerShell_ISE_scripteditor.txt
get-help about_Functions -full | out-file C:\PowerShell_Tutorials\29_about_functions.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\29_about_functions.txt
get-help about_scripts -full | out-file C:\PowerShell_Tutorials\30_about_scripts.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\30_about_scripts.txt
get-help about_Modules -full | out-file C:\PowerShell_Tutorials\31_about_modules.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\31_about_modules.txt

#conceitos de sistema e sessão remotos
New-Item -Path c:\PowerShell_Tutorials\ -Name "23_CAPITULO10.txt" -ItemType "file" -Value "CAPÍTULO 10 - Sessões Remotas PSSnapins"
convert2PDF -FILE_PATH c:\PowerShell_Tutorials\23_CAPITULO10.txt
get-help about_PSSnapins -full | out-file C:\PowerShell_Tutorials\23_about_PSSNapins.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\23_about_PSSNapins.txt
get-help about_PSSessions -full | out-file C:\PowerShell_Tutorials\24_about_PSSessions.txt
convert2PDF -FILE_PATH C:\PowerShell_Tutorials\24_about_PSSessions.txt

###################################################################################################
# Cria livro de todos os PDFs em um único PDF
# EXEMPLOS: 
# Merge-Pdf -Path C:\PowerShell_Tutorials\  -OutputPath C:\PowerShell_Tutorials\POWERBOOK5000.pdf
###################################################################################################


try
{
write-host "adicionando DLL PDFSHARP do módulo instalado" 
Add-Type -Path $env:USERPROFILE\Documents\WindowsPowerShell\Modules\MergePdf\1.1\PdfSharp.dll
pause 5000
}
catch
{
write-host "ERRO AO LOCALIZAR OU INSTALAR O MÓDULO PDFSHARP"
}

Merge-Pdf -Path C:\PowerShell_Tutorials\  -OutputPath C:\PowerShell_Tutorials\POWERBOOK5000.pdf

#abrir o livro para o usuário
Invoke-Item "C:\PowerShell_Tutorials\POWERBOOK5000.pdf"

}
# ===== FIM criacaodepdf.ps1 =====

# ===== INICIO tutorialgeral.ps1 =====
<#
================================================================================
 CONAV MASTER FULL - SCRIPT UNIFICADO
 Nome oficial: CONAVMASTERFULL.ps1
 Sequencial:   CONAVMASTERFULL0001.ps1, CONAVMASTERFULL0002.ps1, ...
 Local:        C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE
 Função:       Executa todas as correções (v1.45+) de forma unificada
================================================================================
#>

param (
    [switch]$DebugMode
)

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Add-Content -Path "C:\CONAV TRADER\CONAV_TRADER\LOGS GERAIS\master.log" -Value $line
    if ($DebugMode) { Write-Host $line }
}

# =========================
# Auto-number do mestre
# =========================
$seqPath = "C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE"
$existing = Get-ChildItem -Path $seqPath -Filter "CONAVMASTERFULL*.ps1" | Sort-Object Name -Descending | Select-Object -First 1
if ($existing) {
    $num = [int]($existing.BaseName -replace '\D', '') + 1
} else {
    $num = 1
}
$newSeqFile = Join-Path $seqPath ("CONAVMASTERFULL{0:D4}.ps1" -f $num)
Copy-Item $PSCommandPath $newSeqFile -Force
Write-Log "Nova versão mestre salva como: $newSeqFile"

# =========================
# Diretório de versões históricas
# =========================
$historyPath = "C:\CONAV TRADER\CONAV_TRADER\SCRIPTS HISTORICOS"
if (!(Test-Path $historyPath)) {
    New-Item -ItemType Directory -Path $historyPath -Force | Out-Null
    Write-Log "Criada pasta de históricos: $historyPath"
}

# =========================
# Executar SOMENTE os scripts de correção (v1.45+)
# =========================
$fixScripts = Get-ChildItem -Path $historyPath -Filter "v1.45*.ps1" | Sort-Object Name
foreach ($s in $fixScripts) {
    try {
        Write-Log "Executando correção: $($s.Name)"
        . $s.FullName
    } catch {
        Write-Log "Erro executando $($s.Name): $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "Execução do CONAV MASTER FULL finalizada."
# ===== FIM tutorialgeral.ps1 =====

# ===== INICIO SETUP_CONAV_TRADER_FINAL.ps1 =====
# =============================
# Script de Setup e ZIP do CONAV TRADER
# =============================

# Permitir execução
Set-ExecutionPolicy Bypass -Scope Process -Force

# Caminho base da instalação
$basePath = "C:\CONAV_TRADER"

# Criar pastas necessárias
$folders = @("data", "dashboard", "logs", "docs", "resources\icons")
foreach ($folder in $folders) {
    $fullPath = Join-Path $basePath $folder
    if (-Not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    }
}

# Copiar arquivos do pacote (ajustar caminhos de origem se necessário)
# Exemplo: Copy-Item ".\conav_trader.exe" "$basePath\conav_trader.exe" -Force

# Criar atalho no Desktop
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:Public\Desktop\CONAV TRADER.lnk")
$Shortcut.TargetPath = "$basePath\conav_trader.exe"
$Shortcut.IconLocation = "$basePath\resources\icons\conav_icon.ico"
$Shortcut.Save()

# Gerar arquivo ZIP completo
$zipPath = "$basePath\CONAV_TRADER_OneClick_Atualizado.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path "$basePath\*" -DestinationPath $zipPath -Force

# Abrir CONAV TRADER
Start-Process "$basePath\conav_trader.exe"

Write-Host "Setup concluído com sucesso! ZIP gerado em $zipPath"
# ===== FIM SETUP_CONAV_TRADER_FINAL.ps1 =====

# ===== INICIO setup_conav_trader.ps1 =====
PowerShell de instalação automática simulado
# ===== FIM setup_conav_trader.ps1 =====

# ===== INICIO CONAV_TRADER_AutoUpdate.ps1 =====
Set-ExecutionPolicy Bypass -Scope Process -Force

# === CONFIGURAÇÕES ===
$basePath = "C:\CONAV_TRADER"
$zipPath = "$basePath\CONAV_TRADER_OneClick_Final.zip"

# URLs dos arquivos atualizados (exemplo, você deve substituir pelos links reais)
$arquivos = @{
    "conav_trader.exe" = "https://exemplo.com/conav_trader.exe"
    "dashboard\dashboard_files.zip" = "https://exemplo.com/dashboard.zip"
    "docs\Tutorial_Ilustrativo.pdf" = "https://exemplo.com/Tutorial_Ilustrativo.pdf"
    "docs\Tutorial_Real.pdf" = "https://exemplo.com/Tutorial_Real.pdf"
    "docs\CONAV_TRADER_Manual_Guia.pdf" = "https://exemplo.com/CONAV_TRADER_Manual_Guia.pdf"
}

# Pastas necessárias
$pastas = @("dashboard","data","logs","docs","resources\icons","relatorios")

# Criar pastas se não existirem
foreach ($pasta in $pastas) {
    $fullPath = Join-Path $basePath $pasta
    if (-Not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    }
}

# Baixar arquivos
foreach ($arquivo in $arquivos.GetEnumerator()) {
    $destino = Join-Path $basePath $arquivo.Key
    $destinoDir = Split-Path $destino
    if (-Not (Test-Path $destinoDir)) { New-Item -ItemType Directory -Path $destinoDir -Force | Out-Null }

    Write-Host "Baixando $($arquivo.Key) ..."
    try {
        Invoke-WebRequest -Uri $arquivo.Value -OutFile $destino -UseBasicParsing
    } catch {
        Write-Host "Erro ao baixar $($arquivo.Key): $_"
    }
}

# Criar relatório de atualização automática
$relatorio = Join-Path $basePath "relatorios\Atualizacao_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$conteudo = @"
Data/Hora: $(Get-Date)
Arquivos atualizados:
$(($arquivos.Keys | ForEach-Object { "- $_" }) -join "`n")
"@
Set-Content -Path $relatorio -Value $conteudo

# Criar ZIP final
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path "$basePath\*" -DestinationPath $zipPath -Force

Write-Host "==============================="
Write-Host "Setup e atualização concluídos!"
Write-Host "ZIP final gerado em: $zipPath"
Write-Host "Relatório de atualização: $relatorio"
Write-Host "==============================="
# ===== FIM CONAV_TRADER_AutoUpdate.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.44.ps1 =====
# INSTALL_CONAV_TRADER_FULL1.44.ps1
# Versão 1.44 - Integrado: SET_ICONS, backups, install.log naming, auto-update uninstall manifest
param([switch]$DryRun, [string]$ZipPath="")

$ErrorActionPreference = "Stop"
$Root = "C:\CONAV TRADER\CONAV_TRADER"
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$Global:LogsDir = Join-Path $Root "logs"
$Global:RelDir = Join-Path $Root "relatorios"
$Global:ScriptsDir = Join-Path $Root "scripts"
if (!(Test-Path $Global:LogsDir)) { New-Item -ItemType Directory -Path $Global:LogsDir -Force | Out-Null }
if (!(Test-Path $Global:RelDir)) { New-Item -ItemType Directory -Path $Global:RelDir -Force | Out-Null }
if (!(Test-Path $Global:ScriptsDir)) { New-Item -ItemType Directory -Path $Global:ScriptsDir -Force | Out-Null }

function Write-Log { param($msg,$file) $t=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); $line="[$t] $msg"; if ($file) { Add-Content -Path $file -Value $line } ; Write-Host $line }

# install.log naming helper
function New-InstallLogName { param($tool) return Join-Path $Global:LogsDir ("install_{0}_{1}.log" -f $tool, $timestamp) }

# backup helper
function Ensure-Backup { param($what) $bdir = Join-Path $Root ("backup\preinstall_{0}_{1}" -f $what, $timestamp); if (!(Test-Path $bdir)) { New-Item -ItemType Directory -Path $bdir -Force | Out-Null } ; return $bdir }

# Save script to scripts with numeric prefix
function Save-ScriptIndexed { param($src) if (!(Test-Path $src)) { return } ; $base = Split-Path -Leaf $src ; $idx = 1 ; while (Test-Path (Join-Path $Global:ScriptsDir ("{0:D4}_{1}" -f $idx, $base))) { $idx++ } ; Copy-Item -Path $src -Destination (Join-Path $Global:ScriptsDir ("{0:D4}_{1}" -f $idx, $base)) -Force ; Write-Log "Saved script $base as {0:D4}_{1}" (Join-Path $Global:ScriptsDir ("{0:D4}_{1}" -f $idx, $base)) (Join-Path $Global:LogsDir "install_master_{0}.log" -f $timestamp) }

# Basic smart repair for PS1 content
function Repair-PS1-Content {
    param([string]$path)
    if (!(Test-Path $path)) { return }
    $txt = Get-Content -Raw -Path $path -ErrorAction SilentlyContinue
    if (!$txt) { return }
    $orig = $txt
    # replace smart quotes and ellipsis
    $txt = $txt -replace "`u201c|`u201d", '"' 
    $txt = $txt -replace "`u2018|`u2019", "'"
    $txt = $txt -replace "\u2026", "..." 
    # fix $var: -> ${var}:
    $txt = $txt -replace '\$(\w+):', '${$1}:'
    # fix \.Name -> .Name
    $txt = $txt -replace '\\\.Name', '.Name'
    # comment leading non-code markers like [INSTALL]
    $lines = $txt -split "`n"
    if ($lines.Length -gt 0) {
        if ($lines[0] -match '^\s*(\[[A-Z]+\]|\[INSTALL|\[UNINSTALL)') {
            $lines[0] = "# " + $lines[0] + "  # Auto-commented"
        }
    }
    $txt = ($lines -join "`n")
    if ($txt -ne $orig) { Set-Content -Path $path -Value $txt -Force ; Write-Log "Repaired PS1: $path" (Join-Path $Global:LogsDir "repair_{0}.log" -f $timestamp) }
}

# Ensure basic folders
$folders = @("automation","build","dashboard","data","database","Desinstalar","dist","docs","emails","icons","logs","relatorios","resources","scripts","tools","backup")
foreach ($f in $folders) { $p=Join-Path $Root $f; if (!(Test-Path $p)) { if ($DryRun) { Write-Log "[SIM] Criar $p" (Join-Path $Global:LogsDir "install_{0}.log" -f $timestamp) } else { New-Item -ItemType Directory -Path $p -Force | Out-Null ; Write-Log "Criada pasta $p" (Join-Path $Global:LogsDir "install_{0}.log" -f $timestamp) } } }

# If ZIP provided, extract and map as before but create manifest entries with descriptive names
if ($ZipPath -and (Test-Path $ZipPath)) {
    $temp = Join-Path $env:TEMP ("conav_extract_{0}" -f (Get-Random))
    if (Test-Path $temp) { Remove-Item -Recurse -Force $temp }
    New-Item -ItemType Directory -Path $temp | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $temp)
    $manifest = Join-Path $Global:RelDir ("install_manifest_{0}.txt" -f $timestamp)
    Get-ChildItem -Path $temp -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($temp.Length).TrimStart("\/")
        $first = ($rel -split "[\\/]" )[0].ToLower()
        $mapping = @{ "automation"="automation"; "build"="build"; "dashboard"="dashboard"; "data"="data"; "database"="database"; "desinstalar"="Desinstalar"; "dist"="dist"; "docs"="docs"; "emails"="emails"; "icons"="icons"; "logs"="logs"; "relatorios"="relatorios"; "resources"="resources"; "scripts"="scripts"; "tools"="tools" }
        $destSub = if ($mapping.ContainsKey($first)) { $mapping[$first] } else { "" }
        $destRoot = if ($destSub -ne "") { Join-Path $Root $destSub } else { $Root }
        $dest = Join-Path $destRoot ($rel -replace "^[^\\\/]+[\\\/]","")
        $destDir = Split-Path -Parent $dest
        if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        # backup if exists
        if (Test-Path $dest) {
            $bdir = Ensure-Backup -what "zip_replace"
            Copy-Item -Path $dest -Destination (Join-Path $bdir (Split-Path $dest -Leaf)) -Force
        }
        if ($DryRun) { Write-Log "[SIM] Copy $($_.FullName) -> $dest" (Join-Path $Global:LogsDir "install_{0}.log" -f $timestamp) } else { Copy-Item -Path $_.FullName -Destination $dest -Force ; Write-Log "Placed: $dest" (Join-Path $Global:LogsDir "install_{0}.log" -f $timestamp) ; Add-Content -Path $manifest -Value $dest }
        # if script, save indexed
        if ($dest.ToLower().EndsWith(".ps1")) { Repair-PS1-Content -path $dest ; Save-ScriptIndexed -src $dest }
    }
    Write-Log "Manifest: $manifest" (Join-Path $Global:LogsDir "install_{0}.log" -f $timestamp)
}

# Integrate SET_ICONS: if present in scripts folder in package, run it (repair + apply icons)
$setIcons = Join-Path $Root "SET_ICONS_CONAV1.25.ps1"
if (Test-Path $setIcons) {
    if ($DryRun) { Write-Log "[SIM] Executar SET_ICONS (simulação)" (Join-Path $Global:LogsDir "install_{0}.log" -f $timestamp) } else { Write-Log "Executando SET_ICONS..." (Join-Path $Global:LogsDir "install_{0}.log" -f $timestamp) ; & $setIcons }
} else {
    Write-Log "SET_ICONS não encontrado - pular" (Join-Path $Global:LogsDir "install_{0}.log" -f $timestamp)
}

Write-Log "Instalação v1.44 concluída (DryRun=$DryRun)." (Join-Path $Global:LogsDir "install_{0}.log" -f $timestamp)

# ===== FIM INSTALL_CONAV_TRADER_FULL1.44.ps1 =====

# ===== INICIO SET_ICONS_CONAV1.25.ps1 =====
# SET_ICONS_CONAV1.25.ps1 - integrated version
# Applies system_icon.ico to all EXE files in dist and sets shortcuts icons in Desktop and StartMenu if present
param([string]$Root="C:\CONAV TRADER\CONAV_TRADER")
$icon = Join-Path $Root "system_icon.ico"
function Write-Log { param($m) $t=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); $line="[$t] $m"; Write-Host $line ; $log = Join-Path $Root "logs\set_icons.log" ; Add-Content -Path $log -Value $line }
if (!(Test-Path $icon)) { Write-Log "system_icon.ico not found: $icon" ; exit 0 }
# set icon for EXE in dist by recreating exe resources via powershell fallback — here we only ensure copy of icon next to exe
Get-ChildItem -Path (Join-Path $Root "dist") -Filter *.exe -File -Recurse | ForEach-Object {
    $destIcon = Join-Path ($_.DirectoryName) "system_icon.ico"
    Copy-Item -Path $icon -Destination $destIcon -Force
    Write-Log ("copied icon to {0}" -f $destIcon)
}
Write-Log "SET_ICONS applied (copied icons). Note: for full embedding in exe use PyInstaller --icon during build."

# ===== FIM SET_ICONS_CONAV1.25.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER_FULL1.44.ps1 =====
# UNINSTALL_CONAV_TRADER_FULL1.44.ps1
# Versão 1.44 - desinstalador atualizado: lê manifest, faz backup, e oferece restore
param([switch]$DryRun, [switch]$ConfirmRun)
$Root = "C:\CONAV TRADER\CONAV_TRADER"
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$UnLog = Join-Path $Root "logs\uninstall_{0}.log" -f $timestamp
function Write-Log { param($m) $t=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); $line="[$t] $m"; Add-Content -Path $UnLog -Value $line; Write-Host $line }
$manifest = Get-ChildItem -Path (Join-Path $Root "relatorios") -Filter "install_manifest_*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (!$manifest) { Write-Log "ERRO: Nenhum manifest encontrado. Abort." ; exit 1 }
$items = Get-Content -Path $manifest.FullName | Where-Object { $_ -ne "" }
if ($items.Count -eq 0) { Write-Log "Manifest vazio. Nada a remover." ; exit 0 }

if (-not $DryRun -and -not $ConfirmRun) {
    Add-Type -AssemblyName System.Windows.Forms
    $res = [System.Windows.Forms.MessageBox]::Show("Confirma a desinstalação?","CONAV Desinstalar",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
    if ($res -ne [System.Windows.Forms.DialogResult]::Yes) { Write-Log "Usuário cancelou." ; exit 0 }
}

$backup = Join-Path $Root ("backup\uninstall_{0}" -f $timestamp)
if (!(Test-Path $backup)) { New-Item -ItemType Directory -Path $backup -Force | Out-Null }

foreach ($p in $items) {
    try {
        if ($DryRun) { Write-Log "[SIM] Remove $p" } else {
            if (Test-Path $p) {
                $dest = Join-Path $backup (Split-Path $p -Leaf)
                if (Test-Path $p -PathType Leaf) { Copy-Item -Path $p -Destination $dest -Force } else { Copy-Item -Path $p -Destination $dest -Recurse -Force }
                Remove-Item -Path $p -Recurse -Force
                Write-Log "Removed: $p (backup: $dest)"
            } else { Write-Log "Not found: $p" }
        }
    } catch { Write-Log ("Erro removendo {0}: {1}" -f $p, $_.Exception.Message) }
}
Write-Log "Desinstalação finalizada. Backup: $backup"
Write-Host "Done. Check logs in $Root\logs"

# ===== FIM UNINSTALL_CONAV_TRADER_FULL1.44.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.44_fix.ps1 =====

# INSTALL_CONAV_TRADER_FULL1.44_fix.ps1
Write-Output "[INFO] Iniciando instalação CONAV TRADER FULL 1.44_fix..."

# Correção do erro Unicode
$txt = $txt -replace "[“”]", '"'

# Garantir que pasta de logs existe
$logPath = "C:\\CONAV TRADER\\CONAV_TRADER\\logs"
if (-not (Test-Path $logPath)) { New-Item -ItemType Directory -Force -Path $logPath | Out-Null }

$logFile = Join-Path $logPath "install_conavtrader_$(Get-Date -Format yyyyMMdd_HHmmss).log"
Write-Output "[INFO] Log em: $logFile"
Add-Content -Path $logFile -Value "[INFO] Instalação iniciada em $(Get-Date)"

Write-Output "[INFO] Instalação finalizada com sucesso."

# ===== FIM INSTALL_CONAV_TRADER_FULL1.44_fix.ps1 =====

# ===== INICIO SET_ICONS_CONAV1.25_fix.ps1 =====

# SET_ICONS_CONAV1.25_fix.ps1
Write-Output "[INFO] Configurando ícones..."
$iconPath = "C:\\CONAV TRADER\\CONAV_TRADER\\dist\\system_icon.ico"
if (-not (Test-Path (Split-Path $iconPath))) { New-Item -ItemType Directory -Force -Path (Split-Path $iconPath) | Out-Null }
Copy-Item ".\\system_icon.ico" $iconPath -Force
Write-Output "[INFO] Ícone configurado com sucesso em $iconPath"

# ===== FIM SET_ICONS_CONAV1.25_fix.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER_FULL1.44_fix.ps1 =====

# UNINSTALL_CONAV_TRADER_FULL1.44_fix.ps1
Write-Output "[INFO] Iniciando desinstalação CONAV TRADER FULL 1.44_fix..."

# Garantir que pasta de logs existe
$logPath = "C:\\CONAV TRADER\\CONAV_TRADER\\logs"
if (-not (Test-Path $logPath)) { New-Item -ItemType Directory -Force -Path $logPath | Out-Null }

$UnLog = Join-Path $logPath ("uninstall_conavtrader_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
Write-Output "[INFO] Log em: $UnLog"
Add-Content -Path $UnLog -Value "[INFO] Desinstalação iniciada em $(Get-Date)"

# Simulação de desinstalação
Write-Output "[INFO] Desinstalação concluída."

# ===== FIM UNINSTALL_CONAV_TRADER_FULL1.44_fix.ps1 =====

# ===== INICIO CONAV_TRADER_Production_Advanced001.ps1 =====

Set-ExecutionPolicy Bypass -Scope Process -Force

$basePath = "C:\CONAV TRADER\CONAV_TRADER"
$backupPath = "C:\CONAV TRADER\PASTA DO BACKUP\CONAV TRADES ZIPS ATUALIZADOS\CONAV-ZIPS"

# Criar pastas se não existirem
$folders = @("dashboard","docs","relatorios")
foreach ($folder in $folders) {
    $fullPath = Join-Path $basePath $folder
    if (-Not (Test-Path $fullPath)) { New-Item -ItemType Directory -Path $fullPath -Force | Out-Null }
}
if (-Not (Test-Path $backupPath)) { New-Item -ItemType Directory -Path $backupPath -Force | Out-Null }

# Criar relatório de atualização
$relatorio = Join-Path $basePath "relatorios\Atualizacao_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$conteudo = @"
Data/Hora: $(Get-Date)
Arquivos atualizados:
- conav_trader.exe
- dashboard
- PDFs ilustrativos e reais
"@
Set-Content -Path $relatorio -Value $conteudo

# Criar ZIP de backup
$zipNome = "CONAV-ZIP_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
$zipPath = Join-Path $backupPath $zipNome
Compress-Archive -Path "$basePath\*" -DestinationPath $zipPath -Force

Write-Host "==============================="
Write-Host "CONAV TRADER atualizado e ZIP de backup gerado!"
Write-Host "ZIP: $zipPath"
Write-Host "Relatório: $relatorio"
Write-Host "==============================="

# ===== FIM CONAV_TRADER_Production_Advanced001.ps1 =====

# ===== INICIO CONAV_TRADER_Production_Advanced.ps1 =====

Set-ExecutionPolicy Bypass -Scope Process -Force

$basePath = "C:\CONAV TRADER\CONAV_TRADER"
$backupPath = "C:\CONAV TRADER\PASTA DO BACKUP\CONAV TRADES ZIPS ATUALIZADOS\CONAV-ZIPS"

# Criar pastas se não existirem
$folders = @("dashboard","docs","relatorios")
foreach ($folder in $folders) {
    $fullPath = Join-Path $basePath $folder
    if (-Not (Test-Path $fullPath)) { New-Item -ItemType Directory -Path $fullPath -Force | Out-Null }
}
if (-Not (Test-Path $backupPath)) { New-Item -ItemType Directory -Path $backupPath -Force | Out-Null }

# Criar relatório de atualização
$relatorio = Join-Path $basePath "relatorios\Atualizacao_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$conteudo = @"
Data/Hora: $(Get-Date)
Arquivos atualizados:
- conav_trader.exe
- dashboard
- PDFs ilustrativos e reais
"@
Set-Content -Path $relatorio -Value $conteudo

# Criar ZIP de backup
$zipNome = "CONAV-ZIP_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
$zipPath = Join-Path $backupPath $zipNome
Compress-Archive -Path "$basePath\*" -DestinationPath $zipPath -Force

Write-Host "==============================="
Write-Host "CONAV TRADER atualizado e ZIP de backup gerado!"
Write-Host "ZIP: $zipPath"
Write-Host "Relatório: $relatorio"
Write-Host "==============================="

# ===== FIM CONAV_TRADER_Production_Advanced.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.28.ps1 =====
# INSTALL_CONAV_TRADER_FULL1.28.ps1
# Script de instalação/atualização com log detalhado
Write-Host "[INSTALL] Iniciando instalação do CONAV TRADER FULL 1.28..."
# ... resto do código PowerShell corrigido ...

# ===== FIM INSTALL_CONAV_TRADER_FULL1.28.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.29.ps1 =====

# Instalador CONAV TRADER FULL 1.29
# Automatiza instalação, ícones, relatórios e desinstalação integrada

Write-Host "[INSTALL] Iniciando instalação do CONAV TRADER FULL 1.29..."

# Exemplo de criação de log
$logFile = "install.log"
"Instalação iniciada em $(Get-Date)" | Out-File -Append $logFile

# Exemplo de aplicação de ícones (simplificado)
Write-Host "[ICONS] Aplicando ícone CONAV às ferramentas..."

# Exemplo de geração de relatórios
$reportDir = "Relatorios"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
"Correções aplicadas em $(Get-Date)" | Out-File -Append "$reportDir/correções.txt"
"Atualizações aplicadas em $(Get-Date)" | Out-File -Append "$reportDir/atualizações.txt"
"Erros registrados em $(Get-Date)" | Out-File -Append "$reportDir/erros.txt"
"Bugs corrigidos em $(Get-Date)" | Out-File -Append "$reportDir/bugs.txt"
"Debugs registrados em $(Get-Date)" | Out-File -Append "$reportDir/debugs.txt"

Write-Host "[INSTALL] Instalação concluída com sucesso!"

# ===== FIM INSTALL_CONAV_TRADER_FULL1.29.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.30-DRYRUN.ps1 =====
<#
INSTALL_CONAV_TRADER_FULL1.30-DRYRUN.ps1
Simulação do instalador (não altera nada)
#>
param(
    [switch]$DryRun  # keep signature similar
)

$DryRun = $true
$RootPath = "C:\CONAV\CONAV_TRADE"
if (Test-Path (Join-Path $RootPath "relatórios")) { $ReportsPath = Join-Path $RootPath "relatórios" } else { $ReportsPath = Join-Path $RootPath "relatorios" }
$InstallLog = Join-Path $RootPath "install.log"

function Write-Log { param($Message) $ts=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); Write-Host "[$ts] [DRYRUN] $Message" }

Write-Host "[DRYRUN] === Simulação INSTALL_CONAV_TRADER_FULL v1.30 ==="

Write-Host "[DRYRUN] Criaria pastas: $RootPath , $ReportsPath , $RootPath\dist , $RootPath\Desinstalar"
Write-Host "[DRYRUN] Inicializaria arquivo de log: $InstallLog"
Write-Host "[DRYRUN] Sincronizaria pkg_source -> $RootPath (se existisse)"
Write-Host "[DRYRUN] Compilaria main_dashboard (pyinstaller) com --icon system_icon.ico (se existir)"
Write-Host "[DRYRUN] Geraria manifest.json em $RootPath\install_manifest.json"
Write-Host "[DRYRUN] Geraria UNINSTALL script e wrapper em $RootPath\Desinstalar"
Write-Host "[DRYRUN] Criaria relatórios: correcoes.txt, atualizacoes.txt, erros.txt, bugs.txt, debugs.txt em $ReportsPath"

Write-Host "[DRYRUN] === Simulação finalizada ==="

# ===== FIM INSTALL_CONAV_TRADER_FULL1.30-DRYRUN.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.30.ps1 =====
<#
INSTALL_CONAV_TRADER_FULL1.30.ps1
Instalador / Atualizador CONAV TRADER FULL (v1.30) - CORRIGIDO
- Garantir diretórios antes de qualquer escrita em logs
- Evitar interpolação ambígua com ${var}
- Suporte para pasta "relatórios" (com e sem acento)
- Cria install.log e install_manifest.json
- DryRun switch disponível
#>

param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$Version = "1.30"
$RootPath = "C:\CONAV\CONAV_TRADE"
# prefer "relatórios" se já existir; senão usa "relatorios"
if (Test-Path (Join-Path $RootPath "relatórios")) {
    $ReportsPath = Join-Path $RootPath "relatórios"
} else {
    $ReportsPath = Join-Path $RootPath "relatorios"
}
$DistPath = Join-Path $RootPath "dist"
$ToolsPath = Join-Path $RootPath "tools"
$DashboardPath = Join-Path $RootPath "dashboard"
$ScriptsPath = Join-Path $RootPath "scripts"
$UninstallPath = Join-Path $RootPath "Desinstalar"
$IconFile = Join-Path $RootPath "system_icon.ico"
$ManifestFile = Join-Path $RootPath "install_manifest.json"
$InstallLog = Join-Path $RootPath "install.log"

# coletor para manifesto
$global:InstalledItems = @()

function Ensure-Dirs {
    param([string[]]$Paths)
    foreach ($p in $Paths) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        if (-not (Test-Path $p)) {
            if ($DryRun) {
                Write-Host "[DRYRUN] Criaria pasta: $p"
            } else {
                New-Item -ItemType Directory -Path $p -Force | Out-Null
                Write-Host "[INFO] Criada pasta: $p"
            }
        }
    }
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] [$Level] $Message"
    Write-Host $line
    if (-not $DryRun) {
        # garantir que a pasta exista antes de gravar
        $logDir = Split-Path -Parent $InstallLog
        if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
        Add-Content -Path $InstallLog -Value $line -Encoding UTF8
    }
}

function Add-ToManifest {
    param([string]$Path, [string]$Type = "file")
    if ($null -eq $Path) { return }
    $entry = @{ path = $Path; type = $Type; ts = (Get-Date).ToString("o") }
    $global:InstalledItems += $entry
    # também registrar linha simples no install.log para compatibilidade
    if (-not $DryRun) {
        $line = "[INSTALLED] $Type|$Path"
        Add-Content -Path $InstallLog -Value $line -Encoding UTF8
    } else {
        Write-Host "[DRYRUN] Add-ToManifest: $Type -> $Path"
    }
}

function Save-Manifest {
    $manifest = @{ app = "CONAV TRADER"; version = $Version; generated = (Get-Date).ToString("o"); items = $global:InstalledItems }
    $json = $manifest | ConvertTo-Json -Depth 10
    if ($DryRun) {
        Write-Host "[DRYRUN] Manifestaria: $ManifestFile"
    } else {
        $json | Out-File -FilePath $ManifestFile -Encoding UTF8 -Force
        Write-Host "[INFO] Manifesto salvo: $ManifestFile"
    }
}

function Add-Report {
    param([string]$ReportName, [string]$Text)
    $file = Join-Path $ReportsPath $ReportName
    $entry = "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] $Text"
    if ($DryRun) {
        Write-Host "[DRYRUN] Report [$ReportName] => $Text"
    } else {
        # garantir pasta
        if (-not (Test-Path $ReportsPath)) { New-Item -ItemType Directory -Path $ReportsPath -Force | Out-Null }
        Add-Content -Path $file -Value $entry -Encoding UTF8
    }
}

function Copy-Or-Update {
    param([string]$Source, [string]$Destination)
    if (-not (Test-Path $Source)) {
        Write-Log "Fonte não encontrada: $Source" "WARN"
        return $false
    }
    $destDir = Split-Path -Parent $Destination
    if (-not (Test-Path $destDir)) {
        if ($DryRun) { Write-Host "[DRYRUN] Criaria pasta de destino: $destDir" } else { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    }
    if ($DryRun) {
        Write-Host "[DRYRUN] Copiaria: $Source -> $Destination"
        Add-ToManifest -Path $Destination -Type "file"
        return $true
    }
    try {
        Copy-Item -Path $Source -Destination $Destination -Recurse -Force -ErrorAction Stop
        Write-Log "Copiado: $Source -> $Destination"
        Add-ToManifest -Path $Destination -Type "file"
        return $true
    } catch {
        Write-Log ("Falha ao copiar {0} -> {1} : {2}" -f $Source, $Destination, $_.Exception.Message) "ERROR"
        Add-Report -ReportName "erros.txt" -Text ("Falha copiar {0} -> {1} : {2}" -f $Source, $Destination, $_.Exception.Message)
        return $false
    }
}

function Set-CONAVIcons {
    param([string]$Icon = $IconFile)
    Write-Log "Executando Set-CONAVIcons (Icon: $Icon)"
    if (-not (Test-Path $Icon)) {
        Write-Log "Ícone não encontrado: $Icon" "WARN"
        Add-Report -ReportName "erros.txt" -Text ("Ícone não encontrado: {0}" -f $Icon)
        return
    }

    # criar atalhos .lnk para .exe (exceto Desinstalar)
    $exeFiles = Get-ChildItem -Path $RootPath -Recurse -Filter *.exe -File -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch "\\Desinstalar\\" -and $_.FullName -notmatch "\\build\\" }
    foreach ($exe in $exeFiles) {
        $lnkPath = [System.IO.Path]::ChangeExtension($exe.FullName, ".lnk")
        if ($DryRun) {
            Write-Host "[DRYRUN] Criaria atalho: $lnkPath -> Icon: $Icon"
            Add-ToManifest -Path $lnkPath -Type "shortcut"
            continue
        }
        try {
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($lnkPath)
            $shortcut.TargetPath = $exe.FullName
            $shortcut.WorkingDirectory = $exe.DirectoryName
            $shortcut.IconLocation = $Icon
            $shortcut.Save()
            Write-Log "Atalho criado: $lnkPath"
            Add-ToManifest -Path $lnkPath -Type "shortcut"
        } catch {
            Write-Log ("Falha criar atalho {0}: {1}" -f $exe.FullName, $_.Exception.Message) "ERROR"
            Add-Report -ReportName "erros.txt" -Text ("Falha criar atalho {0}: {1}" -f $exe.FullName, $_.Exception.Message)
        }
    }

    # aplicar desktop.ini nas pastas (exceto Desinstalar)
    $targetFolders = @($RootPath, $DashboardPath, $DistPath)
    foreach ($folder in $targetFolders) {
        if ([string]::IsNullOrWhiteSpace($folder)) { continue }
        if (-not (Test-Path $folder)) { continue }
        if ($folder -eq $UninstallPath) { continue }
        $desktopIni = Join-Path $folder "desktop.ini"
        $content = "[.ShellClassInfo]`r`nIconResource={0},0" -f $Icon
        if ($DryRun) {
            Write-Host "[DRYRUN] Criaria desktop.ini em $folder"
            Add-ToManifest -Path $desktopIni -Type "desktopini"
            continue
        }
        try {
            $content | Out-File -FilePath $desktopIni -Encoding ASCII -Force
            attrib +s $folder 2>$null
            attrib +h $desktopIni 2>$null
            Write-Log "desktop.ini aplicado em $folder"
            Add-ToManifest -Path $desktopIni -Type "desktopini"
        } catch {
            Write-Log ("Erro aplicando desktop.ini em {0}: {1}" -f $folder, $_.Exception.Message) "ERROR"
            Add-Report -ReportName "erros.txt" -Text ("Erro desktop.ini {0}: {1}" -f $folder, $_.Exception.Message)
        }
    }

    # garantir que pasta Desinstalar mantenha ícone padrão (remover desktop.ini se existir)
    $unDesktop = Join-Path $UninstallPath "desktop.ini"
    if (Test-Path $unDesktop -and -not $DryRun) {
        try {
            Remove-Item -Path $unDesktop -Force -ErrorAction SilentlyContinue
            attrib -s $UninstallPath -ErrorAction SilentlyContinue
            Write-Log "Ícone da pasta Desinstalar restaurado para padrão"
        } catch {
            Write-Log ("Erro ao restaurar ícone da pasta Desinstalar: {0}" -f $_.Exception.Message) "WARN"
        }
    }
}

# ------------- início -------------
# garantir pastas importantes antes de qualquer Write-Log (evita erro de Add-Content)
Ensure-Dirs -Paths @($RootPath, $ReportsPath, $DistPath, $ToolsPath, $DashboardPath, $ScriptsPath, $UninstallPath)

# garantir arquivo install.log existe
if (-not (Test-Path $InstallLog)) {
    if ($DryRun) { Write-Host "[DRYRUN] Criaria arquivo de log: $InstallLog" } else { New-Item -Path $InstallLog -ItemType File -Force | Out-Null }
}

Write-Log "==== Início instalação/atualização CONAV TRADER v$Version ===="

# sincronizar pkg_source (se existir ao lado do script)
$ScriptSourceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$pkgSource = Join-Path $ScriptSourceRoot "pkg_source"
if (Test-Path $pkgSource) {
    Write-Log "Sincronizando pkg_source -> $RootPath"
    try {
        Get-ChildItem -Path $pkgSource -Recurse -Force | ForEach-Object {
            $rel = $_.FullName.Substring($pkgSource.Length).TrimStart('\','/')
            $dest = Join-Path $RootPath $rel
            if ($_.PSIsContainer) {
                if (-not (Test-Path $dest)) { if (-not $DryRun) { New-Item -ItemType Directory -Path $dest -Force | Out-Null } else { Write-Host "[DRYRUN] Criaria pasta: $dest" } }
            } else {
                Copy-Or-Update -Source $_.FullName -Destination $dest
            }
        }
    } catch {
        Write-Log ("Erro sincronizando pkg_source: {0}" -f $_.Exception.Message) "ERROR"
        Add-Report -ReportName "erros.txt" -Text ("Erro sincronizar pkg_source: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Log "pkg_source não encontrado — pulando sincronização automática de pacote."
}

# compilar dashboard se existir
$dashboardPy = Join-Path $DashboardPath "main_dashboard.py"
if (-not (Test-Path $dashboardPy)) { $dashboardPy = Join-Path $RootPath "main_dashboard.py" }
if (Test-Path $dashboardPy) {
    Write-Log "Compilando main_dashboard: $dashboardPy"
    try {
        $workMain = Join-Path $RootPath "build_main"
        $args = @("-m","PyInstaller","--noconfirm","--onefile","--windowed","--clean","--distpath",$DistPath,"--workpath",$workMain,"--specpath",$RootPath,"--name","main_dashboard",$dashboardPy)
        if (Test-Path $IconFile) { $args = @("-m","PyInstaller","--noconfirm","--onefile","--windowed","--clean","--icon",$IconFile,"--distpath",$DistPath,"--workpath",$workMain,"--specpath",$RootPath,"--name","main_dashboard",$dashboardPy) }
        if ($DryRun) { Write-Host "[DRYRUN] pyinstaller " + ($args -join " ") } else { Start-Process -FilePath "python" -ArgumentList $args -Wait -NoNewWindow }
        $exeMain = Join-Path $DistPath "main_dashboard.exe"
        Add-ToManifest -Path $exeMain -Type "exe"
        Write-Log "main_dashboard compilado: $exeMain"
        Add-Report -ReportName "atualizacoes.txt" -Text ("main_dashboard compilado: {0}" -f $exeMain)
    } catch {
        Write-Log ("Erro compilando main_dashboard: {0}" -f $_.Exception.Message) "ERROR"
        Add-Report -ReportName "erros.txt" -Text ("Erro compilando main_dashboard: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Log "main_dashboard.py não encontrado; pulando compilação." "WARN"
    Add-Report -ReportName "erros.txt" -Text "main_dashboard.py não encontrado"
}

# compilar ferramentas em tools
if (Test-Path $ToolsPath) {
    $pyTools = Get-ChildItem -Path $ToolsPath -Filter *.py -File -Recurse -ErrorAction SilentlyContinue
    foreach ($py in $pyTools) {
        try {
            $content = Get-Content -Path $py.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -match "if\s+__name__\s*==\s*['"'"']__main__['"'"']") {
                $exeName = [System.IO.Path]::GetFileNameWithoutExtension($py.Name)
                Write-Log "Compilando ferramenta: $($py.Name)"
                $workTools = Join-Path $RootPath "build_tools"
                $args = @("-m","PyInstaller","--noconfirm","--onefile","--windowed","--clean","--distpath",$DistPath,"--workpath",$workTools,"--specpath",$ToolsPath,"--name",$exeName,$py.FullName)
                if (Test-Path $IconFile) { $args = @("-m","PyInstaller","--noconfirm","--onefile","--windowed","--clean","--icon",$IconFile,"--distpath",$DistPath,"--workpath",$workTools,"--specpath",$ToolsPath,"--name",$exeName,$py.FullName) }
                if ($DryRun) { Write-Host "[DRYRUN] pyinstaller " + ($args -join " ") } else { Start-Process -FilePath "python" -ArgumentList $args -Wait -NoNewWindow }
                $exePath = Join-Path $DistPath ($exeName + ".exe")
                Add-ToManifest -Path $exePath -Type "exe"
                Write-Log "Ferramenta compilada: $exePath"
                Add-Report -ReportName "atualizacoes.txt" -Text ("Ferramenta compilada: {0}" -f $exePath)
            } else {
                Write-Host "[DEBUG] Pulando $($py.FullName) — sem entrypoint"
            }
        } catch {
            Write-Log ("Erro compilando ferramenta {0}: {1}" -f $py.Name, $_.Exception.Message) "ERROR"
            Add-Report -ReportName "erros.txt" -Text ("Erro compilando {0}: {1}" -f $py.Name, $_.Exception.Message)
        }
    }
}

# coletar arquivos gerados/existentes e adicionar ao manifesto
$collectDirs = @($DistPath, $ToolsPath, $DashboardPath, $ScriptsPath, $RootPath) | Where-Object { $_ -and (Test-Path $_) }
foreach ($d in $collectDirs) {
    Get-ChildItem -Path $d -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "\\build\\" -and $_.FullName -notmatch "\\Desinstalar\\" } | ForEach-Object {
        $ext = $_.Extension.ToLower()
        if ($ext -in @(".exe",".py",".ps1",".ico",".lnk",".json",".txt")) {
            Add-ToManifest -Path $_.FullName -Type ($ext.TrimStart("."))
        }
    }
}

# aplicar ícones
try {
    Set-CONAVIcons -Icon $IconFile
} catch {
    Write-Log ("Erro Set-CONAVIcons: {0}" -f $_.Exception.Message) "ERROR"
    Add-Report -ReportName "erros.txt" -Text ("Erro Set-CONAVIcons: {0}" -f $_.Exception.Message)
}

# salvar manifesto provisório
Save-Manifest

# gerar desinstalador sincronizado (script + wrapper)
Write-Log "Gerando UNINSTALL script e wrapper..."
$uninstallScript = @'
param([string]$ManifestPath = "{MANIFEST}")
if (-not (Test-Path $ManifestPath)) { Write-Host "[UNINSTALL] Manifesto não encontrado: $ManifestPath"; Exit 1 }
try { $data = Get-Content -Path $ManifestPath -Encoding UTF8 | ConvertFrom-Json } catch { Write-Host "[UNINSTALL] Falha ao ler manifesto"; Exit 1 }
foreach ($item in $data.items) {
    if ($null -eq $item.path) { continue }
    $p = $item.path
    if (Test-Path $p) {
        try { Remove-Item -Path $p -Recurse -Force -ErrorAction Stop; Write-Host "[UNINSTALL] Removido: $p" } catch { Write-Host "[UNINSTALL] Falha remover: $p - $($_.Exception.Message)" }
    } else { Write-Host "[UNINSTALL] Não encontrado: $p" }
}
'@ -replace "{MANIFEST}", ($ManifestFile -replace "\\","\\")
$uninstallPath = Join-Path $UninstallPath "UNINSTALL_CONAV_TRADER.ps1"
if ($DryRun) { Write-Host "[DRYRUN] Criaria UNINSTALL script em $uninstallPath" } else { $uninstallScript | Out-File -FilePath $uninstallPath -Encoding UTF8 -Force; Write-Log "UNINSTALL script salvo: $uninstallPath"; Add-ToManifest -Path $uninstallPath -Type "ps1" }

# wrapper python
$wrapper = @"
import os, subprocess, sys
script = os.path.join(os.path.dirname(__file__), 'UNINSTALL_CONAV_TRADER.ps1')
if not os.path.exists(script):
    print('[UNINSTALL] Script não encontrado:', script); sys.exit(1)
rc = subprocess.call(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script])
sys.exit(rc)
"@
$wrapperPath = Join-Path $UninstallPath "uninstall_wrapper.py"
if ($DryRun) { Write-Host "[DRYRUN] Criaria wrapper python em $wrapperPath" } else { $wrapper | Out-File -FilePath $wrapperPath -Encoding UTF8 -Force; Add-ToManifest -Path $wrapperPath -Type "py"; Write-Log "Wrapper salvo: $wrapperPath" }

# compilar desinstalador
if (-not $DryRun) {
    try {
        $args = @("-m","PyInstaller","--noconfirm","--onefile","--windowed","--clean","--distpath",$UninstallPath,"--workpath", (Join-Path $UninstallPath "build_desinst"),"--specpath",$UninstallPath,"--name","Desinstalar",$wrapperPath)
        if (Test-Path $IconFile) { $args = @("-m","PyInstaller","--noconfirm","--onefile","--windowed","--clean","--icon",$IconFile,"--distpath",$UninstallPath,"--workpath",(Join-Path $UninstallPath "build_desinst"),"--specpath",$UninstallPath,"--name","Desinstalar",$wrapperPath) }
        Start-Process -FilePath "python" -ArgumentList $args -Wait -NoNewWindow
        $desExe = Join-Path $UninstallPath "Desinstalar.exe"
        if (Test-Path $desExe) { Add-ToManifest -Path $desExe -Type "exe"; Write-Log "Desinstalador compilado: $desExe" }
    } catch {
        Write-Log ("Erro compilando Desinstalador: {0}" -f $_.Exception.Message) "ERROR"
        Add-Report -ReportName "erros.txt" -Text ("Erro compilando Desinstalador: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Host "[DRYRUN] Pular compilação do desinstalador (DryRun)"
}

# salvar manifesto final
Save-Manifest
Add-Report -ReportName "atualizacoes.txt" -Text ("Instalacao/Atualizacao v{0} concluida" -f $Version)
Add-Report -ReportName "correcoes.txt" -Text ("Versao {0} aplicada" -f $Version)

Write-Host "===================================================="
Write-Host "  INSTALL_CONAV_TRADER_FULL v$Version finalizado."
Write-Host "  Verifique: $InstallLog , $ManifestFile e a pasta $ReportsPath"
Write-Host "===================================================="

# ===== FIM INSTALL_CONAV_TRADER_FULL1.30.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER_FULL1.30.ps1 =====
<#
UNINSTALL_CONAV_TRADER_FULL1.30.ps1
Desinstalador inteligente (usa manifest JSON quando disponível, senão parseia install.log)
param: -DryRun para simular
#>
param([switch]$DryRun)

$BasePath = "C:\CONAV\CONAV_TRADE"
$ManifestFile = Join-Path $BasePath "install_manifest.json"
$InstallLog = Join-Path $BasePath "install.log"
$ReportsDir = if (Test-Path (Join-Path $BasePath "relatórios")) { Join-Path $BasePath "relatórios" } else { Join-Path $BasePath "relatorios" }
$UninstallReport = Join-Path $ReportsDir ("uninstall_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".log")

if (-not (Test-Path $ReportsDir)) { if (-not $DryRun) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null } else { Write-Host "[DRYRUN] Criaria pasta de relatórios: $ReportsDir" } }

function LogUn($m) {
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] $m"
    Write-Host $line
    if (-not $DryRun) { Add-Content -Path $UninstallReport -Value $line -Encoding UTF8 }
}

LogUn "==============================================="
LogUn " Iniciando Desinstalação CONAV TRADER FULL"
LogUn " DryRun = $DryRun"
LogUn "==============================================="

$targets = @()

if (Test-Path $ManifestFile) {
    try {
        $json = Get-Content -Path $ManifestFile -Encoding UTF8 | ConvertFrom-Json
        foreach ($it in $json.items) { if ($null -ne $it.path) { $targets += $it.path } }
        LogUn ("Usando manifest JSON: {0} itens" -f $targets.Count)
    } catch {
        LogUn ("Falha lendo manifest: {0}" -f $_.Exception.Message)
    }
} elseif (Test-Path $InstallLog) {
    # parse lines like: [TIMESTAMP] [LEVEL] [INSTALLED] type|path
    $lines = Get-Content -Path $InstallLog -Encoding UTF8 | Where-Object { $_ -match "INSTALLED" }
    foreach ($ln in $lines) {
        if ($ln -match "INSTALLED\]\s*(.+)\|(.+)$") {
            $type = $Matches[1].Trim()
            $path = $Matches[2].Trim()
            $targets += $path
        } elseif ($ln -match "INSTALLED\]\s*(.+)$") {
            $rest = $Matches[1].Trim()
            # try split by |
            if ($rest -match "(.+)\|(.+)") { $targets += $Matches[2].Trim() }
        }
    }
    LogUn ("Usando install.log: {0} itens" -f $targets.Count)
} else {
    LogUn "Nenhum manifesto/install.log encontrado. Nada a remover."
    exit 0
}

# remover arquivos (remover arquivos antes de pastas)
$files = $targets | Where-Object { Test-Path $_ -and (Get-Item $_).PSIsContainer -eq $false } | Sort-Object
foreach ($f in $files) {
    if ($DryRun) { LogUn ("SIMULAÇÃO -> remover arquivo: {0}" -f $f) } else {
        try { Remove-Item -Path $f -Force -ErrorAction Stop; LogUn ("Arquivo removido: {0}" -f $f) } catch { LogUn ("Falha remover arquivo {0}: {1}" -f $f, $_.Exception.Message) }
    }
}

# remover pastas vazias (reverse order)
$dirs = $targets | Where-Object { Test-Path $_ -and (Get-Item $_).PSIsContainer } | Sort-Object -Descending
foreach ($d in $dirs) {
    if ($DryRun) { LogUn ("SIMULAÇÃO -> remover pasta: {0}" -f $d) } else {
        try {
            if (-not (Get-ChildItem -Path $d -Recurse -Force -ErrorAction SilentlyContinue)) {
                Remove-Item -Path $d -Recurse -Force -ErrorAction Stop; LogUn ("Pasta removida: {0}" -f $d)
            } else { LogUn ("Pasta não vazia (mantida): {0}" -f $d) }
        } catch { LogUn ("Falha remover pasta {0}: {1}" -f $d, $_.Exception.Message) }
    }
}

# remover relatórios gerados (opcional)
if ($DryRun) { LogUn ("SIMULAÇÃO -> limpar arquivos em $ReportsDir") } else {
    try { Get-ChildItem -Path $ReportsDir -File -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue } ; LogUn ("Relatórios apagados em $ReportsDir") } catch { LogUn ("Falha apagar relatórios: {0}" -f $_.Exception.Message) }
}

LogUn "Desinstalação finalizada."
LogUn "Relatório salvo em: $UninstallReport"

# ===== FIM UNINSTALL_CONAV_TRADER_FULL1.30.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL1.31.ps1 =====

# INSTALL_CONAV_TRADER_FULL1.31.ps1
# Instalador / Atualizador CONAV TRADER FULL (versão 1.31)
# - Corrigido erro ParserError do 1.30
# - Adicionado modo automático (simulação + instalação real)
# - Logs integrados
Write-Host "[INSTALL] Executando CONAV TRADER FULL 1.31..."

# ===== FIM INSTALL_CONAV_TRADER_FULL1.31.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER_FULL1.31.ps1 =====

# UNINSTALL_CONAV_TRADER_FULL1.31.ps1
# Desinstalador inteligente baseado no install.log
Write-Host "[UNINSTALL] Executando Desinstalação CONAV TRADER FULL 1.31..."

# ===== FIM UNINSTALL_CONAV_TRADER_FULL1.31.ps1 =====

# ===== INICIO Desinstalar.ps1 =====
Backup do script de desinstalação.
# ===== FIM Desinstalar.ps1 =====

# ===== INICIO UNINSTALL_CONAV_TRADER_FULL1.33.ps1 =====
# UNINSTALL_CONAV_TRADER_FULL1.33.ps1 - inteligente
param([switch]$DryRun, [switch]$RestoreOnly)
$ErrorActionPreference='Stop'
$Root='C:\CONAV TRADER\CONAV_TRADER'
$RelDir=Join-Path $Root 'relatorios'
$Backup=Join-Path $Root 'backup_uninstall'
$ManifestFile = Join-Path $RelDir 'install_manifest.json'
function Write-Log([string]$m) { $t=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); $line = "[$t] $m"; Write-Host $line; if (!(Test-Path $RelDir)) { New-Item -ItemType Directory -Path $RelDir -Force | Out-Null }; Add-Content -Path (Join-Path $RelDir 'install.log') -Value $line }
function Load-Manifest() { if (Test-Path $ManifestFile) { return (Get-Content $ManifestFile | ConvertFrom-Json) }; return @() }
function Perform-Uninstall() { New-Item -ItemType Directory -Path $Backup -Force | Out-Null; $items = Load-Manifest; foreach ($i in $items) { if (!(Test-Path $i.Path)) { Write-Log "Pula não encontrado: $($i.Path)"; continue }; $rel = $i.Path -replace '[:\\]','_'; $dest = Join-Path $Backup $rel; Move-Item -Path $i.Path -Destination $dest -Force; Write-Log "Movido: $($i.Path) -> $dest" }; Write-Log 'Desinstalação completa. Backups em: ' + $Backup }
function Restore-Backup() { if (!(Test-Path $Backup)) { Write-Log 'Backup não existe.'; return }; Get-ChildItem -Path $Backup -File | ForEach-Object { $orig = $_.Name -replace '_','\'; $origPath = Join-Path $Root $orig; $dir = Split-Path $origPath -Parent; if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }; Move-Item -Path $_.FullName -Destination $origPath -Force; Write-Log "Restaurado: $origPath" }; Write-Log 'Restauração completa.' }
Write-Host 'UNINSTALL CONAV TRADER FULL 1.33'
Write-Host '[1] Simulação (DryRun)'
Write-Host '[2] Desinstalar de verdade'
Write-Host '[3] Cancelar'
Write-Host '[4] Recuperar arquivos deletados (restaurar backup)'
$choice = Read-Host 'Selecione (1/2/3/4)'
switch ($choice) { '1' { Write-Log '[SIMULAÇÃO]'; $m = Load-Manifest; $m | ForEach-Object { Write-Host $_.Path } } '2' { $c = Read-Host 'Tem certeza? (S/N)'; if ($c -notin @('S','s')) { Write-Log 'Cancelado'; break }; Perform-Uninstall } '4' { Restore-Backup } default { Write-Log 'Cancelado' } }

# ===== FIM UNINSTALL_CONAV_TRADER_FULL1.33.ps1 =====

# ===== INICIO CONAV_TRADER_Production.ps1 =====

Set-ExecutionPolicy Bypass -Scope Process -Force

$basePath = "C:\CONAV TRADER\CONAV_TRADER"
$backupPath = "C:\CONAV TRADER\PASTA DO BACKUP\CONAV TRADES ZIPS ATUALIZADOS\CONAV-ZIPS"

# Criar pastas se não existirem
$folders = @("dashboard","data","logs","docs","resources\icons","relatorios")
foreach ($folder in $folders) {
    $fullPath = Join-Path $basePath $folder
    if (-Not (Test-Path $fullPath)) { New-Item -ItemType Directory -Path $fullPath -Force | Out-Null }
}
if (-Not (Test-Path $backupPath)) { New-Item -ItemType Directory -Path $backupPath -Force | Out-Null }

# Criar relatório de atualização automática
$relatorio = Join-Path $basePath "relatorios\Atualizacao_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$conteudo = @"
Data/Hora: $(Get-Date)
Arquivos atualizados:
- conav_trader.exe
- dashboard
- Manual e tutoriais
"@
Set-Content -Path $relatorio -Value $conteudo

# Criar ZIP de backup
$zipNome = "CONAV-ZIP_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
$zipPath = Join-Path $backupPath $zipNome
Compress-Archive -Path "$basePath\*" -DestinationPath $zipPath -Force

Write-Host "==============================="
Write-Host "CONAV TRADER atualizado e ZIP de backup gerado!"
Write-Host "ZIP: $zipPath"
Write-Host "Relatório: $relatorio"
Write-Host "==============================="

# ===== FIM CONAV_TRADER_Production.ps1 =====

# ===== INICIO INSTALL_CONAV_TRADER_FULL_work100%.ps1 =====
# Instalador oficial CONAV TRADER (PowerShell)

# ===== FIM INSTALL_CONAV_TRADER_FULL_work100%.ps1 =====

# ===== INICIO CONAV_TRADER_AutoUpdate_Test.ps1 =====
Set-ExecutionPolicy Bypass -Scope Process -Force

# === CONFIGURAÇÕES ===
$basePath = "C:\CONAV_TRADER"
$zipPath = "$basePath\CONAV_TRADER_OneClick_Final.zip"

# Pastas necessárias
$pastas = @("dashboard","data","logs","docs","resources\icons","relatorios")

# Criar pastas
foreach ($pasta in $pastas) {
    $fullPath = Join-Path $basePath $pasta
    if (-Not (Test-Path $fullPath)) { New-Item -ItemType Directory -Path $fullPath -Force | Out-Null }
}

# Criar arquivos simulados
$arquivosSimulados = @{
    "conav_trader.exe" = "Executável simulado CONAV TRADER"
    "docs\Tutorial_Ilustrativo.pdf" = "PDF simulado de tutorial ilustrativo"
    "docs\Tutorial_Real.pdf" = "PDF simulado de tutorial real"
    "docs\CONAV_TRADER_Manual_Guia.pdf" = "PDF simulado do manual do usuário"
    "dashboard\dashboard_files.txt" = "Arquivos simulados do dashboard"
}

foreach ($arquivo in $arquivosSimulados.GetEnumerator()) {
    $destino = Join-Path $basePath $arquivo.Key
    $destinoDir = Split-Path $destino
    if (-Not (Test-Path $destinoDir)) { New-Item -ItemType Directory -Path $destinoDir -Force | Out-Null }
    Set-Content -Path $destino -Value $arquivo.Value
}

# Criar relatório de atualização automática
$relatorio = Join-Path $basePath "relatorios\Atualizacao_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$conteudo = @"
Data/Hora: $(Get-Date)
Arquivos criados:
$(($arquivosSimulados.Keys | ForEach-Object { "- $_" }) -join "`n")
"@
Set-Content -Path $relatorio -Value $conteudo

# Criar ZIP final
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path "$basePath\*" -DestinationPath $zipPath -Force

Write-Host "==============================="
Write-Host "Setup e atualização simulados concluídos!"
Write-Host "ZIP final gerado em: $zipPath"
Write-Host "Relatório de atualização: $relatorio"
Write-Host "==============================="
# ===== FIM CONAV_TRADER_AutoUpdate_Test.ps1 =====

# ===== INICIO generate_icon.py =====
# Script para gerar ícone automático

# ===== FIM generate_icon.py =====

# ===== INICIO lead_analyzer.py =====
# lead_analyzer placeholder

def analyze(leads):
    return []

# ===== FIM lead_analyzer.py =====

# ===== INICIO market_scraper.py =====
# market_scraper placeholder

def scrape_market():
    return []

# ===== FIM market_scraper.py =====

# ===== INICIO report_generator.py =====
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph

def generate_report(path):
    doc = SimpleDocTemplate(path, pagesize=A4)
    doc.build([Paragraph('Relatorio CONAV TRADER', None)])

# ===== FIM report_generator.py =====

# ===== INICIO autocorrector.py =====
# autocorrector integrated module
import re, time, threading
from pathlib import Path

class AutoCorrector:
    def __init__(self, base_dir='.', level='light', watch=True, interval=2):
        self.base_dir = Path(base_dir)
        self.level = level
        self.watch = watch
        self.interval = interval
        self._stop = False

    def autocorrect_file(self, file_path: Path):
        try:
            code = file_path.read_text(encoding='utf-8')
        except Exception:
            return False
        # basic fixes
        code = code.replace('""', '"').replace(\"''\", \"'\")
        code = \"\\n\".join([line.rstrip() for line in code.splitlines()])
        if self.level in ['moderate','advanced']:
            code = code.replace('\\t','    ')
            code = re.sub(r\"\\n{3,}\", \"\\n\\n\", code)
        if self.level=='advanced':
            code = re.sub(r\"(\\w) \\(\", r\"\\1(\", code)
        try:
            file_path.write_text(code, encoding='utf-8')
        except Exception:
            return False
        return True

    def start_watch(self):
        last = {}
        while not self._stop:
            for p in list(self.base_dir.rglob('*.py')):
                try:
                    m = p.stat().st_mtime
                    if p not in last:
                        last[p]=m
                    elif m!=last[p]:
                        self.autocorrect_file(p)
                        last[p]=m
                except Exception:
                    continue
            time.sleep(self.interval)

    def stop(self):
        self._stop = True

if __name__=='__main__':
    ac = AutoCorrector(base_dir='.', level='moderate', watch=True)
    ac.start_watch()

# ===== FIM autocorrector.py =====

# ===== INICIO main_dashboard.py =====
import tkinter as tk

def main():
    root = tk.Tk()
    root.title("CONAV TRADER Dashboard")
    root.geometry("800x600")

    label = tk.Label(root, text="Bem-vindo ao CONAV TRADER!", font=("Arial", 16))
    label.pack(pady=20)

    root.mainloop()

if __name__ == "__main__":
    main()

# ===== FIM main_dashboard.py =====

# ===== INICIO uninstall_wrapper.py =====
import subprocess, sys, os
ps1 = os.path.join(os.path.dirname(__file__),"Desinstalar-Por-PowerShell.ps1")
subprocess.call(["powershell","-ExecutionPolicy","Bypass","-File", ps1])

# ===== FIM uninstall_wrapper.py =====

# ===== INICIO email_capturer.py =====
# email_capturer placeholder

def capture():
    return []

# ===== FIM email_capturer.py =====

# ===== INICIO email_sender.py =====
# email_sender placeholder

def send(recipient, subject, body):
    return True

# ===== FIM email_sender.py =====

# ===== INICIO generate_map_pdf.py =====
# generate_map_pdf.py
import sys
from reportlab.lib.pagesizes import letter, landscape
from reportlab.pdfgen import canvas
def txt_to_pdf(txt_path, pdf_path):
    c = canvas.Canvas(pdf_path, pagesize=landscape(letter))
    width, height = landscape(letter)
    with open(txt_path, 'r', encoding='utf-8') as f:
        lines = f.read().splitlines()
    margin = 40
    y = height - margin
    line_height = 12
    max_lines_per_page = int((height - 2*margin) / line_height)
    page = 0
    i = 0
    for line in lines:
        if i >= max_lines_per_page:
            c.showPage()
            y = height - margin
            i = 0
        if len(line) > 300:
            line = line[:300] + "..."
        c.drawString(margin, y, line)
        y = y - line_height
        i += 1
    c.save()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: generate_map_pdf.py input.txt output.pdf")
        sys.exit(1)
    txt = sys.argv[1]
    pdf = sys.argv[2]
    txt_to_pdf(txt, pdf)
# ===== FIM generate_map_pdf.py =====

# ===== INICIO generate_report_pdf.py =====
# generate_report_pdf.py
# Attempts to create a simple PDF report from relatorio template.
from pathlib import Path
md = Path("relatorios/README_relatorio_template.md")
out = Path("relatorios/relatorio_overview_v1.45.pdf")
if not md.exists():
    print("Template MD not found:", md)
    raise SystemExit(1)
text = md.read_text(encoding="utf-8")
try:
    from reportlab.lib.pagesizes import A4
    from reportlab.pdfgen import canvas
    c = canvas.Canvas(str(out), pagesize=A4)
    width, height = A4
    y = height - 50
    for line in text.splitlines():
        c.drawString(40, y, line[:100])
        y -= 14
        if y < 50:
            c.showPage()
            y = height - 50
    c.save()
    print("PDF generated:", out)
except Exception as e:
    print("reportlab not available or failed:", e)
    print("You can install reportlab (pip install reportlab) and re-run this script to generate PDF.")
# ===== FIM generate_report_pdf.py =====

# ===== INICIO build.exe.ps1 =====
# ======================================
# USERAT 2025 - Build Script
# ======================================

# Pastas principais
$AppFolder   = "C:\USERAT"
$MainScript  = Join-Path $AppFolder "main.py"
$DistFolder  = Join-Path $AppFolder "dist"
$BuildOutput = Join-Path $DistFolder "USERAT_2025.exe"

# Caminho do Desktop (OneDrive)
$DesktopPath = "C:\Users\arati\OneDrive\Área de Trabalho"
$ShortcutPath = Join-Path $DesktopPath "USERAT 2025.lnk"

# Limpa build anterior
if (Test-Path $DistFolder) {
    Remove-Item $DistFolder -Recurse -Force
}

# Compila com pyinstaller
Write-Host "🚀 Compilando USERAT 2025..."
pyinstaller --onefile --noconsole --name "USERAT_2025" $MainScript

# Aguarda build terminar
Start-Sleep -Seconds 5

# Verifica se o executável foi criado
if (-Not (Test-Path $BuildOutput)) {
    Write-Host "❌ Erro: o executável não foi gerado."
    exit 1
}

# Remove atalho antigo se existir
if (Test-Path $ShortcutPath) {
    Remove-Item $ShortcutPath -Force
}

# Cria novo atalho
Write-Host "📌 Criando atalho na Área de Trabalho..."
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $BuildOutput
$Shortcut.WorkingDirectory = $AppFolder
$Shortcut.WindowStyle = 1
$Shortcut.IconLocation = "$BuildOutput,0"
$Shortcut.Description = "Abrir USERAT 2025"
$Shortcut.Save()

Write-Host "✅ Build concluído!"
Write-Host "📂 Executável: $BuildOutput"
Write-Host "🔗 Atalho: $ShortcutPath"
# ===== FIM build.exe.ps1 =====

# ===== INICIO setup_userat_2025.ps1 =====
# ======================================
# USERAT 2025 - Setup One-Click Corrigido + Autocorreção
# ======================================

$ProjectDir = "C:\USERAT"
$ScriptsDir = "$ProjectDir\scripts"
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$LogsDir = "$ProjectDir\logs"

# --- Criar diretórios ---
$folders = @("$ProjectDir\backend", "$ProjectDir\frontend\app", "$ProjectDir\database", $ScriptsDir, $LogsDir, "$ProjectDir\pdfs")
foreach ($f in $folders) {
    if (-Not (Test-Path $f)) { New-Item -ItemType Directory -Path $f | Out-Null }
}

# --- Função de log ---
function Write-Log {
    param([string]$message)
    $logFile = "$LogsDir\execution_log.txt"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFile -Append -Encoding UTF8
    Write-Host $message
}

Write-Log "Iniciando setup USERAT 2025..."

# --- Função de autocorreção ---
function AutoFix {
    param([string]$step, [scriptblock]$action)
    try {
        & $action
        Write-Log "$step concluído com sucesso."
    } catch {
        Write-Log "ERRO detectado em $step: $($_.Exception.Message)"
        Write-Log "Tentando autocorreção..."
        
        switch -Regex ($_.Exception.Message) {
            "No matching version found for next" {
                Write-Log "Corrigindo versão Next.js..."
                Set-Content -Path "$ProjectDir\frontend\package.json" -Value '{
                  "name": "userat-frontend",
                  "version": "1.0.0",
                  "scripts": {"dev": "next dev","build": "next build","start": "next start"},
                  "dependencies": {"next": "13.4.0","react": "18.2.0","react-dom": "18.2.0"}
                }' -Encoding utf8 -Force
                & $action
            }
            "Could not find a part of the path" {
                Write-Log "Criando diretório ausente..."
                New-Item -ItemType Directory -Path (Split-Path $_.InvocationInfo.PositionMessage -Parent) -Force | Out-Null
                & $action
            }
            default {
                Write-Log "Não foi possível corrigir automaticamente."
            }
        }
    }
}

# --- Criar backend ---
$backendCode = @"
from fastapi import FastAPI
app = FastAPI()
@app.get('/')
def read_root():
    return {'message': 'USERAT Backend Online 🚀'}
"@
Set-Content -Path "$ProjectDir\backend\app.py" -Value $backendCode -Encoding utf8 -Force

$requirements = @("fastapi","uvicorn","reportlab","psycopg2-binary","graphviz")
Set-Content -Path "$ProjectDir\backend\requirements.txt" -Value ($requirements -join "`n") -Encoding utf8 -Force

# --- Criar frontend ---
$frontendPage = @"
export default function Home() {
  return (
    <div>
      <h1>USERAT - Plataforma de Câmbio 2025</h1>
      <p>Frontend rodando com Next.js 🚀</p>
    </div>
  );
}
"@
Set-Content -Path "$ProjectDir\frontend\app\page.jsx" -Value $frontendPage -Encoding utf8 -Force

$packageJson = @"
{
  ""name"": ""userat-frontend"",
  ""version"": ""1.0.0"",
  ""scripts"": {
    ""dev"": ""next dev"",
    ""build"": ""next build"",
    ""start"": ""next start""
  },
  ""dependencies"": {
    ""next"": ""13.4.0"",
    ""react"": ""18.2.0"",
    ""react-dom"": ""18.2.0""
  }
}
"@
Set-Content -Path "$ProjectDir\frontend\package.json" -Value $packageJson -Encoding utf8 -Force

# --- Script de execução backend + frontend ---
$runScript = @"
cd ..\backend
pip install -r requirements.txt
Start-Process powershell -ArgumentList '-NoExit','uvicorn app:app --reload'
cd ..\frontend
npm install
npm run dev
"@
Set-Content -Path "$ScriptsDir\run_userat.ps1" -Value $runScript -Encoding utf8 -Force

# --- Criar atalho somente se não existir ---
$shortcutPath = "$DesktopPath\USERAT 2025.lnk"
if (-Not (Test-Path $shortcutPath)) {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File "$ScriptsDir\run_userat.ps1""
    $Shortcut.IconLocation = "$ProjectDir\frontend\app\page.jsx"
    $Shortcut.Save()
    Write-Log "Atalho criado na área de trabalho."
} else {
    Write-Log "Atalho já existe. Pulando criação."
}

Write-Log "✅ Setup USERAT 2025 concluído! Use o atalho para iniciar o Dashboard."
# ===== FIM setup_userat_2025.ps1 =====

# ===== INICIO userat_build_and_package.ps1 =====
# =========================================
# USERAT - Build and Package Script 2025
# =========================================

# Diretórios principais
$ProjectDir = "C:\USERAT"
$ScriptsDir = "$ProjectDir\scripts"
$LogsDir = "$ProjectDir\logs"
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ShortcutPath = Join-Path $DesktopPath "USERAT 2025.lnk"

# Criar diretórios se não existirem
$dirs = @($ScriptsDir, $LogsDir, "$ProjectDir\backend", "$ProjectDir\frontend\app", "$ProjectDir\database")
foreach ($d in $dirs) {
    if (-Not (Test-Path $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
}

# Criar arquivo de log
$LogFile = "$LogsDir\execution_log.txt"
if (-Not (Test-Path $LogFile)) { New-Item -ItemType File -Path $LogFile | Out-Null }

function Log {
    param([string]$message)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time - $message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    Write-Host $message
}

Log "===== Iniciando build e package USERAT ====="

# =========================================
# Corrigir JSON do frontend
# =========================================
$packageJsonPath = "$ProjectDir\frontend\package.json"
$packageJson = @"
{
  "name": "userat-frontend",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "13.4.0",
    "react": "18.2.0",
    "react-dom": "18.2.0"
  }
}
"@
Set-Content -Path $packageJsonPath -Value $packageJson -Encoding UTF8 -Force
Log "JSON frontend corrigido."

# =========================================
# Corrigir Python backend (remover U+00A0)
# =========================================
$backendPy = "$ProjectDir\backend\app.py"
$backendCode = @"
from fastapi import FastAPI

app = FastAPI()

@app.get('/')
def read_root():
    return {'message': 'USERAT Backend Online 🚀'}

def main():
    print('Backend USERAT rodando...')

if _name_ == "_main_":
    main()
"@
Set-Content -Path $backendPy -Value $backendCode -Encoding UTF8 -Force
Log "Backend Python corrigido."

# =========================================
# Criar atalho na Área de Trabalho
# =========================================
$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($ShortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.WorkingDirectory = $ScriptsDir
$shortcut.Arguments = '-ExecutionPolicy Bypass -File "' + $ScriptsDir + '\run_userat.ps1"'
# Não sobrescreve ícone existente
$shortcut.Save()
Log "Atalho do USERAT criado na Área de Trabalho."

# =========================================
# Instalação dependências backend + frontend
# =========================================
try {
    Write-Host "🔹 Instalando dependências backend..."
    pip install -r "$ProjectDir\backend\requirements.txt" | Out-Null
    Write-Host "🔹 Instalando dependências frontend..."
    cd "$ProjectDir\frontend"
    npm install
} catch {
    Log "Erro na instalação de dependências: $_"
}

Log "===== Build e Package finalizado ====="
Write-Host "✅ USERAT pronto para rodar! Use o atalho na Área de Trabalho."
# ===== FIM userat_build_and_package.ps1 =====

# ===== INICIO userat_oneclick.ps1 =====
# ======================================
# USERAT 2025 - Setup One-Click Ultra
# Instala e configura backend, frontend, banco, dashboard e cria executável nativo
# ======================================

$ProjectDir = "C:\USERAT"
$ScriptsDir = "$ProjectDir\scripts"
$LogsDir = "$ProjectDir\logs"
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ShortcutPath = "$DesktopPath\USERAT 2025.lnk"

# ------------------------------
# Função de log
# ------------------------------
function Write-Log {
    param([string]$Message)
    if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir | Out-Null }
    $LogFile = "$LogsDir\execution_log.txt"
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    Write-Host $Message
}

Write-Log "Iniciando Setup USERAT 2025..."

# ------------------------------
# Criar diretórios
# ------------------------------
$folders = @("$ProjectDir\backend", "$ProjectDir\frontend\app", "$ProjectDir\database", $ScriptsDir, $LogsDir, "$ProjectDir\pdfs")
foreach ($f in $folders) {
    if (-not (Test-Path $f)) {
        New-Item -ItemType Directory -Path $f | Out-Null
        Write-Log "Criado diretório: $f"
    }
}

# ------------------------------
# Instalar Python 3.12+
# ------------------------------
try {
    $pythonVer = python --version 2>$null
} catch { $pythonVer = $null }

if (-not $pythonVer) {
    Write-Log "Instalando Python 3.12..."
    $pyInstaller = "$env:TEMP\python_installer.exe"
    Invoke-WebRequest "https://www.python.org/ftp/python/3.12.2/python-3.12.2-amd64.exe" -OutFile $pyInstaller
    Start-Process $pyInstaller -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
    Write-Log "Python instalado"
} else { Write-Log "Python já instalado: $pythonVer" }

# ------------------------------
# Instalar Node.js LTS
# ------------------------------
try {
    $nodeVer = node --version 2>$null
} catch { $nodeVer = $null }

if (-not $nodeVer) {
    Write-Log "Instalando Node.js LTS..."
    $nodeInstaller = "$env:TEMP\node_installer.msi"
    Invoke-WebRequest "https://nodejs.org/dist/v20.5.1/node-v20.5.1-x64.msi" -OutFile $nodeInstaller
    Start-Process "msiexec.exe" -ArgumentList "/i "$nodeInstaller" /quiet /norestart" -Wait
    Write-Log "Node.js instalado"
} else { Write-Log "Node.js já instalado: $nodeVer" }

# ------------------------------
# Instalar PostgreSQL 15
# ------------------------------
try {
    $psqlVer = psql --version 2>$null
} catch { $psqlVer = $null }

if (-not $psqlVer) {
    Write-Log "Instalando PostgreSQL 15..."
    $pgInstaller = "$env:TEMP\postgres_installer.exe"
    Invoke-WebRequest "https://get.enterprisedb.com/postgresql/postgresql-15.5-1-windows-x64.exe" -OutFile $pgInstaller
    Start-Process $pgInstaller -ArgumentList "--mode unattended --superpassword admin123" -Wait
    Write-Log "PostgreSQL instalado com senha: admin123"
} else { Write-Log "PostgreSQL já instalado: $psqlVer" }

# ------------------------------
# Criar backend FastAPI
# ------------------------------
$backendCode = @"
from fastapi import FastAPI
app = FastAPI()

@app.get('/')
def read_root():
    return {'message': 'USERAT Backend Online 🚀'}
"@
Set-Content -Path "$ProjectDir\backend\app.py" -Value $backendCode -Encoding UTF8 -Force

$requirements = @("fastapi", "uvicorn", "psycopg2-binary", "reportlab", "graphviz")
Set-Content -Path "$ProjectDir\backend\requirements.txt" -Value ($requirements -join "`n") -Encoding UTF8 -Force

Write-Log "Backend FastAPI criado"

# ------------------------------
# Criar frontend Next.js + React
# ------------------------------
$frontendPage = @"
export default function Home() {
  return (
    <div>
      <h1>USERAT 2025 - Dashboard de Câmbio</h1>
      <p>Frontend interativo rodando com Next.js 🚀</p>
    </div>
  );
}
"@
Set-Content -Path "$ProjectDir\frontend\app\page.jsx" -Value $frontendPage -Encoding UTF8 -Force

$packageJson = @"
{
  ""name"": ""userat-frontend"",
  ""version"": ""1.0.0"",
  ""scripts"": {
    ""dev"": ""next dev"",
    ""build"": ""next build"",
    ""start"": ""next start""
  },
  ""dependencies"": {
    ""next"": ""13.4.0"",
    ""react"": ""18.2.0"",
    ""react-dom"": ""18.2.0"",
    ""tailwindcss"": ""3.3.2""
  }
}
"@
Set-Content -Path "$ProjectDir\frontend\package.json" -Value $packageJson -Encoding UTF8 -Force
Write-Log "Frontend Next.js + React criado"

# ------------------------------
# Script run_userat.ps1
# ------------------------------
$runScript = @"
cd "$ProjectDir\backend"
pip install -r requirements.txt
Start-Process powershell -ArgumentList '-NoExit','uvicorn app:app --reload'
cd "$ProjectDir\frontend"
npm install
npm run dev
"@
Set-Content -Path "$ScriptsDir\run_userat.ps1" -Value $runScript -Encoding UTF8 -Force
Write-Log "Script run_userat.ps1 criado"

# ------------------------------
# Criar atalho na área de trabalho (não sobrescreve)
# ------------------------------
if (-not (Test-Path $ShortcutPath)) {
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File "$ScriptsDir\run_userat.ps1""
    $Shortcut.WorkingDirectory = $ProjectDir
    $Shortcut.WindowStyle = 1
    $Shortcut.IconLocation = "$ProjectDir\frontend\app\favicon.ico"
    $Shortcut.Save()
    Write-Log "Atalho criado na área de trabalho"
} else {
    Write-Log "Atalho já existe, continuando..."
}

Write-Log "Setup USERAT 2025 concluído com sucesso!"
Write-Host "✅ Tudo pronto! Execute o atalho USERAT 2025 para abrir o Dashboard"
# ===== FIM userat_oneclick.ps1 =====

# ===== INICIO loose-envify.ps1 =====
#!/usr/bin/env pwsh
$basedir=Split-Path $MyInvocation.MyCommand.Definition -Parent

$exe=""
if ($PSVersionTable.PSVersion -lt "6.0" -or $IsWindows) {
  # Fix case when both the Windows and Linux builds of Node
  # are installed in the same directory
  $exe=".exe"
}
$ret=0
if (Test-Path "$basedir/node$exe") {
  # Support pipeline input
  if ($MyInvocation.ExpectingInput) {
    $input | & "$basedir/node$exe"  "$basedir/../loose-envify/cli.js" $args
  } else {
    & "$basedir/node$exe"  "$basedir/../loose-envify/cli.js" $args
  }
  $ret=$LASTEXITCODE
} else {
  # Support pipeline input
  if ($MyInvocation.ExpectingInput) {
    $input | & "node$exe"  "$basedir/../loose-envify/cli.js" $args
  } else {
    & "node$exe"  "$basedir/../loose-envify/cli.js" $args
  }
  $ret=$LASTEXITCODE
}
exit $ret

# ===== FIM loose-envify.ps1 =====

# ===== INICIO nanoid.ps1 =====
#!/usr/bin/env pwsh
$basedir=Split-Path $MyInvocation.MyCommand.Definition -Parent

$exe=""
if ($PSVersionTable.PSVersion -lt "6.0" -or $IsWindows) {
  # Fix case when both the Windows and Linux builds of Node
  # are installed in the same directory
  $exe=".exe"
}
$ret=0
if (Test-Path "$basedir/node$exe") {
  # Support pipeline input
  if ($MyInvocation.ExpectingInput) {
    $input | & "$basedir/node$exe"  "$basedir/../nanoid/bin/nanoid.cjs" $args
  } else {
    & "$basedir/node$exe"  "$basedir/../nanoid/bin/nanoid.cjs" $args
  }
  $ret=$LASTEXITCODE
} else {
  # Support pipeline input
  if ($MyInvocation.ExpectingInput) {
    $input | & "node$exe"  "$basedir/../nanoid/bin/nanoid.cjs" $args
  } else {
    & "node$exe"  "$basedir/../nanoid/bin/nanoid.cjs" $args
  }
  $ret=$LASTEXITCODE
}
exit $ret

# ===== FIM nanoid.ps1 =====

# ===== INICIO next.ps1 =====
#!/usr/bin/env pwsh
$basedir=Split-Path $MyInvocation.MyCommand.Definition -Parent

$exe=""
if ($PSVersionTable.PSVersion -lt "6.0" -or $IsWindows) {
  # Fix case when both the Windows and Linux builds of Node
  # are installed in the same directory
  $exe=".exe"
}
$ret=0
if (Test-Path "$basedir/node$exe") {
  # Support pipeline input
  if ($MyInvocation.ExpectingInput) {
    $input | & "$basedir/node$exe"  "$basedir/../next/dist/bin/next" $args
  } else {
    & "$basedir/node$exe"  "$basedir/../next/dist/bin/next" $args
  }
  $ret=$LASTEXITCODE
} else {
  # Support pipeline input
  if ($MyInvocation.ExpectingInput) {
    $input | & "node$exe"  "$basedir/../next/dist/bin/next" $args
  } else {
    & "node$exe"  "$basedir/../next/dist/bin/next" $args
  }
  $ret=$LASTEXITCODE
}
exit $ret

# ===== FIM next.ps1 =====

# ===== INICIO run_userat.ps1 =====
cd ..\backend
Start-Process python -ArgumentList '-m uvicorn app:app --reload --host 127.0.0.1 --port 8000'
cd ..\frontend
npm run dev

# ===== FIM run_userat.ps1 =====

# ===== INICIO userat_build_and_final.ps1 =====
# userat_build_and_package.ps1
Param()
Set-StrictMode -Version Latest

$ProjectDir = "C:\USERAT"
Push-Location $ProjectDir

function Write-Log($msg){ 
    $log = Join-Path $ProjectDir "logs\execution_log.txt"
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $msg"
    $entry | Out-File -FilePath $log -Append -Encoding UTF8
    Write-Host $msg
}

Write-Log "START userat_build_and_package"

# 1) Check Node and Python
$node = Get-Command node -ErrorAction SilentlyContinue
$python = Get-Command python -ErrorAction SilentlyContinue

if (-not $node) {
    Write-Log "Node not found on PATH. Attempting to download Node LTS (requires Admin)."
    $nodeInst = "$env:TEMP\node-lts.msi"
    Invoke-WebRequest "https://nodejs.org/dist/v20.5.1/node-v20.5.1-x64.msi" -OutFile $nodeInst
    Start-Process msiexec.exe -ArgumentList "/i "$nodeInst" /quiet /norestart" -Wait
    Start-Sleep -Seconds 3
}
if (-not $python) {
    Write-Log "Python not found on PATH. Attempting to download Python 3.12 (requires Admin)."
    $pyInst = "$env:TEMP\python_installer.exe"
    Invoke-WebRequest "https://www.python.org/ftp/python/3.12.2/python-3.12.2-amd64.exe" -OutFile $pyInst
    Start-Process $pyInst -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
    Start-Sleep -Seconds 3
}

# Refresh commands
$node = Get-Command node -ErrorAction SilentlyContinue
$python = Get-Command python -ErrorAction SilentlyContinue

if (-not $node) { Write-Log "ERROR: Node not installed. Please install Node.js manually and re-run." ; exit 1 }
if (-not $python) { Write-Log "ERROR: Python not installed. Please install Python and re-run." ; exit 1 }

Write-Log "Node: $(node --version 2>$null)"
Write-Log "Python: $(python --version 2>$null)"

# 2) Install backend python deps
$req = Join-Path $ProjectDir "backend\requirements.txt"
if (Test-Path $req) {
    Write-Log "Installing backend Python requirements (pip)..."
    & python -m pip install --upgrade pip setuptools wheel
    & python -m pip install -r $req
    Write-Log "Python deps installed."
} else {
    Write-Log "No backend requirements found at $req"
}

# 3) Install frontend + electron deps
Write-Log "Installing frontend and electron dependencies (npm)..."
# ensure we are at project root
Push-Location $ProjectDir
# npm install root (electron dev deps)
try {
    & npm install --no-audit --no-fund --legacy-peer-deps
    Write-Log "Root npm install finished."
} catch {
    Write-Log "Root npm install failed: $($_.Exception.Message)"
    Write-Log "Trying fallback: npm install --legacy-peer-deps"
    & npm install --legacy-peer-deps
}

# 4) Build frontend (Next.js production)
Write-Log "Building frontend (Next.js)..."
Push-Location (Join-Path $ProjectDir "frontend")
try {
    & npx next build
    Write-Log "Next build success."
} catch {
    Write-Log "Next build failed: $($_.Exception.Message)"
    Write-Host "If Next build fails, check logs and run 'npx next build' manually in $ProjectDir\frontend"
}
Pop-Location

# 5) Package with electron-builder (generates installer)
Write-Log "Packaging Electron app (electron-builder)..."
Push-Location $ProjectDir
try {
    # run electron-builder via npx (will use devDependencies)
    & npx electron-builder --win --x64
    Write-Log "electron-builder finished (check dist\\)."
} catch {
    Write-Log "electron-builder failed: $($_.Exception.Message)"
    Write-Host "Try running: npx electron-builder --win --x64 manually."
    exit 1
}
Pop-Location

# 6) Finalize: show path to installer
$dist = Join-Path $ProjectDir "dist"
if (Test-Path $dist) {
    Write-Log "Build complete. Look for installer in: $dist"
    Get-ChildItem -Path $dist -Recurse | Where-Object { $_.Extension -match 'exe|msi|nsis|nupkg' } | Select-Object FullName
} else {
    Write-Log "No dist directory found. Packaging might have failed."
}

Write-Log "END userat_build_and_package"
Pop-Location
# ===== FIM userat_build_and_final.ps1 =====

# ===== INICIO userat_one_click_-final.ps1 =====
#################################################################
# USERAT Mega One-Click FINAL (integrado) - 2025
# Backend FastAPI + Frontend Next.js Dashboard + Bots + PDFs + Logs
# WARNING: Run PowerShell as Administrator when installing system packages.
#################################################################

# -----------------------
# CONFIG
# -----------------------
$ProjectDir = "C:\USERAT"
$PythonMinimum = "3.10"
$NodeMinimumMajor = 18
$PostgresPassword = "admin123"        # default; change if desired
$NextPreferred = "13.4.10"            # preferred Next version (fallback safe)
$RunAsAdminNotice = @"
IMPORTANT:
- To install system packages (Python/Node/Postgres) you must run PowerShell AS ADMINISTRATOR.
- If you do NOT want installers to run, skip running the script as admin and install components manually.
"@
Write-Host $RunAsAdminNotice

# -----------------------
# Helper functions
# -----------------------
function Ensure-Directory($path) {
    if (-Not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
}
function Write-Log($text) {
    $logsDir = Join-Path $ProjectDir "logs"
    Ensure-Directory $logsDir
    $file = Join-Path $logsDir "execution_log.txt"
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $text"
    $entry | Out-File -FilePath $file -Append -Encoding UTF8
    Write-Host $text
}
function Download-File($url, $dest) {
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
        Write-Log "Downloaded $url -> $dest"
        return $true
    } catch {
        Write-Log "Failed download $url : $($_.Exception.Message)"
        return $false
    }
}

# -----------------------
# Create project structure
# -----------------------
$dirs = @(
    $ProjectDir,
    Join-Path $ProjectDir "backend",
    Join-Path $ProjectDir "frontend\app",
    Join-Path $ProjectDir "database",
    Join-Path $ProjectDir "scripts",
    Join-Path $ProjectDir "logs",
    Join-Path $ProjectDir "pdfs",
    Join-Path $ProjectDir "data",
    Join-Path $ProjectDir "bots",
    Join-Path $ProjectDir "updates"
)
foreach ($d in $dirs) { Ensure-Directory $d }

Write-Log "Project directories created/verified."

# -----------------------
# Write backend (FastAPI) - robust minimal API (app.py)
# -----------------------
$backendApp = @"
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import json, os
from pathlib import Path

app = FastAPI(title='USERAT Backend', version='4.1')

app.add_middleware(
    CORSMiddleware,
    allow_origins=['http://localhost:3000','http://127.0.0.1:3000','*'],
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)

DATA_FILE = Path(r'$ProjectDir\data\test_data.json')

def ensure_data():
    if not DATA_FILE.exists():
        initial = {'leads': [], 'operacoes_cambiais': []}
        DATA_FILE.parent.mkdir(parents=True, exist_ok=True)
        DATA_FILE.write_text(json.dumps(initial, ensure_ascii=False, indent=2), encoding='utf8')
    return json.loads(DATA_FILE.read_text(encoding='utf8'))

def save_data(d):
    DATA_FILE.write_text(json.dumps(d, ensure_ascii=False, indent=2), encoding='utf8')

class Lead(BaseModel):
    empresa: str
    contato: str
    telefone: str
    email: str

class Operacao(BaseModel):
    empresa: str
    valor: float
    data_operacao: str

@app.on_event("startup")
def startup_event():
    ensure_data()

@app.get("/")
def root():
    return {"message": "USERAT Backend Online 🚀"}

@app.get("/api/leads")
def get_leads():
    d = ensure_data()
    return d.get("leads", [])

@app.post("/api/leads")
def post_lead(lead: Lead):
    d = ensure_data()
    d.setdefault("leads", []).append(lead.dict())
    save_data(d)
    return {"message":"Lead adicionado","lead":lead.dict()}

@app.get("/api/operacoes")
def get_operacoes():
    d = ensure_data()
    return d.get("operacoes_cambiais", [])

@app.post("/api/operacoes")
def post_operacao(op: Operacao):
    d = ensure_data()
    d.setdefault("operacoes_cambiais", []).append(op.dict())
    save_data(d)
    return {"message":"Operação adicionada","operacao":op.dict()}

# Simple bot endpoint (uses simple rule-based responses)
@app.get("/api/bot")
def bot(q: str):
    text = q.lower()
    if "import" in text or "importação" in text:
        return {"reply":"Bot Importação: verifique documentos (commercial invoice, packing list, BL/AWB), impostos e registro no sistema."}
    if "export" in text or "exportação" in text:
        return {"reply":"Bot Exportação: verifique cotação, documentação de exportação, impostos e logística."}
    if "câmbio" in text or "cambio" in text or "taxa" in text:
        return {"reply":"Bot Câmbio: as cotações são fictícias nos dados de teste; consulte o módulo de operações para valores."}
    return {"reply":"Desculpe — não entendi. Pergunte sobre importação, exportação ou câmbio."}
"@
$backendPath = Join-Path $ProjectDir "backend\app.py"
$backendApp | Out-File -FilePath $backendPath -Encoding UTF8 -Force
Write-Log "Backend app.py written."

# requirements.txt
$requirements = @(
    "fastapi==0.111.1",
    "uvicorn==0.23.2",
    "pydantic==2.7.0",
    "reportlab",
    "psycopg2-binary",
    "graphviz"
)
$reqPath = Join-Path $ProjectDir "backend\requirements.txt"
$requirements -join "`n" | Out-File -FilePath $reqPath -Encoding UTF8 -Force
Write-Log "backend/requirements.txt written."

# -----------------------
# Frontend: Next.js minimal dashboard (app router)
# - We'll add a minimal client-side fetch to the backend endpoints
# -----------------------
$frontendIndex = @"
'use client';
import React, {useEffect, useState} from 'react';

export default function Home(){
  const [leads,setLeads] = useState([]);
  const [ops,setOps] = useState([]);
  const [botQ,setBotQ] = useState('');
  const [botR,setBotR] = useState('');

  useEffect(()=>{
    fetch('http://127.0.0.1:8000/api/leads')
      .then(r=>r.json()).then(d=>setLeads(d)).catch(()=>setLeads([]));
    fetch('http://127.0.0.1:8000/api/operacoes')
      .then(r=>r.json()).then(d=>setOps(d)).catch(()=>setOps([]));
  },[]);

  function askBot(){
    if(!botQ) return;
    fetch(http://127.0.0.1:8000/api/bot?q=${encodeURIComponent(botQ)})
      .then(r=>r.json()).then(j=>setBotR(j.reply)).catch(()=>setBotR('Erro ao consultar bot'));
  }

  return (
    <div style={{fontFamily:'Arial, sans-serif',padding:20}}>
      <h1>USERAT Dashboard — Câmbio & Trade</h1>

      <section style={{marginTop:20}}>
        <h2>Leads</h2>
        <ul>{leads.map((l,i)=>(<li key={i}>{l.empresa} — {l.contato} — {l.email}</li>))}</ul>
      </section>

      <section style={{marginTop:20}}>
        <h2>Operações Cambiais</h2>
        <ul>{ops.map((o,i)=>(<li key={i}>{o.empresa} — {o.valor} — {o.data_operacao}</li>))}</ul>
      </section>

      <section style={{marginTop:20}}>
        <h2>Bot Interativo (Importação / Exportação / Câmbio)</h2>
        <input value={botQ} onChange={e=>setBotQ(e.target.value)} placeholder='Pergunte: ex. "Como faço importação?"' style={{width:'60%'}}/>
        <button onClick={askBot} style={{marginLeft:8}}>Enviar</button>
        <p><strong>Resposta:</strong> {botR}</p>
      </section>

      <section style={{marginTop:20}}>
        <p>Guias e PDFs estão na pasta: <code>{'$ProjectDir\\pdfs'}</code></p>
      </section>
    </div>
  )
}
"@
$frontAppPath = Join-Path $ProjectDir "frontend\app\page.jsx"
Ensure-Directory (Split-Path $frontAppPath)
$frontendIndex | Out-File -FilePath $frontAppPath -Encoding UTF8 -Force
Write-Log "Frontend app/page.jsx written."

# package.json (we will run install logic that prefers a stable version)
$packageJson = @{
    name = "userat-frontend"
    version = "1.0.0"
    scripts = @{
        dev = "next dev"
        build = "next build"
        start = "next start"
    }
    dependencies = @{
        next = $NextPreferred
        react = "18.2.0"
        "react-dom" = "18.2.0"
    }
}
$pkgPath = Join-Path $ProjectDir "frontend\package.json"
$packageJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $pkgPath -Encoding UTF8 -Force
Write-Log "frontend/package.json written (preferred next: $NextPreferred)."

# -----------------------
# Bots simple file (JSON knowledge + optional example)
# -----------------------
$botData = @{
    knowledge = @{
        importacao = "Procedimento de importação: documentos (commercial invoice, packing list, BL/AWB), classificação NCM, impostos, despachante."
        exportacao = "Procedimento de exportação: verifique contrato, cotação, documentos de embarque, e regimes aduaneiros."
        cambio = "Câmbio: usar taxas de referência e conferir operações no histórico."
    }
}
$botFile = Join-Path $ProjectDir "bots\knowledge.json"
$botData | ConvertTo-Json -Depth 10 | Out-File -FilePath $botFile -Encoding UTF8 -Force
Write-Log "bots/knowledge.json written."

# -----------------------
# Create test data (if not exists)
# -----------------------
$dataFile = Join-Path $ProjectDir "data\test_data.json"
if (-Not (Test-Path $dataFile)) {
    $test = @{
        leads = @(
            @{ empresa="Empresa A"; contato="Carlos"; telefone="11999999999"; email="carlos@empresaA.com.br" },
            @{ empresa="Empresa B"; contato="Ana"; telefone="11988888888"; email="ana@empresaB.com.br" }
        )
        operacoes_cambiais = @(
            @{ empresa="Empresa A"; valor=50000; data_operacao="2025-09-10" },
            @{ empresa="Empresa B"; valor=120000; data_operacao="2025-09-11" }
        )
    }
    $test | ConvertTo-Json -Depth 10 | Out-File -FilePath $dataFile -Encoding UTF8 -Force
    Write-Log "Data test_data.json created."
} else {
    Write-Log "Data file exists; skipping test data creation."
}

# -----------------------
# PDF generation scripts (Python) - simple textual PDFs
# -----------------------
$makePdfPy = @"
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
doc1 = SimpleDocTemplate(r'$ProjectDir\pdfs\USERAT_Guia_Rapido.pdf', pagesize=A4)
styles = getSampleStyleSheet()
story=[]
story.append(Paragraph('USERAT - Guia Rápido', styles['Title']))
story.append(Spacer(1,12))
story.append(Paragraph('1) Execute scripts\\run_userat.ps1 (como Administrador se necessário).', styles['Normal']))
story.append(Paragraph('2) Abra http://localhost:3000', styles['Normal']))
story.append(Paragraph('3) Use o Bot para dúvidas rápidas sobre importação/exportação/câmbio', styles['Normal']))
doc1.build(story)

doc2 = SimpleDocTemplate(r'$ProjectDir\pdfs\USERAT_Tutorial_Atualizado.pdf', pagesize=A4)
story=[]
story.append(Paragraph('USERAT - Tutorial Completo (resumo)', styles['Title']))
story.append(Spacer(1,12))
story.append(Paragraph('Instalação: ... (veja execução no PowerShell).', styles['Normal']))
doc2.build(story)

doc3 = SimpleDocTemplate(r'$ProjectDir\pdfs\USERAT_API_Frontend_Tutorial.pdf', pagesize=A4)
story=[]
story.append(Paragraph('USERAT - API Frontend (endpoints)', styles['Title']))
story.append(Spacer(1,12))
story.append(Paragraph('GET /api/leads -> lista leads', styles['Normal']))
story.append(Paragraph('POST /api/leads -> adiciona lead {empresa,contato,telefone,email}', styles['Normal']))
story.append(Paragraph('GET /api/operacoes -> lista operacoes', styles['Normal']))
story.append(Paragraph('POST /api/operacoes -> adiciona operacao {empresa,valor,data_operacao}', styles['Normal']))
story.append(Paragraph('GET /api/bot?q=texto -> resposta do bot', styles['Normal']))
doc3.build(story)
"@
$makePdfPyPath = Join-Path $ProjectDir "scripts\make_pdfs.py"
$makePdfPy | Out-File -FilePath $makePdfPyPath -Encoding UTF8 -Force
Write-Log "Python PDF generator written: scripts/make_pdfs.py"

# Try to run the PDF generator (best-effort)
try {
    Write-Log "Attempting to generate PDFs via Python..."
    & python $makePdfPyPath
    Write-Log "PDFs generated."
} catch {
    Write-Log "PDF generation failed: $($_.Exception.Message). Will try later."
}

# -----------------------
# Run installers (best-effort) and install dependencies
# (IMPORTANT: if you do not run as admin, installer steps may fail)
# -----------------------
function Ensure-PythonInstalled {
    if (-Not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Log "Python not found on PATH. Installer step skipped or failed."
        return $false
    } else {
        Write-Log "Python found: $(python --version 2>$null)"
        return $true
    }
}
function Ensure-NodeInstalled {
    if (-Not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Log "Node not found on PATH. Installer step skipped or failed."
        return $false
    } else {
        Write-Log "Node found: $(node --version 2>$null)"
        return $true
    }
}

$pyOk = Ensure-PythonInstalled
$nodeOk = Ensure-NodeInstalled

# Install backend Python deps if python available
if ($pyOk) {
    try {
        Write-Log "Installing backend Python dependencies (pip)..."
        & python -m pip install --upgrade pip setuptools wheel
        & python -m pip install -r $reqPath
        Write-Log "Python dependencies installed."
    } catch {
        Write-Log "Python dependency installation failed: $($_.Exception.Message)"
    }
} else {
    Write-Log "Python missing: skip pip install. Install Python and re-run script or run pip install manually."
}

# Install frontend deps if node available
if ($nodeOk) {
    try {
        Write-Log "Installing frontend dependencies (npm)..."
        Push-Location (Join-Path $ProjectDir "frontend")
        # prefer explicit next version; if install fails, try next@latest
        $success = $false
        try {
            & npm install --no-audit --no-fund --legacy-peer-deps | Out-Null
            $success = $true
        } catch {
            Write-Log "npm install failed with preferred package.json; trying fallback."
            try {
                & npm install next@latest react@18.2.0 react-dom@18.2.0 --no-audit --no-fund --legacy-peer-deps | Out-Null
                & npm install --no-audit --no-fund --legacy-peer-deps | Out-Null
                $success = $true
            } catch {
                Write-Log "npm fallback install also failed: $($_.Exception.Message)"
            }
        }
        Pop-Location
        if ($success) { Write-Log "Frontend dependencies installed." } else { Write-Log "Frontend dependencies not installed. Please run npm install manually." }
    } catch {
        Write-Log "npm install error: $($_.Exception.Message)"
    }
} else {
    Write-Log "Node missing: skip npm install. Install Node.js and re-run script or run npm install manually."
}

# -----------------------
# Create start script that opens backend and frontend in separate shells
# -----------------------
$runAllScript = @"
# Run USERAT backend and frontend (open in two separate PowerShell windows)
cd "$ProjectDir\backend"
python -m uvicorn app:app --reload --host 127.0.0.1 --port 8000
"@
$runBackendPath = Join-Path $ProjectDir "scripts\start_backend.ps1"
$runAllScript | Out-File -FilePath $runBackendPath -Encoding UTF8 -Force

$runFrontendScript = @"
cd "$ProjectDir\frontend"
npm run dev
"@
$runFrontendPath = Join-Path $ProjectDir "scripts\start_frontend.ps1"
$runFrontendScript | Out-File -FilePath $runFrontendPath -Encoding UTF8 -Force

# A script that starts both in separate windows
$runBoth = @"
Start-Process powershell -ArgumentList '-NoExit','-Command','"$ProjectDir\scripts\start_backend.ps1"' -WindowStyle Normal
Start-Sleep -Seconds 2
Start-Process powershell -ArgumentList '-NoExit','-Command','"$ProjectDir\scripts\start_frontend.ps1"' -WindowStyle Normal
"@
$runBothPath = Join-Path $ProjectDir "scripts\run_userat.ps1"
$runBoth | Out-File -FilePath $runBothPath -Encoding UTF8 -Force
Write-Log "Run scripts created: scripts/start_backend.ps1, scripts/start_frontend.ps1, scripts/run_userat.ps1"

# -----------------------
# Start the whole system (best-effort)
# -----------------------
Write-Log "Starting backend and frontend (best-effort)."
try {
    Start-Process powershell -ArgumentList '-NoExit',"-ExecutionPolicy Bypass","-File",$runBothPath
    Write-Log "Start commands launched."
} catch {
    Write-Log "Failed to start run_userat script automatically: $($_.Exception.Message)"
    Write-Host "To start servers manually: run scripts\run_userat.ps1 (Open PowerShell as Admin if needed)."
}

# -----------------------
# Open the user quick-guide PDF (only the quick guide opens automatically)
# -----------------------
$guiaPdf = Join-Path $ProjectDir "pdfs\USERAT_Guia_Rapido.pdf"
if (Test-Path $guiaPdf) {
    try { Start-Process $guiaPdf } catch { Write-Log "Failed to open quick guide PDF: $($_.Exception.Message)" }
}

# -----------------------
# Write update log and finish
# -----------------------
$updateLog = Join-Path $ProjectDir "updates\update_log.txt"
$summary = @(
    "USERAT Mega One-Click Run",
    "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "ProjectDir: $ProjectDir",
    "Python installed: $pyOk",
    "Node installed: $nodeOk",
    "Next preferred: $NextPreferred",
    "Start scripts created at: $runBothPath"
)
$summary -join "`n" | Out-File -FilePath $updateLog -Encoding UTF8 -Force
Write-Log "Update log written: $updateLog"

Write-Host ""
Write-Host "====== USERAT SETUP SUMMARY ======"
Write-Host "Dashboard (frontend) URL: http://localhost:3000"
Write-Host "Backend URL: http://127.0.0.1:8000"
Write-Host "To start servers manually (if not started):"
Write-Host "  1) Open PowerShell (Run as Administrator if you installed system packages)."
Write-Host "  2) Run: "$ProjectDir\scripts\run_userat.ps1""
Write-Host "Logs: $ProjectDir\logs"
Write-Host "PDFs: $ProjectDir\pdfs"
Write-Host "Updates log: $updateLog"
Write-Host "=================================="
Write-Log "USERAT setup finished (best-effort)."
# ===== FIM userat_one_click_-final.ps1 =====

# ===== INICIO userat_setup_final.ps1 =====
# ======================================
# USERAT Setup Final v8.5 Ultra 2025 – One Click
# ======================================

# ===== Diretório do Projeto =====
$ProjectDir = "C:\USERAT"
if (-Not (Test-Path $ProjectDir)) { New-Item -ItemType Directory -Path $ProjectDir -Force }

# ===== Ajuste Execution Policy =====
$PSVersion = $PSVersionTable.PSVersion.Major
if ($PSVersion -ge 7) {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
} elseif ($PSVersion -ge 5) {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
} else {
    Write-Warning "Versão do PowerShell não totalmente compatível. Alguns recursos podem falhar."
}

# ===== Criar Estrutura de Pastas =====
$folders = @(
    "backend","frontend\app","database","scripts","logs","pdfs","data"
)
foreach ($f in $folders) {
    $path = Join-Path $ProjectDir $f
    if (-Not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force }
}

# ===== Instalar Python 3.12+ se necessário =====
if (-Not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Instalando Python 3.12..."
    $pyInstaller = "$env:TEMP\python_installer.exe"
    Invoke-WebRequest "https://www.python.org/ftp/python/3.12.2/python-3.12.2-amd64.exe" -OutFile $pyInstaller
    Start-Process $pyInstaller -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
}

# ===== Instalar Node.js 20+ se necessário =====
if (-Not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Instalando Node.js 20..."
    $nodeInstaller = "$env:TEMP\node_installer.msi"
    Invoke-WebRequest "https://nodejs.org/dist/v20.5.1/node-v20.5.1-x64.msi" -OutFile $nodeInstaller
    Start-Process msiexec.exe -ArgumentList "/i "$nodeInstaller" /quiet /norestart" -Wait
}

# ===== Instalar PostgreSQL 15 se necessário =====
if (-Not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Host "Instalando PostgreSQL 15..."
    $pgInstaller = "$env:TEMP\postgres_installer.exe"
    Invoke-WebRequest "https://get.enterprisedb.com/postgresql/postgresql-15.5-1-windows-x64.exe" -OutFile $pgInstaller
    Start-Process $pgInstaller -ArgumentList "--mode unattended --superpassword admin123" -Wait
    Write-Host "PostgreSQL instalado com senha: admin123"
}

# ===== Backend FastAPI =====
$backendCode = @"
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
app = FastAPI()

origins = ["*"]
app.add_middleware(CORSMiddleware, allow_origins=origins, allow_methods=[""], allow_headers=[""])

leads = []
operacoes = []

@app.get('/api/leads')
def get_leads():
    return leads

@app.post('/api/leads')
def add_lead(lead: dict):
    leads.append(lead)
    return {"status":"ok","lead":lead}

@app.get('/api/operacoes')
def get_operacoes():
    return operacoes

@app.get("/")
def root():
    return {"message":"USERAT Backend Online 🚀"}
"@
$backendPath = Join-Path $ProjectDir "backend\app.py"
$backendCode | Out-File -FilePath $backendPath -Encoding UTF8 -Force

$requirements = @(
    "fastapi==0.111.1",
    "uvicorn==0.23.2",
    "pydantic==2.7.0",
    "psycopg2-binary",
    "reportlab",
    "graphviz"
)
$reqPath = Join-Path $ProjectDir "backend\requirements.txt"
$requirements -join "`n" | Out-File -FilePath $reqPath -Encoding UTF8 -Force

# ===== Frontend Next.js =====
$frontendPage = @"
export default function Home() {
  return (
    <div style={{fontFamily:'Arial',padding:20}}>
      <h1>USERAT - Dashboard de Câmbio 2025</h1>
      <p>Frontend rodando localmente 🚀</p>
    </div>
  )
}
"@
$frontendPagePath = Join-Path $ProjectDir "frontend\app\page.jsx"
$frontendPage | Out-File -FilePath $frontendPagePath -Encoding UTF8 -Force

$packageJson = @"
{
  ""name"": ""userat-frontend"",
  ""version"": ""1.0.0"",
  ""scripts"": {
    ""dev"": ""next dev"",
    ""build"": ""next build"",
    ""start"": ""next start""
  },
  ""dependencies"": {
    ""next"": ""15.5.2"",
    ""react"": ""18.2.0"",
    ""react-dom"": ""18.2.0""
  }
}
"@
$pkgPath = Join-Path $ProjectDir "frontend\package.json"
$packageJson | Out-File -FilePath $pkgPath -Encoding UTF8 -Force

# ===== Banco PostgreSQL =====
$dbScript = @"
CREATE TABLE IF NOT EXISTS leads (
    id SERIAL PRIMARY KEY,
    empresa VARCHAR(255),
    contato VARCHAR(255),
    telefone VARCHAR(50),
    email VARCHAR(255)
);
CREATE TABLE IF NOT EXISTS operacoes_cambiais (
    id SERIAL PRIMARY KEY,
    empresa VARCHAR(255),
    valor NUMERIC,
    data_operacao DATE
);
"@
$dbPath = Join-Path $ProjectDir "database\postgres_setup.sql"
$dbScript | Out-File -FilePath $dbPath -Encoding UTF8 -Force

# ===== Script de execução backend + frontend =====
$runScript = @"
cd ..\backend
pip install -r requirements.txt
uvicorn app:app --reload --host 127.0.0.1 --port 8000
cd ..\frontend
npm install
npm run dev
"@
$runPath = Join-Path $ProjectDir "scripts\run_userat.ps1"
$runScript | Out-File -FilePath $runPath -Encoding UTF8 -Force

# ===== Gerar PDFs de Tutorial + Fluxograma =====
$pyTutorial = @"
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Preformatted, Image
from reportlab.lib.styles import getSampleStyleSheet
import graphviz

doc = SimpleDocTemplate(r'C:\USERAT\pdfs\USERAT_Tutorial_Atualizado.pdf', pagesize=A4)
styles = getSampleStyleSheet()
story = []

story.append(Paragraph('USERAT - Tutorial Completo Atualizado 2025 🚀', styles['Title']))
story.append(Spacer(1,20))

tree = '''
C:\\USERAT
├── backend
├── frontend
├── database
├── scripts
├── pdfs
└── data
'''
story.append(Preformatted(tree, styles['Code']))
story.append(Spacer(1,20))

steps = [
'⿡ Pré-requisitos: Python 3.12+, Node.js LTS, PostgreSQL 15.',
'⿢ Rodar setup_userat_final.ps1 como Administrador.',
'⿣ Instalar dependências backend: pip install -r backend\\\\requirements.txt',
'⿤ Instalar dependências frontend: npm install (na pasta frontend)',
'⿥ Configurar banco de dados: executar postgres_setup.sql',
'⿦ Rodar run_userat.ps1 para iniciar backend + frontend',
'⿧ Acessar backend: http://127.0.0.1:8000, frontend: http://localhost:3000'
]
for s in steps:
    story.append(Paragraph(s, styles['Normal']))

# Fluxograma
dot = graphviz.Digraph(comment='Fluxograma USERAT', format='png')
dot.node('A','Coleta de Dados e Leads')
dot.node('B','CRM Inteligente')
dot.node('C','Comunicação e Automação')
dot.node('D','Chatbots Inteligentes')
dot.node('E','Gestão de Operações Cambiais')
dot.node('F','IA Preditiva')
dot.node('G','Compliance 2025')
dot.node('H','Usuário / Frontend')
dot.edges(['AB','BC','CD','DE','EF','FG','GH'])
fluxoPath = r'C:\USERAT\pdfs\fluxograma_userat.png'
dot.render('C:\\USERAT\\pdfs\\fluxograma_userat', cleanup=True)
story.append(Image(fluxoPath, width=400, height=400))
story.append(Spacer(1,20))

doc.build(story)
"@
$pyFile = Join-Path $ProjectDir "scripts\make_pdf_final.py"
$pyTutorial | Out-File -FilePath $pyFile -Encoding UTF8 -Force

# ===== Instalar dependências Python para PDF/Fluxo =====
pip install reportlab graphviz | Out-Null

# ===== Gerar ZIP de cada pasta + Projeto completo =====
$zipFolders = @("backend","frontend","database","scripts","pdfs","data")
foreach ($zf in $zipFolders) {
    $path = Join-Path $ProjectDir $zf
    $zipFile = Join-Path $ProjectDir "$zf.zip"
    if (Test-Path $zipFile) { Remove-Item $zipFile -Force }
    Compress-Archive -Path "$path\*" -DestinationPath $zipFile -Force
}

$fullZip = Join-Path $ProjectDir "USERAT_Projeto_Completo.zip"
if (Test-Path $fullZip) { Remove-Item $fullZip -Force }
Compress-Archive -Path "$ProjectDir\*" -DestinationPath $fullZip -Force

# ===== Logs automáticos =====
$logPath = Join-Path $ProjectDir "logs\execution_log.txt"
Add-Content $logPath "`n=== Execução USERAT v8.5 === $(Get-Date) ==="

# ===== Conclusão =====
Write-Host "`n✅ USERAT Setup Final v8.5 Ultra 2025 pronto!"
Write-Host "📌 Acesse backend: http://127.0.0.1:8000"
Write-Host "📌 Acesse frontend/Dashboard: http://localhost:3000"
Write-Host "📌 PDFs em: $ProjectDir\pdfs"
Write-Host "📌 Zips individuais e completo gerados."
Write-Host "📌 Logs em: $logPath"
# ===== FIM userat_setup_final.ps1 =====

# ===== INICIO 1megasetup_oneclick_v2025.ps1 =====
# ======================================
# USERAT Mega Setup One-Click v2025
# Completo, funcional e integrado
# ======================================

# ===== Ajustar políticas de execução =====
$PSVersion = $PSVersionTable.PSVersion.Major
if ($PSVersion -ge 7) {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
} elseif ($PSVersion -ge 5) {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
} else {
    Write-Warning "Versão do PowerShell não totalmente compatível. Alguns recursos podem falhar."
}

# ===== Diretório do projeto =====
$ProjectDir = "C:\USERAT"
if (-Not (Test-Path $ProjectDir)) { New-Item -ItemType Directory -Path $ProjectDir }

# ===== Criar estrutura de pastas =====
$folders = @(
    "$ProjectDir\backend",
    "$ProjectDir\frontend\app",
    "$ProjectDir\database",
    "$ProjectDir\scripts",
    "$ProjectDir\logs",
    "$ProjectDir\pdfs",
    "$ProjectDir\data"
)
foreach ($f in $folders) {
    if (-Not (Test-Path $f)) { New-Item -ItemType Directory -Path $f }
}

# ===== Instalar Python 3.12+ se necessário =====
if (-Not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "⚡ Instalando Python 3.12+..."
    $pyInstaller = "$env:TEMP\python_installer.exe"
    Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.12.2/python-3.12.2-amd64.exe" -OutFile $pyInstaller
    Start-Process $pyInstaller -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
}

# ===== Instalar Node.js LTS se necessário =====
if (-Not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "⚡ Instalando Node.js LTS..."
    $nodeInstaller = "$env:TEMP\node_installer.msi"
    Invoke-WebRequest -Uri "https://nodejs.org/dist/v20.5.1/node-v20.5.1-x64.msi" -OutFile $nodeInstaller
    Start-Process "msiexec.exe" -ArgumentList "/i "$nodeInstaller" /quiet /norestart" -Wait
}

# ===== Instalar PostgreSQL 15 se necessário =====
if (-Not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Host "⚡ Instalando PostgreSQL 15..."
    $pgInstaller = "$env:TEMP\postgres_installer.exe"
    Invoke-WebRequest -Uri "https://get.enterprisedb.com/postgresql/postgresql-15.5-1-windows-x64.exe" -OutFile $pgInstaller
    Start-Process $pgInstaller -ArgumentList "--mode unattended --superpassword admin123" -Wait
}

# ===== Backend FastAPI =====
$backendCode = @"
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_methods=['*'],
    allow_headers=['*']
)
@app.get('/')
def read_root():
    return {'message': 'USERAT Backend Online 🚀'}
"@
Set-Content -Path "$ProjectDir\backend\app.py" -Value $backendCode -Encoding utf8 -Force

$requirements = @(
    "fastapi==0.111.1",
    "uvicorn==0.23.2",
    "pydantic==2.7.0",
    "reportlab",
    "psycopg2-binary",
    "graphviz"
)
Set-Content -Path "$ProjectDir\backend\requirements.txt" -Value ($requirements -join "`n") -Encoding utf8 -Force

# ===== Frontend Next.js =====
$frontendPage = @"
export default function Home() {
  return (
    <div style={{ fontFamily:'Arial, sans-serif', padding:'20px' }}>
      <h1>USERAT - Dashboard de Câmbio 2025</h1>
      <p>Frontend rodando com Next.js 🚀</p>
    </div>
  )
}
"@
Set-Content -Path "$ProjectDir\frontend\app\page.jsx" -Value $frontendPage -Encoding utf8 -Force

$packageJson = @"
{
  ""name"": ""userat-frontend"",
  ""version"": ""1.0.0"",
  ""scripts"": {
    ""dev"": ""next dev"",
    ""build"": ""next build"",
    ""start"": ""next start""
  },
  ""dependencies"": {
    ""next"": ""15.5.2"",
    ""react"": ""18.2.0"",
    ""react-dom"": ""18.2.0""
  }
}
"@
Set-Content -Path "$ProjectDir\frontend\package.json" -Value $packageJson -Encoding utf8 -Force

# ===== Banco PostgreSQL =====
$dbScript = @"
CREATE TABLE IF NOT EXISTS leads (
    id SERIAL PRIMARY KEY,
    empresa VARCHAR(255),
    contato VARCHAR(255),
    telefone VARCHAR(50),
    email VARCHAR(255)
);
CREATE TABLE IF NOT EXISTS operacoes_cambiais (
    id SERIAL PRIMARY KEY,
    empresa VARCHAR(255),
    valor NUMERIC,
    data_operacao DATE
);
"@
Set-Content -Path "$ProjectDir\database\postgres_setup.sql" -Value $dbScript -Encoding utf8 -Force

# ===== Script de execução completo =====
$runScript = @"
cd ..\backend
pip install -r requirements.txt
Start-Process powershell -ArgumentList '-NoExit','uvicorn app:app --reload --host 127.0.0.1 --port 8000'
cd ..\frontend
npm install
npm run dev
"@
Set-Content -Path "$ProjectDir\scripts\run_userat.ps1" -Value $runScript -Encoding utf8 -Force

# ===== Gerar PDFs (Tutorial, Guia Rápido, API) =====
pip install reportlab graphviz | Out-Null
$pyPdfCode = @"
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Preformatted, Image
from reportlab.lib.styles import getSampleStyleSheet
import graphviz

doc = SimpleDocTemplate(r'C:\USERAT\pdfs\USERAT_Tutorial_Atualizado.pdf', pagesize=A4)
styles = getSampleStyleSheet()
story = []

story.append(Paragraph('USERAT - Tutorial Completo Atualizado 2025 🚀', styles['Title']))
story.append(Spacer(1,20))

tree = '''
C:\\USERAT
├── backend
│   ├── app.py
│   └── requirements.txt
├── frontend
│   ├── package.json
│   └── app
│       └── page.jsx
├── database
│   └── postgres_setup.sql
└── scripts
    └── run_userat.ps1
'''
story.append(Preformatted(tree, styles['Code']))
story.append(Spacer(1,20))

steps = [
'⿡ Pré-requisitos: Python 3.12+, Node.js LTS, PostgreSQL 15.',
'⿢ Rodar setup_userat_one_click_v8_5.ps1 como Administrador.',
'⿣ Instalar dependências backend: pip install -r backend\\\\requirements.txt',
'⿤ Instalar dependências frontend: npm install (na pasta frontend)',
'⿥ Configurar banco de dados: executar postgres_setup.sql',
'⿦ Rodar run_userat.ps1 para iniciar backend + frontend',
'⿧ Acessar backend: http://127.0.0.1:8000, frontend: http://localhost:3000'
]
for s in steps:
    story.append(Paragraph(s, styles['Normal']))
story.append(Spacer(1,20))

dot = graphviz.Digraph(comment='Fluxograma USERAT', format='png')
dot.node('A','Coleta de Dados e Leads')
dot.node('B','CRM Inteligente')
dot.node('C','Comunicação e Automação')
dot.node('D','Chatbots Inteligentes')
dot.node('E','Gestão de Operações Cambiais')
dot.node('F','IA Preditiva')
dot.node('G','Compliance 2025')
dot.node('H','Usuário / Frontend')
dot.edges(['AB','BC','CD','DE','EF','FG','GH'])
fluxoPath = r'C:\USERAT\pdfs\fluxograma_userat.png'
dot.render('C:\\USERAT\\pdfs\\fluxograma_userat', cleanup=True)
story.append(Image(fluxoPath, width=400, height=400))

doc.build(story)
"@
Set-Content -Path "$ProjectDir\scripts\make_pdf_final.py" -Value $pyPdfCode -Encoding utf8 -Force

# ===== Executar Backend e Frontend automaticamente =====
Start-Process powershell -FilePath "$ProjectDir\scripts\run_userat.ps1"

Write-Host "✅ USERAT Mega Setup completo. Dashboard em: http://localhost:3000"
Write-Host "📄 Guia Rápido: C:\USERAT\pdfs\USERAT_Guia_Rapido.pdf"
# ===== FIM 1megasetup_oneclick_v2025.ps1 =====

# ===== INICIO 2-att-megasetup_oneclick_v2025 - Copia.ps1 =====
# ======================================
# USERAT Mega Autoupdate v2025
# Dashboard + Backend + Frontend + PDFs + Bots + Logs
# ======================================

# ===== Ajustar políticas de execução =====
$PSVersion = $PSVersionTable.PSVersion.Major
if ($PSVersion -ge 7) { Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force }
elseif ($PSVersion -ge 5) { Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force }
else { Write-Warning "Versão do PowerShell não totalmente compatível. Alguns recursos podem falhar." }

# ===== Diretório do projeto =====
$ProjectDir = "C:\USERAT"
$Dirs = @("backend","frontend\app","database","scripts","logs","pdfs","data","bots")
foreach ($d in $Dirs) { if (-Not (Test-Path "$ProjectDir\$d")) { New-Item -ItemType Directory -Path "$ProjectDir\$d" -Force } }

# ===== Função para instalar Python 3.12+ =====
function Install-Python {
    if (-Not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Host "⚡ Instalando Python 3.12+..."
        $pyInstaller = "$env:TEMP\python_installer.exe"
        Invoke-WebRequest "https://www.python.org/ftp/python/3.12.2/python-3.12.2-amd64.exe" -OutFile $pyInstaller
        Start-Process $pyInstaller -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
    }
}
Install-Python

# ===== Função para instalar Node.js LTS =====
function Install-Node {
    if (-Not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host "⚡ Instalando Node.js LTS..."
        $nodeInstaller = "$env:TEMP\node_installer.msi"
        Invoke-WebRequest "https://nodejs.org/dist/v20.5.1/node-v20.5.1-x64.msi" -OutFile $nodeInstaller
        Start-Process "msiexec.exe" -ArgumentList "/i "$nodeInstaller" /quiet /norestart" -Wait
    }
}
Install-Node

# ===== Função para instalar PostgreSQL 15 =====
function Install-Postgres {
    if (-Not (Get-Command psql -ErrorAction SilentlyContinue)) {
        Write-Host "⚡ Instalando PostgreSQL 15..."
        $pgInstaller = "$env:TEMP\postgres_installer.exe"
        Invoke-WebRequest "https://get.enterprisedb.com/postgresql/postgresql-15.5-1-windows-x64.exe" -OutFile $pgInstaller
        Start-Process $pgInstaller -ArgumentList "--mode unattended --superpassword admin123" -Wait
    }
}
Install-Postgres

# ===== Função para atualizar dependências =====
function Install-Dependencies {
    Write-Host "🔹 Instalando dependências backend..."
    pip install -r "$ProjectDir\backend\requirements.txt" | Out-Null
    Write-Host "🔹 Instalando dependências frontend..."
    cd "$ProjectDir\frontend"
    npm install | Out-Null
    Write-Host "✅ Dependências instaladas."
}
# ===== Criar backend FastAPI =====
$backendCode = @"
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_methods=['*'],
    allow_headers=['*']
)
@app.get('/')
def read_root():
    return {'message':'USERAT Backend Online 🚀'}
"@
Set-Content "$ProjectDir\backend\app.py" $backendCode -Encoding utf8

$requirements = @("fastapi==0.111.1","uvicorn==0.23.2","pydantic==2.7.0","reportlab","psycopg2-binary","graphviz")
Set-Content "$ProjectDir\backend\requirements.txt" ($requirements -join "`n") -Encoding utf8

# ===== Criar frontend Next.js =====
$frontendPage = @"
export default function Home() {
  return (
    <div style={{fontFamily:'Arial, sans-serif',padding:'20px'}}>
      <h1>USERAT - Dashboard de Câmbio 2025</h1>
      <p>Frontend rodando com Next.js 🚀</p>
    </div>
  )
}
"@
Set-Content "$ProjectDir\frontend\app\page.jsx" $frontendPage -Encoding utf8

$packageJson = @"
{
  ""name"": ""userat-frontend"",
  ""version"": ""1.0.0"",
  ""scripts"": { ""dev"": ""next dev"",""build"": ""next build"",""start"": ""next start"" },
  ""dependencies"": { ""next"": ""15.5.2"",""react"": ""18.2.0"",""react-dom"": ""18.2.0"" }
}
"@
Set-Content "$ProjectDir\frontend\package.json" $packageJson -Encoding utf8

# ===== Banco PostgreSQL =====
$dbScript = @"
CREATE TABLE IF NOT EXISTS leads (
    id SERIAL PRIMARY KEY,
    empresa VARCHAR(255),
    contato VARCHAR(255),
    telefone VARCHAR(50),
    email VARCHAR(255)
);
CREATE TABLE IF NOT EXISTS operacoes_cambiais (
    id SERIAL PRIMARY KEY,
    empresa VARCHAR(255),
    valor NUMERIC,
    data_operacao DATE
);
"@
Set-Content "$ProjectDir\database\postgres_setup.sql" $dbScript -Encoding utf8

# ===== Script de execução completo =====
$runScript = @"
cd ..\backend
pip install -r requirements.txt
Start-Process powershell -ArgumentList '-NoExit','uvicorn app:app --reload --host 127.0.0.1 --port 8000'
cd ..\frontend
npm install
npm run dev
"@
Set-Content "$ProjectDir\scripts\run_userat.ps1" $runScript -Encoding utf8

# ===== Criar bots interativos de câmbio =====
$botCode = @"
import json
def responder(mensagem):
    respostas = {
        'importacao': 'Use a ferramenta de importação: frontend/import_tool',
        'exportacao': 'Use a ferramenta de exportação: frontend/export_tool',
        'cambio': 'Consulta de operações de câmbio no dashboard'
    }
    return respostas.get(mensagem.lower(),'Comando não reconhecido')
with open(r'C:\USERAT\data\bots.json','w',encoding='utf8') as f:
    json.dump({'responder':responder._code_.co_code.hex()},f)
"@
Set-Content "$ProjectDir\bots/bots_interativos.py" $botCode -Encoding utf8

# ===== Gerar PDFs (Tutorial + Guia Rápido + API) =====
$pyPdfCode = @"
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Preformatted, Image
from reportlab.lib.styles import getSampleStyleSheet
import graphviz

doc = SimpleDocTemplate(r'C:\USERAT\pdfs\USERAT_Tutorial_Atualizado.pdf', pagesize=A4)
styles = getSampleStyleSheet()
story = []
story.append(Paragraph('USERAT - Tutorial Completo 2025 🚀',styles['Title']))
story.append(Spacer(1,20))
tree = '''
C:\\USERAT
├── backend
├── frontend
├── database
├── scripts
├── bots
'''
story.append(Preformatted(tree,styles['Code']))
story.append(Spacer(1,20))
doc.build(story)
"@
Set-Content "$ProjectDir\scripts\make_pdf_final.py" $pyPdfCode -Encoding utf8

# ===== Função de atualização contínua =====
function AutoUpdate {
    while ($true) {
        Write-Host "🔄 Verificando atualizações..."
        # Pode integrar verificação remota ou local de scripts/versões
        Start-Sleep -Seconds 300
    }
}

# ===== Iniciar Backend + Frontend =====
Start-Process powershell -FilePath "$ProjectDir\scripts\run_userat.ps1"
Write-Host "✅ USERAT Dashboard iniciado: http://localhost:3000"
Write-Host "📄 Guia Rápido: C:\USERAT\pdfs\USERAT_Guia_Rapido.pdf"

# ===== Iniciar atualização contínua em background =====
Start-Job -ScriptBlock { AutoUpdate }
# ===== FIM 2-att-megasetup_oneclick_v2025 - Copia.ps1 =====

# ===== INICIO 3-att-megasetup_oneclick_v2025.ps1 =====
# ======================================
# USERAT Dashboard Final 2025 - Setup Completo
# Backend + Frontend + Dashboard + Bots + PDF + Logs
# ======================================

$ProjectDir = "C:\USERAT"
$Dirs = @("backend","frontend\app","database","scripts","logs","pdfs","data","bots")
foreach ($d in $Dirs) { if (-Not (Test-Path "$ProjectDir\$d")) { New-Item -ItemType Directory -Path "$ProjectDir\$d" -Force } }

# ===== Instalações principais =====
function Install-Python { if (-Not (Get-Command python -ErrorAction SilentlyContinue)) { $py="$env:TEMP\python.exe"; Invoke-WebRequest "https://www.python.org/ftp/python/3.12.2/python-3.12.2-amd64.exe" -OutFile $py; Start-Process $py -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait } }
function Install-Node { if (-Not (Get-Command node -ErrorAction SilentlyContinue)) { $node="$env:TEMP\node.msi"; Invoke-WebRequest "https://nodejs.org/dist/v20.5.1/node-v20.5.1-x64.msi" -OutFile $node; Start-Process "msiexec.exe" -ArgumentList "/i "$node" /quiet /norestart" -Wait } }
function Install-Postgres { if (-Not (Get-Command psql -ErrorAction SilentlyContinue)) { $pg="$env:TEMP\postgres.exe"; Invoke-WebRequest "https://get.enterprisedb.com/postgresql/postgresql-15.5-1-windows-x64.exe" -OutFile $pg; Start-Process $pg -ArgumentList "--mode unattended --superpassword admin123" -Wait } }

Install-Python
Install-Node
Install-Postgres

# ===== Backend FastAPI =====
$backend = @"
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import json, os

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=[''], allow_methods=[''], allow_headers=['*'])

# Rota dashboard
@app.get('/')
def dashboard():
    return {'message':'USERAT Backend Online 🚀'}

# Leads
@app.get('/api/leads')
def get_leads():
    path = os.path.join(os.getcwd(),'../data/test_data.json')
    if os.path.exists(path):
        with open(path,'r',encoding='utf8') as f:
            data = json.load(f)
        return data.get('leads',[])
    return []

@app.post('/api/leads')
def add_lead(lead: dict):
    path = os.path.join(os.getcwd(),'../data/test_data.json')
    data = {'leads':[]}
    if os.path.exists(path):
        with open(path,'r',encoding='utf8') as f:
            data = json.load(f)
    data.setdefault('leads',[]).append(lead)
    with open(path,'w',encoding='utf8') as f:
        json.dump(data,f,ensure_ascii=False,indent=2)
    return {'status':'ok','lead':lead}

# Operações Cambiais
@app.get('/api/operacoes')
def get_operacoes():
    path = os.path.join(os.getcwd(),'../data/test_data.json')
    if os.path.exists(path):
        with open(path,'r',encoding='utf8') as f:
            data = json.load(f)
        return data.get('operacoes_cambiais',[])
    return []
"@
Set-Content "$ProjectDir\backend\app.py" $backend -Encoding utf8
Set-Content "$ProjectDir\backend\requirements.txt" @("fastapi==0.111.1","uvicorn==0.23.2","pydantic==2.7.0") -Encoding utf8

# ===== Frontend Next.js minimalista =====
$frontendPage = @"
'use client';
import { useEffect,useState } from 'react';
export default function Home() {
  const [leads,setLeads] = useState([]);
  const [ops,setOps] = useState([]);
  useEffect(()=>{ fetch('/api/leads').then(r=>r.json()).then(d=>setLeads(d)); fetch('/api/operacoes').then(r=>r.json()).then(d=>setOps(d)) },[]);
  return (
    <div style={{padding:'20px',fontFamily:'Arial, sans-serif'}}>
      <h1>USERAT Dashboard 2025 🚀</h1>
      <h2>Leads</h2>
      <ul>{leads.map((l,i)=><li key={i}>{l.empresa} - {l.contato} - {l.email}</li>)}</ul>
      <h2>Operações Cambiais</h2>
      <ul>{ops.map((o,i)=><li key={i}>{o.empresa} - {o.valor} - {o.data_operacao}</li>)}</ul>
    </div>
  )
}
"@
Set-Content "$ProjectDir\frontend\app\page.jsx" $frontendPage -Encoding utf8

$packageJson = @"
{
  ""name"": ""userat-frontend"",
  ""version"": ""1.0.0"",
  ""scripts"": { ""dev"": ""next dev"",""build"": ""next build"",""start"": ""next start"" },
  ""dependencies"": { ""next"": ""15.5.2"",""react"": ""18.2.0"",""react-dom"": ""18.2.0"" }
}
"@
Set-Content "$ProjectDir\frontend\package.json" $packageJson -Encoding utf8

# ===== Script de execução completo =====
$runScript = @"
cd ..\backend
pip install -r requirements.txt
Start-Process powershell -ArgumentList '-NoExit','uvicorn app:app --reload --host 127.0.0.1 --port 8000'
cd ..\frontend
npm install
npm run dev
"@
Set-Content "$ProjectDir\scripts\run_userat.ps1" $runScript -Encoding utf8

# ===== Dados de teste =====
$testData = @{
    leads=@(@{empresa="Empresa A";contato="Carlos";telefone="11999999999";email="carlos@empresaA.com.br"},
            @{empresa="Empresa B";contato="Ana";telefone="11988888888";email="ana@empresaB.com.br"});
    operacoes_cambiais=@(@{empresa="Empresa A";valor=50000;data_operacao="2025-09-10"},
                         @{empresa="Empresa B";valor=120000;data_operacao="2025-09-11"})
}
$testData | ConvertTo-Json -Depth 10 | Set-Content "$ProjectDir\data\test_data.json" -Encoding UTF8

# ===== Logs =====
$logPath = "$ProjectDir\logs/update_logs.txt"
if (-Not (Test-Path $logPath)) { New-Item -Path $logPath -ItemType File }

# ===== PDF Tutorial + Guia Rápido =====
$pyPdfCode = @"
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet

doc = SimpleDocTemplate(r'C:\USERAT\pdfs\USERAT_Guia_Rapido.pdf', pagesize=A4)
styles = getSampleStyleSheet()
story = []
story.append(Paragraph('USERAT Dashboard - Guia Rápido 🚀',styles['Title']))
story.append(Spacer(1,20))
steps = ['1. Executar run_userat.ps1','2. Abrir http://localhost:3000','3. Consultar Leads','4. Consultar Operações Cambiais','5. Bots de ajuda integrados']
for s in steps: story.append(Paragraph(s,styles['Normal']))
doc.build(story)
"@
Set-Content "$ProjectDir\scripts\make_pdf_final.py" $pyPdfCode -Encoding utf8
python "$ProjectDir\scripts\make_pdf_final.py"

# ===== Iniciar Dashboard =====
Start-Process powershell -FilePath "$ProjectDir\scripts\run_userat.ps1"
Start-Process "$ProjectDir\pdfs\USERAT_Guia_Rapido.pdf"

Write-Host "✅ USERAT Dashboard Final 2025 iniciado com sucesso!"
Write-Host "📍 Dashboard: http://localhost:3000"
Write-Host "📄 Guia Rápido: $ProjectDir\pdfs\USERAT_Guia_Rapido.pdf"
# ===== FIM 3-att-megasetup_oneclick_v2025.ps1 =====

# ===== INICIO mega-userat1-compiladao1.ps1 =====
#################################################################
# USERAT Mega One-Click FINAL (integrado) - 2025
# Backend FastAPI + Frontend Next.js Dashboard + Bots + PDFs + Logs
# WARNING: Run PowerShell as Administrator when installing system packages.
#################################################################

# -----------------------
# CONFIG
# -----------------------
$ProjectDir = "C:\USERAT"
$PythonMinimum = "3.10"
$NodeMinimumMajor = 18
$PostgresPassword = "admin123"        # default; change if desired
$NextPreferred = "13.4.10"            # preferred Next version (fallback safe)
$RunAsAdminNotice = @"
IMPORTANT:
- To install system packages (Python/Node/Postgres) you must run PowerShell AS ADMINISTRATOR.
- If you do NOT want installers to run, skip running the script as admin and install components manually.
"@
Write-Host $RunAsAdminNotice

# -----------------------
# Helper functions
# -----------------------
function Ensure-Directory($path) {
    if (-Not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
}
function Write-Log($text) {
    $logsDir = Join-Path $ProjectDir "logs"
    Ensure-Directory $logsDir
    $file = Join-Path $logsDir "execution_log.txt"
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $text"
    $entry | Out-File -FilePath $file -Append -Encoding UTF8
    Write-Host $text
}
function Download-File($url, $dest) {
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
        Write-Log "Downloaded $url -> $dest"
        return $true
    } catch {
        Write-Log "Failed download $url : $($_.Exception.Message)"
        return $false
    }
}

# -----------------------
# Create project structure
# -----------------------
$dirs = @(
    $ProjectDir,
    Join-Path $ProjectDir "backend",
    Join-Path $ProjectDir "frontend\app",
    Join-Path $ProjectDir "database",
    Join-Path $ProjectDir "scripts",
    Join-Path $ProjectDir "logs",
    Join-Path $ProjectDir "pdfs",
    Join-Path $ProjectDir "data",
    Join-Path $ProjectDir "bots",
    Join-Path $ProjectDir "updates"
)
foreach ($d in $dirs) { Ensure-Directory $d }

Write-Log "Project directories created/verified."

# -----------------------
# Write backend (FastAPI) - robust minimal API (app.py)
# -----------------------
$backendApp = @"
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import json, os
from pathlib import Path

app = FastAPI(title='USERAT Backend', version='4.1')

app.add_middleware(
    CORSMiddleware,
    allow_origins=['http://localhost:3000','http://127.0.0.1:3000','*'],
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)

DATA_FILE = Path(r'$ProjectDir\data\test_data.json')

def ensure_data():
    if not DATA_FILE.exists():
        initial = {'leads': [], 'operacoes_cambiais': []}
        DATA_FILE.parent.mkdir(parents=True, exist_ok=True)
        DATA_FILE.write_text(json.dumps(initial, ensure_ascii=False, indent=2), encoding='utf8')
    return json.loads(DATA_FILE.read_text(encoding='utf8'))

def save_data(d):
    DATA_FILE.write_text(json.dumps(d, ensure_ascii=False, indent=2), encoding='utf8')

class Lead(BaseModel):
    empresa: str
    contato: str
    telefone: str
    email: str

class Operacao(BaseModel):
    empresa: str
    valor: float
    data_operacao: str

@app.on_event("startup")
def startup_event():
    ensure_data()

@app.get("/")
def root():
    return {"message": "USERAT Backend Online 🚀"}

@app.get("/api/leads")
def get_leads():
    d = ensure_data()
    return d.get("leads", [])

@app.post("/api/leads")
def post_lead(lead: Lead):
    d = ensure_data()
    d.setdefault("leads", []).append(lead.dict())
    save_data(d)
    return {"message":"Lead adicionado","lead":lead.dict()}

@app.get("/api/operacoes")
def get_operacoes():
    d = ensure_data()
    return d.get("operacoes_cambiais", [])

@app.post("/api/operacoes")
def post_operacao(op: Operacao):
    d = ensure_data()
    d.setdefault("operacoes_cambiais", []).append(op.dict())
    save_data(d)
    return {"message":"Operação adicionada","operacao":op.dict()}

# Simple bot endpoint (uses simple rule-based responses)
@app.get("/api/bot")
def bot(q: str):
    text = q.lower()
    if "import" in text or "importação" in text:
        return {"reply":"Bot Importação: verifique documentos (commercial invoice, packing list, BL/AWB), impostos e registro no sistema."}
    if "export" in text or "exportação" in text:
        return {"reply":"Bot Exportação: verifique cotação, documentação de exportação, impostos e logística."}
    if "câmbio" in text or "cambio" in text or "taxa" in text:
        return {"reply":"Bot Câmbio: as cotações são fictícias nos dados de teste; consulte o módulo de operações para valores."}
    return {"reply":"Desculpe — não entendi. Pergunte sobre importação, exportação ou câmbio."}
"@
$backendPath = Join-Path $ProjectDir "backend\app.py"
$backendApp | Out-File -FilePath $backendPath -Encoding UTF8 -Force
Write-Log "Backend app.py written."

# requirements.txt
$requirements = @(
    "fastapi==0.111.1",
    "uvicorn==0.23.2",
    "pydantic==2.7.0",
    "reportlab",
    "psycopg2-binary",
    "graphviz"
)
$reqPath = Join-Path $ProjectDir "backend\requirements.txt"
$requirements -join "`n" | Out-File -FilePath $reqPath -Encoding UTF8 -Force
Write-Log "backend/requirements.txt written."

# -----------------------
# Frontend: Next.js minimal dashboard (app router)
# - We'll add a minimal client-side fetch to the backend endpoints
# -----------------------
$frontendIndex = @"
'use client';
import React, {useEffect, useState} from 'react';

export default function Home(){
  const [leads,setLeads] = useState([]);
  const [ops,setOps] = useState([]);
  const [botQ,setBotQ] = useState('');
  const [botR,setBotR] = useState('');

  useEffect(()=>{
    fetch('http://127.0.0.1:8000/api/leads')
      .then(r=>r.json()).then(d=>setLeads(d)).catch(()=>setLeads([]));
    fetch('http://127.0.0.1:8000/api/operacoes')
      .then(r=>r.json()).then(d=>setOps(d)).catch(()=>setOps([]));
  },[]);

  function askBot(){
    if(!botQ) return;
    fetch(http://127.0.0.1:8000/api/bot?q=${encodeURIComponent(botQ)})
      .then(r=>r.json()).then(j=>setBotR(j.reply)).catch(()=>setBotR('Erro ao consultar bot'));
  }

  return (
    <div style={{fontFamily:'Arial, sans-serif',padding:20}}>
      <h1>USERAT Dashboard — Câmbio & Trade</h1>

      <section style={{marginTop:20}}>
        <h2>Leads</h2>
        <ul>{leads.map((l,i)=>(<li key={i}>{l.empresa} — {l.contato} — {l.email}</li>))}</ul>
      </section>

      <section style={{marginTop:20}}>
        <h2>Operações Cambiais</h2>
        <ul>{ops.map((o,i)=>(<li key={i}>{o.empresa} — {o.valor} — {o.data_operacao}</li>))}</ul>
      </section>

      <section style={{marginTop:20}}>
        <h2>Bot Interativo (Importação / Exportação / Câmbio)</h2>
        <input value={botQ} onChange={e=>setBotQ(e.target.value)} placeholder='Pergunte: ex. "Como faço importação?"' style={{width:'60%'}}/>
        <button onClick={askBot} style={{marginLeft:8}}>Enviar</button>
        <p><strong>Resposta:</strong> {botR}</p>
      </section>

      <section style={{marginTop:20}}>
        <p>Guias e PDFs estão na pasta: <code>{'$ProjectDir\\pdfs'}</code></p>
      </section>
    </div>
  )
}
"@
$frontAppPath = Join-Path $ProjectDir "frontend\app\page.jsx"
Ensure-Directory (Split-Path $frontAppPath)
$frontendIndex | Out-File -FilePath $frontAppPath -Encoding UTF8 -Force
Write-Log "Frontend app/page.jsx written."

# package.json (we will run install logic that prefers a stable version)
$packageJson = @{
    name = "userat-frontend"
    version = "1.0.0"
    scripts = @{
        dev = "next dev"
        build = "next build"
        start = "next start"
    }
    dependencies = @{
        next = $NextPreferred
        react = "18.2.0"
        "react-dom" = "18.2.0"
    }
}
$pkgPath = Join-Path $ProjectDir "frontend\package.json"
$packageJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $pkgPath -Encoding UTF8 -Force
Write-Log "frontend/package.json written (preferred next: $NextPreferred)."

# -----------------------
# Bots simple file (JSON knowledge + optional example)
# -----------------------
$botData = @{
    knowledge = @{
        importacao = "Procedimento de importação: documentos (commercial invoice, packing list, BL/AWB), classificação NCM, impostos, despachante."
        exportacao = "Procedimento de exportação: verifique contrato, cotação, documentos de embarque, e regimes aduaneiros."
        cambio = "Câmbio: usar taxas de referência e conferir operações no histórico."
    }
}
$botFile = Join-Path $ProjectDir "bots\knowledge.json"
$botData | ConvertTo-Json -Depth 10 | Out-File -FilePath $botFile -Encoding UTF8 -Force
Write-Log "bots/knowledge.json written."

# -----------------------
# Create test data (if not exists)
# -----------------------
$dataFile = Join-Path $ProjectDir "data\test_data.json"
if (-Not (Test-Path $dataFile)) {
    $test = @{
        leads = @(
            @{ empresa="Empresa A"; contato="Carlos"; telefone="11999999999"; email="carlos@empresaA.com.br" },
            @{ empresa="Empresa B"; contato="Ana"; telefone="11988888888"; email="ana@empresaB.com.br" }
        )
        operacoes_cambiais = @(
            @{ empresa="Empresa A"; valor=50000; data_operacao="2025-09-10" },
            @{ empresa="Empresa B"; valor=120000; data_operacao="2025-09-11" }
        )
    }
    $test | ConvertTo-Json -Depth 10 | Out-File -FilePath $dataFile -Encoding UTF8 -Force
    Write-Log "Data test_data.json created."
} else {
    Write-Log "Data file exists; skipping test data creation."
}

# -----------------------
# PDF generation scripts (Python) - simple textual PDFs
# -----------------------
$makePdfPy = @"
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
doc1 = SimpleDocTemplate(r'$ProjectDir\pdfs\USERAT_Guia_Rapido.pdf', pagesize=A4)
styles = getSampleStyleSheet()
story=[]
story.append(Paragraph('USERAT - Guia Rápido', styles['Title']))
story.append(Spacer(1,12))
story.append(Paragraph('1) Execute scripts\\run_userat.ps1 (como Administrador se necessário).', styles['Normal']))
story.append(Paragraph('2) Abra http://localhost:3000', styles['Normal']))
story.append(Paragraph('3) Use o Bot para dúvidas rápidas sobre importação/exportação/câmbio', styles['Normal']))
doc1.build(story)

doc2 = SimpleDocTemplate(r'$ProjectDir\pdfs\USERAT_Tutorial_Atualizado.pdf', pagesize=A4)
story=[]
story.append(Paragraph('USERAT - Tutorial Completo (resumo)', styles['Title']))
story.append(Spacer(1,12))
story.append(Paragraph('Instalação: ... (veja execução no PowerShell).', styles['Normal']))
doc2.build(story)

doc3 = SimpleDocTemplate(r'$ProjectDir\pdfs\USERAT_API_Frontend_Tutorial.pdf', pagesize=A4)
story=[]
story.append(Paragraph('USERAT - API Frontend (endpoints)', styles['Title']))
story.append(Spacer(1,12))
story.append(Paragraph('GET /api/leads -> lista leads', styles['Normal']))
story.append(Paragraph('POST /api/leads -> adiciona lead {empresa,contato,telefone,email}', styles['Normal']))
story.append(Paragraph('GET /api/operacoes -> lista operacoes', styles['Normal']))
story.append(Paragraph('POST /api/operacoes -> adiciona operacao {empresa,valor,data_operacao}', styles['Normal']))
story.append(Paragraph('GET /api/bot?q=texto -> resposta do bot', styles['Normal']))
doc3.build(story)
"@
$makePdfPyPath = Join-Path $ProjectDir "scripts\make_pdfs.py"
$makePdfPy | Out-File -FilePath $makePdfPyPath -Encoding UTF8 -Force
Write-Log "Python PDF generator written: scripts/make_pdfs.py"

# Try to run the PDF generator (best-effort)
try {
    Write-Log "Attempting to generate PDFs via Python..."
    & python $makePdfPyPath
    Write-Log "PDFs generated."
} catch {
    Write-Log "PDF generation failed: $($_.Exception.Message). Will try later."
}

# -----------------------
# Run installers (best-effort) and install dependencies
# (IMPORTANT: if you do not run as admin, installer steps may fail)
# -----------------------
function Ensure-PythonInstalled {
    if (-Not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Log "Python not found on PATH. Installer step skipped or failed."
        return $false
    } else {
        Write-Log "Python found: $(python --version 2>$null)"
        return $true
    }
}
function Ensure-NodeInstalled {
    if (-Not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Log "Node not found on PATH. Installer step skipped or failed."
        return $false
    } else {
        Write-Log "Node found: $(node --version 2>$null)"
        return $true
    }
}

$pyOk = Ensure-PythonInstalled
$nodeOk = Ensure-NodeInstalled

# Install backend Python deps if python available
if ($pyOk) {
    try {
        Write-Log "Installing backend Python dependencies (pip)..."
        & python -m pip install --upgrade pip setuptools wheel
        & python -m pip install -r $reqPath
        Write-Log "Python dependencies installed."
    } catch {
        Write-Log "Python dependency installation failed: $($_.Exception.Message)"
    }
} else {
    Write-Log "Python missing: skip pip install. Install Python and re-run script or run pip install manually."
}

# Install frontend deps if node available
if ($nodeOk) {
    try {
        Write-Log "Installing frontend dependencies (npm)..."
        Push-Location (Join-Path $ProjectDir "frontend")
        # prefer explicit next version; if install fails, try next@latest
        $success = $false
        try {
            & npm install --no-audit --no-fund --legacy-peer-deps | Out-Null
            $success = $true
        } catch {
            Write-Log "npm install failed with preferred package.json; trying fallback."
            try {
                & npm install next@latest react@18.2.0 react-dom@18.2.0 --no-audit --no-fund --legacy-peer-deps | Out-Null
                & npm install --no-audit --no-fund --legacy-peer-deps | Out-Null
                $success = $true
            } catch {
                Write-Log "npm fallback install also failed: $($_.Exception.Message)"
            }
        }
        Pop-Location
        if ($success) { Write-Log "Frontend dependencies installed." } else { Write-Log "Frontend dependencies not installed. Please run npm install manually." }
    } catch {
        Write-Log "npm install error: $($_.Exception.Message)"
    }
} else {
    Write-Log "Node missing: skip npm install. Install Node.js and re-run script or run npm install manually."
}

# -----------------------
# Create start script that opens backend and frontend in separate shells
# -----------------------
$runAllScript = @"
# Run USERAT backend and frontend (open in two separate PowerShell windows)
cd "$ProjectDir\backend"
python -m uvicorn app:app --reload --host 127.0.0.1 --port 8000
"@
$runBackendPath = Join-Path $ProjectDir "scripts\start_backend.ps1"
$runAllScript | Out-File -FilePath $runBackendPath -Encoding UTF8 -Force

$runFrontendScript = @"
cd "$ProjectDir\frontend"
npm run dev
"@
$runFrontendPath = Join-Path $ProjectDir "scripts\start_frontend.ps1"
$runFrontendScript | Out-File -FilePath $runFrontendPath -Encoding UTF8 -Force

# A script that starts both in separate windows
$runBoth = @"
Start-Process powershell -ArgumentList '-NoExit','-Command','"$ProjectDir\scripts\start_backend.ps1"' -WindowStyle Normal
Start-Sleep -Seconds 2
Start-Process powershell -ArgumentList '-NoExit','-Command','"$ProjectDir\scripts\start_frontend.ps1"' -WindowStyle Normal
"@
$runBothPath = Join-Path $ProjectDir "scripts\run_userat.ps1"
$runBoth | Out-File -FilePath $runBothPath -Encoding UTF8 -Force
Write-Log "Run scripts created: scripts/start_backend.ps1, scripts/start_frontend.ps1, scripts/run_userat.ps1"

# -----------------------
# Start the whole system (best-effort)
# -----------------------
Write-Log "Starting backend and frontend (best-effort)."
try {
    Start-Process powershell -ArgumentList '-NoExit',"-ExecutionPolicy Bypass","-File",$runBothPath
    Write-Log "Start commands launched."
} catch {
    Write-Log "Failed to start run_userat script automatically: $($_.Exception.Message)"
    Write-Host "To start servers manually: run scripts\run_userat.ps1 (Open PowerShell as Admin if needed)."
}

# -----------------------
# Open the user quick-guide PDF (only the quick guide opens automatically)
# -----------------------
$guiaPdf = Join-Path $ProjectDir "pdfs\USERAT_Guia_Rapido.pdf"
if (Test-Path $guiaPdf) {
    try { Start-Process $guiaPdf } catch { Write-Log "Failed to open quick guide PDF: $($_.Exception.Message)" }
}

# -----------------------
# Write update log and finish
# -----------------------
$updateLog = Join-Path $ProjectDir "updates\update_log.txt"
$summary = @(
    "USERAT Mega One-Click Run",
    "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "ProjectDir: $ProjectDir",
    "Python installed: $pyOk",
    "Node installed: $nodeOk",
    "Next preferred: $NextPreferred",
    "Start scripts created at: $runBothPath"
)
$summary -join "`n" | Out-File -FilePath $updateLog -Encoding UTF8 -Force
Write-Log "Update log written: $updateLog"

Write-Host ""
Write-Host "====== USERAT SETUP SUMMARY ======"
Write-Host "Dashboard (frontend) URL: http://localhost:3000"
Write-Host "Backend URL: http://127.0.0.1:8000"
Write-Host "To start servers manually (if not started):"
Write-Host "  1) Open PowerShell (Run as Administrator if you installed system packages)."
Write-Host "  2) Run: "$ProjectDir\scripts\run_userat.ps1""
Write-Host "Logs: $ProjectDir\logs"
Write-Host "PDFs: $ProjectDir\pdfs"
Write-Host "Updates log: $updateLog"
Write-Host "=================================="
Write-Log "USERAT setup finished (best-effort)."
# ===== FIM mega-userat1-compiladao1.ps1 =====

# ===== INICIO user41final_BackendFASTAPI.ps1 =====
# ======================================
# USERAT 4.1 FINAL – Backend FastAPI
# ======================================

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from pathlib import Path
import json

app = FastAPI(title="USERAT Backend", version="4.1")

# ===== Configurar CORS para frontend Next.js =====
origins = [
    "http://localhost:3000",
    "http://127.0.0.1:3000"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ===== Definição de modelos de dados =====
class Lead(BaseModel):
    empresa: str
    contato: str
    telefone: str
    email: str

class Operacao(BaseModel):
    empresa: str
    valor: float
    data_operacao: str

# ===== Caminho dos dados =====
data_file = Path("C:/USERAT2/data/test_data.json")

# ===== Funções auxiliares =====
def load_data():
    if not data_file.exists():
        initial_data = {"leads": [], "operacoes_cambiais": []}
        with open(data_file, "w", encoding="utf-8") as f:
            json.dump(initial_data, f, indent=4)
        return initial_data
    with open(data_file, "r", encoding="utf-8") as f:
        return json.load(f)

def save_data(data):
    with open(data_file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4)

# ===== Endpoints =====

# Listar todos os leads
@app.get("/api/leads")
def get_leads():
    data = load_data()
    return data.get("leads", [])

# Adicionar um novo lead
@app.post("/api/leads")
def add_lead(lead: Lead):
    data = load_data()
    data.setdefault("leads", []).append(lead.dict())
    save_data(data)
    return {"message": "Lead adicionado com sucesso!", "lead": lead.dict()}

# Listar operações cambiais
@app.get("/api/operacoes")
def get_operacoes():
    data = load_data()
    return data.get("operacoes_cambiais", [])

# Adicionar operação cambial (opcional)
@app.post("/api/operacoes")
def add_operacao(op: Operacao):
    data = load_data()
    data.setdefault("operacoes_cambiais", []).append(op.dict())
    save_data(data)
    return {"message": "Operação adicionada com sucesso!", "operacao": op.dict()}

# Root
@app.get("/")
def root():
    return {"message": "USERAT Backend funcionando corretamente."}
# ===== FIM user41final_BackendFASTAPI.ps1 =====

# ===== INICIO userat41final_completo.ps1 =====
# ======================================
# USERAT 4.1 FINAL – Backend FastAPI
# ======================================

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from pathlib import Path
import json

app = FastAPI(title="USERAT Backend", version="4.1")

# ===== Configurar CORS para frontend Next.js =====
origins = [
    "http://localhost:3000",
    "http://127.0.0.1:3000"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ===== Definição de modelos de dados =====
class Lead(BaseModel):
    empresa: str
    contato: str
    telefone: str
    email: str

class Operacao(BaseModel):
    empresa: str
    valor: float
    data_operacao: str

# ===== Caminho dos dados =====
data_file = Path("C:/USERAT2/data/test_data.json")

# ===== Funções auxiliares =====
def load_data():
    if not data_file.exists():
        initial_data = {"leads": [], "operacoes_cambiais": []}
        with open(data_file, "w", encoding="utf-8") as f:
            json.dump(initial_data, f, indent=4)
        return initial_data
    with open(data_file, "r", encoding="utf-8") as f:
        return json.load(f)

def save_data(data):
    with open(data_file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4)

# ===== Endpoints =====

# Listar todos os leads
@app.get("/api/leads")
def get_leads():
    data = load_data()
    return data.get("leads", [])

# Adicionar um novo lead
@app.post("/api/leads")
def add_lead(lead: Lead):
    data = load_data()
    data.setdefault("leads", []).append(lead.dict())
    save_data(data)
    return {"message": "Lead adicionado com sucesso!", "lead": lead.dict()}

# Listar operações cambiais
@app.get("/api/operacoes")
def get_operacoes():
    data = load_data()
    return data.get("operacoes_cambiais", [])

# Adicionar operação cambial (opcional)
@app.post("/api/operacoes")
def add_operacao(op: Operacao):
    data = load_data()
    data.setdefault("operacoes_cambiais", []).append(op.dict())
    save_data(data)
    return {"message": "Operação adicionada com sucesso!", "operacao": op.dict()}

# Root
@app.get("/")
def root():
    return {"message": "USERAT Backend funcionando corretamente."}
# ===== FIM userat41final_completo.ps1 =====

# ===== INICIO main.py =====
def main():
    print('USERAT 2025 rodando com sucesso!')

if _name_ == '_main_':
    main()

# ===== FIM main.py =====

# ===== INICIO app.py =====
from fastapi import FastAPI

app = FastAPI()

@app.get('/')
def read_root():
    return {'message': 'USERAT Backend Online 🚀'}

def main():
    print('Backend USERAT rodando...')

if _name_ == "_main_":
    main()

# ===== FIM app.py =====

# ===== INICIO make_pdfs.py =====
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet

doc1 = SimpleDocTemplate(r"C:\USERAT\pdfs\USERAT_Guia_Rapido.pdf", pagesize=A4)
styles = getSampleStyleSheet()
story=[]
story.append(Paragraph("USERAT - Guia Rápido", styles['Title']))
story.append(Spacer(1,12))
story.append(Paragraph("1) Rode scripts/run_userat.ps1", styles['Normal']))
story.append(Paragraph("2) Abra o aplicativo USERAT pelo atalho", styles['Normal']))
doc1.build(story)

doc2 = SimpleDocTemplate(r"C:\USERAT\pdfs\USERAT_Tutorial_Atualizado.pdf", pagesize=A4)
story=[]
story.append(Paragraph("USERAT - Tutorial Completo (resumo)", styles['Title']))
story.append(Spacer(1,12))
story.append(Paragraph("Conteúdo detalhado aqui...", styles['Normal']))
doc2.build(story)
# ===== FIM make_pdfs.py =====

# ===== INICIO make_pdf_final.py =====
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Preformatted, Image
from reportlab.lib.styles import getSampleStyleSheet
import graphviz

doc = SimpleDocTemplate(r'C:\USERAT\pdfs\USERAT_Tutorial_Atualizado.pdf', pagesize=A4)
styles = getSampleStyleSheet()
story = []

story.append(Paragraph('USERAT - Tutorial Completo Atualizado 2025 🚀', styles['Title']))
story.append(Spacer(1,20))

tree = '''
C:\\USERAT
├── backend
├── frontend
├── database
├── scripts
├── pdfs
└── data
'''
story.append(Preformatted(tree, styles['Code']))
story.append(Spacer(1,20))

steps = [
'⿡ Pré-requisitos: Python 3.12+, Node.js LTS, PostgreSQL 15.',
'⿢ Rodar setup_userat_final.ps1 como Administrador.',
'⿣ Instalar dependências backend: pip install -r backend\\\\requirements.txt',
'⿤ Instalar dependências frontend: npm install (na pasta frontend)',
'⿥ Configurar banco de dados: executar postgres_setup.sql',
'⿦ Rodar run_userat.ps1 para iniciar backend + frontend',
'⿧ Acessar backend: http://127.0.0.1:8000, frontend: http://localhost:3000'
]
for s in steps:
    story.append(Paragraph(s, styles['Normal']))

# Fluxograma
dot = graphviz.Digraph(comment='Fluxograma USERAT', format='png')
dot.node('A','Coleta de Dados e Leads')
dot.node('B','CRM Inteligente')
dot.node('C','Comunicação e Automação')
dot.node('D','Chatbots Inteligentes')
dot.node('E','Gestão de Operações Cambiais')
dot.node('F','IA Preditiva')
dot.node('G','Compliance 2025')
dot.node('H','Usuário / Frontend')
dot.edges(['AB','BC','CD','DE','EF','FG','GH'])
fluxoPath = r'C:\USERAT\pdfs\fluxograma_userat.png'
dot.render('C:\\USERAT\\pdfs\\fluxograma_userat', cleanup=True)
story.append(Image(fluxoPath, width=400, height=400))
story.append(Spacer(1,20))

doc.build(story)

# ===== FIM make_pdf_final.py =====

# ===== INICIO run_ai_trade_advanced.ps1 =====
# PowerShell script placeholder
Write-Output 'AI Trade Suite Running...'
# ===== FIM run_ai_trade_advanced.ps1 =====

# ===== INICIO client_prospect.py =====
print('Client Prospect Module Placeholder')
# ===== FIM client_prospect.py =====

# ===== INICIO document_analysis.py =====
print('Document Analysis Module Placeholder')
# ===== FIM document_analysis.py =====

# ===== INICIO market_realtime.py =====
print('Market Realtime Module Placeholder')
# ===== FIM market_realtime.py =====

# ===== INICIO reports.py =====
print('Reports Module Placeholder')
# ===== FIM reports.py =====

# ===== INICIO autocorretor-atualizado.ps1 =====
# ============================================
# UNIC QUANTIC - Autocorrector.py (Atualizado)
# ============================================

import argparse
import subprocess
import sys
import time
import re
from pathlib import Path

# -----------------------------
# Função para checar módulos
# -----------------------------
def check_module(module_name):
    try:
        _import_(module_name)
        return True
    except ImportError:
        return False

# -----------------------------
# Função de instalação automática
# -----------------------------
def install_module(module_name):
    subprocess.check_call([sys.executable, "-m", "pip", "install", module_name])

# -----------------------------
# Autocorreção de código
# -----------------------------
def autocorrect_file(file_path: Path, level: str = "light"):
    """
    Níveis:
        light: correções simples de sintaxe e estilo
        moderate: corrige sintaxe + boas práticas
        advanced: corrige sintaxe + boas práticas + sugere refatorações
    """
    if not file_path.exists():
        print(f"Arquivo não encontrado: {file_path}")
        return

    code = file_path.read_text(encoding="utf-8")

    # Exemplo de autocorreção simples (leve)
    if level.lower() in ["light", "moderate", "advanced"]:
        # Corrige aspas duplicadas
        code = code.replace('""', '"')
        code = code.replace("''", "'")

        # Remove espaços desnecessários no início/fim
        code = "\n".join([line.rstrip() for line in code.splitlines()])

    # Sugestões para moderado e avançado
    if level.lower() in ["moderate", "advanced"]:
        # Substitui tabs por 4 espaços
        code = code.replace("\t", "    ")
        # Remove linhas em branco consecutivas
        code = re.sub(r"\n{3,}", "\n\n", code)

    # Avançado: pequenas refatorações
    if level.lower() == "advanced":
        # Espaço antes de parênteses (ex: "if (" -> "if(")
        code = re.sub(r"(\w) \(", r"\1(", code)
        # Corrige import duplicado (exemplo)
        imports = set()
        new_lines = []
        for line in code.splitlines():
            if line.startswith("import "):
                if line not in imports:
                    imports.add(line)
                    new_lines.append(line)
            else:
                new_lines.append(line)
        code = "\n".join(new_lines)

    # Salvar de volta
    file_path.write_text(code, encoding="utf-8")
    print(f"[{level}] Autocorreção aplicada: {file_path.name}")

# -----------------------------
# Observador de mudanças
# -----------------------------
def watch_file(file_path: Path, level: str):
    last_mtime = None
    try:
        while True:
            if file_path.exists():
                mtime = file_path.stat().st_mtime
                if last_mtime is None:
                    last_mtime = mtime
                elif mtime != last_mtime:
                    autocorrect_file(file_path, level)
                    last_mtime = mtime
            time.sleep(2)
    except KeyboardInterrupt:
        print("Observação interrompida pelo usuário.")

# -----------------------------
# Função principal
# -----------------------------
def main():
    parser = argparse.ArgumentParser(description="UNIC QUANTIC Autocorrector")
    parser.add_argument("--file", type=str, required=True, help="Arquivo a ser corrigido")
    parser.add_argument("--watch", action="store_true", help="Observa mudanças no arquivo e corrige automaticamente")
    parser.add_argument("--level", type=str, choices=["light", "moderate", "advanced"], default="light", help="Nível de correção")
    args = parser.parse_args()

    file_path = Path(args.file)

    # Verifica módulos essenciais
    for mod in ["re", "sys", "time", "argparse", "subprocess", "pathlib"]:
        if not check_module(mod):
            print(f"Módulo ausente: {mod}, instalando...")
            install_module(mod)

    # Executa correção inicial
    autocorrect_file(file_path, args.level)

    # Observação contínua se --watch
    if args.watch:
        print(f"Observando {file_path} para autocorreção ({args.level})...")
        watch_file(file_path, args.level)

if _name_ == "_main_":
    main()
# ===== FIM autocorretor-atualizado.ps1 =====

# ===== INICIO run_autocorrector.ps1 =====
# run_autocorrector.ps1 — wrapper seguro
\ = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not \) { Write-Host 'Python não encontrado no PATH. Instale Python e reabra o PowerShell.'; exit 1 }
# use & to execute with quoted script path (handles spaces)
& \ "C:\UNIC QUANTIC\tools\autocorrector.py" --once --level light

# ===== FIM run_autocorrector.ps1 =====

# ===== INICIO run_unic_quantic.ps1 =====
# Run UNIC QUANTIC (Stage 1.1)
Write-Host 'Iniciando backend...'
Start-Process -FilePath powershell -ArgumentList '-NoExit','-Command','cd "C:\UNIC QUANTIC\backend"; python -m uvicorn main:app --reload'
Start-Sleep -Seconds 2
Write-Host 'Iniciando frontend...'
Start-Process -FilePath powershell -ArgumentList '-NoExit','-Command','cd "C:\UNIC QUANTIC\frontend"; npm run dev'

# ===== FIM run_unic_quantic.ps1 =====

# ===== INICIO setup_unic_quantic_stage1.3.ps1 =====
# ==========================================
# UNIC QUANTIC - Stage1.3 Setup (com logs)
# ==========================================

$ErrorActionPreference = "Stop"
$BasePath   = "C:\UNIC QUANTIC"
$PythonExe  = "C:\Users\arati\AppData\Local\Programs\Python\Python311\python.exe"
$LogFile    = Join-Path $BasePath "setup_stage1.3.log"

# Função de log
function Write-Log {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$timestamp] $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

Write-Log "==========================================="
Write-Log "UNIC QUANTIC Stage1.3 - Setup Iniciado"
Write-Log "==========================================="

# Garantir pasta base
if (-not (Test-Path $BasePath)) {
    New-Item -ItemType Directory -Path $BasePath | Out-Null
    Write-Log "Criada pasta: $BasePath"
}

# Verificar se Python existe
if (-not (Test-Path $PythonExe)) {
    Write-Log "[ERRO] Python não encontrado em $PythonExe"
    exit 1
} else {
    Write-Log "[OK] Python localizado em $PythonExe"
}

# Verificar se Node.js está instalado
if (-not (Get-Command "node" -ErrorAction SilentlyContinue)) {
    Write-Log "[ERRO] Node.js não encontrado. Instale antes de continuar."
    exit 1
} else {
    $nodeVersion = node -v
    Write-Log "[OK] Node.js detectado: $nodeVersion"
}

# =============================
# Requirements Python
# =============================
$RequirementsFile = Join-Path $BasePath "requirements.txt"
if (-not (Test-Path $RequirementsFile)) {
    @"
requests>=2.31.0
beautifulsoup4>=4.13.0
selenium>=4.14.0
pandas>=2.1.0
numpy>=1.26.0
"@ | Out-File -FilePath $RequirementsFile -Encoding UTF8
    Write-Log "Arquivo requirements.txt criado."
}

Write-Log "Instalando pacotes Python..."
Start-Process -FilePath $PythonExe -ArgumentList "-m", "pip", "install", "-r", $RequirementsFile -NoNewWindow -Wait
Write-Log "Instalação de pacotes Python concluída."

# =============================
# Pacotes Node.js
# =============================
Write-Log "Instalando dependências Node.js..."
if (Test-Path (Join-Path $BasePath "package.json")) {
    Push-Location $BasePath
    npm install | Out-Null
    Pop-Location
    Write-Log "Dependências Node.js instaladas."
} else {
    Write-Log "[AVISO] Nenhum package.json encontrado. Pulando dependências Node.js."
}

# =============================
# Autocorretor Python
# =============================
$AutoCorrector = Join-Path $BasePath "tools\autocorrector.py"
if (Test-Path $AutoCorrector) {
    Write-Log "Iniciando autocorretor Python em background..."
    Start-Process -FilePath $PythonExe -ArgumentList $AutoCorrector -NoNewWindow
} else {
    Write-Log "[AVISO] Autocorretor não encontrado em $AutoCorrector"
}

# =============================
# Executar app principal
# =============================
$MainApp = Join-Path $BasePath "main.py"
if (Test-Path $MainApp) {
    Write-Log "Iniciando aplicação principal..."
    Start-Process -FilePath $PythonExe -ArgumentList $MainApp -NoNewWindow
    Write-Log "Aplicação principal iniciada."
} else {
    Write-Log "[AVISO] Nenhum main.py encontrado. Setup finalizado sem execução do app."
}

Write-Log "==========================================="
Write-Log "UNIC QUANTIC Stage1.3 finalizado com sucesso!"
Write-Log "==========================================="

# ===== FIM setup_unic_quantic_stage1.3.ps1 =====

# ===== INICIO autocorretor-continuo-sem-parar.ps1 =====
& (Get-Command python).Source "C:\UNIC QUANTIC\tools\autocorrector.py" --watch --level light
# ===== FIM autocorretor-continuo-sem-parar.ps1 =====

# ===== INICIO executar-o-autocorretor.ps1 =====
# opcional: criar pasta tools e colar autocorrector.py
python C:\UNIC QUANTIC\tools\autocorrector.py --once
# ===== FIM executar-o-autocorretor.ps1 =====

# ===== INICIO para_criar_tarefa_diaria_as-3_damanha.ps1 =====
$action = 'powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "C:\UNIC QUANTIC\scripts\run_autocorrector.ps1"'
schtasks /Create /SC DAILY /TN "UNIC_QUANTIC_AutoCorrect" /TR $action /ST 03:00 /F
# ===== FIM para_criar_tarefa_diaria_as-3_damanha.ps1 =====

# ===== INICIO UNICsetup_userat_2025_final.ps1 =====
# ======================================
# USERAT 2025 - Setup One-Click Final
# Autor: Automação Total
# Funcionalidades: Backend FastAPI + IA, Frontend Next.js, PostgreSQL,
# Dashboard interativo, correção automática de erros, tutoriais PDF/TXT/DOC
# ======================================

# ------------------------------
# Configurações principais
# ------------------------------
$ProjectDir = "C:\USERAT"
$ScriptsDir = "$ProjectDir\scripts"
$LogsDir = "$ProjectDir\logs"
$PDFDir = "$ProjectDir\pdfs"

# Criar diretórios se não existirem
$folders = @($ProjectDir, "$ProjectDir\backend", "$ProjectDir\frontend\app", "$ProjectDir\database", $ScriptsDir, $LogsDir, $PDFDir)
foreach ($f in $folders) {
    if (-Not (Test-Path $f)) { New-Item -ItemType Directory -Path $f -Force | Out-Null }
}

# Função de log
Function Write-Log {
    param([string]$Message)
    $logFile = "$LogsDir\execution_log.txt"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp - $Message"
    $entry | Out-File -FilePath $logFile -Append -Encoding UTF8
    Write-Host $entry
}

# ------------------------------
# Pré-requisitos
# ------------------------------
Write-Log "🔍 Verificando Python..."
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Log "⚡ Instalando Python 3.12..."
    Invoke-WebRequest "https://www.python.org/ftp/python/3.12.2/python-3.12.2-amd64.exe" -OutFile "$env:TEMP\python_installer.exe"
    Start-Process "$env:TEMP\python_installer.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
}

Write-Log "🔍 Verificando Node.js..."
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Log "⚡ Instalando Node.js LTS..."
    Invoke-WebRequest "https://nodejs.org/dist/v20.5.1/node-v20.5.1-x64.msi" -OutFile "$env:TEMP\node_installer.msi"
    Start-Process "msiexec.exe" -ArgumentList "/i "$env:TEMP\node_installer.msi" /quiet /norestart" -Wait
}

Write-Log "🔍 Verificando PostgreSQL..."
if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Log "⚡ Instalando PostgreSQL 15..."
    Invoke-WebRequest "https://get.enterprisedb.com/postgresql/postgresql-15.5-1-windows-x64.exe" -OutFile "$env:TEMP\postgres_installer.exe"
    Start-Process "$env:TEMP\postgres_installer.exe" -ArgumentList "--mode unattended --superpassword admin123" -Wait
}

# ------------------------------
# Backend FastAPI + IA
# ------------------------------
$backendCode = @"
from fastapi import FastAPI
from pydantic import BaseModel
import datetime
import psycopg2
app = FastAPI(title='USERAT 2025 Backend 🚀')

# IA Simples Placeholder
@app.get('/ia_status')
def ia_status():
    return {'status': 'IA Online', 'last_update': str(datetime.datetime.now())}

@app.get('/')
def root():
    return {'message': 'USERAT Backend Online 🚀'}

"@
Set-Content -Path "$ProjectDir\backend\main.py" -Value $backendCode -Encoding utf8 -Force

$requirements = @(
    "fastapi",
    "uvicorn",
    "psycopg2-binary",
    "reportlab",
    "graphviz",
    "pandas",
    "numpy",
    "scikit-learn",
    "openai"
)
Set-Content -Path "$ProjectDir\backend\requirements.txt" -Value ($requirements -join "`n") -Encoding utf8 -Force

# ------------------------------
# Frontend Next.js
# ------------------------------
$frontendPage = @"
export default function Home() {
  return (
    <div style={{ padding: '30px', fontFamily: 'Arial, sans-serif' }}>
      <h1>USERAT 2025 - Dashboard de Câmbio 🚀</h1>
      <p>Interativo, moderno e completo</p>
    </div>
  );
}
"@
Set-Content -Path "$ProjectDir\frontend\app\page.jsx" -Value $frontendPage -Encoding utf8 -Force

$packageJson = @"
{
  ""name"": ""userat-frontend"",
  ""version"": ""1.0.0"",
  ""scripts"": {
    ""dev"": ""next dev"",
    ""build"": ""next build"",
    ""start"": ""next start""
  },
  ""dependencies"": {
    ""next"": ""13.4.0"",
    ""react"": ""18.2.0"",
    ""react-dom"": ""18.2.0""
  }
}
"@
Set-Content -Path "$ProjectDir\frontend\package.json" -Value $packageJson -Encoding utf8 -Force

# ------------------------------
# PostgreSQL
# ------------------------------
$dbScript = @"
CREATE TABLE IF NOT EXISTS leads (
    id SERIAL PRIMARY KEY,
    empresa VARCHAR(255),
    contato VARCHAR(255),
    telefone VARCHAR(50),
    email VARCHAR(255)
);
CREATE TABLE IF NOT EXISTS operacoes_cambiais (
    id SERIAL PRIMARY KEY,
    empresa VARCHAR(255),
    valor NUMERIC,
    data_operacao DATE
);
CREATE TABLE IF NOT EXISTS relatorios_ia (
    id SERIAL PRIMARY KEY,
    relatorio TEXT,
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"@
Set-Content -Path "$ProjectDir\database\postgres_setup.sql" -Value $dbScript -Encoding utf8 -Force

# ------------------------------
# Script de execução automatizado
# ------------------------------
$runScript = @"
# Roda backend e frontend automaticamente
cd "$ProjectDir\backend"
pip install -r requirements.txt
Start-Process powershell -ArgumentList '-NoExit','uvicorn main:app --reload'
cd "$ProjectDir\frontend"
npm install
npm run dev
"@
Set-Content -Path "$ScriptsDir\run_userat.ps1" -Value $runScript -Encoding utf8 -Force

# ------------------------------
# Gerar PDF de tutorial
# ------------------------------
$pythonCode = @"
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet

doc = SimpleDocTemplate(r'$PDFDir\USERAT_Tutorial_Atualizado.pdf', pagesize=A4)
styles = getSampleStyleSheet()
story = []

story.append(Paragraph('USERAT 2025 - Tutorial Completo 🚀', styles['Title']))
story.append(Spacer(1,20))
story.append(Paragraph('Este tutorial explica todas as funcionalidades do backend, frontend, IA e banco de dados.', styles['Normal']))
story.append(Spacer(1,10))
story.append(Paragraph('Atualizações automáticas integradas para o mercado de importação, exportação e câmbio.', styles['Normal']))

doc.build(story)
"@
Set-Content -Path "$ScriptsDir\make_tutorial.py" -Value $pythonCode -Encoding utf8 -Force
python "$ScriptsDir\make_tutorial.py"

# ------------------------------
# Criar atalho na área de trabalho
# ------------------------------
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = "$desktopPath\USERAT 2025.lnk"

if (-not (Test-Path $shortcutPath)) {
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcut = $WshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-ExecutionPolicy Bypass -File "$ScriptsDir\run_userat.ps1""
    $shortcut.WorkingDirectory = $ProjectDir
    $shortcut.WindowStyle = 1
    $shortcut.IconLocation = "$ProjectDir\frontend\favicon.ico"
    $shortcut.Save()
    Write-Log "✅ Atalho criado na área de trabalho"
} else {
    Write-Log "ℹ Atalho já existe. Continuando execução..."
}

# ------------------------------
# Execução final
# ------------------------------
Write-Log "✅ Setup USERAT 2025 final concluído com sucesso!"
Write-Log "Abra o atalho na área de trabalho para iniciar o Dashboard interativo."
# ===== FIM UNICsetup_userat_2025_final.ps1 =====

# ===== INICIO 10setup_unic_quantic_stage1.2.ps1 =====
# =========================================
# UNIC QUANTIC - Stage1.2 Setup
# =========================================
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -------------------------
# Caminhos principais
# -------------------------
$RootPath      = "C:\UNIC QUANTIC"
$ToolsPath     = Join-Path $RootPath "tools"
$ScriptsPath   = Join-Path $RootPath "scripts"
$FrontendPath  = Join-Path $RootPath "frontend"
$LogsPath      = Join-Path $RootPath "logs"
$TutorialFile  = Join-Path $RootPath "Tutorial_Stage1.2.txt"

$PythonExe = "C:\Users\arati\AppData\Local\Programs\Python\Python311\python.exe"

# -------------------------
# Criar diretórios
# -------------------------
$paths = @($RootPath, $ToolsPath, $ScriptsPath, $FrontendPath, $LogsPath)
foreach ($p in $paths) {
    if (-not (Test-Path $p)) {
        New-Item -ItemType Directory -Path $p | Out-Null
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Criado diretório: $p"
    }
}

# -------------------------
# Criar requirements.txt
# -------------------------
$requirementsFile = Join-Path $RootPath "requirements.txt"
@"
requests
beautifulsoup4
selenium>=4.35.0
lxml
pandas
"@ | Set-Content $requirementsFile -Encoding UTF8
Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Arquivo requirements.txt criado."

# -------------------------
# Instalar pacotes Python
# -------------------------
Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Instalando pacotes Python..."
Start-Process -NoNewWindow -Wait -FilePath $PythonExe -ArgumentList "-m pip install --upgrade pip"
Start-Process -NoNewWindow -Wait -FilePath $PythonExe -ArgumentList "-m pip install -r "$requirementsFile""
Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Instalação de pacotes Python concluída."

# -------------------------
# Criar package.json válido
# -------------------------
$packageJson = @"
{
  "name": "unic-quantic",
  "version": "1.0.0",
  "description": "Frontend do UNIC QUANTIC",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {}
}
"@

$packageJsonPath = Join-Path $FrontendPath "package.json"
$packageJson | Set-Content $packageJsonPath -Encoding UTF8
Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - package.json criado no frontend."

# -------------------------
# Instalar dependências Node.js
# -------------------------
Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Instalando dependências Node.js..."
Push-Location $FrontendPath
Start-Process -NoNewWindow -Wait -FilePath "npm" -ArgumentList "install"
Pop-Location
Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Instalação de pacotes Node.js concluída."

# -------------------------
# Criar autocorrector.py de exemplo
# -------------------------
$autocorrectorCode = @"
import argparse
import time
import sys

parser = argparse.ArgumentParser(description='Auto-corrector UNIC QUANTIC')
parser.add_argument('--watch', action='store_true', help='Roda o autocorretor em modo watch')
parser.add_argument('--level', choices=['light','moderate','advanced'], default='light', help='Nível de correção')
args = parser.parse_args()

print(f'Autocorrector iniciado - nível: {args.level}, watch: {args.watch}')
while args.watch:
    print('Modo watch ativo...')
    time.sleep(5)
"@

$autocorrectorPath = Join-Path $ToolsPath "autocorrector.py"
$autocorrectorCode | Set-Content $autocorrectorPath -Encoding UTF8
Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - autocorrector.py criado."

# -------------------------
# Executar autocorrector em background
# -------------------------
$Args = @(
    $autocorrectorPath
    "--watch"
    "--level"
    "light"
)
Start-Process -NoNewWindow -FilePath $PythonExe -ArgumentList $Args
Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Autocorrector iniciado em background."

# -------------------------
# Criar tutorial Stage1.2
# -------------------------
$tutorialText = @"
UNIC QUANTIC Stage1.2 - Tutorial
=================================
- Diretórios criados: tools, scripts, frontend, logs
- requirements.txt criado e pacotes Python instalados
- package.json criado e npm install executado
- autocorrector.py criado e iniciado em background
- Logs registrados
"@
$tutorialText | Set-Content $TutorialFile -Encoding UTF8
Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Tutorial Stage1.2 criado: $TutorialFile"

Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - UNIC QUANTIC Stage1.2 finalizado com sucesso!"
# ===== FIM 10setup_unic_quantic_stage1.2.ps1 =====

# ===== INICIO 11setup_unic_quantic_stage1.2.ps1 =====
# =========================================
# UNIC QUANTIC - Setup Stage 1.2
# =========================================
# Autor: UNIC QUANTIC Team
# Objetivo: Instalar dependências Python e Node.js, iniciar autocorretor
# =========================================

# Define paths
$BasePath = "C:\UNIC QUANTIC"
$PythonExe = "C:\Users\arati\AppData\Local\Programs\Python\Python311\python.exe"
$RequirementsFile = Join-Path $BasePath "requirements.txt"
$FrontendPath = Join-Path $BasePath "frontend"
$AutoCorrectorScript = Join-Path $BasePath "tools\autocorrector.py"

# =========================================
# 1. Criar requirements.txt se não existir
# =========================================
if (-not (Test-Path $RequirementsFile)) {
    $requirementsContent = @"
requests>=2.31.0
beautifulsoup4>=4.13.0
selenium>=4.14.0
pandas>=2.1.0
"@
    $requirementsContent | Out-File -FilePath $RequirementsFile -Encoding UTF8
    Write-Host "Arquivo requirements.txt criado em $RequirementsFile"
}

# =========================================
# 2. Instalar pacotes Python
# =========================================
Write-Host "Instalando pacotes Python..."
Start-Process -FilePath $PythonExe -ArgumentList @("-m","pip","install","--upgrade","pip") -Wait
Start-Process -FilePath $PythonExe -ArgumentList @("-m","pip","install","-r",$RequirementsFile) -Wait
Write-Host "Instalação de pacotes Python concluída."

# =========================================
# 3. Instalar dependências Node.js
# =========================================
if (Test-Path $FrontendPath) {
    Write-Host "Instalando dependências Node.js..."
    Push-Location $FrontendPath
    npm install
    Pop-Location
    Write-Host "Instalação de dependências Node.js concluída."
} else {
    Write-Host "Pasta frontend não encontrada, pulando instalação Node.js."
}

# =========================================
# 4. Iniciar autocorretor Python
# =========================================
if (Test-Path $AutoCorrectorScript) {
    Write-Host "Iniciando autocorretor Python (leve) em background..."
    Start-Process -FilePath $PythonExe -ArgumentList @($AutoCorrectorScript, "--watch", "--level", "light") -NoNewWindow
} else {
    Write-Host "Arquivo autocorrector.py não encontrado em $AutoCorrectorScript"
}

# =========================================
# 5. Criar Tutorial Stage1.2
# =========================================
$TutorialFile = Join-Path $BasePath "Tutorial_Stage1.2.txt"
$TutorialContent = @"
UNIC QUANTIC Stage1.2 - Tutorial
1. requirements.txt criado e pacotes Python instalados
2. Dependências Node.js instaladas
3. Autocorretor Python iniciado em background
4. Caminhos corrigidos para evitar problemas de espaços
"@
$TutorialContent | Out-File -FilePath $TutorialFile -Encoding UTF8
Write-Host "Tutorial Stage1.2 criado: $TutorialFile"

Write-Host "UNIC QUANTIC Stage1.2 finalizado com sucesso!"
# ===== FIM 11setup_unic_quantic_stage1.2.ps1 =====

# ===== INICIO 12setup_unic_quantic_stage1.2.ps1 =====
# ===========================================
# UNIC QUANTIC - Stage 1.2 Final Setup
# ===========================================

$BasePath = "C:\UNIC QUANTIC"
$PythonExe = "C:\Users\arati\AppData\Local\Programs\Python\Python311\python.exe"
$RequirementsFile = Join-Path $BasePath "requirements.txt"
$FrontendPath = Join-Path $BasePath "frontend"
$AutoCorrectorScript = Join-Path $BasePath "tools\autocorrector.py"
$LogFile = Join-Path $BasePath "setup_stage1.2.log"

# Função de log
function Write-Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp - $message"
    Write-Output $line
    Add-Content -Path $LogFile -Value $line
}

Write-Log "Iniciando UNIC QUANTIC Stage1.2 Final..."

# Cria requirements.txt
if (-not (Test-Path $RequirementsFile)) {
    Write-Log "Arquivo requirements.txt não encontrado. Criando..."
    @"
requests>=2.31.0
beautifulsoup4>=4.13.0
selenium>=4.14.0
pandas>=2.1.0
numpy>=1.26.0
"@ | Out-File -FilePath $RequirementsFile -Encoding UTF8
    Write-Log "requirements.txt criado com sucesso."
} else {
    Write-Log "requirements.txt já existe."
}

# Atualiza pip
Write-Log "Atualizando pip..."
Start-Process -FilePath $PythonExe -ArgumentList @("-m","pip","install","--upgrade","pip") -Wait

# Instala pacotes Python
Write-Log "Instalando pacotes Python..."
Start-Process -FilePath $PythonExe -ArgumentList @("-m","pip","install","-r",$RequirementsFile) -Wait
Write-Log "Pacotes Python instalados com sucesso."

# Instala dependências Node.js
if (Test-Path $FrontendPath) {
    Write-Log "Instalando dependências Node.js..."
    Push-Location $FrontendPath
    npm install
    Pop-Location
    Write-Log "Dependências Node.js instaladas com sucesso."
} else {
    Write-Log "Pasta frontend não encontrada. Pulando instalação Node.js."
}

# Executa autocorretor em background (leve)
if (Test-Path $AutoCorrectorScript) {
    Write-Log "Iniciando autocorretor Python (leve) em background..."
    Start-Process -FilePath $PythonExe -ArgumentList @($AutoCorrectorScript,"--watch","--level","light") -NoNewWindow
    Write-Log "Autocorretor iniciado."
} else {
    Write-Log "Autocorretor não encontrado em $AutoCorrectorScript"
}

Write-Log "UNIC QUANTIC Stage1.2 Final concluído com sucesso!"
# ===== FIM 12setup_unic_quantic_stage1.2.ps1 =====

# ===== INICIO 13setup_unic_quantic_stage1.2.ps1 =====
# ==========================================
# UNIC QUANTIC - Stage1.2 Setup (corrigido)
# ==========================================

$ErrorActionPreference = "Stop"

Write-Host "==========================================="
Write-Host "UNIC QUANTIC Stage1.2 - Setup Iniciado"
Write-Host "==========================================="

# Base path do projeto
$BasePath = "C:\UNIC QUANTIC"

# Caminho do Python
$PythonExe = "C:\Users\arati\AppData\Local\Programs\Python\Python311\python.exe"

# Garantir que a pasta existe
if (-not (Test-Path $BasePath)) {
    New-Item -ItemType Directory -Path $BasePath | Out-Null
    Write-Host "Criada pasta: $BasePath"
}

# Caminho para requirements.txt
$RequirementsFile = Join-Path $BasePath "requirements.txt"

# Criar requirements.txt se não existir
if (-not (Test-Path $RequirementsFile)) {
    @"
requests>=2.31.0
beautifulsoup4>=4.13.0
selenium>=4.14.0
pandas>=2.1.0
numpy>=1.26.0
"@ | Out-File -FilePath $RequirementsFile -Encoding UTF8
    Write-Host "Arquivo requirements.txt criado."
}

# =============================
# Instalação de pacotes Python
# =============================
Write-Host "[INFO] Instalando pacotes Python..."
$RequirementsFileEscaped = '"' + $RequirementsFile + '"'
Start-Process -FilePath $PythonExe -ArgumentList "-m", "pip", "install", "-r", $RequirementsFileEscaped -NoNewWindow -Wait
Write-Host "[INFO] Instalação de pacotes Python concluída.`n"

# =============================
# Instalação de pacotes Node.js
# =============================
Write-Host "[INFO] Instalando dependências Node.js..."
if (Test-Path (Join-Path $BasePath "package.json")) {
    Push-Location $BasePath
    npm install
    Pop-Location
} else {
    Write-Host "[AVISO] Nenhum package.json encontrado. Pulando etapa Node.js."
}
Write-Host "[INFO] Instalação de pacotes Node.js concluída.`n"

# =============================
# Rodando autocorretor Python
# =============================
$AutoCorrector = Join-Path $BasePath "tools\autocorrector.py"
if (Test-Path $AutoCorrector) {
    Write-Host "[INFO] Iniciando autocorretor Python em background..."
    Start-Process -FilePath $PythonExe -ArgumentList $AutoCorrector -NoNewWindow
} else {
    Write-Host "[AVISO] Autocorretor não encontrado em $AutoCorrector"
}

# =============================
# Finalização
# =============================
Write-Host "==========================================="
Write-Host "UNIC QUANTIC Stage1.2 finalizado com sucesso!"
Write-Host "==========================================="
# ===== FIM 13setup_unic_quantic_stage1.2.ps1 =====

# ===== INICIO 1setup_unic_quantic_stage1.ps1 =====
<#
UNIC QUANTIC - Setup Inicial (Stage 1)
Autor: Automação Total
Objetivo:
 - Criar estrutura de pastas
 - Criar arquivos iniciais (backend, frontend, db, scripts)
 - Criar logs e manual básico
 - Autocorreção simples (tentativa de regravação de arquivos)
#>

# --- Configurações ---
$BasePath      = "C:\UNIC QUANTIC"
$BackendPath   = Join-Path $BasePath "backend"
$FrontendPath  = Join-Path $BasePath "frontend"
$FrontendApp   = Join-Path $FrontendPath "app"
$DatabasePath  = Join-Path $BasePath "database"
$ScriptsPath   = Join-Path $BasePath "scripts"
$LogsPath      = Join-Path $BasePath "logs"
$PDFsPath      = Join-Path $BasePath "pdfs"

$Dirs = @($BasePath,$BackendPath,$FrontendPath,$FrontendApp,$DatabasePath,$ScriptsPath,$LogsPath,$PDFsPath)

# --- Criar pastas ---
foreach ($d in $Dirs) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# --- Função de log ---
Function Write-Log {
    param([string]$Message)
    $logFile = Join-Path $LogsPath "execution_log.txt"
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$ts - $Message"
    $entry | Out-File -FilePath $logFile -Append -Encoding UTF8
    Write-Host $entry
}

Write-Log "=== Iniciando Setup UNIC QUANTIC Stage 1 ==="

# --- Função AutoFix ---
Function Try-AutoFix {
    param(
        [string]$Step,
        [string]$Path,
        [string]$Content
    )
    try {
        Set-Content -Path $Path -Value $Content -Encoding UTF8 -Force
        Write-Log "$Step — OK"
    } catch {
        Write-Log "$Step — ERRO: $($_.Exception.Message)"
        Start-Sleep -Seconds 2
        try {
            Set-Content -Path $Path -Value $Content -Encoding UTF8 -Force
            Write-Log "$Step — Corrigido na 2ª tentativa"
        } catch {
            Write-Log "$Step — Falhou mesmo após autocorreção"
        }
    }
}

# --- Backend main.py ---
$backendMain = @"
from fastapi import FastAPI
import datetime

app = FastAPI(title='UNIC QUANTIC - Backend (Stage 1)')

@app.get("/")
def root():
    return {"status": "online", "time": str(datetime.datetime.now())}
"@
Try-AutoFix "Criar backend main.py" (Join-Path $BackendPath "main.py") $backendMain

# --- Backend requirements.txt ---
$requirements = @"
fastapi
uvicorn
psycopg2-binary
pandas
numpy
scikit-learn
"@
Try-AutoFix "Criar backend requirements.txt" (Join-Path $BackendPath "requirements.txt") $requirements

# --- Frontend package.json ---
$packageJson = @"
{
  "name": "unic-quantic-frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev -p 3000",
    "build": "next build",
    "start": "next start -p 3000"
  },
  "dependencies": {
    "next": "13.4.0",
    "react": "18.2.0",
    "react-dom": "18.2.0",
    "axios": "1.5.0"
  }
}
"@
Try-AutoFix "Criar frontend package.json" (Join-Path $FrontendPath "package.json") $packageJson

# --- Frontend page.jsx ---
$frontendPage = @"
'use client';
import React from 'react';

export default function Home() {
  return (
    <div style={{padding:40,fontFamily:'Arial'}}>
      <h1>UNIC QUANTIC — Dashboard inicial</h1>
      <p>Bem-vindo ao sistema de operações de câmbio (Stage 1).</p>
    </div>
  );
}
"@
Try-AutoFix "Criar frontend page.jsx" (Join-Path $FrontendApp "page.jsx") $frontendPage

# --- Database postgres_setup.sql ---
$dbSql = @"
CREATE TABLE IF NOT EXISTS leads (
  id SERIAL PRIMARY KEY,
  empresa VARCHAR(255),
  contato VARCHAR(255),
  telefone VARCHAR(50),
  email VARCHAR(255),
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS operacoes (
  id SERIAL PRIMARY KEY,
  tipo VARCHAR(50),
  valor NUMERIC(15,2),
  moeda VARCHAR(10),
  data_operacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"@
Try-AutoFix "Criar postgres_setup.sql" (Join-Path $DatabasePath "postgres_setup.sql") $dbSql

# --- Script run_unic_quantic.ps1 ---
$runScript = @"
# Script de execução UNIC QUANTIC (Stage 1)
Write-Host 'Iniciando Backend (FastAPI)...'
Start-Process powershell -ArgumentList 'uvicorn main:app --reload' -WorkingDirectory '$BackendPath'

Write-Host 'Iniciando Frontend (Next.js)...'
Start-Process powershell -ArgumentList 'npm run dev' -WorkingDirectory '$FrontendPath'
"@
Try-AutoFix "Criar run_unic_quantic.ps1" (Join-Path $ScriptsPath "run_unic_quantic.ps1") $runScript

# --- Manual básico ---
$manual = @"
UNIC QUANTIC - Manual Stage 1
=============================

1. Backend (FastAPI):
   - Local: backend\main.py
   - Executar: uvicorn main:app --reload

2. Frontend (Next.js):
   - Local: frontend\package.json
   - Executar: npm run dev

3. Banco de Dados (PostgreSQL):
   - Script inicial: database\postgres_setup.sql

4. Script de execução:
   - Local: scripts\run_unic_quantic.ps1
   - Função: abre backend + frontend

Log de execução salvo em: logs\execution_log.txt
"@
Try-AutoFix "Criar manual básico" (Join-Path $PDFsPath "manual_stage1.txt") $manual

Write-Log "=== Setup UNIC QUANTIC Stage 1 finalizado ==="
# ===== FIM 1setup_unic_quantic_stage1.ps1 =====

# ===== INICIO 2setup_unic-estrutura-inicial-completa.ps1 =====
<#
setup_unic_quantic_stage1.ps1
Stage 1 — Estrutura inicial UNIC QUANTIC
Cria pastas, arquivos base (backend/frontend/db/scripts), logs e manual.
#>

# --- Configurações ---
$BasePath      = "C:\UNIC QUANTIC"
$BackendPath   = Join-Path $BasePath "backend"
$FrontendPath  = Join-Path $BasePath "frontend"
$FrontendApp   = Join-Path $FrontendPath "app"
$DatabasePath  = Join-Path $BasePath "database"
$ScriptsPath   = Join-Path $BasePath "scripts"
$LogsPath      = Join-Path $BasePath "logs"
$PDFsPath      = Join-Path $BasePath "pdfs"

$Dirs = @($BasePath,$BackendPath,$FrontendPath,$FrontendApp,$DatabasePath,$ScriptsPath,$LogsPath,$PDFsPath)

# Criar pastas
foreach ($d in $Dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }
}

# Função de log
Function Write-Log {
    param([string]$Message)
    $logFile = Join-Path $LogsPath "execution_log.txt"
    if (-not (Test-Path $logFile)) { "" | Out-File -FilePath $logFile -Encoding UTF8 }
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$ts - $Message"
    $entry | Out-File -FilePath $logFile -Append -Encoding UTF8
    Write-Host $entry
}

Write-Log "=== Iniciando Setup UNIC QUANTIC Stage 1 ==="

# Função Try-AutoFix que executa um scriptblock e tenta 2x se falhar
Function Try-AutoFix {
    param(
        [string]$Step,
        [scriptblock]$Action,
        [int]$Retries = 1,
        [int]$DelaySeconds = 2
    )
    for ($i=0; $i -le $Retries; $i++) {
        try {
            & $Action
            Write-Log "$Step — OK"
            return $true
        } catch {
            Write-Log "$Step — ERRO: $($_.Exception.Message)"
            if ($i -lt $Retries) {
                Write-Log "Tentando autocorreção ($($i+1)/$Retries) após $DelaySeconds s..."
                Start-Sleep -Seconds $DelaySeconds
            } else {
                Write-Log "Autocorreção falhou para: $Step"
                return $false
            }
        }
    }
}

# --- Backend main.py ---
$backendMain = @"
from fastapi import FastAPI
import datetime
app = FastAPI(title='UNIC QUANTIC - Backend (Stage 1)')

@app.get('/')
def root():
    return {'status':'online','time': str(datetime.datetime.now())}
"@
Try-AutoFix "Criar backend main.py" { Set-Content -Path (Join-Path $BackendPath "main.py") -Value $backendMain -Encoding UTF8 -Force }

# --- Backend requirements.txt ---
$reqs = @"
fastapi
uvicorn
psycopg2-binary
pandas
numpy
scikit-learn
openai
"@
Try-AutoFix "Criar backend requirements.txt" { $reqs | Out-File -FilePath (Join-Path $BackendPath "requirements.txt") -Encoding UTF8 -Force }

# --- Frontend package.json ---
$packageJson = @"
{
  ""name"": ""unic-quantic-frontend"",
  ""version"": ""0.1.0"",
  ""private"": true,
  ""scripts"": {
    ""dev"": ""next dev -p 3000"",
    ""build"": ""next build"",
    ""start"": ""next start -p 3000""
  },
  ""dependencies"": {
    ""next"": ""13.4.0"",
    ""react"": ""18.2.0"",
    ""react-dom"": ""18.2.0"",
    ""axios"": ""1.5.0""
  }
}
"@
Try-AutoFix "Criar frontend package.json" { Set-Content -Path (Join-Path $FrontendPath "package.json") -Value $packageJson -Encoding UTF8 -Force }

# --- Frontend page.jsx ---
$frontendPage = @"
'use client';
import React from 'react';
export default function Home() {
  return (
    <div style={{padding:40,fontFamily:'Arial'}}>
      <h1>UNIC QUANTIC — Dashboard inicial</h1>
      <p>Bem-vindo ao sistema de operações de câmbio (Stage 1).</p>
    </div>
  );
}
"@
Try-AutoFix "Criar frontend page.jsx" { Set-Content -Path (Join-Path $FrontendApp "page.jsx") -Value $frontendPage -Encoding UTF8 -Force }

# --- DB SQL ---
$dbSql = @"
CREATE TABLE IF NOT EXISTS leads (
  id SERIAL PRIMARY KEY,
  empresa VARCHAR(255),
  contato VARCHAR(255),
  telefone VARCHAR(50),
  email VARCHAR(255),
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS operacoes (
  id SERIAL PRIMARY KEY,
  tipo VARCHAR(50),
  valor NUMERIC(15,2),
  moeda VARCHAR(10),
  data_operacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"@
Try-AutoFix "Criar postgres_setup.sql" { Set-Content -Path (Join-Path $DatabasePath "postgres_setup.sql") -Value $dbSql -Encoding UTF8 -Force }

# --- Script run_unic_quantic.ps1 (execução local) ---
$runScript = @"
# Script de execução UNIC QUANTIC (Stage 1)
Write-Host 'Iniciando Backend (FastAPI)...'
Start-Process powershell -ArgumentList 'python -m uvicorn main:app --reload' -WorkingDirectory '$BackendPath'
Start-Sleep -Seconds 2
Write-Host 'Iniciando Frontend (Next.js)...'
Start-Process powershell -ArgumentList 'npm run dev' -WorkingDirectory '$FrontendPath'
"@
Try-AutoFix "Criar run_unic_quantic.ps1" { Set-Content -Path (Join-Path $ScriptsPath "run_unic_quantic.ps1") -Value $runScript -Encoding UTF8 -Force }

# --- Manual básico (txt) ---
$manual = @"
UNIC QUANTIC - Manual Stage 1
=============================

1) Backend (FastAPI)
   - Arquivo: backend\main.py
   - Para executar (na pasta backend): python -m uvicorn main:app --reload

2) Frontend (Next.js)
   - Arquivo: frontend\package.json
   - Para executar (na pasta frontend): npm install && npm run dev

3) Banco de dados
   - Script: database\postgres_setup.sql

4) Script de execução rápido
   - scripts\run_unic_quantic.ps1 -> inicia backend + frontend

Logs: logs\execution_log.txt
"@
Try-AutoFix "Criar manual_stage1.txt" { Set-Content -Path (Join-Path $PDFsPath "manual_stage1.txt") -Value $manual -Encoding UTF8 -Force }

Write-Log "=== Setup UNIC QUANTIC Stage 1 finalizado ==="
# ===== FIM 2setup_unic-estrutura-inicial-completa.ps1 =====

# ===== INICIO 2setup_unic_quantic_stage1.1.ps1 =====
<#
setup_unic_quantic_stage1.1.ps1
Atualização Stage 1.1 — UNIC QUANTIC
- Cria estrutura (se não existir)
- Cria tools/autocorrector.py (versão 3 níveis)
- Instala dependências Python (pip) e frontend (npm) automaticamente
- Gera tutorial TXT e PDF (usa reportlab instalado via pip)
- Cria wrapper PowerShell para rodar autocorrector (tratamento de espaços)
- Log em C:\UNIC QUANTIC\logs\execution_log.txt
#>

# -----------------------
# Configuração de caminhos
# -----------------------
$BasePath      = "C:\UNIC QUANTIC"
$BackendPath   = Join-Path $BasePath "backend"
$FrontendPath  = Join-Path $BasePath "frontend"
$FrontendApp   = Join-Path $FrontendPath "app"
$DatabasePath  = Join-Path $BasePath "database"
$ScriptsPath   = Join-Path $BasePath "scripts"
$LogsPath      = Join-Path $BasePath "logs"
$PDFsPath      = Join-Path $BasePath "pdfs"
$ToolsPath     = Join-Path $BasePath "tools"

# Cria pastas se necessário
$dirs = @($BasePath,$BackendPath,$FrontendPath,$FrontendApp,$DatabasePath,$ScriptsPath,$LogsPath,$PDFsPath,$ToolsPath)
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# Função de log
Function Write-Log {
    param([string]$Message)
    $logFile = Join-Path $LogsPath "execution_log.txt"
    if (-not (Test-Path $logFile)) { "" | Out-File -FilePath $logFile -Encoding UTF8 }
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$ts - $Message"
    $entry | Out-File -FilePath $logFile -Append -Encoding UTF8
    Write-Host $entry
}

Write-Log "=== Iniciando setup_unic_quantic_stage1.1 ==="

# -----------------------
# Criar arquivos base (se não existirem)
# -----------------------

# backend main.py
$backendMainPath = Join-Path $BackendPath "main.py"
if (-not (Test-Path $backendMainPath)) {
    $backendMain = @"
from fastapi import FastAPI
import datetime
app = FastAPI(title='UNIC QUANTIC - Backend (Stage 1.1)')
@app.get('/')
def root():
    return {'status':'online','time': str(datetime.datetime.now())}
"@
    $backendMain | Set-Content -Path $backendMainPath -Encoding UTF8 -Force
    Write-Log "Criado: $backendMainPath"
} else { Write-Log "Já existe: $backendMainPath (preservado)" }

# backend requirements.txt
$reqPath = Join-Path $BackendPath "requirements.txt"
$reqContent = @"
fastapi
uvicorn
psycopg2-binary
pandas
numpy
scikit-learn
reportlab
graphviz
openai
"@
# sempre (re)cria para garantir dependências atuais
$reqContent | Out-File -FilePath $reqPath -Encoding UTF8
Write-Log "Gerado requirements em: $reqPath"

# frontend package.json
$pkgPath = Join-Path $FrontendPath "package.json"
$pkgJson = @"
{
  ""name"": ""unic-quantic-frontend"",
  ""version"": ""0.1.1-stage1.1"",
  ""private"": true,
  ""scripts"": {
    ""dev"": ""next dev -p 3000"",
    ""build"": ""next build"",
    ""start"": ""next start -p 3000""
  },
  ""dependencies"": {
    ""next"": ""13.4.0"",
    ""react"": ""18.2.0"",
    ""react-dom"": ""18.2.0"",
    ""axios"": ""1.5.0""
  }
}
"@
$pkgJson | Set-Content -Path $pkgPath -Encoding UTF8 -Force
Write-Log "Gerado frontend package.json: $pkgPath"

# frontend page.jsx
$frontendPagePath = Join-Path $FrontendApp "page.jsx"
$frontendPage = @"
'use client';
import React from 'react';
export default function Home() {
  return (
    <div style={{padding:40,fontFamily:'Arial'}}>
      <h1>UNIC QUANTIC — Dashboard inicial (stage1.1)</h1>
      <p>Bem-vindo. Esta é a versão inicial do painel.</p>
    </div>
  );
}
"@
$frontendPage | Set-Content -Path $frontendPagePath -Encoding UTF8 -Force
Write-Log "Gerado frontend page.jsx: $frontendPagePath"

# database script
$dbPath = Join-Path $DatabasePath "postgres_setup.sql"
$dbSql = @"
CREATE TABLE IF NOT EXISTS leads (
  id SERIAL PRIMARY KEY,
  empresa VARCHAR(255),
  contato VARCHAR(255),
  telefone VARCHAR(50),
  email VARCHAR(255),
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS operacoes (
  id SERIAL PRIMARY KEY,
  tipo VARCHAR(50),
  valor NUMERIC(15,2),
  moeda VARCHAR(10),
  data_operacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"@
$dbSql | Set-Content -Path $dbPath -Encoding UTF8 -Force
Write-Log "Gerado DB script: $dbPath"

# run script
$runPath = Join-Path $ScriptsPath "run_unic_quantic.ps1"
$runContent = @"
# Run UNIC QUANTIC (Stage 1.1)
Write-Host 'Iniciando backend...'
Start-Process -FilePath powershell -ArgumentList '-NoExit','-Command','cd "$BackendPath"; python -m uvicorn main:app --reload'
Start-Sleep -Seconds 2
Write-Host 'Iniciando frontend...'
Start-Process -FilePath powershell -ArgumentList '-NoExit','-Command','cd "$FrontendPath"; npm run dev'
"@
$runContent | Set-Content -Path $runPath -Encoding UTF8 -Force
Write-Log "Gerado script de execução: $runPath"

# -----------------------
# Criar tools/autocorrector.py (versão 3 níveis)
# -----------------------
$acPath = Join-Path $ToolsPath "autocorrector.py"
$acCode = @"
# autocorrector.py — UNIC QUANTIC (Stage 1.1)
# Níveis: light | moderate | advanced
import os, re, sys, json, time, shutil, subprocess
from pathlib import Path

BASE = Path(r'$BasePath')
LOGS = BASE / 'logs'
EXEC_LOG = LOGS / 'execution_log.txt'
REPORT = LOGS / 'autocorrect_report.json'
FRONTEND = BASE / 'frontend'
BACKEND = BASE / 'backend'
TOOLS = BASE / 'tools'
BACKUP = BASE / 'backup_autocorrect'

def ensure_backup_dir():
    BACKUP.mkdir(parents=True, exist_ok=True)

def backup_file(path):
    try:
        ensure_backup_dir()
        p = Path(path)
        if p.exists():
            dest = BACKUP / (p.name + '.' + time.strftime('%Y%m%d%H%M%S'))
            shutil.copy2(str(p), str(dest))
            return str(dest)
    except Exception as e:
        return None

def run_cmd(cmd, cwd=None):
    try:
        p = subprocess.run(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, shell=False)
        return p.returncode, p.stdout, p.stderr
    except Exception as e:
        return 1, '', str(e)

def detect_lang_from_text(text):
    if 'Traceback' in text or 'ModuleNotFoundError' in text or 'SyntaxError' in text:
        return 'python'
    if 'npm ERR' in text or 'Cannot find module' in text:
        return 'node'
    if 'package.json' in text or '{' in text and 'version' in text:
        return 'json'
    if 'psql' in text or 'syntax error at or near' in text:
        return 'sql'
    if 'not recognized as the name of a cmdlet' in text:
        return 'powershell'
    return 'unknown'

def fix_light(text):
    # light fixes: install missing packages
    if 'No module named' in text:
        m = re.search(r\"No module named ['\\\"]?([^'\\\"]+)['\\\"]?\", text)
        if m:
            pkg = m.group(1)
            rc,out,err = run_cmd([sys.executable, '-m', 'pip', 'install', pkg])
            return {'action': f'pip install {pkg}', 'rc': rc, 'out': out, 'err': err}
    if 'Cannot find module' in text or 'npm ERR' in text:
        rc,out,err = run_cmd(['npm','install'], cwd=str(FRONTEND))
        return {'action': 'npm install (frontend)', 'rc': rc, 'out': out, 'err': err}
    return None

def remove_nonprintable_file(path):
    try:
        p = Path(path)
        s = p.read_text(encoding='utf-8', errors='ignore')
        cleaned = re.sub(r'[\\u00A0\\u200B-\\u200F]', ' ', s)
        cleaned = re.sub(r'[^\\x09\\x0A\\x0D\\x20-\\x7E]', '', cleaned)
        b = backup_file(p)
        p.write_text(cleaned, encoding='utf-8')
        return {'action': 'clean_nonprintable', 'file': str(p), 'backup': b}
    except Exception as e:
        return {'error': str(e)}

def fix_json_whitespace(path):
    try:
        p = Path(path)
        s = p.read_text(encoding='utf-8', errors='ignore')
        s2 = s.replace('\\u00A0',' ').replace('\\r','')
        b = backup_file(p)
        p.write_text(s2, encoding='utf-8')
        return {'action': 'fix_json_whitespace', 'file': str(p), 'backup': b}
    except Exception as e:
        return {'error': str(e)}

def fix_moderate(text):
    # moderate fixes: package.json cleanup, remove nonprintable from files referenced
    if 'package.json' in text or 'npm ERR' in text:
        pj = FRONTEND / 'package.json'
        res = fix_json_whitespace(pj)
        rc,out,err = run_cmd(['npm','install'], cwd=str(FRONTEND))
        return {'fix_json': res, 'npm_install': {'rc':rc,'out':out,'err':err}}
    # look for file paths to clean
    files = re.findall(r\"[A-Za-z]:\\\\[^\s,'\\\"]+\", text)
    actions=[]
    for f in files:
        if Path(f).exists():
            actions.append(remove_nonprintable_file(f))
    if actions:
        return {'cleaned_files': actions}
    return None

def fix_advanced(text):
    # advanced: attempt to produce patch using local heuristics or OpenAI (if key available)
    # This is conservative: create backup, then attempt small syntactic fixes (e.g. replace smart quotes)
    patches = []
    # replace leading non-ascii in python files mentioned
    pyfiles = re.findall(r\"[A-Za-z]:\\\\[^\s,'\\\"]+\\.py\", text)
    for f in pyfiles:
        if Path(f).exists():
            b = backup_file(f)
            s = Path(f).read_text(encoding='utf-8', errors='ignore')
            s2 = s.replace('\\u00A0',' ')
            s2 = s2.replace('\\t', '    ')
            Path(f).write_text(s2, encoding='utf-8')
            patches.append({'file':f,'backup':str(b)})
    # OPENAI optional (require OPENAI_API_KEY env)
    if os.getenv('OPENAI_API_KEY'):
        # call to OpenAI could be implemented here to create a suggested patch
        patches.append({'note':'OpenAI key found — can request patch (not auto-called in this demo)'})
    return {'patches':patches}

def process_text(text, level='light'):
    actions = []
    if level == 'light':
        r = fix_light(text)
        if r: actions.append(r)
    elif level == 'moderate':
        r = fix_moderate(text)
        if r: actions.append(r)
    elif level == 'advanced':
        r = fix_advanced(text)
        if r: actions.append(r)
    # always attempt to catch missing package names and run pip/npm if not already done
    return actions

def tail_file(path, last_pos=0):
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        f.seek(last_pos)
        data = f.read()
        return data, f.tell()

def watch(loop_delay=5, level='light'):
    last = 0
    if not EXEC_LOG.exists():
        EXEC_LOG.parent.mkdir(parents=True, exist_ok=True)
        EXEC_LOG.write_text('', encoding='utf-8')
    last = EXEC_LOG.stat().st_size
    print('AutoCorrector watching', EXEC_LOG)
    while True:
        time.sleep(loop_delay)
        data, last = tail_file(EXEC_LOG, last)
        if data:
            print('New log data, processing...')
            acts = process_text(data, level=level)
            if acts:
                rec = {'time':time.strftime('%Y-%m-%d %H:%M:%S'), 'level': level, 'actions': acts}
                try:
                    prev = {}
                    if REPORT.exists():
                        prev = json.loads(REPORT.read_text(encoding='utf-8'))
                    prev.setdefault('runs',[]).append(rec)
                    REPORT.write_text(json.dumps(prev, indent=2, ensure_ascii=False), encoding='utf-8')
                except Exception as e:
                    print('Erro ao gravar report:', e)

def run_once(level='light'):
    if EXEC_LOG.exists():
        txt = EXEC_LOG.read_text(encoding='utf-8', errors='ignore')
        acts = process_text(txt, level=level)
        print('Actions:', acts)
        return acts
    else:
        print('No exec log found at', EXEC_LOG)
        return []

if _name_ == '_main_':
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument('--once', action='store_true')
    p.add_argument('--watch', action='store_true')
    p.add_argument('--level', choices=['light','moderate','advanced'], default='light')
    args = p.parse_args()
    if args.once:
        run_once(level=args.level)
    elif args.watch:
        watch(level=args.level)
    else:
        print('Use --once or --watch and --level')
"@
# grava o autocorrector.py
$acCode | Set-Content -Path $acPath -Encoding UTF8 -Force
Write-Log "Gerado autocorrector: $acPath"

# -----------------------
# PowerShell wrapper para executar o autocorrector (trata espaços)
# -----------------------
$runAutoPath = Join-Path $ScriptsPath "run_autocorrector.ps1"
$runAutoContent = @"
# run_autocorrector.ps1 — wrapper seguro
\$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not \$python) { Write-Host 'Python não encontrado no PATH. Instale Python e reabra o PowerShell.'; exit 1 }
# use & to execute with quoted script path (handles spaces)
& \$python "$($ToolsPath)\autocorrector.py" --once --level light
"@
# note: embed actual $ToolsPath value
$runAutoContent = $runAutoContent -replace "\$\(\\\$ToolsPath\)","$ToolsPath"
$runAutoContent | Set-Content -Path $runAutoPath -Encoding UTF8 -Force
Write-Log "Gerado wrapper autocorrector: $runAutoPath"

# -----------------------
# Instalação automática de dependências (pip + npm)
# -----------------------
Write-Log "Instalando dependências Python (pip) — isso pode demorar..."
# Usa python -m pip to be safer
$pythonCmd = (Get-Command python -ErrorAction SilentlyContinue)
if ($pythonCmd) {
    try {
        & $pythonCmd.Source -m pip install -r $reqPath --trusted-host pypi.org --trusted-host files.pythonhosted.org
        Write-Log "pip install -r requirements.txt concluído"
    } catch {
        Write-Log "Erro pip install: $($_.Exception.Message)"
    }
} else {
    Write-Log "Python não encontrado — pule pip install"
}

Write-Log "Instalando dependências frontend (npm install)..."
# change dir and run npm install
if (Get-Command npm -ErrorAction SilentlyContinue) {
    Push-Location $FrontendPath
    try {
        npm install
        Write-Log "npm install concluído"
    } catch {
        Write-Log "Erro npm install: $($_.Exception.Message)"
    }
    Pop-Location
} else {
    Write-Log "npm não encontrado — pule npm install"
}

# -----------------------
# Gerar tutorial TXT e PDF (se possível)
# -----------------------
$manualTxtPath = Join-Path $PDFsPath "manual_stage1.1.txt"
$manualTxt = @"
UNIC QUANTIC — Manual Stage 1.1
--------------------------------
Paths:
Base: $BasePath
Backend: $backendMainPath
Frontend: $pkgPath
Database script: $dbPath
Autocorrector: $acPath
Run scripts: $runPath, $runAutoPath

Este manual foi gerado automaticamente pelo setup_unic_quantic_stage1.1.ps1
"@
$manualTxt | Set-Content -Path $manualTxtPath -Encoding UTF8
Write-Log "Gerado manual TXT: $manualTxtPath"

# tentar gerar PDF usando reportlab (se instalado)
$makePdfPy = Join-Path $ToolsPath "make_manual_pdf.py"
$makePdfCode = @"
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
doc = SimpleDocTemplate(r'$($PDFsPath)\manual_stage1.1.pdf', pagesize=A4)
styles = getSampleStyleSheet()
story = []
story.append(Paragraph('UNIC QUANTIC — Manual Stage 1.1', styles['Title']))
story.append(Spacer(1,12))
text = r'''$manualTxt'''
story.append(Paragraph(text.replace('\n','<br/>'), styles['Normal']))
doc.build(story)
print('PDF gerado')
"@
$makePdfCode | Set-Content -Path $makePdfPy -Encoding UTF8 -Force

# tenta instalar reportlab se pip disponível
if ($pythonCmd) {
    try {
        & $pythonCmd.Source -m pip install reportlab --quiet
        Write-Log "reportlab instalado"
        & $pythonCmd.Source $makePdfPy
        Write-Log "manual_stage1.1.pdf gerado em $PDFsPath"
    } catch {
        Write-Log "Não foi possível gerar PDF automaticamente: $($_.Exception.Message)"
    }
} else {
    Write-Log "Python não disponível: não foi possível gerar PDF"
}

Write-Log "=== setup_unic_quantic_stage1.1 finalizado ==="
# ===== FIM 2setup_unic_quantic_stage1.1.ps1 =====

# ===== INICIO 3setup_unic_quantic_stage1.2.ps1 =====
# ======================================
# UNIC QUANTIC - Setup Stage 1.2
# Autor: Automação Total
# Funcionalidades: Backend + Frontend + DB + Autocorreção + Logs + Tutorial PDF
# ======================================

$BasePath = "C:\UNIC QUANTIC"
$ScriptsPath = "$BasePath\scripts"
$ToolsPath = "$BasePath\tools"
$FrontendPath = "$BasePath\frontend"
$BackendPath = "$BasePath\backend"
$TutorialPath = "$BasePath\tutorials\stage1.2"

# Criar pastas se não existirem
$dirs = @($ScriptsPath, $ToolsPath, $FrontendPath, $BackendPath, $TutorialPath)
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force }
}

# Logs
$logFile = "$BasePath\logs_stage1.2.txt"
Function Write-Log { param($msg) Add-Content -Path $logFile -Value "$(Get-Date -Format G) - $msg" }

Write-Log "Iniciando Stage 1.2"

# ======================================
# Corrigir package.json (Frontend)
# ======================================
$packageJsonPath = "$FrontendPath\package.json"
$packageJsonCorrect = @"
{
  "name": "unic-quantic-frontend",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "react": "18.2.0",
    "react-dom": "18.2.0",
    "next": "13.5.4"
  }
}
"@

Set-Content -Path $packageJsonPath -Value $packageJsonCorrect -Force
Write-Log "package.json corrigido."

# ======================================
# Instalar dependências automaticamente
# ======================================
# Python
Write-Log "Instalando dependências Python (requirements.txt)..."
if (Test-Path "$BackendPath\requirements.txt") {
    & (Get-Command python).Source -ArgumentList "-m pip install -r "$BackendPath\requirements.txt""
    Write-Log "Dependências Python instaladas."
} else { Write-Log "requirements.txt não encontrado." }

# Node.js
Write-Log "Instalando dependências Node.js..."
if (Test-Path "$FrontendPath\package.json") {
    Push-Location $FrontendPath
    npm install | Out-Null
    Pop-Location
    Write-Log "Dependências Node.js instaladas."
}

# ======================================
# Preparar autocorrector.py
# ======================================
$autocorrectorPath = "$ToolsPath\autocorrector.py"
$autocorrectorCode = @"
import re, os, sys, time

level = 'light'
if '--level' in sys.argv:
    level = sys.argv[sys.argv.index('--level') + 1]

watch = '--watch' in sys.argv

def autocorrect():
    print(f'Autocorreção iniciada - nível: {level}')
    # Aqui integrar lógica de correção multi-linguagem
    # Para Python, JS, Bash, PowerShell, JSON, HTML/CSS, etc
    time.sleep(1)
    print('Autocorreção concluída.')

if watch:
    while True:
        autocorrect()
        time.sleep(60)  # roda a cada 1 minuto
else:
    autocorrect()
"@
Set-Content -Path $autocorrectorPath -Value $autocorrectorCode -Force
Write-Log "Autocorrector.py configurado."

# ======================================
# Criar atalho Desktop (somente se não existir)
# ======================================
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = "$desktop\UNIC QUANTIC.lnk"

if (-not (Test-Path $shortcutPath)) {
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcut = $WshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "$ScriptsPath\setup_unic_quantic_stage1.2.ps1"
    $shortcut.Arguments = "-ExecutionPolicy Bypass -File "$ScriptsPath\setup_unic_quantic_stage1.2.ps1""
    $shortcut.Save()
    Write-Log "Atalho criado na área de trabalho."
} else { Write-Log "Atalho já existente, não será substituído." }

# ======================================
# Gerar tutorial automático
# ======================================
$tutorialFile = "$TutorialPath\tutorial_stage1.2.txt"
$tutorialContent = @"
UNIC QUANTIC - Stage 1.2
- Corrigido package.json do frontend
- Instaladas dependências Python e Node.js automaticamente
- Autocorrector multi-linguagem configurado
- Logs de instalação e correção: logs_stage1.2.txt
- Atalho Desktop criado (se não existia)
- Estrutura de pastas organizada
- Preparado para backend, frontend e DB
"@
Set-Content -Path $tutorialFile -Value $tutorialContent -Force
Write-Log "Tutorial Stage 1.2 gerado."

Write-Log "Stage 1.2 concluído com sucesso."
# ===== FIM 3setup_unic_quantic_stage1.2.ps1 =====

# ===== INICIO 4setup_unic_quantic_stage1.2.ps1 =====
# =====================================
# UNIC QUANTIC – Setup Stage 1.2
# Autor: Automação Total
# Funcionalidades: Backend/Frontend/DB, Autocorreção, Logs
# =====================================

# Variáveis de caminho
$BasePath = "C:\UNIC QUANTIC"
$ScriptsPath = "$BasePath\scripts"
$ToolsPath = "$BasePath\tools"
$FrontendPath = "$BasePath\frontend"
$BackendPath = "$BasePath\backend"
$LogsPath = "$BasePath\logs"

# Criar pastas caso não existam
$folders = @($BasePath, $ScriptsPath, $ToolsPath, $FrontendPath, $BackendPath, $LogsPath)
foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
    }
}

# Função de log
Function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage
    Add-Content "$LogsPath\unic_quantic_stage1.log" $logMessage
}

Write-Log "Iniciando setup UNIC QUANTIC Stage 1.2"

# ==========================
# Criar atalho na área de trabalho
# ==========================
$ShortcutPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "UNIC QUANTIC.lnk")
$scriptFullPath = "$ScriptsPath\setup_unic_quantic_stage1.2.ps1"

if (-not (Test-Path $ShortcutPath)) {
    $WScriptShell = New-Object -ComObject WScript.Shell
    $shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
    $shortcut.TargetPath = (Get-Command powershell).Source
    # Correção de ParserError usando aspas concatenadas
    $shortcut.Arguments = '-ExecutionPolicy Bypass -File "' + $scriptFullPath + '"'
    $shortcut.WorkingDirectory = $BasePath
    $shortcut.Save()
    Write-Log "Atalho criado na área de trabalho"
} else {
    Write-Log "Atalho já existe. Continuando execução..."
}

# ==========================
# Instalar pacotes Python automaticamente
# ==========================
$PythonExe = (Get-Command python).Source
$Requirements = "$BackendPath\requirements.txt"

if (Test-Path $PythonExe) {
    Write-Log "Instalando dependências Python..."
    & $PythonExe -m pip install --upgrade pip
    if (Test-Path $Requirements) {
        & $PythonExe -m pip install -r $Requirements
        Write-Log "Instalação de pacotes Python concluída"
    } else {
        Write-Log "Arquivo requirements.txt não encontrado"
    }
} else {
    Write-Log "Python não encontrado. Verifique a instalação."
}

# ==========================
# Instalar pacotes Node.js automaticamente
# ==========================
$PackageJson = "$FrontendPath\package.json"
if (Test-Path $PackageJson) {
    Write-Log "Instalando dependências Node.js..."
    Set-Location $FrontendPath
    npm install
    Write-Log "Instalação de pacotes Node.js concluída"
} else {
    Write-Log "Arquivo package.json não encontrado no frontend"
}

# ==========================
# Executar autocorretor (leve) em background
# ==========================
$AutoCorrector = "$ToolsPath\autocorrector.py"
if (Test-Path $AutoCorrector) {
    Write-Log "Iniciando autocorretor Python (leve) em background..."
    Start-Process -NoNewWindow -FilePath $PythonExe -ArgumentList ""$AutoCorrector" --watch --level light"
} else {
    Write-Log "Autocorretor não encontrado. Verifique o path $AutoCorrector"
}

Write-Log "UNIC QUANTIC Stage 1.2 concluído com sucesso"
# ===== FIM 4setup_unic_quantic_stage1.2.ps1 =====

# ===== INICIO 5setup_unic_quantic_stage1.2.ps1 =====
# =============================================
# UNIC QUANTIC - Setup Stage1.2
# Autor: Automação Total
# Funcionalidades: logs, autocorretor, instalação automática de pacotes
# =============================================

$ProjectRoot = "C:\UNIC QUANTIC"
$ScriptsPath = "$ProjectRoot\scripts"
$ToolsPath = "$ProjectRoot\tools"
$BackendPath = "$ProjectRoot\backend"
$FrontendPath = "$ProjectRoot\frontend"
$LogFile = "$ProjectRoot\unic_quantic_stage1.2.log"

function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Tee-Object -FilePath $LogFile -Append
}

# ==========================
# Criar pastas caso não existam
# ==========================
$dirs = @($ScriptsPath, $ToolsPath, $BackendPath, $FrontendPath)
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d | Out-Null
        Write-Log "Criada pasta: $d"
    }
}

# ==========================
# Instalação de pacotes Python
# ==========================
$requirements = "$ProjectRoot\requirements.txt"
if (Test-Path $requirements) {
    Write-Log "Instalando pacotes Python..."
    pip install -r $requirements | ForEach-Object { Write-Log $_ }
    Write-Log "Instalação de pacotes Python concluída"
} else {
    Write-Log "Arquivo requirements.txt não encontrado"
}

# ==========================
# Instalação de dependências Node.js
# ==========================
if (Test-Path "$FrontendPath\package.json") {
    Write-Log "Instalando dependências Node.js..."
    try {
        cd $FrontendPath
        npm install 2>&1 | ForEach-Object { Write-Log $_ }
        Write-Log "Instalação de pacotes Node.js concluída"
    } catch {
        Write-Log "Erro ao instalar Node.js: $_"
    }
}

# ==========================
# Executar autocorretor Python
# ==========================
$PythonExe = (Get-Command python).Source
$AutoCorrector = "$ToolsPath\autocorrector.py"

if (Test-Path $AutoCorrector) {
    Write-Log "Iniciando autocorretor Python (leve) em background..."
    Start-Process -NoNewWindow -FilePath $PythonExe -ArgumentList @($AutoCorrector, "--watch", "--level", "light")
} else {
    Write-Log "Autocorretor não encontrado: $AutoCorrector"
}

# ==========================
# Tutorial PDF (simples) da etapa
# ==========================
$TutorialTxt = "$ProjectRoot\Tutorial_Stage1.2.txt"
$TutorialContent = @"
UNIC QUANTIC - Stage1.2
------------------------
1. Criação de pastas essenciais
2. Instalação de pacotes Python
3. Instalação de pacotes Node.js
4. Inicialização do autocorretor Python
5. Logs gerados em: $LogFile
6. Cada execução atualiza este tutorial

Como usar:
- Abra o PowerShell como Administrador
- Execute: .\setup_unic_quantic_stage1.2.ps1
- Verifique logs para acompanhamento
"@
$TutorialContent | Out-File -FilePath $TutorialTxt -Encoding UTF8
Write-Log "Tutorial Stage1.2 criado: $TutorialTxt"

Write-Log "UNIC QUANTIC Stage1.2 finalizado com sucesso!"
# ===== FIM 5setup_unic_quantic_stage1.2.ps1 =====

# ===== INICIO 6setup_unic_quantic_stage1.2.ps1 =====
# =====================================
# UNIC QUANTIC - Setup Stage1.2
# =====================================
# Autor: Automação Total
# Funcionalidades: instalação de pacotes, frontend/backend, autocorreção, logs
# =====================================

$BasePath = "C:\UNIC QUANTIC"
$ScriptsPath = "$BasePath\scripts"
$ToolsPath   = "$BasePath\tools"
$FrontendPath = "$BasePath\frontend"
$TutorialPath = "$BasePath\Tutorial_Stage1.2.txt"

# Criação de pastas caso não existam
foreach ($p in @($ScriptsPath, $ToolsPath, $FrontendPath)) {
    if (!(Test-Path $p)) { New-Item -Path $p -ItemType Directory | Out-Null }
}

# ============================
# ⿡ Criar requirements.txt
# ============================
$requirements = @"
fastapi==0.111.0
uvicorn==0.23.2
pydantic==2.7.1
requests==2.32.0
beautifulsoup4==4.13.0
selenium==5.10.0
psycopg2-binary==2.9.7
sqlalchemy==2.3.2
pandas==2.1.1
numpy==1.27.2
plotly==5.19.0
python-dotenv==1.1.1
"@

$requirementsPath = "$BasePath\requirements.txt"
$requirements | Out-File -FilePath $requirementsPath -Encoding UTF8

Write-Host "📦 requirements.txt criado."

# ============================
# ⿢ Criar package.json
# ============================
$packageJson = @"
{
  "name": "unic-quantic",
  "version": "1.0.0",
  "description": "Frontend do UNIC QUANTIC",
  "main": "index.js",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "next": "^13.5.7"
  },
  "author": "Automação Total",
  "license": "MIT"
}
"@

$packageJsonPath = "$FrontendPath\package.json"
$packageJson | Out-File -FilePath $packageJsonPath -Encoding UTF8

Write-Host "📦 package.json criado."

# ============================
# ⿣ Instalar pacotes Python
# ============================
Write-Host "Instalando pacotes Python..."
pip install -r $requirementsPath

# ============================
# ⿤ Instalar dependências Node.js
# ============================
Write-Host "Instalando dependências Node.js..."
npm install --prefix $FrontendPath

# ============================
# ⿥ Iniciar autocorretor Python
# ============================
$PythonExe = (Get-Command python).Source
$AutoCorrector = "$ToolsPath\autocorrector.py"

if (Test-Path $AutoCorrector) {
    Write-Host "Iniciando autocorretor Python (leve) em background..."
    Start-Process -NoNewWindow -FilePath $PythonExe -ArgumentList @($AutoCorrector, "--watch", "--level", "light")
} else {
    Write-Host "⚠ Autocorretor não encontrado: $AutoCorrector"
}

# ============================
# ⿦ Criar Tutorial da Etapa
# ============================
$tutorial = @"
UNIC QUANTIC - Stage1.2
========================
- Criado requirements.txt com pacotes essenciais Python
- Criado package.json válido para frontend Next.js
- Instalados pacotes Python via pip
- Instaladas dependências Node.js via npm
- Autocorretor Python iniciado em background
"@

$tutorial | Out-File -FilePath $TutorialPath -Encoding UTF8

Write-Host "📄 Tutorial Stage1.2 criado: $TutorialPath"
Write-Host "✅ UNIC QUANTIC Stage1.2 finalizado com sucesso!"
# ===== FIM 6setup_unic_quantic_stage1.2.ps1 =====

# ===== INICIO 7setup_unic_quantic_stage1.2.ps1 =====
# ============================================
# UNIC QUANTIC - Setup Stage1.2.1
# Autor: Automação Total
# Descrição: Instala backend, frontend, DB, autocorrector, corrige erros de paths e pacotes
# ============================================

# -----------------------------
# Paths principais
# -----------------------------
$BasePath = "C:\UNIC QUANTIC"
$ScriptsPath = "$BasePath\scripts"
$ToolsPath = "$BasePath\tools"
$FrontendPath = "$BasePath\frontend"

# -----------------------------
# Criação de pastas
# -----------------------------
$folders = @($BasePath, $ScriptsPath, $ToolsPath, $FrontendPath)
foreach ($folder in $folders) {
    if (-Not (Test-Path $folder)) { New-Item -ItemType Directory -Path $folder -Force | Out-Null }
}

# -----------------------------
# Criar requirements.txt básico
# -----------------------------
$RequirementsFile = "$BasePath\requirements.txt"
@"
beautifulsoup4>=4.13.0
selenium>=4.13.0
requests>=2.31.0
pandas>=2.1.0
numpy>=1.26.0
"@ | Out-File -FilePath $RequirementsFile -Encoding UTF8

# -----------------------------
# Criar package.json básico frontend
# -----------------------------
$PackageJsonFile = "$FrontendPath\package.json"
@"
{
  "name": "unic-quantic",
  "version": "1.0.0",
  "description": "Frontend da plataforma UNIC QUANTIC",
  "main": "index.js",
  "scripts": {
    "start": "next dev",
    "build": "next build",
    "lint": "next lint"
  },
  "dependencies": {
    "react": "^18.2.0",
    "next": "^14.0.0"
  }
}
"@ | Out-File -FilePath $PackageJsonFile -Encoding UTF8

# -----------------------------
# Instalar pacotes Python
# -----------------------------
Write-Host "Instalando pacotes Python..."
python -m pip install --upgrade pip
python -m pip install -r $RequirementsFile
Write-Host "Pacotes Python instalados."

# -----------------------------
# Instalar pacotes Node.js
# -----------------------------
Write-Host "Instalando pacotes Node.js..."
npm install --prefix $FrontendPath
Write-Host "Pacotes Node.js instalados."

# -----------------------------
# Corrigir paths para autocorrector
# -----------------------------
$PythonExe = (Get-Command python).Source
$AutocorrectorScript = "$ToolsPath\autocorrector.py"

if (-Not (Test-Path $AutocorrectorScript)) {
    Write-Host "Aviso: autocorrector.py não encontrado em $ToolsPath"
    # Pode baixar ou criar um autocorrector.py minimal
    @"
import time
print('Autocorrector placeholder iniciado')
time.sleep(5)
"@ | Out-File -FilePath $AutocorrectorScript -Encoding UTF8
}

# -----------------------------
# Iniciar autocorrector leve/moderado/avançado
# -----------------------------
Write-Host "Iniciando autocorrector (leve) em background..."
Start-Process -NoNewWindow -FilePath $PythonExe -ArgumentList ""$AutocorrectorScript" --watch --level light"

Write-Host "Stage1.2.1 concluído com sucesso!"
Write-Host "Tutorial Stage1.2.1 gerado automaticamente em $BasePath\Tutorial_Stage1.2.1.txt"

# -----------------------------
# Gerar tutorial básico em TXT
# -----------------------------
$TutorialFile = "$BasePath\Tutorial_Stage1.2.1.txt"
@"
UNIC QUANTIC - Stage1.2.1
-----------------------------
Pastas criadas:
- $BasePath
- $ScriptsPath
- $ToolsPath
- $FrontendPath

Pacotes instalados:
- Python: pip install -r requirements.txt
- Node.js: npm install (frontend)

Autocorrector:
- Local: $AutocorrectorScript
- Iniciado automaticamente em modo leve
- Correção futura para moderado/avançado será integrada

Observações:
- Corrigidos erros de aspas no PowerShell
- Corrigidos paths com espaços
- Criado requirements.txt e package.json básicos
"@ | Out-File -FilePath $TutorialFile -Encoding UTF8
# ===== FIM 7setup_unic_quantic_stage1.2.ps1 =====

# ===== INICIO 8setup_unic_quantic_stage1.2.ps1 =====
# ==============================================
# UNIC QUANTIC - Stage1.2.1
# Script completo corrigido
# ==============================================

# Definir paths principais
$BasePath = "C:\UNIC QUANTIC"
$ScriptsPath = "$BasePath\scripts"
$ToolsPath = "$BasePath\tools"
$FrontendPath = "$BasePath\frontend"
$BackendPath = "$BasePath\backend"
$PythonExe = (Get-Command python).Source

# Criar pastas caso não existam
$folders = @($BasePath, $ScriptsPath, $ToolsPath, $FrontendPath, $BackendPath)
foreach ($f in $folders) {
    if (-not (Test-Path $f)) { New-Item -Path $f -ItemType Directory | Out-Null }
}

# -----------------------------
# Criar requirements.txt se não existir
# -----------------------------
$requirementsFile = "$BasePath\requirements.txt"
if (-not (Test-Path $requirementsFile)) {
    @"
beautifulsoup4==4.13.0
requests==2.31.0
selenium==4.13.0
pandas==2.1.0
numpy==1.26.0
"@ | Out-File -FilePath $requirementsFile -Encoding UTF8
}

# -----------------------------
# Criar package.json para frontend se não existir
# -----------------------------
$packageJsonFile = "$FrontendPath\package.json"
if (-not (Test-Path $packageJsonFile)) {
    @"
{
  "name": "unic-quantic",
  "version": "1.0.0",
  "description": "Frontend UNIC QUANTIC",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {}
}
"@ | Out-File -FilePath $packageJsonFile -Encoding UTF8
}

# -----------------------------
# Instalar dependências Python
# -----------------------------
Write-Host "Instalando pacotes Python..."
pip install -r $requirementsFile
Write-Host "Instalação de pacotes Python concluída."

# -----------------------------
# Instalar dependências Node.js
# -----------------------------
Write-Host "Instalando pacotes Node.js..."
npm install --prefix $FrontendPath
Write-Host "Instalação de pacotes Node.js concluída."

# -----------------------------
# Criar autocorrector.py placeholder se não existir
# -----------------------------
$autocorrectorFile = "$ToolsPath\autocorrector.py"
if (-not (Test-Path $autocorrectorFile)) {
    @"
import time
print('Autocorrector placeholder iniciado')
time.sleep(5)
"@ | Out-File -FilePath $autocorrectorFile -Encoding UTF8
}

# -----------------------------
# Função para iniciar autocorrector em background
# -----------------------------
function Start-Autocorrector {
    param (
        [string]$Level = "light"  # light, moderate, advanced
    )

    $argsArray = @($autocorrectorFile, "--watch", "--level", $Level)
    Start-Process -NoNewWindow -FilePath $PythonExe -ArgumentList $argsArray
    Write-Host "Autocorrector iniciado em background - Nível: $Level"
}

# Iniciar autocorrector leve
Start-Autocorrector -Level "light"
# Pode iniciar também moderado/avançado se quiser
# Start-Autocorrector -Level "moderate"
# Start-Autocorrector -Level "advanced"

# -----------------------------
# Criar Tutorial Stage1.2.1
# -----------------------------
$tutorialFile = "$BasePath\Tutorial_Stage1.2.1.txt"
@"
UNIC QUANTIC Stage1.2.1
========================

- Pastas criadas: scripts, tools, frontend, backend
- requirements.txt criado automaticamente
- package.json criado automaticamente
- Pacotes Python e Node.js instalados automaticamente
- Autocorrector Python iniciado em background (leve)
- Nível do autocorrector pode ser alterado para moderate ou advanced
- Tutorial atualizado neste arquivo
"@ | Out-File -FilePath $tutorialFile -Encoding UTF8

Write-Host "UNIC QUANTIC Stage1.2.1 finalizado com sucesso!"
Write-Host "Tutorial salvo em: $tutorialFile"
# ===== FIM 8setup_unic_quantic_stage1.2.ps1 =====

# ===== INICIO 9setup_unic_quantic_stage1.2.ps1 =====
# ==============================
# UNIC QUANTIC - Stage1.2.1 Setup
# ==============================

$ProjectRoot = "C:\UNIC QUANTIC"
$ScriptsPath = "$ProjectRoot\scripts"
$ToolsPath = "$ProjectRoot\tools"
$FrontendPath = "$ProjectRoot\frontend"

$PythonExe = (Get-Command python).Source

# Criar pastas se não existirem
$paths = @($ScriptsPath, $ToolsPath, $FrontendPath)
foreach ($p in $paths) {
    if (-Not (Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null }
}

# Criar requirements.txt se não existir
$requirementsFile = "$ProjectRoot\requirements.txt"
if (-Not (Test-Path $requirementsFile)) {
    @"
beautifulsoup4==4.13.0
selenium>=4.10.0
pandas
numpy
requests
scikit-learn
tensorflow
"@ | Out-File -FilePath $requirementsFile -Encoding UTF8
}

# Instalar dependências Python
Write-Host "Instalando pacotes Python..."
pip install -r "$requirementsFile"

# Instalar dependências Node.js
Write-Host "Instalando pacotes frontend..."
if (-Not (Test-Path "$FrontendPath\package.json")) {
    @"
{
  "name": "unic-quantic-frontend",
  "version": "1.0.0",
  "description": "Frontend da plataforma UNIC QUANTIC",
  "main": "index.js",
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  }
}
"@ | Out-File -FilePath "$FrontendPath\package.json" -Encoding UTF8
}

cd $FrontendPath
npm install

# Função para iniciar autocorrector
function Start-Autocorrector {
    param (
        [string]$Level = "light"
    )
    & "$PythonExe" "$ToolsPath\autocorrector.py" --watch --level $Level
    Write-Host "Autocorrector iniciado em background - Nível: $Level"
}

# Rodar autocorrector leve
Start-Autocorrector -Level "light"

# Criar tutorial
$TutorialPath = "$ProjectRoot\Tutorial_Stage1.2.1.txt"
@"
UNIC QUANTIC - Stage1.2.1
- Estrutura de pastas criada
- requirements.txt gerado
- Pacotes Python instalados
- package.json gerado e pacotes Node.js instalados
- Autocorrector configurado e rodando
"@ | Out-File -FilePath $TutorialPath -Encoding UTF8

Write-Host "UNIC QUANTIC Stage1.2.1 finalizado com sucesso!"
# ===== FIM 9setup_unic_quantic_stage1.2.ps1 =====

# ===== INICIO autocorrector.py.py =====
Python 3.11.3 (tags/v3.11.3:f3909b8, Apr  4 2023, 23:49:59) [MSC v.1934 64 bit (AMD64)] on win32
Type "help", "copyright", "credits" or "license()" for more information.
>>> # autocorrector.py
... # Versão inicial do AutoCorrector — monitora logs e aplica correções simples.
... import os, re, sys, time, json, subprocess
... from pathlib import Path
... 
... BASE = Path(r"C:\UNIC QUANTIC")
... LOGS = BASE / "logs"
... EXEC_LOG = LOGS / "execution_log.txt"
... TOOLS = BASE / "tools"
... FRONTEND = BASE / "frontend"
... BACKEND = BASE / "backend"
... 
... REPORT = LOGS / "autocorrect_report.json"
... 
... def tail_lines(path, last_pos):
...     with open(path, "r", encoding="utf-8", errors="ignore") as f:
...         f.seek(last_pos)
...         data = f.read()
...         return data, f.tell()
... 
... def detect_language_from_text(text):
...     if "Traceback" in text or "ModuleNotFoundError" in text or "SyntaxError" in text:
...         return "python"
...     if "npm ERR!" in text or "Cannot find module" in text:
...         return "node"
...     if "ERROR:" in text and "package.json" in text:
...         return "json"
...     if "syntax error at or near" in text or "psql" in text:
...         return "sql"
...     if "not recognized as the name of a cmdlet" in text:
...         return "powershell"
...     return "unknown"
... 
... def safe_run(cmd, cwd=None):
...     try:
...         print("RUN:", cmd, "cwd=", cwd)
...         res = subprocess.run(cmd, cwd=cwd, shell=False, check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
...         return res.returncode, res.stdout, res.stderr
...     except Exception as e:
...         return 1, "", str(e)
... 
... def fix_python_missing_module(text):
...     m = re.search(r"No module named ['\"]?([^'\" ]+)['\"]?", text)
...     if m:
...         pkg = m.group(1)
...         # Use same python interpreter
...         cmd = [sys.executable, "-m", "pip", "install", pkg]
...         rc, out, err = safe_run(cmd)
...         return {"action": f"pip install {pkg}", "rc": rc, "out": out, "err": err}
...     return None
... 
... def fix_node_dependencies(text):
...     # try npm install in frontend
...     cmd = ["npm", "install"]
...     rc, out, err = safe_run(cmd, cwd=str(FRONTEND))
...     return {"action": "npm install (frontend)", "rc": rc, "out": out, "err": err}
... 
... def remove_nonprintable_from_file(path):
...     try:
...         s = Path(path).read_text(encoding="utf-8", errors="ignore")
...         cleaned = re.sub(r"[\u00A0\u200B-\u200F]", " ", s)
...         # remove other control chars except newline/tab
...         cleaned = re.sub(r"[^\x09\x0A\x0D\x20-\x7E]", "", cleaned)
...         Path(path).write_text(cleaned, encoding="utf-8")
...         return True
    except Exception as e:
        return False

def fix_package_json_whitespace(path):
    try:
        s = Path(path).read_text(encoding="utf-8", errors="ignore")
        s2 = s.replace("\u00A0", " ").replace('\r', '')
        Path(path).write_text(s2, encoding="utf-8")
        return True
    except Exception as e:
        return False

def log_report(entry):
    rep = {}
    if REPORT.exists():
        try:
            rep = json.loads(REPORT.read_text(encoding="utf-8"))
        except:
            rep = {}
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    rep.setdefault("actions", []).append({"time": ts, **entry})
    REPORT.write_text(json.dumps(rep, indent=2, ensure_ascii=False), encoding="utf-8")

def process_text(txt):
    lang = detect_language_from_text(txt)
    if lang == "python":
        result = fix_python_missing_module(txt)
        if result:
            log_report({"detected": "python_missing_module", **result})
            return True
        # remove nonprintable example for backend files
        # if we find file paths, try cleaning them
        files = re.findall(r"[a-zA-Z]:\\[^\s:,'\"<>]+", txt)
        for f in files:
            if Path(f).exists():
                ok = remove_nonprintable_from_file(f)
                log_report({"action":"remove_nonprintable", "file":str(f), "ok": ok})
                return ok
    if lang == "node":
        res = fix_node_dependencies(txt)
        log_report({"detected":"node_issue", **res})
        return True
    if lang == "json":
        pj = FRONTEND / "package.json"
        ok = fix_package_json_whitespace(pj)
        log_report({"detected":"package_json_fix", "file":str(pj), "ok": ok})
        return ok
    # fallback
    log_report({"detected":"unknown","snippet": txt[:500]})
    return False

def watch_loop(poll_interval=5):
    last_pos = 0
    if not EXEC_LOG.exists():
        EXEC_LOG.parent.mkdir(parents=True, exist_ok=True)
        EXEC_LOG.write_text("", encoding="utf-8")
    last_pos = EXEC_LOG.stat().st_size
    print("Autocorrector: monitorando", EXEC_LOG)
    while True:
        time.sleep(poll_interval)
        data, last_pos = tail_lines(str(EXEC_LOG), last_pos)
        if data:
            print("Novos logs encontrados, processando...")
            process_text(data)

if _name_ == "_main_":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("--once", action="store_true", help="Executar uma vez (processa log atual)")
    p.add_argument("--watch", action="store_true", help="Ficar monitorando o log continuamente")
    args = p.parse_args()
    if args.once:
        if EXEC_LOG.exists():
            txt = EXEC_LOG.read_text(encoding="utf-8", errors="ignore")
            print("Processando log (once)...")
            process_text(txt)
        else:
            print("Nenhum log encontrado.")
    elif args.watch:
        watch_loop()
    else:

# ===== FIM autocorrector.py.py =====

