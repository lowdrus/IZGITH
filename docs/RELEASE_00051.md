# IZGITH 00051 — Functional Integration

## Objetivo
Rodada de endurecimento da integracao para que o contrato de versao e o contrato de nomes dos assistentes sejam validados de forma consistente.

## Alteracoes
- package.json sincronizado para 6.0.0-00051.
- extension/manifest.json sincronizado para 6.0.0.51.
- integrations/assistant_registry.json sincronizado para 6.0.0.00051.
- service worker sincronizado para 00051.
- nome canonico do assistente Ayella mantido sem alias.
- validador passou a verificar tambem o service worker contra os aliases proibidos.
- SONPEF, CONVGPT e KIT_UNICO continuam sendo tratados como integracoes distintas.
- Native Messaging continua opcional no boot; a indisponibilidade do host nao deve impedir a inicializacao da extensao.

## Gate
O comando de validacao permanece:

    npm test

A rodada somente deve ser considerada concluida depois que o GitHub Actions finalizar com sucesso para o commit desta rodada.

## Proxima etapa
00052 — verificacao funcional das integracoes, mantendo mudancas pequenas e testaveis.
