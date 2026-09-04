# ENSHROUDED MANAGER — arquitetura 00070

## Objetivo

O módulo passa a ser um painel de operação realista, mas com fronteira explícita: a extensão Chromium controla a experiência; um **Runtime Agent** opcional executa operações de sistema. Isso evita transformar o service worker MV3 em um executor oculto de Docker/Wine/SteamCMD.

## Referência técnica

O projeto `lincolnthalles/enshrouded-container` usa Fedora + Wine, version pinning, mod injection, backups automatizados, polling de recursos e configuração por variáveis `ENSHROUDED_*`. O servidor expõe, por padrão, UDP 15636/15637 e o repositório documenta Docker 24+ como requisito. A integração IZGITH reproduz o **modelo operacional**, não copia o executor.

## Arquitetura recomendada

```text
Chrome / IZGITH
      |
      | HTTP local autenticado / TLS quando remoto
      v
Runtime Agent (Windows Service / Linux service)
      |
      +--> Docker Engine
      |      +--> Enshrouded container
      |             +--> Wine
      |             +--> Steam / DepotDownloader
      |
      +--> logs / backups / metrics / audit
```

### Por que isso é melhor

1. **Sem terminal após a instalação**: o agente pode ser instalado como serviço do sistema.
2. **Sem reiniciar o Chrome como requisito operacional**: a UI fala com o agente por HTTP local.
3. **Menor superfície de privilégio**: o agente expõe somente operações allow-listed.
4. **Sem Docker socket no navegador**: não colocar `/var/run/docker.sock` nem uma API Docker aberta na rede.
5. **Auditoria**: start/stop/update/backup/ban/kick devem registrar ator, alvo, motivo, horário e resultado.
6. **Fallback seguro**: sem agente, a UI continua em `browser-plan-first` e gera config/compose/planos.

## Native Messaging

O build base do IZGITH permanece sem `nativeMessaging`. Isso elimina os erros recorrentes de `Specified native messaging host not found` e `Access ... forbidden` da base. Quando Native Messaging for usado como opção futura, o instalador deve registrar o host em HKCU/HKLM e o manifesto precisa conter o ID exato da extensão em `allowed_origins`; curingas não são aceitos. O agente HTTP local é preferível para o fluxo normal.

## Compatibilidade com o container de referência

O manager gera parâmetros compatíveis com:

- `VERSION=latest` ou manifest/build pinado;
- `BACKUP_CRON`, `BACKUP_FORMAT`, `BACKUP_KEEP_LAST`;
- `BACKUP_LIVE`, `BACKUP_COLD`, `BACKUP_EMERGENCY`;
- `RESOURCE_POLL_INTERVAL`;
- `ENSHROUDED_NAME`, `ENSHROUDED_SLOT_COUNT`, `ENSHROUDED_QUERY_PORT`;
- volumes de manifests, wineprefix, mods, saves, backups, config e logs.

## Players

A UI já reserva `Kick`, `Ban`, `Unban` e motivo. Essas ações só devem ser efetivadas pelo Runtime Agent, nunca por código de página. `Ban` exige motivo e trilha de auditoria.

## Próxima implementação

- Runtime Agent mínimo com `/health`, `/servers`, `/players`, `/backups`, `/logs`.
- Serviço Windows com instalação silenciosa via instalador IZGITH.
- Token local rotativo e allow-list de operações.
- Adaptador Docker que chama apenas Compose/Engine APIs necessárias.
- Testes de contrato e smoke tests do manager.
