@echo off
setlocal
cd /d "%~dp0.."
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS%" (
  echo [ERRO] Windows PowerShell nao encontrado.
  exit /b 1
)
"%PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0IZGITH_BUILD_00053.ps1"
set "RC=%ERRORLEVEL%"
echo.
if "%RC%"=="0" echo [OK] Build/validacao concluido.
if not "%RC%"=="0" echo [ERRO] Build/validacao falhou. Codigo %RC%.
exit /b %RC%
