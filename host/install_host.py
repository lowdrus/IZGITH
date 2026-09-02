#!/usr/bin/env python3
from __future__ import annotations
import argparse,json,os,platform,subprocess,sys
from pathlib import Path
HOST_NAME='com.izgith.host'
def extension_origin(extension_id:str)->str:
    value=extension_id.strip().lower()
    if len(value)!=32 or any(ch not in 'abcdefghijklmnop' for ch in value):raise ValueError('extension ID must contain 32 characters in the range a-p')
    return f'chrome-extension://{value}/'
def unix_launcher(root:Path)->Path:
    launcher=root/'izgith_host.sh';launcher.write_text(f'#!/bin/sh\nexec "{sys.executable}" "{root/"host.py"}"\n',encoding='utf-8');launcher.chmod(0o755);return launcher
def windows_executable(root:Path)->Path:
    candidates=[root/'dist/izgith_host.exe',root/'izgith_host.exe']
    found=next((p for p in candidates if p.is_file()),None)
    if not found:raise RuntimeError('izgith_host.exe not found. Run installers\\installzipgithub_setup.bat (it builds the host with PyInstaller) or use a release host package.')
    return found
def install(extension_id:str,browser:str)->Path:
    root=Path(__file__).resolve().parent;origin=extension_origin(extension_id);system=platform.system();executable=windows_executable(root) if system=='Windows' else unix_launcher(root)
    manifest={'name':HOST_NAME,'description':'IZGITH local native messaging host','path':str(executable.resolve()),'type':'stdio','allowed_origins':[origin]}
    if system=='Windows':
        manifest_dir=Path(os.environ.get('LOCALAPPDATA',str(root)))/'IZGITH';manifest_dir.mkdir(parents=True,exist_ok=True);manifest_path=manifest_dir/f'{HOST_NAME}.json';manifest_path.write_text(json.dumps(manifest,indent=2),encoding='utf-8');roots={'chrome':r'HKCU\Software\Google\Chrome\NativeMessagingHosts','edge':r'HKCU\Software\Microsoft\Edge\NativeMessagingHosts'};registry=roots.get(browser)
        if not registry:raise ValueError('Windows supports chrome or edge')
        subprocess.run(['reg','add',f'{registry}\\{HOST_NAME}','/ve','/t','REG_SZ','/d',str(manifest_path),'/f'],check=True);return manifest_path
    home=Path.home();roots=({'chrome':home/'Library/Application Support/Google/Chrome/NativeMessagingHosts','edge':home/'Library/Application Support/Microsoft Edge/NativeMessagingHosts','brave':home/'Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts'} if system=='Darwin' else {'chrome':home/'.config/google-chrome/NativeMessagingHosts','chromium':home/'.config/chromium/NativeMessagingHosts','edge':home/'.config/microsoft-edge/NativeMessagingHosts','brave':home/'.config/BraveSoftware/Brave-Browser/NativeMessagingHosts'})
    manifest_dir=roots.get(browser)
    if not manifest_dir:raise ValueError(f'unsupported browser {browser!r} on {system}')
    manifest_dir.mkdir(parents=True,exist_ok=True);manifest_path=manifest_dir/f'{HOST_NAME}.json';manifest_path.write_text(json.dumps(manifest,indent=2),encoding='utf-8');return manifest_path
def main()->int:
    p=argparse.ArgumentParser();p.add_argument('--extension-id',required=True);p.add_argument('--browser',default='chrome',choices=['chrome','chromium','edge','brave']);a=p.parse_args()
    try:path=install(a.extension_id,a.browser)
    except (OSError,ValueError,RuntimeError,subprocess.CalledProcessError) as exc:print(f'ERROR: {exc}',file=sys.stderr);return 1
    print(f'Native host registered: {path}');return 0
if __name__=='__main__':raise SystemExit(main())
