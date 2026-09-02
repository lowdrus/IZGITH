# IZGITH — Integration Pass 00042

## Objetivo
Rodada de endurecimento do fluxo de integração, validação e empacotamento.

## Critérios
- extensão distribuível deve possuir Manifest V3 válido;
- service worker deve ser declarado e existir;
- referências do manifest devem existir;
- JavaScript deve passar `node --check` quando Node estiver disponível;
- ícones 16/32/48/128 devem existir;
- componentes SONPEF, CONVGPT e KIT_UNICO devem possuir registro de integração;
- assistentes Júlia, Ayelle/Ayella e IZART devem permanecer registrados;
- pacote ZIP deve ser reproduzível;
- Native Messaging é opcional para o carregamento inicial da extensão e deve falhar de forma tratável quando indisponível.

## Próxima etapa
Executar testes funcionais reais dos botões e fechar o fluxo de Native Messaging/SONPEF/CONVGPT/KIT_UNICO sem exigir terminal ao usuário final.
