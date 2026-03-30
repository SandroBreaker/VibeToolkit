#requires -Version 7.0

# VIBE AI TOOLKIT - BUNDLER, BLUEPRINT & SELECTIVE
# =================================================================

[CmdletBinding()]
param([string]$Path = ".")

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-Location $Path

$SentinelUiPath = Join-Path $PSScriptRoot "lib\SentinelUI.ps1"
try {
    if (-not (Test-Path $SentinelUiPath -PathType Leaf)) {
        throw "Biblioteca de UI não encontrada: lib\SentinelUI.ps1"
    }

    . $SentinelUiPath
}
catch {
    Write-Error ("Falha ao carregar a biblioteca de UI SENTINEL: {0}" -f $_.Exception.Message)
    exit 1
}

Write-SentinelHeader -Version "v1.0.0"
Write-SentinelStatus -Message "Bootstrap SENTINEL carregado." -Type Success

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
    [Win32]::ShowWindow($consoleHandle, 2) | Out-Null
}

$ProjectName = (Get-Item .).Name
$ScriptFullPath = $MyInvocation.MyCommand.Path
$ToolkitDir = Split-Path $ScriptFullPath
$ModulesDir = Join-Path $ToolkitDir "modules"
$RequiredModulePaths = @(
    (Join-Path $ModulesDir "VibeDirectorProtocol.psm1"),
    (Join-Path $ModulesDir "VibeBundleWriter.psm1"),
    (Join-Path $ModulesDir "VibeSignatureExtractor.psm1"),
    (Join-Path $ModulesDir "VibeFileDiscovery.psm1")
)
foreach ($modulePath in $RequiredModulePaths) {
    if (-not (Test-Path $modulePath -PathType Leaf)) {
        Write-SentinelStatus -Message ("Módulo obrigatório não encontrado: {0}" -f (Split-Path $modulePath -Leaf)) -Type Error
        throw "Módulo obrigatório não encontrado: $modulePath"
    }
}
foreach ($modulePath in $RequiredModulePaths) {
    # Força leitura UTF-8 do conteúdo do módulo para impedir corrupção
    # quando o .psm1 estiver sem BOM no PowerShell 5.1.
    $moduleContent = [System.IO.File]::ReadAllText($modulePath, [System.Text.Encoding]::UTF8)
    $scriptBlock = [scriptblock]::Create($moduleContent)
    $dynamicModuleName = [System.IO.Path]::GetFileNameWithoutExtension($modulePath)
    $dynamicModule = New-Module -Name $dynamicModuleName -ScriptBlock $scriptBlock
    Import-Module -ModuleInfo $dynamicModule -Force -DisableNameChecking -ErrorAction Stop
}

$Choice = $null
$ExecutorTarget = $null
$FilesToProcess = @()
$SendToAI = $false
$AIProvider = $null
$script:LastAgentFailure = $null

$ThemeBg = [System.Drawing.ColorTranslator]::FromHtml("#0F0F0C")
$ThemePanel = [System.Drawing.ColorTranslator]::FromHtml("#161613")
$ThemePanelAlt = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1A")
$ThemeBorder = [System.Drawing.ColorTranslator]::FromHtml("#2A2A26")
$ThemeText = [System.Drawing.ColorTranslator]::FromHtml("#F3F6F7")
$ThemeMuted = [System.Drawing.ColorTranslator]::FromHtml("#A6ADB3")
$ThemeCyan = [System.Drawing.ColorTranslator]::FromHtml("#00E5FF")
$ThemePink    = [System.Drawing.ColorTranslator]::FromHtml("#FF1493")
$ThemeCyanDark = [System.Drawing.ColorTranslator]::FromHtml("#001D28")
$ThemeSuccess = [System.Drawing.ColorTranslator]::FromHtml("#22C55E")
$ThemeWarn = [System.Drawing.ColorTranslator]::FromHtml("#F59E0B")

function Resolve-SentinelStatusTypeFromColor {
    param([System.Drawing.Color]$Color)

    if ($null -eq $Color) { return "Info" }

    switch ($Color.ToArgb()) {
        { $_ -eq $ThemeSuccess.ToArgb() } { return "Success" }
        { $_ -eq $ThemeWarn.ToArgb() } { return "Warning" }
        { $_ -eq $ThemePink.ToArgb() } { return "Error" }
        default { return "Info" }
    }
}

function Write-SentinelConsoleLog {
    param(
        [string]$Message,
        [System.Drawing.Color]$Color = $ThemeText
    )

    if (-not $script:IsConsoleHost) { return }
    if ([string]::IsNullOrWhiteSpace($Message)) { return }

    try {
        Write-SentinelStatus -Message $Message -Type (Resolve-SentinelStatusTypeFromColor -Color $Color)
    }
    catch {
        # Fail-open: a telemetria CLI não pode interromper a HUD existente.
    }
}

$AllowedExtensions = @(
    ".tsx", ".ts", ".js", ".jsx", ".css", ".html", ".json", ".prisma", ".sql", ".yaml", ".md",
    ".py", ".java", ".cs", ".c", ".cpp", ".h", ".hpp", ".go", ".rb", ".php", ".rs", ".swift",
    ".kt", ".scala", ".dart", ".r", ".sh", ".bat", ".ps1", ".csv", ".psm1"
)
$SignatureExtensions = @(
    ".tsx", ".ts", ".js", ".jsx", ".prisma", ".ps1",
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

$TemplateOptions = @(
    [pscustomobject]@{ Id = "director.full.diagnostic"; Name = "[Diretor] Diagnóstico Root Cause" },
    [pscustomobject]@{ Id = "director.full.feature-planning"; Name = "[Diretor] Feature Planning" },
    [pscustomobject]@{ Id = "director.full.architecture-review"; Name = "[Diretor] Architecture Review" },
    [pscustomobject]@{ Id = "director.full.hardening"; Name = "[Diretor] Security Hardening" },
    [pscustomobject]@{ Id = "executor.full.surgical-patch"; Name = "[Executor] Surgical Patch" },
    [pscustomobject]@{ Id = "executor.full.feature-implementation"; Name = "[Executor] Feature Implementation" },
    [pscustomobject]@{ Id = "executor.full.safe-refactor"; Name = "[Executor] Safe Refactor" },
    [pscustomobject]@{ Id = "executor.full.regression-fix"; Name = "[Executor] Regression Fix" }
)

function Test-IsGeneratedArtifactFileName {
    param([string]$FileName)
    if ([string]::IsNullOrWhiteSpace($FileName)) { return $false }
    if (Test-VibeGeneratedArtifactFileName -FileName $FileName) { return $true }
    $patterns = @(
        '^_?(Diretor|Executor)_',
        '^_(COPIAR_TUDO|INTELIGENTE|MANUAL)__',
        '^_meta-prompt_(INTELIGENTE|COPIAR_TUDO|MANUAL|blueprint|bundle|sniper|full|manual)',
        '^_?(diretor|executor)_AI_CONTEXT_',
        '^_?(diretor|executor)_ai_',
        '^_AI_CONTEXT_(bundle|blueprint|sniper|full|manual)_(diretor|executor)_',
        '^_ai_(bundle|blueprint|sniper|full|manual)_(diretor|executor)_',
        '^_TXT_EXPORT__',
        '_TXT_EXPORT__.*\.zip$',
        '^_?(bundle|blueprint|manual)_(diretor|executor)(_[a-zA-Z0-9\-]+)?__',
        '^_meta-prompt_(bundle|blueprint|manual)_(diretor|executor)(_[a-zA-Z0-9\-]+)?__',
        '^_AI_CONTEXT_(bundle|blueprint|manual)_(diretor|executor)(_[a-zA-Z0-9\-]+)?__',
        '^_ai_(bundle|blueprint|manual)_(diretor|executor)(_[a-zA-Z0-9\-]+)?__'
    )
    foreach ($pattern in $patterns) {
        if ($FileName -match $pattern) { return $true }
    }
    return $false
}

function Get-RelevantFiles {
    param([string]$CurrentPath)
    $files = Get-VibeRelevantFiles -CurrentPath $CurrentPath -AllowedExtensions $AllowedExtensions -IgnoredDirs $IgnoredDirs -IgnoredFiles $IgnoredFiles
    return @($files | Where-Object { -not (Test-IsGeneratedArtifactFileName -FileName $_.Name) })
}

function Read-LocalTextArtifact {
    param([string]$Path)
    return (Read-VibeTextFile -Path $Path)
}

function Write-LocalTextArtifact {
    param(
        [string]$Path,
        [AllowEmptyString()][string]$Content,
        [switch]$UseBom
    )
    Write-VibeTextFile -Path $Path -Content $Content -UseBom:$UseBom
}

$FoundFiles = @(Get-RelevantFiles -CurrentPath (Get-Location).Path)

if ($FoundFiles.Count -eq 0) {
    Write-SentinelStatus -Message "Nenhum arquivo válido encontrado no diretório atual." -Type Warning
    [System.Windows.Forms.MessageBox]::Show(
        "Nenhum arquivo válido encontrado no diretório atual.",
        "VibeToolkit", [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    exit
}

# ── UI resolve helpers ────────────────────────────────────────────
function Resolve-ChoiceFromUI {
    param($RbFull, $RbArchitect, $RbSniper, $RbTxtExport)
    if ($RbFull.Checked) { return '1' }
    if ($RbArchitect.Checked) { return '2' }
    if ($RbSniper.Checked) { return '3' }
    if ($RbTxtExport.Checked) { return '4' }
    return $null
}

function Resolve-ExtractionModeFromChoice {
    param([string]$Choice)
    switch ($Choice) {
        '2' { return 'blueprint' }
        '3' { return 'sniper' }
        default { return 'full' }
    }
}

function Resolve-DocumentModeFromExtractionMode {
    param([string]$ExtractionMode)
    if ($ExtractionMode -eq 'sniper') { return 'manual' }
    return 'full'
}

function New-TxtExportOutputDirectory {
    param(
        [string]$BaseDirectory,
        [string]$ProjectNameValue
    )

    $rootName = "_TXT_EXPORT__${ProjectNameValue}"
    $candidate = Join-Path $BaseDirectory $rootName
    $suffix = 2

    while (Test-Path $candidate) {
        $candidate = Join-Path $BaseDirectory ("{0}__{1}" -f $rootName, $suffix)
        $suffix++
    }

    [System.IO.Directory]::CreateDirectory($candidate) | Out-Null
    return $candidate
}

function Convert-SourceFileToTxtExportName {
    param(
        [string]$FullPath,
        [string]$ProjectRootPath
    )

    $fullPathResolved = [System.IO.Path]::GetFullPath($FullPath)
    $projectRootResolved = [System.IO.Path]::GetFullPath($ProjectRootPath)
    $relativePath = $null

    $getRelativePathMethod = [System.IO.Path].GetMethod("GetRelativePath", [type[]]@([string], [string]))
    if ($null -ne $getRelativePathMethod) {
        $relativePath = [System.IO.Path]::GetRelativePath($projectRootResolved, $fullPathResolved)
    }
    else {
        $basePathForUri = $projectRootResolved
        if (-not $basePathForUri.EndsWith([System.IO.Path]::DirectorySeparatorChar) -and -not $basePathForUri.EndsWith([System.IO.Path]::AltDirectorySeparatorChar)) {
            $basePathForUri += [System.IO.Path]::DirectorySeparatorChar
        }

        $projectRootUri = New-Object System.Uri($basePathForUri)
        $fullPathUri = New-Object System.Uri($fullPathResolved)

        if ($projectRootUri.IsBaseOf($fullPathUri)) {
            $relativePath = [System.Uri]::UnescapeDataString($projectRootUri.MakeRelativeUri($fullPathUri).ToString())
            $relativePath = $relativePath -replace '/', [string][System.IO.Path]::DirectorySeparatorChar
        }
        else {
            $relativePath = $fullPathResolved
        }
    }

    if ([string]::IsNullOrWhiteSpace($relativePath) -or $relativePath -eq ".") {
        $relativePath = [System.IO.Path]::GetFileName($fullPathResolved)
    }

    $normalizedRelativePath = $relativePath -replace '[\/]+', [string][System.IO.Path]::DirectorySeparatorChar
    $normalizedRelativePath = $normalizedRelativePath.TrimStart([char[]]@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar, '.'))

    if ([string]::IsNullOrWhiteSpace($normalizedRelativePath) -or $normalizedRelativePath -eq ".") {
        $normalizedRelativePath = [System.IO.Path]::GetFileName($fullPathResolved)
    }

    $segments = @(
        $normalizedRelativePath -split '[\/]+' |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_ -ne "." }
    )

    if ($segments.Count -eq 0) {
        $segments = @([System.IO.Path]::GetFileName($fullPathResolved))
    }

    $safeSegments = New-Object System.Collections.Generic.List[string]

    foreach ($segment in $segments) {
        $safeSegment = $segment -replace '[:*?"<>|]', '_'

        if ([string]::IsNullOrWhiteSpace($safeSegment) -or $safeSegment -match '^\.+$') {
            $safeSegment = '_'
        }

        $safeSegments.Add($safeSegment) | Out-Null
    }

    $lastIndex = $safeSegments.Count - 1
    $safeSegments[$lastIndex] = "{0}.txt" -f $safeSegments[$lastIndex]

    $targetRelativePath = $safeSegments[0]
    for ($i = 1; $i -lt $safeSegments.Count; $i++) {
        $targetRelativePath = Join-Path $targetRelativePath $safeSegments[$i]
    }

    return $targetRelativePath
}

function New-TxtExportZipFilePath {
    param([string]$OutputDirectory)

    $resolvedOutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
    $resolvedOutputDirectory = $resolvedOutputDirectory.TrimEnd([char[]]@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar))

    $parentDirectory = [System.IO.Path]::GetDirectoryName($resolvedOutputDirectory)
    $directoryName = [System.IO.Path]::GetFileName($resolvedOutputDirectory)

    if ([string]::IsNullOrWhiteSpace($parentDirectory)) {
        $parentDirectory = (Get-Location).Path
    }

    $candidate = Join-Path $parentDirectory ("{0}.zip" -f $directoryName)
    $suffix = 2

    while (Test-Path $candidate) {
        $candidate = Join-Path $parentDirectory ("{0}__{1}.zip" -f $directoryName, $suffix)
        $suffix++
    }

    return $candidate
}

function New-TxtExportZipArchive {
    param([string]$OutputDirectory)

    if ([string]::IsNullOrWhiteSpace($OutputDirectory) -or -not (Test-Path $OutputDirectory -PathType Container)) {
        throw "Diretório de saída do TXT Export inválido para compactação: $OutputDirectory"
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $zipFilePath = New-TxtExportZipFilePath -OutputDirectory $OutputDirectory
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $OutputDirectory,
        $zipFilePath,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false
    )

    return $zipFilePath
}

function Test-IsLikelyBinaryFile {
    param([string]$FilePath)

    $stream = $null
    try {
        $stream = [System.IO.File]::Open($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $buffer = New-Object byte[] 4096
        $read = $stream.Read($buffer, 0, $buffer.Length)

        if ($read -le 0) {
            return $false
        }

        for ($i = 0; $i -lt $read; $i++) {
            if ($buffer[$i] -eq 0) {
                return $true
            }
        }

        return $false
    }
    finally {
        if ($null -ne $stream) {
            $stream.Dispose()
        }
    }
}

function Read-TextContentForTxtExport {
    param([string]$FilePath)

    $reader = $null
    try {
        return (Read-LocalTextArtifact -Path $FilePath)
        # retorno acima centraliza a política de encoding
    }
    finally {
        if ($null -ne $reader) {
            $reader.Dispose()
        }
    }
}

function Export-OperationFilesToTxtDirectory {
    param(
        [object[]]$Files,
        [string]$ProjectRootPath,
        [string]$BaseOutputDirectory,
        [string]$ProjectNameValue
    )

    $outputDirectory = New-TxtExportOutputDirectory -BaseDirectory $BaseOutputDirectory -ProjectNameValue $ProjectNameValue
    $exportedFiles = New-Object System.Collections.Generic.List[string]
    $skippedFiles = New-Object System.Collections.Generic.List[string]

    foreach ($sourceFile in $Files) {
        try {
            $sourcePath = if ($sourceFile -is [System.IO.FileInfo]) { $sourceFile.FullName } else { [string]$sourceFile }
            if ([string]::IsNullOrWhiteSpace($sourcePath) -or -not (Test-Path $sourcePath -PathType Leaf)) {
                Write-UILog -Message "TXT Export ignorado: arquivo não encontrado -> $sourcePath" -Color $ThemeWarn
                $skippedFiles.Add([string]$sourcePath) | Out-Null
                continue
            }

            $resolvedSource = (Resolve-Path $sourcePath).Path

            if (Test-IsLikelyBinaryFile -FilePath $resolvedSource) {
                Write-UILog -Message "TXT Export ignorado: arquivo binário/incompatível -> $resolvedSource" -Color $ThemeWarn
                $skippedFiles.Add($resolvedSource) | Out-Null
                continue
            }

            $content = Read-TextContentForTxtExport -FilePath $resolvedSource
            $targetName = Convert-SourceFileToTxtExportName -FullPath $resolvedSource -ProjectRootPath $ProjectRootPath
            $targetPath = Join-Path $outputDirectory $targetName
            $targetDirectory = [System.IO.Path]::GetDirectoryName($targetPath)

            if (-not [string]::IsNullOrWhiteSpace($targetDirectory)) {
                [System.IO.Directory]::CreateDirectory($targetDirectory) | Out-Null
            }

            Write-LocalTextArtifact -Path $targetPath -Content $content -UseBom
            $exportedFiles.Add($targetPath) | Out-Null

            Write-UILog -Message "TXT gerado: $targetName" -Color $ThemeCyan
        }
        catch {
            $failedPath = if ($sourceFile -is [System.IO.FileInfo]) { $sourceFile.FullName } else { [string]$sourceFile }
            Write-UILog -Message "Falha ao exportar TXT: $failedPath :: $($_.Exception.Message)" -Color $ThemePink
            $skippedFiles.Add([string]$failedPath) | Out-Null
        }
    }

    $zipFilePath = New-TxtExportZipArchive -OutputDirectory $outputDirectory

    return [pscustomobject]@{
        OutputDirectory = $outputDirectory
        ZipFilePath     = $zipFilePath
        ExportedFiles   = $exportedFiles
        SkippedFiles    = $skippedFiles
    }
}

function Get-ExtractionModeLabel {
    param([string]$ExtractionMode)
    return (Get-VibeExtractionModeLabel -ExtractionMode $ExtractionMode)
}

function Resolve-AIProviderFromUI {
    param($RbGroq, $RbGemini, $RbOpenAI, $RbAnthropic)
    if ($RbGroq.Checked) { return "groq" }
    if ($RbGemini.Checked) { return "gemini" }
    if ($RbOpenAI.Checked) { return "openai" }
    if ($RbAnthropic.Checked) { return "anthropic" }
    return $null
}

function Resolve-AIPromptModeFromUI {
    param($RbDefault, $RbTemplate, $RbExpert)
    if ($RbTemplate.Checked) { return "template" }
    if ($RbExpert.Checked) { return "expert" }
    return "default"
}

function Resolve-AIFlowModeFromUI {
    param($RbDirector, $RbExecutor)
    if ($RbExecutor.Checked) { return "executor" }
    return "director"
}

function Get-VibeArtifactRouteLabel {
    param([string]$RouteMode)
    if ($RouteMode -match "(?i)executor") { return "executor" }
    return "diretor"
}

function Get-VibeArtifactModeLabel {
    param([string]$ExtractionMode)
    switch -Regex ($ExtractionMode) {
        "(?i)sniper|manual|^3$" { return "manual" }
        "(?i)blueprint|architect|^2$" { return "blueprint" }
        default { return "bundle" }
    }
}

function Get-VibeArtifactFileName {
    param(
        [string]$ProjectNameValue,
        [string]$ExtractionMode,
        [string]$RouteMode,
        [string]$Prefix = "",
        [string]$Provider = "",
        [string]$Extension = ".md"
    )
    $mode = Get-VibeArtifactModeLabel -ExtractionMode $ExtractionMode
    $route = Get-VibeArtifactRouteLabel -RouteMode $RouteMode
    $prov = if ([string]::IsNullOrWhiteSpace($Provider)) { "" } else { "_$Provider" }
    $pfx = if ([string]::IsNullOrWhiteSpace($Prefix)) { "_" } else { "_${Prefix}_" }
    
    return "${pfx}${mode}_${route}${prov}__${ProjectNameValue}${Extension}"
}

function Get-AIContextOutputFileName {
    param([string]$ProjectNameValue, [string]$RouteMode, [string]$ExtractionMode)
    return Get-VibeArtifactFileName -ProjectNameValue $ProjectNameValue -ExtractionMode $ExtractionMode -RouteMode $RouteMode -Prefix "AI_CONTEXT"
}

function Get-AIResultOutputFileName {
    param([string]$ProjectNameValue, [string]$RouteMode, [string]$ExtractionMode)
    return Get-VibeArtifactFileName -ProjectNameValue $ProjectNameValue -ExtractionMode $ExtractionMode -RouteMode $RouteMode -Prefix "_ai_" -Extension ".json"
}

function New-LocalExecutionMeta {
    param(
        [string]$ProjectNameValue,
        [string]$RouteMode,
        [string]$ExtractionMode,
        [string]$DocumentMode,
        [string]$PromptMode = "local",
        [AllowNull()][string]$TemplateId = $null,
        [string]$Provider = "local",
        [string]$Model = "local",
        [AllowNull()][string]$BundlePath = $null,
        [AllowNull()][string]$OutputPath = $null,
        [AllowNull()][string]$ResultMetaPath = $null,
        [hashtable]$ExtraData
    )

    $meta = [ordered]@{
        ok                       = $true
        provider                 = $Provider
        model                    = $Model
        routeMode                = $RouteMode
        extractionMode           = $ExtractionMode
        documentMode             = $DocumentMode
        promptMode               = $PromptMode
        templateId               = $TemplateId
        outputPath               = $OutputPath
        resultMetaPath           = $ResultMetaPath
        bundlePath               = $BundlePath
        generatedAt              = [DateTime]::UtcNow.ToString("o")
        generatedWithoutProvider = $true
    }

    if ($ExtraData) {
        foreach ($key in $ExtraData.Keys) {
            $meta[$key] = $ExtraData[$key]
        }
    }

    return [pscustomobject]$meta
}

function Write-LocalExecutionMeta {
    param(
        [string]$ProjectNameValue,
        [string]$RouteMode,
        [string]$ExtractionMode,
        [string]$DocumentMode,
        [string]$PromptMode = "local",
        [AllowNull()][string]$TemplateId = $null,
        [string]$Provider = "local",
        [string]$Model = "local",
        [AllowNull()][string]$BundlePath = $null,
        [AllowNull()][string]$OutputPath = $null,
        [AllowNull()][string]$ResultMetaPath = $null,
        [hashtable]$ExtraData
    )

    $resolvedResultMetaPath = if ([string]::IsNullOrWhiteSpace($ResultMetaPath)) {
        Join-Path (Get-Location).Path (Get-AIResultOutputFileName -ProjectNameValue $ProjectNameValue -RouteMode $RouteMode -ExtractionMode $ExtractionMode)
    }
    else {
        $ResultMetaPath
    }

    $meta = New-LocalExecutionMeta `
        -ProjectNameValue $ProjectNameValue `
        -RouteMode $RouteMode `
        -ExtractionMode $ExtractionMode `
        -DocumentMode $DocumentMode `
        -PromptMode $PromptMode `
        -TemplateId $TemplateId `
        -Provider $Provider `
        -Model $Model `
        -BundlePath $BundlePath `
        -OutputPath $OutputPath `
        -ResultMetaPath $resolvedResultMetaPath `
        -ExtraData $ExtraData

    $metaJson = $meta | ConvertTo-Json -Depth 12
    Write-LocalTextArtifact -Path $resolvedResultMetaPath -Content $metaJson -UseBom

    return [pscustomobject]@{
        Meta           = $meta
        ResultMetaPath = $resolvedResultMetaPath
    }
}

function Get-DeterministicMetaPromptOutputFileName {
    param(
        [string]$ProjectNameValue,
        [string]$ChoiceValue,
        [string]$RouteMode
    )
    return Get-VibeArtifactFileName -ProjectNameValue $ProjectNameValue -ExtractionMode $ChoiceValue -RouteMode $RouteMode -Prefix "meta-prompt"
}

function Get-DeterministicMetaPromptAnalysisSummary {
    param([string]$ExtractionMode)

    $normalizedExtractionMode = if ([string]::IsNullOrWhiteSpace($ExtractionMode)) { '' } else { $ExtractionMode.ToLowerInvariant() }

    switch ($normalizedExtractionMode) {
        'full' { return "O material consolidado fornece visão ampla do projeto, incluindo estrutura, arquivos fonte e contexto operacional visível." }
        'blueprint' { return "O material consolidado fornece recorte arquitetural focado em contratos, estrutura e componentes centrais." }
        'sniper' { return "O material consolidado fornece recorte cirúrgico do projeto, com foco apenas no contexto explicitamente selecionado." }
        default { return "O material consolidado fornece um bundle operacional estruturado do projeto." }
    }
}

function Get-DeterministicMetaPromptReasoningSummary {
    param(
        [string[]]$RelevantFiles,
        [string]$ExtractionMode
    )

    $parts = @(
        "A saída deve ser compilada localmente no bundler, sem provider remoto e sem invocar groq-agent.ts.",
        "O documento final precisa manter estrutura estável, vocabulário controlado e usar apenas sinais objetivos do bundle visível.",
        "O Executor deve trabalhar sobre o material compilado, preservando contratos e evitando inferência livre fora dos arquivos anexados."
    )

    if ($RelevantFiles -and $RelevantFiles.Count -gt 0) {
        $parts += "Os recortes prioritários para leitura são: $($RelevantFiles -join ', ')."
    }

    return ($parts -join ' ')
}

function Get-DeterministicRelevantFiles {
    param([System.IO.FileInfo[]]$Files)

    $priorityPatterns = @(
        '.\project-bundler.ps1',
        '.\groq-agent.ts',
        '.\modules\VibeDirectorProtocol.psm1',
        '.\modules\VibeBundleWriter.psm1',
        '.\modules\VibeFileDiscovery.psm1',
        '.\modules\VibeSignatureExtractor.psm1',
        '.\DOCUMENTACAO_TECNICA.md',
        '.\README.md',
        '.\package.json'
    )

    $relativeMap = @{}
    foreach ($file in @($Files)) {
        try {
            $relativePath = Resolve-Path -Path $file.FullName -Relative
            $relativeMap[$relativePath] = $true
        }
        catch {
        }
    }

    $result = New-Object System.Collections.Generic.List[string]
    foreach ($pattern in $priorityPatterns) {
        if ($relativeMap.ContainsKey($pattern)) {
            $result.Add($pattern)
        }
    }

    if ($result.Count -eq 0) {
        foreach ($key in ($relativeMap.Keys | Select-Object -First 8)) {
            $result.Add([string]$key)
        }
    }

    return @($result)
}

function Get-DeterministicMomentumSourceLabel {
    param($MomentumContext)

    if ($null -eq $MomentumContext) { return "não identificado" }
    if ($MomentumContext.Status -ne 'found' -or [string]::IsNullOrWhiteSpace($MomentumContext.FilePath)) { return "não identificado" }

    try {
        return (Resolve-Path -Path $MomentumContext.FilePath -Relative)
    }
    catch {
        return [System.IO.Path]::GetFileName($MomentumContext.FilePath)
    }
}

function New-DeterministicMetaPromptArtifact {
    param(
        [string]$ProjectNameValue,
        [string]$ExecutorTargetValue,
        [string]$RouteMode,
        [string]$ExtractionMode,
        [string]$DocumentMode,
        [string]$SourceArtifactFileName,
        [string]$OutputArtifactFileName,
        [AllowEmptyString()][string]$BundleContent,
        [System.IO.FileInfo[]]$Files,
        $MomentumContext
    )

    $generatedAt = [DateTime]::UtcNow.ToString("o")
    $relevantFiles = @(Get-DeterministicRelevantFiles -Files $Files)
    $momentumState = if ($MomentumContext -and $MomentumContext.Status -eq 'found') { 'carregado' } else { 'vazio' }
    $momentumSource = Get-DeterministicMomentumSourceLabel -MomentumContext $MomentumContext
    $normalizedRouteMode = if ($RouteMode -eq 'executor') { 'executor' } else { 'director' }
    $relevantFilesValue = if ($relevantFiles.Count -gt 0) { $relevantFiles -join ', ' } else { 'não identificados objetivamente' }
    $momentumMemoryLabel = if ($momentumState -eq 'carregado') { $momentumSource } else { 'estado vazio / não identificado' }

    $lines = New-Object System.Collections.Generic.List[string]

    if ($normalizedRouteMode -eq 'executor') {
        $lines.Add("### <metadata>")
        $lines.Add("")
        $lines.Add("* **Projeto:** ``$ProjectNameValue``")
        $lines.Add("* **Protocolo:** ``ELITE v4.1 (Sniper Mode)``")
        $lines.Add("* **Route Mode:** ``$normalizedRouteMode``")
        $lines.Add("* **Extração:** ``$(Get-VibeExtractionModeLabel -ExtractionMode $ExtractionMode)``")
        $lines.Add("* **Document Mode:** ``$DocumentMode``")
        $lines.Add("* **Artefato Fonte:** ``$SourceArtifactFileName``")
        $lines.Add("* **Artefato Final:** ``$OutputArtifactFileName``")
        $lines.Add("* **Contexto Momentum:** ``$momentumState``")
        $lines.Add("* **Executor Alvo:** ``$ExecutorTargetValue``")
        $lines.Add("* **Gerado em:** ``$generatedAt``")
        $lines.Add("")
        $lines.Add("</metadata>")
        $lines.Add("")
        $lines.Add("### <identity_and_mandate>")
        $lines.Add("")
        $lines.Add("Você é o **Senior Implementation Agent (Sniper)**. Sua função é a materialização técnica de especificações de ""espaço zero"" (zero-gap) em código de produção.")
        $lines.Add("* **Missão:** Converter o blueprint técnico em código funcional, respeitando invariantes e contratos existentes.")
        $lines.Add("* **Filosofia:** O código é um **passivo técnico (liability)** até ser verificado por um humano.")
        $lines.Add("* **Proibição de Alquimia:** Não tome decisões arquiteturais criativas. Se houver ambiguidade, declare a lacuna antes de prosseguir.")
        $lines.Add("")
        $lines.Add("</identity_and_mandate>")
        $lines.Add("")
        $lines.Add("### <execution_rules>")
        $lines.Add("")
        $lines.Add("1. **Lei da Subtração:** Antes de adicionar código, verifique se a funcionalidade pode ser resolvida reutilizando abstrações presentes ou removendo redundâncias.")
        $lines.Add("2. **DNA do Output (Zero-Yap):** A entrega deve ser técnica e pronta para aplicação.")
        $lines.Add("3. **Preservação de Contexto:** Mantenha estilos de nomenclatura e estruturas de arquivos compatíveis com o projeto **$ProjectNameValue**.")
        $lines.Add("")
        $lines.Add("</execution_rules>")
        $lines.Add("")
        $lines.Add("### <technical_blueprint>")
        $lines.Add("")
        $lines.Add("* **Objetivo:** Materializar ajustes no pipeline estruturado de ``$ProjectNameValue`` para gerar contexto executor determinístico local, sem provider remoto.")
        $lines.Add("* **Arquivos-Alvo:** ``$relevantFilesValue``")
        $lines.Add("* **Injeção de Momentum:** Utilize o estado de ``$momentumMemoryLabel`` como memória de trabalho para evitar regressões sistêmicas.")
        $lines.Add("")
        $lines.Add("</technical_blueprint>")
        $lines.Add("")
        $lines.Add("### <verification_protocol>")
        $lines.Add("")
        $lines.Add("Toda implementação deve incluir:")
        $lines.Add("")
        $lines.Add("1. **Relatório de Impacto:** Lista de arquivos e dependências verificadas.")
        $lines.Add("2. **Property-based Testing/Fuzzing:** Instruções para bombardear o sistema com inputs aleatórios e descobrir falhas de borda.")
        $lines.Add("3. **Checklist de Segurança:** Verificação obrigatória contra exposição de segredos, validação insuficiente de entrada e violações de contrato.")
        $lines.Add("")
        $lines.Add("</verification_protocol>")
        $lines.Add("")
        $lines.Add("### <response_template>")
        $lines.Add("")
        $lines.Add("1. **ANÁLISE DE EXECUÇÃO**")
        $lines.Add("2. **DIFF VISUAL / IMPLEMENTAÇÃO**")
        $lines.Add("3. **PROTOCOLO DE VALIDAÇÃO**")
        $lines.Add("4. **ASSINATURA TÉCNICA**")
        $lines.Add("")
        $lines.Add("</response_template>")
        $lines.Add("")
        $lines.Add("## BUNDLE VISÍVEL CONSOLIDADO")
        $lines.Add("- Projeto: $ProjectNameValue")
        $lines.Add("- Modo operacional: $normalizedRouteMode")
        $lines.Add("- Extração: $ExtractionMode")
        $lines.Add("- Artefato fonte: $SourceArtifactFileName")
        $lines.Add("- Arquivos relevantes: $relevantFilesValue")
        $lines.Add("")
        $lines.Add($BundleContent)

        return ($lines -join "`n")
    }

    $lines.Add((Get-DirectorHighFidelityMetadataSection `
        -ProjectNameValue $ProjectNameValue `
        -ExtractionMode $ExtractionMode `
        -DocumentMode $DocumentMode `
        -GeneratedAt $generatedAt `
        -SourceArtifactFileName $SourceArtifactFileName `
        -OutputArtifactFileName $OutputArtifactFileName `
        -ExecutorTargetValue $ExecutorTargetValue))
    $lines.Add("")
    $lines.Add((Get-DirectorHighFidelitySystemGovernanceSection))
    $lines.Add("")
    $lines.Add((Get-DirectorHighFidelityMetaPromptEngineeringLayersSection -TargetFiles $relevantFiles))
    $lines.Add("")
    $lines.Add((Get-DirectorHighFidelityResponseTemplateSection))
    $lines.Add("")
    $lines.Add((Get-DirectorHighFidelityContextMomentumSection -MomentumState $momentumState -MomentumSource $momentumSource))
    $lines.Add("")
    $lines.Add("## BUNDLE VISÍVEL CONSOLIDADO")
    $lines.Add("- Projeto: $ProjectNameValue")
    $lines.Add("- Modo operacional: $normalizedRouteMode")
    $lines.Add("- Extração: $ExtractionMode")
    $lines.Add("- Artefato fonte: $SourceArtifactFileName")
    $lines.Add("- Arquivos relevantes: $relevantFilesValue")
    $lines.Add("")
    $lines.Add($BundleContent)

    return ($lines -join "`n")
}

function Test-IsMomentumResultFileName {
    param([string]$FileName)
    return (Test-VibeMomentumResultFileName -FileName $FileName)
}

function Resolve-LatestMomentumContext {
    param([string]$SearchRoot)
    return (Resolve-VibeLatestMomentumContext -SearchRoot $SearchRoot)
}

function Get-MarkdownFenceToken {
    param([AllowEmptyString()][string]$Content, [string]$FenceChar = '`')
    return (Get-VibeMarkdownFenceToken -Content $Content -FenceChar $FenceChar)
}

function Convert-ToSafeMarkdownCodeBlock {
    param([AllowEmptyString()][string]$Content, [string]$Language = 'text', [string]$FenceChar = '`')
    return (ConvertTo-VibeSafeMarkdownCodeBlock -Content $Content -Language $Language -FenceChar $FenceChar)
}

function Get-MomentumSectionContent {
    param($MomentumContext)
    return (Get-VibeMomentumSectionContent -MomentumContext $MomentumContext)
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
    return (Get-VibeCodeFenceLanguageFromExtension -Extension $Extension)
}

function Get-PowerShellFunctionSignatures {
    param([string[]]$Lines)
    return @(Get-VibePowerShellFunctionSignatures -Lines $Lines)
}

function Get-BundlerSignaturesForFile {
    param([System.IO.FileInfo]$File, [ref]$IssueMessage)
    return @(Get-VibeBundlerSignaturesForFile -File $File -IssueMessage $IssueMessage)
}

function New-BundlerContractsBlock {
    param([System.IO.FileInfo[]]$Files, [ref]$IssueCollector,
        [string]$StructureHeading, [string]$ContractsHeading, [switch]$LogExtraction)
    if ($null -eq $Files -or $Files.Count -eq 0) { return "" }

    $structureLines = New-Object System.Collections.Generic.List[string]
    foreach ($File in $Files) {
        $structureLines.Add((Resolve-Path -Path $File.FullName -Relative))
    }

    $Block = "${StructureHeading}`n"
    $Block += (Convert-ToSafeMarkdownCodeBlock -Content ($structureLines -join "`n") -Language 'text')
    $Block += "`n`n"
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
        $SignatureContent = ($Signatures -join '')
        $Block += "#### File: $RelPath`n"
        $Block += (Convert-ToSafeMarkdownCodeBlock -Content $SignatureContent -Language $FenceLanguage)
        $Block += "`n`n"
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

function Get-WorkingAreaForBounds {
    param([System.Drawing.Rectangle]$Bounds)
    return [System.Windows.Forms.Screen]::FromRectangle($Bounds).WorkingArea 
}

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
    $ref = if ($form.Bounds.Width -gt 0) { $form.Bounds } else { New-Object System.Drawing.Rectangle(0, 0, $script:PreferredNormalSize.Width, $script:PreferredNormalSize.Height) }
    return [System.Windows.Forms.Screen]::FromRectangle($ref).WorkingArea
}

function Get-CurrentScreenBounds {
    $ref = if ($form.Bounds.Width -gt 0) { $form.Bounds } else { New-Object System.Drawing.Rectangle(0, 0, $script:PreferredNormalSize.Width, $script:PreferredNormalSize.Height) }
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
$panelMode.Text = "1. Modo de Extração"
$panelMode.ForeColor = $ThemeCyan
$panelMode.BackColor = $ThemePanel
$panelMode.Size = New-Object System.Drawing.Size(396, 238)
$panelMode.Location = New-Object System.Drawing.Point(18, 84)
$panelMode.Font = New-Object System.Drawing.Font("Segoe UI", 9.75, [System.Drawing.FontStyle]::Bold)
$panelMode.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($panelMode)

$rbFull = New-Object System.Windows.Forms.RadioButton
$rbFull.Text = "Full Vibe — enviar tudo"
$rbFull.ForeColor = $ThemeText; $rbFull.BackColor = $ThemePanel
$rbFull.Font = New-Object System.Drawing.Font("Segoe UI", 9.75)
$rbFull.Location = New-Object System.Drawing.Point(18, 34)
$rbFull.Size = New-Object System.Drawing.Size(330, 24)
$rbFull.Checked = $true
$panelMode.Controls.Add($rbFull)

$lblFull = New-Object System.Windows.Forms.Label
$lblFull.Text = "Ideal para análise completa, bugs e contexto integral."
$lblFull.ForeColor = $ThemeMuted; $lblFull.BackColor = $ThemePanel
$lblFull.Font = New-Object System.Drawing.Font("Segoe UI", 8.75)
$lblFull.AutoSize = $true
$lblFull.Location = New-Object System.Drawing.Point(38, 58)
$panelMode.Controls.Add($lblFull)

$rbArchitect = New-Object System.Windows.Forms.RadioButton
$rbArchitect.Text = "Architect — blueprint / estrutura"
$rbArchitect.ForeColor = $ThemeText; $rbArchitect.BackColor = $ThemePanel
$rbArchitect.Font = New-Object System.Drawing.Font("Segoe UI", 9.75)
$rbArchitect.Location = New-Object System.Drawing.Point(18, 80)
$rbArchitect.Size = New-Object System.Drawing.Size(330, 24)
$panelMode.Controls.Add($rbArchitect)

$lblArchitect = New-Object System.Windows.Forms.Label
$lblArchitect.Text = "Economiza tokens e foca em contratos e assinaturas."
$lblArchitect.ForeColor = $ThemeMuted; $lblArchitect.BackColor = $ThemePanel
$lblArchitect.Font = New-Object System.Drawing.Font("Segoe UI", 8.75)
$lblArchitect.AutoSize = $true
$lblArchitect.Location = New-Object System.Drawing.Point(38, 104)
$panelMode.Controls.Add($lblArchitect)

$rbSniper = New-Object System.Windows.Forms.RadioButton
$rbSniper.Text = "Sniper — seleção manual"
$rbSniper.ForeColor = $ThemeText; $rbSniper.BackColor = $ThemePanel
$rbSniper.Font = New-Object System.Drawing.Font("Segoe UI", 9.75)
$rbSniper.Location = New-Object System.Drawing.Point(18, 126)
$rbSniper.Size = New-Object System.Drawing.Size(330, 24)
$panelMode.Controls.Add($rbSniper)

$lblSniper = New-Object System.Windows.Forms.Label
$lblSniper.Text = "Recorte manual com foco cirúrgico."
$lblSniper.ForeColor = $ThemeMuted; $lblSniper.BackColor = $ThemePanel
$lblSniper.Font = New-Object System.Drawing.Font("Segoe UI", 8.75)
$lblSniper.AutoSize = $true
$lblSniper.Location = New-Object System.Drawing.Point(38, 150)
$panelMode.Controls.Add($lblSniper)

$rbTxtExport = New-Object System.Windows.Forms.RadioButton
$rbTxtExport.Text = "TXT Export — pasta com arquivos separados"
$rbTxtExport.ForeColor = $ThemeText; $rbTxtExport.BackColor = $ThemePanel
$rbTxtExport.Font = New-Object System.Drawing.Font("Segoe UI", 9.75)
$rbTxtExport.Location = New-Object System.Drawing.Point(18, 172)
$rbTxtExport.Size = New-Object System.Drawing.Size(350, 24)
$panelMode.Controls.Add($rbTxtExport)

$lblTxtExport = New-Object System.Windows.Forms.Label
$lblTxtExport.Text = "Cria nova pasta e salva cada arquivo da operação em .txt."
$lblTxtExport.ForeColor = $ThemeMuted; $lblTxtExport.BackColor = $ThemePanel
$lblTxtExport.Font = New-Object System.Drawing.Font("Segoe UI", 8.75)
$lblTxtExport.AutoSize = $true
$lblTxtExport.Location = New-Object System.Drawing.Point(38, 196)
$panelMode.Controls.Add($lblTxtExport)

$lblModeSep = New-Object System.Windows.Forms.Label
$lblModeSep.Text = "EXECUTOR ALVO"
$lblModeSep.ForeColor = $ThemeCyan
$lblModeSep.BackColor = $ThemePanel
$lblModeSep.Font = New-Object System.Drawing.Font("Segoe UI", 7.75, [System.Drawing.FontStyle]::Bold)
$lblModeSep.AutoSize = $true
$lblModeSep.Location = New-Object System.Drawing.Point(18, 218)
$panelMode.Controls.Add($lblModeSep)

$cmbExecutorInline = New-Object System.Windows.Forms.ComboBox
$cmbExecutorInline.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmbExecutorInline.BackColor = $ThemePanelAlt
$cmbExecutorInline.ForeColor = $ThemeText
$cmbExecutorInline.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$cmbExecutorInline.Location = New-Object System.Drawing.Point(122, 210)
$cmbExecutorInline.Size = New-Object System.Drawing.Size(242, 28)
[void]$cmbExecutorInline.Items.Add("AI Studio Apps")
[void]$cmbExecutorInline.Items.Add("Antigravity")
$cmbExecutorInline.SelectedIndex = 0
$panelMode.Controls.Add($cmbExecutorInline)

# ══════════════════════════════════════════════════════════════════
# PANEL: IA ORQUESTRADORA (with provider chain visualization)
# ══════════════════════════════════════════════════════════════════
$panelProvider = New-Object System.Windows.Forms.GroupBox
$panelProvider.Text = "2. IA Orquestradora"
$panelProvider.ForeColor = $ThemeCyan
$panelProvider.BackColor = $ThemePanel
$panelProvider.Size = New-Object System.Drawing.Size(396, 192)
$panelProvider.Location = New-Object System.Drawing.Point(18, 330)
$panelProvider.Font = New-Object System.Drawing.Font("Segoe UI", 9.75, [System.Drawing.FontStyle]::Bold)
$panelProvider.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($panelProvider)

$providerHint = New-Object System.Windows.Forms.Label
$providerHint.Text = "Selecione o provedor primário. O fallback automático segue a cadeia abaixo."
$providerHint.ForeColor = $ThemeMuted; $providerHint.BackColor = $ThemePanel
$providerHint.Font = New-Object System.Drawing.Font("Segoe UI", 8.25)
$providerHint.AutoSize = $false
$providerHint.Location = New-Object System.Drawing.Point(18, 26)
$providerHint.Size = New-Object System.Drawing.Size(352, 28)
$panelProvider.Controls.Add($providerHint)

$rbGroq = New-Object System.Windows.Forms.RadioButton
$rbGroq.Text = "Groq"; $rbGroq.ForeColor = $ThemeText; $rbGroq.BackColor = $ThemePanel
$rbGroq.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbGroq.Location = New-Object System.Drawing.Point(18, 60); $rbGroq.Size = New-Object System.Drawing.Size(82, 24)
$rbGroq.Checked = $true
$panelProvider.Controls.Add($rbGroq)

$rbGemini = New-Object System.Windows.Forms.RadioButton
$rbGemini.Text = "Gemini"; $rbGemini.ForeColor = $ThemeText; $rbGemini.BackColor = $ThemePanel
$rbGemini.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbGemini.Location = New-Object System.Drawing.Point(102, 60); $rbGemini.Size = New-Object System.Drawing.Size(86, 24)
$panelProvider.Controls.Add($rbGemini)

$rbOpenAI = New-Object System.Windows.Forms.RadioButton
$rbOpenAI.Text = "OpenAI"; $rbOpenAI.ForeColor = $ThemeText; $rbOpenAI.BackColor = $ThemePanel
$rbOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbOpenAI.Location = New-Object System.Drawing.Point(194, 60); $rbOpenAI.Size = New-Object System.Drawing.Size(86, 24)
$panelProvider.Controls.Add($rbOpenAI)

$rbAnthropic = New-Object System.Windows.Forms.RadioButton
$rbAnthropic.Text = "Anthropic"; $rbAnthropic.ForeColor = $ThemeText; $rbAnthropic.BackColor = $ThemePanel
$rbAnthropic.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbAnthropic.Location = New-Object System.Drawing.Point(284, 60); $rbAnthropic.Size = New-Object System.Drawing.Size(96, 24)
$panelProvider.Controls.Add($rbAnthropic)

$pnlProviderChain = New-Object System.Windows.Forms.Panel
$pnlProviderChain.BackColor = $ThemePanel
$pnlProviderChain.Location = New-Object System.Drawing.Point(18, 94)
$pnlProviderChain.Size = New-Object System.Drawing.Size(360, 26)
$panelProvider.Controls.Add($pnlProviderChain)

function Build-ProviderChainDots {
    param([string]$ActiveProvider)
    $pnlProviderChain.Controls.Clear()
    $providers = @("groq", "gemini", "openai", "anthropic")
    $labels = @("Groq", "Gemini", "OpenAI", "Anthropic")
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
        $lblFontSize = if ($isActive) { 9.0 } else { 8.5 }
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
$lblCurrentModel.Location = New-Object System.Drawing.Point(18, 126)
$panelProvider.Controls.Add($lblCurrentModel)

$lblFallbackHint = New-Object System.Windows.Forms.Label
$lblFallbackHint.Text = "A cadeia é recalculada a partir do provedor selecionado."
$lblFallbackHint.ForeColor = $ThemeMuted
$lblFallbackHint.BackColor = $ThemePanel
$lblFallbackHint.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblFallbackHint.AutoSize = $true
$lblFallbackHint.Location = New-Object System.Drawing.Point(18, 146)
$panelProvider.Controls.Add($lblFallbackHint)

$lblProviderDisabled = New-Object System.Windows.Forms.Label
$lblProviderDisabled.Text = "Ative a geração com IA abaixo para habilitar o orquestrador."
$lblProviderDisabled.ForeColor = $ThemeWarn
$lblProviderDisabled.BackColor = $ThemePanel
$lblProviderDisabled.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
$lblProviderDisabled.AutoSize = $true
$lblProviderDisabled.Location = New-Object System.Drawing.Point(18, 166)
$lblProviderDisabled.Visible = $true
$panelProvider.Controls.Add($lblProviderDisabled)

# ══════════════════════════════════════════════════════════════════
# STATUS BAR
# ══════════════════════════════════════════════════════════════════
$panelStatus = New-Object System.Windows.Forms.Panel
$panelStatus.BackColor = $ThemePanelAlt
$panelStatus.Size = New-Object System.Drawing.Size(412, 48)
$panelStatus.Location = New-Object System.Drawing.Point(430, 84)
$panelStatus.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($panelStatus)

$lblStatusProvider = New-Object System.Windows.Forms.Label
$lblStatusProvider.Text = "● Groq  ·  llama-3.3-70b-versatile"
$lblStatusProvider.ForeColor = $ThemeCyan
$lblStatusProvider.BackColor = $ThemePanelAlt
$lblStatusProvider.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblStatusProvider.AutoSize = $true
$lblStatusProvider.Location = New-Object System.Drawing.Point(12, 10)
$panelStatus.Controls.Add($lblStatusProvider)

$lblStatusInfo = New-Object System.Windows.Forms.Label
$lblStatusInfo.Text = "~0 tokens  ·  $($FoundFiles.Count) arquivos  ·  $ProjectName"
$lblStatusInfo.ForeColor = $ThemeMuted
$lblStatusInfo.BackColor = $ThemePanelAlt
$lblStatusInfo.Font = New-Object System.Drawing.Font("Segoe UI", 8.75)
$lblStatusInfo.AutoSize = $true
$lblStatusInfo.Location = New-Object System.Drawing.Point(12, 28)
$panelStatus.Controls.Add($lblStatusInfo)

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "ENERGIZE"
$btnRun.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnRun.FlatAppearance.BorderSize = 1
$btnRun.FlatAppearance.BorderColor = $ThemeCyan
$btnRun.BackColor = $ThemeCyanDark
$btnRun.ForeColor = $ThemeCyan
$btnRun.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
$btnRun.Size = New-Object System.Drawing.Size(152, 34)
$btnRun.Location = New-Object System.Drawing.Point(248, 7)
$btnRun.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$panelStatus.Controls.Add($btnRun)

# ══════════════════════════════════════════════════════════════════
# SNIPER PANEL
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

$txtSniperSearch = New-Object System.Windows.Forms.TextBox
$txtSniperSearch.BackColor = $ThemePanelAlt
$txtSniperSearch.ForeColor = $ThemeMuted
$txtSniperSearch.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtSniperSearch.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$txtSniperSearch.Location = New-Object System.Drawing.Point(18, 26)
$txtSniperSearch.Size = New-Object System.Drawing.Size(332, 24)
$txtSniperSearch.Text = "Buscar arquivo..."
$panelSniper.Controls.Add($txtSniperSearch)

$lblSniperHint = New-Object System.Windows.Forms.Label
$lblSniperHint.Text = "Selecione o recorte manual. O restante entra apenas como contexto do bundler."
$lblSniperHint.ForeColor = $ThemeMuted; $lblSniperHint.BackColor = $ThemePanel
$lblSniperHint.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblSniperHint.AutoSize = $true
$lblSniperHint.Location = New-Object System.Drawing.Point(360, 30)
$panelSniper.Controls.Add($lblSniperHint)

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

$btnSelectAll = New-SniperButton -Text "✔ Tudo"   -X 0   -Width 72
$btnDeselectAll = New-SniperButton -Text "✘ Nenhum" -X 76  -Width 80
$sniperToolbar.Controls.AddRange(@($btnSelectAll, $btnDeselectAll))

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
    if ($Tokens -ge 1000) { return "~$([Math]::Round($Tokens/1000,1))k tokens" }
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
        }
        else {
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
# CHECKBOX: GERAR COM IA E FLUXO FINAL
# ══════════════════════════════════════════════════════════════════
$chkSendToAI = New-Object System.Windows.Forms.CheckBox
$chkSendToAI.Text = "Gerar o prompt final com IA ao concluir"
$chkSendToAI.ForeColor = $ThemeText; $chkSendToAI.BackColor = $ThemeBg
$chkSendToAI.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$chkSendToAI.AutoSize = $false
$chkSendToAI.Location = New-Object System.Drawing.Point(18, 336)
$chkSendToAI.Size = New-Object System.Drawing.Size(360, 22)
$chkSendToAI.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($chkSendToAI)

$chkDeterministicDirector = New-Object System.Windows.Forms.CheckBox
$chkDeterministicDirector.Text = "Gerar meta-prompt determinístico local (sem IA e sem groq-agent.ts)"
$chkDeterministicDirector.ForeColor = $ThemeText; $chkDeterministicDirector.BackColor = $ThemeBg
$chkDeterministicDirector.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$chkDeterministicDirector.AutoSize = $false
$chkDeterministicDirector.Location = New-Object System.Drawing.Point(18, 362)
$chkDeterministicDirector.Size = New-Object System.Drawing.Size(520, 22)
$chkDeterministicDirector.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($chkDeterministicDirector)

$panelAIPromptMode = New-Object System.Windows.Forms.GroupBox
$panelAIPromptMode.Text = "3. Fluxo Final / Geração com IA"
$panelAIPromptMode.ForeColor = $ThemePink
$panelAIPromptMode.BackColor = $ThemePanel
$panelAIPromptMode.Size = New-Object System.Drawing.Size(824, 92)
$panelAIPromptMode.Location = New-Object System.Drawing.Point(18, 580)
$panelAIPromptMode.Font = New-Object System.Drawing.Font("Segoe UI", 9.75, [System.Drawing.FontStyle]::Bold)
$panelAIPromptMode.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($panelAIPromptMode)

$lblAIFlowMode = New-Object System.Windows.Forms.Label
$lblAIFlowMode.Text = "FLUXO DE SAÍDA"
$lblAIFlowMode.ForeColor = $ThemeCyan; $lblAIFlowMode.BackColor = $ThemePanel
$lblAIFlowMode.Font = New-Object System.Drawing.Font("Segoe UI", 7.75, [System.Drawing.FontStyle]::Bold)
$lblAIFlowMode.AutoSize = $true
$lblAIFlowMode.Location = New-Object System.Drawing.Point(18, 30)
$panelAIPromptMode.Controls.Add($lblAIFlowMode)

$rbAIFlowDirector = New-Object System.Windows.Forms.RadioButton
$rbAIFlowDirector.Text = "Via Diretor"
$rbAIFlowDirector.ForeColor = $ThemeText; $rbAIFlowDirector.BackColor = $ThemePanel
$rbAIFlowDirector.Font = New-Object System.Drawing.Font("Segoe UI", 9.75)
$rbAIFlowDirector.Location = New-Object System.Drawing.Point(18, 50)
$rbAIFlowDirector.Size = New-Object System.Drawing.Size(140, 24)
$rbAIFlowDirector.Checked = $true
$panelAIPromptMode.Controls.Add($rbAIFlowDirector)

$rbAIFlowExecutor = New-Object System.Windows.Forms.RadioButton
$rbAIFlowExecutor.Text = "Direto para Executor"
$rbAIFlowExecutor.ForeColor = $ThemeText; $rbAIFlowExecutor.BackColor = $ThemePanel
$rbAIFlowExecutor.Font = New-Object System.Drawing.Font("Segoe UI", 9.75)
$rbAIFlowExecutor.Location = New-Object System.Drawing.Point(180, 50)
$rbAIFlowExecutor.Size = New-Object System.Drawing.Size(180, 24)
$panelAIPromptMode.Controls.Add($rbAIFlowExecutor)

$lblAIFlowHint = New-Object System.Windows.Forms.Label
$lblAIFlowHint.Text = "Via Diretor mantém a camada analítica. Direto para Executor entrega contexto final sem intermediação."
$lblAIFlowHint.ForeColor = $ThemeMuted; $lblAIFlowHint.BackColor = $ThemePanel
$lblAIFlowHint.Font = New-Object System.Drawing.Font("Segoe UI", 8.25)
$lblAIFlowHint.AutoSize = $true
$lblAIFlowHint.Location = New-Object System.Drawing.Point(18, 76)
$panelAIPromptMode.Controls.Add($lblAIFlowHint)

$lblAIPromptMode = New-Object System.Windows.Forms.Label
$lblAIPromptMode.Text = "MODO DE CUSTOMIZAÇÃO"
$lblAIPromptMode.ForeColor = $ThemeCyan; $lblAIPromptMode.BackColor = $ThemePanel
$lblAIPromptMode.Font = New-Object System.Drawing.Font("Segoe UI", 7.75, [System.Drawing.FontStyle]::Bold)
$lblAIPromptMode.AutoSize = $true
$lblAIPromptMode.Location = New-Object System.Drawing.Point(18, 100)
$lblAIPromptMode.Visible = $false
$panelAIPromptMode.Controls.Add($lblAIPromptMode)

$rbPromptModeDefault = New-Object System.Windows.Forms.RadioButton
$rbPromptModeDefault.Text = "Default"
$rbPromptModeDefault.ForeColor = $ThemeText; $rbPromptModeDefault.BackColor = $ThemePanel
$rbPromptModeDefault.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbPromptModeDefault.Location = New-Object System.Drawing.Point(18, 118)
$rbPromptModeDefault.Size = New-Object System.Drawing.Size(100, 24)
$rbPromptModeDefault.Checked = $true
$rbPromptModeDefault.Visible = $false
$panelAIPromptMode.Controls.Add($rbPromptModeDefault)

$rbPromptModeTemplate = New-Object System.Windows.Forms.RadioButton
$rbPromptModeTemplate.Text = "Template"
$rbPromptModeTemplate.ForeColor = $ThemeText; $rbPromptModeTemplate.BackColor = $ThemePanel
$rbPromptModeTemplate.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbPromptModeTemplate.Location = New-Object System.Drawing.Point(130, 118)
$rbPromptModeTemplate.Size = New-Object System.Drawing.Size(120, 24)
$rbPromptModeTemplate.Visible = $false
$panelAIPromptMode.Controls.Add($rbPromptModeTemplate)

$rbPromptModeExpert = New-Object System.Windows.Forms.RadioButton
$rbPromptModeExpert.Text = "Expert Override"
$rbPromptModeExpert.ForeColor = $ThemeText; $rbPromptModeExpert.BackColor = $ThemePanel
$rbPromptModeExpert.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbPromptModeExpert.Location = New-Object System.Drawing.Point(260, 118)
$rbPromptModeExpert.Size = New-Object System.Drawing.Size(180, 24)
$rbPromptModeExpert.Visible = $false
$panelAIPromptMode.Controls.Add($rbPromptModeExpert)

# ---- CAMPOS DO MODO TEMPLATE ----
$pnlTemplateFields = New-Object System.Windows.Forms.Panel
$pnlTemplateFields.BackColor = $ThemePanel
$pnlTemplateFields.Location = New-Object System.Drawing.Point(18, 146)
$pnlTemplateFields.Size = New-Object System.Drawing.Size(788, 164)
$pnlTemplateFields.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$pnlTemplateFields.Visible = $false
$panelAIPromptMode.Controls.Add($pnlTemplateFields)

function Add-TemplateFieldLabel {
    param([string]$Text, [int]$X, [int]$Y)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Text
    $lbl.ForeColor = $ThemeMuted; $lbl.BackColor = $ThemePanel
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $lbl.AutoSize = $true
    $lbl.Location = New-Object System.Drawing.Point($X, $Y)
    $pnlTemplateFields.Controls.Add($lbl)
}

function Add-TemplateFieldTextBox {
    param([int]$X, [int]$Y, [int]$W)
    $txt = New-Object System.Windows.Forms.TextBox
    $txt.BackColor = $ThemePanelAlt; $txt.ForeColor = $ThemeText
    $txt.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $txt.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $txt.Location = New-Object System.Drawing.Point($X, $Y)
    $txt.Size = New-Object System.Drawing.Size($W, 23)
    $pnlTemplateFields.Controls.Add($txt)
    return $txt
}

Add-TemplateFieldLabel -Text "Template:" -X 0 -Y 3
$cmbTemplateId = New-Object System.Windows.Forms.ComboBox
$cmbTemplateId.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmbTemplateId.BackColor = $ThemePanelAlt; $cmbTemplateId.ForeColor = $ThemeText
$cmbTemplateId.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$cmbTemplateId.Location = New-Object System.Drawing.Point(64, 0)
$cmbTemplateId.Size = New-Object System.Drawing.Size(320, 23)
foreach ($opt in $TemplateOptions) { [void]$cmbTemplateId.Items.Add($opt.Name) }
if ($cmbTemplateId.Items.Count -gt 0) { $cmbTemplateId.SelectedIndex = 0 }
$pnlTemplateFields.Controls.Add($cmbTemplateId)

Add-TemplateFieldLabel -Text "Objetivo:" -X 0 -Y 35
$txtTemplateObjective = Add-TemplateFieldTextBox -X 64 -Y 32 -W 320

Add-TemplateFieldLabel -Text "Entrega:" -X 400 -Y 35
$txtTemplateDelivery = Add-TemplateFieldTextBox -X 456 -Y 32 -W 320

Add-TemplateFieldLabel -Text "Tags:" -X 0 -Y 67
$txtTemplateFocus = Add-TemplateFieldTextBox -X 64 -Y 64 -W 320

Add-TemplateFieldLabel -Text "Restrições:" -X 400 -Y 67
$txtTemplateConstraints = Add-TemplateFieldTextBox -X 468 -Y 64 -W 308

Add-TemplateFieldLabel -Text "Instruções:" -X 0 -Y 99
$txtTemplateAdditional = New-Object System.Windows.Forms.TextBox
$txtTemplateAdditional.Multiline = $true; $txtTemplateAdditional.AcceptsReturn = $true
$txtTemplateAdditional.BackColor = $ThemePanelAlt; $txtTemplateAdditional.ForeColor = $ThemeText
$txtTemplateAdditional.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$txtTemplateAdditional.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$txtTemplateAdditional.Location = New-Object System.Drawing.Point(64, 96)
$txtTemplateAdditional.Size = New-Object System.Drawing.Size(712, 60)
$txtTemplateAdditional.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$pnlTemplateFields.Controls.Add($txtTemplateAdditional)

# ---- CAMPO DO MODO EXPERT ----
$txtCustomSystemPrompt = New-Object System.Windows.Forms.TextBox
$txtCustomSystemPrompt.Multiline = $true; $txtCustomSystemPrompt.AcceptsReturn = $true
$txtCustomSystemPrompt.AcceptsTab = $true
$txtCustomSystemPrompt.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$txtCustomSystemPrompt.BackColor = $ThemePanelAlt; $txtCustomSystemPrompt.ForeColor = $ThemeText
$txtCustomSystemPrompt.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$txtCustomSystemPrompt.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtCustomSystemPrompt.Location = New-Object System.Drawing.Point(18, 146)
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
$progressBar.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

# ══════════════════════════════════════════════════════════════════
# LOG HEADER + LOG VIEWER
# ══════════════════════════════════════════════════════════════════
$panelLogHeader = New-Object System.Windows.Forms.Panel
$panelLogHeader.BackColor = $ThemePanelAlt
$panelLogHeader.Size = New-Object System.Drawing.Size(412, 34)
$panelLogHeader.Location = New-Object System.Drawing.Point(430, 140)
$panelLogHeader.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($panelLogHeader)

$lblLogTitle = New-Object System.Windows.Forms.Label
$lblLogTitle.Text = "LOG OPERACIONAL"
$lblLogTitle.ForeColor = $ThemeMuted; $lblLogTitle.BackColor = $ThemePanelAlt
$lblLogTitle.Font = New-Object System.Drawing.Font("Segoe UI", 7.75, [System.Drawing.FontStyle]::Bold)
$lblLogTitle.AutoSize = $true
$lblLogTitle.Location = New-Object System.Drawing.Point(10, 10)
$panelLogHeader.Controls.Add($lblLogTitle)

$cmbLogFilter = New-Object System.Windows.Forms.ComboBox
$cmbLogFilter.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmbLogFilter.BackColor = $ThemePanelAlt; $cmbLogFilter.ForeColor = $ThemeText
$cmbLogFilter.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$cmbLogFilter.Size = New-Object System.Drawing.Size(96, 23)
$cmbLogFilter.Location = New-Object System.Drawing.Point(590, 5)
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
    $b.Size = New-Object System.Drawing.Size(62, 24)
    $b.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
    return $b
}

$btnCopyLog = New-LogHeaderButton -Text "Copiar" -X 690
$btnExpandLog = New-LogHeaderButton -Text "▲ Expandir" -X 758
$btnExpandLog.Size = New-Object System.Drawing.Size(58, 24)
$panelLogHeader.Controls.AddRange(@($btnCopyLog, $btnExpandLog))

$logViewer = New-Object System.Windows.Forms.RichTextBox
$logViewer.BackColor = $ThemePanelAlt; $logViewer.ForeColor = $ThemeText
$logViewer.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$logViewer.ReadOnly = $true; $logViewer.DetectUrls = $false
$logViewer.Font = New-Object System.Drawing.Font("Consolas", 9.25)
$logViewer.Location = New-Object System.Drawing.Point(430, 172)
$logViewer.Size = New-Object System.Drawing.Size(412, 360)
$logViewer.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($logViewer)

# ══════════════════════════════════════════════════════════════════
# HELPER: STATUS BAR UPDATE
# ══════════════════════════════════════════════════════════════════
function Update-StatusBar {
    $filesToEstimate = if ($rbSniper.Checked) {
        @(Get-AllFileNodes -Nodes $treeFiles.Nodes | Where-Object { $_.Checked } | ForEach-Object { [System.IO.FileInfo]$_.Tag })
    }
    else {
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
    $isActive = $chkSendToAI.Checked -and -not $chkDeterministicDirector.Checked
    $info = Get-ProviderDisplayInfo -Provider $provider
    $lblStatusProvider.Text = "$(if ($isActive) { '●' } else { '○' }) $info"
    $lblStatusProvider.ForeColor = if ($isActive) { $ThemeCyan } else { $ThemeMuted }
    Build-ProviderChainDots -ActiveProvider $provider
    $lblCurrentModel.Text = "Modelo: $info"
    $panelProvider.Enabled = $isActive
    $lblProviderDisabled.Visible = -not $isActive
}

# ══════════════════════════════════════════════════════════════════
# HELPER: MODE SELECTION HIGHLIGHT
# ══════════════════════════════════════════════════════════════════
function Update-ModeSelectionHighlight {
    $rbFull.ForeColor = if ($rbFull.Checked) { $ThemeCyan } else { $ThemeText }
    $rbArchitect.ForeColor = if ($rbArchitect.Checked) { $ThemeCyan } else { $ThemeText }
    $rbSniper.ForeColor = if ($rbSniper.Checked) { $ThemeCyan } else { $ThemeText }
    $rbTxtExport.ForeColor = if ($rbTxtExport.Checked) { $ThemeCyan } else { $ThemeText }

    $lblFull.ForeColor = if ($rbFull.Checked) { $ThemeText } else { $ThemeMuted }
    $lblArchitect.ForeColor = if ($rbArchitect.Checked) { $ThemeText } else { $ThemeMuted }
    $lblSniper.ForeColor = if ($rbSniper.Checked) { $ThemeText } else { $ThemeMuted }
    $lblTxtExport.ForeColor = if ($rbTxtExport.Checked) { $ThemeText } else { $ThemeMuted }

    $rbAIFlowDirector.ForeColor = if ($rbAIFlowDirector.Checked) { $ThemeCyan } else { $ThemeText }
    $rbAIFlowExecutor.ForeColor = if ($rbAIFlowExecutor.Checked) { $ThemeCyan } else { $ThemeText }
}

# ══════════════════════════════════════════════════════════════════
# HELPER: AI PANEL VISIBILITY
# ══════════════════════════════════════════════════════════════════
function Update-AIPromptModeUi {
    $promptVisible = $chkSendToAI.Checked
    $tplVis = $promptVisible -and $rbPromptModeTemplate.Checked
    $expVis = $promptVisible -and $rbPromptModeExpert.Checked

    $lblAIPromptMode.Visible = $promptVisible
    $rbPromptModeDefault.Visible = $promptVisible
    $rbPromptModeTemplate.Visible = $promptVisible
    $rbPromptModeExpert.Visible = $promptVisible

    $pnlTemplateFields.Visible = $tplVis
    $txtCustomSystemPrompt.Visible = $expVis

    if ($tplVis) {
        $panelAIPromptMode.Height = 320
    }
    elseif ($expVis) {
        $panelAIPromptMode.Height = 246
    }
    elseif ($promptVisible) {
        $panelAIPromptMode.Height = 156
    }
    else {
        $panelAIPromptMode.Height = 92
    }

    Update-ProviderStatus
    Update-ResponsiveLayout
}

# ══════════════════════════════════════════════════════════════════
# RESPONSIVE LAYOUT
# ══════════════════════════════════════════════════════════════════
function Update-ResponsiveLayout {
    $clientWidth  = [int]$form.ClientSize.Width
    $clientHeight = [int]$form.ClientSize.Height

    $leftGap = 18
    $rightGap = 18
    $colGap = 14
    $topY = 84
    $bottomGap = 16
    $modeH = 238
    $providerH = 192
    $statusH = 48
    $logHeaderH = 32
    $progressH = 4
    $chkBlockH = 56

    $usableW = [int][Math]::Max(560, ($clientWidth - $leftGap - $rightGap))
    $leftColW = [int][Math]::Min(420, [Math]::Max(396, [Math]::Floor($usableW * 0.48)))
    $rightColX = $leftGap + $leftColW + $colGap
    $rightColW = $usableW - $leftColW - $colGap

    $panelMode.Location = New-Object System.Drawing.Point($leftGap, $topY)
    $panelMode.Size = New-Object System.Drawing.Size($leftColW, $modeH)

    $providerTop = $topY + $modeH + 8
    $panelProvider.Location = New-Object System.Drawing.Point($leftGap, $providerTop)
    $panelProvider.Size = New-Object System.Drawing.Size($leftColW, $providerH)

    $innerProviderW = [int][Math]::Max(120, ($leftColW - 36))
    $providerHint.MaximumSize        = New-Object System.Drawing.Size($innerProviderW, 0)
    $pnlProviderChain.Size           = New-Object System.Drawing.Size($innerProviderW, 24)
    $lblCurrentModel.MaximumSize     = New-Object System.Drawing.Size($innerProviderW, 0)
    $lblFallbackHint.MaximumSize     = New-Object System.Drawing.Size($innerProviderW, 0)
    $lblProviderDisabled.MaximumSize = New-Object System.Drawing.Size($innerProviderW, 0)

    $leftColBottom = $providerTop + $providerH + 10

    $panelStatus.Location = New-Object System.Drawing.Point($rightColX, $topY)
    $panelStatus.Size = New-Object System.Drawing.Size($rightColW, $statusH)

    $lblStatusProvider.Location = New-Object System.Drawing.Point(10, 6)
    $lblStatusInfo.Location = New-Object System.Drawing.Point(10, 26)
    $btnRun.Location = New-Object System.Drawing.Point(
        ($panelStatus.Width - $btnRun.Width - 8),
        ([int](($statusH - $btnRun.Height) / 2))
    )

    $rightContentTop = $topY + $statusH + 8
    if ($panelSniper.Visible) {
        $minLogReserve = if ($script:LogExpanded) { 400 } else { 140 }
        $maxSniperH = [Math]::Max(180, $clientHeight - $rightContentTop - $logHeaderH - $minLogReserve - $bottomGap)
        $sniperH = [int][Math]::Min(290, $maxSniperH)
        $panelSniper.Location = New-Object System.Drawing.Point($rightColX, $rightContentTop)
        $panelSniper.Size = New-Object System.Drawing.Size($rightColW, $sniperH)

        $innerW = [int][Math]::Max(100, ($panelSniper.ClientSize.Width - 36))
        $treeH = [int][Math]::Max(50, ($panelSniper.Height - 120))
        $sniperToolbar.Size = New-Object System.Drawing.Size($innerW, 28)
        $treeFiles.Size = New-Object System.Drawing.Size($innerW, $treeH)
        $txtSniperSearch.Size = New-Object System.Drawing.Size([int]([Math]::Min(300, $innerW * 0.50)), 22)
        $lblFileCount.Location = New-Object System.Drawing.Point(18, ($treeFiles.Bottom + 6))
        $rightContentTop = $panelSniper.Bottom + 8
    }

    $panelLogHeader.Location = New-Object System.Drawing.Point($rightColX, $rightContentTop)
    $panelLogHeader.Size = New-Object System.Drawing.Size($rightColW, $logHeaderH)
    $cmbLogFilter.Location = New-Object System.Drawing.Point(($rightColW - 250), 5)
    $btnCopyLog.Location = New-Object System.Drawing.Point(($rightColW - 148), 4)
    $btnExpandLog.Location = New-Object System.Drawing.Point(($rightColW - 84), 4)

    $logTop = $rightContentTop + $logHeaderH
    $minLogH = if ($script:IsFullscreen) { 80 } else { 100 }
    $logMaxBottom = if ($script:LogExpanded) {
        $clientHeight - $bottomGap
    }
    else {
        [int][Math]::Max($leftColBottom, $logTop + $minLogH + 8)
    }
    $logH = [Math]::Max($minLogH, $logMaxBottom - $logTop)
    $logViewer.Location = New-Object System.Drawing.Point($rightColX, $logTop)
    $logViewer.Size = New-Object System.Drawing.Size($rightColW, $logH)

    $fwY = [int][Math]::Max($leftColBottom, $logViewer.Bottom + 8)
    $fwW = $usableW

    $chkSendToAI.Location = New-Object System.Drawing.Point($leftGap, $fwY)
    $chkDeterministicDirector.Location = New-Object System.Drawing.Point($leftGap, ($fwY + 26))

    $promptVis = $chkSendToAI.Checked
    $tplVis = $promptVis -and $rbPromptModeTemplate.Checked
    $expVis = $promptVis -and $rbPromptModeExpert.Checked
    $aiPanelH = if ($tplVis) { 320 } elseif ($expVis) { 246 } elseif ($promptVis) { 156 } else { 92 }

    $aiPanelTop = $fwY + $chkBlockH
    $panelAIPromptMode.Location = New-Object System.Drawing.Point($leftGap, $aiPanelTop)
    $panelAIPromptMode.Size = New-Object System.Drawing.Size($fwW, $aiPanelH)

    $innerAI = [int][Math]::Max(200, ($fwW - 36))
    $lblAIFlowHint.MaximumSize = New-Object System.Drawing.Size($innerAI, 0)
    if ($expVis) { $txtCustomSystemPrompt.Size = New-Object System.Drawing.Size($innerAI, 86) }
    if ($tplVis) {
        $pnlTemplateFields.Size = New-Object System.Drawing.Size($innerAI, 164)
        $txtTemplateAdditional.Size = New-Object System.Drawing.Size([int]($innerAI - 76), 60)
    }

    $progressTop = $aiPanelTop + $aiPanelH + 6
    $progressBar.Location = New-Object System.Drawing.Point($leftGap, $progressTop)
    $progressBar.Size = New-Object System.Drawing.Size($fwW, $progressH)

    $contentBottom = $progressTop + $progressH + $bottomGap
    $form.AutoScrollMinSize = New-Object System.Drawing.Size(0, [Math]::Max($clientHeight, $contentBottom))

    $resizeGrip.Visible = -not $script:IsFullscreen
    $resizeGrip.Location = New-Object System.Drawing.Point(
        ($clientWidth - $resizeGrip.Width),
        ($clientHeight - $resizeGrip.Height)
    )
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
$rbSniper.Add_CheckedChanged({ Set-SniperLayout -Visible $rbSniper.Checked; Update-StatusBar; Update-ModeSelectionHighlight })
$rbFull.Add_CheckedChanged({ if ($rbFull.Checked) { Set-SniperLayout -Visible $false }; Update-StatusBar; Update-ModeSelectionHighlight })
$rbArchitect.Add_CheckedChanged({ if ($rbArchitect.Checked) { Set-SniperLayout -Visible $false }; Update-StatusBar; Update-ModeSelectionHighlight })
$rbTxtExport.Add_CheckedChanged({ if ($rbTxtExport.Checked) { Set-SniperLayout -Visible $false }; Update-StatusBar; Update-ModeSelectionHighlight })

$chkSendToAI.Add_CheckedChanged({
    if ($chkSendToAI.Checked) {
        $chkDeterministicDirector.Checked = $false
    }
    Update-AIPromptModeUi
})
$chkDeterministicDirector.Add_CheckedChanged({
    if ($chkDeterministicDirector.Checked) {
        $chkSendToAI.Checked = $false
    }
    Update-AIPromptModeUi
})
$rbPromptModeDefault.Add_CheckedChanged({ Update-AIPromptModeUi })
$rbPromptModeTemplate.Add_CheckedChanged({ Update-AIPromptModeUi })
$rbPromptModeExpert.Add_CheckedChanged({ Update-AIPromptModeUi })
$rbAIFlowDirector.Add_CheckedChanged({ Update-AIPromptModeUi; Update-ModeSelectionHighlight })
$rbAIFlowExecutor.Add_CheckedChanged({ Update-AIPromptModeUi; Update-ModeSelectionHighlight })

$rbGroq.Add_CheckedChanged({ Update-ProviderStatus })
$rbGemini.Add_CheckedChanged({ Update-ProviderStatus })
$rbOpenAI.Add_CheckedChanged({ Update-ProviderStatus })
$rbAnthropic.Add_CheckedChanged({ Update-ProviderStatus })

$form.Add_Shown({
        Set-SniperLayout -Visible $false
        Update-AIPromptModeUi
        Update-StatusBar
        Update-ModeSelectionHighlight
        Set-HudNormalSize
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
# ENERGIZE HOVER EFFECTS
# ══════════════════════════════════════════════════════════════════
$btnRun.Add_MouseEnter({
    if ($btnRun.Enabled) {
        $btnRun.BackColor = $ThemeCyan
        $btnRun.ForeColor = $ThemeBg
    }
})
$btnRun.Add_MouseLeave({
    $btnRun.BackColor = $ThemeCyanDark
    $btnRun.ForeColor = $ThemeCyan
})

# ══════════════════════════════════════════════════════════════════
# LOG ENGINE
# ══════════════════════════════════════════════════════════════════
function Get-LogLevel {
    param([System.Drawing.Color]$Color)
    if ($Color.ToArgb() -eq $ThemeCyan.ToArgb()) { return "ia" }
    if ($Color.ToArgb() -eq $ThemeSuccess.ToArgb()) { return "success" }
    if ($Color.ToArgb() -eq $ThemePink.ToArgb()) { return "warn" }
    return "info"
}

function Test-LogEntryVisible {
    param([hashtable]$Entry)
    $filter = $cmbLogFilter.SelectedItem
    if ($filter -eq "Todos") { return $true }
    if ($filter -eq "IA" -and $Entry.Level -eq "ia") { return $true }
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
    Write-SentinelConsoleLog -Message $Message -Color $Color
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
            Write-UILog -Message "Log copiado para a área de clipboard." -Color $ThemeSuccess
        }
        catch {
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
    $panelMode.Enabled = -not $Busy
    $panelProvider.Enabled = if ($Busy) { $false } else { $chkSendToAI.Checked }
    $panelSniper.Enabled = -not $Busy
    $panelAIPromptMode.Enabled = -not $Busy
    $chkSendToAI.Enabled = -not $Busy
    $chkDeterministicDirector.Enabled = -not $Busy
    $btnRun.Enabled = -not $Busy
    $progressBar.Visible = $Busy
    $btnRun.Text = if ($Busy) { "..." } else { "ENERGIZE" }
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
        [string]$CustomPromptConfigPath = $null
    )

    if (-not (Test-Path $AgentScriptPath)) { throw "Script groq-agent.ts não localizado." }

    $winner = [ordered]@{ Provider = $null; Model = $null }
    $failure = [ordered]@{ Type = $null; Status = $null; Message = $null; Details = $null }
    $script:LastAgentFailure = $null
    $stdoutTranscript = New-Object 'System.Collections.Generic.List[object]'
    $stderrTranscript = New-Object 'System.Collections.Generic.List[object]'
    $combinedTranscript = New-Object 'System.Collections.Generic.List[object]'
    $processStartedAtUtc = $null
    $processFinishedAtUtc = $null
    $processDurationMs = 0
    $processId = $null

    $handleAgentLine = {
        param([string]$Line, [System.Drawing.Color]$DefaultColor, [string]$StreamName = "stdout")
        if ([string]::IsNullOrWhiteSpace($Line)) { return }

        $capturedAt = [DateTime]::UtcNow.ToString("o")
        $transcriptEntry = @{
            stream     = $StreamName
            capturedAt = $capturedAt
            line       = $Line
        }

        if ($StreamName -eq "stderr") {
            $stderrTranscript.Add($transcriptEntry) | Out-Null
        }
        else {
            $stdoutTranscript.Add($transcriptEntry) | Out-Null
        }

        $combinedTranscript.Add($transcriptEntry) | Out-Null

        if ($Line -match '^\[AI_ERROR\]\s+(.+)$') {
            try {
                $parsedFailure = $Matches[1] | ConvertFrom-Json
                $failure.Type = [string]$parsedFailure.type
                $failure.Status = [string]$parsedFailure.status
                $failure.Message = [string]$parsedFailure.message
                $failure.Details = [string]$parsedFailure.details
                $script:LastAgentFailure = [pscustomobject]@{
                    Type    = $failure.Type
                    Status  = $failure.Status
                    Message = $failure.Message
                    Details = $failure.Details
                }
            }
            catch {}
            return
        }

        if ($Line -match '\[_ai_\]\s+provider=([^;]+);model=(.+)$') {
            $winner.Provider = $Matches[1].Trim()
            $winner.Model = $Matches[2].Trim()
            return
        }

        Write-UILog -Message $Line -Color $DefaultColor
    }.GetNewClosure()

    $bundleParent = Split-Path $BundlePath -Parent
    $routeToken = if ($OutputRouteModeValue -eq 'executor') { 'executor' } else { 'diretor' }
    $normalizedProjectName = [System.IO.Path]::GetFileNameWithoutExtension($BundlePath) -replace '^_+(?:Diretor|Executor)_(?:BUNDLER__|BLUEPRINT__|SELECTIVE__|COPIAR_TUDO__|INTELIGENTE__|MANUAL__)?', ''
    $resultMetaFileName = Get-AIResultOutputFileName -ProjectNameValue $normalizedProjectName -RouteMode $OutputRouteModeValue -ExtractionMode $BundleModeValue
    $resultMetaPath = Join-Path $bundleParent $resultMetaFileName

    $commandParts = @(
        "npx",
        "--quiet",
        "tsx",
        "`"$AgentScriptPath`"",
        "--bundlePath",
        "`"$BundlePath`"",
        "--projectName",
        "`"$ProjectNameValue`"",
        "--executorTarget",
        "`"$ExecutorTargetValue`"",
        "--extractionMode",
        "`"$BundleModeValue`"",
        "--provider",
        "`"$PrimaryProviderValue`"",
        "--routeMode",
        "`"$OutputRouteModeValue`"",
        "--resultMetaPath",
        "`"$resultMetaPath`""
    )

    if (-not [string]::IsNullOrWhiteSpace($CustomPromptConfigPath)) {
        $commandParts += "--promptConfigFilePath"
        $commandParts += "`"$CustomPromptConfigPath`""
    }

    $entrypointDisplay = "npx --quiet tsx $([System.IO.Path]::GetFileName($AgentScriptPath))"
    $commandLine = "/c " + ($commandParts -join " ")

    Write-UILog -Message "Host de execução do agente: cmd.exe /c" -Color $ThemeCyan
    Write-UILog -Message "Entrypoint do agente: $entrypointDisplay" -Color $ThemeCyan
    Write-UILog -Message "Provider alvo: $PrimaryProviderValue | Bundle: $([System.IO.Path]::GetFileName($BundlePath))" -Color $ThemeCyan

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $process.StartInfo.FileName = "cmd.exe"
    $process.StartInfo.Arguments = $commandLine
    $process.StartInfo.WorkingDirectory = $ToolkitDir
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.EnvironmentVariables["DOTENV_CONFIG_SILENT"] = "true"
    $process.StartInfo.EnvironmentVariables["npm_config_update_notifier"] = "false"
    $process.StartInfo.EnvironmentVariables["NO_UPDATE_NOTIFIER"] = "1"

    if (-not $process.Start()) { throw "Falha ao iniciar o processo do agente de IA." }

    $processStartedAtUtc = [DateTime]::UtcNow
    $processId = $process.Id

    while (-not $process.HasExited) {
        while ($process.StandardOutput.Peek() -ge 0) { & $handleAgentLine $process.StandardOutput.ReadLine() $ThemeCyan "stdout" }
        while ($process.StandardError.Peek() -ge 0) { & $handleAgentLine $process.StandardError.ReadLine() $ThemePink "stderr" }
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 100
    }

    $process.WaitForExit()

    while ($process.StandardOutput.Peek() -ge 0) { & $handleAgentLine $process.StandardOutput.ReadLine() $ThemeCyan "stdout" }
    while ($process.StandardError.Peek() -ge 0) { & $handleAgentLine $process.StandardError.ReadLine() $ThemePink "stderr" }

    $processFinishedAtUtc = [DateTime]::UtcNow
    if ($processStartedAtUtc) {
        $processDurationMs = [int][Math]::Round(($processFinishedAtUtc - $processStartedAtUtc).TotalMilliseconds)
    }

    if ($process.ExitCode -ne 0) {
        throw "groq-agent.ts finalizou com código $($process.ExitCode)."
    }

    $script:LastAgentFailure = $null

    $resultMetaPathFromDisk = $null
    if (Test-Path $resultMetaPath) {
        $resultMetaPathFromDisk = $resultMetaPath
    }

    if ($resultMetaPathFromDisk) {
        try {
            $meta = (Read-LocalTextArtifact -Path $resultMetaPathFromDisk) | ConvertFrom-Json -AsHashtable
            if ($null -eq $meta) { $meta = @{} }

            $processAudit = @{}
            if ($meta.ContainsKey('processAudit') -and $meta.processAudit -is [System.Collections.IDictionary]) {
                $processAudit = @{} + $meta.processAudit
            }

            $processAudit.launcher = @{
                host             = 'cmd.exe /c'
                entrypoint       = $entrypointDisplay
                commandLine      = ('cmd.exe {0}' -f $commandLine)
                workingDirectory = $ToolkitDir
                bundlePath       = $BundlePath
                startedAt        = if ($processStartedAtUtc) { $processStartedAtUtc.ToString('o') } else { $null }
                finishedAt       = if ($processFinishedAtUtc) { $processFinishedAtUtc.ToString('o') } else { $null }
                durationMs       = $processDurationMs
                exitCode         = $process.ExitCode
                processId        = $processId
            }

            $processAudit.streamTranscript = @{
                stdout   = @($stdoutTranscript.ToArray())
                stderr   = @($stderrTranscript.ToArray())
                combined = @($combinedTranscript.ToArray())
            }

            $processAudit.auxiliaryScripts = @{
                patchAgent = @{
                    path     = (Join-Path $ToolkitDir 'patch_agent.js')
                    invoked  = $false
                    evidence = 'Nenhuma execução automática de patch_agent.js foi registrada nesta chamada do orquestrador.'
                }
            }

            $meta.processAudit = $processAudit
            $meta.resultMetaPath = $resultMetaPathFromDisk
            $meta.winnerProvider = if ($winner.Provider) { $winner.Provider } else { $meta.provider }
            $meta.winnerModel = if ($winner.Model) { $winner.Model } else { $meta.model }

            $metaJson = $meta | ConvertTo-Json -Depth 20
            Write-LocalTextArtifact -Path $resultMetaPathFromDisk -Content $metaJson

            return [pscustomobject]@{
                OutputPath     = $meta.outputPath
                ResultMetaPath = $resultMetaPathFromDisk
                WinnerProvider = if ($winner.Provider) { $winner.Provider } else { $meta.provider }
                WinnerModel    = if ($winner.Model) { $winner.Model } else { $meta.model }
            }
        }
        catch {
            return [pscustomobject]@{
                OutputPath     = $null
                ResultMetaPath = $resultMetaPathFromDisk
                WinnerProvider = $winner.Provider
                WinnerModel    = $winner.Model
            }
        }
    }

    return [pscustomobject]@{
        OutputPath     = $null
        ResultMetaPath = $null
        WinnerProvider = $winner.Provider
        WinnerModel    = $winner.Model
    }
}

# ══════════════════════════════════════════════════════════════════
# PROTOCOL HEADER BUILDER
# ══════════════════════════════════════════════════════════════════

function Get-ProtocolSliceSection0 { return (Get-VibeProtocolSliceSection0) }

function Get-ProtocolSliceSection1 {
    param([string]$RouteMode, [string]$ExtractionMode)
    return (Get-VibeProtocolSliceSection1 -RouteMode $RouteMode -ExtractionMode $ExtractionMode)
}

function Get-ProtocolSliceDirectorMode { return (Get-VibeProtocolSliceDirectorMode) }

function Get-ProtocolSliceExecutorMode { return (Get-VibeProtocolSliceExecutorMode) }

function Get-ProtocolSliceBlueprintMode { return (Get-VibeProtocolSliceBlueprintMode) }

function Get-ProtocolSliceSniperMode { return (Get-VibeProtocolSliceSniperMode) }

function Get-ProtocolSliceSection3 {
    param([string]$RouteMode, [string]$ExtractionMode)
    return (Get-VibeProtocolSliceSection3 -RouteMode $RouteMode -ExtractionMode $ExtractionMode)
}

function Get-ProtocolSliceSection4 {
    param([string]$ExecutorTargetValue)
    return (Get-VibeProtocolSliceSection4 -ExecutorTargetValue $ExecutorTargetValue)
}

function Get-DirectorEliteV3ProtocolSection0 {
    param([string]$ExecutorTargetValue)
    return (Get-VibeDirectorEliteV3ProtocolSection0 -ExecutorTargetValue $ExecutorTargetValue)
}

function Get-DirectorEliteV3ProtocolSection1 {
    param([string]$ExtractionMode)
    return (Get-VibeDirectorEliteV3ProtocolSection1 -ExtractionMode $ExtractionMode)
}

function Get-DirectorEliteV3ProtocolSection2 { return (Get-VibeDirectorEliteV3ProtocolSection2) }

function Get-DirectorEliteV3ProtocolSection3 { return (Get-VibeDirectorEliteV3ProtocolSection3) }

function Get-DirectorHighFidelityMetadataSection {
    param(
        [string]$ProjectNameValue,
        [string]$ExtractionMode,
        [string]$DocumentMode,
        [string]$GeneratedAt,
        [string]$SourceArtifactFileName,
        [string]$OutputArtifactFileName,
        [string]$ExecutorTargetValue
    )
    return (Get-VibeDirectorHighFidelityMetadataSection -ProjectNameValue $ProjectNameValue -ExtractionMode $ExtractionMode -DocumentMode $DocumentMode -GeneratedAt $GeneratedAt -SourceArtifactFileName $SourceArtifactFileName -OutputArtifactFileName $OutputArtifactFileName -ExecutorTargetValue $ExecutorTargetValue)
}

function Get-DirectorHighFidelitySystemGovernanceSection { return (Get-VibeDirectorHighFidelitySystemGovernanceSection) }

function Get-DirectorHighFidelityMetaPromptEngineeringLayersSection {
    param([string[]]$TargetFiles)
    return (Get-VibeDirectorHighFidelityMetaPromptEngineeringLayersSection -TargetFiles $TargetFiles)
}

function Get-DirectorHighFidelityResponseTemplateSection { return (Get-VibeDirectorHighFidelityResponseTemplateSection) }

function Get-DirectorHighFidelityContextMomentumSection {
    param([string]$MomentumState, [string]$MomentumSource)
    return (Get-VibeDirectorHighFidelityContextMomentumSection -MomentumState $MomentumState -MomentumSource $MomentumSource)
}

function Get-ProtocolHeaderContent {
    param([string]$RouteMode, [string]$ExtractionMode, [string]$ExecutorTargetValue)
    return (Get-VibeProtocolHeaderContent -RouteMode $RouteMode -ExtractionMode $ExtractionMode -ExecutorTargetValue $ExecutorTargetValue)
}

function Normalize-BundleContentForDiff {
    param([AllowEmptyString()][string]$Content)
    if ($null -eq $Content) { return "" }
    return (($Content -replace "`0", "") -replace "`r`n", "`n").TrimEnd()
}

function Get-BundleContentHash {
    param([AllowEmptyString()][string]$Content)
    $normalized = Normalize-BundleContentForDiff -Content $Content
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Read-NormalizedBundleFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    $raw = Read-LocalTextArtifact -Path $Path
    return (Normalize-BundleContentForDiff -Content $raw)
}

function Confirm-IdenticalBundleProceed {
    param([string]$BundlePath)
    $message = "Conteúdo idêntico detectado.`n`nArquivo:`n$BundlePath`n`nDeseja prosseguir com a IA mesmo assim?"
    $dialogResult = [System.Windows.Forms.MessageBox]::Show(
        $message, "Bundle idêntico detectado",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    return ($dialogResult -eq [System.Windows.Forms.DialogResult]::Yes)
}

function Resolve-BundlePreflightGate {
    param(
        [string]$OfficialBundlePath,
        [AllowEmptyString()][string]$NewBundleContent
    )
    $normalizedNew = Normalize-BundleContentForDiff -Content $NewBundleContent
    $newHash = Get-BundleContentHash -Content $normalizedNew

    $officialExists = Test-Path $OfficialBundlePath
    $officialNormalized = $null
    $officialHash = $null
    $isIdentical = $false

    if ($officialExists) {
        $officialNormalized = Read-NormalizedBundleFile -Path $OfficialBundlePath
        $officialHash = Get-BundleContentHash -Content $officialNormalized
        $isIdentical = ($officialHash -eq $newHash)
    }

    return [pscustomobject]@{
        OfficialExists = $officialExists
        IsIdentical    = $isIdentical
        NewHash        = $newHash
        OfficialHash   = $officialHash
    }
}

# ══════════════════════════════════════════════════════════════════
# ENERGIZE BUTTON
# ══════════════════════════════════════════════════════════════════
$btnRun.Add_Click({
        $currentChoice = Resolve-ChoiceFromUI -RbFull $rbFull -RbArchitect $rbArchitect -RbSniper $rbSniper -RbTxtExport $rbTxtExport
        $currentExecutorTarget = $cmbExecutorInline.SelectedItem
        $currentAIProvider = Resolve-AIProviderFromUI -RbGroq $rbGroq -RbGemini $rbGemini -RbOpenAI $rbOpenAI -RbAnthropic $rbAnthropic
        $currentAIPromptMode = Resolve-AIPromptModeFromUI -RbDefault $rbPromptModeDefault -RbTemplate $rbPromptModeTemplate -RbExpert $rbPromptModeExpert
        $currentAIFlowMode = Resolve-AIFlowModeFromUI -RbDirector $rbAIFlowDirector -RbExecutor $rbAIFlowExecutor
        $currentExtractionMode = Resolve-ExtractionModeFromChoice -Choice $currentChoice
        $currentDocumentMode = Resolve-DocumentModeFromExtractionMode -ExtractionMode $currentExtractionMode

        if (-not $currentChoice) {
            [System.Windows.Forms.MessageBox]::Show("Selecione um modo de extração.", "VibeToolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }
        if ($chkSendToAI.Checked -and -not $chkDeterministicDirector.Checked -and -not $currentAIProvider) {
            [System.Windows.Forms.MessageBox]::Show("Selecione a IA primária.", "VibeToolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }
        if (-not $currentExecutorTarget) {
            [System.Windows.Forms.MessageBox]::Show("Selecione o executor alvo.", "VibeToolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }
        if ($chkSendToAI.Checked -and -not $chkDeterministicDirector.Checked -and $currentAIPromptMode -eq "expert" -and [string]::IsNullOrWhiteSpace($txtCustomSystemPrompt.Text)) {
            [System.Windows.Forms.MessageBox]::Show("No modo Expert Override, preencha as diretrizes do especialista.", "VibeToolkit",
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }

        $selectedFiles = @()
        $unselectedFiles = @()

        if ($currentChoice -eq '3') {
            foreach ($fileNode in (Get-AllFileNodes -Nodes $treeFiles.Nodes)) {
                if ($fileNode.Checked) { $selectedFiles += [System.IO.FileInfo]$fileNode.Tag }
                else { $unselectedFiles += [System.IO.FileInfo]$fileNode.Tag }
            }
            if ($selectedFiles.Count -eq 0) {
                [System.Windows.Forms.MessageBox]::Show("No modo Sniper, selecione pelo menos um arquivo.", "VibeToolkit",
                    [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
                return
            }
        }
        else {
            $selectedFiles = @($FoundFiles)
        }

        $Choice = $currentChoice
        $ExecutorTarget = $currentExecutorTarget
        $AIProvider = $currentAIProvider
        $FilesToProcess = @($selectedFiles)
        $SendToAI = $chkSendToAI.Checked
        $UseDeterministicDirector = $chkDeterministicDirector.Checked
        $ResolvedOutputRouteMode = $currentAIFlowMode
        $CallFinalGenerator = $SendToAI -or $UseDeterministicDirector
        $TempPromptConfigPath = $null
        $TempBundlePath = $null

        Set-UiBusy -Busy $true
        $logViewer.Clear()
        $script:LogEntries.Clear()

        try {
            Write-UILog -Message "HUD energizado." -Color $ThemeCyan
            Write-UILog -Message "Projeto: $ProjectName"
            Write-UILog -Message "Modo: $(if ($Choice -eq '1') { 'Full Vibe' } elseif ($Choice -eq '2') { 'Architect' } elseif ($Choice -eq '3') { 'Sniper' } else { 'TXT Export' })"
            Write-UILog -Message "Executor alvo: $ExecutorTarget"
            if ($SendToAI -and -not $UseDeterministicDirector) { Write-UILog -Message "IA primária: $AIProvider" -Color $ThemeCyan }
            if ($UseDeterministicDirector) { Write-UILog -Message "Fluxo local determinístico: sem provider remoto e sem groq-agent.ts." -Color $ThemeCyan }
            Write-UILog -Message "Arquivos na operação: $($FilesToProcess.Count)"
            if ($Choice -eq '3') {
                Write-UILog -Message "Sniper: $($FilesToProcess.Count) arquivo(s) selecionado(s) em modo manual." -Color $ThemeCyan
                if ($unselectedFiles.Count -gt 0) {
                    Write-UILog -Message "Sniper: $($unselectedFiles.Count) arquivo(s) não selecionado(s) serão anexados em modo Bundler." -Color $ThemeCyan
                }
            }
            Write-UILog -Message "Geração final: $(if ($UseDeterministicDirector) { 'Determinística local' } elseif ($SendToAI) { $currentAIPromptMode } else { 'Desabilitada' })"
            Write-UILog -Message "Fluxo final: $(if ($ResolvedOutputRouteMode -eq 'executor') { 'Direto para Executor' } else { 'Via Diretor' })"

            $IsTxtExportMode = ($Choice -eq '4')

            if ($IsTxtExportMode) {
                Write-UILog -Message "Iniciando Modo TXT Export..." -Color $ThemeCyan

                if ($SendToAI) {
                    Write-UILog -Message "Modo TXT Export ignora chamada de IA por desenho." -Color $ThemeWarn
                }

                $TxtExportResult = Export-OperationFilesToTxtDirectory `
                    -Files $FilesToProcess `
                    -ProjectRootPath (Get-Location).Path `
                    -BaseOutputDirectory (Get-Location).Path `
                    -ProjectNameValue $ProjectName

                Write-UILog -Message "Pasta de saída: $($TxtExportResult.OutputDirectory)" -Color $ThemeSuccess
                Write-UILog -Message "Arquivo ZIP: $($TxtExportResult.ZipFilePath)" -Color $ThemeSuccess
                Write-UILog -Message "Arquivos exportados: $($TxtExportResult.ExportedFiles.Count)" -Color $ThemeSuccess

                if ($TxtExportResult.SkippedFiles.Count -gt 0) {
                    Write-UILog -Message "Arquivos ignorados por incompatibilidade/erro: $($TxtExportResult.SkippedFiles.Count)" -Color $ThemeWarn
                }

                $TxtExportMetaResult = Write-LocalExecutionMeta `
                    -ProjectNameValue $ProjectName `
                    -RouteMode $ResolvedOutputRouteMode `
                    -ExtractionMode $currentExtractionMode `
                    -DocumentMode "txt_export" `
                    -PromptMode "local" `
                    -Provider "local" `
                    -Model "txt-export" `
                    -OutputPath $TxtExportResult.ZipFilePath `
                    -ExtraData @{
                        outputDirectory   = $TxtExportResult.OutputDirectory
                        zipFilePath       = $TxtExportResult.ZipFilePath
                        exportedFiles     = @($TxtExportResult.ExportedFiles)
                        skippedFiles      = @($TxtExportResult.SkippedFiles)
                        exportedFileCount = $TxtExportResult.ExportedFiles.Count
                        skippedFileCount  = $TxtExportResult.SkippedFiles.Count
                    }

                Write-UILog -Message "Metadados locais salvos em: $($TxtExportMetaResult.ResultMetaPath)" -Color $ThemeSuccess

                return
            }

            $HeaderContent = Get-ProtocolHeaderContent `
                -RouteMode $ResolvedOutputRouteMode `
                -ExtractionMode $currentExtractionMode `
                -ExecutorTargetValue $ExecutorTarget

            $FinalContent = $HeaderContent + "`n`n"
            $MomentumContext = $null
            $ShouldLoadMomentumContext = ($ResolvedOutputRouteMode -eq 'director') -or $UseDeterministicDirector

            if ($ShouldLoadMomentumContext) {
                $MomentumContext = Resolve-LatestMomentumContext -SearchRoot (Get-Location).Path

                foreach ($MomentumWarning in @($MomentumContext.Warnings)) {
                    Write-UILog -Message $MomentumWarning -Color $ThemeWarn
                }

                if ($MomentumContext.Status -eq 'found') {
                    Write-UILog -Message "Contexto Momentum carregado: $([System.IO.Path]::GetFileName($MomentumContext.FilePath))" -Color $ThemeCyan
                }
                else {
                    Write-UILog -Message $MomentumContext.Message -Color $ThemeWarn
                }
            }

            if ($ResolvedOutputRouteMode -eq 'director') {
                $FinalContent += (Get-MomentumSectionContent -MomentumContext $MomentumContext) + "`n`n"
            }

            $BlueprintIssues = @()

            if ($Choice -eq '1' -or $Choice -eq '3') {
                if ($Choice -eq '1') {
                    $OutputFile = Get-VibeArtifactFileName -ProjectNameValue $ProjectName -ExtractionMode $Choice -RouteMode $ResolvedOutputRouteMode
                    $HeaderTitle = "MODO COPIAR TUDO"
                    Write-UILog -Message "Iniciando Modo Copiar Tudo..." -Color $ThemeCyan
                }
                else {
                    $OutputFile = Get-VibeArtifactFileName -ProjectNameValue $ProjectName -ExtractionMode $Choice -RouteMode $ResolvedOutputRouteMode
                    $HeaderTitle = "MODO MANUAL"
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
                    $Content = Read-LocalTextArtifact -Path $File.FullName
                    if ($Content) {
                        $Content = $Content -replace "(`r?`n){3,}", "`r`n`r`n"
                        $FinalContent += "#### File: $RelPath`n"
                        $FinalContent += (Convert-ToSafeMarkdownCodeBlock -Content $Content.TrimEnd() -Language 'text') + "`n`n"
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
            }
            else {
                $OutputFile = Get-VibeArtifactFileName -ProjectNameValue $ProjectName -ExtractionMode $Choice -RouteMode $ResolvedOutputRouteMode
                Write-UILog -Message "Iniciando Modo Architect / Inteligente..." -Color $ThemeCyan
                $FinalContent += "## MODO INTELIGENTE: $ProjectName`n`n"
                $FinalContent += "### 1. TECH STACK`n"

                $PackageJsonPath = Join-Path $ToolkitDir "package.json"
                if (Test-Path $PackageJsonPath -PathType Leaf) {
                    Write-UILog -Message "Lendo package.json para tech stack..."
                    $Pkg = (Read-LocalTextArtifact -Path $PackageJsonPath) | ConvertFrom-Json
                    if ($Pkg.dependencies) { $FinalContent += "* **Deps:** $(($Pkg.dependencies.PSObject.Properties.Name -join ', '))`n" }
                    if ($Pkg.devDependencies) { $FinalContent += "* **Dev Deps:** $(($Pkg.devDependencies.PSObject.Properties.Name -join ', '))`n" }
                }
                else {
                    Write-UILog -Message "package.json não encontrado em $PackageJsonPath; tech stack será omitida." -Color $ThemeWarn
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
            $TempBundlePath = Join-Path ([System.IO.Path]::GetTempPath()) ("vibetoolkit-bundle-" + [System.Guid]::NewGuid().ToString("N") + ".md")

            Write-LocalTextArtifact -Path $TempBundlePath -Content $FinalContent

            if ($UseDeterministicDirector) {
                $DeterministicOutputFile = Get-DeterministicMetaPromptOutputFileName -ProjectNameValue $ProjectName -ChoiceValue $Choice -RouteMode $ResolvedOutputRouteMode
                $DeterministicOutputFullPath = Join-Path (Get-Location) $DeterministicOutputFile

                Write-UILog -Message "Fluxo determinístico local ignorará o pre-flight diff gate." -Color $ThemeCyan
                Write-UILog -Message ("Compilando meta-prompt determinístico local diretamente no bundler ({0})..." -f $(if ($ResolvedOutputRouteMode -eq 'executor') { 'executor' } else { 'director' })) -Color $ThemeCyan

                $DeterministicContent = New-DeterministicMetaPromptArtifact `
                    -ProjectNameValue $ProjectName `
                    -ExecutorTargetValue $ExecutorTarget `
                    -RouteMode $ResolvedOutputRouteMode `
                    -ExtractionMode $currentExtractionMode `
                    -DocumentMode $currentDocumentMode `
                    -SourceArtifactFileName $OutputFile `
                    -OutputArtifactFileName $DeterministicOutputFile `
                    -BundleContent $FinalContent `
                    -Files $FilesToProcess `
                    -MomentumContext $MomentumContext

                Write-LocalTextArtifact -Path $DeterministicOutputFullPath -Content $DeterministicContent -UseBom

                $DeterministicMetaResult = Write-LocalExecutionMeta `
                    -ProjectNameValue $ProjectName `
                    -RouteMode $ResolvedOutputRouteMode `
                    -ExtractionMode $currentExtractionMode `
                    -DocumentMode $currentDocumentMode `
                    -PromptMode "deterministic_local" `
                    -TemplateId $(if ($ResolvedOutputRouteMode -eq "executor") { "executor_meta_v1" } else { "director_meta_v1" }) `
                    -Provider "local" `
                    -Model $(if ($ResolvedOutputRouteMode -eq "executor") { "deterministic-executor_meta_v1" } else { "deterministic-director_meta_v1" }) `
                    -BundlePath $OutputFullPath `
                    -OutputPath $DeterministicOutputFullPath `
                    -ExtraData @{
                        sourceArtifactFile = $OutputFile
                        outputArtifactFile = $DeterministicOutputFile
                    }

                Write-UILog -Message "Metadados locais salvos em: $($DeterministicMetaResult.ResultMetaPath)" -Color $ThemeSuccess

                $DeterministicTokenEstimate = [math]::Round($DeterministicContent.Length / 4)

                try {
                    $DeterministicContent | Set-Clipboard
                    $CopiedDeterministic = $true
                }
                catch {
                    $CopiedDeterministic = $false
                }

                if ($BlueprintIssues -and $BlueprintIssues.Count -gt 0) {
                    Write-UILog -Message "Artefato gerado com $($BlueprintIssues.Count) aviso(s)." -Color $ThemePink
                    foreach ($Issue in ($BlueprintIssues | Select-Object -First 10)) { Write-UILog -Message $Issue -Color $ThemePink }
                }
                else {
                    Write-UILog -Message "Meta-prompt determinístico consolidado com sucesso." -Color $ThemeSuccess
                }

                $ModoNome = if ($Choice -eq '1') {
                    "Meta-Prompt · Copiar Tudo"
                }
                elseif ($Choice -eq '2') {
                    "Meta-Prompt · Inteligente"
                }
                elseif ($Choice -eq '3') {
                    "Meta-Prompt · Manual"
                }
                else {
                    "Meta-Prompt"
                }

                Write-UILog -Message "Modo: $ModoNome  ·  Executor: $ExecutorTarget"
                Write-UILog -Message "Arquivo: $DeterministicOutputFile"
                Write-UILog -Message "Tokens estimados: ~$(Format-TokenCount -Tokens $DeterministicTokenEstimate)"
                Write-UILog -Message "Meta-prompt determinístico salvo em: $DeterministicOutputFullPath" -Color $ThemeSuccess

                if ($CopiedDeterministic) {
                    Write-UILog -Message "Meta-prompt final copiado para a área de clipboard." -Color $ThemeCyan
                }
                else {
                    Write-UILog -Message "Meta-prompt final gerado, mas clipboard indisponível." -Color $ThemePink
                }

                Write-UILog -Message "Execução concluída sem chamada de IA e sem groq-agent.ts." -Color $ThemeSuccess
                return
            }

            $ShouldCallAI = $false
            $ShouldPersistOfficialBundle = $true
            $Preflight = $null

            if ($SendToAI) {
                $Preflight = Resolve-BundlePreflightGate `
                    -OfficialBundlePath $OutputFullPath `
                    -NewBundleContent $FinalContent

                if (-not $Preflight.OfficialExists) {
                    Write-UILog -Message "Bundle oficial inexistente. Persistindo nova versão e liberando IA." -Color $ThemeCyan
                    $ShouldCallAI = $true
                    $ShouldPersistOfficialBundle = $true
                }
                elseif (-not $Preflight.IsIdentical) {
                    Write-UILog -Message "Diferença detectada no bundle. Atualizando arquivo oficial e liberando IA." -Color $ThemeCyan
                    $ShouldCallAI = $true
                    $ShouldPersistOfficialBundle = $true
                }
                else {
                    Write-UILog -Message "Conteúdo idêntico detectado entre o bundle oficial e o bundle recém-gerado." -Color $ThemePink
                    $ShouldPersistOfficialBundle = $false
                    $ShouldCallAI = Confirm-IdenticalBundleProceed -BundlePath $OutputFullPath

                    if ($ShouldCallAI) {
                        Write-UILog -Message "Usuário autorizou prosseguir com a IA apesar do conteúdo idêntico." -Color $ThemeCyan
                    }
                    else {
                        Write-UILog -Message "IA cancelada pelo usuário após o pre-flight diff gate." -Color $ThemeSuccess
                    }
                }
            }

            if ($ShouldPersistOfficialBundle) {
                Write-LocalTextArtifact -Path $OutputFullPath -Content $FinalContent -UseBom
                Write-UILog -Message "Bundle oficial salvo em: $OutputFullPath" -Color $ThemeSuccess
            }
            else {
                Write-UILog -Message "Bundle oficial preservado sem regravação por não haver diferença de conteúdo." -Color $ThemeSuccess
            }

                        $LocalMetaResult = $null
            if (-not ($SendToAI -and $ShouldCallAI)) {
                $LocalMetaResult = Write-LocalExecutionMeta `
                    -ProjectNameValue $ProjectName `
                    -RouteMode $ResolvedOutputRouteMode `
                    -ExtractionMode $currentExtractionMode `
                    -DocumentMode $currentDocumentMode `
                    -PromptMode $(if ($SendToAI) { "local_no_provider" } else { "local" }) `
                    -Provider "local" `
                    -Model "bundler-local" `
                    -BundlePath $OutputFullPath `
                    -OutputPath $OutputFullPath `
                    -ExtraData @{
                        promptGenerationSkipped = $true
                        skippedReason = $(if ($SendToAI) { "identical_bundle_user_cancelled_ai" } else { "provider_not_requested" })
                    }

                Write-UILog -Message "Metadados locais salvos em: $($LocalMetaResult.ResultMetaPath)" -Color $ThemeSuccess
            }

            $TokenEstimate = [math]::Round($FinalContent.Length / 4)


            try { $FinalContent | Set-Clipboard; $Copied = $true } catch { $Copied = $false }

            if ($BlueprintIssues -and $BlueprintIssues.Count -gt 0) {
                Write-UILog -Message "Artefato gerado com $($BlueprintIssues.Count) aviso(s)." -Color $ThemePink
                foreach ($Issue in ($BlueprintIssues | Select-Object -First 10)) { Write-UILog -Message $Issue -Color $ThemePink }
            }
            else {
                Write-UILog -Message "Artefato consolidado com sucesso." -Color $ThemeSuccess
            }

            $ModoNome = if ($Choice -eq '1') {
                "Copiar Tudo"
            }
            elseif ($Choice -eq '2') {
                "Inteligente"
            }
            elseif ($Choice -eq '3') {
                "Manual"
            }
            else {
                "TXT Export"
            }
            Write-UILog -Message "Modo: $ModoNome  ·  Executor: $ExecutorTarget"
            Write-UILog -Message "Arquivo: $OutputFile"
            Write-UILog -Message "Tokens estimados: ~$(Format-TokenCount -Tokens $TokenEstimate)"

            if ($Copied) { Write-UILog -Message "Bundle copiado para a área de clipboard." -Color $ThemeCyan }
            else { Write-UILog -Message "Arquivo salvo. Clipboard indisponível." -Color $ThemePink }

            if ($SendToAI -and $ShouldCallAI) {
                Write-UILog -Message "Chamando agente de IA..." -Color $ThemeCyan
                Write-UILog -Message "Provider primário: $AIProvider | fallback automático ativo." -Color $ThemeCyan

                # Preparar payload JSON do modo selecionado
                $TempPromptConfigPath = Join-Path ([System.IO.Path]::GetTempPath()) ("vibetoolkit-config-" + [System.Guid]::NewGuid().ToString("N") + ".json")
            
                if ($currentAIPromptMode -eq "template") {
                    $SelectedTemplate = $TemplateOptions | Where-Object { $_.Name -eq $cmbTemplateId.SelectedItem } | Select-Object -First 1
                    $ConfigPayload = @{
                        promptMode             = "template"
                        routeMode              = $currentAIFlowMode
                        extractionMode         = $currentExtractionMode
                        executorTarget         = $currentExecutorTarget
                        templateId             = if ($SelectedTemplate) { $SelectedTemplate.Id } else { $null }
                        objective              = $txtTemplateObjective.Text
                        deliveryType           = $txtTemplateDelivery.Text
                        focusTags              = @($txtTemplateFocus.Text -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
                        constraints            = @($txtTemplateConstraints.Text -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
                        depth                  = if ($null -ne $cmbTemplateDepth -and $cmbTemplateDepth.SelectedIndex -ge 0) { $cmbTemplateDepth.SelectedItem.ToString().ToLower() } else { $null }
                        additionalInstructions = $txtTemplateAdditional.Text
                    }
                    Write-UILog -Message "Modo Template selecionado: $($SelectedTemplate.Name)" -Color $ThemeCyan
                }
                elseif ($currentAIPromptMode -eq "expert") {
                    $ConfigPayload = @{
                        promptMode         = "expertOverride"
                        routeMode          = $currentAIFlowMode
                        extractionMode     = $currentExtractionMode
                        executorTarget     = $currentExecutorTarget
                        expertSystemPrompt = $txtCustomSystemPrompt.Text
                    }
                    Write-UILog -Message "Modo Expert Override: injetando diretrizes customizadas no pipeline." -Color $ThemePink
                }
                else {
                    $ConfigPayload = @{
                        promptMode     = "default"
                        routeMode      = $currentAIFlowMode
                        extractionMode = $currentExtractionMode
                        executorTarget = $currentExecutorTarget
                    }
                    Write-UILog -Message "Modo Padrão: usando fluxo nativo configurado no agente." -Color $ThemeCyan
                }

                $ConfigJson = $ConfigPayload | ConvertTo-Json -Depth 3 -Compress
                Write-LocalTextArtifact -Path $TempPromptConfigPath -Content $ConfigJson

                $AgentScript = Join-Path $ToolkitDir "groq-agent.ts"
            
                $AgentResult = Invoke-OrchestratorAgent `
                    -AgentScriptPath $AgentScript `
                    -BundlePath $OutputFullPath `
                    -ProjectNameValue $ProjectName `
                    -ExecutorTargetValue $ExecutorTarget `
                    -BundleModeValue $currentExtractionMode `
                    -PrimaryProviderValue $(if ($UseDeterministicDirector) { "groq" } else { $AIProvider }) `
                    -OutputRouteModeValue $ResolvedOutputRouteMode `
                    -CustomPromptConfigPath $TempPromptConfigPath

                $FinalPromptPath = $null
                if ($AgentResult -and $AgentResult.OutputPath -and (Test-Path $AgentResult.OutputPath)) {
                    $FinalPromptPath = $AgentResult.OutputPath
                }
                else {
                    $bundleParent = Split-Path $OutputFullPath -Parent
                    $candidateContextPaths = @(
                        (Join-Path $bundleParent (Get-AIContextOutputFileName -ProjectNameValue $ProjectName -RouteMode $currentAIFlowMode -ExtractionMode $currentExtractionMode)),
                        (Join-Path $bundleParent "_AI_CONTEXT_${ProjectName}.md")
                    )
                    foreach ($cp in $candidateContextPaths) {
                        if (Test-Path $cp) { $FinalPromptPath = $cp; break }
                    }
                }

                if ($FinalPromptPath) {
                    $FinalSummarizedContent = Read-LocalTextArtifact -Path $FinalPromptPath
                    try {
                        $FinalSummarizedContent | Set-Clipboard
                        Write-UILog -Message "Prompt final preparado e copiado para o clipboard." -Color $ThemeSuccess
                    }
                    catch {
                        Write-UILog -Message "Prompt final gerado, mas clipboard indisponível." -Color $ThemePink
                    }
                }
                else {
                    Write-UILog -Message "Arquivo final da IA não foi localizado." -Color $ThemePink
                }

                if ($AgentResult -and $AgentResult.WinnerProvider) {
                    Write-UILog -Message "Provider efetivo: $($AgentResult.WinnerProvider) | Modelo: $($AgentResult.WinnerModel)" -Color $ThemeSuccess
                }

                Write-UILog -Message "$(if ($currentAIFlowMode -eq 'executor') { 'Agora é só colar no seu executor.' } else { 'Agora é só colar no seu orquestrador.' })" -Color $ThemeCyan
            }
            elseif ($SendToAI) {
                Write-UILog -Message "Execução concluída sem chamada da IA." -Color $ThemeSuccess
            }
            else {
                Write-UILog -Message "Execução concluída sem chamada da IA." -Color $ThemeSuccess
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            $errorTitle = "Falha na execução"
            $errorIcon = [System.Windows.Forms.MessageBoxIcon]::Error
            $agentFailure = $script:LastAgentFailure

            if ($agentFailure -and $agentFailure.Type) {
                switch ($agentFailure.Type) {
                    "AUTH_ERROR" {
                        $errorTitle = "Erro de Configuração / API Keys"
                        $errorMessage = "O agente falhou devido a um erro de autenticação ou configuração das chaves de API.`n`nVerifique seu arquivo .env e tente novamente."
                        $errorIcon = [System.Windows.Forms.MessageBoxIcon]::Warning
                    }
                    "PAYLOAD_TOO_LARGE" {
                        $errorTitle = "Bundle Grande Demais"
                        $errorMessage = "O provider rejeitou o payload por tamanho excessivo (HTTP 413).`n`nReduza o bundle, use Architect/Sniper ou quebre o envio em partes menores."
                        $errorIcon = [System.Windows.Forms.MessageBoxIcon]::Warning
                    }
                    "CONFIG_ERROR" {
                        $errorTitle = "Erro de Configuração da Requisição"
                        $errorMessage = "A requisição foi rejeitada pelo provider por configuração inválida (ex.: modelo, endpoint ou parâmetros).`n`nRevise o provider primário e a configuração enviada antes de tentar novamente."
                        $errorIcon = [System.Windows.Forms.MessageBoxIcon]::Warning
                    }
                    "RATE_LIMIT" {
                        $errorTitle = "Rate Limit / Quota"
                        $errorMessage = "O provider atingiu limite de requisições ou quota (HTTP 429).`n`nAguarde alguns instantes ou revise sua cota antes de repetir a operação."
                        $errorIcon = [System.Windows.Forms.MessageBoxIcon]::Warning
                    }
                    "NETWORK_ERROR" {
                        $errorTitle = "Falha de Rede / Timeout"
                        $errorMessage = "A chamada do agente falhou por rede, timeout ou indisponibilidade transitória.`n`nTente novamente em instantes."
                    }
                    "PROVIDER_DOWN" {
                        $errorTitle = "Provider Indisponível"
                        $errorMessage = "O provider retornou erro de infraestrutura (5xx/overload).`n`nTente trocar o provider primário ou aguarde alguns instantes."
                    }
                    "PARSE_ERROR" {
                        $errorTitle = "Erro de Estrutura / Parse"
                        $errorMessage = "O provider respondeu, mas o payload não pôde ser validado ou reparado no schema esperado.`n`nRevise o prompt/configuração e tente novamente."
                        $errorIcon = [System.Windows.Forms.MessageBoxIcon]::Warning
                    }
                }

                if ($agentFailure.Status) {
                    Write-UILog -Message "Status final do agente: $($agentFailure.Status) | Tipo: $($agentFailure.Type)" -Color $ThemePink
                }
                if ($agentFailure.Details) {
                    Write-UILog -Message "Detalhes técnicos: $($agentFailure.Details)" -Color $ThemePink
                }
            }
            elseif ($errorMessage -match "finalizou com código 1") {
                $errorTitle = "Erro de Configuração / API Keys"
                $errorMessage = "O agente falhou devido a um erro de autenticação ou configuração das chaves de API.`n`nVerifique seu arquivo .env e tente novamente."
                $errorIcon = [System.Windows.Forms.MessageBoxIcon]::Warning
            }
            elseif ($errorMessage -match "finalizou com código 2") {
                $errorTitle = "Rate Limit / Quota"
                $errorMessage = "O provider atingiu limite de requisições ou quota (HTTP 429).`n`nAguarde alguns instantes ou revise sua cota antes de repetir a operação."
                $errorIcon = [System.Windows.Forms.MessageBoxIcon]::Warning
            }
            elseif ($errorMessage -match "finalizou com código 3") {
                $errorTitle = "Erro de Configuração da Requisição"
                $errorMessage = "A requisição foi rejeitada por configuração inválida ou payload excessivo.`n`nRevise modelo, endpoint, parâmetros e tamanho do bundle."
                $errorIcon = [System.Windows.Forms.MessageBoxIcon]::Warning
            }
            elseif ($errorMessage -match "finalizou com código 4") {
                $errorTitle = "Erro de Infraestrutura / Rede"
                $errorMessage = "A chamada ao provider falhou por rede, timeout ou indisponibilidade transitória.`n`nTente novamente em alguns instantes."
            }
            elseif ($errorMessage -match "finalizou com código 5") {
                $errorTitle = "Erro de Estrutura / Parse"
                $errorMessage = "O provider respondeu, mas o payload retornado não pôde ser validado no schema esperado.`n`nRevise o prompt/configuração e tente novamente."
                $errorIcon = [System.Windows.Forms.MessageBoxIcon]::Warning
            }

            Write-UILog -Message $errorMessage -Color $ThemePink
            [System.Windows.Forms.MessageBox]::Show($errorMessage, $errorTitle, [System.Windows.Forms.MessageBoxButtons]::OK, $errorIcon) | Out-Null
        }
        finally {
            if ($TempPromptConfigPath -and (Test-Path $TempPromptConfigPath)) {
                Remove-Item $TempPromptConfigPath -Force -ErrorAction SilentlyContinue
            }
            if ($TempBundlePath -and (Test-Path $TempBundlePath)) {
                Remove-Item $TempBundlePath -Force -ErrorAction SilentlyContinue
            }
            $script:LastAgentFailure = $null
            Set-UiBusy -Busy $false
        }
    })

# ══════════════════════════════════════════════════════════════════
# BOOT
# ══════════════════════════════════════════════════════════════════
Update-StatusBar
Write-UILog -Message "Pronto. Configure o modo, o executor e energize." -Color $ThemeCyan
[void]$form.ShowDialog()