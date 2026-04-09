$script:SentinelEscape = [char]27

function Test-SentinelAnsiSupport {
    $isOutputRedirected = $false

    try {
        $isOutputRedirected = [Console]::IsOutputRedirected
    }
    catch {
        $isOutputRedirected = $false
    }

    if ($isOutputRedirected) {
        return $false
    }

    if (-not [string]::IsNullOrWhiteSpace($env:NO_COLOR) -and $env:NO_COLOR -ne '0') {
        return $false
    }

    try {
        if ($PSStyle -and $PSStyle.OutputRendering -eq 'PlainText') {
            return $false
        }
    }
    catch {
    }

    if (
        -not [string]::IsNullOrWhiteSpace($env:WT_SESSION) -or
        $env:TERM_PROGRAM -eq 'vscode' -or
        $env:ConEmuANSI -eq 'ON'
    ) {
        return $true
    }

    if (-not [string]::IsNullOrWhiteSpace($env:TERM) -and $env:TERM -ne 'dumb') {
        return $true
    }

    try {
        if ($Host.UI -and $Host.UI.SupportsVirtualTerminal) {
            return $true
        }
    }
    catch {
    }

    return $false
}

$script:SentinelAnsiEnabled = Test-SentinelAnsiSupport
$script:SentinelPlainGlyphs = @{
    Success = '[OK]'
    Info    = '[>>]'
    Warning = '[!!]'
    Error   = '[ER]'
}

$SentinelTheme = [ordered]@{
    Reset     = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[0m" } else { '' }
    Primary   = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;0;229;255m" } else { '' }
    Secondary = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;110;118;129m" } else { '' }
    Muted     = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;148;163;184m" } else { '' }
    Success   = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;34;197;94m" } else { '' }
    Warning   = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;245;158;11m" } else { '' }
    Error     = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;239;68;68m" } else { '' }
    Glyphs    = @{
        Success = if ($script:SentinelAnsiEnabled) { '✅' } else { $script:SentinelPlainGlyphs.Success }
        Info    = if ($script:SentinelAnsiEnabled) { '➤' } else { $script:SentinelPlainGlyphs.Info }
        Warning = if ($script:SentinelAnsiEnabled) { '⚠️' } else { $script:SentinelPlainGlyphs.Warning }
        Error   = if ($script:SentinelAnsiEnabled) { '❌' } else { $script:SentinelPlainGlyphs.Error }
    }
}

function Get-SentinelToneColor {
    param([string]$Tone = 'Primary')

    switch ($Tone) {
        'Success' { return $SentinelTheme.Success }
        'Warning' { return $SentinelTheme.Warning }
        'Error'   { return $SentinelTheme.Error }
        'Secondary' { return $SentinelTheme.Secondary }
        'Muted' { return $SentinelTheme.Muted }
        default { return $SentinelTheme.Primary }
    }
}

function Write-SentinelText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [string]$Color = $SentinelTheme.Primary
    )

    if ([string]::IsNullOrEmpty($Color)) {
        Write-Host $Text
        return
    }

    Write-Host ("{0}{1}{2}" -f $Color, $Text, $SentinelTheme.Reset)
}

function Write-SentinelDivider {
    [CmdletBinding()]
    param(
        [string]$Label,
        [ValidateSet('Primary', 'Success', 'Warning', 'Error', 'Secondary', 'Muted')]
        [string]$Tone = 'Secondary',
        [int]$Width = 39,
        [string]$Character = '═'
    )

    $line = ($Character * [Math]::Max($Width, 8))
    $color = Get-SentinelToneColor -Tone $Tone

    if ([string]::IsNullOrWhiteSpace($Label)) {
        Write-SentinelText -Text ("  {0}" -f $line) -Color $color
        return
    }

    Write-SentinelText -Text ("  {0} {1} {0}" -f $line, $Label) -Color $color
}

function Format-SentinelBadge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [ValidateSet('Primary', 'Success', 'Warning', 'Error', 'Secondary', 'Muted')]
        [string]$Tone = 'Primary'
    )

    $normalized = $Label.Trim().ToUpperInvariant()
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return ''
    }

    if (-not $script:SentinelAnsiEnabled) {
        return ('[{0}]' -f $normalized)
    }

    $color = Get-SentinelToneColor -Tone $Tone
    return ("{0}[ {1} ]{2}" -f $color, $normalized, $SentinelTheme.Reset)
}

function Write-SentinelBadgeLine {
    [CmdletBinding()]
    param([string[]]$Badges)

    $normalizedBadges = @($Badges | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($normalizedBadges.Count -eq 0) {
        return
    }

    Write-Host ("  {0}" -f ($normalizedBadges -join ' '))
}

function Write-SentinelHeader {
    [CmdletBinding()]
    param(
        [string]$Title = 'SENTINEL',
        [string]$Version = 'v1.0.0',
        [ValidateSet('Hero', 'Compact', 'Minimal')]
        [string]$Variant = 'Hero'
    )

    switch ($Variant) {
        'Minimal' {
            Write-SentinelDivider -Tone 'Secondary'
            Write-SentinelText -Text ("  {0}  ·  {1}" -f $Title, $Version) -Color $SentinelTheme.Primary
            Write-Host ''
            return
        }
        'Compact' {
            Write-SentinelDivider -Tone 'Secondary'
            Write-SentinelText -Text ("  {0}" -f $Title) -Color $SentinelTheme.Primary
            Write-SentinelText -Text ("  versão {0}" -f $Version) -Color $SentinelTheme.Secondary
            Write-Host ''
            return
        }
        default {
            $logo = @(
                '  ███████╗███████╗███╗   ██╗████████╗██╗███╗   ██╗███████╗██╗     ',
                '  ██╔════╝██╔════╝████╗  ██║╚══██╔══╝██║████╗  ██║██╔════╝██║     ',
                '  ███████╗█████╗  ██╔██╗ ██║   ██║   ██║██╔██╗ ██║█████╗  ██║     ',
                '  ╚════██║██╔══╝  ██║╚██╗██║   ██║   ██║██║╚██╗██║██╔══╝  ██║     ',
                '  ███████║███████╗██║ ╚████║   ██║   ██║██║ ╚████║███████╗███████╗',
                '  ╚══════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝'
            )

            foreach ($line in $logo) {
                Write-SentinelText -Text $line -Color $SentinelTheme.Primary
            }

            Write-SentinelText -Text ("  {0}  ·  {1}" -f $Title, $Version) -Color $SentinelTheme.Secondary
            Write-Host ''
        }
    }
}

function Write-SentinelSection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [string]$Subtitle,
        [ValidateSet('Primary', 'Success', 'Warning', 'Error', 'Secondary', 'Muted')]
        [string]$Tone = 'Primary'
    )

    Write-Host ''
    Write-SentinelDivider -Tone $Tone
    Write-SentinelText -Text ("   {0}" -f $Title) -Color (Get-SentinelToneColor -Tone $Tone)
    if (-not [string]::IsNullOrWhiteSpace($Subtitle)) {
        Write-SentinelText -Text ("   {0}" -f $Subtitle) -Color $SentinelTheme.Secondary
    }
    Write-SentinelDivider -Tone $Tone
    Write-Host ''
}

function Write-SentinelPanel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [string[]]$Lines,
        [ValidateSet('Primary', 'Success', 'Warning', 'Error', 'Secondary', 'Muted')]
        [string]$Tone = 'Secondary'
    )

    $normalizedLines = @($Lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    Write-SentinelText -Text ("  {0}" -f $Title) -Color (Get-SentinelToneColor -Tone $Tone)

    foreach ($line in $normalizedLines) {
        Write-SentinelText -Text ("    {0}" -f $line) -Color $SentinelTheme.Secondary
    }

    Write-Host ''
}

function Write-SentinelKeyValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        [AllowEmptyString()][string]$Value = '',
        [int]$KeyWidth = 18,
        [ValidateSet('Primary', 'Success', 'Warning', 'Error', 'Secondary', 'Muted')]
        [string]$Tone = 'Primary'
    )

    $paddedKey = $Key.PadRight([Math]::Max($KeyWidth, 8))
    $valueText = if ($null -eq $Value) { '' } else { [string]$Value }

    if (-not $script:SentinelAnsiEnabled) {
        Write-Host ("  {0} : {1}" -f $paddedKey, $valueText)
        return
    }

    $keyColor = $SentinelTheme.Secondary
    $valueColor = Get-SentinelToneColor -Tone $Tone
    Write-Host ("  {0}{1}{2} : {3}{4}{5}" -f $keyColor, $paddedKey, $SentinelTheme.Reset, $valueColor, $valueText, $SentinelTheme.Reset)
}

function Write-SentinelMenuOptions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Options
    )

    for ($index = 0; $index -lt $Options.Count; $index++) {
        Write-SentinelText -Text ("    [{0}] {1}" -f ($index + 1), $Options[$index]) -Color $SentinelTheme.Secondary
    }

    Write-Host ''
}

function Write-SentinelProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Activity,
        [int]$Current = 0,
        [int]$Total = 0,
        [ValidateSet('Primary', 'Success', 'Warning', 'Error', 'Secondary', 'Muted')]
        [string]$Tone = 'Primary'
    )

    if ($Total -le 0) {
        Write-SentinelText -Text ("  ⟳ {0}" -f $Activity) -Color (Get-SentinelToneColor -Tone $Tone)
        return
    }

    $safeCurrent = [Math]::Min([Math]::Max($Current, 0), $Total)
    $barWidth = 22
    $ratio = if ($Total -eq 0) { 0 } else { [double]$safeCurrent / [double]$Total }
    $filled = [Math]::Round($ratio * $barWidth)
    $empty = $barWidth - $filled
    $bar = ('█' * $filled) + ('·' * $empty)
    $percent = [Math]::Round($ratio * 100)

    Write-SentinelText -Text ("  {0,-26} [{1}] {2,3}% ({3}/{4})" -f $Activity, $bar, $percent, $safeCurrent, $Total) -Color (Get-SentinelToneColor -Tone $Tone)
}

function Write-SentinelStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('Success', 'Info', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )

    $glyph = $SentinelTheme.Glyphs[$Type]
    $color = switch ($Type) {
        'Success' { $SentinelTheme.Success }
        'Warning' { $SentinelTheme.Warning }
        'Error' { $SentinelTheme.Error }
        default { $SentinelTheme.Primary }
    }

    Write-SentinelText -Text (" {0} {1}" -f $glyph, $Message) -Color $color
}

function Show-SentinelMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string[]]$Options
    )

    Write-SentinelSection -Title $Title -Tone 'Primary'
    Write-SentinelMenuOptions -Options $Options
    return (Read-Host 'Selecione uma opção')
}

function Show-SentinelSpinner {
    [CmdletBinding()]
    param([string]$Message = 'Processando...')

    Write-SentinelProgress -Activity $Message -Tone 'Primary'
}

