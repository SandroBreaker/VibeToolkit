import Groq from "groq-sdk";
import * as dotenv from "dotenv";
import { promises as fs } from "fs";
import * as path from "path";

// Força o dotenv a procurar o .env na mesma pasta deste script (VibeToolkit)
dotenv.config({ path: path.resolve(__dirname, '.env') });

interface GroqRequestParams {
    model: string;
    systemContent: string;
    userPrompt: string;
    temperature?: number;
    maxTokens?: number;
}

interface Logger {
    info: (message: string, meta?: Record<string, unknown>) => void;
    error: (message: string, error?: unknown) => void;
}

const logger: Logger = {
    info: (message, meta) => console.log(JSON.stringify({ level: "INFO", message, ...meta })),
    error: (message, error) => console.error(JSON.stringify({ level: "ERROR", message, error }))
};

const SYSTEM_PROMPT = `
ROLE: PRINCIPAL_SOFTWARE_ARCHITECT
OBJECTIVE: Analisar o dump de um projeto (Blueprint/Bundler) e gerar um "AI Context Briefing" de ALTÍSSIMA DENSIDADE. Este arquivo servirá de System Prompt primário para outras IAs codificarem no projeto.

RESTRIÇÕES ABSOLUTAS (NON-NEGOTIABLE):
- ZERO FLUFF: Proibido usar linguagem comercial, genérica ou de "produto" (ex: "O objetivo é fornecer uma experiência...", "Arquitetura modular moderna...").
- ZERO OBVIEDADES: Não explique o que o React faz. Foque nas particularidades DESTE projeto.
- ZERO ALUCINAÇÃO: Não crie regras que dependam de arquivos que a próxima IA não terá (ex: "Consulte a documentação externa").
- MODO: Extração cirúrgica de metadados, contratos e infraestrutura.

ESTRUTURA OBRIGATÓRIA DA SAÍDA (MARKDOWN):

### 1. SYSTEM_IDENTITY
- Resumo técnico brutalista (1 ou 2 frases). Ex: "React SPA gamificado focado em leitura bíblica, utilizando Supabase (Auth/DB) e Google GenAI para insights contextuais".

### 2. TECH_STACK_&_INTEGRATIONS
- Listar apenas dependências core e integrações externas (BaaS, LLMs, APIs).

### 3. ARCHITECTURAL_PATTERNS
- Padrões exatos extraídos do código (ex: "Service Layer pattern com instâncias Singleton exportadas", "Gerenciamento de estado via useLocalStorage", "Tipagem baseada em interfaces rigorosas").

### 4. CORE_MECHANICS_&_DOMAIN
- Extrair as lógicas de negócio específicas a partir das assinaturas (ex: Gamification (Badges, XP, Streaks), Contextualização por tempo/humor (TimeContext, EmotionType), Enriquecimento via IA).

### 5. AI_HARD_GUARDRAILS
- Diretrizes acionáveis e estritas para a próxima IA. (ex: "Preservar assinaturas do SupabaseClient", "Manter compatibilidade com interfaces de Gamificação", "Proibido remover hooks customizados").
`;

class GroqService {
    private readonly client: Groq;

    constructor() {
        const apiKey = process.env.GROQ_API_KEY;
        if (!apiKey) {
            throw new Error("Variável de ambiente GROQ_API_KEY não definida.");
        }
        this.client = new Groq({ apiKey });
    }

    public async generateContextDocument(params: GroqRequestParams): Promise<string | null> {
        try {
            logger.info("Iniciando análise arquitetural no Groq", { model: params.model });

            const response = await this.client.chat.completions.create({
                messages: [
                    { role: "system", content: params.systemContent },
                    { role: "user", content: params.userPrompt },
                ],
                model: params.model,
                temperature: params.temperature ?? 0.1,
                max_tokens: params.maxTokens ?? 4000,
            });

            const content = response.choices[0]?.message?.content;
            
            if (!content) {
                logger.error("Resposta vazia da API Groq");
                return null;
            }

            return content;
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : "Erro desconhecido";
            logger.error("Falha na requisição da API Groq", { error: errorMessage });
            return null;
        }
    }
}

async function main(): Promise<void> {
    try {
        const args = process.argv.slice(2);
        if (args.length < 2) {
            logger.error("Parâmetros insuficientes. Uso: npx tsx groq-agent.ts <caminho_do_bundle> <nome_do_projeto>");
            process.exit(1);
        }

        const bundlePath = args[0];
        const projectName = args[1];
        
        const absoluteBundlePath = path.resolve(process.cwd(), bundlePath);
        const sourceCodeDump = await fs.readFile(absoluteBundlePath, "utf-8");
        
        const groqService = new GroqService();
        const params: GroqRequestParams = {
            model: "llama-3.3-70b-versatile",
            systemContent: SYSTEM_PROMPT,
            userPrompt: `Analise o seguinte código/blueprint do projeto '${projectName}' e gere o AI Context Briefing:\n\n${sourceCodeDump}`,
            temperature: 0.1,
            maxTokens: 4000
        };

        const result = await groqService.generateContextDocument(params);
        
        if (result) {
            const outputDir = path.dirname(absoluteBundlePath);
            const outputPath = path.resolve(outputDir, `_AI_CONTEXT_${projectName}.md`);
            
            // Injeta a Persona Executora, o Resumo da IA e o Blueprint original
            const finalSuperPrompt = `<system_instruction>
ROLE: SENIOR_FULLSTACK_ARCHITECT_EXECUTOR
DETERMINISM_MODE: LOW_ENTROPY
OUTPUT_VARIANCE: MINIMIZED
CREATIVITY: DISABLED
SPECULATION: FORBIDDEN

MISSION:
Analisar o contexto e aplicar diretamente as alterações solicitadas,
gerando o código atualizado do(s) arquivo(s) impactado(s).

EXECUTION_MODE: Você executa as modificações.

ABSOLUTE OUTPUT RULE:
- Retornar exclusivamente o código completo do arquivo modificado.

FILE DELIVERY CONTRACT:
- Sempre devolver o arquivo inteiro.
- Nunca devolver apenas trechos.
- Nunca usar "..." para omitir partes.
- Nunca remover partes não solicitadas.
- Nunca alterar fora do escopo.
- Manter nomes originais e estrutura existente.

LOGIC ENFORCEMENT:
- Preservar comportamento atual e zero regressão funcional.
- Não remover hooks, funções ou lógica existente sem instrução.

PERFORMANCE ENFORCEMENT:
- Não degradar performance e evitar re-renders desnecessários.
</system_instruction>

# AI PROJECT CONTEXT BRIEFING
${result}

---

# PROJECT BLUEPRINT (TECHNICAL REFERENCE)
${sourceCodeDump}`;
            
            await fs.writeFile(outputPath, finalSuperPrompt, "utf-8");
            logger.info("Super Prompt unificado gerado com sucesso", { output: outputPath });
        }
    } catch (error: unknown) {
        const errorMessage = error instanceof Error ? error.message : "Erro fatal na aplicação";
        logger.error("Falha na execução principal", { error: errorMessage });
        process.exit(1);
    }
}

main();