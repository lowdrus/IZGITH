@echo off
setlocal
chcp 65001 >nul 2>nul
set "SCRIPT=%~dp0IZGITH_BUILD_00042.ps1"
if not exist "%SCRIPT%" echo [ERRO] %SCRIPT% nao encontrado & exit /b 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
if errorlevel 1 echo [ERRO] Preflight falhou & exit /b 1
echo [OK] IZGITH 00042 verificado.
endlocal
