#requires -version 2.0
[CmdletBinding()]
param([string]$Root = "")
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrEmpty($Root)) { $Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path) }
$ext = Join-Path $Root 'extension'
$manifest = Join-Path $ext 'manifest.json'
$sw = Join-Path $ext 'sw.js'
$required = @(
  $manifest,
  $sw,
  (Join-Path $ext 'ui\popup.html'),
  (Join-Path $ext 'ui\popup.js'),
  (Join-Path $ext 'ui\popup.css'),
  (Join-Path $ext 'ui\dashboard.html'),
  (Join-Path $ext 'ui\dashboard.js'),
  (Join-Path $ext 'ui\dashboard.css'),
  (Join-Path $ext 'assets\icons\icon16.png'),
  (Join-Path $ext 'assets\icons\icon32.png'),
  (Join-Path $ext 'assets\icons\icon48.png'),
  (Join-Path $ext 'assets\icons\icon128.png')
)
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missing.Count -gt 0) {
  Write-Host '[FAIL] Arquivos obrigatorios ausentes:' -ForegroundColor Red
  $missing | ForEach-Object { Write-Host (' - ' + $_) -ForegroundColor Red }
  exit 1
}
try {
  $json = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
  if ($json.manifest_version -ne 3) { throw 'manifest_version diferente de 3' }
  if ([string]::IsNullOrEmpty($json.background.service_worker)) { throw 'background.service_worker vazio' }
  if (-not (Test-Path -LiteralPath (Join-Path $ext $json.background.service_worker) -PathType Leaf)) { throw 'service worker referenciado nao existe' }
} catch {
  Write-Host ('[FAIL] Manifesto: ' + $_.Exception.Message) -ForegroundColor Red
  exit 1
}
Write-Host '[OK] Estrutura MV3, UI e icones verificados.' -ForegroundColor Green
Write-Host ('[OK] Raiz: ' + $Root)
Write-Host '[INFO] Native Messaging nao e requisito para o boot da extensao.' -ForegroundColor Yellow
Write-Host '[INFO] Componentes historicos permanecem em archive/legacy ate promocao individual.' -ForegroundColor Yellow
exit 0
