@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
where powershell.exe >nul 2>&1
if errorlevel 1 (
  echo PowerShell nao encontrado.
  pause
  exit /b 1
)
set "SCRIPT=%~dp0INSTALAR_IZGITH_HOST.ps1"
if not exist "%SCRIPT%" (
  echo Instalador PowerShell nao encontrado: "%SCRIPT%"
  pause
  exit /b 1
)
rem Executa o instalador no escopo do processo, sem exigir assinatura do PS1.
rem Se o computador tiver uma Group Policy que imponha AllSigned, somente a politica corporativa pode prevalecer.
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $p=$env:IZGITH_HOST_INSTALLER; if(-not $p){$p='%SCRIPT%'}; if(Test-Path -LiteralPath $p){try{Unblock-File -LiteralPath $p -ErrorAction SilentlyContinue}catch{}}; & powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $p; exit $LASTEXITCODE"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo A instalacao nao foi concluida. Codigo: %RC%
  echo Se uma politica de grupo impuser AllSigned, o administrador do Windows precisa autorizar o script.
  pause
  exit /b %RC%
)
echo Instalacao concluida.
pause
exit /b 0
