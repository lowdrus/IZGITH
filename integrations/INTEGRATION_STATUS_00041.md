# IZGITH 00041 — Integration Pass

## Objetivo
Consolidar as integrações históricas sem contaminar o CLEAN CORE e sem exigir terminal para o uso normal da extensão.

## Componentes
- SONPEF: unificação/auditoria de scripts PowerShell e Python. O executor deve permanecer controlado e registrar logs.
- CONVGPT: exportação do histórico/conversa selecionada pelo usuário, quando a página e as permissões permitirem.
- KIT_UNICO: camada de assistentes e componentes históricos; somente código efetivamente recuperado deve ser promovido ao core.
- Assistentes: Júlia; Ayelle (alias histórico Ayella); IZART.
- Native Messaging: opcional. A extensão não deve depender dele para carregar, abrir a UI ou executar funções offline.

## Regra de segurança
Nenhuma integração deve presumir que um executável/host local existe. Ausência de Native Messaging deve produzir estado informativo, não uma exceção não tratada.

## Critério de aceite 00041
1. Manifest MV3 válido.
2. Service worker carregável.
3. Ícones referenciados existem.
4. UI abre sem Native Messaging.
5. Download usa `saveAs: true`.
6. Integrações têm estado/log explícito.
7. Componentes históricos permanecem em `archive/legacy` até revisão individual.
8. CI/CodeQL são a barreira antes de promover a rodada.

## Limitações atuais
Arquivos históricos expirados fora do GitHub não podem ser reconstruídos byte-a-byte sem novo upload. O repositório deve continuar sendo a fonte de verdade do material recuperado.