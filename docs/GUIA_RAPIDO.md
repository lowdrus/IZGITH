# IZGITH — Guia Rápido 00075

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

## 5. ENSH-GERENC

Em **Servidores**, o card **ENSH-GERENC** concentra:

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

### Runtime remoto autorizado

Quando houver um Runtime Agent administrado pelo usuário, informe no card:

1. **Endpoint** do agente remoto.
2. **Bearer token** somente no campo de sessão; nunca o coloque em arquivo versionado.
3. Clique **Verificar** ou **Conectar Runtime**.
4. Com o runtime saudável, **Iniciar** e **Parar** podem solicitar as operações allow-listed ao agente.

O agente do repositório não aceita shell arbitrário. Para execução real, o servidor remoto precisa ter Docker e o Compose do Enshrouded configurados.

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
