# Reconstrução histórica — 00042

## Fonte de verdade
Esta rodada foi reconstruída a partir do estado efetivamente recuperado no repositório `lowdrus/IZGITH` em 2026-09-02, somado às decisões de projeto já registradas no próprio repositório.

## Baseline preservado
- UI de referência: `IZGITH_v6.0.0.00034_Full_Build`.
- Ordem principal: Identidade & Host, Ferramentas, Configurações, Logs, Temas.
- Rodapé: EULA e Guia Rápido como informação, sem aceite obrigatório.
- 36 temas.
- Native Messaging opcional para boot.
- Integrações registradas: SONPEF, CONVGPT, KIT_UNICO e CHAT_HISTORY.
- Assistentes registrados: Júlia, Ayelle/Ayella e IZART.

## Correção estrutural desta rodada
O problema recorrente de `Specified native messaging host not found/forbidden` era agravado pelo ping automático executado durante a inicialização do dashboard. O 00042 remove esse acionamento automático. O host somente é consultado quando o usuário aciona uma ferramenta que realmente precisa dele.

O problema recorrente de `Invalid shorthand property initializer` no service worker também é evitado no core atual: o arquivo `extension/sw.js` não usa a forma inválida `type="popup"`; quando necessário, propriedades de objeto usam `type: "popup"`.

## Ultra + Controlado
O modo `unified` é a configuração padrão. Ele não transforma ações locais sensíveis em instalação silenciosa nem contorna as proteções do navegador. Ele combina automação de tarefas não sensíveis com salvaguardas nas operações locais que dependem do host.

## KIT_UNICO / CONVGPT / SONPEF
Os registros de integração presentes no repositório são tratados como fontes recuperadas/referências. A promoção de código para o core só ocorre quando o código-fonte correspondente está realmente disponível e passa por validação. Isso evita inventar ou substituir silenciosamente conteúdo histórico que não está disponível nesta recuperação.

## Limite da reconstrução
Anexos que expiraram fora do repositório não podem ser recriados byte-a-byte sem novo upload. Para esses itens, o repositório mantém a referência histórica e o estado de promoção.
