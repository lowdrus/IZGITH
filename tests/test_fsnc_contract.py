import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class FsncContractTests(unittest.TestCase):
    def test_contract_is_explicit_and_no_force_push(self):
        data = json.loads((ROOT / "integrations/F-SNC/integration.json").read_text(encoding="utf-8"))
        self.assertTrue(data["automatic_publication_after_authorization"])
        self.assertEqual(data["authorization"]["method"], "fine_grained_token_explicit")
        self.assertFalse(data["authorization"]["hardcoded_token"])
        self.assertFalse(data["authorization"]["cookies"])
        self.assertFalse(data["authorization"]["force_push"])
        self.assertEqual(data["publication"]["transport"], "GitHub Contents API")

    def test_service_worker_has_explicit_authorization_and_safe_publication(self):
        sw = (ROOT / "extension/sw.js").read_text(encoding="utf-8")
        self.assertIn("GITHUB_AUTHORIZE", sw)
        self.assertIn("GITHUB_PUBLISH_CAPTURE", sw)
        self.assertIn("Authorization", sw)
        self.assertIn("api.github.com/repos/", sw)
        self.assertNotIn("git push --force", sw.lower())
        self.assertNotIn("document.cookie", sw.lower())
        self.assertNotIn("github_pat_", sw)

    def test_manifest_allows_github_api_and_keeps_native_messaging_off(self):
        manifest = json.loads((ROOT / "extension/manifest.json").read_text(encoding="utf-8"))
        self.assertIn("https://api.github.com/*", manifest.get("host_permissions", []))
        self.assertNotIn("nativeMessaging", manifest.get("permissions", []))

    def test_menu_fix_contains_window_and_embed_hardening(self):
        js = (ROOT / "extension/ui/menu-fix.js").read_text(encoding="utf-8")
        self.assertIn("getCurrent", js)
        self.assertIn("windows.remove", js)
        self.assertIn("enshrouded-embed", js)
        self.assertIn("Autorizar", js)


if __name__ == "__main__":
    unittest.main()
