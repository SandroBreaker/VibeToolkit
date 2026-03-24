import "dotenv/config";
import fs from "fs/promises";
import path from "path";
import process from "process";

type OutputRouteMode = "director" | "executor";
type ExtractionMode = "full" | "blueprint" | "sniper";
type DocumentMode = "full" | "manual";
type ProviderName = "groq" | "gemini" | "openai" | "anthropic";
type PromptMode = "default" | "template" | "expertOverride";

type PromptDepth = "normal" | "deep" | "max";
type PromptTone = "technical" | "surgical" | "assertive";

interface PromptCustomizationConfig {
    promptMode: PromptMode;
    templateId: string | null;
    objective: string | null;
    deliveryType: string | null;
    focusTags: string[];
    constraints: string[];
    depth: PromptDepth;
    tone: PromptTone;
    additionalInstructions: string | null;
    expertSystemPrompt: string | null;
}

interface PromptTemplatePreset {
    id: string;
    label: string;
    allowedRouteModes: OutputRouteMode[];
    allowedExtractionModes: ExtractionMode[];
    objective: string;
    deliveryType: string;
    focusTags: string[];
    constraints: string[];
    systemDelta: string;
    userDelta: string;
}

interface ExecutionMeta {
    projectName: string;
    sourceArtifact: string;
    executorTarget: string;
    routeMode: OutputRouteMode;
    generatedAt: string;
}

interface CommonSections {
    task: string;
    objective: string;
    scope: string[];
    constraints: string[];
    acceptanceCriteria: string[];
}

interface DirectorSections extends CommonSections {
    technicalContext: string[];
    technicalChecklist: string[];
    executionPlan: string[];
    implementationNotes: string[];
}

interface ExecutorSections extends CommonSections {
    targetFiles: string[];
    implementationRules: string[];
    deliveryFormat: string[];
    implementationNotes: string[];
}

interface DirectorStructuredOutput {
    routeMode: "director";
    documentMode: DocumentMode;
    executionMeta: ExecutionMeta;
    sections: DirectorSections;
}

interface ExecutorStructuredOutput {
    routeMode: "executor";
    documentMode: DocumentMode;
    executionMeta: ExecutionMeta;
    sections: ExecutorSections;
}

type StructuredOutputDocument = DirectorStructuredOutput | ExecutorStructuredOutput;

interface ProviderRequestPayload {
    systemPrompt: string;
    userPrompt: string;
    model?: string;
}

interface ProviderResponse {
    provider: ProviderName;
    model: string;
    content: string;
}

interface AIClient {
    readonly name: ProviderName;
    request(payload: ProviderRequestPayload): Promise<ProviderResponse>;
}

interface BuildAugmentedPromptBundleParams {
    projectName: string;
    technicalBundleDump: string;
    executorTarget: string;
    routeMode: OutputRouteMode;
    mode: DocumentMode;
    extractionMode: ExtractionMode;
    promptConfig: PromptCustomizationConfig;
}

type ProviderErrorType = "AUTH_ERROR" | "RATE_LIMIT" | "NETWORK_ERROR" | "PARSE_ERROR" | "PROVIDER_DOWN" | "CONFIG_ERROR";

class AgentRuntimeError extends Error {
    readonly status: number;
    readonly details?: string;
    readonly retryable: boolean;
    readonly errorType?: ProviderErrorType;

    constructor(message: string, options?: { status?: number; details?: string; retryable?: boolean; errorType?: ProviderErrorType }) {
        super(message);
        this.name = "AgentRuntimeError";
        this.status = options?.status ?? 500;
        this.details = options?.details;
        this.retryable = options?.retryable ?? false;
        this.errorType = options?.errorType;
    }
}

const PROMPT_TEMPLATE_REGISTRY: Record<string, PromptTemplatePreset> = {
    "director.full.diagnostic": {
        id: "director.full.diagnostic",
        label: "Director · Diagnostic",
        allowedRouteModes: ["director"],
        allowedExtractionModes: ["full", "blueprint", "sniper"],
        objective: "Produzir diagnóstico técnico com causa raiz, evidências, riscos e critérios de aceitação claros.",
        deliveryType: "Especificação diagnóstica guiada para Diretor",
        focusTags: ["root-cause", "logs", "contracts", "regression"],
        constraints: [
            "Não alterar o envelope estrutural obrigatório.",
            "Não inferir fatos fora do bundle.",
            "Priorizar evidência, causalidade e riscos operacionais."
        ],
        systemDelta: [
            "Especialização operacional ativa: diagnóstico técnico via Diretor.",
            "Aprofunde causalidade, evidências observáveis, riscos de regressão e critérios de aceitação.",
            "Mantenha intacto o schema JSON, routeMode, extractionMode, parse e repair do pipeline."
        ].join("\n"),
        userDelta: [
            "Template operacional: diagnóstico técnico.",
            "Priorizar causa raiz, sintomas, impactos, riscos e validações objetivas."
        ].join("\n")
    },
    "director.full.feature-planning": {
        id: "director.full.feature-planning",
        label: "Director · Feature Planning",
        allowedRouteModes: ["director"],
        allowedExtractionModes: ["full", "blueprint"],
        objective: "Planejar implementação de feature com escopo, dependências, riscos e estratégia de entrega.",
        deliveryType: "Planejamento operacional para Diretor",
        focusTags: ["feature-scope", "dependencies", "contracts", "delivery-plan"],
        constraints: [
            "Não implementar código diretamente.",
            "Preservar contratos existentes.",
            "Não criar fluxo executor no lugar do Diretor."
        ],
        systemDelta: [
            "Especialização operacional ativa: feature planning via Diretor.",
            "Priorize escopo, dependências, contratos tocados, riscos e decomposição executável.",
            "Mantenha intacto o envelope estrutural obrigatório."
        ].join("\n"),
        userDelta: [
            "Template operacional: planejamento de feature.",
            "Destacar etapas, dependências, riscos e estratégia incremental."
        ].join("\n")
    },
    "director.full.architecture-review": {
        id: "director.full.architecture-review",
        label: "Director · Architecture Review",
        allowedRouteModes: ["director"],
        allowedExtractionModes: ["full", "blueprint"],
        objective: "Avaliar arquitetura visível, contratos, acoplamentos e pontos críticos do projeto.",
        deliveryType: "Review arquitetural para Diretor",
        focusTags: ["architecture", "boundaries", "contracts", "coupling"],
        constraints: [
            "Não inventar módulos não visíveis.",
            "Preservar routeMode e extractionMode ativos.",
            "Não desligar validação estrutural."
        ],
        systemDelta: [
            "Especialização operacional ativa: architecture review via Diretor.",
            "Aprofunde limites, contratos, organização, acoplamentos e riscos sistêmicos.",
            "Mantenha JSON, schema, parse e repair intactos."
        ].join("\n"),
        userDelta: [
            "Template operacional: revisão arquitetural.",
            "Priorizar topologia, fronteiras, contratos e impacto sistêmico."
        ].join("\n")
    },
    "director.full.hardening": {
        id: "director.full.hardening",
        label: "Director · Hardening",
        allowedRouteModes: ["director"],
        allowedExtractionModes: ["full", "blueprint", "sniper"],
        objective: "Preparar hardening técnico com foco em segurança, robustez e resiliência operacional.",
        deliveryType: "Plano de hardening para Diretor",
        focusTags: ["hardening", "security", "resilience", "regression"],
        constraints: [
            "Não inferir superfícies não documentadas.",
            "Não trocar o papel do Diretor.",
            "Não alterar o schema obrigatório."
        ],
        systemDelta: [
            "Especialização operacional ativa: hardening via Diretor.",
            "Priorize robustez, segurança, fail-safe, riscos e cuidados operacionais.",
            "Mantenha o pipeline estruturado integralmente ativo."
        ].join("\n"),
        userDelta: [
            "Template operacional: hardening.",
            "Mapear riscos, fragilidades, guardrails e critérios de endurecimento."
        ].join("\n")
    },
    "executor.full.surgical-patch": {
        id: "executor.full.surgical-patch",
        label: "Executor · Surgical Patch",
        allowedRouteModes: ["executor"],
        allowedExtractionModes: ["full"],
        objective: "Preparar execução cirúrgica com mínimo impacto colateral e preservação rígida de contratos.",
        deliveryType: "Contexto técnico para patch cirúrgico",
        focusTags: ["minimal-scope", "contracts", "safety", "bugfix"],
        constraints: [
            "Alterar somente o escopo pedido.",
            "Preservar nomes, contratos e comportamento existente.",
            "Não criar papel de Diretor."
        ],
        systemDelta: [
            "Especialização operacional ativa: patch cirúrgico via Executor.",
            "Minimize diff, preserve contratos e trate falhas explicitamente.",
            "Entregue instruções objetivas e implementáveis."
        ].join("\n"),
        userDelta: [
            "Template operacional: patch cirúrgico.",
            "Priorize alteração mínima, arquivos tocados e critérios claros de validação."
        ].join("\n")
    },
    "executor.full.feature-implementation": {
        id: "executor.full.feature-implementation",
        label: "Executor · Feature Implementation",
        allowedRouteModes: ["executor"],
        allowedExtractionModes: ["full"],
        objective: "Preparar implementação completa de feature com integração consistente ao projeto visível.",
        deliveryType: "Contexto técnico para implementação de feature",
        focusTags: ["feature", "integration", "contracts", "delivery"],
        constraints: [
            "Respeitar stack e padrões existentes.",
            "Não extrapolar o bundle visível.",
            "Não gerar papel de Diretor."
        ],
        systemDelta: [
            "Especialização operacional ativa: feature implementation via Executor.",
            "Planeje arquivos tocados, contratos, dependências e passos de entrega prontos para codificação.",
            "Preserve compatibilidade com o projeto existente."
        ].join("\n"),
        userDelta: [
            "Template operacional: implementação de feature.",
            "Destacar arquivos alvo, integrações, contratos e riscos de regressão."
        ].join("\n")
    },
    "executor.full.safe-refactor": {
        id: "executor.full.safe-refactor",
        label: "Executor · Safe Refactor",
        allowedRouteModes: ["executor"],
        allowedExtractionModes: ["full"],
        objective: "Preparar refatoração segura com preservação comportamental, redução de dívida e mínimo risco.",
        deliveryType: "Contexto técnico para refatoração segura",
        focusTags: ["refactor", "behavior-preservation", "clarity", "safety"],
        constraints: [
            "Preservar comportamento observável.",
            "Não quebrar contratos públicos.",
            "Não atuar como Diretor."
        ],
        systemDelta: [
            "Especialização operacional ativa: safe refactor via Executor.",
            "Priorize preservação comportamental, diffs controlados e risco baixo.",
            "Mapeie claramente arquivos e contratos tocados."
        ].join("\n"),
        userDelta: [
            "Template operacional: refatoração segura.",
            "Destacar invariantes, contratos preservados e plano de alteração controlado."
        ].join("\n")
    },
    "executor.full.regression-fix": {
        id: "executor.full.regression-fix",
        label: "Executor · Regression Fix",
        allowedRouteModes: ["executor"],
        allowedExtractionModes: ["full"],
        objective: "Preparar correção de regressão com foco em restauração de comportamento, causa provável e blindagem futura.",
        deliveryType: "Contexto técnico para correção de regressão",
        focusTags: ["regression", "bugfix", "root-cause", "safety"],
        constraints: [
            "Corrigir sem ampliar escopo desnecessariamente.",
            "Preservar contratos existentes.",
            "Não introduzir papel de Diretor."
        ],
        systemDelta: [
            "Especialização operacional ativa: regression fix via Executor.",
            "Aponte causa provável, superfície tocada, risco de recaída e validação objetiva.",
            "Entregue instruções prontas para execução técnica."
        ].join("\n"),
        userDelta: [
            "Template operacional: correção de regressão.",
            "Priorize causa provável, arquivos tocados, proteção contra recaída e validação."
        ].join("\n")
    }
};

function normalizeProviderName(value: string | undefined | null): ProviderName {
    switch ((value ?? "").trim().toLowerCase()) {
        case "groq":
            return "groq";
        case "gemini":
            return "gemini";
        case "openai":
            return "openai";
        case "anthropic":
            return "anthropic";
        default:
            return "groq";
    }
}

function normalizeOutputRouteMode(value: string | undefined | null): OutputRouteMode {
    const normalized = (value ?? "").trim().toLowerCase();
    return normalized === "executor" ? "executor" : "director";
}

function normalizeExtractionMode(value: string | undefined | null, fileName: string): ExtractionMode {
    const normalized = (value ?? "").trim().toLowerCase();
    if (normalized === "blueprint" || normalized === "architect" || normalized === "inteligente") {
        return "blueprint";
    }
    if (normalized === "sniper" || normalized === "selective" || normalized === "manual") {
        return "sniper";
    }
    if (normalized === "full" || normalized === "copiar tudo" || normalized === "bundler") {
        return "full";
    }

    const normalizedFileName = fileName.toLowerCase();
    if (normalizedFileName.startsWith("_inteligente__") || normalizedFileName.startsWith("_blueprint__") || normalizedFileName.startsWith("_architect__")) {
        return "blueprint";
    }
    if (normalizedFileName.startsWith("_manual__") || normalizedFileName.startsWith("_selective__") || normalizedFileName.startsWith("_sniper__")) {
        return "sniper";
    }
    return "full";
}

function resolveDocumentModeFromExtractionMode(extractionMode: ExtractionMode): DocumentMode {
    return extractionMode === "sniper" ? "manual" : "full";
}

function parseCliArgs(argv: string[]): Record<string, string> {
    const args: Record<string, string> = {};
    for (let i = 0; i < argv.length; i += 1) {
        const token = argv[i];
        if (!token.startsWith("--")) {
            continue;
        }

        const key = token.slice(2);
        const next = argv[i + 1];
        if (!next || next.startsWith("--")) {
            args[key] = "true";
            continue;
        }

        args[key] = next;
        i += 1;
    }

    return args;
}

async function fileExists(filePath: string): Promise<boolean> {
    try {
        await fs.access(filePath);
        return true;
    } catch {
        return false;
    }
}

async function readTextFile(filePath: string): Promise<string> {
    return fs.readFile(filePath, "utf-8");
}

async function writeTextFile(filePath: string, content: string): Promise<void> {
    await fs.writeFile(filePath, content, "utf-8");
}

function safeJsonParse<T>(value: string, fallback: T): T {
    try {
        return JSON.parse(value) as T;
    } catch {
        return fallback;
    }
}

function getPromptTemplatePreset(templateId: string | null | undefined): PromptTemplatePreset | null {
    if (!templateId) {
        return null;
    }
    return PROMPT_TEMPLATE_REGISTRY[templateId] ?? null;
}

function normalizePromptDepth(value: unknown): PromptDepth {
    const normalized = typeof value === "string" ? value.trim().toLowerCase() : "";
    if (normalized === "deep") {
        return "deep";
    }
    if (normalized === "max" || normalized === "maximum") {
        return "max";
    }
    return "normal";
}

function normalizePromptTone(value: unknown): PromptTone {
    const normalized = typeof value === "string" ? value.trim().toLowerCase() : "";
    if (normalized === "surgical") {
        return "surgical";
    }
    if (normalized === "assertive") {
        return "assertive";
    }
    return "technical";
}

function sanitizeStringList(value: unknown): string[] {
    if (!Array.isArray(value)) {
        return [];
    }

    return value
        .map((item) => (typeof item === "string" ? item.trim() : ""))
        .filter((item) => item.length > 0);
}

function normalizePromptMode(value: unknown): PromptMode {
    const normalized = typeof value === "string" ? value.trim().toLowerCase() : "";
    if (normalized === "template") {
        return "template";
    }
    if (normalized === "expertoverride" || normalized === "expert_override" || normalized === "expert-override") {
        return "expertOverride";
    }
    return "default";
}

function buildDefaultPromptCustomizationConfig(
    routeMode: OutputRouteMode,
    extractionMode: ExtractionMode,
    executorTarget: string
): PromptCustomizationConfig {
    const objective =
        routeMode === "director"
            ? "Gerar documento técnico estruturado de alto sinal para orientar o Executor."
            : "Gerar contexto técnico estruturado pronto para implementação direta.";

    const deliveryType =
        routeMode === "director"
            ? "Especificação operacional estruturada para Diretor"
            : `Especificação operacional estruturada para Executor (${executorTarget})`;

    const baseConstraints =
        routeMode === "director"
            ? [
                  "Não implementar código diretamente.",
                  "Não sair do bundle visível.",
                  "Preservar routeMode e extractionMode."
              ]
            : [
                  "Preservar contratos, nomes e comportamento existente.",
                  "Não extrapolar o bundle visível.",
                  "Não assumir papel de Diretor."
              ];

    const baseTags =
        routeMode === "director"
            ? ["director", extractionMode, "structured-output"]
            : ["executor", extractionMode, executorTarget.toLowerCase(), "structured-output"];

    return {
        promptMode: "default",
        templateId: null,
        objective,
        deliveryType,
        focusTags: baseTags,
        constraints: baseConstraints,
        depth: "normal",
        tone: "technical",
        additionalInstructions: null,
        expertSystemPrompt: null
    };
}

function sanitizePromptCustomizationConfig(
    raw: unknown,
    routeMode: OutputRouteMode,
    extractionMode: ExtractionMode,
    executorTarget: string
): PromptCustomizationConfig {
    const fallback = buildDefaultPromptCustomizationConfig(routeMode, extractionMode, executorTarget);

    if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
        return fallback;
    }

    const candidate = raw as Record<string, unknown>;
    const promptMode = normalizePromptMode(candidate.promptMode);
    const templateId = typeof candidate.templateId === "string" && candidate.templateId.trim().length > 0 ? candidate.templateId.trim() : null;
    const objective = typeof candidate.objective === "string" && candidate.objective.trim().length > 0 ? candidate.objective.trim() : null;
    const deliveryType =
        typeof candidate.deliveryType === "string" && candidate.deliveryType.trim().length > 0
            ? candidate.deliveryType.trim()
            : null;
    const focusTags = sanitizeStringList(candidate.focusTags);
    const constraints = sanitizeStringList(candidate.constraints);
    const depth = normalizePromptDepth(candidate.depth);
    const tone = normalizePromptTone(candidate.tone);
    const additionalInstructions =
        typeof candidate.additionalInstructions === "string" && candidate.additionalInstructions.trim().length > 0
            ? candidate.additionalInstructions.trim()
            : null;
    const expertSystemPrompt =
        typeof candidate.expertSystemPrompt === "string" && candidate.expertSystemPrompt.trim().length > 0
            ? candidate.expertSystemPrompt.trim()
            : null;

    const config: PromptCustomizationConfig = {
        promptMode,
        templateId,
        objective: objective ?? fallback.objective,
        deliveryType: deliveryType ?? fallback.deliveryType,
        focusTags: focusTags.length > 0 ? focusTags : fallback.focusTags,
        constraints: constraints.length > 0 ? constraints : fallback.constraints,
        depth,
        tone,
        additionalInstructions,
        expertSystemPrompt
    };

    if (config.promptMode === "template") {
        if (!config.templateId) {
            throw new Error("promptMode=template exige templateId.");
        }

        const preset = getPromptTemplatePreset(config.templateId);
        if (!preset) {
            throw new Error(`Template não encontrado: ${config.templateId}`);
        }

        if (!preset.allowedRouteModes.includes(routeMode)) {
            throw new Error(`Template incompatível com routeMode=${routeMode}: ${config.templateId}`);
        }

        if (!preset.allowedExtractionModes.includes(extractionMode)) {
            throw new Error(`Template incompatível com extractionMode=${extractionMode}: ${config.templateId}`);
        }
    }

    if (config.promptMode === "expertOverride" && !config.expertSystemPrompt) {
        throw new Error("promptMode=expertOverride exige expertSystemPrompt.");
    }

    if (config.promptMode === "default") {
        config.templateId = null;
        config.expertSystemPrompt = null;
    }

    return config;
}

async function readOptionalPromptConfig(
    promptConfigFilePath: string | undefined,
    routeMode: OutputRouteMode,
    extractionMode: ExtractionMode,
    executorTarget: string
): Promise<PromptCustomizationConfig> {
    if (!promptConfigFilePath || promptConfigFilePath.trim().length === 0) {
        return buildDefaultPromptCustomizationConfig(routeMode, extractionMode, executorTarget);
    }

    const absolutePath = path.resolve(promptConfigFilePath);
    if (!(await fileExists(absolutePath))) {
        return buildDefaultPromptCustomizationConfig(routeMode, extractionMode, executorTarget);
    }

    const raw = await readTextFile(absolutePath);
    if (raw.trim().length === 0) {
        return buildDefaultPromptCustomizationConfig(routeMode, extractionMode, executorTarget);
    }

    const parsed = safeJsonParse<unknown>(raw, null);
    if (!parsed) {
        return buildDefaultPromptCustomizationConfig(routeMode, extractionMode, executorTarget);
    }

    return sanitizePromptCustomizationConfig(parsed, routeMode, extractionMode, executorTarget);
}

function buildPromptCustomizationSystemLayer(
    routeMode: OutputRouteMode,
    extractionMode: ExtractionMode,
    promptConfig: PromptCustomizationConfig
): string {
    const layers: string[] = [
        "## CUSTOM PROMPT LAYER — STRICT ENFORCEMENT",
        `ROUTE_MODE_LOCK=${routeMode}`,
        `EXTRACTION_MODE_LOCK=${extractionMode}`,
        `PROMPT_MODE=${promptConfig.promptMode}`,
        `DEPTH=${promptConfig.depth}`,
        `TONE=${promptConfig.tone}`,
        "É proibido desligar JSON, schema obrigatório, parse estruturado, repair estruturado, routeMode ou extractionMode."
    ];

    if (promptConfig.objective) {
        layers.push(`OBJECTIVE_OVERRIDE=${promptConfig.objective}`);
    }

    if (promptConfig.deliveryType) {
        layers.push(`DELIVERY_TYPE_OVERRIDE=${promptConfig.deliveryType}`);
    }

    if (promptConfig.focusTags.length > 0) {
        layers.push(`FOCUS_TAGS=${promptConfig.focusTags.join(", ")}`);
    }

    if (promptConfig.constraints.length > 0) {
        layers.push("CONSTRAINT_OVERRIDES:");
        for (const item of promptConfig.constraints) {
            layers.push(`- ${item}`);
        }
    }

    if (promptConfig.promptMode === "template" && promptConfig.templateId) {
        const preset = getPromptTemplatePreset(promptConfig.templateId);
        if (preset) {
            layers.push(`TEMPLATE_ID=${preset.id}`);
            layers.push(`TEMPLATE_LABEL=${preset.label}`);
            layers.push("TEMPLATE_SYSTEM_DELTA_BEGIN");
            layers.push(preset.systemDelta);
            layers.push("TEMPLATE_SYSTEM_DELTA_END");
        }
    }

    if (promptConfig.additionalInstructions) {
        layers.push("ADDITIONAL_SYSTEM_GUIDANCE_BEGIN");
        layers.push(promptConfig.additionalInstructions);
        layers.push("ADDITIONAL_SYSTEM_GUIDANCE_END");
    }

    if (promptConfig.promptMode === "expertOverride" && promptConfig.expertSystemPrompt) {
        layers.push("EXPERT_SYSTEM_OVERRIDE_BEGIN");
        layers.push(promptConfig.expertSystemPrompt);
        layers.push("EXPERT_SYSTEM_OVERRIDE_END");
    }

    return layers.join("\n");
}

function buildPromptCustomizationUserLayer(promptConfig: PromptCustomizationConfig): string {
    const lines: string[] = ["## PROMPT CUSTOMIZATION CONTEXT"];

    if (promptConfig.objective) {
        lines.push(`- Objetivo focal: ${promptConfig.objective}`);
    }

    if (promptConfig.deliveryType) {
        lines.push(`- Entrega focal: ${promptConfig.deliveryType}`);
    }

    if (promptConfig.focusTags.length > 0) {
        lines.push(`- Tags de foco: ${promptConfig.focusTags.join(", ")}`);
    }

    if (promptConfig.constraints.length > 0) {
        lines.push("- Restrições adicionais:");
        for (const item of promptConfig.constraints) {
            lines.push(`  - ${item}`);
        }
    }

    if (promptConfig.promptMode === "template" && promptConfig.templateId) {
        const preset = getPromptTemplatePreset(promptConfig.templateId);
        if (preset) {
            lines.push(`- Template ativo: ${preset.label}`);
            if (preset.userDelta.trim().length > 0) {
                lines.push("- Especialização do template:");
                for (const row of preset.userDelta.split("\n")) {
                    lines.push(`  - ${row}`);
                }
            }
        }
    }

    if (promptConfig.additionalInstructions) {
        lines.push("- Instruções adicionais do operador:");
        for (const row of promptConfig.additionalInstructions.split("\n")) {
            lines.push(`  - ${row}`);
        }
    }

    lines.push(`- Profundidade desejada: ${promptConfig.depth}`);
    lines.push(`- Tom desejado: ${promptConfig.tone}`);

    return lines.join("\n");
}

function getCurrentTimestampIso(): string {
    return new Date().toISOString();
}

function normalizeWhitespace(value: string): string {
    return value.replace(/\r\n/g, "\n").trim();
}

function escapeMarkdown(value: string): string {
    return value.replace(/\\/g, "\\\\");
}

function ensureParagraphs(items: string[]): string[] {
    return items.map((item) => item.trim()).filter((item) => item.length > 0);
}

function dedupePreserveOrder(values: string[]): string[] {
    const seen = new Set<string>();
    const result: string[] = [];
    for (const value of values) {
        const normalized = value.trim();
        if (normalized.length === 0 || seen.has(normalized)) {
            continue;
        }
        seen.add(normalized);
        result.push(normalized);
    }
    return result;
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
    return Array.isArray(value) && value.every((item) => typeof item === "string");
}

function parseCommonSections(rawSections: Record<string, unknown>): CommonSections {
    const task = isNonEmptyString(rawSections.task) ? rawSections.task.trim() : "";
    const objective = isNonEmptyString(rawSections.objective) ? rawSections.objective.trim() : "";
    const scope = isStringArray(rawSections.scope) ? ensureParagraphs(rawSections.scope) : [];
    const constraints = isStringArray(rawSections.constraints) ? ensureParagraphs(rawSections.constraints) : [];
    const acceptanceCriteria = isStringArray(rawSections.acceptanceCriteria)
        ? ensureParagraphs(rawSections.acceptanceCriteria)
        : [];

    if (task.length === 0) {
        throw new AgentRuntimeError("Campo obrigatório ausente: sections.task", { status: 422 });
    }

    if (objective.length === 0) {
        throw new AgentRuntimeError("Campo obrigatório ausente: sections.objective", { status: 422 });
    }

    if (scope.length === 0) {
        throw new AgentRuntimeError("Campo obrigatório ausente: sections.scope", { status: 422 });
    }

    if (constraints.length === 0) {
        throw new AgentRuntimeError("Campo obrigatório ausente: sections.constraints", { status: 422 });
    }

    if (acceptanceCriteria.length === 0) {
        throw new AgentRuntimeError("Campo obrigatório ausente: sections.acceptanceCriteria", { status: 422 });
    }

    return {
        task,
        objective,
        scope,
        constraints,
        acceptanceCriteria
    };
}

function parseStructuredDocument(payload: unknown): StructuredOutputDocument {
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
        throw new AgentRuntimeError("Payload estruturado inválido: objeto raiz ausente.", { status: 422 });
    }

    const root = payload as Record<string, unknown>;
    const routeMode = root.routeMode;
    const documentMode = root.documentMode;
    const executionMeta = root.executionMeta;
    const sections = root.sections;

    if (routeMode !== "director" && routeMode !== "executor") {
        throw new AgentRuntimeError("Campo obrigatório inválido: routeMode", { status: 422 });
    }

    if (documentMode !== "full" && documentMode !== "manual") {
        throw new AgentRuntimeError("Campo obrigatório inválido: documentMode", { status: 422 });
    }

    if (!executionMeta || typeof executionMeta !== "object" || Array.isArray(executionMeta)) {
        throw new AgentRuntimeError("Campo obrigatório inválido: executionMeta", { status: 422 });
    }

    if (!sections || typeof sections !== "object" || Array.isArray(sections)) {
        throw new AgentRuntimeError("Campo obrigatório inválido: sections", { status: 422 });
    }

    const executionMetaRecord = executionMeta as Record<string, unknown>;
    const parsedExecutionMeta: ExecutionMeta = {
        projectName: isNonEmptyString(executionMetaRecord.projectName) ? executionMetaRecord.projectName.trim() : "",
        sourceArtifact: isNonEmptyString(executionMetaRecord.sourceArtifact)
            ? executionMetaRecord.sourceArtifact.trim()
            : "",
        executorTarget: isNonEmptyString(executionMetaRecord.executorTarget)
            ? executionMetaRecord.executorTarget.trim()
            : "",
        routeMode,
        generatedAt: isNonEmptyString(executionMetaRecord.generatedAt) ? executionMetaRecord.generatedAt.trim() : ""
    };

    if (parsedExecutionMeta.projectName.length === 0) {
        throw new AgentRuntimeError("Campo obrigatório ausente: executionMeta.projectName", { status: 422 });
    }

    if (parsedExecutionMeta.sourceArtifact.length === 0) {
        throw new AgentRuntimeError("Campo obrigatório ausente: executionMeta.sourceArtifact", { status: 422 });
    }

    if (parsedExecutionMeta.executorTarget.length === 0) {
        throw new AgentRuntimeError("Campo obrigatório ausente: executionMeta.executorTarget", { status: 422 });
    }

    if (parsedExecutionMeta.generatedAt.length === 0) {
        throw new AgentRuntimeError("Campo obrigatório ausente: executionMeta.generatedAt", { status: 422 });
    }

    const parsedCommonSections = parseCommonSections(sections as Record<string, unknown>);
    const rawSections = sections as Record<string, unknown>;

    if (routeMode === "director") {
        const technicalContext = isStringArray(rawSections.technicalContext) ? ensureParagraphs(rawSections.technicalContext) : [];
        const technicalChecklist = isStringArray(rawSections.technicalChecklist)
            ? ensureParagraphs(rawSections.technicalChecklist)
            : [];
        const executionPlan = isStringArray(rawSections.executionPlan) ? ensureParagraphs(rawSections.executionPlan) : [];
        const implementationNotes = isStringArray(rawSections.implementationNotes)
            ? ensureParagraphs(rawSections.implementationNotes)
            : [];

        if (technicalContext.length === 0) {
            throw new AgentRuntimeError("Campo obrigatório ausente: sections.technicalContext", { status: 422 });
        }

        if (technicalChecklist.length === 0) {
            throw new AgentRuntimeError("Campo obrigatório ausente: sections.technicalChecklist", { status: 422 });
        }

        if (executionPlan.length === 0) {
            throw new AgentRuntimeError("Campo obrigatório ausente: sections.executionPlan", { status: 422 });
        }

        return {
            routeMode: "director",
            documentMode,
            executionMeta: parsedExecutionMeta,
            sections: {
                ...parsedCommonSections,
                technicalContext,
                technicalChecklist,
                executionPlan,
                implementationNotes
            }
        };
    }

    const targetFiles = isStringArray(rawSections.targetFiles) ? ensureParagraphs(rawSections.targetFiles) : [];
    const implementationRules = isStringArray(rawSections.implementationRules)
        ? ensureParagraphs(rawSections.implementationRules)
        : [];
    const deliveryFormat = isStringArray(rawSections.deliveryFormat) ? ensureParagraphs(rawSections.deliveryFormat) : [];
    const implementationNotes = isStringArray(rawSections.implementationNotes)
        ? ensureParagraphs(rawSections.implementationNotes)
        : [];

    if (targetFiles.length === 0) {
        throw new AgentRuntimeError("Campo obrigatório ausente: sections.targetFiles", { status: 422 });
    }

    if (implementationRules.length === 0) {
        throw new AgentRuntimeError("Campo obrigatório ausente: sections.implementationRules", { status: 422 });
    }

    if (deliveryFormat.length === 0) {
        throw new AgentRuntimeError("Campo obrigatório ausente: sections.deliveryFormat", { status: 422 });
    }

    return {
        routeMode: "executor",
        documentMode,
        executionMeta: parsedExecutionMeta,
        sections: {
            ...parsedCommonSections,
            targetFiles,
            implementationRules,
            deliveryFormat,
            implementationNotes
        }
    };
}

function renderBulletedMarkdown(items: string[]): string {
    return ensureParagraphs(items)
        .map((item) => `- ${escapeMarkdown(item)}`)
        .join("\n");
}

function getExtractionModeLabel(extractionMode: ExtractionMode): string {
    switch (extractionMode) {
        case "blueprint":
            return "BLUEPRINT";
        case "sniper":
            return "SNIPER";
        default:
            return "FULL";
    }
}

function buildProtocolSliceSection1(outputRouteMode: OutputRouteMode, extractionMode: ExtractionMode): string {
    return [
        "## PROTOCOLO OPERACIONAL TRANSVERSAL — ELITE v2",
        "",
        "### §0 — FILOSOFIA UNIFICADA (STRICT GLOBAL ENFORCEMENT)",
        "- Toda saída deve conter exclusivamente conteúdo técnico compatível com o modo efetivamente gerado.",
        "- É proibido misturar papéis, blocos ou instruções de modos incompatíveis com a combinação ativa de rota e extração.",
        "- Não inferir arquitetura, contratos, fluxos ou comportamento fora do que estiver documentado no artefato visível.",
        "",
        "### §1 — ENQUADRAMENTO OPERACIONAL",
        `- Rota ativa: ${outputRouteMode === "director" ? "VIA DIRETOR" : "DIRETO PARA EXECUTOR"}.`,
        `- Extração efetiva: ${getExtractionModeLabel(extractionMode)}.`,
        "- O protocolo final deve ser composto apenas com os slices compatíveis com esta combinação operacional."
    ].join("\n");
}

function buildProtocolSliceFullMode(): string {
    return [
        "### MODO FULL",
        "- Escopo contextual máximo dentro do bundle visível.",
        "- Preservar contratos, dependências e topologia observável.",
        "- Proibido introduzir regras de BLUEPRINT ou SNIPER fora do contexto aplicável."
    ].join("\n");
}

function buildProtocolSliceBlueprintMode(): string {
    return [
        "### MODO BLUEPRINT",
        "- Priorizar arquitetura visível, contratos, interfaces, dependências e topologia.",
        "- Não fingir leitura integral de implementações não contidas no artefato.",
        "- Proibido introduzir blocos de FULL ou SNIPER que contradigam a extração ativa."
    ].join("\n");
}

function buildProtocolSliceSniperMode(): string {
    return [
        "### MODO SNIPER",
        "- Atuar somente sobre o recorte manual efetivamente selecionado.",
        "- Não extrapolar para arquivos, fluxos ou módulos não incluídos no recorte.",
        "- Preservar precisão cirúrgica e compatibilidade com o projeto visível."
    ].join("\n");
}

function buildProtocolSliceSection3(documentMode: DocumentMode, extractionMode: ExtractionMode, routeMode: OutputRouteMode): string {
    const lines: string[] = [
        routeMode === "director" ? "### MODO DIRETOR (OPTIMIZED v2.1)" : "### MODO EXECUTOR (OPTIMIZED v2.1)"
    ];

    if (routeMode === "director") {
        lines.push("- **Função:** Atuar como camada de inteligência analítica que processa inputs e gera especificações zero-gap para o Executor.");
        lines.push("- **DNA do Output:** Técnico, imperativo, denso e estruturado.");
        if (extractionMode === "blueprint") {
            lines.push("- Como a extração é BLUEPRINT, priorizar visão estrutural e não puxar regras de SNIPER.");
        } else if (extractionMode === "sniper") {
            lines.push("- Como a extração é SNIPER, limitar análise ao recorte manual visível.");
        } else {
            lines.push("- Como a extração é FULL, não inserir blocos de BLUEPRINT nem de SNIPER.");
        }
    } else {
        lines.push("- **Função:** Atuar como engine de engenharia e implementação direta (Code-First). Converter especificações técnicas, blueprints ou logs de erro em código funcional e produtivo.");
        lines.push("- **DNA do Output:** Strict Zero-Yap. Proibido atuar como Diretor.");
        if (documentMode === "manual") {
            lines.push("- O documento final deve manter precisão compatível com recorte manual.");
        }
        if (extractionMode === "blueprint") {
            lines.push("- A extração é BLUEPRINT: privilegiar contratos, interfaces e pontos de injeção sem fingir leitura integral.");
        } else if (extractionMode === "sniper") {
            lines.push("- A extração é SNIPER: alterar somente o recorte manual documentado.");
        } else {
            lines.push("- A extração é FULL: operar com o contexto total visível do bundle.");
        }
    }

    return lines.join("\n");
}

function buildProtocolMarkdown(document: StructuredOutputDocument, extractionMode: ExtractionMode): string {
    return [
        buildProtocolSliceSection1(document.routeMode, extractionMode),
        "",
        extractionMode === "full" ? buildProtocolSliceFullMode() : extractionMode === "blueprint" ? buildProtocolSliceBlueprintMode() : buildProtocolSliceSniperMode(),
        "",
        buildProtocolSliceSection3(document.documentMode, extractionMode, document.routeMode)
    ]
        .filter((part) => part.trim().length > 0)
        .join("\n\n");
}

function buildExecutionMetaMarkdown(meta: ExecutionMeta): string {
    return [
        "## EXECUTION META",
        "",
        `- Projeto: ${escapeMarkdown(meta.projectName)}`,
        `- Artefato fonte: ${escapeMarkdown(meta.sourceArtifact)}`,
        `- Executor alvo: ${escapeMarkdown(meta.executorTarget)}`,
        `- Route mode: ${escapeMarkdown(meta.routeMode)}`,
        `- Gerado em: ${escapeMarkdown(meta.generatedAt)}`
    ].join("\n");
}

function buildDirectorPromptTemplateMarkdown(document: DirectorStructuredOutput): string {
    const sections = document.sections;
    return [
        "# TASK",
        "",
        escapeMarkdown(sections.task),
        "",
        "## 1. CONTEXTO TÉCNICO",
        "",
        renderBulletedMarkdown(sections.technicalContext),
        "",
        "## 2. OBJETIVO PRIMÁRIO",
        "",
        escapeMarkdown(sections.objective),
        "",
        "## 3. ESCOPO",
        "",
        renderBulletedMarkdown(sections.scope),
        "",
        "## 4. RESTRIÇÕES GLOBAIS (STRICT ADHERENCE)",
        "",
        renderBulletedMarkdown(sections.constraints),
        "",
        "## 5. CHECKLIST TÉCNICO",
        "",
        renderBulletedMarkdown(sections.technicalChecklist),
        "",
        "## 6. PLANO DE EXECUÇÃO",
        "",
        renderBulletedMarkdown(sections.executionPlan),
        "",
        "## 7. CRITÉRIOS DE ACEITAÇÃO",
        "",
        renderBulletedMarkdown(sections.acceptanceCriteria),
        ...(sections.implementationNotes.length > 0
            ? ["", "## 8. NOTAS DE IMPLEMENTAÇÃO", "", renderBulletedMarkdown(sections.implementationNotes)]
            : [])
    ].join("\n");
}

function buildExecutorPromptTemplateMarkdown(document: ExecutorStructuredOutput): string {
    const sections = document.sections;
    return [
        "# TASK",
        "",
        escapeMarkdown(sections.task),
        "",
        "## 1. OBJETIVO PRIMÁRIO",
        "",
        escapeMarkdown(sections.objective),
        "",
        "## 2. ARQUIVOS-ALVO",
        "",
        renderBulletedMarkdown(sections.targetFiles),
        "",
        "## 3. ESCOPO",
        "",
        renderBulletedMarkdown(sections.scope),
        "",
        "## 4. REGRAS DE IMPLEMENTAÇÃO",
        "",
        renderBulletedMarkdown(sections.implementationRules),
        "",
        "## 5. RESTRIÇÕES GLOBAIS (STRICT ADHERENCE)",
        "",
        renderBulletedMarkdown(sections.constraints),
        "",
        "## 6. FORMATO DE ENTREGA",
        "",
        renderBulletedMarkdown(sections.deliveryFormat),
        "",
        "## 7. CRITÉRIOS DE ACEITAÇÃO",
        "",
        renderBulletedMarkdown(sections.acceptanceCriteria),
        ...(sections.implementationNotes.length > 0
            ? ["", "## 8. NOTAS DE IMPLEMENTAÇÃO", "", renderBulletedMarkdown(sections.implementationNotes)]
            : [])
    ].join("\n");
}

function buildStructuredMarkdownDocument(
    document: StructuredOutputDocument,
    technicalBundleDump: string,
    extractionMode: ExtractionMode
): string {
    const protocolMarkdown = buildProtocolMarkdown(document, extractionMode);
    const executionMetaMarkdown = buildExecutionMetaMarkdown(document.executionMeta);
    const promptTemplateMarkdown =
        document.routeMode === "director"
            ? buildDirectorPromptTemplateMarkdown(document as DirectorStructuredOutput)
            : buildExecutorPromptTemplateMarkdown(document as ExecutorStructuredOutput);

    return [
        protocolMarkdown,
        "",
        executionMetaMarkdown,
        "",
        "## SOURCE OF TRUTH",
        "",
        `> Modo de extração: ${getExtractionModeLabel(extractionMode)}.`,
        `> Route mode: ${document.routeMode}.`,
        `> Document mode: ${document.documentMode}.`,
        "",
        promptTemplateMarkdown,
        "",
        "## BUNDLE VISÍVEL",
        "",
        "```text",
        normalizeWhitespace(technicalBundleDump),
        "```"
    ].join("\n");
}

function buildExtractionModeScopeInstruction(extractionMode: ExtractionMode): string {
    switch (extractionMode) {
        case "blueprint":
            return [
                "A extração efetiva é BLUEPRINT (Architect).",
                "Foque em arquitetura visível, contratos, interfaces, dependências, topologia e pontos de integração.",
                "Não fingir leitura integral de implementações fora do recorte visível."
            ].join(" ");
        case "sniper":
            return [
                "A extração efetiva é SNIPER (manual/selective).",
                "Responda apenas com base no recorte manual incluído.",
                "Não extrapole para arquivos ou fluxos fora do recorte."
            ].join(" ");
        default:
            return [
                "A extração efetiva é FULL.",
                "Use o contexto integral visível no bundle.",
                "Não inclua regras de BLUEPRINT nem de SNIPER fora do contexto aplicável."
            ].join(" ");
    }
}

function buildExtractionModeRequirements(extractionMode: ExtractionMode): string[] {
    switch (extractionMode) {
        case "blueprint":
            return [
                "Priorizar arquitetura, interfaces, contratos e acoplamentos.",
                "Não presumir detalhes de implementação não visíveis.",
                "Não inserir blocos ou regras de SNIPER no protocolo final."
            ];
        case "sniper":
            return [
                "Atuar exclusivamente no recorte manual.",
                "Não extrapolar para módulos fora do artefato selecionado.",
                "Preservar precisão cirúrgica e compatibilidade contextual."
            ];
        default:
            return [
                "Usar o contexto integral visível no bundle.",
                "Preservar contratos, dependências e topologia observável.",
                "Não inserir blocos ou regras de BLUEPRINT/SNIPER no protocolo final."
            ];
    }
}

function buildDirectorStructuredSystemPrompt(
    mode: DocumentMode,
    extractionMode: ExtractionMode,
    executorTarget: string
): string {
    const scopeInstruction = buildExtractionModeScopeInstruction(extractionMode);

    return [
        "Você atua EXCLUSIVAMENTE como DIRETOR TÉCNICO DE EXECUÇÃO.",
        "Sua função é transformar o bundle visível em uma especificação operacional zero-gap para o Executor.",
        "Saída obrigatória em JSON estrito, sem markdown, comentários ou texto fora do objeto.",
        "O JSON final deve obedecer exatamente o schema solicitado.",
        "É proibido misturar papel de Executor, implementar código ou sair do artefato visível.",
        scopeInstruction,
        "A composição final do protocolo em markdown será feita por slices determinísticos compatíveis com routeMode + extractionMode.",
        `O executor alvo informado é: ${executorTarget}.`,
        `O documentMode externo é: ${mode}.`,
        "Preencha todos os campos obrigatórios com alto sinal técnico.",
        "Não use placeholders vazios.",
        "Não omita listas obrigatórias."
    ].join("\n");
}

function buildExecutorStructuredSystemPrompt(
    mode: DocumentMode,
    extractionMode: ExtractionMode,
    executorTarget: string
): string {
    const scopeInstruction = buildExtractionModeScopeInstruction(extractionMode);

    return [
        "Você atua EXCLUSIVAMENTE como ENGINE EXECUTOR DE IMPLEMENTAÇÃO.",
        "Sua função é converter o bundle visível em contexto técnico operacional pronto para implementação direta.",
        "Saída obrigatória em JSON estrito, sem markdown, comentários ou texto fora do objeto.",
        "O JSON final deve obedecer exatamente o schema solicitado.",
        "É proibido agir como Diretor, orquestrar outras IAs ou fugir do bundle visível.",
        scopeInstruction,
        "A composição final do protocolo em markdown será feita por slices determinísticos compatíveis com routeMode + extractionMode.",
        `O executor alvo informado é: ${executorTarget}.`,
        `O documentMode externo é: ${mode}.`,
        "Preencha todos os campos obrigatórios com precisão operacional.",
        "Não use placeholders vazios.",
        "Não omita listas obrigatórias."
    ].join("\n");
}

function buildStructuredOutputJsonSchema(routeMode: OutputRouteMode, mode: DocumentMode): string {
    if (routeMode === "director") {
        return JSON.stringify(
            {
                routeMode: "director",
                documentMode: mode,
                executionMeta: {
                    projectName: "<string>",
                    sourceArtifact: "<string>",
                    executorTarget: "<string>",
                    routeMode: "director",
                    generatedAt: "<ISO8601>"
                },
                sections: {
                    task: "<string>",
                    objective: "<string>",
                    scope: ["<string>"],
                    constraints: ["<string>"],
                    acceptanceCriteria: ["<string>"],
                    technicalContext: ["<string>"],
                    technicalChecklist: ["<string>"],
                    executionPlan: ["<string>"],
                    implementationNotes: ["<string — opcional>"]
                }
            },
            null,
            2
        );
    }

    return JSON.stringify(
        {
            routeMode: "executor",
            documentMode: mode,
            executionMeta: {
                projectName: "<string>",
                sourceArtifact: "<string>",
                executorTarget: "<string>",
                routeMode: "executor",
                generatedAt: "<ISO8601>"
            },
            sections: {
                task: "<string>",
                objective: "<string>",
                targetFiles: ["<string>"],
                scope: ["<string>"],
                implementationRules: ["<string>"],
                constraints: ["<string>"],
                deliveryFormat: ["<string>"],
                acceptanceCriteria: ["<string>"],
                implementationNotes: ["<string — opcional>"]
            }
        },
        null,
        2
    );
}

function buildDirectorStructuredUserPrompt(
    projectName: string,
    executorTarget: string,
    mode: DocumentMode,
    extractionMode: ExtractionMode,
    technicalBundleDump: string
): string {
    return [
        `PROJECT_NAME: ${projectName}`,
        `EXECUTOR_TARGET: ${executorTarget}`,
        "ROUTE_MODE: director",
        `DOCUMENT_MODE: ${mode}`,
        `EXTRACTION_MODE: ${extractionMode}`,
        "",
        "Gere um JSON estrito obedecendo exatamente o schema abaixo.",
        "Não escreva markdown.",
        "Não escreva comentários.",
        "Não use texto fora do objeto JSON.",
        "",
        "REGRAS OPERACIONAIS:",
        ...buildExtractionModeRequirements(extractionMode).map((line) => `- ${line}`),
        "- Não inventar módulos, contratos ou comportamentos fora do bundle.",
        "- Não misturar papel de Executor.",
        "- Especificação deve ser operacional, densa e pronta para consumo do Executor.",
        "",
        "SCHEMA JSON OBRIGATÓRIO:",
        buildStructuredOutputJsonSchema("director", mode),
        "",
        "BUNDLE VISÍVEL:",
        technicalBundleDump
    ].join("\n");
}

function buildExecutorStructuredUserPrompt(
    projectName: string,
    executorTarget: string,
    mode: DocumentMode,
    extractionMode: ExtractionMode,
    technicalBundleDump: string
): string {
    return [
        `PROJECT_NAME: ${projectName}`,
        `EXECUTOR_TARGET: ${executorTarget}`,
        "ROUTE_MODE: executor",
        `DOCUMENT_MODE: ${mode}`,
        `EXTRACTION_MODE: ${extractionMode}`,
        "",
        "Gere um JSON estrito obedecendo exatamente o schema abaixo.",
        "Não escreva markdown.",
        "Não escreva comentários.",
        "Não use texto fora do objeto JSON.",
        "",
        "REGRAS OPERACIONAIS:",
        ...buildExtractionModeRequirements(extractionMode).map((line) => `- ${line}`),
        "- Não inventar arquivos fora do bundle.",
        "- Não agir como Diretor.",
        "- Conteúdo deve ser operacional e pronto para implementação direta.",
        "",
        "SCHEMA JSON OBRIGATÓRIO:",
        buildStructuredOutputJsonSchema("executor", mode),
        "",
        "BUNDLE VISÍVEL:",
        technicalBundleDump
    ].join("\n");
}

function buildRepairPrompt(routeMode: OutputRouteMode, mode: DocumentMode, extractionMode: ExtractionMode): string {
    return [
        "Sua última resposta não pôde ser interpretada como JSON válido ou violou o schema obrigatório.",
        "Reemita apenas o objeto JSON corrigido.",
        "Não inclua markdown, explicações, comentários ou texto extra.",
        `ROUTE_MODE: ${routeMode}`,
        `DOCUMENT_MODE: ${mode}`,
        `EXTRACTION_MODE: ${extractionMode}`,
        "Respeite rigorosamente o schema obrigatório e preserve o alto sinal técnico."
    ].join("\n");
}

function validateForbiddenPatterns(content: string): void {
    const forbiddenPatterns: RegExp[] = [
        /```/,
        /<script/i,
        /ignorar\s+routeMode/i,
        /ignore\s+routeMode/i,
        /ignorar\s+extractionMode/i,
        /ignore\s+extractionMode/i
    ];

    for (const pattern of forbiddenPatterns) {
        if (pattern.test(content)) {
            throw new AgentRuntimeError("Resposta do provider contém padrão proibido.", {
                status: 422,
                details: `Pattern bloqueado: ${pattern.toString()}`
            });
        }
    }
}

function mergePromptConfigWithTemplatePreset(config: PromptCustomizationConfig): PromptCustomizationConfig {
    if (config.promptMode !== "template" || !config.templateId) {
        return config;
    }

    const preset = getPromptTemplatePreset(config.templateId);
    if (!preset) {
        return config;
    }

    return {
        ...config,
        objective: config.objective ?? preset.objective,
        deliveryType: config.deliveryType ?? preset.deliveryType,
        focusTags: dedupePreserveOrder([...preset.focusTags, ...config.focusTags]),
        constraints: dedupePreserveOrder([...preset.constraints, ...config.constraints])
    };
}

function buildAugmentedPromptBundle({
    projectName,
    technicalBundleDump,
    executorTarget,
    routeMode,
    mode,
    extractionMode,
    promptConfig
}: BuildAugmentedPromptBundleParams): ProviderRequestPayload {
    const hydratedConfig = mergePromptConfigWithTemplatePreset(promptConfig);

    const baseSystemPrompt =
        routeMode === "director"
            ? buildDirectorStructuredSystemPrompt(mode, extractionMode, executorTarget)
            : buildExecutorStructuredSystemPrompt(mode, extractionMode, executorTarget);

    const baseUserPrompt =
        routeMode === "director"
            ? buildDirectorStructuredUserPrompt(projectName, executorTarget, mode, extractionMode, technicalBundleDump)
            : buildExecutorStructuredUserPrompt(projectName, executorTarget, mode, extractionMode, technicalBundleDump);

    const customSystemLayer = buildPromptCustomizationSystemLayer(routeMode, extractionMode, hydratedConfig);
    const customUserLayer = buildPromptCustomizationUserLayer(hydratedConfig);

    return {
        systemPrompt: [baseSystemPrompt, "", customSystemLayer].join("\n"),
        userPrompt: [customUserLayer, "", baseUserPrompt].join("\n")
    };
}

class GroqClient implements AIClient {
    readonly name: ProviderName = "groq";
    private readonly apiKey: string;
    private readonly model: string;

    constructor(apiKey: string, model: string) {
        this.apiKey = apiKey;
        this.model = model;
    }

    async request(payload: ProviderRequestPayload): Promise<ProviderResponse> {
        const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
            method: "POST",
            headers: {
                Authorization: `Bearer ${this.apiKey}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                model: payload.model ?? this.model,
                temperature: 0.2,
                messages: [
                    { role: "system", content: payload.systemPrompt },
                    { role: "user", content: payload.userPrompt }
                ]
            })
        });

        if (!response.ok) {
            const details = await response.text();
            throw new AgentRuntimeError("Falha ao consultar Groq.", {
                status: response.status,
                details
            });
        }

        const data = (await response.json()) as {
            choices?: Array<{ message?: { content?: string } }>;
            model?: string;
        };

        const content = data.choices?.[0]?.message?.content?.trim();
        if (!content) {
            throw new AgentRuntimeError("Groq retornou conteúdo vazio.", { status: 502 });
        }

        return {
            provider: "groq",
            model: data.model ?? this.model,
            content
        };
    }
}

class GeminiClient implements AIClient {
    readonly name: ProviderName = "gemini";
    private readonly apiKey: string;
    private readonly model: string;

    constructor(apiKey: string, model: string) {
        this.apiKey = apiKey;
        this.model = model;
    }

    async request(payload: ProviderRequestPayload): Promise<ProviderResponse> {
        const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(
            payload.model ?? this.model
        )}:generateContent?key=${encodeURIComponent(this.apiKey)}`;

        const response = await fetch(url, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                generationConfig: {
                    temperature: 0.2
                },
                contents: [
                    {
                        role: "user",
                        parts: [
                            {
                                text: [payload.systemPrompt, "", payload.userPrompt].join("\n")
                            }
                        ]
                    }
                ]
            })
        });

        if (!response.ok) {
            const details = await response.text();
            throw new AgentRuntimeError("Falha ao consultar Gemini.", {
                status: response.status,
                details
            });
        }

        const data = (await response.json()) as {
            candidates?: Array<{
                content?: {
                    parts?: Array<{ text?: string }>;
                };
            }>;
            modelVersion?: string;
        };

        const content = data.candidates?.[0]?.content?.parts?.map((item) => item.text ?? "").join("").trim();
        if (!content) {
            throw new AgentRuntimeError("Gemini retornou conteúdo vazio.", { status: 502 });
        }

        return {
            provider: "gemini",
            model: data.modelVersion ?? this.model,
            content
        };
    }
}

class OpenAIClient implements AIClient {
    readonly name: ProviderName = "openai";
    private readonly apiKey: string;
    private readonly model: string;

    constructor(apiKey: string, model: string) {
        this.apiKey = apiKey;
        this.model = model;
    }

    async request(payload: ProviderRequestPayload): Promise<ProviderResponse> {
        const response = await fetch("https://api.openai.com/v1/chat/completions", {
            method: "POST",
            headers: {
                Authorization: `Bearer ${this.apiKey}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                model: payload.model ?? this.model,
                temperature: 0.2,
                messages: [
                    { role: "system", content: payload.systemPrompt },
                    { role: "user", content: payload.userPrompt }
                ]
            })
        });

        if (!response.ok) {
            const details = await response.text();
            throw new AgentRuntimeError("Falha ao consultar OpenAI.", {
                status: response.status,
                details
            });
        }

        const data = (await response.json()) as {
            choices?: Array<{ message?: { content?: string } }>;
            model?: string;
        };

        const content = data.choices?.[0]?.message?.content?.trim();
        if (!content) {
            throw new AgentRuntimeError("OpenAI retornou conteúdo vazio.", { status: 502 });
        }

        return {
            provider: "openai",
            model: data.model ?? this.model,
            content
        };
    }
}

class AnthropicClient implements AIClient {
    readonly name: ProviderName = "anthropic";
    private readonly apiKey: string;
    private readonly model: string;

    constructor(apiKey: string, model: string) {
        this.apiKey = apiKey;
        this.model = model;
    }

    async request(payload: ProviderRequestPayload): Promise<ProviderResponse> {
        const response = await fetch("https://api.anthropic.com/v1/messages", {
            method: "POST",
            headers: {
                "x-api-key": this.apiKey,
                "anthropic-version": "2023-06-01",
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                model: payload.model ?? this.model,
                max_tokens: 4096,
                temperature: 0.2,
                system: payload.systemPrompt,
                messages: [{ role: "user", content: payload.userPrompt }]
            })
        });

        if (!response.ok) {
            const details = await response.text();
            throw new AgentRuntimeError("Falha ao consultar Anthropic.", {
                status: response.status,
                details
            });
        }

        const data = (await response.json()) as {
            content?: Array<{ type?: string; text?: string }>;
            model?: string;
        };

        const content = data.content?.filter((item) => item.type === "text").map((item) => item.text ?? "").join("").trim();
        if (!content) {
            throw new AgentRuntimeError("Anthropic retornou conteúdo vazio.", { status: 502 });
        }

        return {
            provider: "anthropic",
            model: data.model ?? this.model,
            content
        };
    }
}

function getEnvValue(keys: string[]): string | null {
    for (const key of keys) {
        const value = process.env[key];
        if (typeof value === "string" && value.trim().length > 0) {
            return value.trim();
        }
    }
    return null;
}

function createClient(provider: ProviderName, modelOverride?: string): AIClient {
    switch (provider) {
        case "gemini": {
            const apiKey = getEnvValue(["GEMINI_API_KEY", "GOOGLE_API_KEY"]);
            if (!apiKey) {
                throw new AgentRuntimeError("GEMINI_API_KEY/GOOGLE_API_KEY não configurada.", { 
                    status: 401, 
                    errorType: "AUTH_ERROR" 
                });
            }
            return new GeminiClient(apiKey, modelOverride ?? "gemini-1.5-pro");
        }
        case "openai": {
            const apiKey = getEnvValue(["OPENAI_API_KEY"]);
            if (!apiKey) {
                throw new AgentRuntimeError("OPENAI_API_KEY não configurada.", { 
                    status: 401, 
                    errorType: "AUTH_ERROR" 
                });
            }
            return new OpenAIClient(apiKey, modelOverride ?? "gpt-4o");
        }
        case "anthropic": {
            const apiKey = getEnvValue(["ANTHROPIC_API_KEY"]);
            if (!apiKey) {
                throw new AgentRuntimeError("ANTHROPIC_API_KEY não configurada.", { 
                    status: 401, 
                    errorType: "AUTH_ERROR" 
                });
            }
            return new AnthropicClient(apiKey, modelOverride ?? "claude-3-5-sonnet-20240620");
        }
        case "groq":
        default: {
            const apiKey = getEnvValue(["GROQ_API_KEY"]);
            if (!apiKey) {
                throw new AgentRuntimeError("GROQ_API_KEY não configurada.", { 
                    status: 401, 
                    errorType: "AUTH_ERROR" 
                });
            }
            return new GroqClient(apiKey, modelOverride ?? "llama-3.3-70b-versatile");
        }
    }
}

function classifyError(error: unknown): { status: number; errorType: ProviderErrorType; message: string } {
    if (error instanceof AgentRuntimeError) {
        return { 
            status: error.status, 
            errorType: error.errorType ?? "PROVIDER_DOWN", 
            message: error.message 
        };
    }

    const message = error instanceof Error ? error.message : String(error);
    const lowMessage = message.toLowerCase();

    if (lowMessage.includes("401") || lowMessage.includes("unauthorized") || lowMessage.includes("403") || lowMessage.includes("forbidden") || lowMessage.includes("invalid api key")) {
        return { status: 401, errorType: "AUTH_ERROR", message };
    }
    if (lowMessage.includes("429") || lowMessage.includes("rate limit") || lowMessage.includes("too many requests")) {
        return { status: 429, errorType: "RATE_LIMIT", message };
    }
    if (lowMessage.includes("econnreset") || lowMessage.includes("enetunreach") || lowMessage.includes("timeout") || lowMessage.includes("fetch failed") || lowMessage.includes("dns")) {
        return { status: 503, errorType: "NETWORK_ERROR", message };
    }
    if (lowMessage.includes("500") || lowMessage.includes("502") || lowMessage.includes("503") || lowMessage.includes("504")) {
        return { status: 502, errorType: "PROVIDER_DOWN", message };
    }

    return { status: 500, errorType: "PROVIDER_DOWN", message };
}

function buildProviderChain(primary: ProviderName): ProviderName[] {
    const allProviders: ProviderName[] = ["groq", "gemini", "openai", "anthropic"];
    return [primary, ...allProviders.filter((item) => item !== primary)];
}

async function tryProviderChain(
    primaryProvider: ProviderName,
    payload: ProviderRequestPayload,
    modelOverride?: string
): Promise<ProviderResponse> {
    const chain = buildProviderChain(primaryProvider);
    const logDetails: string[] = [];
    const errorObjects: AgentRuntimeError[] = [];

    for (const provider of chain) {
        try {
            const client = createClient(provider, modelOverride);
            const response = await client.request(payload);
            return response;
        } catch (error) {
            const classified = classifyError(error);
            const brief = `${provider.toUpperCase()}: [${classified.errorType}] ${classified.message}`;
            logDetails.push(brief);
            
            // Log observability in stderr for HUD capture
            console.error(`    Skipping ${provider}: ${classified.errorType} (Status ${classified.status})`);
            
            errorObjects.push(new AgentRuntimeError(classified.message, {
                status: classified.status,
                errorType: classified.errorType,
                details: brief
            }));
        }
    }

    // Preserve the "best" error to define exit code status
    // Priority: AUTH_ERROR > RATE_LIMIT > PROVIDER_DOWN > NETWORK_ERROR
    const priority: ProviderErrorType[] = ["AUTH_ERROR", "RATE_LIMIT", "PROVIDER_DOWN", "NETWORK_ERROR"];
    let bestError = errorObjects[0];

    for (const pType of priority) {
        const found = errorObjects.find(e => e.errorType === pType);
        if (found) {
            bestError = found;
            break;
        }
    }

    throw new AgentRuntimeError("Falha em toda a cadeia de providers.", {
        status: bestError?.status ?? 502,
        errorType: bestError?.errorType ?? "PROVIDER_DOWN",
        details: logDetails.join(" | ")
    });
}

async function repairStructuredPayload(
    content: string,
    routeMode: OutputRouteMode,
    mode: DocumentMode,
    extractionMode: ExtractionMode,
    primaryProvider: ProviderName,
    modelOverride?: string
): Promise<StructuredOutputDocument> {
    const candidate = extractJsonCandidate(content);
    if (!candidate) {
        throw new AgentRuntimeError("Nenhum JSON candidato encontrado na resposta do provider.", { status: 422 });
    }

    try {
        validateForbiddenPatterns(candidate);
        const parsed = safeJsonParse<unknown>(candidate, null);
        return parseStructuredDocument(parsed);
    } catch {
        const repairPayload: ProviderRequestPayload = {
            systemPrompt: buildRepairPrompt(routeMode, mode, extractionMode),
            userPrompt: candidate
        };

        const repaired = await tryProviderChain(primaryProvider, repairPayload, modelOverride);
        const repairedCandidate = extractJsonCandidate(repaired.content);
        if (!repairedCandidate) {
            throw new AgentRuntimeError("Repair falhou: JSON candidato ausente.", { status: 422 });
        }

        validateForbiddenPatterns(repairedCandidate);
        const repairedParsed = safeJsonParse<unknown>(repairedCandidate, null);
        return parseStructuredDocument(repairedParsed);
    }
}

async function main(): Promise<void> {
    const args = parseCliArgs(process.argv.slice(2));

    const bundlePath = args.bundlePath ?? args.bundle ?? args.input;
    if (!bundlePath) {
        throw new AgentRuntimeError("Parâmetro obrigatório ausente: --bundlePath", { status: 400 });
    }

    const provider = normalizeProviderName(args.provider);
    const modelOverride = args.model;
    const executorTarget = (args.executorTarget ?? "AI Studio Apps").trim();
    const promptConfigFilePath = args.promptConfigFilePath;
    const explicitProjectName = args.projectName;
    const explicitOutputPath = args.outputPath;
    const explicitResultMetaPath = args.resultMetaPath;
    const explicitRouteMode = args.routeMode ? normalizeOutputRouteMode(args.routeMode) : null;

    const absolutePath = path.resolve(bundlePath);
    const sourceArtifactName = path.basename(absolutePath);
    const technicalBundleDump = await readTextFile(absolutePath);

    const inferredProjectName =
        explicitProjectName?.trim() ||
        sourceArtifactName
            .replace(/^_+(Diretor|Executor)_/i, "")
            .replace(/^_+(BUNDLER__|BLUEPRINT__|SELECTIVE__|COPIAR_TUDO__|INTELIGENTE__|MANUAL__)/i, "")
            .replace(/\.md$/i, "");

    const bundleMode =
        args.extractionMode ??
        args.mode ??
        (sourceArtifactName.toLowerCase().includes("inteligente") || sourceArtifactName.toLowerCase().includes("blueprint")
            ? "blueprint"
            : sourceArtifactName.toLowerCase().includes("manual") || sourceArtifactName.toLowerCase().includes("selective")
            ? "sniper"
            : "full");

    const extractionMode = normalizeExtractionMode(bundleMode, path.basename(absolutePath));
    const mode: DocumentMode = resolveDocumentModeFromExtractionMode(extractionMode);
    const outputRouteMode = explicitRouteMode ?? (sourceArtifactName.toLowerCase().includes("_executor_") ? "executor" : "director");

    const promptConfig = await readOptionalPromptConfig(promptConfigFilePath, outputRouteMode, extractionMode, executorTarget);

    console.error(
        `Pipeline estruturado ativo | routeMode=${outputRouteMode} | extractionMode=${extractionMode} | promptMode=${promptConfig.promptMode}`
    );

    const promptPayload = buildAugmentedPromptBundle({
        projectName: inferredProjectName,
        technicalBundleDump,
        executorTarget,
        routeMode: outputRouteMode,
        mode,
        extractionMode,
        promptConfig
    });

    const providerResponse = await tryProviderChain(provider, promptPayload, modelOverride);
    const structuredDocument = await repairStructuredPayload(
        providerResponse.content,
        outputRouteMode,
        mode,
        extractionMode,
        provider,
        modelOverride
    );

    const finalMarkdown = buildStructuredMarkdownDocument(structuredDocument, technicalBundleDump, extractionMode);

    const outputBaseDir = path.dirname(absolutePath);
    const routePrefix = outputRouteMode === "director" ? "_diretor_AI_CONTEXT_" : "_executor_AI_CONTEXT_";
    const fallbackOutputPath = path.join(outputBaseDir, `${routePrefix}${inferredProjectName}.md`);
    const finalOutputPath = explicitOutputPath ? path.resolve(explicitOutputPath) : fallbackOutputPath;

    const fallbackResultMetaPath = path.join(
        outputBaseDir,
        `${outputRouteMode === "director" ? "_diretor_AI_RESULT_" : "_executor_AI_RESULT_"}${inferredProjectName}.json`
    );
    const finalResultMetaPath = explicitResultMetaPath ? path.resolve(explicitResultMetaPath) : fallbackResultMetaPath;

    await writeTextFile(finalOutputPath, finalMarkdown);

    const resultMeta = {
        ok: true,
        provider: providerResponse.provider,
        model: providerResponse.model,
        routeMode: outputRouteMode,
        extractionMode,
        documentMode: mode,
        promptMode: promptConfig.promptMode,
        templateId: promptConfig.templateId,
        hasAdditionalInstructions: Boolean(promptConfig.additionalInstructions),
        hasExpertOverride: Boolean(promptConfig.expertSystemPrompt),
        outputPath: finalOutputPath,
        bundlePath: absolutePath,
        generatedAt: getCurrentTimestampIso()
    };

    await writeTextFile(finalResultMetaPath, JSON.stringify(resultMeta, null, 2));

    // FIX (bug 5): emit structured marker on stdout so PowerShell can parse provider/model
    // without relying solely on the result JSON file on disk.
    process.stdout.write(
        `[AI_RESULT] provider=${providerResponse.provider};model=${providerResponse.model}\n`
    );

    process.stdout.write(
        JSON.stringify(
            {
                ok: true,
                outputPath: finalOutputPath,
                resultMetaPath: finalResultMetaPath,
                provider: providerResponse.provider,
                model: providerResponse.model,
                routeMode: outputRouteMode,
                extractionMode,
                promptMode: promptConfig.promptMode,
                templateId: promptConfig.templateId
            },
            null,
            2
        )
    );
}

main().catch((error) => {
    const status = error instanceof AgentRuntimeError ? error.status : 500;
    const message = error instanceof Error ? error.message : String(error);
    const details = error instanceof AgentRuntimeError ? error.details : undefined;

    if (details) {
        console.error(`[!] ERRO: ${message}`);
        console.error(`    Detalhes técnicos: ${details}`);
    } else {
        console.error(`[!] ERRO: ${message}`);
    }

    // FIX (bug 3): differentiate exit codes — auth failures = 1, server/parse errors = 2
    process.exit(status === 401 || status === 403 ? 1 : 2);
});