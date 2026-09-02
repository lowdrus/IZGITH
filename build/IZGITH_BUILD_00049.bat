@echo off
setlocal EnableExtensions
cd /d "%~dp0.."
set "ROOT=%CD%"
echo ==========================================================
echo IZGITH BUILD 00049 - FULL VALIDATION / PACKAGE
echo ==========================================================
where powershell.exe >nul 2>nul
if errorlevel 1 (
  echo [ERRO] Windows PowerShell nao encontrado.
  exit /b 1
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\build\IZGITH_BUILD_00049.ps1" -Root "%ROOT%"
if errorlevel 1 (
  echo [ERRO] Build/validacao falhou.
  exit /b 1
)
echo [OK] Build 00049 concluido.
exit /b 0
