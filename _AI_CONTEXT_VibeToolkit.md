> # COTEXTO DO PROJETO - VIBETOOLKIT
> **COMO USAR ESTE ARQUIVO:**
> Instruções: Copie TODO o conteúdo deste arquivo e cole no ChatGPT, Claude ou Gemini. Na linha de baixo, escreva o que você quer fazer (Exemplo: 'Com base nesse meu projeto, crie um botão azul na tela inicial').

Olá! Vamos analisar o projeto VibeToolkit de forma simples e clara.

**1. Tecnologias usadas:**
Este projeto utiliza as seguintes tecnologias:
- dotenv (para gerenciar variáveis de ambiente)
- groq-sdk (para interagir com a API do Groq)
- TypeScript (para escrever o código em uma linguagem mais segura e organizada)
- Node.js (para executar o código)

**2. Organização dos arquivos e pastas:**
A estrutura do projeto é simples, com todos os arquivos importantes na raiz do projeto. Os principais arquivos são:
- `groq-agent.ts` (contém o código principal do projeto)
- `package.json` (contém informações sobre o projeto e suas dependências)
- `tsconfig.json` (configuração do TypeScript)

**3. Para que serve este projeto:**
Este projeto parece ser uma ferramenta para gerar documentos de contexto para projetos, utilizando a API do Groq. Ele recebe alguns parâmetros, como um modelo e um prompt, e gera um documento de contexto com base nesses parâmetros. O projeto parece ser uma ferramenta de automação para ajudar a criar documentos de contexto de forma mais eficiente.

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
const instructionalHeader = `> # COTEXTO DO PROJETO - VIBETOOLKIT
const finalFile = `$
```