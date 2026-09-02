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