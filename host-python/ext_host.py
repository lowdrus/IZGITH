#!/usr/bin/env python3
"""IZGITH Native Messaging host and local CLI.

Never installs an extension silently into the main browser profile. It prepares and
audits packages and can launch unpacked extensions in an isolated Chromium profile.
"""
from __future__ import annotations
import argparse,json,os,shutil,struct,subprocess,sys,tempfile,zipfile
from pathlib import Path
from typing import Any
HOST_NAME='com.izgith.host'
MAX_ARCHIVE_FILES=10_000
MAX_ARCHIVE_BYTES=512*1024*1024

def _safe_extract_archive(archive: zipfile.ZipFile,destination: Path)->Path:
    destination=destination.resolve();destination.mkdir(parents=True,exist_ok=True)
    members=archive.infolist()
    if len(members)>MAX_ARCHIVE_FILES:raise ValueError(f'archive has more than {MAX_ARCHIVE_FILES} files')
    if sum(member.file_size for member in members)>MAX_ARCHIVE_BYTES:raise ValueError('uncompressed archive is larger than 512 MiB')
    for member in members:
        target=(destination/member.filename).resolve()
        if target!=destination and destination not in target.parents: raise ValueError(f'unsafe ZIP member: {member.filename}')
        mode=(member.external_attr>>16)&0o170000
        if mode==0o120000: raise ValueError(f'symlink is not allowed: {member.filename}')
    archive.extractall(destination);return destination

def _safe_extract(zip_path:Path,destination:Path)->Path:
    with zipfile.ZipFile(zip_path) as archive:return _safe_extract_archive(archive,destination)

def _crx_zip_offset(data:bytes)->int:
    if len(data)<12:raise ValueError('CRX header is incomplete')
    if data[:4]!=b'Cr24': raise ValueError('invalid CRX magic')
    version=int.from_bytes(data[4:8],'little')
    if version==3:
        header=int.from_bytes(data[8:12],'little');offset=12+header
    elif version==2:
        pub=int.from_bytes(data[8:12],'little');sig=int.from_bytes(data[12:16],'little');offset=16+pub+sig
    else: raise ValueError(f'unsupported CRX version {version}')
    if offset<0 or offset+4>len(data) or data[offset:offset+4]!=b'PK\x03\x04': raise ValueError('CRX ZIP payload not found')
    return offset

def _extract_crx(path:Path,destination:Path)->Path:
    import io
    data=path.read_bytes();offset=_crx_zip_offset(data)
    with zipfile.ZipFile(io.BytesIO(data[offset:])) as archive:return _safe_extract_archive(archive,destination)

def _find_manifest(root:Path)->Path|None:
    direct=root/'manifest.json'
    if direct.is_file():return direct
    candidates=[p for p in root.rglob('manifest.json') if len(p.relative_to(root).parts)<=3]
    return candidates[0] if len(candidates)==1 else None

def pick_directory(title='Selecione a pasta da extensão')->str|None:
    import tkinter as tk
    from tkinter import filedialog
    root=tk.Tk();root.withdraw();root.attributes('-topmost',True)
    try:selected=filedialog.askdirectory(title=title,mustexist=True)
    finally:root.destroy()
    return selected or None

def pick_package(title='Selecione um pacote .zip ou .crx')->str|None:
    import tkinter as tk
    from tkinter import filedialog
    root=tk.Tk();root.withdraw();root.attributes('-topmost',True)
    try:selected=filedialog.askopenfilename(title=title,filetypes=[('Extensões Chromium','*.zip *.crx'),('ZIP','*.zip'),('CRX','*.crx'),('Todos','*.*')])
    finally:root.destroy()
    return selected or None

def analyze_manifest(path:str)->dict[str,Any]:
    target=Path(path).expanduser().resolve();manifest=target if target.name=='manifest.json' else (_find_manifest(target) if target.is_dir() else None)
    if not manifest or not manifest.is_file():return {'ok':False,'error':'manifest.json not found'}
    try:data=json.loads(manifest.read_text(encoding='utf-8'))
    except (OSError,json.JSONDecodeError) as exc:return {'ok':False,'error':f'invalid manifest: {exc}'}
    permissions=list(data.get('permissions') or []);hosts=list(data.get('host_permissions') or []);risk=0;findings=[]
    weighted={'debugger':40,'proxy':30,'webRequestBlocking':25,'history':15,'tabs':8,'cookies':15,'management':18,'nativeMessaging':12,'downloads':5}
    for perm,weight in weighted.items():
        if perm in permissions:risk+=weight;findings.append(f'permission:{perm}')
    if '<all_urls>' in hosts:risk+=25;findings.append('host:<all_urls>')
    remote=[v for v in hosts if v.startswith(('http://','https://'))]
    if remote:risk+=min(15,3*len(remote));findings.append(f'remote_hosts:{len(remote)}')
    mv=data.get('manifest_version')
    if mv!=3:risk+=20;findings.append(f'manifest_version:{mv}')
    return {'ok':True,'manifest':str(manifest),'path':str(manifest.parent),'name':data.get('name','unnamed'),'version':data.get('version','unknown'),'manifest_version':mv,'score':max(0,100-min(risk,100)),'findings':findings,'permissions':permissions,'host_permissions':hosts}

def prepare_package(path:str)->dict[str,Any]:
    source=Path(path).expanduser().resolve()
    if source.is_dir():
        result=analyze_manifest(str(source));result['kind']='directory';return result
    if not source.is_file():return {'ok':False,'error':'package not found'}
    if source.suffix.lower() not in {'.zip','.crx'}:return {'ok':False,'error':'only .zip or .crx packages are supported'}
    destination=Path(tempfile.mkdtemp(prefix='izgith-package-'))
    try:
        if source.suffix.lower()=='.zip':_safe_extract(source,destination);kind='zip'
        else:_extract_crx(source,destination);kind='crx'
        manifest=_find_manifest(destination)
        if not manifest:
            shutil.rmtree(destination,ignore_errors=True)
            return {'ok':False,'kind':kind,'error':'manifest.json not found after extraction'}
        result=analyze_manifest(str(manifest.parent));result.update({'kind':kind,'source':str(source),'path':str(manifest.parent)});return result
    except (OSError,ValueError,zipfile.BadZipFile) as exc:
        shutil.rmtree(destination,ignore_errors=True);return {'ok':False,'error':str(exc)}

def detect_browser()->str|None:
    if sys.platform=='win32':
        roots=[os.environ.get('PROGRAMFILES'),os.environ.get('PROGRAMFILES(X86)'),os.environ.get('LOCALAPPDATA')]
        candidates=[]
        for root in filter(None,roots):
            b=Path(root);candidates += [b/'Google/Chrome/Application/chrome.exe',b/'Microsoft/Edge/Application/msedge.exe',b/'BraveSoftware/Brave-Browser/Application/brave.exe']
        return next((str(p) for p in candidates if p.is_file()),None)
    if sys.platform=='darwin':
        candidates=[Path('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'),Path('/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge'),Path('/Applications/Brave Browser.app/Contents/MacOS/Brave Browser')]
        return next((str(p) for p in candidates if p.is_file()),None)
    for binary in ('google-chrome','google-chrome-stable','chromium','chromium-browser','microsoft-edge','brave-browser'):
        found=shutil.which(binary)
        if found:return found
    return None

def launch_sandbox(extension_path:str,browser:str|None=None)->dict[str,Any]:
    extension=Path(extension_path).expanduser().resolve();manifest=_find_manifest(extension) if extension.is_dir() else None
    if not manifest:return {'ok':False,'error':'sandbox requires an unpacked directory containing manifest.json'}
    analysis=analyze_manifest(str(manifest.parent));browser_path=browser or detect_browser()
    if not browser_path:return {'ok':False,'error':'no supported Chromium browser found','analysis':analysis}
    profile=Path(tempfile.mkdtemp(prefix='izgith-sandbox-'));args=[browser_path,f'--user-data-dir={profile}',f'--load-extension={manifest.parent}','--no-first-run','--disable-sync','about:blank'];subprocess.Popen(args,close_fds=(sys.platform!='win32'))
    return {'ok':True,'profile':str(profile),'browser':browser_path,'path':str(manifest.parent),'name':analysis.get('name'),'version':analysis.get('version'),'score':analysis.get('score'),'findings':analysis.get('findings',[])}

def diagnostics()->dict[str,Any]:
    return {'ok':True,'host':HOST_NAME,'python':sys.version.split()[0],'platform':sys.platform,'browser':detect_browser(),'temp':tempfile.gettempdir()}

def handle(message:dict[str,Any])->dict[str,Any]:
    command=message.get('command')
    if command=='ping':return diagnostics()
    if command=='pick_and_analyze':
        selected=pick_directory('Selecione a pasta da extensão para auditoria');return {'ok':False,'cancelled':True} if not selected else analyze_manifest(selected)
    if command=='pick_and_prepare':
        selected=pick_package();return {'ok':False,'cancelled':True} if not selected else prepare_package(selected)
    if command=='pick_and_sandbox':
        selected=pick_directory('Selecione a pasta unpacked para abrir no sandbox');return {'ok':False,'cancelled':True} if not selected else launch_sandbox(selected,message.get('browser'))
    if command=='analyze_manifest':return analyze_manifest(str(message.get('path','')))
    if command=='prepare_package':return prepare_package(str(message.get('path','')))
    if command=='launch_sandbox':return launch_sandbox(str(message.get('path','')),message.get('browser'))
    return {'ok':False,'error':f'unknown command: {command}'}

def read_message()->dict[str,Any]|None:
    raw=sys.stdin.buffer.read(4)
    if not raw:return None
    length=struct.unpack('<I',raw)[0]
    if length>16*1024*1024:raise ValueError('native message too large')
    payload=sys.stdin.buffer.read(length)
    if len(payload)!=length:raise EOFError('incomplete native message')
    return json.loads(payload.decode('utf-8'))

def write_message(message:dict[str,Any])->None:
    payload=json.dumps(message,ensure_ascii=False).encode('utf-8');sys.stdout.buffer.write(struct.pack('<I',len(payload)));sys.stdout.buffer.write(payload);sys.stdout.buffer.flush()

def native_loop()->None:
    while True:
        message=read_message()
        if message is None:break
        try:write_message(handle(message))
        except Exception as exc:write_message({'ok':False,'error':f'host error: {exc}'})

def main()->int:
    parser=argparse.ArgumentParser(description='IZGITH native host');parser.add_argument('--analyze');parser.add_argument('--prepare');parser.add_argument('--sandbox');args=parser.parse_args()
    if args.analyze:result=analyze_manifest(args.analyze)
    elif args.prepare:result=prepare_package(args.prepare)
    elif args.sandbox:result=launch_sandbox(args.sandbox)
    else:native_loop();return 0
    print(json.dumps(result,ensure_ascii=False,indent=2));return 0 if result.get('ok') else 1
if __name__=='__main__':raise SystemExit(main())
