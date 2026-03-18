import * as dotenv from "dotenv";
import { promises as fs } from "fs";
import * as path from "path";

// Prioriza o .env na raiz da execução, permitindo override opcional do diretório do script
dotenv.config({ path: path.resolve(process.cwd(), ".env"), quiet: true });
dotenv.config({ path: path.resolve(__dirname, ".env"), quiet: true, override: false });

// --- TYPES & INTERFACES ---
type ProviderId = "groq" | "gemini" | "openai" | "anthropic";

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

// --- LOGGING SYSTEM ---
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

// --- UTILS ---
function getEnvValue(...keys: string[]): string | null {
    for (const key of keys) {
        const value = process.env[key]?.trim();
        if (value) return value;
    }
    return null;
}

function shouldFallback(status: number | null): boolean {
    if (status === null) return true;
    // Fallback em erros de autenticação (401), limite (429) ou erro interno (5xx)
    return [400, 401, 402, 403, 404, 408, 409, 422, 429, 500, 502, 503, 504].includes(status);
}

function normalizePrimaryProvider(input?: string): ProviderId {
    const value = (input || "groq").trim().toLowerCase();
    if (value === "groq" || value === "gemini" || value === "openai" || value === "anthropic") {
        return value;
    }
    return "groq";
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
            return json?.error?.message || json?.error || json?.message || JSON.stringify(json);
        }
        return (await response.text()).trim() || response.statusText;
    } catch {
        return response.statusText || "Falha sem corpo de erro.";
    }
}

// --- PROVIDER REQUEST HANDLERS ---
async function requestGroq(config: ProviderConfig, params: GenerateRequestParams): Promise<ProviderAttemptResult> {
    if (!config.apiKey) throw new ProviderRequestError(config.id, "Chave Groq ausente.", null, "Defina GROQ_API_KEY.", true);

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${config.apiKey}` },
        body: JSON.stringify({
            model: params.model,
            temperature: params.temperature ?? 0.1,
            max_tokens: params.maxTokens ?? 8192,
            messages: [{ role: "system", content: params.systemContent }, { role: "user", content: params.userPrompt }],
        }),
    });

    if (!response.ok) throw new ProviderRequestError(config.id, "Erro Groq", response.status, await parseErrorResponse(response), shouldFallback(response.status));
    const json = await response.json();
    return { provider: config.id, model: params.model, content: json?.choices?.[0]?.message?.content ?? null };
}

async function requestGemini(config: ProviderConfig, params: GenerateRequestParams): Promise<ProviderAttemptResult> {
    if (!config.apiKey) throw new ProviderRequestError(config.id, "Chave Gemini ausente.", null, "Defina GEMINI_API_KEY.", true);

    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(params.model)}:generateContent`;
    const response = await fetch(endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-goog-api-key": config.apiKey },
        body: JSON.stringify({
            system_instruction: { parts: [{ text: params.systemContent }] },
            contents: [{ role: "user", parts: [{ text: params.userPrompt }] }],
            generationConfig: { temperature: params.temperature ?? 0.1, maxOutputTokens: params.maxTokens ?? 8192 },
        }),
    });

    if (!response.ok) throw new ProviderRequestError(config.id, "Erro Gemini", response.status, await parseErrorResponse(response), shouldFallback(response.status));
    const json = await response.json();
    const content = json?.candidates?.[0]?.content?.parts?.map((p: any) => p.text).join("") || null;
    return { provider: config.id, model: params.model, content };
}

async function requestOpenAI(config: ProviderConfig, params: GenerateRequestParams): Promise<ProviderAttemptResult> {
    if (!config.apiKey) throw new ProviderRequestError(config.id, "Chave OpenAI ausente.", null, "Defina OPENAI_API_KEY.", true);

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${config.apiKey}` },
        body: JSON.stringify({
            model: params.model,
            temperature: params.temperature ?? 0.1,
            messages: [{ role: "system", content: params.systemContent }, { role: "user", content: params.userPrompt }],
        }),
    });

    if (!response.ok) throw new ProviderRequestError(config.id, "Erro OpenAI", response.status, await parseErrorResponse(response), shouldFallback(response.status));
    const json = await response.json();
    return { provider: config.id, model: params.model, content: json?.choices?.[0]?.message?.content ?? null };
}

async function requestAnthropic(config: ProviderConfig, params: GenerateRequestParams): Promise<ProviderAttemptResult> {
    if (!config.apiKey) throw new ProviderRequestError(config.id, "Chave Anthropic ausente.", null, "Defina ANTHROPIC_API_KEY.", true);

    const response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-api-key": config.apiKey, "anthropic-version": "2023-06-01" },
        body: JSON.stringify({
            model: params.model,
            max_tokens: params.maxTokens ?? 8192,
            system: params.systemContent,
            messages: [{ role: "user", content: params.userPrompt }],
        }),
    });

    if (!response.ok) throw new ProviderRequestError(config.id, "Erro Anthropic", response.status, await parseErrorResponse(response), shouldFallback(response.status));
    const json = await response.json();
    const content = json?.content?.filter((i: any) => i.type === "text").map((i: any) => i.text).join("") || null;
    return { provider: config.id, model: params.model, content };
}

async function requestWithProvider(provider: ProviderId, params: GenerateRequestParams): Promise<ProviderAttemptResult> {
    const config = getProviderConfig(provider);
    switch (provider) {
        case "groq": return requestGroq(config, params);
        case "gemini": return requestGemini(config, params);
        case "openai": return requestOpenAI(config, params);
        case "anthropic": return requestAnthropic(config, params);
    }
}

// --- CORE ENGINE ---
async function generateContextDocument(params: Omit<GenerateRequestParams, "model">, primaryProvider: ProviderId): Promise<ProviderAttemptResult | null> {
    const providerChain = buildProviderChain(primaryProvider);
    const errors: string[] = [];

    logger.info(`Provider primário: ${primaryProvider} | Fallback: ${providerChain.join(" -> ")}`);

    for (const provider of providerChain) {
        try {
            const config = getProviderConfig(provider);
            logger.info(`Tentando ${config.displayName} (${config.model})...`);
            const result = await requestWithProvider(provider, { ...params, model: config.model });

            if (!result.content) throw new ProviderRequestError(provider, "Resposta vazia.", null, "", true);
            return result;
        } catch (error) {
            logger.error(`Falha no provider ${provider}`, error);
            if (error instanceof ProviderRequestError && !error.retryable) break;
        }
    }
    return null;
}

function normalizeSourceDump(content: string): string {
    return content.replace(/\r\n/g, "\n").replace(/\u0000/g, "").trim();
}

async function main() {
    const [bundlePath, projectName, executorTarget, bundleMode = "full", selectedProvider = "groq"] = process.argv.slice(2);
    if (!bundlePath || !executorTarget) process.exit(1);

    const absolutePath = path.resolve(process.cwd(), bundlePath);
    const sourceCodeDump = normalizeSourceDump(await fs.readFile(absolutePath, "utf-8"));
    const isManual = bundleMode === "manual" || path.basename(absolutePath).startsWith("_MANUAL__");

    const systemPrompt = isManual
        ? `Você é um ENGENHEIRO DE SOFTWARE SÊNIOR E ARQUITETO DE IA. Gere um DOCUMENTO DE CONTEXTO TÉCNICO (Source of Truth) para um RECORTE PARCIAL do projeto em ${executorTarget}. Mapeie apenas o que está visível.`
        : `Você é um ENGENHEIRO DE SOFTWARE SÊNIOR E ARQUITETO DE IA. Gere um DOCUMENTO DE CONTEXTO TÉCNICO (Source of Truth) completo para o projeto em ${executorTarget}.`;

    const userPrompt = `${isManual ? "Analise este recorte parcial" : "Analise o projeto"} '${projectName}':\n\n${sourceCodeDump}`;

    const result = await generateContextDocument({ systemContent: systemPrompt, userPrompt, temperature: 0.1, maxTokens: 8192 }, normalizePrimaryProvider(selectedProvider));

    if (!result?.content) process.exit(1);

    const outputPath = path.resolve(path.dirname(absolutePath), `_AI_CONTEXT_${projectName}.md`);
    const header = `> # DOCUMENTO DE CONTEXTO TÉCNICO\n> Fonte da Verdade (Source of Truth)${isManual ? " do recorte" : ""}.\n\n`;

    await fs.writeFile(outputPath, `${header}${result.content}\n\n---\n\n# ESTRUTURA E CÓDIGO\n${sourceCodeDump}`, "utf-8");
    logger.info(`Contexto gerado via ${result.provider} em: _AI_CONTEXT_${projectName}.md`);
}

main().catch(err => { logger.error("Falha fatal", err); process.exit(1); });