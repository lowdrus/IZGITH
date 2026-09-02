# IZGITH — Próxima rodada 00045

## Objetivo
Consolidar a arquitetura **Ultra + Controlado unificada** sobre a base funcional 00044, sem voltar a depender de substituições manuais de arquivos.

## Etapa 1 — Gate de estabilidade
- Validar `manifest.json` e todas as referências de assets antes do build.
- Validar `sw.js` como JavaScript puro, sem interpolação acidental de PowerShell.
- Executar preflight compatível com Windows PowerShell 5.x.
- Garantir que o boot da extensão não dependa de Native Messaging.
- Manter diagnóstico de Native Messaging explícito e verdadeiro, sem chamadas cegas ao host.

## Etapa 2 — UI / experiência
- Preservar a UI-base aprovada pelo projeto.
- Manter a sequência: **Identidade & Host → Ferramentas → Configurações → Logs → Temas**.
- Manter Logs legíveis, em verde, com estado e timestamp consistentes.
- Consolidar os 36 temas e persistência de tema.
- Manter Guia Rápido e EULA como abas informativas no rodapé.

## Etapa 3 — Integrações
- Manter SONPEF, CONVGPT, KIT_UNICO e CHAT_HISTORY no registro de integração.
- Não promover arquivos históricos inexistentes por suposição.
- Promover cada artefato real somente após validação de origem e execução.
- Manter Júlia, Ayelle/Ayella e IZART como assistentes registrados conforme os artefatos efetivamente recuperados.

## Etapa 4 — Automação Windows
- Builder sempre entregue em par `.bat` + `.ps1`.
- Evitar nomes reservados do PowerShell, como `$Host`.
- Evitar operadores exclusivos de PowerShell 7 (`?.`) quando o alvo for Windows PowerShell 5.x.
- Evitar here-strings frágeis para conteúdo JavaScript/JSON.
- Gerar arquivos determinísticos e verificar existência/tamanho antes de declarar sucesso.

## Etapa 5 — Empacotamento
- Gerar pacote limpo a partir da árvore de build.
- Excluir artefatos temporários, caches e arquivos históricos do pacote distribuível.
- Executar validação final antes de publicar release.

## Critérios de aceite
1. `manifest.json` carrega em `chrome://extensions` sem erro.
2. Service worker inicia sem Status 15.
3. Nenhuma referência de ícone aponta para arquivo inexistente.
4. Popup/app abre sem ficar preso em “Carregando IZGITH”.
5. Native Messaging ausente não impede o boot; quando instalado, o diagnóstico informa corretamente seu estado.
6. Todos os botões da UI têm ação definida ou ficam explicitamente marcados como indisponíveis.
7. Builder `.bat` e `.ps1` passam pelo preflight antes de anunciar “Build concluído”.
8. O pacote final é reproduzível a partir da árvore de build.

## Regra de integridade
Arquivos de versões anteriores que não estejam disponíveis no repositório ou nos artefatos fornecidos devem permanecer como **pendentes**, nunca ser reconstruídos como se fossem o original.
