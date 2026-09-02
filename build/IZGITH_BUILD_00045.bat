@echo off
setlocal
cd /d "%~dp0.."
where powershell.exe >nul 2>&1
if errorlevel 1 (
  echo [ERRO] Windows PowerShell nao encontrado.
  exit /b 1
)
echo ==========================================================
echo IZGITH - BUILD/VERIFY 6.0.0.00045
 echo ==========================================================
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0IZGITH_BUILD_00045.ps1" -Root "%cd%"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" echo [ERRO] Verificacao falhou. Veja as mensagens acima.
if "%RC%"=="0" echo [OK] Verificacao concluida.
exit /b %RC%
