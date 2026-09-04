# IZGITH 6.0.0.00065 — instalação e uso

Esta é a versão da branch `integracao`, sem alteração automática da `main`.
Não é uma publicação na Chrome Web Store e não é um fork separado.

## 1. Obter e carregar a extensão

1. No GitHub, abra **Actions → CI** e a execução bem-sucedida da branch `integracao`.
2. Baixe o artefato **IZGITH-extension**. O GitHub pode exigir login para baixar artefatos.
3. Extraia o ZIP do artefato e depois o ZIP `IZGITH_v6.0.0.00065_FULL.zip` contido nele.
4. Mantenha a pasta extraída em um local permanente, como `C:\IZGITH`.
5. No Chrome, abra `chrome://extensions`, ative **Modo do desenvolvedor** e clique em **Carregar sem compactação**.
6. Escolha a pasta `extension` que contém `manifest.json`, não a pasta superior nem a pasta MYJDOWNLOADER.
7. Abra o IZGITH pelo ícone da extensão. O painel e o CONV-D funcionam sem o host.

As confirmações do Chrome são obrigatórias. Uma extensão comum não pode instalar
silenciosamente seu próprio host ou conceder permissões à conta GitHub.

## 2. Preparar publicação GitHub no Windows

Esta preparação é feita uma vez por instalação/ID da extensão:

1. Instale Python 3.11 ou superior, habilitando sua inclusão no PATH.
2. Instale **Git for Windows**, incluindo **Git LFS** e **Git Credential Manager**.
3. Configure a autenticação Git da sua conta pelo Git Credential Manager. O IZGITH
   usa essa autenticação existente; não pede nem guarda um token GitHub.
4. Em `chrome://extensions`, copie o ID de 32 letras do IZGITH.
5. Execute `host\installers\installzipgithub_setup.bat` da pasta extraída.
   Ele verifica Git/LFS, compila o host Python com PyInstaller e pede o ID copiado.
6. Cole o ID quando solicitado. O instalador registra `com.izgith.host` somente
   para essa extensão. Mantenha a pasta do host no mesmo local após o registro.
7. Reinicie o Chrome. No primeiro uso de UPPER GITHUB, autorize o acesso nativo solicitado.

O pacote não inclui um executável Git/LFS nem instala dependências sem consentimento.
O **suporte LFS está integrado ao fluxo**, usando os programas instalados no sistema.
No Linux/macOS, utilize o instalador do host compatível e instale Git/LFS pelo
gerenciador de pacotes do sistema. As janelas de seleção exigem suporte Tkinter.

## 3. UPPER GITHUB

1. Abra **Ferramentas → UPPER GITHUB**.
2. Informe `https://github.com/usuario/repositorio`. O repositório deve existir,
   ter uma branch padrão inicializada e permitir escrita à conta autenticada.
3. Clique em **Selecionar arquivos** ou **Selecionar pasta**. A janela do sistema
   faz a seleção; arquivos grandes não precisam atravessar mensagens do Chrome.
4. Confira a lista e clique em **Enviar**.
5. O host prepara um clone temporário, aplica Git LFS quando necessário e mostra
   destino, branch padrão, quantidade de arquivos e aviso de visibilidade/cotas.
6. Confirme para publicar. Nomes existentes serão substituídos. Uma pasta selecionada
   é enviada com seu próprio nome; arquivos selecionados individualmente vão à raiz.
7. A mensagem de sucesso só aparece após verificar o SHA do commit remoto. Se o
   conteúdo já for igual, o módulo informa que não houve alterações.

Arquivos de 100 MiB ou mais usam LFS. O limite conservador é 2 GB por arquivo;
limites e cobranças da conta GitHub continuam valendo. São recusados links
simbólicos, caminhos perigosos, alguns arquivos sensíveis e possíveis tokens/chaves.
Essa checagem não substitui a revisão humana de dados pessoais e segredos.

Conflitos, proteção de branch, falta de permissão e falta de cota interrompem a
operação. Não há `push --force`, rebase automático ou tentativa de outra credencial.
Não feche o painel durante uma publicação. Após timeout ou desconexão, confira o
GitHub antes de repetir: a operação remota pode ter concluído sem retorno ao painel.

## 4. UPPER URL / FORSE-SINC

1. Em **UPPER URL**, cole a URL exata da conversa ChatGPT e o repositório de destino.
2. Clique em **Ativar FORSE-SINC**. A conversa será aberta.
3. Clique em **FORSE-SINC** dentro dessa conversa.
4. A tela do IZGITH mostra o JSON das mensagens carregadas e visíveis. Revise-o.
5. Marque a autorização e clique em **Publicar no GitHub**. Confirme também no host.
6. Após confirmar o commit remoto, o IZGITH exibe **O conteúdo foi publicado no GitHub!**.
7. Para interromper o recurso, volte ao painel e clique em **Desativar FORSE-SINC**.

O recurso não interpreta frases do chat como autorização automática. Não recupera
conversas privadas pelo simples link, histórico ainda não carregado, anexos ou
arquivos de outras rodadas. Publica o JSON revisado em `conversations/` com nome
derivado do conteúdo. Limite: 4 MiB por revisão; a revisão expira após 10 minutos.
O conteúdo transitório fica na sessão da extensão e é removido após publicação ou cancelamento.

## 5. JDOWNLOADER

1. Instale e abra seu JDownloader no computador e conecte-o à sua conta MyJDownloader.
2. Em **Ferramentas → JDOWNLOADER**, clique em **Abrir JDOWNLOADER**.
3. Entre com a conta MyJDownloader, escolha o dispositivo e envie os links pelo painel.
4. Se desejar integração nas páginas, ative **captura de páginas** e autorize o
   acesso aos sites. Depois, recarregue as páginas em que pretende utilizá-la.
5. Desativar a captura impede novas injeções. Recarregue abas já abertas para
   remover scripts que já estavam executando nelas.

As credenciais/sessões MyJDownloader são distintas da autenticação GitHub. O cliente
original usa armazenamento local para manter sua sessão. Saia da conta no painel
em computadores compartilhados. As fontes e avisos de licença originais foram preservados.
O arquivo `selectionContentscript.js` recebido está vazio e não foi registrado;
o fluxo de seleção existente utiliza `onCopyContentscript.js`.

## 6. Erros

As novas interfaces mostram **Algo deu errado.**, com bomba e lupa. Clique na lupa
para ver o detalhe e a orientação. Falhas tratadas internamente pelo cliente
MyJDownloader também podem aparecer nas mensagens próprias desse cliente.

- **Host not found:** execute o instalador, confira ID e caminho e reinicie Chrome.
- **Host forbidden:** o ID carregado difere daquele registrado no instalador.
- **Falha Git/LFS:** confira login Git, acesso ao repositório, branch protegida,
  conexão, Git LFS instalado e cota. Não envie credenciais em conversas.
- **Conversa vazia:** aguarde mensagens carregarem e confira a URL configurada.
- **Revisão aberta:** conclua ou cancele a revisão anterior; revisões abandonadas expiram.
- **Dispositivo ausente:** confira o login e o JDownloader conectado à mesma conta.

## 7. Verificação e limites desta entrega

Execute na raiz do código-fonte: `npm test`, `npm run package`,
`python -m compileall -q host scripts tools tests` e `git diff --check`.
O build de referência é `build/IZGITH_BUILD.bat` com `IZGITH_BUILD.ps1` ao lado.
`python scripts/build_jdownloader.py` regenera o módulo a partir das fontes preservadas.

Os testes cobrem sintaxe, estrutura, referências HTML, mensagens, recusa de origens,
cancelamento e ciclo Git/LFS com um destino local de teste. Não comprovam login
MyJDownloader, downloads reais de dispositivos, CAPTCHAs, instalação Windows ou
publicação com as credenciais do usuário. Esses testes ponta a ponta continuam pendentes.
O legado arquivado não foi todo convertido em funcionalidades e os assistentes
locais não são modelos de IA conectados. Ações antigas falhadas não são apagadas:
uma nova execução valida o commit novo.

## Referências

- Git LFS: https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage
- Native Messaging: https://developer.chrome.com/docs/extensions/develop/concepts/native-messaging
- Licença dos ícones: https://lucide.dev/license
