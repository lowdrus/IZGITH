# EULA — IZGITH

**Versão funcional documentada: 6.0.0.00068 · Rodada 00068**

## 1. Finalidade

IZGITH é uma extensão local de apoio à organização, auditoria, exportação de conversas, preparação de arquivos, temas, assistentes e gerenciamento de perfis de servidores.

## 2. Controle do usuário

O usuário decide quais arquivos selecionar, quais conversas exportar, qual formato salvar e qual destino local utilizar. Os recursos de publicação em GitHub não devem coletar, armazenar ou transmitir tokens silenciosamente.

## 3. Conversas e dados

O CONV-D processa localmente o conteúdo disponibilizado pela página de conversa suportada. Quando a plataforma expõe um identificador de autor/usuário/mensagem, ele pode ser preservado. Quando não expõe, o exportador usa rótulos explícitos como `Você` e `IA[Plataforma]` e registra que o ID não foi exposto. O IZGITH não fabrica IDs privados.

## 4. Execução externa

A arquitetura funcional atual não depende de Native Messaging. SONPEF opera no navegador sobre os arquivos que o usuário seleciona. O Enshrouded Manager prepara perfis, configurações e planos, mas não inicia Docker, Wine, SteamCMD ou processos do sistema silenciosamente.

## 5. GitHub

UPPER GITHUB e UPPER URL podem registrar/preparar destinos, arquivos e operações. Qualquer publicação efetiva em repositório deve ocorrer mediante autenticação e autorização explícitas do usuário ou por uma integração oficialmente autorizada.

## 6. Limitações de plataformas

Cada plataforma de IA possui DOM, autenticação, políticas e mecanismos de navegação próprios. A disponibilidade do botão CONV-D depende de a página fornecer conteúdo acessível à extensão e de a integração correspondente permanecer compatível.

## 7. Segurança

Não coloque senhas, tokens, cookies de sessão ou chaves privadas em arquivos do projeto. Não use operações destrutivas ou force-push contra repositórios sem autorização. O modo de preparação não equivale a autorização de execução.

## 8. Enshrouded Manager

A integração é de planejamento no navegador. A referência pública `lincolnthalles/enshrouded-container` é usada para manter a documentação de version pinning, backups, mods, volumes e configuração coerente, sem copiar credenciais ou executar o container automaticamente.

## 9. Aceite

Ao utilizar IZGITH, o usuário reconhece que é responsável pelos dados exportados, pelas permissões concedidas ao navegador e pelos destinos para os quais decidir publicar conteúdo.
