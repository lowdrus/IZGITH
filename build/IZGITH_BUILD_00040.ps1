Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
Write-Host '=========================================================='
Write-Host 'IZGITH CLEAN CORE 00040 - BUILD / VERIFY'
Write-Host '=========================================================='
$py = Get-Command py.exe -ErrorAction SilentlyContinue
if ($null -eq $py) { $py = Get-Command python.exe -ErrorAction SilentlyContinue }
if ($null -eq $py) { throw 'Python nao encontrado. Instale Python 3 e tente novamente.' }
& $py.Source 'scripts/validate_project.py'
if ($LASTEXITCODE -ne 0) { throw 'Validacao falhou.' }
& $py.Source 'scripts/package_extension.py'
if ($LASTEXITCODE -ne 0) { throw 'Empacotamento falhou.' }
Write-Host '[OK] Build e pacote concluidos.'
Write-Host ('[OK] Extensao: ' + (Join-Path $root 'extension'))
Write-Host ('[OK] ZIP: ' + (Join-Path $root 'dist'))
