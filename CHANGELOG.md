# CHANGELOG

## 6.0.0.00042 - FUNCTIONAL BASELINE

- Endurecido o Manifest MV3 e fixada a versão funcional 00042.
- Service worker revisado para evitar `Unchecked runtime.lastError` durante diagnóstico de Native Messaging.
- Adicionado diagnóstico `NATIVE_HOST_CHECK` sem tornar Native Messaging requisito do boot.
- Adicionado diagnóstico `GET_INTEGRATION_STATUS` para SONPEF, CONVGPT, KIT_UNICO e CHAT_HISTORY.
- Adicionado `tools/validate_extension_00042.ps1`, compatível com Windows PowerShell 5.x.
- Confirmada a presença dos caminhos dos quatro ícones no repositório.
- Documentados os limites da recuperação dos arquivos históricos expirados.
- Não foram inventados arquivos históricos ausentes: KIT_UNICO, SONPEF/sonpef_unify.ps1, CONVGPT e chat_history_bridge.js permanecem marcados como referência/pendentes quando não encontrados.

## 6.0.0.00041 - INTEGRATION PASS

- Adicionado registro formal das integrações SONPEF, CONVGPT, KIT_UNICO e CHAT_HISTORY.
- Registrados os assistentes Júlia, Ayelle (alias histórico Ayella) e IZART.
- Reforçada a regra de que Native Messaging não é requisito para o boot da extensão.
- Adicionados critérios de aceite para Manifest MV3, service worker, UI, ícones, downloads e integrações.
- Adicionado builder irmão `.bat` + `.ps1`, compatível com Windows PowerShell 5.x para a rotina de verificação local.
- Mantido o material histórico em `archive/legacy` até promoção individual após revisão.

## 6.0.0.00040 - CLEAN CORE

- Sincronizada a versão do Manifest MV3 e do package.
- Declarado o service worker como module e reforçada a validação de sua existência.
- Reforçadas verificações de referências do Manifest e dos quatro ícones.
- Corrigida a verificação de sincronismo de versão do preflight.
- Adicionados builders Windows `.bat` e `.ps1` na pasta `build/`.
- Documentada a política de Native Messaging para evitar chamadas cegas a hosts inexistentes.
- Mantidas as integrações SONPEF, CONVGPT e KIT_UNICO em áreas separadas.
- Mantidos os assistentes Julia, Ayelle/Ayella e IZART.

## Histórico

Versões anteriores e material legado permanecem preservados no arquivo histórico do repositório quando disponíveis.
