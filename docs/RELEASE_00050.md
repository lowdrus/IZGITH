# IZGITH 00050 — Integration Verification

## Objetivo
Rodada de verificacao de integracao e sincronizacao, preservando o gate de estabilidade das rodadas anteriores.

## Contratos
- Manifest V3 com service worker declarado e existente.
- Versoes sincronizadas entre `extension/manifest.json`, `package.json` e `integrations/assistant_registry.json`.
- Assistentes canonicos: **Júlia**, **Ayella**, **IZART**.
- `Ayelle`, `alias Ayella` e `Alias: Ayella` permanecem nomes proibidos.
- Empacotamento e testes continuam delegados aos scripts oficiais do repositorio.

## Integracoes preservadas
- SONPEF
- CONVGPT
- KIT_UNICO
- CHAT_HISTORY

## Validacao
O CI deve executar `npm test` e o empacotamento definido no workflow antes de considerar a rodada concluida.

## Nota de recuperacao
Arquivos historicos que nao estejam presentes no repositorio nao sao inventados ou reconstruidos como se fossem originais. Quando disponiveis, devem ser incorporados preservando sua procedencia.
