# CONV-D

## Função

O CONV-D adiciona o botão **Baixar Conversa** às páginas de conversa das plataformas suportadas. Ele trabalha sobre o conteúdo que a página disponibiliza à extensão e tenta percorrer o histórico carregado antes de exportar.

## Escopo

- **Tudo**: exporta o conjunto de mensagens detectado desde o início até o final do histórico carregado.
- **Ultima Rodada**: seleciona a última rodada detectada, iniciada pela mensagem do usuário mais recente.

## Formatos

O usuário escolhe explicitamente um formato antes do download:

- PDF
- Word `.doc`
- TXT
- Markdown `.md`
- JSON estruturado
- Excel `.xls`

Não há formato automático: nenhum download é iniciado em `.xls` sem a escolha do usuário.

## Participantes e IDs

Quando a plataforma expõe um identificador de usuário/autor/mensagem, o exportador preserva esse valor. Quando o identificador não é exposto pelo DOM da plataforma, o arquivo usa um rótulo seguro como `Você` ou `IA[Nome da plataforma]` e informa que o ID não foi exposto. O CONV-D não inventa IDs privados.

## Plataformas

A integração possui seletores específicos para ChatGPT, Claude, Gemini, Copilot, Perplexity, Grok, DeepSeek, Poe, Le Chat, You.com, Meta AI, Qwen, HuggingChat e Character.AI. A compatibilidade pode variar conforme mudanças de DOM, login, carregamento virtual e políticas de cada plataforma.

## Salvamento

O service worker usa o diálogo de salvamento do navegador. O usuário escolhe local e nome do arquivo.

## Limites

O CONV-D não acessa APIs privadas, não quebra autenticação e não fabrica conteúdo que a página não disponibilizou. Conversas muito longas podem depender do carregamento progressivo do histórico pela própria plataforma.
