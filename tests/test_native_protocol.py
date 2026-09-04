import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]

class NativeProtocolTests(unittest.TestCase):
    def command(self):
        return [os.environ['IZGITH_TEST_HOST_BINARY']] if os.environ.get('IZGITH_TEST_HOST_BINARY') else [sys.executable,str(ROOT/'host/host.py')]

    def test_real_process_handshake_and_diagnostics(self):
        messages=[{'command':'ping','requestId':1},{'command':'git_diagnostics','requestId':2}]
        request=b''
        for m in messages:
            b=json.dumps(m).encode();request+=struct.pack('<I',len(b))+b
        result=subprocess.run([*self.command(),'chrome-extension://'+'a'*32+'/','--parent-window=0'],input=request,capture_output=True,timeout=60)
        self.assertEqual(result.returncode,0,result.stderr.decode(errors='replace'))
        data=result.stdout;responses=[]
        while data:
            self.assertGreaterEqual(len(data),4)
            size=struct.unpack('<I',data[:4])[0];self.assertLessEqual(size,1024*1024)
            self.assertGreaterEqual(len(data),size+4)
            responses.append(json.loads(data[4:4+size]));data=data[4+size:]
        self.assertEqual(len(responses),2)
        self.assertEqual(responses[0]['host'],'com.izgith.host')
        self.assertEqual(responses[0]['publisher_protocol'],1)
        self.assertEqual(responses[1]['requestId'],2)
        self.assertFalse(responses[1]['tools']['write_access_verified'])
        self.assertNotIn('token',json.dumps(responses).lower())

    def test_truncated_header_fails_without_success_response(self):
        result=subprocess.run(self.command(),input=b'\x05',capture_output=True,timeout=60)
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(result.stdout,b'')

if __name__=='__main__':unittest.main()
