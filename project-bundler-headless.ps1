[CmdletBinding()]
param(
    [string]$Path = ".",
    [ValidateSet('full', 'blueprint', 'sniper', 'txtExport')]
    [Alias('Mode')]
    [string]$BundleMode = 'full',
    [string[]]$SelectedPaths,
    [ValidateSet('director', 'executor')]
    [string]$RouteMode = 'executor',
    [string]$ExecutorTarget = 'AI Studio Apps',
    [switch]$SendToAI,
    [switch]$DeterministicDirector,
    [ValidateSet('groq', 'gemini', 'openai', 'anthropic')]
    [string]$Provider = 'groq',
    [ValidateSet('default', 'template', 'expert')]
    [string]$AIPromptMode = 'default',
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
    [switch]$NoClipboard
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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
        Write-Host $Message
    }
}

function Test-IsGeneratedArtifactFileName {
    param([string]$FileName)
    return (Test-VibeGeneratedArtifactFileName -FileName $FileName)
}

function Get-RelevantFiles {
    param([string]$CurrentPath)
    return @(Get-VibeRelevantFiles -CurrentPath $CurrentPath -AllowedExtensions $script:AllowedExtensions -IgnoredDirs $script:IgnoredDirs -IgnoredFiles $script:IgnoredFiles)
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
        [string]$CustomPromptConfigPath = $null
    )

    if (-not (Test-Path $AgentScriptPath -PathType Leaf)) { throw "Script groq-agent.ts não localizado." }

    $winner = [ordered]@{ Provider = $null; Model = $null }
    $failure = [ordered]@{ Type = $null; Status = $null; Message = $null; Details = $null }
    $script:LastAgentFailure = $null

    $handleAgentLine = {
        param([string]$Line, [string]$DefaultColor)
        if ([string]::IsNullOrWhiteSpace($Line)) { return }

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

        if ($Line -match '\[AI_RESULT\]\s+provider=([^;]+);model=(.+)$') {
            $winner.Provider = $Matches[1].Trim()
            $winner.Model = $Matches[2].Trim()
            return
        }

        Write-UILog -Message $Line -Color $DefaultColor
    }.GetNewClosure()

    $bundleParent = Split-Path $BundlePath -Parent
    $routeToken = if ($OutputRouteModeValue -eq 'executor') { 'executor' } else { 'diretor' }
    $normalizedProjectName = [System.IO.Path]::GetFileNameWithoutExtension($BundlePath) -replace '^_+(?:Diretor|Executor)_(?:BUNDLER__|BLUEPRINT__|SELECTIVE__|COPIAR_TUDO__|INTELIGENTE__|MANUAL__)?', ''
    $resultMetaPath = Join-Path $bundleParent ("_{0}_AI_RESULT_{1}.json" -f $routeToken, $normalizedProjectName)

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

    Write-UILog -Message 'Host de execução do agente: cmd.exe /c' -Color $ThemeCyan
    Write-UILog -Message ("Entrypoint do agente: npx --quiet tsx {0}" -f [System.IO.Path]::GetFileName($AgentScriptPath)) -Color $ThemeCyan
    Write-UILog -Message ("Provider alvo: {0} | Bundle: {1}" -f $PrimaryProviderValue, [System.IO.Path]::GetFileName($BundlePath)) -Color $ThemeCyan

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $process.StartInfo.FileName = 'cmd.exe'
    $process.StartInfo.Arguments = '/c ' + ($commandParts -join ' ')
    $process.StartInfo.WorkingDirectory = $script:ToolkitDir
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.EnvironmentVariables['DOTENV_CONFIG_SILENT'] = 'true'
    $process.StartInfo.EnvironmentVariables['npm_config_update_notifier'] = 'false'
    $process.StartInfo.EnvironmentVariables['NO_UPDATE_NOTIFIER'] = '1'

    if (-not $process.Start()) { throw 'Falha ao iniciar o processo do agente de IA.' }

    while (-not $process.HasExited) {
        while ($process.StandardOutput.Peek() -ge 0) { & $handleAgentLine $process.StandardOutput.ReadLine() $ThemeCyan }
        while ($process.StandardError.Peek() -ge 0) { & $handleAgentLine $process.StandardError.ReadLine() $ThemePink }
        Start-Sleep -Milliseconds 100
    }

    $process.WaitForExit()

    while ($process.StandardOutput.Peek() -ge 0) { & $handleAgentLine $process.StandardOutput.ReadLine() $ThemeCyan }
    while ($process.StandardError.Peek() -ge 0) { & $handleAgentLine $process.StandardError.ReadLine() $ThemePink }

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
            $meta = (Read-LocalTextArtifact -Path $resultMetaPathFromDisk) | ConvertFrom-Json
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

function Get-DeterministicMetaPromptOutputFileName {
    param(
        [string]$ProjectNameValue,
        [string]$ChoiceValue
    )

    switch ($ChoiceValue) {
        '1' { return "_meta-prompt_COPIAR_TUDO__${ProjectNameValue}.md" }
        '2' { return "_meta-prompt_INTELIGENTE__${ProjectNameValue}.md" }
        '3' { return "_meta-prompt_MANUAL__${ProjectNameValue}.md" }
        default { return "_meta-prompt__${ProjectNameValue}.md" }
    }
}

function Get-DeterministicMetaPromptModeLabel {
    param([string]$ChoiceValue)

    switch ($ChoiceValue) {
        '1' { return "COPIAR_TUDO" }
        '2' { return "INTELIGENTE" }
        '3' { return "MANUAL" }
        default { return "BUNDLE" }
    }
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
    ".kt", ".scala", ".dart", ".r", ".sh", ".bat", ".ps1", ".csv", ".psm1"
)
$script:SignatureExtensions = @(
    ".tsx", ".ts", ".js", ".jsx", ".prisma", ".ps1",
    ".py", ".java", ".cs", ".go", ".rb", ".php", ".rs", ".swift", ".kt", ".scala", ".dart"
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
. $SentinelUiPath

Write-SentinelHeader -Title 'SENTINEL HEADLESS' -Version 'v1.0.0'
Write-UILog -Message 'Bootstrap headless carregado.' -Color $ThemeSuccess

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

Set-Location $resolvedTargetPath

$projectName = (Get-Item .).Name
$choice = Resolve-ChoiceFromBundleMode -ModeValue $BundleMode
$currentExtractionMode = Resolve-ExtractionModeFromBundleMode -ModeValue $BundleMode
$currentDocumentMode = Resolve-DocumentModeFromExtractionMode -ExtractionMode $currentExtractionMode
$isTxtExportMode = ($choice -eq '4')
$promptConfigTemp = $null

Write-UILog -Message ("Projeto: {0}" -f $projectName)
Write-UILog -Message ("Modo headless: {0}" -f $BundleMode)
Write-UILog -Message ("Rota: {0}" -f $(if ($RouteMode -eq 'executor') { 'Direto para Executor' } else { 'Via Diretor' }))
Write-UILog -Message ("Executor alvo: {0}" -f $ExecutorTarget)

$foundFiles = @(Get-RelevantFiles -CurrentPath (Get-Location).Path | Sort-Object FullName)
if ($foundFiles.Count -eq 0) {
    throw "Nenhum arquivo elegível foi encontrado em: $resolvedTargetPath"
}

$filesToProcess = @()
$unselectedFiles = @()

if ($choice -eq '3') {
    $filesToProcess = @(Resolve-SelectedFilesForSniper -ProjectRootPath (Get-Location).Path -AllFiles $foundFiles -RequestedPaths $SelectedPaths)
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
        if ($SendToAI) {
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

        return
    }

    $headerContent = Get-VibeProtocolHeaderContent `
        -RouteMode $RouteMode `
        -ExtractionMode $currentExtractionMode `
        -ExecutorTargetValue $ExecutorTarget

    $finalContent = $headerContent + "`n`n"
    $momentumContext = $null
    $shouldLoadMomentumContext = ($RouteMode -eq 'director') -or $DeterministicDirector

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

    if ($RouteMode -eq 'director') {
        $finalContent += (Get-MomentumSectionContent -MomentumContext $momentumContext) + "`n`n"
    }

    $blueprintIssues = @()

    if ($choice -eq '1' -or $choice -eq '3') {
        if ($choice -eq '1') {
            $outputFile = Add-OutputRoutePrefixToFileName -FileName "_COPIAR_TUDO__${projectName}.md" -RouteMode $RouteMode
            $headerTitle = 'MODO COPIAR TUDO'
            Write-UILog -Message 'Iniciando Modo Copiar Tudo...' -Color $ThemeCyan
        }
        else {
            $outputFile = Add-OutputRoutePrefixToFileName -FileName "_MANUAL__${projectName}.md" -RouteMode $RouteMode
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
        $outputFile = Add-OutputRoutePrefixToFileName -FileName "_INTELIGENTE__${projectName}.md" -RouteMode $RouteMode
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

    if ($DeterministicDirector) {
        $deterministicOutputFile = Get-DeterministicMetaPromptOutputFileName -ProjectNameValue $projectName -ChoiceValue $choice
        $deterministicOutputFullPath = Join-Path (Get-Location).Path $deterministicOutputFile

        Write-UILog -Message 'Fluxo determinístico local ignorará o pre-flight diff gate.' -Color $ThemeCyan
        Write-UILog -Message ("Compilando meta-prompt determinístico local diretamente no bundler ({0})..." -f $(if ($RouteMode -eq 'executor') { 'executor' } else { 'director' })) -Color $ThemeCyan

        $deterministicContent = New-DeterministicMetaPromptArtifact `
            -ProjectNameValue $projectName `
            -ExecutorTargetValue $ExecutorTarget `
            -RouteMode $RouteMode `
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

        Write-UILog -Message 'Execução concluída sem chamada de IA e sem groq-agent.ts.' -Color $ThemeSuccess
        return
    }

    $shouldCallAI = $false
    $shouldPersistOfficialBundle = $true

    if ($SendToAI) {
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

    if ($SendToAI -and $shouldCallAI) {
        $promptConfig = New-HeadlessPromptConfigFile `
            -RouteModeValue $RouteMode `
            -ExtractionModeValue $currentExtractionMode `
            -ExecutorTargetValue $ExecutorTarget `
            -PromptModeValue $AIPromptMode `
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
        Write-UILog -Message ("Provider primário: {0} | fallback automático ativo." -f $Provider) -Color $ThemeCyan

        $agentResult = Invoke-OrchestratorAgent `
            -AgentScriptPath $agentScript `
            -BundlePath $outputFullPath `
            -ProjectNameValue $projectName `
            -ExecutorTargetValue $ExecutorTarget `
            -BundleModeValue $currentExtractionMode `
            -PrimaryProviderValue $Provider `
            -OutputRouteModeValue $RouteMode `
            -CustomPromptConfigPath $promptConfig.Path

        $finalPromptPath = $null
        if ($agentResult -and $agentResult.OutputPath -and (Test-Path $agentResult.OutputPath -PathType Leaf)) {
            $finalPromptPath = $agentResult.OutputPath
        }
        else {
            $bundleParent = Split-Path $outputFullPath -Parent
            $candidateContextPaths = @(
                (Join-Path $bundleParent (Get-AIContextOutputFileName -ProjectNameValue $projectName -RouteMode $RouteMode)),
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

        Write-UILog -Message $(if ($RouteMode -eq 'executor') { 'Agora é só colar no seu executor.' } else { 'Agora é só colar no seu orquestrador.' }) -Color $ThemeCyan
    }
    else {
        Write-UILog -Message 'Execução concluída sem chamada da IA.' -Color $ThemeSuccess
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
