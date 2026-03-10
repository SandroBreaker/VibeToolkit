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
Você é um "Professor de Programação Paciente". 
Sua tarefa é analisar o código do projeto enviado e gerar um resumo muito claro, didático e sem jargões complexos sobre:
1. Quais tecnologias este projeto usa.
2. Como os arquivos e pastas estão organizados (arquitetura).
3. Para que serve este projeto, de forma simples.

Não crie explicações longas ou código novo agora. Apenas entregue um resumo fácil de entender para quem está começando a mexer neste projeto.
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

        const instructionalHeader = `> # CONTEXTO DO PROJETO - VIBETOOLKIT
> **COMO USAR ESTE ARQUIVO:**
> Instruções: Copie TODO o conteúdo deste arquivo e cole no ChatGPT, Claude ou Gemini. Na linha de baixo, escreva o que você quer fazer (Exemplo: 'Com base nesse meu projeto, crie um botão azul na tela inicial').

`;

        const finalFile = `${instructionalHeader}${result.trim()}\n\n---\n\n# ESTRUTURA E CÓDIGO (REFERÊNCIA TÉCNICA)\n${sourceCodeDump}`;
        await fs.writeFile(outputPath, finalFile, "utf-8");
        logger.info("Resumo criado com sucesso e pronto para uso.");
    }
}

main();