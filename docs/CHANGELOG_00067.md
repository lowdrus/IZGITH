# CHANGELOG — 00067

## Correções

- corrigido o comportamento de abertura/fechamento do menu de **CONV-D**;
- corrigido o comportamento de abertura/fechamento do menu de **UPPER GITHUB**;
- menus agora fecham ao clicar fora e mantêm `aria-expanded` sincronizado;
- adicionado controlador dedicado `extension/ui/menu-fix.js` para impedir dupla alternância e clipping visual;
- cards podem manter menus visíveis sem serem cortados pelo container;
- root manifest e extension manifest sincronizados em `6.0.0.67`;
- pacote NPM sincronizado em `6.0.0-00067`;
- documentação de carregamento do Chrome reforçada para evitar o erro de manifesto ausente.

## Documentação

- Guia Rápido atualizado;
- EULA atualizado;
- CONV-D atualizado;
- Enshrouded Manager revisado contra a referência declarada;
- README atualizado;
- esta rodada registrada para auditoria.

## ENSHROUDED MANAGER

O módulo permanece deliberadamente sem execução silenciosa de Docker/Wine/SteamCMD. A referência `lincolnthalles/enshrouded-container` foi revisada e os dados relevantes foram atualizados na documentação do IZGITH.

## Critério de aceite

A rodada só deve ser considerada concluída quando `npm test` e `npm run package` passarem e o ZIP resultante tiver `manifest.json` diretamente na raiz.
