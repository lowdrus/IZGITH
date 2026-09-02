@echo off
setlocal
chcp 65001 >nul 2>nul
set "SCRIPT=%~dp0IZGITH_BUILD_00042.ps1"
if not exist "%SCRIPT%" (
  echo [ERRO] Builder PS1 nao encontrado: %SCRIPT%
  exit /b 1
)
where powershell.exe >nul 2>nul
if errorlevel 1 (
  echo [ERRO] Windows PowerShell nao encontrado.
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
if errorlevel 1 (
  echo [ERRO] Preflight falhou.
  exit /b 1
)
echo [OK] Preflight/build verificado.
endlocal
