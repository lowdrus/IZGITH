# IZGITH

Extensão Chrome Manifest V3 para preparação, auditoria, exportação local e organização de ferramentas. A árvore reúne popup, fila, painel geral, Central De Ferramentas, CONV-D, SONPEF, KIT_UNICO e ENSHGERENC.

## Estado atual — 6.0.0.00073

A interface usa **Ultra + Controlado — Unificado** como padrão, com `Controlado` e `Ultra` disponíveis. A navegação é **Painel Geral → Ferramentas → Servidores → Configurações → Logs → Temas**, com EULA e Guia Rápido no rodapé.

## Funcionalidades

- download HTTP/HTTPS com diálogo de salvamento;
- fila local de arquivos ZIP/CRX;
- auditoria e validação de Manifest V3;
- proteção contra ZIP Slip;
- preparação de ZIP/CRX;
- 36 temas com profundidades 2D/3D/4D;
- CI, testes, CodeQL e empacotamento;
- SONPEF, CONV-D, KIT_UNICO e ENSHGERENC;
- assistentes IZART, Ayella e Júlia no Painel Geral;
- UPPER URL, UPPER GITHUB e F-SNC;
- menus de CONV-D e UPPER GITHUB com abertura/fechamento determinístico e fechamento ao clicar fora.

## Carregamento correto no Chrome

O repositório possui uma árvore de desenvolvimento e uma árvore de extensão. Para **Carregar sem compactação**, selecione a pasta:

`IZGITH/extension/`

Essa pasta contém diretamente `manifest.json`, `sw.js`, `ui/`, `assets/` e `integrations/`.

O `manifest.json` da raiz também é mantido como uma entrada **root-loadable** para ferramentas que precisam iniciar pelo diretório do repositório. O pacote oficial do CI, entretanto, é gerado a partir de `extension/` e coloca `manifest.json` na raiz do ZIP.

## CONV-D

CONV-D adiciona **Baixar Conversa** às páginas de provedores suportados quando o conteúdo da conversa é acessível ao content script. O usuário escolhe o escopo e o formato antes do salvamento.

Escopos: **Tudo** ou **Ultima Rodada**.

Formatos: PDF, Word `.doc`, TXT, Markdown `.md`, JSON estruturado e Excel `.xls`, conforme o adaptador/implementação disponível.

## F-SNC

F-SNC é um capturador de referência no contexto da conversa. Ao clicar, identifica a página/provedor suportado e registra localmente o **último turno de conteúdo encontrado**, incluindo URL, host, título, papel e texto. O service worker mantém a captura em `chrome.storage.local` para posterior uso explícito por uma rotina de publicação.

Por segurança, a extensão **não coleta tokens, cookies ou credenciais e não executa `git push --force` silenciosamente**. Publicação em GitHub exige uma ação/autenticação explícita fora do capturador. Isso evita transformar uma página de conversa em um canal de exfiltração de credenciais.

## Menus

Os menus são controles de estado locais. O ícone abre e fecha a lista, `aria-expanded` acompanha o estado e um clique fora recolhe o menu. O controlador `extension/ui/menu-fix.js` é carregado depois do dashboard para impedir dupla alternância causada por listeners antigos.

## ENSHGERENC

O módulo mantém perfis e prepara informações de servidores. A referência técnica declarada é `lincolnthalles/enshrouded-container`, que documenta Docker 24+, Fedora 44 + Wine 11, versionamento por manifest, mods, backups, polling e variáveis `ENSHROUDED_*`. O IZGITH não inicia processos externos silenciosamente.

## Segurança

Native Messaging não é requisito do baseline. Credenciais, cookies, tokens e chaves privadas não devem ser colocados no dashboard nem versionados. Publicações em GitHub devem usar autenticação explícita e permissões apropriadas.

## Validação

Requisitos: Python 3.11+ e Node.js 24+.

```text
python scripts/validate_project.py
python -m unittest discover -s tests -v
npm test
npm run package
```

O CI deve validar primeiro e só depois gerar o ZIP. O artefato distribuível é construído a partir de `extension/` para evitar o erro histórico de ZIP com `manifest.json` em subpasta.

## Estrutura

- `extension/` — árvore distribuível e diretamente carregável.
- `integrations/` — contratos de integração.
- `scripts/` — validação e empacotamento.
- `tests/` — testes.
- `docs/` — documentação ativa e histórica.
- `archive/legacy/` — material legado preservado.

## Licença

Consulte `LICENSE` e a documentação correspondente às fontes históricas.
