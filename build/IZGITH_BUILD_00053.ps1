$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$ext = Join-Path $root 'extension'
$manifestPath = Join-Path $ext 'manifest.json'
$workerPath = Join-Path $ext 'sw.js'
$dist = Join-Path $root 'dist'

Write-Host 'IZGITH BUILD 00053 - validation and packaging'

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw 'manifest.json nao encontrado' }
if (-not (Test-Path -LiteralPath $workerPath -PathType Leaf)) { throw 'sw.js nao encontrado' }

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ([int]$manifest.manifest_version -ne 3) { throw 'Manifest nao e Manifest V3' }
$workerRel = [string]$manifest.background.service_worker
if ([string]::IsNullOrWhiteSpace($workerRel)) { throw 'service_worker vazio' }
if (-not (Test-Path -LiteralPath (Join-Path $ext $workerRel) -PathType Leaf)) { throw 'service worker declarado nao existe' }

foreach ($size in 16,32,48,128) {
  $icon = Join-Path $ext ('assets\icons\icon{0}.png' -f $size)
  if (-not (Test-Path -LiteralPath $icon -PathType Leaf)) { throw ('icone ausente: icon{0}.png' -f $size) }
  if ((Get-Item -LiteralPath $icon).Length -le 0) { throw ('icone vazio: icon{0}.png' -f $size) }
}

$themesPath = Join-Path $ext 'themes\catalog.json'
if (-not (Test-Path -LiteralPath $themesPath -PathType Leaf)) { throw 'catalogo de temas ausente' }
$themes = Get-Content -LiteralPath $themesPath -Raw | ConvertFrom-Json
if ([int]$themes.total -ne 36) { throw 'catalogo nao contem 36 temas' }

$required = @(
  'integrations\SONPEF\integration.json',
  'integrations\CONVGPT\integration.json',
  'integrations\KIT_UNICO\integration.json',
  'integrations\assistant_registry.json'
)
foreach ($item in $required) {
  if (-not (Test-Path -LiteralPath (Join-Path $root $item) -PathType Leaf)) { throw ('arquivo obrigatorio ausente: ' + $item) }
}

New-Item -ItemType Directory -Path $dist -Force | Out-Null
$stage = Join-Path $dist 'IZGITH_v6.0.0.00053_FULL'
$zip = Join-Path $dist 'IZGITH_v6.0.0.00053_FULL.zip'
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
Copy-Item -LiteralPath $ext -Destination (Join-Path $stage 'extension') -Recurse -Force
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal

Write-Host ('[OK] Manifest V3: ' + $manifest.version)
Write-Host '[OK] Service worker presente'
Write-Host '[OK] Icones 16/32/48/128 presentes'
Write-Host '[OK] Catalogo com 36 temas'
Write-Host '[OK] SONPEF / CONVGPT / KIT_UNICO registrados'
Write-Host ('[OK] ZIP: ' + $zip)
