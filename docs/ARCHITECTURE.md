# Arquitetura IZGITH

```text
IZGITH/
├─ extension/              # Manifest V3, popup, dashboard, assets
├─ host/            # Native Messaging + CLI local
│  └─ installers/          # registro/build do host por SO
├─ tools/                  # utilitários de recuperação/exportação
├─ scripts/                # validação e empacotamento do produto
├─ tests/                  # testes do host/core
├─ docs/                   # especificação, arquitetura e tutorial
├─ archive/legacy/         # fontes históricas, fora do build
└─ .github/workflows/      # CI, CodeQL e releases
```

## Trust boundaries
O popup/dashboard roda no sandbox de extensão. Acesso a filesystem/processos só ocorre pelo Native Messaging host instalado explicitamente. Pacotes externos nunca são executados durante preparação. ZIP/CRX são extraídos com validação contra traversal/symlink. O sandbox abre um perfil Chromium temporário separado do principal.

## Fluxo
URL → `chrome.downloads` → arquivo do usuário. Para auditoria local: Dashboard → Native Messaging → picker do SO → prepare/analyze → score + caminho unpacked → usuário escolhe entre Secure Lab ou carregamento manual suportado pelo navegador.
