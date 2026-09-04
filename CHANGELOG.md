# CHANGELOG

## 6.0.0.00066 — host Windows e diagnóstico Git

- Compilação Windows do host e teste do protocolo nativo no executável gerado.
- Instalador BAT/PS1 com configuração exportada pela extensão, registro por usuário e login externo.
- Descoberta de Git/GitHub CLI mesmo quando o Chrome conserva o PATH antigo.
- Handshake obrigatório do host, diagnóstico Git/LFS e limpeza de chamadas interrompidas.
- Testes de mensagens truncadas, concorrência de conexão e falhas de transporte.

## 6.0.0.00065 — integração JDOWNLOADER e publicação confirmada

- Recuperação das bibliotecas, estilos e traduções do RAR MyJDownloader.
- Módulo JDOWNLOADER com caminhos adaptados, identidade única e captura de páginas opcional.
- UPPER GITHUB com seleção local, Git LFS automático a partir de 100 MiB, confirmação e verificação do commit remoto.
- UPPER URL/FORSE-SINC com configuração por conversa exata e revisão do JSON antes da publicação.
- Notificações com ícones Lucide, detalhes de erro e orientação para correção.
- JSON solicitado preservado byte a byte; acesso nativo opcional, sem PAT embutido.
- CI/CodeQL passam a abranger `integracao`; testes de Git/LFS com repositório local, contratos de mensagens e referências HTML.
- ZIP inclui o host Python e o guia atual. Contas externas, instalação Windows e execução ponta a ponta com MyJDownloader precisam de validação no ambiente do usuário.

## 6.0.0.00059 - CONV-D FULL + ROUND EXPORT

- CONV-D exporta a conversa inteira, percorrendo o conteúdo carregado do início ao fim e acumulando mensagens durante a rolagem.
- Adicionada opção de escopo `Tudo — início até o final` ou `Rodada`.
- Em `Rodada`, o usuário escolhe a rodada detectada antes do download.
- O download agora usa o diálogo nativo de salvamento do Chrome (`saveAs`), permitindo escolher a pasta e o nome no próprio computador.
- Removido o comportamento de selecionar automaticamente Excel; nenhum formato é baixado sem escolha explícita.
- Mantidos PDF, Word `.doc`, TXT, Markdown `.md`, JSON estruturado e Excel `.xls`.
- CONV-D passou a usar o contrato `izgith.conv-d.v3` e o service worker centraliza o salvamento.
- Mantidos ChatGPT, Claude, Gemini, Copilot, Perplexity, Grok, DeepSeek, Poe, Le Chat e You.com.
- A identificação do participante usa o ID exposto pela própria página quando disponível; quando a plataforma não o expõe, o exportador não inventa um ID.
- Corrigido o contrato do validador para acompanhar CONV-D v3.
- Sincronizada a versão do pacote, manifesto e registry para 00059.

## 6.0.0.00045 - ULTRA + CONTROLLED UNIFIED

- Consolidado o modo operacional padrão como `unified`, combinando automação Ultra com salvaguardas Controladas.
- Preservada a referência visual/UI da série `IZGITH_v6.0.0.00034_Full_Build`.
- Mantida a ordem de navegação: Identidade & Host, Ferramentas, Configurações, Logs, Temas.
- Mantidos EULA e Guia Rápido como abas informativas no rodapé.
- Service worker endurecido para centralizar Native Messaging e consumir `chrome.runtime.lastError` no ponto correto.
- Dashboard deixou de chamar Native Messaging diretamente e passou a usar o roteamento do service worker.
- Adicionado `SET_MODE` para persistência explícita de `unified`, `controlled` e `ultra`.
- Adicionado par Windows `IZGITH_BUILD_00045.bat` + `IZGITH_BUILD_00045.ps1` para verificação sem sintaxe incompatível com Windows PowerShell antigo.
- Mantidos os 36 temas, SONPEF, CONV-D, KIT_UNICO, CHAT_HISTORY e os assistentes Júlia, Ayella e IZART.
- Native Messaging continua opcional para o boot; sem o host instalado, a extensão deve informar o estado em vez de congelar.

## 6.0.0.00044 - RECOVERY + INTEGRATION HARDENING

- Sincronizada a versão do pacote, popup e documentação para 00044.
- Canonicalizado o Native Messaging para `com.izgith.host` em todos os registros funcionais.
- Native Messaging explicitamente opcional para o boot da extensão.
- Tratamento de `chrome.runtime.lastError` mantido dentro do callback de `onDisconnect`.
- Corrigido o status de integração que anteriormente podia declarar `bootRequired` de forma incorreta.
- Atualizado o inventário de recuperação para distinguir fontes históricas reais de arquivos ainda não recuperados.
- Mantidos SONPEF, CONV-D, KIT_UNICO e CHAT_HISTORY como integrações separadas.
- Mantidos Júlia, Ayella e IZART.
- Mantidos os 36 temas, EULA informativo e Guia Rápido.
- Adicionado par de builders Windows 00044 (`.bat` + `.ps1`) com sintaxe conservadora para Windows PowerShell.

## 6.0.0.00042 - FUNCTIONAL BASELINE

- Endurecido o Manifest MV3 e fixada a versão funcional 00042.
- Service worker revisado para evitar `Unchecked runtime.lastError` durante diagnóstico de Native Messaging.
- Adicionado diagnóstico `NATIVE_HOST_CHECK` sem tornar Native Messaging requisito do boot.
- Adicionado diagnóstico `GET_INTEGRATION_STATUS` para SONPEF, CONV-D, KIT_UNICO e CHAT_HISTORY.
- Adicionado `tools/validate_extension_00042.ps1`, compatível com Windows PowerShell 5.x.
- Confirmada a presença dos caminhos dos quatro ícones no repositório.
- Documentados os limites da recuperação dos arquivos históricos expirados.

## 6.0.0.00041 - INTEGRATION PASS

- Adicionado registro formal das integrações SONPEF, CONV-D, KIT_UNICO e CHAT_HISTORY.
- Registrados os assistentes Júlia, Ayella e IZART.
- Reforçada a regra de que Native Messaging não é requisito para o boot da extensão.
- Adicionados critérios de aceite para Manifest MV3, service worker, UI, ícones, downloads e integrações.
- Mantido o material histórico em `archive/legacy` até promoção individual após revisão.

## Histórico

Versões anteriores e material legado permanecem preservados no arquivo histórico do repositório quando disponíveis.
