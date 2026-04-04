#requires -Version 7.0

[CmdletBinding()]
param(
    [string]$Path = ".",
    [Alias('Mode')]
    [string]$BundleMode = '',
    [string[]]$SelectedPaths,
    [string]$RouteMode = '',
    [string]$ExecutorTarget = 'ChatGPT',
    [switch]$SendToAI,
    [switch]$DeterministicDirector,
    [string]$Provider = '',
    [string]$AIPromptMode = '',
    [string]$PromptConfigFilePath,
    [string]$TemplateId,
    [string]$TemplateObjective,
    [string]$TemplateDelivery,
    [string[]]$TemplateFocusTags,
    [string[]]$TemplateConstraints,
    [ValidateSet('normal', 'deep', 'max')]
    [string]$TemplateDepth,
    [string]$TemplateAdditionalInstructions,
    [string]$ExpertSystemPrompt,
    [switch]$ForceAIAgainstIdenticalBundle,
    [switch]$NoClipboard,
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:SentinelUtf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $script:SentinelUtf8NoBom
[Console]::OutputEncoding = $script:SentinelUtf8NoBom
$OutputEncoding = $script:SentinelUtf8NoBom

$env:NO_COLOR = '1'
$env:FORCE_COLOR = '0'
$env:TERM = 'dumb'
$env:PYTHONUTF8 = '1'
$env:DOTNET_SYSTEM_CONSOLE_ALLOW_ANSI_COLOR_REDIRECTION = '0'

try {
    if ($PSStyle) {
        $PSStyle.OutputRendering = 'PlainText'
    }
}
catch {
}

$script:ToolkitDir = $PSScriptRoot
$script:LastAgentFailure = $null

$ThemeText = 'Info'
$ThemeCyan = 'Info'
$ThemeSuccess = 'Success'
$ThemeWarn = 'Warning'
$ThemePink = 'Error'

function Write-UILog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Color = $ThemeText
    )

    if ([string]::IsNullOrWhiteSpace($Message)) { return }

    $statusType = switch ($Color) {
        'Success' { 'Success' }
        'Warning' { 'Warning' }
        'Error' { 'Error' }
        default { 'Info' }
    }

    try {
        Write-SentinelStatus -Message $Message -Type $statusType
    }
    catch {
        [Console]::Out.WriteLine($Message)
    }
}

function Get-SentinelUiRequiredFunctionNames {
    return @(
        'Write-SentinelHeader',
        'Write-SentinelStatus'
    )
}

function Get-SentinelUiBootstrapFailureSummary {
    param(
        [Parameter(Mandatory = $true)]
        $ErrorRecord
    )

    $fragments = New-Object System.Collections.Generic.List[string]

    if ($null -ne $ErrorRecord.Exception) {
        if (-not [string]::IsNullOrWhiteSpace($ErrorRecord.Exception.Message)) {
            $fragments.Add([string]$ErrorRecord.Exception.Message) | Out-Null
        }

        if ($null -ne $ErrorRecord.Exception.InnerException -and -not [string]::IsNullOrWhiteSpace($ErrorRecord.Exception.InnerException.Message)) {
            $fragments.Add([string]$ErrorRecord.Exception.InnerException.Message) | Out-Null
        }

        $fragments.Add($ErrorRecord.Exception.GetType().FullName) | Out-Null
    }

    if ($ErrorRecord.FullyQualifiedErrorId) {
        $fragments.Add([string]$ErrorRecord.FullyQualifiedErrorId) | Out-Null
    }

    if ($ErrorRecord.CategoryInfo -and $ErrorRecord.CategoryInfo.Reason) {
        $fragments.Add([string]$ErrorRecord.CategoryInfo.Reason) | Out-Null
    }

    $summary = (($fragments | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ' | ').Trim()

    if ([string]::IsNullOrWhiteSpace($summary)) {
        $summary = ([string]$ErrorRecord).Trim()
    }

    $summary = $summary -replace '\s+', ' '

    if ($summary.Length -gt 500) {
        $summary = $summary.Substring(0, 500) + '...'
    }

    return $summary
}

function Test-IsSentinelUiPolicyBlockedError {
    param(
        [Parameter(Mandatory = $true)]
        $ErrorRecord
    )

    $summary = Get-SentinelUiBootstrapFailureSummary -ErrorRecord $ErrorRecord

    return (
        $summary -match '(?i)not digitally signed' -or
        $summary -match '(?i)cannot be loaded because running scripts is disabled' -or
        $summary -match '(?i)authorizationmanager check failed' -or
        $summary -match '(?i)execution policy' -or
        $summary -match '(?i)PSSecurityException'
    )
}

function Register-SentinelCliFallback {
    $writeSentinelStatus = {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message,

            [ValidateSet('Success', 'Info', 'Warning', 'Error')]
            [string]$Type = 'Info'
        )

        $prefix = switch ($Type) {
            'Success' { '[+]' }
            'Warning' { '[!]' }
            'Error' { '[x]' }
            default { '[*]' }
        }

        Write-Host ("{0} {1}" -f $prefix, $Message)
    }

    $writeSentinelHeader = {
        param(
            [string]$Title = 'SENTINEL',
            [string]$Version = 'v1.0.0'
        )

        Write-Host ('=' * 72)
        Write-Host (" {0}  ·  {1}" -f $Title, $Version)
        Write-Host ('=' * 72)
        Write-Host ''
    }

    Set-Item -Path Function:\script:Write-SentinelStatus -Value $writeSentinelStatus -Force
    Set-Item -Path Function:\script:Write-SentinelHeader -Value $writeSentinelHeader -Force
}

function Assert-SentinelUiBootstrapContract {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SentinelUiPath,
        [switch]$FallbackActive
    )

    $requiredFunctions = @(Get-SentinelUiRequiredFunctionNames)
    $missingFunctions = New-Object System.Collections.Generic.List[string]

    foreach ($requiredFunction in $requiredFunctions) {
        $command = Get-Command -Name $requiredFunction -ErrorAction SilentlyContinue
        if ($null -eq $command -or $command.CommandType -ne 'Function') {
            $missingFunctions.Add($requiredFunction) | Out-Null
        }
    }

    if ($missingFunctions.Count -gt 0) {
        $bootstrapMode = if ($FallbackActive) { 'fallback local' } else { 'SentinelUI carregado' }
        throw "Contrato mínimo de UI indisponível após bootstrap ($bootstrapMode) para '$SentinelUiPath'. Funções ausentes: $($missingFunctions -join ', ')."
    }
}

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
    $files = Get-VibeRelevantFiles -CurrentPath $CurrentPath -AllowedExtensions $script:AllowedExtensions -IgnoredDirs $script:IgnoredDirs -IgnoredFiles $script:IgnoredFiles
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

function Resolve-LatestMomentumContext {
    param([string]$SearchRoot)
    return (Resolve-VibeLatestMomentumContext -SearchRoot $SearchRoot)
}

function Convert-ToSafeMarkdownCodeBlock {
    param(
        [AllowNull()][string]$Content,
        [string]$Language = '',
        [string]$FenceChar = '`'
    )
    return (ConvertTo-VibeSafeMarkdownCodeBlock -Content $Content -Language $Language -FenceChar $FenceChar)
}

function Get-MomentumSectionContent {
    param($MomentumContext)
    return (Get-VibeMomentumSectionContent -MomentumContext $MomentumContext)
}

function Get-CodeFenceLanguageFromExtension {
    param([string]$Extension)
    return (Get-VibeCodeFenceLanguageFromExtension -Extension $Extension)
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
        if ($script:SignatureExtensions -notcontains $File.Extension) { continue }
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

function Resolve-ChoiceFromBundleMode {
    param([string]$ModeValue)

    switch ($ModeValue) {
        'full' { return '1' }
        'blueprint' { return '2' }
        'sniper' { return '3' }
        'txtExport' { return '4' }
        default { throw "Modo inválido: $ModeValue" }
    }
}

function Resolve-ExtractionModeFromBundleMode {
    param([string]$ModeValue)

    switch ($ModeValue) {
        'full' { return 'full' }
        'blueprint' { return 'blueprint' }
        'sniper' { return 'sniper' }
        default { return 'full' }
    }
}


function Test-InteractiveConsoleSelectionSupported {
    try {
        if ([Console]::IsInputRedirected) { return $false }
        if ([Console]::IsOutputRedirected) { return $false }
        $null = $Host.UI.RawUI.WindowSize
        return $true
    }
    catch {
        return $false
    }
}

function Invoke-ConsoleMultiSelect {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Items,
        [string]$Title = 'SENTINEL HEADLESS — Selecao Sniper',
        [string]$Hint = '↑↓ Navegar   ESPACO Marcar/Desmarcar   A Todos   N Nenhum   ENTER Confirmar   Q Cancelar'
    )

    if ($null -eq $Items -or $Items.Count -eq 0) {
        return @()
    }

    $selected = @{}
    $currentIndex = 0
    $offset = 0

    while ($true) {
        $windowHeight = 24
        try {
            $windowHeight = [Math]::Max([Console]::WindowHeight, 18)
        }
        catch {
            $windowHeight = 24
        }

        $pageSize = [Math]::Max(8, $windowHeight - 12)

        if ($currentIndex -lt $offset) {
            $offset = $currentIndex
        }

        if ($currentIndex -ge ($offset + $pageSize)) {
            $offset = $currentIndex - $pageSize + 1
        }

        Clear-Host
        Write-Host ''
        Write-Host '  ═══════════════════════════════════════' -ForegroundColor DarkCyan
        Write-Host ('   {0}' -f $Title) -ForegroundColor Cyan
        Write-Host '  ═══════════════════════════════════════' -ForegroundColor DarkCyan
        Write-Host ''
        Write-Host ('  {0}' -f $Hint) -ForegroundColor DarkGray
        Write-Host ''

        $endIndex = [Math]::Min($Items.Count - 1, $offset + $pageSize - 1)
        for ($i = $offset; $i -le $endIndex; $i++) {
            $item = $Items[$i]
            $isCurrent = ($i -eq $currentIndex)
            $isSelected = $selected.ContainsKey($item)
            $cursor = if ($isCurrent) { '>' } else { ' ' }
            $mark = if ($isSelected) { '[x]' } else { '[ ]' }
            $line = ('  {0} {1} {2}' -f $cursor, $mark, $item)

            if ($isCurrent) {
                Write-Host $line -ForegroundColor Cyan
            }
            elseif ($isSelected) {
                Write-Host $line -ForegroundColor Green
            }
            else {
                Write-Host $line
            }
        }

        if ($endIndex -lt ($Items.Count - 1)) {
            Write-Host '  ...' -ForegroundColor DarkGray
        }

        Write-Host ''
        Write-Host ('  Marcados: {0} de {1}' -f $selected.Count, $Items.Count) -ForegroundColor Yellow

        $rangeStart = $offset + 1
        $rangeEnd = $endIndex + 1
        Write-Host ('  Exibindo: {0}-{1} de {2}' -f $rangeStart, $rangeEnd, $Items.Count) -ForegroundColor DarkGray

        $keyInfo = [Console]::ReadKey($true)
        $keyChar = ''
        if ($keyInfo.KeyChar -ne [char]0) {
            $keyChar = ([string]$keyInfo.KeyChar).ToLowerInvariant()
        }

        switch ($keyInfo.Key) {
            'UpArrow' {
                if ($currentIndex -gt 0) { $currentIndex-- }
                continue
            }
            'DownArrow' {
                if ($currentIndex -lt ($Items.Count - 1)) { $currentIndex++ }
                continue
            }
            'PageUp' {
                $currentIndex = [Math]::Max(0, $currentIndex - $pageSize)
                continue
            }
            'PageDown' {
                $currentIndex = [Math]::Min($Items.Count - 1, $currentIndex + $pageSize)
                continue
            }
            'Home' {
                $currentIndex = 0
                continue
            }
            'End' {
                $currentIndex = $Items.Count - 1
                continue
            }
            'Spacebar' {
                $currentItem = $Items[$currentIndex]
                if ($selected.ContainsKey($currentItem)) {
                    $selected.Remove($currentItem)
                }
                else {
                    $selected[$currentItem] = $true
                }
                continue
            }
            'Escape' {
                throw 'Selecao sniper cancelada pelo usuario.'
            }
            'Enter' {
                if ($selected.Count -eq 0) {
                    Write-Host ''
                    Write-Host '  Selecione pelo menos um item antes de confirmar.' -ForegroundColor Yellow
                    [void][Console]::ReadKey($true)
                    continue
                }

                return @($Items | Where-Object { $selected.ContainsKey($_) })
            }
        }

        switch ($keyChar) {
            'a' {
                $selected = @{}
                foreach ($item in $Items) {
                    $selected[$item] = $true
                }
                continue
            }
            'n' {
                $selected = @{}
                continue
            }
            'q' {
                throw 'Selecao sniper cancelada pelo usuario.'
            }
        }
    }
}

function Resolve-SniperRequestedPaths {
    param(
        [string]$ProjectRootPath,
        [System.IO.FileInfo[]]$AllFiles,
        [string[]]$RequestedPaths,
        [switch]$NonInteractive
    )

    $normalizedRequestedPaths = @($RequestedPaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($normalizedRequestedPaths.Count -gt 0) {
        return $normalizedRequestedPaths
    }

    if ($NonInteractive) {
        throw 'No modo sniper não interativo, informe -SelectedPaths com pelo menos um arquivo ou diretorio.'
    }

    $relativeOptions = @(
        $AllFiles |
        Sort-Object FullName |
        ForEach-Object { Resolve-Path -Path $_.FullName -Relative }
    )

    if (Test-InteractiveConsoleSelectionSupported) {
        return @(
            Invoke-ConsoleMultiSelect `
                -Items $relativeOptions `
                -Title 'SENTINEL HEADLESS — Selecao Sniper' `
                -Hint '↑↓ Navegar   ESPACO Marcar/Desmarcar   A Todos   N Nenhum   ENTER Confirmar   Q Cancelar'
        )
    }

    Write-Host ''
    Write-Host '  Selecao manual do modo Sniper:' -ForegroundColor Cyan
    Write-Host "    - Informe um ou mais caminhos relativos ou absolutos separados por ';'"
    Write-Host '    - Pode ser arquivo ou diretorio'
    Write-Host ''
    Write-Host '  Arquivos elegiveis detectados (previa):' -ForegroundColor Cyan

    foreach ($previewFile in ($relativeOptions | Select-Object -First 20)) {
        Write-Host ('    - {0}' -f $previewFile)
    }

    if ($relativeOptions.Count -gt 20) {
        Write-Host ('    ... e mais {0} arquivo(s).' -f ($relativeOptions.Count - 20)) -ForegroundColor DarkGray
    }

    $inputValue = (Read-Host '  Caminhos do Sniper').Trim()
    if ([string]::IsNullOrWhiteSpace($inputValue)) {
        throw 'No modo sniper, informe -SelectedPaths com pelo menos um arquivo ou diretorio.'
    }

    return @(
        $inputValue -split ';' |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
}

function Resolve-SelectedFilesForSniper {
    param(
        [string]$ProjectRootPath,
        [System.IO.FileInfo[]]$AllFiles,
        [string[]]$RequestedPaths
    )

    if ($null -eq $RequestedPaths -or $RequestedPaths.Count -eq 0) {
        throw "No modo sniper, informe -SelectedPaths com pelo menos um arquivo ou diretório."
    }

    $allowedMap = @{}
    foreach ($file in @($AllFiles)) {
        $allowedMap[[System.IO.Path]::GetFullPath($file.FullName)] = $file
    }

    $selectedMap = @{}

    foreach ($requestedPath in @($RequestedPaths)) {
        if ([string]::IsNullOrWhiteSpace($requestedPath)) { continue }

        $candidatePath = $requestedPath
        if (-not [System.IO.Path]::IsPathRooted($candidatePath)) {
            $candidatePath = Join-Path $ProjectRootPath $candidatePath
        }

        if (-not (Test-Path $candidatePath)) {
            throw "Caminho selecionado não encontrado: $requestedPath"
        }

        if (Test-Path $candidatePath -PathType Leaf) {
            $full = [System.IO.Path]::GetFullPath((Resolve-Path -Path $candidatePath).Path)
            if (-not $allowedMap.ContainsKey($full)) {
                throw "Arquivo fora do escopo de descoberta ou ignorado pelo bundler: $requestedPath"
            }

            $selectedMap[$full] = $allowedMap[$full]
            continue
        }

        if (Test-Path $candidatePath -PathType Container) {
            $discovered = @(Get-RelevantFiles -CurrentPath $candidatePath)
            foreach ($item in $discovered) {
                $full = [System.IO.Path]::GetFullPath($item.FullName)
                if ($allowedMap.ContainsKey($full)) {
                    $selectedMap[$full] = $allowedMap[$full]
                }
            }
            continue
        }

        throw "Caminho selecionado inválido: $requestedPath"
    }

    if ($selectedMap.Count -eq 0) {
        throw "No modo sniper, nenhum arquivo elegível foi selecionado."
    }

    return @($selectedMap.Values | Sort-Object FullName)
}

function Try-CopyToClipboard {
    param([AllowEmptyString()][string]$Content)

    if ($NoClipboard) { return $false }

    try {
        Set-Clipboard -Value $Content
        return $true
    }
    catch {
        return $false
    }
}

function New-HeadlessPromptConfigFile {
    param(
        [string]$RouteModeValue,
        [string]$ExtractionModeValue,
        [string]$ExecutorTargetValue,
        [string]$PromptModeValue,
        [string]$ExistingConfigPath,
        [string]$TemplateIdValue,
        [string]$TemplateObjectiveValue,
        [string]$TemplateDeliveryValue,
        [string[]]$TemplateFocusTagsValue,
        [string[]]$TemplateConstraintsValue,
        [string]$TemplateDepthValue,
        [string]$TemplateAdditionalInstructionsValue,
        [string]$ExpertSystemPromptValue
    )

    if (-not [string]::IsNullOrWhiteSpace($ExistingConfigPath)) {
        if (-not (Test-Path $ExistingConfigPath -PathType Leaf)) {
            throw "Arquivo de configuração de prompt não encontrado: $ExistingConfigPath"
        }

        return [pscustomobject]@{
            Path        = (Resolve-Path -Path $ExistingConfigPath).Path
            IsTemporary = $false
        }
    }

    $configPayload = $null

    switch ($PromptModeValue) {
        'template' {
            if ([string]::IsNullOrWhiteSpace($TemplateIdValue)) {
                throw "No modo template, informe -TemplateId ou use -PromptConfigFilePath."
            }

            $configPayload = @{
                promptMode             = 'template'
                routeMode              = $RouteModeValue
                extractionMode         = $ExtractionModeValue
                executorTarget         = $ExecutorTargetValue
                templateId             = $TemplateIdValue
                objective              = $TemplateObjectiveValue
                deliveryType           = $TemplateDeliveryValue
                focusTags              = @($TemplateFocusTagsValue | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
                constraints            = @($TemplateConstraintsValue | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
                depth                  = $TemplateDepthValue
                additionalInstructions = $TemplateAdditionalInstructionsValue
            }
        }
        'expert' {
            if ([string]::IsNullOrWhiteSpace($ExpertSystemPromptValue)) {
                throw "No modo expert, informe -ExpertSystemPrompt ou use -PromptConfigFilePath."
            }

            $configPayload = @{
                promptMode         = 'expertOverride'
                routeMode          = $RouteModeValue
                extractionMode     = $ExtractionModeValue
                executorTarget     = $ExecutorTargetValue
                expertSystemPrompt = $ExpertSystemPromptValue
            }
        }
        default {
            $configPayload = @{
                promptMode     = 'default'
                routeMode      = $RouteModeValue
                extractionMode = $ExtractionModeValue
                executorTarget = $ExecutorTargetValue
            }
        }
    }

    $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) ("vibetoolkit-config-" + [System.Guid]::NewGuid().ToString("N") + ".json")
    $configJson = $configPayload | ConvertTo-Json -Depth 5 -Compress
    Write-LocalTextArtifact -Path $tempPath -Content $configJson

    return [pscustomobject]@{
        Path        = $tempPath
        IsTemporary = $true
    }
}

function Invoke-OrchestratorAgent {
    param(
        [string]$AgentScriptPath,
        [string]$BundlePath,
        [string]$ProjectNameValue,
        [string]$ExecutorTargetValue,
        [string]$BundleModeValue,
        [string]$PrimaryProviderValue,
        [string]$OutputRouteModeValue,
        [string]$CustomPromptConfigPath = $null,
        [string]$DocumentModeValue = $null,
        [string]$PromptModeValue = $null,
        [AllowNull()][string]$TemplateIdValue = $null,
        [AllowNull()][string]$ExplicitOutputPath = $null,
        [AllowNull()][string]$ExplicitResultMetaPath = $null,
        [AllowNull()][string]$SkipReasonValue = $null,
        [AllowNull()][string]$LocalModelValue = $null
    )

    if (-not (Test-Path $AgentScriptPath -PathType Leaf)) { throw "Script groq-agent.ts não localizado." }

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

    $emitAgentLog = {
        param([string]$Message, [string]$Color)

        if ([string]::IsNullOrWhiteSpace($Message)) { return }

        $statusType = switch ($Color) {
            'Success' { 'Success' }
            'Warning' { 'Warning' }
            'Error' { 'Error' }
            default { 'Info' }
        }

        try {
            Write-SentinelStatus -Message $Message -Type $statusType
        }
        catch {
            Write-Host $Message
        }
    }.GetNewClosure()

    $handleAgentLine = {
        param([string]$Line, [string]$DefaultColor, [string]$StreamName = 'stdout')
        if ([string]::IsNullOrWhiteSpace($Line)) { return }

        $capturedAt = [DateTime]::UtcNow.ToString('o')
        $transcriptEntry = @{
            stream     = $StreamName
            capturedAt = $capturedAt
            line       = $Line
        }

        if ($StreamName -eq 'stderr') {
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

        & $emitAgentLog $Line $DefaultColor
    }.GetNewClosure()

    $bundleParent = Split-Path $BundlePath -Parent
    $routeToken = if ($OutputRouteModeValue -eq 'executor') { 'executor' } else { 'diretor' }
    $normalizedProjectName = [System.IO.Path]::GetFileNameWithoutExtension($BundlePath) -replace '^_+(?:Diretor|Executor)_(?:BUNDLER__|BLUEPRINT__|SELECTIVE__|COPIAR_TUDO__|INTELIGENTE__|MANUAL__)?', ''
    $resultMetaFileName = Get-AIResultOutputFileName -ProjectNameValue $normalizedProjectName -RouteMode $OutputRouteModeValue -ExtractionMode $BundleModeValue
    $resultMetaPath = if (-not [string]::IsNullOrWhiteSpace($ExplicitResultMetaPath)) {
        $ExplicitResultMetaPath
    }
    else {
        Join-Path $bundleParent $resultMetaFileName
    }

    $commandParts = @(
        'npx',
        '--quiet',
        'tsx',
        ('"{0}"' -f $AgentScriptPath),
        '--bundlePath',
        ('"{0}"' -f $BundlePath),
        '--projectName',
        ('"{0}"' -f $ProjectNameValue),
        '--executorTarget',
        ('"{0}"' -f $ExecutorTargetValue),
        '--extractionMode',
        ('"{0}"' -f $BundleModeValue),
        '--provider',
        ('"{0}"' -f $PrimaryProviderValue),
        '--routeMode',
        ('"{0}"' -f $OutputRouteModeValue),
        '--resultMetaPath',
        ('"{0}"' -f $resultMetaPath)
    )

    if (-not [string]::IsNullOrWhiteSpace($CustomPromptConfigPath)) {
        $commandParts += '--promptConfigFilePath'
        $commandParts += ('"{0}"' -f $CustomPromptConfigPath)
    }

    if (-not [string]::IsNullOrWhiteSpace($DocumentModeValue)) {
        $commandParts += '--documentMode'
        $commandParts += ('"{0}"' -f $DocumentModeValue)
    }

    if (-not [string]::IsNullOrWhiteSpace($PromptModeValue)) {
        $commandParts += '--promptMode'
        $commandParts += ('"{0}"' -f $PromptModeValue)
    }

    if (-not [string]::IsNullOrWhiteSpace($TemplateIdValue)) {
        $commandParts += '--templateId'
        $commandParts += ('"{0}"' -f $TemplateIdValue)
    }

    if (-not [string]::IsNullOrWhiteSpace($ExplicitOutputPath)) {
        $commandParts += '--outputPath'
        $commandParts += ('"{0}"' -f $ExplicitOutputPath)
    }

    if (-not [string]::IsNullOrWhiteSpace($SkipReasonValue)) {
        $commandParts += '--skipReason'
        $commandParts += ('"{0}"' -f $SkipReasonValue)
    }

    if (-not [string]::IsNullOrWhiteSpace($LocalModelValue)) {
        $commandParts += '--localModel'
        $commandParts += ('"{0}"' -f $LocalModelValue)
    }

    $entrypointDisplay = ('npx --quiet tsx {0}' -f [System.IO.Path]::GetFileName($AgentScriptPath))
    $commandLine = '/c ' + ($commandParts -join ' ')

    Write-UILog -Message 'Host de execução do agente: cmd.exe /c' -Color $ThemeCyan
    Write-UILog -Message ("Entrypoint do agente: {0}" -f $entrypointDisplay) -Color $ThemeCyan
    Write-UILog -Message ("Provider alvo: {0} | Bundle: {1}" -f $PrimaryProviderValue, [System.IO.Path]::GetFileName($BundlePath)) -Color $ThemeCyan

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $process.StartInfo.FileName = 'cmd.exe'
    $process.StartInfo.Arguments = $commandLine
    $process.StartInfo.WorkingDirectory = $script:ToolkitDir
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.EnvironmentVariables['DOTENV_CONFIG_SILENT'] = 'true'
    $process.StartInfo.EnvironmentVariables['npm_config_update_notifier'] = 'false'
    $process.StartInfo.EnvironmentVariables['NO_UPDATE_NOTIFIER'] = '1'

    if (-not $process.Start()) { throw 'Falha ao iniciar o processo do agente de IA.' }

    $processStartedAtUtc = [DateTime]::UtcNow
    $processId = $process.Id

    while (-not $process.HasExited) {
        while ($process.StandardOutput.Peek() -ge 0) { & $handleAgentLine $process.StandardOutput.ReadLine() $ThemeCyan 'stdout' }
        while ($process.StandardError.Peek() -ge 0) { & $handleAgentLine $process.StandardError.ReadLine() $ThemePink 'stderr' }
        Start-Sleep -Milliseconds 100
    }

    $process.WaitForExit()

    while ($process.StandardOutput.Peek() -ge 0) { & $handleAgentLine $process.StandardOutput.ReadLine() $ThemeCyan 'stdout' }
    while ($process.StandardError.Peek() -ge 0) { & $handleAgentLine $process.StandardError.ReadLine() $ThemePink 'stderr' }

    $processFinishedAtUtc = [DateTime]::UtcNow
    if ($processStartedAtUtc) {
        $processDurationMs = [int][Math]::Round(($processFinishedAtUtc - $processStartedAtUtc).TotalMilliseconds)
    }

    if ($process.ExitCode -ne 0) {
        throw "groq-agent.ts finalizou com código $($process.ExitCode)."
    }

    $script:LastAgentFailure = $null

    $resultMetaPathFromDisk = $null
    if (Test-Path $resultMetaPath -PathType Leaf) {
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

function Resolve-DocumentModeFromExtractionMode {
    param([string]$ExtractionMode)
    if ($ExtractionMode -eq 'sniper') { return 'manual' }
    return 'full'
}

function Resolve-BundleMode {
    param(
        [string]$BundleMode,
        [switch]$NonInteractive
    )

    if ($BundleMode -in @('full', 'blueprint', 'sniper', 'txtExport')) { return $BundleMode }

    if ($NonInteractive) {
        throw "Modo de extração obrigatório em execução não interativa. Use -BundleMode full, blueprint, sniper ou txtExport."
    }

    Write-Host ""
    Write-Host "  1. Modo de Extracao:" -ForegroundColor Cyan
    Write-Host "    [1] Full / Tudo  -  enviar tudo (analise completa)"
    Write-Host "    [2] Architect    -  blueprint / estrutura (economiza tokens)"
    Write-Host "    [3] Sniper       -  selecao manual (recorte com foco cirurgico)"
    Write-Host "    [4] TXT Export   -  pasta com arquivos separados"
    Write-Host ""

    $resolved = $null
    while ($null -eq $resolved) {
        $inp = (Read-Host "  Digite 1, 2, 3 ou 4").Trim()
        switch ($inp) {
            '1' { $resolved = 'full' }
            '2' { $resolved = 'blueprint' }
            '3' { $resolved = 'sniper' }
            '4' { $resolved = 'txtExport' }
            default { Write-Host "  Entrada invalida. Digite 1, 2, 3 ou 4." -ForegroundColor Yellow }
        }
    }

    Write-Host ""
    return $resolved
}

function Resolve-RouteMode {
    param(
        [string]$RouteMode,
        [switch]$NonInteractive
    )

    if ($RouteMode -eq 'director' -or $RouteMode -eq 'executor') { return $RouteMode }

    if ($NonInteractive) {
        throw "Rota obrigatória em execução não interativa. Use -RouteMode director ou executor."
    }

    Write-Host "  Fluxo de Saida:" -ForegroundColor Cyan
    Write-Host "    [1] Via Diretor          (mantem camada analitica)"
    Write-Host "    [2] Direto para Executor (contexto final sem intermediacao)"
    Write-Host ""

    $resolved = $null
    while ($null -eq $resolved) {
        $inp = (Read-Host "  Digite 1 ou 2").Trim()
        switch ($inp) {
            '1' { $resolved = 'director' }
            '2' { $resolved = 'executor' }
            default { Write-Host "  Entrada invalida. Digite 1 ou 2." -ForegroundColor Yellow }
        }
    }

    Write-Host ""
    return $resolved
}

function Resolve-IAOptions {
    param(
        [bool]$SendToAI,
        [bool]$DeterministicDirector,
        [switch]$NonInteractive
    )

    # Se qualquer flag de IA foi ativada explicitamente via CLI, respeitar sem perguntar
    if ($SendToAI -or $DeterministicDirector -or $NonInteractive) {
        return [pscustomobject]@{ SendToAI = $SendToAI; DeterministicDirector = $DeterministicDirector }
    }

    Write-Host "  Opcoes de IA:" -ForegroundColor Cyan
    Write-Host ""

    $aiInput = (Read-Host "  Gerar o prompt final com IA ao concluir? (s/N)").Trim().ToLower()
    $resolvedSendToAI = ($aiInput -eq 's' -or $aiInput -eq 'sim')

    $detInput = (Read-Host "  Gerar meta-prompt deterministico local (sem IA / sem provider remoto)? (s/N)").Trim().ToLower()
    $resolvedDeterministic = ($detInput -eq 's' -or $detInput -eq 'sim')

    Write-Host ""
    return [pscustomobject]@{ SendToAI = $resolvedSendToAI; DeterministicDirector = $resolvedDeterministic }
}

function Resolve-Provider {
    param(
        [string]$Provider,
        [bool]$SendToAI,
        [switch]$NonInteractive
    )

    # Sem IA ativa, provider nao e relevante — retornar groq como fallback silencioso
    if (-not $SendToAI) {
        if ([string]::IsNullOrWhiteSpace($Provider)) {
            return 'groq'
        }

        return $Provider
    }

    if ($Provider -in @('groq', 'gemini', 'openai', 'anthropic')) { return $Provider }

    if ($NonInteractive) {
        if ([string]::IsNullOrWhiteSpace($Provider)) {
            return 'groq'
        }

        throw "Provider inválido em execução não interativa: $Provider"
    }

    Write-Host "  2. IA Orquestradora:" -ForegroundColor Cyan
    Write-Host "    [1] Groq"
    Write-Host "    [2] Gemini"
    Write-Host "    [3] OpenAI"
    Write-Host "    [4] Anthropic"
    Write-Host ""

    $resolved = $null
    while ($null -eq $resolved) {
        $inp = (Read-Host "  Digite 1, 2, 3 ou 4").Trim()
        switch ($inp) {
            '1' { $resolved = 'groq' }
            '2' { $resolved = 'gemini' }
            '3' { $resolved = 'openai' }
            '4' { $resolved = 'anthropic' }
            default { Write-Host "  Entrada invalida. Digite 1, 2, 3 ou 4." -ForegroundColor Yellow }
        }
    }

    Write-Host ""
    return $resolved
}

function Resolve-AIPromptMode {
    param(
        [string]$AIPromptMode,
        [bool]$SendToAI,
        [switch]$NonInteractive
    )

    # Sem IA ativa, modo de customizacao nao e relevante
    if (-not $SendToAI) {
        if ([string]::IsNullOrWhiteSpace($AIPromptMode)) {
            return 'default'
        }

        return $AIPromptMode
    }

    if ($AIPromptMode -in @('default', 'template', 'expert')) { return $AIPromptMode }

    if ($NonInteractive) {
        if ([string]::IsNullOrWhiteSpace($AIPromptMode)) {
            return 'default'
        }

        throw "Modo de customização inválido em execução não interativa: $AIPromptMode"
    }

    Write-Host "  Modo de Customizacao:" -ForegroundColor Cyan
    Write-Host "    [1] Default"
    Write-Host "    [2] Template"
    Write-Host "    [3] Expert Override"
    Write-Host ""

    $resolved = $null
    while ($null -eq $resolved) {
        $inp = (Read-Host "  Digite 1, 2 ou 3").Trim()
        switch ($inp) {
            '1' { $resolved = 'default' }
            '2' { $resolved = 'template' }
            '3' { $resolved = 'expert' }
            default { Write-Host "  Entrada invalida. Digite 1, 2 ou 3." -ForegroundColor Yellow }
        }
    }

    Write-Host ""
    return $resolved
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
    return Get-VibeArtifactFileName -ProjectNameValue $ProjectNameValue -ExtractionMode $ExtractionMode -RouteMode $RouteMode -Extension ".json"
}

function New-LocalExecutionMeta {
    param(
        [string]$ProjectNameValue,
        [string]$RouteMode,
        [string]$ExtractionMode,
        [string]$DocumentMode,
        [string]$PromptMode = 'local',
        [AllowNull()][string]$TemplateId = $null,
        [string]$Provider = 'local',
        [string]$Model = 'local',
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
        generatedAt              = [DateTime]::UtcNow.ToString('o')
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
        [string]$PromptMode = 'local',
        [AllowNull()][string]$TemplateId = $null,
        [string]$Provider = 'local',
        [string]$Model = 'local',
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

    $metadataSourcePath = if (-not [string]::IsNullOrWhiteSpace($BundlePath)) {
        $BundlePath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        $OutputPath
    }
    else {
        $null
    }

    $agentScriptPath = if ($script:ToolkitDir) {
        Join-Path $script:ToolkitDir 'groq-agent.ts'
    }
    else {
        Join-Path (Get-Location).Path 'groq-agent.ts'
    }

    if ($Provider -eq 'local' -and -not [string]::IsNullOrWhiteSpace($metadataSourcePath) -and (Test-Path $metadataSourcePath -PathType Leaf) -and (Test-Path $agentScriptPath -PathType Leaf)) {
        try {
            $skipReasonValue = $null
            if ($ExtraData -and $ExtraData.ContainsKey('skippedReason') -and -not [string]::IsNullOrWhiteSpace([string]$ExtraData['skippedReason'])) {
                $skipReasonValue = [string]$ExtraData['skippedReason']
            }

            $agentResult = Invoke-OrchestratorAgent `
                -AgentScriptPath $agentScriptPath `
                -BundlePath $metadataSourcePath `
                -ProjectNameValue $ProjectNameValue `
                -ExecutorTargetValue 'Local Governance' `
                -BundleModeValue $ExtractionMode `
                -PrimaryProviderValue 'local' `
                -OutputRouteModeValue $RouteMode `
                -DocumentModeValue $DocumentMode `
                -PromptModeValue $PromptMode `
                -TemplateIdValue $TemplateId `
                -ExplicitOutputPath $(if ([string]::IsNullOrWhiteSpace($OutputPath)) { $metadataSourcePath } else { $OutputPath }) `
                -ExplicitResultMetaPath $resolvedResultMetaPath `
                -SkipReasonValue $skipReasonValue `
                -LocalModelValue $Model

            $resultMetaPathFromDisk = if ($agentResult -and $agentResult.ResultMetaPath -and (Test-Path $agentResult.ResultMetaPath -PathType Leaf)) {
                $agentResult.ResultMetaPath
            }
            elseif (Test-Path $resolvedResultMetaPath -PathType Leaf) {
                $resolvedResultMetaPath
            }
            else {
                $null
            }

            if ($resultMetaPathFromDisk) {
                $meta = (Read-LocalTextArtifact -Path $resultMetaPathFromDisk) | ConvertFrom-Json -AsHashtable
                if ($null -eq $meta) { $meta = @{} }

                if ($ExtraData) {
                    foreach ($key in $ExtraData.Keys) {
                        $meta[$key] = $ExtraData[$key]
                    }
                }

                $meta.resultMetaPath = $resultMetaPathFromDisk
                $metaJson = $meta | ConvertTo-Json -Depth 20
                Write-LocalTextArtifact -Path $resultMetaPathFromDisk -Content $metaJson -UseBom

                return [pscustomobject]@{
                    Meta           = [pscustomobject]$meta
                    ResultMetaPath = $resultMetaPathFromDisk
                }
            }
        }
        catch {
        }
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
        $lines.Add(('* **Projeto:** `{0}`' -f $ProjectNameValue))
        $lines.Add('* **Protocolo:** `ELITE v4.1 (Sniper Mode)`')
        $lines.Add(('* **Route Mode:** `{0}`' -f $normalizedRouteMode))
        $lines.Add(('* **Extração:** `{0}`' -f (Get-VibeExtractionModeLabel -ExtractionMode $ExtractionMode)))
        $lines.Add(('* **Document Mode:** `{0}`' -f $DocumentMode))
        $lines.Add(('* **Artefato Fonte:** `{0}`' -f $SourceArtifactFileName))
        $lines.Add(('* **Artefato Final:** `{0}`' -f $OutputArtifactFileName))
        $lines.Add(('* **Contexto Momentum:** `{0}`' -f $momentumState))
        $lines.Add(('* **Executor Alvo:** `{0}`' -f $ExecutorTargetValue))
        $lines.Add(('* **Gerado em:** `{0}`' -f $generatedAt))
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
        $lines.Add(('* **Objetivo:** Materializar ajustes no pipeline estruturado de `{0}` para gerar contexto executor determinístico local, sem provider remoto.' -f $ProjectNameValue))
        $lines.Add(('* **Arquivos-Alvo:** `{0}`' -f $relevantFilesValue))
        $lines.Add(('* **Injeção de Momentum:** Utilize o estado de `{0}` como memória de trabalho para evitar regressões sistêmicas.' -f $momentumMemoryLabel))
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

$script:AllowedExtensions = @(
    ".tsx", ".ts", ".js", ".jsx", ".css", ".html", ".json", ".prisma", ".sql", ".yaml", ".md",
    ".py", ".java", ".cs", ".c", ".cpp", ".h", ".hpp", ".go", ".rb", ".php", ".rs", ".swift",
    ".kt", ".scala", ".dart", ".r", ".sh", ".bat", ".ps1", ".csv", ".psm1", ".xaml", ".cs"
)
$script:SignatureExtensions = @(
    ".tsx", ".ts", ".js", ".jsx", ".css", ".html", ".json", ".prisma", ".sql", ".yaml", ".md",
    ".py", ".java", ".cs", ".c", ".cpp", ".h", ".hpp", ".go", ".rb", ".php", ".rs", ".swift",
    ".kt", ".scala", ".dart", ".r", ".sh", ".bat", ".ps1", ".csv", ".psm1", ".xaml", ".cs"
)
$script:IgnoredDirs = @(
    "node_modules", ".git", "dist", "build", ".next", ".cache", "out",
    "android", "ios", "coverage", ".venv", "venv", "env", "__pycache__",
    ".pytest_cache", ".tox", "bin", "obj", "target", "vendor"
)
$script:IgnoredFiles = @(
    "package-lock.json", "pnpm-lock.yaml", "yarn.lock",
    ".DS_Store", "metadata.json", ".gitignore",
    "google-services.json", "capacitor.config.json",
    "capacitor.plugins.json", "cordova.js", "cordova_plugins.js",
    "poetry.lock", "Pipfile.lock", "Cargo.lock", "go.sum", "composer.lock"
)

$resolvedTargetPath = $null
try {
    $resolvedTargetPath = [System.IO.Path]::GetFullPath((Resolve-Path -Path $Path -ErrorAction Stop).Path)
}
catch {
    throw "Path alvo inválido: $Path"
}

$SentinelUiPath = Join-Path $script:ToolkitDir 'lib\SentinelUI.ps1'
if (-not (Test-Path $SentinelUiPath -PathType Leaf)) {
    throw "Biblioteca de UI não encontrada: $SentinelUiPath"
}

$sentinelUiFallbackActive = $false
try {
    . $SentinelUiPath
}
catch {
    $sentinelBootstrapFailure = $_

    if (Test-IsSentinelUiPolicyBlockedError -ErrorRecord $sentinelBootstrapFailure) {
        Register-SentinelCliFallback
        $sentinelUiFallbackActive = $true

        $sentinelFailureSummary = Get-SentinelUiBootstrapFailureSummary -ErrorRecord $sentinelBootstrapFailure
        Write-Host "[!] SentinelUI bloqueado por assinatura/execution policy. Ativando fallback textual para o modo headless."
        Write-Host ("    {0}" -f $sentinelFailureSummary)
    }
    else {
        $sentinelFailureSummary = Get-SentinelUiBootstrapFailureSummary -ErrorRecord $sentinelBootstrapFailure
        throw "Falha estrutural ao carregar biblioteca de UI '$SentinelUiPath'. $sentinelFailureSummary"
    }
}

Assert-SentinelUiBootstrapContract -SentinelUiPath $SentinelUiPath -FallbackActive:$sentinelUiFallbackActive

Write-SentinelHeader -Title 'SENTINEL HEADLESS' -Version 'v1.0.0'
if ($sentinelUiFallbackActive) {
    Write-UILog -Message 'Bootstrap headless carregado com fallback textual de console.' -Color $ThemeWarn
}
else {
    Write-UILog -Message 'Bootstrap headless carregado.' -Color $ThemeSuccess
}

$modulesDir = Join-Path $script:ToolkitDir 'modules'
$requiredModulePaths = @(
    (Join-Path $modulesDir 'VibeDirectorProtocol.psm1'),
    (Join-Path $modulesDir 'VibeBundleWriter.psm1'),
    (Join-Path $modulesDir 'VibeSignatureExtractor.psm1'),
    (Join-Path $modulesDir 'VibeFileDiscovery.psm1')
)
foreach ($modulePath in $requiredModulePaths) {
    if (-not (Test-Path $modulePath -PathType Leaf)) {
        throw "Módulo obrigatório não encontrado: $modulePath"
    }
}
foreach ($modulePath in $requiredModulePaths) {
    $moduleContent = [System.IO.File]::ReadAllText($modulePath, [System.Text.Encoding]::UTF8)
    $scriptBlock = [scriptblock]::Create($moduleContent)
    $dynamicModuleName = [System.IO.Path]::GetFileNameWithoutExtension($modulePath)
    $dynamicModule = New-Module -Name $dynamicModuleName -ScriptBlock $scriptBlock
    Import-Module -ModuleInfo $dynamicModule -Force -DisableNameChecking -ErrorAction Stop
}

if (-not (Get-Command -Name Get-VibeExtractionModeLabel -ErrorAction SilentlyContinue)) {
    function Get-VibeExtractionModeLabel {
        param([string]$ExtractionMode)

        $normalizedExtractionMode = if ($null -eq $ExtractionMode) { '' } else { [string]$ExtractionMode }
        switch ($normalizedExtractionMode.ToLowerInvariant()) {
            'full' { return 'full / tudo' }
            'architect' { return 'architect / blueprint' }
            'sniper' { return 'sniper / recorte cirúrgico' }
            'txt' { return 'txt export' }
            default {
                if ([string]::IsNullOrWhiteSpace($ExtractionMode)) {
                    return 'não informado'
                }

                return $ExtractionMode
            }
        }
    }
}

if (-not (Get-Command -Name Get-DirectorHighFidelityMetadataSection -ErrorAction SilentlyContinue)) {
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

        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add('## METADADOS DE OPERAÇÃO')
        $lines.Add(('- Projeto: {0}' -f $ProjectNameValue))
        $lines.Add('- Protocolo: ELITE v4.1 (Director Mode)')
        $lines.Add(('- Extração: {0}' -f (Get-VibeExtractionModeLabel -ExtractionMode $ExtractionMode)))
        $lines.Add(('- Document Mode: {0}' -f $DocumentMode))
        $lines.Add(('- Artefato fonte: {0}' -f $SourceArtifactFileName))
        $lines.Add(('- Artefato final: {0}' -f $OutputArtifactFileName))
        $lines.Add(('- Executor alvo: {0}' -f $ExecutorTargetValue))
        $lines.Add(('- Gerado em: {0}' -f $GeneratedAt))

        return ($lines -join "`n")
    }
}

if (-not (Get-Command -Name Get-DirectorHighFidelitySystemGovernanceSection -ErrorAction SilentlyContinue)) {
    function Get-DirectorHighFidelitySystemGovernanceSection {
        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add('## GOVERNANÇA DO SISTEMA')
        $lines.Add('1. O bundle visível é a única fonte de verdade operacional.')
        $lines.Add('2. Aplique a Lei da Subtração antes de adicionar novos blocos.')
        $lines.Add('3. Preserve contratos, assinaturas, nomes públicos e fluxo já existente.')
        $lines.Add('4. Não faça alquimia arquitetural: declare lacunas em vez de inventar comportamento.')
        $lines.Add('5. Trate todo código como passivo até validação humana e teste real.')
        $lines.Add('6. Nunca exponha segredos, tokens, caminhos locais sensíveis ou conteúdo bruto desnecessário.')

        return ($lines -join "`n")
    }
}

if (-not (Get-Command -Name Get-DirectorHighFidelityMetaPromptEngineeringLayersSection -ErrorAction SilentlyContinue)) {
    function Get-DirectorHighFidelityMetaPromptEngineeringLayersSection {
        param([string[]]$TargetFiles)

        $targetFilesValue = if ($TargetFiles -and $TargetFiles.Count -gt 0) {
            ($TargetFiles | ForEach-Object { '`{0}`' -f $_ }) -join ', '
        }
        else {
            'não identificados objetivamente'
        }

        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add('## CAMADAS DE ENGENHARIA DO META-PROMPT')
        $lines.Add('1. Recon: mapear arquivos impactados, contratos e riscos de regressão.')
        $lines.Add('2. Subtração: preferir reutilização e remoção de redundância ao acréscimo arbitrário.')
        $lines.Add('3. Materialização: propor alterações atômicas, compatíveis com a stack existente.')
        $lines.Add('4. Validação: definir testes objetivos, negativos e de borda antes de considerar concluído.')
        $lines.Add('5. Segurança: revisar exposição de segredos, entrada não validada e quebra de isolamento.')
        $lines.Add(('- Arquivos prioritários desta rodada: {0}' -f $targetFilesValue))

        return ($lines -join "`n")
    }
}

if (-not (Get-Command -Name Get-DirectorHighFidelityResponseTemplateSection -ErrorAction SilentlyContinue)) {
    function Get-DirectorHighFidelityResponseTemplateSection {
        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add('## TEMPLATE DE RESPOSTA OBRIGATÓRIO')
        $lines.Add('1. ANÁLISE DE EXECUÇÃO')
        $lines.Add('2. RELATÓRIO DE IMPACTO')
        $lines.Add('3. IMPLEMENTAÇÃO (CÓDIGO)')
        $lines.Add('4. PROTOCOLO DE VALIDAÇÃO')
        $lines.Add('5. VERIFICAÇÃO DE SEGURANÇA')

        return ($lines -join "`n")
    }
}

if (-not (Get-Command -Name Get-DirectorHighFidelityContextMomentumSection -ErrorAction SilentlyContinue)) {
    function Get-DirectorHighFidelityContextMomentumSection {
        param(
            [string]$MomentumState,
            [string]$MomentumSource
        )

        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add('## CONTEXTO MOMENTUM')
        $lines.Add(('- Estado: {0}' -f $MomentumState))
        $lines.Add(('- Fonte: {0}' -f $MomentumSource))
        $lines.Add('Use o contexto momentum apenas para reduzir regressões e contradições com artefatos anteriores.')
        $lines.Add('Se o estado estiver vazio, não invente memória histórica; sinalize explicitamente a ausência de contexto.')

        return ($lines -join "`n")
    }
}

Set-Location $resolvedTargetPath

$projectName = (Get-Item .).Name

# ── Wizard interativo ────────────────────────────────────────────────────────
# Cada resolver pergunta apenas se o parametro nao veio explicitamente via CLI.
Write-Host ""
Write-Host "  ═══════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host "   SENTINEL HEADLESS — Configuracao" -ForegroundColor Cyan
Write-Host "  ═══════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""

$ResolvedBundleMode = Resolve-BundleMode     -BundleMode $BundleMode -NonInteractive:$NonInteractive
$ResolvedRouteMode = Resolve-RouteMode      -RouteMode  $RouteMode -NonInteractive:$NonInteractive
$iaOptions = Resolve-IAOptions      -SendToAI $SendToAI.IsPresent -DeterministicDirector $DeterministicDirector.IsPresent -NonInteractive:$NonInteractive
$ResolvedSendToAI = $iaOptions.SendToAI
$ResolvedDeterministicDirector = $iaOptions.DeterministicDirector
$ResolvedProvider = Resolve-Provider       -Provider $Provider     -SendToAI $ResolvedSendToAI -NonInteractive:$NonInteractive
$ResolvedAIPromptMode = Resolve-AIPromptMode   -AIPromptMode $AIPromptMode -SendToAI $ResolvedSendToAI -NonInteractive:$NonInteractive
# ────────────────────────────────────────────────────────────────────────────

$choice = Resolve-ChoiceFromBundleMode      -ModeValue $ResolvedBundleMode
$currentExtractionMode = Resolve-ExtractionModeFromBundleMode -ModeValue $ResolvedBundleMode
$currentDocumentMode = Resolve-DocumentModeFromExtractionMode -ExtractionMode $currentExtractionMode
$isTxtExportMode = ($choice -eq '4')
$promptConfigTemp = $null

Write-UILog -Message ("Projeto: {0}" -f $projectName)
Write-UILog -Message ("Modo headless: {0}" -f $ResolvedBundleMode)
Write-UILog -Message ("Rota: {0}" -f $(if ($ResolvedRouteMode -eq 'executor') { 'Direto para Executor' } else { 'Via Diretor' }))
Write-UILog -Message ("Executor alvo: {0}" -f $ExecutorTarget)

$foundFiles = @(Get-RelevantFiles -CurrentPath (Get-Location).Path | Sort-Object FullName)
if ($foundFiles.Count -eq 0) {
    throw "Nenhum arquivo elegível foi encontrado em: $resolvedTargetPath"
}

$filesToProcess = @()
$unselectedFiles = @()

if ($choice -eq '3') {
    $resolvedSelectedPaths = @(Resolve-SniperRequestedPaths -ProjectRootPath (Get-Location).Path -AllFiles $foundFiles -RequestedPaths $SelectedPaths -NonInteractive:$NonInteractive)
    $filesToProcess = @(Resolve-SelectedFilesForSniper -ProjectRootPath (Get-Location).Path -AllFiles $foundFiles -RequestedPaths $resolvedSelectedPaths)
    $selectedMap = @{}
    foreach ($file in $filesToProcess) {
        $selectedMap[[System.IO.Path]::GetFullPath($file.FullName)] = $true
    }
    foreach ($file in $foundFiles) {
        $full = [System.IO.Path]::GetFullPath($file.FullName)
        if (-not $selectedMap.ContainsKey($full)) {
            $unselectedFiles += $file
        }
    }
}
else {
    $filesToProcess = @($foundFiles)
}

Write-UILog -Message ("Arquivos na operação: {0}" -f $filesToProcess.Count)

if ($choice -eq '3') {
    Write-UILog -Message ("Sniper: {0} arquivo(s) selecionado(s)." -f $filesToProcess.Count) -Color $ThemeCyan
    if ($unselectedFiles.Count -gt 0) {
        Write-UILog -Message ("Sniper: {0} arquivo(s) não selecionado(s) serão anexados em modo Bundler." -f $unselectedFiles.Count) -Color $ThemeCyan
    }
}

try {
    if ($isTxtExportMode) {
        if ($ResolvedSendToAI) {
            Write-UILog -Message 'Modo TXT Export ignora chamada de IA por desenho.' -Color $ThemeWarn
        }

        $txtExportResult = Export-OperationFilesToTxtDirectory `
            -Files $filesToProcess `
            -ProjectRootPath (Get-Location).Path `
            -BaseOutputDirectory (Get-Location).Path `
            -ProjectNameValue $projectName

        Write-UILog -Message ("Pasta de saída: {0}" -f $txtExportResult.OutputDirectory) -Color $ThemeSuccess
        Write-UILog -Message ("Arquivo ZIP: {0}" -f $txtExportResult.ZipFilePath) -Color $ThemeSuccess
        Write-UILog -Message ("Arquivos exportados: {0}" -f $txtExportResult.ExportedFiles.Count) -Color $ThemeSuccess

        if ($txtExportResult.SkippedFiles.Count -gt 0) {
            Write-UILog -Message ("Arquivos ignorados por incompatibilidade/erro: {0}" -f $txtExportResult.SkippedFiles.Count) -Color $ThemeWarn
        }

        $txtExportMetaResult = Write-LocalExecutionMeta `
            -ProjectNameValue $projectName `
            -RouteMode $ResolvedRouteMode `
            -ExtractionMode $currentExtractionMode `
            -DocumentMode 'txt_export' `
            -PromptMode 'local' `
            -Provider 'local' `
            -Model 'txt-export' `
            -OutputPath $txtExportResult.ZipFilePath `
            -ExtraData @{
            outputDirectory   = $txtExportResult.OutputDirectory
            zipFilePath       = $txtExportResult.ZipFilePath
            exportedFiles     = @($txtExportResult.ExportedFiles)
            skippedFiles      = @($txtExportResult.SkippedFiles)
            exportedFileCount = $txtExportResult.ExportedFiles.Count
            skippedFileCount  = $txtExportResult.SkippedFiles.Count
        }

        Write-UILog -Message ("Metadados locais salvos em: {0}" -f $txtExportMetaResult.ResultMetaPath) -Color $ThemeSuccess
        return
    }

    $headerContent = Get-VibeProtocolHeaderContent `
        -RouteMode $ResolvedRouteMode `
        -ExtractionMode $currentExtractionMode `
        -ExecutorTargetValue $ExecutorTarget

    $finalContent = $headerContent + "`n`n"
    $momentumContext = $null
    $shouldLoadMomentumContext = ($ResolvedRouteMode -eq 'director') -or $ResolvedDeterministicDirector

    if ($shouldLoadMomentumContext) {
        $momentumContext = Resolve-LatestMomentumContext -SearchRoot (Get-Location).Path

        foreach ($momentumWarning in @($momentumContext.Warnings)) {
            Write-UILog -Message $momentumWarning -Color $ThemeWarn
        }

        if ($momentumContext.Status -eq 'found') {
            Write-UILog -Message ("Contexto Momentum carregado: {0}" -f [System.IO.Path]::GetFileName($momentumContext.FilePath)) -Color $ThemeCyan
        }
        else {
            Write-UILog -Message $momentumContext.Message -Color $ThemeWarn
        }
    }

    if ($ResolvedRouteMode -eq 'director') {
        $finalContent += (Get-MomentumSectionContent -MomentumContext $momentumContext) + "`n`n"
    }

    $blueprintIssues = @()

    if ($choice -eq '1' -or $choice -eq '3') {
        if ($choice -eq '1') {
            $outputFile = Get-VibeArtifactFileName -ProjectNameValue $projectName -ExtractionMode $choice -RouteMode $ResolvedRouteMode
            $headerTitle = 'MODO COPIAR TUDO'
            Write-UILog -Message 'Iniciando Modo Copiar Tudo...' -Color $ThemeCyan
        }
        else {
            $outputFile = Get-VibeArtifactFileName -ProjectNameValue $projectName -ExtractionMode $choice -RouteMode $ResolvedRouteMode
            $headerTitle = 'MODO MANUAL'
            Write-UILog -Message 'Iniciando Modo Sniper / Manual...' -Color $ThemePink
        }

        $finalContent += "## ${headerTitle}: $projectName`n`n"

        if ($choice -eq '3') {
            $finalContent += "### 0. ANALYSIS SCOPE`n" + '```text' + "`n"
            $finalContent += "ESCOPO: FECHADO / PARCIAL`n"
            $finalContent += "Este bundle contém os arquivos selecionados manualmente pelo usuário.`n"
            if ($unselectedFiles.Count -gt 0) {
                $finalContent += "Os arquivos não selecionados foram anexados ao final em modo Bundler como contexto complementar.`n"
            }
            $finalContent += "Qualquer análise deve considerar exclusivamente o visível neste artefato.`n"
            $finalContent += "É proibido inferir módulos, dependências ou comportamento não visíveis.`n"
            $finalContent += "Quando faltar contexto, declarar: 'não visível no recorte enviado'.`n"
            $finalContent += '```' + "`n`n"
        }

        Write-UILog -Message 'Montando estrutura do projeto...'
        $finalContent += "### 1. PROJECT STRUCTURE`n" + '```text' + "`n"
        foreach ($file in $filesToProcess) {
            $finalContent += (Resolve-Path -Path $file.FullName -Relative) + "`n"
        }
        $finalContent += '```' + "`n`n"

        Write-UILog -Message 'Lendo arquivos e consolidando conteúdo...'
        $finalContent += "### 2. SOURCE FILES`n`n"

        foreach ($file in $filesToProcess) {
            $relPath = Resolve-Path -Path $file.FullName -Relative
            Write-UILog -Message ("Lendo {0}" -f $relPath)
            $content = Read-LocalTextArtifact -Path $file.FullName
            if ($null -ne $content) {
                $content = $content -replace "(`r?`n){3,}", "`r`n`r`n"
                $finalContent += "#### File: $relPath`n"
                $finalContent += (Convert-ToSafeMarkdownCodeBlock -Content $content.TrimEnd() -Language 'text') + "`n`n"
            }
        }

        if ($choice -eq '3' -and $unselectedFiles.Count -gt 0) {
            Write-UILog -Message 'Anexando arquivos não selecionados (modo Bundler)...' -Color $ThemeCyan
            $finalContent += "## ARQUIVOS NÃO SELECIONADOS INSERIDOS EM MODO BUNDLER`n`n"
            $finalContent += New-BundlerContractsBlock `
                -Files $unselectedFiles `
                -IssueCollector ([ref]$blueprintIssues) `
                -StructureHeading "### PROJECT STRUCTURE (BUNDLER)" `
                -ContractsHeading "### CORE DOMAINS & CONTRACTS (BUNDLER)" `
                -LogExtraction
        }
    }
    else {
        $outputFile = Get-VibeArtifactFileName -ProjectNameValue $projectName -ExtractionMode $choice -RouteMode $ResolvedRouteMode
        Write-UILog -Message 'Iniciando Modo Architect / Inteligente...' -Color $ThemeCyan
        $finalContent += "## MODO INTELIGENTE: $projectName`n`n"
        $finalContent += "### 1. TECH STACK`n"

        $packageJsonPath = Join-Path (Get-Location).Path 'package.json'
        if (Test-Path $packageJsonPath -PathType Leaf) {
            Write-UILog -Message 'Lendo package.json para tech stack...'
            $pkg = (Read-LocalTextArtifact -Path $packageJsonPath) | ConvertFrom-Json
            if ($pkg.dependencies) { $finalContent += "* **Deps:** $(($pkg.dependencies.PSObject.Properties.Name -join ', '))`n" }
            if ($pkg.devDependencies) { $finalContent += "* **Dev Deps:** $(($pkg.devDependencies.PSObject.Properties.Name -join ', '))`n" }
        }
        else {
            Write-UILog -Message ("package.json não encontrado em {0}; tech stack será omitida." -f $packageJsonPath) -Color $ThemeWarn
        }

        $finalContent += "`n"
        $finalContent += New-BundlerContractsBlock `
            -Files $filesToProcess `
            -IssueCollector ([ref]$blueprintIssues) `
            -StructureHeading "### 2. PROJECT STRUCTURE" `
            -ContractsHeading "### 3. CORE DOMAINS & CONTRACTS" `
            -LogExtraction
    }

    $outputFullPath = Join-Path (Get-Location).Path $outputFile

    if ($ResolvedDeterministicDirector) {
        $deterministicOutputFile = Get-DeterministicMetaPromptOutputFileName -ProjectNameValue $projectName -ChoiceValue $choice -RouteMode $ResolvedRouteMode
        $deterministicOutputFullPath = Join-Path (Get-Location).Path $deterministicOutputFile

        Write-UILog -Message 'Fluxo determinístico local ignorará o pre-flight diff gate.' -Color $ThemeCyan
        Write-UILog -Message ("Compilando meta-prompt determinístico local diretamente no bundler ({0})..." -f $(if ($ResolvedRouteMode -eq 'executor') { 'executor' } else { 'director' })) -Color $ThemeCyan

        $deterministicContent = New-DeterministicMetaPromptArtifact `
            -ProjectNameValue $projectName `
            -ExecutorTargetValue $ExecutorTarget `
            -RouteMode $ResolvedRouteMode `
            -ExtractionMode $currentExtractionMode `
            -DocumentMode $currentDocumentMode `
            -SourceArtifactFileName $outputFile `
            -OutputArtifactFileName $deterministicOutputFile `
            -BundleContent $finalContent `
            -Files $filesToProcess `
            -MomentumContext $momentumContext

        Write-LocalTextArtifact -Path $deterministicOutputFullPath -Content $deterministicContent -UseBom
        $deterministicTokenEstimate = [math]::Round($deterministicContent.Length / 4)
        $copiedDeterministic = Try-CopyToClipboard -Content $deterministicContent

        if ($blueprintIssues -and $blueprintIssues.Count -gt 0) {
            Write-UILog -Message ("Artefato gerado com {0} aviso(s)." -f $blueprintIssues.Count) -Color $ThemePink
            foreach ($issue in ($blueprintIssues | Select-Object -First 10)) {
                Write-UILog -Message $issue -Color $ThemePink
            }
        }
        else {
            Write-UILog -Message 'Meta-prompt determinístico consolidado com sucesso.' -Color $ThemeSuccess
        }

        Write-UILog -Message ("Arquivo: {0}" -f $deterministicOutputFile)
        Write-UILog -Message ("Tokens estimados: ~{0}" -f $deterministicTokenEstimate)
        Write-UILog -Message ("Meta-prompt determinístico salvo em: {0}" -f $deterministicOutputFullPath) -Color $ThemeSuccess

        if ($copiedDeterministic) {
            Write-UILog -Message 'Meta-prompt final copiado para a área de clipboard.' -Color $ThemeCyan
        }
        else {
            Write-UILog -Message 'Meta-prompt final gerado, mas clipboard indisponível.' -Color $ThemeWarn
        }

        $deterministicMetaResult = Write-LocalExecutionMeta `
            -ProjectNameValue $projectName `
            -RouteMode $ResolvedRouteMode `
            -ExtractionMode $currentExtractionMode `
            -DocumentMode $currentDocumentMode `
            -PromptMode 'deterministic_local' `
            -TemplateId $(if ($ResolvedRouteMode -eq 'executor') { 'executor_meta_v1' } else { 'director_meta_v1' }) `
            -Provider 'local' `
            -Model $(if ($ResolvedRouteMode -eq 'executor') { 'deterministic-executor_meta_v1' } else { 'deterministic-director_meta_v1' }) `
            -BundlePath $outputFullPath `
            -OutputPath $deterministicOutputFullPath `
            -ExtraData @{
            sourceArtifactFile = $outputFile
            outputArtifactFile = $deterministicOutputFile
        }

        Write-UILog -Message ("Metadados locais salvos em: {0}" -f $deterministicMetaResult.ResultMetaPath) -Color $ThemeSuccess
        Write-UILog -Message 'Execução concluída sem provider remoto; metadados de governança consolidados via groq-agent.ts local.' -Color $ThemeSuccess
        return
    }

    $shouldCallAI = $false
    $shouldPersistOfficialBundle = $true

    if ($ResolvedSendToAI) {
        $preflight = Resolve-BundlePreflightGate -OfficialBundlePath $outputFullPath -NewBundleContent $finalContent

        if (-not $preflight.OfficialExists) {
            Write-UILog -Message 'Bundle oficial inexistente. Persistindo nova versão e liberando IA.' -Color $ThemeCyan
            $shouldCallAI = $true
            $shouldPersistOfficialBundle = $true
        }
        elseif (-not $preflight.IsIdentical) {
            Write-UILog -Message 'Diferença detectada no bundle. Atualizando arquivo oficial e liberando IA.' -Color $ThemeCyan
            $shouldCallAI = $true
            $shouldPersistOfficialBundle = $true
        }
        else {
            Write-UILog -Message 'Conteúdo idêntico detectado entre o bundle oficial e o bundle recém-gerado.' -Color $ThemeWarn
            $shouldPersistOfficialBundle = $false

            if ($ForceAIAgainstIdenticalBundle) {
                Write-UILog -Message 'Flag -ForceAIAgainstIdenticalBundle ativa. IA liberada apesar do conteúdo idêntico.' -Color $ThemeCyan
                $shouldCallAI = $true
            }
            else {
                Write-UILog -Message 'IA bloqueada pelo pre-flight diff gate por conteúdo idêntico.' -Color $ThemeSuccess
                $shouldCallAI = $false
            }
        }
    }

    if ($shouldPersistOfficialBundle) {
        Write-LocalTextArtifact -Path $outputFullPath -Content $finalContent -UseBom
        Write-UILog -Message ("Bundle oficial salvo em: {0}" -f $outputFullPath) -Color $ThemeSuccess
    }
    else {
        Write-UILog -Message 'Bundle oficial preservado sem regravação por não haver diferença de conteúdo.' -Color $ThemeSuccess
    }

    $tokenEstimate = [math]::Round($finalContent.Length / 4)
    $copied = Try-CopyToClipboard -Content $finalContent

    if ($blueprintIssues -and $blueprintIssues.Count -gt 0) {
        Write-UILog -Message ("Artefato gerado com {0} aviso(s)." -f $blueprintIssues.Count) -Color $ThemePink
        foreach ($issue in ($blueprintIssues | Select-Object -First 10)) {
            Write-UILog -Message $issue -Color $ThemePink
        }
    }
    else {
        Write-UILog -Message 'Artefato consolidado com sucesso.' -Color $ThemeSuccess
    }

    Write-UILog -Message ("Arquivo: {0}" -f $outputFile)
    Write-UILog -Message ("Tokens estimados: ~{0}" -f $tokenEstimate)

    if ($copied) {
        Write-UILog -Message 'Bundle copiado para a área de clipboard.' -Color $ThemeCyan
    }
    else {
        Write-UILog -Message 'Arquivo salvo. Clipboard indisponível.' -Color $ThemeWarn
    }

    if ($ResolvedSendToAI -and $shouldCallAI) {
        $promptConfig = New-HeadlessPromptConfigFile `
            -RouteModeValue $ResolvedRouteMode `
            -ExtractionModeValue $currentExtractionMode `
            -ExecutorTargetValue $ExecutorTarget `
            -PromptModeValue $ResolvedAIPromptMode `
            -ExistingConfigPath $PromptConfigFilePath `
            -TemplateIdValue $TemplateId `
            -TemplateObjectiveValue $TemplateObjective `
            -TemplateDeliveryValue $TemplateDelivery `
            -TemplateFocusTagsValue $TemplateFocusTags `
            -TemplateConstraintsValue $TemplateConstraints `
            -TemplateDepthValue $TemplateDepth `
            -TemplateAdditionalInstructionsValue $TemplateAdditionalInstructions `
            -ExpertSystemPromptValue $ExpertSystemPrompt

        $promptConfigTemp = $promptConfig

        $agentScript = Join-Path $script:ToolkitDir 'groq-agent.ts'
        Write-UILog -Message 'Chamando agente de IA...' -Color $ThemeCyan
        Write-UILog -Message ("Provider primário: {0} | fallback automático ativo." -f $ResolvedProvider) -Color $ThemeCyan

        $agentResult = Invoke-OrchestratorAgent `
            -AgentScriptPath $agentScript `
            -BundlePath $outputFullPath `
            -ProjectNameValue $projectName `
            -ExecutorTargetValue $ExecutorTarget `
            -BundleModeValue $currentExtractionMode `
            -PrimaryProviderValue $ResolvedProvider `
            -OutputRouteModeValue $ResolvedRouteMode `
            -CustomPromptConfigPath $promptConfig.Path

        $finalPromptPath = $null
        if ($agentResult -and $agentResult.OutputPath -and (Test-Path $agentResult.OutputPath -PathType Leaf)) {
            $finalPromptPath = $agentResult.OutputPath
        }
        else {
            $bundleParent = Split-Path $outputFullPath -Parent
            $candidateContextPaths = @(
                (Join-Path $bundleParent (Get-AIContextOutputFileName -ProjectNameValue $projectName -RouteMode $ResolvedRouteMode -ExtractionMode $currentExtractionMode)),
                (Join-Path $bundleParent "_AI_CONTEXT_${projectName}.md")
            )

            foreach ($cp in $candidateContextPaths) {
                if (Test-Path $cp -PathType Leaf) {
                    $finalPromptPath = $cp
                    break
                }
            }
        }

        if ($finalPromptPath) {
            $finalSummarizedContent = Read-LocalTextArtifact -Path $finalPromptPath
            if (Try-CopyToClipboard -Content $finalSummarizedContent) {
                Write-UILog -Message 'Prompt final preparado e copiado para o clipboard.' -Color $ThemeSuccess
            }
            else {
                Write-UILog -Message 'Prompt final gerado, mas clipboard indisponível.' -Color $ThemeWarn
            }

            Write-UILog -Message ("Arquivo final da IA: {0}" -f $finalPromptPath) -Color $ThemeSuccess
        }
        else {
            Write-UILog -Message 'Arquivo final da IA não foi localizado.' -Color $ThemePink
        }

        if ($agentResult -and $agentResult.WinnerProvider) {
            Write-UILog -Message ("Provider efetivo: {0} | Modelo: {1}" -f $agentResult.WinnerProvider, $agentResult.WinnerModel) -Color $ThemeSuccess
        }

        Write-UILog -Message $(if ($ResolvedRouteMode -eq 'executor') { 'Agora é só colar no seu executor.' } else { 'Agora é só colar no seu orquestrador.' }) -Color $ThemeCyan
    }
    else {
        $localMetaResult = Write-LocalExecutionMeta `
            -ProjectNameValue $projectName `
            -RouteMode $ResolvedRouteMode `
            -ExtractionMode $currentExtractionMode `
            -DocumentMode $currentDocumentMode `
            -PromptMode $(if ($ResolvedSendToAI) { 'local_no_provider' } else { 'local' }) `
            -Provider 'local' `
            -Model 'bundler-local' `
            -BundlePath $outputFullPath `
            -OutputPath $outputFullPath `
            -ExtraData @{
            promptGenerationSkipped = $true
            skippedReason           = $(if ($ResolvedSendToAI) { 'identical_bundle_user_cancelled_ai' } else { 'provider_not_requested' })
        }

        Write-UILog -Message ("Metadados locais salvos em: {0}" -f $localMetaResult.ResultMetaPath) -Color $ThemeSuccess
        Write-UILog -Message 'Execução concluída sem chamada da IA; governança consolidada via groq-agent.ts local.' -Color $ThemeSuccess
    }
}
catch {
    $errorMessage = $_.Exception.Message
    $agentFailure = $script:LastAgentFailure

    if ($agentFailure -and $agentFailure.Type) {
        Write-UILog -Message ("Status final do agente: {0} | Tipo: {1}" -f $agentFailure.Status, $agentFailure.Type) -Color $ThemePink
        if ($agentFailure.Details) {
            Write-UILog -Message ("Detalhes técnicos: {0}" -f $agentFailure.Details) -Color $ThemePink
        }
    }

    Write-UILog -Message ("Falha na execução: {0}" -f $errorMessage) -Color $ThemePink
    throw
}
finally {
    if ($promptConfigTemp -and $promptConfigTemp.IsTemporary -and $promptConfigTemp.Path -and (Test-Path $promptConfigTemp.Path -PathType Leaf)) {
        try {
            Remove-Item -Path $promptConfigTemp.Path -Force -ErrorAction Stop
        }
        catch {
        }
    }
}