# Static verification for IZGITH 00044. PowerShell 5.1+.
[CmdletBinding()]
param([string]$ExtensionRoot = '')
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ExtensionRoot)) { $ExtensionRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'extension' }
$ManifestPath = Join-Path $ExtensionRoot 'manifest.json'
$SwPath = Join-Path $ExtensionRoot 'sw.js'
$Required = @('manifest.json','sw.js','ui\popup.html','ui\popup.js','ui\popup.css','assets\icons\icon16.png','assets\icons\icon32.png','assets\icons\icon48.png','assets\icons\icon128.png')
$failed = @()
foreach ($item in $Required) { if (-not (Test-Path -LiteralPath (Join-Path $ExtensionRoot $item))) { $failed += $item } }
if ($failed.Count) { Write-Host '[ERRO] Arquivos ausentes:' -ForegroundColor Red; $failed | ForEach-Object { Write-Host (' - ' + $_) }; exit 1 }
try { $manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json } catch { Write-Host '[ERRO] manifest.json invalido.' -ForegroundColor Red; exit 1 }
if ($manifest.manifest_version -ne 3) { Write-Host '[ERRO] manifest_version diferente de 3.' -ForegroundColor Red; exit 1 }
if ([string]::IsNullOrWhiteSpace([string]$manifest.background.service_worker)) { Write-Host '[ERRO] service_worker ausente.' -ForegroundColor Red; exit 1 }
if ($manifest.background.service_worker -ne 'sw.js') { Write-Host '[ERRO] service_worker nao aponta para sw.js.' -ForegroundColor Red; exit 1 }
if (-not (Test-Path -LiteralPath $SwPath)) { Write-Host '[ERRO] sw.js ausente.' -ForegroundColor Red; exit 1 }
$sw = Get-Content -LiteralPath $SwPath -Raw
if ($sw -match '\btype\s*=\s*["'']popup') { Write-Host '[ERRO] sintaxe suspeita no objeto windows.create.' -ForegroundColor Red; exit 1 }
Write-Host '[OK] Estrutura basica, manifest e service worker conferidos.' -ForegroundColor Green
Write-Host ('[OK] Versao: ' + $manifest.version)
Write-Host ('[OK] Extensao: ' + $ExtensionRoot)
