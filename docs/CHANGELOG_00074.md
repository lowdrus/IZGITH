# IZGITH 00074

## F-SNC

- Captura de conversa mantida localmente como fronteira de segurança.
- Publicação GitHub automática passa a existir após autorização explícita.
- Token Fine-grained é aceito somente em memória do service worker.
- Cookies não são lidos.
- Nenhum `git push --force` é usado.
- Publicação usa GitHub Contents API e commits normais.

## UPPER GITHUB

- Menu de ações recebe estado de autorização.
- Autorizar, publicar captura e ações de arquivos/pastas passam a ter handlers dedicados.
- Configuração exportada registra `auth: explicit-in-memory` e `force_push: false`.

## Dashboard

- Minimizar em janela popup devolve foco ao navegador e fecha somente a janela do IZGITH.
- Fechar remove somente a janela/aba do IZGITH.
- O ENSHROUDED MANAGER completo é incorporado ao card de Servidores.

## ENSHROUDED MANAGER

- Mantida a fronteira Browser → Runtime Agent → Docker Engine.
- Referência funcional alinhada ao `lincolnthalles/enshrouded-container`.
- UI permanece local e não depende de Native Messaging para iniciar.

## Release

- Manifest: `6.0.0.74`
- Pacote: `6.0.0-00074`
- Registry: `6.0.0.00074`
