# Enshrouded Manager — IZGITH

## Estado atual — Rodada 00068

O **ENSHROUDED MANAGER** está integrado ao dashboard e funciona como uma camada de gerenciamento/preparação local. Ele mantém perfis, valida endpoints, prepara configurações, gera compose e registra planos de ação. O botão de abertura usa uma tela dedicada do IZGITH em nova aba.

### Limite deliberado de execução

A extensão não inicia Docker, Wine, SteamCMD ou executáveis do sistema por conta própria. As ações `install`, `start`, `stop`, `backup`, `restore`, `prune`, `mods`, `resources` e `version` são representadas como **planos preparados**. Isso evita Native Messaging e evita execução silenciosa no computador.

## Referência oficial do projeto

A referência de arquitetura é `lincolnthalles/enshrouded-container`.

Na versão consultada em 4 de setembro de 2026, o projeto de referência declara Fedora 44 + Wine 11, Docker 24+, version pinning por `VERSION`, mods em `/data/mods`, backups configuráveis por `BACKUP_CRON`, polling por `RESOURCE_POLL_INTERVAL` e configuração por variáveis `ENSHROUDED_*`. O README também documenta volumes para manifests, Wine prefix, mods, saves, backups, config e logs, além das portas UDP 15636/15637 e 27015 para os usos descritos pelo projeto.

O IZGITH usa esses dados como referência de composição e documentação; não copia o projeto nem executa seus comandos automaticamente. A imagem declarada pelo projeto de referência é `ghcr.io/lincolnthalles/enshrouded-container:latest`.

## Fluxo recomendado

1. Abra **Servidores**.
2. Informe nome, host e porta.
3. Use **Validar**.
4. Salve o perfil.
5. Use uma ação de preparação para gerar o plano.
6. Baixe **Config**, **Compose** ou **Plano** quando precisar levar a configuração para um ambiente externo autorizado.
7. Use o ícone de maximizar ao lado de **ENSHROUDED MANAGER** para abrir a tela dedicada.

## Segurança

Não coloque senhas, tokens Steam, chaves ou cookies no perfil. Credenciais para operações externas devem ser fornecidas somente no ambiente externo apropriado e nunca gravadas pelo dashboard.

## Por que essa arquitetura?

O navegador é excelente para UI, armazenamento local e preparação de arquivos, mas não deve fingir que pode iniciar processos do sistema sem uma ponte explícita. A separação entre **preparar** e **executar** deixa o IZGITH previsível, auditável e compatível com a exigência de não depender de Native Messaging.
