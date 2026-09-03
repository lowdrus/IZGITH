# IZGITH BUILD 00058 - Windows PowerShell 5.x / 7.x compatible
# ASCII source on purpose: avoids code-page corruption in Windows PowerShell 5.
[CmdletBinding()]
param(
  [string]$SourceRoot = '',
  [string]$OutputRoot = ''
)

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($SourceRoot)) { $SourceRoot = Split-Path -Parent $scriptRoot }
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
if ([string]::IsNullOrWhiteSpace($OutputRoot)) { $OutputRoot = Join-Path $SourceRoot 'dist' }

function Write-Ok([string]$Text) { Write-Host ('[OK] ' + $Text) -ForegroundColor Green }
function Write-Fail([string]$Text) { Write-Host ('[FAIL] ' + $Text) -ForegroundColor Red }
function Require-File([string]$Path, [string]$Label) {
  if (!(Test-Path -LiteralPath $Path -PathType Leaf)) { throw ($Label + ' missing: ' + $Path) }
  Write-Ok $Label
}
function Require-Dir([string]$Path, [string]$Label) {
  if (!(Test-Path -LiteralPath $Path -PathType Container)) { throw ($Label + ' missing: ' + $Path) }
  Write-Ok $Label
}
function Read-Json([string]$Path) {
  return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json)
}

Write-Host ''
Write-Host '=========================================================='
Write-Host ' IZGITH - FULL BUILD 00058'
Write-Host ' PowerShell 5.x / 7.x compatible'
Write-Host '=========================================================='
Write-Host ('Source: ' + $SourceRoot)
Write-Host ('Output: ' + $OutputRoot)
Write-Host ''

$extensionRoot = Join-Path $SourceRoot 'extension'
$manifestPath = Join-Path $extensionRoot 'manifest.json'
$workerPath = Join-Path $extensionRoot 'sw.js'

Require-Dir $extensionRoot 'extension'
Require-File $manifestPath 'manifest.json'
Require-File $workerPath 'service worker'

$manifest = Read-Json $manifestPath
if ([int]$manifest.manifest_version -ne 3) { throw 'manifest_version is not 3' }
if ([string]::IsNullOrWhiteSpace([string]$manifest.version)) { throw 'manifest version is empty' }
$workerRel = [string]$manifest.background.service_worker
if ([string]::IsNullOrWhiteSpace($workerRel)) { throw 'background.service_worker is empty' }
Require-File (Join-Path $extensionRoot $workerRel) 'background service worker target'

$iconSizes = @(16,32,48,128)
foreach ($size in $iconSizes) {
  $icon = Join-Path $extensionRoot ('assets\icons\icon' + $size + '.png')
  Require-File $icon ('icon' + $size + '.png')
  $bytes = (Get-Item -LiteralPath $icon).Length
  if ($bytes -lt 100) { throw ('icon' + $size + '.png appears invalid or empty') }
}

$popup = Join-Path $extensionRoot ([string]$manifest.action.default_popup)
Require-File $popup 'popup'
Require-Dir (Join-Path $extensionRoot 'ui') 'ui'
Require-Dir (Join-Path $extensionRoot 'themes') 'themes'
Require-File (Join-Path $extensionRoot 'themes\catalog.json') 'theme catalog'
Require-File (Join-Path $SourceRoot 'integrations\SONPEF\integration.json') 'SONPEF integration registry'
Require-File (Join-Path $SourceRoot 'integrations\CONV-D\integration.json') 'CONV-D integration registry'
Require-File (Join-Path $SourceRoot 'integrations\KIT_UNICO\integration.json') 'KIT_UNICO integration registry'
Require-File (Join-Path $SourceRoot 'integrations\assistant_registry.json') 'assistant registry'

$themeCatalog = Read-Json (Join-Path $extensionRoot 'themes\catalog.json')
if ([int]$themeCatalog.total -ne 36) { throw 'theme catalog must contain 36 themes' }
Write-Ok '36 themes'

$registry = Read-Json (Join-Path $SourceRoot 'integrations\assistant_registry.json')
$assistantNames = @($registry.canonical_assistants | ForEach-Object { [string]$_.name })
$expectedAssistants = @('Júlia','Ayella','IZART')
if (($assistantNames -join '|') -ne ($expectedAssistants -join '|')) { throw 'assistant registry is not canonical: Julia, Ayella, IZART' }
Write-Ok 'assistant registry: Julia / Ayella / IZART'

$workerText = Get-Content -LiteralPath $workerPath -Raw -Encoding UTF8
if ($workerText -match '\?\.') { throw 'service worker contains optional chaining; remove for compatibility' }
if ($workerText -match 'type="popup"') { throw 'service worker contains invalid object assignment syntax' }
Write-Ok 'service worker static syntax guards'

$dist = Join-Path $OutputRoot 'IZGITH_v6.0.0.00058_Full_Build'
if (Test-Path -LiteralPath $dist) { Remove-Item -LiteralPath $dist -Recurse -Force }
New-Item -ItemType Directory -Path $dist -Force | Out-Null

$copyDirs = @('extension','host','integrations','scripts','tests','docs','build','archive')
foreach ($dirName in $copyDirs) {
  $src = Join-Path $SourceRoot $dirName
  if (Test-Path -LiteralPath $src -PathType Container) {
    Copy-Item -LiteralPath $src -Destination $dist -Recurse -Force
  }
}
foreach ($fileName in @('README.md','LICENSE','SECURITY.md','package.json')) {
  $src = Join-Path $SourceRoot $fileName
  if (Test-Path -LiteralPath $src -PathType Leaf) { Copy-Item -LiteralPath $src -Destination $dist -Force }
}

$zipPath = Join-Path $OutputRoot 'IZGITH_v6.0.0.00058_Full_Build.zip'
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
Compress-Archive -Path (Join-Path $dist '*') -DestinationPath $zipPath -CompressionLevel Optimal -Force
Require-File $zipPath 'final ZIP'

Write-Host ''
Write-Host 'BUILD PASS' -ForegroundColor Green
Write-Host ('Package: ' + $zipPath) -ForegroundColor Cyan
Write-Host 'The extension folder to load in Chrome is:' -ForegroundColor Cyan
Write-Host (Join-Path $dist 'extension') -ForegroundColor Cyan
Write-Host ''
Write-Host 'No native host is required for boot. If native messaging is absent, the UI must report OFF.'
Write-Host 'This build does not silently install a native host because Chrome blocks that behavior.'
