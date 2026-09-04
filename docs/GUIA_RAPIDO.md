# IZGITH — Guia Rápido 00068

## 1. Carregar a extensão sem erro de manifesto

Há duas formas válidas:

- **Desenvolvimento:** abra `chrome://extensions`, ative **Modo do desenvolvedor** e use **Carregar sem compactação** apontando para `IZGITH/extension/`, onde `manifest.json` fica diretamente na raiz da árvore distribuível.
- **Pacote CI:** extraia o ZIP gerado e selecione a pasta que contém `manifest.json` diretamente na raiz.

Não selecione uma pasta pai que contenha outra pasta `IZGITH_v...`; o manifesto precisa estar no nível escolhido pelo Chrome.

## 2. Central De Ferramentas

### CONV-D
Ativa/desativa a captura/exportação de conversas suportadas. O botão **Baixar Conversa** aparece nas páginas de conversa suportadas. O usuário escolhe **Tudo** ou **Ultima Rodada** e depois o formato.

### UPPER URL
Cole uma URL HTTPS de conversa. O campo de repositório é apenas o destino pretendido. A abertura é explícita e não envia tokens automaticamente.

### Download por Link
Aceita URLs HTTP/HTTPS diretas e usa a API de downloads do navegador. FTP, SMTP, POP e torrents não são transportes genéricos oferecidos pela API de downloads da extensão.

### SONPEF
Selecione arquivos `.ps1` e `.py` para unificação local no navegador. O fluxo não depende de Native Messaging.

### KIT_UNICO
Hub de integrações e fluxos compartilhados do IZGITH.

### Selecionar .ZIP/.CRX
Escolha um pacote local para conferir nome, tamanho e extensão antes de inspeção, auditoria ou instalação.

### UPPER GITHUB
Prepara arquivos/pastas e registra o destino. Publicações em GitHub devem usar autenticação explícita e permissões adequadas.

### JDOWNLOADER
Fornece integração/atalhos de captura sem instalar ou iniciar o aplicativo externo automaticamente.

## 3. Menus

Os menus de **CONV-D** e **UPPER GITHUB** são alternáveis e ancorados aos seus cards. Clique no ícone para abrir/fechar; clique fora ou pressione **Escape** para recolher. O estado é controlado pelo atributo `aria-expanded`.

## 4. Assistentes

**IZART** — diagnóstico, auditoria, arquitetura e testes.

**Ayella** — orientação, operação, configuração, CONV-D e temas.

**Júlia** — organização, fila, KIT_UNICO, SONPEF e pacotes.

As três conversas ficam dentro do painel inicial e possuem **minimizar**, **fechar** e **limpar chat**.

## 5. Enshrouded Manager

Em **Servidores**, informe nome, host e porta, valide e salve o perfil. O ícone ao lado de **ENSHROUDED MANAGER** abre a tela dedicada interna do IZGITH em nova aba. O módulo prepara dados; não inicia Docker, Wine, SteamCMD ou executáveis silenciosamente.

## 6. Configurações

**Ultra + Controlado — Unificado:** equilíbrio entre automação interna e salvaguardas.

**Controlado:** prioriza previsibilidade e confirmação.

**Ultra:** reduz interrupções para operações internas suportadas.

**Auto preparar:** organiza dados, arquivos, parâmetros e sequência sem executar etapa externa.

**Auto com confirmação:** prepara a ação e mostra o que será feito; a execução depende da confirmação.

**Manual:** cada etapa é iniciada explicitamente.

## 7. Profundidade visual

**2D:** interface plana e leve.

**3D:** perspectiva e profundidade.

**4D:** movimento e efeitos temporais/dinâmicos.

Os três modos são aplicados por `data-depth` e podem ser trocados em Configurações.

## 8. Janela

**—** minimiza somente a janela do IZGITH.

**×** fecha somente a janela do IZGITH.

## 9. Segurança

Não informe senhas, cookies, tokens ou chaves privadas ao dashboard. O navegador e a extensão não devem ser usados para contornar autenticação de terceiros.
