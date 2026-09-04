# Enshrouded Manager — IZGITH

## Estado atual

O **ENSHROUDED MANAGER** está integrado ao dashboard e funciona como uma camada de gerenciamento/preparação local. Ele mantém perfis, valida endpoints, prepara configurações, gera compose e registra planos de ação.

### Limite deliberado de execução

A extensão não inicia Docker, Wine, SteamCMD ou executáveis do sistema por conta própria. As ações `install`, `start`, `stop`, `backup`, `restore`, `prune`, `mods`, `resources` e `version` são representadas como **planos preparados**. Isso evita Native Messaging e evita execução silenciosa no computador.

## Referência oficial do projeto

A referência de arquitetura é `lincolnthalles/enshrouded-container`.

Na versão consultada em 4 de setembro de 2026, o projeto de referência declara:

- imagem `ghcr.io/lincolnthalles/enshrouded-container:latest`;
- Docker 24+ como requisito;
- `network_mode: host` no compose principal;
- `VERSION` para versão/manifests;
- backups configuráveis por `BACKUP_CRON`;
- configuração `ENSHROUDED_*` para o servidor;
- volumes para backups, config, logs, mods, saves, manifests e Wine prefix;
- `15636/udp` e `15637/udp` para tráfego do servidor e consulta, com `27015` usado para RCON/gameplay conforme a documentação do projeto.

O IZGITH usa esses dados como referência de composição e documentação; não copia o projeto nem executa seus comandos automaticamente.

## Fluxo recomendado

1. Abra **Servidores**.
2. Informe nome, host e porta.
3. Use **Validar**.
4. Salve o perfil.
5. Use uma ação de preparação para gerar o plano.
6. Baixe **Config**, **Compose** ou **Plano** quando precisar levar a configuração para um ambiente externo autorizado.

## Segurança

Não coloque senhas, tokens Steam, chaves ou cookies no perfil. Credenciais para operações externas devem ser fornecidas somente no ambiente externo apropriado e nunca gravadas pelo dashboard.

## Por que essa arquitetura?

O navegador é excelente para UI, armazenamento local e preparação de arquivos, mas não deve fingir que pode iniciar processos do sistema sem uma ponte explícita. A separação entre **preparar** e **executar** deixa o IZGITH previsível, auditável e compatível com a exigência de não depender de Native Messaging.
