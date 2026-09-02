@echo off
setlocal
cd /d "%~dp0\.."
where python >nul 2>nul || (echo Python 3 nao foi encontrado no PATH.& exit /b 1)
python -m pip install --disable-pip-version-check --user "pyinstaller>=6.0,<7"
if errorlevel 1 exit /b 1
python -m PyInstaller --noconfirm --clean --onefile --name izgith_host ext_host.py
if errorlevel 1 exit /b 1
set /p IZGITH_ID=Digite o ID de 32 caracteres mostrado em chrome://extensions: 
python install_host.py --extension-id "%IZGITH_ID%" --browser chrome
if errorlevel 1 exit /b 1
echo.
echo Host IZGITH registrado. Reinicie o Chrome.
pause
