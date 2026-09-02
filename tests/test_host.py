import json,tempfile,unittest,zipfile
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'host-python'))
import ext_host
class HostTests(unittest.TestCase):
    def test_manifest_score(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d);(p/'manifest.json').write_text(json.dumps({'manifest_version':3,'name':'x','version':'1','permissions':['tabs'],'host_permissions':[]}),encoding='utf-8');r=ext_host.analyze_manifest(d);self.assertTrue(r['ok']);self.assertEqual(r['score'],92)
    def test_zip_slip_blocked(self):
        with tempfile.TemporaryDirectory() as d:
            z=Path(d)/'bad.zip'
            with zipfile.ZipFile(z,'w') as a:a.writestr('../escape.txt','x')
            r=ext_host.prepare_package(str(z));self.assertFalse(r['ok']);self.assertIn('unsafe ZIP member',r['error'])
    def test_prepare_zip(self):
        with tempfile.TemporaryDirectory() as d:
            z=Path(d)/'ok.zip'
            with zipfile.ZipFile(z,'w') as a:a.writestr('ext/manifest.json',json.dumps({'manifest_version':3,'name':'ok','version':'1'}))
            r=ext_host.prepare_package(str(z));self.assertTrue(r['ok']);self.assertEqual(r['kind'],'zip');self.assertEqual(r['name'],'ok')
    def test_invalid_crx(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'x.crx';p.write_bytes(b'not-crx');r=ext_host.prepare_package(str(p));self.assertFalse(r['ok'])
if __name__=='__main__':unittest.main()
