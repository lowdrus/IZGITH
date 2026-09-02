# IZGITH 6.0.0.00044 — Ultra + Controlled

Esta rodada unifica os dois modos de operacao em uma base unica:

- **Ultra**: automacao maxima dentro das APIs permitidas pelo Chrome/Windows.
- **Controlado**: toda acao externa fica explicita, auditavel e reversivel.
- **Service worker**: usa o formato classico de MV3 (`sw.js` sem `type: module`) para reduzir pontos de falha no carregamento.
- **Native Messaging**: o nome canônico e `com.izgith.host` em toda a cadeia.
- **Windows**: `build/IZGITH_HOST_SETUP_00044.bat` chama o PowerShell 5.1+ compatível e cria o manifesto + registro HKCU.
- **Verificacao**: `build/VERIFY_IZGITH_00044.ps1` confirma arquivos essenciais, Manifest V3 e `background.service_worker`.

## Limite importante do Chrome

Uma extensao nao pode conceder a si propria privilegios do sistema, registrar um Native Messaging host ou instalar silenciosamente um executavel fora do sandbox. Por isso, a automacao do host e feita por um instalador local de um clique. Depois do registro, a extensao apenas consulta o host; se ele estiver ausente, o erro e convertido em estado diagnostico em vez de quebrar a UI.

## Regra de ouro para as proximas rodadas

Nao gerar codigo JavaScript dentro de strings PowerShell ou BAT quando isso puder ser evitado. Arquivos de codigo sao gravados como arquivos independentes UTF-8; BAT apenas chama o PS1; PS1 apenas cria/valida a arvore. Isso evita os erros historicos de `&`, here-string, mojibake, `?.Source`, `type="popup"` e `MissingEqualsInHashLiteral`.
