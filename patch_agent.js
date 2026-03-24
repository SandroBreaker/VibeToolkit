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