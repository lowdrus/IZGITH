# Rodada 00068 — Menu Hardening + Enshrouded Manager

## Correções

- CONV-D e UPPER GITHUB agora têm controlador de menu com alternância única.
- O handler do botão é instalado em fase de captura e bloqueia handlers legados que poderiam abrir/fechar duas vezes.
- Clique fora fecha o menu.
- `Escape` fecha o menu.
- `aria-expanded` e o estado visual são mantidos sincronizados.
- Menus recebem ancoragem relativa ao card e limite de altura para não ficarem soltos sobre a grade.

## ENSHROUDED MANAGER

- Mantida a tela dedicada em `extension/ui/enshrouded.html`.
- O botão ao lado de **ENSHROUDED MANAGER** usa o desenho de maximizar/abrir em nova tela e abre a tela interna do IZGITH em nova aba.
- A integração permanece `browser-plan-only` e não inicia Docker, Wine, SteamCMD ou processos externos.
- A documentação foi alinhada ao README atual do projeto de referência `lincolnthalles/enshrouded-container`.

## Validação

A suíte deve verificar Manifest V3, service worker, integrações, versões, menus colapsáveis e empacotamento. A validação de runtime de Windows/Docker continua fora do escopo do navegador.
