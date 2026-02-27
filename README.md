# ⚡ VibeToolkit - AI Context Synthesizer & Bundler

O **VibeToolkit** é uma ferramenta de linha de comando (CLI) construída com PowerShell e Node.js que atua como um engenheiro reverso para seus projetos de software. 

Ele varre seu repositório, extrai contratos, tipagens e arquitetura, e utiliza a API da **Groq (Llama 3.3 70B)** para gerar um "Super Prompt" de altíssima densidade. O resultado é um documento otimizado que você envia para qualquer LLM (ChatGPT, Claude, Gemini) para que a IA codifique no seu projeto com precisão milimétrica, zero alucinação e consumindo o mínimo de tokens possível.

## 🚨 O Problema que Resolvemos
Trabalhar com LLMs em projetos grandes envolve um gargalo terrível de contexto:
1. Copiar e colar dezenas de arquivos manualmente é lento e sujeito a erros.
2. Enviar o código-fonte inteiro consome milhares de tokens e confunde a IA.
3. Sem os contratos exatos (interfaces, types), a IA alucina propriedades e quebra a sua aplicação.

## 🛠️ A Solução (Vibe Workflow)
O VibeToolkit automatiza a extração de contexto e cria um **AI Context Document** consolidado que contém:
1. **A Persona Executora:** Instruções estritas forçando a IA a não alterar o que não foi pedido e devolver o código completo.
2. **AI Briefing (Zero Fluff):** Um resumo arquitetural gerado pelo Groq Llama 3 focado apenas em *Tech Stack*, *Design Patterns*, *Domínios* e *Guardrails*.
3. **Project Blueprint:** As assinaturas de funções, classes e interfaces estritas para a IA saber exatamente como o seu código se comunica.

---

## 🚀 Como Instalar

### Pré-requisitos
* **Node.js** (v18+)
* **PowerShell**
* Chave de API gratuita da [Groq Console](https://console.groq.com/)

### Passo a Passo
1. Clone este repositório para a sua máquina.
2. Instale as dependências do Node.js:
   ```bash
   npm install
   ```

3. Crie um arquivo `.env` na raiz do projeto (use o `.env.example` como base) e insira sua chave da Groq:
   ```env
   GROQ_API_KEY=gsk_sua_chave_aqui
   ```

---

## 💻 Como Usar

Abra o terminal na pasta do projeto que você deseja analisar e execute o script apontando para o VibeToolkit.
*(Dica: Você pode adicionar o caminho do VibeToolkit nas suas variáveis de ambiente para rodar de qualquer lugar).*

```powershell
# Exemplo executando de dentro da pasta do seu projeto alvo:
D:\repositorio\VibeToolkit\project-bundler.ps1
```

### O Menu Interativo

O script apresentará 3 modos de extração:

* **[ 1 ] BUNDLER:** Empacota o código-fonte completo de todos os arquivos relevantes mapeados. Ideal para projetos pequenos.
* **[ 2 ] BLUEPRINT:** Extrai **apenas** a arquitetura, imports e assinaturas (interfaces, types, consts exportadas). Ideal para gerar o contexto de projetos médios e grandes.
* **[ 3 ] SELECTIVE:** Permite escolher manualmente via terminal quais arquivos você quer consolidar.

Após a extração, o script perguntará se você deseja processar o artefato com a IA. Ao confirmar, o Node.js assume, envia o dump para o Llama 3.3 70B e devolve o seu arquivo mestre: `_AI_CONTEXT_NomeDoProjeto.md`.

---

## 🧠 Como usar o arquivo gerado com outras IAs?

Para iniciar uma sessão de pair-programming com IA (Claude, ChatGPT, etc) com nível Sênior:

1. Faça o upload do arquivo `_AI_CONTEXT_NomeDoProjeto.md`.
2. Faça o upload do arquivo específico que você quer editar (ex: `AuthService.ts`).
3. Digite sua instrução (ex: *"Refatore a função login para usar try/catch e adicione logs"*).

A IA terá a visão global da arquitetura e as restrições exatas do seu código, gerando um resultado de primeira (first-shot) muito superior.

---

## 🛡️ Segurança e Privacidade

O script ignora automaticamente pastas pesadas (`node_modules`, `dist`, `.git`) e arquivos sensíveis (`.env`, chaves de serviço). Todo o processamento de IA ocorre via API na nuvem da Groq de forma efêmera.