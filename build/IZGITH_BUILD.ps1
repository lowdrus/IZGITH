[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Python = Get-Command python -ErrorAction SilentlyContinue
if (-not $Python) { $Python = Get-Command py -ErrorAction SilentlyContinue }
if (-not $Python) { throw 'Python 3.11+ não encontrado.' }
Push-Location $Root
try {
  & $Python.Source scripts/validate_project.py
  if ($LASTEXITCODE -ne 0) { throw 'Validação falhou.' }
  & $Python.Source -m unittest discover -s tests -v
  if ($LASTEXITCODE -ne 0) { throw 'Testes falharam.' }
  & $Python.Source scripts/package_extension.py
  if ($LASTEXITCODE -ne 0) { throw 'Empacotamento falhou.' }
  Write-Host 'BUILD PASS ✅' -ForegroundColor Green
} finally { Pop-Location }
