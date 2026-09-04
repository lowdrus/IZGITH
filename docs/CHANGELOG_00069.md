# CHANGELOG — Rodada 00069

## UI / menus

- Endurecido o posicionamento dos menus de **UPPER GITHUB** e **CONV-D** para permanecerem ancorados aos respectivos cards.
- Mantido o fechamento por clique fora e o estado `aria-expanded`.
- Registrado o problema histórico da rodada 00067: o workflow `IZGITH CI / validate` falhava no check de sincronização da versão do registry.

## Enshrouded Manager

- Adicionado controle de expansão ao lado do título da tela dedicada.
- O controle abre uma nova janela do próprio módulo do IZGITH.
- Mantida a arquitetura browser-plan-only: a extensão prepara dados e planos, mas não executa Docker/Wine/SteamCMD silenciosamente.
- Documentação sincronizada com a referência pública `lincolnthalles/enshrouded-container`.

## Documentação

- Guia Rápido atualizado para 00069.
- EULA atualizado para 00069 e explicitamente informativo, sem bloqueio de uso.
- Documentação do Enshrouded Manager atualizada com parâmetros e limites de responsabilidade.

## Versionamento

- Root manifest: `6.0.0.69`.
- Extension manifest: `6.0.0.69`.
- Package: `6.0.0-00069`.
- Assistant registry: `6.0.0.00069`.

## Validação

A rodada deve passar por Manifest V3, service worker, sintaxe JavaScript, HTML/CSS, ícones, 36 temas, assistentes, integrações, menus, Enshrouded Manager e sincronização de versões.
