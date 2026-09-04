# IZGITH 6.0.0.00065 — Rodada 00066

## Objetivo

Estabilizar a Central De Ferramentas, eliminar menus soltos, tornar os controles de estado claros e registrar a arquitetura do Enshrouded Manager sem introduzir execução silenciosa de processos externos.

## Alterações

- **UPPER GITHUB**
  - Menu agora fica ancorado ao próprio card.
  - Ações do menu permanecem agrupadas e fecham corretamente ao clicar fora.
  - Adicionado controle de energia com ícone de power e estado `ON/OFF` do módulo.
  - O estado não finge disponibilidade de Native Messaging: a instalação atual continua sem `nativeMessaging`.
- **UPPER URL**
  - Controle de FORSE-SINC foi convertido para ícone de power no cabeçalho do card.
  - Estado persistido em `chrome.storage.local` como `ON/OFF`.
- **CONV-D**
  - Menu de plataformas permanece ao lado do ícone de informação e dentro do fluxo do card.
  - Exportação continua local, com escolha explícita de formato e diálogo de salvamento.
- **Cards**
  - Cards de ferramentas receberam dimensões compactas e posicionamento relativo para impedir menus “soltos”.
- **Validação**
  - `scripts/validate_project.py` ganhou gates para menus, controles de energia, controles de janela e documentação.
- **Documentação**
  - EULA, Guia Rápido e documentação do Enshrouded Manager foram alinhados com a arquitetura atual.

## Enshrouded Manager

A implementação atual é deliberadamente **browser-plan-only**: perfis, validações, composição de configuração e planos de operação são preparados dentro do IZGITH, mas o dashboard não inicia Docker, Wine, SteamCMD ou outro processo externo silenciosamente. A referência funcional usada para a composição é `lincolnthalles/enshrouded-container`, cujo compose atual usa `ghcr.io/lincolnthalles/enshrouded-container:latest`, `network_mode: host`, volumes persistentes e variáveis como `VERSION`, `BACKUP_CRON` e `ENSHROUDED_*`.

## Critério de aceite

A rodada só é considerada pronta quando `npm test` / `python scripts/validate_project.py` passar integralmente e o Manifest V3 continuar carregável a partir da pasta `extension/`.
