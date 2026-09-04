@echo off
setlocal
powershell.exe -NoProfile -File "%~dp0INSTALAR_IZGITH_HOST.ps1"
if errorlevel 1 (
  echo A instalacao nao foi concluida. Confira a mensagem acima.
  pause
  exit /b 1
)
pause
