# F-SNC + GitHub — autorização explícita

## Objetivo

O F-SNC captura uma conversa em uma plataforma suportada e pode publicá-la automaticamente no repositório escolhido **somente depois de uma autorização explícita do usuário**.

## Segurança

- Nenhum token é hardcoded.
- Nenhum cookie de sessão é lido.
- O token é mantido apenas em memória do service worker.
- A extensão não executa `git push --force`.
- A publicação usa a GitHub Contents API para criar ou atualizar um arquivo e gerar um commit normal.
- A permissão necessária é **Contents: Read and write** em um Fine-grained Personal Access Token limitado ao repositório desejado.

## Fluxo

1. Abra **Ferramentas → UPPER GITHUB**.
2. Informe o repositório HTTPS.
3. Abra o menu e escolha **Autorizar**.
4. Cole um Fine-grained token com `Contents: Read and write` para o repositório.
5. Ative o UPPER URL/F-SNC.
6. O F-SNC captura a conversa e, enquanto a autorização permanecer válida na memória, publica automaticamente em `captures/fsnc/<provedor>/...json`.
7. Se o service worker for reiniciado e perder a autorização de memória, a captura continua local e a publicação volta a exigir nova autorização.

## Por que isso é diferente de force push?

O objetivo é publicar evidência de captura sem reescrever histórico. A Contents API preserva o histórico de commits e evita uma operação destrutiva de ref.
