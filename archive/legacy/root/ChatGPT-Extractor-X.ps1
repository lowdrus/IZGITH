
<#  ChatGPT-Extractor-X.ps1  (v2.2)
    by Aelly

    Objetivo:
      Extrair histórico do ChatGPT para formatos MD/HTML/JSON em múltiplos modos:
        - web, ios, winapp, linux, store (Microsoft Store)
      Integrado ao SUPER_PROJETO_FULLONE e CONVERSATIONGPT.

    Uso rápido:
      .\ChatGPT-Extractor-X.ps1 -Mode store -Format md -Auto

    Notas:
      * Modo 'store' usa fluxo prático via link compartilhado (Share):
        1) No app ChatGPT (Microsoft Store), clique em "Share"/"Compartilhar"
        2) Copie o link público (https://chat.openai.com/share/XXXXXXXX)
        3) Este script detecta o link na área de transferência e baixa a conversa
      * Alternativa: cole o link via -ShareUrl 'https://...'

#>

param(
  [ValidateSet('web','ios','winapp','linux','store')]
  [string]$Mode = 'web',
  [ValidateSet('md','html','json')]
  [string]$Format = 'md',
  [switch]$Auto,
  [string]$ShareUrl,
  [string]$OutDir = 'D:\PROJETOS\CONVERSACHAT\EXTRAÇÃO\PARA CONVERSATIONS.JSON'
)

function Write-Info($msg){ Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Ok($msg){ Write-Host "[OK]  $msg" -ForegroundColor Green }
function Write-Warn($msg){ Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg){ Write-Host "[ERR] $msg" -ForegroundColor Red }

function Ensure-OutDir {
  param([string]$Path)
  if(-not (Test-Path -LiteralPath $Path)){
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Get-ClipboardText {
  try {
    Add-Type -AssemblyName PresentationCore
    return [Windows.Clipboard]::GetText()
  } catch {
    try {
      return Get-Clipboard
    } catch {
      return ""
    }
  }
}

function Wait-ForShareUrl {
  Write-Info "Aguardando link 'share' do ChatGPT na área de transferência..."
  $rx = '^https?://chat\.openai\.com/share/[A-Za-z0-9\-_]+'
  for($i=0;$i -lt 60;$i++){
    $clip = Get-ClipboardText
    if($clip -match $rx){ return $clip }
    Start-Sleep -Seconds 2
  }
  return $null
}

function Fetch-Page {
  param([string]$Url)
  Write-Info "Baixando página: $Url"
  try {
    $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 60
    return $r.Content
  } catch {
    Write-Err "Falha ao baixar a página: $($_.Exception.Message)"
    return $null
  }
}

function Extract-MessagesFromSharedHtml {
  param([string]$html)
  if([string]::IsNullOrWhiteSpace($html)){ return @() }
  $lines = $html -split "`n"
  $msgs = @()
  $buf = [System.Collections.Generic.List[string]]::new()
  $inBlock = $false
  foreach($ln in $lines){
    if($ln -match '<article' -or $ln -match 'data-message-author-role'){
      if($buf.Count -gt 0){
        $msgs += ,(@{ role='unknown'; text=($buf -join "`n") })
        $buf.Clear()
      }
      $inBlock = $true
      continue
    }
    if($inBlock -and $ln -match '</article>'){
      $inBlock = $false
      $msgs += ,(@{ role='unknown'; text=($buf -join "`n") })
      $buf.Clear()
      continue
    }
    if($inBlock){ $buf.Add($ln) }
  }
  $clean = @()
  foreach($m in $msgs){
    $t = [System.Web.HttpUtility]::HtmlDecode(($m.text -replace '<[^>]+>',' ')) -replace '\s+',' '
    if($t.Trim().Length -gt 3){
      $role = if($t -match '✅iarate|user|Você'){'user'} elseif($t -match '✅Aelly|assistant'){'assistant'} else {'unknown'}
      $clean += ,(@{ role=$role; text=$t.Trim() })
    }
  }
  return $clean
}

function Render-MD {
  param($messages)
  $out = @("# Conversa exportada (modo share)","","---")
  $i=0
  foreach($m in $messages){
    $i++
    $label = if($m.role -eq 'user'){'✅iarate'} elseif($m.role -eq 'assistant'){'✅Aelly'} else {'unknown'}
    $out += "**$i. $label**"
    $out += $m.text
    $out += ""
  }
  return ($out -join "`r`n")
}

function Save-Output {
  param([string]$baseName, [string]$format, $messages, [string]$outDir)
  Ensure-OutDir -Path $outDir
  $ts = (Get-Date).ToString('yyyyMMdd_HHmmss')
  switch($format){
    'md'   { $content = Render-MD -messages $messages ; $ext='md' }
    'json' { $content = ($messages | ConvertTo-Json -Depth 5) ; $ext='json' }
    'html' { $md = Render-MD -messages $messages ; $content = "<pre>"+[System.Web.HttpUtility]::HtmlEncode($md)+"</pre>"; $ext='html' }
  }
  $path = Join-Path $outDir "$($baseName)_$ts.$ext"
  Set-Content -LiteralPath $path -Value $content -Encoding UTF8
  Write-Ok "Salvo: $path"
  return $path
}

Ensure-OutDir -Path $OutDir

if($Mode -eq 'store'){
  if(-not $ShareUrl){
    if($Auto){
      $ShareUrl = Wait-ForShareUrl
      if(-not $ShareUrl){
        Write-Err "Não encontrei o link compartilhado na área de transferência."
        exit 1
      }
    } else {
      Write-Info "Cole aqui o link do botão 'Share' copiado do app (ex: https://chat.openai.com/share/xxxx):"
      $ShareUrl = Read-Host "URL"
    }
  }
  Write-Info "Usando URL: $ShareUrl"
  $html = Fetch-Page -Url $ShareUrl
  if(-not $html){ exit 1 }
  $messages = Extract-MessagesFromSharedHtml -html $html
  if($messages.Count -lt 2){
    Write-Warn "Poucas mensagens detectadas. O HTML público pode ter alterado o layout. Continuando mesmo assim..."
  }
  $saved = Save-Output -baseName "chat_store" -format $Format -messages $messages -outDir $OutDir
  Write-Ok "Concluído em modo 'store'."
  exit 0
}

Write-Info "Modo $Mode ainda usa os fluxos A/B/C via extensão e export local."
Write-Ok "Considere usar a extensão CONVERSATIONGPT (botão OneClickHistoryDownload)."
