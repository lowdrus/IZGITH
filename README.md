# IZGITH

Extensão Chrome Manifest V3 para baixar, preparar e auditar pacotes de extensões Chromium com segurança. O IZGITH reúne em um único produto o popup, a fila, o painel de controle, o monitor de releases públicas do GitHub e um host local opcional em Python.

## Estado atual — 6.0.0.00045

A linha atual preserva a referência visual `IZGITH_v6.0.0.00034_Full_Build` e usa **Ultra + Controlado unificados** como modo padrão. O usuário ainda pode selecionar `Controlado` ou `Ultra` individualmente em Configurações.

A ordem fixa da interface é: **Identidade & Host → Ferramentas → Configurações → Logs → Temas**. No rodapé ficam **EULA** e **Guia Rápido**, ambos informativos; o EULA não bloqueia o uso.

## O que funciona

- download HTTP/HTTPS com confirmação de destino;
- fila local de arquivos ZIP/CRX;
- auditoria de `manifest.json` com pontuação explicável;
- extração protegida contra ZIP Slip e links simbólicos;
- preparação de ZIP e CRX2/CRX3;
- laboratório isolado em perfil temporário do Chrome/Chromium;
- monitor de releases públicas do GitHub;
- 36 temas, modo de desempenho e preferências persistentes;
- Chrome, Edge, Brave e Chromium, conforme o sistema operacional;
- CI, CodeQL, testes, pacote ZIP e releases automáticas;
- integrações registradas para SONPEF, CONVGPT, KIT_UNICO e CHAT_HISTORY;
- assistentes registrados: Júlia, Ayelle e IZART.

> O Chrome não permite que uma extensão comum instale silenciosamente outra extensão no perfil principal. O IZGITH prepara, audita e abre extensões em um perfil isolado; a instalação definitiva usa o fluxo oficial “Carregar sem compactação”.

## Native Messaging sem congelar o boot

O Native Messaging **não é requisito para abrir a extensão**. O service worker centraliza as chamadas nativas, faz uma sondagem antes das operações e consome `chrome.runtime.lastError` no callback correto. Se `com.izgith.host` não estiver instalado, a interface deve apresentar `OFF`/informativo em vez de bloquear o carregamento.

A instalação do host continua sujeita às regras de segurança do Chrome/Windows: uma extensão não pode, por si só, registrar silenciosamente um executável nativo no sistema operacional. Por isso o pacote inclui os scripts de preparação/verificação, mas não finge que essa barreira de segurança não existe.

## Instalação rápida no Google Chrome

1. Baixe o ZIP `IZGITH-extension` da aba **Actions** ou da página **Releases**.
2. Extraia o ZIP para uma pasta permanente, por exemplo `C:\IZGITH\extension`.
3. Abra `chrome://extensions`.
4. Ative **Modo do desenvolvedor**.
5. Clique em **Carregar sem compactação** e escolha a pasta que contém `manifest.json`.
6. Fixe o IZGITH na barra do Chrome e abra o popup.

O popup funciona sem programas adicionais. Para auditoria local, CRX/ZIP e laboratório isolado, siga `docs/TUTORIAL_INSTALACAO_E_USO.md`.

## Verificação Windows

Na raiz do repositório, o par `build/IZGITH_BUILD_00045.bat` + `build/IZGITH_BUILD_00045.ps1` verifica a estrutura do pacote, Manifest V3, service worker, UI, quatro ícones, catálogo de 36 temas e registro dos assistentes. O `.ps1` foi escrito sem `?.` e sem usar `$Host` como variável, evitando os erros recorrentes observados em Windows PowerShell antigo.

## Desenvolvimento

Requisitos: Python 3.11+ e Node.js 24+.

```bash
python scripts/validate_project.py
python -m unittest discover -s tests -v
npm test
npm run package
```

O pacote é criado em `dist/`. Nenhuma dependência npm é necessária.

## Estrutura

- `extension/`: única extensão distribuível do IZGITH.
- `host/`: host Native Messaging e instaladores.
- `integrations/`: registros e material recuperado de SONPEF, CONVGPT, KIT_UNICO e CHAT_HISTORY.
- `scripts/`: validação e empacotamento.
- `tests/`: testes unitários e de integração estática.
- `docs/`: tutorial, arquitetura e especificações.
- `archive/legacy/`: fontes históricas incorporadas, fora do build.

Consulte `docs/AUDITORIA_DO_LEGADO.md` para saber exatamente o que foi preservado, removido e efetivamente integrado.

## Segurança e privacidade

O projeto não requer token do GitHub para consultar releases públicas e não armazena credenciais. Leia `SECURITY.md` e `docs/PRIVACIDADE.md`.

## Licença

Consulte `LICENSE`. Fontes históricas mantêm suas próprias licenças e não são incluídas no pacote final.
