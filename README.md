# IZGITH

IZGITH é um hub **offline-first** para download, preparação, auditoria e teste isolado de pacotes de extensões Chromium. A versão atual é **4.4.0**.

## O que funciona
- Extensão Manifest V3 em `extension/`.
- Download HTTP/HTTPS com “Salvar como”.
- Popup com drag & drop, seleção múltipla e fila rápida.
- Dashboard com 36 temas, efeitos 3D e modo performance.
- Dashboard conectado ao Native Messaging host.
- Seleção nativa de pasta e de `.zip/.crx`.
- Preparação segura de ZIP e CRX2/CRX3, com proteção contra path traversal e symlinks.
- Compliance local de `manifest.json` com score explicável.
- Secure Lab: perfil Chromium temporário isolado.
- GitHub Monitor para releases públicas.
- Testes, CI, CodeQL, Dependabot e CD por tags.

> Limite do Chrome: o IZGITH **não instala silenciosamente** extensões no perfil principal. Depois da preparação, use `chrome://extensions` → Modo do desenvolvedor → Carregar sem compactação. Para testar sem tocar no perfil principal, use Secure Lab.

## Estrutura
Veja `docs/ARCHITECTURE.md` e `docs/PROJECT_SPEC.md`.

## Instalação da extensão
1. Clone/baixe o repositório.
2. Abra `chrome://extensions`.
3. Ative **Modo do desenvolvedor**.
4. Clique em **Carregar sem compactação**.
5. Selecione **`extension/`**.
6. Fixe IZGITH na barra.

## Native Host
O popup funciona sem Python. Para pickers nativos, auditoria por caminho, preparação ZIP/CRX e Secure Lab, instale o host.

### Windows
Execute `host-python\installers\installzipgithub_setup.bat`. O script instala PyInstaller no perfil do usuário, compila `izgith_host.exe`, pede o ID da extensão e registra o host para Chrome.

### Linux/macOS
```sh
chmod +x host-python/installers/install_host_unix.sh
host-python/installers/install_host_unix.sh SEU_EXTENSION_ID chrome
```

### CLI
```sh
python3 host-python/ext_host.py --analyze /caminho/extensao
python3 host-python/ext_host.py --prepare pacote.zip
python3 host-python/ext_host.py --sandbox /caminho/extensao
```

## CI/CD
`CI` valida Manifest V3, JS, Python, shell, testes e empacota a extensão. `CodeQL` analisa JS/Python. Tags `vX.Y.Z` geram release com ZIP da extensão, host-source e checksums.

## Segurança
Não versione `.pem`, tokens ou segredos. Pacotes externos não são executados durante a preparação. Prefira Secure Lab para código desconhecido.
