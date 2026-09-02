# IZGITH

Extensão Chrome Manifest V3 para baixar, preparar e auditar pacotes de extensões Chromium com segurança. O IZGITH reúne em um único produto o popup, a fila, o painel de controle, o monitor de releases públicas do GitHub e um host local opcional em Python.

## O que funciona

- download HTTP/HTTPS com confirmação de destino;
- fila local de arquivos ZIP/CRX;
- auditoria de `manifest.json` com pontuação explicável;
- extração protegida contra ZIP Slip e links simbólicos;
- preparação de ZIP e CRX2/CRX3;
- laboratório isolado em perfil temporário do Chrome/Chromium;
- monitor de releases públicas do GitHub;
- 36 temas, modo de desempenho e preferências persistentes;
- Chrome, Edge, Brave e Chromium, conforme o sistema operacional;
- CI, CodeQL, testes, pacote ZIP e releases automáticas.

> O Chrome não permite que uma extensão comum instale silenciosamente outra extensão no perfil principal. O IZGITH prepara, audita e abre extensões em um perfil isolado; a instalação definitiva usa o fluxo oficial “Carregar sem compactação”.

## Instalação rápida no Google Chrome

1. Baixe o ZIP `IZGITH-extension` da aba **Actions** ou da página **Releases**.
2. Extraia o ZIP para uma pasta permanente, por exemplo `C:\IZGITH\extension`.
3. Abra `chrome://extensions`.
4. Ative **Modo do desenvolvedor**.
5. Clique em **Carregar sem compactação** e escolha a pasta que contém `manifest.json`.
6. Fixe o IZGITH na barra do Chrome e abra o popup.

O popup funciona sem programas adicionais. Para auditoria local, CRX/ZIP e laboratório isolado, siga [docs/TUTORIAL_INSTALACAO_E_USO.md](docs/TUTORIAL_INSTALACAO_E_USO.md).

## Desenvolvimento

Requisitos: Python 3.11+ e Node.js 24+.

```bash
python scripts/validate_project.py
python -m unittest discover -s tests -v
npm test
npm run package
```

O pacote é criado em `dist/`. Nenhuma dependência npm é necessária.

## Estrutura

- `extension/` (Manifest V3 v6 CLEAN CORE): única extensão distribuível do IZGITH.
- `host/`: host Native Messaging e instaladores.
- `scripts/`: validação e empacotamento.
- `tests/`: testes unitários e de integração estática.
- `docs/`: tutorial, arquitetura e especificação.
- `archive/legacy/`: fontes históricas incorporadas, fora do build.

Consulte [docs/AUDITORIA_DO_LEGADO.md](docs/AUDITORIA_DO_LEGADO.md) para saber exatamente o que foi preservado, removido e efetivamente integrado.

## Segurança e privacidade

O projeto não requer token do GitHub para consultar releases públicas e não armazena credenciais. Leia [SECURITY.md](SECURITY.md) e [docs/PRIVACIDADE.md](docs/PRIVACIDADE.md).

## Licença

Consulte [LICENSE](LICENSE). Fontes históricas mantêm suas próprias licenças e não são incluídas no pacote final.
