
# Tutorial — Modo D (Download & Extração de Extensões)

## 1. Onde clicar
Abra a extensão **CONVERSATIONGPT** → Aba **Ferramentas** → Botão **EXTRAIR EXTENSÃO CHROME**.

## 2. O que colar
Cole a URL da extensão (ex.: `https://chromewebstore.google.com/detail/...`).

## 3. O que acontece
1) A IA analisa o DOM da página e identifica o link real do `.crx` (mesmo que escondido).  
2) Baixa o arquivo sem instalar.  
3) Extrai TUDO: manifest.json, scripts, ícones, páginas, assets, permissões, metadados.  
4) Se algo faltar: reconstrói uma build local para testes/edição.  

## 4. Onde salva
- `D:\PROJETOS\CONVERSACHAT\EXTENSOES ARQUIVO\EXTENSOES ARQUIVOS CHROME\<nome-da-extensão>\`

## 5. Dicas
- Se a Web Store mudar, ajuste os seletores na aba **Avançado**.
- Use o botão **VERIFICAÇÃO EXPORTJSON** para gerar um JSON do processo e checar integridade.
- Ative **IA Sugestiva** para recomendações de uso/integração com FULLONE.
