# IZGITH 6.0.0.00044 - Windows Native Messaging setup
# Compatible with Windows PowerShell 5.1 and PowerShell 7+
[CmdletBinding()]
param(
  [string]$ExtensionId = '',
  [ValidateSet('chrome','edge')][string]$Browser = 'chrome'
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$HostDir = Join-Path $Root 'host'
$HostName = 'com.izgith.host'

function Fail([string]$Message) { Write-Host ('[ERRO] ' + $Message) -ForegroundColor Red; exit 1 }

if ([string]::IsNullOrWhiteSpace($ExtensionId)) { $ExtensionId = Read-Host 'Cole o ID da extensao IZGITH' }
$ExtensionId = $ExtensionId.Trim().ToLowerInvariant()
if ($ExtensionId -notmatch '^[a-p]{32}$') { Fail 'ID invalido. O ID do Chrome deve ter 32 caracteres de a-p.' }

$Python = Get-Command python.exe -ErrorAction SilentlyContinue
if ($null -eq $Python) { Fail 'Python nao encontrado. Instale Python 3.11+ e execute este arquivo novamente.' }

$Exe = Join-Path $HostDir 'dist\izgith_host.exe'
if (-not (Test-Path -LiteralPath $Exe)) {
  $PyInstaller = Get-Command pyinstaller.exe -ErrorAction SilentlyContinue
  if ($null -eq $PyInstaller) {
    & $Python.Source -m pip install --user pyinstaller
    if ($LASTEXITCODE -ne 0) { Fail 'Nao foi possivel instalar PyInstaller.' }
    $PyInstaller = Get-Command pyinstaller.exe -ErrorAction SilentlyContinue
  }
  if ($null -eq $PyInstaller) { Fail 'PyInstaller nao encontrado apos a instalacao.' }
  Push-Location $HostDir
  try {
    & $PyInstaller.Source --noconfirm --clean --onefile --name izgith_host host.py
    if ($LASTEXITCODE -ne 0) { Fail 'Falha ao compilar o host.' }
  } finally { Pop-Location }
}
if (-not (Test-Path -LiteralPath $Exe)) { Fail 'izgith_host.exe nao foi criado.' }

$Local = $env:LOCALAPPDATA
if ([string]::IsNullOrWhiteSpace($Local)) { $Local = Join-Path $env:USERPROFILE 'AppData\Local' }
$ManifestDir = Join-Path $Local 'IZGITH'
New-Item -ItemType Directory -Path $ManifestDir -Force | Out-Null
$ManifestPath = Join-Path $ManifestDir ($HostName + '.json')
$Origin = 'chrome-extension://' + $ExtensionId + '/'
$Manifest = [ordered]@{
  name = $HostName
  description = 'IZGITH local native messaging host'
  path = (Resolve-Path -LiteralPath $Exe).Path
  type = 'stdio'
  allowed_origins = @($Origin)
}
$Json = $Manifest | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($ManifestPath, $Json, (New-Object System.Text.UTF8Encoding($false)))

if ($Browser -eq 'chrome') { $RegBase = 'HKCU:\Software\Google\Chrome\NativeMessagingHosts' }
else { $RegBase = 'HKCU:\Software\Microsoft\Edge\NativeMessagingHosts' }
$RegKey = Join-Path $RegBase $HostName
if (-not (Test-Path -LiteralPath $RegBase)) { New-Item -Path $RegBase -Force | Out-Null }
New-Item -Path $RegKey -Force | Out-Null
Set-ItemProperty -LiteralPath $RegKey -Name '(default)' -Value $ManifestPath

Write-Host ''
Write-Host '[OK] Host compilado:  ' $Exe -ForegroundColor Green
Write-Host '[OK] Manifesto:        ' $ManifestPath -ForegroundColor Green
Write-Host '[OK] Registro:         ' $RegKey -ForegroundColor Green
Write-Host '[OK] Origem permitida: ' $Origin -ForegroundColor Green
Write-Host ''
Write-Host 'Recarregue a extensao em chrome://extensions antes de testar.' -ForegroundColor Yellow
