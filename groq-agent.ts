import * as dotenv from "dotenv";
import { promises as fs } from "fs";
import * as path from "path";

dotenv.config({ path: path.resolve(process.cwd(), ".env"), quiet: true });
dotenv.config({ path: path.resolve(__dirname, ".env"), quiet: true, override: false });

type ProviderId = "groq" | "gemini" | "openai" | "anthropic";
type DocumentMode = "manual" | "full";
type ExtractionMode = "full" | "blueprint" | "sniper";
type OutputRouteMode = "director" | "executor";

interface GenerateRequestParams {
    model: string;
    systemContent: string;
    userPrompt: string;
    temperature?: number;
    maxTokens?: number;
}

interface ProviderAttemptResult {
    provider: ProviderId;
    model: string;
    content: string | null;
}

interface ProviderConfig {
    id: ProviderId;
    displayName: string;
    model: string;
    apiKey: string | null;
}

interface CommonStructuredSections {
    documentPurpose: string;
    executiveSummary: string;
    analyzedScope: string;
    stackAndDependencies: string;
    architectureAndOrganization: string;
    contractsEntitiesAndFlows: string;
    designRulesAndObservedPatterns: string;
    regressionRisksAndOperationalCare: string;
    contextGaps: string;
    operationalInstructions: string;
}

interface StructuredDirectorPromptTemplate {
    context: string[];
    objective: string;
    rules: string[];
    delivery: string[];
    adaptationNotes: string[];
}

interface StructuredDirectorDocument {
    routeMode: "director";
    documentTitle: string;
    documentMode: DocumentMode;
    projectName: string;
    executorTarget: string;
    sections: CommonStructuredSections;
    directorPromptTemplate: StructuredDirectorPromptTemplate;
}

interface StructuredExecutorDocument {
    routeMode: "executor";
    documentTitle: string;
    documentMode: DocumentMode;
    projectName: string;
    executorTarget: string;
    sections: CommonStructuredSections;
}

type StructuredOutputDocument = StructuredDirectorDocument | StructuredExecutorDocument;

class ProviderRequestError extends Error {
    public readonly provider: ProviderId;
    public readonly status: number | null;
    public readonly details: string;
    public readonly retryable: boolean;

    constructor(provider: ProviderId, message: string, status: number | null = null, details = "", retryable = false) {
        super(message);
        this.name = "ProviderRequestError";
        this.provider = provider;
        this.status = status;
        this.details = details;
        this.retryable = retryable;
    }
}

const logger = {
    info: (message: string) => console.log(`[AI] ${message}`),
    warn: (message: string) => console.warn(`[AI] ${message}`),
    error: (message: string, error?: unknown) => {
        console.error(`[!] ERRO: ${message}`);

        if (!error) return;

        if (error instanceof ProviderRequestError) {
            const statusText = error.status ? ` (HTTP ${error.status})` : "";
            console.error(`    Provider: ${error.provider}${statusText}`);
            if (error.details) {
                console.error(`    Detalhes técnicos: ${error.details}`);
            }
            return;
        }

        if (error instanceof Error) {
            console.error(`    Detalhes técnicos: ${error.message}`);
            return;
        }

        console.error(`    Detalhes técnicos: ${String(error)}`);
    },
};

function getEnvValue(...keys: string[]): string | null {
    for (const key of keys) {
        const value = process.env[key]?.trim();
        if (value) return value;
    }
    return null;
}

function shouldFallback(status: number | null): boolean {
    if (status === null) return true;
    return [400, 401, 402, 403, 404, 408, 409, 422, 429, 500, 502, 503, 504].includes(status);
}

function normalizePrimaryProvider(input?: string): ProviderId {
    const value = (input || "groq").trim().toLowerCase();
    if (value === "groq" || value === "gemini" || value === "openai" || value === "anthropic") {
        return value;
    }
    return "groq";
}

function normalizeOutputRouteMode(input?: string): OutputRouteMode {
    return input?.trim().toLowerCase() === "executor" ? "executor" : "director";
}

function normalizeExtractionMode(input?: string): ExtractionMode {
    const val = input?.trim().toLowerCase();
    if (val === "blueprint" || val === "architect") return "blueprint";
    if (val === "sniper" || val === "manual") return "sniper";
    return "full";
}

function buildProviderChain(primaryProvider: ProviderId): ProviderId[] {
    const defaultOrder: ProviderId[] = ["groq", "gemini", "openai", "anthropic"];
    return [primaryProvider, ...defaultOrder.filter((provider) => provider !== primaryProvider)];
}

function getProviderConfig(provider: ProviderId): ProviderConfig {
    switch (provider) {
        case "groq":
            return {
                id: "groq",
                displayName: "Groq",
                model: getEnvValue("GROQ_MODEL", "VITE_GROQ_MODEL") || "llama-3.3-70b-versatile",
                apiKey: getEnvValue("GROQ_API_KEY", "VITE_GROQ_API_KEY"),
            };
        case "gemini":
            return {
                id: "gemini",
                displayName: "Gemini",
                model: getEnvValue("GEMINI_MODEL", "GOOGLE_MODEL", "VITE_GEMINI_MODEL") || "gemini-1.5-pro",
                apiKey: getEnvValue("GEMINI_API_KEY", "GOOGLE_API_KEY", "VITE_GEMINI_API_KEY"),
            };
        case "openai":
            return {
                id: "openai",
                displayName: "OpenAI",
                model: getEnvValue("OPENAI_MODEL", "VITE_OPENAI_MODEL") || "gpt-4o",
                apiKey: getEnvValue("OPENAI_API_KEY", "VITE_OPENAI_API_KEY"),
            };
        case "anthropic":
            return {
                id: "anthropic",
                displayName: "Anthropic",
                model: getEnvValue("ANTHROPIC_MODEL", "VITE_ANTHROPIC_MODEL") || "claude-3-5-sonnet-20240620",
                apiKey: getEnvValue("ANTHROPIC_API_KEY", "VITE_ANTHROPIC_API_KEY"),
            };
    }
}

async function parseErrorResponse(response: Response): Promise<string> {
    const contentType = response.headers.get("content-type") || "";

    try {
        if (contentType.includes("application/json")) {
            const json = await response.json();
            if (typeof json?.error?.message === "string") return json.error.message;
            if (typeof json?.error === "string") return json.error;
            if (typeof json?.message === "string") return json.message;
            return JSON.stringify(json);
        }

        return (await response.text()).trim() || response.statusText;
    } catch {
        return response.statusText || "Falha sem corpo de erro.";
    }
}

async function requestGroq(config: ProviderConfig, params: GenerateRequestParams): Promise<ProviderAttemptResult> {
    if (!config.apiKey) {
        throw new ProviderRequestError(config.id, "Chave Groq ausente.", null, "Defina GROQ_API_KEY.", true);
    }

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${config.apiKey}`,
        },
        body: JSON.stringify({
            model: params.model,
            temperature: params.temperature ?? 0.1,
            max_tokens: params.maxTokens ?? 8192,
            messages: [
                { role: "system", content: params.systemContent },
                { role: "user", content: params.userPrompt },
            ],
        }),
    });

    if (!response.ok) {
        throw new ProviderRequestError(
            config.id,
            "Erro Groq",
            response.status,
            await parseErrorResponse(response),
            shouldFallback(response.status)
        );
    }

    const json = await response.json();
    return {
        provider: config.id,
        model: params.model,
        content: json?.choices?.[0]?.message?.content ?? null,
    };
}

async function requestGemini(config: ProviderConfig, params: GenerateRequestParams): Promise<ProviderAttemptResult> {
    if (!config.apiKey) {
        throw new ProviderRequestError(config.id, "Chave Gemini ausente.", null, "Defina GEMINI_API_KEY.", true);
    }

    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(params.model)}:generateContent`;
    const response = await fetch(endpoint, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": config.apiKey,
        },
        body: JSON.stringify({
            system_instruction: { parts: [{ text: params.systemContent }] },
            contents: [{ role: "user", parts: [{ text: params.userPrompt }] }],
            generationConfig: {
                temperature: params.temperature ?? 0.1,
                maxOutputTokens: params.maxTokens ?? 8192,
            },
        }),
    });

    if (!response.ok) {
        throw new ProviderRequestError(
            config.id,
            "Erro Gemini",
            response.status,
            await parseErrorResponse(response),
            shouldFallback(response.status)
        );
    }

    const json = await response.json();
    const content =
        json?.candidates?.[0]?.content?.parts
            ?.map((part: { text?: string }) => part.text ?? "")
            .join("") || null;

    return {
        provider: config.id,
        model: params.model,
        content,
    };
}

async function requestOpenAI(config: ProviderConfig, params: GenerateRequestParams): Promise<ProviderAttemptResult> {
    if (!config.apiKey) {
        throw new ProviderRequestError(config.id, "Chave OpenAI ausente.", null, "Defina OPENAI_API_KEY.", true);
    }

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${config.apiKey}`,
        },
        body: JSON.stringify({
            model: params.model,
            temperature: params.temperature ?? 0.1,
            messages: [
                { role: "system", content: params.systemContent },
                { role: "user", content: params.userPrompt },
            ],
        }),
    });

    if (!response.ok) {
        throw new ProviderRequestError(
            config.id,
            "Erro OpenAI",
            response.status,
            await parseErrorResponse(response),
            shouldFallback(response.status)
        );
    }

    const json = await response.json();
    return {
        provider: config.id,
        model: params.model,
        content: json?.choices?.[0]?.message?.content ?? null,
    };
}

async function requestAnthropic(config: ProviderConfig, params: GenerateRequestParams): Promise<ProviderAttemptResult> {
    if (!config.apiKey) {
        throw new ProviderRequestError(config.id, "Chave Anthropic ausente.", null, "Defina ANTHROPIC_API_KEY.", true);
    }

    const response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "x-api-key": config.apiKey,
            "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
            model: params.model,
            max_tokens: params.maxTokens ?? 8192,
            system: params.systemContent,
            messages: [{ role: "user", content: params.userPrompt }],
        }),
    });

    if (!response.ok) {
        throw new ProviderRequestError(
            config.id,
            "Erro Anthropic",
            response.status,
            await parseErrorResponse(response),
            shouldFallback(response.status)
        );
    }

    const json = await response.json();
    const content =
        json?.content
            ?.filter((item: { type?: string }) => item.type === "text")
            .map((item: { text?: string }) => item.text ?? "")
            .join("") || null;

    return {
        provider: config.id,
        model: params.model,
        content,
    };
}

async function requestWithProvider(provider: ProviderId, params: GenerateRequestParams): Promise<ProviderAttemptResult> {
    const config = getProviderConfig(provider);

    switch (provider) {
        case "groq":
            return requestGroq(config, params);
        case "gemini":
            return requestGemini(config, params);
        case "openai":
            return requestOpenAI(config, params);
        case "anthropic":
            return requestAnthropic(config, params);
    }
}

async function generateContextDocument(
    params: Omit<GenerateRequestParams, "model">,
    primaryProvider: ProviderId
): Promise<ProviderAttemptResult | null> {
    const providerChain = buildProviderChain(primaryProvider);

    logger.info(`Provider primário: ${primaryProvider} | Fallback: ${providerChain.join(" -> ")}`);

    for (const provider of providerChain) {
        try {
            const config = getProviderConfig(provider);
            logger.info(`Tentando ${config.displayName} (${config.model})...`);

            const result = await requestWithProvider(provider, {
                ...params,
                model: config.model,
            });

            if (!result.content) {
                throw new ProviderRequestError(provider, "Resposta vazia.", null, "", true);
            }

            return result;
        } catch (error) {
            logger.error(`Falha no provider ${provider}`, error);

            if (error instanceof ProviderRequestError && !error.retryable) {
                break;
            }
        }
    }

    return null;
}

function normalizeSourceDump(content: string): string {
    return content.replace(/\r\n/g, "\n").replace(/\u0000/g, "").trim();
}

function normalizeBlockText(value: string): string {
    return value.replace(/\r\n/g, "\n").trim();
}

function normalizeList(values: string[]): string[] {
    const seen = new Set<string>();
    const normalized: string[] = [];

    for (const value of values) {
        const item = normalizeBlockText(value);
        if (!item) continue;

        const key = item.toLowerCase();
        if (seen.has(key)) continue;

        seen.add(key);
        normalized.push(item);
    }

    return normalized;
}

function isMarkdownHeadingLine(line: string): boolean {
    return /^(#{1,6})\s+\S/.test(line);
}

function isMarkdownFenceLine(line: string): boolean {
    return /^```/.test(line.trim());
}

function isMarkdownListLine(line: string): boolean {
    return /^(\s*[-*+]\s+\S|\s*\d+\.\s+\S)/.test(line);
}

function shiftEmbeddedHeadingLevel(line: string): string {
    const match = line.match(/^(#{3,6})(\s+.*)$/);
    if (!match) {
        return line;
    }

    return `${"#".repeat(match[1].length - 1)}${match[2]}`;
}

function formatMarkdownFragment(
    content: string,
    options: { shiftTechnicalHeadingLevels?: boolean } = {}
): string {
    const normalized = normalizeBlockText(content);

    if (!normalized) {
        return "\n";
    }

    const sourceLines = normalized.split("\n");
    const output: string[] = [];
    let inFence = false;
    let insideList = false;

    const pushBlankLine = () => {
        if (output.length > 0 && output[output.length - 1] !== "") {
            output.push("");
        }
    };

    for (const rawLine of sourceLines) {
        let line = rawLine.replace(/[ \t]+$/g, "");

        if (!inFence && options.shiftTechnicalHeadingLevels) {
            line = shiftEmbeddedHeadingLevel(line);
        }

        const trimmed = line.trim();

        if (trimmed === "") {
            if (inFence) {
                output.push("");
            } else {
                insideList = false;
                pushBlankLine();
            }
            continue;
        }

        if (isMarkdownFenceLine(line)) {
            if (!inFence) {
                pushBlankLine();
            }

            output.push(line);
            inFence = !inFence;
            insideList = false;

            if (!inFence) {
                output.push("");
            }

            continue;
        }

        if (inFence) {
            output.push(line);
            continue;
        }

        if (isMarkdownHeadingLine(line)) {
            pushBlankLine();
            output.push(line);
            output.push("");
            insideList = false;
            continue;
        }

        const isListLine = isMarkdownListLine(line);

        if (isListLine && !insideList) {
            pushBlankLine();
        }

        if (!isListLine && insideList) {
            pushBlankLine();
        }

        output.push(line);
        insideList = isListLine;
    }

    while (output.length > 0 && output[output.length - 1] === "") {
        output.pop();
    }

    return `${output.join("\n")}\n`;
}

function normalizeMarkdownHeadingHierarchy(content: string, fallbackTitle: string): string {
    const normalized = normalizeBlockText(content);

    if (!normalized) {
        return `# ${fallbackTitle}\n`;
    }

    const sourceLines = normalized.split("\n");
    const output: string[] = [];
    let inFence = false;
    let sawFirstNonEmptyLine = false;
    let previousHeadingLevel = 0;

    for (const rawLine of sourceLines) {
        let line = rawLine.replace(/[ \t]+$/g, "");
        const trimmed = line.trim();

        if (!sawFirstNonEmptyLine && trimmed !== "") {
            sawFirstNonEmptyLine = true;

            if (!isMarkdownHeadingLine(line)) {
                output.push(`# ${fallbackTitle}`);
                output.push("");
                previousHeadingLevel = 1;
            }
        }

        if (isMarkdownFenceLine(line)) {
            output.push(line);
            inFence = !inFence;
            continue;
        }

        if (!inFence) {
            const headingMatch = line.match(/^(#{1,6})\s+(.*)$/);
            if (headingMatch) {
                const originalLevel = headingMatch[1].length;
                const text = headingMatch[2].trim();

                if (text) {
                    const normalizedLevel =
                        previousHeadingLevel === 0 ? 1 : Math.min(originalLevel, previousHeadingLevel + 1);

                    line = `${"#".repeat(normalizedLevel)} ${text}`;
                    previousHeadingLevel = normalizedLevel;
                }
            }
        }

        output.push(line);
    }

    if (!sawFirstNonEmptyLine) {
        return `# ${fallbackTitle}\n`;
    }

    return output.join("\n");
}

function normalizeCustomMarkdownOutput(content: string, projectName: string): string {
    const withSafeHierarchy = normalizeMarkdownHeadingHierarchy(content, `Contexto Técnico - ${projectName}`);
    return formatMarkdownFragment(withSafeHierarchy).trimEnd() + "\n";
}

function getFirstMatchIndex(content: string, patterns: RegExp[]): number | null {
    for (const pattern of patterns) {
        const match = pattern.exec(content);
        if (match?.index !== undefined) {
            return match.index;
        }
    }

    return null;
}

function extractTechnicalBundleDump(rawBundleDump: string): string {
    const normalized = normalizeSourceDump(rawBundleDump);

    const technicalSectionIndex = getFirstMatchIndex(normalized, [
        /^### 0\. ANALYSIS SCOPE$/m,
        /^### 1\. TECH STACK$/m,
        /^### 1\. PROJECT STRUCTURE$/m,
        /^### 2\. PROJECT STRUCTURE$/m,
        /^### 2\. SOURCE FILES$/m,
    ]);

    if (technicalSectionIndex !== null) {
        return normalized.slice(technicalSectionIndex).trim();
    }

    const modeHeadingIndex = getFirstMatchIndex(normalized, [/^## MODO [^\n]+$/m]);
    if (modeHeadingIndex !== null) {
        return normalized.slice(modeHeadingIndex).trim();
    }

    return normalized;
}

function extractJsonCandidate(content: string): string | null {
    const trimmed = content.trim();

    const fencedMatch = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
    if (fencedMatch?.[1]) {
        return fencedMatch[1].trim();
    }

    const firstBrace = trimmed.indexOf("{");
    const lastBrace = trimmed.lastIndexOf("}");
    if (firstBrace >= 0 && lastBrace > firstBrace) {
        return trimmed.slice(firstBrace, lastBrace + 1).trim();
    }

    return null;
}

function isNonEmptyString(value: unknown): value is string {
    return typeof value === "string" && value.trim().length > 0;
}

function isStringArray(value: unknown): value is string[] {
    return Array.isArray(value) && value.every(isNonEmptyString);
}

function parseCommonSections(sections: Record<string, unknown>): CommonStructuredSections {
    const requiredKeys: Array<keyof CommonStructuredSections> = [
        "documentPurpose",
        "executiveSummary",
        "analyzedScope",
        "stackAndDependencies",
        "architectureAndOrganization",
        "contractsEntitiesAndFlows",
        "designRulesAndObservedPatterns",
        "regressionRisksAndOperationalCare",
        "contextGaps",
        "operationalInstructions",
    ];

    for (const key of requiredKeys) {
        if (!isNonEmptyString(sections[key])) {
            throw new Error(`Seção obrigatória ausente ou vazia: ${key}.`);
        }
    }

    return {
        documentPurpose: normalizeBlockText(sections.documentPurpose as string),
        executiveSummary: normalizeBlockText(sections.executiveSummary as string),
        analyzedScope: normalizeBlockText(sections.analyzedScope as string),
        stackAndDependencies: normalizeBlockText(sections.stackAndDependencies as string),
        architectureAndOrganization: normalizeBlockText(sections.architectureAndOrganization as string),
        contractsEntitiesAndFlows: normalizeBlockText(sections.contractsEntitiesAndFlows as string),
        designRulesAndObservedPatterns: normalizeBlockText(sections.designRulesAndObservedPatterns as string),
        regressionRisksAndOperationalCare: normalizeBlockText(sections.regressionRisksAndOperationalCare as string),
        contextGaps: normalizeBlockText(sections.contextGaps as string),
        operationalInstructions: normalizeBlockText(sections.operationalInstructions as string),
    };
}

function parseStructuredDocument(rawContent: string, outputRouteMode: OutputRouteMode): StructuredOutputDocument {
    const candidate = extractJsonCandidate(rawContent);
    if (!candidate) {
        throw new Error("A resposta da IA não contém JSON extraível.");
    }

    let parsed: unknown;
    try {
        parsed = JSON.parse(candidate);
    } catch (error) {
        throw new Error(`JSON inválido retornado pela IA: ${error instanceof Error ? error.message : String(error)}`);
    }

    if (typeof parsed !== "object" || parsed === null) {
        throw new Error("Payload estruturado inválido: raiz não é um objeto.");
    }

    const payload = parsed as Record<string, unknown>;
    const sections = payload.sections as Record<string, unknown> | undefined;

    if (payload.routeMode !== outputRouteMode) {
        throw new Error(`routeMode inválido. Esperado: ${outputRouteMode}.`);
    }

    if (!isNonEmptyString(payload.documentTitle)) throw new Error("Campo obrigatório ausente: documentTitle.");
    if (payload.documentMode !== "manual" && payload.documentMode !== "full") throw new Error("Campo obrigatório inválido: documentMode.");
    if (!isNonEmptyString(payload.projectName)) throw new Error("Campo obrigatório ausente: projectName.");
    if (!isNonEmptyString(payload.executorTarget)) throw new Error("Campo obrigatório ausente: executorTarget.");
    if (!sections || typeof sections !== "object") throw new Error("Campo obrigatório ausente: sections.");

    const parsedSections = parseCommonSections(sections);

    if (outputRouteMode === "director") {
        const promptTemplate = payload.directorPromptTemplate as Record<string, unknown> | undefined;
        if (!promptTemplate || typeof promptTemplate !== "object") {
            throw new Error("Campo obrigatório ausente: directorPromptTemplate.");
        }

        if (!isStringArray(promptTemplate.context)) throw new Error("Campo obrigatório inválido: directorPromptTemplate.context.");
        if (!isNonEmptyString(promptTemplate.objective)) throw new Error("Campo obrigatório inválido: directorPromptTemplate.objective.");
        if (!isStringArray(promptTemplate.rules)) throw new Error("Campo obrigatório inválido: directorPromptTemplate.rules.");
        if (!isStringArray(promptTemplate.delivery)) throw new Error("Campo obrigatório inválido: directorPromptTemplate.delivery.");
        if (!isStringArray(promptTemplate.adaptationNotes)) throw new Error("Campo obrigatório inválido: directorPromptTemplate.adaptationNotes.");

        return {
            routeMode: "director",
            documentTitle: normalizeBlockText(payload.documentTitle),
            documentMode: payload.documentMode,
            projectName: normalizeBlockText(payload.projectName),
            executorTarget: normalizeBlockText(payload.executorTarget),
            sections: parsedSections,
            directorPromptTemplate: {
                context: normalizeList(promptTemplate.context as string[]),
                objective: normalizeBlockText(promptTemplate.objective as string),
                rules: normalizeList(promptTemplate.rules as string[]),
                delivery: normalizeList(promptTemplate.delivery as string[]),
                adaptationNotes: normalizeList(promptTemplate.adaptationNotes as string[]),
            },
        };
    }

    return {
        routeMode: "executor",
        documentTitle: normalizeBlockText(payload.documentTitle),
        documentMode: payload.documentMode,
        projectName: normalizeBlockText(payload.projectName),
        executorTarget: normalizeBlockText(payload.executorTarget),
        sections: parsedSections,
    };
}

function renderBulletList(values: string[]): string {
    return values.map((value) => `- ${value}`).join("\n");
}

function buildProtocolMarkdown(routeMode: OutputRouteMode, extractionMode: ExtractionMode): string {
    const blocks: string[] = [];

    // §0
    blocks.push(
        "## PROTOCOLO OPERACIONAL TRANSVERSAL — ELITE v2",
        "",
        "### §0 — FILOSOFIA UNIFICADA (STRICT GLOBAL ENFORCEMENT)",
        "**ZERO-VERBOSITY RULE**:\n- Toda saída deve conter EXCLUSIVAMENTE conteúdo técnico de alta densidade.\n- Nenhuma frase introdutória, de transição, de encerramento ou de cortesia é tolerada.\n- Se a informação já está implícita no contexto, NÃO repita.",
        "**TOKEN ECONOMY RULE**:\n- Cada token consumido deve carregar valor técnico mensurável.\n- Priorizar notação compacta: bullet-points, key-value, diffs, blocos de código.\n- Eliminar artigos, preposições e estruturas frasais quando uma lista ou tabela comunica o mesmo."
    );

    // §1
    blocks.push(
        "### §1 — PROIBIÇÕES GLOBAIS (HARD-BLOCKED)",
        "As seguintes saídas são BLOQUEADAS em QUALQUER modo. Violação = falha de protocolo.",
        "1. Termos de cortesia ou rapport: 'Aqui está', 'Espero que ajude', 'Com certeza', 'Claro!', 'Vamos lá'.\n2. Redundância com o contexto fornecido: Repetir o que o usuário já disse ou o que consta na Source of Truth.\n3. Explicações de conceitos básicos: Definir o que é REST, o que é TypeScript, etc.\n4. Meta-comentários sobre a própria resposta: 'Abaixo segue...', 'Vou explicar...'.\n5. Respostas genéricas sem adaptação ao projeto.\n6. Inventar arquitetura/contratos/regras sem evidência textual."
    );

    // §2 — ESPECIFICAÇÃO POR MODO
    if (routeMode === "director") {
        blocks.push(
            "### §2 — ESPECIFICAÇÃO DE MODO: DIRETOR",
            "**IDENTIDADE**: Você é o DIRETOR TÉCNICO DE EXECUÇÃO. Você NÃO é a IA executora final.",
            "**FUNÇÃO OBRIGATÓRIA**:\n- Ler este documento como Source of Truth\n- Assimilar o projeto\n- Aguardar a solicitação futura do usuário\n- Converter a solicitação em um PROMPT DE EXECUÇÃO imperativo e mapeado\n- Entregar esse prompt para uma IA executora/agêntica",
            "**SAÍDA OBRIGATÓRIA**: Prompt estruturado no formato abaixo, sem texto fora do bloco:\n\n```text\n## Instruções\nCONTEXTO:\n- [referências diretas ao projeto, arquivos, contratos afetados]\n\nOBJETIVO:\n[verbo imperativo] + [alvo técnico preciso]\n\nREGRAS:\n- [restrições técnicas derivadas da Source of Truth]\n\nENTREGA:\n- [artefatos esperados: arquivos, diffs, comandos]\n\nADAPTAÇÕES AO PROJETO:\n- [particularidades do projeto que o executor DEVE respeitar]\n```"
        );
    } else {
        blocks.push(
            "### §2 — ESPECIFICAÇÃO DE MODO: EXECUTOR",
            "**IDENTIDADE**: Você é o SENIOR_ENGINEERING_EXECUTOR. Você É a IA executora final.",
            "**FUNÇÃO OBRIGATÓRIA**:\n- Ler este documento como contexto técnico de execução.\n- Executar diretamente a alteração solicitada no código existente.\n- Responder com implementação final pronta para uso.",
            "**SAÍDA OBRIGATÓRIA**: Código completo, diffs ou arquivos completos. ZERO explicações narrativas.\n**SAÍDAS PROIBIDAS**: Prompt para outra IA, orquestração intermediária, explicações conceituais."
        );
    }

    // Modes
    if (extractionMode === "blueprint") {
        blocks.push(
            "### MODO BLUEPRINT",
            "- O contexto contém majoritariamente assinaturas, interfaces e contratos (Blueprints).",
            "- Não tente inferir implementações internas profundas que não estão documentadas.",
            "- Foque na integração e na conformidade com as interfaces expostas."
        );
    } else if (extractionMode === "sniper") {
        blocks.push(
            "### MODO SNIPER",
            "- O contexto é um RECORTE PARCIAL e cirúrgico de arquivos específicos.",
            "- Respeite os limites do recorte; não assuma a existência de arquivos fora desta lista.",
            "- Se precisar de algo fora do recorte, declare como LACUNA DE CONTEXTO."
        );
    }

    // §3
    const section3Body = extractionMode === "full"
        ? "Baseie sua resposta no projeto completo fornecido nesta Source of Truth."
        : "Em recorte parcial/blueprint: restringir ao escopo visível e declarar explicitamente o que não está disponível.";
    blocks.push(`### §3 — REGRA DE CONTEXTO INSUFICIENTE\n${section3Body}`);

    // §4
    blocks.push(
        "### §4 — MANUTENÇÃO DE INTEGRIDADE",
        "- Preservar 100% da estrutura de arquivos e código-fonte que constam neste documento.",
        "- Qualquer alteração deve referenciar o arquivo e a linha/contrato afetado.",
        "- Contratos, identificadores e comportamento existente são INTOCÁVEIS salvo instrução explícita."
    );

    return formatMarkdownFragment(blocks.join("\n\n")).trimEnd();
}

function buildDirectorPromptTemplateMarkdown(template: StructuredDirectorPromptTemplate): string {
    return formatMarkdownFragment(
        [
            "```text",
            "## Instruções",
            "CONTEXTO:",
            renderBulletList(template.context),
            "",
            "OBJETIVO:",
            template.objective,
            "",
            "REGRAS:",
            renderBulletList(template.rules),
            "",
            "ENTREGA:",
            renderBulletList(template.delivery),
            "",
            "ADAPTAÇÕES AO PROJETO:",
            renderBulletList(template.adaptationNotes),
            "```",
        ].join("\n")
    ).trimEnd();
}

function buildStructuredMarkdownDocument(document: StructuredOutputDocument, technicalBundleDump: string): string {
    const analyzedScopeTitle =
        document.documentMode === "manual"
            ? "ESCOPO VISÍVEL E LIMITES DO RECORTE"
            : "ESCOPO ANALISADO E LIMITES";

    const protocolMarkdown = buildProtocolMarkdown(document.routeMode, (document as any).extractionMode || "full");

    const operationalHeading =
        document.routeMode === "director"
            ? "## DIRETRIZES OPERACIONAIS PARA O DIRETOR"
            : "## DIRETRIZES OPERACIONAIS PARA O EXECUTOR";

    const formattedTechnicalBundleDump = formatMarkdownFragment(technicalBundleDump).trimEnd();

    const blocks: string[] = [
        `# ${document.documentTitle}`,
        "",
        `> Projeto: ${document.projectName}`,
        `> Executor alvo: ${document.executorTarget}`,
        `> Modo do documento: ${document.documentMode === "manual" ? "recorte parcial" : "projeto completo"}.`,
        "",
        protocolMarkdown,
        "",
        "## FINALIDADE DO DOCUMENTO",
        document.sections.documentPurpose,
        "",
        "## RESUMO EXECUTIVO",
        document.sections.executiveSummary,
        "",
        `## ${analyzedScopeTitle}`,
        document.sections.analyzedScope,
        "",
        "## STACK, DEPENDÊNCIAS E TECNOLOGIAS OBSERVADAS",
        document.sections.stackAndDependencies,
        "",
        "## ARQUITETURA E ORGANIZAÇÃO",
        document.sections.architectureAndOrganization,
        "",
        "## CONTRATOS, ENTIDADES, INTERFACES E FLUXOS",
        document.sections.contractsEntitiesAndFlows,
        "",
        "## REGRAS DE DESIGN E PADRÕES OBSERVADOS",
        document.sections.designRulesAndObservedPatterns,
        "",
        "## RISCOS DE REGRESSÃO E CUIDADOS OPERACIONAIS",
        document.sections.regressionRisksAndOperationalCare,
        "",
        "## LACUNAS DE CONTEXTO",
        document.sections.contextGaps,
        "",
        operationalHeading,
        document.sections.operationalInstructions,
    ];

    if (document.routeMode === "director") {
        blocks.push(
            "",
            "## TEMPLATE DE PROMPT OTIMIZADO PARA O DIRETOR",
            "",
            buildDirectorPromptTemplateMarkdown(document.directorPromptTemplate)
        );
    }

    blocks.push(
        "",
        "---",
        "",
        "## ESTRUTURA E CÓDIGO",
        "",
        formattedTechnicalBundleDump
    );

    return formatMarkdownFragment(blocks.join("\n")).trimEnd() + "\n";
}

function buildDirectorStructuredSystemPrompt(mode: DocumentMode, executorTarget: string): string {
    const scopeInstruction =
        mode === "manual"
            ? [
                  "O bundle representa um RECORTE PARCIAL do projeto.",
                  "Mapeie exclusivamente o que estiver visível.",
                  "Não inferir módulos, contratos, arquivos, fluxos ou responsabilidades não presentes.",
                  "Quando faltar contexto, declarar explicitamente que não está visível no recorte.",
              ].join(" ")
            : [
                  "O bundle representa o projeto completo contido no artefato enviado.",
                  "Baseie-se exclusivamente no material fornecido.",
                  "Não invente arquitetura, comportamento ou responsabilidades sem evidência textual.",
              ].join(" ");

    return [
        "Você é um ENGENHEIRO DE SOFTWARE SÊNIOR E ARQUITETO DE IA.",
        `Gere uma Source of Truth técnica destinada ao executor ${executorTarget}, no fluxo VIA DIRETOR.`,
        scopeInstruction,
        "A Source of Truth deve preparar uma IA subsequente para assumir a persona de Diretor.",
        "O Diretor deve assimilar o projeto, aguardar o pedido futuro do usuário e então gerar um prompt otimizado para um agente executor com capacidades agênticas.",
        "Na seção directorPromptTemplate, o valor principal é a ESTRUTURA TÓPICA.",
        "Preserve obrigatoriamente os tópicos CONTEXTO, OBJETIVO, REGRAS, ENTREGA e ADAPTAÇÕES AO PROJETO.",
        "RETORNE EXCLUSIVAMENTE JSON VÁLIDO.",
        "NÃO use markdown.",
        "NÃO use comentários.",
        "NÃO use crases.",
        "NÃO inclua texto antes ou depois do JSON.",
        "Use EXATAMENTE este schema:",
        JSON.stringify(
            {
                routeMode: "director",
                documentTitle: "string",
                documentMode: mode,
                projectName: "string",
                executorTarget,
                sections: {
                    documentPurpose: "string",
                    executiveSummary: "string",
                    analyzedScope: "string",
                    stackAndDependencies: "string",
                    architectureAndOrganization: "string",
                    contractsEntitiesAndFlows: "string",
                    designRulesAndObservedPatterns: "string",
                    regressionRisksAndOperationalCare: "string",
                    contextGaps: "string",
                    operationalInstructions: "string",
                },
                directorPromptTemplate: {
                    context: ["string"],
                    objective: "string",
                    rules: ["string"],
                    delivery: ["string"],
                    adaptationNotes: ["string"],
                },
            },
            null,
            2
        ),
    ].join("\n\n");
}

function buildExecutorStructuredSystemPrompt(mode: DocumentMode, executorTarget: string): string {
    const scopeInstruction =
        mode === "manual"
            ? [
                  "O bundle representa um RECORTE PARCIAL do projeto.",
                  "Mapeie exclusivamente o que estiver visível.",
                  "Não inferir módulos, contratos, arquivos, fluxos ou responsabilidades não presentes.",
                  "Quando faltar contexto, declarar explicitamente que não está visível no recorte.",
              ].join(" ")
            : [
                  "O bundle representa o projeto completo contido no artefato enviado.",
                  "Baseie-se exclusivamente no material fornecido.",
                  "Não invente arquitetura, comportamento ou responsabilidades sem evidência textual.",
              ].join(" ");

    return [
        "Você é um ENGENHEIRO DE SOFTWARE SÊNIOR E ARQUITETO DE IA.",
        `Gere um CONTEXTO TÉCNICO DE EXECUÇÃO destinado diretamente ao executor ${executorTarget}, no fluxo DIRETO PARA O EXECUTOR.`,
        scopeInstruction,
        "O documento deve preparar a IA subsequente para operar diretamente como SENIOR_ENGINEERING_EXECUTOR.",
        "O objetivo não é criar Diretor nem prompt intermediário.",
        "O documento deve permitir execução direta de alterações futuras no código.",
        "RETORNE EXCLUSIVAMENTE JSON VÁLIDO.",
        "NÃO use markdown.",
        "NÃO use comentários.",
        "NÃO use crases.",
        "NÃO inclua texto antes ou depois do JSON.",
        "Use EXATAMENTE este schema:",
        JSON.stringify(
            {
                routeMode: "executor",
                documentTitle: "string",
                documentMode: mode,
                projectName: "string",
                executorTarget,
                sections: {
                    documentPurpose: "string",
                    executiveSummary: "string",
                    analyzedScope: "string",
                    stackAndDependencies: "string",
                    architectureAndOrganization: "string",
                    contractsEntitiesAndFlows: "string",
                    designRulesAndObservedPatterns: "string",
                    regressionRisksAndOperationalCare: "string",
                    contextGaps: "string",
                    operationalInstructions: "string",
                },
            },
            null,
            2
        ),
    ].join("\n\n");
}

function buildDirectorStructuredUserPrompt(
    projectName: string,
    executorTarget: string,
    mode: DocumentMode,
    technicalBundleDump: string
): string {
    return [
        `PROJECT_NAME: ${projectName}`,
        `EXECUTOR_TARGET: ${executorTarget}`,
        `DOCUMENT_MODE: ${mode}`,
        "",
        "Requisitos obrigatórios:",
        "- O fluxo é VIA DIRETOR.",
        "- A seção directorPromptTemplate deve preservar os tópicos CONTEXTO, OBJETIVO, REGRAS, ENTREGA e ADAPTAÇÕES AO PROJETO.",
        "- O valor principal do template é a sua estrutura tópica, não um texto fixo literal.",
        "- O template deve servir como matriz operacional para o Diretor converter pedidos futuros em prompt de execução.",
        "- O prompt final do Diretor deve ser voltado para um agente executor que cria/edita arquivos, roda comandos, aplica mudanças e valida resultados.",
        "- Preservar contratos, identificadores, comportamento existente e evitar impacto colateral.",
        "- Em modo manual, deixar explícitos os limites do recorte.",
        "- Considere apenas as seções técnicas do bundle. Ignore qualquer cabeçalho instrucional anterior ao conteúdo técnico.",
        "",
        "BUNDLE TÉCNICO:",
        technicalBundleDump,
    ].join("\n");
}

function buildExecutorStructuredUserPrompt(
    projectName: string,
    executorTarget: string,
    mode: DocumentMode,
    technicalBundleDump: string
): string {
    return [
        `PROJECT_NAME: ${projectName}`,
        `EXECUTOR_TARGET: ${executorTarget}`,
        `DOCUMENT_MODE: ${mode}`,
        "",
        "Requisitos obrigatórios:",
        "- O fluxo é DIRETO PARA O EXECUTOR.",
        "- O documento deve preparar a IA subsequente para executar diretamente mudanças futuras no código.",
        "- Não criar Diretor, não criar prompt intermediário e não orientar outro agente.",
        "- Preservar contratos, identificadores, comportamento existente e evitar impacto colateral.",
        "- Em modo manual, deixar explícitos os limites do recorte.",
        "- Considere apenas as seções técnicas do bundle. Ignore qualquer cabeçalho instrucional anterior ao conteúdo técnico.",
        "",
        "BUNDLE TÉCNICO:",
        technicalBundleDump,
    ].join("\n");
}

async function fileExists(filePath: string): Promise<boolean> {
    try {
        await fs.access(filePath);
        return true;
    } catch {
        return false;
    }
}

async function readOptionalCustomSystemPrompt(customSystemPromptFilePath?: string): Promise<string | null> {
    if (!customSystemPromptFilePath?.trim()) {
        return null;
    }

    const absoluteCustomPromptPath = path.resolve(process.cwd(), customSystemPromptFilePath.trim());

    if (!(await fileExists(absoluteCustomPromptPath))) {
        throw new Error(`Arquivo de systemPrompt customizado não encontrado: ${absoluteCustomPromptPath}`);
    }

    const content = normalizeSourceDump(await fs.readFile(absoluteCustomPromptPath, "utf-8"));
    return content || null;
}

function buildCustomUserPrompt(
    projectName: string,
    executorTarget: string,
    mode: DocumentMode,
    technicalBundleDump: string,
    outputRouteMode: OutputRouteMode
): string {
    return [
        `PROJECT_NAME: ${projectName}`,
        `EXECUTOR_TARGET: ${executorTarget}`,
        `DOCUMENT_MODE: ${mode}`,
        `OUTPUT_ROUTE_MODE: ${outputRouteMode}`,
        "",
        "Você está operando em MODO PERSONALIZADO.",
        "Use o bundle técnico abaixo como contexto integral de trabalho.",
        "Ignore qualquer instrução estrutural padrão do modo default e siga exclusivamente o systemPrompt customizado recebido.",
        "",
        "BUNDLE TÉCNICO:",
        technicalBundleDump,
    ].join("\n");
}

async function repairStructuredPayload(
    rawContent: string,
    projectName: string,
    executorTarget: string,
    mode: DocumentMode,
    outputRouteMode: OutputRouteMode,
    primaryProvider: ProviderId
): Promise<StructuredOutputDocument | null> {
    const repairSystemPrompt =
        outputRouteMode === "director"
            ? [
                  "Converta a resposta abaixo para JSON VÁLIDO seguindo EXATAMENTE o schema solicitado.",
                  "Não invente fatos fora do texto de origem.",
                  "Na seção directorPromptTemplate, preserve obrigatoriamente os tópicos CONTEXTO, OBJETIVO, REGRAS, ENTREGA e ADAPTAÇÕES AO PROJETO.",
                  "Não use markdown.",
                  "Não use comentários.",
                  "Não use crases.",
                  "Retorne somente JSON.",
              ].join("\n")
            : [
                  "Converta a resposta abaixo para JSON VÁLIDO seguindo EXATAMENTE o schema solicitado.",
                  "Não invente fatos fora do texto de origem.",
                  "O fluxo é DIRETO PARA O EXECUTOR.",
                  "Não crie Diretor, não crie prompt intermediário e não adicione seções fora do schema.",
                  "Não use markdown.",
                  "Não use comentários.",
                  "Não use crases.",
                  "Retorne somente JSON.",
              ].join("\n");

    const repairSchema =
        outputRouteMode === "director"
            ? {
                  routeMode: "director",
                  documentTitle: "string",
                  documentMode: mode,
                  projectName,
                  executorTarget,
                  sections: {
                      documentPurpose: "string",
                      executiveSummary: "string",
                      analyzedScope: "string",
                      stackAndDependencies: "string",
                      architectureAndOrganization: "string",
                      contractsEntitiesAndFlows: "string",
                      designRulesAndObservedPatterns: "string",
                      regressionRisksAndOperationalCare: "string",
                      contextGaps: "string",
                      operationalInstructions: "string",
                  },
                  directorPromptTemplate: {
                      context: ["string"],
                      objective: "string",
                      rules: ["string"],
                      delivery: ["string"],
                      adaptationNotes: ["string"],
                  },
              }
            : {
                  routeMode: "executor",
                  documentTitle: "string",
                  documentMode: mode,
                  projectName,
                  executorTarget,
                  sections: {
                      documentPurpose: "string",
                      executiveSummary: "string",
                      analyzedScope: "string",
                      stackAndDependencies: "string",
                      architectureAndOrganization: "string",
                      contractsEntitiesAndFlows: "string",
                      designRulesAndObservedPatterns: "string",
                      regressionRisksAndOperationalCare: "string",
                      contextGaps: "string",
                      operationalInstructions: "string",
                  },
              };

    const repairUserPrompt = [
        `PROJECT_NAME: ${projectName}`,
        `EXECUTOR_TARGET: ${executorTarget}`,
        `DOCUMENT_MODE: ${mode}`,
        `OUTPUT_ROUTE_MODE: ${outputRouteMode}`,
        "",
        "Schema obrigatório:",
        JSON.stringify(repairSchema, null, 2),
        "",
        "Conteúdo bruto a reparar:",
        rawContent,
    ].join("\n");

    const repaired = await generateContextDocument(
        {
            systemContent: repairSystemPrompt,
            userPrompt: repairUserPrompt,
            temperature: 0,
            maxTokens: 8192,
        },
        primaryProvider
    );

    if (!repaired?.content) {
        return null;
    }

    try {
        return parseStructuredDocument(repaired.content, outputRouteMode);
    } catch {
        return null;
    }
}

async function main() {
    const [
        bundlePath,
        projectName,
        executorTarget,
        bundleMode = "full",
        selectedProvider = "groq",
        outputRouteModeArg = "director",
        customSystemPromptFilePath = "",
        extractionModeArg = "full",
    ] = process.argv.slice(2);

    if (!bundlePath || !executorTarget) {
        process.exit(1);
    }

    const absolutePath = path.resolve(process.cwd(), bundlePath);
    const rawBundleDump = normalizeSourceDump(await fs.readFile(absolutePath, "utf-8"));
    const technicalBundleDump = extractTechnicalBundleDump(rawBundleDump);
    const mode: DocumentMode =
        bundleMode === "manual" || path.basename(absolutePath).startsWith("_MANUAL__")
            ? "manual"
            : "full";
    const primaryProvider = normalizePrimaryProvider(selectedProvider);
    const outputRouteMode = normalizeOutputRouteMode(outputRouteModeArg);
    const extractionMode = normalizeExtractionMode(extractionModeArg);
    const customSystemPrompt = await readOptionalCustomSystemPrompt(customSystemPromptFilePath);

    const prefix = outputRouteMode === "director" ? "_diretor_" : "_executor_";
    const outputPath = path.resolve(path.dirname(absolutePath), `${prefix}AI_CONTEXT_${projectName}.md`);
    const resultMetaPath = path.resolve(path.dirname(absolutePath), `_AI_RESULT_${projectName}.json`);

    if (customSystemPrompt) {
        logger.info(`Modo customizado ativo: usando systemPrompt definido pelo HUD (${outputRouteMode}).`);

        const customUserPrompt = buildCustomUserPrompt(
            projectName,
            executorTarget,
            mode,
            technicalBundleDump,
            outputRouteMode
        );

        const customResult = await generateContextDocument(
            {
                systemContent: customSystemPrompt,
                userPrompt: customUserPrompt,
                temperature: 0.1,
                maxTokens: 8192,
            },
            primaryProvider
        );

        if (!customResult?.content) {
            process.exit(1);
        }

        const finalCustomOutput = normalizeCustomMarkdownOutput(customResult.content, projectName);

        await fs.writeFile(outputPath, finalCustomOutput, "utf-8");
        await fs.writeFile(
            resultMetaPath,
            JSON.stringify(
                {
                    provider: customResult.provider,
                    model: customResult.model,
                    outputPath,
                    promptMode: "custom",
                    outputRouteMode,
                    extractionMode,
                },
                null,
                2
            ),
            "utf-8"
        );

        logger.info(`[AI_RESULT] provider=${customResult.provider};model=${customResult.model}`);
        logger.info(`Saída customizada gerada via ${customResult.provider} (${customResult.model}) em: ${prefix}AI_CONTEXT_${projectName}.md`);
        return;
    }

    const systemPrompt =
        outputRouteMode === "director"
            ? buildDirectorStructuredSystemPrompt(mode, executorTarget)
            : buildExecutorStructuredSystemPrompt(mode, executorTarget);

    const userPrompt =
        outputRouteMode === "director"
            ? buildDirectorStructuredUserPrompt(projectName, executorTarget, mode, technicalBundleDump)
            : buildExecutorStructuredUserPrompt(projectName, executorTarget, mode, technicalBundleDump);

    const result = await generateContextDocument(
        {
            systemContent: systemPrompt,
            userPrompt,
            temperature: 0.1,
            maxTokens: 8192,
        },
        primaryProvider
    );

    if (!result?.content) {
        process.exit(1);
    }

    let structuredDocument: StructuredOutputDocument;

    try {
        structuredDocument = parseStructuredDocument(result.content, outputRouteMode);
    } catch (parseError) {
        logger.warn(
            `Saída fora do schema na primeira tentativa. Iniciando reparo estrutural. Motivo: ${
                parseError instanceof Error ? parseError.message : String(parseError)
            }`
        );

        const repairedDocument = await repairStructuredPayload(
            result.content,
            projectName,
            executorTarget,
            mode,
            outputRouteMode,
            primaryProvider
        );

        if (!repairedDocument) {
            throw new Error("Não foi possível obter uma saída estruturalmente válida após reparo.");
        }

        structuredDocument = repairedDocument;
    }

    (structuredDocument as any).extractionMode = extractionMode;
    const finalMarkdown = buildStructuredMarkdownDocument(structuredDocument, technicalBundleDump);

    await fs.writeFile(outputPath, finalMarkdown, "utf-8");
    await fs.writeFile(
        resultMetaPath,
        JSON.stringify(
            {
                provider: result.provider,
                model: result.model,
                outputPath,
                promptMode: "default",
                outputRouteMode,
                extractionMode,
            },
            null,
            2
        ),
        "utf-8"
    );

    logger.info(`[AI_RESULT] provider=${result.provider};model=${result.model}`);
    logger.info(`Contexto gerado via ${result.provider} (${result.model}) em: ${prefix}AI_CONTEXT_${projectName}.md`);
}

main().catch((err) => {
    logger.error("Falha fatal", err);
    process.exit(1);
});