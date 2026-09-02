# IZGITH 00050 portable builder
# ASCII-only on purpose: safe to parse in Windows PowerShell 2-5 and newer.
[CmdletBinding()]
param([string]$Target = '')
$ErrorActionPreference = 'Stop'

$scriptFile = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptFile
$parent = Split-Path -Parent $scriptDir
if ([string]::IsNullOrEmpty($Target)) { $Target = Join-Path $parent 'IZGITH_v6.0.0.00050_Full_Build' }
$Target = [IO.Path]::GetFullPath($Target)
$repoZip = Join-Path $env:TEMP 'izgith-00050-source.zip'
$url = 'https://github.com/lowdrus/IZGITH/archive/refs/heads/main.zip'

function Get-FileSafe([string]$Url,[string]$Path) {
  try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
  try {
    $wc = New-Object Net.WebClient
    $wc.Headers['User-Agent'] = 'IZGITH-Builder/00050'
    $wc.DownloadFile($Url,$Path)
  } catch {
    if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue }
    throw
  }
}
function Expand-ZipCompat([string]$Zip,[string]$Dest) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
  if ([Type]::GetType('System.IO.Compression.ZipFile, System.IO.Compression.FileSystem')) {
    [IO.Compression.ZipFile]::ExtractToDirectory($Zip,$Dest)
    return
  }
  $shell = New-Object -ComObject Shell.Application
  $src = $shell.NameSpace($Zip)
  $dst = $shell.NameSpace($Dest)
  if ($null -eq $src -or $null -eq $dst) { throw 'ZIP extraction is unavailable on this Windows installation.' }
  $dst.CopyHere($src.Items(),20)
}

Write-Host 'IZGITH 00050 - FULL BUILD' -ForegroundColor Cyan
Write-Host ('Target: ' + $Target)
if (Test-Path -LiteralPath $Target) { Remove-Item -LiteralPath $Target -Recurse -Force }
New-Item -ItemType Directory -Path $Target -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $Target '_source') -Force | Out-Null

Write-Host '[1/5] Downloading repository source...' -ForegroundColor Yellow
Get-FileSafe $url $repoZip
Write-Host '[2/5] Extracting...' -ForegroundColor Yellow
Expand-ZipCompat $repoZip (Join-Path $Target '_source')
$top = Get-ChildItem -LiteralPath (Join-Path $Target '_source') -Directory | Select-Object -First 1
if ($null -eq $top) { throw 'Downloaded archive has no top-level directory.' }

Write-Host '[3/5] Installing clean package...' -ForegroundColor Yellow
$extensionSource = Join-Path $top.FullName 'extension'
if (-not (Test-Path -LiteralPath (Join-Path $extensionSource 'manifest.json') -PathType Leaf)) { throw 'manifest.json missing from downloaded package.' }
Copy-Item -LiteralPath $extensionSource -Destination (Join-Path $Target 'extension') -Recurse -Force
foreach ($d in @('host','scripts','tools','docs','integrations','build')) {
  $src = Join-Path $top.FullName $d
  if (Test-Path -LiteralPath $src -PathType Container) { Copy-Item -LiteralPath $src -Destination (Join-Path $Target $d) -Recurse -Force }
}

Write-Host '[4/5] Writing launchers and instructions...' -ForegroundColor Yellow
@('IZGITH 00050 FULL BUILD','', 'Load the extension from: extension', 'The extension works without Native Messaging.', 'Use the in-app host check only when the optional native host is installed.', 'UI order: Identidade & Host > Ferramentas > Configuracoes > Logs > Temas.', 'Default operation: Ultra + Controlado - Unificado.', 'See docs/GUIA_RAPIDO.md and docs/EULA.md.') | Set-Content -LiteralPath (Join-Path $Target 'README.txt') -Encoding UTF8
Copy-Item -LiteralPath $scriptFile -Destination (Join-Path $Target 'IZGITH_BUILD_00050.ps1') -Force
$bat = Join-Path $Target 'IZGITH_BUILD_00050.bat'
@('@echo off','setlocal','powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0IZGITH_BUILD_00050.ps1"','exit /b %ERRORLEVEL%') | Set-Content -LiteralPath $bat -Encoding ASCII

Write-Host '[5/5] Structural validation...' -ForegroundColor Yellow
$manifest = Join-Path $Target 'extension\manifest.json'
$sw = Join-Path $Target 'extension\sw.js'
foreach ($p in @($manifest,$sw,(Join-Path $Target 'extension\assets\icons\icon16.png'),(Join-Path $Target 'extension\assets\icons\icon32.png'),(Join-Path $Target 'extension\assets\icons\icon48.png'),(Join-Path $Target 'extension\assets\icons\icon128.png'))) { if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { throw ('Required file missing: ' + $p) } }
$manifestText = [IO.File]::ReadAllText($manifest)
if ($manifestText -notmatch '"manifest_version"\s*:\s*3') { throw 'Manifest is not MV3.' }
if ($manifestText -notmatch '"service_worker"\s*:\s*"sw\.js"') { throw 'Manifest service_worker is not sw.js.' }
$swText = [IO.File]::ReadAllText($sw)
if ($swText -match '\btype\s*=\s*"') { throw 'Found invalid JavaScript type= initializer.' }
if ($swText -match '\?\.') { throw 'Optional chaining found in service worker; remove for compatibility.' }
Write-Host '[OK] manifest.json + sw.js + icons + package structure' -ForegroundColor Green
Write-Host ('DONE: ' + $Target) -ForegroundColor Green
Remove-Item -LiteralPath $repoZip -Force -ErrorAction SilentlyContinue
exit 0
