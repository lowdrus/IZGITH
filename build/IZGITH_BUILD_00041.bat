@echo off
setlocal
chcp 65001 >nul
set "SCRIPT=%~dp0IZGITH_BUILD_00041.ps1"
if not exist "%SCRIPT%" (
  echo [ERRO] Builder PS1 nao encontrado: %SCRIPT%
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
if errorlevel 1 (
  echo [ERRO] Build falhou.
  exit /b 1
)
echo [OK] Build concluido.
endlocal
