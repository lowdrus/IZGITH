# Integração ChatGPT → GitHub

A conversa `69cb3e9ea61c81a2895c94c07cbd9c33` está registrada em `.chatgpt/conversations/`. O registro informa ao agente o repositório, branch e workflow corretos.

## Fluxo autônomo autorizado

1. A sessão autenticada produz ou altera os arquivos.
2. O plugin GitHub grava o commit diretamente; alternativamente, um cliente autenticado envia o evento `repository_dispatch` do tipo `gitpush_true`.
3. O workflow valida caminho, conteúdo, testes e pacote.
4. Somente com validação aprovada ele executa pull com rebase, commit e push no `main`.
5. CI e CodeQL validam o novo commit.

Uma URL de conversa é um identificador, não uma credencial. Portanto, a sessão precisa ter o GitHub App conectado ou uma credencial externa válida. Nenhum PAT é armazenado no repositório.
