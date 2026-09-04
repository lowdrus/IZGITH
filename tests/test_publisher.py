import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import importlib.util
spec = importlib.util.spec_from_file_location('izgith_publisher', Path(__file__).resolve().parents[1]/'host/publisher.py')
p = importlib.util.module_from_spec(spec)
spec.loader.exec_module(p)


class PublisherTests(unittest.TestCase):
    def test_repository_is_exact_https_github(self):
        self.assertEqual(p.repository_url('https://github.com/lowdrus/IZGITH.git'), 'https://github.com/lowdrus/IZGITH')
        for url in ['http://github.com/a/b', 'https://github.com.evil/a/b', 'https://token@github.com/a/b',
                    'file:///a/b', 'https://github.com/a/b?token=x', 'https://github.com/a/..']:
            with self.subTest(url=url), self.assertRaises(ValueError):
                p.repository_url(url)

    def test_paths_cannot_escape_or_contain_secrets(self):
        for name in ['../file', '/file', 'a/.git/config', '.lfsconfig', 'a\\b', 'a/.env.local',
                     'a/id_rsa', 'key.pem', 'a:stream', 'a/../b', 'a./b']:
            with self.subTest(name=name), self.assertRaises(ValueError):
                p.safe_relative(name)
        self.assertEqual(p.safe_relative('pasta/arquivo [1].txt'), 'pasta/arquivo [1].txt')

    def test_secret_scanner_across_chunk_boundary(self):
        with tempfile.TemporaryDirectory() as tmp:
            f=Path(tmp)/'text.txt'
            f.write_bytes(b'x'*(1024*1024-5)+b'github_' + b'pat_' + b'A'*40)
            with self.assertRaises(ValueError):
                p.scan_file(f)

    def test_supplied_json_exact_bytes(self):
        f=Path(__file__).resolve().parents[1]/'.chatgpt/conversations/69cb3e9ea61c81a2895c94c07cbd9c33.json'
        self.assertEqual(hashlib.sha256(f.read_bytes()).hexdigest(), 'e750c1640e0940037cfb67502641dfdd901be4de52a585382b76672c73997c8b')
        self.assertEqual(json.loads(f.read_bytes())['schema_version'],3)

    def test_selection_cleared_on_close(self):
        publisher=p.Publisher()
        result=publisher.handle({'command':'publish_conversation','payload':{'schema':'izgith.forse-sinc.v1','messages':[]}})
        self.assertTrue(result['ok'])
        location=Path(publisher.temp.name)
        publisher.close()
        self.assertFalse(location.exists())
        with self.assertRaises(ValueError):
            publisher.handle({'command':'publish_send','repository':'https://github.com/a/b'})

    def fake_git(self, calls, remote_sha='a'*40, fail_push=False):
        def git(args,cwd=None):
            calls.append(args)
            if 'clone' in args:
                Path(args[-1]).mkdir()
            if args[:2]==['symbolic-ref','--short']: return 'main'
            if args[:2]==['diff','--cached']: return 'arquivo.txt'
            if args[:2]==['rev-parse','HEAD']: return 'a'*40
            if args[0]=='ls-remote': return remote_sha+'\trefs/heads/main'
            if args[0]=='push' and fail_push: raise RuntimeError('Permissão negada')
            return ''
        return git

    def test_lfs_and_remote_verification(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(p,'LFS_THRESHOLD',8):
            root=Path(tmp);(root/'arquivo.txt').write_bytes(b'public data')
            calls=[]
            result=p.publish_snapshot(root,'https://github.com/a/b',lambda detail: bool(detail['lfs']),self.fake_git(calls))
            self.assertTrue(result['ok']);self.assertEqual(result['lfs'],1)
            self.assertIn(['lfs','track','--filename','--','arquivo.txt'],calls)
            self.assertIn(['lfs','push','origin','HEAD'],calls)
            self.assertFalse(any('--force-with-lease' in x or '--rebase' in x for x in calls))
            with self.assertRaises(RuntimeError):
                p.publish_snapshot(root,'https://github.com/a/b',lambda _:True,self.fake_git([],remote_sha='b'*40))
            with self.assertRaises(RuntimeError):
                p.publish_snapshot(root,'https://github.com/a/b',lambda _:True,self.fake_git([],fail_push=True))

    def test_cancellation_never_pushes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);(root/'arquivo.txt').write_text('data')
            calls=[];result=p.publish_snapshot(root,'https://github.com/a/b',lambda _:False,self.fake_git(calls))
            self.assertTrue(result['cancelled'])
            self.assertFalse(any(x[0] in {'push','commit'} or x[:2]==['lfs','push'] for x in calls))

    def test_real_git_local_remote_roundtrip(self):
        """Git real; destino bare local. Nenhuma publicação externa no teste."""
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);remote=root/'remote.git';seed=root/'seed';snapshot=root/'snapshot';snapshot.mkdir()
            env=os.environ.copy();env.update(GIT_AUTHOR_NAME='Teste',GIT_AUTHOR_EMAIL='test@example.invalid',GIT_COMMITTER_NAME='Teste',GIT_COMMITTER_EMAIL='test@example.invalid',GIT_LITERAL_PATHSPECS='1')
            def raw(args,cwd=None):
                r=subprocess.run(['git',*args],cwd=cwd,env=env,capture_output=True,text=True,check=True)
                return r.stdout.strip()
            raw(['init','--bare','--initial-branch=main',str(remote)])
            raw(['clone',str(remote),str(seed)])
            (seed/'README.md').write_text('Inicial')
            raw(['add','.'],seed);raw(['commit','-m','Inicial'],seed);raw(['push','origin','main'],seed)
            (snapshot/'arquivo [1].txt').write_text('publicação verificada',encoding='utf-8')
            def local_git(args,cwd=None):
                if 'clone' in args: return raw(['clone','--no-checkout',str(remote),args[-1]])
                if args[:2]==['config','--local'] and args[2] in {'lfs.url','remote.origin.lfsurl','remote.origin.lfspushurl'}:
                    return raw([*args[:-1],remote.as_uri()],cwd)
                return raw(args,cwd)
            with patch.object(p,'LFS_THRESHOLD',8):
                result=p.publish_snapshot(snapshot,'https://github.com/test/repo',lambda _:True,local_git)
            self.assertEqual(raw(['rev-parse','main'],remote),result['commit'])
            self.assertIn('version https://git-lfs.github.com/spec/v1',raw(['show','main:arquivo [1].txt'],remote))
            raw(['pull','--ff-only'],seed)
            self.assertEqual((seed/'arquivo [1].txt').read_text('utf-8'),'publicação verificada')


if __name__=='__main__': unittest.main()
