# CHANGELOG

## 6.0.0.00044 - RECOVERY + INTEGRATION HARDENING

- Sincronizada a versão do pacote, popup e documentação para 00044.
- Canonicalizado o Native Messaging para `com.izgith.host` em todos os registros funcionais.
- Native Messaging explicitamente opcional para o boot da extensão.
- Tratamento de `chrome.runtime.lastError` mantido dentro do callback de `onDisconnect`.
- Corrigido o status de integração que anteriormente podia declarar `bootRequired` de forma incorreta.
- Atualizado o inventário de recuperação para distinguir fontes históricas reais de arquivos ainda não recuperados.
- Mantidos SONPEF, CONVGPT, KIT_UNICO e CHAT_HISTORY como integrações separadas.
- Mantidos Júlia, Ayelle/Ayella e IZART.
- Mantidos os 36 temas, EULA informativo e Guia Rápido.
- Adicionado par de builders Windows 00044 (`.bat` + `.ps1`) com sintaxe conservadora para Windows PowerShell.

## 6.0.0.00042 - FUNCTIONAL BASELINE

- Endurecido o Manifest MV3 e fixada a versão funcional 00042.
- Service worker revisado para evitar `Unchecked runtime.lastError` durante diagnóstico de Native Messaging.
- Adicionado diagnóstico `NATIVE_HOST_CHECK` sem tornar Native Messaging requisito do boot.
- Adicionado diagnóstico `GET_INTEGRATION_STATUS` para SONPEF, CONVGPT, KIT_UNICO e CHAT_HISTORY.
- Adicionado `tools/validate_extension_00042.ps1`, compatível com Windows PowerShell 5.x.
- Confirmada a presença dos caminhos dos quatro ícones no repositório.
- Documentados os limites da recuperação dos arquivos históricos expirados.

## 6.0.0.00041 - INTEGRATION PASS

- Adicionado registro formal das integrações SONPEF, CONVGPT, KIT_UNICO e CHAT_HISTORY.
- Registrados os assistentes Júlia, Ayelle (alias histórico Ayella) e IZART.
- Reforçada a regra de que Native Messaging não é requisito para o boot da extensão.
- Adicionados critérios de aceite para Manifest MV3, service worker, UI, ícones, downloads e integrações.
- Mantido o material histórico em `archive/legacy` até promoção individual após revisão.

## Histórico

Versões anteriores e material legado permanecem preservados no arquivo histórico do repositório quando disponíveis.
