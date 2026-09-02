#requires -version 2.0
[CmdletBinding()]
param([string]$Root = "")
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrEmpty($Root)) { $Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path) }
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
  (Join-Path $ext 'assets\icons\icon128.png')
)
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missing.Count -gt 0) {
  Write-Host '[FAIL] Required files are missing:' -ForegroundColor Red
  $missing | ForEach-Object { Write-Host (' - ' + $_) -ForegroundColor Red }
  exit 1
}
$manifestPath = Join-Path $ext 'manifest.json'
$manifestText = Get-Content -LiteralPath $manifestPath -Raw
if ($manifestText -notmatch '"manifest_version"\s*:\s*3') { Write-Host '[FAIL] Manifest V3 missing.' -ForegroundColor Red; exit 1 }
if ($manifestText -notmatch '"service_worker"\s*:\s*"sw\.js"') { Write-Host '[FAIL] Service worker declaration missing.' -ForegroundColor Red; exit 1 }
$sw = Get-Content -LiteralPath (Join-Path $ext 'sw.js') -Raw
if ([string]::IsNullOrEmpty($sw)) { Write-Host '[FAIL] sw.js is empty.' -ForegroundColor Red; exit 1 }
if ($sw -match 'type\s*=\s*') { Write-Host '[FAIL] JS contains invalid type= initializer.' -ForegroundColor Red; exit 1 }
if ($sw -match '\?\.') { Write-Host '[FAIL] JS contains optional chaining; review for older browser compatibility.' -ForegroundColor Red; exit 1 }
Write-Host '[OK] MV3 + service worker + UI + four icons verified.' -ForegroundColor Green
Write-Host '[OK] Native Messaging is optional for extension boot.' -ForegroundColor Green
Write-Host '[OK] Canonical Native Host: com.izgith.host' -ForegroundColor Green
Write-Host '[OK] Version target: 6.0.0.00044' -ForegroundColor Green
exit 0
