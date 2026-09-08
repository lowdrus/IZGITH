# IZGITH

Extensão Chrome Manifest V3 para preparação, auditoria, exportação local e organização de ferramentas. A árvore reúne popup, fila, painel geral, Central De Ferramentas, CONV-D, SONPEF, KIT_UNICO e **ENSH-GERENC**.

## Estado atual — 6.0.0.00076

A interface usa **Ultra + Controlado — Unificado** como padrão, com `Controlado` e `Ultra` disponíveis. A navegação é **Painel Geral → Ferramentas → Servidores → Configurações → Logs → Temas**, com EULA e Guia Rápido no rodapé.

## Funcionalidades

- download HTTP/HTTPS com diálogo de salvamento;
- fila local de arquivos ZIP/CRX;
- auditoria e validação de Manifest V3;
- proteção contra ZIP Slip;
- preparação de ZIP/CRX;
- 36 temas com profundidades 2D/3D/4D;
- CI, testes, CodeQL e empacotamento;
- SONPEF, CONV-D, KIT_UNICO e ENSH-GERENC;
- assistentes IZART, Ayella e Júlia no Painel Geral;
- UPPER URL, UPPER GITHUB e F-SNC;
- menus de CONV-D e UPPER GITHUB com abertura/fechamento determinístico;
- ENSHGERENC com todos os controles operacionais em um único painel;
- contrato de Runtime Agent allow-listed para execução externa autorizada.

## Carregamento correto no Chrome

Para **Carregar sem compactação**, selecione:

`IZGITH/extension/`

Essa pasta contém diretamente `manifest.json`, `sw.js`, `ui/`, `assets/` e `integrations/`.

O `manifest.json` da raiz também é mantido como entrada root-loadable. O pacote oficial do CI é construído a partir de `extension/` e coloca `manifest.json` na raiz do ZIP.

## CONV-D

CONV-D adiciona **Baixar Conversa** às páginas de provedores suportados quando o conteúdo da conversa é acessível ao content script. O usuário escolhe o escopo e o formato antes do salvamento.

Escopos: **Tudo** ou **Ultima Rodada**.

Formatos: PDF, Word `.doc`, TXT, Markdown `.md`, JSON estruturado e Excel `.xls`, conforme o adaptador/implementação disponível.

## UPPER URL × UPPER GITHUB

São módulos independentes.

- **UPPER URL** abre uma URL HTTPS de conversa indicada pelo usuário e não define o destino de publicação do GitHub.
- **UPPER GITHUB** mantém seu próprio campo de repositório e seu próprio estado/fluxo.
- Nenhum token é solicitado, inferido ou enviado automaticamente.

## ENSH-GERENC / ENSHGERENC

O **ENSHGERENC** concentra em um único painel: Salvar perfil, Validar, Limpar, Baixar Config, Baixar Compose, Baixar Plano, Verificar, Preparar Instalação, Preparar Início, Preparar Parada, Backup, Restaurar, Retenção, Mods, Recursos e Versão.

A referência técnica é `lincolnthalles/enshrouded-container`. O projeto de referência documenta Fedora 44 + Wine 11, Docker 24+, versionamento por manifest, mods, backups, polling de recursos e as variáveis `VERSION`, `BACKUP_*`, `RESOURCE_POLL_INTERVAL` e `ENSHROUDED_*`.

O IZGITH mantém o navegador como plano de controle. Para executar Docker/Wine/SteamCMD de verdade, o ENSHGERENC conversa com um **Runtime Agent autorizado** por um endpoint HTTP allow-listed. O agente exige Bearer token fora do código e não aceita shell arbitrário.

### Runtime Agent

Endpoint padrão: `http://127.0.0.1:38751`.

- `GET /health`
- `POST /v1/operations/servers.validate`
- `POST /v1/operations/profiles.save`
- `POST /v1/operations/server.prepare-install`
- `POST /v1/operations/server.start`
- `POST /v1/operations/server.stop`
- `POST /v1/operations/backup.create`
- `POST /v1/operations/backup.restore`
- `POST /v1/operations/backup.prune`
- `POST /v1/operations/mods.list`
- `POST /v1/operations/resources.read`
- `POST /v1/operations/server.version`

O endpoint detalhado está em `integrations/ENSHROUDED_MANAGER/runtime-agent-endpoint.json`. O contrato geral está em `integrations/ENSHROUDED_MANAGER/runtime-contract.json`.

Para um ambiente remoto real, proteja o agente com TLS/VPN/rede privada. O GitHub armazena o código/contrato; ele não fornece sozinho uma máquina Docker remota para execução.

## Segurança

Native Messaging não é requisito do baseline. Credenciais, cookies, tokens e chaves privadas não devem ser colocados no dashboard nem versionados. O Runtime Agent deve autenticar mutações, validar entradas, registrar auditoria e manter o Docker socket fora do navegador.

## Validação

Requisitos: Python 3.11+ e Node.js 24+.

```text
python scripts/validate_project.py
python -m unittest discover -s tests -v
npm test
npm run package
```

O CI valida primeiro e só depois gera o ZIP. O artefato distribuível é construído a partir de `extension/` para evitar o erro histórico de ZIP com `manifest.json` em subpasta.

## Estrutura

- `extension/` — árvore distribuível e diretamente carregável.
- `integrations/` — contratos de integração.
- `runtime/enshgerenc-agent/` — Runtime Agent remoto autorizado.
- `scripts/` — validação e empacotamento.
- `tests/` — testes.
- `docs/` — documentação ativa e histórica.
- `archive/legacy/` — material legado preservado.

## Licença

Consulte `LICENSE` e a documentação correspondente às fontes históricas.
