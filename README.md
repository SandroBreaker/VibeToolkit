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