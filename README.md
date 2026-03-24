# VibeToolkit ⚡

O **VibeToolkit** é uma solução de engenharia de prompts e orquestração de LLMs (Large Language Models) de elite, desenhada especificamente para o fluxo de **Vibe Coding**. Ele automatiza a criação de contextos técnicos de altíssima densidade, permitindo que IAs atuem como **Diretores** (especificação e planeamento) ou **Executores** (implementação cirúrgica) com rigor operacional sem precedentes.

## 🧠 Filosofia: Agentic Mesh & Sentinel Command
O toolkit opera sob o **Protocolo Operacional Transversal — ELITE v2.1 (Optimized)** e é gerido internamente pelo **SENTINEL COMMAND**, um gatekeeper de integridade que impõe:
*   **Zero-Verbosity**: Saídas puramente técnicas, sem cortesias ou redundâncias.
*   **Token Economy**: Ultra-densidade de informação para maximizar janelas de contexto.
*   **Surgical Precision**: Alinhamento estrito entre o modo de extração e o papel da IA (Director/Executor).

## 🚀 Funcionalidades Principais

*   **Modos de Extração Inteligente**:
    *   **FULL**: Mapeamento completo para visão holística do sistema.
    *   **ARCHITECT (Blueprint)**: Focado em contratos, interfaces e dependências. Essencial para bases de código massivas.
    *   **SNIPER (Selective)**: Recorte manual preciso de arquivos específicos para correções pontuais.
    *   **TXT EXPORT**: Exporta ficheiros para uma estrutura física separada (`_TXT_EXPORT__`), ideal para análise externa offline.
*   **Orquestração Multi-Provider (Resilience Layer)**:
    *   Integração nativa com **Groq (Llama 3.3)**, **Gemini 1.5 Pro**, **OpenAI (GPT-4o)** e **Anthropic (Claude 3.5)**.
    *   **Failover Automático**: Cadeia de execução robusta que transita entre providers em caso de erro ou rate limits.
    *   **Observabilidade Avançada**: Diagnósticos detalhados de falhas no HUD via taxonomia de erros estruturada.
*   **Aesthetics & HUD Interface**: Interface PowerShell de alta performance com suporte a arrastar-e-soltar, modo fullscreen e logs em tempo real.

## 🛠️ Templates Operacionais (Registry)
O sistema inclui presets especializados para contextos comuns:
*   **Director**: Diagnostic (Root Cause), Feature Planning, Architecture Review, Hardening.
*   **Executor**: Surgical Patch, Feature Implementation, Safe Refactor, Regression Fix.

## 📋 Como Usar

### Interface Gráfica (HUD)
1.  **Ação**: Clique com o botão direito em qualquer pasta de projeto no Explorer.
2.  **Menu**: Selecione **"Gerar Blueprint / Contexto (Vibe AI)"**.
3.  **Configuração**: No painel HUD:
    *   Escolha o **Modo de Extração** (Full, Architect, Sniper ou TXT Export).
    *   Defina o **Fluxo** (Diretor para planeamento ou Executor para código).
    *   Selecione o **Executor Alvo** (Antigravity, AI Studio, etc).
4.  **Execução**: Clique em **ENERGIZE**. O contexto será gerado e/ou copiado automaticamente.

### CLI (Advanced)
```powershell
.\project-bundler.ps1 -Path "C:\caminho" -RouteMode "executor" -ExtractionMode "blueprint"
```

## 🏗️ Estrutura do Núcleo
*   `groq-agent.ts`: Motor de orquestração, normalização de documentos e gestão de prompts.
*   `project-bundler.ps1`: Orquestrador de UI, extração de assinaturas de código e bundling de arquivos.
*   `patch_agent.js`: Bridge de alta velocidade para transformações de contexto em tempo real.

---
*VibeToolkit © 2026 — Engineered for the Agentic Era*