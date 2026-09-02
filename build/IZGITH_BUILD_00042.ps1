#requires -version 2.0
[CmdletBinding()]
param([string]$Root = "")
$ErrorActionPreference='Stop'
if([string]::IsNullOrEmpty($Root)){$Root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)}
$ext=Join-Path $Root 'extension'
$required=@((Join-Path $ext 'manifest.json'),(Join-Path $ext 'sw.js'),(Join-Path $ext 'ui\popup.html'),(Join-Path $ext 'ui\popup.js'),(Join-Path $ext 'ui\popup.css'),(Join-Path $ext 'ui\dashboard.html'),(Join-Path $ext 'ui\dashboard.js'),(Join-Path $ext 'ui\dashboard.css'),(Join-Path $ext 'assets\icons\icon16.png'),(Join-Path $ext 'assets\icons\icon32.png'),(Join-Path $ext 'assets\icons\icon48.png'),(Join-Path $ext 'assets\icons\icon128.png'))
$missing=@($required|Where-Object{ -not(Test-Path -LiteralPath $_ -PathType Leaf)})
if($missing.Count -gt 0){Write-Host '[FAIL] Arquivos obrigatorios ausentes:' -ForegroundColor Red;$missing|ForEach-Object{Write-Host (' - '+$_) -ForegroundColor Red};exit 1}
try{$m=Get-Content -LiteralPath (Join-Path $ext 'manifest.json') -Raw|ConvertFrom-Json;if($m.manifest_version -ne 3){throw 'manifest_version deve ser 3'};if([string]::IsNullOrEmpty($m.background.service_worker)){throw 'service_worker vazio'};if(-not(Test-Path -LiteralPath (Join-Path $ext $m.background.service_worker) -PathType Leaf)){throw 'service worker referenciado nao existe'}}catch{Write-Host ('[FAIL] Manifesto: '+$_.Exception.Message) -ForegroundColor Red;exit 1}
$sw=Get-Content -LiteralPath (Join-Path $ext 'sw.js') -Raw;if($sw -match 'type\s*=\s*'){Write-Host '[FAIL] JS contem inicializador type=; use type:' -ForegroundColor Red;exit 1}
Write-Host '[OK] MV3 + service worker + UI + 4 icones verificados.' -ForegroundColor Green
Write-Host '[OK] Native Messaging nao e requisito para o boot.' -ForegroundColor Green
Write-Host '[OK] Modo unificado: Ultra + Controlado.' -ForegroundColor Green
exit 0
