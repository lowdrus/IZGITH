# IZGITH — EULA / Termos de Uso

**Versão documental: 00075 — 8 de setembro de 2026**

## 1. Natureza do software

IZGITH é uma extensão e plataforma local de apoio à preparação, auditoria, organização, exportação de conversas e gerenciamento de perfis. Recursos podem depender das APIs disponíveis pelo navegador e das permissões concedidas pelo usuário.

## 2. Controle do usuário

O usuário decide quais arquivos selecionar, quais conversas exportar e quais destinos utilizar. A extensão não deve solicitar, armazenar ou transmitir senhas, cookies, tokens ou chaves privadas como parte normal de seus fluxos.

## 3. Conversas e exportação

CONV-D opera sobre conteúdo que o usuário já consegue visualizar em plataformas suportadas. A disponibilidade e a estrutura de uma conversa podem mudar conforme cada provedor. O usuário é responsável por verificar se a exportação e o armazenamento são permitidos pelos termos do respectivo serviço.

## 4. UPPER URL e UPPER GITHUB

UPPER URL e UPPER GITHUB são módulos independentes. UPPER URL abre a conversa HTTPS indicada pelo usuário. UPPER GITHUB registra/prepara um destino de repositório próprio. Nenhum token de GitHub é inferido, coletado ou transmitido silenciosamente.

## 5. ENSH-GERENC e execução externa

O baseline do IZGITH evita execução silenciosa de processos do sistema. Native Messaging não é requisito para o carregamento normal. O ENSH-GERENC prepara perfis, configuração, Compose e planos.

Para execução real de Docker/Wine/SteamCMD, o usuário pode operar um Runtime Agent remoto autorizado. Esse agente é uma fronteira separada, autenticada por Bearer token e limitada a operações allow-listed. Ele não aceita shell arbitrário. O usuário é responsável pela infraestrutura remota, rede, TLS/VPN, Docker e credenciais do ambiente.

## 6. Terceiros

Integrações com ChatGPT, Claude, Gemini, Grok, GitHub, Enshrouded e outros serviços não implicam afiliação ou endosso. Os respectivos nomes e marcas pertencem aos seus titulares.

## 7. Segurança

Não coloque segredos em arquivos versionados. Tokens de runtime devem permanecer fora do repositório. Não exponha um endpoint de runtime diretamente à Internet sem autenticação e transporte seguro.

## 8. Limitação de responsabilidade

O software é fornecido conforme sua implementação e documentação. Mudanças de navegador, provedores, APIs, políticas, formatos de páginas, redes ou sistemas externos podem afetar funcionalidades. Um endpoint remoto pode ficar indisponível independentemente da extensão.

## 9. Aceite

Ao utilizar o IZGITH, o usuário declara que possui autorização para acessar, exportar, armazenar e manipular os dados utilizados e que observará as leis, políticas e termos aplicáveis.
