#requires -Version 7.0

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:SentinelAllowedExtensions = @(
    '.tsx', '.ts', '.js', '.jsx', '.css', '.html', '.json', '.prisma', '.sql', '.yaml', '.yml', '.md',
    '.py', '.java', '.cs', '.c', '.cpp', '.h', '.hpp', '.go', '.rb', '.php', '.rs', '.swift',
    '.kt', '.scala', '.dart', '.r', '.sh', '.bat', '.ps1', '.psm1', '.csv', '.xml', '.xaml'
)

$script:SentinelIgnoredDirs = @(
    'node_modules', '.git', 'dist', 'build', '.next', '.cache', 'out',
    'android', 'ios', 'coverage', '.venv', 'venv', 'env', '__pycache__',
    '.pytest_cache', '.tox', 'bin', 'obj', 'target', 'vendor', '.vs', '.idea'
)

$script:SentinelIgnoredFiles = @(
    'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock',
    '.DS_Store', 'metadata.json', '.gitignore',
    'google-services.json', 'capacitor.config.json',
    'capacitor.plugins.json', 'cordova.js', 'cordova_plugins.js',
    'poetry.lock', 'Pipfile.lock', 'Cargo.lock', 'go.sum', 'composer.lock'
)
$script:SentinelLogBuffer = [System.Text.StringBuilder]::new()
$script:SentinelLogFontFamily = 'Consolas'   # resolved at runtime by Get-SentinelHudBestLogFont
$script:SentinelLogFontSize = 14.0
$script:SentinelLogLineHeightFactor = 1.18

function global:Assert-SentinelWpfRuntime {
    if (-not $IsWindows) {
        throw 'O HUD WPF exige Windows. Surpresa zero.'
    }

    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
    Add-Type -AssemblyName System.Xaml
}

function global:Import-SentinelBundlerModules {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolkitDir
    )

    $modulesDir = Join-Path $ToolkitDir 'modules'
    $requiredModulePaths = @(
        (Join-Path $modulesDir 'VibeBundleWriter.psm1'),
        (Join-Path $modulesDir 'VibeFileDiscovery.psm1')
    )

    foreach ($modulePath in $requiredModulePaths) {
        if (-not (Test-Path $modulePath -PathType Leaf)) {
            throw "Módulo obrigatório não encontrado para o HUD: $modulePath"
        }
    }

    foreach ($modulePath in $requiredModulePaths) {
        $dynamicModuleName = [System.IO.Path]::GetFileNameWithoutExtension($modulePath)
        if (Get-Module -Name $dynamicModuleName -ErrorAction SilentlyContinue) {
            continue
        }

        Import-Module $modulePath -Force -DisableNameChecking -ErrorAction Stop | Out-Null
    }
}

function global:Get-SentinelPwshPath {
    foreach ($candidate in @('pwsh.exe', 'pwsh')) {
        $command = Get-Command -Name $candidate -ErrorAction SilentlyContinue
        if ($null -ne $command) {
            return $command.Source
        }
    }

    throw 'pwsh.exe não encontrado no PATH.'
}

function global:Test-SentinelGeneratedArtifactFileName {
    param(
        [AllowNull()]
        [string]$FileName
    )

    if ([string]::IsNullOrWhiteSpace($FileName)) {
        return $false
    }

    if (Get-Command -Name Test-VibeGeneratedArtifactFileName -ErrorAction SilentlyContinue) {
        try {
            if (Test-VibeGeneratedArtifactFileName -FileName $FileName) {
                return $true
            }
        }
        catch {
        }
    }

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
        if ($FileName -match $pattern) {
            return $true
        }
    }

    return $false
}

function global:Get-SentinelRelevantFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $resolvedTargetPath = [System.IO.Path]::GetFullPath($TargetPath)

    if (Get-Command -Name Get-VibeRelevantFiles -ErrorAction SilentlyContinue) {
        try {
            $items = @(Get-VibeRelevantFiles -CurrentPath $resolvedTargetPath -AllowedExtensions $script:SentinelAllowedExtensions -IgnoredDirs $script:SentinelIgnoredDirs -IgnoredFiles $script:SentinelIgnoredFiles)
            $relativePaths = foreach ($item in $items) {
                $name = if ($item -is [System.IO.FileInfo]) { $item.Name } else { [string]$item.Name }
                if (Test-SentinelGeneratedArtifactFileName -FileName $name) {
                    continue
                }

                $fullName = if ($item -is [System.IO.FileInfo]) { $item.FullName } else { [string]$item.FullName }
                if ([string]::IsNullOrWhiteSpace($fullName)) {
                    continue
                }

                [System.IO.Path]::GetRelativePath($resolvedTargetPath, $fullName)
            }

            return @($relativePaths | Sort-Object -Unique)
        }
        catch {
        }
    }

    $files = Get-ChildItem -LiteralPath $resolvedTargetPath -File -Recurse -Force -ErrorAction Stop
    $result = New-Object System.Collections.Generic.List[string]

    foreach ($file in $files) {
        if ([string]::IsNullOrWhiteSpace($file.Extension) -or ($script:SentinelAllowedExtensions -notcontains $file.Extension.ToLowerInvariant())) {
            continue
        }

        if ($script:SentinelIgnoredFiles -contains $file.Name) {
            continue
        }

        if (Test-SentinelGeneratedArtifactFileName -FileName $file.Name) {
            continue
        }

        $relativePath = [System.IO.Path]::GetRelativePath($resolvedTargetPath, $file.FullName)
        $segments = @($relativePath -split '[\\/]')
        $skip = $false

        foreach ($segment in $segments) {
            if ($script:SentinelIgnoredDirs -contains $segment) {
                $skip = $true
                break
            }
        }

        if ($skip) {
            continue
        }

        $result.Add($relativePath) | Out-Null
    }

    return @($result | Sort-Object -Unique)
}

function global:New-SentinelHudRgbBrush {
    param(
        [Parameter(Mandatory = $true)]
        [byte]$Red,

        [Parameter(Mandatory = $true)]
        [byte]$Green,

        [Parameter(Mandatory = $true)]
        [byte]$Blue
    )

    $brush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb($Red, $Green, $Blue))
    if ($brush.CanFreeze) {
        $brush.Freeze()
    }

    return $brush
}

function global:Get-SentinelHudAnsiBrushFromCodes {
    param(
        [AllowNull()]
        [int[]]$Codes,

        [Parameter(Mandatory = $true)]
        [System.Windows.Media.Brush]$DefaultBrush
    )

    if ($null -eq $Codes -or $Codes.Count -eq 0) {
        return $DefaultBrush
    }

    for ($index = 0; $index -lt $Codes.Count; $index++) {
        $code = $Codes[$index]

        switch ($code) {
            0 { return $DefaultBrush }
            39 { return $DefaultBrush }
            30 { return [System.Windows.Media.Brushes]::Black }
            31 { return [System.Windows.Media.Brushes]::IndianRed }
            32 { return [System.Windows.Media.Brushes]::MediumSeaGreen }
            33 { return [System.Windows.Media.Brushes]::Goldenrod }
            34 { return [System.Windows.Media.Brushes]::CornflowerBlue }
            35 { return [System.Windows.Media.Brushes]::Orchid }
            36 { return [System.Windows.Media.Brushes]::DeepSkyBlue }
            37 { return [System.Windows.Media.Brushes]::Gainsboro }
            90 { return [System.Windows.Media.Brushes]::SlateGray }
            91 { return [System.Windows.Media.Brushes]::LightCoral }
            92 { return [System.Windows.Media.Brushes]::LightGreen }
            93 { return [System.Windows.Media.Brushes]::Khaki }
            94 { return [System.Windows.Media.Brushes]::LightSkyBlue }
            95 { return [System.Windows.Media.Brushes]::Violet }
            96 { return [System.Windows.Media.Brushes]::Cyan }
            97 { return [System.Windows.Media.Brushes]::White }
            38 {
                if (($index + 4) -lt $Codes.Count -and $Codes[$index + 1] -eq 2) {
                    return New-SentinelHudRgbBrush -Red ([byte]$Codes[$index + 2]) -Green ([byte]$Codes[$index + 3]) -Blue ([byte]$Codes[$index + 4])
                }
            }
        }
    }

    return $DefaultBrush
}

function global:Convert-SentinelHudAnsiSegments {
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Text = '',

        [Parameter(Mandatory = $true)]
        [System.Windows.Media.Brush]$DefaultBrush
    )

    $segments = [System.Collections.Generic.List[object]]::new()
    if ([string]::IsNullOrEmpty($Text)) {
        return $segments
    }

    $escape = [string][char]27
    $pattern = '{0}\[(?<codes>[0-9;]*)m' -f [regex]::Escape($escape)
    $selectionMatches = [regex]::Matches($Text, $pattern)
    $cursor = 0
    $currentBrush = $DefaultBrush

    foreach ($match in $selectionMatches) {
        if ($match.Index -gt $cursor) {
            $segments.Add([pscustomobject]@{
                    Text       = $Text.Substring($cursor, $match.Index - $cursor)
                    Foreground = $currentBrush
                }) | Out-Null
        }

        $rawCodes = [string]$match.Groups['codes'].Value
        $codes = if ([string]::IsNullOrWhiteSpace($rawCodes)) {
            @(0)
        }
        else {
            @(
                $rawCodes.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries) |
                ForEach-Object { [int]$_ }
            )
        }

        $currentBrush = Get-SentinelHudAnsiBrushFromCodes -Codes $codes -DefaultBrush $DefaultBrush
        $cursor = $match.Index + $match.Length
    }

    if ($cursor -lt $Text.Length) {
        $segments.Add([pscustomobject]@{
                Text       = $Text.Substring($cursor)
                Foreground = $currentBrush
            }) | Out-Null
    }

    return $segments
}

function global:Get-SentinelHudLogLevel {
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Message = ''
    )

    if ([string]::IsNullOrWhiteSpace($Message)) { return 'default' }

    $clean = $Message -replace "\x1b\[[0-9;]*m", ""

    if ($clean -match '(?i)\b(erro|falha|error|failed|fail\b|exception|crítico|fatal|crash|abortado|aborted|killed)\b') { return 'error' }
    if ($clean -match '(?i)\b(aviso|warning|warn|atenção|deprecated|obsoleto)\b')                                      { return 'warning' }
    if ($clean -match '(?i)\b(sucesso|concluído|concluida|completo|finalizado|carregado|bootstrap|detectado|pronto|done\b|success|ok\b|gravado|salvo|gerado|exportado)\b') { return 'success' }
    if ($clean -match '(?i)(inicializando|aguardando|disparando|processo iniciado|pid=|sentinel headless|headless carregado|configurac)') { return 'system' }
    if ($clean -match '^[\s\-=─━\*·\u2500-\u257F]+$')                                                                  { return 'divider' }

    return 'default'
}

function global:Get-SentinelHudLogLineBrushes {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Level
    )

    switch ($Level) {
        'error' {
            return @{
                Timestamp = (New-SentinelHudRgbBrush -Red 190 -Green 70  -Blue 70)
                Message   = (New-SentinelHudRgbBrush -Red 255 -Green 110 -Blue 110)
                Accent    = (New-SentinelHudRgbBrush -Red 210 -Green 55  -Blue 55)
                RowBg     = (New-SentinelHudRgbBrush -Red 38  -Green 10  -Blue 10)
            }
        }
        'warning' {
            return @{
                Timestamp = (New-SentinelHudRgbBrush -Red 175 -Green 135 -Blue 55)
                Message   = (New-SentinelHudRgbBrush -Red 255 -Green 198 -Blue 90)
                Accent    = (New-SentinelHudRgbBrush -Red 210 -Green 155 -Blue 45)
                RowBg     = (New-SentinelHudRgbBrush -Red 30  -Green 22  -Blue 6)
            }
        }
        'success' {
            return @{
                Timestamp = (New-SentinelHudRgbBrush -Red 70  -Green 150 -Blue 92)
                Message   = (New-SentinelHudRgbBrush -Red 102 -Green 222 -Blue 148)
                Accent    = (New-SentinelHudRgbBrush -Red 55  -Green 175 -Blue 100)
                RowBg     = $null
            }
        }
        'system' {
            return @{
                Timestamp = (New-SentinelHudRgbBrush -Red 98  -Green 138 -Blue 178)
                Message   = (New-SentinelHudRgbBrush -Red 148 -Green 192 -Blue 245)
                Accent    = (New-SentinelHudRgbBrush -Red 55  -Green 118 -Blue 200)
                RowBg     = $null
            }
        }
        'divider' {
            return @{
                Timestamp = (New-SentinelHudRgbBrush -Red 42  -Green 62  -Blue 82)
                Message   = (New-SentinelHudRgbBrush -Red 38  -Green 58  -Blue 78)
                Accent    = $null
                RowBg     = $null
            }
        }
        default {
            return @{
                Timestamp = (New-SentinelHudRgbBrush -Red 132 -Green 163 -Blue 194)
                Message   = (New-SentinelHudRgbBrush -Red 226 -Green 232 -Blue 240)
                Accent    = $null
                RowBg     = $null
            }
        }
    }
}

function global:Add-SentinelHudLogLine {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Window]$Window,

        [Parameter(Mandatory = $true)]
        [System.Windows.Controls.ListBox]$LogList,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$Message = ''
    )

    $timestamp = (Get-Date).ToString('HH:mm:ss')

    $cleanMessage = $Message -replace "\x1b\[[0-9;]*m", ""
    $script:SentinelLogBuffer.AppendLine("[$timestamp] $cleanMessage") | Out-Null

    $currentFontSize   = $script:SentinelLogFontSize
    $currentFontFamily = $script:SentinelLogFontFamily
    $currentLineHeight = Get-SentinelHudResolvedLogLineHeight -FontSize $currentFontSize

    $logLevel   = Get-SentinelHudLogLevel -Message $Message
    $logBrushes = Get-SentinelHudLogLineBrushes -Level $logLevel
    $hasAnsi    = $Message -match "\x1b\["

    $updateAction = {
        $timestampBrush = [System.Windows.Media.Brush]$logBrushes.Timestamp
        $defaultBrush   = [System.Windows.Media.Brush]$logBrushes.Message

        $lineBlock = [System.Windows.Controls.TextBlock]::new()
        $lineBlock.FontFamily           = [System.Windows.Media.FontFamily]::new($currentFontFamily)
        $lineBlock.FontSize             = $currentFontSize
        $lineBlock.TextWrapping         = [System.Windows.TextWrapping]::NoWrap
        $lineBlock.LineStackingStrategy = [System.Windows.LineStackingStrategy]::BlockLineHeight
        $lineBlock.LineHeight           = $currentLineHeight
        $lineBlock.Margin               = [System.Windows.Thickness]::new(0)
        $lineBlock.SnapsToDevicePixels  = $true
        $lineBlock.UseLayoutRounding    = $true
        [System.Windows.Media.TextOptions]::SetTextFormattingMode($lineBlock, [System.Windows.Media.TextFormattingMode]::Ideal)
        [System.Windows.Media.TextOptions]::SetTextRenderingMode($lineBlock,  [System.Windows.Media.TextRenderingMode]::ClearType)
        [System.Windows.Media.TextOptions]::SetTextHintingMode($lineBlock,    [System.Windows.Media.TextHintingMode]::Fixed)

        $timestampRun            = [System.Windows.Documents.Run]::new("[$timestamp] ")
        $timestampRun.Foreground = $timestampBrush
        $timestampRun.FontWeight = if ($logLevel -eq 'error') { [System.Windows.FontWeights]::Bold } else { [System.Windows.FontWeights]::SemiBold }
        $lineBlock.Inlines.Add($timestampRun) | Out-Null

        if ($hasAnsi) {
            $segments = Convert-SentinelHudAnsiSegments -Text $Message -DefaultBrush $defaultBrush
            if ($segments.Count -eq 0) {
                $r = [System.Windows.Documents.Run]::new([string]$Message)
                $r.Foreground = $defaultBrush
                $lineBlock.Inlines.Add($r) | Out-Null
            }
            else {
                foreach ($seg in $segments) {
                    if ([string]::IsNullOrEmpty([string]$seg.Text)) { continue }
                    $r = [System.Windows.Documents.Run]::new([string]$seg.Text)
                    $r.Foreground = [System.Windows.Media.Brush]$seg.Foreground
                    $lineBlock.Inlines.Add($r) | Out-Null
                }
            }
        }
        else {
            $msgRun = [System.Windows.Documents.Run]::new([string]$Message)
            $msgRun.Foreground = $defaultBrush
            if ($logLevel -eq 'error') { $msgRun.FontWeight = [System.Windows.FontWeights]::SemiBold }
            $lineBlock.Inlines.Add($msgRun) | Out-Null
        }

        $container                     = [System.Windows.Controls.Border]::new()
        $container.BorderThickness     = [System.Windows.Thickness]::new(3, 0, 0, 0)
        $container.Padding             = [System.Windows.Thickness]::new(8, 0, 0, 0)
        $container.Margin              = [System.Windows.Thickness]::new(0)
        $container.SnapsToDevicePixels = $true
        $container.BorderBrush         = if ($null -ne $logBrushes.Accent) { [System.Windows.Media.Brush]$logBrushes.Accent } else { [System.Windows.Media.Brushes]::Transparent }
        $container.Background          = if ($null -ne $logBrushes.RowBg)  { [System.Windows.Media.Brush]$logBrushes.RowBg  } else { [System.Windows.Media.Brushes]::Transparent }
        $container.Child               = $lineBlock

        $null = $LogList.Items.Add($container)
        $LogList.ScrollIntoView($container)
    }.GetNewClosure()

    if ($Window.Dispatcher.CheckAccess()) {
        & $updateAction
    }
    else {
        $Window.Dispatcher.BeginInvoke([System.Action]$updateAction) | Out-Null
    }
}

function global:Set-SentinelHudFooterStatus {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Window]$Window,

        [Parameter(Mandatory = $true)]
        [System.Windows.Controls.TextBlock]$FooterStatus,

        [Parameter(Mandatory = $true)]
        [System.Windows.Controls.TextBlock]$RunState,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [string]$Badge = 'Pronto'
    )

    $updateAction = {
        $FooterStatus.Text = $Message
        $RunState.Text = $Badge
    }.GetNewClosure()

    if ($Window.Dispatcher.CheckAccess()) {
        & $updateAction
    }
    else {
        $Window.Dispatcher.BeginInvoke([System.Action]$updateAction) | Out-Null
    }
}

function global:Set-SentinelHudExecutionSummary {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Window]$Window,

        [Parameter(Mandatory = $true)]
        [System.Windows.Controls.TextBox]$SummaryBox,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $updateAction = {
        $previousContent = $SummaryBox.Text
        $SummaryBox.Text = $Content
        $SummaryBox.ScrollToHome()

        if ($previousContent -ne $Content -and -not [string]::IsNullOrWhiteSpace($Content) -and -not [string]::IsNullOrEmpty($previousContent)) {
            $logList = $Window.FindName('lstLog')
            if ($logList -is [System.Windows.Controls.ListBox]) {
                Add-SentinelHudLogLine -Window $Window -LogList $logList -Message 'Resumo da execução:'
                foreach ($summaryLine in ($Content -split "`r?`n")) {
                    if (-not [string]::IsNullOrWhiteSpace($summaryLine)) {
                        Add-SentinelHudLogLine -Window $Window -LogList $logList -Message ("  {0}" -f $summaryLine.Trim())
                    }
                }
            }
        }
    }.GetNewClosure()

    if ($Window.Dispatcher.CheckAccess()) {
        & $updateAction
    }
    else {
        $Window.Dispatcher.BeginInvoke([System.Action]$updateAction) | Out-Null
    }
}

function global:Get-SentinelHudAvailableLogFonts {
    $preferredFonts = @(
        'Consolas',
        'Lucida Console',
        'Courier New',
        'Cascadia Code',
        'Cascadia Mono',
        'IBM Plex Mono',
        'Source Code Pro',
        'JetBrains Mono',
        'Fira Code'
    )

    $installedFonts = @(
        [System.Windows.Media.Fonts]::SystemFontFamilies |
        ForEach-Object { $_.Source } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique
    )

    $ordered = New-Object System.Collections.Generic.List[string]

    foreach ($fontName in $preferredFonts) {
        if ($installedFonts -contains $fontName) {
            $ordered.Add($fontName) | Out-Null
        }
    }

    foreach ($fontName in $installedFonts) {
        if ($ordered -notcontains $fontName) {
            $ordered.Add($fontName) | Out-Null
        }
    }

    return @($ordered)
}

function global:Get-SentinelHudBestLogFont {
    # Priority order — first one found on the system wins
    $priority = @(
        'Consolas',
        'Lucida Console',
        'Courier New',
        'Cascadia Code',
        'Cascadia Mono',
        'IBM Plex Mono',
        'Source Code Pro',
        'JetBrains Mono',
        'Fira Code'
    )

    $installed = @(
        [System.Windows.Media.Fonts]::SystemFontFamilies |
        ForEach-Object { $_.Source }
    )

    foreach ($name in $priority) {
        if ($installed -contains $name) {
            return $name
        }
    }

    return 'Consolas'
}

function global:Get-SentinelHudResolvedLogLineHeight {
    param(
        [double]$FontSize = 14
    )

    $resolvedSize = if ($FontSize -lt 9) { 9.0 } elseif ($FontSize -gt 24) { 24.0 } else { [Math]::Round($FontSize, 1) }
    return [Math]::Round($resolvedSize * $script:SentinelLogLineHeightFactor, 1)
}

function global:Set-SentinelHudLogTypography {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Controls,

        [AllowNull()]
        [string]$FontFamily,

        [double]$FontSize = 14
    )

    $resolvedFamily     = if ([string]::IsNullOrWhiteSpace($FontFamily)) { 'Consolas' } else { $FontFamily.Trim() }
    $resolvedSize       = if ($FontSize -lt 9) { 9.0 } elseif ($FontSize -gt 24) { 24.0 } else { [Math]::Round($FontSize, 1) }
    $resolvedLineHeight = Get-SentinelHudResolvedLogLineHeight -FontSize $resolvedSize

    $script:SentinelLogFontFamily = $resolvedFamily
    $script:SentinelLogFontSize   = $resolvedSize

    if ($Controls.ContainsKey('lstLog') -and $null -ne $Controls.lstLog) {
        $Controls.lstLog.FontFamily = [System.Windows.Media.FontFamily]::new($resolvedFamily)
        $Controls.lstLog.FontSize   = $resolvedSize
        [System.Windows.Media.TextOptions]::SetTextFormattingMode($Controls.lstLog, [System.Windows.Media.TextFormattingMode]::Ideal)
        [System.Windows.Media.TextOptions]::SetTextRenderingMode($Controls.lstLog,  [System.Windows.Media.TextRenderingMode]::ClearType)
        [System.Windows.Media.TextOptions]::SetTextHintingMode($Controls.lstLog,    [System.Windows.Media.TextHintingMode]::Fixed)

        foreach ($item in @($Controls.lstLog.Items)) {
            $tb = $null
            if ($item -is [System.Windows.Controls.Border] -and $item.Child -is [System.Windows.Controls.TextBlock]) {
                $tb = [System.Windows.Controls.TextBlock]$item.Child
            }
            elseif ($item -is [System.Windows.Controls.TextBlock]) {
                $tb = [System.Windows.Controls.TextBlock]$item
            }

            if ($null -ne $tb) {
                $tb.FontFamily           = [System.Windows.Media.FontFamily]::new($resolvedFamily)
                $tb.FontSize             = $resolvedSize
                $tb.LineStackingStrategy = [System.Windows.LineStackingStrategy]::BlockLineHeight
                $tb.LineHeight           = $resolvedLineHeight
                $tb.SnapsToDevicePixels  = $true
                $tb.UseLayoutRounding    = $true
                [System.Windows.Media.TextOptions]::SetTextFormattingMode($tb, [System.Windows.Media.TextFormattingMode]::Ideal)
                [System.Windows.Media.TextOptions]::SetTextRenderingMode($tb,  [System.Windows.Media.TextRenderingMode]::ClearType)
                [System.Windows.Media.TextOptions]::SetTextHintingMode($tb,    [System.Windows.Media.TextHintingMode]::Fixed)
            }
        }
    }
}

function global:Set-SentinelHudInputsEnabled {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Controls,

        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )

    $controlsToToggle = @(
        'cmbBundleMode',
        'cmbRouteMode',
        'cmbProvider',
        'cmbAIPromptMode',
        'txtExecutorTarget',
        'chkSendToAI',
        'chkDeterministicDirector',
        'trvFiles',
        'btnSelectAll',
        'btnSelectNone',
        'btnRun'
    )

    foreach ($name in $controlsToToggle) {
        if ($Controls.ContainsKey($name) -and $null -ne $Controls[$name]) {
            $Controls[$name].IsEnabled = $Enabled
        }
    }
}

function global:Update-SentinelSelectionSummary {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Controls,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$SelectedItems,

        [Parameter(Mandatory = $true)]
        [int]$TotalAvailable
    )

    $mode = if ($Controls.cmbBundleMode.SelectedItem) { [string]$Controls.cmbBundleMode.SelectedItem.Tag } else { 'full' }
    if ($mode -ne 'sniper') {
        $Controls.txtSelectionSummary.Text = "Sniper desabilitado para o modo atual. Total elegível: $TotalAvailable arquivo(s)."
        return
    }

    $Controls.txtSelectionSummary.Text = "Marcados: $($SelectedItems.Count) de $TotalAvailable arquivo(s)."
}

function global:Update-SentinelSniperUiState {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Controls,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$SelectedItems,

        [Parameter(Mandatory = $true)]
        [int]$TotalAvailable
    )

    $isSniper = $false
    if ($Controls.cmbBundleMode.SelectedItem) {
        $isSniper = ([string]$Controls.cmbBundleMode.SelectedItem.Tag -eq 'sniper')
    }

    $Controls.trvFiles.IsEnabled = $isSniper
    $Controls.btnSelectAll.IsEnabled = $isSniper
    $Controls.btnSelectNone.IsEnabled = $isSniper

    Update-SentinelSelectionSummary -Controls $Controls -SelectedItems $SelectedItems -TotalAvailable $TotalAvailable
}

function global:New-SentinelTreeNode {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [bool]$IsDirectory
    )

    return [pscustomobject]@{
        Name         = $Name
        RelativePath = $RelativePath
        IsDirectory  = $IsDirectory
        Parent       = $null
        Children     = [System.Collections.Generic.List[object]]::new()
        TreeViewItem = $null
        CheckBox     = $null
    }
}

function global:Get-SentinelTreeRootNodes {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$RelativePaths
    )

    $rootNodes = [System.Collections.Generic.List[object]]::new()
    $nodeMap = @{}

    foreach ($relativePath in @($RelativePaths)) {
        if ([string]::IsNullOrWhiteSpace($relativePath)) {
            continue
        }

        $normalizedPath = ($relativePath -replace '[\\/]+', [string][System.IO.Path]::DirectorySeparatorChar).Trim([System.IO.Path]::DirectorySeparatorChar)
        if ([string]::IsNullOrWhiteSpace($normalizedPath)) {
            continue
        }

        $segments = $normalizedPath -split '[\\/]'
        $currentParent = $null
        $currentPath = ''

        for ($index = 0; $index -lt $segments.Count; $index++) {
            $segment = [string]$segments[$index]
            if ([string]::IsNullOrWhiteSpace($segment)) {
                continue
            }

            if ([string]::IsNullOrWhiteSpace($currentPath)) {
                $currentPath = $segment
            }
            else {
                $currentPath = Join-Path -Path $currentPath -ChildPath $segment
            }

            if (-not $nodeMap.ContainsKey($currentPath)) {
                $isDirectory = $index -lt ($segments.Count - 1)
                $node = New-SentinelTreeNode -Name $segment -RelativePath $currentPath -IsDirectory $isDirectory

                if ($null -eq $currentParent) {
                    $rootNodes.Add($node)
                }
                else {
                    $node.Parent = $currentParent
                    $currentParent.Children.Add($node)
                }

                $nodeMap[$currentPath] = $node
            }

            $currentParent = $nodeMap[$currentPath]
        }
    }

    return @($rootNodes)
}

function global:Get-SentinelOrderedChildNodes {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.IEnumerable]$Nodes
    )

    return @(
        $Nodes |
        Sort-Object @{ Expression = { [bool]$_.IsDirectory }; Descending = $true }, @{ Expression = { [string]$_.Name }; Descending = $false }
    )
}

function global:Set-SentinelTreeNodeCheckedStateRecursive {
    param(
        [Parameter(Mandatory = $true)]
        $Node,

        [Parameter(Mandatory = $true)]
        [bool]$IsChecked
    )

    if ($Node.CheckBox) {
        $Node.CheckBox.IsChecked = $IsChecked
    }

    foreach ($childNode in @($Node.Children)) {
        Set-SentinelTreeNodeCheckedStateRecursive -Node $childNode -IsChecked $IsChecked
    }
}

function global:Update-SentinelTreeAncestorCheckedState {
    param(
        [AllowNull()]
        $Node
    )

    $currentNode = $Node
    while ($null -ne $currentNode) {
        $childStates = @(
            @($currentNode.Children) |
            ForEach-Object {
                if ($_.CheckBox) { $_.CheckBox.IsChecked } else { $false }
            }
        )

        $allChecked = $true
        $allUnchecked = $true

        foreach ($childState in $childStates) {
            if ($childState -ne $true) {
                $allChecked = $false
            }

            if ($childState -ne $false) {
                $allUnchecked = $false
            }
        }

        $nextState = if ($allChecked) {
            $true
        }
        elseif ($allUnchecked) {
            $false
        }
        else {
            $null
        }

        if ($currentNode.CheckBox) {
            $currentNode.CheckBox.IsChecked = $nextState
        }

        $currentNode = $currentNode.Parent
    }
}

function global:Add-SentinelCheckedLeafPaths {
    param(
        [Parameter(Mandatory = $true)]
        $Node,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$SelectedItems
    )

    if (-not $Node.IsDirectory) {
        if ($Node.CheckBox -and $Node.CheckBox.IsChecked -eq $true) {
            $null = $SelectedItems.Add([string]$Node.RelativePath)
        }

        return
    }

    foreach ($childNode in @($Node.Children)) {
        Add-SentinelCheckedLeafPaths -Node $childNode -SelectedItems $SelectedItems
    }
}

function global:Sync-SentinelSelectedItemsFromTree {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$RootNodes,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$SelectedItems
    )

    $SelectedItems.Clear()

    foreach ($rootNode in @($RootNodes)) {
        Add-SentinelCheckedLeafPaths -Node $rootNode -SelectedItems $SelectedItems
    }
}

function global:Invoke-SentinelTreeNodeToggle {
    param(
        [Parameter(Mandatory = $true)]
        $Node,

        [Parameter(Mandatory = $true)]
        [bool]$DesiredState,

        [Parameter(Mandatory = $true)]
        [hashtable]$TreeState,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$SelectedItems,

        [Parameter(Mandatory = $true)]
        [hashtable]$Controls,

        [Parameter(Mandatory = $true)]
        [int]$TotalAvailable
    )

    if ($TreeState.IsUpdating) {
        return
    }

    try {
        $TreeState.IsUpdating = $true
        Set-SentinelTreeNodeCheckedStateRecursive -Node $Node -IsChecked $DesiredState
        Update-SentinelTreeAncestorCheckedState -Node $Node.Parent
    }
    finally {
        $TreeState.IsUpdating = $false
    }

    Sync-SentinelSelectedItemsFromTree -RootNodes $TreeState.RootNodes -SelectedItems $SelectedItems
    Update-SentinelSelectionSummary -Controls $Controls -SelectedItems $SelectedItems -TotalAvailable $TotalAvailable
}

function global:Add-SentinelTreeViewNodes {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Items,

        [Parameter(Mandatory = $true)]
        [object[]]$Nodes,

        [Parameter(Mandatory = $true)]
        [hashtable]$TreeState,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$SelectedItems,

        [Parameter(Mandatory = $true)]
        [hashtable]$Controls,

        [Parameter(Mandatory = $true)]
        [int]$TotalAvailable
    )

    if ($null -eq $Items) {
        throw 'Coleção de itens do TreeView não informada.'
    }

    foreach ($node in @(Get-SentinelOrderedChildNodes -Nodes $Nodes)) {
        $treeViewItem = New-Object System.Windows.Controls.TreeViewItem
        $treeViewItem.Tag = $node
        $treeViewItem.IsExpanded = $false
        $treeViewItem.Focusable = $true

        $checkBox = New-Object System.Windows.Controls.CheckBox
        $checkBox.Content = $node.Name
        $checkBox.Tag = $node
        $checkBox.Foreground = [System.Windows.Media.Brushes]::White
        $checkBox.Margin = '0,2,0,2'
        $checkBox.VerticalAlignment = 'Center'
        $checkBox.IsThreeState = [bool]$node.IsDirectory

        if ($node.IsDirectory) {
            $checkBox.FontWeight = 'SemiBold'
        }

        $node.TreeViewItem = $treeViewItem
        $node.CheckBox = $checkBox
        $treeViewItem.Header = $checkBox

        $checkBox.Add_PreviewMouseLeftButtonDown({
                $TreeState.SelectedNode = $node
                if ($node.TreeViewItem) {
                    $node.TreeViewItem.IsSelected = $true
                    $node.TreeViewItem.Focus() | Out-Null
                }
            }.GetNewClosure())

        $checkBox.Add_Checked({
                if ($TreeState.IsUpdating) {
                    return
                }

                Invoke-SentinelTreeNodeToggle -Node $node -DesiredState $true -TreeState $TreeState -SelectedItems $SelectedItems -Controls $Controls -TotalAvailable $TotalAvailable
            }.GetNewClosure())

        $checkBox.Add_Unchecked({
                if ($TreeState.IsUpdating) {
                    return
                }

                Invoke-SentinelTreeNodeToggle -Node $node -DesiredState $false -TreeState $TreeState -SelectedItems $SelectedItems -Controls $Controls -TotalAvailable $TotalAvailable
            }.GetNewClosure())

        $treeViewItem.Add_Selected({
                $TreeState.SelectedNode = $node
            }.GetNewClosure())

        if ($node.IsDirectory -and @($node.Children).Count -gt 0) {
            Add-SentinelTreeViewNodes -Items $treeViewItem.Items -Nodes @($node.Children) -TreeState $TreeState -SelectedItems $SelectedItems -Controls $Controls -TotalAvailable $TotalAvailable
        }

        $null = $Items.Add($treeViewItem)
    }
}

function global:Set-SentinelTreeAllCheckedState {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$RootNodes,

        [Parameter(Mandatory = $true)]
        [bool]$IsChecked,

        [Parameter(Mandatory = $true)]
        [hashtable]$TreeState,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$SelectedItems,

        [Parameter(Mandatory = $true)]
        [hashtable]$Controls,

        [Parameter(Mandatory = $true)]
        [int]$TotalAvailable
    )

    try {
        $TreeState.IsUpdating = $true

        foreach ($rootNode in @($RootNodes)) {
            Set-SentinelTreeNodeCheckedStateRecursive -Node $rootNode -IsChecked $IsChecked
        }
    }
    finally {
        $TreeState.IsUpdating = $false
    }

    Sync-SentinelSelectedItemsFromTree -RootNodes $RootNodes -SelectedItems $SelectedItems
    Update-SentinelSelectionSummary -Controls $Controls -SelectedItems $SelectedItems -TotalAvailable $TotalAvailable
}

function global:Find-SentinelTreeNodeByRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Nodes,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    foreach ($node in @($Nodes)) {
        if ([string]::Equals([string]$node.RelativePath, $RelativePath, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $node
        }

        $childMatch = Find-SentinelTreeNodeByRelativePath -Nodes @($node.Children) -RelativePath $RelativePath
        if ($null -ne $childMatch) {
            return $childMatch
        }
    }

    return $null
}

function global:Set-SentinelBootstrapSelections {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$RootNodes,

        [Parameter(Mandatory = $true)]
        [string[]]$BootstrapSelectedItems,

        [Parameter(Mandatory = $true)]
        [hashtable]$TreeState,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$SelectedItems,

        [Parameter(Mandatory = $true)]
        [hashtable]$Controls,

        [Parameter(Mandatory = $true)]
        [int]$TotalAvailable
    )

    $normalizedBootstrap = @(
        @($BootstrapSelectedItems) |
        Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } |
        ForEach-Object { ([string]$_ -replace '[\\/]+', [string][System.IO.Path]::DirectorySeparatorChar).Trim([System.IO.Path]::DirectorySeparatorChar) } |
        Sort-Object -Unique
    )

    if (@($normalizedBootstrap).Count -le 0) {
        return
    }

    try {
        $TreeState.IsUpdating = $true

        foreach ($relativePath in $normalizedBootstrap) {
            $node = Find-SentinelTreeNodeByRelativePath -Nodes $RootNodes -RelativePath $relativePath
            if ($null -eq $node) {
                continue
            }

            if ($node.CheckBox) {
                $node.CheckBox.IsChecked = $true
            }

            Update-SentinelTreeAncestorCheckedState -Node $node.Parent
        }
    }
    finally {
        $TreeState.IsUpdating = $false
    }

    Sync-SentinelSelectedItemsFromTree -RootNodes $RootNodes -SelectedItems $SelectedItems
    Update-SentinelSelectionSummary -Controls $Controls -SelectedItems $SelectedItems -TotalAvailable $TotalAvailable
}

function global:Get-SentinelNamedControls {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Window]$Window
    )

    $names = @(
        'txtHeader',
        'txtSubHeader',
        'txtTargetPath',
        'txtRunState',
        'cmbBundleMode',
        'cmbRouteMode',
        'cmbProvider',
        'cmbAIPromptMode',
        'txtExecutorTarget',
        'chkSendToAI',
        'chkDeterministicDirector',
        'btnSelectAll',
        'btnSelectNone',
        'trvFiles',
        'lstLog',
        'btnCopyLogs',
        'txtSelectionSummary',
        'txtExecutionSummary',
        'txtFooterStatus',
        'btnRun',
        'btnClose'
    )

    $controls = @{}
    foreach ($name in $names) {
        $controls[$name] = $Window.FindName($name)
    }

    return $controls
}

function global:Assert-SentinelNamedControls {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Controls
    )

    $missing = @(
        $Controls.Keys | Where-Object { $null -eq $Controls[$_] }
    )

    if (@($missing).Count -gt 0) {
        throw "Controles obrigatórios não encontrados no XAML: $($missing -join ', ')"
    }
}

function global:New-SentinelHudSelectionItem {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$Tag
    )

    $item = New-Object System.Windows.Controls.ComboBoxItem
    $item.Content = $Label
    $item.Tag = $Tag
    return $item
}

function global:Set-SentinelSelectedComboByTag {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Controls.ComboBox]$ComboBox,

        [Parameter(Mandatory = $true)]
        [string]$TagValue
    )

    foreach ($item in @($ComboBox.Items)) {
        if ([string]$item.Tag -eq $TagValue) {
            $ComboBox.SelectedItem = $item
            return
        }
    }

    if ($ComboBox.Items.Count -gt 0 -and -not $ComboBox.SelectedItem) {
        $ComboBox.SelectedIndex = 0
    }
}

function global:Start-SentinelHudStreamReadTask {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.StreamReader]$Reader
    )

    return $Reader.ReadLineAsync()
}

function global:Clear-SentinelHudCompletedStreamTask {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [string]$TaskKey,

        [Parameter(Mandatory = $true)]
        [string]$ReaderKey,

        [Parameter(Mandatory = $true)]
        [System.Windows.Window]$Window,

        [Parameter(Mandatory = $true)]
        [System.Windows.Controls.ListBox]$LogList,

        [string]$Prefix = ''
    )

    while ($true) {
        $task = $State[$TaskKey]
        if ($null -eq $task -or -not $task.IsCompleted) {
            break
        }

        try {
            $line = $task.GetAwaiter().GetResult()
        }
        catch {
            Add-SentinelHudLogLine -Window $Window -LogList $LogList -Message ("Falha ao ler stream do processo: {0}" -f $_.Exception.Message)
            $State[$TaskKey] = $null
            break
        }

        if ($null -eq $line) {
            $State[$TaskKey] = $null
            break
        }

        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $message = if ([string]::IsNullOrWhiteSpace($Prefix)) { $line } else { "{0}{1}" -f $Prefix, $line }
            Add-SentinelHudLogLine -Window $Window -LogList $LogList -Message $message
        }

        $reader = $State[$ReaderKey]
        if ($null -eq $reader) {
            $State[$TaskKey] = $null
            break
        }

        $State[$TaskKey] = Start-SentinelHudStreamReadTask -Reader $reader
    }
}

function global:Read-SentinelHudRemainingStreamContent {
    param(
        [AllowNull()]
        [System.IO.StreamReader]$Reader,

        [Parameter(Mandatory = $true)]
        [System.Windows.Window]$Window,

        [Parameter(Mandatory = $true)]
        [System.Windows.Controls.ListBox]$LogList,

        [string]$Prefix = ''
    )

    if ($null -eq $Reader) {
        return
    }

    try {
        $remaining = $Reader.ReadToEnd()
    }
    catch {
        return
    }

    if ([string]::IsNullOrWhiteSpace($remaining)) {
        return
    }

    $lines = $remaining -split "`r?`n"
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $message = if ([string]::IsNullOrWhiteSpace($Prefix)) { $line } else { "{0}{1}" -f $Prefix, $line }
        Add-SentinelHudLogLine -Window $Window -LogList $LogList -Message $message
    }
}

function global:Complete-SentinelHudProcessRun {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Controls,

        [Parameter(Mandatory = $true)]
        [System.Windows.Window]$Window,

        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$SelectedItems,

        [Parameter(Mandatory = $true)]
        [string]$BundleMode,

        [Parameter(Mandatory = $true)]
        [string]$RouteMode,

        [Parameter(Mandatory = $true)]
        [string]$Provider,

        [Parameter(Mandatory = $true)]
        [string]$AIPromptMode,

        [Parameter(Mandatory = $true)]
        [bool]$SendToAI,

        [Parameter(Mandatory = $true)]
        [bool]$DeterministicDirector,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $process = $State.Process
    if ($null -eq $process) {
        return
    }

    $timer = $State.MonitorTimer
    if ($timer) {
        try {
            $timer.Stop()
        }
        catch {
        }
    }

    try {
        $process.WaitForExit()
    }
    catch {
    }

    Clear-SentinelHudCompletedStreamTask -State $State -TaskKey 'StdOutTask' -ReaderKey 'StdOutReader' -Window $Window -LogList $Controls.lstLog
    Clear-SentinelHudCompletedStreamTask -State $State -TaskKey 'StdErrTask' -ReaderKey 'StdErrReader' -Window $Window -LogList $Controls.lstLog -Prefix '[stderr] '
    Read-SentinelHudRemainingStreamContent -Reader $State.StdOutReader -Window $Window -LogList $Controls.lstLog
    Read-SentinelHudRemainingStreamContent -Reader $State.StdErrReader -Window $Window -LogList $Controls.lstLog -Prefix '[stderr] '

    try {
        $exitCode = $process.ExitCode
        $summary = @(
            "ExitCode: $exitCode"
            "Modo: $BundleMode"
            "Rota: $RouteMode"
            "Provider: $Provider"
            "Prompt IA: $AIPromptMode"
            "SendToAI: $SendToAI"
            "DeterministicDirector: $DeterministicDirector"
            "Selecionados no Sniper: $($SelectedItems.Count)"
            "Path: $TargetPath"
        ) -join [Environment]::NewLine

        Set-SentinelHudExecutionSummary -Window $Window -SummaryBox $Controls.txtExecutionSummary -Content $summary

        if ($exitCode -eq 0) {
            Set-SentinelHudFooterStatus -Window $Window -FooterStatus $Controls.txtFooterStatus -RunState $Controls.txtRunState -Message 'Execução concluída sem explodir. HUD mantida aberta.' -Badge 'Concluído'
        }
        else {
            Set-SentinelHudFooterStatus -Window $Window -FooterStatus $Controls.txtFooterStatus -RunState $Controls.txtRunState -Message ("Execução encerrada com falha. ExitCode={0}" -f $exitCode) -Badge 'Falhou'
        }
    }
    catch {
        Add-SentinelHudLogLine -Window $Window -LogList $Controls.lstLog -Message ("Falha no pós-processamento da execução: {0}" -f $_.Exception.Message)
        Set-SentinelHudFooterStatus -Window $Window -FooterStatus $Controls.txtFooterStatus -RunState $Controls.txtRunState -Message 'Execução finalizada, mas o pós-processamento da HUD falhou. Janela preservada.' -Badge 'Atenção'
    }
    finally {
        try {
            $process.Dispose()
        }
        catch {
        }

        $State.Process = $null
        $State.StdOutReader = $null
        $State.StdErrReader = $null
        $State.StdOutTask = $null
        $State.StdErrTask = $null
        $State.MonitorTimer = $null
        $State.ExitHandled = $false

        Set-SentinelHudInputsEnabled -Controls $Controls -Enabled $true
    }
}

function global:Start-SentinelHudProcessMonitoring {
    param(
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Process]$Process,

        [Parameter(Mandatory = $true)]
        [hashtable]$Controls,

        [Parameter(Mandatory = $true)]
        [System.Windows.Window]$Window,

        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$SelectedItems,

        [Parameter(Mandatory = $true)]
        [string]$BundleMode,

        [Parameter(Mandatory = $true)]
        [string]$RouteMode,

        [Parameter(Mandatory = $true)]
        [string]$Provider,

        [Parameter(Mandatory = $true)]
        [string]$AIPromptMode,

        [Parameter(Mandatory = $true)]
        [bool]$SendToAI,

        [Parameter(Mandatory = $true)]
        [bool]$DeterministicDirector,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    if (-not $Process.Start()) {
        throw 'Falha ao iniciar o processo do bundler headless.'
    }

    $State.Process = $Process
    $State.StdOutReader = $Process.StandardOutput
    $State.StdErrReader = $Process.StandardError
    $State.StdOutTask = Start-SentinelHudStreamReadTask -Reader $State.StdOutReader
    $State.StdErrTask = Start-SentinelHudStreamReadTask -Reader $State.StdErrReader
    $State.ExitHandled = $false

    $timer = [System.Windows.Threading.DispatcherTimer]::new()
    $timer.Interval = [TimeSpan]::FromMilliseconds(120)
    $timer.Add_Tick({
            try {
                Clear-SentinelHudCompletedStreamTask -State $State -TaskKey 'StdOutTask' -ReaderKey 'StdOutReader' -Window $Window -LogList $Controls.lstLog
                Clear-SentinelHudCompletedStreamTask -State $State -TaskKey 'StdErrTask' -ReaderKey 'StdErrReader' -Window $Window -LogList $Controls.lstLog -Prefix '[stderr] '

                if ($State.Process -and $State.Process.HasExited -and -not $State.ExitHandled) {
                    $State.ExitHandled = $true
                    Complete-SentinelHudProcessRun -Controls $Controls -Window $Window -State $State -SelectedItems $SelectedItems -BundleMode $BundleMode -RouteMode $RouteMode -Provider $Provider -AIPromptMode $AIPromptMode -SendToAI $SendToAI -DeterministicDirector $DeterministicDirector -TargetPath $TargetPath
                }
            }
            catch {
                try {
                    Add-SentinelHudLogLine -Window $Window -LogList $Controls.lstLog -Message ("Falha no monitoramento da execução: {0}" -f $_.Exception.Message)
                    Set-SentinelHudFooterStatus -Window $Window -FooterStatus $Controls.txtFooterStatus -RunState $Controls.txtRunState -Message 'Monitoramento da HUD falhou, mas a janela foi preservada.' -Badge 'Erro'
                }
                catch {
                }

                if ($State.MonitorTimer) {
                    try {
                        $State.MonitorTimer.Stop()
                    }
                    catch {
                    }
                }

                Set-SentinelHudInputsEnabled -Controls $Controls -Enabled $true
            }
        }.GetNewClosure())

    $State.MonitorTimer = $timer

    Add-SentinelHudLogLine -Window $Window -LogList $Controls.lstLog -Message ("Processo iniciado. PID={0}" -f $Process.Id)
    $timer.Start()

    return $Process
}

function global:New-SentinelHudProcess {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HeadlessScriptPath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [hashtable]$Controls,

        [Parameter(Mandatory = $true)]
        [System.Windows.Window]$Window,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$SelectedItems,

        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )

    $bundleMode = [string]$Controls.cmbBundleMode.SelectedItem.Tag
    $routeMode = [string]$Controls.cmbRouteMode.SelectedItem.Tag
    $provider = [string]$Controls.cmbProvider.SelectedItem.Tag
    $aiPromptMode = [string]$Controls.cmbAIPromptMode.SelectedItem.Tag
    $sendToAI = [bool]$Controls.chkSendToAI.IsChecked
    $deterministicDirector = [bool]$Controls.chkDeterministicDirector.IsChecked
    $executorTarget = [string]$Controls.txtExecutorTarget.Text

    if ($bundleMode -eq 'sniper' -and $SelectedItems.Count -le 0) {
        throw 'Modo Sniper exige ao menos um arquivo marcado. Milagre não compila.'
    }

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = Get-SentinelPwshPath
    $psi.WorkingDirectory = [System.IO.Path]::GetDirectoryName($HeadlessScriptPath)
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $psi.StandardErrorEncoding = [System.Text.UTF8Encoding]::new($false)
    $psi.CreateNoWindow = $true

    $null = $psi.ArgumentList.Add('-NoProfile')
    $null = $psi.ArgumentList.Add('-ExecutionPolicy')
    $null = $psi.ArgumentList.Add('Bypass')
    $null = $psi.ArgumentList.Add('-File')
    $null = $psi.ArgumentList.Add($HeadlessScriptPath)
    $null = $psi.ArgumentList.Add('-Path')
    $null = $psi.ArgumentList.Add($TargetPath)
    $null = $psi.ArgumentList.Add('-BundleMode')
    $null = $psi.ArgumentList.Add($bundleMode)
    $null = $psi.ArgumentList.Add('-RouteMode')
    $null = $psi.ArgumentList.Add($routeMode)
    $null = $psi.ArgumentList.Add('-Provider')
    $null = $psi.ArgumentList.Add($provider)
    $null = $psi.ArgumentList.Add('-ExecutorTarget')
    $null = $psi.ArgumentList.Add($executorTarget)
    $null = $psi.ArgumentList.Add('-AIPromptMode')
    $null = $psi.ArgumentList.Add($aiPromptMode)
    $null = $psi.ArgumentList.Add('-NonInteractive')

    if ($sendToAI) {
        $null = $psi.ArgumentList.Add('-SendToAI')
    }

    if ($deterministicDirector) {
        $null = $psi.ArgumentList.Add('-DeterministicDirector')
    }

    if ($bundleMode -eq 'sniper') {
        $null = $psi.ArgumentList.Add('-SelectedPaths')
        foreach ($item in $SelectedItems) {
            $null = $psi.ArgumentList.Add([string]$item)
        }
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $psi
    return $process
}

function global:Start-SentinelBundlerHud {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolkitDir,

        [Parameter(Mandatory = $true)]
        [string]$HeadlessScriptPath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    Assert-SentinelWpfRuntime
    Import-SentinelBundlerModules -ToolkitDir $ToolkitDir

    $resolvedTargetPath = [System.IO.Path]::GetFullPath($TargetPath)
    if (-not (Test-Path $resolvedTargetPath -PathType Container)) {
        throw "Pasta alvo não encontrada: $resolvedTargetPath"
    }

    $xamlPath = Join-Path $ToolkitDir 'lib\SentinelHud.xaml'
    if (-not (Test-Path $xamlPath -PathType Leaf)) {
        throw "XAML do HUD não encontrado: $xamlPath"
    }

    [xml]$xaml = [System.IO.File]::ReadAllText($xamlPath, [System.Text.Encoding]::UTF8)
    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    try {
        $window = [System.Windows.Markup.XamlReader]::Load($reader)
    }
    catch {
        $inner = if ($_.Exception.InnerException) { $_.Exception.InnerException.Message } else { $_.Exception.Message }
        throw "Falha ao carregar o XAML do HUD: $inner"
    }

    if ($null -eq $window) {
        throw 'Falha ao materializar a janela WPF do HUD.'
    }

    $controls = Get-SentinelNamedControls -Window $window
    Assert-SentinelNamedControls -Controls $controls

    $controls.txtHeader.Text = 'SENTINEL HUD — WPF'
    $controls.txtSubHeader.Text = 'Painel operacional denso. Preparação à esquerda, execução à direita. Sem gordura decorativa.'
    $controls.txtTargetPath.Text = "Path: $resolvedTargetPath"
    $controls.txtRunState.Text = 'Concluído'
    $controls.txtFooterStatus.Text = 'Execução concluída sem explodir. HUD mantida aberta.'

    $availableFiles = @(Get-SentinelRelevantFiles -TargetPath $resolvedTargetPath)

    $controls.cmbBundleMode.Items.Clear()
    $controls.cmbRouteMode.Items.Clear()
    $controls.cmbProvider.Items.Clear()
    $controls.cmbAIPromptMode.Items.Clear()

    foreach ($item in @(
            (New-SentinelHudSelectionItem -Label 'Full Vibe / Bundle' -Tag 'full'),
            (New-SentinelHudSelectionItem -Label 'Blueprint / Inteligente' -Tag 'blueprint'),
            (New-SentinelHudSelectionItem -Label 'Sniper / Manual' -Tag 'sniper')
        )) {
        $null = $controls.cmbBundleMode.Items.Add($item)
    }

    foreach ($item in @(
            (New-SentinelHudSelectionItem -Label 'Via Diretor' -Tag 'director'),
            (New-SentinelHudSelectionItem -Label 'Direto para Executor' -Tag 'executor')
        )) {
        $null = $controls.cmbRouteMode.Items.Add($item)
    }

    foreach ($item in @(
            (New-SentinelHudSelectionItem -Label 'Groq' -Tag 'groq'),
            (New-SentinelHudSelectionItem -Label 'Gemini' -Tag 'gemini'),
            (New-SentinelHudSelectionItem -Label 'OpenAI' -Tag 'openai'),
            (New-SentinelHudSelectionItem -Label 'Anthropic' -Tag 'anthropic')
        )) {
        $null = $controls.cmbProvider.Items.Add($item)
    }

    foreach ($item in @(
            (New-SentinelHudSelectionItem -Label 'Default' -Tag 'default'),
            (New-SentinelHudSelectionItem -Label 'Template' -Tag 'template'),
            (New-SentinelHudSelectionItem -Label 'Expert Override' -Tag 'expert')
        )) {
        $null = $controls.cmbAIPromptMode.Items.Add($item)
    }

    $bootstrapSelectedItems = @()
    if (Get-Variable -Scope Script -Name SentinelHudBootstrapSelectedItems -ErrorAction SilentlyContinue) {
        $bootstrapSelectedItems = @($script:SentinelHudBootstrapSelectedItems)
    }

    if (@($bootstrapSelectedItems).Count -gt 0) {
        Set-SentinelSelectedComboByTag -ComboBox $controls.cmbBundleMode -TagValue 'sniper'
    }
    else {
        Set-SentinelSelectedComboByTag -ComboBox $controls.cmbBundleMode -TagValue 'blueprint'
    }

    Set-SentinelSelectedComboByTag -ComboBox $controls.cmbRouteMode -TagValue 'executor'
    Set-SentinelSelectedComboByTag -ComboBox $controls.cmbProvider -TagValue 'groq'
    Set-SentinelSelectedComboByTag -ComboBox $controls.cmbAIPromptMode -TagValue 'default'
    $controls.txtExecutorTarget.Text = 'ChatGPT'

    $selectedItems = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $treeState = @{
        RootNodes    = @(Get-SentinelTreeRootNodes -RelativePaths $availableFiles)
        IsUpdating   = $false
        SelectedNode = $null
    }

    $controls.trvFiles.Items.Clear()
    Add-SentinelTreeViewNodes -Items $controls.trvFiles.Items -Nodes $treeState.RootNodes -TreeState $treeState -SelectedItems $selectedItems -Controls $controls -TotalAvailable $availableFiles.Count

    if (@($bootstrapSelectedItems).Count -gt 0) {
        Set-SentinelBootstrapSelections -RootNodes $treeState.RootNodes -BootstrapSelectedItems $bootstrapSelectedItems -TreeState $treeState -SelectedItems $selectedItems -Controls $controls -TotalAvailable $availableFiles.Count
    }

    $state = @{
        Process      = $null
        StdOutReader = $null
        StdErrReader = $null
        StdOutTask   = $null
        StdErrTask   = $null
        MonitorTimer = $null
        ExitHandled  = $false
        AllowClose   = $false
    }

    Update-SentinelSniperUiState -Controls $controls -SelectedItems $selectedItems -TotalAvailable $availableFiles.Count
    $initialSummary = @(
        'ExitCode: 0'
        'Modo: blueprint'
        'Rota: executor'
        'Provider: groq'
        'Prompt IA: default'
        'SendToAI: False'
        'DeterministicDirector: False'
        'Selecionados no Sniper: 0'
        "Path: $resolvedTargetPath"
    ) -join [Environment]::NewLine

    Set-SentinelHudExecutionSummary -Window $window -SummaryBox $controls.txtExecutionSummary -Content $initialSummary

    # Auto-select the best available monospace font and apply it
    $script:SentinelLogFontFamily = Get-SentinelHudBestLogFont
    Set-SentinelHudLogTypography -Controls $controls -FontFamily $script:SentinelLogFontFamily -FontSize $script:SentinelLogFontSize

    Add-SentinelHudLogLine -Window $window -LogList $controls.lstLog -Message 'HUD carregado.'
    Add-SentinelHudLogLine -Window $window -LogList $controls.lstLog -Message ("Arquivos elegíveis detectados: {0}" -f $availableFiles.Count)

    $controls.cmbBundleMode.Add_SelectionChanged({
            Update-SentinelSniperUiState -Controls $controls -SelectedItems $selectedItems -TotalAvailable $availableFiles.Count
        }.GetNewClosure())

    $controls.trvFiles.Add_PreviewKeyDown({
            param($eventSender, $uiEventArgs)

            $currentNode = $treeState.SelectedNode
            if ($null -eq $currentNode) {
                return
            }

            switch ($uiEventArgs.Key) {
                ([System.Windows.Input.Key]::Space) {
                    if ($null -eq $currentNode.CheckBox) {
                        return
                    }

                    $desiredState = -not ($currentNode.CheckBox.IsChecked -eq $true)
                    Invoke-SentinelTreeNodeToggle -Node $currentNode -DesiredState $desiredState -TreeState $treeState -SelectedItems $selectedItems -Controls $controls -TotalAvailable $availableFiles.Count
                    $uiEventArgs.Handled = $true
                    break
                }
                ([System.Windows.Input.Key]::Right) {
                    if ($currentNode.IsDirectory -and $currentNode.TreeViewItem) {
                        $currentNode.TreeViewItem.IsExpanded = $true
                        $uiEventArgs.Handled = $true
                    }
                    break
                }
                ([System.Windows.Input.Key]::Left) {
                    if ($currentNode.IsDirectory -and $currentNode.TreeViewItem) {
                        $currentNode.TreeViewItem.IsExpanded = $false
                        $uiEventArgs.Handled = $true
                    }
                    break
                }
            }
        }.GetNewClosure())

    $controls.btnSelectAll.Add_Click({
            Set-SentinelTreeAllCheckedState -RootNodes $treeState.RootNodes -IsChecked $true -TreeState $treeState -SelectedItems $selectedItems -Controls $controls -TotalAvailable $availableFiles.Count
        }.GetNewClosure())

    $controls.btnSelectNone.Add_Click({
            Set-SentinelTreeAllCheckedState -RootNodes $treeState.RootNodes -IsChecked $false -TreeState $treeState -SelectedItems $selectedItems -Controls $controls -TotalAvailable $availableFiles.Count
        }.GetNewClosure())

    $controls.btnRun.Add_Click({
            try {
                $state.AllowClose = $false
                Set-SentinelHudInputsEnabled -Controls $controls -Enabled $false
                Set-SentinelHudFooterStatus -Window $window -FooterStatus $controls.txtFooterStatus -RunState $controls.txtRunState -Message 'Disparando engine headless...' -Badge 'Executando'
                Add-SentinelHudLogLine -Window $window -LogList $controls.lstLog -Message 'Inicializando execução...'

                $process = New-SentinelHudProcess -HeadlessScriptPath $HeadlessScriptPath -TargetPath $resolvedTargetPath -Controls $controls -Window $window -SelectedItems $selectedItems -State $state
                Start-SentinelHudProcessMonitoring -Process $process -Controls $controls -Window $window -State $state -SelectedItems $selectedItems -BundleMode ([string]$controls.cmbBundleMode.SelectedItem.Tag) -RouteMode ([string]$controls.cmbRouteMode.SelectedItem.Tag) -Provider ([string]$controls.cmbProvider.SelectedItem.Tag) -AIPromptMode ([string]$controls.cmbAIPromptMode.SelectedItem.Tag) -SendToAI ([bool]$controls.chkSendToAI.IsChecked) -DeterministicDirector ([bool]$controls.chkDeterministicDirector.IsChecked) -TargetPath $resolvedTargetPath | Out-Null
            }
            catch {
                Set-SentinelHudInputsEnabled -Controls $controls -Enabled $true
                Set-SentinelHudFooterStatus -Window $window -FooterStatus $controls.txtFooterStatus -RunState $controls.txtRunState -Message $_.Exception.Message -Badge 'Erro'
                Add-SentinelHudLogLine -Window $window -LogList $controls.lstLog -Message ("Falha ao iniciar execução: {0}" -f $_.Exception.Message)
            }
        }.GetNewClosure())

    # Captura a referência do StringBuilder como variável local antes da closure.
    # GetNewClosure() cria um módulo interno onde $script: aponta para o escopo
    # DESSE módulo, não para o SentinelHud.ps1 — então $script:SentinelLogBuffer
    # dentro do handler seria um objeto diferente (vazio). Como StringBuilder é
    # passado por referência, $logBufferRef sempre lê o conteúdo atualizado.
    $logBufferRef = $script:SentinelLogBuffer

    $controls.btnCopyLogs.Add_Click({
            if ($logBufferRef -and $logBufferRef.Length -gt 0) {
                $logText = $logBufferRef.ToString()
                try {
                    # SetDataObject($data, $true) persiste o conteúdo no clipboard após a janela fechar.
                    # Dispatcher.Invoke garante execução na thread STA do WPF, evitando falhas de COM.
                    $window.Dispatcher.Invoke([Action]{
                        [System.Windows.Clipboard]::SetDataObject($logText, $true)
                    })
                    Set-SentinelHudFooterStatus -Window $window -FooterStatus $controls.txtFooterStatus -RunState $controls.txtRunState -Message 'Logs copiados para a área de transferência.' -Badge $controls.txtRunState.Text
                }
                catch {
                    Add-SentinelHudLogLine -Window $window -LogList $controls.lstLog -Message "Falha ao copiar logs: $($_.Exception.Message)"
                }
            }
            else {
                Set-SentinelHudFooterStatus -Window $window -FooterStatus $controls.txtFooterStatus -RunState $controls.txtRunState -Message 'Nenhum log disponível para copiar.' -Badge $controls.txtRunState.Text
            }
        }.GetNewClosure())

    $controls.btnClose.Add_Click({
            $state.AllowClose = $true
            $window.Close()
        }.GetNewClosure())

    $window.Add_Closing({
            param($eventSender, $uiEventArgs)

            if (-not $state.AllowClose) {
                $uiEventArgs.Cancel = $true
                Set-SentinelHudFooterStatus -Window $window -FooterStatus $controls.txtFooterStatus -RunState $controls.txtRunState -Message 'HUD preservada. Use o botão Fechar para encerrar manualmente.' -Badge 'Ativa'
                Add-SentinelHudLogLine -Window $window -LogList $controls.lstLog -Message 'Tentativa de fechamento automático bloqueada.'
                return
            }

            if ($state.MonitorTimer) {
                try {
                    $state.MonitorTimer.Stop()
                }
                catch {
                }
            }

            if ($state.Process -and -not $state.Process.HasExited) {
                try {
                    $state.Process.Kill()
                }
                catch {
                }
            }
        }.GetNewClosure())

    $null = $window.ShowDialog()
}