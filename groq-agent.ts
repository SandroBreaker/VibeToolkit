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
    if (!process.env.GROQ_API_KEY) {
        logger.error("Ops! Não achamos a sua chave da API da Groq no arquivo .env");
        process.exit(1);
    }

    const [bundlePath, projectName, executorTarget, bundleMode = "full"] = process.argv.slice(2);
    if (!bundlePath || !executorTarget) process.exit(1);

    const absolutePath = path.resolve(process.cwd(), bundlePath);
    let sourceCodeDump = await fs.readFile(absolutePath, "utf-8");

    sourceCodeDump = sourceCodeDump.replace(/# ♊ CONFIGURAÇÃO PARA AI STUDIO APPS[\s\S]*?```\s*/g, "").trim();
    sourceCodeDump = sourceCodeDump.replace(/# 🛸 CONFIGURAÇÃO PARA ANTIGRAVITY[\s\S]*?```\s*/g, "").trim();

    const isManualBundle = bundleMode === "manual" || path.basename(absolutePath).startsWith("_MANUAL__");

    const systemPrompt = isManualBundle
        ? `
Você é um ENGENHEIRO DE SOFTWARE SÊNIOR E ARQUITETO DE IA.
Sua tarefa é analisar exclusivamente o recorte de código enviado e gerar um DOCUMENTO DE CONTEXTO TÉCNICO (Source of Truth) detalhado.

Este documento servirá como base de conhecimento absoluto para um Orquestrador (como Gemini Web ou ChatGPT), garantindo que ele compreenda apenas o escopo visível antes de qualquer intervenção no ambiente ${executorTarget}.
REGRAS RÍGIDAS:
- O bundle atual é um RECORTE PARCIAL e de ESCOPO FECHADO.
- Analise SOMENTE os arquivos presentes no bundle recebido.
- NÃO trate o conteúdo como representação do projeto inteiro.
- NÃO infira arquitetura global, módulos ausentes, dependências não visíveis ou fluxos externos não mostrados.
- Quando houver lacuna de contexto, declare explicitamente: "não visível no recorte enviado".
- NÃO gere comandos de ação imediata.
- NÃO crie prompts solicitando alterações no código.
- Seu foco exclusivo é mapear a verdade atual do recorte fornecido, de forma neutra e técnica.

Entregue o seguinte conteúdo em Markdown:
1. **Escopo da Análise:** Deixe explícito que a leitura cobre somente os arquivos enviados.
2. **Tech Stack & Dependências Visíveis:** Liste apenas tecnologias e bibliotecas explicitamente observáveis no recorte.
3. **Project Structure do Recorte:** Resumo objetivo apenas dos arquivos listados no bundle.
4. **Core Domains & Contratos Visíveis:** Identifique interfaces, classes principais e métodos críticos apenas do que estiver presente.
5. **Estado Atual (Snapshot do Recorte):** Analise tecnicamente o que o código lido faz atualmente e como os módulos visíveis se comunicam.
`
        : `
Você é um ENGENHEIRO DE SOFTWARE SÊNIOR E ARQUITETO DE IA.
Sua tarefa é analisar o código do projeto enviado e gerar um DOCUMENTO DE CONTEXTO TÉCNICO (Source of Truth) detalhado.

Este documento servirá como base de conhecimento absoluto para um Orquestrador (como Gemini Web ou ChatGPT), garantindo que ele compreenda o estado atual do projeto antes de qualquer intervenção no ambiente ${executorTarget}.
REGRAS RÍGIDAS:
- NÃO gere comandos de ação imediata.
- NÃO crie prompts solicitando alterações no código.
- Seu foco exclusivo é mapear a verdade atual do código, estrutura, contratos e stack tecnológica de forma neutra e técnica.

Entregue o seguinte conteúdo em Markdown:
1. **Tech Stack & Dependências:** Lista clara das tecnologias e bibliotecas identificadas.
2. **Project Structure:** Resumo objetivo da organização de pastas e arquivos.
3. **Core Domains & Contratos:** Identificação de interfaces, classes principais (como GroqService) e métodos críticos.
4. **Estado Atual (Snapshot):** Uma análise técnica do que o código lido faz atualmente e como os módulos se comunicam.
`;

    const userPrompt = isManualBundle
        ? `Analise exclusivamente este recorte parcial do projeto '${projectName}'. O escopo é fechado e limitado aos arquivos presentes no bundle. Nunca assuma contexto externo. Sempre marque qualquer lacuna como 'não visível no recorte enviado'.\n\n${sourceCodeDump}`
        : `Analise este projeto '${projectName}' e mapeie o contexto técnico como Fonte da Verdade:\n\n${sourceCodeDump}`;

    const groqService = new GroqService();
    const result = await groqService.generateContextDocument({
        model: "llama-3.3-70b-versatile",
        systemContent: systemPrompt,
        userPrompt,
    });

    if (result) {
        const outputPath = path.resolve(path.dirname(absolutePath), `_AI_CONTEXT_${projectName}.md`);

        const instructionalHeader = isManualBundle
            ? `> # DOCUMENTO DE CONTEXTO TÉCNICO
> Este arquivo é a Fonte da Verdade (Source of Truth) do recorte enviado.
> O escopo desta análise é FECHADO e limitado apenas aos arquivos selecionados manualmente.
> Qualquer dependência, fluxo ou módulo não incluído deve ser tratado como "não visível no recorte enviado".
> NENHUMA AÇÃO DE CÓDIGO É EXIGIDA IMEDIATAMENTE APENAS COM A LEITURA DESTE ARQUIVO.

`
            : `> # DOCUMENTO DE CONTEXTO TÉCNICO
> Este arquivo é a Fonte da Verdade (Source of Truth) do projeto.
> Ele contém a estrutura, tech stack e os contratos base para referência do Orquestrador.
> NENHUMA AÇÃO DE CÓDIGO É EXIGIDA IMEDIATAMENTE APENAS COM A LEITURA DESTE ARQUIVO.

`;

        const finalFile = `${instructionalHeader}${result.trim()}\n\n---\n\n# ESTRUTURA E CÓDIGO (REFERÊNCIA TÉCNICA)\n${sourceCodeDump}`;
        await fs.writeFile(outputPath, finalFile, "utf-8");
        logger.info(`Documento de Contexto Técnico (Source of Truth) preparado com sucesso em: _AI_CONTEXT_${projectName}.md`);
    }
}

main();
