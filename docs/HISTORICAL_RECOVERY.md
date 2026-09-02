# IZGITH — recuperação histórica e proveniência

Data da auditoria: 2026-09-02

## Objetivo

Registrar de forma verificável quais fontes do projeto IZGITH estão recuperadas no repositório e quais dependem de reenvio dos arquivos históricos originais da conversa.

## Fontes recuperadas no Git

- `extension/`: código ativo Manifest V3.
- `host/`: Native Messaging e instaladores.
- `scripts/`: validação e empacotamento.
- `tests/`: testes do projeto.
- `docs/`: documentação.
- `archive/legacy/root/`: legado histórico preservado no Git.
- `integrations/KIT_UNICO/`, `integrations/CONVGPT/` e `integrations/SONPEF/`: adaptadores/manifestos de integração.

A auditoria existente registra 616 arquivos históricos preservados em `archive/legacy/root/`, incluindo JavaScript, TypeScript, CSS, Python, filtros, recursos e imagens. Esses arquivos permanecem separados do build distribuível até revisão individual de licença, segurança e compatibilidade MV3.

## KIT_UNICO / CONVGPT / SONPEF

O histórico Git contém commits específicos de integração com a mensagem `KIT_UNICO + CONVGPT + SONPEF`. A integração atual registra:

- KIT_UNICO: `integrations/KIT_UNICO/integration.json` — fonte histórica marcada como `audited-source` e ativação por função.
- SONPEF: `integrations/SONPEF/integration.json` — adaptador preparado, apontando para a camada de assistentes e para o legado.
- CONVGPT: `integrations/CONVGPT/integration.json` — adaptador preparado para `chat_history_bridge.js`, com privacidade local.

O núcleo de assistentes do histórico Git também registra Júlia, Ayelle (alias Ayella) e IZART como papéis distintos/unificados na arquitetura.

## Limitação importante

Os ZIPs/arquivos anexados originalmente na conversa não estão atualmente disponíveis como bytes recuperáveis nesta sessão. Portanto, **não é correto afirmar que o conteúdo exato desses anexos foi reconstruído byte a byte**. O que pode ser recuperado sem reenvio é o material que já foi preservado no Git e no histórico de commits.

Arquivos históricos específicos como o `sonpef_unify.ps1`, versões exatas do `chat_history_bridge.js` anexadas na conversa e o conteúdo completo original do KIT_UNICO só devem ser promovidos para o código ativo depois que seus arquivos originais forem novamente disponibilizados ou quando uma cópia verificável estiver presente no Git.

## Regra de reconstrução

1. Priorizar o arquivo original recuperado.
2. Preservar nome, conteúdo e licença quando possível.
3. Não substituir uma fonte histórica por uma implementação inventada sem marcar a diferença.
4. Integrar função por função em Manifest V3, com testes.
5. Manter o legado fora do pacote distribuível até a auditoria de segurança/licença.
6. Nunca registrar tokens, cookies, credenciais ou exportações pessoais no repositório.

## Estado atual

O repositório já possui uma base ativa `v6.0.0.00039 CLEAN CORE`, com Manifest V3, service worker, host Python, scripts de validação/empacotamento, 36 temas declarados e estruturas de integração para KIT_UNICO, CONVGPT e SONPEF. O objetivo desta página é impedir que fontes históricas ausentes sejam tratadas como se estivessem integralmente recuperadas.
