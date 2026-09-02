@echo off
setlocal
set "ROOT=%~dp0.."
echo ==========================================================
echo IZGITH - BUILD / VERIFY 6.0.0.00044
echo ==========================================================
where powershell.exe >nul 2>nul
if errorlevel 1 (
  echo [FAIL] Windows PowerShell nao encontrado.
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0IZGITH_BUILD_00044.ps1" -Root "%ROOT%"
if errorlevel 1 (
  echo [FAIL] Verificacao encerrada com erro.
  exit /b 1
)
echo [OK] IZGITH verificado.
echo [INFO] Para empacotar: python scripts\package_extension.py
exit /b 0
