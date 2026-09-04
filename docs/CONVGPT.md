# CONV-D

## Nota de compatibilidade

O nome funcional atual do módulo é **CONV-D**. Arquivos históricos ou referências antigas a `CONVGPT` podem permanecer no histórico do repositório por rastreabilidade, mas a interface atual usa CONV-D.

## Função

CONV-D adiciona o controle **Baixar Conversa** às páginas de conversa suportadas. O usuário escolhe o escopo e o formato antes do download.

Escopos:

- **Tudo** — exporta o conteúdo disponível da conversa inteira.
- **Ultima Rodada** — exporta somente a rodada mais recente disponível.

Formatos previstos pelo módulo: PDF, Word `.doc`, TXT, Markdown `.md`, JSON estruturado e Excel `.xls`.

## Plataformas

A arquitetura suporta adaptadores para provedores de IA. A página precisa corresponder a um domínio declarado no Manifest V3 e a um adaptador que consiga reconhecer a estrutura da conversa.

## Segurança

A exportação ocorre localmente no navegador. O módulo não deve pedir credenciais do provedor nem enviar automaticamente conteúdo para um repositório.

## Diagnóstico

Se o botão não aparecer, verifique: extensão atualizada, domínio suportado, CONV-D ativo e carregamento do content script. Alterações de DOM dos provedores podem exigir atualização do adaptador.
