@echo off
setlocal
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0IZGITH_BUILD.ps1"
exit /b %ERRORLEVEL%
