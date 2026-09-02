# IZGITH 00054 — CONVGPT Multi-Export

## Objetivo
Ampliar o botão **Baixar conversa · CONVGPT** sem substituir a arquitetura existente e sem depender de terminal.

## Exportadores

O menu agora oferece:

- PDF
- Word (`.doc` HTML compatível com Word)
- TXT
- Markdown (`.md`)
- JSON estruturado
- Excel (`.xls` SpreadsheetML compatível com Excel)
- Todos os formatos de uma vez

## Dados exportados

O schema `izgith.convgpt.v2` preserva título, URL, data ISO de exportação, quantidade de mensagens e cada mensagem com índice, papel e texto.

O coletor faz uma tentativa limitada de carregar conteúdo adicional da conversa por rolagem e restaura a posição anterior. A extensão não usa uma API privada do ChatGPT e não promete recuperar mensagens que o site não disponibilize no DOM.

## Recuperação da árvore histórica

A árvore histórica existente no repositório foi tratada como fonte complementar, não como substituta da árvore atual. O arquivo `archive/legacy/root` contém artefatos legados diversos; nesta rodada não foi encontrado, por evidência disponível no repositório, um exportador CONVGPT histórico funcional que devesse ser sobrescrito ou copiado para o núcleo atual.

Portanto, somente a capacidade que estava faltando foi adicionada ao CONVGPT atual.

## Gate

O validador exige a presença do contrato multi-formato no `extension/integrations/convgpt.js`, além das verificações existentes de Manifest V3, service worker, assets, temas, EULA, Guia Rápido, SONPEF, CONVGPT, KIT_UNICO, assistentes e sincronização de versões.
