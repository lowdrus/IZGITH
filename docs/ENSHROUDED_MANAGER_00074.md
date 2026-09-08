# ENSHROUDED MANAGER — 00074

O ENSHROUDED MANAGER (ENSHGERENC) continua sendo o plano de controle do IZGITH para perfis de servidores Enshrouded.

## Referência técnica

A arquitetura é alinhada ao projeto público `lincolnthalles/enshrouded-container`, cuja descrição do repositório destaca um container para servidor dedicado Enshrouded com backups agendados, injeção de mods e version pinning. citeturn107file0

No IZGITH, a extensão permanece como **control plane**: ela não tenta transformar o Chrome em daemon, não executa Docker/Wine/SteamCMD silenciosamente e mantém o Runtime Agent como fronteira explícita para execução real.

## Integração visual

A página completa `extension/ui/enshrouded.html` agora é incorporada ao card **ENSHROUDED MANAGER** na aba **Servidores**. Isso evita uma segunda experiência desconectada e mantém a operação no contexto do dashboard.

## Limite de execução

- Browser: UI, perfis, configuração, diagnósticos e planos.
- Runtime Agent: execução autorizada de operações externas.
- Docker/Wine/SteamCMD: somente no runtime explicitamente disponível.

## Testes esperados

- Manifest V3 válido.
- Service worker válido.
- UI Enshrouded presente.
- Contrato de runtime presente.
- Nenhuma dependência obrigatória de Native Messaging.
- Dashboard com embed do ENSHROUDED MANAGER.
