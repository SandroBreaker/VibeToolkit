# Política de runtime: PowerShell 7 preferencial; Windows PowerShell 5.1 como fallback operacional.

[CmdletBinding()]
param(
    [string]$Path = '.',
    [Alias('Mode')]
    [string]$BundleMode = '',
    [string[]]$SelectedPaths,
    [string]$RouteMode = '',
    [string]$ExecutorTarget = 'IA Generativa (GenAI)',
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:SentinelUtf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $script:SentinelUtf8NoBom
[Console]::OutputEncoding = $script:SentinelUtf8NoBom
$OutputEncoding = $script:SentinelUtf8NoBom

$env:PYTHONUTF8 = '1'

$script:SentinelPlainOutput = $false
try {
    $script:SentinelPlainOutput = [Console]::IsOutputRedirected
}
catch {
    $script:SentinelPlainOutput = $false
}

try {
    if ($PSStyle) {
        $PSStyle.OutputRendering = if ($script:SentinelPlainOutput) { 'PlainText' } else { 'Host' }
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

function Get-SentinelLogLeafName {
    param([AllowEmptyString()][string]$PathValue = '')

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return ''
    }

    $normalizedPathValue = $PathValue.Trim().Trim('"')
    $normalizedPathValue = $normalizedPathValue.TrimEnd([char[]]@('\', '/'))

    if ([string]::IsNullOrWhiteSpace($normalizedPathValue)) {
        return ''
    }

    try {
        $leafName = [System.IO.Path]::GetFileName($normalizedPathValue)
        if (-not [string]::IsNullOrWhiteSpace($leafName)) {
            return $leafName
        }
    }
    catch {
    }

    return $normalizedPathValue
}

function Format-SentinelLogMessage {
    param([Parameter(Mandatory = $true)][string]$Message)

    $normalizedMessage = $Message.Trim()
    if ([string]::IsNullOrWhiteSpace($normalizedMessage)) {
        return $normalizedMessage
    }

    if ($normalizedMessage -match '^Lendo (?<path>.+)$') {
        $pathValue = $Matches.path.Trim()
        $leafName = Get-SentinelLogLeafName -PathValue $pathValue
        if (-not [string]::IsNullOrWhiteSpace($leafName) -and $leafName -ne $pathValue) {
            return ('Lendo {0} · {1}' -f $leafName, $pathValue)
        }
    }

    if ($normalizedMessage -match '^Extraindo assinaturas de (?<path>.+)$') {
        $pathValue = $Matches.path.Trim()
        $leafName = Get-SentinelLogLeafName -PathValue $pathValue
        if (-not [string]::IsNullOrWhiteSpace($leafName) -and $leafName -ne $pathValue) {
            return ('Extraindo assinaturas de {0} · {1}' -f $leafName, $pathValue)
        }
    }

    if ($normalizedMessage -match '^(?<prefix>TXT gerado:|Artefato final TXT Export:|Staging interno removido:|Pasta de saída:|Arquivo ZIP:|Metadados locais salvos em:|Meta-prompt salvo em:|Clone temporário removido:|Diretório temporário automático:|Diretório manual informado:)\s*(?<path>.+)$') {
        $prefix = $Matches.prefix
        $pathValue = $Matches.path.Trim()
        $leafName = Get-SentinelLogLeafName -PathValue $pathValue
        if (-not [string]::IsNullOrWhiteSpace($leafName) -and $leafName -ne $pathValue) {
            return ('{0} {1} · {2}' -f $prefix, $leafName, $pathValue)
        }
    }

    if ($normalizedMessage -match '^Falha ao exportar TXT:\s*(?<path>.+?)\s*::\s*(?<reason>.+)$') {
        $pathValue = $Matches.path.Trim()
        $reasonValue = $Matches.reason.Trim()
        $leafName = Get-SentinelLogLeafName -PathValue $pathValue
        if (-not [string]::IsNullOrWhiteSpace($leafName)) {
            return ('Falha ao exportar TXT: {0} :: {1}' -f $leafName, $reasonValue)
        }
    }

    return $normalizedMessage
}

function Write-UILog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Color = $ThemeText
    )

    if ([string]::IsNullOrWhiteSpace($Message)) {
        return
    }

    $formattedMessage = Format-SentinelLogMessage -Message $Message
    $statusType = switch ($Color) {
        'Success' { 'Success' }
        'Warning' { 'Warning' }
        'Error' { 'Error' }
        default { 'Info' }
    }

    try {
        Write-SentinelStatus -Message $formattedMessage -Type $statusType
    }
    catch {
        [Console]::Out.WriteLine($formattedMessage)
    }
}

function Get-SentinelBundleModeTone {
    param([string]$BundleModeValue)

    switch ($BundleModeValue) {
        'full' { return 'Primary' }
        'blueprint' { return 'Success' }
        'sniper' { return 'Warning' }
        'txtExport' { return 'Secondary' }
        'txt_export' { return 'Secondary' }
        default { return 'Muted' }
    }
}

function Get-SentinelRouteModeTone {
    param([string]$RouteModeValue)

    switch ($RouteModeValue) {
        'director' { return 'Primary' }
        'executor' { return 'Success' }
        default { return 'Muted' }
    }
}

function Get-SentinelModeBadgeLines {
    param(
        [string]$BundleModeValue,
        [string]$RouteModeValue
    )

    $badges = New-Object System.Collections.Generic.List[string]
    $normalizedBundleMode = if ($BundleModeValue -eq 'txt_export') { 'TXT_EXPORT' } else { $BundleModeValue.ToUpperInvariant() }
    $normalizedRouteMode = $RouteModeValue.ToUpperInvariant()

    $badges.Add((Format-SentinelBadge -Label $normalizedBundleMode -Tone (Get-SentinelBundleModeTone -BundleModeValue $BundleModeValue))) | Out-Null
    $badges.Add((Format-SentinelBadge -Label $normalizedRouteMode -Tone (Get-SentinelRouteModeTone -RouteModeValue $RouteModeValue))) | Out-Null

    return @($badges)
}

function Write-SentinelOperationSummary {
    param(
        [string]$ProjectNameValue,
        [string]$BundleModeValue,
        [string]$RouteModeValue,
        [string]$ExecutorTargetValue,
        [string]$OriginValue = '',
        [int]$EligibleCount = -1,
        [int]$OperationCount = -1
    )

    Write-Host ''
    Write-SentinelBadgeLine -Badges (Get-SentinelModeBadgeLines -BundleModeValue $BundleModeValue -RouteModeValue $RouteModeValue)
    Write-Host ''

    $routeLabel = if ($RouteModeValue -eq 'executor') { 'Executor' } else { 'Diretor' }
    $extractionLabel = switch ($BundleModeValue) {
        'full' { 'Full' }
        'blueprint' { 'Blueprint' }
        'sniper' { 'Sniper' }
        'txtExport' { 'TXT Export' }
        'txt_export' { 'TXT Export' }
        default { $BundleModeValue }
    }

    Write-SentinelText -Text '  Projeto' -Color $SentinelTheme.Muted
    Write-SentinelKeyValue -Key 'Nome' -Value $ProjectNameValue -Tone 'Primary' -KeyWidth 14
    if (-not [string]::IsNullOrWhiteSpace($OriginValue)) {
        Write-SentinelKeyValue -Key 'Origem' -Value $OriginValue -Tone 'Primary' -KeyWidth 14
    }
    Write-Host ''

    Write-SentinelText -Text '  Execução' -Color $SentinelTheme.Muted
    Write-SentinelKeyValue -Key 'Extração' -Value $extractionLabel -Tone (Get-SentinelBundleModeTone -BundleModeValue $BundleModeValue) -KeyWidth 14
    Write-SentinelKeyValue -Key 'Rota' -Value $routeLabel -Tone (Get-SentinelRouteModeTone -RouteModeValue $RouteModeValue) -KeyWidth 14
    Write-SentinelKeyValue -Key 'Executor' -Value $ExecutorTargetValue -Tone 'Primary' -KeyWidth 14
    Write-Host ''

    if ($EligibleCount -ge 0) {
        Write-SentinelText -Text '  Escopo' -Color $SentinelTheme.Muted
        Write-SentinelKeyValue -Key 'Elegíveis' -Value $EligibleCount -Tone 'Primary' -KeyWidth 14
        Write-SentinelKeyValue -Key 'Operação' -Value $(if ($OperationCount -ge 0) { $OperationCount } else { $EligibleCount }) -Tone 'Primary' -KeyWidth 14
        Write-Host ''
    }
}

function Get-SentinelExecutionModeLabel {
    param([string]$ChoiceValue)

    switch ($ChoiceValue) {
        '1' { return 'Full' }
        '2' { return 'Blueprint' }
        '3' { return 'Sniper' }
        '4' { return 'TXT Export' }
        default { return 'Execução' }
    }
}

function Write-SentinelExecutionStreamHeader {
    param(
        [string]$ChoiceValue,
        [string]$ProjectNameValue,
        [int]$DiscoveredFileCount,
        [int]$FilesToProcessCount,
        [int]$UnselectedFileCount,
        [string]$EffectiveOutputDirectory
    )

    Write-SentinelKeyValue -Key 'Saída' -Value $EffectiveOutputDirectory -Tone 'Secondary' -KeyWidth 14

    if ($UnselectedFileCount -gt 0) {
        Write-SentinelKeyValue -Key 'Fora do recorte' -Value $UnselectedFileCount -Tone 'Warning' -KeyWidth 14
    }

    Write-SentinelDivider -Tone 'Muted'
    Write-Host ''
}

function Get-SentinelSourceModeDisplay {
    param([string]$SourceModeValue)

    switch ($SourceModeValue) {
        'github' { return 'Repositório GitHub' }
        default { return 'Path local' }
    }
}

function New-SentinelMenuOptionLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [AllowEmptyString()][string]$Description = '',
        [int]$LabelWidth = 18
    )

    $safeLabel = ($Label -replace '\s+', ' ').Trim()
    $safeDescription = ($Description -replace '\s+', ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($safeDescription)) {
        return $safeLabel
    }

    return ('{0} {1}' -f $safeLabel.PadRight([Math]::Max($LabelWidth, 8)), $safeDescription)
}

function Write-SentinelConfigurationContext {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$StepLabel = '',
        [AllowEmptyString()][string]$ProjectNameValue = '',
        [AllowEmptyString()][string]$OriginValue = '',
        [AllowEmptyString()][string]$SourceModeValue = '',
        [AllowEmptyString()][string]$BundleModeValue = '',
        [AllowEmptyString()][string]$RouteModeValue = '',
        [AllowEmptyString()][string]$ExecutorTargetValue = ''
    )

    $hasContext = $false

    if (-not [string]::IsNullOrWhiteSpace($StepLabel)) {
        Write-SentinelBadgeLine -Badges @((Format-SentinelBadge -Label $StepLabel -Tone 'Secondary'))
        $hasContext = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($ProjectNameValue)) {
        Write-SentinelKeyValue -Key 'Projeto' -Value $ProjectNameValue -Tone 'Primary'
        $hasContext = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($OriginValue)) {
        Write-SentinelKeyValue -Key 'Origem' -Value $OriginValue -Tone 'Primary'
        $hasContext = $true
    }
    elseif (-not [string]::IsNullOrWhiteSpace($SourceModeValue)) {
        Write-SentinelKeyValue -Key 'Origem' -Value (Get-SentinelSourceModeDisplay -SourceModeValue $SourceModeValue) -Tone 'Primary'
        $hasContext = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($BundleModeValue)) {
        Write-SentinelKeyValue -Key 'Extração' -Value $BundleModeValue -Tone (Get-SentinelBundleModeTone -BundleModeValue $BundleModeValue)
        $hasContext = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($RouteModeValue)) {
        $routeLabel = if ($RouteModeValue -eq 'executor') { 'Executor' } else { 'Diretor' }
        Write-SentinelKeyValue -Key 'Rota' -Value $routeLabel -Tone (Get-SentinelRouteModeTone -RouteModeValue $RouteModeValue)
        $hasContext = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($ExecutorTargetValue)) {
        Write-SentinelKeyValue -Key 'Executor' -Value $ExecutorTargetValue -Tone 'Primary'
        $hasContext = $true
    }

    if ($hasContext) {
        Write-Host ''
    }
}

function Get-SentinelUiRequiredFunctionNames {
    return @(
        'Write-SentinelHeader',
        'Write-SentinelStatus',
        'Write-SentinelDivider',
        'Write-SentinelSection',
        'Write-SentinelPanel',
        'Write-SentinelKeyValue',
        'Write-SentinelMenuOptions',
        'Write-SentinelProgress',
        'Format-SentinelBadge',
        'Write-SentinelBadgeLine'
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
    $getFallbackDividerContent = {
        param(
            [AllowEmptyString()][string]$Label = '',
            [int]$Width = 34,
            [string]$Character = '='
        )

        $safeWidth = [Math]::Max($Width, 8)
        $dividerChar = if ([string]::IsNullOrEmpty($Character)) { '=' } else { $Character.Substring(0, 1) }

        if ([string]::IsNullOrWhiteSpace($Label)) {
            return ($dividerChar * $safeWidth)
        }

        $normalizedLabel = ($Label -replace '\s+', ' ').Trim()
        if ([string]::IsNullOrWhiteSpace($normalizedLabel)) {
            return ($dividerChar * $safeWidth)
        }

        $minimumSideWidth = 2
        $labelPaddingWidth = 2
        $maxLabelLength = $safeWidth - (($minimumSideWidth * 2) + $labelPaddingWidth)

        if ($maxLabelLength -le 0) {
            return ($dividerChar * $safeWidth)
        }

        if ($normalizedLabel.Length -gt $maxLabelLength) {
            if ($maxLabelLength -eq 1) {
                $normalizedLabel = '.'
            }
            elseif ($maxLabelLength -eq 2) {
                $normalizedLabel = '..'
            }
            else {
                $normalizedLabel = $normalizedLabel.Substring(0, $maxLabelLength - 3) + '...'
            }
        }

        $framedLabel = " $normalizedLabel "
        $remaining = $safeWidth - $framedLabel.Length

        if ($remaining -lt ($minimumSideWidth * 2)) {
            return ($dividerChar * $safeWidth)
        }

        $leftWidth = [int][Math]::Floor($remaining / 2)
        $rightWidth = $remaining - $leftWidth

        if ($leftWidth -lt $minimumSideWidth) {
            $leftWidth = $minimumSideWidth
            $rightWidth = $remaining - $leftWidth
        }

        if ($rightWidth -lt $minimumSideWidth) {
            $rightWidth = $minimumSideWidth
            $leftWidth = $remaining - $rightWidth
        }

        return ('{0}{1}{2}' -f ($dividerChar * $leftWidth), $framedLabel, ($dividerChar * $rightWidth))
    }

    $writeSentinelText = {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Text,
            [string]$Color = ''
        )

        Write-Host $Text
    }

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
            default { '[>]' }
        }

        Write-Host ("  {0} {1}" -f $prefix, $Message)
    }

    $writeSentinelDivider = {
        param(
            [string]$Label,
            [string]$Tone = 'Secondary',
            [int]$Width = 34,
            [string]$Character = '='
        )

        $safeWidth = [Math]::Max($Width, 8)
        $dividerChar = if ([string]::IsNullOrEmpty($Character)) { '=' } else { $Character.Substring(0, 1) }

        if ([string]::IsNullOrWhiteSpace($Label)) {
            Write-Host ("  {0}" -f ($dividerChar * $safeWidth))
            return
        }

        $normalizedLabel = ($Label -replace '\s+', ' ').Trim()
        if ([string]::IsNullOrWhiteSpace($normalizedLabel)) {
            Write-Host ("  {0}" -f ($dividerChar * $safeWidth))
            return
        }

        $minimumSideWidth = 2
        $labelPaddingWidth = 2
        $maxLabelLength = $safeWidth - (($minimumSideWidth * 2) + $labelPaddingWidth)

        if ($maxLabelLength -le 0) {
            Write-Host ("  {0}" -f ($dividerChar * $safeWidth))
            return
        }

        if ($normalizedLabel.Length -gt $maxLabelLength) {
            if ($maxLabelLength -eq 1) {
                $normalizedLabel = '.'
            }
            elseif ($maxLabelLength -eq 2) {
                $normalizedLabel = '..'
            }
            else {
                $normalizedLabel = $normalizedLabel.Substring(0, $maxLabelLength - 3) + '...'
            }
        }

        $framedLabel = " $normalizedLabel "
        $remaining = $safeWidth - $framedLabel.Length

        if ($remaining -lt ($minimumSideWidth * 2)) {
            Write-Host ("  {0}" -f ($dividerChar * $safeWidth))
            return
        }

        $leftWidth = [int][Math]::Floor($remaining / 2)
        $rightWidth = $remaining - $leftWidth

        if ($leftWidth -lt $minimumSideWidth) {
            $leftWidth = $minimumSideWidth
            $rightWidth = $remaining - $leftWidth
        }

        if ($rightWidth -lt $minimumSideWidth) {
            $rightWidth = $minimumSideWidth
            $leftWidth = $remaining - $rightWidth
        }

        Write-Host ("  {0}" -f ('{0}{1}{2}' -f ($dividerChar * $leftWidth), $framedLabel, ($dividerChar * $rightWidth)))
    }

    $writeSentinelHeader = {
        param(
            [string]$Title = 'SENTINEL',
            [string]$Version = 'v1.0.0',
            [ValidateSet('Hero', 'Compact', 'Minimal')]
            [string]$Variant = 'Hero'
        )

        switch ($Variant) {
            'Minimal' {
                Write-Host ("  {0} · {1}" -f $Title, $Version)
                Write-Host ''
                return
            }
            'Compact' {
                & $writeSentinelDivider -Label $Title -Tone 'Primary'
                Write-Host ("  {0}" -f $Version)
                Write-Host ''
                return
            }
            default {
                & $writeSentinelDivider -Tone 'Secondary'
                Write-Host ("  {0} · {1}" -f $Title, $Version)
                & $writeSentinelDivider -Tone 'Secondary'
                Write-Host ''
            }
        }
    }

    $writeSentinelSection = {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Title,
            [string]$Subtitle,
            [string]$Tone = 'Primary'
        )

        Write-Host ''
        & $writeSentinelDivider -Label $Title -Tone $Tone
        if (-not [string]::IsNullOrWhiteSpace($Subtitle)) {
            Write-Host ("  {0}" -f $Subtitle)
        }
        Write-Host ''
    }

    $writeSentinelPanel = {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Title,
            [string[]]$Lines,
            [string]$Tone = 'Secondary'
        )

        Write-Host ("  {0}" -f $Title)
        foreach ($line in @($Lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
            Write-Host ("    {0}" -f $line)
        }
        Write-Host ''
    }

    $writeSentinelKeyValue = {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Key,
            [AllowEmptyString()][string]$Value = '',
            [int]$KeyWidth = 18,
            [string]$Tone = 'Primary'
        )

        $paddedKey = $Key.PadRight([Math]::Max($KeyWidth, 8))
        Write-Host ("  {0}: {1}" -f $paddedKey, $Value)
    }

    $writeSentinelMenuOptions = {
        param(
            [Parameter(Mandatory = $true)]
            [string[]]$Options
        )

        for ($index = 0; $index -lt $Options.Count; $index++) {
            Write-Host ("    [{0}] {1}" -f ($index + 1), $Options[$index])
        }
        Write-Host ''
    }

    $writeSentinelProgress = {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Activity,
            [int]$Current = 0,
            [int]$Total = 0,
            [string]$Tone = 'Primary',
            [string]$Item = ''
        )

        $windowWidth = 80
        try { $windowWidth = [Math]::Max([Console]::WindowWidth, 60) } catch {}

        if ($Total -le 0) {
            $line = "  > {0}" -f $Activity
            Write-Host ("`r{0}" -f $line.PadRight($windowWidth - 1)) -NoNewline
            return
        }

        $safeCurrent = [Math]::Min([Math]::Max($Current, 0), $Total)
        $barWidth = 14
        $ratio = if ($Total -eq 0) { 0 } else { [double]$safeCurrent / [double]$Total }
        $filled = [int][Math]::Round(($ratio * $barWidth), 0, [System.MidpointRounding]::AwayFromZero)
        $filled = [Math]::Min([Math]::Max($filled, 0), $barWidth)
        $empty = $barWidth - $filled
        $bar = ('#' * $filled) + ('-' * $empty)
        $percent = [int][Math]::Round(($ratio * 100), 0, [System.MidpointRounding]::AwayFromZero)

        $progressText = "[{0}] {1,3}% ({2}/{3})" -f $bar, $percent, $safeCurrent, $Total
        $fixedLength = 4 + $Activity.Length + 1 + $progressText.Length
        $availableForItem = $windowWidth - $fixedLength - 5
        
        $displayItem = ''
        if (-not [string]::IsNullOrWhiteSpace($Item) -and $availableForItem -gt 5) {
            $displayItem = if ($Item.Length -le $availableForItem) { $Item } else { '...' + $Item.Substring($Item.Length - ($availableForItem - 3)) }
            $displayItem = " " + $displayItem
        }

        $line = "  > {0} {1}{2}" -f $Activity, $progressText, $displayItem
        Write-Host ("`r{0}" -f $line.PadRight($windowWidth - 1)) -NoNewline
    }

    $formatSentinelBadge = {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Label,
            [string]$Tone = 'Primary'
        )

        return ('[{0}]' -f (($Label -replace '\s+', ' ').Trim().ToUpperInvariant()))
    }

    $writeSentinelBadgeLine = {
        param([string[]]$Badges)

        $normalizedBadges = @($Badges | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($normalizedBadges.Count -gt 0) {
            Write-Host ("  {0}" -f ($normalizedBadges -join ' '))
        }
    }

    Set-Item -Path Function:\script:Write-SentinelText -Value $writeSentinelText.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelStatus -Value $writeSentinelStatus.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelDivider -Value $writeSentinelDivider.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelHeader -Value $writeSentinelHeader.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelSection -Value $writeSentinelSection.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelPanel -Value $writeSentinelPanel.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelKeyValue -Value $writeSentinelKeyValue.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelMenuOptions -Value $writeSentinelMenuOptions.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelProgress -Value $writeSentinelProgress.GetNewClosure() -Force
    Set-Item -Path Function:\script:Format-SentinelBadge -Value $formatSentinelBadge.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelBadgeLine -Value $writeSentinelBadgeLine.GetNewClosure() -Force
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
        '^_txt_export_(?:diretor|executor)(?:_[A-Za-z0-9\-]+)?__.*\.zip$',
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

function Get-NormalizedRelativeProjectPath {
    param([System.IO.FileInfo]$File)

    if ($null -eq $File) {
        return $null
    }

    $relPath = Resolve-Path -Path $File.FullName -Relative
    if ([string]::IsNullOrWhiteSpace($relPath)) {
        return $relPath
    }

    return ($relPath -replace '/', '\')
}

function Test-BlueprintPeripheralFile {
    param([string]$LeafName)

    if ([string]::IsNullOrWhiteSpace($LeafName)) {
        return $true
    }

    if ($LeafName -match '(?i)\.(test|spec|stories|story|mock|stub|fake|fixture|bench|snapshot)\b') {
        return $true
    }

    if ($LeafName -match '(?i)^(test_|spec_|__test|__spec|__mock)') {
        return $true
    }

    if ($LeafName -match '(?i)\.(module\.css|module\.scss|styles|styled|theme|animation)\b') {
        return $true
    }

    if ($LeafName -match '(?i)^(migration|seed|fixture|changelog|license)') {
        return $true
    }

    if ($LeafName -match '(?i)\.(generated|auto|g|designer)\.[^.]+$') {
        return $true
    }

    return $false
}

function Get-BlueprintContractBucket {
    param([System.IO.FileInfo]$File)

    if ($null -eq $File) {
        return $null
    }

    if ($script:SignatureExtensions -notcontains $File.Extension) {
        return $null
    }

    $relPath = (Get-NormalizedRelativeProjectPath -File $File).ToLowerInvariant()
    $leafName = $File.Name.ToLowerInvariant()
    $baseName = $File.BaseName.ToLowerInvariant()

    if ($File.Extension -in @('.cmd', '.bat', '.reg', '.vbs', '.ps1xml')) {
        return $null
    }

    if (Test-BlueprintPeripheralFile -LeafName $leafName) {
        return $null
    }

    # --- VibeToolkit-specific rules (preserved) ---

    if ($relPath -match '^\.\\project-bundler(?:-headless)?\.ps1$') {
        return 'ENTRYPOINTS & ORCHESTRATION'
    }

    if ($relPath -match '^\.\\modules\\.*protocol.*\.psm1$') {
        return 'PROTOCOLS & OPERATING RULES'
    }

    if ($relPath -match '^\.\\modules\\.*(discovery|writer|extractor).*\.psm1$') {
        return 'DISCOVERY, WRITERS & EXTRACTORS'
    }

    if ($relPath -match '^\.\\modules\\.*(bundle|artifact|context|execution|route|naming).*\.psm1$') {
        return 'CORE MODULES'
    }

    if ($relPath -match '^\.\\modules\\.*\.psm1$' -and $leafName -notmatch '^(sentinelui|sentineltheme|sentinelclonehelpers)\.psm1$') {
        return 'CORE MODULES'
    }

    # --- Generic entrypoints & roots (stack-agnostic) ---

    if ($relPath -match '^\.\\(?:main|index|app|server|program|startup|host|root|bootstrap|entrypoint)\.(?:ts|tsx|js|jsx|mjs|py|go|rs|cs|java|kt|php|rb|ex|swift|dart|scala)$') {
        return 'APPLICATION ENTRYPOINTS'
    }

    if ($relPath -match '^\.\\(?:src|app|server|api|lib|core)\\(?:main|index|app|server|program|startup|host|root|bootstrap|entrypoint)\.[^.]+$') {
        return 'APPLICATION ENTRYPOINTS'
    }

    # --- Contracts, types, schemas, DTOs, enums, protocols (stack-agnostic) ---

    if ($baseName -match '(?:^|[._-])(?:types|interfaces|contracts|schemas|models|dtos|entities|enums|protocols|events|constants|definitions|declarations)(?:$|[._-])') {
        return 'CONTRACTS & TYPES'
    }

    if ($relPath -match '[\\/](?:types|interfaces|contracts|schemas|models|dtos|entities|enums|protocols|events|definitions)[\\/]') {
        return 'CONTRACTS & TYPES'
    }

    if ($leafName -match '(?i)\.d\.ts$') {
        return 'CONTRACTS & TYPES'
    }

    # --- Integrations & boundaries (stack-agnostic) ---

    if ($baseName -match '(?:^|[._-])(?:client|service|provider|gateway|repository|adapter|transport|connector|proxy|driver|api[._-]?client|http[._-]?client|grpc[._-]?client)(?:$|[._-])') {
        return 'INTEGRATIONS & BOUNDARIES'
    }

    if ($baseName -match '(?:^|[._-])(?:auth|storage|database|cache|queue|messaging|notification|email|payment|search)[._-]?(?:service|client|provider|gateway|repository|adapter|boundary)(?:$|[._-])') {
        return 'INTEGRATIONS & BOUNDARIES'
    }

    if ($relPath -match '[\\/](?:services|providers|gateways|repositories|adapters|clients|infrastructure|integrations|boundaries)[\\/]') {
        return 'INTEGRATIONS & BOUNDARIES'
    }

    # --- Flow orchestrators (stack-agnostic) ---

    if ($baseName -match '(?:^|[._-])(?:store|state|context|session|middleware|pipeline|runtime|orchestrat|coordinat|dispatcher|controller|handler|resolver|interceptor|guard|router|routes|navigation|bus|queue|worker|scheduler|registry|factory|container|injector|compositor|manager|engine)(?:$|[._-])') {
        return 'FLOW ORCHESTRATORS'
    }

    if ($relPath -match '[\\/](?:stores|state|middleware|controllers|handlers|resolvers|interceptors|guards|routes|routing|orchestration|coordination|dispatchers|pipelines|workers|schedulers)[\\/]') {
        return 'FLOW ORCHESTRATORS'
    }

    # --- Domain core modules (position-based, stack-agnostic) ---

    if ($relPath -match '^\.\\(?:src|app|lib|core|pkg|internal|domain)\\[^\\/]+\.(?:ts|tsx|js|jsx|mjs|py|go|rs|cs|java|kt|php|rb|ex|swift|dart|scala|psm1|ps1)$') {
        if ($baseName -notmatch '(?:^|[._-])(?:utils?|helpers?|tools|common|shared|misc|log|logger|debug|polyfill|shim|patch|compat|i18n|locale|env|setup|teardown|init|cleanup)(?:$|[._-])') {
            return 'DOMAIN CORE'
        }
    }

    return $null
}

function Get-BlueprintContractEntries {
    param([System.IO.FileInfo[]]$Files)

    if ($null -eq $Files -or $Files.Count -eq 0) {
        return @()
    }

    $bucketOrder = @{
        'ENTRYPOINTS & ORCHESTRATION' = 0
        'APPLICATION ENTRYPOINTS' = 1
        'PROTOCOLS & OPERATING RULES' = 2
        'CONTRACTS & TYPES' = 3
        'INTEGRATIONS & BOUNDARIES' = 4
        'FLOW ORCHESTRATORS' = 5
        'DISCOVERY, WRITERS & EXTRACTORS' = 6
        'CORE MODULES' = 7
        'DOMAIN CORE' = 8
    }

    $bucketCap = @{
        'APPLICATION ENTRYPOINTS' = 6
        'CONTRACTS & TYPES' = 8
        'INTEGRATIONS & BOUNDARIES' = 8
        'FLOW ORCHESTRATORS' = 6
        'DOMAIN CORE' = 6
    }

    $entries = New-Object System.Collections.Generic.List[object]

    foreach ($file in $Files) {
        $bucket = Get-BlueprintContractBucket -File $file
        if ([string]::IsNullOrWhiteSpace($bucket)) {
            continue
        }

        $relPath = Get-NormalizedRelativeProjectPath -File $file
        $order = if ($bucketOrder.ContainsKey($bucket)) { $bucketOrder[$bucket] } else { 999 }

        $entries.Add([pscustomobject]@{
            File = $file
            RelativePath = $relPath
            Bucket = $bucket
            BucketOrder = $order
        }) | Out-Null
    }

    $sorted = @($entries | Sort-Object BucketOrder, RelativePath -Unique)

    $bucketCounts = @{}
    $result = @($sorted | Where-Object {
        $b = $_.Bucket
        if (-not $bucketCounts.ContainsKey($b)) {
            $bucketCounts[$b] = 0
        }
        $cap = if ($bucketCap.ContainsKey($b)) { $bucketCap[$b] } else { 999 }
        if ($bucketCounts[$b] -lt $cap) {
            $bucketCounts[$b]++
            $true
        }
        else {
            $false
        }
    })

    return $result
}

function New-BlueprintContractsBlock {
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
        $structureLines.Add((Get-NormalizedRelativeProjectPath -File $file)) | Out-Null
    }

    $block = "${StructureHeading}`n"
    $block += (Convert-ToSafeMarkdownCodeBlock -Content ($structureLines -join "`n") -Language 'text')
    $block += "`n`n"
    $block += "${ContractsHeading}`n"
    $block += "> Cobertura abrangente de superfícies estruturais. Todos os arquivos elegíveis do escopo visível que possuem assinaturas extraíveis (contratos, headers, exports, tipos) estão mapeados abaixo. O blueprint preserva contexto mantendo a economia ao focar exclusivamente na extração estrutural, omitindo implementação completa.`n`n"
    
    $hasContracts = $false
    
    $processedCount = 0
    foreach ($file in $Files) {
        $processedCount++
        if ($script:SignatureExtensions -notcontains $file.Extension) {
            continue
        }
        
        $relPath = Get-NormalizedRelativeProjectPath -File $file
        
        if ($LogExtraction) {
            Write-SentinelProgress -Activity 'Extraindo assinaturas estruturais' -Current $processedCount -Total $Files.Count -Tone 'Secondary' -Item $relPath
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
        
        $hasContracts = $true
        $fenceLanguage = Get-CodeFenceLanguageFromExtension -Extension $file.Extension
        $signatureContent = ($signatures -join '')
        $block += "#### File: $relPath`n"
        $block += (Convert-ToSafeMarkdownCodeBlock -Content $signatureContent -Language $fenceLanguage)
        $block += "`n`n"
    }

    if (-not $hasContracts) {
        $block += "_Nenhuma assinatura ou contrato central foi identificado no recorte visível._`n`n"
    }

    if ($LogExtraction) { Write-Host "" }

    return $block
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

    $processedCount = 0
    foreach ($file in $Files) {
        $processedCount++
        if ($script:SignatureExtensions -notcontains $file.Extension) {
            continue
        }

        $relPath = Resolve-Path -Path $file.FullName -Relative
        if ($LogExtraction) {
            Write-SentinelProgress -Activity 'Extraindo assinaturas' -Current $processedCount -Total $Files.Count -Tone 'Secondary' -Item $relPath
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

    if ($LogExtraction) { Write-Host "" }

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

    if ($ExtractionMode -eq 'blueprint') {
        return 'blueprint'
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

function Get-SentinelCompactDisplayText {
    param(
        [AllowEmptyString()][string]$Text = '',
        [int]$MaxLength = 72
    )

    $value = if ($null -eq $Text) { '' } else { [string]$Text }
    if ([string]::IsNullOrWhiteSpace($value)) {
        return ''
    }

    $safeMaxLength = [Math]::Max($MaxLength, 12)
    if ($value.Length -le $safeMaxLength) {
        return $value
    }

    if ($safeMaxLength -le 3) {
        return '...'
    }

    $headLength = [Math]::Max([int][Math]::Floor(($safeMaxLength - 1) * 0.55), 8)
    $tailLength = [Math]::Max(($safeMaxLength - 1) - $headLength, 4)

    if (($headLength + $tailLength + 1) -gt $safeMaxLength) {
        $tailLength = [Math]::Max(($safeMaxLength - $headLength - 1), 1)
    }

    return ('{0}…{1}' -f $value.Substring(0, $headLength), $value.Substring($value.Length - $tailLength))
}

function Get-SentinelConsoleMultiSelectHintLines {
    param([AllowEmptyString()][string]$Hint = '')

    $normalizedHint = (($Hint -replace '\s+', ' ').Trim()).ToUpperInvariant()
    $defaultHints = @(
        '↑↓ NAVEGAR ESPACO MARCAR/DESMARCAR A TODOS N NENHUM ENTER CONFIRMAR Q CANCELAR',
        '↑↓ NAVEGAR ESPAÇO MARCAR/DESMARCAR A TODOS N NENHUM ENTER CONFIRMAR Q CANCELAR'
    )

    if ($defaultHints -contains $normalizedHint) {
        return @(
            '  ↑↓ mover · PgUp/PgDn página · Home/End extremos',
            '  Espaço marca · Enter confirma · A todos · N nenhum · Q/Esc sai'
        )
    }

    if ([string]::IsNullOrWhiteSpace($Hint)) {
        return @()
    }

    return @('  ' + ($Hint -replace '\s+', ' ').Trim())
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
        $windowWidth = 100
        try {
            $windowHeight = [Math]::Max([Console]::WindowHeight, 18)
            $windowWidth = [Math]::Max([Console]::WindowWidth, 80)
        }
        catch {
            $windowHeight = 24
            $windowWidth = 100
        }

        $pageSize = [Math]::Max(8, $windowHeight - 16)
        $contentWidth = [Math]::Max(($windowWidth - 8), 28)
        $itemTextWidth = [Math]::Max(($contentWidth - 8), 20)

        if ($currentIndex -lt $offset) {
            $offset = $currentIndex
        }

        if ($currentIndex -ge ($offset + $pageSize)) {
            $offset = $currentIndex - $pageSize + 1
        }

        Clear-Host
        Write-Host ''
        Write-SentinelDivider -Label 'SNIPER' -Tone 'Warning'
        Write-Host ('  {0}' -f $Title) -ForegroundColor Cyan
        Write-SentinelBadgeLine -Badges @(
            (Format-SentinelBadge -Label 'INTERATIVO' -Tone 'Warning'),
            (Format-SentinelBadge -Label 'MULTISELECT' -Tone 'Secondary')
        )

        foreach ($hintLine in @(Get-SentinelConsoleMultiSelectHintLines -Hint $Hint)) {
            Write-Host $hintLine -ForegroundColor DarkGray
        }

        Write-SentinelDivider -Tone 'Secondary'
        Write-Host ''

        $endIndex = [Math]::Min($Items.Count - 1, $offset + $pageSize - 1)
        if ($offset -gt 0) {
            Write-Host ('  … itens anteriores: {0}' -f $offset) -ForegroundColor DarkGray
        }

        for ($i = $offset; $i -le $endIndex; $i++) {
            $item = $Items[$i]
            $isCurrent = ($i -eq $currentIndex)
            $isSelected = $selected.ContainsKey($item)
            $cursor = if ($isCurrent) { '>' } else { ' ' }
            $mark = if ($isSelected) { '[x]' } else { '[ ]' }
            $displayItem = Get-SentinelCompactDisplayText -Text $item -MaxLength $itemTextWidth
            $lineColor = if ($isCurrent) { 'Cyan' } elseif ($isSelected) { 'Gray' } else { 'Gray' }
            $markColor = if ($isSelected) { 'Green' } else { 'DarkGray' }
            $cursorColor = if ($isCurrent) { 'Cyan' } else { 'DarkGray' }

            Write-Host '  ' -NoNewline
            Write-Host $cursor -ForegroundColor $cursorColor -NoNewline
            Write-Host ' ' -NoNewline
            Write-Host $mark -ForegroundColor $markColor -NoNewline
            Write-Host ' ' -NoNewline
            Write-Host $displayItem -ForegroundColor $lineColor
        }

        if ($endIndex -lt ($Items.Count - 1)) {
            Write-Host ('  … itens seguintes: {0}' -f ($Items.Count - $endIndex - 1)) -ForegroundColor DarkGray
        }

        Write-Host ''
        Write-SentinelDivider -Tone 'Muted'
        Write-Host ('  Marcados : {0}/{1}' -f $selected.Count, $Items.Count) -ForegroundColor Yellow
        Write-Host ('  Exibindo : {0}-{1} de {2}' -f ($offset + 1), ($endIndex + 1), $Items.Count) -ForegroundColor DarkGray
        Write-Host ('  Atual    : {0} de {1}' -f ($currentIndex + 1), $Items.Count) -ForegroundColor DarkGray

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
                    Write-SentinelStatus -Message 'Selecione pelo menos um item antes de confirmar.' -Type Warning
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

    Write-SentinelSection -Title 'Seleção manual do modo Sniper' -Subtitle 'Informe um ou mais caminhos relativos ou absolutos separados por ;' -Tone 'Warning'
    $sniperPreviewLines = New-Object System.Collections.Generic.List[string]
    $sniperPreviewLines.Add('Pode ser arquivo ou diretório.') | Out-Null
    foreach ($previewFile in ($relativeOptions | Select-Object -First 20)) {
        $sniperPreviewLines.Add('- ' + $previewFile) | Out-Null
    }
    if ($relativeOptions.Count -gt 20) {
        $sniperPreviewLines.Add('... e mais ' + ($relativeOptions.Count - 20) + ' arquivo(s).') | Out-Null
    }
    Write-SentinelPanel -Title 'Arquivos elegíveis detectados (prévia)' -Tone 'Secondary' -Lines ($sniperPreviewLines.ToArray())

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

    $visibleArtifactHeading = if ($ExtractionMode -eq 'blueprint') { '## BLUEPRINT VISÍVEL' } else { '## BUNDLE VISÍVEL' }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('## ATIVAÇÃO OPERACIONAL LOCAL — DIRETOR v4.0') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('### MODO ATIVO') | Out-Null
    $lines.Add('- Assuma imediatamente o modo Diretor. Este documento contém regras operacionais ativas, não texto informativo.') | Out-Null
    $lines.Add('- Papel obrigatório durante toda a resposta: Diretor de Engenharia Agêntica em modo determinístico local.') | Out-Null
    $lines.Add('- Rota ativa: VIA DIRETOR.') | Out-Null
    $lines.Add(("- Extração efetiva: {0}." -f $extractionLabel)) | Out-Null
    $lines.Add(("- Executor alvo de referência: {0}." -f $ExecutorTargetValue)) | Out-Null
    $lines.Add('- Fronteira de execução: não implementar código diretamente.') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('### ORDEM OBRIGATÓRIA DE LEITURA') | Out-Null
    $lines.Add('1. Ler primeiro `PROJECT STRUCTURE` do artefato fonte.') | Out-Null
    $lines.Add('2. Assimilar apenas as pastas, arquivos e limites realmente visíveis.') | Out-Null
    $lines.Add('3. Ler depois `SOURCE FILES` do mesmo artefato.') | Out-Null
    $lines.Add('4. Só então analisar, responder e compor instruções para o Executor.') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('### FONTE PRIMÁRIA E RESTRIÇÕES OBRIGATÓRIAS') | Out-Null
    $lines.Add(("- Artefato fonte obrigatório: {0}." -f $SourceArtifactFileName)) | Out-Null
    $lines.Add('- O artefato visível é a única fonte primária obrigatória.') | Out-Null
    $lines.Add('- Não usar memória anterior, contexto implícito, seleção remota ou comportamento presumido fora do artefato.') | Out-Null
    $lines.Add('- Quando faltar contexto, declarar explicitamente `não visível no recorte enviado`.') | Out-Null
    $lines.Add('- Recortes prioritários para leitura após a estrutura: ' + $relevantFilesValue + '.') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('## EXECUTION META') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add(("- Projeto: {0}" -f $ProjectNameValue)) | Out-Null
    $lines.Add(("- Artefato fonte: {0}" -f $SourceArtifactFileName)) | Out-Null
    $lines.Add(("- Artefato final: {0}" -f $OutputArtifactFileName)) | Out-Null
    $lines.Add(("- Executor alvo: {0}" -f $ExecutorTargetValue)) | Out-Null
    $lines.Add('- Route mode: director') | Out-Null
    $lines.Add(("- Document mode: {0}" -f $DocumentMode)) | Out-Null
    $lines.Add(("- Gerado em: {0}" -f $generatedAt)) | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('[META-PROMPT PARA EXECUTOR]') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('## PROMPT PARA O EXECUTOR (COPIAR ABAIXO)') | Out-Null
    $lines.Add('--- INÍCIO DO PROMPT ---') | Out-Null
    $lines.Add('## ATIVAÇÃO OPERACIONAL LOCAL — EXECUTOR v4.0') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('### MODO ATIVO') | Out-Null
    $lines.Add('- Assuma imediatamente o modo Executor. Este prompt contém regras operacionais ativas, não texto informativo.') | Out-Null
    $lines.Add('- Papel obrigatório durante toda a resposta: Senior Implementation Agent (Sniper).') | Out-Null
    $lines.Add('- Missão: materializar a solicitação estritamente dentro do escopo visível do bundle.') | Out-Null
    $lines.Add(("- Extraction mode: {0}." -f $ExtractionMode)) | Out-Null
    $lines.Add(("- Executor alvo: {0}." -f $ExecutorTargetValue)) | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('### ORDEM OBRIGATÓRIA DE LEITURA') | Out-Null
    $lines.Add('1. Ler primeiro `PROJECT STRUCTURE` do bundle visível.') | Out-Null
    $lines.Add('2. Assimilar apenas as pastas, arquivos e limites realmente visíveis.') | Out-Null
    $lines.Add('3. Ler depois `SOURCE FILES`.') | Out-Null
    $lines.Add('4. Só então iniciar análise de impacto, implementação e resposta técnica.') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('### RESTRIÇÕES OBRIGATÓRIAS') | Out-Null
    $lines.Add('- O bundle visível é a única fonte primária obrigatória.') | Out-Null
    $lines.Add('- Não inferir módulos, contratos, dependências ou comportamentos fora do bundle visível.') | Out-Null
    $lines.Add('- Declarar explicitamente qualquer lacuna de contexto com `não visível no recorte enviado`.') | Out-Null
    $lines.Add('- Aplicar Lei da Subtração antes de adicionar novo código.') | Out-Null
    $lines.Add('- Preservar contratos, nomes, comportamento existente e compatibilidade com o fluxo atual.') | Out-Null
    $lines.Add('- Não usar memória anterior reaproveitada, seleção remota, parametrização externa ou qualquer superfície de IA removida.') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('### SAÍDA OBRIGATÓRIA') | Out-Null
    $lines.Add('- Entregar Relatório de Impacto, implementação por arquivo, protocolo de verificação e verificação de segurança.') | Out-Null
    $lines.Add('- Propor checks de regressão, cenários negativos e validações compatíveis com o escopo.') | Out-Null
    $lines.Add('--- FIM DO PROMPT ---') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add($visibleArtifactHeading) | Out-Null
    $lines.Add('') | Out-Null
    
    $croppedContent = $BundleContent
    if (-not [string]::IsNullOrWhiteSpace($croppedContent)) {
        $structuralAnchors = @(
            '### 1. PROJECT STRUCTURE',
            '### 2. PROJECT STRUCTURE',
            '### PROJECT STRUCTURE (BUNDLER)',
            '### PROJECT STRUCTURE',
            '## 1. PROJECT STRUCTURE',
            '## 2. PROJECT STRUCTURE',
            '## PROJECT STRUCTURE'
        )

        foreach ($anchor in $structuralAnchors) {
            $idx = $croppedContent.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase)
            if ($idx -ge 0) {
                $croppedContent = $croppedContent.Substring($idx)
                break
            }
        }
    }

    # Limpar as costuras internas (fences vazios ou nomeados) para envelopar em um único fence coerente
    $cleanContent = [regex]::Replace($croppedContent, '(?m)^[ \t]*```+[a-zA-Z0-9\-\+]*[ \t]*\r?\n?', '')

    $lines.Add((Convert-ToSafeMarkdownCodeBlock -Content (Format-BundleContentForDiff -Content $cleanContent) -Language 'text')) | Out-Null

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

    $isWindowsFlag = $false
    try {
        if (Test-Path variable:IsWindows) {
            $isWindowsFlag = [bool]$IsWindows
        }
        else {
            $isWindowsFlag = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
        }
    }
    catch {
        $isWindowsFlag = $false
    }

    return [ordered]@{
        osVersion = [System.Environment]::OSVersion.VersionString
        psVersion = $psVersion
        isWindows = $isWindowsFlag
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
    param(
        [string]$BaseDirectory,
        [string]$ProjectNameValue,
        [string]$RouteMode
    )

    $resolvedBaseDirectory = [System.IO.Path]::GetFullPath($BaseDirectory)

    if ([string]::IsNullOrWhiteSpace($resolvedBaseDirectory) -or -not (Test-Path $resolvedBaseDirectory -PathType Container)) {
        throw "Diretório base inválido para o artefato final TXT Export: $BaseDirectory"
    }

    $artifactFileName = Get-VibeArtifactFileName -ProjectNameValue $ProjectNameValue -ExtractionMode 'txt_export' -RouteMode $RouteMode -Extension '.zip'
    $candidate = Join-Path $resolvedBaseDirectory $artifactFileName
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($artifactFileName)
    $suffix = 2

    while (Test-Path $candidate) {
        $candidate = Join-Path $resolvedBaseDirectory ("{0}__{1}.zip" -f $baseName, $suffix)
        $suffix++
    }

    return $candidate
}

function New-TxtExportZipArchive {
    param(
        [string]$OutputDirectory,
        [string]$BaseDirectory,
        [string]$ProjectNameValue,
        [string]$RouteMode
    )

    if ([string]::IsNullOrWhiteSpace($OutputDirectory) -or -not (Test-Path $OutputDirectory -PathType Container)) {
        throw "Diretório de staging do TXT Export inválido para compactação: $OutputDirectory"
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $zipFilePath = New-TxtExportZipFilePath -BaseDirectory $BaseDirectory -ProjectNameValue $ProjectNameValue -RouteMode $RouteMode
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $OutputDirectory,
        $zipFilePath,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false
    )

    return $zipFilePath
}

function Remove-TxtExportOutputDirectory {
    param([string]$OutputDirectory)

    if ([string]::IsNullOrWhiteSpace($OutputDirectory) -or -not (Test-Path $OutputDirectory -PathType Container)) {
        return $false
    }

    Remove-Item -Path $OutputDirectory -Recurse -Force -ErrorAction Stop
    return $true
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
        [string]$ProjectNameValue,
        [string]$RouteMode
    )

    $outputDirectory = New-TxtExportOutputDirectory -BaseDirectory $BaseOutputDirectory -ProjectNameValue $ProjectNameValue
    $exportedFiles = New-Object System.Collections.Generic.List[string]
    $skippedFiles = New-Object System.Collections.Generic.List[string]

    for ($index = 0; $index -lt $Files.Count; $index++) {
        $sourceFile = $Files[$index]
        $sourcePathVisual = if ($sourceFile -is [System.IO.FileInfo]) { $sourceFile.FullName } else { [string]$sourceFile }
        Write-SentinelProgress -Activity 'TXT Export' -Current ($index + 1) -Total $Files.Count -Tone 'Secondary' -Item $sourcePathVisual
        try {
            $sourcePath = if ($sourceFile -is [System.IO.FileInfo]) { $sourceFile.FullName } else { [string]$sourceFile }
            if ([string]::IsNullOrWhiteSpace($sourcePath) -or -not (Test-Path $sourcePath -PathType Leaf)) {
                Write-Host ""
                Write-UILog -Message "TXT Export ignorado: arquivo não encontrado -> $sourcePath" -Color $ThemeWarn
                $skippedFiles.Add([string]$sourcePath) | Out-Null
                continue
            }

            $resolvedSource = (Resolve-Path $sourcePath).Path

            if (Test-IsLikelyBinaryFile -FilePath $resolvedSource) {
                Write-Host ""
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
        }
        catch {
            Write-Host ""
            $failedPath = if ($sourceFile -is [System.IO.FileInfo]) { $sourceFile.FullName } else { [string]$sourceFile }
            Write-UILog -Message "Falha ao exportar TXT: $failedPath :: $($_.Exception.Message)" -Color $ThemePink
            $skippedFiles.Add([string]$failedPath) | Out-Null
        }
    }
    
    Write-Host ""

    try {
        $zipFilePath = New-TxtExportZipArchive -OutputDirectory $outputDirectory -BaseDirectory $BaseOutputDirectory -ProjectNameValue $ProjectNameValue -RouteMode $RouteMode
    }
    catch {
        throw "Falha ao criar o artefato final do TXT Export: $($_.Exception.Message)"
    }

    try {
        $stagingRemoved = Remove-TxtExportOutputDirectory -OutputDirectory $outputDirectory
        if (-not $stagingRemoved) {
            throw "Diretório de staging não encontrado para remoção: $outputDirectory"
        }
    }
    catch {
        throw "Artefato final do TXT Export criado em '$zipFilePath', mas não foi possível remover o staging interno '$outputDirectory': $($_.Exception.Message)"
    }

    return [pscustomobject]@{
        StagingDirectory = $outputDirectory
        StagingDirectoryRemoved = $stagingRemoved
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

    Write-SentinelSection -Title 'ETAPA 2/3 · Extração' -Tone 'Primary'
    Write-SentinelMenuOptions -Options @(
        (New-SentinelMenuOptionLine -Label 'Full' -Description 'análise completa' -LabelWidth 14),
        (New-SentinelMenuOptionLine -Label 'Blueprint' -Description 'estrutura e contratos' -LabelWidth 14),
        (New-SentinelMenuOptionLine -Label 'Sniper' -Description 'recorte manual cirúrgico' -LabelWidth 14),
        (New-SentinelMenuOptionLine -Label 'TXT Export' -Description 'zip com .txt' -LabelWidth 14)
    )

    $resolved = $null
    while ($null -eq $resolved) {
        $inp = (Read-Host '  Escolha a extração [1-4]').Trim()
        switch ($inp) {
            '1' { $resolved = 'full' }
            '2' { $resolved = 'blueprint' }
            '3' { $resolved = 'sniper' }
            '4' { $resolved = 'txtExport' }
            default { Write-SentinelStatus -Message 'Entrada inválida. Escolha entre 1 e 4.' -Type Warning }
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

    Write-SentinelSection -Title 'ETAPA 3/3 · Rota' -Tone 'Primary'
    Write-SentinelMenuOptions -Options @(
        (New-SentinelMenuOptionLine -Label 'Diretor' -Description 'gera meta-prompt local   ← padrão' -LabelWidth 14),
        (New-SentinelMenuOptionLine -Label 'Executor' -Description 'gera contexto final' -LabelWidth 14)
    )

    $resolved = $null
    while ($null -eq $resolved) {
        $inp = (Read-Host '  Escolha a rota [1-2] (padrão: 1)').Trim()
        if ([string]::IsNullOrWhiteSpace($inp)) { $inp = '1' }
        switch ($inp) {
            '1' { $resolved = 'director' }
            '2' { $resolved = 'executor' }
            default { Write-SentinelStatus -Message 'Entrada inválida. Escolha 1 ou 2.' -Type Warning }
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

    $originPreview = $DefaultPath
    try {
        $originPreview = [System.IO.Path]::GetFullPath((Resolve-Path -Path $DefaultPath -ErrorAction Stop).Path)
    }
    catch {
        $originPreview = $DefaultPath
    }

    Write-SentinelSection -Title 'ETAPA 1/3 · Origem' -Tone 'Primary'
    Write-SentinelKeyValue -Key 'Path atual' -Value $originPreview -Tone 'Secondary' -KeyWidth 14
    Write-Host ''
    Write-SentinelMenuOptions -Options @(
        (New-SentinelMenuOptionLine -Label 'Path atual' -Description 'diretório informado' -LabelWidth 14),
        (New-SentinelMenuOptionLine -Label 'Clonar GitHub' -Description 'clonagem local/interativa' -LabelWidth 14)
    )

    $choice = $null
    while ($choice -notin @('1', '2')) {
        $choice = (Read-Host '  Escolha a origem [1-2]').Trim()
        if ($choice -notin @('1', '2')) {
            Write-SentinelStatus -Message 'Entrada inválida. Escolha 1 ou 2.' -Type Warning
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

    Write-SentinelSection -Title 'ETAPA 1.1 · Clonagem GitHub' -Tone 'Primary'

    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) {
        throw 'Git não está instalado ou não está disponível no PATH. A clonagem de repositórios GitHub requer o Git.'
    }

    $repoUrl = $null
    while ([string]::IsNullOrWhiteSpace($repoUrl)) {
        $repoUrl = (Read-Host '  URL do repositório GitHub (ex: https://github.com/user/repo.git)').Trim()
        if ([string]::IsNullOrWhiteSpace($repoUrl)) {
            Write-SentinelStatus -Message 'URL não pode ser vazia.' -Type Warning
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
                Write-SentinelStatus -Message 'Caminho não pode ser vazio.' -Type Warning
                continue
            }
            try {
                $resolvedManual = [System.IO.Path]::GetFullPath($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($manualPath))
            }
            catch {
                Write-SentinelStatus -Message 'Caminho inválido. Tente novamente.' -Type Warning
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
    '.gradle', '.sln', '.csproj', '.vbproj', '.fsproj', '.vcxproj', '.filters', '.reg', '.vbs'
)

$script:SignatureExtensions = @(
    '.tsx', '.ts', '.js', '.jsx', '.mjs', '.cjs', '.mts', '.cts', '.vue', '.svelte', '.astro',
    '.py', '.pyi', '.java', '.cs', '.vb', '.fs', '.fsi', '.fsx', '.c', '.cpp', '.cc', '.cxx', '.h', '.hh', '.hpp', '.hxx',
    '.go', '.rb', '.php', '.phtml', '.rs', '.swift', '.kt', '.kts', '.scala', '.dart', '.r', '.lua',
    '.pl', '.pm', '.jl', '.zig', '.nim', '.elm', '.ex', '.exs', '.erl', '.hrl', '.clj', '.cljs', '.cljc', '.edn', '.ml', '.mli',
    '.sh', '.bash', '.zsh', '.fish', '.ksh', '.bat', '.cmd', '.ps1', '.psm1', '.psd1', '.ps1xml',
    '.sql', '.prisma', '.graphql', '.gql', '.proto', '.tf', '.tfvars', '.hcl', '.bicep',
    '.cshtml', '.razor', '.xaml', '.xml', '.gradle', '.sln', '.csproj', '.vbproj', '.fsproj', '.vcxproj', '.props', '.targets', '.reg', '.vbs'
)

$script:IgnoredDirs = @(
    'node_modules', '.git', 'dist', 'build', '.next', '.cache', 'out',
    'coverage', '.venv', 'venv', 'env', '__pycache__', '.pytest_cache', '.tox',
    'bin', 'obj', 'target', 'vendor', '.agent', '.github', '.vite', 'android'
)

$script:IgnoredFiles = @(
    'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock',
    '.DS_Store', 'metadata.json', '.gitignore',
    'capacitor.plugins.json', 'cordova.js', 'cordova_plugins.js',
    'poetry.lock', 'Pipfile.lock', 'Cargo.lock', 'go.sum', 'composer.lock'
)

Register-SentinelCliFallback

try {
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
            Write-SentinelStatus -Message 'SentinelUI bloqueado por assinatura/execution policy. Ativando fallback textual para o modo headless.' -Type Warning
            Write-SentinelPanel -Title 'Resumo do bootstrap' -Tone 'Warning' -Lines @($sentinelFailureSummary)
        }
        else {
            $sentinelFailureSummary = Get-SentinelUiBootstrapFailureSummary -ErrorRecord $sentinelBootstrapFailure
            throw "Falha estrutural ao carregar biblioteca de UI '$SentinelUiPath'. $sentinelFailureSummary"
        }
    }

    Assert-SentinelUiBootstrapContract -SentinelUiPath $SentinelUiPath -FallbackActive:$sentinelUiFallbackActive

    Write-SentinelHeader -Title 'SENTINEL HEADLESS' -Version 'v2.0.0' -Variant 'Compact'
    if ($sentinelUiFallbackActive) {
        Write-UILog -Message 'Bootstrap headless carregado com fallback textual de console.' -Color $ThemeWarn
    }
    else {
        Write-UILog -Message 'Bootstrap headless carregado.' -Color $ThemeSuccess
    }

    Write-SentinelKeyValue -Key 'Projeto' -Value $Path -Tone 'Primary' -KeyWidth 14
    Write-SentinelKeyValue -Key 'Executor' -Value $ExecutorTarget -Tone 'Primary' -KeyWidth 14
    Write-Host ''

    $sourceResult = Resolve-ProjectSource -DefaultPath $Path -NonInteractive:$NonInteractive
    $resolvedTargetPath = $sourceResult.ResolvedPath
    $sourceMode = $sourceResult.SourceMode
    $originalInput = $sourceResult.OriginalInput
    $script:CloneCleanupInfo = $sourceResult.CloneCleanupInfo

    $script:EffectiveOutputDirectory = $resolvedTargetPath
    if ($sourceMode -eq 'github' -and $script:CloneCleanupInfo.CloneMode -eq 'temporary' -and -not $script:CloneCleanupInfo.KeepClone) {
        $script:EffectiveOutputDirectory = $script:OriginalWorkingDirectory.Path
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

    $executionStartedAt = Get-Date
    $resolvedBundleMode = Resolve-BundleMode -BundleMode $BundleMode -NonInteractive:$NonInteractive
    $resolvedRouteMode = Resolve-RouteMode -RouteMode $RouteMode -NonInteractive:$NonInteractive
    $choice = Resolve-ChoiceFromBundleMode -ModeValue $resolvedBundleMode
    $currentExtractionMode = Resolve-ExtractionModeFromBundleMode -ModeValue $resolvedBundleMode
    $currentDocumentMode = Resolve-DocumentModeFromExtractionMode -ExtractionMode $currentExtractionMode
    $isTxtExportMode = ($choice -eq '4')

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

    Write-SentinelOperationSummary -ProjectNameValue $projectName -BundleModeValue $resolvedBundleMode -RouteModeValue $resolvedRouteMode -ExecutorTargetValue $ExecutorTarget -OriginValue $resolvedTargetPath -EligibleCount $foundFiles.Count -OperationCount $filesToProcess.Count

    Write-SentinelExecutionStreamHeader -ChoiceValue $choice -ProjectNameValue $projectName -DiscoveredFileCount $foundFiles.Count -FilesToProcessCount $filesToProcess.Count -UnselectedFileCount $unselectedFiles.Count -EffectiveOutputDirectory $script:EffectiveOutputDirectory

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
        $txtExportResult = Export-OperationFilesToTxtDirectory -Files $filesToProcess -ProjectRootPath (Get-Location).Path -BaseOutputDirectory $script:EffectiveOutputDirectory -ProjectNameValue $projectName -RouteMode $resolvedRouteMode

        Write-UILog -Message ("Artefato final TXT Export: {0}" -f $txtExportResult.ZipFilePath) -Color $ThemeSuccess
        Write-UILog -Message ("Staging interno removido: {0}" -f $txtExportResult.StagingDirectory) -Color $ThemeSuccess
        Write-UILog -Message ("Arquivos exportados: {0}" -f $txtExportResult.ExportedFiles.Count) -Color $ThemeSuccess

        if ($txtExportResult.SkippedFiles.Count -gt 0) {
            Write-UILog -Message ("Arquivos ignorados por incompatibilidade/erro: {0}" -f $txtExportResult.SkippedFiles.Count) -Color $ThemeWarn
        }

        $extraData = $baseExtraData.Clone()
        $extraData.finalArtifactPath = $txtExportResult.ZipFilePath
        $extraData.zipFilePath = $txtExportResult.ZipFilePath
        $extraData.stagingDirectory = $txtExportResult.StagingDirectory
        $extraData.stagingDirectoryRemoved = $txtExportResult.StagingDirectoryRemoved
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
            $headerTitle = 'MODO FULL'
            Write-UILog -Message 'Iniciando Modo Full...' -Color $ThemeCyan
        }
        else {
            $sourceArtifactFileName = Get-VibeArtifactFileName -ProjectNameValue $projectName -ExtractionMode $currentExtractionMode -RouteMode $resolvedRouteMode
            $headerTitle = 'MODO SNIPER'
            Write-UILog -Message 'Iniciando Modo Sniper...' -Color $ThemePink
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
        for ($index = 0; $index -lt $filesToProcess.Count; $index++) {
            $file = $filesToProcess[$index]
            $relPath = Resolve-Path -Path $file.FullName -Relative
            Write-SentinelProgress -Activity 'Consolidação' -Current ($index + 1) -Total $filesToProcess.Count -Tone 'Secondary' -Item $relPath
            $content = Read-LocalTextArtifact -Path $file.FullName
            if ($null -ne $content) {
                $content = $content -replace "(`r?`n){3,}", "`r`n`r`n"
                $finalContent += "#### File: $relPath`n"
                $finalContent += (Convert-ToSafeMarkdownCodeBlock -Content $content.TrimEnd() -Language 'text') + "`n`n"
            }
        }
        Write-Host ""

        if ($choice -eq '3' -and $unselectedFiles.Count -gt 0) {
            Write-UILog -Message 'Anexando arquivos não selecionados (modo Bundler)...' -Color $ThemeCyan
            $finalContent += "## ARQUIVOS NÃO SELECIONADOS INSERIDOS EM MODO BUNDLER`n`n"
            $finalContent += New-BundlerContractsBlock -Files $unselectedFiles -IssueCollector ([ref]$blueprintIssues) -StructureHeading '### PROJECT STRUCTURE (BUNDLER)' -ContractsHeading '### CORE DOMAINS & CONTRACTS (BUNDLER)' -LogExtraction
        }
    }
    else {
        $sourceArtifactFileName = Get-VibeArtifactFileName -ProjectNameValue $projectName -ExtractionMode $currentExtractionMode -RouteMode $resolvedRouteMode
        Write-UILog -Message 'Iniciando Modo Blueprint...' -Color $ThemeCyan
        $finalContent += "## BLUEPRINT: $projectName`n`n"
        $finalContent += "### 0. BLUEPRINT CONTRACT`n"
        $finalContent += (Convert-ToSafeMarkdownCodeBlock -Content @'
Ler nesta ordem:
1. PROJECT STRUCTURE
2. CORE DOMAINS & CONTRACTS

Use apenas o recorte visível deste artefato.
Quando faltar contexto, declarar: não visível no recorte enviado.
A seção de contratos foi priorizada para entrypoints, contratos/tipos, integrações, orquestradores, protocolos, discovery, writers, extractors e módulos centrais de domínio.
'@.Trim() -Language 'text')
        $finalContent += "`n`n"
        $finalContent += "### 1. EXTERNAL DEPENDENCIES`n"

        $packageJsonPath = Join-Path (Get-Location).Path 'package.json'
        if (Test-Path $packageJsonPath -PathType Leaf) {
            try {
                Write-UILog -Message 'Lendo package.json para dependências externas do blueprint...'
                $pkg = (Read-LocalTextArtifact -Path $packageJsonPath) | ConvertFrom-Json
                $runtimeDeps = @()
                $devDeps = @()

                if ($pkg.dependencies) {
                    $runtimeDeps = @($pkg.dependencies.PSObject.Properties.Name | Sort-Object -Unique)
                }

                if ($pkg.devDependencies) {
                    $devDeps = @($pkg.devDependencies.PSObject.Properties.Name | Sort-Object -Unique)
                }

                if ($runtimeDeps.Count -gt 0) { $finalContent += "* **Runtime:** $(($runtimeDeps -join ', '))`n" }
                if ($devDeps.Count -gt 0) { $finalContent += "* **Dev:** $(($devDeps -join ', '))`n" }
                if ($runtimeDeps.Count -eq 0 -and $devDeps.Count -eq 0) { $finalContent += "* Nenhuma dependência declarada no package.json.`n" }
            }
            catch {
                Write-UILog -Message 'package.json existe, mas não pôde ser lido. Seguindo sem dependências externas declaradas.' -Color $ThemeWarn
                $finalContent += "* package.json presente, mas não legível no recorte local.`n"
            }
        }
        else {
            Write-UILog -Message 'package.json não encontrado; dependências externas serão omitidas do blueprint.' -Color $ThemeWarn
            $finalContent += "* package.json não visível no recorte local.`n"
        }

        $finalContent += "`n"
        $finalContent += New-BlueprintContractsBlock -Files $filesToProcess -IssueCollector ([ref]$blueprintIssues) -StructureHeading '### 2. PROJECT STRUCTURE' -ContractsHeading '### 3. CORE DOMAINS & CONTRACTS' -LogExtraction
    }

    $sourceArtifactPath = Join-Path $script:EffectiveOutputDirectory $sourceArtifactFileName
    Write-LocalTextArtifact -Path $sourceArtifactPath -Content $finalContent -UseBom
    $finalOutputPath = $sourceArtifactPath

    if ($resolvedRouteMode -eq 'director') {
        $deterministicOutputFile = Get-DeterministicMetaPromptOutputFileName -ProjectNameValue $projectName -ExtractionMode $currentExtractionMode -RouteMode $resolvedRouteMode
        $deterministicOutputPath = Join-Path $script:EffectiveOutputDirectory $deterministicOutputFile

        Write-UILog -Message 'Compilando meta-prompt determinístico local diretamente no bundler...' -Color $ThemeCyan
        $deterministicContent = New-DeterministicMetaPromptArtifact -ProjectNameValue $projectName -ExecutorTargetValue $ExecutorTarget -ExtractionMode $currentExtractionMode -DocumentMode $currentDocumentMode -SourceArtifactFileName $sourceArtifactFileName -OutputArtifactFileName $deterministicOutputFile -BundleContent $finalContent -Files $filesToProcess

        Write-LocalTextArtifact -Path $deterministicOutputPath -Content $deterministicContent -UseBom
        $finalOutputPath = $deterministicOutputPath

        Write-UILog -Message ("Meta-prompt salvo em: {0}" -f $deterministicOutputPath) -Color $ThemeSuccess
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
    $durationMs = [int][Math]::Round(((Get-Date) - $executionStartedAt).TotalMilliseconds)
    $extraData = $baseExtraData.Clone()
    $extraData.sourceArtifactFile = $sourceArtifactFileName
    $extraData.outputArtifactFile = [System.IO.Path]::GetFileName($finalOutputPath)
    $extraData.fileCount = $filesToProcess.Count
    $extraData.unselectedFileCount = $unselectedFiles.Count
    $extraData.generatedFromLocalGovernance = $true

    $resultMetaPath = Join-Path $script:EffectiveOutputDirectory ([System.IO.Path]::GetFileNameWithoutExtension($finalOutputPath) + '.json')
    $metaResult = Write-LocalExecutionMeta -ProjectNameValue $projectName -RouteMode $resolvedRouteMode -ExtractionMode $currentExtractionMode -DocumentMode $currentDocumentMode -ExecutorTargetValue $ExecutorTarget -SourceArtifactPath $sourceArtifactPath -OutputPath $finalOutputPath -ResultMetaPath $resultMetaPath -DurationMs $durationMs -ExtraData $extraData

    Write-Host ''
    Write-SentinelSection -Title 'SUCESSO' -Tone 'Success'
    $artifactName = [System.IO.Path]::GetFileName($finalOutputPath)
    $metaName = [System.IO.Path]::GetFileName($metaResult.ResultMetaPath)
    Write-SentinelKeyValue -Key 'Artefato' -Value $artifactName -Tone 'Success' -KeyWidth 12
    Write-SentinelKeyValue -Key 'Metadata' -Value $metaName -Tone 'Secondary' -KeyWidth 12
    Write-SentinelKeyValue -Key 'Destino' -Value $script:EffectiveOutputDirectory -Tone 'Secondary' -KeyWidth 12
    Write-Host ''
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