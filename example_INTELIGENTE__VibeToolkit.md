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
.\_COPIAR_TUDO__VibeToolkit.md
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

