import "dotenv/config";
import crypto from "crypto";
import { execFileSync } from "child_process";
import fs from "fs/promises";
import os from "os";
import path from "path";
import process from "process";

type OutputRouteMode = "director" | "executor";
type ExtractionMode = "full" | "blueprint" | "sniper";
type DocumentMode = "full" | "manual" | "txt_export";
type ProviderName = "groq" | "gemini" | "openai" | "anthropic" | "local";
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

interface PromptAuditMessage {
    role: "system" | "user";
    content: string;
    charLength: number;
    sha256: string;
}

interface PromptAudit {
    interactionMode: "remote-provider" | "deterministic-local";
    systemPrompt: string | null;
    userPrompt: string | null;
    finalPrompt: string | null;
    messages: PromptAuditMessage[];
    estimatedChars: number;
    redactions: string[];
}

interface ResponseAudit {
    interactionMode: "remote-provider" | "deterministic-local";
    providerRawContent: string | null;
    providerRawContentSha256: string | null;
    providerRawContentPreview: string | null;
    finalMarkdownSha256: string;
    finalMarkdownPreview: string;
    finalMarkdownCharLength: number;
}

interface ProcessingAuditStep {
    name: string;
    status: "success" | "error";
    startedAt: string;
    finishedAt: string;
    durationMs: number;
    details?: string;
}

interface ProcessingAuditStepHandle {
    name: string;
    startedAt: string;
    startedAtMs: number;
}

interface UserExecutionContext {
    identity: string;
    username: string | null;
    domain: string | null;
    homeDirectory: string | null;
}

interface EnvironmentExecutionContext {
    osVersion: string;
    psVersion: string | null;
    isElevated: boolean;
    platform: string;
    architecture: string;
    hostname: string;
    nodeVersion: string;
}

interface RetryAttemptTelemetry {
    provider: ProviderName;
    resolvedModel: string;
    status: number;
    errorType?: ProviderErrorType;
    message: string;
    details?: string;
    retryable: boolean;
    startedAt: string;
    finishedAt: string;
    durationMs: number;
    outcome: "success" | "error";
}

interface RetryHistoryMeta {
    originalProvider: ProviderName;
    successfulProvider: ProviderName;
    fallbackTriggered: boolean;
    attemptCount: number;
    attempts: RetryAttemptTelemetry[];
}

interface ProviderChainResult {
    response: ProviderResponse;
    retryHistory: RetryHistoryMeta;
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

const DETERMINISTIC_DIRECTOR_TEMPLATE_ID = "director_meta_v1" as const;

interface ContextMomentumMeta {
    state: "loaded" | "empty";
    source: string | null;
    payload: Record<string, unknown> | null;
}

interface DeterministicDirectorTemplateModel {
    projectName: string;
    sourceArtifact: string;
    executorTarget: string;
    extractionMode: ExtractionMode;
    documentMode: DocumentMode;
    generatedAt: string;
    objective: string;
    deliveryType: string;
    focusTags: string[];
    constraints: string[];
    contextMomentum: ContextMomentumMeta;
    visibleFiles: string[];
    relevantFiles: string[];
    analysisSummary: string;
    reasoningSummary: string;
}

type ProviderErrorType = "AUTH_ERROR" | "RATE_LIMIT" | "NETWORK_ERROR" | "PARSE_ERROR" | "PROVIDER_DOWN" | "CONFIG_ERROR" | "PAYLOAD_TOO_LARGE";

interface ClassifiedError {
    status: number;
    errorType: ProviderErrorType;
    message: string;
    details?: string;
    retryable: boolean;
}

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

function normalizeErrorDetails(details: string | undefined): string | undefined {
    if (!details) {
        return undefined;
    }

    const normalized = details.replace(/\r\n/g, "\n").replace(/\s+/g, " ").trim();
    if (normalized.length === 0) {
        return undefined;
    }

    return normalized.length > 500 ? `${normalized.slice(0, 500)}…` : normalized;
}

function classifyHttpStatus(status: number, details?: string): { errorType: ProviderErrorType; retryable: boolean } {
    const lowDetails = (details ?? "").toLowerCase();

    if (status === 401 || status === 403) {
        return { errorType: "AUTH_ERROR", retryable: false };
    }

    if (status === 413 || lowDetails.includes("payload too large") || lowDetails.includes("request entity too large")) {
        return { errorType: "PAYLOAD_TOO_LARGE", retryable: false };
    }

    if (status === 429 || lowDetails.includes("rate limit") || lowDetails.includes("too many requests")) {
        return { errorType: "RATE_LIMIT", retryable: true };
    }

    if (
        status === 400 ||
        status === 404 ||
        status === 409 ||
        status === 422 ||
        lowDetails.includes("invalid model") ||
        lowDetails.includes("not found") ||
        lowDetails.includes("bad request")
    ) {
        return { errorType: "CONFIG_ERROR", retryable: false };
    }

    if (
        status === 408 ||
        lowDetails.includes("timeout") ||
        lowDetails.includes("econnreset") ||
        lowDetails.includes("enetunreach") ||
        lowDetails.includes("dns") ||
        lowDetails.includes("fetch failed")
    ) {
        return { errorType: "NETWORK_ERROR", retryable: true };
    }

    if (status === 500 || status === 502 || status === 503 || status === 504) {
        return { errorType: "PROVIDER_DOWN", retryable: true };
    }

    return { errorType: "PROVIDER_DOWN", retryable: false };
}

function buildProviderHttpError(providerLabel: string, status: number, details?: string): AgentRuntimeError {
    const classified = classifyHttpStatus(status, details);

    return new AgentRuntimeError(`Falha ao consultar ${providerLabel}.`, {
        status,
        details: normalizeErrorDetails(details),
        retryable: classified.retryable,
        errorType: classified.errorType
    });
}

function getExitCodeForErrorType(errorType: ProviderErrorType): number {
    switch (errorType) {
        case "AUTH_ERROR":
            return 1;
        case "RATE_LIMIT":
            return 2;
        case "CONFIG_ERROR":
        case "PAYLOAD_TOO_LARGE":
            return 3;
        case "NETWORK_ERROR":
        case "PROVIDER_DOWN":
            return 4;
        case "PARSE_ERROR":
            return 5;
        default:
            return 2;
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
            "Mantenha intactos os headings obrigatórios, delimitadores do prompt, routeMode e extractionMode do pipeline."
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
            "Mantenha intactos os headings obrigatórios, delimitadores do prompt, parse e repair do pipeline."
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
            "Não alterar o contrato estrutural obrigatório."
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

    "director_meta_v1": {
        id: "director_meta_v1",
        label: "Diretor Meta-Prompt Determinístico v1",
        allowedRouteModes: ["director"],
        allowedExtractionModes: ["full", "blueprint", "sniper"],
        objective: "Compilar meta-prompt do Diretor em Markdown determinístico, sem provider remoto.",
        deliveryType: "Documento Markdown pronto para cópia operacional.",
        focusTags: ["director", "meta-prompt", "deterministic", "elite-v3"],
        constraints: [
            "Não chamar provider remoto.",
            "Preservar headings obrigatórios do Diretor.",
            "Usar apenas sinais objetivos do bundle visível.",
            "Não inferir módulos, contratos ou comportamentos ausentes."
        ],
        systemDelta: "Modo local determinístico ativo.",
        userDelta: "Renderize o documento final localmente."
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

const DIRECTOR_DETERMINISTIC_PHRASEBOOK = {
    analysisByExtractionMode: {
        full: "O bundle visível fornece visão ampla do projeto, incluindo estrutura, componentes centrais e contratos operacionais.",
        blueprint: "O bundle visível fornece recorte arquitetural orientado a contratos, responsabilidades e superfícies de integração.",
        sniper: "O bundle visível fornece recorte cirúrgico orientado a um ajuste pontual, com contexto minimizado."
    } as const,
    reasoningBase: [
        "A saída deve converter sinais objetivos do bundle em um meta-prompt estável e pronto para cópia.",
        "O documento precisa preservar routeMode, extractionMode, contrato estrutural do Diretor e Lei da Subtração.",
        "Nenhum bloco deve depender de inferência livre ou de respostas probabilísticas do provider."
    ]
};

function isDeterministicDirectorTemplate(
    routeMode: OutputRouteMode,
    promptConfig: PromptCustomizationConfig
): boolean {
    return (
        routeMode === "director" &&
        promptConfig.promptMode === "template" &&
        promptConfig.templateId === DETERMINISTIC_DIRECTOR_TEMPLATE_ID
    );
}

function extractVisibleFilesFromBundle(bundle: string): string[] {
    const matches = Array.from(bundle.matchAll(/#### File:\s+(.+)$/gm));
    const items = matches.map((match) => match[1].trim());
    return Array.from(new Set(items));
}

function selectRelevantFiles(visibleFiles: string[]): string[] {
    const priority = [
        ".\\groq-agent.ts",
        ".\\project-bundler.ps1",
        ".\\modules\\VibeDirectorProtocol.psm1",
        ".\\modules\\VibeBundleWriter.psm1",
        ".\\DOCUMENTACAO_TECNICA.md",
        ".\\README.md"
    ];

    const visible = new Set(visibleFiles);
    return priority.filter((file) => visible.has(file));
}

function extractContextMomentum(bundle: string): ContextMomentumMeta {
    const headingMatch = bundle.search(/#{4,6}\s*0\.\s*CONTEXTO MOMENTUM/i);
    if (headingMatch < 0) {
        return { state: "empty", source: null, payload: null };
    }

    const sectionTail = bundle.slice(headingMatch);
    const nextHeadingRelative = sectionTail.slice(1).search(/\n#{2,6}\s+/);
    const section =
        nextHeadingRelative >= 0
            ? sectionTail.slice(0, nextHeadingRelative + 1)
            : sectionTail;

    const sourceMatch = section.match(/-\s*Fonte:\s*(.+)$/im);
    const jsonMatch = section.match(/```json\s*([\s\S]*?)```/i);
    const payload = jsonMatch ? safeJsonParse<Record<string, unknown> | null>(jsonMatch[1], null) : null;

    return {
        state: payload ? "loaded" : "empty",
        source: sourceMatch ? sourceMatch[1].trim() : null,
        payload
    };
}

function buildDeterministicDirectorTemplateModel(params: {
    projectName: string;
    sourceArtifact: string;
    executorTarget: string;
    extractionMode: ExtractionMode;
    documentMode: DocumentMode;
    generatedAt: string;
    technicalBundleDump: string;
    promptConfig: PromptCustomizationConfig;
}): DeterministicDirectorTemplateModel {
    const visibleFiles = extractVisibleFilesFromBundle(params.technicalBundleDump);
    const relevantFiles = selectRelevantFiles(visibleFiles);
    const contextMomentum = extractContextMomentum(params.technicalBundleDump);

    const analysisSummary =
        DIRECTOR_DETERMINISTIC_PHRASEBOOK.analysisByExtractionMode[params.extractionMode];

    const reasoningSummary = [
        ...DIRECTOR_DETERMINISTIC_PHRASEBOOK.reasoningBase,
        relevantFiles.length > 0
            ? `Os recortes prioritários para o Executor são: ${relevantFiles.join(", ")}.`
            : "Não foram detectados recortes prioritários explícitos no bundle visível."
    ].join(" ");

    return {
        projectName: params.projectName,
        sourceArtifact: params.sourceArtifact,
        executorTarget: params.executorTarget,
        extractionMode: params.extractionMode,
        documentMode: params.documentMode,
        generatedAt: params.generatedAt,
        objective:
            params.promptConfig.objective ??
            "Gerar meta-prompt operacional estruturado para orientar o Executor com alto sinal técnico.",
        deliveryType:
            params.promptConfig.deliveryType ??
            "Meta-prompt operacional estruturado para Diretor",
        focusTags: params.promptConfig.focusTags,
        constraints: params.promptConfig.constraints,
        contextMomentum,
        visibleFiles,
        relevantFiles,
        analysisSummary,
        reasoningSummary
    };
}

function renderDeterministicDirectorMarkdown(model: DeterministicDirectorTemplateModel): string {
    const layer1 = [
        "### LAYER 1: IDENTIDADE E REGRAS",
        "- Papel do Executor: Senior Implementation Agent (Sniper).",
        "- Preservar contratos, nomes, comportamento existente e compatibilidade com o fluxo atual.",
        "- Aplicar Lei da Subtração antes de adicionar novo código.",
        "- Não inferir módulos, contratos ou comportamentos fora do bundle visível."
    ];

    const layer2 = [
        "### LAYER 2: BLUEPRINT TÉCNICO",
        `- Objetivo: ${model.objective}`,
        `- Entrega esperada: ${model.deliveryType}`,
        "- Route mode de origem: director",
        `- Extraction mode: ${model.extractionMode}`,
        `- Executor alvo: ${model.executorTarget}`
    ];

    const layer3 = [
        "### LAYER 3: CONTEXTO MOMENTUM",
        `- Estado: ${model.contextMomentum.state === "loaded" ? "carregado" : "vazio"}`,
        `- Fonte: ${model.contextMomentum.source ?? "não identificada"}`,
        model.relevantFiles.length > 0
            ? `- Recortes prioritários: ${model.relevantFiles.join(", ")}`
            : "- Recortes prioritários: não identificados objetivamente"
    ];

    const layer4 = [
        "### LAYER 4: PROTOCOLO DE VERIFICAÇÃO",
        "- Validar contra o contrato estrutural do Diretor e do Executor.",
        "- Exigir Relatório de Impacto, diff claro, validação objetiva e verificação de segurança.",
        "- Propor testes mínimos e checagens de regressão compatíveis com o escopo."
    ];

    const extraConstraints =
        model.constraints.length > 0
            ? ["", "### RESTRIÇÕES ADICIONAIS", ...model.constraints.map((item) => `- ${item}`)]
            : [];

    return [
        "## PROTOCOLO OPERACIONAL TRANSVERSAL — ELITE v3",
        "",
        "### §0 — IDENTIDADE E MANDATO (O DIRETOR)",
        "- Papel ativo: Diretor de Engenharia Agêntica.",
        "- Saída compilada localmente por template determinístico.",
        "",
        "### §1 — ENQUADRAMENTO OPERACIONAL",
        "- Rota ativa: VIA DIRETOR.",
        `- Extração efetiva: ${getExtractionModeLabel(model.extractionMode)}.`,
        `- Executor alvo de referência: ${model.executorTarget}.`,
        "- O bloco [META-PROMPT PARA EXECUTOR] abaixo está pronto para cópia.",
        "",
        "## EXECUTION META",
        "",
        `- Projeto: ${model.projectName}`,
        `- Artefato fonte: ${model.sourceArtifact}`,
        `- Executor alvo: ${model.executorTarget}`,
        "- Route mode: director",
        `- Gerado em: ${model.generatedAt}`,
        "",
        "## SOURCE OF TRUTH",
        "",
        `> Modo de extração: ${getExtractionModeLabel(model.extractionMode)}.`,
        "> Route mode: director.",
        `> Document mode: ${model.documentMode}.`,
        "",
        "[META-PROMPT PARA EXECUTOR]",
        "",
        "## ANÁLISE DO DIRETOR",
        model.analysisSummary,
        "",
        "## RACIOCÍNIO (CoT)",
        model.reasoningSummary,
        "",
        "## PROMPT PARA O EXECUTOR (COPIAR ABAIXO)",
        "--- INÍCIO DO PROMPT ---",
        ...layer1,
        "",
        ...layer2,
        "",
        ...layer3,
        "",
        ...layer4,
        ...extraConstraints,
        "--- FIM DO PROMPT ---"
    ].join("\n");
}

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
        case "local":
            return "local";
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

function normalizeDocumentMode(value: string | undefined | null): DocumentMode | null {
    const normalized = (value ?? "").trim().toLowerCase();

    switch (normalized) {
        case "full":
            return "full";
        case "manual":
        case "sniper":
            return "manual";
        case "txt_export":
        case "txt-export":
        case "txtexport":
            return "txt_export";
        default:
            return null;
    }
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

async function readOptionalTextFileForAudit(filePath: string): Promise<string | null> {
    try {
        return await fs.readFile(filePath, "utf-8");
    } catch {
        return null;
    }
}

async function computeFileSha256(filePath: string): Promise<string> {
    const content = await fs.readFile(filePath);
    return crypto.createHash("sha256").update(content).digest("hex");
}

function tryExecCapture(command: string, args: string[]): string | null {
    try {
        const output = execFileSync(command, args, {
            encoding: "utf8",
            stdio: ["ignore", "pipe", "ignore"]
        });

        const normalized = output.trim();
        return normalized.length > 0 ? normalized : null;
    } catch {
        return null;
    }
}

function detectPowerShellVersion(): string | null {
    const candidates = ["pwsh", "pwsh.exe"];

    for (const executable of candidates) {
        const value = tryExecCapture(executable, [
            "-NoProfile",
            "-Command",
            "$PSVersionTable.PSVersion.ToString()"
        ]);

        if (value) {
            return value;
        }
    }

    return null;
}

function detectIsElevated(): boolean {
    if (process.platform === "win32") {
        const candidates = ["pwsh", "pwsh.exe"];
        const elevationScript =
            "$p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); if ($p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { 'true' } else { 'false' }";

        for (const executable of candidates) {
            const value = tryExecCapture(executable, ["-NoProfile", "-Command", elevationScript]);
            if (value === "true") {
                return true;
            }
            if (value === "false") {
                return false;
            }
        }

        return false;
    }

    return typeof process.getuid === "function" ? process.getuid() === 0 : false;
}

function buildEnvironmentExecutionContext(): EnvironmentExecutionContext {
    const versionParts = [os.type(), os.release()];

    try {
        const detailedVersion = typeof os.version === "function" ? os.version() : null;
        if (detailedVersion && detailedVersion.trim().length > 0) {
            versionParts.push(detailedVersion.trim());
        }
    } catch {
        // no-op
    }

    return {
        osVersion: versionParts.join(" | "),
        psVersion: detectPowerShellVersion(),
        isElevated: detectIsElevated(),
        platform: process.platform,
        architecture: os.arch(),
        hostname: os.hostname(),
        nodeVersion: process.version
    };
}

function buildUserExecutionContext(): UserExecutionContext {
    const username = process.env.USERNAME?.trim() || process.env.USER?.trim() || null;
    const domain = process.env.USERDOMAIN?.trim() || null;
    const homeDirectory = process.env.USERPROFILE?.trim() || process.env.HOME?.trim() || null;

    return {
        identity: domain && username ? `${domain}\\${username}` : username ?? "unknown",
        username,
        domain,
        homeDirectory
    };
}

function buildLocalRetryHistory(model: string, message = "Execução local sem provider remoto."): RetryHistoryMeta {
    const now = getCurrentTimestampIso();

    return {
        originalProvider: "local",
        successfulProvider: "local",
        fallbackTriggered: false,
        attemptCount: 1,
        attempts: [
            {
                provider: "local",
                resolvedModel: model,
                status: 200,
                message,
                retryable: false,
                startedAt: now,
                finishedAt: now,
                durationMs: 0,
                outcome: "success"
            }
        ]
    };
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
            ? "Gerar análise técnica e meta-prompt zero-gap de alto sinal para orientar o Executor."
            : "Gerar contexto técnico estruturado pronto para implementação direta.";

    const deliveryType =
        routeMode === "director"
            ? "Meta-prompt operacional estruturado para Diretor"
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
    const contractGuard =
        routeMode === "director"
            ? "É proibido alterar o contrato do Diretor ELITE v3: headings obrigatórios, delimitadores do prompt, routeMode ou extractionMode."
            : "É proibido desligar JSON, schema obrigatório, parse estruturado, repair estruturado, routeMode ou extractionMode.";

    const layers: string[] = [
        "## CUSTOM PROMPT LAYER — STRICT ENFORCEMENT",
        `ROUTE_MODE_LOCK=${routeMode}`,
        `EXTRACTION_MODE_LOCK=${extractionMode}`,
        `PROMPT_MODE=${promptConfig.promptMode}`,
        `DEPTH=${promptConfig.depth}`,
        `TONE=${promptConfig.tone}`,
        contractGuard
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

function computeSha256FromString(value: string): string {
    return crypto.createHash("sha256").update(value, "utf8").digest("hex");
}

function createAuditPreview(value: string | null | undefined, maxLength = 4000): string | null {
    if (!value) {
        return null;
    }

    const normalized = value.replace(/\r\n/g, "\n").trim();
    if (normalized.length === 0) {
        return null;
    }

    return normalized.length > maxLength ? `${normalized.slice(0, maxLength)}…` : normalized;
}

function startProcessingAuditStep(name: string): ProcessingAuditStepHandle {
    const startedAtMs = Date.now();
    return {
        name,
        startedAt: new Date(startedAtMs).toISOString(),
        startedAtMs
    };
}

function finishProcessingAuditStep(
    steps: ProcessingAuditStep[],
    handle: ProcessingAuditStepHandle,
    status: "success" | "error",
    details?: string
): void {
    const finishedAtMs = Date.now();
    steps.push({
        name: handle.name,
        status,
        startedAt: handle.startedAt,
        finishedAt: new Date(finishedAtMs).toISOString(),
        durationMs: finishedAtMs - handle.startedAtMs,
        ...(details ? { details } : {})
    });
}

function buildPromptAudit(
    interactionMode: "remote-provider" | "deterministic-local",
    payload: ProviderRequestPayload | null
): PromptAudit {
    const systemPrompt = payload?.systemPrompt ?? null;
    const userPrompt = payload?.userPrompt ?? null;
    const finalPrompt =
        systemPrompt && userPrompt
            ? [systemPrompt, "", userPrompt].join("\n")
            : systemPrompt ?? userPrompt ?? null;

    const messages: PromptAuditMessage[] = [];
    if (systemPrompt) {
        messages.push({
            role: "system",
            content: systemPrompt,
            charLength: systemPrompt.length,
            sha256: computeSha256FromString(systemPrompt)
        });
    }

    if (userPrompt) {
        messages.push({
            role: "user",
            content: userPrompt,
            charLength: userPrompt.length,
            sha256: computeSha256FromString(userPrompt)
        });
    }

    return {
        interactionMode,
        systemPrompt,
        userPrompt,
        finalPrompt,
        messages,
        estimatedChars: finalPrompt?.length ?? 0,
        redactions: []
    };
}

function buildResponseAudit(params: {
    interactionMode: "remote-provider" | "deterministic-local";
    providerRawContent: string | null;
    finalMarkdown: string;
    finalMarkdownSha256Override?: string | null;
    finalMarkdownPreviewOverride?: string | null;
    finalMarkdownCharLengthOverride?: number | null;
}): ResponseAudit {
    return {
        interactionMode: params.interactionMode,
        providerRawContent: params.providerRawContent,
        providerRawContentSha256: params.providerRawContent ? computeSha256FromString(params.providerRawContent) : null,
        providerRawContentPreview: createAuditPreview(params.providerRawContent),
        finalMarkdownSha256: params.finalMarkdownSha256Override ?? computeSha256FromString(params.finalMarkdown),
        finalMarkdownPreview: params.finalMarkdownPreviewOverride ?? createAuditPreview(params.finalMarkdown) ?? "",
        finalMarkdownCharLength: params.finalMarkdownCharLengthOverride ?? params.finalMarkdown.length
    };
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

function buildExecutorEliteV41ProtocolMarkdown(document: ExecutorStructuredOutput, extractionMode: ExtractionMode): string {
    const extractionLabel = getExtractionModeLabel(extractionMode);

    return [
        "### IMPLEMENTAÇÃO: PROTOCOLO OPERACIONAL EXECUTOR — ELITE v4.1 (SNIPER MODE)",
        "",
        "#### §0 — IDENTIDADE OPERACIONAL (O SNIPER)",
        "- **Papel:** Você é o **Senior Implementation Agent (Sniper)**. Sua função é a materialização de sintaxe com precisão cirúrgica a partir de especificações técnicas.",
        "- **Missão:** Converter o blueprint recebido em código funcional, respeitando invariantes, contratos e a arquitetura existente.",
        "- **Filosofia:** O código é um **passivo técnico (liability)**. Sua entrega só se torna um ativo após validação rigorosa. Não decida arquitetura; execute o plano.",
        "",
        "#### §1 — REGRAS DE EXECUÇÃO \"ZERO-GAP\"",
        "- **Rota ativa:** DIRETO PARA O EXECUTOR.",
        `- **Extração efetiva:** ${extractionLabel}.`,
        `- **Document mode:** ${document.documentMode}.`,
        "1. **Lei da Subtração:** Antes de adicionar código, verifique se a funcionalidade pode ser resolvida reutilizando abstrações existentes ou removendo redundâncias.",
        "2. **Preservação de Contexto:** Mantenha estilos de nomenclatura, padrões de documentação e estruturas de arquivos compatíveis com o projeto original.",
        "3. **DNA do Output (Zero-Yap):** A entrega deve ser exclusivamente técnica e pronta para aplicação.",
        "",
        "#### §2 — FLUXO DE MATERIALIZAÇÃO",
        "- **Análise de Impacto:** Identifique arquivos afetados e dependências antes de iniciar a escrita.",
        "- **Implementação de Alta Fidelidade:** Siga estritamente as assinaturas de funções e tipos definidos no blueprint.",
        "- **Checklist de Segurança:** Verifique contra vulnerabilidades comuns antes de finalizar.",
        "",
        "#### §3 — TEMPLATE OBRIGATÓRIO DE RESPOSTA",
        "Toda saída deve seguir esta estrutura rigorosa:",
        "1. **[RELATÓRIO DE IMPACTO]**: Lista de arquivos alterados e dependências verificadas.",
        "2. **[IMPLEMENTAÇÃO]**:",
        "   * `### ARQUIVO: [caminho/do/arquivo]`",
        "   * (Blocos de código Markdown com diffs precisos ou arquivo completo conforme solicitado).",
        "3. **[PROTOCOLO DE VERIFICAÇÃO]**:",
        "   * Sugestões de Property-based Testing ou Fuzzing para validar o código gerado contra falhas não previstas.",
        "4. **[ASSINATURA TÉCNICA]**: Confirmação de que todos os requisitos do contrato foram atendidos."
    ].join("\n");
}

function buildProtocolMarkdown(document: StructuredOutputDocument, extractionMode: ExtractionMode): string {
    if (document.routeMode === "executor") {
        return buildExecutorEliteV41ProtocolMarkdown(document as ExecutorStructuredOutput, extractionMode);
    }

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
    const impactLines = [
        ...sections.targetFiles.map((item) => `Arquivo-alvo: ${item}`),
        ...sections.scope.map((item) => `Escopo: ${item}`),
        ...sections.constraints.map((item) => `Restrição: ${item}`)
    ];

    const verificationLines = [
        ...sections.acceptanceCriteria,
        ...sections.deliveryFormat
    ];

    const signatureLines = [
        "Executor ativo: Senior Implementation Agent (Sniper).",
        "Todos os requisitos devem permanecer aderentes ao bundle visível e ao protocolo ELITE v4.1."
    ];

    return [
        "## [RELATÓRIO DE IMPACTO]",
        "",
        renderBulletedMarkdown(impactLines),
        "",
        "## [IMPLEMENTAÇÃO]",
        "",
        "### ARQUIVO(S)-ALVO",
        "",
        renderBulletedMarkdown(sections.targetFiles),
        "",
        "### REGRAS DE IMPLEMENTAÇÃO",
        "",
        renderBulletedMarkdown(sections.implementationRules),
        ...(sections.implementationNotes.length > 0
            ? ["", "### NOTAS DE IMPLEMENTAÇÃO", "", renderBulletedMarkdown(sections.implementationNotes)]
            : []),
        "",
        "## [PROTOCOLO DE VERIFICAÇÃO]",
        "",
        renderBulletedMarkdown(verificationLines),
        "",
        "## [ASSINATURA TÉCNICA]",
        "",
        renderBulletedMarkdown(signatureLines)
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

const DIRECTOR_REQUIRED_BLOCKS: readonly string[] = [
    "## ANÁLISE DO DIRETOR",
    "## RACIOCÍNIO (CoT)",
    "## PROMPT PARA O EXECUTOR (COPIAR ABAIXO)",
    "--- INÍCIO DO PROMPT ---",
    "--- FIM DO PROMPT ---"
];

function buildDirectorEliteV3SystemPrompt(
    mode: DocumentMode,
    extractionMode: ExtractionMode,
    executorTarget: string
): string {
    const scopeInstruction = buildExtractionModeScopeInstruction(extractionMode);

    return [
        "Você atua EXCLUSIVAMENTE como DIRETOR DE ENGENHARIA AGÊNTICA.",
        "Sua função é ler o bundle visível, assimilar o contexto e produzir um meta-prompt zero-gap para o Executor.",
        "Você está proibido de implementar código, escrever patches finais, assumir papel de Executor ou inventar arquitetura fora do bundle visível.",
        "Quando houver lacuna de contexto, declare explicitamente a lacuna em vez de improvisar.",
        "O bundle pode conter uma seção de CONTEXTO MOMENTUM com metadados _ai_ anteriores; use-a apenas como estado anterior de apoio, sem sobrescrever o bundle visível.",
        scopeInstruction,
        `O executor alvo de referência é: ${executorTarget}.`,
        `O documentMode externo é: ${mode}.`,
        "Sua saída deve obedecer exatamente ao contrato abaixo, sem qualquer bloco adicional antes, depois ou entre eles:",
        "## ANÁLISE DO DIRETOR",
        "## RACIOCÍNIO (CoT)",
        "## PROMPT PARA O EXECUTOR (COPIAR ABAIXO)",
        "--- INÍCIO DO PROMPT ---",
        "--- FIM DO PROMPT ---",
        "Dentro do bloco PROMPT PARA O EXECUTOR, estruture o conteúdo em camadas: LAYER 1 IDENTIDADE E REGRAS, LAYER 2 BLUEPRINT TÉCNICO, LAYER 3 CONTEXTO MOMENTUM, LAYER 4 PROTOCOLO DE VERIFICAÇÃO.",
        "Instrua explicitamente Lei da Subtração, Relatório de Impacto, diff claro, validação objetiva e verificação de segurança.",
        "Use linguagem técnica, imperativa, densa e rastreável."
    ].join("\n");
}

function buildDirectorEliteV3UserPrompt(
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
        "TAREFA:",
        "- Assimilar exclusivamente o bundle visível.",
        "- Produzir análise técnica, decomposição lógica e um prompt copiável para o Executor.",
        "- Não escrever código final.",
        "- Não responder em JSON.",
        "- Não usar qualquer seção fora do contrato obrigatório.",
        "",
        "CONTRATO OBRIGATÓRIO DE SAÍDA:",
        "## ANÁLISE DO DIRETOR",
        "## RACIOCÍNIO (CoT)",
        "## PROMPT PARA O EXECUTOR (COPIAR ABAIXO)",
        "--- INÍCIO DO PROMPT ---",
        "--- FIM DO PROMPT ---",
        "",
        "CONTEÚDO MÍNIMO DO BLOCO DE PROMPT PARA O EXECUTOR:",
        "- [LAYER 1: IDENTIDADE E REGRAS]",
        "- [LAYER 2: BLUEPRINT TÉCNICO]",
        "- [LAYER 3: CONTEXTO MOMENTUM]",
        "- [LAYER 4: PROTOCOLO DE VERIFICAÇÃO]",
        "- exigir Lei da Subtração",
        "- exigir Relatório de Impacto",
        "- exigir verificação de segurança",
        "",
        "BUNDLE VISÍVEL:",
        technicalBundleDump
    ].join("\n");
}

function extractDirectorPromptBody(content: string): string {
    const startToken = "--- INÍCIO DO PROMPT ---";
    const endToken = "--- FIM DO PROMPT ---";
    const startIndex = content.indexOf(startToken);
    const endIndex = content.indexOf(endToken);

    if (startIndex < 0 || endIndex <= startIndex) {
        throw new AgentRuntimeError("Bloco do prompt do Executor não pôde ser delimitado.", { status: 422 });
    }

    const promptBody = content.slice(startIndex + startToken.length, endIndex).trim();
    if (promptBody.length === 0) {
        throw new AgentRuntimeError("Bloco do prompt do Executor veio vazio.", { status: 422 });
    }

    return promptBody;
}

function validateDirectorResponseContract(content: string): string {
    const normalized = normalizeWhitespace(content);
    validateForbiddenPatterns(normalized);

    const missingBlocks = DIRECTOR_REQUIRED_BLOCKS.filter((block) => !normalized.includes(block));
    if (missingBlocks.length > 0) {
        throw new AgentRuntimeError("Resposta do Diretor fora do contrato obrigatório.", {
            status: 422,
            details: `Blocos obrigatórios ausentes: ${missingBlocks.join(" | ")}`
        });
    }

    extractDirectorPromptBody(normalized);
    return normalized;
}

function buildDirectorRepairPrompt(extractionMode: ExtractionMode, failureDetails?: string): string {
    return [
        "Sua última resposta violou o contrato obrigatório do Diretor ELITE v3.",
        "Reemita a resposta inteira mantendo a mesma intenção técnica derivada do bundle visível.",
        "Não implementar código.",
        "Não responder em JSON.",
        "Não adicionar qualquer bloco fora do contrato obrigatório.",
        "Use exatamente:",
        "## ANÁLISE DO DIRETOR",
        "## RACIOCÍNIO (CoT)",
        "## PROMPT PARA O EXECUTOR (COPIAR ABAIXO)",
        "--- INÍCIO DO PROMPT ---",
        "--- FIM DO PROMPT ---",
        `EXTRACTION_MODE: ${extractionMode}`,
        ...(failureDetails ? [`DETALHE DA VIOLAÇÃO: ${failureDetails}`] : [])
    ].join("\n");
}

async function repairDirectorResponseContract(
    content: string,
    extractionMode: ExtractionMode,
    primaryProvider: ProviderName,
    processingSteps: ProcessingAuditStep[],
    modelOverride?: string
): Promise<string> {
    const validationStep = startProcessingAuditStep("validate_director_response_contract");

    try {
        const validated = validateDirectorResponseContract(content);
        finishProcessingAuditStep(processingSteps, validationStep, "success");
        return validated;
    } catch (error) {
        const classified = classifyError(error);
        finishProcessingAuditStep(
            processingSteps,
            validationStep,
            "error",
            classified.details ?? classified.message
        );

        const repairPayload: ProviderRequestPayload = {
            systemPrompt: buildDirectorRepairPrompt(extractionMode, classified.details ?? classified.message),
            userPrompt: content
        };

        const repairStep = startProcessingAuditStep("repair_director_response_contract");
        const repaired = await tryProviderChain(primaryProvider, repairPayload, modelOverride);
        finishProcessingAuditStep(
            processingSteps,
            repairStep,
            "success",
            `Provider=${repaired.response.provider}; Model=${repaired.response.model}`
        );

        const repairedValidationStep = startProcessingAuditStep("validate_repaired_director_response_contract");
        const validated = validateDirectorResponseContract(repaired.response.content);
        finishProcessingAuditStep(processingSteps, repairedValidationStep, "success");
        return validated;
    }
}

function buildDirectorEliteV3MarkdownDocument(
    directorResponse: string,
    technicalBundleDump: string,
    executionMeta: ExecutionMeta,
    extractionMode: ExtractionMode
): string {
    const protocolMarkdown = [
        "## PROTOCOLO OPERACIONAL TRANSVERSAL — ELITE v3",
        "",
        "### §0 — IDENTIDADE E MANDATO (O DIRETOR)",
        "- Papel ativo: Diretor de Engenharia Agêntica.",
        "- Saída validada contra o contrato obrigatório do Diretor ELITE v3.",
        "",
        "### §1 — ENQUADRAMENTO OPERACIONAL",
        "- Rota ativa: VIA DIRETOR.",
        `- Extração efetiva: ${getExtractionModeLabel(extractionMode)}.`,
        `- Executor alvo de referência: ${escapeMarkdown(executionMeta.executorTarget)}.`,
        "- O bloco [META-PROMPT PARA EXECUTOR] abaixo está pronto para cópia."
    ].join("\n");

    return [
        protocolMarkdown,
        "",
        buildExecutionMetaMarkdown(executionMeta),
        "",
        "## SOURCE OF TRUTH",
        "",
        `> Modo de extração: ${getExtractionModeLabel(extractionMode)}.`,
        `> Route mode: ${executionMeta.routeMode}.`,
        `> Document mode: full.`,
        "",
        "[META-PROMPT PARA EXECUTOR]",
        "",
        validateDirectorResponseContract(directorResponse),
        "",
        "## BUNDLE VISÍVEL",
        "",
        "```text",
        normalizeWhitespace(technicalBundleDump),
        "```"
    ].join("\n");
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
        "Você atua EXCLUSIVAMENTE como o Senior Implementation Agent (Sniper).",
        "Sua função é converter o bundle visível em contexto técnico operacional pronto para implementação direta com precisão cirúrgica.",
        "Considere o protocolo base do Executor como ELITE v4.1 (Sniper Mode).",
        "Saída obrigatória em JSON estrito, sem markdown, comentários ou texto fora do objeto.",
        "O JSON final deve obedecer exatamente ao schema solicitado.",
        "É proibido agir como Diretor, orquestrar outras IAs ou fugir do bundle visível.",
        "A Lei da Subtração deve orientar targetFiles, implementationRules, deliveryFormat e implementationNotes.",
        "O deliveryFormat precisa preparar explicitamente a resposta final do Executor com [RELATÓRIO DE IMPACTO], [IMPLEMENTAÇÃO], [PROTOCOLO DE VERIFICAÇÃO] e [ASSINATURA TÉCNICA].",
        scopeInstruction,
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
        "- Papel ativo: Senior Implementation Agent (Sniper).",
        "- Objetivo base: implementação zero-gap com precisão cirúrgica.",
        "- deliveryFormat deve refletir o protocolo de resposta do Executor ELITE v4.1.",
        "- Não inventar arquivos fora do bundle.",
        "- Não agir como Diretor.",
        "- Conteúdo deve ser operacional e pronto para implementação direta.",
        ...buildExtractionModeRequirements(extractionMode).map((line) => `- ${line}`),
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
    const customSystemLayer = buildPromptCustomizationSystemLayer(routeMode, extractionMode, hydratedConfig);
    const customUserLayer = buildPromptCustomizationUserLayer(hydratedConfig);

    if (routeMode === "director") {
        const baseSystemPrompt = buildDirectorEliteV3SystemPrompt(mode, extractionMode, executorTarget);
        const baseUserPrompt = buildDirectorEliteV3UserPrompt(
            projectName,
            executorTarget,
            mode,
            extractionMode,
            technicalBundleDump
        );

        return {
            systemPrompt: [baseSystemPrompt, "", customSystemLayer].join("\n"),
            userPrompt: [customUserLayer, "", baseUserPrompt].join("\n")
        };
    }

    const baseSystemPrompt = buildExecutorStructuredSystemPrompt(mode, extractionMode, executorTarget);
    const baseUserPrompt = buildExecutorStructuredUserPrompt(
        projectName,
        executorTarget,
        mode,
        extractionMode,
        technicalBundleDump
    );

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
                temperature: 0,
                messages: [
                    { role: "system", content: payload.systemPrompt },
                    { role: "user", content: payload.userPrompt }
                ]
            })
        });

        if (!response.ok) {
            const details = await response.text();
            throw buildProviderHttpError("Groq", response.status, details);
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
                    temperature: 0
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
            throw buildProviderHttpError("Gemini", response.status, details);
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
                temperature: 0,
                messages: [
                    { role: "system", content: payload.systemPrompt },
                    { role: "user", content: payload.userPrompt }
                ]
            })
        });

        if (!response.ok) {
            const details = await response.text();
            throw buildProviderHttpError("OpenAI", response.status, details);
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
        const body: any = {
            model: payload.model ?? this.model,
            max_tokens: 4096,
            temperature: 0,
            messages: [{ role: "user", content: payload.userPrompt }]
        };

        if (payload.systemPrompt && payload.systemPrompt.trim() !== "") {
            body.system = payload.systemPrompt;
        }

        const response = await fetch("https://api.anthropic.com/v1/messages", {
            method: "POST",
            headers: {
                "x-api-key": this.apiKey,
                "anthropic-version": "2023-06-01",
                "Content-Type": "application/json"
            },
            body: JSON.stringify(body)
        });

        if (!response.ok) {
            const details = await response.text();
            throw buildProviderHttpError("Anthropic", response.status, details);
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

function resolveModelForProvider(provider: ProviderName, modelOverride?: string): string {
    if (typeof modelOverride === "string" && modelOverride.trim().length > 0) {
        return modelOverride.trim();
    }

    switch (provider) {
        case "local":
            return "deterministic-director_meta_v1";
        case "gemini":
            return getEnvValue(["GEMINI_MODEL", "GOOGLE_MODEL"]) ?? "gemini-1.5-pro";
        case "openai":
            return getEnvValue(["OPENAI_MODEL"]) ?? "gpt-4o";
        case "anthropic":
            return getEnvValue(["ANTHROPIC_MODEL"]) ?? "claude-3-5-sonnet-20240620";
        case "groq":
        default:
            return getEnvValue(["GROQ_MODEL"]) ?? "llama-3.3-70b-versatile";
    }
}

function createClient(provider: ProviderName, modelOverride?: string): AIClient {
    const resolvedModel = resolveModelForProvider(provider, modelOverride);

    switch (provider) {
        case "local": {
            throw new AgentRuntimeError("Provider local não deve ser instanciado via createClient().", {
                status: 400,
                errorType: "CONFIG_ERROR"
            });
        }
        case "gemini": {
            const apiKey = getEnvValue(["GEMINI_API_KEY", "GOOGLE_API_KEY"]);
            if (!apiKey) {
                throw new AgentRuntimeError("GEMINI_API_KEY/GOOGLE_API_KEY não configurada.", {
                    status: 401,
                    errorType: "AUTH_ERROR"
                });
            }
            return new GeminiClient(apiKey, resolvedModel);
        }
        case "openai": {
            const apiKey = getEnvValue(["OPENAI_API_KEY"]);
            if (!apiKey) {
                throw new AgentRuntimeError("OPENAI_API_KEY não configurada.", {
                    status: 401,
                    errorType: "AUTH_ERROR"
                });
            }
            return new OpenAIClient(apiKey, resolvedModel);
        }
        case "anthropic": {
            const apiKey = getEnvValue(["ANTHROPIC_API_KEY"]);
            if (!apiKey) {
                throw new AgentRuntimeError("ANTHROPIC_API_KEY não configurada.", {
                    status: 401,
                    errorType: "AUTH_ERROR"
                });
            }
            return new AnthropicClient(apiKey, resolvedModel);
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
            return new GroqClient(apiKey, resolvedModel);
        }
    }
}

function classifyError(error: unknown): ClassifiedError {
    if (error instanceof AgentRuntimeError) {
        if (error.errorType) {
            return {
                status: error.status,
                errorType: error.errorType,
                message: error.message,
                details: error.details,
                retryable: error.retryable
            };
        }

        if (error.status === 422) {
            return {
                status: error.status,
                errorType: "PARSE_ERROR",
                message: error.message,
                details: error.details,
                retryable: false
            };
        }

        const inferred = classifyHttpStatus(error.status, [error.message, error.details ?? ""].join("\n"));
        return {
            status: error.status,
            errorType: inferred.errorType,
            message: error.message,
            details: error.details,
            retryable: error.retryable || inferred.retryable
        };
    }

    const message = error instanceof Error ? error.message : String(error);
    const lowMessage = message.toLowerCase();

    if (lowMessage.includes("401") || lowMessage.includes("unauthorized") || lowMessage.includes("403") || lowMessage.includes("forbidden") || lowMessage.includes("invalid api key")) {
        return { status: 401, errorType: "AUTH_ERROR", message, retryable: false };
    }
    if (lowMessage.includes("413") || lowMessage.includes("payload too large") || lowMessage.includes("request entity too large")) {
        return { status: 413, errorType: "PAYLOAD_TOO_LARGE", message, retryable: false };
    }
    if (lowMessage.includes("429") || lowMessage.includes("rate limit") || lowMessage.includes("too many requests")) {
        return { status: 429, errorType: "RATE_LIMIT", message, retryable: true };
    }
    if (lowMessage.includes("422")) {
        return { status: 422, errorType: "PARSE_ERROR", message, retryable: false };
    }
    if (lowMessage.includes("400") || lowMessage.includes("404") || lowMessage.includes("bad request") || lowMessage.includes("not found") || lowMessage.includes("invalid model")) {
        return { status: lowMessage.includes("404") ? 404 : 400, errorType: "CONFIG_ERROR", message, retryable: false };
    }
    if (lowMessage.includes("econnreset") || lowMessage.includes("enetunreach") || lowMessage.includes("timeout") || lowMessage.includes("fetch failed") || lowMessage.includes("dns")) {
        return { status: 503, errorType: "NETWORK_ERROR", message, retryable: true };
    }
    if (lowMessage.includes("500") || lowMessage.includes("502") || lowMessage.includes("503") || lowMessage.includes("504")) {
        return { status: 502, errorType: "PROVIDER_DOWN", message, retryable: true };
    }

    return { status: 500, errorType: "PROVIDER_DOWN", message, retryable: false };
}

function buildProviderChain(primary: ProviderName): ProviderName[] {
    const allProviders: ProviderName[] = ["groq", "gemini", "openai", "anthropic"];
    return [primary, ...allProviders.filter((item) => item !== primary)];
}

async function tryProviderChain(
    primaryProvider: ProviderName,
    payload: ProviderRequestPayload,
    modelOverride?: string
): Promise<ProviderChainResult> {
    const chain = buildProviderChain(primaryProvider);
    const logDetails: string[] = [];
    const errorObjects: AgentRuntimeError[] = [];
    const attempts: RetryAttemptTelemetry[] = [];

    for (const provider of chain) {
        const startedAtMs = Date.now();
        const startedAt = new Date(startedAtMs).toISOString();

        try {
            const resolvedModel = resolveModelForProvider(provider, modelOverride);
            console.error(`    Provider target: ${provider} | Resolved model: ${resolvedModel}`);

            const client = createClient(provider, modelOverride);
            const response = await client.request(payload);

            const finishedAtMs = Date.now();
            const finishedAt = new Date(finishedAtMs).toISOString();

            attempts.push({
                provider,
                resolvedModel,
                status: 200,
                message: "Provider retornou conteúdo com sucesso.",
                retryable: false,
                startedAt,
                finishedAt,
                durationMs: finishedAtMs - startedAtMs,
                outcome: "success"
            });

            return {
                response,
                retryHistory: {
                    originalProvider: primaryProvider,
                    successfulProvider: response.provider,
                    fallbackTriggered: provider !== primaryProvider,
                    attemptCount: attempts.length,
                    attempts
                }
            };
        } catch (error) {
            const finishedAtMs = Date.now();
            const finishedAt = new Date(finishedAtMs).toISOString();
            const classified = classifyError(error);
            const resolvedModel = resolveModelForProvider(provider, modelOverride);
            const brief = `${provider.toUpperCase()}: [${classified.errorType}] ${classified.message}${classified.details ? ` | ${classified.details}` : ""}`;

            logDetails.push(brief);
            console.error(`    Skipping ${provider}: ${classified.errorType} (Status ${classified.status})`);

            attempts.push({
                provider,
                resolvedModel,
                status: classified.status,
                errorType: classified.errorType,
                message: classified.message,
                details: classified.details,
                retryable: classified.retryable,
                startedAt,
                finishedAt,
                durationMs: finishedAtMs - startedAtMs,
                outcome: "error"
            });

            errorObjects.push(new AgentRuntimeError(classified.message, {
                status: classified.status,
                errorType: classified.errorType,
                details: brief,
                retryable: classified.retryable
            }));
        }
    }

    const priority: ProviderErrorType[] = ["AUTH_ERROR", "PAYLOAD_TOO_LARGE", "CONFIG_ERROR", "RATE_LIMIT", "PROVIDER_DOWN", "NETWORK_ERROR", "PARSE_ERROR"];
    let bestError = errorObjects[0];

    for (const pType of priority) {
        const found = errorObjects.find((e) => e.errorType === pType);
        if (found) {
            bestError = found;
            break;
        }
    }

    throw new AgentRuntimeError("Falha em toda a cadeia de providers.", {
        status: bestError?.status ?? 502,
        errorType: bestError?.errorType ?? "PROVIDER_DOWN",
        details: logDetails.join(" | "),
        retryable: bestError?.retryable ?? false
    });
}

async function repairStructuredPayload(
    content: string,
    routeMode: OutputRouteMode,
    mode: DocumentMode,
    extractionMode: ExtractionMode,
    primaryProvider: ProviderName,
    processingSteps: ProcessingAuditStep[],
    modelOverride?: string
): Promise<StructuredOutputDocument> {
    const extractionStep = startProcessingAuditStep("extract_structured_payload_candidate");
    const candidate = extractJsonCandidate(content);
    if (!candidate) {
        finishProcessingAuditStep(processingSteps, extractionStep, "error", "JSON candidato ausente.");
        throw new AgentRuntimeError("Nenhum JSON candidato encontrado na resposta do provider.", { status: 422 });
    }

    finishProcessingAuditStep(processingSteps, extractionStep, "success");

    const validationStep = startProcessingAuditStep("validate_structured_payload");

    try {
        validateForbiddenPatterns(candidate);
        const parsed = safeJsonParse<unknown>(candidate, null);
        const document = parseStructuredDocument(parsed);
        finishProcessingAuditStep(processingSteps, validationStep, "success");
        return document;
    } catch (error) {
        const classified = classifyError(error);
        finishProcessingAuditStep(
            processingSteps,
            validationStep,
            "error",
            classified.details ?? classified.message
        );

        const repairPayload: ProviderRequestPayload = {
            systemPrompt: buildRepairPrompt(routeMode, mode, extractionMode),
            userPrompt: candidate
        };

        const repairStep = startProcessingAuditStep("repair_structured_payload");
        const repaired = await tryProviderChain(primaryProvider, repairPayload, modelOverride);
        finishProcessingAuditStep(
            processingSteps,
            repairStep,
            "success",
            `Provider=${repaired.response.provider}; Model=${repaired.response.model}`
        );

        const repairedCandidateStep = startProcessingAuditStep("extract_repaired_structured_payload_candidate");
        const repairedCandidate = extractJsonCandidate(repaired.response.content);
        if (!repairedCandidate) {
            finishProcessingAuditStep(processingSteps, repairedCandidateStep, "error", "JSON candidato ausente após repair.");
            throw new AgentRuntimeError("Repair falhou: JSON candidato ausente.", { status: 422 });
        }

        finishProcessingAuditStep(processingSteps, repairedCandidateStep, "success");

        const repairedValidationStep = startProcessingAuditStep("validate_repaired_structured_payload");
        validateForbiddenPatterns(repairedCandidate);
        const repairedParsed = safeJsonParse<unknown>(repairedCandidate, null);
        const document = parseStructuredDocument(repairedParsed);
        finishProcessingAuditStep(processingSteps, repairedValidationStep, "success");
        return document;
    }
}

async function main(): Promise<void> {
    const executionStartedAtMs = Date.now();
    const executionId = crypto.randomUUID();
    const args = parseCliArgs(process.argv.slice(2));

    const bundlePath = args.bundlePath ?? args.bundle ?? args.input;
    if (!bundlePath) {
        throw new AgentRuntimeError("Parâmetro obrigatório ausente: --bundlePath", { status: 400 });
    }

    const provider = normalizeProviderName(args.provider);
    const modelOverride = args.model;
    const executorTarget = (args.executorTarget ?? "ChatGPT").trim();
    const promptConfigFilePath = args.promptConfigFilePath;
    const explicitProjectName = args.projectName;
    const explicitOutputPath = args.outputPath;
    const explicitResultMetaPath = args.resultMetaPath;
    const explicitRouteMode = args.routeMode ? normalizeOutputRouteMode(args.routeMode) : null;
    const explicitDocumentMode = normalizeDocumentMode(args.documentMode);
    const explicitPromptMode = typeof args.promptMode === "string" && args.promptMode.trim().length > 0 ? args.promptMode.trim() : null;
    const explicitTemplateId = typeof args.templateId === "string" && args.templateId.trim().length > 0 ? args.templateId.trim() : null;
    const explicitSkipReason = typeof args.skipReason === "string" && args.skipReason.trim().length > 0 ? args.skipReason.trim() : null;
    const explicitLocalModel = typeof args.localModel === "string" && args.localModel.trim().length > 0 ? args.localModel.trim() : null;

    const absolutePath = path.resolve(bundlePath);
    const sourceArtifactName = path.basename(absolutePath);
    const bundleHash = await computeFileSha256(absolutePath);

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
    const mode: DocumentMode = explicitDocumentMode ?? resolveDocumentModeFromExtractionMode(extractionMode);
    const outputRouteMode = explicitRouteMode ?? (sourceArtifactName.toLowerCase().includes("_executor_") ? "executor" : "director");

    const promptConfig = await readOptionalPromptConfig(promptConfigFilePath, outputRouteMode, extractionMode, executorTarget);
    assertDeterministicTemplateLoaded(promptConfig);
    const isGenericLocalGovernance = provider === "local" && !isDeterministicDirectorTemplate(outputRouteMode, promptConfig);
    const pipelineLogPromptMode = isGenericLocalGovernance ? explicitPromptMode ?? "local" : promptConfig.promptMode;
    const pipelineLogTemplateId = isGenericLocalGovernance ? explicitTemplateId : promptConfig.templateId;

    console.error(
        `Pipeline estruturado ativo | routeMode=${outputRouteMode} | extractionMode=${extractionMode} | promptMode=${pipelineLogPromptMode} | templateId=${pipelineLogTemplateId ?? "null"}`
    );

    const generatedAt = getCurrentTimestampIso();

    const processingSteps: ProcessingAuditStep[] = [];
    let providerResponse: ProviderResponse;
    let retryHistory: RetryHistoryMeta;
    let finalMarkdown = "";
    let promptAudit: PromptAudit;
    let shouldWriteOutputArtifact = true;
    let technicalBundleDump = "";
    let resultPromptMode: string | null = promptConfig.promptMode;
    let resultTemplateId: string | null = promptConfig.templateId;
    let hasAdditionalInstructions = Boolean(promptConfig.additionalInstructions);
    let hasExpertOverride = Boolean(promptConfig.expertSystemPrompt);

    if (isDeterministicDirectorTemplate(outputRouteMode, promptConfig)) {
        technicalBundleDump = await readTextFile(absolutePath);
        const deterministicStep = startProcessingAuditStep("render_deterministic_director_template");
        const model = buildDeterministicDirectorTemplateModel({
            projectName: inferredProjectName,
            sourceArtifact: sourceArtifactName,
            executorTarget,
            extractionMode,
            documentMode: mode,
            generatedAt,
            technicalBundleDump,
            promptConfig
        });

        providerResponse = {
            provider: "local",
            model: "deterministic-director_meta_v1",
            content: ""
        };

        retryHistory = buildLocalRetryHistory(providerResponse.model, "Template determinístico local executado sem cadeia de fallback.");

        console.error("    Provider target: local | Resolved model: deterministic-director_meta_v1");
        finalMarkdown = renderDeterministicDirectorMarkdown(model);
        finishProcessingAuditStep(processingSteps, deterministicStep, "success");
        promptAudit = buildPromptAudit("deterministic-local", null);
        resultPromptMode = explicitPromptMode ?? "deterministic_local";
        resultTemplateId = explicitTemplateId ?? promptConfig.templateId;
    } else if (isGenericLocalGovernance) {
        const localGovernanceStep = startProcessingAuditStep("local_governance_metadata");
        providerResponse = {
            provider: "local",
            model: explicitLocalModel ?? "bundler-vibe-core",
            content: ""
        };
        retryHistory = buildLocalRetryHistory(providerResponse.model);
        promptAudit = buildPromptAudit("deterministic-local", null);
        shouldWriteOutputArtifact = false;
        resultPromptMode = explicitPromptMode ?? "local";
        resultTemplateId = explicitTemplateId;
        hasAdditionalInstructions = false;
        hasExpertOverride = false;
        finishProcessingAuditStep(
            processingSteps,
            localGovernanceStep,
            "success",
            explicitSkipReason ?? "provider_not_requested"
        );
    } else {
        technicalBundleDump = await readTextFile(absolutePath);
        const promptBuildStep = startProcessingAuditStep("build_augmented_prompt_bundle");
        const promptPayload = buildAugmentedPromptBundle({
            projectName: inferredProjectName,
            technicalBundleDump,
            executorTarget,
            routeMode: outputRouteMode,
            mode,
            extractionMode,
            promptConfig
        });

        finishProcessingAuditStep(processingSteps, promptBuildStep, "success");
        promptAudit = buildPromptAudit("remote-provider", promptPayload);

        const providerChainResult = await tryProviderChain(provider, promptPayload, modelOverride);
        providerResponse = providerChainResult.response;
        retryHistory = providerChainResult.retryHistory;

        finalMarkdown =
            outputRouteMode === "director"
                ? buildDirectorEliteV3MarkdownDocument(
                      await repairDirectorResponseContract(
                          providerResponse.content,
                          extractionMode,
                          provider,
                          processingSteps,
                          modelOverride
                      ),
                      technicalBundleDump,
                      {
                          projectName: inferredProjectName,
                          sourceArtifact: sourceArtifactName,
                          executorTarget,
                          routeMode: outputRouteMode,
                          generatedAt
                      },
                      extractionMode
                  )
                : buildStructuredMarkdownDocument(
                      await repairStructuredPayload(
                          providerResponse.content,
                          outputRouteMode,
                          mode,
                          extractionMode,
                          provider,
                          processingSteps,
                          modelOverride
                      ),
                      technicalBundleDump,
                      extractionMode
                  );
    }

    const outputBaseDir = path.dirname(absolutePath);
    const modeLabel = extractionMode === "sniper" ? "manual" : extractionMode === "blueprint" ? "blueprint" : "bundle";
    const routeLabel = outputRouteMode === "director" ? "diretor" : "executor";
    const providerStr = providerResponse.provider !== "local" ? `_${providerResponse.provider}` : "";
    const prefixStr = outputRouteMode === "director" ? "_meta-prompt" : "";

    const fallbackOutputPath = path.join(
        outputBaseDir,
        `${prefixStr}_${modeLabel}_${routeLabel}${providerStr}__${inferredProjectName}.md`
    );
    const finalOutputPath = explicitOutputPath ? path.resolve(explicitOutputPath) : fallbackOutputPath;

    /**
     * Mantém o diretório explicitamente pedido pelo chamador, mas força o basename
     * do metadata a espelhar exatamente o basename do artefato Markdown final.
     *
     * Exemplo:
     *   outputPath     -> C:\dev\monitor\_blueprint_executor_gemini__monitor.md
     *   resultMetaPath -> C:\dev\monitor\_blueprint_executor_gemini__monitor.json
     *
     * Isso neutraliza nomes legados injetados pelo caller via --resultMetaPath,
     * sem remover a capacidade de escolher outro diretório para o metadata.
     */
    const resultMetaDir = explicitResultMetaPath
        ? path.dirname(path.resolve(explicitResultMetaPath))
        : path.dirname(finalOutputPath);

    const finalResultMetaPath = path.join(
        resultMetaDir,
        `${path.basename(finalOutputPath, path.extname(finalOutputPath))}.json`
    );

    const writeOutputStep = startProcessingAuditStep("write_final_output_markdown");
    if (shouldWriteOutputArtifact) {
        await writeTextFile(finalOutputPath, finalMarkdown);
        finishProcessingAuditStep(processingSteps, writeOutputStep, "success", finalOutputPath);
    } else {
        finishProcessingAuditStep(processingSteps, writeOutputStep, "success", `reused_existing_output:${finalOutputPath}`);
    }

    const durationMs = Date.now() - executionStartedAtMs;
    const environment = buildEnvironmentExecutionContext();
    const user = buildUserExecutionContext();

    let responseAudit: ResponseAudit;
    if (isGenericLocalGovernance) {
        const localOutputText = await readOptionalTextFileForAudit(finalOutputPath);
        const localOutputSha256 = await computeFileSha256(finalOutputPath);
        responseAudit = buildResponseAudit({
            interactionMode: "deterministic-local",
            providerRawContent: null,
            finalMarkdown: localOutputText ?? "",
            finalMarkdownSha256Override: localOutputSha256,
            finalMarkdownPreviewOverride: createAuditPreview(localOutputText),
            finalMarkdownCharLengthOverride: localOutputText ? localOutputText.length : 0
        });
    } else {
        responseAudit = buildResponseAudit({
            interactionMode: providerResponse.provider === "local" ? "deterministic-local" : "remote-provider",
            providerRawContent: providerResponse.provider === "local" ? null : providerResponse.content,
            finalMarkdown
        });
    }

    const resultMeta = {
        ok: true,
        executionId,
        provider: providerResponse.provider,
        model: providerResponse.model,
        routeMode: outputRouteMode,
        extractionMode,
        documentMode: mode,
        promptMode: resultPromptMode,
        templateId: resultTemplateId,
        hasAdditionalInstructions,
        hasExpertOverride,
        outputPath: finalOutputPath,
        resultMetaPath: finalResultMetaPath,
        bundlePath: absolutePath,
        bundleHash,
        generatedAt,
        durationMs,
        generatedWithoutProvider: providerResponse.provider === "local",
        promptGenerationSkipped: isGenericLocalGovernance,
        ...(isGenericLocalGovernance && explicitSkipReason ? { skippedReason: explicitSkipReason } : {}),
        environment,
        user,
        retryHistory,
        promptAudit,
        responseAudit,
        processingAudit: {
            steps: processingSteps
        }
    };

    const writeMetaStep = startProcessingAuditStep("write_result_meta_json");
    await writeTextFile(finalResultMetaPath, JSON.stringify(resultMeta, null, 2));
    finishProcessingAuditStep(processingSteps, writeMetaStep, "success", finalResultMetaPath);

    resultMeta.processingAudit = {
        steps: processingSteps
    };
    await writeTextFile(finalResultMetaPath, JSON.stringify(resultMeta, null, 2));

    process.stdout.write(
        `[_ai_] provider=${providerResponse.provider};model=${providerResponse.model}\n`
    );

    process.stdout.write(
        JSON.stringify(
            {
                ok: true,
                executionId,
                outputPath: finalOutputPath,
                resultMetaPath: finalResultMetaPath,
                provider: providerResponse.provider,
                model: providerResponse.model,
                routeMode: outputRouteMode,
                extractionMode,
                promptMode: promptConfig.promptMode,
                templateId: promptConfig.templateId,
                durationMs,
                bundleHash
            },
            null,
            2
        )
    );
}

main().catch((error) => {
    const classified = classifyError(error);
    const message = error instanceof Error ? error.message : String(error);
    const details = error instanceof AgentRuntimeError ? error.details : classified.details;

    if (details) {
        console.error(`[!] ERRO: ${message}`);
        console.error(`    Detalhes técnicos: ${details}`);
    } else {
        console.error(`[!] ERRO: ${message}`);
    }

    process.stderr.write(
        `[AI_ERROR] ${JSON.stringify({
            type: classified.errorType,
            status: classified.status,
            message,
            details
        })}\n`
    );

    process.exit(getExitCodeForErrorType(classified.errorType));
});

function assertDeterministicTemplateLoaded(promptConfig: PromptCustomizationConfig): void {
    if (
        promptConfig.templateId === "director_meta_v1" &&
        promptConfig.promptMode !== "template"
    ) {
        throw new Error("Prompt config inconsistente: director_meta_v1 exige promptMode=template.");
    }
}

;