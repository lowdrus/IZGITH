# Reconstrução histórica — 00042

Baseada no material efetivamente recuperado no repositório em 2026-09-02 e nas decisões registradas no projeto.

- UI de referência: `IZGITH_v6.0.0.00034_Full_Build`.
- Ordem: Identidade & Host → Ferramentas → Configurações → Logs → Temas.
- Rodapé: EULA + Guia Rápido, ambos informativos.
- 36 temas.
- Native Messaging opcional para boot; host oficial recuperado: `com.izgith.host`.
- Integrações registradas: SONPEF, CONVGPT, KIT_UNICO e CHAT_HISTORY.
- Assistentes registrados: Júlia, Ayelle/Ayella e IZART.

## Correção de causa-raiz
A extensão não deve tentar conectar ao Native Messaging durante o boot. O dashboard agora consulta o host somente quando o usuário aciona uma ação dependente dele. Isso evita o erro recorrente `Specified native messaging host not found/forbidden` quando o host não está instalado.

O core também mantém o service worker livre do erro de inicializador `type="..."`: em objetos JavaScript a forma correta é `type: "..."`.

## Modos
`unified` combina automação Ultra com salvaguardas Controladas. Não significa instalação silenciosa nem contorno das proteções do navegador.

## Limite
Arquivos históricos expirados fora do repositório não podem ser reconstruídos byte-a-byte sem novo upload. Não foram inventados arquivos ausentes; fontes recuperadas continuam em `archive/legacy` até promoção individual.
