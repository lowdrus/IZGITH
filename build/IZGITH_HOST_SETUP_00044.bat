@echo off
setlocal
cd /d "%~dp0"
title IZGITH Native Host Setup 00044
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0IZGITH_HOST_SETUP_00044.ps1" %*
if errorlevel 1 (
  echo.
  echo [ERRO] Configuracao do Native Messaging nao foi concluida.
) else (
  echo.
  echo [OK] Configuracao concluida.
)
pause
endlocal
