# Auditoria dos arquivos históricos

## O que foi encontrado

A raiz reunia várias bases independentes: componentes de bloqueio/privacidade, gerenciador de downloads, visualização de Git, scripts FULLONE, extratores de conversas, fontes, filtros, executáveis e pacotes compactados. Esses projetos não formavam uma única extensão instalável: havia manifests, licenças, APIs e pontos de entrada concorrentes.

## O que foi feito

- A única extensão distribuível passou a ser `extension/`.
- O host local foi consolidado em `host-python/`.
- 616 arquivos históricos úteis foram movidos para `archive/legacy/root/`.
- O arquivo histórico contém, entre outros, 230 JavaScripts, 71 TypeScripts, 43 folhas CSS, 33 fontes Python, filtros, recursos WASM e imagens.
- Exportações pessoais, `.env`, chaves/placeholders, executáveis, PDFs quebrados e pacotes ZIP/RAR duplicados ou inválidos foram removidos do estado atual.
- O histórico Git anterior foi preservado, portanto uma remoção pode ser inspecionada ou recuperada por commit.
- `archive/legacy/` foi excluído do build, do ZIP e do CodeQL para impedir que projetos incompatíveis voltem a quebrar o produto principal.

## O que não foi feito

Os 616 arquivos não foram todos ativados dentro da extensão. Arquivar não significa integrar. Reutilizar mecanismos completos de projetos como uBlock, Privacy Possum ou DownThemAll exige revisão de licença, modelagem de permissões Manifest V3, migração para `declarativeNetRequest`, testes de desempenho e uma decisão explícita de produto.

## Critério para futuras integrações

Cada função legada deve ser tratada como uma migração isolada: identificar origem/licença, definir comportamento IZGITH, reduzir permissões, reescrever para Manifest V3 quando necessário, adicionar testes, integrar à interface em português e somente então remover a classificação de legado.
