# IZGITH — Guia Rápido 00076

## 1. Carregar a extensão sem erro de manifesto

No Chrome, abra `chrome://extensions`, ative **Modo do desenvolvedor** e use **Carregar sem compactação** apontando para:

`IZGITH/extension/`

A pasta escolhida precisa conter `manifest.json` diretamente. Não selecione uma pasta pai que contenha outra pasta `IZGITH`.

## 2. Central De Ferramentas

### CONV-D
Ativa/desativa a captura/exportação de conversas suportadas. O botão **Baixar Conversa** aparece nas páginas de conversa suportadas. O usuário escolhe **Tudo** ou **Ultima Rodada** e depois o formato.

### UPPER URL
Cole uma URL HTTPS de conversa. UPPER URL abre a conversa indicada; ele não define nem usa o destino do UPPER GITHUB.

### UPPER GITHUB
Mantém seu próprio destino de repositório e seu próprio estado. Publicações usam autenticação explícita; nenhum token é coletado silenciosamente.

### Download por Link
Aceita URLs HTTP/HTTPS diretas e usa a API de downloads do navegador. FTP, SMTP, POP e torrents não são transportes genéricos oferecidos pela API de downloads da extensão.

### SONPEF
Selecione arquivos `.ps1` e `.py` para unificação local no navegador. O fluxo não depende de Native Messaging.

### KIT_UNICO
Hub de integrações e fluxos compartilhados do IZGITH.

### Selecionar .ZIP/.CRX
Escolha um pacote local para conferir nome, tamanho e extensão antes de inspeção, auditoria ou instalação.

## 3. Menus

Os menus de **CONV-D** e **UPPER GITHUB** são alternáveis. Clique no ícone para abrir/fechar; clique fora para recolher. O estado é acompanhado por `aria-expanded`.

## 4. Assistentes

**IZART** — diagnóstico, auditoria, arquitetura e testes.

**Ayella** — orientação, operação, configuração, CONV-D e temas.

**Júlia** — organização, fila, KIT_UNICO, SONPEF e pacotes.

As três conversas ficam dentro do painel inicial e possuem **minimizar**, **fechar** e **limpar chat**.

## 5. ENSH-GERENC / ENSHGERENC

O **ENSHGERENC** concentra os controles operacionais em um único painel:

- Salvar perfil
- Validar
- Limpar
- Baixar Config
- Baixar Compose
- Baixar Plano
- Verificar
- Preparar Instalação
- Preparar Início
- Preparar Parada
- Backup
- Restaurar
- Retenção
- Mods
- Recursos
- Versão

O modo plano prepara dados sem iniciar processos externos.

### Runtime Agent

O painel agora expõe um contrato explícito para agentes runtime:

- endpoint padrão: `http://127.0.0.1:38751`
- health: `GET /health`
- operações: `POST /v1/operations/<operação>`
- autenticação: `Authorization: Bearer <token>` somente em sessão
- operações allow-listed; shell arbitrário e argumentos Docker arbitrários são proibidos

Informe o endpoint e, se necessário, o Bearer token em **Configurações**. O token fica apenas em `sessionStorage` durante a sessão e não é versionado.

A arquitetura continua separando **Browser → Runtime Agent → Docker Engine**. A extensão não executa Docker, Wine ou SteamCMD diretamente.

O contrato detalhado está em `integrations/ENSHROUDED_MANAGER/runtime-agent-endpoint.json` e `integrations/ENSHROUDED_MANAGER/runtime-contract.json`.

### Referência ENSHROUDED

O modelo de servidor é alinhado ao projeto `lincolnthalles/enshrouded-container`, que documenta version pinning, mods, configuração por `ENSHROUDED_*`, backups agendados e por desligamento, polling de recursos e as portas 15636/15637/27015.

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

## 8. Janela

**—** minimiza somente a janela do IZGITH.

**×** fecha somente a janela do IZGITH.

## 9. Segurança

Não informe senhas, cookies, tokens ou chaves privadas ao dashboard. Runtime remoto deve ser protegido por TLS/VPN/rede privada. O usuário continua responsável por autorizar o servidor e os dados que administra.
