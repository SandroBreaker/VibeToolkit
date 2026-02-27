# ⚡ VibeToolkit - AI Context Synthesizer & Bundler

O **VibeToolkit** é uma ferramenta de linha de comando (CLI) construída com **PowerShell** e **Node.js** que atua como um engenheiro reverso para seus projetos de software. 

Ele varre seu repositório, extrai contratos, tipagens e arquitetura, e utiliza a API da **Groq (Llama 3.3 70B)** para gerar um "Super Prompt" de altíssima densidade. O resultado é um documento otimizado que você envia para qualquer LLM (ChatGPT, Claude, Gemini) para que a IA codifique no seu projeto com precisão milimétrica, zero alucinação e consumindo o mínimo de tokens possível.

## 🚨 O Problema que Resolvemos
Trabalhar com LLMs em projetos grandes envolve um gargalo terrível de contexto:
1. **Caos Manual:** Copiar e colar dezenas de arquivos é lento e gera erros.
2. **Desperdício de Tokens:** Enviar o código inteiro é caro e "dilui" a atenção da IA.
3. **Alucinação Arquitetural:** Sem interfaces claras, a IA inventa propriedades e quebra o build.

## 🛠️ A Solução (Vibe Workflow)
O VibeToolkit automatiza a extração e cria um **AI Context Document** (`.md`) consolidado contendo:
* **Persona Executora:** Instruções estritas (Low Entropy) para garantir entregas de código completas.
* **AI Briefing (Zero Fluff):** Resumo estratégico gerado pelo Llama 3 focado em Tech Stack e Guardrails.
* **Project Blueprint:** Mapeamento de assinaturas, tipos e estruturas de arquivos para referência técnica.

---

## 🚀 Como Instalar

### Pré-requisitos
* **Node.js** (v18+)
* **PowerShell**
* Chave de API gratuita da [Groq Console](https://console.groq.com/)

### Passo a Passo
1. Clone este repositório.
2. Instale as dependências:
   ```bash
   npm install
   ```
3. Configure sua chave no arquivo `.env` (use o `.env.example` como base):
   ```env
   GROQ_API_KEY=gsk_sua_chave_aqui
   ```

### 🖱️ Atalho no Botão Direito (Windows)
Para integrar o toolkit ao menu do Windows e usá-lo em qualquer pasta:
1. Execute o script `setup-menu.ps1` como **Administrador**.
2. O script detectará o caminho da instalação e aplicará o registro automaticamente.
3. Clique com o botão direito em qualquer pasta de projeto e selecione **"Gerar Blueprint / Contexto (Vibe AI)"**.

---

## 💻 Como Usar

### Via Terminal
Execute o script apontando para o arquivo principal de dentro da pasta do projeto que deseja analisar:

```powershell
D:\caminho\para\VibeToolkit\project-bundler.ps1
```

### Modos de Extração
* **[ 1 ] BUNDLER:** Código-fonte completo (ideal para arquivos específicos ou projetos pequenos).
* **[ 2 ] BLUEPRINT:** Apenas a "casca" técnica (interfaces, tipos e assinaturas). Ideal para projetos grandes.
* **[ 3 ] SELECTIVE:** Escolha manual via terminal de quais arquivos devem entrar no contexto.

Ao final, confirme a análise da IA para gerar o arquivo `_AI_CONTEXT_NomeDoProjeto.md`.

---

## 🧠 Como interagir com o resultado

Para um pair-programming de elite com Claude, ChatGPT ou Gemini:

1. Faça o upload do arquivo `_AI_CONTEXT_...md`.
2. Faça o upload do arquivo que você quer modificar (ex: `UserService.ts`).
3. Dê sua ordem: *"Refatore este serviço para implementar o novo padrão de erro definido no blueprint"*.

A IA agora possui consciência situacional total do seu projeto.

---

## 🛡️ Segurança e Privacidade
O toolkit ignora automaticamente `node_modules`, `.git`, `dist`, `.env` e outros arquivos sensíveis via blacklist configurável. O processamento via Groq é efêmero e focado na extração de lógica.