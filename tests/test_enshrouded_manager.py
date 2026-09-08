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

    def test_runtime_contract_is_browser_safe_and_remote_capable(self):
        p = json.loads((ROOT / 'integrations/ENSHROUDED_MANAGER/runtime-contract.json').read_text(encoding='utf-8'))
        self.assertFalse(p['browser_execution'])
        self.assertEqual(p['default_endpoint'], 'http://127.0.0.1:38751')
        self.assertIn('server.start', p['operations'])
        self.assertIn('player.ban', p['operations'])
        self.assertIn('server.start', p['implemented_remote_operations'])
        self.assertIn('Bearer token', p['auth'])

    def test_remote_agent_is_allowlisted(self):
        agent = (ROOT / 'runtime/enshgerenc-agent/app.py').read_text(encoding='utf-8')
        self.assertIn('IZGITH_RUNTIME_TOKEN', agent)
        self.assertIn('compare_digest', agent)
        self.assertIn('server.start', agent)
        self.assertIn('server.stop', agent)
        self.assertNotIn('shell=True', agent)
        self.assertNotIn('os.system(', agent)
        self.assertNotIn('eval(', agent)

    def test_manager_contains_required_controls(self):
        page = (EXT / 'ui/enshrouded.html').read_text(encoding='utf-8')
        for text in ('Servidores', 'Jogadores', 'Backups', 'Registros', 'Configurações', 'Instalação', 'Atualizações', 'Diagnóstico'):
            self.assertIn(text, page)
        screen = (EXT / 'ui/enshrouded-manager-screen.js').read_text(encoding='utf-8')
        for text in ('Runtime Agent', 'Kick', 'Ban', 'BACKUP_EMERGENCY', 'docker-compose.enshrouded.yml'):
            self.assertIn(text, screen)

    def test_dashboard_card_is_ensh_gerenc_and_contains_all_actions(self):
        dashboard = (EXT / 'ui/dashboard.html').read_text(encoding='utf-8')
        screen = (EXT / 'integrations/enshrouded-manager.js').read_text(encoding='utf-8')
        for text in ('ENSH-GERENC', 'Salvar perfil', 'Validar', 'Limpar'):
            self.assertIn(text, dashboard)
        for text in ('ENSH-GERENC', 'Verificar', 'Preparar Instalação', 'Preparar Início', 'Preparar Parada', 'Backup', 'Restaurar', 'Retenção', 'Mods', 'Recursos', 'Versão', 'Baixar Config', 'Baixar Compose', 'Baixar Plano', 'Conectar Runtime'):
            self.assertIn(text, screen)

if __name__ == '__main__':
    unittest.main()
