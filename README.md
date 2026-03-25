# 🛠️ VibeToolkit ⚡

O **VibeToolkit** é uma engine de alta densidade para empacotamento de contexto e orquestração de Large Language Models (LLMs). Projetado para fluxos de "Vibe Coding", ele transforma repositórios de código em artefactos estruturados, eliminando o ruído conversacional e forçando a precisão técnica através do **Protocolo ELITE v2**.

## 🎯 Filosofia Operacional
O VibeToolkit não é um invólucro de chat comum. É um pipeline de conformidade que prioriza:
* **Zero-Yap:** Saídas estritamente técnicas, sem saudações ou explicações desnecessárias.
* **Densidade de Contexto:** Máxima informação útil com o menor ruído possível.
* **Isolamento de Papéis:** Separação rígida entre análise estratégica (Diretor) e implementação de código (Executor).

---

## 🛡️ Protocolo ELITE v2 (Strict Global Enforcement)
O toolkit opera sob regras transversais que garantem a integridade da saída:
1.  **Proibição de Inferência:** A IA está proibida de assumir arquiteturas ou fluxos não documentados no bundle visível.
2.  **Enquadramento de Rota:** Bloqueio de drift operacional (um Executor nunca deve agir como Diretor).
3.  **JSON Enforcement:** Validação obrigatória de schemas. Respostas fora do padrão são automaticamente submetidas a reparação estrutural.

---

## 🏗️ Arquitetura e Componentes

### 1. Core Engine (`groq-agent.ts`)
O coração do pipeline. Gere a normalização de rotas, montagem de prompts dinâmicos, chamadas multiplataforma e a gravação final dos artefactos de contexto.

### 2. Interface Operacional (`project-bundler.ps1`)
Console HUD em PowerShell que gere o estado visual do toolkit:
* Seleção de modos e providers.
* Gestão de ficheiros e geração de bundles.
* Log em tempo real e interface de visualização de progresso.

### 3. Sentinel Gatekeeper (`patch_agent.js`)
Script de reforço que aplica patches de conformidade em runtime, garantindo que o agente adira estritamente às instruções do sistema.

---

## ⚙️ Modos de Operação

### Rotas de Saída (Route Modes)
* **Diretor:** Focado em inteligência analítica. Gera especificações, diagnósticos de causa raiz e planos de implementação.
* **Executor:** Focado em implementação direta (Code-First). Converte planos em código funcional e patches cirúrgicos.

### Modos de Extração (Extraction Modes)
* **FULL:** Panorama completo do projeto para contexto total.
* **BLUEPRINT:** Foco em arquitetura, assinaturas de contratos e topologia (ideal para sistemas complexos).
* **SNIPER:** Atuação granular em ficheiros específicos para correções pontuais e patches rápidos.

---

## 🚀 Configuração e Instalação

### Pré-requisitos
* Node.js (v18+) & npm/pnpm
* PowerShell 7+ (para o HUD)
* Runtime TypeScript (`tsx`)

### Instalação
```bash
# Instalar dependências
npm install

# Configurar Variáveis de Ambiente (.env)
GROQ_API_KEY=sua_chave
GEMINI_API_KEY=sua_chave
OPENAI_API_KEY=sua_chave
ANTHROPIC_API_KEY=sua_chave
```

---

## 🛠️ Utilização

### 1. Via HUD (Interface Visual)
Execute o bundler para abrir o console de gestão:
```powershell
.\project-bundler.ps1
```

### 2. Via CLI (Execução Direta)
O agente pode ser chamado via terminal para automação:
```bash
npx --quiet tsx .\groq-agent.ts `
  --bundlePath "./bundles/meu-projeto.md" `
  --projectName "MeuProjeto" `
  --extractionMode "full" `
  --provider "groq" `
  --routeMode "executor"
```

---

## 💾 Padrões de Saída (Output)
Os ficheiros são gerados na raiz ou no diretório de saída seguindo a convenção:

| Tipo de Ficheiro | Nomenclatura | Descrição |
| :--- | :--- | :--- |
| **Contexto (.md)** | `_<rota>_AI_CONTEXT_<Projeto>.md` | O artefacto técnico final gerado pela IA. |
| **Metadados (.json)** | `_<rota>_AI_RESULT_<Projeto>.json` | Detalhes da execução, modelo usado e metadados estruturados. |

---

## 🧰 Stack Técnica
* **Runtime:** Node.js, PowerShell.
* **Linguagens:** TypeScript, PowerShell Scripting.
* **Modelos Suportados:** Llama 3.3 (Groq), Gemini 1.5 Pro, GPT-4o, Claude 3.5 Sonnet.
* **Processamento:** `tsx` para execução TypeScript sem transpilação manual.

---
> **Filosofia Final:** *O código é o detalhe, o contexto é a lei. Reduza o ruído, aumente o sinal.*