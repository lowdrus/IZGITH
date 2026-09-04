from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXT = ROOT / 'extension'


def test_tool_menus_can_collapse():
    css = (EXT / 'ui' / 'dashboard.css').read_text(encoding='utf-8')
    js = (EXT / 'integrations' / 'enshrouded-manager.js').read_text(encoding='utf-8')
    html = (EXT / 'ui' / 'dashboard.html').read_text(encoding='utf-8')
    assert '[hidden]{display:none!important}' in css
    assert 'providerMenuButton' in js and 'githubMenuButton' in js
    assert "m.hidden=!open" in js
    assert 'id="providerMenu"' in html and 'id="githubMenu"' in html


def test_enshrouded_manager_screen_is_packaged():
    screen = EXT / 'ui' / 'enshrouded.html'
    screen_js = EXT / 'ui' / 'enshrouded-manager-screen.js'
    manager = (EXT / 'integrations' / 'enshrouded-manager.js').read_text(encoding='utf-8')
    assert screen.is_file()
    assert screen_js.is_file()
    assert "chrome.tabs.create({url:chrome.runtime.getURL('ui/enshrouded.html'),active:true})" in manager
    assert 'ENSHROUDED MANAGER' in screen.read_text(encoding='utf-8')
