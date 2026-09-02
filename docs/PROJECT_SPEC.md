# IZGITH — especificação consolidada

Esta especificação reconstrói os requisitos úteis registrados na conversa do projeto e separa **funcionalidades reais** de ideias futuras.

## Produto
IZGITH é um hub offline-first para pacotes de extensões Chromium. O núcleo deve funcionar localmente; rede/cloud são opcionais. A interface combina popup rápido, fila e dashboard.

## Requisitos preservados
- Download HTTP/HTTPS com “Salvar como”.
- Popup minimalista/high-end, drag & drop e fila múltipla.
- Dashboard com 36 temas em 4 famílias (Cyber, Premium, Matrix, Glass), glow/3D e modo performance.
- Preparação de pasta, ZIP e CRX; análise de Manifest V3; score explicável.
- Native Messaging host Python para operações de filesystem e sandbox.
- GitHub Monitor para releases públicas.
- Perfis/modos Manual, Auto com confirmação e Auto preparar.
- Secure Lab: quarentena por padrão e perfil Chromium isolado.
- Logs/histórico local e arquitetura pronta para rollback/comparador.
- Chrome/Edge/Brave/Chromium quando suportado pelo host.
- CI/CD, CodeQL, Dependabot, testes, builds e releases verificáveis.

## Restrições reais do navegador
Uma extensão Chrome comum não pode instalar silenciosamente outra extensão no perfil principal. Por isso, o fluxo oficial do IZGITH é **preparar/auditar** e orientar “Carregar sem compactação”; testes automatizados usam perfil isolado via `--load-extension`. CRX fora da Chrome Web Store pode ser rejeitado pelo Chrome e nunca deve ser representado como “instalação garantida”.

## Roadmap preservado
- v4.1 FULL ONE: popup + fila + dashboard + 36 temas + 3D.
- v4.2 SMART SYSTEM: auto mode + GitHub Monitor + rollback + quarentena.
- v4.3 SECURE LAB: sandbox + perfis + comparador + isolamento.
- v4.4 CONSOLIDATED CORE: estrutura monorepo, Native Host realmente conectado ao dashboard, preparação ZIP/CRX e CI/CD alinhado.

## Backlog futuro (não alegar como pronto)
Cloud Sync opt-in, sistema de perfis de IA, Chat Export, comparador/rollback completo, assinatura de relatórios, plugins Rust/WASM/Python/TypeScript, integração CI externa e análise avançada de código. Qualquer IA/serviço remoto deve exigir configuração explícita e não pode enviar código privado sem consentimento.
