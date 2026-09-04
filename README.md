# IZGITH

Extensão Chrome Manifest V3 para baixar, preparar e auditar pacotes de extensões Chromium com segurança. O IZGITH reúne popup, fila, painel de controle, ferramentas locais, CONV-D, SONPEF, KIT_UNICO e ENSHROUDED MANAGER em uma árvore única.

## Estado atual — 6.0.0.00067 · Rodada 00067

A interface usa **Ultra + Controlado — Unificado** como modo padrão, com `Controlado` e `Ultra` disponíveis separadamente. A navegação principal é **Painel Geral → Ferramentas → Servidores → Configurações → Logs → Temas**, com EULA e Guia Rápido no rodapé.

## O que funciona

- download HTTP/HTTPS com diálogo de salvamento;
- fila local de arquivos ZIP/CRX;
- auditoria de `manifest.json`;
- extração protegida contra ZIP Slip;
- preparação de ZIP e CRX;
- 36 temas com profundidades 2D/3D/4D;
- CI, CodeQL, testes, pacote ZIP e releases;
- SONPEF, CONV-D, KIT_UNICO e ENSHROUDED MANAGER registrados;
- assistentes **IZART, Ayella e Júlia** no painel inicial;
- **UPPER URL** e **UPPER GITHUB** com controles visuais de estado;
- menus de ferramentas ancorados aos respectivos cards e com estado `hidden` efetivo para evitar menus soltos ou impossíveis de recolher.

## CONV-D

O CONV-D adiciona **Baixar Conversa** às plataformas de IA suportadas quando a página fornece conteúdo acessível à extensão. O usuário escolhe `Tudo` ou `Ultima Rodada` e depois o formato de exportação. O salvamento é local e usa o diálogo do navegador.

## Native Messaging e execução externa

Native Messaging **não é requisito** da versão atual. A extensão não instala nem registra executáveis silenciosamente. SONPEF funciona com arquivos selecionados pelo usuário e o ENSHROUDED MANAGER prepara planos/configurações no navegador.

Uma extensão Chromium não deve fingir que pode iniciar Docker, Wine, SteamCMD ou outro processo arbitrário sem uma ponte autorizada pelo sistema operacional. Por isso a camada Enshrouded é deliberadamente `browser-plan-only`.

## ENSHROUDED MANAGER

O módulo mantém perfis, valida host/porta e prepara ações como instalação, início, parada, backup, restauração, retenção, mods, recursos e versão. A composição usa como referência pública `lincolnthalles/enshrouded-container`: Fedora 44 + Wine 11, Docker 24+, version pinning por manifest, mod injection, configuração `ENSHROUDED_*`, backups automáticos e monitoramento de recursos. O IZGITH usa esses dados para preparação e documentação; não copia nem executa o projeto de referência automaticamente.

## Instalação rápida no Chrome

1. Baixe/extraia o pacote da extensão.
2. Abra `chrome://extensions`.
3. Ative **Modo do desenvolvedor**.
4. Clique em **Carregar sem compactação**.
5. Selecione **a pasta `extension/`**, isto é, a pasta que contém diretamente `manifest.json`.
6. Fixe o IZGITH na barra do Chrome e abra o popup.

Se o Chrome disser que o manifesto está ausente, não selecione a raiz do repositório: selecione `extension/`.

## Desenvolvimento e validação

Requisitos: Python 3.11+ e Node.js 24+.

```bash
python scripts/validate_project.py
python -m unittest discover -s tests -v
npm test
npm run package
```

O pacote é criado em `dist/`. A validação inclui Manifest V3, service worker, referências, ícones, 36 temas, integrações, assistentes canônicos, profundidade visual, menus e controles da rodada 00067.

## Estrutura

- `extension/`: extensão distribuível.
- `integrations/`: registros de SONPEF, CONV-D, KIT_UNICO e ENSHROUDED MANAGER.
- `scripts/`: validação e empacotamento.
- `tests/`: testes unitários e estáticos.
- `docs/`: documentação ativa e histórica.
- `archive/legacy/`: material histórico preservado fora do build.

## Segurança e privacidade

Não coloque tokens, cookies, senhas ou chaves privadas no repositório. Operações efetivas de publicação em GitHub exigem autenticação explícita. Leia `SECURITY.md`, `docs/EULA.md` e `docs/PRIVACIDADE.md`.

## Licença

Consulte `LICENSE`. Fontes históricas mantêm suas próprias licenças.
