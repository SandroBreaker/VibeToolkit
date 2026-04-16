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

$script:SentinelUiLayout = @{
    DividerWidth          = 34
    ProgressBarWidth      = 18
    ProgressActivityWidth = 24
}

$SentinelTheme = [ordered]@{
    Reset     = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[0m" } else { '' }
    Primary   = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;0;229;255m" } else { '' }
    Secondary = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;176;190;212m" } else { '' }
    Muted     = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;120;133;153m" } else { '' }
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
        'Success'   { return $SentinelTheme.Success }
        'Warning'   { return $SentinelTheme.Warning }
        'Error'     { return $SentinelTheme.Error }
        'Secondary' { return $SentinelTheme.Secondary }
        'Muted'     { return $SentinelTheme.Muted }
        default     { return $SentinelTheme.Primary }
    }
}

function Get-SentinelTrimmedText {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$Text = '',
        [int]$MaxLength = 24
    )

    $value = if ($null -eq $Text) { '' } else { [string]$Text }
    if ([string]::IsNullOrEmpty($value)) {
        return ''
    }

    if ($value.Length -le $MaxLength) {
        return $value
    }

    if ($MaxLength -le 1) {
        return '…'
    }

    return ($value.Substring(0, $MaxLength - 1) + '…')
}

function Get-SentinelDividerContent {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$Label = '',
        [int]$Width = 34,
        [string]$Character = '━'
    )

    $safeWidth = [Math]::Max($Width, 8)
    $dividerChar = if ([string]::IsNullOrEmpty($Character)) { '━' } else { $Character.Substring(0, 1) }

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
            $normalizedLabel = '…'
        }
        else {
            $normalizedLabel = $normalizedLabel.Substring(0, $maxLabelLength - 1) + '…'
        }
    }

    $framedLabel = " $normalizedLabel "
    $remaining = $safeWidth - $framedLabel.Length

    if ($remaining -lt ($minimumSideWidth * 2)) {
        $maxFramedLabelLength = $safeWidth - ($minimumSideWidth * 2)
        if ($maxFramedLabelLength -le 0) {
            return ($dividerChar * $safeWidth)
        }

        if ($framedLabel.Length -gt $maxFramedLabelLength) {
            $framedLabel = $framedLabel.Substring(0, $maxFramedLabelLength)
        }

        $remaining = $safeWidth - $framedLabel.Length
    }

    $leftWidth = [Math]::Max([int][Math]::Floor($remaining / 2), $minimumSideWidth)
    $rightWidth = [Math]::Max(($remaining - $leftWidth), $minimumSideWidth)

    $currentLength = $leftWidth + $framedLabel.Length + $rightWidth
    if ($currentLength -gt $safeWidth) {
        $overflow = $currentLength - $safeWidth

        if ($rightWidth -gt $minimumSideWidth) {
            $shrinkRight = [Math]::Min($overflow, $rightWidth - $minimumSideWidth)
            $rightWidth -= $shrinkRight
            $overflow -= $shrinkRight
        }

        if ($overflow -gt 0 -and $leftWidth -gt $minimumSideWidth) {
            $shrinkLeft = [Math]::Min($overflow, $leftWidth - $minimumSideWidth)
            $leftWidth -= $shrinkLeft
            $overflow -= $shrinkLeft
        }
    }

    return ('{0}{1}{2}' -f ($dividerChar * $leftWidth), $framedLabel, ($dividerChar * $rightWidth))
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
        [int]$Width = 34,
        [string]$Character = '━'
    )

    $dividerText = Get-SentinelDividerContent -Label $Label -Width $Width -Character $Character
    $color = Get-SentinelToneColor -Tone $Tone
    Write-SentinelText -Text ("  {0}" -f $dividerText) -Color $color
}

function Format-SentinelBadge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [ValidateSet('Primary', 'Success', 'Warning', 'Error', 'Secondary', 'Muted')]
        [string]$Tone = 'Primary'
    )

    $normalized = ($Label -replace '\s+', ' ').Trim().ToUpperInvariant()
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return ''
    }

    if (-not $script:SentinelAnsiEnabled) {
        return ('[{0}]' -f $normalized)
    }

    $color = Get-SentinelToneColor -Tone $Tone
    return ("{0}[{1}]{2}" -f $color, $normalized, $SentinelTheme.Reset)
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
            Write-SentinelText -Text ("  {0} · {1}" -f $Title, $Version) -Color $SentinelTheme.Primary
            Write-Host ''
            return
        }
        'Compact' {
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
                Write-SentinelText -Text ("  {0} · {1}" -f $Title, $Version) -Color $SentinelTheme.Primary
                Write-SentinelDivider -Label $Title -Tone 'Primary'
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

            Write-SentinelDivider -Tone 'Secondary'
            foreach ($line in $logo) {
                Write-SentinelText -Text $line -Color $SentinelTheme.Primary
            }

            Write-SentinelText -Text ("  {0} · {1}" -f $Title, $Version) -Color $SentinelTheme.Secondary
            Write-SentinelDivider -Tone 'Secondary'
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
    Write-SentinelDivider -Label $Title -Tone $Tone
    if (-not [string]::IsNullOrWhiteSpace($Subtitle)) {
        Write-SentinelText -Text ("  {0}" -f $Subtitle) -Color $SentinelTheme.Secondary
    }
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
    Write-Host ("  {0}{1}{2}{3}:{2} {4}{5}{2}" -f $keyColor, $paddedKey, $SentinelTheme.Reset, $SentinelTheme.Muted, $valueColor, $valueText)
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
        [string]$Tone = 'Primary',
        [string]$Item = ''
    )

    $windowWidth = 80
    try {
        $windowWidth = [Math]::Max([Console]::WindowWidth, 60)
    } catch {}

    if ($Total -le 0) {
        $activityText = Get-SentinelTrimmedText -Text $Activity -MaxLength ([Math]::Max(($script:SentinelUiLayout.ProgressActivityWidth + 8), 12))
        $line = ("  ⟳ {0}" -f $activityText).PadRight($windowWidth - 1)
        if ($script:SentinelAnsiEnabled) {
            Write-Host ("`r{0}{1}{2}" -f (Get-SentinelToneColor -Tone $Tone), $line, $SentinelTheme.Reset) -NoNewline
        } else {
            Write-Host ("`r{0}" -f $line) -NoNewline
        }
        return
    }

    $safeCurrent = [Math]::Min([Math]::Max($Current, 0), $Total)
    $barWidth = [Math]::Max($script:SentinelUiLayout.ProgressBarWidth, 14)
    $ratio = if ($Total -eq 0) { 0 } else { [double]$safeCurrent / [double]$Total }
    $filled = [int][Math]::Round(($ratio * $barWidth), 0, [System.MidpointRounding]::AwayFromZero)
    $filled = [Math]::Min([Math]::Max($filled, 0), $barWidth)
    $empty = $barWidth - $filled
    $bar = if ($script:SentinelAnsiEnabled) { ('█' * $filled) + ('░' * $empty) } else { ('#' * $filled) + ('·' * $empty) }
    $percent = [int][Math]::Round(($ratio * 100), 0, [System.MidpointRounding]::AwayFromZero)

    $progressBase = "  ⟳ {0}  [{1}] {2,3}% ({3}/{4})" -f $Activity, $bar, $percent, $safeCurrent, $Total

    $displayItem = ''
    if (-not [string]::IsNullOrWhiteSpace($Item)) {
        $maxItemLen = [Math]::Max($windowWidth - $progressBase.Length - 4, 8)
        $leaf = [System.IO.Path]::GetFileName($Item)
        if ([string]::IsNullOrWhiteSpace($leaf)) { $leaf = $Item }
        $displayItem = if ($leaf.Length -le $maxItemLen) {
            '  ' + $leaf
        } else {
            '  …' + $leaf.Substring([Math]::Max($leaf.Length - $maxItemLen + 1, 0))
        }
    }

    $line = ($progressBase + $displayItem).PadRight($windowWidth - 1)

    if ($script:SentinelAnsiEnabled) {
        $color = Get-SentinelToneColor -Tone $Tone
        Write-Host ("`r{0}{1}{2}" -f $color, $line, $SentinelTheme.Reset) -NoNewline
    } else {
        Write-Host ("`r{0}" -f $line) -NoNewline
    }
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
        'Error'   { $SentinelTheme.Error }
        default   { $SentinelTheme.Primary }
    }

    Write-SentinelText -Text ("  {0} {1}" -f $glyph, $Message) -Color $color
}

function Show-SentinelMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string[]]$Options,

        [string]$Prompt = ''
    )

    Write-SentinelSection -Title $Title -Tone 'Primary'
    Write-SentinelMenuOptions -Options $Options
    $promptText = if (-not [string]::IsNullOrWhiteSpace($Prompt)) { $Prompt } else { ('  Escolha [1-{0}]' -f $Options.Count) }
    return (Read-Host $promptText)
}

function Show-SentinelSpinner {
    [CmdletBinding()]
    param([string]$Message = 'Processando...')

    Write-SentinelProgress -Activity $Message -Tone 'Primary'
}