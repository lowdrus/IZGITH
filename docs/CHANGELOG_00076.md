# Rodada 00076 — ENSHGERENC + Runtime Agent

## Alterações

- Todos os controles operacionais do ENSHGERENC foram reunidos em um único painel visual.
- Adicionados os controles: Salvar perfil, Validar, Limpar, Baixar Config, Baixar Compose, Baixar Plano, Verificar, Preparar Instalação, Preparar Início, Preparar Parada, Backup, Restaurar, Retenção, Mods, Recursos e Versão.
- A identidade visual do ENSHGERENC recebeu um painel de operações unificado, microinterações, responsividade e estados de runtime mais claros.
- O painel passou a aceitar endpoint de Runtime Agent e Bearer token somente em sessão.
- Criado o contrato `runtime-agent-endpoint.json` com operações allow-listed.
- Atualizado o contrato geral do runtime para refletir as operações da interface.
- Atualizados README, Guia Rápido e EULA para 00076.
- Versões sincronizadas para `6.0.0.00076`.

## Segurança

O navegador permanece como plano de controle. Docker, Wine, Steam/DepotDownloader e processos do sistema continuam fora da extensão. O Runtime Agent é uma fronteira explícita e autenticada; shell arbitrário, argumentos Docker arbitrários e exposição direta do Docker socket são proibidos.

## Referência técnica

A integração acompanha o modelo documentado por `lincolnthalles/enshrouded-container`: version pinning, mods, configuração via `ENSHROUDED_*`, backups, polling de recursos e portas do servidor.
