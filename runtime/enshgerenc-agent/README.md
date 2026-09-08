# ENSH-GERENC Remote Runtime Agent

Este agente é a fronteira de execução autorizada do ENSH-GERENC. O navegador continua sendo o plano de controle; o agente é quem pode conversar com Docker no host remoto.

## O que ele faz

- `GET /health` — verifica se o agente possui token e se o Docker responde.
- `POST /v1/operations/servers.list`
- `POST /v1/operations/server.start`
- `POST /v1/operations/server.stop`
- `POST /v1/operations/server.restart`
- `POST /v1/operations/server.update`

Não existe endpoint para executar shell arbitrário, receber comandos Docker arbitrários ou escolher um `docker-compose.yml` enviado pelo navegador.

## Configuração

Defina no host remoto:

```text
IZGITH_RUNTIME_BIND=0.0.0.0
IZGITH_RUNTIME_PORT=38751
IZGITH_RUNTIME_TOKEN=<segredo-forte-fora-do-repositorio>
IZGITH_ENSHROUDED_COMPOSE=/caminho/absoluto/docker-compose.yml
IZGITH_RUNTIME_CORS=https://origem-autorizada.example
```

Depois execute `python app.py` em um ambiente protegido por TLS/VPN/rede privada. **Não publique a porta 38751 diretamente na Internet sem uma camada de autenticação e transporte seguro.**

O compose deve apontar para o serviço `enshrouded` e usar a imagem/regras compatíveis com a referência `lincolnthalles/enshrouded-container`.

## Integração com o IZGITH

No card **ENSH-GERENC**, informe o endpoint, informe o token apenas no campo de sessão (ele não é versionado) e clique em **Verificar** ou **Conectar Runtime**. Os botões **Iniciar** e **Parar** passam a usar a fronteira remota somente depois de uma resposta saudável.

## Limites deliberados

O agente não substitui autenticação Steam, não distribui binários do jogo e não contém credenciais. Ele é uma camada operacional para o servidor que o usuário já administra.
