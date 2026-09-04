@echo off
setlocal
cd /d "%~dp0\.."
where git >nul 2>nul || (echo Instale Git for Windows com Git LFS e Git Credential Manager: https://git-scm.com/download/win & pause & exit /b 1)
git lfs version >nul 2>nul || (echo Git LFS nao encontrado: https://git-lfs.com/ & pause & exit /b 1)
where python >nul 2>nul || (echo Python 3 nao foi encontrado no PATH.& exit /b 1)
python -m pip install --disable-pip-version-check --user "pyinstaller>=6.0,<7"
if errorlevel 1 exit /b 1
python -m PyInstaller --noconfirm --clean --onefile --name izgith_host host.py
if errorlevel 1 exit /b 1
set /p IZGITH_ID=Digite o ID de 32 caracteres mostrado em chrome://extensions:
python install_host.py --extension-id "%IZGITH_ID%" --browser chrome
if errorlevel 1 exit /b 1
echo.
echo Host IZGITH registrado. Reinicie o Chrome.
pause
