# EULA — IZGITH

**Versão funcional documentada: 6.0.0.00065 · Rodada 00066**

## 1. Finalidade

IZGITH é uma extensão local de apoio à organização, auditoria, exportação de conversas, preparação de arquivos, temas, assistentes e gerenciamento de perfis de servidores.

## 2. Controle do usuário

O usuário decide quais arquivos selecionar, quais conversas exportar, qual formato salvar e qual destino local utilizar. Os recursos de publicação em GitHub não devem coletar, armazenar ou transmitir tokens silenciosamente.

## 3. Conversas e dados

O CONV-D processa localmente o conteúdo disponibilizado pela página de conversa suportada. A extensão não deve fabricar IDs privados de contas: quando uma plataforma expõe um identificador ou papel público da mensagem, ele pode ser preservado; caso contrário, são usados rótulos como `Usuário` e `IA`.

## 4. Execução externa

A arquitetura funcional atual não depende de Native Messaging. SONPEF opera no navegador sobre os arquivos que o usuário seleciona. O Enshrouded Manager prepara perfis, configurações e planos, mas não inicia Docker, Wine, SteamCMD ou processos do sistema silenciosamente.

## 5. GitHub

UPPER GITHUB e UPPER URL podem registrar/preparar destinos, arquivos e operações. Qualquer publicação efetiva em repositório deve ocorrer mediante autenticação e autorização explícitas do usuário ou por uma integração oficialmente autorizada.

## 6. Limitações de plataformas

Cada plataforma de IA possui DOM, autenticação, políticas e mecanismos de navegação próprios. A disponibilidade do botão CONV-D depende de a página fornecer conteúdo acessível à extensão e de a integração correspondente permanecer compatível.

## 7. Segurança

Não coloque senhas, tokens, cookies de sessão ou chaves privadas em arquivos do projeto. Não utilize `git push --force` contra repositórios alheios. O modo de preparação não equivale a autorização de execução.

## 8. Aceite

Ao utilizar IZGITH, o usuário reconhece que é responsável pelos dados exportados, pelas permissões concedidas ao navegador e pelos destinos para os quais decidir publicar conteúdo.
