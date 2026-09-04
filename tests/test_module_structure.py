from html.parser import HTMLParser
import json
from pathlib import Path
import re
import unittest
from urllib.parse import urlsplit, unquote

EXT=Path(__file__).resolve().parents[1]/'extension'

class References(HTMLParser):
    def __init__(self): super().__init__(); self.refs=[]
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if tag in {'script','img','iframe'} and a.get('src'): self.refs.append(a['src'])
        if tag=='link' and a.get('href'): self.refs.append(a['href'])

class ModuleStructureTests(unittest.TestCase):
    def test_all_html_local_dependencies_exist(self):
        for path in EXT.rglob('*.html'):
            parser=References();parser.feed(path.read_text('utf-8'))
            for ref in parser.refs:
                if urlsplit(ref).scheme or ref.startswith('//') or '{{' in ref: continue
                location=unquote(urlsplit(ref).path)
                target=EXT/location.lstrip('/') if location.startswith('/') else path.parent/location
                with self.subTest(file=str(path.relative_to(EXT)),ref=ref): self.assertTrue(target.is_file())

    def test_one_manifest_and_identity(self):
        self.assertEqual(len(list(EXT.rglob('manifest.json'))),1)
        m=json.loads((EXT/'manifest.json').read_text())
        self.assertEqual(m['name'],'IZGITH');self.assertNotIn('key',m);self.assertNotIn('update_url',m)
        self.assertNotIn('nativeMessaging',m['permissions']);self.assertIn('nativeMessaging',m['optional_permissions'])
        self.assertNotIn('<all_urls>',m['host_permissions'])

    def test_dynamic_scripts_and_worker_paths(self):
        entries=json.loads((EXT/'modules/jdownloader/content-scripts.json').read_text())
        for entry in entries:
            for name in entry['js']: self.assertTrue((EXT/name).is_file())
        text=(EXT/'modules/jdownloader/background.js').read_text()
        for name in re.findall(r"files: \['([^']+)'\]",text): self.assertTrue((EXT/name).is_file(),name)
        self.assertNotIn("setAccessLevel({ accessLevel: 'TRUSTED_AND_UNTRUSTED_CONTEXTS'",text)
        self.assertIn('myjd-get-captcha-job',text)

    def test_translations_parse_and_cover_default(self):
        default=json.loads((EXT/'_locales/pt_BR/messages.json').read_text())
        self.assertTrue(default)
        for path in (EXT/'_locales').glob('*/messages.json'):
            data=json.loads(path.read_text());self.assertTrue(all(isinstance(x.get('message'),str) for x in data.values()))

if __name__=='__main__': unittest.main()
