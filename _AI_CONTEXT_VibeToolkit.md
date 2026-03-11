> # CONTEXTO DO PROJETO
Aqui está um resumo claro e simples sobre o projeto VibeToolkit:

**1. Tecnologias usadas:**
O projeto VibeToolkit utiliza as seguintes tecnologias:
- dotenv (para gerenciar variáveis de ambiente)
- groq-sdk (para interagir com a API do Groq)
- TypeScript (para escrever o código)
- Node.js (para executar o código)

**2. Organização dos arquivos e pastas:**
Os arquivos e pastas estão organizados da seguinte forma:
- O projeto tem um arquivo `groq-agent.ts` que contém o código principal
- Existem arquivos de configuração como `package.json`, `tsconfig.json` e `README.md`
- Há também scripts em PowerShell como `project-bundler.ps1` e `setup-menu.ps1`

**3. Propósito do projeto:**
O projeto VibeToolkit parece ser uma ferramenta para gerar contextos de projeto de forma inteligente, utilizando a API do Groq. Ele pode ser usado para criar documentos de contexto para projetos, com base em prompts de usuário e modelos pré-definidos. Em resumo, é uma ferramenta para ajudar a criar documentos de contexto de forma automática e inteligente.

---

# ESTRUTURA E CÓDIGO (REFERÊNCIA TÉCNICA)
# MODO INTELIGENTE: VibeToolkit

## 1. TECH STACK
* **Deps:** dotenv, groq-sdk
* **Dev Deps:** @types/node, tsx, typescript

## 2. PROJECT STRUCTURE
```text
.\groq-agent.ts
.\package.json
.\project-bundler.ps1
.\README.md
.\setup-menu.ps1
.\tsconfig.json
.\_COPIAR_TUDO__VibeToolkit.md
.\_INTELIGENTE__VibeToolkit.md
```

## 3. CORE DOMAINS & CONTRACTS
### File: .\groq-agent.ts
```typescript
interface GroqRequestParams {
    model: string;
    systemContent: string;
    userPrompt: string;
    temperature?: number;
    maxTokens?: number;
}
const logger = 
const SYSTEM_PROMPT = `
class GroqService 
const response = await this.client.chat.completions.create(
const absolutePath = path.resolve(process.cwd(), bundlePath);
const groqService = new GroqService();
const result = await groqService.generateContextDocument(
const outputPath = path.resolve(path.dirname(absolutePath), `_AI_CONTEXT_$
const instructionalHeader = `> # CONTEXTO DO PROJETO
const finalFile = `$
```