#requires -version 2.0
[CmdletBinding()]
param([string]$Root = "")
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrEmpty($Root)) { $Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path) }
$ext = Join-Path $Root 'extension'
$required = @(
  (Join-Path $ext 'manifest.json'), (Join-Path $ext 'sw.js'),
  (Join-Path $ext 'ui\popup.html'), (Join-Path $ext 'ui\popup.js'), (Join-Path $ext 'ui\popup.css'),
  (Join-Path $ext 'ui\dashboard.html'), (Join-Path $ext 'ui\dashboard.js'), (Join-Path $ext 'ui\dashboard.css'),
  (Join-Path $ext 'assets\icons\icon16.png'), (Join-Path $ext 'assets\icons\icon32.png'),
  (Join-Path $ext 'assets\icons\icon48.png'), (Join-Path $ext 'assets\icons\icon128.png')
)
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missing.Count -gt 0) { Write-Host '[FAIL] Arquivos obrigatorios ausentes:' -ForegroundColor Red; $missing | ForEach-Object { Write-Host (' - ' + $_) -ForegroundColor Red }; exit 1 }
try {
  $json = Get-Content -LiteralPath (Join-Path $ext 'manifest.json') -Raw | ConvertFrom-Json
  if ($json.manifest_version -ne 3) { throw 'manifest_version deve ser 3' }
  if ([string]::IsNullOrEmpty($json.background.service_worker)) { throw 'background.service_worker vazio' }
  if (-not (Test-Path -LiteralPath (Join-Path $ext $json.background.service_worker) -PathType Leaf)) { throw 'service worker referenciado nao existe' }
  foreach ($key in @('16','32','48','128')) { if (-not (Test-Path -LiteralPath (Join-Path $ext $json.icons.$key) -PathType Leaf)) { throw ('icone ausente: ' + $key) } }
} catch { Write-Host ('[FAIL] Manifesto/MV3: ' + $_.Exception.Message) -ForegroundColor Red; exit 1 }
$swText = Get-Content -LiteralPath (Join-Path $ext 'sw.js') -Raw
if ($swText -match 'type\s*=') { Write-Host '[WARN] Possivel inicializador invalido no JS detectado.' -ForegroundColor Yellow }
Write-Host '[OK] Estrutura MV3, service worker, UI e 4 icones verificados.' -ForegroundColor Green
Write-Host ('[OK] Raiz: ' + $Root)
Write-Host '[OK] Native Messaging nao e requisito para o boot.' -ForegroundColor Green
Write-Host '[OK] Modo unificado: Ultra + Controlado.' -ForegroundColor Green
exit 0
