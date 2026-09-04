"""Publicação Git/LFS com seleção local, confirmação e credenciais externas.

Nenhum comando recebido do navegador é executado como shell. O host mantém
a seleção em memória; a página não pode indicar um caminho arbitrário para ler.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
from urllib.parse import urlsplit

LFS_THRESHOLD = 100 * 1024 * 1024
MAX_FILE_SIZE = 2_000_000_000  # limite conservador: GitHub Free/Pro
MAX_FILES = 10000
SECRET = re.compile(rb'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{30,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----')


def repository_url(value):
    u = urlsplit(str(value))
    if (u.scheme != 'https' or u.netloc != 'github.com' or u.query or u.fragment
            or not re.fullmatch(r'/[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9_.-]+/?', u.path)):
        raise ValueError('Use https://github.com/usuario/repositorio, sem token ou parâmetros.')
    path = u.path.rstrip('/').removesuffix('.git')
    if path.rsplit('/', 1)[1] in {'.', '..'}:
        raise ValueError('Nome de repositório inválido.')
    return 'https://github.com' + path


def safe_relative(value):
    value = str(value)
    parts = value.split('/')
    if (not value or len(value) > 220 or any(p in {'', '.', '..'} for p in parts)
            or any(p.lower() in {'.git', '.lfsconfig'} for p in parts)
            or re.search(r'[\\\x00-\x1f:*?"<>|]', value)
            or any(p.endswith((' ', '.')) for p in parts)):
        raise ValueError('Nome ou caminho de arquivo não permitido.')
    for part in parts:
        low = part.lower()
        if low in {'.env', 'id_rsa', 'id_ed25519'} or low.startswith('.env.') or low.endswith(('.pem', '.key', '.p12', '.pfx')):
            raise ValueError('Arquivo potencialmente secreto: selecione somente conteúdo publicável.')
    return value


def scan_file(path):
    digest = hashlib.sha256()
    tail = b''
    size = 0
    with path.open('rb') as stream:
        while chunk := stream.read(1024 * 1024):
            size += len(chunk)
            if size > MAX_FILE_SIZE:
                raise ValueError('Arquivo excede o limite conservador de 2 GB do módulo.')
            if SECRET.search(tail + chunk):
                raise ValueError('Possível token ou chave privada detectado. O envio foi bloqueado.')
            digest.update(chunk)
            tail = chunk[-512:]
    return size, digest.hexdigest()


def run_git(args, cwd=None):
    from git_tools import executable
    binary = executable('git')
    if not binary:
        raise RuntimeError('Git não encontrado. Execute INSTALAR_IZGITH_HOST.bat no pacote Windows.')
    env = os.environ.copy()
    env.update(GIT_TERMINAL_PROMPT='0', GIT_LFS_SKIP_SMUDGE='1', GIT_LITERAL_PATHSPECS='1')
    # Não imprimir stdout/stderr: um credential helper pode revelar dados sensíveis.
    result = subprocess.run([binary, *args], cwd=cwd, env=env, capture_output=True,
                            text=True, timeout=1800, shell=False,
                            creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
    if result.returncode:
        raise RuntimeError('Git/LFS não concluiu a operação. Verifique autenticação no Git Credential Manager, '
                           'permissão de escrita, proteção da branch, conexão e cota LFS. Nenhum force-push foi feito.')
    return result.stdout.strip()


def publish_snapshot(snapshot, repo, confirm, git=run_git):
    """Publica uma árvore já congelada. confirm recebe detalhes ANTES do push."""
    repo = repository_url(repo)
    git(['--version'])
    git(['lfs', 'version'])
    candidates = list(snapshot.rglob('*'))
    if any(p.is_symlink() for p in candidates):
        raise ValueError('Links simbólicos não são aceitos na seleção.')
    files = sorted(p for p in candidates if p.is_file())
    if not files:
        raise ValueError('Nenhum arquivo selecionado.')
    entries = [(safe_relative(p.relative_to(snapshot).as_posix()), *scan_file(p)) for p in files]
    if len(entries) > MAX_FILES:
        raise ValueError('Seleção excede 10.000 arquivos.')
    large = [name for name, size, _ in entries if size >= LFS_THRESHOLD]
    with tempfile.TemporaryDirectory(prefix='izgith-publish-') as directory:
        root = Path(directory)
        hooks = root / 'empty-hooks'
        hooks.mkdir()
        work = root / 'repo'
        opts = ['-c', f'core.hooksPath={hooks}', '-c', 'protocol.file.allow=never']
        git([*opts, 'clone', '--no-checkout', '--', repo + '.git', str(work)])
        # O endpoint LFS vem do URL validado, nunca de um .lfsconfig do repositório.
        for key in ('lfs.url', 'remote.origin.lfsurl', 'remote.origin.lfspushurl'):
            git(['config', '--local', key, repo + '.git/info/lfs'], work)
        git(['config', '--local', 'core.hooksPath', str(hooks)], work)
        git(['config', '--local', 'user.name', 'IZGITH'], work)
        git(['config', '--local', 'user.email', 'izgith@users.noreply.github.com'], work)
        branch = git(['symbolic-ref', '--short', 'HEAD'], work)
        git(['check-ref-format', '--branch', branch], work)
        git(['checkout', '--force'], work)  # somente clone temporário criado acima
        for name, _, _ in entries:
            source, destination = snapshot / name, work / name
            for part in [destination, *destination.parents]:
                if part == work:
                    break
                if part.is_symlink():
                    raise ValueError('Destino contém link simbólico; envio interrompido.')
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, destination)
        if large and (work / '.gitattributes').is_symlink():
            raise ValueError('O arquivo .gitattributes não pode ser um link simbólico.')
        for name in large:
            git(['lfs', 'track', '--filename', '--', name], work)
        git(['add', '--', *[name for name, _, _ in entries]], work)
        if large:
            git(['add', '--', '.gitattributes'], work)
        if not git(['diff', '--cached', '--name-only'], work):
            commit = git(['rev-parse', 'HEAD'], work)
            remote = git(['ls-remote', '--exit-code', 'origin', f'refs/heads/{branch}'], work)
            if not remote or remote.split()[0] != commit:
                raise RuntimeError('O destino mudou durante a revisão. Selecione novamente.')
            return {'ok': True, 'unchanged': True, 'repository': repo, 'branch': branch,
                    'commit': commit}
        if not confirm({'repository': repo, 'branch': branch, 'files': entries, 'lfs': large}):
            return {'ok': False, 'cancelled': True}
        git(['commit', '-m', 'Publica arquivos selecionados pelo IZGITH'], work)
        # Não rebasear/forçar silenciosamente: se alguém publicou depois do clone,
        # o push normal é rejeitado e o usuário deve revisar uma nova tentativa.
        git(['lfs', 'push', 'origin', 'HEAD'], work)
        git(['push', 'origin', f'HEAD:refs/heads/{branch}'], work)
        commit = git(['rev-parse', 'HEAD'], work)
        remote = git(['ls-remote', '--exit-code', 'origin', f'refs/heads/{branch}'], work)
        if not remote or remote.split()[0] != commit:
            raise RuntimeError('Não foi possível confirmar o commit remoto. Confira o GitHub antes de repetir.')
        return {'ok': True, 'repository': repo, 'branch': branch, 'commit': commit,
                'url': repo + '/commit/' + commit, 'files': len(entries), 'lfs': len(large)}


class Publisher:
    def __init__(self):
        self.temp = None

    def close(self):
        if self.temp:
            self.temp.cleanup()
            self.temp = None

    def fresh(self):
        self.close()
        self.temp = tempfile.TemporaryDirectory(prefix='izgith-selection-')
        return Path(self.temp.name)

    def handle(self, message):
        command = message.get('command')
        if command == 'publish_pick':
            import tkinter as tk
            from tkinter import filedialog
            root = tk.Tk()
            root.withdraw()
            root.attributes('-topmost', True)
            try:
                if message.get('kind') == 'folder':
                    selected = filedialog.askdirectory(title='Pasta que será publicada no GitHub', parent=root)
                    base = Path(selected) if selected else None
                    if base and base.is_symlink():
                        raise ValueError('Links simbólicos não são aceitos.')
                    sources = [(p, base.name + '/' + p.relative_to(base).as_posix()) for p in base.rglob('*')] if base else []
                else:
                    sources = [(Path(p), Path(p).name) for p in filedialog.askopenfilenames(
                        title='Arquivos que serão publicados no GitHub', parent=root)]
            finally:
                root.destroy()
            if not sources:
                return {'ok': False, 'cancelled': True}
            target = self.fresh()
            names = set()
            total = 0
            try:
                for source, name in sources:
                    safe_relative(name)
                    if source.is_symlink():
                        raise ValueError('Links simbólicos não são aceitos.')
                    if source.is_dir():
                        continue
                    if not source.is_file():
                        raise ValueError('Somente arquivos regulares são aceitos.')
                    if name.casefold() in names or len(names) >= MAX_FILES:
                        raise ValueError('Nomes duplicados ou arquivos em excesso.')
                    names.add(name.casefold())
                    size, _ = scan_file(source)
                    total += size
                    destination = target / name
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(source, destination)
                return {'ok': True, 'files': sorted(names)[:100], 'count': len(names), 'bytes': total}
            except Exception:
                self.close()
                raise
        if command == 'publish_conversation':
            payload = message.get('payload')
            if not isinstance(payload, dict) or payload.get('schema') != 'izgith.forse-sinc.v1':
                raise ValueError('Exportação de conversa inválida.')
            encoded = json.dumps(payload, ensure_ascii=False, indent=2).encode('utf-8')
            if len(encoded) > 4 * 1024 * 1024 or SECRET.search(encoded):
                raise ValueError('Conversa excede 4 MiB ou contém possível segredo. Revise antes de publicar.')
            target = self.fresh() / 'conversations'
            target.mkdir()
            name = hashlib.sha256(encoded).hexdigest()[:16] + '.json'
            (target / name).write_bytes(encoded)
            return {'ok': True, 'files': ['conversations/' + name], 'count': 1, 'bytes': len(encoded)}
        if command == 'publish_send':
            if not self.temp:
                raise ValueError('Selecione os arquivos novamente antes de enviar.')
            from tkinter import Tk, messagebox
            def confirm(details):
                root = Tk()
                root.withdraw()
                root.attributes('-topmost', True)
                names = '\n'.join(name for name, _, _ in details['files'][:20])
                text = (f"Destino: {details['repository']}\nBranch: {details['branch']}\n"
                        f"Arquivos: {len(details['files'])}\n{names}\n\n"
                        'Arquivos existentes com os mesmos nomes serão substituídos. '
                        'Se o repositório for público, qualquer pessoa poderá ler este conteúdo.\n'
                        f"Arquivos LFS: {len(details['lfs'])}. Aplicam-se cotas e eventual cobrança da sua conta.\n\nPublicar?")
                try:
                    return messagebox.askyesno('IZGITH — confirmar publicação', text, parent=root)
                finally:
                    root.destroy()
            result = publish_snapshot(Path(self.temp.name), message.get('repository'), confirm)
            if result.get('ok'):
                self.close()
            return result
        raise ValueError('Operação de publicação desconhecida.')
