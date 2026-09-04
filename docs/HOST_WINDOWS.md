# Host e Git no Windows — 00066

O host permite selecionar arquivos locais e publicar pelo UPPER GITHUB. A extensão
sozinha não instala programas nem concede permissões no GitHub.

## Instalação assistida

1. Carregue a pasta `extension` da versão 00066 em `chrome://extensions`, usando
   **Modo do desenvolvedor → Carregar sem compactação**. Mantenha essa pasta no mesmo local.
2. No IZGITH, abra **Ferramentas → UPPER GITHUB → Baixar configuração do host**.
   Salve `izgith-host-config.json` em Downloads. Esse arquivo contém apenas o ID da extensão.
3. Abra [Host Windows no GitHub Actions](https://github.com/lowdrus/IZGITH/actions/workflows/host-windows.yml),
   escolha uma execução concluída com sucesso da branch `integracao` e baixe o artefato
   **IZGITH-Windows-Host**. O GitHub pode solicitar login para baixar artefatos.
4. Extraia todo o ZIP. Execute `INSTALAR_IZGITH_HOST.bat`, mantendo o PS1 e o EXE
   na mesma pasta. Não é necessário instalar Python nem compilar no computador.
5. Confirme a instalação. Se solicitado, selecione o JSON do passo 2. O instalador
   oferece instalar Git e GitHub CLI usando winget e verifica Git LFS.
6. Autorize o login no fluxo oficial do GitHub aberto pelo GitHub CLI. Não envie
   tokens para a conversa ou para arquivos do projeto. O gerenciador de credenciais
   externo cuida da autenticação; o IZGITH não pede um PAT.
7. Feche completamente e reabra o Chrome. Clique em **Verificar host/Git** e
   permita Native Messaging quando o Chrome solicitar.
8. Informe o repositório, selecione arquivos ou pasta e envie. Revise a confirmação
   local. O sucesso só é mostrado depois da publicação e da conferência do SHA remoto.

O instalador registra somente o ID escolhido, para o usuário atual, e guarda o
host em `%LOCALAPPDATA%\IZGITH\host`. Se o ID mudar, execute novamente com a nova
configuração. O pacote de código-fonte FULL não contém o EXE: use o artefato Windows.

## Diagnóstico

- **Host não encontrado:** confira se executou o instalador e reiniciou o Chrome.
- **Host proibido:** gere novamente o JSON da extensão instalada e reinstale.
- **Git/LFS ausente:** execute o instalador novamente; winget precisa estar disponível.
- **Login ausente:** refaça a etapa de login. Permissões de escrita dependem da conta,
  do repositório e das regras da branch; o diagnóstico não concede essas permissões.
- **Política do PowerShell ou proteção do Windows bloqueou:** pare e consulte o
  administrador. Não desative proteções. O executável não possui assinatura comercial.
- **Push rejeitado:** confira a permissão e as regras do repositório. Não há force-push
  nem tentativa de contornar bloqueios. Consulte os detalhes pela lupa na notificação.

Arquivos a partir de 100 MiB usam Git LFS; há limite de 2 GB por arquivo no módulo,
além dos limites e cotas do serviço. Arquivos sensíveis e links simbólicos são rejeitados.
Conversas só são publicadas após revisão e ação explícita. Não há sincronização secreta.

## Verificação automática

O workflow Windows compila o host, testa mensagens nativas reais e valida o
instalador em PowerShell sem alterar o registro nem efetuar login. Os testes locais
verificam Git/LFS com repositório isolado. Isso não substitui a primeira verificação
no Chrome e na conta GitHub do usuário.
