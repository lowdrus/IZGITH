@echo off
setlocal
cd /d "%~dp0"
title IZGITH FULL BUILD 00058
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0IZGITH_BUILD_00058.ps1"
if errorlevel 1 (
  echo.
  echo [FAIL] Build failed.
  pause
  exit /b 1
)
echo.
echo [OK] Build completed.
pause
endlocal
