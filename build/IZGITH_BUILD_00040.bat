@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0.."
echo ==========================================================
echo IZGITH CLEAN CORE 00040 - BUILD / VERIFY
 echo ==========================================================
where py >nul 2>&1
if %errorlevel%==0 (set "PY=py") else (set "PY=python")
%PY% scripts\validate_project.py
if errorlevel 1 (
  echo [ERRO] Validacao falhou.
  exit /b 1
)
%PY% scripts\package_extension.py
if errorlevel 1 (
  echo [ERRO] Empacotamento falhou.
  exit /b 1
)
echo [OK] Build e pacote concluidos.
echo [OK] Extensao: %cd%\extension
echo [OK] ZIP: %cd%\dist
exit /b 0
