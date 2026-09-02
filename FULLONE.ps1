<#
FULLONEv14 - Pack de Automação Unificado
Descrição: busca .ps1/.py em lista de paths, conta, detecta duplicados, SafeFix (opcional),
gera compilado, backups, logs, relatório TXT e PDF, diagrama PNG/PDF, zip export e build .exe via PS2EXE.
Observação: Tutorial.pdf está incluído no pacote mas NÃO é aberto automaticamente.
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

$Version = 'FULLONEv14'
function Safe-JoinPath { param([string]$P,[string]$C) return Join-Path -Path $P -ChildPath $C }

# --- Output root (enterprise locations)
$RootOut = 'C:\SCRIPTS\FULL ONE'
$CompileRoot = Safe-JoinPath -Path $RootOut -Child 'COMPILADO'
$BackupRoot  = Safe-JoinPath -Path $RootOut -Child 'BACKUP'
$LogsRoot    = Safe-JoinPath -Path $RootOut -Child 'LOGS'
$DeployRoot  = Safe-JoinPath -Path $RootOut -Child 'DEPLOY'
$DiagramRoot = Safe-JoinPath -Path $RootOut -Child 'DIAGRAMA VISUAL'

# Ensure directories exist
foreach ($d in @($RootOut,$CompileRoot,$BackupRoot,$LogsRoot,$DeployRoot,$DiagramRoot)) {
    if (-not (Test-Path -LiteralPath $d)) {
        try { New-Item -ItemType Directory -Path $d -Force | Out-Null } catch { }
    }
}

# Global log file (guarantee a file, not a directory)
$Global:FULL_LOG_FILE = Safe-JoinPath -Path $LogsRoot -Child ("fullone_log_{0}.txt" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
if (-not (Test-Path -LiteralPath $Global:FULL_LOG_FILE -PathType Leaf)) {
    try { New-Item -ItemType File -Path $Global:FULL_LOG_FILE -Force | Out-Null } catch {}
}

function Write-Log {
    param([string]$Message, [ValidateSet('INFO','OK','WARN','ERROR')][string]$Level = 'INFO')
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$ts][$Level] $Message"
    try { Add-Content -Path $Global:FULL_LOG_FILE -Value $line -Encoding UTF8 } catch {}
    switch ($Level) {
        'INFO' { Write-Host $line -ForegroundColor White }
        'OK'   { Write-Host $line -ForegroundColor Green }
        'WARN' { Write-Host $line -ForegroundColor Yellow }
        'ERROR'{ Write-Host $line -ForegroundColor Red }
    }
}

Write-Log -Message ("{0} iniciado. DryRun={1}, AutoFix={2}, Backup={3}, Exec={4}, Deploy={5}" -f $Version, $DryRun, $AutoFix, $Backup, $Exec, $Deploy) -Level 'INFO'

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

# collect files across search paths
$collected = New-Object System.Collections.ArrayList
foreach ($p in $SearchPaths) {
    try {
        if (Test-Path -LiteralPath $p) {
            $found = Get-ChildItem -Path $p -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.ps1','.py' }
            foreach ($f in $found) { $null = $collected.Add($f) }
        } else {
            Write-Log -Message ("Search path not found (skipped): {0}" -f $p) -Level 'WARN'
        }
    } catch {
        Write-Log -Message ("Error scanning {0}: {1}" -f $p, $_.Exception.Message) -Level 'WARN'
    }
}

$totalCount = $collected.Count
Write-Log -Message ("Total scripts found across all search paths: {0}" -f $totalCount) -Level 'INFO'

# Save summary TXT report
$reportTxt = Safe-JoinPath -Path $CompileRoot -Child ("relatorio_FULLONE_{0}.txt" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$summary = New-Object System.Collections.Generic.List[string]
$summary.Add(("FULLONE Report - {0}" -f (Get-Date)))
$summary.Add(("SearchPaths count: {0}" -f $SearchPaths.Count))
$summary.Add(("Total scripts found: {0}" -f $totalCount))
$summary.Add("")
$collected | ForEach-Object { $summary.Add(($_.FullName)) }
$summary | Out-File -FilePath $reportTxt -Encoding UTF8 -Force
Write-Log -Message ("Relatório TXT salvo em: {0}" -f $reportTxt) -Level 'OK'

# Compile into single PS1 file (include PY as commented blocks)
$compiledFile = Safe-JoinPath -Path $CompileRoot -Child ("FULLONE_COMPILED_{0}.ps1" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
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
        Write-Log -Message ("Falha incluindo {0}: {1}" -f $f.FullName, $_.Exception.Message) -Level 'WARN'
    }
}
$compiledLines -join "`r`n" | Out-File -FilePath $compiledFile -Encoding UTF8 -Force
Write-Log -Message ("Compiled saved: {0}" -f $compiledFile) -Level 'OK'

# Backup compiled
$backupDir = Safe-JoinPath -Path $BackupRoot -Child ((Get-Date).ToString('yyyyMMdd_HHmmss'))
if (-not (Test-Path -LiteralPath $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
try { Copy-Item -Path $compiledFile -Destination $backupDir -Force; Write-Log -Message ("Backup created: {0}" -f $backupDir) -Level 'OK' } catch { Write-Log -Message ("Backup failed: {0}" -f $_.Exception.Message) -Level 'WARN' }

# Deploy compiled
if ($Deploy) {
    try { Copy-Item -Path $compiledFile -Destination $DeployRoot -Force; Write-Log -Message ("Deployed compiled to: {0}" -f $DeployRoot) -Level 'OK' } catch { Write-Log -Message ("Deploy failed: {0}" -f $_.Exception.Message) -Level 'ERROR' }
}

# Generate diagram and PDF via Python (ReportLab + Pillow) - write temp python script and run it
function Invoke-GenerateDiagram {
    param()
    $pyScript = @"
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from reportlab.lib.pagesizes import landscape, A4
from reportlab.pdfgen import canvas
import os
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
for i,(t,x,y) in enumerate(nodes):
    # glow
    for radius in range(30,0,-6):
        draw.rectangle((x-260-radius, y-60-radius, x+260+radius, y+60+radius), outline=(0,60,120, max(1,int(radius/3))), width=1)
    draw.rectangle((x-260, y-60, x+260, y+60), fill=(6,18,30), outline=(0,200,255), width=3)
    # text
    try:
        font = ImageFont.truetype('DejaVuSans-Bold.ttf', 28)
    except:
        font = ImageFont.load_default()
    wtxt, htxt = draw.textsize(t, font=font)
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
# create PDF
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
    Set-Content -Path $pyScriptPath -Value $pyScript -Encoding UTF8 -Force
    try {
        & python $pyScriptPath
        Write-Log -Message ("Diagram generated into: {0}" -f $DiagramRoot) -Level 'OK'
    } catch {
        Write-Log -Message ("Diagram generation failed (python error): {0}" -f $_.Exception.Message) -Level 'WARN'
    } finally {
        Remove-Item -Path $pyScriptPath -ErrorAction SilentlyContinue
    }
}

Invoke-GenerateDiagram

# Generate PDF report via Python (ReportLab) - write small python script and run it
function Invoke-GenerateReportPDF {
    param([string]$txtReportPath)
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
    $py = $py -replace '\{pdf_out\}', (Safe-JoinPath -Path $CompileRoot -Child ("relatorio_FULLONE_{0}.pdf" -f (Get-Date -Format 'yyyyMMdd_HHmmss')) -replace '\\','\\\\')
    $py = $py -replace '\{txt_in\}', ($txtReportPath -replace '\\','\\\\')
    $pyPath = Join-Path $env:TEMP ('fullone_report_{0}.py' -f (Get-Date -Format 'yyyyMMddHHmmss'))
    Set-Content -Path $pyPath -Value $py -Encoding UTF8 -Force
    try {
        & python $pyPath
        Write-Log -Message ("PDF report generated") -Level 'OK'
    } catch {
        Write-Log -Message ("PDF generation failed: {0}" -f $_.Exception.Message) -Level 'WARN'
    } finally {
        Remove-Item -Path $pyPath -ErrorAction SilentlyContinue
    }
}

# Call PDF generation for the TXT we saved earlier
Invoke-GenerateReportPDF -txtReportPath $reportTxt

# Create ZIP export using Python (ensure zipfile present)
function Invoke-CreateZip {
    param([string]$zipOut)
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
    Set-Content -Path $pyPath -Value $py -Encoding UTF8 -Force
    try {
        & python $pyPath
        Write-Log -Message ("ZIP created: {0}" -f $zipOut) -Level 'OK'
    } catch {
        Write-Log -Message ("ZIP creation failed: {0}" -f $_.Exception.Message) -Level 'WARN'
    } finally {
        Remove-Item -Path $pyPath -ErrorAction SilentlyContinue
    }
}

# create package zip in RootOut
$zipOut = Safe-JoinPath -Path $RootOut -Child ("FULLONEv14_package_{0}.zip" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
Invoke-CreateZip -zipOut $zipOut

# Optionally build EXE via PS2EXE if requested
if ($BuildExe) {
    Write-Log -Message "BuildExe requested. Attempting to create FULLONE.exe via PS2EXE." -Level 'INFO'
    try {
        if (Get-Command -Name Invoke-PS2EXE -ErrorAction SilentlyContinue) {
            Invoke-PS2EXE -InputFile $MyInvocation.MyCommand.Definition -OutputFile (Safe-JoinPath -Path $RootOut -Child 'FULLONE.exe') -NoConsole -Force
            Write-Log -Message "FULLONE.exe created via Invoke-PS2EXE." -Level 'OK'
        } elseif (Get-Command -Name ps2exe -ErrorAction SilentlyContinue) {
            & ps2exe -inputFile $MyInvocation.MyCommand.Definition -outputFile (Safe-JoinPath -Path $RootOut -Child 'FULLONE.exe')
            Write-Log -Message "FULLONE.exe created via ps2exe." -Level 'OK'
        } else {
            Write-Log -Message "PS2EXE not found in PATH. Skipping EXE build." -Level 'WARN'
        }
    } catch {
        Write-Log -Message ("BuildExe failed: {0}" -f $_.Exception.Message) -Level 'ERROR'
    }
}

Write-Log -Message "FULLONEv14 finished." -Level 'OK'
