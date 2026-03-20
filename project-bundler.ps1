# VIBE AI TOOLKIT - BUNDLER, BLUEPRINT & SELECTIVE
# =================================================================

[CmdletBinding()]
param([string]$Path = ".")

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-Location $Path

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
    [Win32]::ShowWindow($consoleHandle, 0) | Out-Null
}

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

function Resolve-AIPromptModeFromUI {
    param(
        [System.Windows.Forms.RadioButton]$RbDefault,
        [System.Windows.Forms.RadioButton]$RbCustom
    )

    if ($RbCustom.Checked) { return "custom" }
    return "default"
}

function Resolve-AIFlowModeFromUI {
    param(
        [System.Windows.Forms.RadioButton]$RbDirector,
        [System.Windows.Forms.RadioButton]$RbExecutor
    )

    if ($RbExecutor.Checked) { return "executor" }
    return "director"
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

$panelAIPromptMode = New-Object System.Windows.Forms.GroupBox
$panelAIPromptMode.Text = "Geração Final com IA"
$panelAIPromptMode.ForeColor = $ThemePink
$panelAIPromptMode.BackColor = $ThemePanel
$panelAIPromptMode.Size = New-Object System.Drawing.Size(824, 148)
$panelAIPromptMode.Location = New-Object System.Drawing.Point(18, 430)
$panelAIPromptMode.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelAIPromptMode.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
$panelAIPromptMode.Visible = $false
$form.Controls.Add($panelAIPromptMode)

$lblAIFlowMode = New-Object System.Windows.Forms.Label
$lblAIFlowMode.Text = "Fluxo final"
$lblAIFlowMode.ForeColor = $ThemeCyan
$lblAIFlowMode.BackColor = $ThemePanel
$lblAIFlowMode.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$lblAIFlowMode.AutoSize = $true
$lblAIFlowMode.Location = New-Object System.Drawing.Point(18, 30)
$panelAIPromptMode.Controls.Add($lblAIFlowMode)

$rbAIFlowDirector = New-Object System.Windows.Forms.RadioButton
$rbAIFlowDirector.Text = "Via Diretor"
$rbAIFlowDirector.ForeColor = $ThemeText
$rbAIFlowDirector.BackColor = $ThemePanel
$rbAIFlowDirector.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbAIFlowDirector.Location = New-Object System.Drawing.Point(18, 52)
$rbAIFlowDirector.Size = New-Object System.Drawing.Size(140, 24)
$rbAIFlowDirector.Checked = $true
$panelAIPromptMode.Controls.Add($rbAIFlowDirector)

$rbAIFlowExecutor = New-Object System.Windows.Forms.RadioButton
$rbAIFlowExecutor.Text = "Direto para Executor"
$rbAIFlowExecutor.ForeColor = $ThemeText
$rbAIFlowExecutor.BackColor = $ThemePanel
$rbAIFlowExecutor.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbAIFlowExecutor.Location = New-Object System.Drawing.Point(180, 52)
$rbAIFlowExecutor.Size = New-Object System.Drawing.Size(180, 24)
$panelAIPromptMode.Controls.Add($rbAIFlowExecutor)

$lblAIFlowHint = New-Object System.Windows.Forms.Label
$lblAIFlowHint.Text = "Via Diretor mantém o fluxo atual. Direto para Executor gera um contexto final para a IA executora atuar sem intermediação do Diretor."
$lblAIFlowHint.ForeColor = $ThemeMuted
$lblAIFlowHint.BackColor = $ThemePanel
$lblAIFlowHint.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblAIFlowHint.AutoSize = $true
$lblAIFlowHint.Location = New-Object System.Drawing.Point(18, 76)
$panelAIPromptMode.Controls.Add($lblAIFlowHint)

$lblAIPromptMode = New-Object System.Windows.Forms.Label
$lblAIPromptMode.Text = "SystemPrompt"
$lblAIPromptMode.ForeColor = $ThemeCyan
$lblAIPromptMode.BackColor = $ThemePanel
$lblAIPromptMode.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$lblAIPromptMode.AutoSize = $true
$lblAIPromptMode.Location = New-Object System.Drawing.Point(18, 100)
$panelAIPromptMode.Controls.Add($lblAIPromptMode)

$rbPromptModeDefault = New-Object System.Windows.Forms.RadioButton
$rbPromptModeDefault.Text = "Modo padrão"
$rbPromptModeDefault.ForeColor = $ThemeText
$rbPromptModeDefault.BackColor = $ThemePanel
$rbPromptModeDefault.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbPromptModeDefault.Location = New-Object System.Drawing.Point(18, 122)
$rbPromptModeDefault.Size = New-Object System.Drawing.Size(140, 24)
$rbPromptModeDefault.Checked = $true
$panelAIPromptMode.Controls.Add($rbPromptModeDefault)

$rbPromptModeCustom = New-Object System.Windows.Forms.RadioButton
$rbPromptModeCustom.Text = "Modo personalizado"
$rbPromptModeCustom.ForeColor = $ThemeText
$rbPromptModeCustom.BackColor = $ThemePanel
$rbPromptModeCustom.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$rbPromptModeCustom.Location = New-Object System.Drawing.Point(180, 122)
$rbPromptModeCustom.Size = New-Object System.Drawing.Size(180, 24)
$panelAIPromptMode.Controls.Add($rbPromptModeCustom)

$lblAIPromptModeHint = New-Object System.Windows.Forms.Label
$lblAIPromptModeHint.Text = "No modo padrão, o toolkit usa o systemPrompt nativo do fluxo selecionado. No modo personalizado, o HUD envia o systemPrompt digitado abaixo."
$lblAIPromptModeHint.ForeColor = $ThemeMuted
$lblAIPromptModeHint.BackColor = $ThemePanel
$lblAIPromptModeHint.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblAIPromptModeHint.AutoSize = $true
$lblAIPromptModeHint.Location = New-Object System.Drawing.Point(18, 146)
$panelAIPromptMode.Controls.Add($lblAIPromptModeHint)

$lblCustomSystemPrompt = New-Object System.Windows.Forms.Label
$lblCustomSystemPrompt.Text = "SystemPrompt personalizado"
$lblCustomSystemPrompt.ForeColor = $ThemeCyan
$lblCustomSystemPrompt.BackColor = $ThemePanel
$lblCustomSystemPrompt.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$lblCustomSystemPrompt.AutoSize = $true
$lblCustomSystemPrompt.Location = New-Object System.Drawing.Point(18, 172)
$lblCustomSystemPrompt.Visible = $false
$panelAIPromptMode.Controls.Add($lblCustomSystemPrompt)

$txtCustomSystemPrompt = New-Object System.Windows.Forms.TextBox
$txtCustomSystemPrompt.Multiline = $true
$txtCustomSystemPrompt.AcceptsReturn = $true
$txtCustomSystemPrompt.AcceptsTab = $true
$txtCustomSystemPrompt.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$txtCustomSystemPrompt.BackColor = $ThemePanelAlt
$txtCustomSystemPrompt.ForeColor = $ThemeText
$txtCustomSystemPrompt.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$txtCustomSystemPrompt.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtCustomSystemPrompt.Location = New-Object System.Drawing.Point(18, 194)
$txtCustomSystemPrompt.Size = New-Object System.Drawing.Size(788, 86)
$txtCustomSystemPrompt.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$txtCustomSystemPrompt.Visible = $false
$panelAIPromptMode.Controls.Add($txtCustomSystemPrompt)

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

function Update-AIPromptModeUi {
    $panelAIPromptMode.Visible = $chkSendToAI.Checked

    $customPromptVisible = $chkSendToAI.Checked -and $rbPromptModeCustom.Checked

    $lblCustomSystemPrompt.Visible = $customPromptVisible
    $txtCustomSystemPrompt.Visible = $customPromptVisible

    if ($customPromptVisible) {
        $panelAIPromptMode.Height = 292
    } else {
        $panelAIPromptMode.Height = 172
    }

    Update-ResponsiveLayout
}

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

    if ($panelAIPromptMode.Visible) {
        $panelAIPromptMode.Location = New-Object System.Drawing.Point($leftGap, ($chkY + 32))
        $panelAIPromptMode.Size = New-Object System.Drawing.Size($usableWidth, $panelAIPromptMode.Height)

        $lblAIFlowHint.MaximumSize = New-Object System.Drawing.Size(($panelAIPromptMode.Width - 36), 0)
        $lblAIPromptModeHint.MaximumSize = New-Object System.Drawing.Size(($panelAIPromptMode.Width - 36), 0)
        $txtCustomSystemPrompt.Size = New-Object System.Drawing.Size(($panelAIPromptMode.Width - 36), 86)

        $progressBarY = [int]($panelAIPromptMode.Bottom + 16)
    } else {
        $progressBarY = [int]($chkY + 48)
    }

    $progressBar.Location = New-Object System.Drawing.Point($leftGap, $progressBarY)
    $progressBar.Size = New-Object System.Drawing.Size($usableWidth, 12)

    $logTop = [int]($progressBar.Bottom + 10)
    $logHeight = [int][Math]::Max(120, ($clientHeight - $logTop - 20))
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

$chkSendToAI.Add_CheckedChanged({
    Update-AIPromptModeUi
})

$rbPromptModeDefault.Add_CheckedChanged({
    Update-AIPromptModeUi
})

$rbPromptModeCustom.Add_CheckedChanged({
    Update-AIPromptModeUi
})

$rbAIFlowDirector.Add_CheckedChanged({
    Update-AIPromptModeUi
})

$rbAIFlowExecutor.Add_CheckedChanged({
    Update-AIPromptModeUi
})

$form.Add_Shown({
    Set-SniperLayout -Visible $false
    Update-AIPromptModeUi
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
        [string]$PrimaryProviderValue,
        [string]$OutputRouteModeValue,
        [string]$CustomSystemPromptFilePath = $null
    )

    if (-not (Test-Path $AgentScriptPath)) {
        throw "Script groq-agent.ts não localizado."
    }

    $winner = [ordered]@{
        Provider = $null
        Model    = $null
    }

    $handleAgentLine = {
        param(
            [string]$Line,
            [System.Drawing.Color]$DefaultColor
        )

        if ([string]::IsNullOrWhiteSpace($Line)) {
            return
        }

        if ($Line -match '\[AI_RESULT\]\s+provider=([^;]+);model=(.+)$') {
            $winner.Provider = $Matches[1].Trim()
            $winner.Model = $Matches[2].Trim()
            return
        }

        Write-UILog -Message $Line -Color $DefaultColor
    }.GetNewClosure()

    $commandParts = @(
        "npx",
        "--quiet",
        "tsx",
        "`"$AgentScriptPath`"",
        "`"$BundlePath`"",
        "`"$ProjectNameValue`"",
        "`"$ExecutorTargetValue`"",
        "`"$BundleModeValue`"",
        "`"$PrimaryProviderValue`"",
        "`"$OutputRouteModeValue`""
    )

    if (-not [string]::IsNullOrWhiteSpace($CustomSystemPromptFilePath)) {
        $commandParts += "`"$CustomSystemPromptFilePath`""
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $process.StartInfo.FileName = "cmd.exe"
    $process.StartInfo.Arguments = "/c " + ($commandParts -join " ")
    $process.StartInfo.WorkingDirectory = (Get-Location).Path
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.EnvironmentVariables["DOTENV_CONFIG_SILENT"] = "true"
    $process.StartInfo.EnvironmentVariables["npm_config_update_notifier"] = "false"
    $process.StartInfo.EnvironmentVariables["NO_UPDATE_NOTIFIER"] = "1"

    if (-not $process.Start()) {
        throw "Falha ao iniciar o processo do agente de IA."
    }

    while (-not $process.HasExited) {
        while ($process.StandardOutput.Peek() -ge 0) {
            $line = $process.StandardOutput.ReadLine()
            & $handleAgentLine $line $ThemeCyan
        }

        while ($process.StandardError.Peek() -ge 0) {
            $line = $process.StandardError.ReadLine()
            & $handleAgentLine $line $ThemePink
        }

        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 100
    }

    $process.WaitForExit()

    while ($process.StandardOutput.Peek() -ge 0) {
        $line = $process.StandardOutput.ReadLine()
        & $handleAgentLine $line $ThemeCyan
    }

    while ($process.StandardError.Peek() -ge 0) {
        $line = $process.StandardError.ReadLine()
        & $handleAgentLine $line $ThemePink
    }

    if ($process.ExitCode -ne 0) {
        throw "groq-agent.ts finalizou com código $($process.ExitCode)."
    }

    $resultMetaPath = Join-Path (Split-Path $BundlePath -Parent) "_AI_RESULT_$ProjectNameValue.json"

    if (Test-Path $resultMetaPath) {
        try {
            $resultMeta = Get-Content $resultMetaPath -Raw -Encoding UTF8 | ConvertFrom-Json

            return [pscustomobject]@{
                WinnerProvider = if ($resultMeta.provider) { [string]$resultMeta.provider } else { $winner.Provider }
                WinnerModel    = if ($resultMeta.model) { [string]$resultMeta.model } else { $winner.Model }
                OutputPath     = if ($resultMeta.outputPath) { [string]$resultMeta.outputPath } else { $null }
            }
        } catch {
            return [pscustomobject]@{
                WinnerProvider = $winner.Provider
                WinnerModel    = $winner.Model
                OutputPath     = $null
            }
        }
    }

    return [pscustomobject]@{
        WinnerProvider = $winner.Provider
        WinnerModel    = $winner.Model
        OutputPath     = $null
    }
}

$btnRun.Add_Click({
    $currentChoice = Resolve-ChoiceFromUI -RbFull $rbFull -RbArchitect $rbArchitect -RbSniper $rbSniper
    $currentExecutorTarget = Resolve-ExecutorFromUI -RbAIStudio $rbAIStudio -RbAntigravity $rbAntigravity
    $currentAIProvider = Resolve-AIProviderFromUI -RbGroq $rbGroq -RbGemini $rbGemini -RbOpenAI $rbOpenAI -RbAnthropic $rbAnthropic
    $currentAIPromptMode = Resolve-AIPromptModeFromUI -RbDefault $rbPromptModeDefault -RbCustom $rbPromptModeCustom
    $currentAIFlowMode = Resolve-AIFlowModeFromUI -RbDirector $rbAIFlowDirector -RbExecutor $rbAIFlowExecutor

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

    if ($chkSendToAI.Checked -and $currentAIPromptMode -eq "custom" -and [string]::IsNullOrWhiteSpace($txtCustomSystemPrompt.Text)) {
        [System.Windows.Forms.MessageBox]::Show(
            "No modo personalizado, preencha o systemPrompt da IA.",
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

    $CustomSystemPromptFilePath = $null

    Set-UiBusy -Busy $true
    $logViewer.Clear()

    try {
        Write-UILog -Message "HUD energizado." -Color $ThemeCyan
        Write-UILog -Message "Projeto detectado: $ProjectName"
        Write-UILog -Message "Modo selecionado: $(if ($Choice -eq '1') { 'Full Vibe' } elseif ($Choice -eq '2') { 'Architect' } else { 'Sniper' })"
        Write-UILog -Message "Executor alvo: $ExecutorTarget"
        Write-UILog -Message "IA primária: $AIProvider"
        Write-UILog -Message "Arquivos na operação: $($FilesToProcess.Count)"
        Write-UILog -Message "Modo de geração final com IA: $(if ($SendToAI) { if ($currentAIPromptMode -eq 'custom') { 'Personalizado' } else { 'Padrão' } } else { 'Desabilitado' })"
        Write-UILog -Message "Fluxo final da IA: $(if ($SendToAI) { if ($currentAIFlowMode -eq 'executor') { 'Direto para Executor' } else { 'Via Diretor' } } else { 'Desabilitado' })"

        $HeaderContent = ""

        if ($Choice -eq '3') {
            $HeaderContent = @"
## Instruções
Você deve assumir a persona de DIRETOR TÉCNICO DE EXECUÇÃO.

POSICIONAMENTO:
- Este documento é uma SOURCE OF TRUTH PARCIAL do projeto
- O conteúdo representa apenas um RECORTE VISÍVEL do sistema
- O executor alvo final deste fluxo é: $ExecutorTarget

PAPEL DO DIRETOR:
- Ler este documento como base técnica de verdade
- Assimilar apenas stack, contratos, fluxos, componentes, arquivos, assinaturas e restrições efetivamente visíveis
- Aguardar a solicitação futura do usuário
- Converter a solicitação em um prompt técnico otimizado para um agente executor com capacidades agênticas
- Produzir instruções para uma IA que cria/edita arquivos, roda comandos, aplica mudanças e valida resultados

REGRAS DE INTERPRETAÇÃO OBRIGATÓRIAS:
- Considerar exclusivamente o que está visível neste recorte
- Não inferir arquivos, módulos, dependências, fluxos, regras, responsabilidades ou comportamentos fora do material apresentado
- Quando faltar contexto, declarar explicitamente a limitação no prompt gerado
- Restringir qualquer execução futura ao escopo observável neste documento
- Priorizar precisão, previsibilidade e zero impacto colateral

OBJETIVO DO DIRETOR:
Receber este recorte parcial, compreender o que está visível e, diante de uma solicitação futura do usuário, gerar um prompt otimizado para execução técnica segura e precisa, limitado ao escopo documentado, sem extrapolar contexto e sem modificar nada fora do que puder ser sustentado por evidência neste material.

TEMPLATE DE PROMPT QUE VOCÊ DEVE GERAR PARA O EXECUTOR:

## Instruções
CONTEXTO:
- Papel esperado: SENIOR_ENGINEERING_EXECUTOR
- Tarefa: executar alterações técnicas em código existente
- Prioridade: precisão, previsibilidade e zero impacto colateral
- Premissas: o projeto já possui contratos, identificadores e princípios de design que devem ser preservados
- Restrição adicional: atuar somente sobre o escopo visível neste recorte parcial

OBJETIVO:
Executar exatamente a alteração solicitada no escopo informado, mantendo compatibilidade com a base atual visível, sem regressões funcionais e sem modificar nada fora do pedido ou fora do recorte analisado.

REGRAS:
- Usar tipagem estrita quando a stack suportar
- Preservar contratos, assinaturas, identificadores e comportamento existente
- Não alterar arquitetura, layout, nomes ou fluxos fora do escopo explícito
- Não inferir dependências, arquivos ou comportamentos não documentados no recorte
- Priorizar eficiência e simplicidade, evitando abstrações e operações redundantes
- Tratar falhas explicitamente
- Controlar fluxos assíncronos corretamente
- Inserir logs apenas quando forem realmente necessários
- Não entregar conteúdo fragmentado
- Não incluir comentários supérfluos
- Responder de forma curta e técnica
- Código deve ser o artefato principal da resposta

ENTREGA:
- Implementação completa
- Pronta para uso
- Sem regressão
- Sem mudanças colaterais
- Restrita ao escopo visível
- Com o mínimo de texto explicativo

REGRA FINAL DO DIRETOR:
- O prompt gerado deve ser adaptado ao contexto real deste recorte
- O prompt nunca deve ser genérico
- O prompt deve deixar explícito o que é limitação de contexto
- O prompt deve impedir qualquer execução fora do material visível
"@
        } else {
            $HeaderContent = @"
## Instruções
Você deve assumir a persona de DIRETOR TÉCNICO DE EXECUÇÃO.

POSICIONAMENTO:
- Este documento é uma SOURCE OF TRUTH do projeto
- O conteúdo representa uma visão global ou estrutural ampla do sistema
- O executor alvo final deste fluxo é: $ExecutorTarget

PAPEL DO DIRETOR:
- Ler este documento como base técnica de verdade
- Assimilar stack, arquitetura, contratos, identificadores, fluxos, componentes, módulos e restrições observáveis
- Aguardar a solicitação futura do usuário
- Converter a solicitação em um prompt técnico otimizado para um agente executor com capacidades agênticas
- Produzir instruções para uma IA que cria/edita arquivos, roda comandos, aplica mudanças e valida resultados

REGRAS DE INTERPRETAÇÃO OBRIGATÓRIAS:
- Basear-se exclusivamente no que estiver documentado neste bundle
- Preservar contratos, identificadores, comportamento existente e princípios de design observáveis
- Não inventar arquitetura, dependências ou regras sem evidência no material
- Quando houver lacuna de contexto, explicitar a limitação no prompt gerado
- Priorizar precisão, previsibilidade e zero impacto colateral

OBJETIVO DO DIRETOR:
Receber esta Source of Truth, compreender o projeto e, diante de uma solicitação futura do usuário, gerar um prompt otimizado para execução técnica segura e precisa no código existente, respeitando a base atual e sem modificar nada fora do escopo solicitado.

TEMPLATE DE PROMPT QUE VOCÊ DEVE GERAR PARA O EXECUTOR:

## Instruções
CONTEXTO:
- Papel esperado: SENIOR_ENGINEERING_EXECUTOR
- Tarefa: executar alterações técnicas em código existente
- Prioridade: precisão, previsibilidade e zero impacto colateral
- Premissas: o projeto já possui contratos, identificadores e princípios de design que devem ser preservados

OBJETIVO:
Executar exatamente a alteração solicitada no escopo informado, mantendo compatibilidade com a base atual, sem regressões funcionais e sem modificar nada fora do pedido.

REGRAS:
- Usar tipagem estrita quando a stack suportar
- Preservar contratos, assinaturas, identificadores e comportamento existente
- Não alterar arquitetura, layout, nomes ou fluxos fora do escopo explícito
- Priorizar eficiência e simplicidade, evitando abstrações e operações redundantes
- Tratar falhas explicitamente
- Controlar fluxos assíncronos corretamente
- Inserir logs apenas quando forem realmente necessários
- Não entregar conteúdo fragmentado
- Não incluir comentários supérfluos
- Responder de forma curta e técnica
- Código deve ser o artefato principal da resposta

ENTREGA:
- Implementação completa
- Pronta para uso
- Sem regressão
- Sem mudanças colaterais
- Com o mínimo de texto explicativo

REGRA FINAL DO DIRETOR:
- O prompt gerado deve ser adaptado ao contexto real deste projeto
- O prompt nunca deve ser genérico
- O prompt deve considerar stack, padrões, contratos, restrições e limites observáveis neste documento
- O prompt deve orientar execução segura, precisa e sem impacto colateral
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

            if ($currentAIPromptMode -eq "custom") {
                $CustomSystemPromptFilePath = Join-Path ([System.IO.Path]::GetTempPath()) ("vibetoolkit-custom-systemprompt-" + [System.Guid]::NewGuid().ToString("N") + ".txt")
                [System.IO.File]::WriteAllText($CustomSystemPromptFilePath, $txtCustomSystemPrompt.Text, (New-Object System.Text.UTF8Encoding $false))
                Write-UILog -Message "Modo personalizado ativo: systemPrompt definido no HUD será enviado para a IA." -Color $ThemePink
            } else {
                Write-UILog -Message "Modo padrão ativo: usando o fluxo nativo configurado no agente." -Color $ThemeCyan
            }

            if ($currentAIFlowMode -eq "executor") {
                Write-UILog -Message "Fluxo direto para executor ativo: a saída final será preparada para a IA executora atuar sem passar pelo Diretor." -Color $ThemePink
            } else {
                Write-UILog -Message "Fluxo via Diretor ativo: a saída final continuará preparando a IA orquestradora no papel de Diretor." -Color $ThemeCyan
            }

            $AgentScript = Join-Path $ToolkitDir "groq-agent.ts"
            $BundleMode = if ($Choice -eq '1') { 'full' } elseif ($Choice -eq '2') { 'blueprint' } else { 'manual' }

            $AgentResult = Invoke-OrchestratorAgent `
                -AgentScriptPath $AgentScript `
                -BundlePath $OutputFullPath `
                -ProjectNameValue $ProjectName `
                -ExecutorTargetValue $ExecutorTarget `
                -BundleModeValue $BundleMode `
                -PrimaryProviderValue $AIProvider `
                -OutputRouteModeValue $currentAIFlowMode `
                -CustomSystemPromptFilePath $CustomSystemPromptFilePath

            $FinalPromptPath = $null

            if ($AgentResult -and $AgentResult.OutputPath -and (Test-Path $AgentResult.OutputPath)) {
                $FinalPromptPath = $AgentResult.OutputPath
            } else {
                $FallbackAiContextPath = Join-Path (Split-Path $OutputFullPath -Parent) "_AI_CONTEXT_$ProjectName.md"
                if (Test-Path $FallbackAiContextPath) {
                    $FinalPromptPath = $FallbackAiContextPath
                }
            }

            if ($FinalPromptPath) {
                $FinalSummarizedContent = Get-Content $FinalPromptPath -Raw -Encoding UTF8
                try {
                    $FinalSummarizedContent | Set-Clipboard
                    Write-UILog -Message "Prompt final preparado e copiado para o clipboard." -Color $ThemeSuccess
                } catch {
                    Write-UILog -Message "Prompt final preparado, mas não foi possível copiar para o clipboard." -Color $ThemePink
                }
            } else {
                Write-UILog -Message "Arquivo final da IA não foi localizado." -Color $ThemePink
            }

            if ($AgentResult -and $AgentResult.WinnerProvider) {
                Write-UILog -Message "Provider efetivo usado: $($AgentResult.WinnerProvider) | Modelo: $($AgentResult.WinnerModel)" -Color $ThemeSuccess
            } else {
                Write-UILog -Message "Provider efetivo não identificado no retorno do agente." -Color $ThemePink
            }

            if ($currentAIFlowMode -eq "executor") {
                Write-UILog -Message "Agora é só colar no seu executor." -Color $ThemeCyan
            } else {
                Write-UILog -Message "Agora é só colar no seu orquestrador." -Color $ThemeCyan
            }
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
        if ($CustomSystemPromptFilePath -and (Test-Path $CustomSystemPromptFilePath)) {
            Remove-Item $CustomSystemPromptFilePath -Force -ErrorAction SilentlyContinue
        }

        Set-UiBusy -Busy $false
    }
})

Write-UILog -Message "Pronto. Configure o modo, o executor e energize." -Color $ThemeCyan
[void]$form.ShowDialog()
