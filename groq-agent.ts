import Groq from "groq-sdk";
import * as dotenv from "dotenv";
import { promises as fs } from "fs";
import * as path from "path";

dotenv.config({ path: path.resolve(__dirname, ".env") });

interface GroqRequestParams {
    model: string;
    systemContent: string;
    userPrompt: string;
    temperature?: number;
    maxTokens?: number;
}

const logger = {
    info: (message: string) => {
        console.log(`[AI] ${message}`);
    },
    error: (message: string, error?: any) => {
        console.error(`[!] ERRO: ${message}`);
        if (error) {
            if (error.status === 401) {
                console.error("    Sua chave da Groq falhou. Verifique o arquivo .env.");
                console.error("    Dica: Acesse console.groq.com, crie uma nova chave e cole lá.");
            }
            else if (error.status === 429) {
                console.error("    O limite de uso gratuito da Groq foi atingido. Tente novamente em alguns minutos.");
            }
            else {
                console.error(`    Detalhes técnicos: ${error.message || error}`);
            }
        }
    }
};

const SYSTEM_PROMPT = `
Você é um "Mentor de Vibe-Coding Senior". 
Sua tarefa é analisar o código do projeto enviado e gerar um documento de contexto que ajude o usuário (provavelmente um iniciante) a continuar desenvolvendo.

Entregue o seguinte conteúdo em Markdown:
1. **Resumo Executivo:** O que o projeto faz de forma simples e "cool".
2. **Mapa de Vibe:** Quais tecnologias estão sendo usadas e por que elas são boas.
3. **Próximos Passos:** Sugira 3 funcionalidades ou melhorias que o usuário poderia fazer a seguir para evoluir o projeto.
4. **Alerta de Mentor:** Identifique algum "code smell" ou algo que possa ser melhorado na estrutura atual.
5. **Prompt Sugerido:** Um prompt pronto que o usuário pode colar no chat para pedir a primeira melhoria.

Use uma linguagem amigável, direta e cheia de energia positiva (use emojis). Não crie explicações longas ou código novo agora.
`;

class GroqService {
    private client: Groq;
    constructor() {
        this.client = new Groq({ apiKey: process.env.GROQ_API_KEY || "MISSING_KEY" });
    }

    public async generateContextDocument(params: GroqRequestParams): Promise<string | null> {
        try {
            const response = await this.client.chat.completions.create({
                messages: [{ role: "system", content: params.systemContent }, { role: "user", content: params.userPrompt }],
                model: params.model,
                temperature: 0.1,
            });
            return response.choices[0]?.message?.content || null;
        } catch (error) {
            logger.error("Falha na API Groq", error);
            return null;
        }
    }
}

async function main() {
    // Validação imediata da API Key para ajudar o usuário
    if (!process.env.GROQ_API_KEY) {
        logger.error("Ops! Não achamos a sua chave da API da Groq no arquivo .env");
        process.exit(1);
    }

    const [bundlePath, projectName] = process.argv.slice(2);
    if (!bundlePath) process.exit(1);

    const absolutePath = path.resolve(process.cwd(), bundlePath);
    let sourceCodeDump = await fs.readFile(absolutePath, "utf-8");

    sourceCodeDump = sourceCodeDump.replace(/<system_instruction>[\s\S]*?<\/system_instruction>/g, "").trim();

    const groqService = new GroqService();
    const result = await groqService.generateContextDocument({
        model: "llama-3.3-70b-versatile",
        systemContent: SYSTEM_PROMPT,
        userPrompt: `Analise este projeto '${projectName}':\n\n${sourceCodeDump}`,
    });

    if (result) {
        const outputPath = path.resolve(path.dirname(absolutePath), `_AI_CONTEXT_${projectName}.md`);

        const instructionalHeader = `> # CONTEXTO DO PROJETO
`;

        const finalFile = `${instructionalHeader}${result.trim()}\n\n---\n\n# ESTRUTURA E CÓDIGO (REFERÊNCIA TÉCNICA)\n${sourceCodeDump}`;
        await fs.writeFile(outputPath, finalFile, "utf-8");
        logger.info("Resumo criado com sucesso e pronto para uso.");
    }
}

main();