# IZGITH 00050 - recuperacao e verificacao

## Resultado da busca

O repositorio oficial encontrado foi `lowdrus/IZGITH`. A base atual ja contem a extensao MV3, host opcional, 36 temas, integracoes SONPEF/CONVGPT/KIT_UNICO/CHAT_HISTORY e o registro canonico de Julia, Ayella e IZART.

## Correcoes preservadas nesta rodada

- O README passa a apontar para 6.0.0.00050, eliminando a referencia antiga a 00049.
- O par `build/IZGITH_BUILD_00050.bat` + `build/IZGITH_BUILD_00050.ps1` permanece junto e foi confirmado como a rota de build limpa.
- O builder 00050 evita os erros recorrentes de Windows PowerShell antigo: nao usa optional chaining `?.`, nao usa `$Host` como variavel e nao injeta JavaScript diretamente em codigo PowerShell.
- Foi adicionada uma entrada segura `integrations/SONPEF/sonpef_unify.ps1`. Ela localiza `.ps1` e `.py`, cria um inventario unificado e nao executa os scripts encontrados.
- O SONPEF historico continua preservado em `archive/legacy/root/` para auditoria e migracao posterior.

## Limites importantes

O GitHub nao fornece os bytes dos PNGs pelo endpoint textual usado para esta auditoria; a presenca dos quatro arquivos e verificada pelo validador local. A instalacao silenciosa de Native Messaging tambem continua limitada pelas regras do Chrome/Windows: a extensao nao pode registrar um executavel nativo por conta propria.

## Proxima rodada tecnica

1. adicionar a acao visual do SONPEF ao dashboard e conecta-la ao host;
2. ampliar o host para executar somente entradas explicitamente permitidas;
3. adicionar testes estaticos para cada botao da UI;
4. validar o pacote em Chrome/Edge/Brave;
5. gerar release ZIP somente apos todos os checks passarem.
