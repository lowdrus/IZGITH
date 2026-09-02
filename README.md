# IZGITH

Extensao Chrome Manifest V3 para baixar, preparar e auditar pacotes de extensoes Chromium com seguranca. O IZGITH reune em um unico produto o popup, a fila, o painel de controle, o monitor de releases publicas do GitHub e um host local opcional em Python.

## Estado atual - 6.0.0.00057

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
- assistentes canonicos: Julia, Ayella e IZART.

> O Chrome nao permite que uma extensao comum instale silenciosamente outra extensao no perfil principal. O IZGITH prepara, audita e abre extensoes em um perfil isolado; a instalacao definitiva usa o fluxo oficial "Carregar sem compactacao".

## Native Messaging sem congelar o boot

O Native Messaging **nao e requisito para abrir a extensao**. A versao autonoma atual nao declara a permissao `nativeMessaging` no Manifest V3, portanto os erros antigos `host not found`/`forbidden` nao fazem parte do caminho normal de inicializacao. O host local continua separado para cenarios que realmente exigirem integracao nativa.

## Instalacao rapida no Google Chrome

1. Baixe o pacote da pagina de releases.
2. Extraia para uma pasta permanente.
3. Abra `chrome://extensions`.
4. Ative **Modo do desenvolvedor**.
5. Clique em **Carregar sem compactacao** e escolha a pasta que contem `manifest.json`.
6. Fixe o IZGITH na barra do Chrome e abra o popup.

## Verificacao Windows

O projeto mantem scripts de build/verificacao na pasta `build/`. O `.ps1` deve permanecer compativel com Windows PowerShell 5.1, evitando `?.` e evitando o uso de `$Host` como variavel. O Manifest V3 referencia `sw.js` diretamente e os quatro icones ficam em `extension/assets/icons/`.

## Assistentes e KIT_UNICO

O registro canonico esta em `integrations/assistant_registry.json` e a camada de UI em `extension/scripts/assistants.js`. Os tres nomes sao distintos: **Júlia**, **Ayella** e **IZART**. O dashboard agora renderiza os tres explicitamente; eles nao dependem do Native Messaging para aparecer.

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
- `host/`: host Native Messaging e instaladores opcionais.
- `integrations/`: registros e material recuperado de SONPEF, CONVGPT, KIT_UNICO e CHAT_HISTORY.
- `scripts/`: validacao e empacotamento.
- `tests/`: testes unitarios e de integracao estatica.
- `docs/`: tutorial, arquitetura e especificacoes.
- `archive/legacy/`: fontes historicas incorporadas, fora do build.

Consulte `docs/AUDITORIA_DO_LEGADO.md` para saber exatamente o que foi preservado, removido e efetivamente integrado.

## Seguranca e privacidade

O projeto nao requer token do GitHub para consultar releases publicas e nao armazena credenciais. Leia `SECURITY.md` e `docs/PRIVACIDADE.md`.

## Licenca

Consulte `LICENSE`. Fontes historicas mantem suas proprias licencas e nao sao incluidas no pacote final.
