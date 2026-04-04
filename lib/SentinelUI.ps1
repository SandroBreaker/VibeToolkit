$script:SentinelEscape = [char]27
$script:SentinelAnsiEnabled = (
    -not [string]::IsNullOrWhiteSpace($env:WT_SESSION) -or
    $env:TERM_PROGRAM -eq 'vscode' -or
    $env:ConEmuANSI -eq 'ON'
)

$SentinelTheme = [ordered]@{
    Reset     = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[0m" } else { '' }
    Primary   = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;0;229;255m" } else { '' }
    Secondary = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;110;118;129m" } else { '' }
    Success   = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;34;197;94m" } else { '' }
    Warning   = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;245;158;11m" } else { '' }
    Error     = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;239;68;68m" } else { '' }
    Glyphs    = @{
        Success = '✔'
        Info    = '➜'
        Warning = '⚠'
        Error   = '✖'
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

function Write-SentinelHeader {
    param(
        [string]$Title = 'SENTINEL',
        [string]$Version = 'v1.0.0'
    )

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

    Write-SentinelText -Text $Title -Color $SentinelTheme.Primary

    for ($index = 0; $index -lt $Options.Count; $index++) {
        Write-SentinelText -Text (" [{0}] {1}" -f ($index + 1), $Options[$index]) -Color $SentinelTheme.Secondary
    }

    return (Read-Host 'Selecione uma opção')
}

function Show-SentinelSpinner {
    [CmdletBinding()]
    param([string]$Message = 'Processando...')

    Write-SentinelStatus -Message $Message -Type Info
}
