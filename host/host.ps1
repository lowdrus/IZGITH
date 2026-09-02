$ErrorActionPreference='Stop'
$Python=Get-Command python -ErrorAction SilentlyContinue
if(-not $Python){throw 'Python não encontrado'}
& $Python.Source (Join-Path $PSScriptRoot 'host.py')
exit $LASTEXITCODE
