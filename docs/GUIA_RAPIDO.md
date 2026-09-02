# GUIA RAPIDO IZGITH

## 1. Abrir
1. Extraia o pacote para uma pasta permanente.
2. Abra `chrome://extensions`.
3. Ative Modo do desenvolvedor.
4. Use Carregar sem compactacao e selecione `extension` (a pasta que contem `manifest.json`).

## 2. Identidade & Host
- O IZGITH funciona sem Native Messaging.
- Use **Testar host** somente para verificar o host nativo instalado.
- Se aparecer OFF, isso significa que o host opcional nao esta instalado ou nao esta registrado; nao e falha do boot da extensao.
- Para instalar o host no Windows, use os instaladores fornecidos no pacote/release e confirme o ID da extensao antes do registro.

## 3. Ferramentas
Use as ferramentas de auditoria e preparacao para inspecionar ZIP/CRX. Operacoes que dependem do host exigem que ele esteja instalado.

## 4. Configuracoes
O modo padrao e **Ultra + Controlado — Unificado**. Tambem existem os modos individuais Controlado e Ultra. `Pausar animacoes` reduz movimento, brilho e efeitos visuais.

## 5. Logs
Os eventos devem ser apresentados de forma legivel e, quando forem logs operacionais, em fonte verde.

## 6. Temas
Existem 36 presets. A profundidade visual suporta 2D, 3D e 4D como camadas de apresentacao; pausar animacoes desliga os efeitos dinamicos.

## Rodada de diagnostico
Se houver erro, primeiro recarregue a extensao em `chrome://extensions`, depois abra Inspecionar visualizacoes e confira o service worker. Nunca copie e cole trechos de arquivos antigos por cima de uma versao nova: use um build completo.
