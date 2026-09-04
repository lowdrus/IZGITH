# IZGITH

Extensao Chrome Manifest V3 para baixar, preparar e auditar pacotes de extensoes Chromium com seguranca. O IZGITH reune em um unico produto o popup, a fila, o painel de controle, o monitor de releases publicas do GitHub e ferramentas locais de preparação.

## Estado atual - 6.0.0.00065

A linha atual preserva a referencia visual `IZGITH_v6.0.0.00034_Full_Build` e usa **Ultra + Controlado unificados** como modo padrao. O usuario ainda pode selecionar `Controlado` ou `Ultra` individualmente em Configuracoes.

A ordem fixa da interface e: **Painel Geral -> Ferramentas -> Servidores -> Configuracoes -> Logs -> Temas**. No rodape ficam **EULA** e **Guia Rapido**.

## O que funciona

- download HTTP/HTTPS com confirmacao de destino;
- fila local de arquivos ZIP/CRX;
- auditoria de `manifest.json` com pontuacao explicavel;
- extracao protegida contra ZIP Slip e links simbolicos;
- preparacao de ZIP e CRX2/CRX3;
- laboratorio isolado em perfil temporario do Chrome/Chromium;
- monitor de releases publicas do GitHub;
- 36 temas com profundidades 2D/3D/4D;
- CI, CodeQL, testes, pacote ZIP e releases automaticas;
- integracoes registradas para SONPEF, CONV-D e KIT_UNICO;
- assistentes registrados: Julia, Ayella e IZART;
- **ENSHROUDED MANAGER** com perfis, validacao, planos de operacao e geracao de configuracao/compose.

## Native Messaging e execucao externa

Native Messaging nao e requisito para abrir a extensao. A camada atual e local e deliberadamente nao inicia processos externos silenciosamente.

Uma extensao Chromium nao pode instalar/registrar ou iniciar silenciosamente um executavel Windows, Docker Desktop, Wine, Steam ou outro processo arbitrario. Por isso o ENSHROUDED MANAGER atual prepara e audita planos, configuracoes e artefatos. A execucao real de um runtime externo requer uma ponte local autorizada pelo sistema operacional.

## ENSHROUDED MANAGER

O modulo foi desenhado a partir de conceitos publicos do projeto `lincolnthalles/enshrouded-container`, incluindo version pinning, instalacao, start/stop, backups live/cold/emergency, retencao, restore, mods e polling de recursos. A referencia e documentada em `docs/ENSHROUDED_MANAGER.md`.

## Instalacao rapida no Google Chrome

1. Baixe o pacote `IZGITH-extension` da aba **Actions** ou da pagina **Releases**.
2. Extraia o ZIP para uma pasta permanente, por exemplo `C:\IZGITH\extension`.
3. Abra `chrome://extensions`.
4. Ative **Modo do desenvolvedor**.
5. Clique em **Carregar sem compactacao** e escolha a pasta que contem `manifest.json`.
6. Fixe o IZGITH na barra do Chrome e abra o popup.

O popup funciona sem programas adicionais.

## Desenvolvimento

Requisitos: Python 3.11+ e Node.js 24+.

```bash
python scripts/validate_project.py
python -m unittest discover -s tests -v
npm test
npm run package
```

O pacote e criado em `dist/`. Nenhuma dependencia npm e necessaria.

## Estrutura

- `extension/`: unica extensao distribuivel do IZGITH.
- `integrations/`: registros de SONPEF, CONV-D, KIT_UNICO e ENSHROUDED MANAGER.
- `scripts/`: validacao e empacotamento.
- `tests/`: testes unitarios e de integracao estatica.
- `docs/`: tutorial, arquitetura e especificacoes.
- `archive/legacy/`: fontes historicas incorporadas, fora do build.

## Seguranca e privacidade

O projeto nao requer token do GitHub para consultar releases publicas e nao armazena credenciais. Leia `SECURITY.md` e `docs/PRIVACIDADE.md`.

## Licenca

Consulte `LICENSE`. Fontes historicas mantem suas proprias licencas e nao sao incluidas no pacote final.
