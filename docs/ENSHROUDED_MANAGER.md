# Enshrouded Manager — IZGITH

**Rodada de documentação: 00069 · 4 de setembro de 2026**

## Objetivo

O **ENSHROUDED MANAGER** do IZGITH é uma camada de preparação e gerenciamento de perfis de servidores. Ele mantém nome, host, porta e observações, valida endpoints e organiza informações para uma operação posterior.

## Referência técnica verificada

A referência declarada é `lincolnthalles/enshrouded-container`, um projeto público de container para Enshrouded Dedicated Server. O repositório está público e descreve version pinning, mod injection e backups agendados.

Fonte externa consultada: https://github.com/lincolnthalles/enshrouded-container

A documentação consultada descreve Fedora 44 + Wine 11, Docker 24+, `VERSION` com `latest`, manifest ID ou `build:<id>`, configuração por variáveis `ENSHROUDED_*`, backups configuráveis, polling de recursos e volumes persistentes para manifests, Wine prefix, mods, saves, backups, configuração e logs.

## Portas verificadas na referência

- `15636/udp` — dados do servidor;
- `15637/udp` — consulta;
- `27015/tcp` — RCON;
- `27015/udp` — tráfego/gameplay documentado pelo projeto.

Fonte: README do projeto de referência, consultado em 4 de setembro de 2026.

## O que o IZGITH faz

1. Cria e guarda perfis locais.
2. Valida host e porta.
3. Prepara configurações, compose e planos para revisão.
4. Organiza ações como verificar, instalar, iniciar, parar, backup, restauração, retenção, mods, recursos e versão.
5. Mantém a preparação separada da execução externa.

## O que o IZGITH não faz automaticamente

O dashboard **não inicia Docker, Wine, SteamCMD ou executáveis do sistema por conta própria**. Não instala um servidor silenciosamente e não pede credenciais Steam.

Essa separação é intencional: o navegador funciona como painel e preparador, enquanto a execução fica em um ambiente externo explicitamente autorizado pelo operador.

## Fluxo recomendado

**Servidores → Nome/Host/Porta → Validar → Salvar perfil → preparar configuração/plano → revisar → executar no ambiente externo autorizado.**

## Backups, mods e versionamento

A arquitetura de referência suporta backups agendados e de desligamento, retenção configurável, mod injection e versionamento por Steam manifest. O IZGITH documenta esses conceitos e gera artefatos de preparação; ele não copia nem executa o container de terceiros automaticamente.

## Segurança

Nunca coloque senhas Steam, tokens, cookies ou chaves privadas em campos do dashboard ou em arquivos versionados. Operações que exigem autenticação devem permanecer explícitas no ambiente externo autorizado.

## Estado da integração 00069

O botão de expansão usa um ícone compatível com o padrão visual do Lucide e abre o **ENSHROUDED MANAGER** em uma nova janela dedicada. Referência visual: https://lucide.dev/icons/square-arrow-out-up-right

A implementação permanece **browser-plan-only**. Qualquer execução de Docker/SteamCMD/Wine deverá ocorrer fora da extensão, em ambiente explicitamente autorizado.
