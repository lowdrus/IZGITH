[CmdletBinding()]
param(
    [string]$ExtensionId,
    [string]$ConfigPath,
    [string]$InstallDirectory = (Join-Path $env:LOCALAPPDATA 'IZGITH\host'),
    [switch]$SkipDependencies,
    [switch]$SkipLogin,
    [switch]$NoRegister,
    [switch]$NoPrompt
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Confirm-Step([string]$Message) {
    if ($NoPrompt) { return }
    Add-Type -AssemblyName System.Windows.Forms
    $Answer = [System.Windows.Forms.MessageBox]::Show($Message, 'IZGITH', 'YesNo', 'Question')
    if ($Answer -ne 'Yes') { throw 'Operacao cancelada pelo usuario.' }
}

if (-not $ExtensionId) {
    if (-not $ConfigPath) {
        $Candidates = @((Join-Path $PSScriptRoot 'izgith-host-config.json'),
            (Join-Path $env:USERPROFILE 'Downloads\izgith-host-config.json'))
        $ConfigPath = $Candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    }
    if (-not $ConfigPath) {
        if ($NoPrompt) { throw 'Informe ExtensionId ou ConfigPath.' }
        Add-Type -AssemblyName System.Windows.Forms
        $Dialog = New-Object System.Windows.Forms.OpenFileDialog
        $Dialog.Title = 'Selecione izgith-host-config.json baixado no painel IZGITH'
        $Dialog.Filter = 'Configuracao IZGITH (*.json)|*.json'
        try {
            if ($Dialog.ShowDialog() -ne 'OK') { throw 'Selecao cancelada.' }
            $ConfigPath = $Dialog.FileName
        } finally { $Dialog.Dispose() }
    }
    $Config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($Config.schema -ne 'izgith.host.setup.v1') { throw 'Configuracao invalida.' }
    $ExtensionId = [string]$Config.extension_id
}
if ($ExtensionId -cnotmatch '^[a-p]{32}$') { throw 'ID invalido: esperado ID Chrome de 32 letras a-p.' }

$Candidates = @((Join-Path $PSScriptRoot 'izgith_host.exe'),
    (Join-Path $PSScriptRoot '..\izgith_host.exe'),
    (Join-Path $PSScriptRoot '..\dist\izgith_host.exe'))
$SourceExe = $Candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $SourceExe) { throw 'Baixe o artefato IZGITH-Windows-Host no CI: izgith_host.exe nao encontrado.' }
Confirm-Step "Registrar o host IZGITH para a extensao $ExtensionId em ${InstallDirectory}? Arquivos anteriores do host nesse destino serao atualizados."

if (-not $SkipDependencies) {
    $Packages = @(@{Command='git'; Id='Git.Git'}, @{Command='gh'; Id='GitHub.cli'})
    foreach ($Package in $Packages) {
        if (-not (Get-Command $Package.Command -ErrorAction SilentlyContinue)) {
            Confirm-Step "Instalar $($Package.Id) pelo Windows Package Manager? O Windows pode solicitar autorizacao."
            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'winget nao encontrado. Instale Git for Windows e GitHub CLI pelos sites oficiais.' }
            & winget install --id $Package.Id --exact --source winget
            if ($LASTEXITCODE -ne 0) { throw "Falha ao instalar $($Package.Id). Nenhuma restricao foi contornada." }
            $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
        }
    }
    & git --version
    if ($LASTEXITCODE -ne 0) { throw 'Git nao esta disponivel.' }
    & git lfs version
    if ($LASTEXITCODE -ne 0) { throw 'Instale Git LFS antes de continuar.' }
}

if (-not $SkipLogin) {
    Confirm-Step 'Conectar sua conta ao GitHub CLI e configura-lo como autenticador Git para github.com? O login ocorre no fluxo oficial do GitHub. Nenhum token sera solicitado pelo IZGITH.'
    & gh auth login --hostname github.com --git-protocol https --web
    if ($LASTEXITCODE -ne 0) { throw 'Login nao concluido. O host nao foi registrado.' }
    & gh auth setup-git --hostname github.com
    if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel configurar a autenticacao Git.' }
}

[void](New-Item -ItemType Directory -Path $InstallDirectory -Force)
$TargetExe = Join-Path $InstallDirectory 'izgith_host.exe'
if ([IO.Path]::GetFullPath($SourceExe) -ne [IO.Path]::GetFullPath($TargetExe)) {
    Copy-Item -LiteralPath $SourceExe -Destination $TargetExe -Force
}
$ManifestPath = Join-Path $InstallDirectory 'com.izgith.host.json'
$Manifest = @{name='com.izgith.host'; description='Host local IZGITH'; path=[IO.Path]::GetFullPath($TargetExe); type='stdio'; allowed_origins=@("chrome-extension://$ExtensionId/")}
$Json = $Manifest | ConvertTo-Json -Depth 4
[IO.File]::WriteAllText($ManifestPath, $Json, (New-Object System.Text.UTF8Encoding($false)))
if (-not $NoRegister) {
    $RegistryPath = 'HKCU:\Software\Google\Chrome\NativeMessagingHosts\com.izgith.host'
    [void](New-Item -Path $RegistryPath -Force)
    Set-Item -Path $RegistryPath -Value $ManifestPath
}
Write-Host 'Host preparado. Reinicie o Chrome e clique em Verificar host/Git no IZGITH.' -ForegroundColor Green
Write-Host "Manifesto: $ManifestPath"
