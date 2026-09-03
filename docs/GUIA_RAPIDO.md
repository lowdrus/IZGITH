# GUIA RAPIDO IZGITH

## 1. Abrir
1. Extraia o pacote para uma pasta permanente.
2. Abra `chrome://extensions`.
3. Ative Modo do desenvolvedor.
4. Use **Carregar sem compactacao** e selecione `extension` (a pasta que contem `manifest.json`).

## 2. Painel Geral e janelas
- **Sistema Ativo** indica o estado visual do painel.
- **—** minimiza o painel dedicado e devolve o foco ao navegador sem fechar o navegador.
- **×** fecha somente a janela do IZGITH.
- Nas conversas das assistentes, **—**, **×** e **Limpar chat** atuam somente no chat da assistente.

## 3. CONV-D
- **Ativar CONV** liga/desliga a insercao do botao **Baixar Conversa** nas plataformas suportadas.
- Na propria conversa, escolha **Tudo** para a conversa inteira ou **Ultima Rodada** para a ultima rodada detectada.
- Depois escolha um unico formato: **PDF, Word .doc, TXT, Markdown .md, JSON estruturado ou Excel .xls**.
- O navegador abre o dialogo de salvamento para que o usuario escolha onde guardar o arquivo. Nenhum formato e escolhido automaticamente.
- O exportador preserva o papel detectado de usuario/assistente e IDs de mensagem quando a plataforma os expoe; ele nao inventa um ID privado.

## 4. CONVERSAS POR URL
- Cole a URL completa de uma conversa suportada.
- Opcionalmente informe o repositorio GitHub de destino como referencia do fluxo.
- O modulo valida a URL e abre a conversa autenticada no navegador; o CONV-D trabalha no contexto dessa pagina.
- O modulo **nao executa force-push**, nao embute tokens e nao publica uma conversa privada automaticamente. Isso evita sobrescrita destrutiva e vazamento de credenciais.

## 5. Download por Link
- Para arquivos, use URL **HTTP/HTTPS** e o navegador exibira o dialogo de destino.
- Para uma URL de conversa suportada, o modulo abre a conversa e o CONV-D aparece apos o carregamento.
- SMTP/POP nao sao URLs de download suportadas pela API `chrome.downloads`; FTP tambem pode ser bloqueado pelo navegador. Nao confunda protocolos de correio com uma URL web de arquivo.

## 6. Fila Rapida
Selecione varios arquivos locais. O IZGITH grava apenas metadados basicos na fila local (nome, tamanho, tipo e data). Use quando tiver muitos pacotes e quiser organiza-los antes de auditoria ou empacotamento.

## 7. Selecionar .ZIP/.CRX
Use quando recebeu uma extensao empacotada. Selecione um ou varios `.zip`/`.crx`; eles entram na fila para uma etapa posterior de auditoria/extracao. O ato de selecionar nao instala nem executa o pacote.

## 8. SONPEF
Selecione `.ps1` e `.py` no navegador. O IZGITH le os arquivos escolhidos e gera uma unificacao textual local. Nao e necessario Native Messaging para essa operacao.

## 9. Assistentes
**IZART**, **Ayella** e **Júlia** ficam em **Assistentes** na pagina inicial. Cada uma abre seu chat abaixo dos cards, com **Limpar chat**, fechar e minimizar. O comportamento atual e um hub local orientativo; ele nao finge ser uma API de LLM externa.

## 10. Configuracoes
- **Ultra + Controlado — Unificado:** equilibrio entre automacao e salvaguardas.
- **Controlado:** privilegia previsibilidade e confirmacao.
- **Ultra:** privilegia velocidade dentro das permissoes do navegador.
- **Auto preparar:** monta dados, arquivos e parametros sem executar etapa externa.
- **Auto com confirmacao:** prepara e mostra a acao antes da efetivacao.
- **Manual:** cada etapa e iniciada pelo usuario.

## 11. Temas
Sao 36 presets. A profundidade visual agora tem comportamento efetivo:
- **2D:** apresentacao plana e leve.
- **3D:** profundidade e movimento suave.
- **4D:** profundidade, movimento temporal e animacoes adicionais.

## 12. Diagnostico
Se a extensao nao carregar, recarregue-a em `chrome://extensions` e abra Inspecionar visualizacoes. O Manifest V3 e o service worker sao validados pelo CI. Prefira sempre um build completo, em vez de copiar trechos de versoes antigas por cima da arvore nova.
