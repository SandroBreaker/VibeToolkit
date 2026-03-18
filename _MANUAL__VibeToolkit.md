text
<system_instruction>
ROLE: SENIOR_ENGINEERING_EXECUTOR

OBJECTIVE:
Executar alterações técnicas com precisão, previsibilidade e zero impacto colateral.

NON_NEGOTIABLES:
- Tipagem estrita.
- Contratos claros.
- Princípios de design preservados.
- Nenhuma regressão funcional.
- Nenhuma modificação fora do escopo explícito.

PERFORMANCE_ENFORCEMENT:
- Eficiência antes de abstração.
- Evitar operações redundantes.
- Simplicidade como regra.

ERROR_POLICY:
- Falhas tratadas explicitamente.
- Assíncronos sempre controlados.
- Logs apenas quando necessários.

OUTPUT_RULES:
- Entrega completa.
- Nada fragmentado.
- Identificadores preservados.
- Sem comentários supérfluos.

INTERACTION_MODEL:
- Respostas curtas.
- Código como artefato principal.

FLOW:
1. Receber entrada.
2. Validar contexto.
3. Executar exatamente o solicitado.
4. Aguardar próxima instrução.

</system_instruction>
`


## MODO MANUAL: VibeToolkit

### 0. ANALYSIS SCOPE
```text
ESCOPO: FECHADO / PARCIAL
Este bundle contém apenas os arquivos selecionados manualmente pelo usuário.
Qualquer análise, resumo ou prompt derivado DEVE considerar exclusivamente os arquivos listados neste artefato.
É proibido inferir estrutura global, módulos ausentes, dependências não visíveis ou comportamento de partes não incluídas.
Quando faltar contexto, declarar explicitamente: 'não visível no recorte enviado'.
```

### 1. PROJECT STRUCTURE
```text
.\groq-agent.ts
.\package.json
.\project-bundler.ps1
.\README.md
.\tsconfig.json
.\_COPIAR_TUDO__VibeToolkit.md
```

### 2. SOURCE FILES

#### File: .\groq-agent.ts
```text
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

$ProjectName = (Get-Item .).Name
$ScriptFullPath = $MyInvocation.MyCommand.Path
$ToolkitDir = Split-Path $ScriptFullPath

$Choice = $null
$ExecutorTarget = $null
$FilesToProcess = @()
$SendToAI = $false
$AIProvider = $null

$ThemeBg = [System.Drawing.ColorTranslator]::FromHtml("#0F0F0C")
$ThemePanel = [System.Drawing.ColorTranslator]::FromHtml("#161613")
$ThemePanelAlt = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1A")
$ThemeBorder = [System.Drawing.ColorTranslator]::FromHtml("#22221E")
$ThemeText = [System.Drawing.ColorTranslator]::FromHtml("#F3F6F7")
$ThemeMuted = [System.Drawing.ColorTranslator]::FromHtml("#A6ADB3")
$ThemeCyan = [System.Drawing.ColorTranslator]::FromHtml("#00E5FF")
$ThemePink = [System.Drawing.ColorTranslator]::FromHtml("#FF1493")
$ThemeSuccess = [System.Drawing.ColorTranslator]::FromHtml("#22C55E")

$AllowedExtensions = @(
    ".tsx", ".ts", ".js", ".jsx", ".css", ".html", ".json", ".prisma", ".sql", ".yaml", ".md",
    ".py", ".java", ".cs", ".c", ".cpp", ".h", ".hpp", ".go", ".rb", ".php", ".rs", ".swift", ".kt", ".scala", ".dart", ".r", ".sh", ".bat", ".ps1", ".csv"
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

function Get-RelevantFiles {
    param([string]$CurrentPath)

    try {
        $Items = Get-ChildItem -Path $CurrentPath -ErrorAction Stop
        foreach ($Item in $Items) {
            if ($Item.PSIsContainer) {
                if ($Item.Name -notin $IgnoredDirs) {
                    Get-RelevantFiles -CurrentPath $Item.FullName
                }
            } else {
                $IsTarget = ($Item.Extension -in $AllowedExtensions) -and
                    ($Item.Name -notin $IgnoredFiles) -and
                    ($Item.BaseName -notmatch '-[a-f0-9]{8,}$') -and
                    ($Item.Name -notmatch '^_BUNDLER__') -and
                    ($Item.Name -notmatch '^_BLUEPRINT__') -and
                    ($Item.Name -notmatch '^_SELECTIVE__') -and
                    ($Item.Name -notmatch '^_AI_CONTEXT_')

                if ($IsTarget) { $Item }
            }
        }
    } catch {
    }
}

$FoundFiles = @(Get-RelevantFiles -CurrentPath (Get-Location).Path)

if ($FoundFiles.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show(
        "Nenhum arquivo válido encontrado no diretório atual.",
        "VibeToolkit",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null
    exit
}

function Resolve-ChoiceFromUI {
    param(
        [System.Windows.Forms.RadioButton]$RbFull,
        [System.Windows.Forms.RadioButton]$RbArchitect,
        [System.Windows.Forms.RadioButton]$RbSniper
    )

    if ($RbFull.Checked) { return '1' }
    if ($RbArchitect.Checked) { return '2' }
    if ($RbSniper.Checked) { return '3' }
    return $null
}

function Resolve-ExecutorFromUI {
    param(
        [System.Windows.Forms.RadioButton]$RbAIStudio,
        [System.Windows.Forms.RadioButton]$RbAntigravity
    )

    if ($RbAIStudio.Checked) { return "AI Studio Apps" }
    if ($RbAntigravity.Checked) { return "Antigravity" }
    return $null
}

function Resolve-AIProviderFromUI {
    param(
        [System.Windows.Forms.RadioButton]$RbGroq,
        [System.Windows.Forms.RadioButton]$RbGemini,
        [System.Windows.Forms.RadioButton]$RbOpenAI,
        [System.Windows.Forms.RadioButton]$RbAnthropic
    )

    if ($RbGroq.Checked) { return "groq" }
    if ($RbGemini.Checked) { return "gemini" }
    if ($RbOpenAI.Checked) { return "openai" }
    if ($RbAnthropic.Checked) { return "anthropic" }
    return $null
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Vibe AI Toolkit"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(860, 820)
$form.MinimumSize = New-Object System.Drawing.Size(860, 720)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.BackColor = $ThemeBg
$form.ForeColor = $ThemeText
$form.TopMost = $false

$script:PreferredNormalSize = New-Object System.Drawing.Size(860, 820)
$script:PreferredSniperSize = New-Object System.Drawing.Size(860, 1040)
$script:IsDragging = $false
$script:DragCursor = [System.Drawing.Point]::Empty
$script:DragForm = [System.Drawing.Point]::Empty
$script:IsResizing = $false
$script:ResizeCursor = [System.Drawing.Point]::Empty
$script:ResizeBounds = [System.Drawing.Rectangle]::Empty

function Get-WorkingAreaForBounds {
    param([System.Drawing.Rectangle]$Bounds)
    return [System.Windows.Forms.Screen]::FromRectangle($Bounds).WorkingArea
}

function Clamp-RectangleToWorkingArea {
    param([System.Drawing.Rectangle]$Bounds)

    $workingArea = Get-WorkingAreaForBounds -Bounds $Bounds

    $minWidth = [Math]::Max($form.MinimumSize.Width, 640)
    $minHeight = [Math]::Max($form.MinimumSize.Height, 520)

    $targetWidth = [Math]::Min([Math]::Max($Bounds.Width, $minWidth), $workingArea.Width)
    $targetHeight = [Math]::Min([Math]::Max($Bounds.Height, $minHeight), $workingArea.Height)

    $targetX = $Bounds.X
    $targetY = $Bounds.Y

    if ($targetX -lt $workingArea.Left) {
        $targetX = $workingArea.Left
    }
    if ($targetY -lt $workingArea.Top) {
        $targetY = $workingArea.Top
    }
    if (($targetX + $targetWidth) -gt $workingArea.Right) {
        $targetX = $workingArea.Right - $targetWidth
    }
    if (($targetY + $targetHeight) -gt $workingArea.Bottom) {
        $targetY = $workingArea.Bottom - $targetHeight
    }

    return New-Object System.Drawing.Rectangle($targetX, $targetY, $targetWidth, $targetHeight)
}

function Set-FormBoundsSafe {
    param(
        [int]$Width,
        [int]$Height,
        [bool]$PreserveLocation = $true
    )

    $baseLocation = if ($PreserveLocation) { $form.Location } else { [System.Drawing.Point]::Empty }
    $requestedBounds = New-Object System.Drawing.Rectangle($baseLocation.X, $baseLocation.Y, $Width, $Height)
    $safeBounds = Clamp-RectangleToWorkingArea -Bounds $requestedBounds
    $form.SetBounds($safeBounds.X, $safeBounds.Y, $safeBounds.Width, $safeBounds.Height)
}

function Ensure-FormVisible {
    $currentBounds = New-Object System.Drawing.Rectangle($form.Left, $form.Top, $form.Width, $form.Height)
    $safeBounds = Clamp-RectangleToWorkingArea -Bounds $currentBounds

    if (
        $safeBounds.X -ne $form.Left -or
        $safeBounds.Y -ne $form.Top -or
        $safeBounds.Width -ne $form.Width -or
        $safeBounds.Height -ne $form.Height
    ) {
        $form.SetBounds($safeBounds.X, $safeBounds.Y, $safeBounds.Width, $safeBounds.Height)
    }
}

$DragMouseDown = {
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left -and -not $script:IsResizing) {
        $script:IsDragging = $true
        $script:DragCursor = [System.Windows.Forms.Cursor]::Position
        $script:DragForm = $form.Location
    }
}

$DragMouseMove = {
    if ($script:IsDragging) {
        $currentCursor = [System.Windows.Forms.Cursor]::Position
        $newX = $script:DragForm.X + $currentCursor.X - $script:DragCursor.X
        $newY = $script:DragForm.Y + $currentCursor.Y - $script:DragCursor.Y

        $candidate = New-Object System.Drawing.Rectangle($newX, $newY, $form.Width, $form.Height)
        $safeBounds = Clamp-RectangleToWorkingArea -Bounds $candidate
        $form.Location = New-Object System.Drawing.Point($safeBounds.X, $safeBounds.Y)
    }
}

$DragMouseUp = {
    $script:IsDragging = $false
}

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

$resizeGrip = New-Object System.Windows.Forms.Panel
$resizeGrip.Size = New-Object System.Drawing.Size(18, 18)
$resizeGrip.BackColor = $ThemePanelAlt
$resizeGrip.Cursor = [System.Windows.Forms.Cursors]::SizeNWSE
$resizeGrip.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($resizeGrip)

$ResizeMouseDown = {
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:IsResizing = $true
        $script:ResizeCursor = [System.Windows.Forms.Cursor]::Position
        $script:ResizeBounds = $form.Bounds
    }
}

$ResizeMouseMove = {
    if ($script:IsResizing) {
        $currentCursor = [System.Windows.Forms.Cursor]::Position
        $deltaX = $currentCursor.X - $script:ResizeCursor.X
        $deltaY = $currentCursor.Y - $script:ResizeCursor.Y

        $requestedWidth = $script:ResizeBounds.Width + $deltaX
        $requestedHeight = $script:ResizeBounds.Height + $deltaY

        $candidate = New-Object System.Drawing.Rectangle(
            $script:ResizeBounds.X,
            $script:ResizeBounds.Y,
            $requestedWidth,
            $requestedHeight
        )
        $safeBounds = Clamp-RectangleToWorkingArea -Bounds $candidate
        $form.SetBounds($safeBounds.X, $safeBounds.Y, $safeBounds.Width, $safeBounds.Height)
    }
}

$ResizeMouseUp = {
    $script:IsResizing = $false
}

$resizeGrip.Add_MouseDown($ResizeMouseDown)
$resizeGrip.Add_MouseMove($ResizeMouseMove)
$resizeGrip.Add_MouseUp($ResizeMouseUp)

$titleBar.Add_MouseDown($DragMouseDown)
$titleBar.Add_MouseMove($DragMouseMove)
$titleBar.Add_MouseUp($DragMouseUp)
$titleLabel.Add_MouseDown($DragMouseDown)
$titleLabel.Add_MouseMove($DragMouseMove)
$titleLabel.Add_MouseUp($DragMouseUp)
$subTitleLabel.Add_MouseDown($DragMouseDown)
$subTitleLabel.Add_MouseMove($DragMouseMove)
$subTitleLabel.Add_MouseUp($DragMouseUp)

$panelMode = New-Object System.Windows.Forms.GroupBox
$panelMode.Text = "Modo de Extração"
$panelMode.ForeColor = $ThemeCyan
$panelMode.BackColor = $ThemePanel
$panelMode.Size = New-Object System.Drawing.Size(395, 162)
$panelMode.Location = New-Object System.Drawing.Point(18, 84)
$panelMode.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelMode.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($panelMode)

$rbFull = New-Object System.Windows.Forms.RadioButton
$rbFull.Text = "Full Vibe — enviar tudo"
$rbFull.ForeColor = $ThemeText
$rbFull.BackColor = $ThemePanel
$rbFull.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbFull.Location = New-Object System.Drawing.Point(18, 34)
$rbFull.Size = New-Object System.Drawing.Size(330, 24)
$rbFull.Checked = $true
$panelMode.Controls.Add($rbFull)

$lblFull = New-Object System.Windows.Forms.Label
$lblFull.Text = "Ideal para análise completa, bugs e contexto integral."
$lblFull.ForeColor = $ThemeMuted
$lblFull.BackColor = $ThemePanel
$lblFull.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblFull.AutoSize = $true
$lblFull.Location = New-Object System.Drawing.Point(38, 58)
$panelMode.Controls.Add($lblFull)

$rbArchitect = New-Object System.Windows.Forms.RadioButton
$rbArchitect.Text = "Architect — blueprint / estrutura"
$rbArchitect.ForeColor = $ThemeText
$rbArchitect.BackColor = $ThemePanel
$rbArchitect.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbArchitect.Location = New-Object System.Drawing.Point(18, 84)
$rbArchitect.Size = New-Object System.Drawing.Size(330, 24)
$panelMode.Controls.Add($rbArchitect)

$lblArchitect = New-Object System.Windows.Forms.Label
$lblArchitect.Text = "Economiza tokens e foca em contratos e assinaturas."
$lblArchitect.ForeColor = $ThemeMuted
$lblArchitect.BackColor = $ThemePanel
$lblArchitect.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblArchitect.AutoSize = $true
$lblArchitect.Location = New-Object System.Drawing.Point(38, 108)
$panelMode.Controls.Add($lblArchitect)

$rbSniper = New-Object System.Windows.Forms.RadioButton
$rbSniper.Text = "Sniper — seleção manual"
$rbSniper.ForeColor = $ThemeText
$rbSniper.BackColor = $ThemePanel
$rbSniper.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbSniper.Location = New-Object System.Drawing.Point(18, 134)
$rbSniper.Size = New-Object System.Drawing.Size(330, 24)
$panelMode.Controls.Add($rbSniper)

$panelExecutor = New-Object System.Windows.Forms.GroupBox
$panelExecutor.Text = "Executor Alvo"
$panelExecutor.ForeColor = $ThemePink
$panelExecutor.BackColor = $ThemePanel
$panelExecutor.Size = New-Object System.Drawing.Size(409, 162)
$panelExecutor.Location = New-Object System.Drawing.Point(433, 84)
$panelExecutor.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelExecutor.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($panelExecutor)

$rbAIStudio = New-Object System.Windows.Forms.RadioButton
$rbAIStudio.Text = "AI Studio Apps"
$rbAIStudio.ForeColor = $ThemeText
$rbAIStudio.BackColor = $ThemePanel
$rbAIStudio.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbAIStudio.Location = New-Object System.Drawing.Point(18, 38)
$rbAIStudio.Size = New-Object System.Drawing.Size(240, 24)
$rbAIStudio.Checked = $true
$panelExecutor.Controls.Add($rbAIStudio)

$lblAIStudio = New-Object System.Windows.Forms.Label
$lblAIStudio.Text = "Orquestrador prepara output otimizado para AI Studio Apps."
$lblAIStudio.ForeColor = $ThemeMuted
$lblAIStudio.BackColor = $ThemePanel
$lblAIStudio.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblAIStudio.AutoSize = $true
$lblAIStudio.Location = New-Object System.Drawing.Point(38, 62)
$panelExecutor.Controls.Add($lblAIStudio)

$rbAntigravity = New-Object System.Windows.Forms.RadioButton
$rbAntigravity.Text = "Antigravity"
$rbAntigravity.ForeColor = $ThemeText
$rbAntigravity.BackColor = $ThemePanel
$rbAntigravity.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbAntigravity.Location = New-Object System.Drawing.Point(18, 92)
$rbAntigravity.Size = New-Object System.Drawing.Size(240, 24)
$panelExecutor.Controls.Add($rbAntigravity)

$lblAntigravity = New-Object System.Windows.Forms.Label
$lblAntigravity.Text = "Prepara o bundle para o fluxo Gemini/ChatGPT → Antigravity."
$lblAntigravity.ForeColor = $ThemeMuted
$lblAntigravity.BackColor = $ThemePanel
$lblAntigravity.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblAntigravity.AutoSize = $true
$lblAntigravity.Location = New-Object System.Drawing.Point(38, 116)
$panelExecutor.Controls.Add($lblAntigravity)

$panelProvider = New-Object System.Windows.Forms.GroupBox
$panelProvider.Text = "IA Orquestradora"
$panelProvider.ForeColor = $ThemeCyan
$panelProvider.BackColor = $ThemePanel
$panelProvider.Size = New-Object System.Drawing.Size(824, 118)
$panelProvider.Location = New-Object System.Drawing.Point(18, 262)
$panelProvider.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelProvider.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($panelProvider)

$providerHint = New-Object System.Windows.Forms.Label
$providerHint.Text = "Escolha a IA primária. Se ela falhar ou atingir limite, o agente tenta a próxima automaticamente."
$providerHint.ForeColor = $ThemeMuted
$providerHint.BackColor = $ThemePanel
$providerHint.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$providerHint.AutoSize = $true
$providerHint.Location = New-Object System.Drawing.Point(18, 28)
$panelProvider.Controls.Add($providerHint)

$rbGroq = New-Object System.Windows.Forms.RadioButton
$rbGroq.Text = "Groq"
$rbGroq.ForeColor = $ThemeText
$rbGroq.BackColor = $ThemePanel
$rbGroq.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbGroq.Location = New-Object System.Drawing.Point(18, 62)
$rbGroq.Size = New-Object System.Drawing.Size(120, 24)
$rbGroq.Checked = $true
$panelProvider.Controls.Add($rbGroq)

$rbGemini = New-Object System.Windows.Forms.RadioButton
$rbGemini.Text = "Gemini"
$rbGemini.ForeColor = $ThemeText
$rbGemini.BackColor = $ThemePanel
$rbGemini.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbGemini.Location = New-Object System.Drawing.Point(162, 62)
$rbGemini.Size = New-Object System.Drawing.Size(120, 24)
$panelProvider.Controls.Add($rbGemini)

$rbOpenAI = New-Object System.Windows.Forms.RadioButton
$rbOpenAI.Text = "OpenAI"
$rbOpenAI.ForeColor = $ThemeText
$rbOpenAI.BackColor = $ThemePanel
$rbOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbOpenAI.Location = New-Object System.Drawing.Point(306, 62)
$rbOpenAI.Size = New-Object System.Drawing.Size(120, 24)
$panelProvider.Controls.Add($rbOpenAI)

$rbAnthropic = New-Object System.Windows.Forms.RadioButton
$rbAnthropic.Text = "Anthropic"
$rbAnthropic.ForeColor = $ThemeText
$rbAnthropic.BackColor = $ThemePanel
$rbAnthropic.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbAnthropic.Location = New-Object System.Drawing.Point(450, 62)
$rbAnthropic.Size = New-Object System.Drawing.Size(140, 24)
$panelProvider.Controls.Add($rbAnthropic)

$providerFallbackLabel = New-Object System.Windows.Forms.Label
$providerFallbackLabel.Text = "Fallback: Groq → Gemini → OpenAI → Anthropic (a ordem começa pela IA escolhida)."
$providerFallbackLabel.ForeColor = $ThemePink
$providerFallbackLabel.BackColor = $ThemePanel
$providerFallbackLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$providerFallbackLabel.AutoSize = $true
$providerFallbackLabel.Location = New-Object System.Drawing.Point(594, 66)
$panelProvider.Controls.Add($providerFallbackLabel)

$panelSniper = New-Object System.Windows.Forms.GroupBox
$panelSniper.Text = "Preview de Arquivos — Sniper Mode"
$panelSniper.ForeColor = $ThemeCyan
$panelSniper.BackColor = $ThemePanel
$panelSniper.Size = New-Object System.Drawing.Size(824, 210)
$panelSniper.Location = New-Object System.Drawing.Point(18, 396)
$panelSniper.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelSniper.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$panelSniper.Visible = $false
$form.Controls.Add($panelSniper)

$sniperHint = New-Object System.Windows.Forms.Label
$sniperHint.Text = "Selecione os arquivos que entrarão no bundle manual."
$sniperHint.ForeColor = $ThemeMuted
$sniperHint.BackColor = $ThemePanel
$sniperHint.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$sniperHint.AutoSize = $true
$sniperHint.Location = New-Object System.Drawing.Point(18, 28)
$panelSniper.Controls.Add($sniperHint)

$checkedFiles = New-Object System.Windows.Forms.CheckedListBox
$checkedFiles.BackColor = $ThemePanelAlt
$checkedFiles.ForeColor = $ThemeText
$checkedFiles.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$checkedFiles.CheckOnClick = $true
$checkedFiles.Font = New-Object System.Drawing.Font("Consolas", 9)
$checkedFiles.Location = New-Object System.Drawing.Point(18, 54)
$checkedFiles.Size = New-Object System.Drawing.Size(788, 130)
$checkedFiles.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$panelSniper.Controls.Add($checkedFiles)

foreach ($file in $FoundFiles) {
    $relPath = Resolve-Path -Path $file.FullName -Relative
    [void]$checkedFiles.Items.Add($relPath, $true)
}

$lblFileCount = New-Object System.Windows.Forms.Label
$lblFileCount.Text = "Arquivos detectados: $($FoundFiles.Count)"
$lblFileCount.ForeColor = $ThemeMuted
$lblFileCount.BackColor = $ThemePanel
$lblFileCount.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblFileCount.AutoSize = $true
$lblFileCount.Location = New-Object System.Drawing.Point(18, 188)
$panelSniper.Controls.Add($lblFileCount)

$chkSendToAI = New-Object System.Windows.Forms.CheckBox
$chkSendToAI.Text = "Gerar o Prompt Final com IA ao concluir"
$chkSendToAI.ForeColor = $ThemeText
$chkSendToAI.BackColor = $ThemeBg
$chkSendToAI.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$chkSendToAI.AutoSize = $true
$chkSendToAI.Location = New-Object System.Drawing.Point(18, 396)
$chkSendToAI.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($chkSendToAI)

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "ENERGIZE"
$btnRun.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnRun.FlatAppearance.BorderSize = 1
$btnRun.FlatAppearance.BorderColor = $ThemeCyan
$btnRun.BackColor = $ThemePanelAlt
$btnRun.ForeColor = $ThemeText
$btnRun.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnRun.Location = New-Object System.Drawing.Point(657, 390)
$btnRun.Size = New-Object System.Drawing.Size(185, 40)
$btnRun.Anchor = [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($btnRun)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
$progressBar.MarqueeAnimationSpeed = 30
$progressBar.Size = New-Object System.Drawing.Size(824, 12)
$progressBar.Location = New-Object System.Drawing.Point(18, 444)
$progressBar.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

$logViewer = New-Object System.Windows.Forms.RichTextBox
$logViewer.BackColor = $ThemePanelAlt
$logViewer.ForeColor = $ThemeText
$logViewer.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$logViewer.ReadOnly = $true
$logViewer.DetectUrls = $false
$logViewer.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$logViewer.Location = New-Object System.Drawing.Point(18, 466)
$logViewer.Size = New-Object System.Drawing.Size(824, 316)
$logViewer.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($logViewer)

function Update-ResponsiveLayout {
    $clientWidth = [int]$form.ClientSize.Width
    $clientHeight = [int]$form.ClientSize.Height

    $rightGap = 18
    $leftGap = 18
    $topContentY = 84
    $columnGap = 20
    $panelHeight = 162

    $usableWidth = [int]($clientWidth - ($leftGap * 2))
    $leftWidth = [int][Math]::Floor(($usableWidth - $columnGap) / 2)
    $rightWidth = [int]($usableWidth - $leftWidth - $columnGap)

    $panelMode.Location = New-Object System.Drawing.Point($leftGap, $topContentY)
    $panelMode.Size = New-Object System.Drawing.Size($leftWidth, $panelHeight)

    $executorX = [int]($leftGap + $leftWidth + $columnGap)
    $panelExecutor.Location = New-Object System.Drawing.Point($executorX, $topContentY)
    $panelExecutor.Size = New-Object System.Drawing.Size($rightWidth, $panelHeight)

    $panelProvider.Location = New-Object System.Drawing.Point($leftGap, 262)
    $panelProvider.Size = New-Object System.Drawing.Size($usableWidth, 118)

    $providerFallbackX = [int][Math]::Max(594, ($panelProvider.Width - $providerFallbackLabel.PreferredWidth - 18))
    $providerFallbackLabel.Location = New-Object System.Drawing.Point($providerFallbackX, 66)

    $providerHintMaxWidth = [int]($panelProvider.Width - 36)
    $providerHint.MaximumSize = New-Object System.Drawing.Size($providerHintMaxWidth, 0)

    $sniperTop = 396
    $panelSniper.Location = New-Object System.Drawing.Point($leftGap, $sniperTop)
    $panelSniper.Size = New-Object System.Drawing.Size($usableWidth, 210)

    $checkedFilesWidth = [int]($panelSniper.ClientSize.Width - 36)
    $checkedFiles.Size = New-Object System.Drawing.Size($checkedFilesWidth, 130)

    if ($panelSniper.Visible) {
        $chkY = [int]($panelSniper.Bottom + 22)
    } else {
        $chkY = 396
    }

    $chkSendToAI.Location = New-Object System.Drawing.Point($leftGap, $chkY)

    $btnRunX = [int]($clientWidth - $rightGap - $btnRun.Width)
    $btnRunY = [int]($chkY - 6)
    $btnRun.Location = New-Object System.Drawing.Point($btnRunX, $btnRunY)

    $progressBarY = [int]($chkY + 48)
    $progressBar.Location = New-Object System.Drawing.Point($leftGap, $progressBarY)
    $progressBar.Size = New-Object System.Drawing.Size($usableWidth, 12)

    $logTop = [int]($progressBar.Bottom + 10)
    $logHeight = [int][Math]::Max(140, ($clientHeight - $logTop - 20))
    $logViewer.Location = New-Object System.Drawing.Point($leftGap, $logTop)
    $logViewer.Size = New-Object System.Drawing.Size($usableWidth, $logHeight)

    $resizeGripX = [int]($clientWidth - $resizeGrip.Width)
    $resizeGripY = [int]($clientHeight - $resizeGrip.Height)
    $resizeGrip.Location = New-Object System.Drawing.Point($resizeGripX, $resizeGripY)
}

function Set-SniperLayout {
    param([bool]$Visible)

    $panelSniper.Visible = $Visible

    $preferredSize = if ($Visible) {
        $script:PreferredSniperSize
    } else {
        $script:PreferredNormalSize
    }

    Set-FormBoundsSafe -Width $preferredSize.Width -Height $preferredSize.Height -PreserveLocation $true
    Update-ResponsiveLayout
    Ensure-FormVisible
}

$rbSniper.Add_CheckedChanged({
    Set-SniperLayout -Visible $rbSniper.Checked
})

$rbFull.Add_CheckedChanged({
    if ($rbFull.Checked) { Set-SniperLayout -Visible $false }
})

$rbArchitect.Add_CheckedChanged({
    if ($rbArchitect.Checked) { Set-SniperLayout -Visible $false }
})

$form.Add_Shown({
    Set-SniperLayout -Visible $false
    Ensure-FormVisible
})

$form.Add_Move({
    if (-not $script:IsDragging -and -not $script:IsResizing) {
        Ensure-FormVisible
    }
})

$form.Add_SizeChanged({
    if (-not $script:IsResizing) {
        Ensure-FormVisible
    }
    Update-ResponsiveLayout
})

function Write-UILog {
    param(
        [string]$Message,
        [System.Drawing.Color]$Color = $ThemeText
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $logViewer.SelectionStart = $logViewer.TextLength
    $logViewer.SelectionLength = 0
    $logViewer.SelectionColor = $Color
    $logViewer.AppendText("[$timestamp] $Message`r`n")
    $logViewer.SelectionColor = $logViewer.ForeColor
    $logViewer.ScrollToCaret()
    $logViewer.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

function Set-UiBusy {
    param([bool]$Busy)

    $panelMode.Enabled = -not $Busy
    $panelExecutor.Enabled = -not $Busy
    $panelProvider.Enabled = -not $Busy
    $panelSniper.Enabled = -not $Busy
    $chkSendToAI.Enabled = -not $Busy
    $btnRun.Enabled = -not $Busy
    $progressBar.Visible = $Busy
}

function Invoke-OrchestratorAgent {
    param(
        [string]$AgentScriptPath,
        [string]$BundlePath,
        [string]$ProjectNameValue,
        [string]$ExecutorTargetValue,
        [string]$BundleModeValue,
        [string]$PrimaryProviderValue
    )

    if (-not (Test-Path $AgentScriptPath)) {
        throw "Script groq-agent.ts não localizado."
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $process.StartInfo.FileName = "cmd.exe"
    $process.StartInfo.Arguments = "/c npx --quiet tsx `"$AgentScriptPath`" `"$BundlePath`" `"$ProjectNameValue`" `"$ExecutorTargetValue`" `"$BundleModeValue`" `"$PrimaryProviderValue`""
    $process.StartInfo.WorkingDirectory = (Get-Location).Path
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true

    $env:DOTENV_CONFIG_SILENT = "true"

    if (-not $process.Start()) {
        throw "Falha ao iniciar o processo do agente de IA."
    }

    while (-not $process.HasExited) {
        while ($process.StandardOutput.Peek() -ge 0) {
            $line = $process.StandardOutput.ReadLine()
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                Write-UILog -Message $line -Color $ThemeCyan
            }
        }

        while ($process.StandardError.Peek() -ge 0) {
            $line = $process.StandardError.ReadLine()
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                Write-UILog -Message $line -Color $ThemePink
            }
        }

        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 100
    }

    while ($process.StandardOutput.Peek() -ge 0) {
        $line = $process.StandardOutput.ReadLine()
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            Write-UILog -Message $line -Color $ThemeCyan
        }
    }

    while ($process.StandardError.Peek() -ge 0) {
        $line = $process.StandardError.ReadLine()
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            Write-UILog -Message $line -Color $ThemePink
        }
    }

    $process.WaitForExit()

    if ($process.ExitCode -ne 0) {
        throw "groq-agent.ts finalizou com código $($process.ExitCode)."
    }
}

$btnRun.Add_Click({
    $currentChoice = Resolve-ChoiceFromUI -RbFull $rbFull -RbArchitect $rbArchitect -RbSniper $rbSniper
    $currentExecutorTarget = Resolve-ExecutorFromUI -RbAIStudio $rbAIStudio -RbAntigravity $rbAntigravity
    $currentAIProvider = Resolve-AIProviderFromUI -RbGroq $rbGroq -RbGemini $rbGemini -RbOpenAI $rbOpenAI -RbAnthropic $rbAnthropic

    if (-not $currentChoice) {
        [System.Windows.Forms.MessageBox]::Show(
            "Selecione um modo de extração.",
            "VibeToolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    if (-not $currentAIProvider) {
        [System.Windows.Forms.MessageBox]::Show(
            "Selecione a IA primária.",
            "VibeToolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    if (-not $currentExecutorTarget) {
        [System.Windows.Forms.MessageBox]::Show(
            "Selecione o executor alvo.",
            "VibeToolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    $selectedFiles = @()

    if ($currentChoice -eq '3') {
        for ($i = 0; $i -lt $checkedFiles.Items.Count; $i++) {
            if ($checkedFiles.GetItemChecked($i)) {
                $selectedFiles += $FoundFiles[$i]
            }
        }

        if ($selectedFiles.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "No modo Sniper, selecione pelo menos um arquivo.",
                "VibeToolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }
    } else {
        $selectedFiles = @($FoundFiles)
    }

    $Choice = $currentChoice
    $ExecutorTarget = $currentExecutorTarget
    $AIProvider = $currentAIProvider
    $FilesToProcess = @($selectedFiles)
    $SendToAI = $chkSendToAI.Checked

    Set-UiBusy -Busy $true
    $logViewer.Clear()

    try {
        Write-UILog -Message "HUD energizado." -Color $ThemeCyan
        Write-UILog -Message "Projeto detectado: $ProjectName"
        Write-UILog -Message "Modo selecionado: $(if ($Choice -eq '1') { 'Full Vibe' } elseif ($Choice -eq '2') { 'Architect' } else { 'Sniper' })"
        Write-UILog -Message "Executor alvo: $ExecutorTarget"
        Write-UILog -Message "IA primária: $AIProvider"
        Write-UILog -Message "Arquivos na operação: $($FilesToProcess.Count)"

        $HeaderContent = ""

        if ($ExecutorTarget -eq "AI Studio Apps") {
            $HeaderContent = @"
text
<system_instruction>
ROLE: SENIOR_ENGINEERING_EXECUTOR

OBJECTIVE:
Executar alterações técnicas com precisão, previsibilidade e zero impacto colateral.

NON_NEGOTIABLES:
- Tipagem estrita.
- Contratos claros.
- Princípios de design preservados.
- Nenhuma regressão funcional.
- Nenhuma modificação fora do escopo explícito.

PERFORMANCE_ENFORCEMENT:
- Eficiência antes de abstração.
- Evitar operações redundantes.
- Simplicidade como regra.

ERROR_POLICY:
- Falhas tratadas explicitamente.
- Assíncronos sempre controlados.
- Logs apenas quando necessários.

OUTPUT_RULES:
- Entrega completa.
- Nada fragmentado.
- Identificadores preservados.
- Sem comentários supérfluos.

INTERACTION_MODEL:
- Respostas curtas.
- Código como artefato principal.

FLOW:
1. Receber entrada.
2. Validar contexto.
3. Executar exatamente o solicitado.
4. Aguardar próxima instrução.

</system_instruction>
```

"@
} else {
$HeaderContent = @"
text
<system_instruction>
ROLE: SENIOR_ENGINEERING_EXECUTOR

OBJECTIVE:
Executar alterações técnicas com precisão, previsibilidade e zero impacto colateral.

NON_NEGOTIABLES:

* Tipagem estrita.
* Contratos claros.
* Princípios de design preservados.
* Nenhuma regressão funcional.
* Nenhuma modificação fora do escopo explícito.

PERFORMANCE_ENFORCEMENT:

* Eficiência antes de abstração.
* Evitar operações redundantes.
* Simplicidade como regra.

ERROR_POLICY:

* Falhas tratadas explicitamente.
* Assíncronos sempre controlados.
* Logs apenas quando necessários.

OUTPUT_RULES:

* Entrega completa.
* Nada fragmentado.
* Identificadores preservados.
* Sem comentários supérfluos.

INTERACTION_MODEL:

* Respostas curtas.
* Código como artefato principal.

FLOW:

1. Receber entrada.
2. Validar contexto.
3. Executar exatamente o solicitado.
4. Aguardar próxima instrução.

</system_instruction>

````
"@
        }

        $FinalContent = $HeaderContent + "`n`n"
        $BlueprintIssues = @()

        if ($Choice -eq '1' -or $Choice -eq '3') {
            if ($Choice -eq '1') {
                $OutputFile = "_COPIAR_TUDO__${ProjectName}.md"
                $HeaderTitle = "MODO COPIAR TUDO"
                Write-UILog -Message "Iniciando Modo Copiar Tudo..." -Color $ThemeCyan
            } else {
                $OutputFile = "_MANUAL__${ProjectName}.md"
                $HeaderTitle = "MODO MANUAL"
                Write-UILog -Message "Iniciando Modo Sniper / Manual..." -Color $ThemePink
            }

            $FinalContent += "## ${HeaderTitle}: $ProjectName`n`n"

            if ($Choice -eq '3') {
                $FinalContent += "### 0. ANALYSIS SCOPE`n"
                $FinalContent += '```text' + "`n"
                $FinalContent += "ESCOPO: FECHADO / PARCIAL`n"
                $FinalContent += "Este bundle contém apenas os arquivos selecionados manualmente pelo usuário.`n"
                $FinalContent += "Qualquer análise, resumo ou prompt derivado DEVE considerar exclusivamente os arquivos listados neste artefato.`n"
                $FinalContent += "É proibido inferir estrutura global, módulos ausentes, dependências não visíveis ou comportamento de partes não incluídas.`n"
                $FinalContent += "Quando faltar contexto, declarar explicitamente: 'não visível no recorte enviado'.`n"
                $FinalContent += '```' + "`n`n"
            }

            Write-UILog -Message "Montando estrutura do projeto..."
            $FinalContent += "### 1. PROJECT STRUCTURE`n" + '```text' + "`n"
            foreach ($File in $FilesToProcess) {
                $FinalContent += (Resolve-Path -Path $File.FullName -Relative) + "`n"
            }
            $FinalContent += '```' + "`n`n"

            Write-UILog -Message "Lendo arquivos e consolidando conteúdo..."
            $FinalContent += "### 2. SOURCE FILES`n`n"

            foreach ($File in $FilesToProcess) {
                $RelPath = Resolve-Path -Path $File.FullName -Relative
                Write-UILog -Message "Lendo $RelPath"
                $Content = Get-Content $File.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue

                if ($Content) {
                    $Content = $Content -replace "(`r?`n){3,}", "`r`n`r`n"
                    $FinalContent += "#### File: $RelPath`n"
                    $FinalContent += '```text' + "`n"
                    $FinalContent += $Content.TrimEnd() + "`n"
                    $FinalContent += '```' + "`n`n"
                }
            }
        } else {
            $OutputFile = "_INTELIGENTE__${ProjectName}.md"
            Write-UILog -Message "Iniciando Modo Architect / Inteligente..." -Color $ThemeCyan

            $FinalContent += "## MODO INTELIGENTE: $ProjectName`n`n"
            $FinalContent += "### 1. TECH STACK`n"

            if (Test-Path "package.json") {
                Write-UILog -Message "Lendo package.json para tech stack..."
                $Pkg = Get-Content "package.json" | ConvertFrom-Json
                if ($Pkg.dependencies) {
                    $FinalContent += "* **Deps:** $(($Pkg.dependencies.PSObject.Properties.Name -join ', '))`n"
                }
                if ($Pkg.devDependencies) {
                    $FinalContent += "* **Dev Deps:** $(($Pkg.devDependencies.PSObject.Properties.Name -join ', '))`n"
                }
            }

            $FinalContent += "`n"
            $FinalContent += "### 2. PROJECT STRUCTURE`n" + '```text' + "`n"
            foreach ($File in $FilesToProcess) {
                $FinalContent += (Resolve-Path -Path $File.FullName -Relative) + "`n"
            }
            $FinalContent += '```' + "`n`n"

            $FinalContent += "### 3. CORE DOMAINS & CONTRACTS`n"

            foreach ($File in $FilesToProcess) {
                if ($SignatureExtensions -contains $File.Extension) {
                    $RelPath = Resolve-Path -Path $File.FullName -Relative
                    Write-UILog -Message "Extraindo assinaturas de $RelPath"

                    $ContentRaw = Get-Content $File.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                    if (-not $ContentRaw) { continue }

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
                                        $Block += "$($Lines[$j])`n"
                                        $j++
                                    }
                                    if ($j -lt $Lines.Count) { $Block += "$($Lines[$j])`n" }
                                    $i = $j
                                }
                                $Signatures += $Block
                            } elseif ($Line -match '^(?:export\s+)?(?:const|function|class)\s+[A-Za-z0-9_]+') {
                                $Signature = ($Line -replace '\{.*$', '') -replace '\s*=>.*$', ''
                                $Signatures += "$Signature`n"
                            } elseif ($Line -match '^(?:public|protected|private|internal)\s+(?:class|interface|record|struct|enum)\s+[A-Za-z0-9_]+') {
                                $Signature = $Line -replace '\{.*$', ''
                                $Signatures += "$Signature`n"
                            } elseif ($Line -match '^(?:def|class)\s+[A-Za-z0-9_]+') {
                                $Signature = $Line -replace ':$', ''
                                $Signatures += "$Signature`n"
                            } elseif ($Line -match '^func\s+[A-Za-z0-9_]+') {
                                $Signature = $Line -replace '\{.*$', ''
                                $Signatures += "$Signature`n"
                            } elseif ($Line -match '^(?:pub\s+)?(?:fn|struct|enum|trait)\s+[A-Za-z0-9_]+') {
                                $Signature = $Line -replace '\{.*$', ''
                                $Signatures += "$Signature`n"
                            }
                        }
                    } catch {
                        $BlueprintIssues += "[$RelPath] $($_.Exception.Message)"
                        continue
                    }

                    if ($Signatures.Count -gt 0) {
                        $Ext = $File.Extension.TrimStart('.')
                        if ($Ext -match "^(tsx?)$") { $Ext = "typescript" }
                        elseif ($Ext -match "^(jsx?)$") { $Ext = "javascript" }
                        elseif ($Ext -match "^(py)$") { $Ext = "python" }
                        elseif ($Ext -match "^(cs)$") { $Ext = "csharp" }
                        elseif ($Ext -match "^(rb)$") { $Ext = "ruby" }
                        elseif ($Ext -match "^(rs)$") { $Ext = "rust" }
                        elseif ($Ext -match "^(kt)$") { $Ext = "kotlin" }
                        elseif ($Ext -match "^(go)$") { $Ext = "go" }
                        elseif ($Ext -match "^(java)$") { $Ext = "java" }
                        elseif ($Ext -match "^(php)$") { $Ext = "php" }
                        elseif ($Ext -match "^(c|h|cpp|hpp)$") { $Ext = "cpp" }

                        $FinalContent += "#### File: $RelPath`n" + '```' + $Ext + "`n"
                        $FinalContent += ($Signatures -join '')
                        $FinalContent += '```' + "`n`n"
                    }
                }
            }
        }

        Write-UILog -Message "Salvando artefato..."
        $OutputFullPath = Join-Path (Get-Location) $OutputFile

        $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($OutputFullPath, $FinalContent, $Utf8NoBom)

        $TokenEstimate = [math]::Round($FinalContent.Length / 4)

        try {
            $FinalContent | Set-Clipboard
            $Copied = $true
        } catch {
            $Copied = $false
        }

        if ($BlueprintIssues -and $BlueprintIssues.Count -gt 0) {
            Write-UILog -Message "Artefato gerado com $($BlueprintIssues.Count) aviso(s)." -Color $ThemePink
            foreach ($Issue in ($BlueprintIssues | Select-Object -First 10)) {
                Write-UILog -Message $Issue -Color $ThemePink
            }
        } else {
            Write-UILog -Message "Artefato consolidado com sucesso." -Color $ThemeSuccess
        }

        if ($Choice -eq '1') { $ModoNome = "Copiar Tudo" }
        elseif ($Choice -eq '2') { $ModoNome = "Inteligente" }
        else { $ModoNome = "Manual" }

        Write-UILog -Message "Modo: $ModoNome"
        Write-UILog -Message "Executor: $ExecutorTarget"
        Write-UILog -Message "IA primária: $AIProvider"
        Write-UILog -Message "Arquivo: $OutputFile"
        Write-UILog -Message "Tokens estimados: ~$TokenEstimate"

        if ($Copied) {
            Write-UILog -Message "Bundle copiado para a área de transferência." -Color $ThemeCyan
        } else {
            Write-UILog -Message "Arquivo salvo localmente; clipboard indisponível." -Color $ThemePink
        }

        if ($SendToAI) {
            Write-UILog -Message "Chamando agente de IA..." -Color $ThemeCyan
            Write-UILog -Message "Provider primário: $AIProvider | fallback automático ativo." -Color $ThemeCyan
            $AgentScript = Join-Path $ToolkitDir "groq-agent.ts"
            $BundleMode = if ($Choice -eq '1') { 'full' } elseif ($Choice -eq '2') { 'blueprint' } else { 'manual' }

            Invoke-OrchestratorAgent -AgentScriptPath $AgentScript -BundlePath $OutputFullPath -ProjectNameValue $ProjectName -ExecutorTargetValue $ExecutorTarget -BundleModeValue $BundleMode -PrimaryProviderValue $AIProvider

            $FinalSummarizedContent = Get-Content $OutputFullPath -Raw -Encoding UTF8
            try {
                $FinalSummarizedContent | Set-Clipboard
                Write-UILog -Message "Prompt final preparado e copiado para o clipboard." -Color $ThemeSuccess
            } catch {
                Write-UILog -Message "Prompt final preparado, mas não foi possível copiar para o clipboard." -Color $ThemePink
            }
            Write-UILog -Message "Verifique no log acima qual provider venceu o fallback." -Color $ThemeCyan
            Write-UILog -Message "Agora é só colar no seu orquestrador." -Color $ThemeCyan
        } else {
            Write-UILog -Message "Execução concluída sem chamada da Groq." -Color $ThemeSuccess
        }
    } catch {
        Write-UILog -Message $_.Exception.Message -Color $ThemePink
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            "Falha na execução",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    } finally {
        Set-UiBusy -Busy $false
    }
})

Write-UILog -Message "Pronto. Configure o modo, o executor e energize." -Color $ThemeCyan
[void]$form.ShowDialog()
```

#### File: .\README.md
```text
# 🚀 VibeToolkit
**AI Context Synthesizer for Orchestrators**

O **VibeToolkit** é uma ferramenta de infraestrutura para IA focada em transformar projetos de software em bundles estruturados. Ele prepara o contexto ideal para **orquestradores** (como ChatGPT Web e Gemini Web), que geram o prompt final para execução em ferramentas como **AI Studio Apps** ou **Antigravity**.

O objetivo central é eliminar alucinações por falta de contexto, gerando uma **Source of Truth** (Fonte de Verdade) consistente e previsível.

---

## 🛠️ Fluxo de Trabalho

1.  **Consolidação:** Lê e agrupa arquivos relevantes do projeto.
2.  **Bundling:** Gera um arquivo Markdown estruturado.
3.  **Injeção:** Embuti instruções específicas para o executor alvo.
4.  **Orquestração (Opcional):** Chama uma IA para refinar o contexto.
5.  **Entrega:** Copia o prompt final para o clipboard, pronto para o uso.

### Stack Técnica
* **Runtime:** Node.js via `tsx` (TypeScript)
* **Interface:** PowerShell + WinForms (HUD Visual)
* **Providers:** Groq, Gemini, OpenAI e Anthropic.
* **Comunicação:** REST/JSON com fallback inteligente.

---

## ✨ Principais Recursos

### 🔄 Multi-provider com Fallback Automático
Suporte nativo a Groq, Gemini, OpenAI e Anthropic. Se o provedor primário falhar (Rate limit, erro de autenticação ou indisponibilidade), o toolkit aciona automaticamente o próximo da cadeia.

### 📂 Modos de Extração
* **Full Vibe:** Conteúdo completo de todos os arquivos (Entendimento global).
* **Architect:** Extrai apenas estruturas, contratos e assinaturas (Economia de tokens).
* **Sniper:** Seleção manual de arquivos para correções cirúrgicas.

### 🎯 Executores Alvo
O bundle é otimizado especificamente para o comportamento do executor final:
* **AI Studio Apps**
* **Antigravity**

---

## 📂 Estrutura do Projeto

* `groq-agent.ts`: Motor principal de orquestração e lógica de fallback.
* `project-bundler.ps1`: Interface (HUD), leitura de arquivos e montagem do bundle.
* `package.json`: Gerenciamento de dependências e scripts.
* `tsconfig.json`: Configurações de tipagem estrita do TypeScript.

---

## ⚙️ Configuração

### 1. Instalação
```bash
npm install
```

### 2. Variáveis de Ambiente
Crie um arquivo `.env` na raiz do projeto:
```env
GROQ_API_KEY=sua_chave
GEMINI_API_KEY=sua_chave
OPENAI_API_KEY=sua_chave
ANTHROPIC_API_KEY=sua_chave

# Modelos Preferenciais
GROQ_MODEL=llama-3.3-70b-versatile
GEMINI_MODEL=gemini-1.5-pro
OPENAI_MODEL=gpt-4o
ANTHROPIC_MODEL=claude-3-5-sonnet-20240620
```

---

## 🚀 Como Usar

### Via Interface Visual (Recomendado)
Execute o script PowerShell para abrir o HUD de controle:
```powershell
.\project-bundler.ps1
```
No HUD, você poderá selecionar o modo de extração, o executor alvo e o provedor de IA.

### Via Linha de Comando (CLI)
Para integrar em outros fluxos, chame o agente diretamente:
```bash
npx tsx groq-agent.ts <caminho_bundle> <nome_projeto> <executor> <modo> <provedor>
```

---

## 🛡️ Política de Resiliência
O toolkit utiliza a classe `ProviderRequestError` para monitorar a saúde das requisições. O sistema realiza retries e fallbacks automáticos em casos de:
* Erros de autenticação ou chaves expiradas.
* Rate limiting (Excesso de requisições).
* Respostas vazias ou instabilidade do servidor.

---

## 🧠 Princípios do Projeto
* **Previsibilidade:** Markdown padronizado para evitar interpretações erradas.
* **Eficiência:** Foco em reduzir o consumo de tokens sem perder a essência do código.
* **Contexto Fechado:** No modo Sniper, a IA é instruída a não assumir nada além do que foi fornecido.
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

#### File: .\_COPIAR_TUDO__VibeToolkit.md
```text
text
<system_instruction>
ROLE: SENIOR_ENGINEERING_EXECUTOR

OBJECTIVE:
Executar alterações técnicas com precisão, previsibilidade e zero impacto colateral.

NON_NEGOTIABLES:
- Tipagem estrita.
- Contratos claros.
- Princípios de design preservados.
- Nenhuma regressão funcional.
- Nenhuma modificação fora do escopo explícito.

PERFORMANCE_ENFORCEMENT:
- Eficiência antes de abstração.
- Evitar operações redundantes.
- Simplicidade como regra.

ERROR_POLICY:
- Falhas tratadas explicitamente.
- Assíncronos sempre controlados.
- Logs apenas quando necessários.

OUTPUT_RULES:
- Entrega completa.
- Nada fragmentado.
- Identificadores preservados.
- Sem comentários supérfluos.

INTERACTION_MODEL:
- Respostas curtas.
- Código como artefato principal.

FLOW:
1. Receber entrada.
2. Validar contexto.
3. Executar exatamente o solicitado.
4. Aguardar próxima instrução.

</system_instruction>
`

## MODO COPIAR TUDO: VibeToolkit

### 1. PROJECT STRUCTURE
```text
.\groq-agent.ts
.\package.json
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

$ProjectName = (Get-Item .).Name
$ScriptFullPath = $MyInvocation.MyCommand.Path
$ToolkitDir = Split-Path $ScriptFullPath

$Choice = $null
$ExecutorTarget = $null
$FilesToProcess = @()
$SendToAI = $false
$AIProvider = $null

$ThemeBg = [System.Drawing.ColorTranslator]::FromHtml("#0F0F0C")
$ThemePanel = [System.Drawing.ColorTranslator]::FromHtml("#161613")
$ThemePanelAlt = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1A")
$ThemeBorder = [System.Drawing.ColorTranslator]::FromHtml("#22221E")
$ThemeText = [System.Drawing.ColorTranslator]::FromHtml("#F3F6F7")
$ThemeMuted = [System.Drawing.ColorTranslator]::FromHtml("#A6ADB3")
$ThemeCyan = [System.Drawing.ColorTranslator]::FromHtml("#00E5FF")
$ThemePink = [System.Drawing.ColorTranslator]::FromHtml("#FF1493")
$ThemeSuccess = [System.Drawing.ColorTranslator]::FromHtml("#22C55E")

$AllowedExtensions = @(
    ".tsx", ".ts", ".js", ".jsx", ".css", ".html", ".json", ".prisma", ".sql", ".yaml", ".md",
    ".py", ".java", ".cs", ".c", ".cpp", ".h", ".hpp", ".go", ".rb", ".php", ".rs", ".swift", ".kt", ".scala", ".dart", ".r", ".sh", ".bat", ".ps1", ".csv"
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

function Get-RelevantFiles {
    param([string]$CurrentPath)

    try {
        $Items = Get-ChildItem -Path $CurrentPath -ErrorAction Stop
        foreach ($Item in $Items) {
            if ($Item.PSIsContainer) {
                if ($Item.Name -notin $IgnoredDirs) {
                    Get-RelevantFiles -CurrentPath $Item.FullName
                }
            } else {
                $IsTarget = ($Item.Extension -in $AllowedExtensions) -and
                    ($Item.Name -notin $IgnoredFiles) -and
                    ($Item.BaseName -notmatch '-[a-f0-9]{8,}$') -and
                    ($Item.Name -notmatch '^_BUNDLER__') -and
                    ($Item.Name -notmatch '^_BLUEPRINT__') -and
                    ($Item.Name -notmatch '^_SELECTIVE__') -and
                    ($Item.Name -notmatch '^_AI_CONTEXT_')

                if ($IsTarget) { $Item }
            }
        }
    } catch {
    }
}

$FoundFiles = @(Get-RelevantFiles -CurrentPath (Get-Location).Path)

if ($FoundFiles.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show(
        "Nenhum arquivo válido encontrado no diretório atual.",
        "VibeToolkit",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null
    exit
}

function Resolve-ChoiceFromUI {
    param(
        [System.Windows.Forms.RadioButton]$RbFull,
        [System.Windows.Forms.RadioButton]$RbArchitect,
        [System.Windows.Forms.RadioButton]$RbSniper
    )

    if ($RbFull.Checked) { return '1' }
    if ($RbArchitect.Checked) { return '2' }
    if ($RbSniper.Checked) { return '3' }
    return $null
}

function Resolve-ExecutorFromUI {
    param(
        [System.Windows.Forms.RadioButton]$RbAIStudio,
        [System.Windows.Forms.RadioButton]$RbAntigravity
    )

    if ($RbAIStudio.Checked) { return "AI Studio Apps" }
    if ($RbAntigravity.Checked) { return "Antigravity" }
    return $null
}

function Resolve-AIProviderFromUI {
    param(
        [System.Windows.Forms.RadioButton]$RbGroq,
        [System.Windows.Forms.RadioButton]$RbGemini,
        [System.Windows.Forms.RadioButton]$RbOpenAI,
        [System.Windows.Forms.RadioButton]$RbAnthropic
    )

    if ($RbGroq.Checked) { return "groq" }
    if ($RbGemini.Checked) { return "gemini" }
    if ($RbOpenAI.Checked) { return "openai" }
    if ($RbAnthropic.Checked) { return "anthropic" }
    return $null
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Vibe AI Toolkit"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(860, 820)
$form.MinimumSize = New-Object System.Drawing.Size(860, 820)
$form.MaximumSize = New-Object System.Drawing.Size(860, 1040)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.BackColor = $ThemeBg
$form.ForeColor = $ThemeText
$form.TopMost = $false

$script:IsDragging = $false
$script:DragCursor = [System.Drawing.Point]::Empty
$script:DragForm = [System.Drawing.Point]::Empty

$DragMouseDown = {
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:IsDragging = $true
        $script:DragCursor = [System.Windows.Forms.Cursor]::Position
        $script:DragForm = $form.Location
    }
}

$DragMouseMove = {
    if ($script:IsDragging) {
        $currentCursor = [System.Windows.Forms.Cursor]::Position
        $form.Location = New-Object System.Drawing.Point(
            ($script:DragForm.X + $currentCursor.X - $script:DragCursor.X),
            ($script:DragForm.Y + $currentCursor.Y - $script:DragCursor.Y)
        )
    }
}

$DragMouseUp = {
    $script:IsDragging = $false
}

$titleBar = New-Object System.Windows.Forms.Panel
$titleBar.Size = New-Object System.Drawing.Size(860, 44)
$titleBar.Location = New-Object System.Drawing.Point(0, 0)
$titleBar.BackColor = $ThemePanelAlt
$titleBar.Cursor = [System.Windows.Forms.Cursors]::SizeAll
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
$form.Controls.Add($projectLabel)

$closeButton = New-Object System.Windows.Forms.Label
$closeButton.Text = "✕"
$closeButton.ForeColor = $ThemeText
$closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$closeButton.AutoSize = $true
$closeButton.Location = New-Object System.Drawing.Point(826, 9)
$closeButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$closeButton.Add_MouseEnter({ $closeButton.ForeColor = $ThemePink })
$closeButton.Add_MouseLeave({ $closeButton.ForeColor = $ThemeText })
$closeButton.Add_Click({ $form.Close() })
$titleBar.Controls.Add($closeButton)

$titleBar.Add_MouseDown($DragMouseDown)
$titleBar.Add_MouseMove($DragMouseMove)
$titleBar.Add_MouseUp($DragMouseUp)
$titleLabel.Add_MouseDown($DragMouseDown)
$titleLabel.Add_MouseMove($DragMouseMove)
$titleLabel.Add_MouseUp($DragMouseUp)
$subTitleLabel.Add_MouseDown($DragMouseDown)
$subTitleLabel.Add_MouseMove($DragMouseMove)
$subTitleLabel.Add_MouseUp($DragMouseUp)

$panelMode = New-Object System.Windows.Forms.GroupBox
$panelMode.Text = "Modo de Extração"
$panelMode.ForeColor = $ThemeCyan
$panelMode.BackColor = $ThemePanel
$panelMode.Size = New-Object System.Drawing.Size(395, 162)
$panelMode.Location = New-Object System.Drawing.Point(18, 84)
$panelMode.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($panelMode)

$rbFull = New-Object System.Windows.Forms.RadioButton
$rbFull.Text = "Full Vibe — enviar tudo"
$rbFull.ForeColor = $ThemeText
$rbFull.BackColor = $ThemePanel
$rbFull.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbFull.Location = New-Object System.Drawing.Point(18, 34)
$rbFull.Size = New-Object System.Drawing.Size(330, 24)
$rbFull.Checked = $true
$panelMode.Controls.Add($rbFull)

$lblFull = New-Object System.Windows.Forms.Label
$lblFull.Text = "Ideal para análise completa, bugs e contexto integral."
$lblFull.ForeColor = $ThemeMuted
$lblFull.BackColor = $ThemePanel
$lblFull.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblFull.AutoSize = $true
$lblFull.Location = New-Object System.Drawing.Point(38, 58)
$panelMode.Controls.Add($lblFull)

$rbArchitect = New-Object System.Windows.Forms.RadioButton
$rbArchitect.Text = "Architect — blueprint / estrutura"
$rbArchitect.ForeColor = $ThemeText
$rbArchitect.BackColor = $ThemePanel
$rbArchitect.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbArchitect.Location = New-Object System.Drawing.Point(18, 84)
$rbArchitect.Size = New-Object System.Drawing.Size(330, 24)
$panelMode.Controls.Add($rbArchitect)

$lblArchitect = New-Object System.Windows.Forms.Label
$lblArchitect.Text = "Economiza tokens e foca em contratos e assinaturas."
$lblArchitect.ForeColor = $ThemeMuted
$lblArchitect.BackColor = $ThemePanel
$lblArchitect.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblArchitect.AutoSize = $true
$lblArchitect.Location = New-Object System.Drawing.Point(38, 108)
$panelMode.Controls.Add($lblArchitect)

$rbSniper = New-Object System.Windows.Forms.RadioButton
$rbSniper.Text = "Sniper — seleção manual"
$rbSniper.ForeColor = $ThemeText
$rbSniper.BackColor = $ThemePanel
$rbSniper.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbSniper.Location = New-Object System.Drawing.Point(18, 134)
$rbSniper.Size = New-Object System.Drawing.Size(330, 24)
$panelMode.Controls.Add($rbSniper)

$panelExecutor = New-Object System.Windows.Forms.GroupBox
$panelExecutor.Text = "Executor Alvo"
$panelExecutor.ForeColor = $ThemePink
$panelExecutor.BackColor = $ThemePanel
$panelExecutor.Size = New-Object System.Drawing.Size(409, 162)
$panelExecutor.Location = New-Object System.Drawing.Point(433, 84)
$panelExecutor.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($panelExecutor)

$rbAIStudio = New-Object System.Windows.Forms.RadioButton
$rbAIStudio.Text = "AI Studio Apps"
$rbAIStudio.ForeColor = $ThemeText
$rbAIStudio.BackColor = $ThemePanel
$rbAIStudio.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbAIStudio.Location = New-Object System.Drawing.Point(18, 38)
$rbAIStudio.Size = New-Object System.Drawing.Size(240, 24)
$rbAIStudio.Checked = $true
$panelExecutor.Controls.Add($rbAIStudio)

$lblAIStudio = New-Object System.Windows.Forms.Label
$lblAIStudio.Text = "Orquestrador prepara output otimizado para AI Studio Apps."
$lblAIStudio.ForeColor = $ThemeMuted
$lblAIStudio.BackColor = $ThemePanel
$lblAIStudio.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblAIStudio.AutoSize = $true
$lblAIStudio.Location = New-Object System.Drawing.Point(38, 62)
$panelExecutor.Controls.Add($lblAIStudio)

$rbAntigravity = New-Object System.Windows.Forms.RadioButton
$rbAntigravity.Text = "Antigravity"
$rbAntigravity.ForeColor = $ThemeText
$rbAntigravity.BackColor = $ThemePanel
$rbAntigravity.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbAntigravity.Location = New-Object System.Drawing.Point(18, 92)
$rbAntigravity.Size = New-Object System.Drawing.Size(240, 24)
$panelExecutor.Controls.Add($rbAntigravity)

$lblAntigravity = New-Object System.Windows.Forms.Label
$lblAntigravity.Text = "Prepara o bundle para o fluxo Gemini/ChatGPT → Antigravity."
$lblAntigravity.ForeColor = $ThemeMuted
$lblAntigravity.BackColor = $ThemePanel
$lblAntigravity.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblAntigravity.AutoSize = $true
$lblAntigravity.Location = New-Object System.Drawing.Point(38, 116)
$panelExecutor.Controls.Add($lblAntigravity)

$panelProvider = New-Object System.Windows.Forms.GroupBox
$panelProvider.Text = "IA Orquestradora"
$panelProvider.ForeColor = $ThemeCyan
$panelProvider.BackColor = $ThemePanel
$panelProvider.Size = New-Object System.Drawing.Size(824, 118)
$panelProvider.Location = New-Object System.Drawing.Point(18, 262)
$panelProvider.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($panelProvider)

$providerHint = New-Object System.Windows.Forms.Label
$providerHint.Text = "Escolha a IA primária. Se ela falhar ou atingir limite, o agente tenta a próxima automaticamente."
$providerHint.ForeColor = $ThemeMuted
$providerHint.BackColor = $ThemePanel
$providerHint.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$providerHint.AutoSize = $true
$providerHint.Location = New-Object System.Drawing.Point(18, 28)
$panelProvider.Controls.Add($providerHint)

$rbGroq = New-Object System.Windows.Forms.RadioButton
$rbGroq.Text = "Groq"
$rbGroq.ForeColor = $ThemeText
$rbGroq.BackColor = $ThemePanel
$rbGroq.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbGroq.Location = New-Object System.Drawing.Point(18, 62)
$rbGroq.Size = New-Object System.Drawing.Size(120, 24)
$rbGroq.Checked = $true
$panelProvider.Controls.Add($rbGroq)

$rbGemini = New-Object System.Windows.Forms.RadioButton
$rbGemini.Text = "Gemini"
$rbGemini.ForeColor = $ThemeText
$rbGemini.BackColor = $ThemePanel
$rbGemini.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbGemini.Location = New-Object System.Drawing.Point(162, 62)
$rbGemini.Size = New-Object System.Drawing.Size(120, 24)
$panelProvider.Controls.Add($rbGemini)

$rbOpenAI = New-Object System.Windows.Forms.RadioButton
$rbOpenAI.Text = "OpenAI"
$rbOpenAI.ForeColor = $ThemeText
$rbOpenAI.BackColor = $ThemePanel
$rbOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbOpenAI.Location = New-Object System.Drawing.Point(306, 62)
$rbOpenAI.Size = New-Object System.Drawing.Size(120, 24)
$panelProvider.Controls.Add($rbOpenAI)

$rbAnthropic = New-Object System.Windows.Forms.RadioButton
$rbAnthropic.Text = "Anthropic"
$rbAnthropic.ForeColor = $ThemeText
$rbAnthropic.BackColor = $ThemePanel
$rbAnthropic.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbAnthropic.Location = New-Object System.Drawing.Point(450, 62)
$rbAnthropic.Size = New-Object System.Drawing.Size(140, 24)
$panelProvider.Controls.Add($rbAnthropic)

$providerFallbackLabel = New-Object System.Windows.Forms.Label
$providerFallbackLabel.Text = "Fallback: Groq → Gemini → OpenAI → Anthropic (a ordem começa pela IA escolhida)."
$providerFallbackLabel.ForeColor = $ThemePink
$providerFallbackLabel.BackColor = $ThemePanel
$providerFallbackLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$providerFallbackLabel.AutoSize = $true
$providerFallbackLabel.Location = New-Object System.Drawing.Point(594, 66)
$panelProvider.Controls.Add($providerFallbackLabel)

$panelSniper = New-Object System.Windows.Forms.GroupBox
$panelSniper.Text = "Preview de Arquivos — Sniper Mode"
$panelSniper.ForeColor = $ThemeCyan
$panelSniper.BackColor = $ThemePanel
$panelSniper.Size = New-Object System.Drawing.Size(824, 210)
$panelSniper.Location = New-Object System.Drawing.Point(18, 396)
$panelSniper.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelSniper.Visible = $false
$form.Controls.Add($panelSniper)

$sniperHint = New-Object System.Windows.Forms.Label
$sniperHint.Text = "Selecione os arquivos que entrarão no bundle manual."
$sniperHint.ForeColor = $ThemeMuted
$sniperHint.BackColor = $ThemePanel
$sniperHint.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$sniperHint.AutoSize = $true
$sniperHint.Location = New-Object System.Drawing.Point(18, 28)
$panelSniper.Controls.Add($sniperHint)

$checkedFiles = New-Object System.Windows.Forms.CheckedListBox
$checkedFiles.BackColor = $ThemePanelAlt
$checkedFiles.ForeColor = $ThemeText
$checkedFiles.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$checkedFiles.CheckOnClick = $true
$checkedFiles.Font = New-Object System.Drawing.Font("Consolas", 9)
$checkedFiles.Location = New-Object System.Drawing.Point(18, 54)
$checkedFiles.Size = New-Object System.Drawing.Size(788, 130)
$panelSniper.Controls.Add($checkedFiles)

foreach ($file in $FoundFiles) {
    $relPath = Resolve-Path -Path $file.FullName -Relative
    [void]$checkedFiles.Items.Add($relPath, $true)
}

$lblFileCount = New-Object System.Windows.Forms.Label
$lblFileCount.Text = "Arquivos detectados: $($FoundFiles.Count)"
$lblFileCount.ForeColor = $ThemeMuted
$lblFileCount.BackColor = $ThemePanel
$lblFileCount.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblFileCount.AutoSize = $true
$lblFileCount.Location = New-Object System.Drawing.Point(18, 188)
$panelSniper.Controls.Add($lblFileCount)

$chkSendToAI = New-Object System.Windows.Forms.CheckBox
$chkSendToAI.Text = "Gerar o Prompt Final com IA ao concluir"
$chkSendToAI.ForeColor = $ThemeText
$chkSendToAI.BackColor = $ThemeBg
$chkSendToAI.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$chkSendToAI.AutoSize = $true
$chkSendToAI.Location = New-Object System.Drawing.Point(18, 396)
$form.Controls.Add($chkSendToAI)

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "ENERGIZE"
$btnRun.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnRun.FlatAppearance.BorderSize = 1
$btnRun.FlatAppearance.BorderColor = $ThemeCyan
$btnRun.BackColor = $ThemePanelAlt
$btnRun.ForeColor = $ThemeText
$btnRun.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnRun.Location = New-Object System.Drawing.Point(657, 390)
$btnRun.Size = New-Object System.Drawing.Size(185, 40)
$form.Controls.Add($btnRun)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
$progressBar.MarqueeAnimationSpeed = 30
$progressBar.Size = New-Object System.Drawing.Size(824, 12)
$progressBar.Location = New-Object System.Drawing.Point(18, 444)
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

$logViewer = New-Object System.Windows.Forms.RichTextBox
$logViewer.BackColor = $ThemePanelAlt
$logViewer.ForeColor = $ThemeText
$logViewer.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$logViewer.ReadOnly = $true
$logViewer.DetectUrls = $false
$logViewer.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$logViewer.Location = New-Object System.Drawing.Point(18, 466)
$logViewer.Size = New-Object System.Drawing.Size(824, 316)
$form.Controls.Add($logViewer)

function Set-SniperLayout {
    param([bool]$Visible)

    $panelSniper.Visible = $Visible

    if ($Visible) {
        $form.Size = New-Object System.Drawing.Size(860, 1040)
        $form.MinimumSize = New-Object System.Drawing.Size(860, 1040)
        $chkSendToAI.Location = New-Object System.Drawing.Point(18, 628)
        $btnRun.Location = New-Object System.Drawing.Point(657, 622)
        $progressBar.Location = New-Object System.Drawing.Point(18, 676)
        $logViewer.Location = New-Object System.Drawing.Point(18, 698)
        $logViewer.Size = New-Object System.Drawing.Size(824, 300)
    } else {
        $form.Size = New-Object System.Drawing.Size(860, 820)
        $form.MinimumSize = New-Object System.Drawing.Size(860, 820)
        $chkSendToAI.Location = New-Object System.Drawing.Point(18, 396)
        $btnRun.Location = New-Object System.Drawing.Point(657, 390)
        $progressBar.Location = New-Object System.Drawing.Point(18, 444)
        $logViewer.Location = New-Object System.Drawing.Point(18, 466)
        $logViewer.Size = New-Object System.Drawing.Size(824, 316)
    }
}

$rbSniper.Add_CheckedChanged({
    Set-SniperLayout -Visible $rbSniper.Checked
})

$rbFull.Add_CheckedChanged({
    if ($rbFull.Checked) { Set-SniperLayout -Visible $false }
})

$rbArchitect.Add_CheckedChanged({
    if ($rbArchitect.Checked) { Set-SniperLayout -Visible $false }
})

Set-SniperLayout -Visible $false

function Write-UILog {
    param(
        [string]$Message,
        [System.Drawing.Color]$Color = $ThemeText
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $logViewer.SelectionStart = $logViewer.TextLength
    $logViewer.SelectionLength = 0
    $logViewer.SelectionColor = $Color
    $logViewer.AppendText("[$timestamp] $Message`r`n")
    $logViewer.SelectionColor = $logViewer.ForeColor
    $logViewer.ScrollToCaret()
    $logViewer.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

function Set-UiBusy {
    param([bool]$Busy)

    $panelMode.Enabled = -not $Busy
    $panelExecutor.Enabled = -not $Busy
    $panelProvider.Enabled = -not $Busy
    $panelSniper.Enabled = -not $Busy
    $chkSendToAI.Enabled = -not $Busy
    $btnRun.Enabled = -not $Busy
    $progressBar.Visible = $Busy
}

function Invoke-OrchestratorAgent {
    param(
        [string]$AgentScriptPath,
        [string]$BundlePath,
        [string]$ProjectNameValue,
        [string]$ExecutorTargetValue,
        [string]$BundleModeValue,
        [string]$PrimaryProviderValue
    )

    if (-not (Test-Path $AgentScriptPath)) {
        throw "Script groq-agent.ts não localizado."
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $process.StartInfo.FileName = "cmd.exe"
    $process.StartInfo.Arguments = "/c npx --quiet tsx `"$AgentScriptPath`" `"$BundlePath`" `"$ProjectNameValue`" `"$ExecutorTargetValue`" `"$BundleModeValue`" `"$PrimaryProviderValue`""
    $process.StartInfo.WorkingDirectory = (Get-Location).Path
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true

    $env:DOTENV_CONFIG_SILENT = "true"

    if (-not $process.Start()) {
        throw "Falha ao iniciar o processo do agente de IA."
    }

    while (-not $process.HasExited) {
        while ($process.StandardOutput.Peek() -ge 0) {
            $line = $process.StandardOutput.ReadLine()
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                Write-UILog -Message $line -Color $ThemeCyan
            }
        }

        while ($process.StandardError.Peek() -ge 0) {
            $line = $process.StandardError.ReadLine()
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                Write-UILog -Message $line -Color $ThemePink
            }
        }

        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 100
    }

    while ($process.StandardOutput.Peek() -ge 0) {
        $line = $process.StandardOutput.ReadLine()
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            Write-UILog -Message $line -Color $ThemeCyan
        }
    }

    while ($process.StandardError.Peek() -ge 0) {
        $line = $process.StandardError.ReadLine()
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            Write-UILog -Message $line -Color $ThemePink
        }
    }

    $process.WaitForExit()

    if ($process.ExitCode -ne 0) {
        throw "groq-agent.ts finalizou com código $($process.ExitCode)."
    }
}

$btnRun.Add_Click({
    $currentChoice = Resolve-ChoiceFromUI -RbFull $rbFull -RbArchitect $rbArchitect -RbSniper $rbSniper
    $currentExecutorTarget = Resolve-ExecutorFromUI -RbAIStudio $rbAIStudio -RbAntigravity $rbAntigravity
    $currentAIProvider = Resolve-AIProviderFromUI -RbGroq $rbGroq -RbGemini $rbGemini -RbOpenAI $rbOpenAI -RbAnthropic $rbAnthropic

    if (-not $currentChoice) {
        [System.Windows.Forms.MessageBox]::Show(
            "Selecione um modo de extração.",
            "VibeToolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    if (-not $currentAIProvider) {
        [System.Windows.Forms.MessageBox]::Show(
            "Selecione a IA primária.",
            "VibeToolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    if (-not $currentExecutorTarget) {
        [System.Windows.Forms.MessageBox]::Show(
            "Selecione o executor alvo.",
            "VibeToolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    $selectedFiles = @()

    if ($currentChoice -eq '3') {
        for ($i = 0; $i -lt $checkedFiles.Items.Count; $i++) {
            if ($checkedFiles.GetItemChecked($i)) {
                $selectedFiles += $FoundFiles[$i]
            }
        }

        if ($selectedFiles.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "No modo Sniper, selecione pelo menos um arquivo.",
                "VibeToolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }
    } else {
        $selectedFiles = @($FoundFiles)
    }

    $Choice = $currentChoice
    $ExecutorTarget = $currentExecutorTarget
    $AIProvider = $currentAIProvider
    $FilesToProcess = @($selectedFiles)
    $SendToAI = $chkSendToAI.Checked

    Set-UiBusy -Busy $true
    $logViewer.Clear()

    try {
        Write-UILog -Message "HUD energizado." -Color $ThemeCyan
        Write-UILog -Message "Projeto detectado: $ProjectName"
        Write-UILog -Message "Modo selecionado: $(if ($Choice -eq '1') { 'Full Vibe' } elseif ($Choice -eq '2') { 'Architect' } else { 'Sniper' })"
        Write-UILog -Message "Executor alvo: $ExecutorTarget"
        Write-UILog -Message "IA primária: $AIProvider"
        Write-UILog -Message "Arquivos na operação: $($FilesToProcess.Count)"

        $HeaderContent = ""

        if ($ExecutorTarget -eq "AI Studio Apps") {
            $HeaderContent = @"
text
<system_instruction>
ROLE: SENIOR_ENGINEERING_EXECUTOR

OBJECTIVE:
Executar alterações técnicas com precisão, previsibilidade e zero impacto colateral.

NON_NEGOTIABLES:
- Tipagem estrita.
- Contratos claros.
- Princípios de design preservados.
- Nenhuma regressão funcional.
- Nenhuma modificação fora do escopo explícito.

PERFORMANCE_ENFORCEMENT:
- Eficiência antes de abstração.
- Evitar operações redundantes.
- Simplicidade como regra.

ERROR_POLICY:
- Falhas tratadas explicitamente.
- Assíncronos sempre controlados.
- Logs apenas quando necessários.

OUTPUT_RULES:
- Entrega completa.
- Nada fragmentado.
- Identificadores preservados.
- Sem comentários supérfluos.

INTERACTION_MODEL:
- Respostas curtas.
- Código como artefato principal.

FLOW:
1. Receber entrada.
2. Validar contexto.
3. Executar exatamente o solicitado.
4. Aguardar próxima instrução.

</system_instruction>
```
"@
        } else {
            $HeaderContent = @"
text
<system_instruction>
ROLE: SENIOR_ENGINEERING_EXECUTOR

OBJECTIVE:
Executar alterações técnicas com precisão, previsibilidade e zero impacto colateral.

NON_NEGOTIABLES:
- Tipagem estrita.
- Contratos claros.
- Princípios de design preservados.
- Nenhuma regressão funcional.
- Nenhuma modificação fora do escopo explícito.

PERFORMANCE_ENFORCEMENT:
- Eficiência antes de abstração.
- Evitar operações redundantes.
- Simplicidade como regra.

ERROR_POLICY:
- Falhas tratadas explicitamente.
- Assíncronos sempre controlados.
- Logs apenas quando necessários.

OUTPUT_RULES:
- Entrega completa.
- Nada fragmentado.
- Identificadores preservados.
- Sem comentários supérfluos.

INTERACTION_MODEL:
- Respostas curtas.
- Código como artefato principal.

FLOW:
1. Receber entrada.
2. Validar contexto.
3. Executar exatamente o solicitado.
4. Aguardar próxima instrução.

</system_instruction>
```
"@
        }

        $FinalContent = $HeaderContent + "`n`n"
        $BlueprintIssues = @()

        if ($Choice -eq '1' -or $Choice -eq '3') {
            if ($Choice -eq '1') {
                $OutputFile = "_COPIAR_TUDO__${ProjectName}.md"
                $HeaderTitle = "MODO COPIAR TUDO"
                Write-UILog -Message "Iniciando Modo Copiar Tudo..." -Color $ThemeCyan
            } else {
                $OutputFile = "_MANUAL__${ProjectName}.md"
                $HeaderTitle = "MODO MANUAL"
                Write-UILog -Message "Iniciando Modo Sniper / Manual..." -Color $ThemePink
            }

            $FinalContent += "## ${HeaderTitle}: $ProjectName`n`n"

            if ($Choice -eq '3') {
                $FinalContent += "### 0. ANALYSIS SCOPE`n"
                $FinalContent += '```text' + "`n"
                $FinalContent += "ESCOPO: FECHADO / PARCIAL`n"
                $FinalContent += "Este bundle contém apenas os arquivos selecionados manualmente pelo usuário.`n"
                $FinalContent += "Qualquer análise, resumo ou prompt derivado DEVE considerar exclusivamente os arquivos listados neste artefato.`n"
                $FinalContent += "É proibido inferir estrutura global, módulos ausentes, dependências não visíveis ou comportamento de partes não incluídas.`n"
                $FinalContent += "Quando faltar contexto, declarar explicitamente: 'não visível no recorte enviado'.`n"
                $FinalContent += '```' + "`n`n"
            }

            Write-UILog -Message "Montando estrutura do projeto..."
            $FinalContent += "### 1. PROJECT STRUCTURE`n" + '```text' + "`n"
            foreach ($File in $FilesToProcess) {
                $FinalContent += (Resolve-Path -Path $File.FullName -Relative) + "`n"
            }
            $FinalContent += '```' + "`n`n"

            Write-UILog -Message "Lendo arquivos e consolidando conteúdo..."
            $FinalContent += "### 2. SOURCE FILES`n`n"

            foreach ($File in $FilesToProcess) {
                $RelPath = Resolve-Path -Path $File.FullName -Relative
                Write-UILog -Message "Lendo $RelPath"
                $Content = Get-Content $File.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue

                if ($Content) {
                    $Content = $Content -replace "(`r?`n){3,}", "`r`n`r`n"
                    $FinalContent += "#### File: $RelPath`n"
                    $FinalContent += '```text' + "`n"
                    $FinalContent += $Content.TrimEnd() + "`n"
                    $FinalContent += '```' + "`n`n"
                }
            }
        } else {
            $OutputFile = "_INTELIGENTE__${ProjectName}.md"
            Write-UILog -Message "Iniciando Modo Architect / Inteligente..." -Color $ThemeCyan

            $FinalContent += "## MODO INTELIGENTE: $ProjectName`n`n"
            $FinalContent += "### 1. TECH STACK`n"

            if (Test-Path "package.json") {
                Write-UILog -Message "Lendo package.json para tech stack..."
                $Pkg = Get-Content "package.json" | ConvertFrom-Json
                if ($Pkg.dependencies) {
                    $FinalContent += "* **Deps:** $(($Pkg.dependencies.PSObject.Properties.Name -join ', '))`n"
                }
                if ($Pkg.devDependencies) {
                    $FinalContent += "* **Dev Deps:** $(($Pkg.devDependencies.PSObject.Properties.Name -join ', '))`n"
                }
            }

            $FinalContent += "`n"
            $FinalContent += "### 2. PROJECT STRUCTURE`n" + '```text' + "`n"
            foreach ($File in $FilesToProcess) {
                $FinalContent += (Resolve-Path -Path $File.FullName -Relative) + "`n"
            }
            $FinalContent += '```' + "`n`n"

            $FinalContent += "### 3. CORE DOMAINS & CONTRACTS`n"

            foreach ($File in $FilesToProcess) {
                if ($SignatureExtensions -contains $File.Extension) {
                    $RelPath = Resolve-Path -Path $File.FullName -Relative
                    Write-UILog -Message "Extraindo assinaturas de $RelPath"

                    $ContentRaw = Get-Content $File.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                    if (-not $ContentRaw) { continue }

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
                                        $Block += "$($Lines[$j])`n"
                                        $j++
                                    }
                                    if ($j -lt $Lines.Count) { $Block += "$($Lines[$j])`n" }
                                    $i = $j
                                }
                                $Signatures += $Block
                            } elseif ($Line -match '^(?:export\s+)?(?:const|function|class)\s+[A-Za-z0-9_]+') {
                                $Signature = ($Line -replace '\{.*$', '') -replace '\s*=>.*$', ''
                                $Signatures += "$Signature`n"
                            } elseif ($Line -match '^(?:public|protected|private|internal)\s+(?:class|interface|record|struct|enum)\s+[A-Za-z0-9_]+') {
                                $Signature = $Line -replace '\{.*$', ''
                                $Signatures += "$Signature`n"
                            } elseif ($Line -match '^(?:def|class)\s+[A-Za-z0-9_]+') {
                                $Signature = $Line -replace ':$', ''
                                $Signatures += "$Signature`n"
                            } elseif ($Line -match '^func\s+[A-Za-z0-9_]+') {
                                $Signature = $Line -replace '\{.*$', ''
                                $Signatures += "$Signature`n"
                            } elseif ($Line -match '^(?:pub\s+)?(?:fn|struct|enum|trait)\s+[A-Za-z0-9_]+') {
                                $Signature = $Line -replace '\{.*$', ''
                                $Signatures += "$Signature`n"
                            }
                        }
                    } catch {
                        $BlueprintIssues += "[$RelPath] $($_.Exception.Message)"
                        continue
                    }

                    if ($Signatures.Count -gt 0) {
                        $Ext = $File.Extension.TrimStart('.')
                        if ($Ext -match "^(tsx?)$") { $Ext = "typescript" }
                        elseif ($Ext -match "^(jsx?)$") { $Ext = "javascript" }
                        elseif ($Ext -match "^(py)$") { $Ext = "python" }
                        elseif ($Ext -match "^(cs)$") { $Ext = "csharp" }
                        elseif ($Ext -match "^(rb)$") { $Ext = "ruby" }
                        elseif ($Ext -match "^(rs)$") { $Ext = "rust" }
                        elseif ($Ext -match "^(kt)$") { $Ext = "kotlin" }
                        elseif ($Ext -match "^(go)$") { $Ext = "go" }
                        elseif ($Ext -match "^(java)$") { $Ext = "java" }
                        elseif ($Ext -match "^(php)$") { $Ext = "php" }
                        elseif ($Ext -match "^(c|h|cpp|hpp)$") { $Ext = "cpp" }

                        $FinalContent += "#### File: $RelPath`n" + '```' + $Ext + "`n"
                        $FinalContent += ($Signatures -join '')
                        $FinalContent += '```' + "`n`n"
                    }
                }
            }
        }

        Write-UILog -Message "Salvando artefato..."
        $OutputFullPath = Join-Path (Get-Location) $OutputFile

        $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($OutputFullPath, $FinalContent, $Utf8NoBom)

        $TokenEstimate = [math]::Round($FinalContent.Length / 4)

        try {
            $FinalContent | Set-Clipboard
            $Copied = $true
        } catch {
            $Copied = $false
        }

        if ($BlueprintIssues -and $BlueprintIssues.Count -gt 0) {
            Write-UILog -Message "Artefato gerado com $($BlueprintIssues.Count) aviso(s)." -Color $ThemePink
            foreach ($Issue in ($BlueprintIssues | Select-Object -First 10)) {
                Write-UILog -Message $Issue -Color $ThemePink
            }
        } else {
            Write-UILog -Message "Artefato consolidado com sucesso." -Color $ThemeSuccess
        }

        if ($Choice -eq '1') { $ModoNome = "Copiar Tudo" }
        elseif ($Choice -eq '2') { $ModoNome = "Inteligente" }
        else { $ModoNome = "Manual" }

        Write-UILog -Message "Modo: $ModoNome"
        Write-UILog -Message "Executor: $ExecutorTarget"
        Write-UILog -Message "IA primária: $AIProvider"
        Write-UILog -Message "Arquivo: $OutputFile"
        Write-UILog -Message "Tokens estimados: ~$TokenEstimate"

        if ($Copied) {
            Write-UILog -Message "Bundle copiado para a área de transferência." -Color $ThemeCyan
        } else {
            Write-UILog -Message "Arquivo salvo localmente; clipboard indisponível." -Color $ThemePink
        }

        if ($SendToAI) {
            Write-UILog -Message "Chamando agente de IA..." -Color $ThemeCyan
            Write-UILog -Message "Provider primário: $AIProvider | fallback automático ativo." -Color $ThemeCyan
            $AgentScript = Join-Path $ToolkitDir "groq-agent.ts"
            $BundleMode = if ($Choice -eq '1') { 'full' } elseif ($Choice -eq '2') { 'blueprint' } else { 'manual' }

            Invoke-OrchestratorAgent -AgentScriptPath $AgentScript -BundlePath $OutputFullPath -ProjectNameValue $ProjectName -ExecutorTargetValue $ExecutorTarget -BundleModeValue $BundleMode -PrimaryProviderValue $AIProvider

            $FinalSummarizedContent = Get-Content $OutputFullPath -Raw -Encoding UTF8
            try {
                $FinalSummarizedContent | Set-Clipboard
                Write-UILog -Message "Prompt final preparado e copiado para o clipboard." -Color $ThemeSuccess
            } catch {
                Write-UILog -Message "Prompt final preparado, mas não foi possível copiar para o clipboard." -Color $ThemePink
            }
            Write-UILog -Message "Verifique no log acima qual provider venceu o fallback." -Color $ThemeCyan
            Write-UILog -Message "Agora é só colar no seu orquestrador." -Color $ThemeCyan
        } else {
            Write-UILog -Message "Execução concluída sem chamada da Groq." -Color $ThemeSuccess
        }
    } catch {
        Write-UILog -Message $_.Exception.Message -Color $ThemePink
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            "Falha na execução",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    } finally {
        Set-UiBusy -Busy $false
    }
})

Write-UILog -Message "Pronto. Configure o modo, o executor e energize." -Color $ThemeCyan
[void]$form.ShowDialog()
```

#### File: .\README.md
```text
# 🚀 VibeToolkit
**AI Context Synthesizer for Orchestrators**

O **VibeToolkit** é uma ferramenta de infraestrutura para IA focada em transformar projetos de software em bundles estruturados. Ele prepara o contexto ideal para **orquestradores** (como ChatGPT Web e Gemini Web), que geram o prompt final para execução em ferramentas como **AI Studio Apps** ou **Antigravity**.

O objetivo central é eliminar alucinações por falta de contexto, gerando uma **Source of Truth** (Fonte de Verdade) consistente e previsível.

---

## 🛠️ Fluxo de Trabalho

1.  **Consolidação:** Lê e agrupa arquivos relevantes do projeto.
2.  **Bundling:** Gera um arquivo Markdown estruturado.
3.  **Injeção:** Embuti instruções específicas para o executor alvo.
4.  **Orquestração (Opcional):** Chama uma IA para refinar o contexto.
5.  **Entrega:** Copia o prompt final para o clipboard, pronto para o uso.

### Stack Técnica
* **Runtime:** Node.js via `tsx` (TypeScript)
* **Interface:** PowerShell + WinForms (HUD Visual)
* **Providers:** Groq, Gemini, OpenAI e Anthropic.
* **Comunicação:** REST/JSON com fallback inteligente.

---

## ✨ Principais Recursos

### 🔄 Multi-provider com Fallback Automático
Suporte nativo a Groq, Gemini, OpenAI e Anthropic. Se o provedor primário falhar (Rate limit, erro de autenticação ou indisponibilidade), o toolkit aciona automaticamente o próximo da cadeia.

### 📂 Modos de Extração
* **Full Vibe:** Conteúdo completo de todos os arquivos (Entendimento global).
* **Architect:** Extrai apenas estruturas, contratos e assinaturas (Economia de tokens).
* **Sniper:** Seleção manual de arquivos para correções cirúrgicas.

### 🎯 Executores Alvo
O bundle é otimizado especificamente para o comportamento do executor final:
* **AI Studio Apps**
* **Antigravity**

---

## 📂 Estrutura do Projeto

* `groq-agent.ts`: Motor principal de orquestração e lógica de fallback.
* `project-bundler.ps1`: Interface (HUD), leitura de arquivos e montagem do bundle.
* `package.json`: Gerenciamento de dependências e scripts.
* `tsconfig.json`: Configurações de tipagem estrita do TypeScript.

---

## ⚙️ Configuração

### 1. Instalação
```bash
npm install
```

### 2. Variáveis de Ambiente
Crie um arquivo `.env` na raiz do projeto:
```env
GROQ_API_KEY=sua_chave
GEMINI_API_KEY=sua_chave
OPENAI_API_KEY=sua_chave
ANTHROPIC_API_KEY=sua_chave

# Modelos Preferenciais
GROQ_MODEL=llama-3.3-70b-versatile
GEMINI_MODEL=gemini-1.5-pro
OPENAI_MODEL=gpt-4o
ANTHROPIC_MODEL=claude-3-5-sonnet-20240620
```

---

## 🚀 Como Usar

### Via Interface Visual (Recomendado)
Execute o script PowerShell para abrir o HUD de controle:
```powershell
.\project-bundler.ps1
```
No HUD, você poderá selecionar o modo de extração, o executor alvo e o provedor de IA.

### Via Linha de Comando (CLI)
Para integrar em outros fluxos, chame o agente diretamente:
```bash
npx tsx groq-agent.ts <caminho_bundle> <nome_projeto> <executor> <modo> <provedor>
```

---

## 🛡️ Política de Resiliência
O toolkit utiliza a classe `ProviderRequestError` para monitorar a saúde das requisições. O sistema realiza retries e fallbacks automáticos em casos de:
* Erros de autenticação ou chaves expiradas.
* Rate limiting (Excesso de requisições).
* Respostas vazias ou instabilidade do servidor.

---

## 🧠 Princípios do Projeto
* **Previsibilidade:** Markdown padronizado para evitar interpretações erradas.
* **Eficiência:** Foco em reduzir o consumo de tokens sem perder a essência do código.
* **Contexto Fechado:** No modo Sniper, a IA é instruída a não assumir nada além do que foi fornecido.
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
```

