import json
import tempfile
import unittest
import zipfile
from pathlib import Path

import ext_host


class HostTests(unittest.TestCase):
    def test_analyze_manifest_scores_risky_permissions(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (root / "manifest.json").write_text(json.dumps({
                "manifest_version": 3,
                "name": "Risky",
                "version": "1.0.0",
                "permissions": ["tabs", "debugger"],
                "host_permissions": ["<all_urls>"]
            }), encoding="utf-8")
            result = ext_host.analyze_manifest(str(root))
            self.assertTrue(result["ok"])
            self.assertLess(result["score"], 50)
            self.assertIn("permission:debugger", result["findings"])

    def test_safe_extract_rejects_zip_slip(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            archive = root / "bad.zip"
            with zipfile.ZipFile(archive, "w") as zf:
                zf.writestr("../escape.txt", "bad")
            with self.assertRaises(ValueError):
                ext_host._safe_extract(archive, root / "out")

    def test_safe_extract_and_find_manifest(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            archive = root / "good.zip"
            with zipfile.ZipFile(archive, "w") as zf:
                zf.writestr("sample/manifest.json", json.dumps({"manifest_version": 3, "name": "Good", "version": "1.0.0"}))
            out = ext_host._safe_extract(archive, root / "out")
            result = ext_host.analyze_manifest(str(out))
            self.assertTrue(result["ok"])
            self.assertEqual(result["name"], "Good")


if __name__ == "__main__":
    unittest.main()
