import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXT = ROOT / 'extension'


class ConvDContractTests(unittest.TestCase):
    def test_link_module_exists_and_is_syntax_shaped(self):
        p = EXT / 'integrations' / 'conv-d-link.js'
        self.assertTrue(p.is_file())
        text = p.read_text(encoding='utf-8')
        self.assertIn('IZGITH_CONVD_LINK', text)
        self.assertIn('chrome.tabs.create', text)
        self.assertNotIn('connectNative', text)

    def test_conversation_module_has_required_exports(self):
        p = EXT / 'integrations' / 'conv-d.js'
        text = p.read_text(encoding='utf-8')
        for token in ('izgith.conv-d.v4', 'Baixar Conversa', 'Tudo', 'Ultima Rodada', 'SAVE_FILE', 'convDEnabled'):
            self.assertIn(token, text)
        self.assertNotIn('izgith-cd-min', text)
        self.assertIn("saveAs:true", ROOT.joinpath('extension/sw.js').read_text(encoding='utf-8'))

    def test_registry_matches_manifest_package(self):
        manifest = json.loads((EXT / 'manifest.json').read_text(encoding='utf-8'))
        package = json.loads((ROOT / 'package.json').read_text(encoding='utf-8'))
        registry = json.loads((ROOT / 'integrations' / 'assistant_registry.json').read_text(encoding='utf-8'))
        m = re.fullmatch(r'(\d+\.\d+\.\d+)\.(\d+)', manifest['version'])
        self.assertIsNotNone(m)
        self.assertEqual(package['version'], f'{m.group(1)}-{int(m.group(2)):05d}')
        self.assertEqual(registry['version'], f'{m.group(1)}.{int(m.group(2)):05d}')

    def test_native_messaging_is_not_a_runtime_dependency(self):
        manifest = json.loads((EXT / 'manifest.json').read_text(encoding='utf-8'))
        sw = (EXT / 'sw.js').read_text(encoding='utf-8')
        self.assertNotIn('nativeMessaging', manifest.get('permissions', []))
        self.assertNotIn('connectNative', sw)
        self.assertNotIn('NATIVE_HOST', sw)


if __name__ == '__main__':
    unittest.main()
