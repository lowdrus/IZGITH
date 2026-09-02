# Tutorial completo — instalar e usar o IZGITH

## 1. Baixar a extensão

1. Abra o repositório `lowdrus/IZGITH` no GitHub.
2. Entre em **Actions** e abra a execução verde mais recente chamada **CI**.
3. Em **Artifacts**, baixe **IZGITH-extension**. Em versões oficiais, você também pode usar o arquivo `IZGITH-extension-vX.Y.Z.zip` da página **Releases**.
4. Clique com o botão direito no ZIP, escolha **Extrair tudo** e use uma pasta permanente, por exemplo `C:\IZGITH\extension`.
5. Confirme que essa pasta contém `manifest.json`, `popup.html` e `background.js` diretamente. Se houver uma pasta intermediária, abra-a.

## 2. Carregar no Google Chrome

1. Digite `chrome://extensions` na barra de endereços.
2. Ative **Modo do desenvolvedor**, no canto superior direito.
3. Clique em **Carregar sem compactação**.
4. Selecione a pasta da etapa anterior e confirme.
5. Verifique se o cartão mostra **IZGITH**, sem erros.
6. Clique no ícone de quebra-cabeça do Chrome e fixe o IZGITH.

Depois de atualizar os arquivos, volte a `chrome://extensions` e clique no botão de recarregar do cartão IZGITH.

## 3. Uso básico sem host local

### Baixar um pacote

1. Abra o popup do IZGITH.
2. Cole um endereço começando com `https://` ou `http://`.
3. Clique em **Baixar** e escolha onde salvar.

### Montar a fila

1. Arraste arquivos `.zip` ou `.crx` para a área pontilhada, ou clique para selecionar.
2. O contador mostra quantos pacotes foram reconhecidos.
3. Clique em **Abrir painel** para ver a fila e as demais ferramentas.

### Consultar uma release do GitHub

1. No painel, abra **GitHub Monitor**.
2. Informe o repositório no formato `proprietario/repositorio`, por exemplo `lowdrus/IZGITH`.
3. Clique em **Consultar release**. Repositórios públicos não precisam de token.

## 4. Instalar o host local opcional no Windows

O host habilita seleção de pastas pelo sistema, auditoria, preparação de ZIP/CRX e Secure Lab. Instale Python 3.11 ou superior em `python.org` e marque **Add Python to PATH**.

1. Baixe `IZGITH-host-source` em **Releases** e extraia para `C:\IZGITH\host`.
2. Em `chrome://extensions`, copie o ID exibido no cartão IZGITH. Ele tem 32 letras.
3. Abra o PowerShell dentro da pasta do host.
4. Execute:

```powershell
python .\install_host.py --extension-id COLE_AQUI_O_ID --browser chrome
```

5. Feche completamente o Chrome e abra-o novamente.
6. Abra o painel do IZGITH e clique em **Diagnóstico do host**. O estado deve mudar para **OK**.

Se usar o instalador `.bat`, execute-o somente a partir do pacote oficial e informe o mesmo ID quando solicitado.

## 5. Linux e macOS

Na pasta `host`, execute:

```bash
python3 install_host.py --extension-id ID_DA_EXTENSAO --browser chrome
```

Para Chromium, Edge ou Brave, substitua `chrome` por `chromium`, `edge` ou `brave`. Nem todos os navegadores estão disponíveis em todos os sistemas.

## 6. Auditar e preparar extensões

1. Abra o painel e entre em **Preparar**.
2. Use **Selecionar pasta** para avaliar uma extensão já extraída.
3. Use **Selecionar pacote** para extrair e avaliar ZIP/CRX.
4. Leia a pontuação e os achados. Pontuação alta reduz sinais conhecidos, mas não garante que o código seja seguro.
5. Para testar, vá a **Secure Lab** e escolha uma pasta com `manifest.json`. O IZGITH abre um novo perfil temporário do navegador.

Nunca use o perfil principal para testar código desconhecido.

## 7. Atualizações automáticas do repositório

Cada `push` ou pull request executa automaticamente:

- validação do Manifest V3, HTML e JavaScript;
- compilação e testes Python;
- verificação do instalador shell;
- criação do ZIP instalável;
- análise CodeQL separada para JavaScript e Python.

Tags no formato `vX.Y.Z`, iguais à versão do `extension/manifest.json`, criam uma release e anexos automaticamente.

## 8. Solução de problemas

- **Manifest ausente:** selecione a pasta que contém `manifest.json`, não a pasta acima dela.
- **Host não encontrado:** repita a instalação com o ID atual e reinicie todo o Chrome.
- **ID mudou:** isso pode acontecer se a extensão for removida e carregada de outro caminho; registre novamente o host.
- **CRX recusado:** o Chrome pode impedir CRX externo. Prepare o pacote e use **Carregar sem compactação**.
- **Release não encontrada:** o repositório precisa ser público e ter pelo menos uma release publicada.
- **Botão com erro após editar arquivos:** abra `chrome://extensions`, clique em **Erros**, corrija e recarregue.
