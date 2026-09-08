# IZGITH 6.0.0.00075 — ENSH-GERENC + Runtime Boundary

## Entregas

- Card de servidores renomeado visualmente para **ENSH-GERENC**.
- Todos os controles do gerenciador foram agrupados no card: perfil, validação, limpeza, downloads de configuração/Compose/plano e ações operacionais.
- UPPER URL e UPPER GITHUB foram separados: cada módulo possui estado e destino próprios.
- ENSH-GERENC recebeu uma fronteira de runtime remoto autorizado.
- Runtime Agent implementado em `runtime/enshgerenc-agent/app.py` com Bearer token obrigatório, operações allow-listed e sem shell arbitrário.
- Contrato de runtime atualizado para v2.
- Documentação do README, Guia Rápido e EULA atualizada.
- Versões sincronizadas para `6.0.0.00075`.

## Referência Enshrouded

O gerenciador permanece alinhado conceitualmente ao projeto `lincolnthalles/enshrouded-container`: Docker + Wine/Steam/DepotDownloader, versionamento por manifest, backups, mods, polling e configuração por `ENSHROUDED_*`.

## Limites de execução

O navegador não executa Docker, Wine ou SteamCMD. A execução real ocorre somente quando um Runtime Agent autorizado e administrado pelo usuário estiver disponível.

## Critério de aceite

`python scripts/validate_project.py`, `python -m unittest discover -s tests -v` e `npm test` devem passar antes do empacotamento.
