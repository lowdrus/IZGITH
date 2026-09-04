# Guia Rápido — IZGITH

**Versão documentada: 6.0.0.00067 · Rodada 00067**

## 1. Abrir a extensão

No Chromium, abra `chrome://extensions`, ative o **Modo do desenvolvedor** e carregue **a pasta `extension/`** como extensão descompactada. O `manifest.json` precisa estar diretamente dentro dessa pasta.

## 2. Central De Ferramentas

### CONV-D
Ativa/desativa o módulo de exportação de conversas. Nas páginas de conversa suportadas, **Baixar Conversa** permite escolher `Tudo` ou `Ultima Rodada` e depois o formato antes do salvamento.

### UPPER URL
Cole a URL HTTPS de uma conversa suportada. O segundo campo é o repositório GitHub pretendido. O menu de UPPER URL fica ancorado ao card e pode ser aberto/fechado pelo ícone de menu.

### Download por Link
Cole uma URL **HTTP/HTTPS direta** para um arquivo e use o ícone de download. O navegador abre o diálogo de salvamento quando configurado para isso. FTP, SMTP, POP e torrents não são transportes genéricos suportados pela API de downloads do navegador.

### SONPEF
Selecione arquivos `.ps1` e `.py`. O módulo reúne o conteúdo em uma saída unificada no navegador, sem exigir executor local.

### KIT_UNICO
É o hub lógico das integrações e papéis compartilhados do IZGITH.

### Selecionar .ZIP/.CRX
Selecione um pacote local quando quiser conferir o arquivo antes de inspeção, auditoria ou instalação. O módulo não instala automaticamente o pacote.

### UPPER GITHUB
Use o menu para selecionar arquivos/pastas e verificar o estado de integração. A publicação efetiva exige autenticação explícita; o IZGITH não coleta credenciais silenciosamente.

### JDOWNLOADER
A interface registra atalhos de integração/captura, mas não instala nem inicia o aplicativo externo automaticamente.

## 3. Fila Rápida

A Fila Rápida é um espaço de preparação e acompanhamento. Ela permite manter itens organizados antes de uma etapa posterior, sem disparar operações externas escondidas.

## 4. Assistentes

**IZART**, **Ayella** e **Júlia** aparecem na página inicial. Clique em uma delas para abrir o chat no próprio painel. Use **Limpar chat** para reiniciar a conversa e **×** para fechar apenas o painel da assistente.

## 5. Janela do IZGITH

- `—` = minimiza somente a janela do IZGITH.
- `×` = fecha somente a janela do IZGITH.
- O navegador não é encerrado.

## 6. Temas e profundidade

Há **36 temas**. A profundidade pode ser `2D`, `3D` ou `4D`:

- **2D:** visual plano e leve.
- **3D:** perspectiva e profundidade.
- **4D:** camada dinâmica com movimento e variação temporal.

**Aleatório** escolhe um tema e sua profundidade automaticamente.

## 7. Modos operacionais

- **Ultra + Controlado — Unificado:** automatiza tarefas internas e mantém ações sensíveis sob controle.
- **Controlado:** prioriza previsibilidade e confirmação.
- **Ultra:** reduz interrupções para tarefas locais suportadas.

## 8. Modos automáticos

- **Auto preparar:** organiza dados, arquivos, parâmetros e sequência, mas não executa uma etapa externa sozinho.
- **Auto com confirmação:** prepara a ação, mostra o que será feito e aguarda confirmação antes da etapa efetiva.
- **Manual:** cada etapa é iniciada pelo usuário.

## 9. Enshrouded Manager

O módulo mantém perfis de servidor, valida host/porta e prepara configurações, compose e planos. A implementação atual é deliberadamente **browser-plan-only**: não inicia Docker, Wine, SteamCMD ou processos do sistema sem uma integração externa explicitamente autorizada.

A referência pública usada para a arquitetura é `lincolnthalles/enshrouded-container`. Ela atualmente documenta Fedora 44 + Wine 11, Docker 24+, version pinning por manifest, mod injection, configuração por variáveis `ENSHROUDED_*`, backups automatizados, polling de recursos e volumes persistentes. O IZGITH usa essas informações como referência de composição/documentação, sem executar o projeto de referência automaticamente.
