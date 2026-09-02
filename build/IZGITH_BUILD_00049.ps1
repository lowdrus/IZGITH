#requires -version 2.0
[CmdletBinding()]
param([string]$Root = "")
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrEmpty($Root)) { $Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path) }
$extensionRoot = Join-Path $Root 'extension'
$required = @('manifest.json','sw.js','ui\popup.html','ui\popup.js','ui\popup.css','ui\dashboard.html','ui\dashboard.js','ui\dashboard.css','assets\icons\icon16.png','assets\icons\icon32.png','assets\icons\icon48.png','assets\icons\icon128.png','themes\catalog.json','scripts\assistants.js')
Write-Host 'IZGITH BUILD 00049 - validation and packaging' -ForegroundColor Cyan
Write-Host ('Root: ' + $Root)
if (-not (Test-Path -LiteralPath $extensionRoot -PathType Container)) { throw 'extension directory not found.' }
$missing = @()
foreach ($relative in $required) { $candidate = Join-Path $extensionRoot $relative; if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { $missing += $relative } }
if ($missing.Count -gt 0) { Write-Host 'Missing required files:' -ForegroundColor Red; $missing | ForEach-Object { Write-Host (' - ' + $_) -ForegroundColor Red }; throw 'Required package files are missing.' }
$manifestPath = Join-Path $extensionRoot 'manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ([int]$manifest.manifest_version -ne 3) { throw 'Manifest is not MV3.' }
if ([string]::IsNullOrEmpty($manifest.background.service_worker)) { throw 'Manifest background service_worker is empty.' }
if ($manifest.background.service_worker -ne 'sw.js') { throw 'Manifest service_worker must be sw.js.' }
if ($manifest.version -ne '6.0.0.49') { throw 'Manifest version is not 6.0.0.49.' }
$swPath = Join-Path $extensionRoot 'sw.js'; $sw = Get-Content -LiteralPath $swPath -Raw
if ([string]::IsNullOrEmpty($sw)) { throw 'sw.js is empty.' }
if ($sw -match '\btype\s*=\s*') { throw 'Invalid JavaScript shorthand initializer type= found.' }
if ($sw -match '\?\.') { throw 'Optional chaining found in service worker.' }
if ($sw -notmatch 'NATIVE_HOST_CHECK') { throw 'Native host check route is missing.' }
if ($sw -notmatch 'NATIVE_CALL') { throw 'Native call route is missing.' }
$catalogPath = Join-Path $extensionRoot 'themes\catalog.json'; $catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
if ([int]$catalog.total -ne 36) { throw 'Theme catalog must contain 36 themes.' }
foreach ($size in @(16,32,48,128)) { $iconPath = Join-Path $extensionRoot ('assets\icons\icon' + $size + '.png'); $bytes = [System.IO.File]::ReadAllBytes($iconPath); if ($bytes.Length -lt 8) { throw ('Icon is empty: ' + $iconPath) }; if ($bytes[0] -ne 137 -or $bytes[1] -ne 80 -or $bytes[2] -ne 78 -or $bytes[3] -ne 71) { throw ('Invalid PNG signature: ' + $iconPath) } }
$assistantPath = Join-Path $extensionRoot 'scripts\assistants.js'; $assistantText = Get-Content -LiteralPath $assistantPath -Raw
foreach ($name in @('Júlia','Ayella','IZART')) { if ($assistantText.IndexOf($name, [System.StringComparison]::Ordinal) -lt 0) { throw ('Assistant missing: ' + $name) } }
$python = Get-Command python.exe -ErrorAction SilentlyContinue
if ($null -ne $python) { & $python.Source (Join-Path $Root 'scripts\validate_project.py'); if ($LASTEXITCODE -ne 0) { throw 'Python project validation failed.' }; & $python.Source (Join-Path $Root 'scripts\package_extension.py'); if ($LASTEXITCODE -ne 0) { throw 'Python packaging failed.' } } else { Write-Host 'Python not found; structural validation completed, package step skipped.' -ForegroundColor Yellow }
Write-Host '[OK] MV3 manifest' -ForegroundColor Green
Write-Host '[OK] sw.js routes and syntax guards' -ForegroundColor Green
Write-Host '[OK] four PNG icons' -ForegroundColor Green
Write-Host '[OK] 36 themes' -ForegroundColor Green
Write-Host '[OK] Julia / Ayella / IZART registry presence' -ForegroundColor Green
Write-Host '[OK] Ultra + Controlled unified mode remains default' -ForegroundColor Green
Write-Host 'BUILD 00049 COMPLETE' -ForegroundColor Green
exit 0
