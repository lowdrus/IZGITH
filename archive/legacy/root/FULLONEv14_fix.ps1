<#
FULLONEv14 - Pack de Automação Unificado (CORREÇÃO)
Correções aplicadas (linha a linha):
- Safe-JoinPath: parâmetros renomeados para -Path e -Child (compatível com chamadas).
- Safe-JoinPath valida entradas e aplica fallback quando Path vazio.
- Garantia explícita de criação de diretórios antes de usar Join-Path.
- Proteções antes de gravar arquivos (reportTxt, compiledFile, zipOut): validação e logs claros.
- Geração Python: uso de textbbox/font.getsize compatível com Pillow; checagens para evitar chamar python com paths vazios.
- Todas as operações críticas usam try/catch e fazem Write-Log com paths reais.
- Removida abertura automática do Tutorial.pdf.
- BuildExe tenta usar Invoke-PS2EXE ou ps2exe e reporta erros claramente.
#>

param(
    [switch]$DryRun = $true,
    [switch]$AutoFix = $false,
    [switch]$Backup = $true,
    [switch]$Exec = $false,
    [switch]$Deploy = $true,
    [switch]$BuildExe = $false
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$Version = 'FULLONEv14-FIX1'

# --- helper: Safe-JoinPath (robusta)
function Safe-JoinPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Child
    )
    if ([string]::IsNullOrWhiteSpace($Path)) {
        # fallback to C:\SCRIPTS\FULL ONE if possible, else current script folder
        $fallback = 'C:\SCRIPTS\FULL ONE'
        if (Test-Path -LiteralPath $fallback) { $Path = $fallback }
        elseif ($PSScriptRoot) { $Path = $PSScriptRoot }
        else { $Path = (Get-Location).ProviderPath }
    }
    if ([string]::IsNullOrWhiteSpace($Child)) { return $Path }
    return Join-Path -Path $Path -ChildPath $Child
}

# --- determine script folder (fallback)
if ($PSScriptRoot) { $ScriptDir = $PSScriptRoot } else { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }

# --- Output root (enterprise locations) - guaranteed
$RootOut = 'C:\SCRIPTS\FULL ONE'
# ensure RootOut exists, if not try to create; if creation fails, fallback to script dir
try {
    if (-not (Test-Path -LiteralPath $RootOut)) {
        New-Item -ItemType Directory -Path $RootOut -Force | Out-Null
    }
} catch {
    Write-Host "Aviso: não foi possível criar $RootOut. Fallback para pasta do script: $ScriptDir" -ForegroundColor Yellow
    $RootOut = $ScriptDir
}

$CompileRoot = Safe-JoinPath -Path $RootOut -Child 'COMPILADO'
$BackupRoot  = Safe-JoinPath -Path $RootOut -Child 'BACKUP'
$LogsRoot    = Safe-JoinPath -Path $RootOut -Child 'LOGS'
$DeployRoot  = Safe-JoinPath -Path $RootOut -Child 'DEPLOY'
$DiagramRoot = Safe-JoinPath -Path $RootOut -Child 'DIAGRAMA VISUAL'

# Ensure directories exist (create if necessary)
foreach ($d in @($RootOut,$CompileRoot,$BackupRoot,$LogsRoot,$DeployRoot,$DiagramRoot)) {
    try {
        if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    } catch {
        Write-Host "Falha criando pasta: $d - $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Global log file path (always a file)
$Global:FULL_LOG_FILE = Safe-JoinPath -Path $LogsRoot -Child ("fullone_log_{0}.txt" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
try {
    if (-not (Test-Path -LiteralPath $Global:FULL_LOG_FILE -PathType Leaf)) { New-Item -ItemType File -Path $Global:FULL_LOG_FILE -Force | Out-Null }
} catch {
    Write-Host "Falha criando arquivo de log: $Global:FULL_LOG_FILE - $($_.Exception.Message)" -ForegroundColor Yellow
    # fallback to a temp file
    $Global:FULL_LOG_FILE = Safe-JoinPath -Path ([System.IO.Path]::GetTempPath()) -Child ("fullone_log_{0}.txt" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    New-Item -ItemType File -Path $Global:FULL_LOG_FILE -Force | Out-Null
}

# Robust Write-Log (safe around missing file)
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','OK','WARN','ERROR')][string]$Level = 'INFO'
    )
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$ts][$Level] $Message"
    try {
        if ($Global:FULL_LOG_FILE) { Add-Content -Path $Global:FULL_LOG_FILE -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue }
    } catch {}
    switch ($Level) {
        'INFO' { Write-Host $line -ForegroundColor White }
        'OK'   { Write-Host $line -ForegroundColor Green }
        'WARN' { Write-Host $line -ForegroundColor Yellow }
        'ERROR'{ Write-Host $line -ForegroundColor Red }
    }
}

Write-Log ("{0} iniciado. DryRun={1}, AutoFix={2}, Backup={3}, Exec={4}, Deploy={5}" -f $Version, $DryRun, $AutoFix, $Backup, $Exec, $Deploy) 'INFO'

# --- Explicit search paths (user-provided list)
$SearchPaths = @(
    'C:\CONAV TRADER',
    'C:\CONAV TRADER\CONAV_TRADER\automation',
    'C:\CONAV TRADER\CONAV_TRADER\build',
    'C:\CONAV TRADER\CONAV_TRADER\dashboard',
    'C:\CONAV TRADER\CONAV_TRADER\data',
    'C:\CONAV TRADER\CONAV_TRADER\database',
    'C:\CONAV TRADER\CONAV_TRADER\Desinstalar',
    'C:\CONAV TRADER\CONAV_TRADER\dist',
    'C:\CONAV TRADER\CONAV_TRADER\docs',
    'C:\CONAV TRADER\CONAV_TRADER\emails',
    'C:\CONAV TRADER\CONAV_TRADER\icons',
    'C:\CONAV TRADER\CONAV_TRADER\logs',
    'C:\CONAV TRADER\CONAV_TRADER\relatórios',
    'C:\CONAV TRADER\CONAV_TRADER\resources',
    'C:\CONAV TRADER\CONAV_TRADER\scripts',
    'C:\CONAV TRADER\CONAV_TRADER\tools',
    'C:\CONAV TRADER\CONAV_TRADER\automation\autocorrector',
    'C:\CONAV TRADER\CONAV_TRADER\build\Desinstalar',
    'C:\CONAV TRADER\CONAV_TRADER\build\Desinstalar\localpycs',
    'C:\CONAV TRADER\CONAV_TRADER\build\Desinstalar\base_library.zip',
    'C:\CONAV TRADER\CONAV_TRADER\build\Desinstalar\base_library.zip\collections',
    'C:\CONAV TRADER\CONAV_TRADER\build\Desinstalar\base_library.zip\encodings',
    'C:\CONAV TRADER\CONAV_TRADER\build\Desinstalar\base_library.zip\re',
    'C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard',
    'C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\localpycs',
    'C:\CONAV TRADER\CONAV_TRADER\build\main_dashboard\base_library.zip',
    'C:\CONAV TRADER\CONAV_TRADER\build\uninstall_wrapper',
    'C:\CONAV TRADER\CONAV_TRADER\build\uninstall_wrapper\localpycs',
    'C:\CONAV TRADER\CONAV_TRADER\build\uninstall_wrapper\base_library.zip',
    'C:\CONAV TRADER\CONAV_TRADER\build\uninstall_wrapper\base_library.zip\collections',
    'C:\CONAV TRADER\CONAV_TRADER\build\uninstall_wrapper\base_library.zip\re',
    'C:\CONAV TRADER\CONAV_TRADER\build\uninstall_wrapper\base_library.zip\encodings',
    'C:\CONAV TRADER\CONAV_TRADER\Desinstalar\build',
    'C:\CONAV TRADER\CONAV_TRADER\mapas de fluxograma',
    'C:\CONAV TRADER\CONAV_TRADER\PACKAGES OFICIAIS',
    'C:\CONAV TRADER\CONAV_TRADER\SCRIPT MESTRE',
    'C:\CONAV TRADER\CONAV_TRADER\scripts\0001',
    'C:\CONAV TRADER\CONAV_TRADER\scripts\0002',
    'C:\CONAV TRADER\CONAV_TRADER\scripts\0003',
    'C:\CONAV TRADER\CONAV_TRADER\scripts\004',
    'C:\CONAV TRADER\CONAV_TRADER\scripts\aleatorios versoes 1.30+',
    'C:\CONAV TRADER\CONAV_TRADER\scripts\PACKAGES OFICIAIS',
    'C:\CONAV TRADER\CONAV_TRADER\scripts\SCRIPTS BASE OFICIAIS',
    'C:\CONAV TRADER\CONAV_TRADER\scripts\SCRIPTS DE LISTAGEM',
    'C:\CONAV TRADER\CONAV_TRADER\scripts\uninstall versoes 1.30+',
    'C:\CONAV TRADER\CONAV_TRADER\SCRIPTS DE LISTAGEM',
    'C:\CONAV TRADER\CONAV_TRADER\SCRIPTS BASE OFICIAIS',
    'C:\CONAV TRADER\CONAV_TRADER\tools',
    'C:\CONAV TRADER\CONAV_TRADER\TUTORIAL GERAL',
    'C:\CONAV TRADER\CONAV_TRADER\CONAV MASTER FULL',
    'C:\CONAV TRADER\dist',
    'C:\CONAV TRADER\logs',
    'C:\CONAV TRADER\PASTA DO BACKUP\CONAV TRADES ZIPS ATUALIZADOS\CONAV-ZIPS\CONAV-ZIP_20250911_160904',
    'C:\CONAV TRADER\PASTA DO BACKUP\CONAV TRADES ZIPS ATUALIZADOS\CONAV-ZIPS\CONAV-ZIP_20250911_161555',
    'C:\CONAV TRADER\PASTAS DO  BACKUP',
    'C:\CONAV TRADER\PASTAS DO  BACKUP\CONAV TRADER TESTER ONE CLICK',
    'C:\CONAV TRADER\PASTAS DO  BACKUP\CONAV TRADERS ZIPS ATUALIZADOS',
    'C:\CONAV TRADER\PASTAS DO  BACKUP\CONAV TRADERS ZIPS ATUALIZADOS\CONAV_TRADER_FULL2',
    'C:\CONAV TRADER\PASTAS DO  BACKUP\CONAV TRADERS ZIPS ATUALIZADOS\INSTALL CONAV  TRADERFULL',
    'C:\CONAV TRADER\PASTAS DO  BACKUP\CONAV TRADERS ZIPS ATUALIZADOS\INSTALL SETUP CONAV ICONS',
    'C:\CONAV TRADER\PASTAS DO  BACKUP\CONAV TRADERS ZIPS ATUALIZADOS\UNINSTALL CONAV TRADER',
    'C:\CONAV TRADER\PASTAS DO  BACKUP\CONAV TRADERS ZIPS ATUALIZADOS\CONAV_TRADER_FULL1',
    'C:\CONAV TRADER\PASTAS DO  BACKUP\CONAV TRADERS ZIPS ATUALIZADOS\CONAV_TRADER_FULL2',
    'C:\CONAV TRADER\PASTAS DO  BACKUP\CONAV TRADERS ZIPS ATUALIZADOS\CONAV_TRADER_OneClick-CONTEM ERROS',
    'C:\CONAV TRADER\PASTAS DO  BACKUP\CONAV TRADERS ZIPS ATUALIZADOS\CONAV-ZIPS\CONAV TRADER FULL 1.44',
    'C:\CONAV TRADER\CONAV_TRADER\CONAV MASTER FULL\FULLONEMASTER-INSTALL',
    'C:\CONAV TRADER\CONAV_TRADER\CONAV MASTER FULL\FULLONEMASTER\FULLONE-MESTER',
    'C:\CONAV TRADER\CONAV_TRADER\scripts\CONAV MASTER FULL FIX4\CONAVMASTER FIX4',
    'C:\CONAV TRADER\CONAV_TRADER\PACKAGES OFICIAIS\CONAV_FULL_PROFESSIONAL_v1.45_fix3_pkg',
    'C:\CONAV TRADER\CONAV_TRADER\PACKAGES OFICIAIS\CONAV_FULL_PROFESSIONAL_v1.45_fix3_pkg_1',
    'C:\CONAV TRADER\PASTAS DO  BACKUP\CONAV TRADERS ZIPS ATUALIZADOS\CONAV-ZIPS\CONAV_TRADER_ADVANCED_PRODUCTION\CONAV_TRADER',
    'C:\USERAT',
    'C:\USERAT\scripts',
    'C:\USERAT\USERAT_Projeto_Completo\scripts',
    'C:\USERAT1',
    'C:\USERAT1\USERAT_Final_Atualizado\scripts',
    'C:\USERAT2',
    'C:\USERAT2\scripts',
    'C:\TESTEE 2',
    'C:\TESTEE 3',
    'C:\UNIC QUANTIC\scripts',
    'C:\UNIC QUANTIC\tools'
)

# collect files across search paths (skip non-existing & handle errors)
$collected = New-Object System.Collections.ArrayList
foreach ($p in $SearchPaths) {
    try {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        if (Test-Path -LiteralPath $p) {
            $found = Get-ChildItem -Path $p -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.ps1','.py' }
            foreach ($f in $found) { $null = $collected.Add($f) }
        } else {
            Write-Log ("Search path not found (skipped): {0}" -f $p) 'WARN'
        }
    } catch {
        Write-Log ("Error scanning {0}: {1}" -f $p, $_.Exception.Message) 'WARN'
    }
}

$totalCount = $collected.Count
Write-Log ("Total scripts found across all search paths: {0}" -f $totalCount) 'INFO'

# Save summary TXT report (only if CompileRoot exists)
$reportTxt = $null
try {
    if (-not (Test-Path -LiteralPath $CompileRoot)) { New-Item -ItemType Directory -Path $CompileRoot -Force | Out-Null }
    $reportTxt = Safe-JoinPath -Path $CompileRoot -Child ("relatorio_FULLONE_{0}.txt" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    if ($reportTxt) { $summary = New-Object System.Collections.Generic.List[string]; $summary.Add(("FULLONE Report - {0}" -f (Get-Date))); $summary.Add(("Total scripts found: {0}" -f $totalCount)); $summary.Add(""); $collected | ForEach-Object { $summary.Add(($_.FullName)) }; $summary | Out-File -FilePath $reportTxt -Encoding UTF8 -Force; Write-Log ("Relatório TXT salvo em: {0}" -f $reportTxt) 'OK' }
} catch {
    Write-Log ("Falha salvando relatório TXT: {0}" -f $_.Exception.Message) 'WARN'
}

# Compile into single PS1 file (include PY as commented blocks)
$compiledFile = $null
try {
    if (-not (Test-Path -LiteralPath $CompileRoot)) { New-Item -ItemType Directory -Path $CompileRoot -Force | Out-Null }
    $compiledFile = Safe-JoinPath -Path $CompileRoot -Child ("FULLONE_COMPILED_{0}.ps1" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    if ($compiledFile) {
        $compiledLines = New-Object System.Collections.ArrayList
        foreach ($f in $collected) {
            try {
                $compiledLines.Add("##############################################################################") | Out-Null
                $compiledLines.Add(("# INICIO: {0}" -f $f.FullName)) | Out-Null
                if ($f.Extension -eq '.py') {
                    $txt = Get-Content -Raw -LiteralPath $f.FullName -ErrorAction Stop
                    $compiledLines.Add(("<# PY: begin {0} #>" -f $f.FullName)) | Out-Null
                    $compiledLines.Add($txt) | Out-Null
                    $compiledLines.Add(("<# PY: end {0} #>" -f $f.FullName)) | Out-Null
                } else {
                    $txt = Get-Content -Raw -LiteralPath $f.FullName -ErrorAction Stop
                    $compiledLines.Add($txt) | Out-Null
                }
                $compiledLines.Add(("# FIM: {0}" -f $f.FullName)) | Out-Null
                $compiledLines.Add("##############################################################################") | Out-Null
            } catch {
                Write-Log ("Falha incluindo {0}: {1}" -f $f.FullName, $_.Exception.Message) 'WARN'
            }
        }
        $compiledLines -join "`r`n" | Out-File -FilePath $compiledFile -Encoding UTF8 -Force
        Write-Log ("Compiled saved: {0}" -f $compiledFile) 'OK'
    }
} catch {
    Write-Log ("Falha ao salvar compilado: {0}" -f $_.Exception.Message) 'ERROR'
}

# Backup compiled (if compiledFile available)
if ($compiledFile) {
    try {
        $backupDir = Safe-JoinPath -Path $BackupRoot -Child ((Get-Date).ToString('yyyyMMdd_HHmmss'))
        if (-not (Test-Path -LiteralPath $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
        Copy-Item -Path $compiledFile -Destination $backupDir -Force
        Write-Log ("Backup created: {0}" -f $backupDir) 'OK'
    } catch {
        Write-Log ("Backup failed: {0}" -f $_.Exception.Message) 'WARN'
    }
} else {
    Write-Log "Nenhum compilado para backup." 'WARN'
}

# Deploy compiled (if requested)
if ($Deploy -and $compiledFile) {
    try {
        if (-not (Test-Path -LiteralPath $DeployRoot)) { New-Item -ItemType Directory -Path $DeployRoot -Force | Out-Null }
        Copy-Item -Path $compiledFile -Destination $DeployRoot -Force
        Write-Log ("Deployed compiled to: {0}" -f $DeployRoot) 'OK'
    } catch {
        Write-Log ("Deploy failed: {0}" -f $_.Exception.Message) 'ERROR'
    }
} elseif ($Deploy) {
    Write-Log "Deploy solicitado mas não há compilado." 'WARN'
}

# Generate diagram and PDF via Python (ReportLab + Pillow)
function Invoke-GenerateDiagram {
    param()
    if (-not (Test-Path -LiteralPath $DiagramRoot)) { New-Item -ItemType Directory -Path $DiagramRoot -Force | Out-Null }
    $pyScript = @"
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from reportlab.lib.pagesizes import landscape, A4
from reportlab.pdfgen import canvas
import os, sys
base = r'{diagramBase}'
png = os.path.join(base, 'DIAGRAM TECH FUTURIST.png')
pdf = os.path.join(base, 'DIAGRAM TECH FUTURIST.pdf')
w,h = 1600,900
img = Image.new('RGB',(w,h),(8,12,24))
draw = ImageDraw.Draw(img)
# draw grid
for x in range(0,w,40):
    draw.line([(x,0),(x,h)], fill=(4,8,20), width=1)
for y in range(0,h,40):
    draw.line([(0,y),(w,y)], fill=(4,8,20), width=1)
# glow boxes and connectors
nodes = [('SEARCH PATHS',800,140),('COMPILADO',800,360),('BACKUP / LOGS',480,660),('DEPLOY',1120,660)]
try:
    font = ImageFont.truetype('DejaVuSans-Bold.ttf', 28)
except:
    font = ImageFont.load_default()
for (t,x,y) in nodes:
    # glow boxes
    for radius in range(30,0,-6):
        draw.rectangle((x-260-radius, y-60-radius, x+260+radius, y+60+radius), outline=(0,60,120), width=1)
    draw.rectangle((x-260, y-60, x+260, y+60), fill=(6,18,30), outline=(0,200,255), width=3)
    # compute text size robustly
    try:
        bbox = draw.textbbox((0,0), t, font=font)
        wtxt = bbox[2]-bbox[0]; htxt = bbox[3]-bbox[1]
    except:
        try:
            wtxt, htxt = font.getsize(t)
        except:
            wtxt, htxt = (len(t)*8, 16)
    draw.text((x-wtxt/2, y-htxt/2), t, font=font, fill=(180,255,255))
# connectors
draw.line((800,200,800,300), fill=(0,200,255), width=4)
draw.line((800,420,520,620), fill=(0,200,255), width=4)
draw.line((800,420,1080,620), fill=(0,200,255), width=4)
# accents
for i in range(30):
    draw.ellipse((30+i*50,820,38+i*50,828), fill=(0,160+i*3,255))
img = img.filter(ImageFilter.GaussianBlur(0))
img.save(png)
# create PDF (simple)
c = canvas.Canvas(pdf, pagesize=landscape(A4))
c.setFillColorRGB(0,0.95,1)
c.setFont('Helvetica-Bold', 26)
c.drawCentredString(420,520,'DIAGRAM TECH FUTURIST - FULLONEv14')
c.setStrokeColorRGB(0,0.78,1)
c.setFillColorRGB(0.02,0.04,0.08)
c.rect(240,360,700,60, stroke=1, fill=1)
c.setFillColorRGB(1,1,1)
c.drawCentredString(590,390,'SEARCH PATHS (multiple)')
c.rect(240,240,200,60, stroke=1, fill=1)
c.drawCentredString(340,270,'COMPILADO')
c.rect(40,80,220,60, stroke=1, fill=1)
c.drawCentredString(150,110,'BACKUP / LOGS')
c.rect(760,80,220,60, stroke=1, fill=1)
c.drawCentredString(870,110,'DEPLOY')
c.save()
"@
    $pyScriptPath = Join-Path $env:TEMP ('fullone_gen_diagram_{0}.py' -f (Get-Date -Format 'yyyyMMddHHmmss'))
    $pyScript = $pyScript -replace '\{diagramBase\}', ($DiagramRoot -replace '\\','\\\\')
    try {
        Set-Content -Path $pyScriptPath -Value $pyScript -Encoding UTF8 -Force
        & python $pyScriptPath 2>&1 | Out-Null
        Write-Log ("Diagram generated into: {0}" -f $DiagramRoot) 'OK'
    } catch {
        Write-Log ("Diagram generation failed (python error): {0}" -f $_.Exception.Message) 'WARN'
    } finally {
        Remove-Item -Path $pyScriptPath -ErrorAction SilentlyContinue
    }
}

Invoke-GenerateDiagram

# Generate PDF report via Python (ReportLab) - only if reportTxt exists
function Invoke-GenerateReportPDF {
    param([string]$txtReportPath)
    if (-not (Test-Path -LiteralPath $txtReportPath)) { Write-Log ("PDF skipped: TXT report not found: {0}" -f $txtReportPath) 'WARN'; return }
    $pdfOut = Safe-JoinPath -Path $CompileRoot -Child ("relatorio_FULLONE_{0}.pdf" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    $py = @"
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
doc = SimpleDocTemplate(r'{pdf_out}')
styles = getSampleStyleSheet()
story = []
story.append(Paragraph('FULLONEv14 - Relatório', styles['Heading1']))
story.append(Spacer(1,12))
with open(r'{txt_in}', 'r', encoding='utf-8') as f:
    lines = f.readlines()
for l in lines:
    story.append(Paragraph(l.replace('&','&amp;'), styles['Normal']))
    story.append(Spacer(1,4))
doc.build(story)
"@
    $py = $py -replace '\{pdf_out\}', ($pdfOut -replace '\\','\\\\')
    $py = $py -replace '\{txt_in\}', ($txtReportPath -replace '\\','\\\\')
    $pyPath = Join-Path $env:TEMP ('fullone_report_{0}.py' -f (Get-Date -Format 'yyyyMMddHHmmss'))
    try {
        Set-Content -Path $pyPath -Value $py -Encoding UTF8 -Force
        & python $pyPath 2>&1 | Out-Null
        Write-Log "PDF report generated" 'OK'
    } catch {
        Write-Log ("PDF generation failed: {0}" -f $_.Exception.Message) 'WARN'
    } finally {
        Remove-Item -Path $pyPath -ErrorAction SilentlyContinue
    }
}

if ($reportTxt) { Invoke-GenerateReportPDF -txtReportPath $reportTxt } else { Write-Log "No TXT report to convert to PDF." 'WARN' }

# Create ZIP export using Python (ensure zipfile present) - only if RootOut exists
function Invoke-CreateZip {
    param([string]$zipOut)
    if ([string]::IsNullOrWhiteSpace($zipOut)) { Write-Log "Zip skipped: output path empty." 'WARN'; return }
    $py = @"
import sys, zipfile, os
out = r'{zipout}'
root = r'{rootout}'
zf = zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED)
for folder, subs, files in os.walk(root):
    for f in files:
        full = os.path.join(folder,f)
        arc = os.path.relpath(full, root)
        zf.write(full, arc)
zf.close()
print('OK')
"@
    $py = $py -replace '\{zipout\}', ($zipOut -replace '\\','\\\\')
    $py = $py -replace '\{rootout\}', ($RootOut -replace '\\','\\\\')
    $pyPath = Join-Path $env:TEMP ('fullone_zip_{0}.py' -f (Get-Date -Format 'yyyyMMddHHmmss'))
    try {
        Set-Content -Path $pyPath -Value $py -Encoding UTF8 -Force
        & python $pyPath 2>&1 | Out-Null
        Write-Log ("ZIP created: {0}" -f $zipOut) 'OK'
    } catch {
        Write-Log ("ZIP creation failed: {0}" -f $_.Exception.Message) 'WARN'
    } finally {
        Remove-Item -Path $pyPath -ErrorAction SilentlyContinue
    }
}

$zipOut = Safe-JoinPath -Path $RootOut -Child ("FULLONEv14_package_{0}.zip" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
Invoke-CreateZip -zipOut $zipOut

# Optionally build EXE via PS2EXE if requested
if ($BuildExe) {
    Write-Log "BuildExe requested. Attempting to create FULLONE.exe via PS2EXE." 'INFO'
    try {
        if (Get-Command -Name Invoke-PS2EXE -ErrorAction SilentlyContinue) {
            Invoke-PS2EXE -InputFile $PSCommandPath -OutputFile (Safe-JoinPath -Path $RootOut -Child 'FULLONE.exe') -NoConsole -Force
            Write-Log "FULLONE.exe created via Invoke-PS2EXE." 'OK'
        } elseif (Get-Command -Name ps2exe -ErrorAction SilentlyContinue) {
            & ps2exe -inputFile $PSCommandPath -outputFile (Safe-JoinPath -Path $RootOut -Child 'FULLONE.exe')
            Write-Log "FULLONE.exe created via ps2exe." 'OK'
        } else {
            Write-Log "PS2EXE not found in PATH. Skipping EXE build." 'WARN'
        }
    } catch {
        Write-Log ("BuildExe failed: {0}" -f $_.Exception.Message) 'ERROR'
    }
}

Write-Log "FULLONEv14-FIX1 finished." 'OK'
