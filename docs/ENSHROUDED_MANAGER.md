# Enshrouded Manager — IZGITH

## Estado atual

O **ENSHROUDED MANAGER** está integrado ao dashboard e funciona como uma camada de gerenciamento/preparação local. Ele mantém perfis, valida endpoints, prepara configurações, gera compose e registra planos de ação.

### Limite deliberado de execução

A extensão não inicia Docker, Wine, SteamCMD ou executáveis do sistema por conta própria. As ações `install`, `start`, `stop`, `backup`, `restore`, `prune`, `mods`, `resources` e `version` são representadas como **planos preparados**. Isso evita Native Messaging e evita execução silenciosa no computador.

## Referência oficial do projeto

A referência de arquitetura é urllincolnthalles/enshrouded-containerhttps://github.com/lincolnthalles/enshrouded-container.

A documentação pública atualmente consultada descreve um container para Enshrouded Dedicated Server baseado em Fedora 44 + Wine 11, com Docker 24+, version pinning por Steam manifest, mod injection, configuração genérica por variáveis `ENSHROUDED_*`, backups automatizados e polling de recursos. O compose principal usa `network_mode: host`; a documentação também descreve persistência para manifests, Wine prefix, mods, saves, backups, config e logs. citeturn191file0

### Parâmetros de referência incorporados ao IZGITH

- imagem documentada: `ghcr.io/lincolnthalles/enshrouded-container:latest`;
- `VERSION` pode representar `latest`, um Steam manifest ID ou `build:<id>`;
- backups podem ser controlados por `BACKUP_CRON`, `BACKUP_FORMAT`, `BACKUP_LEVEL`, `BACKUP_KEEP_LAST`, `BACKUP_LIVE`, `BACKUP_COLD` e `BACKUP_EMERGENCY`;
- `RESOURCE_POLL_INTERVAL` controla o monitoramento periódico de CPU/memória;
- configurações do servidor usam o prefixo `ENSHROUDED_*`;
- volumes separam manifests, Wine prefix, mods, saves, backups, config e logs;
- as portas documentadas incluem `15636/udp`, `15637/udp` e `27015/tcp`/`udp`. citeturn191file0

O IZGITH usa esses dados como **referência de composição e documentação**, não como código executável copiado. Valores e versões devem ser conferidos contra a documentação do projeto de referência antes de uma implantação real.

## Fluxo recomendado no IZGITH

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

## Escopo da próxima evolução

A próxima etapa do módulo deve concentrar-se em validação de parâmetros, geração de artefatos de configuração e comparação automática com a referência pública, sem transformar o navegador em um executor oculto de Docker/SteamCMD/Wine.
