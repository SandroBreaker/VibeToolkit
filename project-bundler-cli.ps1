#requires -Version 7.0

[CmdletBinding()]
param(
    [string]$Path = '.',
    [Alias('Mode')]
    [string]$BundleMode = '',
    [string[]]$SelectedPaths,
    [string]$RouteMode = '',
    [string]$ExecutorTarget = 'ChatGPT',
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
$script:OriginalWorkingDirectory = Get-Location
$script:CloneCleanupInfo = $null
$script:EffectiveOutputDirectory = $null

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

    if ([string]::IsNullOrWhiteSpace($Message)) {
        return
    }

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

    if ([string]::IsNullOrWhiteSpace($FileName)) {
        return $false
    }

    if (Test-VibeGeneratedArtifactFileName -FileName $FileName) {
        return $true
    }

    $patterns = @(
        '^_(?:bundle|blueprint|manual|txt_export)_(?:diretor|executor)(?:_[A-Za-z0-9\-]+)?__.*\.(?:md|json)$',
        '^_meta-prompt_(?:bundle|blueprint|manual)_(?:diretor|executor)(?:_[A-Za-z0-9\-]+)?__.*\.(?:md|json)$',
        '^_TXT_EXPORT__',
        '^_TXT_EXPORT__.*\.zip$'
    )

    foreach ($pattern in $patterns) {
        if ($FileName -match $pattern) {
            return $true
        }
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

function Convert-ToSafeMarkdownCodeBlock {
    param(
        [AllowNull()][string]$Content,
        [string]$Language = '',
        [string]$FenceChar = '`'
    )

    return (ConvertTo-VibeSafeMarkdownCodeBlock -Content $Content -Language $Language -FenceChar $FenceChar)
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
    param(
        [System.IO.FileInfo[]]$Files,
        [ref]$IssueCollector,
        [string]$StructureHeading,
        [string]$ContractsHeading,
        [switch]$LogExtraction
    )

    if ($null -eq $Files -or $Files.Count -eq 0) {
        return ''
    }

    $structureLines = New-Object System.Collections.Generic.List[string]
    foreach ($file in $Files) {
        $structureLines.Add((Resolve-Path -Path $file.FullName -Relative)) | Out-Null
    }

    $block = "${StructureHeading}`n"
    $block += (Convert-ToSafeMarkdownCodeBlock -Content ($structureLines -join "`n") -Language 'text')
    $block += "`n`n"
    $block += "${ContractsHeading}`n"

    foreach ($file in $Files) {
        if ($script:SignatureExtensions -notcontains $file.Extension) {
            continue
        }

        $relPath = Resolve-Path -Path $file.FullName -Relative
        if ($LogExtraction) {
            Write-UILog -Message "Extraindo assinaturas de $relPath"
        }

        $issueMessage = $null
        $signatures = @(Get-BundlerSignaturesForFile -File $file -IssueMessage ([ref]$issueMessage))
        if ($issueMessage) {
            if ($IssueCollector) {
                $IssueCollector.Value += $issueMessage
            }
            continue
        }

        if ($signatures.Count -le 0) {
            continue
        }

        $fenceLanguage = Get-CodeFenceLanguageFromExtension -Extension $file.Extension
        $signatureContent = ($signatures -join '')
        $block += "#### File: $relPath`n"
        $block += (Convert-ToSafeMarkdownCodeBlock -Content $signatureContent -Language $fenceLanguage)
        $block += "`n`n"
    }

    return $block
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
        'txtExport' { return 'txt_export' }
        default { return 'full' }
    }
}

function Resolve-DocumentModeFromExtractionMode {
    param([string]$ExtractionMode)

    if ($ExtractionMode -eq 'sniper') {
        return 'manual'
    }

    if ($ExtractionMode -eq 'txt_export') {
        return 'txt_export'
    }

    return 'full'
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
        Write-Host ('  Exibindo: {0}-{1} de {2}' -f ($offset + 1), ($endIndex + 1), $Items.Count) -ForegroundColor DarkGray

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
                throw 'Seleção sniper cancelada pelo usuário.'
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
                throw 'Seleção sniper cancelada pelo usuário.'
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
        throw 'No modo sniper não interativo, informe -SelectedPaths com pelo menos um arquivo ou diretório.'
    }

    $relativeOptions = @(
        $AllFiles |
        Sort-Object FullName |
        ForEach-Object { Resolve-Path -Path $_.FullName -Relative }
    )

    if (Test-InteractiveConsoleSelectionSupported) {
        return @(
            Invoke-ConsoleMultiSelect -Items $relativeOptions -Title 'SENTINEL HEADLESS — Seleção Sniper' -Hint '↑↓ Navegar   ESPAÇO Marcar/Desmarcar   A Todos   N Nenhum   ENTER Confirmar   Q Cancelar'
        )
    }

    Write-Host ''
    Write-Host '  Seleção manual do modo Sniper:' -ForegroundColor Cyan
    Write-Host "    - Informe um ou mais caminhos relativos ou absolutos separados por ';'"
    Write-Host '    - Pode ser arquivo ou diretório'
    Write-Host ''
    Write-Host '  Arquivos elegíveis detectados (prévia):' -ForegroundColor Cyan

    foreach ($previewFile in ($relativeOptions | Select-Object -First 20)) {
        Write-Host ('    - {0}' -f $previewFile)
    }

    if ($relativeOptions.Count -gt 20) {
        Write-Host ('    ... e mais {0} arquivo(s).' -f ($relativeOptions.Count - 20)) -ForegroundColor DarkGray
    }

    $inputValue = (Read-Host '  Caminhos do Sniper').Trim()
    if ([string]::IsNullOrWhiteSpace($inputValue)) {
        throw 'No modo sniper, informe -SelectedPaths com pelo menos um arquivo ou diretório.'
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
        throw 'No modo sniper, informe -SelectedPaths com pelo menos um arquivo ou diretório.'
    }

    $allowedMap = @{}
    foreach ($file in @($AllFiles)) {
        $allowedMap[[System.IO.Path]::GetFullPath($file.FullName)] = $file
    }

    $selectedMap = @{}

    foreach ($requestedPath in @($RequestedPaths)) {
        if ([string]::IsNullOrWhiteSpace($requestedPath)) {
            continue
        }

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
        throw 'No modo sniper, nenhum arquivo elegível foi selecionado.'
    }

    return @($selectedMap.Values | Sort-Object FullName)
}

function Set-ClipboardData {
    param([AllowEmptyString()][string]$Content)

    if ($NoClipboard) {
        return $false
    }

    try {
        Set-Clipboard -Value $Content
        return $true
    }
    catch {
        return $false
    }
}

function Get-VibeArtifactRouteLabel {
    param([string]$RouteMode)

    if ($RouteMode -match '(?i)executor') {
        return 'executor'
    }

    return 'diretor'
}

function Get-VibeArtifactModeLabel {
    param([string]$ExtractionMode)

    switch -Regex ($ExtractionMode) {
        '(?i)sniper|manual|^3$' { return 'manual' }
        '(?i)blueprint|architect|^2$' { return 'blueprint' }
        '(?i)txt_export|txtExport|^4$' { return 'txt_export' }
        default { return 'bundle' }
    }
}

function Get-VibeArtifactFileName {
    param(
        [string]$ProjectNameValue,
        [string]$ExtractionMode,
        [string]$RouteMode,
        [string]$Prefix = '',
        [string]$Extension = '.md'
    )

    $mode = Get-VibeArtifactModeLabel -ExtractionMode $ExtractionMode
    $route = Get-VibeArtifactRouteLabel -RouteMode $RouteMode
    $pfx = if ([string]::IsNullOrWhiteSpace($Prefix)) { '_' } else { "_${Prefix}_" }

    return "${pfx}${mode}_${route}__${ProjectNameValue}${Extension}"
}

function Get-ResultMetaOutputFileName {
    param(
        [string]$ProjectNameValue,
        [string]$RouteMode,
        [string]$ExtractionMode
    )

    return (Get-VibeArtifactFileName -ProjectNameValue $ProjectNameValue -ExtractionMode $ExtractionMode -RouteMode $RouteMode -Extension '.json')
}

function Get-DeterministicMetaPromptOutputFileName {
    param(
        [string]$ProjectNameValue,
        [string]$ExtractionMode,
        [string]$RouteMode
    )

    return (Get-VibeArtifactFileName -ProjectNameValue $ProjectNameValue -ExtractionMode $ExtractionMode -RouteMode $RouteMode -Prefix 'meta-prompt')
}

function Get-DeterministicRelevantFiles {
    param([System.IO.FileInfo[]]$Files)

    $priorityPatterns = @(
        '.\project-bundler-cli.ps1',
        '.\project-bundler-headless.ps1',
        '.\modules\VibeDirectorProtocol.psm1',
        '.\modules\VibeBundleWriter.psm1',
        '.\modules\VibeFileDiscovery.psm1',
        '.\modules\VibeSignatureExtractor.psm1',
        '.\README.md'
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
            $result.Add($pattern) | Out-Null
        }
    }

    if ($result.Count -eq 0) {
        foreach ($key in ($relativeMap.Keys | Select-Object -First 8)) {
            $result.Add([string]$key) | Out-Null
        }
    }

    return @($result)
}

function New-DeterministicMetaPromptArtifact {
    param(
        [string]$ProjectNameValue,
        [string]$ExecutorTargetValue,
        [string]$ExtractionMode,
        [string]$DocumentMode,
        [string]$SourceArtifactFileName,
        [string]$OutputArtifactFileName,
        [AllowEmptyString()][string]$BundleContent,
        [System.IO.FileInfo[]]$Files
    )

    $generatedAt = [DateTime]::UtcNow.ToString('o')
    $relevantFiles = @(Get-DeterministicRelevantFiles -Files $Files)
    $relevantFilesValue = if ($relevantFiles.Count -gt 0) { $relevantFiles -join ', ' } else { 'não identificados objetivamente' }
    $extractionLabel = Get-VibeExtractionModeLabel -ExtractionMode $ExtractionMode

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('## PROTOCOLO OPERACIONAL TRANSVERSAL — ELITE v3.1') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('### §0 — IDENTIDADE E MANDATO (O DIRETOR)') | Out-Null
    $lines.Add('- Papel ativo: Diretor de Engenharia Agêntica em modo determinístico local.') | Out-Null
    $lines.Add('- Saída compilada integralmente em PowerShell, sem qualquer dependência remota ou estado anterior reaproveitado.') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('### §1 — ENQUADRAMENTO OPERACIONAL') | Out-Null
    $lines.Add('- Rota ativa: VIA DIRETOR.') | Out-Null
    $lines.Add(("- Extração efetiva: {0}." -f $extractionLabel)) | Out-Null
    $lines.Add(("- Executor alvo de referência: {0}." -f $ExecutorTargetValue)) | Out-Null
    $lines.Add('- O bloco [META-PROMPT PARA EXECUTOR] abaixo está pronto para cópia.') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('## EXECUTION META') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add(("- Projeto: {0}" -f $ProjectNameValue)) | Out-Null
    $lines.Add(("- Artefato fonte: {0}" -f $SourceArtifactFileName)) | Out-Null
    $lines.Add(("- Artefato final: {0}" -f $OutputArtifactFileName)) | Out-Null
    $lines.Add(("- Executor alvo: {0}" -f $ExecutorTargetValue)) | Out-Null
    $lines.Add('- Route mode: director') | Out-Null
    $lines.Add(("- Gerado em: {0}" -f $generatedAt)) | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('## SOURCE OF TRUTH') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add(("> Modo de extração: {0}." -f $extractionLabel)) | Out-Null
    $lines.Add('> Route mode: director.') | Out-Null
    $lines.Add(("> Document mode: {0}." -f $DocumentMode)) | Out-Null
    $lines.Add('> Governança local: PowerShell puro.') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('[META-PROMPT PARA EXECUTOR]') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('## ANÁLISE DO DIRETOR') | Out-Null
    $lines.Add('O bundle visível fornece contexto suficiente para orientar uma execução local rastreável sem dependência de IA remota, mantendo contratos, escopo e regras operacionais observáveis.') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('## RACIOCÍNIO (CoT)') | Out-Null
    $lines.Add('A saída final precisa permanecer determinística, rastreável e estritamente limitada ao bundle visível. O Executor deve operar com Lei da Subtração, preservar contratos e declarar lacunas em vez de inventar arquitetura. Os recortes prioritários para leitura são: ' + $relevantFilesValue + '.') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('## PROMPT PARA O EXECUTOR (COPIAR ABAIXO)') | Out-Null
    $lines.Add('--- INÍCIO DO PROMPT ---') | Out-Null
    $lines.Add('### LAYER 1: IDENTIDADE E REGRAS') | Out-Null
    $lines.Add('- Papel do Executor: Senior Implementation Agent (Sniper).') | Out-Null
    $lines.Add('- Preservar contratos, nomes, comportamento existente e compatibilidade com o fluxo atual.') | Out-Null
    $lines.Add('- Aplicar Lei da Subtração antes de adicionar novo código.') | Out-Null
    $lines.Add('- Não inferir módulos, contratos ou comportamentos fora do bundle visível.') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('### LAYER 2: BLUEPRINT TÉCNICO') | Out-Null
    $lines.Add('- Objetivo: materializar a solicitação estritamente dentro do escopo visível do bundle.') | Out-Null
    $lines.Add('- Entrega esperada: arquivos completos alterados, sem refactor paralelo e com validação objetiva.') | Out-Null
    $lines.Add('- Route mode de origem: director.') | Out-Null
    $lines.Add(("- Extraction mode: {0}." -f $ExtractionMode)) | Out-Null
    $lines.Add(("- Executor alvo: {0}." -f $ExecutorTargetValue)) | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('### LAYER 3: ARQUIVOS-ALVO E ESCOPO') | Out-Null
    $lines.Add(("- Recortes prioritários: {0}" -f $relevantFilesValue)) | Out-Null
    $lines.Add('- Declarar explicitamente qualquer lacuna de contexto em vez de improvisar comportamento ausente.') | Out-Null
    $lines.Add('- Não usar memória anterior reaproveitada, seleção remota, parametrização externa ou qualquer superfície de IA removida.') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('### LAYER 4: PROTOCOLO DE VERIFICAÇÃO') | Out-Null
    $lines.Add('- Exigir Relatório de Impacto, implementação por arquivo, verificação de segurança e validação final.') | Out-Null
    $lines.Add('- Propor checks de regressão, cenários negativos e validações compatíveis com o escopo.') | Out-Null
    $lines.Add('--- FIM DO PROMPT ---') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('## BUNDLE VISÍVEL') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('```text') | Out-Null
    $lines.Add((Format-BundleContentForDiff -Content $BundleContent)) | Out-Null
    $lines.Add('```') | Out-Null

    return ($lines -join "`n")
}

function Format-BundleContentForDiff {
    param([AllowEmptyString()][string]$Content)

    if ($null -eq $Content) {
        return ''
    }

    return (($Content -replace "`0", '') -replace "`r`n", "`n").TrimEnd()
}

function Get-BundleContentHash {
    param([AllowEmptyString()][string]$Content)

    $normalized = Format-BundleContentForDiff -Content $Content
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()

    try {
        return ([System.BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Get-FileHashSha256 {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path $Path -PathType Leaf)) {
        return $null
    }

    return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-EnvironmentSnapshot {
    $psVersion = $null
    try {
        $psVersion = $PSVersionTable.PSVersion.ToString()
    }
    catch {
    }

    return [ordered]@{
        osVersion = [System.Environment]::OSVersion.VersionString
        psVersion = $psVersion
        isWindows = $IsWindows
        hostname = [System.Environment]::MachineName
        processArchitecture = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture.ToString()
    }
}

function Get-UserSnapshot {
    $username = $env:USERNAME
    if ([string]::IsNullOrWhiteSpace($username)) {
        $username = $env:USER
    }

    return [ordered]@{
        username = $username
        domain = $env:USERDOMAIN
        homeDirectory = $(if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) { $env:USERPROFILE } else { $env:HOME })
    }
}

function Write-LocalExecutionMeta {
    param(
        [string]$ProjectNameValue,
        [string]$RouteMode,
        [string]$ExtractionMode,
        [string]$DocumentMode,
        [string]$ExecutorTargetValue,
        [AllowNull()][string]$SourceArtifactPath = $null,
        [AllowNull()][string]$OutputPath = $null,
        [AllowNull()][string]$ResultMetaPath = $null,
        [int]$DurationMs = 0,
        [hashtable]$ExtraData
    )

    $resolvedResultMetaPath = if ([string]::IsNullOrWhiteSpace($ResultMetaPath)) {
        $baseDir = if ($script:EffectiveOutputDirectory) { $script:EffectiveOutputDirectory } else { (Get-Location).Path }
        Join-Path $baseDir (Get-ResultMetaOutputFileName -ProjectNameValue $ProjectNameValue -RouteMode $RouteMode -ExtractionMode $ExtractionMode)
    }
    else {
        $ResultMetaPath
    }

    $sourceHash = Get-FileHashSha256 -Path $SourceArtifactPath
    $outputHash = Get-FileHashSha256 -Path $OutputPath

    $meta = [ordered]@{
        ok = $true
        executionId = [guid]::NewGuid().ToString()
        executionMode = 'local'
        routeMode = $RouteMode
        extractionMode = $ExtractionMode
        documentMode = $DocumentMode
        executorTarget = $ExecutorTargetValue
        generatedAt = [DateTime]::UtcNow.ToString('o')
        durationMs = $DurationMs
        sourceArtifactPath = $SourceArtifactPath
        sourceArtifactHash = $sourceHash
        outputPath = $OutputPath
        outputHash = $outputHash
        resultMetaPath = $resolvedResultMetaPath
        generatedLocally = $true
        environment = Get-EnvironmentSnapshot
        user = Get-UserSnapshot
    }

    if ($ExtraData) {
        foreach ($key in $ExtraData.Keys) {
            $meta[$key] = $ExtraData[$key]
        }
    }

    $metaJson = $meta | ConvertTo-Json -Depth 12
    Write-LocalTextArtifact -Path $resolvedResultMetaPath -Content $metaJson -UseBom

    return [pscustomobject]@{
        Meta = [pscustomobject]$meta
        ResultMetaPath = $resolvedResultMetaPath
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

    $getRelativePathMethod = [System.IO.Path].GetMethod('GetRelativePath', [type[]]@([string], [string]))
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

    if ([string]::IsNullOrWhiteSpace($relativePath) -or $relativePath -eq '.') {
        $relativePath = [System.IO.Path]::GetFileName($fullPathResolved)
    }

    $normalizedRelativePath = $relativePath -replace '[\\/]+', [string][System.IO.Path]::DirectorySeparatorChar
    $normalizedRelativePath = $normalizedRelativePath.TrimStart([char[]]@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar, '.'))

    if ([string]::IsNullOrWhiteSpace($normalizedRelativePath) -or $normalizedRelativePath -eq '.') {
        $normalizedRelativePath = [System.IO.Path]::GetFileName($fullPathResolved)
    }

    $segments = @(
        $normalizedRelativePath -split '[\\/]+' |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_ -ne '.' }
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
    $safeSegments[$lastIndex] = '{0}.txt' -f $safeSegments[$lastIndex]

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

    return (Read-LocalTextArtifact -Path $FilePath)
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
        ZipFilePath = $zipFilePath
        ExportedFiles = $exportedFiles
        SkippedFiles = $skippedFiles
    }
}

function Resolve-BundleMode {
    param(
        [string]$BundleMode,
        [switch]$NonInteractive
    )

    if ($BundleMode -in @('full', 'blueprint', 'sniper', 'txtExport', 'txt_export')) {
        if ($BundleMode -eq 'txt_export') {
            return 'txtExport'
        }
        return $BundleMode
    }

    if ($NonInteractive) {
        throw 'Modo de extração obrigatório em execução não interativa. Use -BundleMode full, blueprint, sniper ou txtExport.'
    }

    Write-Host ''
    Write-Host '  1. Modo de Extração:' -ForegroundColor Cyan
    Write-Host '    [1] Full / Tudo  -  enviar tudo (análise completa)'
    Write-Host '    [2] Architect    -  blueprint / estrutura'
    Write-Host '    [3] Sniper       -  seleção manual (recorte com foco cirúrgico)'
    Write-Host '    [4] TXT Export   -  pasta com arquivos separados'
    Write-Host ''

    $resolved = $null
    while ($null -eq $resolved) {
        $inp = (Read-Host '  Digite 1, 2, 3 ou 4').Trim()
        switch ($inp) {
            '1' { $resolved = 'full' }
            '2' { $resolved = 'blueprint' }
            '3' { $resolved = 'sniper' }
            '4' { $resolved = 'txtExport' }
            default { Write-Host '  Entrada inválida. Digite 1, 2, 3 ou 4.' -ForegroundColor Yellow }
        }
    }

    Write-Host ''
    return $resolved
}

function Resolve-RouteMode {
    param(
        [string]$RouteMode,
        [switch]$NonInteractive
    )

    if ($RouteMode -eq 'director' -or $RouteMode -eq 'executor') {
        return $RouteMode
    }

    if ($NonInteractive) {
        throw 'Rota obrigatória em execução não interativa. Use -RouteMode director ou executor.'
    }

    Write-Host '  Fluxo de Saída:' -ForegroundColor Cyan
    Write-Host '    [1] Via Diretor          (gera meta-prompt local)'
    Write-Host '    [2] Direto para Executor (gera contexto final)'
    Write-Host ''

    $resolved = $null
    while ($null -eq $resolved) {
        $inp = (Read-Host '  Digite 1 ou 2').Trim()
        switch ($inp) {
            '1' { $resolved = 'director' }
            '2' { $resolved = 'executor' }
            default { Write-Host '  Entrada inválida. Digite 1 ou 2.' -ForegroundColor Yellow }
        }
    }

    Write-Host ''
    return $resolved
}

function Resolve-ProjectSource {
    param(
        [string]$DefaultPath,
        [switch]$NonInteractive
    )

    if ($NonInteractive) {
        return [pscustomobject]@{
            ResolvedPath = [System.IO.Path]::GetFullPath((Resolve-Path -Path $DefaultPath -ErrorAction Stop).Path)
            SourceMode = 'local'
            OriginalInput = $DefaultPath
            CloneCleanupInfo = $null
        }
    }

    Write-Host ''
    Write-Host '  ═══════════════════════════════════════' -ForegroundColor DarkCyan
    Write-Host '   ORIGEM DO PROJETO' -ForegroundColor Cyan
    Write-Host '  ═══════════════════════════════════════' -ForegroundColor DarkCyan
    Write-Host ''
    Write-Host '  Selecione a origem do projeto:' -ForegroundColor Cyan
    Write-Host '    [1] Usar path atual'
    Write-Host '    [2] Clonar repositório GitHub'
    Write-Host ''

    $choice = $null
    while ($choice -notin @('1', '2')) {
        $choice = (Read-Host '  Digite 1 ou 2').Trim()
        if ($choice -notin @('1', '2')) {
            Write-Host '  Entrada inválida. Digite 1 ou 2.' -ForegroundColor Yellow
        }
    }

    if ($choice -eq '1') {
        Write-Host ''
        $resolved = [System.IO.Path]::GetFullPath((Resolve-Path -Path $DefaultPath -ErrorAction Stop).Path)
        Write-UILog -Message ("Origem: path local -> {0}" -f $resolved) -Color $ThemeSuccess
        return [pscustomobject]@{
            ResolvedPath = $resolved
            SourceMode = 'local'
            OriginalInput = $DefaultPath
            CloneCleanupInfo = $null
        }
    }

    Write-Host ''
    Write-Host '  ═══════════════════════════════════════' -ForegroundColor DarkCyan
    Write-Host '   CLONAGEM DE REPOSITÓRIO GITHUB' -ForegroundColor Cyan
    Write-Host '  ═══════════════════════════════════════' -ForegroundColor DarkCyan
    Write-Host ''

    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) {
        throw 'Git não está instalado ou não está disponível no PATH. A clonagem de repositórios GitHub requer o Git.'
    }

    $repoUrl = $null
    while ([string]::IsNullOrWhiteSpace($repoUrl)) {
        $repoUrl = (Read-Host '  URL do repositório GitHub (ex: https://github.com/user/repo.git)').Trim()
        if ([string]::IsNullOrWhiteSpace($repoUrl)) {
            Write-Host '  URL não pode ser vazia.' -ForegroundColor Yellow
        }
    }

    if ($repoUrl -notmatch '^https?://(www\.)?github\.com/') {
        Write-UILog -Message 'Aviso: a URL fornecida não parece ser do GitHub. A clonagem será tentada mesmo assim.' -Color $ThemeWarn
    }

    Write-Host ''
    $useTempInput = (Read-Host '  Usar diretório temporário automático? (S/n)').Trim().ToLower()
    $useTempDir = -not ($useTempInput -eq 'n' -or $useTempInput -eq 'nao')

    $targetDir = $null
    $cloneMode = $null

    if ($useTempDir) {
        $cloneMode = 'temporary'
        $baseTemp = Join-Path ([System.IO.Path]::GetTempPath()) 'VibeToolkit\clones'
        if (-not (Test-Path $baseTemp)) {
            New-Item -ItemType Directory -Path $baseTemp -Force | Out-Null
        }
        $uniqueName = [System.Guid]::NewGuid().ToString('N')
        $targetDir = Join-Path $baseTemp $uniqueName
        Write-UILog -Message ("Diretório temporário automático: {0}" -f $targetDir) -Color $ThemeCyan
    }
    else {
        $cloneMode = 'manual'
        $manualPath = $null
        while ([string]::IsNullOrWhiteSpace($manualPath)) {
            $manualPath = (Read-Host '  Informe o caminho completo do diretório de destino').Trim()
            if ([string]::IsNullOrWhiteSpace($manualPath)) {
                Write-Host '  Caminho não pode ser vazio.' -ForegroundColor Yellow
                continue
            }
            try {
                $resolvedManual = [System.IO.Path]::GetFullPath($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($manualPath))
            }
            catch {
                Write-Host '  Caminho inválido. Tente novamente.' -ForegroundColor Yellow
                $manualPath = $null
                continue
            }
            $manualPath = $resolvedManual
        }
        $targetDir = $manualPath
    }

    Write-Host ''
    $keepCloneInput = (Read-Host '  Manter o clone após a execução? (s/N)').Trim().ToLower()
    $keepClone = ($keepCloneInput -eq 's' -or $keepCloneInput -eq 'sim')

    Write-UILog -Message ("Iniciando clone de {0} para {1} ..." -f $repoUrl, $targetDir) -Color $ThemeCyan

    $cloneArgs = @('clone', '--', $repoUrl, $targetDir)
    $cloneProcess = Start-Process -FilePath 'git' -ArgumentList $cloneArgs -NoNewWindow -Wait -PassThru
    if ($cloneProcess.ExitCode -ne 0) {
        throw "Falha ao clonar repositório (código de saída: $($cloneProcess.ExitCode)). Verifique a URL e sua conexão."
    }

    Write-UILog -Message 'Clone concluído com sucesso.' -Color $ThemeSuccess

    $cleanupInfo = @{
        Path = $targetDir
        CloneMode = $cloneMode
        KeepClone = $keepClone
        CreatedByUs = $true
        cleanupPerformed = $false
    }

    return [pscustomobject]@{
        ResolvedPath = $targetDir
        SourceMode = 'github'
        OriginalInput = $repoUrl
        CloneCleanupInfo = $cleanupInfo
    }
}

$script:AllowedExtensions = @(
    '.tsx', '.ts', '.js', '.jsx', '.mjs', '.cjs', '.mts', '.cts', '.vue', '.svelte', '.astro',
    '.css', '.scss', '.sass', '.less', '.html', '.htm', '.xhtml', '.cshtml', '.razor', '.xaml', '.svg',
    '.json', '.jsonc', '.json5', '.yaml', '.yml', '.xml', '.toml', '.ini', '.cfg', '.conf', '.config',
    '.properties', '.props', '.targets', '.editorconfig', '.plist', '.pbxproj', '.xcconfig',
    '.md', '.mdx', '.txt', '.rst', '.adoc', '.tex', '.csv', '.tsv',
    '.py', '.pyi', '.java', '.cs', '.vb', '.fs', '.fsi', '.fsx', '.c', '.cpp', '.cc', '.cxx', '.h', '.hh', '.hpp', '.hxx',
    '.go', '.rb', '.php', '.phtml', '.rs', '.swift', '.kt', '.kts', '.scala', '.dart', '.r', '.lua', '.pl', '.pm',
    '.jl', '.zig', '.nim', '.elm', '.ex', '.exs', '.erl', '.hrl', '.clj', '.cljs', '.cljc', '.edn', '.ml', '.mli',
    '.sh', '.bash', '.zsh', '.fish', '.ksh', '.bat', '.cmd', '.ps1', '.psm1', '.psd1', '.ps1xml',
    '.sql', '.prisma', '.graphql', '.gql', '.proto', '.tf', '.tfvars', '.hcl', '.bicep',
    '.gradle', '.sln', '.csproj', '.vbproj', '.fsproj', '.vcxproj', '.filters', '.reg'
)

$script:SignatureExtensions = @(
    '.tsx', '.ts', '.js', '.jsx', '.mjs', '.cjs', '.mts', '.cts', '.vue', '.svelte', '.astro',
    '.py', '.pyi', '.java', '.cs', '.vb', '.fs', '.fsi', '.fsx', '.c', '.cpp', '.cc', '.cxx', '.h', '.hh', '.hpp', '.hxx',
    '.go', '.rb', '.php', '.phtml', '.rs', '.swift', '.kt', '.kts', '.scala', '.dart', '.r', '.lua',
    '.pl', '.pm', '.jl', '.zig', '.nim', '.elm', '.ex', '.exs', '.erl', '.hrl', '.clj', '.cljs', '.cljc', '.edn', '.ml', '.mli',
    '.sh', '.bash', '.zsh', '.fish', '.ksh', '.bat', '.cmd', '.ps1', '.psm1', '.psd1', '.ps1xml',
    '.sql', '.prisma', '.graphql', '.gql', '.proto', '.tf', '.tfvars', '.hcl', '.bicep',
    '.cshtml', '.razor', '.xaml', '.xml', '.gradle', '.sln', '.csproj', '.vbproj', '.fsproj', '.vcxproj', '.props', '.targets', '.reg'
)

$script:IgnoredDirs = @(
    'node_modules', '.git', 'dist', 'build', '.next', '.cache', 'out',
    'coverage', '.venv', 'venv', 'env', '__pycache__', '.pytest_cache', '.tox',
    'bin', 'obj', 'target', 'vendor'
)

$script:IgnoredFiles = @(
    'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock',
    '.DS_Store', 'metadata.json', '.gitignore',
    'capacitor.plugins.json', 'cordova.js', 'cordova_plugins.js',
    'poetry.lock', 'Pipfile.lock', 'Cargo.lock', 'go.sum', 'composer.lock'
)

try {
    $sourceResult = Resolve-ProjectSource -DefaultPath $Path -NonInteractive:$NonInteractive
    $resolvedTargetPath = $sourceResult.ResolvedPath
    $sourceMode = $sourceResult.SourceMode
    $originalInput = $sourceResult.OriginalInput
    $script:CloneCleanupInfo = $sourceResult.CloneCleanupInfo

    $script:EffectiveOutputDirectory = $resolvedTargetPath
    if ($sourceMode -eq 'github' -and $script:CloneCleanupInfo.CloneMode -eq 'temporary' -and -not $script:CloneCleanupInfo.KeepClone) {
        $script:EffectiveOutputDirectory = $script:OriginalWorkingDirectory.Path
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
            Write-Host '[!] SentinelUI bloqueado por assinatura/execution policy. Ativando fallback textual para o modo headless.'
            Write-Host ("    {0}" -f $sentinelFailureSummary)
        }
        else {
            $sentinelFailureSummary = Get-SentinelUiBootstrapFailureSummary -ErrorRecord $sentinelBootstrapFailure
            throw "Falha estrutural ao carregar biblioteca de UI '$SentinelUiPath'. $sentinelFailureSummary"
        }
    }

    Assert-SentinelUiBootstrapContract -SentinelUiPath $SentinelUiPath -FallbackActive:$sentinelUiFallbackActive

    Write-SentinelHeader -Title 'SENTINEL HEADLESS' -Version 'v2.0.0'
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

    Set-Location $resolvedTargetPath
    $projectName = (Get-Item .).Name

    Write-Host ''
    Write-Host '  ═══════════════════════════════════════' -ForegroundColor DarkCyan
    Write-Host '   SENTINEL HEADLESS — Configuração' -ForegroundColor Cyan
    Write-Host '  ═══════════════════════════════════════' -ForegroundColor DarkCyan
    Write-Host ''

    $executionStartedAt = Get-Date
    $resolvedBundleMode = Resolve-BundleMode -BundleMode $BundleMode -NonInteractive:$NonInteractive
    $resolvedRouteMode = Resolve-RouteMode -RouteMode $RouteMode -NonInteractive:$NonInteractive
    $choice = Resolve-ChoiceFromBundleMode -ModeValue $resolvedBundleMode
    $currentExtractionMode = Resolve-ExtractionModeFromBundleMode -ModeValue $resolvedBundleMode
    $currentDocumentMode = Resolve-DocumentModeFromExtractionMode -ExtractionMode $currentExtractionMode
    $isTxtExportMode = ($choice -eq '4')

    Write-UILog -Message ("Projeto: {0}" -f $projectName)
    Write-UILog -Message ("Modo headless: {0}" -f $resolvedBundleMode)
    Write-UILog -Message ("Rota: {0}" -f $(if ($resolvedRouteMode -eq 'executor') { 'Direto para Executor' } else { 'Via Diretor' }))
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

    $baseExtraData = @{
        sourceMode = $sourceMode
        originalInput = $originalInput
        resolvedWorkingPath = $resolvedTargetPath
        effectiveOutputDirectory = $script:EffectiveOutputDirectory
    }

    if ($script:CloneCleanupInfo) {
        $baseExtraData.cloneMode = $script:CloneCleanupInfo.CloneMode
        $baseExtraData.keepClone = $script:CloneCleanupInfo.KeepClone
        $baseExtraData.cleanupPerformed = $false
    }

    if ($isTxtExportMode) {
        $txtExportResult = Export-OperationFilesToTxtDirectory -Files $filesToProcess -ProjectRootPath (Get-Location).Path -BaseOutputDirectory $script:EffectiveOutputDirectory -ProjectNameValue $projectName

        Write-UILog -Message ("Pasta de saída: {0}" -f $txtExportResult.OutputDirectory) -Color $ThemeSuccess
        Write-UILog -Message ("Arquivo ZIP: {0}" -f $txtExportResult.ZipFilePath) -Color $ThemeSuccess
        Write-UILog -Message ("Arquivos exportados: {0}" -f $txtExportResult.ExportedFiles.Count) -Color $ThemeSuccess

        if ($txtExportResult.SkippedFiles.Count -gt 0) {
            Write-UILog -Message ("Arquivos ignorados por incompatibilidade/erro: {0}" -f $txtExportResult.SkippedFiles.Count) -Color $ThemeWarn
        }

        $extraData = $baseExtraData.Clone()
        $extraData.outputDirectory = $txtExportResult.OutputDirectory
        $extraData.zipFilePath = $txtExportResult.ZipFilePath
        $extraData.exportedFiles = @($txtExportResult.ExportedFiles)
        $extraData.skippedFiles = @($txtExportResult.SkippedFiles)
        $extraData.exportedFileCount = $txtExportResult.ExportedFiles.Count
        $extraData.skippedFileCount = $txtExportResult.SkippedFiles.Count

        $durationMs = [int][Math]::Round(((Get-Date) - $executionStartedAt).TotalMilliseconds)
        $txtExportMetaResult = Write-LocalExecutionMeta -ProjectNameValue $projectName -RouteMode $resolvedRouteMode -ExtractionMode $currentExtractionMode -DocumentMode 'txt_export' -ExecutorTargetValue $ExecutorTarget -SourceArtifactPath $txtExportResult.ZipFilePath -OutputPath $txtExportResult.ZipFilePath -DurationMs $durationMs -ExtraData $extraData

        Write-UILog -Message ("Metadados locais salvos em: {0}" -f $txtExportMetaResult.ResultMetaPath) -Color $ThemeSuccess
        return
    }

    $headerContent = Get-VibeProtocolHeaderContent -RouteMode $resolvedRouteMode -ExtractionMode $currentExtractionMode -ExecutorTargetValue $ExecutorTarget
    $finalContent = $headerContent + "`n`n"
    $blueprintIssues = @()

    if ($choice -eq '1' -or $choice -eq '3') {
        if ($choice -eq '1') {
            $sourceArtifactFileName = Get-VibeArtifactFileName -ProjectNameValue $projectName -ExtractionMode $currentExtractionMode -RouteMode $resolvedRouteMode
            $headerTitle = 'MODO COPIAR TUDO'
            Write-UILog -Message 'Iniciando Modo Copiar Tudo...' -Color $ThemeCyan
        }
        else {
            $sourceArtifactFileName = Get-VibeArtifactFileName -ProjectNameValue $projectName -ExtractionMode $currentExtractionMode -RouteMode $resolvedRouteMode
            $headerTitle = 'MODO MANUAL'
            Write-UILog -Message 'Iniciando Modo Sniper / Manual...' -Color $ThemePink
        }

        $finalContent += "## ${headerTitle}: $projectName`n`n"

        if ($choice -eq '3') {
            $finalContent += "### 0. ANALYSIS SCOPE`n```text`n"
            $finalContent += "ESCOPO: FECHADO / PARCIAL`n"
            $finalContent += "Este bundle contém apenas os arquivos selecionados manualmente pelo usuário.`n"
            if ($unselectedFiles.Count -gt 0) {
                $finalContent += "Os arquivos não selecionados foram anexados ao final em modo Bundler como contexto complementar.`n"
            }
            $finalContent += "Qualquer análise deve considerar exclusivamente o visível neste artefato.`n"
            $finalContent += "É proibido inferir módulos, dependências ou comportamento não visíveis.`n"
            $finalContent += "Quando faltar contexto, declarar: 'não visível no recorte enviado'.`n"
            $finalContent += "```\n\n"
        }

        Write-UILog -Message 'Montando estrutura do projeto...'
        $finalContent += "### 1. PROJECT STRUCTURE`n```text`n"
        foreach ($file in $filesToProcess) {
            $finalContent += (Resolve-Path -Path $file.FullName -Relative) + "`n"
        }
        $finalContent += "```\n\n"

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
            $finalContent += New-BundlerContractsBlock -Files $unselectedFiles -IssueCollector ([ref]$blueprintIssues) -StructureHeading '### PROJECT STRUCTURE (BUNDLER)' -ContractsHeading '### CORE DOMAINS & CONTRACTS (BUNDLER)' -LogExtraction
        }
    }
    else {
        $sourceArtifactFileName = Get-VibeArtifactFileName -ProjectNameValue $projectName -ExtractionMode $currentExtractionMode -RouteMode $resolvedRouteMode
        Write-UILog -Message 'Iniciando Modo Architect / Blueprint...' -Color $ThemeCyan
        $finalContent += "## MODO INTELIGENTE: $projectName`n`n"
        $finalContent += "### 1. TECH STACK`n"

        $packageJsonPath = Join-Path (Get-Location).Path 'package.json'
        if (Test-Path $packageJsonPath -PathType Leaf) {
            try {
                Write-UILog -Message 'Lendo package.json para tech stack...'
                $pkg = (Read-LocalTextArtifact -Path $packageJsonPath) | ConvertFrom-Json
                if ($pkg.dependencies) { $finalContent += "* **Deps:** $(($pkg.dependencies.PSObject.Properties.Name -join ', '))`n" }
                if ($pkg.devDependencies) { $finalContent += "* **Dev Deps:** $(($pkg.devDependencies.PSObject.Properties.Name -join ', '))`n" }
            }
            catch {
                Write-UILog -Message 'package.json existe, mas não pôde ser lido. Seguindo sem tech stack declarada.' -Color $ThemeWarn
            }
        }
        else {
            Write-UILog -Message 'package.json não encontrado; tech stack externa será omitida.' -Color $ThemeWarn
        }

        $finalContent += "`n"
        $finalContent += New-BundlerContractsBlock -Files $filesToProcess -IssueCollector ([ref]$blueprintIssues) -StructureHeading '### 2. PROJECT STRUCTURE' -ContractsHeading '### 3. CORE DOMAINS & CONTRACTS' -LogExtraction
    }

    $sourceArtifactPath = Join-Path $script:EffectiveOutputDirectory $sourceArtifactFileName
    Write-LocalTextArtifact -Path $sourceArtifactPath -Content $finalContent -UseBom
    Write-UILog -Message ("Artefato operacional salvo em: {0}" -f $sourceArtifactPath) -Color $ThemeSuccess

    $artifactForClipboardPath = $sourceArtifactPath
    $finalOutputPath = $sourceArtifactPath

    if ($resolvedRouteMode -eq 'director') {
        $deterministicOutputFile = Get-DeterministicMetaPromptOutputFileName -ProjectNameValue $projectName -ExtractionMode $currentExtractionMode -RouteMode $resolvedRouteMode
        $deterministicOutputPath = Join-Path $script:EffectiveOutputDirectory $deterministicOutputFile

        Write-UILog -Message 'Compilando meta-prompt determinístico local diretamente no bundler...' -Color $ThemeCyan
        $deterministicContent = New-DeterministicMetaPromptArtifact -ProjectNameValue $projectName -ExecutorTargetValue $ExecutorTarget -ExtractionMode $currentExtractionMode -DocumentMode $currentDocumentMode -SourceArtifactFileName $sourceArtifactFileName -OutputArtifactFileName $deterministicOutputFile -BundleContent $finalContent -Files $filesToProcess

        Write-LocalTextArtifact -Path $deterministicOutputPath -Content $deterministicContent -UseBom
        $artifactForClipboardPath = $deterministicOutputPath
        $finalOutputPath = $deterministicOutputPath

        Write-UILog -Message ("Meta-prompt determinístico salvo em: {0}" -f $deterministicOutputPath) -Color $ThemeSuccess
    }

    if ($blueprintIssues -and $blueprintIssues.Count -gt 0) {
        Write-UILog -Message ("Artefato gerado com {0} aviso(s)." -f $blueprintIssues.Count) -Color $ThemeWarn
        foreach ($issue in ($blueprintIssues | Select-Object -First 10)) {
            Write-UILog -Message $issue -Color $ThemeWarn
        }
    }
    else {
        Write-UILog -Message 'Artefato consolidado com sucesso.' -Color $ThemeSuccess
    }

    $clipboardContent = Read-LocalTextArtifact -Path $artifactForClipboardPath
    $copied = Set-ClipboardData -Content $clipboardContent
    if ($copied) {
        Write-UILog -Message 'Artefato final copiado para a área de clipboard.' -Color $ThemeCyan
    }
    else {
        Write-UILog -Message 'Artefato final salvo. Clipboard indisponível.' -Color $ThemeWarn
    }

    $durationMs = [int][Math]::Round(((Get-Date) - $executionStartedAt).TotalMilliseconds)
    $extraData = $baseExtraData.Clone()
    $extraData.sourceArtifactFile = $sourceArtifactFileName
    $extraData.outputArtifactFile = [System.IO.Path]::GetFileName($finalOutputPath)
    $extraData.fileCount = $filesToProcess.Count
    $extraData.unselectedFileCount = $unselectedFiles.Count
    $extraData.generatedFromLocalGovernance = $true

    $resultMetaPath = Join-Path $script:EffectiveOutputDirectory ([System.IO.Path]::GetFileNameWithoutExtension($finalOutputPath) + '.json')
    $metaResult = Write-LocalExecutionMeta -ProjectNameValue $projectName -RouteMode $resolvedRouteMode -ExtractionMode $currentExtractionMode -DocumentMode $currentDocumentMode -ExecutorTargetValue $ExecutorTarget -SourceArtifactPath $sourceArtifactPath -OutputPath $finalOutputPath -ResultMetaPath $resultMetaPath -DurationMs $durationMs -ExtraData $extraData

    Write-UILog -Message ("Metadados locais salvos em: {0}" -f $metaResult.ResultMetaPath) -Color $ThemeSuccess
}
catch {
    $errorMessage = $_.Exception.Message
    Write-UILog -Message ("Falha na execução: {0}" -f $errorMessage) -Color $ThemePink
    throw
}
finally {
    if ($script:CloneCleanupInfo -and $script:CloneCleanupInfo.CreatedByUs -and -not $script:CloneCleanupInfo.KeepClone) {
        $clonePath = $script:CloneCleanupInfo.Path
        if (Test-Path $clonePath -PathType Container) {
            if ($script:OriginalWorkingDirectory) {
                Set-Location $script:OriginalWorkingDirectory.Path -ErrorAction SilentlyContinue
            }

            try {
                Remove-Item -Path $clonePath -Recurse -Force -ErrorAction Stop
                Write-UILog -Message ("Clone temporário removido: {0}" -f $clonePath) -Color $ThemeSuccess
                if ($script:CloneCleanupInfo.ContainsKey('cleanupPerformed')) {
                    $script:CloneCleanupInfo.cleanupPerformed = $true
                }
            }
            catch {
                Write-UILog -Message ("Não foi possível remover o clone temporário: {0}. Erro: {1}" -f $clonePath, $_.Exception.Message) -Color $ThemeWarn
            }
        }
    }
}
