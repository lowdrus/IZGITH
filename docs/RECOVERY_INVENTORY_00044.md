# IZGITH — Recovery Inventory 00044

## Fonte de verdade
O repositório `lowdrus/IZGITH` contém partes reais do projeto e deve ser tratado como fonte primária para o código recuperável.

## Material histórico recuperado no repositório
A árvore `archive/legacy/root` contém, entre outros, `BUSCAR-TODOS-SCRIPTS.ps1`, `FULLONE.ps1`, várias variantes `FULLONE*`, `ChatGPT-Extractor-X.ps1`, `FRAGMENTS_CATALOG.json`, `FRAGMENTS_REPORT.md` e outros artefatos históricos.

## Integrações já registradas
- `integrations/SONPEF/integration.json`
- `integrations/CONVGPT/integration.json`
- `integrations/KIT_UNICO/integration.json`
- `integrations/CHAT_HISTORY/integration.json`
- `integrations/registry.json`

## Limite de recuperação
O arquivo histórico exato `sonpef_unify.ps1` não foi encontrado por busca no repositório atual. O registro SONPEF aponta para as fontes históricas realmente presentes, mas não promove um arquivo inexistente para execução.

O pacote externo original de `KIT_UNICO` não está disponível como fonte separada no estado atual do repositório. O material em `archive/legacy` pode ser auditado e aproveitado quando houver correspondência comprovável.

## Regras de integração
1. Não sobrescrever código histórico como se fosse código novo.
2. Não declarar uma integração como funcional apenas por possuir um `integration.json`.
3. Toda promoção para execução deve ter fonte identificável e teste correspondente.
4. Native Messaging não pode ser requisito para o boot da extensão.
5. Falha do host deve ser exibida como estado diagnosticável, sem `runtime.lastError` não tratado.

## Estado 00044
- Manifest V3: presente.
- Service worker: presente.
- Ícones 16/32/48/128: presentes no diretório distribuível.
- Host canônico: `com.izgith.host`.
- Boot sem host: permitido.
- 36 temas: mantidos.
- EULA e Guia Rápido: mantidos na UI.
- Júlia, Ayelle/Ayella e IZART: registrados.
