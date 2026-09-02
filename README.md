# IZGITH

IZGITH é um hub **offline-first** para trabalhar com pacotes de extensões Chromium com mais transparência: download por URL, fila de pacotes, dashboard, temas, monitor de releases públicas no GitHub, análise local de `manifest.json` e um host Python opcional para testes em perfil isolado.

> Importante: extensões comuns não podem instalar silenciosamente outras extensões no perfil principal do Chrome. O IZGITH respeita essa restrição. O fluxo padrão prepara/audita o pacote e orienta o carregamento suportado em `chrome://extensions`; o modo sandbox usa um perfil Chromium separado via host local.

## Estado desta revisão

Versão: **4.3.1**

- Manifest V3 válido.
- Popup funcional com download real pela API `chrome.downloads`, seleção múltipla e drag & drop de `.zip`/`.crx`.
- Dashboard unificado.
- 36 presets visuais em quatro famílias (Cyber, Premium, Matrix e Glass), efeitos 3D e modo performance.
- Fila persistida em `chrome.storage.local`.
- Monitor de release pública do GitHub.
- Host Python com análise de manifest, extração ZIP protegida contra zip-slip e lançamento de sandbox Chromium.
- Instalador cross-platform do Native Messaging host.
- CI, empacotamento de artefatos, CodeQL, Dependabot e CD por tags `vX.Y.Z`.

## Instalar a extensão em desenvolvimento

1. Clone ou baixe este repositório.
2. Abra `chrome://extensions`.
3. Ative **Modo do desenvolvedor**.
4. Clique em **Carregar sem compactação**.
5. Selecione a raiz do repositório (a pasta que contém `manifest.json`).
6. Fixe o ícone IZGITH na barra de ferramentas.

O popup já funciona sem Python para download, fila, dashboard e GitHub Monitor.

## Host Python opcional

O host habilita operações que uma extensão não pode fazer sozinha, especialmente análise por caminho local e sandbox com perfil isolado.

### Windows

1. Descubra o ID do IZGITH em `chrome://extensions`.
2. Execute `installzipgithub_setup.bat`.
3. Informe o ID quando solicitado.
4. Reinicie o Chrome.

### Linux/macOS

```sh
chmod +x install_host_unix.sh
./install_host_unix.sh SEU_ID_DA_EXTENSAO chrome
```

Também é possível usar o host diretamente:

```sh
python3 ext_host.py --analyze /caminho/para/extensao
python3 ext_host.py --sandbox /caminho/para/extensao
```

O sandbox cria um `--user-data-dir` temporário e inicia um Chromium detectado com `--load-extension`; ele **não modifica o perfil principal**.

## Estrutura principal

```text
manifest.json          Manifest V3
background.js          service worker
popup.*                fluxo rápido
dashboard.*            painel expandido + 36 temas
ext_host.py            host/CLI local
install_host.py        registro Native Messaging
installzipgithub_setup.bat
install_host_unix.sh
tests/                 testes Python
.github/workflows/     CI, CodeQL e release
```

Os arquivos ZIP/PDF históricos na raiz são insumos/arquivos de recuperação encontrados no projeto antigo. Eles não entram no artefato da extensão gerado pelo CI.

## CI/CD

### CI

`.github/workflows/ci.yml` executa em pushes/PRs:

- validação do Manifest V3;
- `node --check` nos scripts da extensão;
- compilação Python;
- testes unitários do host;
- validação do script shell;
- rejeição de artefatos placeholder conhecidos;
- criação de um ZIP `unpacked` como artifact do GitHub Actions.

### Segurança

`codeql.yml` analisa JavaScript/TypeScript e Python. O Dependabot mantém GitHub Actions atualizadas.

### Release/CD

Ao publicar uma tag, por exemplo `v4.3.1`, `release.yml` confirma que a tag corresponde ao `manifest.json`, gera ZIPs separados da extensão e do host, cria `SHA256SUMS.txt` e publica uma GitHub Release.

## Limites e próximos passos

A revisão 4.3.1 consolida uma base real e executável. Recursos que exigem integração com o sistema operacional devem passar pelo host local; recursos de nuvem permanecem opcionais para preservar o desenho offline-first. Antes de distribuir publicamente, teste o artefato em Windows/macOS/Linux e em Chrome/Edge/Brave conforme o navegador-alvo.

## Segurança

- Não inclua chaves privadas `.pem` no repositório.
- Não publique tokens do GitHub.
- Revise permissões de extensões de terceiros antes de carregá-las.
- Prefira sandbox/perfil separado ao testar código desconhecido.
