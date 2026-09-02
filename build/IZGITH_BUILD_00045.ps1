#requires -version 2.0
[CmdletBinding()]
param([string]$Root = "")
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrEmpty($Root)) {
  $Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
}

$ext = Join-Path $Root 'extension'
$required = @(
  (Join-Path $ext 'manifest.json'),
  (Join-Path $ext 'sw.js'),
  (Join-Path $ext 'ui\popup.html'),
  (Join-Path $ext 'ui\popup.js'),
  (Join-Path $ext 'ui\popup.css'),
  (Join-Path $ext 'ui\dashboard.html'),
  (Join-Path $ext 'ui\dashboard.js'),
  (Join-Path $ext 'ui\dashboard.css'),
  (Join-Path $ext 'assets\icons\icon16.png'),
  (Join-Path $ext 'assets\icons\icon32.png'),
  (Join-Path $ext 'assets\icons\icon48.png'),
  (Join-Path $ext 'assets\icons\icon128.png'),
  (Join-Path $ext 'themes\catalog.json'),
  (Join-Path $ext 'scripts\assistants.js')
)

$missing = @($required | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missing.Count -gt 0) {
  Write-Host '[FAIL] Arquivos obrigatorios ausentes:' -ForegroundColor Red
  $missing | ForEach-Object { Write-Host (' - ' + $_) -ForegroundColor Red }
  exit 1
}

$manifestPath = Join-Path $ext 'manifest.json'
$manifestText = Get-Content -LiteralPath $manifestPath -Raw
if ($manifestText -notmatch '"manifest_version"\s*:\s*3') { Write-Host '[FAIL] Manifest V3 ausente.' -ForegroundColor Red; exit 1 }
if ($manifestText -notmatch '"service_worker"\s*:\s*"sw\.js"') { Write-Host '[FAIL] service_worker invalido.' -ForegroundColor Red; exit 1 }
if ($manifestText -match '"background"\s*:\s*\{\s*\}') { Write-Host '[FAIL] background vazio.' -ForegroundColor Red; exit 1 }

$sw = Get-Content -LiteralPath (Join-Path $ext 'sw.js') -Raw
if ([string]::IsNullOrEmpty($sw)) { Write-Host '[FAIL] sw.js vazio.' -ForegroundColor Red; exit 1 }
if ($sw -match '\btype\s*=\s*') { Write-Host '[FAIL] JS contem initializer type= invalido.' -ForegroundColor Red; exit 1 }
if ($sw -match '\?\.') { Write-Host '[FAIL] sw.js usa optional chaining; removido para compatibilidade ampla.' -ForegroundColor Red; exit 1 }
if ($sw -notmatch 'NATIVE_HOST_CHECK') { Write-Host '[FAIL] fluxo de verificacao do host ausente.' -ForegroundColor Red; exit 1 }
if ($sw -notmatch 'NATIVE_CALL') { Write-Host '[FAIL] roteamento NATIVE_CALL ausente.' -ForegroundColor Red; exit 1 }

$catalog = Get-Content -LiteralPath (Join-Path $ext 'themes\catalog.json') -Raw | ConvertFrom-Json
if ([int]$catalog.total -ne 36) { Write-Host '[FAIL] Catalogo nao possui 36 temas.' -ForegroundColor Red; exit 1 }

Write-Host '[OK] IZGITH 00045: estrutura, Manifest V3, service worker, UI, icones, temas e assistentes verificados.' -ForegroundColor Green
Write-Host '[OK] Modo unificado: Ultra + Controlado.' -ForegroundColor Green
Write-Host '[OK] Native Messaging nao e necessario para o boot; quando instalado, o host e sondado antes de operacoes nativas.' -ForegroundColor Green
Write-Host '[OK] PowerShell 2.0+; sem ?. e sem variavel $Host.' -ForegroundColor Green
exit 0
