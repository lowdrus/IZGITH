import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXT = ROOT / 'extension'

class EnshroudedManagerContractTests(unittest.TestCase):
    def test_ui_assets_and_manifest_reference(self):
        self.assertTrue((EXT / 'ui/enshrouded.html').is_file())
        self.assertTrue((EXT / 'ui/enshrouded-manager.css').is_file())
        self.assertTrue((EXT / 'ui/enshrouded-manager-screen.js').is_file())
        page = (EXT / 'ui/enshrouded.html').read_text(encoding='utf-8')
        self.assertIn('enshrouded-manager.css', page)
        self.assertIn('enshrouded-manager-screen.js', page)

    def test_runtime_contract_is_browser_safe(self):
        p = json.loads((ROOT / 'integrations/ENSHROUDED_MANAGER/runtime-contract.json').read_text(encoding='utf-8'))
        self.assertFalse(p['browser_execution'])
        self.assertEqual(p['default_endpoint'], 'http://127.0.0.1:38751')
        self.assertIn('server.start', p['operations'])
        self.assertIn('player.ban', p['operations'])

    def test_manager_contains_required_controls(self):
        page = (EXT / 'ui/enshrouded.html').read_text(encoding='utf-8')
        for text in ('Servidores', 'Jogadores', 'Backups', 'Registros', 'Configurações', 'Instalação', 'Atualizações', 'Diagnóstico'):
            self.assertIn(text, page)
        screen = (EXT / 'ui/enshrouded-manager-screen.js').read_text(encoding='utf-8')
        for text in ('Runtime Agent', 'Kick', 'Ban', 'BACKUP_EMERGENCY', 'docker-compose.enshrouded.yml'):
            self.assertIn(text, screen)

if __name__ == '__main__':
    unittest.main()
