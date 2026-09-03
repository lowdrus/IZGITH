# IZGITH

Extensao Chrome Manifest V3 para baixar, preparar e auditar pacotes de extensoes Chromium com seguranca. O IZGITH reune em um unico produto o popup, a fila, o painel de controle, o monitor de releases publicas do GitHub e um host local opcional em Python.

## Estado atual - 6.0.0.00050

A linha atual preserva a referencia visual `IZGITH_v6.0.0.00034_Full_Build` e usa **Ultra + Controlado unificados** como modo padrao. O usuario ainda pode selecionar `Controlado` ou `Ultra` individualmente em Configuracoes.

A ordem fixa da interface e: **Identidade & Host -> Ferramentas -> Configuracoes -> Logs -> Temas**. No rodape ficam **EULA** e **Guia Rapido**, ambos informativos; o EULA nao bloqueia o uso.

## O que funciona

- download HTTP/HTTPS com confirmacao de destino;
- fila local de arquivos ZIP/CRX;
- auditoria de `manifest.json` com pontuacao explicavel;
- extracao protegida contra ZIP Slip e links simbolicos;
- preparacao de ZIP e CRX2/CRX3;
- laboratorio isolado em perfil temporario do Chrome/Chromium;
- monitor de releases publicas do GitHub;
- 36 temas, modo de desempenho e preferencias persistentes;
- Chrome, Edge, Brave e Chromium, conforme o sistema operacional;
- CI, CodeQL, testes, pacote ZIP e releases automaticas;
- integracoes registradas para SONPEF, CONVGPT, KIT_UNICO e CHAT_HISTORY;
- assistentes registrados: Julia, Ayella e IZART.

> O Chrome nao permite que uma extensao comum instale silenciosamente outra extensao no perfil principal. O IZGITH prepara, audita e abre extensoes em um perfil isolado; a instalacao definitiva usa o fluxo oficial "Carregar sem compactacao".

## Native Messaging sem congelar o boot

O Native Messaging **nao e requisito para abrir a extensao**. O service worker centraliza as chamadas nativas, faz uma sondagem antes das operacoes e consome `chrome.runtime.lastError` no callback correto. Se `com.izgith.host` nao estiver instalado, a interface deve apresentar `OFF`/informativo em vez de bloquear o carregamento.

A instalacao do host continua sujeita as regras de seguranca do Chrome/Windows: uma extensao nao pode, por si, registrar silenciosamente um executavel nativo no sistema operacional. Por isso o pacote inclui os scripts de preparacao/verificacao, mas nao finge que essa barreira de seguranca nao existe.

## Instalacao rapida no Google Chrome

1. Baixe o ZIP `IZGITH-extension` da aba **Actions** ou da pagina **Releases**.
2. Extraia o ZIP para uma pasta permanente, por exemplo `C:\IZGITH\extension`.
3. Abra `chrome://extensions`.
4. Ative **Modo do desenvolvedor**.
5. Clique em **Carregar sem compactacao** e escolha a pasta que contem `manifest.json`.
6. Fixe o IZGITH na barra do Chrome e abra o popup.

O popup funciona sem programas adicionais. Para auditoria local, CRX/ZIP e laboratorio isolado, siga `docs/TUTORIAL_INSTALACAO_E_USO.md`.

## Verificacao Windows

Na raiz do repositorio, o par `build/IZGITH_BUILD_00050.bat` + `build/IZGITH_BUILD_00050.ps1` cria uma base limpa a partir do proprio repositorio e verifica manifest.json, service worker, UI e os quatro icones PNG. O `.ps1` foi escrito sem `?.` e sem usar `$Host` como variavel, evitando os erros recorrentes observados em Windows PowerShell antigo. O BAT e o PS1 permanecem juntos na mesma pasta.

## Desenvolvimento

Requisitos: Python 3.11+ e Node.js 24+.

```bash
python scripts/validate_project.py
python -m unittest discover -s tests -v
npm test
npm run package
```

O pacote e criado em `dist/`. Nenhuma dependencia npm e necessaria.

## Estrutura

- `extension/`: unica extensao distribuivel do IZGITH.
- `host/`: host Native Messaging e instaladores.
- `integrations/`: registros e material recuperado de SONPEF, CONVGPT, KIT_UNICO e CHAT_HISTORY.
- `scripts/`: validacao e empacotamento.
- `tests/`: testes unitarios e de integracao estatica.
- `docs/`: tutorial, arquitetura e especificacoes.
- `archive/legacy/`: fontes historicas incorporadas, fora do build.

Consulte `docs/AUDITORIA_DO_LEGADO.md` para saber exatamente o que foi preservado, removido e efetivamente integrado.

## Recuperacao do legado

Os fontes antigos nao foram simplesmente descartados. A auditoria registra que 616 arquivos historicos uteis foram preservados em `archive/legacy/root/`. O SONPEF historico, por exemplo, esta preservado para migracao controlada; a nova entrada `integrations/SONPEF/sonpef_unify.ps1` e uma implementacao segura que inventaria e unifica fontes sem executar os scripts descobertos.

KIT_UNICO permanece como fonte auditada e CONVGPT como adaptador de historico. Nenhum arquivo historico e promovido automaticamente para a extensao sem revisao de permissao, licenca e testes.

## Seguranca e privacidade

O projeto nao requer token do GitHub para consultar releases publicas e nao armazena credenciais. Leia `SECURITY.md` e `docs/PRIVACIDADE.md`.

## Licenca

Consulte `LICENSE`. Fontes historicas mantem suas proprias licencas e nao sao incluidas no pacote final.
