# 🚀 VibeToolkit
**AI Context Synthesizer for Orchestrators**

O **VibeToolkit** é uma ferramenta de infraestrutura para IA focada em transformar projetos de software em bundles estruturados. Ele prepara o contexto ideal para **orquestradores** (como ChatGPT Web e Gemini Web), que geram o prompt final para execução em ferramentas como **AI Studio Apps** ou **Antigravity**.

O objetivo central é eliminar alucinações por falta de contexto, gerando uma **Source of Truth** (Fonte de Verdade) consistente e previsível.

---

## 🛠️ Fluxo de Trabalho

1.  **Consolidação:** Lê e agrupa arquivos relevantes do projeto.
2.  **Bundling:** Gera um arquivo Markdown estruturado.
3.  **Injeção:** Embuti instruções específicas para o executor alvo.
4.  **Orquestração (Opcional):** Chama uma IA para refinar o contexto.
5.  **Entrega:** Copia o prompt final para o clipboard, pronto para o uso.

### Stack Técnica
* **Runtime:** Node.js via `tsx` (TypeScript)
* **Interface:** PowerShell + WinForms (HUD Visual)
* **Providers:** Groq, Gemini, OpenAI e Anthropic.
* **Comunicação:** REST/JSON com fallback inteligente.

---

## ✨ Principais Recursos

### 🔄 Multi-provider com Fallback Automático
Suporte nativo a Groq, Gemini, OpenAI e Anthropic. Se o provedor primário falhar (Rate limit, erro de autenticação ou indisponibilidade), o toolkit aciona automaticamente o próximo da cadeia.

### 📂 Modos de Extração
* **Full Vibe:** Conteúdo completo de todos os arquivos (Entendimento global).
* **Architect:** Extrai apenas estruturas, contratos e assinaturas (Economia de tokens).
* **Sniper:** Seleção manual de arquivos para correções cirúrgicas.

### 🎯 Executores Alvo
O bundle é otimizado especificamente para o comportamento do executor final:
* **AI Studio Apps**
* **Antigravity**

---

## 📂 Estrutura do Projeto

* `groq-agent.ts`: Motor principal de orquestração e lógica de fallback.
* `project-bundler.ps1`: Interface (HUD), leitura de arquivos e montagem do bundle.
* `package.json`: Gerenciamento de dependências e scripts.
* `tsconfig.json`: Configurações de tipagem estrita do TypeScript.

---

## ⚙️ Configuração

### 1. Instalação
```bash
npm install
```

### 2. Variáveis de Ambiente
Crie um arquivo `.env` na raiz do projeto:
```env
GROQ_API_KEY=sua_chave
GEMINI_API_KEY=sua_chave
OPENAI_API_KEY=sua_chave
ANTHROPIC_API_KEY=sua_chave

# Modelos Preferenciais
GROQ_MODEL=llama-3.3-70b-versatile
GEMINI_MODEL=gemini-1.5-pro
OPENAI_MODEL=gpt-4o
ANTHROPIC_MODEL=claude-3-5-sonnet-20240620
```

---

## 🚀 Como Usar

### Via Interface Visual (Recomendado)
Execute o script PowerShell para abrir o HUD de controle:
```powershell
.\project-bundler.ps1
```
No HUD, você poderá selecionar o modo de extração, o executor alvo e o provedor de IA.

### Via Linha de Comando (CLI)
Para integrar em outros fluxos, chame o agente diretamente:
```bash
npx tsx groq-agent.ts <caminho_bundle> <nome_projeto> <executor> <modo> <provedor>
```

---

## 🛡️ Política de Resiliência
O toolkit utiliza a classe `ProviderRequestError` para monitorar a saúde das requisições. O sistema realiza retries e fallbacks automáticos em casos de:
* Erros de autenticação ou chaves expiradas.
* Rate limiting (Excesso de requisições).
* Respostas vazias ou instabilidade do servidor.

---

## 🧠 Princípios do Projeto
* **Previsibilidade:** Markdown padronizado para evitar interpretações erradas.
* **Eficiência:** Foco em reduzir o consumo de tokens sem perder a essência do código.
* **Contexto Fechado:** No modo Sniper, a IA é instruída a não assumir nada além do que foi fornecido.
