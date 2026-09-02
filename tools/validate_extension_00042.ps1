[CmdletBinding()]
param([string]$ExtensionRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'extension'))

$ErrorActionPreference = 'Stop'

function Assert-File([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing file: $Path" }
  Write-Host "OK  $Path" -ForegroundColor Green
}

if (-not (Test-Path -LiteralPath $ExtensionRoot -PathType Container)) {
  throw "Extension root not found: $ExtensionRoot"
}

$manifestPath = Join-Path $ExtensionRoot 'manifest.json'
Assert-File $manifestPath
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

if ([int]$manifest.manifest_version -ne 3) { throw 'Manifest is not MV3.' }
if ([string]::IsNullOrWhiteSpace([string]$manifest.background.service_worker)) { throw 'background.service_worker is empty.' }

$worker = Join-Path $ExtensionRoot ([string]$manifest.background.service_worker)
Assert-File $worker
Assert-File (Join-Path $ExtensionRoot 'ui\popup.html')
Assert-File (Join-Path $ExtensionRoot 'ui\popup.js')
Assert-File (Join-Path $ExtensionRoot 'ui\dashboard.html')
Assert-File (Join-Path $ExtensionRoot 'ui\dashboard.js')

foreach ($size in 16,32,48,128) {
  Assert-File (Join-Path $ExtensionRoot ("assets\icons\icon{0}.png" -f $size))
}

$node = Get-Command node.exe -ErrorAction SilentlyContinue
if ($null -ne $node) {
  & $node.Source --check $worker
  if ($LASTEXITCODE -ne 0) { throw 'Node syntax check failed for sw.js.' }
  Write-Host 'OK  node --check sw.js' -ForegroundColor Green
} else {
  Write-Host 'INFO Node.js not installed; JavaScript syntax check skipped.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'IZGITH 00042 validation completed.' -ForegroundColor Cyan
Write-Host 'Native Messaging is diagnostic-only at extension boot; a missing host must not prevent loading.' -ForegroundColor Cyan
