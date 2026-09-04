# CHANGELOG

## 6.0.0.00068 - MENU HARDENING + ENSHROUDED MANAGER

- Corrigido o ciclo de abertura/fechamento dos menus de **CONV-D** e **UPPER GITHUB**.
- O clique no ícone de menu não sofre mais dupla alternância por handlers legados.
- Menus fecham ao clicar fora e com `Escape`.
- Layout dos menus fica ancorado ao card correto, com `overflow` controlado e limite de altura.
- Adicionado teste de regressão para o contrato de menus colapsáveis.
- O botão de maximizar do **ENSHROUDED MANAGER** usa o desenho de abertura externa e abre a tela interna dedicada do IZGITH em nova aba.
- Sincronizada a versão do pacote, manifestos e registry para 00068.
- Documentação ativa atualizada para 00068.
- A integração Enshrouded continua `browser-plan-only`: o IZGITH não inicia Docker, Wine, SteamCMD ou executáveis externos silenciosamente.

## 6.0.0.00059 - CONV-D FULL + ROUND EXPORT

- CONV-D exporta a conversa inteira, percorrendo o conteúdo carregado do início ao fim e acumulando mensagens durante a rolagem.
- Adicionada opção de escopo `Tudo` ou `Ultima Rodada`.
- O download usa o diálogo nativo de salvamento do Chrome (`saveAs`).
- Mantidos PDF, Word `.doc`, TXT, Markdown `.md`, JSON estruturado e Excel `.xls`.
- A identificação do participante usa o ID exposto pela própria página quando disponível; quando a plataforma não o expõe, o exportador não inventa um ID.

## Histórico

Versões anteriores e material legado permanecem preservados quando disponíveis.
