# IZGITH — Reconstrução histórica 2026-09-02

## Objetivo
Consolidar em uma base única os artefatos que continuam recuperáveis no Git e no histórico do repositório, sem inventar ou declarar como recuperados arquivos anexados que não estão disponíveis como bytes.

## Fontes efetivamente recuperadas
- `extension/` — base ativa Manifest V3.
- `host/` — Native Messaging e instaladores.
- `scripts/` — validação e empacotamento.
- `tests/` — testes.
- `docs/` — documentação.
- `archive/legacy/root/` — legado histórico preservado.
- `integrations/KIT_UNICO/`, `integrations/CONVGPT/`, `integrations/SONPEF/` — pontos de integração preservados.

A recuperação histórica registrada no repositório contém 616 arquivos em `archive/legacy/root/`.

## Integrações
`KIT_UNICO`, `CONVGPT` e `SONPEF` permanecem na árvore do projeto. Os adaptadores atuais apontam para suas fontes/entradas históricas, mas não promovem automaticamente arquivos históricos não auditados para o build distribuível.

O núcleo de assistentes preserva os papéis Júlia, Ayelle/Ayella e IZART conforme registrado na auditoria do projeto.

## Modos unificados
O produto passa a tratar **Ultra** e **Controlado** como perfis operacionais da mesma base:

- **Controlado**: confirmação explícita antes de operações locais sensíveis.
- **Ultra**: fluxo máximo de automação permitido pela plataforma e pelas permissões disponíveis.
- Os dois modos compartilham a mesma UI, armazenamento, validação e mecanismos de segurança.

Nenhum modo pode contornar as restrições do Chrome/Chromium ou executar código local arbitrário sem um mecanismo local autorizado.

## Limite de fidelidade
Os ZIPs que expiraram na conversa não podem ser recuperados byte a byte apenas pelo histórico textual. Quando um arquivo histórico específico não existe no Git, ele não é recriado como se fosse o original. O build de recuperação usa somente fontes presentes no repositório e marca integrações incompletas como tal.

## Critério de promoção
Um componente histórico só deve sair de `archive/legacy/` para `extension/` quando houver fonte verificável, compatibilidade MV3, validação sintática, teste e revisão de licença/segurança.

## Resultado
Esta reconstrução preserva o que é recuperável, mantém o legado acessível para análise e estabelece uma base única para os próximos builds, evitando substituições manuais arquivo a arquivo.
