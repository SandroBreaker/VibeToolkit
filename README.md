# 🚀 VibeToolkit
**AI Context Synthesizer & Execution Director**

O **VibeToolkit** é uma suite de infraestrutura para IA focada em transformar bases de código brutas em um **Bundle de Contexto Estruturado**. Ele resolve o problema da "falta de contexto" ao preparar uma **Source of Truth** (Fonte de Verdade) blindada para orquestradores (ChatGPT, Gemini, Claude) que atuam como **Diretores** para executores agênticos (**AI Studio Apps** ou **Antigravity**).

---

## 💎 O Conceito de "Vibe"
O toolkit não apenas "copia arquivos", ele extrai a **vibe** (arquitetura, padrões, intenções e contratos) do projeto. O output final não é apenas código, mas um documento meta-analítico que ensina a IA subsequente a agir como um Diretor Técnico do seu projeto.

---

## ✨ Principais Recursos

### 🎨 HUD de Controle Visual
Interface nativa em WinForms (HUD) que centraliza toda a operação. Zero CLI para o fluxo diário, focado em produtividade máxima.

### 🛡️ Smart Chain Multi-Provider (Fallback Dinâmico)
Sistema resiliente de requisições:
1.  **Ordem:** Groq → Gemini → OpenAI → Anthropic.
2.  **Fallback Automático:** Se um provider atingir Rate Limit ou estiver offline, o agente pula para o próximo da cadeia sem perder o progresso.
3.  **Monitoramento:** Logs em tempo real de latência e saúde de cada provider.

### 🎯 Modos de Extração Cirúrgica
*   **🔵 Full Vibe:** Contexto integral. Ideal para análise de bugs complexos.
*   **🟠 Architect:** Apenas estruturas, assinaturas e contratos. Economia agressiva de tokens.
*   **🔴 Sniper Mode:** Seleção granular de arquivos via checklist visual para correções focadas.

### 🧩 Integração Nativa (Right-Click Magic)
Acesso instantâneo via **Menu de Contexto do Windows**. Clique com o botão direito em qualquer pasta para iniciar o "Vibing" sem abrir terminais.

### 🧠 Custom System Prompts
Controle total sobre a geração. Permite injetar instruções específicas (ex: "Foque apenas em refatorar para Hooks" ou "Analise performance de SQL") diretamente na orquestração da IA.

---

## 📂 Estrutura do Ecossistema

-   `project-bundler.ps1`: O núcleo do HUD e lógica de bundling (PowerShell).
-   `groq-agent.ts`: O motor de IA que estrutura o documento e gerencia os providers.
-   `install-vibe-menu.reg`: Script de registro para integração com o Windows Explorer.
-   `run-vibe-toolkit.vbs`: Helper para execução silenciosa e suave.
-   `.env`: Centralização secreta e segura de credenciais de API.

---

## ⚙️ Configuração Rápida

### 1. Requisitos
-   [Node.js](https://nodejs.org/) instalado.
-   [PowerShell 7](https://github.com/PowerShell/PowerShell) (Recomendado para melhor performance).

### 2. Instale as Dependências
```bash
npm install
```

### 3. Credenciais (`.env`)
Clone o `.env.example` para `.env` e preencha suas chaves:
```env
# API Keys (Mínimo uma necessária para o chain funcionar)
GROQ_API_KEY=gsk_...
GEMINI_API_KEY=...
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Modelos (Padrões otimizados)
GROQ_MODEL=llama-3.3-70b-versatile
GEMINI_MODEL=gemini-1.5-pro
OPENAI_MODEL=gpt-4o
ANTHROPIC_MODEL=claude-3-5-sonnet-20240620
```

### 4. Instale o Menu de Contexto (Opcional)
Execute o arquivo `install-vibe-menu.reg` para adicionar o "Vibe AI" ao botão direito do seu Windows.

---

## 🚀 Como Usar

### Fluxo Padrão (HUD)
1.  Clique com o botão direito na pasta do projeto e escolha **"Gerar Blueprint / Contexto (Vibe AI)"**.
2.  No HUD, escolha o **Modo de Extração** (Sniper se for algo específico).
3.  Selecione o **Executor Alvo** (Onde você vai colar o prompt).
4.  Clique em **ENERGIZE**.
5.  O bundle estruturado será copiado para o seu clipboard!

### Versão CLI (Deep Integration)
Se quiser rodar puramente via script:
```powershell
.\project-bundler.ps1 -Path "C:\caminho\do\meu\projeto"
```

---

## 🧠 Princípios de Engenharia
*   **Predictability:** Markdown padronizado para evitar alucinações de interpretadores de prompt.
*   **Resilience:** Failover de infraestrutura em nível de API.
*   **Tokens-Efficiency:** Estratégias de blueprint para reduzir custos e aumentar a janela de contexto.
*   **Local-First:** Leitura de arquivos local e segura.

---
*VibeToolkit © 2026 - Engineered for the Agentic Era*

