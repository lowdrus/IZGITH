@echo off
setlocal
title IZGITH 00050 FULL BUILD
set "HERE=%~dp0"
echo ==========================================================
echo IZGITH - FULL BUILD 00050
echo ==========================================================
echo.
where powershell.exe >nul 2>&1
if errorlevel 1 (
  echo [ERRO] PowerShell nao encontrado.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%HERE%IZGITH_BUILD_00050.ps1"
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" echo [ERRO] Build terminou com codigo %RC%.
if "%RC%"=="0" echo [OK] Build concluido.
pause
exit /b %RC%
