"""Descoberta explícita de Git/GitHub CLI, sem coletar credenciais."""
import os
from pathlib import Path
import shutil
import subprocess


def executable(name):
    found = shutil.which(name)
    if found:
        return found
    if os.name == 'nt':
        # O Chrome pode ter herdado um PATH anterior à instalação.
        candidates = {'git': [('PROGRAMFILES', 'Git/cmd/git.exe'),
                              ('LOCALAPPDATA', 'Programs/Git/cmd/git.exe')],
                      'gh': [('PROGRAMFILES', 'GitHub CLI/gh.exe'),
                             ('LOCALAPPDATA', 'Programs/GitHub CLI/gh.exe')]}
        for variable, relative in candidates.get(name, []):
            if os.environ.get(variable):
                target = Path(os.environ[variable]) / relative
                if target.is_file():
                    return str(target)
    return None


def diagnostics():
    git, gh = executable('git'), executable('gh')
    def probe(binary, args):
        if not binary:
            return False
        try:
            result = subprocess.run([binary, *args], stdin=subprocess.DEVNULL,
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                    timeout=15, shell=False,
                                    creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
            return result.returncode == 0
        except (OSError, subprocess.TimeoutExpired):
            return False
    return {'git': probe(git, ['--version']), 'lfs': probe(git, ['lfs', 'version']),
            'github_cli': bool(gh), 'github_cli_authenticated': probe(gh, ['auth', 'status', '--hostname', 'github.com']),
            'write_access_verified': False,
            'note': 'Autenticação não concede escrita em qualquer repositório. O destino é verificado durante o envio.'}
