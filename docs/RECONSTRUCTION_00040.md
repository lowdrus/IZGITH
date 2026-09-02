# IZGITH 6.0.0.00040 - Reconstrucao e estado

## O que foi feito nesta rodada

- Manifest MV3 sincronizado para 6.0.0.40 / 6.0.0.00040 CLEAN CORE.
- Service worker declarado explicitamente e validado como arquivo nao vazio.
- Referencias de popup, worker e icones verificadas pelo preflight.
- Icones 16/32/48/128 continuam no caminho `extension/assets/icons/`.
- SONPEF, CONVGPT e KIT_UNICO permanecem separados como integracoes, evitando contaminar o core.
- Assistentes internos preservados: Julia, Ayelle (alias Ayella) e IZART.
- Validacao reforcada contra divergencia de versao e referencias quebradas.
- Builders Windows `.bat` e `.ps1` adicionados em `build/`.

## Regra de reconstrucao

O material historico real preservado no repositorio deve ser tratado como fonte primaria. Arquivos historicos que nao estejam presentes no repositorio nao devem ser inventados. Quando um arquivo antigo for recuperado, ele entra primeiro em `archive/legacy/` e so depois pode ser promovido para uma integracao ativa apos revisao.

## Native Messaging

A permissao `nativeMessaging` no Manifest nao instala nem registra um host nativo. O host precisa existir no Windows e possuir um manifesto registrado para o ID da extensao. Por isso, o core nao deve tentar `connectNative()` automaticamente sem uma verificacao controlada; caso contrario, o Chrome pode produzir `Specified native messaging host not found` ou `forbidden`.

## Proxima rodada

1. Validar a extensao em `chrome://extensions` com o diretorio `extension/`.
2. Executar o preflight e o empacotador pelo builder.
3. Integrar os arquivos reais recuperados de SONPEF/KIT_UNICO/CONVGPT individualmente.
4. Criar testes de UI para cada botao antes de promover qualquer integracao.
5. Implementar o fluxo de Native Messaging somente com instalador/registro verificavel.
6. Gerar ZIP versionado apos todos os checks passarem.
