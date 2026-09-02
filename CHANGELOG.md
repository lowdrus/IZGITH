# Changelog

## 4.4.0
- Estrutura consolidada em `extension/`, `host-python/`, `tools/`, `docs/` e `archive/recovery/`.
- Dashboard conectado ao Native Messaging host.
- Picker nativo de ZIP/CRX e pasta.
- Preparação de CRX2/CRX3 e ZIP com proteção contra traversal/symlink.
- Secure Lab acessível pelo dashboard.
- Instalador Windows ajustado para gerar executável real do Native Host com PyInstaller.
- CI/CD atualizado para os novos caminhos.
- Especificação da conversa consolidada em `docs/PROJECT_SPEC.md`.
# 4.4.0 — núcleo consolidado

- Uma única extensão distribuível em `extension/`, Manifest V3.
- Host Native Messaging conectado ao dashboard.
- Extração ZIP/CRX endurecida contra traversal, symlink e arquivos expansivos.
- Fontes legadas organizadas fora do build; pacotes inválidos e dados pessoais removidos.
- CI e Release migrados para actions com runtime Node.js 24.
- CodeQL v4 com raízes explícitas para JavaScript e Python.
- Tutorial completo em português e validação local sem dependências npm.
