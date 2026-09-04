# CHANGELOG — Rodada 00067

## Correções

- Corrigido o comportamento visual dos menus de **UPPER GITHUB** e **CONV-D**.
- Corrigida a causa estrutural que fazia menus com `hidden` permanecerem visíveis: a regra de layout agora contém `.provider-list[hidden]{display:none!important}`.
- Menus passaram a ser ancorados ao próprio card, evitando listas soltas em relação ao módulo correspondente.
- Mantido o fechamento por clique fora do menu e o estado `aria-expanded` para acessibilidade.
- Adicionada validação estática específica para a regra de colapso dos menus.

## Documentação

- README atualizado para 6.0.0.00067.
- Guia Rápido atualizado.
- EULA atualizado.
- ENSHROUDED MANAGER revisado contra a documentação pública atual do projeto de referência.

## Enshrouded Manager

O IZGITH permanece como camada **browser-plan-only**: prepara perfis, configurações e planos, mas não inicia Docker, Wine, SteamCMD ou processos do sistema silenciosamente. A referência técnica é `lincolnthalles/enshrouded-container`.

## Validação

A validação da rodada cobre Manifest V3, service worker, sintaxe JavaScript, HTML/CSS, ícones, 36 temas, integrações, assistentes, sincronização de versões, menus e controles da interface.
