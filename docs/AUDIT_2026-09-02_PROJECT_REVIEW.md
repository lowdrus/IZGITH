# IZGITH — revisão técnica consolidada

Data: 2026-09-02

## Escopo

Esta revisão consolida os requisitos recorrentes do projeto IZGITH registrados na conversa e confronta-os com o estado atualmente versionado neste repositório.

## Base atualmente presente no repositório

- Extensão Manifest V3 em `extension/`.
- Service worker em `extension/sw.js`.
- UI em `extension/ui/`.
- Catálogo de temas em `extension/themes/catalog.json`.
- Script de validação em `scripts/validate_project.py`.
- Native Messaging em `host/host.py` e `host/install_host.py`.
- Instalador do host em `host/installers/`.
- Ponte de histórico em `extension/scripts/chat_history_bridge.js`.
- Documentação em `docs/`.
- Áreas de integração em `integrations/`.

## Requisitos consolidados da conversa

1. Preservar a UI de referência IZGITH v6.0.0.00034_Full_Build.
2. Manter 36 temas: 26 temas principais + 10 temas #coders, incluindo apresentação 3D/4D e emojis.
3. Ordem fixa: Identidade & Host → Ferramentas → Configurações → Logs → Temas.
4. Native Messaging deve usar o ID real da extensão e o mesmo nome de host em todos os pontos.
5. Os erros históricos a evitar incluem: service worker status 15, host forbidden/not found, canal fechado, PowerShell 5 incompatível com `?.`, hashes malformados, `type="popup"` escrito como `type="popup"` (nunca `type="popup"` com atribuição em objeto JS), e arquivos de ícone ausentes/corrompidos.
6. CONVGPT deve ser uma integração para exportação do histórico selecionado do ChatGPT; a implementação final deve respeitar as APIs e permissões realmente disponíveis, sem prometer acesso a dados que a extensão não consegue obter.
7. KIT_UNICO deve ser tratado como fonte dos componentes das assistentes Júlia, Ayelle/Ayella e IZART, mas os arquivos originais precisam estar disponíveis para integração fiel.
8. SONPEF deve permitir execução da rotina de unificação de `.ps1`/`.py` sem exigir terminal como fluxo normal da UI; a implementação precisa de um mecanismo local autorizado (por exemplo, Native Messaging) para executar scripts no Windows.
9. EULA e Guia Rápido devem ser informativos; o EULA não deve bloquear o uso da extensão.
10. Atualizações futuras devem ser entregues como pacote completo, evitando substituições manuais arquivo a arquivo.
11. Builder `.bat` e `.ps1` devem ser irmãos na mesma pasta e ser compatíveis com Windows PowerShell 5.1 e PowerShell 7+, evitando sintaxe exclusiva de versões novas.
12. Logs devem permanecer legíveis, com texto verde conforme o padrão visual solicitado.

## Achados técnicos importantes

### 1. Service worker

O `extension/sw.js` atualmente versionado não contém o erro histórico `type="popup"`/`type=...` que causava `Invalid shorthand property initializer`. A linha correta em objetos JavaScript é `type: "popup"`.

O Manifest V3 aponta `background.service_worker` para `sw.js`, portanto o arquivo deve permanecer na raiz de `extension/` e ser JavaScript puro, sem conteúdo PowerShell, JSON ou heredoc.

### 2. Native Messaging

O host atual do repositório usa o identificador `com.izgith.host`. Todos os pontos de conexão da extensão e o manifesto instalado no Windows precisam usar exatamente o mesmo nome.

O erro histórico `Specified native messaging host not found/forbidden` não é resolvido apenas pelo JavaScript: é necessário existir um manifesto de Native Messaging registrado no local correto do Windows, com `allowed_origins` contendo exatamente `chrome-extension://<EXTENSION_ID>/` e apontando para um executável existente.

### 3. Compatibilidade PowerShell

PowerShell 5.1 não suporta o operador de encadeamento nulo `?.` usado nos builders antigos. A forma compatível é obter o objeto primeiro e testar explicitamente, por exemplo:

```powershell
$cscCommand = Get-Command csc.exe -ErrorAction SilentlyContinue
$csc = $null
if ($null -ne $cscCommand) { $csc = $cscCommand.Source }
```

Builders também não devem usar variáveis chamadas `$Host`, pois `$Host` é uma variável automática somente leitura do PowerShell. Use nomes como `$HostDir`.

### 4. Codificação

Os erros `IZGITHâ„¢`, `Ã§`, `Ã£` e semelhantes indicam corrupção de UTF-8 durante a geração/execução dos scripts. Builders devem escrever arquivos em UTF-8 de forma controlada e evitar inserir JavaScript/JSON diretamente em strings PowerShell frágeis. Arquivos de código devem ser gerados como conteúdo literal seguro ou copiados como arquivos irmãos.

### 5. Ícones

O Manifesto referencia `ui/assets/icons/icon16.png`, `icon32.png`, `icon48.png` e `icon128.png`. Esses quatro arquivos precisam existir dentro de `extension/ui/assets/icons/` antes de carregar a extensão. Arquivos PNG inválidos ou apenas placeholders também devem ser rejeitados pelo validador.

### 6. Histórico do ChatGPT / CONVGPT

O arquivo atualmente versionado `extension/scripts/chat_history_bridge.js` é apenas uma função de normalização de registros; ele não constitui, sozinho, um mecanismo de exportação do histórico completo do ChatGPT. A implementação final deve separar claramente: coleta autorizada dos dados disponíveis, normalização, geração de Markdown/HTML e salvamento via `chrome.downloads`.

### 7. SONPEF / KIT_UNICO

Os requisitos históricos são conhecidos, mas os arquivos originais enviados em conversas anteriores não estão todos disponíveis neste ambiente. Não é correto fabricar uma cópia "idêntica" desses arquivos. Quando os ZIPs originais do KIT_UNICO/SONPEF forem reenviados, eles devem ser incorporados integralmente e versionados como fonte, preservando licença, autoria e estrutura.

## Critério para o próximo build

O próximo pacote deve ser considerado pronto somente quando:

- `manifest.json` for JSON válido;
- `background.service_worker` apontar para um `sw.js` existente;
- os quatro PNGs forem arquivos reais e válidos;
- o JavaScript do service worker passar por validação sintática;
- não houver sintaxe PowerShell incompatível com 5.1;
- nenhum script usar `$Host` como variável;
- o nome do Native Host for único e consistente;
- o manifesto do Native Host for gerado com o ID real da extensão;
- a UI mantiver a ordem e a caixa de logs definidas;
- os 36 temas estiverem efetivamente presentes no catálogo/UI;
- integrações ausentes forem marcadas como pendentes, e não simuladas.

## Limitação de recuperação de arquivos

Alguns anexos de conversas anteriores expiraram e não podem ser recuperados automaticamente deste ambiente. Portanto, este documento não declara como "subidos" arquivos cujo conteúdo não está disponível. Para uma recuperação fiel de todos os códigos históricos, os ZIPs/arquivos originais do KIT_UNICO, SONPEF e demais pacotes que não estejam no repositório precisam ser reenviados.
