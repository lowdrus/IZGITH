@echo off
setlocal EnableExtensions
cd /d "%~dp0"
where powershell.exe >nul 2>&1
if errorlevel 1 (
  echo PowerShell nao encontrado.
  pause
  exit /b 1
)
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0INSTALAR_IZGITH_HOST.ps1"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo A instalacao nao foi concluida. Codigo: %RC%
  pause
  exit /b %RC%
)
echo Instalacao concluida.
pause
exit /b 0
