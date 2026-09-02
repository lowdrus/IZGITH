# Regras de trabalho do IZGITH

Estas regras valem para sessões Codex/ChatGPT que clonarem este repositório com autorização de escrita do proprietário.

1. Trabalhar somente na extensão distribuível em `extension/`, no host em `host-python/`, nos testes, scripts e documentação correspondentes.
2. Tratar `archive/legacy/` como fonte histórica: não incluí-la no ZIP final nem reativar código sem auditoria de licença, segurança e compatibilidade Manifest V3.
3. Nunca gravar tokens, chaves, cookies, exportações de conversas ou dados pessoais no Git.
4. Antes de cada commit, executar `npm test`, `npm run package`, `python -m compileall -q host-python scripts tools tests` e `git diff --check`.
5. Após uma alteração solicitada e validada, criar um commit descritivo em português e enviá-lo ao branch autorizado. Nunca usar `push --force` no `main`.
6. Confirmar no GitHub Actions que CI e CodeQL terminaram com sucesso; corrigir falhas introduzidas pela alteração antes de concluir o trabalho.
7. Manter `README.md`, tutorial e `CHANGELOG.md` atualizados quando o comportamento do produto mudar.

O GitHub App/plugin conectado fornece autenticação. Não existe nem deve ser criada uma opção `git push true`, um token permanente em arquivo ou uma permissão vinculada a uma URL de conversa.
