# CONTEXTO DO PROJETO
Aqui está um resumo claro e fácil de entender sobre o projeto "VibeToolkit":

**1. Tecnologias usadas:**
O projeto utiliza as seguintes tecnologias:
- dotenv (para gerenciar variáveis de ambiente)
- groq-sdk (para interagir com a API do Groq)
- TypeScript (para escrever o código)
- Node.js (para executar o código)

**2. Organização dos arquivos e pastas:**
Os arquivos e pastas estão organizados da seguinte forma:
- Todos os arquivos importantes estão na raiz do projeto, incluindo o arquivo `groq-agent.ts` que contém o código principal.
- Há arquivos de configuração como `package.json` e `tsconfig.json`.
- Há também scripts em PowerShell para realizar tarefas específicas.

**3. Propósito do projeto:**
O projeto "VibeToolkit" parece ser uma ferramenta que utiliza a API do Groq para gerar contextos de projeto de forma automática. Ele recebe parâmetros como modelo, conteúdo do sistema e prompt do usuário, e então gera um documento de contexto com base nesses parâmetros. O projeto parece ser útil para gerar documentação ou contexto para projetos de forma rápida e eficiente.

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
.\remove-menu.ps1
.\setup-menu.ps1
.\tsconfig.json
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