# ENSHROUDED MANAGER

## Objetivo

O ENSHROUDED MANAGER do IZGITH incorpora, de forma incremental e sem copiar o projeto de referência, conceitos do `enshctl` encontrado em `lincolnthalles/enshrouded-container`: versionamento determinístico, preparação de instalação, ciclo de vida, backups, retenção, restauração, mods e observabilidade de recursos.

Fonte de referência: https://github.com/lincolnthalles/enshrouded-container

## O que foi extraído como conceito

O `enshctl` é um orquestrador Python dentro de um container. A árvore pública possui módulos de configuração, download, instalação, mods, recursos, retenção e comandos de backup/restore/start/stop/verify/version. O README do projeto também documenta version pinning por Steam manifest, backups live/cold/emergency, retenção, overlay de mods e polling de CPU/RSS.

O IZGITH não incorpora Docker, Wine, Steam credentials ou DepotDownloader dentro da extensão. Em vez disso, o módulo cria perfis, valida endpoints, gera configuração, gera `docker-compose`, e produz planos auditáveis de execução.

## Arquitetura Windows recomendada

### Camada 1 — IZGITH Extension

- interface do ENSHROUDED MANAGER;
- perfis e configurações persistentes em `chrome.storage.local`;
- validação de host/porta;
- geração de configuração e planos;
- nenhuma execução de processo arbitrário.

### Camada 2 — Runtime local opcional

Para executar de verdade Docker/Wine/Steam/DepotDownloader em Windows seria necessário um processo local autorizado pelo sistema operacional. Ele pode ser futuramente implementado como serviço Windows ou aplicativo desktop assinado, com uma API local limitada e autenticação por origem.

### Camada 3 — Runtime Enshrouded

O runtime executaria o container ou servidor dedicado e cuidaria de:

1. instalar/atualizar uma versão;
2. iniciar/parar de forma graciosa;
3. produzir backups live/cold/emergency;
4. aplicar retenção;
5. restaurar backup selecionado;
6. aplicar mods;
7. coletar CPU/RSS e logs;
8. validar configuração e portas.

## Limite importante

Uma extensão Chrome/Chromium não pode iniciar silenciosamente um processo Windows, Docker Desktop, Wine ou um serviço arbitrário. Portanto, a versão atual é deliberadamente **browser-plan-only**: ela é funcional para preparação, validação, persistência e geração de artefatos, mas não finge executar processos externos sem uma ponte local autorizada.

Isso preserva a exigência de não depender de Native Messaging para o boot do IZGITH e evita introduzir uma execução silenciosa insegura.

## Fluxo de uso atual

1. Abra **Servidores → ENSHROUDED MANAGER**.
2. Crie um perfil com nome, host e porta.
3. Salve/valide o perfil.
4. Use **Verificar**, **Preparar Instalação**, **Preparar Início**, **Backup**, **Restaurar**, **Mods**, **Recursos**, etc. para criar planos locais.
5. Use **Baixar Config**, **Baixar Compose** ou **Baixar Plano** quando precisar levar a configuração para um runtime externo.

Nenhuma senha Steam, token GitHub ou credencial é solicitada pelo módulo.
