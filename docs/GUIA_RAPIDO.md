# Guia Rapido IZGITH 00050

## 1. Abrir a extensao
1. Extraia o pacote para uma pasta permanente.
2. Abra `chrome://extensions`.
3. Ative **Modo do desenvolvedor**.
4. Clique em **Carregar sem compactacao** e selecione a pasta `extension` que contem `manifest.json`.

## 2. Identidade & Host
O IZGITH foi desenhado para abrir sem Native Messaging. Portanto, `Host OFF` nao significa falha do boot.

- Use **Testar host** para consultar o host nativo opcional.
- Se o Chrome informar `Specified native messaging host not found` ou `forbidden`, verifique se o manifesto do host esta registrado para o ID atual da extensao.
- O ID pode mudar quando uma extensao e carregada de forma diferente. Sempre registre o ID exibido em `chrome://extensions` para aquela instalacao.

## 3. Ferramentas
Use auditoria de pasta e preparacao de ZIP/CRX quando o host estiver instalado. Operacoes que dependem do host sao deliberadamente separadas do boot da interface.

## 4. Configuracoes
Padrao: **Ultra + Controlado — Unificado**. Existem tambem Controlado e Ultra. A opcao **Pausar animacoes** reduz movimento e efeitos visuais.

## 5. Logs
A fila/log deve permanecer legivel; logs operacionais usam fonte verde e fonte monoespaco.

## 6. Temas
O catalogo contem 36 presets. A profundidade visual oferece 2D, 3D e 4D como camadas de apresentacao, sem mudar regras de seguranca.

## 7. Assistentes e integracoes
Assistentes canonicos: **Júlia**, **Ayella** e **IZART**. Integracoes registradas: **SONPEF**, **CONVGPT**, **KIT_UNICO** e **CHAT_HISTORY**.

## Regra de manutencao
Use sempre um build completo. Nao misture arquivos de rodadas antigas por copia e cola manual.
