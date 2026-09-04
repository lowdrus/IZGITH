# Enshrouded Manager — IZGITH

## Objetivo

O **ENSHROUDED MANAGER** do IZGITH é uma camada de preparação e gerenciamento de perfis de servidores. Ele mantém nome, host, porta e observações, valida endpoints e organiza informações para uma operação posterior.

## Referência técnica

A referência declarada para a arquitetura é `lincolnthalles/enshrouded-container`. A versão consultada em 4 de setembro de 2026 descreve um container de servidor dedicado com Fedora 44 + Wine 11, Docker 24+, versionamento por manifest da Steam, injeção de mods, backups agendados, polling de recursos e configuração por variáveis `ENSHROUDED_*`.

Entre os pontos úteis para o IZGITH estão:

- `VERSION` para usar `latest`, um manifest ID ou `build:<id>`;
- `BACKUP_CRON`, `BACKUP_FORMAT` e retenção configurável;
- configurações do servidor através do prefixo `ENSHROUDED_*`;
- volumes separados para manifests, Wine prefix, mods, saves, backups, config e logs;
- portas UDP `15636` (tráfego do servidor) e `15637` (consulta), além de `27015` TCP/UDP para as funções descritas pelo projeto.

## O que o IZGITH faz

1. Cria e guarda perfis locais.
2. Valida host e porta.
3. Permite organizar informações antes da execução externa.
4. Mantém a preparação separada da execução do servidor.

## O que o IZGITH não faz automaticamente

O dashboard não inicia Docker, Wine, SteamCMD ou executáveis do sistema por conta própria. Não instala um servidor silenciosamente e não pede credenciais Steam.

Essa separação é intencional: a extensão funciona como painel e preparador, enquanto a execução fica em um ambiente externo explicitamente autorizado pelo operador.

## Fluxo recomendado

**Servidores → Nome/Host/Porta → Validar → Salvar perfil → preparar a operação externa.**

Para uma implantação real, siga a documentação e os requisitos do projeto de referência antes de abrir portas ou iniciar containers. O servidor dedicado é um processo externo ao navegador.

## Backups e mods

A arquitetura de referência suporta backups programados e no desligamento, além de uma camada de mods sobre uma instalação versionada. O IZGITH documenta essas capacidades como referência; ele não copia nem executa o container de terceiros automaticamente.

## Segurança

Nunca coloque senhas Steam, tokens, cookies ou chaves privadas em campos do dashboard ou em arquivos versionados. Use o mecanismo de secrets do ambiente externo quando uma operação realmente exigir autenticação.
