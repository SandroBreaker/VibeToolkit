## PROTOCOLO OPERACIONAL TRANSVERSAL — ELITE v2

### §0 — FILOSOFIA UNIFICADA (STRICT GLOBAL ENFORCEMENT)
**ZERO-VERBOSITY RULE**:
- Toda saída deve conter EXCLUSIVAMENTE conteúdo técnico de alta densidade.
- Nenhuma frase introdutória, de transição, de encerramento ou de cortesia é tolerada.

**TOKEN ECONOMY RULE**:
- Cada token consumido deve carregar valor técnico mensurável.
- Priorizar notação compacta: bullet-points, key-value, diffs, blocos de código.

### §1 — PROIBIÇÕES GLOBAIS (HARD-BLOCKED)
As seguintes saídas são BLOQUEADAS em QUALQUER modo. Violação = falha de protocolo.
1. Termos de cortesia ou rapport.
2. Redundância com o contexto fornecido.
3. Explicações de conceitos básicos.
4. Meta-comentários sobre a própria resposta.

### §2 — ESPECIFICAÇÃO DE MODO: EXECUTOR
**IDENTIDADE**: Você é o SENIOR_ENGINEERING_EXECUTOR.
**FUNÇÃO OBRIGATÓRIA**: Executar diretamente a alteração solicitada no código existente.

### §3 — REGRA DE CONTEXTO INSUFICIENTE
Baseie sua resposta no projeto completo fornecido.

### §4 — MANUTENÇÃO DE INTEGRIDADE
- Preservar a estrutura de arquivos e código-fonte.
- Contratos e identificadores são INTOCÁVEIS.

## MODO COPIAR TUDO: VibeToolkit

### 1. PROJECT STRUCTURE
```text
.\groq-agent.ts
.\package.json
.\patch_agent.js
.\project-bundler.ps1
.\README.md
.\tsconfig.json
```

### 2. SOURCE FILES

#### File: .\groq-agent.ts
```text
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
```

#### File: .\package.json
```text
{
  "name": "vibetoolkit",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "type": "commonjs",
  "dependencies": {
    "dotenv": "^17.3.1",
    "groq-sdk": "^0.37.0"
  },
  "devDependencies": {
    "@types/node": "^25.3.2",
    "tsx": "^4.21.0",
    "typescript": "^5.9.3"
  }
}
```

#### File: .\patch_agent.js
```text
const fs = require('fs');

const path = 'C:\\dev\\VibeToolkit\\groq-agent.ts';
let code = fs.readFileSync(path, 'utf8');

const registryCode = `
export const Force_Protocol_Flag = true;

export const VibeToolkit_Agentic_Registry = {
    DIRETOR_ESTRATEGICO: {
        role: "DIRETOR TÉCNICO DE EXECUÇÃO",
        alias: ["Director", "Orquestrador", "Technical Director"],
        process: "Decompor intenção em requisitos técnicos e emitir Prompt Estruturado de Execução.",
        expectedOutput: "StructuredDirectorDocument (JSON)",
        constraints: [
            "Nunca escrever código nativo final.",
            "Não atuar como executor.",
            "Não fornecer explicações consultivas soltas.",
            "Saída 100% determinística e estruturada."
        ],
        runtimeRole: "director",
        gateLogic: (payload: any) => payload.routeMode === "director" && !!payload.directorPromptTemplate,
        tone: "Objetivo, diretivo, estratégico.",
        protocolMindset: "Orquestrar o caos em passos determinísticos.",
        blockingRules: [
            "Detecção de respostas conversacionais.",
            "Presença de código final na saída.",
            "Falta de headers estruturais."
        ],
        recoveryRules: "Re-ancorar persona do DIRETOR_ESTRATEGICO e forçar envelopamento estruturado no JSON schema obrigatório."
    },
    EXECUTOR_OPERACIONAL: {
        role: "SENIOR SOFTWARE EXECUTOR",
        alias: ["Executor", "Engenheiro"],
        process: "Consumir o Prompt Estruturado de Execução e gerar template de comando técnico.",
        expectedOutput: "StructuredExecutorDocument (JSON)",
        constraints: [
            "Não questionar ou refazer o plano do Diretor.",
            "Fidelidade absoluta ao contexto.",
            "Codificação estrita e modular sem deriva arquitetural."
        ],
        runtimeRole: "executor",
        gateLogic: (payload: any) => payload.routeMode === "executor" && !!payload.sections,
        tone: "Técnico, contido, preciso.",
        protocolMindset: "Mutação de código sem side-effects.",
        blockingRules: [
            "Detecção de abstrações de negócio irrelevantes.",
            "Tentativa de assumir papel de orquestrador (Director)."
        ],
        recoveryRules: "Re-ancorar persona do EXECUTOR_OPERACIONAL e forçar remoção de ruído orquestral. Saída deve ser apenas o schema de comando."
    },
    SENTINEL_COMMAND: {
        role: "KERNEL DE CONFORMIDADE E GATEKEEPER",
        alias: ["Sentinel", "Firewall Operacional", "Silent Operator"],
        process: "Verificar conformidade de protocolo em runtime, bloquear deriva conversacional, impedir mistura de papéis e forçar format JSON estrito.",
        expectedOutput: "N/A (Atua nas entrelinhas da infraestrutura)",
        constraints: [
            "Zero deriva conversacional.",
            "Nenhuma alteração direta no código alvo.",
            "Forçar Zero-Trust Delegation. Tudo é bloqueado se quebrar o ruleset."
        ],
        runtimeRole: "sentinel",
        gateLogic: () => true,
        tone: "Invisível, estrito, punitivo.",
        protocolMindset: "Zero-Trust Protocol Enforcement.",
        blockingRules: [],
        recoveryRules: "N/A"
    }
};

export class SentinelValidationError extends Error {
    public readonly unformattedContent: string;
    constructor(reason: string, unformattedContent: string) {
        super(reason);
        this.name = "SentinelValidationError";
        this.unformattedContent = unformattedContent;
    }
}
`;

code = code.replace(
    /type StructuredOutputDocument = StructuredDirectorDocument \| StructuredExecutorDocument;/,
    "type StructuredOutputDocument = StructuredDirectorDocument | StructuredExecutorDocument;\n\n" + registryCode
);

const gateKeeperCode = `function parseStructuredDocument(rawContent: string, outputRouteMode: OutputRouteMode): StructuredOutputDocument {
    if (Force_Protocol_Flag) {
        const lowerContent = rawContent.trim().toLowerCase();
        const conversationalTriggers = [
            "aqui está", "aqui esta", "com certeza", "certamente", "claro,", 
            "vou gerar", "segue ", "vamos lá", "entendido"
        ];
        if (conversationalTriggers.some(t => lowerContent.startsWith(t))) {
            throw new SentinelValidationError("Deriva conversacional detectada no início do payload. Expressões de cortesia são bloqueadas.", rawContent);
        }
    }

    const candidate = extractJsonCandidate(rawContent);
    if (!candidate && Force_Protocol_Flag && rawContent.trim().length > 0) {
        throw new SentinelValidationError("Ausência de JSON. O agente respondeu sem o container estrutural esperado. Bloqueando saída puramente textual.", rawContent);
    }
    if (!candidate) {
        throw new Error("A resposta da IA não contém JSON extraível e está fora do schema.");
    }

    let parsed: unknown;
    try {
        parsed = JSON.parse(candidate);
    } catch (error) {
        throw new SentinelValidationError(\`Falha no parse do JSON (Estrutura corrompida). Detalhe nativo: \${error instanceof Error ? error.message : String(error)}\`, rawContent);
    }

    if (typeof parsed !== "object" || parsed === null) {
        throw new SentinelValidationError("A estrutura root do JSON retornado é inválida (Não é um objeto).", rawContent);
    }

    const payload = parsed as Record<string, unknown>;
    const sections = payload.sections as Record<string, unknown> | undefined;

    if (payload.routeMode !== outputRouteMode) {
        throw new SentinelValidationError(\`Mixagem de papéis. Agente atuou como '\${payload.routeMode}' mas a rota exigia '\${outputRouteMode}'.\`, rawContent);
    }

    const registryEntity = outputRouteMode === "director" 
        ? VibeToolkit_Agentic_Registry.DIRETOR_ESTRATEGICO 
        : VibeToolkit_Agentic_Registry.EXECUTOR_OPERACIONAL;
        
    if (!registryEntity.gateLogic(payload)) {
        throw new SentinelValidationError(\`Payload rejeitado na Gate Logic do SENTINEL. O objeto não possui a arquitetura mínima exigida para a persona \${registryEntity.role}.\`, rawContent);
    }

    if (!isNonEmptyString(payload.documentTitle)) throw new SentinelValidationError("Campo obrigatório ausente: documentTitle", rawContent);
    if (payload.documentMode !== "manual" && payload.documentMode !== "full") throw new SentinelValidationError("Campo obrigatório inválido: documentMode", rawContent);
    if (!isNonEmptyString(payload.projectName)) throw new SentinelValidationError("Campo obrigatório ausente: projectName", rawContent);
    if (!isNonEmptyString(payload.executorTarget)) throw new SentinelValidationError("Campo obrigatório ausente: executorTarget", rawContent);
    if (!sections || typeof sections !== "object") throw new SentinelValidationError("Campo obrigatório ausente: sections", rawContent);`;

code = code.replace(
    /function parseStructuredDocument.*?if \(\!sections \|\| typeof sections \!\=\= "object"\) throw new Error\("Campo obrigatório ausente: sections\."\);/s,
    gateKeeperCode
);

const systemHeaderCode = `
function buildSystemHeader(registryEntityName: "DIRETOR_ESTRATEGICO" | "EXECUTOR_OPERACIONAL"): string {
    const entity = VibeToolkit_Agentic_Registry[registryEntityName];
    return [
        \`[SENTINEL COMMAND GATE ACTIVATED]\`,
        \`[FORCE_PROTOCOL_FLAG: \${Force_Protocol_Flag.toString().toUpperCase()}]\`,
        \`[RUNTIME_ROLE: \${entity.role}]\`,
        \`== REGISTRY DE AUTORIDADE ==\`,
        \`IDENTITY: Você opera estritamente como \${entity.alias.join(" / ")}.\`,
        \`MINDSET: \${entity.protocolMindset}\`,
        \`RESPONSIBILITY: \${entity.process}\`,
        \`TONE: \${entity.tone}\`,
        \`\`,
        \`== SENTINEL CONSTRAINTS ==\`,
        ...entity.constraints.map((c: string) => \`- \${c}\`),
        \`\`,
        \`# WARNING (SENTINEL GATEKEEPER):\`,
        \`Nenhuma saída deste prompt é validada sem passar por rigoroso escrutínio de schema.\`,
        \`A deriva conversacional é HARD-BLOCKED gerando falha crítica no pipeline.\`,
        \`Mantenha a segregação de persona ou a pipeline será abortada e forçará retry sob punição.\`
    ].join("\\n");
}

function buildDirectorStructuredSystemPrompt(mode: DocumentMode, executorTarget: string): string {`;

code = code.replace(
    /function buildDirectorStructuredSystemPrompt\(mode: DocumentMode, executorTarget: string\): string \{/,
    systemHeaderCode
);

code = code.replace(
    /"Você é um ENGENHEIRO DE SOFTWARE SÊNIOR E ARQUITETO DE IA\.",\n\s+`Gere/,
    `buildSystemHeader("DIRETOR_ESTRATEGICO"),\n        "",\n        \`Gere`
);

code = code.replace(
    /"Você é o SENIOR SOFTWARE EXECUTOR\. Sua missão é estruturar um CONTEXTO TÉCNICO DE EXECUÇÃO destinado diretamente ao executor final\.",\n\s+scopeInstruction/,
    `buildSystemHeader("EXECUTOR_OPERACIONAL"),\n        "",\n        scopeInstruction`
);

const recoveryCode = `async function executeSentinelStateRecovery(
    error: SentinelValidationError,
    projectName: string,
    executorTarget: string,
    mode: DocumentMode,
    outputRouteMode: OutputRouteMode,
    primaryProvider: ProviderId
): Promise<StructuredOutputDocument | null> {
    logger.warn(\`[SENTINEL COMMAND] Quebra de protocolo interceptada! Motivo do bloqueio: \${error.message}\`);
    logger.info(\`[SENTINEL COMMAND] Iniciando protocolo de recuperação de estado e reancoragem...\`);

    const registryEntity = outputRouteMode === "director" 
        ? VibeToolkit_Agentic_Registry.DIRETOR_ESTRATEGICO 
        : VibeToolkit_Agentic_Registry.EXECUTOR_OPERACIONAL;
        
    const repairSystemPrompt = [
        "[SENTINEL COMMAND OVERRIDE - STATE RECOVERY ACTIVATED]",
        \`ALERTA DE SEGURANÇA OPERACIONAL DETECTADO.\`,
        \`Você violou as constraints nucleares da persona \${registryEntity.role}.\`,
        \`MOTIVO TÉCNICO DO BLOQUEIO: \${error.message}\`,
        \`Ação exigida pelo kernel: \${registryEntity.recoveryRules}\`,
        "",
        "DIRETRIZES IMEDIATAS: AUTOCORREÇÃO:",
        ...registryEntity.blockingRules.map((r: string) => \`- EVITAR: \${r}\`),
        "- Ancore-se de volta ao seu escopo estrito.",
        "- Não converse, não se desculpe e não introduza a resposta.",
        "- Converta a base rejeitada (abaixo) em EXATAMENTE o schema JSON correto, corrigindo os erros aprontados.",
        "Não use markdown ou blocos de código se isso envolver gerar sujeira antes ou depois.",
        "Retorne APENAS o JSON estruturalmente completo."
    ].join("\\n");

    const repairUserPrompt = [
        \`PROJECT_NAME: \${projectName}\`,
        \`EXECUTOR_TARGET: \${executorTarget}\`,
        \`DOCUMENT_MODE: \${mode}\`,
        \`OUTPUT_ROUTE_MODE: \${outputRouteMode}\`,
        "",
        "Conteúdo bruto que gerou falha de protocolo (Para ser reparado):",
        error.unformattedContent,
    ].join("\\n");

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
        return null; // fall off entirely
    }
}`;

code = code.replace(
    /async function repairStructuredPayload.*?return null;\n\s+\}\n\s+\}/s,
    recoveryCode
);

code = code.replace(
    /const repairedDocument = await repairStructuredPayload\(/,
    "const repairedDocument = await executeSentinelStateRecovery(\n            parseError as SentinelValidationError,"
);

// We need to change the try catch in main so it handles SentinelValidationError logic if we bypass normal parse errors.
// Wait, parseError as SentinelValidationError expects parseError to pass Sentinel block. Since parseStructuredDocument now throws SentinelValidationError almost everywhere, any error acts as Sentinel error.

fs.writeFileSync(path, code);
console.log('Patch complete.');
```

#### File: .\project-bundler.ps1
```text
# VIBE AI TOOLKIT - BUNDLER, BLUEPRINT & SELECTIVE
# =================================================================

[CmdletBinding()]
param([string]$Path = ".")

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-Location $Path

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class Win32 {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

$consoleHandle = [Win32]::GetConsoleWindow()
if ($consoleHandle -ne [IntPtr]::Zero) {
    [Win32]::ShowWindow($consoleHandle, 0) | Out-Null
}

$ProjectName = (Get-Item .).Name
$ScriptFullPath = $MyInvocation.MyCommand.Path
$ToolkitDir = Split-Path $ScriptFullPath

$Choice = $null
$ExecutorTarget = $null
$FilesToProcess = @()
$SendToAI = $false
$AIProvider = $null

$ThemeBg       = [System.Drawing.ColorTranslator]::FromHtml("#0F0F0C")
$ThemePanel    = [System.Drawing.ColorTranslator]::FromHtml("#161613")
$ThemePanelAlt = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1A")
$ThemeBorder   = [System.Drawing.ColorTranslator]::FromHtml("#2A2A26")
$ThemeText     = [System.Drawing.ColorTranslator]::FromHtml("#F3F6F7")
$ThemeMuted    = [System.Drawing.ColorTranslator]::FromHtml("#A6ADB3")
$ThemeCyan     = [System.Drawing.ColorTranslator]::FromHtml("#00E5FF")
$ThemePink     = [System.Drawing.ColorTranslator]::FromHtml("#FF1493")
$ThemeSuccess  = [System.Drawing.ColorTranslator]::FromHtml("#22C55E")
$ThemeWarn     = [System.Drawing.ColorTranslator]::FromHtml("#F59E0B")

$AllowedExtensions = @(
    ".tsx", ".ts", ".js", ".jsx", ".css", ".html", ".json", ".prisma", ".sql", ".yaml", ".md",
    ".py", ".java", ".cs", ".c", ".cpp", ".h", ".hpp", ".go", ".rb", ".php", ".rs", ".swift",
    ".kt", ".scala", ".dart", ".r", ".sh", ".bat", ".ps1", ".csv"
)
$SignatureExtensions = @(
    ".tsx", ".ts", ".js", ".jsx", ".prisma",
    ".py", ".java", ".cs", ".go", ".rb", ".php", ".rs", ".swift", ".kt", ".scala", ".dart"
)
$IgnoredDirs = @(
    "node_modules", ".git", "dist", "build", ".next", ".cache", "out",
    "android", "ios", "coverage", ".venv", "venv", "env", "__pycache__",
    ".pytest_cache", ".tox", "bin", "obj", "target", "vendor"
)
$IgnoredFiles = @(
    "package-lock.json", "pnpm-lock.yaml", "yarn.lock",
    ".DS_Store", "metadata.json", ".gitignore",
    "google-services.json", "capacitor.config.json",
    "capacitor.plugins.json", "cordova.js", "cordova_plugins.js",
    "poetry.lock", "Pipfile.lock", "Cargo.lock", "go.sum", "composer.lock"
)

$ProviderDefaultModels = @{
    groq      = "llama-3.3-70b-versatile"
    gemini    = "gemini-1.5-pro"
    openai    = "gpt-4o"
    anthropic = "claude-3-5-sonnet-20240620"
}

function Test-IsGeneratedArtifactFileName {
    param([string]$FileName)
    if ([string]::IsNullOrWhiteSpace($FileName)) { return $false }
    return $FileName -match '^_(?:(?:Diretor|Executor)_)?(?:BUNDLER__|BLUEPRINT__|SELECTIVE__|COPIAR_TUDO__|INTELIGENTE__|MANUAL__|AI_CONTEXT_|AI_RESULT_)'
}

function Get-RelevantFiles {
    param([string]$CurrentPath)
    try {
        $Items = Get-ChildItem -Path $CurrentPath -ErrorAction Stop
        foreach ($Item in $Items) {
            if ($Item.PSIsContainer) {
                if ($Item.Name -notin $IgnoredDirs) { Get-RelevantFiles -CurrentPath $Item.FullName }
            } else {
                $IsTarget = ($Item.Extension -in $AllowedExtensions) -and
                    ($Item.Name -notin $IgnoredFiles) -and
                    ($Item.BaseName -notmatch '-[a-f0-9]{8,}$') -and
                    (-not (Test-IsGeneratedArtifactFileName -FileName $Item.Name))
                if ($IsTarget) { $Item }
            }
        }
    } catch {}
}

$FoundFiles = @(Get-RelevantFiles -CurrentPath (Get-Location).Path)

if ($FoundFiles.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show(
        "Nenhum arquivo válido encontrado no diretório atual.",
        "VibeToolkit", [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    exit
}

# ── UI resolve helpers ────────────────────────────────────────────
function Resolve-ChoiceFromUI {
    param($RbFull, $RbArchitect, $RbSniper)
    if ($RbFull.Checked)     { return '1' }
    if ($RbArchitect.Checked){ return '2' }
    if ($RbSniper.Checked)   { return '3' }
    return $null
}

function Resolve-AIProviderFromUI {
    param($RbGroq, $RbGemini, $RbOpenAI, $RbAnthropic)
    if ($RbGroq.Checked)      { return "groq" }
    if ($RbGemini.Checked)    { return "gemini" }
    if ($RbOpenAI.Checked)    { return "openai" }
    if ($RbAnthropic.Checked) { return "anthropic" }
    return $null
}

function Resolve-AIPromptModeFromUI {
    param($RbDefault, $RbCustom)
    if ($RbCustom.Checked) { return "custom" }
    return "default"
}

function Resolve-AIFlowModeFromUI {
    param($RbDirector, $RbExecutor)
    if ($RbExecutor.Checked) { return "executor" }
    return "director"
}

function Get-OutputRouteModeLabel {
    param([string]$RouteMode)
    if ($RouteMode -eq "executor") { return "Executor" }
    return "Diretor"
}

function Add-OutputRoutePrefixToFileName {
    param([string]$FileName, [string]$RouteMode)
    if ([string]::IsNullOrWhiteSpace($FileName)) { throw "Nome de arquivo inválido." }
    $n = $FileName.Trim()
    $p = "_$(Get-OutputRouteModeLabel -RouteMode $RouteMode)"
    if ($n -eq $p -or $n.StartsWith("${p}_")) { return $n }
    if ($n.StartsWith("_")) { return "${p}${n}" }
    return "${p}_${n}"
}

function Get-AIContextOutputFileName {
    param([string]$ProjectNameValue, [string]$RouteMode)
    return Add-OutputRoutePrefixToFileName -FileName "_AI_CONTEXT_${ProjectNameValue}.md" -RouteMode $RouteMode
}

function Get-AIResultOutputFileName {
    param([string]$ProjectNameValue, [string]$RouteMode)
    return Add-OutputRoutePrefixToFileName -FileName "_AI_RESULT_${ProjectNameValue}.json" -RouteMode $RouteMode
}

function Get-ProviderDisplayInfo {
    param([string]$Provider)
    $envModels = @{
        groq = $env:GROQ_MODEL; gemini = $env:GEMINI_MODEL
        openai = $env:OPENAI_MODEL; anthropic = $env:ANTHROPIC_MODEL
    }
    $model = if ($envModels[$Provider]) { $envModels[$Provider] } else { $ProviderDefaultModels[$Provider] }
    $names = @{ groq = "Groq"; gemini = "Gemini"; openai = "OpenAI"; anthropic = "Anthropic" }
    return "$($names[$Provider])  ·  $model"
}

function Get-CodeFenceLanguageFromExtension {
    param([string]$Extension)
    $Ext = ($Extension | ForEach-Object { $_ })
    if ([string]::IsNullOrWhiteSpace($Ext)) { return "text" }
    $Ext = $Ext.TrimStart('.').ToLowerInvariant()
    if ($Ext -match '^(tsx?)$')       { return 'typescript' }
    if ($Ext -match '^(jsx?)$')       { return 'javascript' }
    if ($Ext -match '^(py)$')         { return 'python' }
    if ($Ext -match '^(cs)$')         { return 'csharp' }
    if ($Ext -match '^(rb)$')         { return 'ruby' }
    if ($Ext -match '^(rs)$')         { return 'rust' }
    if ($Ext -match '^(kt)$')         { return 'kotlin' }
    if ($Ext -match '^(go)$')         { return 'go' }
    if ($Ext -match '^(java)$')       { return 'java' }
    if ($Ext -match '^(php)$')        { return 'php' }
    if ($Ext -match '^(c|h|cpp|hpp)$'){ return 'cpp' }
    return $Ext
}

function Get-BundlerSignaturesForFile {
    param([System.IO.FileInfo]$File, [ref]$IssueMessage)
    if ($IssueMessage) { $IssueMessage.Value = $null }
    if ($null -eq $File) { return @() }
    $RelPath = Resolve-Path -Path $File.FullName -Relative
    $ContentRaw = Get-Content $File.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $ContentRaw) { return @() }
    try {
        $Lines = @(Get-Content $File.FullName -Encoding UTF8)
        $Signatures = @()
        for ($i = 0; $i -lt $Lines.Count; $i++) {
            $RawLine = $Lines[$i]
            if ($null -eq $RawLine) { continue }
            $Line = $RawLine.Trim()
            if ($Line -match '^(?:export\s+)?(interface|type|enum)\s+[A-Za-z0-9_]+') {
                $Block = "$Line`n"
                if ($Line -notmatch '\}' -and $Line -notmatch ' = ' -and $Line -notmatch ';$') {
                    $j = $i + 1
                    while ($j -lt $Lines.Count -and $Lines[$j] -notmatch '^\}') {
                        $Block += "$($Lines[$j])`n"; $j++
                    }
                    if ($j -lt $Lines.Count) { $Block += "$($Lines[$j])`n" }
                    $i = $j
                }
                $Signatures += $Block
            } elseif ($Line -match '^(?:export\s+)?(?:const|function|class)\s+[A-Za-z0-9_]+') {
                $Signatures += "$(($Line -replace '\{.*$','') -replace '\s*=>.*$','')`n"
            } elseif ($Line -match '^(?:public|protected|private|internal)\s+(?:class|interface|record|struct|enum)\s+[A-Za-z0-9_]+') {
                $Signatures += "$($Line -replace '\{.*$','')`n"
            } elseif ($Line -match '^(?:def|class)\s+[A-Za-z0-9_]+') {
                $Signatures += "$($Line -replace ':$','')`n"
            } elseif ($Line -match '^func\s+[A-Za-z0-9_]+') {
                $Signatures += "$($Line -replace '\{.*$','')`n"
            } elseif ($Line -match '^(?:pub\s+)?(?:fn|struct|enum|trait)\s+[A-Za-z0-9_]+') {
                $Signatures += "$($Line -replace '\{.*$','')`n"
            }
        }
        return @($Signatures)
    } catch {
        if ($IssueMessage) { $IssueMessage.Value = "[$RelPath] $($_.Exception.Message)" }
        return @()
    }
}

function New-BundlerContractsBlock {
    param([System.IO.FileInfo[]]$Files, [ref]$IssueCollector,
          [string]$StructureHeading, [string]$ContractsHeading, [switch]$LogExtraction)
    if ($null -eq $Files -or $Files.Count -eq 0) { return "" }
    $Block = "${StructureHeading}`n" + '```text' + "`n"
    foreach ($File in $Files) { $Block += (Resolve-Path -Path $File.FullName -Relative) + "`n" }
    $Block += '```' + "`n`n"
    $Block += "${ContractsHeading}`n"
    foreach ($File in $Files) {
        if ($SignatureExtensions -notcontains $File.Extension) { continue }
        $RelPath = Resolve-Path -Path $File.FullName -Relative
        if ($LogExtraction) { Write-UILog -Message "Extraindo assinaturas de $RelPath" }
        $IssueMessage = $null
        $Signatures = @(Get-BundlerSignaturesForFile -File $File -IssueMessage ([ref]$IssueMessage))
        if ($IssueMessage) {
            if ($IssueCollector) { $IssueCollector.Value += $IssueMessage }
            continue
        }
        if ($Signatures.Count -le 0) { continue }
        $FenceLanguage = Get-CodeFenceLanguageFromExtension -Extension $File.Extension
        $Block += "#### File: $RelPath`n" + '```' + $FenceLanguage + "`n"
        $Block += ($Signatures -join '')
        $Block += '```' + "`n`n"
    }
    return $Block
}

# ══════════════════════════════════════════════════════════════════
# FORM
# ══════════════════════════════════════════════════════════════════
$form = New-Object System.Windows.Forms.Form
$form.Text = "Vibe AI Toolkit"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(860, 820)
$form.MinimumSize = New-Object System.Drawing.Size(860, 700)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.BackColor = $ThemeBg
$form.ForeColor = $ThemeText
$form.AutoScroll = $true
$form.AutoScrollMinSize = New-Object System.Drawing.Size(0, 0)

$script:PreferredNormalSize = New-Object System.Drawing.Size(860, 820)
$script:PreferredSniperSize = New-Object System.Drawing.Size(860, 1060)
$script:IsDragging = $false
$script:DragCursor = [System.Drawing.Point]::Empty
$script:DragForm = [System.Drawing.Point]::Empty
$script:IsResizing = $false
$script:ResizeCursor = [System.Drawing.Point]::Empty
$script:ResizeBounds = [System.Drawing.Rectangle]::Empty
$script:IsFullscreen = $false
$script:LogExpanded = $false
$script:StoredNormalBounds = New-Object System.Drawing.Rectangle(0, 0, $script:PreferredNormalSize.Width, $script:PreferredNormalSize.Height)
$script:SuppressVisibleClamp = $false
$script:LogEntries = [System.Collections.Generic.List[hashtable]]::new()
$script:ExtChipButtons = @{}
$script:SuppressTreeCheck = $false
$script:TreeNodeMap = @{}

function Get-WorkingAreaForBounds { param([System.Drawing.Rectangle]$Bounds)
    return [System.Windows.Forms.Screen]::FromRectangle($Bounds).WorkingArea }

function Clamp-RectangleToWorkingArea {
    param([System.Drawing.Rectangle]$Bounds)
    $wa = Get-WorkingAreaForBounds -Bounds $Bounds
    $minW = [Math]::Max($form.MinimumSize.Width, 640)
    $minH = [Math]::Max($form.MinimumSize.Height, 520)
    $w = [Math]::Min([Math]::Max($Bounds.Width, $minW), $wa.Width)
    $h = [Math]::Min([Math]::Max($Bounds.Height, $minH), $wa.Height)
    $x = [Math]::Min([Math]::Max($Bounds.X, $wa.Left), $wa.Right - $w)
    $y = [Math]::Min([Math]::Max($Bounds.Y, $wa.Top), $wa.Bottom - $h)
    return New-Object System.Drawing.Rectangle($x, $y, $w, $h)
}

function Set-FormBoundsSafe {
    param([int]$Width, [int]$Height, [bool]$PreserveLocation = $true)
    $loc = if ($PreserveLocation) { $form.Location } else { [System.Drawing.Point]::Empty }
    $safe = Clamp-RectangleToWorkingArea -Bounds (New-Object System.Drawing.Rectangle($loc.X, $loc.Y, $Width, $Height))
    $form.SetBounds($safe.X, $safe.Y, $safe.Width, $safe.Height)
}

function Ensure-FormVisible {
    $safe = Clamp-RectangleToWorkingArea -Bounds (New-Object System.Drawing.Rectangle($form.Left, $form.Top, $form.Width, $form.Height))
    if ($safe.X -ne $form.Left -or $safe.Y -ne $form.Top -or $safe.Width -ne $form.Width -or $safe.Height -ne $form.Height) {
        $form.SetBounds($safe.X, $safe.Y, $safe.Width, $safe.Height)
    }
}

function Get-CurrentScreenWorkingArea {
    $ref = if ($form.Bounds.Width -gt 0) { $form.Bounds } else { New-Object System.Drawing.Rectangle(0,0,$script:PreferredNormalSize.Width,$script:PreferredNormalSize.Height) }
    return [System.Windows.Forms.Screen]::FromRectangle($ref).WorkingArea
}

function Get-CurrentScreenBounds {
    $ref = if ($form.Bounds.Width -gt 0) { $form.Bounds } else { New-Object System.Drawing.Rectangle(0,0,$script:PreferredNormalSize.Width,$script:PreferredNormalSize.Height) }
    return [System.Windows.Forms.Screen]::FromRectangle($ref).Bounds
}

function Set-HudFullscreen {
    if (-not $script:IsFullscreen) { $script:StoredNormalBounds = $form.Bounds }
    $sb = Get-CurrentScreenBounds
    $script:SuppressVisibleClamp = $true
    $form.SetBounds($sb.X, $sb.Y, $sb.Width, $sb.Height)
    $script:SuppressVisibleClamp = $false
    $script:IsFullscreen = $true
    if ($null -ne $resizeGrip) { $resizeGrip.Visible = $false }
    if ($null -ne $maximizeButton) { $maximizeButton.Text = "❐" }
    Update-ResponsiveLayout
}

function Set-HudNormalSize {
    $target = $script:StoredNormalBounds
    if ($target.Width -lt $form.MinimumSize.Width -or $target.Height -lt $form.MinimumSize.Height) {
        $target = New-Object System.Drawing.Rectangle($form.Left, $form.Top, $script:PreferredNormalSize.Width, $script:PreferredNormalSize.Height)
    }
    $safe = Clamp-RectangleToWorkingArea -Bounds $target
    $script:SuppressVisibleClamp = $true
    $form.SetBounds($safe.X, $safe.Y, $safe.Width, $safe.Height)
    $script:SuppressVisibleClamp = $false
    $script:IsFullscreen = $false
    if ($null -ne $resizeGrip) { $resizeGrip.Visible = $true }
    if ($null -ne $maximizeButton) { $maximizeButton.Text = "□" }
    Update-ResponsiveLayout
    Ensure-FormVisible
}

function Toggle-HudFullscreen {
    if ($script:IsFullscreen) { Set-HudNormalSize } else { Set-HudFullscreen }
}

# ── Drag & resize handlers ────────────────────────────────────────
$DragMouseDown = {
    if ($script:IsFullscreen) { return }
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left -and -not $script:IsResizing) {
        $script:IsDragging = $true
        $script:DragCursor = [System.Windows.Forms.Cursor]::Position
        $script:DragForm = $form.Location
    }
}
$DragMouseMove = {
    if ($script:IsDragging) {
        $cur = [System.Windows.Forms.Cursor]::Position
        $newX = $script:DragForm.X + $cur.X - $script:DragCursor.X
        $newY = $script:DragForm.Y + $cur.Y - $script:DragCursor.Y
        $safe = Clamp-RectangleToWorkingArea -Bounds (New-Object System.Drawing.Rectangle($newX, $newY, $form.Width, $form.Height))
        $form.Location = New-Object System.Drawing.Point($safe.X, $safe.Y)
    }
}
$DragMouseUp = { $script:IsDragging = $false }

# ── Title bar ─────────────────────────────────────────────────────
$titleBar = New-Object System.Windows.Forms.Panel
$titleBar.Size = New-Object System.Drawing.Size(860, 44)
$titleBar.Location = New-Object System.Drawing.Point(0, 0)
$titleBar.BackColor = $ThemePanelAlt
$titleBar.Cursor = [System.Windows.Forms.Cursors]::SizeAll
$titleBar.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($titleBar)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "VIBE AI TOOLKIT"
$titleLabel.ForeColor = $ThemeText
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(18, 11)
$titleBar.Controls.Add($titleLabel)

$subTitleLabel = New-Object System.Windows.Forms.Label
$subTitleLabel.Text = "HUD EXECUTION CONSOLE"
$subTitleLabel.ForeColor = $ThemeCyan
$subTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$subTitleLabel.AutoSize = $true
$subTitleLabel.Location = New-Object System.Drawing.Point(210, 15)
$titleBar.Controls.Add($subTitleLabel)

$projectLabel = New-Object System.Windows.Forms.Label
$projectLabel.Text = "Projeto: $ProjectName"
$projectLabel.ForeColor = $ThemeMuted
$projectLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$projectLabel.AutoSize = $true
$projectLabel.Location = New-Object System.Drawing.Point(18, 54)
$projectLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($projectLabel)

$closeButton = New-Object System.Windows.Forms.Label
$closeButton.Text = "✕"
$closeButton.ForeColor = $ThemeText
$closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$closeButton.AutoSize = $true
$closeButton.Location = New-Object System.Drawing.Point(826, 9)
$closeButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$closeButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$closeButton.Add_MouseEnter({ $closeButton.ForeColor = $ThemePink })
$closeButton.Add_MouseLeave({ $closeButton.ForeColor = $ThemeText })
$closeButton.Add_Click({ $form.Close() })
$titleBar.Controls.Add($closeButton)

$maximizeButton = New-Object System.Windows.Forms.Label
$maximizeButton.Text = "□"
$maximizeButton.ForeColor = $ThemeText
$maximizeButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$maximizeButton.AutoSize = $true
$maximizeButton.Location = New-Object System.Drawing.Point(792, 11)
$maximizeButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$maximizeButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$maximizeButton.Add_MouseEnter({ $maximizeButton.ForeColor = $ThemeCyan })
$maximizeButton.Add_MouseLeave({ $maximizeButton.ForeColor = $ThemeText })
$maximizeButton.Add_Click({ Toggle-HudFullscreen })
$titleBar.Controls.Add($maximizeButton)

$resizeGrip = New-Object System.Windows.Forms.Panel
$resizeGrip.Size = New-Object System.Drawing.Size(18, 18)
$resizeGrip.BackColor = $ThemePanelAlt
$resizeGrip.Cursor = [System.Windows.Forms.Cursors]::SizeNWSE
$resizeGrip.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($resizeGrip)

$ResizeMouseDown = {
    if ($script:IsFullscreen) { return }
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:IsResizing = $true
        $script:ResizeCursor = [System.Windows.Forms.Cursor]::Position
        $script:ResizeBounds = $form.Bounds
    }
}
$ResizeMouseMove = {
    if ($script:IsResizing) {
        $cur = [System.Windows.Forms.Cursor]::Position
        $dX = $cur.X - $script:ResizeCursor.X
        $dY = $cur.Y - $script:ResizeCursor.Y
        $safe = Clamp-RectangleToWorkingArea -Bounds (New-Object System.Drawing.Rectangle(
            $script:ResizeBounds.X, $script:ResizeBounds.Y,
            $script:ResizeBounds.Width + $dX, $script:ResizeBounds.Height + $dY))
        $form.SetBounds($safe.X, $safe.Y, $safe.Width, $safe.Height)
    }
}
$ResizeMouseUp = { $script:IsResizing = $false }

$resizeGrip.Add_MouseDown($ResizeMouseDown)
$resizeGrip.Add_MouseMove($ResizeMouseMove)
$resizeGrip.Add_MouseUp($ResizeMouseUp)
$titleBar.Add_MouseDown($DragMouseDown); $titleBar.Add_MouseMove($DragMouseMove); $titleBar.Add_MouseUp($DragMouseUp)
$titleLabel.Add_MouseDown($DragMouseDown); $titleLabel.Add_MouseMove($DragMouseMove); $titleLabel.Add_MouseUp($DragMouseUp)
$subTitleLabel.Add_MouseDown($DragMouseDown); $subTitleLabel.Add_MouseMove($DragMouseMove); $subTitleLabel.Add_MouseUp($DragMouseUp)
$titleBar.Add_DoubleClick({ Toggle-HudFullscreen })
$titleLabel.Add_DoubleClick({ Toggle-HudFullscreen })
$subTitleLabel.Add_DoubleClick({ Toggle-HudFullscreen })

# ══════════════════════════════════════════════════════════════════
# PANEL: MODO DE EXTRAÇÃO (includes executor inline)
# ══════════════════════════════════════════════════════════════════
$panelMode = New-Object System.Windows.Forms.GroupBox
$panelMode.Text = "Modo de Extração"
$panelMode.ForeColor = $ThemeCyan
$panelMode.BackColor = $ThemePanel
$panelMode.Size = New-Object System.Drawing.Size(395, 192)
$panelMode.Location = New-Object System.Drawing.Point(18, 84)
$panelMode.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelMode.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($panelMode)

$rbFull = New-Object System.Windows.Forms.RadioButton
$rbFull.Text = "Full Vibe — enviar tudo"
$rbFull.ForeColor = $ThemeText; $rbFull.BackColor = $ThemePanel
$rbFull.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbFull.Location = New-Object System.Drawing.Point(18, 34)
$rbFull.Size = New-Object System.Drawing.Size(330, 24)
$rbFull.Checked = $true
$panelMode.Controls.Add($rbFull)

$lblFull = New-Object System.Windows.Forms.Label
$lblFull.Text = "Ideal para análise completa, bugs e contexto integral."
$lblFull.ForeColor = $ThemeMuted; $lblFull.BackColor = $ThemePanel
$lblFull.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblFull.AutoSize = $true
$lblFull.Location = New-Object System.Drawing.Point(38, 58)
$panelMode.Controls.Add($lblFull)

$rbArchitect = New-Object System.Windows.Forms.RadioButton
$rbArchitect.Text = "Architect — blueprint / estrutura"
$rbArchitect.ForeColor = $ThemeText; $rbArchitect.BackColor = $ThemePanel
$rbArchitect.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbArchitect.Location = New-Object System.Drawing.Point(18, 80)
$rbArchitect.Size = New-Object System.Drawing.Size(330, 24)
$panelMode.Controls.Add($rbArchitect)

$lblArchitect = New-Object System.Windows.Forms.Label
$lblArchitect.Text = "Economiza tokens e foca em contratos e assinaturas."
$lblArchitect.ForeColor = $ThemeMuted; $lblArchitect.BackColor = $ThemePanel
$lblArchitect.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblArchitect.AutoSize = $true
$lblArchitect.Location = New-Object System.Drawing.Point(38, 104)
$panelMode.Controls.Add($lblArchitect)

$rbSniper = New-Object System.Windows.Forms.RadioButton
$rbSniper.Text = "Sniper — seleção manual"
$rbSniper.ForeColor = $ThemeText; $rbSniper.BackColor = $ThemePanel
$rbSniper.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbSniper.Location = New-Object System.Drawing.Point(18, 126)
$rbSniper.Size = New-Object System.Drawing.Size(330, 24)
$panelMode.Controls.Add($rbSniper)

# Separator
$lblModeSep = New-Object System.Windows.Forms.Label
$lblModeSep.Text = "EXECUTOR ALVO"
$lblModeSep.ForeColor = $ThemeMuted
$lblModeSep.BackColor = $ThemePanel
$lblModeSep.Font = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Bold)
$lblModeSep.AutoSize = $true
$lblModeSep.Location = New-Object System.Drawing.Point(18, 160)
$panelMode.Controls.Add($lblModeSep)

$cmbExecutorInline = New-Object System.Windows.Forms.ComboBox
$cmbExecutorInline.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmbExecutorInline.BackColor = $ThemePanelAlt
$cmbExecutorInline.ForeColor = $ThemeText
$cmbExecutorInline.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$cmbExecutorInline.Location = New-Object System.Drawing.Point(130, 155)
$cmbExecutorInline.Size = New-Object System.Drawing.Size(220, 26)
[void]$cmbExecutorInline.Items.Add("AI Studio Apps")
[void]$cmbExecutorInline.Items.Add("Antigravity")
$cmbExecutorInline.SelectedIndex = 0
$panelMode.Controls.Add($cmbExecutorInline)

# ══════════════════════════════════════════════════════════════════
# PANEL: IA ORQUESTRADORA (with provider chain visualization)
# ══════════════════════════════════════════════════════════════════
$panelProvider = New-Object System.Windows.Forms.GroupBox
$panelProvider.Text = "IA Orquestradora"
$panelProvider.ForeColor = $ThemeCyan
$panelProvider.BackColor = $ThemePanel
$panelProvider.Size = New-Object System.Drawing.Size(409, 192)
$panelProvider.Location = New-Object System.Drawing.Point(433, 84)
$panelProvider.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelProvider.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($panelProvider)

$providerHint = New-Object System.Windows.Forms.Label
$providerHint.Text = "Provedor primário. Fallback automático se falhar ou atingir limite."
$providerHint.ForeColor = $ThemeMuted; $providerHint.BackColor = $ThemePanel
$providerHint.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$providerHint.AutoSize = $true
$providerHint.Location = New-Object System.Drawing.Point(18, 28)
$panelProvider.Controls.Add($providerHint)

$rbGroq = New-Object System.Windows.Forms.RadioButton
$rbGroq.Text = "Groq"; $rbGroq.ForeColor = $ThemeText; $rbGroq.BackColor = $ThemePanel
$rbGroq.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbGroq.Location = New-Object System.Drawing.Point(18, 56); $rbGroq.Size = New-Object System.Drawing.Size(88, 24)
$rbGroq.Checked = $true
$panelProvider.Controls.Add($rbGroq)

$rbGemini = New-Object System.Windows.Forms.RadioButton
$rbGemini.Text = "Gemini"; $rbGemini.ForeColor = $ThemeText; $rbGemini.BackColor = $ThemePanel
$rbGemini.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbGemini.Location = New-Object System.Drawing.Point(116, 56); $rbGemini.Size = New-Object System.Drawing.Size(88, 24)
$panelProvider.Controls.Add($rbGemini)

$rbOpenAI = New-Object System.Windows.Forms.RadioButton
$rbOpenAI.Text = "OpenAI"; $rbOpenAI.ForeColor = $ThemeText; $rbOpenAI.BackColor = $ThemePanel
$rbOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbOpenAI.Location = New-Object System.Drawing.Point(214, 56); $rbOpenAI.Size = New-Object System.Drawing.Size(88, 24)
$panelProvider.Controls.Add($rbOpenAI)

$rbAnthropic = New-Object System.Windows.Forms.RadioButton
$rbAnthropic.Text = "Anthropic"; $rbAnthropic.ForeColor = $ThemeText; $rbAnthropic.BackColor = $ThemePanel
$rbAnthropic.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbAnthropic.Location = New-Object System.Drawing.Point(312, 56); $rbAnthropic.Size = New-Object System.Drawing.Size(88, 24)
$panelProvider.Controls.Add($rbAnthropic)

# Provider chain progress bar (dots)
$pnlProviderChain = New-Object System.Windows.Forms.Panel
$pnlProviderChain.BackColor = $ThemePanel
$pnlProviderChain.Location = New-Object System.Drawing.Point(18, 90)
$pnlProviderChain.Size = New-Object System.Drawing.Size(373, 24)
$panelProvider.Controls.Add($pnlProviderChain)

function Build-ProviderChainDots {
    param([string]$ActiveProvider)
    $pnlProviderChain.Controls.Clear()
    $providers = @("groq","gemini","openai","anthropic")
    $labels = @("Groq","Gemini","OpenAI","Anthropic")
    $x = 0
    for ($i = 0; $i -lt $providers.Count; $i++) {
        $isActive = $providers[$i] -eq $ActiveProvider
        $dot = New-Object System.Windows.Forms.Label
        $dot.Text = if ($isActive) { "●" } else { "○" }
        $dot.ForeColor = if ($isActive) { $ThemeCyan } else { $ThemeMuted }
        $dot.BackColor = $ThemePanel
        $dot.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $dot.AutoSize = $true
        $dot.Location = New-Object System.Drawing.Point($x, 2)
        $pnlProviderChain.Controls.Add($dot)
        $x += 12

        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $labels[$i]
        $lbl.ForeColor = if ($isActive) { $ThemeCyan } else { $ThemeMuted }
        $lbl.BackColor = $ThemePanel
        $lblFontSize  = if ($isActive) { 9.0 } else { 8.5 }
        $lblFontStyle = if ($isActive) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
        $lbl.Font = New-Object System.Drawing.Font("Segoe UI", $lblFontSize, $lblFontStyle)
        $lbl.AutoSize = $true
        $lbl.Location = New-Object System.Drawing.Point($x, 3)
        $pnlProviderChain.Controls.Add($lbl)
        $x += $lbl.PreferredWidth + 4

        if ($i -lt $providers.Count - 1) {
            $arr = New-Object System.Windows.Forms.Label
            $arr.Text = "→"
            $arr.ForeColor = $ThemeMuted
            $arr.BackColor = $ThemePanel
            $arr.Font = New-Object System.Drawing.Font("Segoe UI", 8)
            $arr.AutoSize = $true
            $arr.Location = New-Object System.Drawing.Point($x, 4)
            $pnlProviderChain.Controls.Add($arr)
            $x += $arr.PreferredWidth + 4
        }
    }
}

Build-ProviderChainDots -ActiveProvider "groq"

$lblCurrentModel = New-Object System.Windows.Forms.Label
$lblCurrentModel.Text = "Modelo: $(Get-ProviderDisplayInfo -Provider 'groq')"
$lblCurrentModel.ForeColor = $ThemeMuted
$lblCurrentModel.BackColor = $ThemePanel
$lblCurrentModel.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
$lblCurrentModel.AutoSize = $true
$lblCurrentModel.Location = New-Object System.Drawing.Point(18, 120)
$panelProvider.Controls.Add($lblCurrentModel)

$lblFallbackHint = New-Object System.Windows.Forms.Label
$lblFallbackHint.Text = "A ordem inicia pelo provedor selecionado acima."
$lblFallbackHint.ForeColor = $ThemeMuted
$lblFallbackHint.BackColor = $ThemePanel
$lblFallbackHint.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblFallbackHint.AutoSize = $true
$lblFallbackHint.Location = New-Object System.Drawing.Point(18, 142)
$panelProvider.Controls.Add($lblFallbackHint)

# NOVA: linha informativa "Gerar com IA" para ativar provider
$lblProviderDisabled = New-Object System.Windows.Forms.Label
$lblProviderDisabled.Text = "Ative 'Gerar com IA' abaixo para usar o orquestrador."
$lblProviderDisabled.ForeColor = $ThemeWarn
$lblProviderDisabled.BackColor = $ThemePanel
$lblProviderDisabled.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
$lblProviderDisabled.AutoSize = $true
$lblProviderDisabled.Location = New-Object System.Drawing.Point(18, 164)
$lblProviderDisabled.Visible = $true
$panelProvider.Controls.Add($lblProviderDisabled)

# ══════════════════════════════════════════════════════════════════
# STATUS BAR (tokens · arquivos · projeto · ENERGIZE)
# ══════════════════════════════════════════════════════════════════
$panelStatus = New-Object System.Windows.Forms.Panel
$panelStatus.BackColor = $ThemePanelAlt
$panelStatus.Size = New-Object System.Drawing.Size(824, 44)
$panelStatus.Location = New-Object System.Drawing.Point(18, 284)
$panelStatus.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($panelStatus)

$lblStatusProvider = New-Object System.Windows.Forms.Label
$lblStatusProvider.Text = "● Groq  ·  llama-3.3-70b-versatile"
$lblStatusProvider.ForeColor = $ThemeCyan
$lblStatusProvider.BackColor = $ThemePanelAlt
$lblStatusProvider.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$lblStatusProvider.AutoSize = $true
$lblStatusProvider.Location = New-Object System.Drawing.Point(12, 14)
$panelStatus.Controls.Add($lblStatusProvider)

$lblStatusInfo = New-Object System.Windows.Forms.Label
$lblStatusInfo.Text = "~0 tokens  ·  $($FoundFiles.Count) arquivos  ·  $ProjectName"
$lblStatusInfo.ForeColor = $ThemeMuted
$lblStatusInfo.BackColor = $ThemePanelAlt
$lblStatusInfo.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblStatusInfo.AutoSize = $true
$lblStatusInfo.Location = New-Object System.Drawing.Point(280, 14)
$panelStatus.Controls.Add($lblStatusInfo)

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "ENERGIZE"
$btnRun.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnRun.FlatAppearance.BorderSize = 1
$btnRun.FlatAppearance.BorderColor = $ThemeCyan
$btnRun.BackColor = $ThemePanelAlt
$btnRun.ForeColor = $ThemeCyan
$btnRun.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnRun.Size = New-Object System.Drawing.Size(148, 30)
$btnRun.Location = New-Object System.Drawing.Point(664, 7)
$btnRun.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$panelStatus.Controls.Add($btnRun)

# ══════════════════════════════════════════════════════════════════
# SNIPER PANEL (accordion: search + chips + tree)
# ══════════════════════════════════════════════════════════════════
$panelSniper = New-Object System.Windows.Forms.GroupBox
$panelSniper.Text = "Preview de Arquivos — Sniper Mode"
$panelSniper.ForeColor = $ThemeCyan
$panelSniper.BackColor = $ThemePanel
$panelSniper.Size = New-Object System.Drawing.Size(824, 290)
$panelSniper.Location = New-Object System.Drawing.Point(18, 336)
$panelSniper.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelSniper.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$panelSniper.Visible = $false
$form.Controls.Add($panelSniper)

# Search box
$txtSniperSearch = New-Object System.Windows.Forms.TextBox
$txtSniperSearch.BackColor = $ThemePanelAlt
$txtSniperSearch.ForeColor = $ThemeMuted
$txtSniperSearch.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtSniperSearch.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$txtSniperSearch.Location = New-Object System.Drawing.Point(18, 26)
$txtSniperSearch.Size = New-Object System.Drawing.Size(350, 22)
$txtSniperSearch.Text = "Buscar arquivo..."
$panelSniper.Controls.Add($txtSniperSearch)

$lblSniperHint = New-Object System.Windows.Forms.Label
$lblSniperHint.Text = "Selecione os arquivos que entrarão no bundle manual."
$lblSniperHint.ForeColor = $ThemeMuted; $lblSniperHint.BackColor = $ThemePanel
$lblSniperHint.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblSniperHint.AutoSize = $true
$lblSniperHint.Location = New-Object System.Drawing.Point(380, 30)
$panelSniper.Controls.Add($lblSniperHint)

# Quick actions toolbar
$sniperToolbar = New-Object System.Windows.Forms.Panel
$sniperToolbar.BackColor = $ThemePanel
$sniperToolbar.Location = New-Object System.Drawing.Point(18, 56)
$sniperToolbar.Size = New-Object System.Drawing.Size(788, 28)
$sniperToolbar.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$panelSniper.Controls.Add($sniperToolbar)

function New-SniperButton {
    param([string]$Text, [int]$X, [int]$Width)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $b.FlatAppearance.BorderSize = 1
    $b.FlatAppearance.BorderColor = $ThemeMuted
    $b.BackColor = $ThemePanelAlt
    $b.ForeColor = $ThemeText
    $b.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $b.Location = New-Object System.Drawing.Point($X, 1)
    $b.Size = New-Object System.Drawing.Size($Width, 26)
    return $b
}

$btnSelectAll   = New-SniperButton -Text "✔ Tudo"   -X 0   -Width 72
$btnDeselectAll = New-SniperButton -Text "✘ Nenhum" -X 76  -Width 80
$sniperToolbar.Controls.AddRange(@($btnSelectAll, $btnDeselectAll))

# Extension chips panel
$lblChipsLabel = New-Object System.Windows.Forms.Label
$lblChipsLabel.Text = "EXT:"
$lblChipsLabel.ForeColor = $ThemeMuted; $lblChipsLabel.BackColor = $ThemePanel
$lblChipsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Bold)
$lblChipsLabel.AutoSize = $true
$lblChipsLabel.Location = New-Object System.Drawing.Point(166, 7)
$sniperToolbar.Controls.Add($lblChipsLabel)

$x = 192
$uniqueExtensions = @($FoundFiles | ForEach-Object { $_.Extension.ToLower() } | Sort-Object -Unique)
foreach ($ext in $uniqueExtensions) {
    $chipWidth = [Math]::Max(38, $ext.Length * 8 + 14)
    $chip = New-Object System.Windows.Forms.Button
    $chip.Text = $ext
    $chip.Tag = $ext
    $chip.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $chip.FlatAppearance.BorderSize = 1
    $chip.FlatAppearance.BorderColor = $ThemeCyan
    $chip.BackColor = $ThemePanelAlt
    $chip.ForeColor = $ThemeCyan
    $chip.Font = New-Object System.Drawing.Font("Segoe UI", 7.5)
    $chip.Location = New-Object System.Drawing.Point($x, 2)
    $chip.Size = New-Object System.Drawing.Size($chipWidth, 24)
    $chip.Add_Click({
        $clickedExt = $this.Tag
        $extNodes = @(Get-AllFileNodes -Nodes $treeFiles.Nodes | Where-Object { ([System.IO.FileInfo]$_.Tag).Extension.ToLower() -eq $clickedExt })
        $anyChecked = @($extNodes | Where-Object { $_.Checked }).Count -gt 0
        $newState = -not $anyChecked
        $script:SuppressTreeCheck = $true
        foreach ($node in $extNodes) { $node.Checked = $newState; Update-FolderParents -Node $node }
        $script:SuppressTreeCheck = $false
        Update-SniperStats
        Update-ExtChipAppearance -Ext $clickedExt
    })
    $sniperToolbar.Controls.Add($chip)
    $script:ExtChipButtons[$ext] = $chip
    $x += $chipWidth + 4
}

# TreeView
$treeFiles = New-Object System.Windows.Forms.TreeView
$treeFiles.CheckBoxes = $true
$treeFiles.BackColor = $ThemePanelAlt
$treeFiles.ForeColor = $ThemeText
$treeFiles.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$treeFiles.Font = New-Object System.Drawing.Font("Consolas", 9)
$treeFiles.Location = New-Object System.Drawing.Point(18, 92)
$treeFiles.Size = New-Object System.Drawing.Size(788, 150)
$treeFiles.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$treeFiles.ShowLines = $true; $treeFiles.ShowPlusMinus = $true
$treeFiles.ShowNodeToolTips = $true; $treeFiles.HideSelection = $false
$panelSniper.Controls.Add($treeFiles)

# Populate tree
foreach ($file in $FoundFiles) {
    $relPath = (Resolve-Path -Path $file.FullName -Relative).TrimStart('.').TrimStart('\').TrimStart('/')
    $parts = $relPath -split '[/\\]'
    $parentCollection = $treeFiles.Nodes
    $currentKey = ""
    for ($pi = 0; $pi -lt ($parts.Count - 1); $pi++) {
        $currentKey = if ($currentKey) { "$currentKey\$($parts[$pi])" } else { $parts[$pi] }
        if (-not $script:TreeNodeMap.ContainsKey($currentKey)) {
            $folderNode = New-Object System.Windows.Forms.TreeNode($parts[$pi])
            $folderNode.Checked = $true; $folderNode.ForeColor = $ThemeCyan
            $folderNode.ToolTipText = $currentKey
            [void]$parentCollection.Add($folderNode)
            $script:TreeNodeMap[$currentKey] = $folderNode
        }
        $parentCollection = $script:TreeNodeMap[$currentKey].Nodes
    }
    $displayName = $parts[-1]
    $fileNode = New-Object System.Windows.Forms.TreeNode($displayName)
    $fileNode.Checked = $true; $fileNode.Tag = $file
    $fileNode.ToolTipText = $relPath
    [void]$parentCollection.Add($fileNode)
}

$lblFileCount = New-Object System.Windows.Forms.Label
$lblFileCount.Text = "Selecionados: $($FoundFiles.Count) / $($FoundFiles.Count)  ·  calculando tokens..."
$lblFileCount.ForeColor = $ThemeMuted; $lblFileCount.BackColor = $ThemePanel
$lblFileCount.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblFileCount.AutoSize = $true
$lblFileCount.Location = New-Object System.Drawing.Point(18, 252)
$panelSniper.Controls.Add($lblFileCount)

# ── Tree helpers ──────────────────────────────────────────────────
function Get-AllFileNodes {
    param($Nodes)
    foreach ($node in $Nodes) {
        if ($node.Tag -is [System.IO.FileInfo]) { $node }
        else { Get-AllFileNodes -Nodes $node.Nodes }
    }
}

function Set-AllTreeNodesChecked {
    param($Nodes, [bool]$IsChecked)
    foreach ($node in $Nodes) {
        $node.Checked = $IsChecked
        if ($node.Nodes.Count -gt 0) { Set-AllTreeNodesChecked -Nodes $node.Nodes -IsChecked $IsChecked }
    }
}

function Set-AllDescendantsChecked {
    param($Node, [bool]$IsChecked)
    foreach ($child in $Node.Nodes) {
        $child.Checked = $IsChecked
        if ($child.Nodes.Count -gt 0) { Set-AllDescendantsChecked -Node $child -IsChecked $IsChecked }
    }
}

function Update-FolderParents {
    param($Node)
    $parent = $Node.Parent
    while ($null -ne $parent) {
        $parent.Checked = @($parent.Nodes | Where-Object { $_.Checked }).Count -gt 0
        $parent = $parent.Parent
    }
}

function Format-TokenCount {
    param([long]$Tokens)
    if ($Tokens -ge 1000000) { return "~$([Math]::Round($Tokens/1000000,1))M tokens" }
    if ($Tokens -ge 1000)    { return "~$([Math]::Round($Tokens/1000,1))k tokens" }
    return "~$Tokens tokens"
}

function Update-SniperStats {
    $selectedNodes = @(Get-AllFileNodes -Nodes $treeFiles.Nodes | Where-Object { $_.Checked })
    $count = $selectedNodes.Count
    $totalSize = ($selectedNodes | ForEach-Object { ([System.IO.FileInfo]$_.Tag).Length } | Measure-Object -Sum).Sum
    if ($null -eq $totalSize) { $totalSize = 0 }
    $tokenEst = [Math]::Round($totalSize / 4)
    $lblFileCount.Text = "Selecionados: $count / $($FoundFiles.Count)  ·  $(Format-TokenCount -Tokens $tokenEst)"
    Update-StatusBar
}

function Update-ExtChipAppearance {
    param([string]$Ext)
    $btn = $script:ExtChipButtons[$Ext]
    if ($null -eq $btn) { return }
    $extNodes = @(Get-AllFileNodes -Nodes $treeFiles.Nodes | Where-Object { ([System.IO.FileInfo]$_.Tag).Extension.ToLower() -eq $Ext })
    $anyChecked = @($extNodes | Where-Object { $_.Checked }).Count -gt 0
    $btn.BackColor = if ($anyChecked) { $ThemePanelAlt }  else { $ThemeBg }
    $btn.ForeColor = if ($anyChecked) { $ThemeCyan }      else { $ThemeMuted }
}

function Apply-SniperSearch {
    param([string]$Query)
    $q = $Query.Trim().ToLower()
    $isSearch = $q -ne "" -and $q -ne "buscar arquivo..."
    foreach ($fileNode in (Get-AllFileNodes -Nodes $treeFiles.Nodes)) {
        if ($isSearch) {
            $tooltip = $fileNode.ToolTipText.ToLower()
            $match = $tooltip -like "*$q*"
            $fileNode.ForeColor = if ($match) { $ThemeText } else { $ThemeMuted }
        } else {
            $fileNode.ForeColor = $ThemeText
        }
    }
}

$treeFiles.Add_AfterCheck({
    if ($script:SuppressTreeCheck) { return }
    $script:SuppressTreeCheck = $true
    $node = $_.Node
    if ($node.Tag -isnot [System.IO.FileInfo]) { Set-AllDescendantsChecked -Node $node -IsChecked $node.Checked }
    Update-FolderParents -Node $node
    Update-SniperStats
    foreach ($ext in $script:ExtChipButtons.Keys) { Update-ExtChipAppearance -Ext $ext }
    $script:SuppressTreeCheck = $false
})

$txtSniperSearch.Add_GotFocus({
    if ($txtSniperSearch.Text -eq "Buscar arquivo...") {
        $txtSniperSearch.Text = ""
        $txtSniperSearch.ForeColor = $ThemeText
    }
})
$txtSniperSearch.Add_LostFocus({
    if ($txtSniperSearch.Text -eq "") {
        $txtSniperSearch.Text = "Buscar arquivo..."
        $txtSniperSearch.ForeColor = $ThemeMuted
    }
})
$txtSniperSearch.Add_TextChanged({ Apply-SniperSearch -Query $txtSniperSearch.Text })

$btnSelectAll.Add_Click({
    $script:SuppressTreeCheck = $true
    Set-AllTreeNodesChecked -Nodes $treeFiles.Nodes -IsChecked $true
    $script:SuppressTreeCheck = $false
    Update-SniperStats
    foreach ($ext in $script:ExtChipButtons.Keys) { Update-ExtChipAppearance -Ext $ext }
})

$btnDeselectAll.Add_Click({
    $script:SuppressTreeCheck = $true
    Set-AllTreeNodesChecked -Nodes $treeFiles.Nodes -IsChecked $false
    $script:SuppressTreeCheck = $false
    Update-SniperStats
    foreach ($ext in $script:ExtChipButtons.Keys) { Update-ExtChipAppearance -Ext $ext }
})

# ══════════════════════════════════════════════════════════════════
# CHECKBOX: GERAR COM IA
# ══════════════════════════════════════════════════════════════════
$chkSendToAI = New-Object System.Windows.Forms.CheckBox
$chkSendToAI.Text = "Gerar o Prompt Final com IA ao concluir"
$chkSendToAI.ForeColor = $ThemeText; $chkSendToAI.BackColor = $ThemeBg
$chkSendToAI.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$chkSendToAI.AutoSize = $true
$chkSendToAI.Location = New-Object System.Drawing.Point(18, 336)
$chkSendToAI.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($chkSendToAI)

# ══════════════════════════════════════════════════════════════════
# PANEL: FLUXO FINAL / GERAÇÃO COM IA
# ══════════════════════════════════════════════════════════════════
$panelAIPromptMode = New-Object System.Windows.Forms.GroupBox
$panelAIPromptMode.Text = "Fluxo Final / Geração com IA"
$panelAIPromptMode.ForeColor = $ThemePink
$panelAIPromptMode.BackColor = $ThemePanel
$panelAIPromptMode.Size = New-Object System.Drawing.Size(824, 92)
$panelAIPromptMode.Location = New-Object System.Drawing.Point(18, 370)
$panelAIPromptMode.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelAIPromptMode.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($panelAIPromptMode)

$lblAIFlowMode = New-Object System.Windows.Forms.Label
$lblAIFlowMode.Text = "FLUXO FINAL"
$lblAIFlowMode.ForeColor = $ThemeCyan; $lblAIFlowMode.BackColor = $ThemePanel
$lblAIFlowMode.Font = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Bold)
$lblAIFlowMode.AutoSize = $true
$lblAIFlowMode.Location = New-Object System.Drawing.Point(18, 30)
$panelAIPromptMode.Controls.Add($lblAIFlowMode)

$rbAIFlowDirector = New-Object System.Windows.Forms.RadioButton
$rbAIFlowDirector.Text = "Via Diretor"
$rbAIFlowDirector.ForeColor = $ThemeText; $rbAIFlowDirector.BackColor = $ThemePanel
$rbAIFlowDirector.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbAIFlowDirector.Location = New-Object System.Drawing.Point(18, 50)
$rbAIFlowDirector.Size = New-Object System.Drawing.Size(140, 24)
$rbAIFlowDirector.Checked = $true
$panelAIPromptMode.Controls.Add($rbAIFlowDirector)

$rbAIFlowExecutor = New-Object System.Windows.Forms.RadioButton
$rbAIFlowExecutor.Text = "Direto para Executor"
$rbAIFlowExecutor.ForeColor = $ThemeText; $rbAIFlowExecutor.BackColor = $ThemePanel
$rbAIFlowExecutor.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbAIFlowExecutor.Location = New-Object System.Drawing.Point(180, 50)
$rbAIFlowExecutor.Size = New-Object System.Drawing.Size(180, 24)
$panelAIPromptMode.Controls.Add($rbAIFlowExecutor)

$lblAIFlowHint = New-Object System.Windows.Forms.Label
$lblAIFlowHint.Text = "Via Diretor mantém o fluxo atual. Direto para Executor gera contexto final para a IA executora sem intermediação."
$lblAIFlowHint.ForeColor = $ThemeMuted; $lblAIFlowHint.BackColor = $ThemePanel
$lblAIFlowHint.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblAIFlowHint.AutoSize = $true
$lblAIFlowHint.Location = New-Object System.Drawing.Point(18, 76)
$panelAIPromptMode.Controls.Add($lblAIFlowHint)

$lblAIPromptMode = New-Object System.Windows.Forms.Label
$lblAIPromptMode.Text = "SYSTEMPROMPT"
$lblAIPromptMode.ForeColor = $ThemeCyan; $lblAIPromptMode.BackColor = $ThemePanel
$lblAIPromptMode.Font = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Bold)
$lblAIPromptMode.AutoSize = $true
$lblAIPromptMode.Location = New-Object System.Drawing.Point(18, 100)
$lblAIPromptMode.Visible = $false
$panelAIPromptMode.Controls.Add($lblAIPromptMode)

$rbPromptModeDefault = New-Object System.Windows.Forms.RadioButton
$rbPromptModeDefault.Text = "Modo padrão"
$rbPromptModeDefault.ForeColor = $ThemeText; $rbPromptModeDefault.BackColor = $ThemePanel
$rbPromptModeDefault.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbPromptModeDefault.Location = New-Object System.Drawing.Point(18, 118)
$rbPromptModeDefault.Size = New-Object System.Drawing.Size(140, 24)
$rbPromptModeDefault.Checked = $true
$rbPromptModeDefault.Visible = $false
$panelAIPromptMode.Controls.Add($rbPromptModeDefault)

$rbPromptModeCustom = New-Object System.Windows.Forms.RadioButton
$rbPromptModeCustom.Text = "Modo personalizado"
$rbPromptModeCustom.ForeColor = $ThemeText; $rbPromptModeCustom.BackColor = $ThemePanel
$rbPromptModeCustom.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbPromptModeCustom.Location = New-Object System.Drawing.Point(180, 118)
$rbPromptModeCustom.Size = New-Object System.Drawing.Size(180, 24)
$rbPromptModeCustom.Visible = $false
$panelAIPromptMode.Controls.Add($rbPromptModeCustom)

$lblAIPromptModeHint = New-Object System.Windows.Forms.Label
$lblAIPromptModeHint.Text = "Modo padrão usa o fluxo nativo. Personalizado envia o systemPrompt abaixo."
$lblAIPromptModeHint.ForeColor = $ThemeMuted; $lblAIPromptModeHint.BackColor = $ThemePanel
$lblAIPromptModeHint.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblAIPromptModeHint.AutoSize = $true
$lblAIPromptModeHint.Location = New-Object System.Drawing.Point(18, 144)
$lblAIPromptModeHint.Visible = $false
$panelAIPromptMode.Controls.Add($lblAIPromptModeHint)

$lblCustomSystemPrompt = New-Object System.Windows.Forms.Label
$lblCustomSystemPrompt.Text = "SystemPrompt personalizado"
$lblCustomSystemPrompt.ForeColor = $ThemeCyan; $lblCustomSystemPrompt.BackColor = $ThemePanel
$lblCustomSystemPrompt.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$lblCustomSystemPrompt.AutoSize = $true
$lblCustomSystemPrompt.Location = New-Object System.Drawing.Point(18, 170)
$lblCustomSystemPrompt.Visible = $false
$panelAIPromptMode.Controls.Add($lblCustomSystemPrompt)

$txtCustomSystemPrompt = New-Object System.Windows.Forms.TextBox
$txtCustomSystemPrompt.Multiline = $true; $txtCustomSystemPrompt.AcceptsReturn = $true
$txtCustomSystemPrompt.AcceptsTab = $true
$txtCustomSystemPrompt.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$txtCustomSystemPrompt.BackColor = $ThemePanelAlt; $txtCustomSystemPrompt.ForeColor = $ThemeText
$txtCustomSystemPrompt.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$txtCustomSystemPrompt.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtCustomSystemPrompt.Location = New-Object System.Drawing.Point(18, 192)
$txtCustomSystemPrompt.Size = New-Object System.Drawing.Size(788, 86)
$txtCustomSystemPrompt.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$txtCustomSystemPrompt.Visible = $false
$panelAIPromptMode.Controls.Add($txtCustomSystemPrompt)

# ══════════════════════════════════════════════════════════════════
# PROGRESS BAR
# ══════════════════════════════════════════════════════════════════
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
$progressBar.MarqueeAnimationSpeed = 30
$progressBar.Size = New-Object System.Drawing.Size(824, 10)
$progressBar.Location = New-Object System.Drawing.Point(18, 474)
$progressBar.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

# ══════════════════════════════════════════════════════════════════
# LOG HEADER + LOG VIEWER
# ══════════════════════════════════════════════════════════════════
$panelLogHeader = New-Object System.Windows.Forms.Panel
$panelLogHeader.BackColor = $ThemePanelAlt
$panelLogHeader.Size = New-Object System.Drawing.Size(824, 32)
$panelLogHeader.Location = New-Object System.Drawing.Point(18, 492)
$panelLogHeader.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($panelLogHeader)

$lblLogTitle = New-Object System.Windows.Forms.Label
$lblLogTitle.Text = "LOG DE EXECUÇÃO"
$lblLogTitle.ForeColor = $ThemeMuted; $lblLogTitle.BackColor = $ThemePanelAlt
$lblLogTitle.Font = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Bold)
$lblLogTitle.AutoSize = $true
$lblLogTitle.Location = New-Object System.Drawing.Point(10, 9)
$panelLogHeader.Controls.Add($lblLogTitle)

$cmbLogFilter = New-Object System.Windows.Forms.ComboBox
$cmbLogFilter.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmbLogFilter.BackColor = $ThemePanelAlt; $cmbLogFilter.ForeColor = $ThemeText
$cmbLogFilter.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$cmbLogFilter.Size = New-Object System.Drawing.Size(90, 22)
$cmbLogFilter.Location = New-Object System.Drawing.Point(600, 5)
$cmbLogFilter.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
[void]$cmbLogFilter.Items.Add("Todos")
[void]$cmbLogFilter.Items.Add("IA")
[void]$cmbLogFilter.Items.Add("Avisos")
$cmbLogFilter.SelectedIndex = 0
$panelLogHeader.Controls.Add($cmbLogFilter)

function New-LogHeaderButton {
    param([string]$Text, [int]$X)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $b.FlatAppearance.BorderSize = 1
    $b.FlatAppearance.BorderColor = $ThemeMuted
    $b.BackColor = $ThemePanelAlt; $b.ForeColor = $ThemeMuted
    $b.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $b.Location = New-Object System.Drawing.Point($X, 4)
    $b.Size = New-Object System.Drawing.Size(58, 24)
    $b.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
    return $b
}

$btnCopyLog   = New-LogHeaderButton -Text "Copiar" -X 698
$btnExpandLog = New-LogHeaderButton -Text "▲ Expandir" -X 760
$btnExpandLog.Size = New-Object System.Drawing.Size(56, 24)
$panelLogHeader.Controls.AddRange(@($btnCopyLog, $btnExpandLog))

$logViewer = New-Object System.Windows.Forms.RichTextBox
$logViewer.BackColor = $ThemePanelAlt; $logViewer.ForeColor = $ThemeText
$logViewer.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$logViewer.ReadOnly = $true; $logViewer.DetectUrls = $false
$logViewer.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$logViewer.Location = New-Object System.Drawing.Point(18, 532)
$logViewer.Size = New-Object System.Drawing.Size(824, 260)
$logViewer.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($logViewer)

# ══════════════════════════════════════════════════════════════════
# HELPER: STATUS BAR UPDATE
# ══════════════════════════════════════════════════════════════════
function Update-StatusBar {
    $filesToEstimate = if ($rbSniper.Checked) {
        @(Get-AllFileNodes -Nodes $treeFiles.Nodes | Where-Object { $_.Checked } | ForEach-Object { [System.IO.FileInfo]$_.Tag })
    } else {
        @($FoundFiles)
    }
    $totalSize = ($filesToEstimate | Measure-Object -Property Length -Sum).Sum
    if ($null -eq $totalSize) { $totalSize = 0 }
    $tokenEst = [Math]::Round($totalSize / 4)
    $lblStatusInfo.Text = "$(Format-TokenCount -Tokens $tokenEst)  ·  $($filesToEstimate.Count) arquivos  ·  $ProjectName"
}

function Update-ProviderStatus {
    $provider = Resolve-AIProviderFromUI -RbGroq $rbGroq -RbGemini $rbGemini -RbOpenAI $rbOpenAI -RbAnthropic $rbAnthropic
    if (-not $provider) { $provider = "groq" }
    $isActive = $chkSendToAI.Checked
    $info = Get-ProviderDisplayInfo -Provider $provider
    $lblStatusProvider.Text = "$(if ($isActive) { '●' } else { '○' }) $info"
    $lblStatusProvider.ForeColor = if ($isActive) { $ThemeCyan } else { $ThemeMuted }
    Build-ProviderChainDots -ActiveProvider $provider
    $lblCurrentModel.Text = "Modelo: $info"
    $panelProvider.Enabled = $isActive
    $lblProviderDisabled.Visible = -not $isActive
}

# ══════════════════════════════════════════════════════════════════
# HELPER: AI PANEL VISIBILITY
# ══════════════════════════════════════════════════════════════════
function Update-AIPromptModeUi {
    $promptVisible = $chkSendToAI.Checked
    $customVisible = $promptVisible -and $rbPromptModeCustom.Checked

    $lblAIPromptMode.Visible      = $promptVisible
    $rbPromptModeDefault.Visible  = $promptVisible
    $rbPromptModeCustom.Visible   = $promptVisible
    $lblAIPromptModeHint.Visible  = $promptVisible
    $lblCustomSystemPrompt.Visible = $customVisible
    $txtCustomSystemPrompt.Visible = $customVisible

    if ($customVisible)      { $panelAIPromptMode.Height = 292 }
    elseif ($promptVisible)  { $panelAIPromptMode.Height = 168 }
    else                     { $panelAIPromptMode.Height = 92  }

    Update-ProviderStatus
    Update-ResponsiveLayout
}

# ══════════════════════════════════════════════════════════════════
# RESPONSIVE LAYOUT
# ══════════════════════════════════════════════════════════════════
function Update-ResponsiveLayout {
    $clientWidth  = [int]$form.ClientSize.Width
    $clientHeight = [int]$form.ClientSize.Height

    $leftGap      = 18
    $rightGap     = 18
    $colGap       = 20
    $panelHeight  = 192
    $statusH      = 44
    $topContentY  = 84
    $bottomGap    = 20
    $progressH    = 10
    $logHeaderH   = 32
    $minLogH      = if ($script:IsFullscreen) { 100 } else { 120 }

    $usableWidth = [int][Math]::Max(320, ($clientWidth - ($leftGap * 2)))
    $leftWidth   = [int][Math]::Floor(($usableWidth - $colGap) / 2)
    $rightWidth  = [int]($usableWidth - $leftWidth - $colGap)

    # Row 1: mode + provider
    $panelMode.Location = New-Object System.Drawing.Point($leftGap, $topContentY)
    $panelMode.Size     = New-Object System.Drawing.Size($leftWidth, $panelHeight)

    $providerX = [int]($leftGap + $leftWidth + $colGap)
    $panelProvider.Location = New-Object System.Drawing.Point($providerX, $topContentY)
    $panelProvider.Size     = New-Object System.Drawing.Size($rightWidth, $panelHeight)

    $innerProviderW = [int][Math]::Max(140, ($panelProvider.Width - 36))
    $providerHint.MaximumSize        = New-Object System.Drawing.Size($innerProviderW, 0)
    $pnlProviderChain.Size           = New-Object System.Drawing.Size($innerProviderW, 24)
    $lblCurrentModel.MaximumSize     = New-Object System.Drawing.Size($innerProviderW, 0)
    $lblFallbackHint.MaximumSize     = New-Object System.Drawing.Size($innerProviderW, 0)
    $lblProviderDisabled.MaximumSize = New-Object System.Drawing.Size($innerProviderW, 0)

    # Status bar
    $statusY = [int]($topContentY + $panelHeight + 8)
    $panelStatus.Location = New-Object System.Drawing.Point($leftGap, $statusY)
    $panelStatus.Size     = New-Object System.Drawing.Size($usableWidth, $statusH)
    $btnRun.Location      = New-Object System.Drawing.Point(($panelStatus.Width - $btnRun.Width - 8), 7)

    # Sniper (accordion)
    $sniperTop = [int]($statusY + $statusH + 8)
    $desiredSniperH = 290
    $minSniperH     = 160

    if ($panelSniper.Visible) {
        $panelSniper.Location = New-Object System.Drawing.Point($leftGap, $sniperTop)
        $panelSniper.Size     = New-Object System.Drawing.Size($usableWidth, $desiredSniperH)

        $innerW    = [int][Math]::Max(140, ($panelSniper.ClientSize.Width - 36))
        $treeH     = [int][Math]::Max(60, ($panelSniper.Height - 120))
        $sniperToolbar.Size = New-Object System.Drawing.Size($innerW, 28)
        $treeFiles.Size     = New-Object System.Drawing.Size($innerW, $treeH)
        $txtSniperSearch.Size = New-Object System.Drawing.Size([int]([Math]::Min(360, $innerW * 0.45)), 22)
        $lblFileCount.Location = New-Object System.Drawing.Point(18, ($treeFiles.Bottom + 6))

        $chkY = [int]($panelSniper.Bottom + 10)
    } else {
        $chkY = $sniperTop
    }

    $chkSendToAI.Location = New-Object System.Drawing.Point($leftGap, $chkY)

    $aiPanelTop  = [int]($chkY + 32)
    $promptVis   = $chkSendToAI.Checked
    $customVis   = $promptVis -and $rbPromptModeCustom.Checked
    $aiPanelH    = if ($customVis) { 292 } elseif ($promptVis) { 168 } else { 92 }

    $panelAIPromptMode.Location = New-Object System.Drawing.Point($leftGap, $aiPanelTop)
    $panelAIPromptMode.Size     = New-Object System.Drawing.Size($usableWidth, $aiPanelH)

    $innerAI = [int][Math]::Max(140, ($panelAIPromptMode.Width - 36))
    $lblAIFlowHint.MaximumSize      = New-Object System.Drawing.Size($innerAI, 0)
    $lblAIPromptModeHint.MaximumSize = New-Object System.Drawing.Size($innerAI, 0)
    if ($customVis) { $txtCustomSystemPrompt.Size = New-Object System.Drawing.Size($innerAI, 86) }

    # Progress
    $progressY = [int]($panelAIPromptMode.Bottom + 8)
    $progressBar.Location = New-Object System.Drawing.Point($leftGap, $progressY)
    $progressBar.Size     = New-Object System.Drawing.Size($usableWidth, $progressH)

    # Log header + viewer
    $logHeaderY = [int]($progressY + $progressH + 6)
    $panelLogHeader.Location = New-Object System.Drawing.Point($leftGap, $logHeaderY)
    $panelLogHeader.Size     = New-Object System.Drawing.Size($usableWidth, $logHeaderH)

    # Reposition log header buttons to right edge
    $cmbLogFilter.Location   = New-Object System.Drawing.Point(($panelLogHeader.Width - 250), 5)
    $btnCopyLog.Location     = New-Object System.Drawing.Point(($panelLogHeader.Width - 148), 4)
    $btnExpandLog.Location   = New-Object System.Drawing.Point(($panelLogHeader.Width - 84), 4)

    $logTop = [int]($logHeaderY + $logHeaderH)
    $expandedLogH = [int]($clientHeight - $logTop - $bottomGap - 80)
    $normalLogH   = [int]($clientHeight - $logTop - $bottomGap)
    $logH = if ($script:LogExpanded) {
        [Math]::Max($minLogH, $expandedLogH)
    } else {
        [Math]::Max($minLogH, $normalLogH)
    }
    $logViewer.Location = New-Object System.Drawing.Point($leftGap, $logTop)
    $logViewer.Size     = New-Object System.Drawing.Size($usableWidth, $logH)

    $contentBottom = [int]($logViewer.Bottom + $bottomGap)
    $form.AutoScrollMinSize = New-Object System.Drawing.Size(0, [Math]::Max($clientHeight, $contentBottom))

    $resizeGrip.Visible = -not $script:IsFullscreen
    $resizeGrip.Location = New-Object System.Drawing.Point(($clientWidth - $resizeGrip.Width), ($clientHeight - $resizeGrip.Height))
}

# ══════════════════════════════════════════════════════════════════
# SNIPER LAYOUT TOGGLE
# ══════════════════════════════════════════════════════════════════
function Set-SniperLayout {
    param([bool]$Visible)
    $panelSniper.Visible = $Visible
    $pref = if ($Visible) { $script:PreferredSniperSize } else { $script:PreferredNormalSize }
    if (-not $script:IsFullscreen) {
        Set-FormBoundsSafe -Width $pref.Width -Height $pref.Height -PreserveLocation $true
        $script:StoredNormalBounds = $form.Bounds
    }
    Update-StatusBar
    Update-ResponsiveLayout
    Ensure-FormVisible
}

# ══════════════════════════════════════════════════════════════════
# EVENT WIRING
# ══════════════════════════════════════════════════════════════════
$rbSniper.Add_CheckedChanged({ Set-SniperLayout -Visible $rbSniper.Checked; Update-StatusBar })
$rbFull.Add_CheckedChanged({ if ($rbFull.Checked) { Set-SniperLayout -Visible $false }; Update-StatusBar })
$rbArchitect.Add_CheckedChanged({ if ($rbArchitect.Checked) { Set-SniperLayout -Visible $false }; Update-StatusBar })

$chkSendToAI.Add_CheckedChanged({ Update-AIPromptModeUi })
$rbPromptModeDefault.Add_CheckedChanged({ Update-AIPromptModeUi })
$rbPromptModeCustom.Add_CheckedChanged({ Update-AIPromptModeUi })
$rbAIFlowDirector.Add_CheckedChanged({ Update-AIPromptModeUi })
$rbAIFlowExecutor.Add_CheckedChanged({ Update-AIPromptModeUi })

$rbGroq.Add_CheckedChanged({ Update-ProviderStatus })
$rbGemini.Add_CheckedChanged({ Update-ProviderStatus })
$rbOpenAI.Add_CheckedChanged({ Update-ProviderStatus })
$rbAnthropic.Add_CheckedChanged({ Update-ProviderStatus })

$form.Add_Shown({
    Set-SniperLayout -Visible $false
    Update-AIPromptModeUi
    Update-StatusBar
    Set-HudFullscreen
    Ensure-FormVisible
})
$form.Add_Move({
    if ($script:SuppressVisibleClamp) { return }
    if (-not $script:IsDragging -and -not $script:IsResizing -and -not $script:IsFullscreen) {
        $script:StoredNormalBounds = $form.Bounds
        Ensure-FormVisible
    }
})
$form.Add_SizeChanged({
    if ($script:SuppressVisibleClamp) { Update-ResponsiveLayout; return }
    if (-not $script:IsResizing) { Ensure-FormVisible }
    if (-not $script:IsFullscreen) { $script:StoredNormalBounds = $form.Bounds }
    Update-ResponsiveLayout
})

# ══════════════════════════════════════════════════════════════════
# LOG ENGINE
# ══════════════════════════════════════════════════════════════════
function Get-LogLevel {
    param([System.Drawing.Color]$Color)
    if ($Color.ToArgb() -eq $ThemeCyan.ToArgb())    { return "ia" }
    if ($Color.ToArgb() -eq $ThemeSuccess.ToArgb())  { return "success" }
    if ($Color.ToArgb() -eq $ThemePink.ToArgb())     { return "warn" }
    return "info"
}

function Test-LogEntryVisible {
    param([hashtable]$Entry)
    $filter = $cmbLogFilter.SelectedItem
    if ($filter -eq "Todos") { return $true }
    if ($filter -eq "IA"     -and $Entry.Level -eq "ia")      { return $true }
    if ($filter -eq "Avisos" -and ($Entry.Level -eq "warn" -or $Entry.Level -eq "success")) { return $true }
    return $false
}

function Append-LogEntry {
    param([hashtable]$Entry)
    $logViewer.SelectionStart = $logViewer.TextLength
    $logViewer.SelectionLength = 0
    $logViewer.SelectionColor = $Entry.Color
    $logViewer.AppendText("[$($Entry.Timestamp)] $($Entry.Message)`r`n")
    $logViewer.SelectionColor = $logViewer.ForeColor
    $logViewer.ScrollToCaret()
    $logViewer.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

function Redraw-LogViewer {
    $logViewer.Clear()
    foreach ($entry in $script:LogEntries) {
        if (Test-LogEntryVisible -Entry $entry) { Append-LogEntry -Entry $entry }
    }
}

function Write-UILog {
    param([string]$Message, [System.Drawing.Color]$Color = $ThemeText)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $level = Get-LogLevel -Color $Color
    $entry = @{ Timestamp = $timestamp; Message = $Message; Color = $Color; Level = $level }
    $script:LogEntries.Add($entry)
    if (Test-LogEntryVisible -Entry $entry) { Append-LogEntry -Entry $entry }
}

$cmbLogFilter.Add_SelectedIndexChanged({ Redraw-LogViewer })

$btnCopyLog.Add_Click({
    $text = ($script:LogEntries | ForEach-Object { "[$($_.Timestamp)] $($_.Message)" }) -join "`r`n"
    try {
        $text | Set-Clipboard
        Write-UILog -Message "Log copiado para a área de transferência." -Color $ThemeSuccess
    } catch {
        Write-UILog -Message "Não foi possível copiar o log." -Color $ThemePink
    }
})

$btnExpandLog.Add_Click({
    $script:LogExpanded = -not $script:LogExpanded
    $btnExpandLog.Text = if ($script:LogExpanded) { "▼ Reduzir" } else { "▲ Expandir" }
    Update-ResponsiveLayout
})

# ══════════════════════════════════════════════════════════════════
# SET-UIBUSY
# ══════════════════════════════════════════════════════════════════
function Set-UiBusy {
    param([bool]$Busy)
    $panelMode.Enabled          = -not $Busy
    $panelProvider.Enabled      = if ($Busy) { $false } else { $chkSendToAI.Checked }
    $panelSniper.Enabled        = -not $Busy
    $panelAIPromptMode.Enabled  = -not $Busy
    $chkSendToAI.Enabled        = -not $Busy
    $btnRun.Enabled             = -not $Busy
    $progressBar.Visible        = $Busy
    $btnRun.Text                = if ($Busy) { "..." } else { "ENERGIZE" }
}

# ══════════════════════════════════════════════════════════════════
# ORCHESTRATOR AGENT INVOCATION
# ══════════════════════════════════════════════════════════════════
function Invoke-OrchestratorAgent {
    param(
        [string]$AgentScriptPath,
        [string]$BundlePath,
        [string]$ProjectNameValue,
        [string]$ExecutorTargetValue,
        [string]$BundleModeValue,
        [string]$PrimaryProviderValue,
        [string]$OutputRouteModeValue,
        [string]$CustomSystemPromptFilePath = $null,
        [string]$ExtractionModeValue = "full"
    )

    if (-not (Test-Path $AgentScriptPath)) { throw "Script groq-agent.ts não localizado." }

    $winner = [ordered]@{ Provider = $null; Model = $null }

    $handleAgentLine = {
        param([string]$Line, [System.Drawing.Color]$DefaultColor)
        if ([string]::IsNullOrWhiteSpace($Line)) { return }
        if ($Line -match '\[AI_RESULT\]\s+provider=([^;]+);model=(.+)$') {
            $winner.Provider = $Matches[1].Trim()
            $winner.Model    = $Matches[2].Trim()
            return
        }
        Write-UILog -Message $Line -Color $DefaultColor
    }.GetNewClosure()

    $commandParts = @(
        "npx", "--quiet", "tsx", "`"$AgentScriptPath`"",
        "`"$BundlePath`"", "`"$ProjectNameValue`"", "`"$ExecutorTargetValue`"",
        "`"$BundleModeValue`"", "`"$PrimaryProviderValue`"", "`"$OutputRouteModeValue`"",
        (if ($null -ne $CustomSystemPromptFilePath -and $CustomSystemPromptFilePath -ne "") { "`"$CustomSystemPromptFilePath`"" } else { '""' }),
        "`"$ExtractionModeValue`""
    )

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $process.StartInfo.FileName = "cmd.exe"
    $process.StartInfo.Arguments = "/c " + ($commandParts -join " ")
    $process.StartInfo.WorkingDirectory = (Get-Location).Path
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError  = $true
    $process.StartInfo.EnvironmentVariables["DOTENV_CONFIG_SILENT"]    = "true"
    $process.StartInfo.EnvironmentVariables["npm_config_update_notifier"] = "false"
    $process.StartInfo.EnvironmentVariables["NO_UPDATE_NOTIFIER"]      = "1"

    if (-not $process.Start()) { throw "Falha ao iniciar o processo do agente de IA." }

    while (-not $process.HasExited) {
        while ($process.StandardOutput.Peek() -ge 0) { & $handleAgentLine $process.StandardOutput.ReadLine() $ThemeCyan }
        while ($process.StandardError.Peek()  -ge 0) { & $handleAgentLine $process.StandardError.ReadLine()  $ThemePink }
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 100
    }
    $process.WaitForExit()
    while ($process.StandardOutput.Peek() -ge 0) { & $handleAgentLine $process.StandardOutput.ReadLine() $ThemeCyan }
    while ($process.StandardError.Peek()  -ge 0) { & $handleAgentLine $process.StandardError.ReadLine()  $ThemePink }

    if ($process.ExitCode -ne 0) { throw "groq-agent.ts finalizou com código $($process.ExitCode)." }

    # groq-agent.ts escreve sem prefixo de rota (_AI_RESULT_X.json).
    # Tenta o nome prefixado primeiro; se nao existir, tenta o nome nativo do agent.
    $bundleDir = Split-Path $BundlePath -Parent
    $candidateResultPaths = @(
        (Join-Path $bundleDir (Get-AIResultOutputFileName -ProjectNameValue $ProjectNameValue -RouteMode $OutputRouteModeValue)),
        (Join-Path $bundleDir "_AI_RESULT_${ProjectNameValue}.json")
    )

    foreach ($candidatePath in $candidateResultPaths) {
        if (Test-Path $candidatePath) {
            try {
                $resultMeta = Get-Content $candidatePath -Raw -Encoding UTF8 | ConvertFrom-Json
                return [pscustomobject]@{
                    WinnerProvider = if ($resultMeta.provider) { [string]$resultMeta.provider } else { $winner.Provider }
                    WinnerModel    = if ($resultMeta.model)    { [string]$resultMeta.model    } else { $winner.Model    }
                    OutputPath     = if ($resultMeta.outputPath) { [string]$resultMeta.outputPath } else { $null }
                }
            } catch {}
        }
    }

    return [pscustomobject]@{ WinnerProvider = $winner.Provider; WinnerModel = $winner.Model; OutputPath = $null }
}

# ══════════════════════════════════════════════════════════════════
# PROTOCOL HEADER BUILDER
# ══════════════════════════════════════════════════════════════════
function Get-ProtocolHeaderContent {
    param([string]$RouteMode, [string]$BundleChoice, [string]$ExecutorTargetValue)
    
    $extractionMode = if ($BundleChoice -eq '1') { 'full' } elseif ($BundleChoice -eq '2') { 'blueprint' } else { 'sniper' }
    
    $blocks = @()
    $blocks += "## PROTOCOLO OPERACIONAL TRANSVERSAL — ELITE v2"
    $blocks += ""
    $blocks += "### §0 — FILOSOFIA UNIFICADA (STRICT GLOBAL ENFORCEMENT)"
    $blocks += "**ZERO-VERBOSITY RULE**:"
    $blocks += "- Toda saída deve conter EXCLUSIVAMENTE conteúdo técnico de alta densidade."
    $blocks += "- Nenhuma frase introdutória, de transição, de encerramento ou de cortesia é tolerada."
    $blocks += ""
    $blocks += "**TOKEN ECONOMY RULE**:"
    $blocks += "- Cada token consumido deve carregar valor técnico mensurável."
    $blocks += "- Priorizar notação compacta: bullet-points, key-value, diffs, blocos de código."
    
    $blocks += ""
    $blocks += "### §1 — PROIBIÇÕES GLOBAIS (HARD-BLOCKED)"
    $blocks += "As seguintes saídas são BLOQUEADAS em QUALQUER modo. Violação = falha de protocolo."
    $blocks += "1. Termos de cortesia ou rapport."
    $blocks += "2. Redundância com o contexto fornecido."
    $blocks += "3. Explicações de conceitos básicos."
    $blocks += "4. Meta-comentários sobre a própria resposta."
    
    if ($RouteMode -eq 'director') {
        $blocks += ""
        $blocks += "### §2 — ESPECIFICAÇÃO DE MODO: DIRETOR"
        $blocks += "**IDENTIDADE**: Você é o DIRETOR TÉCNICO DE EXECUÇÃO. Você NÃO é a IA executora final."
        $blocks += "**FUNÇÃO OBRIGATÓRIA**:"
        $blocks += "- Ler este documento como Source of Truth"
        $blocks += "- Assimilar o projeto"
        $blocks += "- Aguardar a solicitação futura do usuário"
        $blocks += "- Converter a solicitação em um PROMPT DE EXECUÇÃO imperativo e mapeado"
        $blocks += "- Entregar esse prompt para uma IA executora/agêntica"
        $blocks += ""
        $blocks += "**SAÍDA OBRIGATÓRIA**: Prompt estruturado no formato abaixo, sem texto fora do bloco:"
        $blocks += "````text"
        $blocks += "## Instruções"
        $blocks += "CONTEXTO:"
        $blocks += "- [referências diretas ao projeto, arquivos, contratos afetados]"
        $blocks += ""
        $blocks += "OBJETIVO:"
        $blocks += "[verbo imperativo] + [alvo técnico preciso]"
        $blocks += ""
        $blocks += "REGRAS:"
        $blocks += "- [restrições técnicas derivadas da Source of Truth]"
        $blocks += ""
        $blocks += "ENTREGA:"
        $blocks += "- [artefatos esperados: arquivos, diffs, comandos]"
        $blocks += ""
        $blocks += "ADAPTAÇÕES AO PROJETO:"
        $blocks += "- [particularidades do projeto que o executor DEVE respeitar]"
        $blocks += "````"
    } else {
        $blocks += ""
        $blocks += "### §2 — ESPECIFICAÇÃO DE MODO: EXECUTOR"
        $blocks += "**IDENTIDADE**: Você é o SENIOR_ENGINEERING_EXECUTOR."
        $blocks += "**FUNÇÃO OBRIGATÓRIA**: Executar diretamente a alteração solicitada no código existente."
    }
    
    if ($extractionMode -eq 'blueprint') {
        $blocks += ""
        $blocks += "### MODO BLUEPRINT"
        $blocks += "- O contexto contém majoritariamente assinaturas e interfaces."
        $blocks += "- Não tente inferir implementações profundas não documentadas."
    } elseif ($extractionMode -eq 'sniper') {
        $blocks += ""
        $blocks += "### MODO SNIPER"
        $blocks += "- O contexto é um RECORTE PARCIAL cirúrgico."
        $blocks += "- Respeite os limites do recorte enviado."
    }
    
    $blocks += ""
    $blocks += "### §3 — REGRA DE CONTEXTO INSUFICIENTE"
    if ($extractionMode -eq 'full') {
        $blocks += "Baseie sua resposta no projeto completo fornecido."
    } else {
        $blocks += "Em recorte parcial/blueprint: restringir ao escopo visível."
    }
    
    $blocks += ""
    $blocks += "### §4 — MANUTENÇÃO DE INTEGRIDADE"
    $blocks += "- Preservar a estrutura de arquivos e código-fonte."
    $blocks += "- Contratos e identificadores são INTOCÁVEIS."
    
    return ($blocks -join "`n")
}

# ══════════════════════════════════════════════════════════════════
# ENERGIZE BUTTON
# ══════════════════════════════════════════════════════════════════
$btnRun.Add_Click({
    $currentChoice        = Resolve-ChoiceFromUI -RbFull $rbFull -RbArchitect $rbArchitect -RbSniper $rbSniper
    $currentExecutorTarget = $cmbExecutorInline.SelectedItem
    $currentAIProvider    = Resolve-AIProviderFromUI -RbGroq $rbGroq -RbGemini $rbGemini -RbOpenAI $rbOpenAI -RbAnthropic $rbAnthropic
    $currentAIPromptMode  = Resolve-AIPromptModeFromUI -RbDefault $rbPromptModeDefault -RbCustom $rbPromptModeCustom
    $currentAIFlowMode    = Resolve-AIFlowModeFromUI -RbDirector $rbAIFlowDirector -RbExecutor $rbAIFlowExecutor

    if (-not $currentChoice) {
        [System.Windows.Forms.MessageBox]::Show("Selecione um modo de extração.", "VibeToolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }
    if ($chkSendToAI.Checked -and -not $currentAIProvider) {
        [System.Windows.Forms.MessageBox]::Show("Selecione a IA primária.", "VibeToolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }
    if (-not $currentExecutorTarget) {
        [System.Windows.Forms.MessageBox]::Show("Selecione o executor alvo.", "VibeToolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }
    if ($chkSendToAI.Checked -and $currentAIPromptMode -eq "custom" -and [string]::IsNullOrWhiteSpace($txtCustomSystemPrompt.Text)) {
        [System.Windows.Forms.MessageBox]::Show("No modo personalizado, preencha o systemPrompt da IA.", "VibeToolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }

    $selectedFiles   = @()
    $unselectedFiles = @()

    if ($currentChoice -eq '3') {
        foreach ($fileNode in (Get-AllFileNodes -Nodes $treeFiles.Nodes)) {
            if ($fileNode.Checked) { $selectedFiles   += [System.IO.FileInfo]$fileNode.Tag }
            else                   { $unselectedFiles += [System.IO.FileInfo]$fileNode.Tag }
        }
        if ($selectedFiles.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No modo Sniper, selecione pelo menos um arquivo.", "VibeToolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }
    } else {
        $selectedFiles = @($FoundFiles)
    }

    $Choice          = $currentChoice
    $ExecutorTarget  = $currentExecutorTarget
    $AIProvider      = $currentAIProvider
    $FilesToProcess  = @($selectedFiles)
    $SendToAI        = $chkSendToAI.Checked
    $CustomSystemPromptFilePath = $null

    Set-UiBusy -Busy $true
    $logViewer.Clear()
    $script:LogEntries.Clear()

    try {
        Write-UILog -Message "HUD energizado." -Color $ThemeCyan
        Write-UILog -Message "Projeto: $ProjectName"
        Write-UILog -Message "Modo: $(if ($Choice -eq '1') { 'Full Vibe' } elseif ($Choice -eq '2') { 'Architect' } else { 'Sniper' })"
        Write-UILog -Message "Executor alvo: $ExecutorTarget"
        if ($SendToAI) { Write-UILog -Message "IA primária: $AIProvider" -Color $ThemeCyan }
        Write-UILog -Message "Arquivos na operação: $($FilesToProcess.Count)"
        if ($Choice -eq '3') {
            Write-UILog -Message "Sniper: $($FilesToProcess.Count) arquivo(s) selecionado(s) em modo manual." -Color $ThemeCyan
            if ($unselectedFiles.Count -gt 0) {
                Write-UILog -Message "Sniper: $($unselectedFiles.Count) arquivo(s) não selecionado(s) serão anexados em modo Bundler." -Color $ThemeCyan
            }
        }
        Write-UILog -Message "Geração com IA: $(if ($SendToAI) { if ($currentAIPromptMode -eq 'custom') { 'Personalizado' } else { 'Padrão' } } else { 'Desabilitado' })"
        Write-UILog -Message "Fluxo final: $(if ($currentAIFlowMode -eq 'executor') { 'Direto para Executor' } else { 'Via Diretor' })"

        $HeaderContent = Get-ProtocolHeaderContent -RouteMode $currentAIFlowMode -BundleChoice $Choice -ExecutorTargetValue $ExecutorTarget
        $FinalContent = $HeaderContent + "`n`n"
        $BlueprintIssues = @()

        if ($Choice -eq '1' -or $Choice -eq '3') {
            if ($Choice -eq '1') {
                $OutputFile   = Add-OutputRoutePrefixToFileName -FileName "_COPIAR_TUDO__${ProjectName}.md" -RouteMode $currentAIFlowMode
                $HeaderTitle  = "MODO COPIAR TUDO"
                Write-UILog -Message "Iniciando Modo Copiar Tudo..." -Color $ThemeCyan
            } else {
                $OutputFile   = Add-OutputRoutePrefixToFileName -FileName "_MANUAL__${ProjectName}.md" -RouteMode $currentAIFlowMode
                $HeaderTitle  = "MODO MANUAL"
                Write-UILog -Message "Iniciando Modo Sniper / Manual..." -Color $ThemePink
            }

            $FinalContent += "## ${HeaderTitle}: $ProjectName`n`n"

            if ($Choice -eq '3') {
                $FinalContent += "### 0. ANALYSIS SCOPE`n" + '```text' + "`n"
                $FinalContent += "ESCOPO: FECHADO / PARCIAL`n"
                $FinalContent += "Este bundle contém os arquivos selecionados manualmente pelo usuário.`n"
                if ($unselectedFiles.Count -gt 0) {
                    $FinalContent += "Os arquivos não selecionados foram anexados ao final em modo Bundler como contexto complementar.`n"
                }
                $FinalContent += "Qualquer análise deve considerar exclusivamente o visível neste artefato.`n"
                $FinalContent += "É proibido inferir módulos, dependências ou comportamento não visíveis.`n"
                $FinalContent += "Quando faltar contexto, declarar: 'não visível no recorte enviado'.`n"
                $FinalContent += '```' + "`n`n"
            }

            Write-UILog -Message "Montando estrutura do projeto..."
            $FinalContent += "### 1. PROJECT STRUCTURE`n" + '```text' + "`n"
            foreach ($File in $FilesToProcess) { $FinalContent += (Resolve-Path -Path $File.FullName -Relative) + "`n" }
            $FinalContent += '```' + "`n`n"

            Write-UILog -Message "Lendo arquivos e consolidando conteúdo..."
            $FinalContent += "### 2. SOURCE FILES`n`n"

            foreach ($File in $FilesToProcess) {
                $RelPath = Resolve-Path -Path $File.FullName -Relative
                Write-UILog -Message "Lendo $RelPath"
                $Content = Get-Content $File.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                if ($Content) {
                    $Content = $Content -replace "(`r?`n){3,}", "`r`n`r`n"
                    $FinalContent += "#### File: $RelPath`n" + '```text' + "`n"
                    $FinalContent += $Content.TrimEnd() + "`n"
                    $FinalContent += '```' + "`n`n"
                }
            }

            if ($Choice -eq '3' -and $unselectedFiles.Count -gt 0) {
                Write-UILog -Message "Anexando arquivos não selecionados (modo Bundler)..." -Color $ThemeCyan
                $FinalContent += "## ARQUIVOS NÃO SELECIONADOS INSERIDOS EM MODO BUNDLER`n`n"
                $FinalContent += New-BundlerContractsBlock `
                    -Files $unselectedFiles `
                    -IssueCollector ([ref]$BlueprintIssues) `
                    -StructureHeading "### PROJECT STRUCTURE (BUNDLER)" `
                    -ContractsHeading "### CORE DOMAINS & CONTRACTS (BUNDLER)" `
                    -LogExtraction
            }
        } else {
            $OutputFile = Add-OutputRoutePrefixToFileName -FileName "_INTELIGENTE__${ProjectName}.md" -RouteMode $currentAIFlowMode
            Write-UILog -Message "Iniciando Modo Architect / Inteligente..." -Color $ThemeCyan
            $FinalContent += "## MODO INTELIGENTE: $ProjectName`n`n"
            $FinalContent += "### 1. TECH STACK`n"

            if (Test-Path "package.json") {
                Write-UILog -Message "Lendo package.json para tech stack..."
                $Pkg = Get-Content "package.json" | ConvertFrom-Json
                if ($Pkg.dependencies)    { $FinalContent += "* **Deps:** $(($Pkg.dependencies.PSObject.Properties.Name -join ', '))`n" }
                if ($Pkg.devDependencies) { $FinalContent += "* **Dev Deps:** $(($Pkg.devDependencies.PSObject.Properties.Name -join ', '))`n" }
            }

            $FinalContent += "`n"
            $FinalContent += New-BundlerContractsBlock `
                -Files $FilesToProcess `
                -IssueCollector ([ref]$BlueprintIssues) `
                -StructureHeading "### 2. PROJECT STRUCTURE" `
                -ContractsHeading "### 3. CORE DOMAINS & CONTRACTS" `
                -LogExtraction
        }

        Write-UILog -Message "Salvando artefato..."
        $OutputFullPath = Join-Path (Get-Location) $OutputFile
        $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($OutputFullPath, $FinalContent, $Utf8NoBom)

        $TokenEstimate = [math]::Round($FinalContent.Length / 4)

        try { $FinalContent | Set-Clipboard; $Copied = $true } catch { $Copied = $false }

        if ($BlueprintIssues -and $BlueprintIssues.Count -gt 0) {
            Write-UILog -Message "Artefato gerado com $($BlueprintIssues.Count) aviso(s)." -Color $ThemePink
            foreach ($Issue in ($BlueprintIssues | Select-Object -First 10)) { Write-UILog -Message $Issue -Color $ThemePink }
        } else {
            Write-UILog -Message "Artefato consolidado com sucesso." -Color $ThemeSuccess
        }

        $ModoNome = if ($Choice -eq '1') { "Copiar Tudo" } elseif ($Choice -eq '2') { "Inteligente" } else { "Manual" }
        Write-UILog -Message "Modo: $ModoNome  ·  Executor: $ExecutorTarget"
        Write-UILog -Message "Arquivo: $OutputFile"
        Write-UILog -Message "Tokens estimados: ~$(Format-TokenCount -Tokens $TokenEstimate)"

        if ($Copied) { Write-UILog -Message "Bundle copiado para a área de transferência." -Color $ThemeCyan }
        else         { Write-UILog -Message "Arquivo salvo. Clipboard indisponível." -Color $ThemePink }

        if ($SendToAI) {
            Write-UILog -Message "Chamando agente de IA..." -Color $ThemeCyan
            Write-UILog -Message "Provider primário: $AIProvider | fallback automático ativo." -Color $ThemeCyan

            if ($currentAIPromptMode -eq "custom") {
                $CustomSystemPromptFilePath = Join-Path ([System.IO.Path]::GetTempPath()) ("vibetoolkit-custom-sp-" + [System.Guid]::NewGuid().ToString("N") + ".txt")
                [System.IO.File]::WriteAllText($CustomSystemPromptFilePath, $txtCustomSystemPrompt.Text, (New-Object System.Text.UTF8Encoding $false))
                Write-UILog -Message "Modo personalizado: systemPrompt do HUD será enviado para a IA." -Color $ThemePink
            } else {
                Write-UILog -Message "Modo padrão: usando fluxo nativo configurado no agente." -Color $ThemeCyan
            }

            if ($currentAIFlowMode -eq "executor") {
                Write-UILog -Message "Fluxo direto para executor ativo." -Color $ThemePink
            } else {
                Write-UILog -Message "Fluxo via Diretor ativo." -Color $ThemeCyan
            }

            $AgentScript = Join-Path $ToolkitDir "groq-agent.ts"
            $BundleMode  = if ($Choice -eq '1') { 'full' } elseif ($Choice -eq '2') { 'blueprint' } else { 'manual' }

            $AgentResult = Invoke-OrchestratorAgent `
                -AgentScriptPath $AgentScript `
                -BundlePath $OutputFullPath `
                -ProjectNameValue $ProjectName `
                -ExecutorTargetValue $ExecutorTarget `
                -BundleModeValue $BundleMode `
                -PrimaryProviderValue $AIProvider `
                -OutputRouteModeValue $currentAIFlowMode `
                -CustomSystemPromptFilePath $CustomSystemPromptFilePath `
                -ExtractionModeValue $BundleMode

            $FinalPromptPath = $null
            if ($AgentResult -and $AgentResult.OutputPath -and (Test-Path $AgentResult.OutputPath)) {
                $FinalPromptPath = $AgentResult.OutputPath
            } else {
                $bundleParent = Split-Path $OutputFullPath -Parent
                $candidateContextPaths = @(
                    (Join-Path $bundleParent (Get-AIContextOutputFileName -ProjectNameValue $ProjectName -RouteMode $currentAIFlowMode)),
                    (Join-Path $bundleParent "_AI_CONTEXT_${ProjectName}.md")
                )
                foreach ($cp in $candidateContextPaths) {
                    if (Test-Path $cp) { $FinalPromptPath = $cp; break }
                }
            }

            if ($FinalPromptPath) {
                $FinalSummarizedContent = Get-Content $FinalPromptPath -Raw -Encoding UTF8
                try {
                    $FinalSummarizedContent | Set-Clipboard
                    Write-UILog -Message "Prompt final preparado e copiado para o clipboard." -Color $ThemeSuccess
                } catch {
                    Write-UILog -Message "Prompt final gerado, mas clipboard indisponível." -Color $ThemePink
                }
            } else {
                Write-UILog -Message "Arquivo final da IA não foi localizado." -Color $ThemePink
            }

            if ($AgentResult -and $AgentResult.WinnerProvider) {
                Write-UILog -Message "Provider efetivo: $($AgentResult.WinnerProvider) | Modelo: $($AgentResult.WinnerModel)" -Color $ThemeSuccess
            }

            Write-UILog -Message "$(if ($currentAIFlowMode -eq 'executor') { 'Agora é só colar no seu executor.' } else { 'Agora é só colar no seu orquestrador.' })" -Color $ThemeCyan
        } else {
            Write-UILog -Message "Execução concluída sem chamada da IA." -Color $ThemeSuccess
        }
    } catch {
        Write-UILog -Message $_.Exception.Message -Color $ThemePink
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message, "Falha na execução",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    } finally {
        if ($CustomSystemPromptFilePath -and (Test-Path $CustomSystemPromptFilePath)) {
            Remove-Item $CustomSystemPromptFilePath -Force -ErrorAction SilentlyContinue
        }
        Set-UiBusy -Busy $false
    }
})

# ══════════════════════════════════════════════════════════════════
# BOOT
# ══════════════════════════════════════════════════════════════════
Update-StatusBar
Write-UILog -Message "Pronto. Configure o modo, o executor e energize." -Color $ThemeCyan
[void]$form.ShowDialog()
```

#### File: .\README.md
```text
# 🚀 VibeToolkit
**AI Context Synthesizer & Execution Director**

O **VibeToolkit** é uma suite de infraestrutura para IA focada em transformar bases de código brutas em um **Bundle de Contexto Estruturado**. Ele resolve o problema da "falta de contexto" ao preparar uma **Source of Truth** (Fonte de Verdade) blindada para orquestradores (ChatGPT, Gemini, Claude) que atuam como **Diretores** para executores agênticos (**AI Studio Apps** ou **Antigravity**).

---

## 💎 O Conceito de "Vibe"
O toolkit não apenas "copia arquivos", ele extrai a **vibe** (arquitetura, padrões, intenções e contratos) do projeto. O output final não é apenas código, mas um documento meta-analítico que ensina a IA subsequente a agir como um Diretor Técnico do seu projeto.

---

## ✨ Principais Recursos

### 🎨 HUD de Controle Visual
Interface nativa em WinForms (HUD) que centraliza toda a operação. Zero CLI para o fluxo diário, focado em produtividade máxima.

### 🛡️ Smart Chain Multi-Provider (Fallback Dinâmico)
Sistema resiliente de requisições:
1.  **Ordem:** Groq → Gemini → OpenAI → Anthropic.
2.  **Fallback Automático:** Se um provider atingir Rate Limit ou estiver offline, o agente pula para o próximo da cadeia sem perder o progresso.
3.  **Monitoramento:** Logs em tempo real de latência e saúde de cada provider.

### 🎯 Modos de Extração Cirúrgica
*   **🔵 Full Vibe:** Contexto integral. Ideal para análise de bugs complexos.
*   **🟠 Architect:** Apenas estruturas, assinaturas e contratos. Economia agressiva de tokens.
*   **🔴 Sniper Mode:** Seleção granular de arquivos via checklist visual para correções focadas.

### 🧩 Integração Nativa (Right-Click Magic)
Acesso instantâneo via **Menu de Contexto do Windows**. Clique com o botão direito em qualquer pasta para iniciar o "Vibing" sem abrir terminais.

### 🧠 Custom System Prompts
Controle total sobre a geração. Permite injetar instruções específicas (ex: "Foque apenas em refatorar para Hooks" ou "Analise performance de SQL") diretamente na orquestração da IA.

---

## 📂 Estrutura do Ecossistema

-   `project-bundler.ps1`: O núcleo do HUD e lógica de bundling (PowerShell).
-   `groq-agent.ts`: O motor de IA que estrutura o documento e gerencia os providers.
-   `install-vibe-menu.reg`: Script de registro para integração com o Windows Explorer.
-   `run-vibe-toolkit.vbs`: Helper para execução silenciosa e suave.
-   `.env`: Centralização secreta e segura de credenciais de API.

---

## ⚙️ Configuração Rápida

### 1. Requisitos
-   [Node.js](https://nodejs.org/) instalado.
-   [PowerShell 7](https://github.com/PowerShell/PowerShell) (Recomendado para melhor performance).

### 2. Instale as Dependências
```bash
npm install
```

### 3. Credenciais (`.env`)
Clone o `.env.example` para `.env` e preencha suas chaves:
```env
# API Keys (Mínimo uma necessária para o chain funcionar)
GROQ_API_KEY=gsk_...
GEMINI_API_KEY=...
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Modelos (Padrões otimizados)
GROQ_MODEL=llama-3.3-70b-versatile
GEMINI_MODEL=gemini-1.5-pro
OPENAI_MODEL=gpt-4o
ANTHROPIC_MODEL=claude-3-5-sonnet-20240620
```

### 4. Instale o Menu de Contexto (Opcional)
Execute o arquivo `install-vibe-menu.reg` para adicionar o "Vibe AI" ao botão direito do seu Windows.

---

## 🚀 Como Usar

### Fluxo Padrão (HUD)
1.  Clique com o botão direito na pasta do projeto e escolha **"Gerar Blueprint / Contexto (Vibe AI)"**.
2.  No HUD, escolha o **Modo de Extração** (Sniper se for algo específico).
3.  Selecione o **Executor Alvo** (Onde você vai colar o prompt).
4.  Clique em **ENERGIZE**.
5.  O bundle estruturado será copiado para o seu clipboard!

### Versão CLI (Deep Integration)
Se quiser rodar puramente via script:
```powershell
.\project-bundler.ps1 -Path "C:\caminho\do\meu\projeto"
```

---

## 🧠 Princípios de Engenharia
*   **Predictability:** Markdown padronizado para evitar alucinações de interpretadores de prompt.
*   **Resilience:** Failover de infraestrutura em nível de API.
*   **Tokens-Efficiency:** Estratégias de blueprint para reduzir custos e aumentar a janela de contexto.
*   **Local-First:** Leitura de arquivos local e segura.

---
*VibeToolkit © 2026 - Engineered for the Agentic Era*
```

#### File: .\tsconfig.json
```text
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "CommonJS",
    "moduleResolution": "node",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "./dist"
  },
  "include": ["**/*.ts"],
  "exclude": ["node_modules"]
}
```

