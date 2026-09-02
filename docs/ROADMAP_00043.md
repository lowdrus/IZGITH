# IZGITH — Roadmap 00043

## Entregue nesta rodada
- Versão da extensão sincronizada para 6.0.0.43 / 6.0.0-00043.
- Validador Python atualizado para não depender de versão fixa anterior.
- Checagem de sintaxe JavaScript passa a ser feita quando Node.js estiver disponível; ausência de Node não quebra a validação estrutural.
- Popup sincronizado com 00043.
- Native Messaging permanece opcional para o boot.

## Estado recuperável
O repositório contém uma área `archive/legacy` com artefatos históricos. Arquivos anexados em conversas anteriores que expiraram não podem ser reconstruídos byte-a-byte sem novo upload.

## Próxima fase funcional
1. Exercitar cada ação da UI.
2. Validar o fluxo real do Native Messaging com `com.izgith.host`.
3. Integrar os componentes reais de SONPEF, CONVGPT e KIT_UNICO quando presentes no código recuperável.
4. Validar os assistentes Júlia, Ayelle/Ayella e IZART.
5. Executar empacotamento e smoke tests em instalação limpa.
6. Publicar somente artefatos efetivamente testados.

## Regra de qualidade
Não declarar uma integração como concluída apenas pela existência de um botão, arquivo ou registro. A funcionalidade deve ter execução verificável e tratamento explícito de falhas.
