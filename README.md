# VibeToolkit ⚡

O **VibeToolkit** é uma solução de engenharia de prompts e orquestração de LLMs (Large Language Models) desenhada para o fluxo de "vibe coding". Ele automatiza a criação de contextos técnicos de alta densidade, permitindo que IAs atuem como **Diretores** (planeamento) ou **Executores** (implementação direta) com precisão cirúrgica.

## 🧠 Filosofia: Orchestrator-Executor
O toolkit opera sob o **Protocolo Operacional Transversal — ELITE v2**, que garante que a saída da IA seja estritamente técnica e compatível com o modo de extração ativo, eliminando alucinações de arquitetura.

## 🚀 Funcionalidades Principais

* **Modos de Extração Inteligente**:
    * **FULL**: Mapeamento completo do projeto para visão holística.
    * **BLUEPRINT (Architect)**: Focado em estruturas, interfaces, contratos e dependências, ideal para grandes bases de código onde o limite de tokens é um desafio.
    * **SNIPER (Manual)**: Focado apenas em recortes específicos de ficheiros para correções pontuais.
* **Multi-Provider com Failover**: Integração nativa com **Groq (Llama 3)**, **Gemini 1.5 Pro**, **OpenAI (GPT-4o)** e **Anthropic (Claude 3.5)**. Se um provider falhar ou atingir limites, o sistema transita automaticamente para o próximo da cadeia.
* **HUD e Integração com Windows**: Interface gráfica via PowerShell para seleção de modos e botão "ENERGIZE" para processamento imediato, com suporte a menu de contexto no botão direito do Windows.

## 🛠️ Stack Técnica
* **Runtime**: Node.js / TypeScript.
* **Orquestração**: PowerShell (HUD e scripts de automação).
* **Dependências**: `dotenv` para gestão de chaves e `fs/path` para manipulação de arquivos.

## 📋 Como Usar

### Interface Gráfica (HUD)
1.  Clique com o botão direito na pasta do seu projeto.
2.  Selecione **"Gerar Blueprint / Contexto (Vibe AI)"**.
3.  No HUD:
    * Escolha o **Modo de Extração** (Full, Architect ou Sniper).
    * Selecione o **Fluxo** (Diretor para planeamento ou Executor para código).
    * Escolha o **Executor Alvo** (ex: AI Studio, Claude, GPT).
4.  Clique em **ENERGIZE** para copiar o bundle estruturado para o clipboard.

### CLI (Integração Profunda)
```powershell
.\project-bundler.ps1 -Path "C:\caminho\do\projeto" -RouteMode "executor" -ExtractionMode "full"
```

## 🏗️ Estrutura do Projeto
* `groq-agent.ts`: Core da lógica de comunicação com LLMs e normalização de documentos.
* `project-bundler.ps1`: Script principal de interface e empacotamento de ficheiros.
* `patch_agent.js`: Script de suporte para transformações rápidas de contexto.

---
*VibeToolkit © 2026 — Engineered for the Agentic Era*