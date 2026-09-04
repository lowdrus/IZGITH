# IZGITH — Guia Rápido 00069

## 1. Carregar a extensão sem erro de manifesto

No Chromium, abra `chrome://extensions`, ative **Modo do desenvolvedor** e use **Carregar sem compactação** apontando exatamente para a pasta que contém o `manifest.json` da extensão.

O pacote publicado pelo CI também pode ser extraído e carregado a partir da pasta que contém `manifest.json` diretamente no nível selecionado.

## 2. Ordem da interface

A navegação principal permanece: **Painel Geral → Ferramentas → Servidores → Configurações → Logs → Temas**.

No rodapé ficam **EULA** e **Guia Rápido** como abas informativas. O EULA não é um bloqueio de uso.

## 3. Menus UPPER GITHUB e CONV-D

Os dois menus possuem botão próprio, `aria-expanded`, fechamento ao clicar fora e posicionamento relativo ao card correspondente. Se um menu abrir, ele deve permanecer visualmente preso ao módulo que o originou, sem escapar para outro card.

## 4. Ferramentas

### CONV-D
Ativa/desativa a captura/exportação de conversas suportadas. O botão **Baixar Conversa** aparece nas páginas compatíveis. O usuário escolhe **Tudo** ou **Ultima Rodada** e depois o formato.

### UPPER URL
Cole uma URL HTTPS de conversa. O campo de repositório é apenas o destino pretendido. A abertura é explícita e não envia tokens automaticamente.

### Download por Link
Aceita URLs HTTP/HTTPS diretas e usa a API de downloads do navegador com **Salvar como**. Protocolos como FTP e torrents não são tratados como transporte genérico pela API padrão de downloads da extensão.

### SONPEF
Selecione arquivos `.ps1` e `.py` para unificação local no navegador. O fluxo normal não depende de Native Messaging.

### KIT_UNICO
Hub de integrações e fluxos compartilhados do IZGITH.

### UPPER GITHUB
Prepara arquivos/pastas e registra o destino. Publicações em GitHub devem usar autenticação explícita e permissões adequadas.

### JDOWNLOADER
Oferece integração/atalhos de captura sem instalar ou iniciar o aplicativo externo automaticamente.

## 5. Assistentes

**IZART** — diagnóstico, auditoria, arquitetura e testes.

**Ayella** — orientação, operação, configuração, CONV-D e temas.

**Júlia** — organização, fila, KIT_UNICO, SONPEF e pacotes.

As três ficam no painel inicial e possuem minimizar, fechar e limpar chat.

## 6. Enshrouded Manager

Em **Servidores**, informe nome, host e porta, valide e salve o perfil. O módulo prepara dados e planos; não inicia Docker, Wine, SteamCMD ou executáveis silenciosamente.

Na tela dedicada do **ENSHROUDED MANAGER**, o ícone de expansão abre uma nova janela do próprio módulo. A aparência do ícone segue o padrão `square-arrow-out-up-right` do Lucide.

A referência técnica verificada é `lincolnthalles/enshrouded-container`, que documenta Fedora 44 + Wine 11, Docker 24+, versionamento por Steam manifest, mod injection, backups e configuração por `ENSHROUDED_*`.

## 7. Configurações

**Ultra + Controlado — Unificado:** equilíbrio entre automação interna e salvaguardas.

**Controlado:** prioriza previsibilidade e confirmação.

**Ultra:** reduz interrupções para operações internas suportadas.

**Auto preparar:** organiza dados, arquivos, parâmetros e sequência sem executar etapa externa.

**Auto com confirmação:** prepara a ação e mostra o que será feito; a execução depende da confirmação.

**Manual:** cada etapa é iniciada explicitamente.

## 8. Profundidade visual

**2D:** interface plana e leve.

**3D:** perspectiva e profundidade.

**4D:** movimento e efeitos temporais/dinâmicos.

O IZGITH mantém 36 presets: 26 base + 10 `#coders`.

## 9. Logs

A caixa de logs deve preservar a leitura monoespaçada, rolagem vertical, contraste alto e mensagens sem sobreposição. Erros de uma operação devem permanecer associados à ação que os originou.

## 10. Segurança

Não informe senhas, cookies, tokens ou chaves privadas ao dashboard. O navegador e a extensão não devem ser usados para contornar autenticação de terceiros.
