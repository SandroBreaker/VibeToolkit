# VIBE AI TOOLKIT - BUNDLER, BLUEPRINT & SELECTIVE
# =================================================================

[CmdletBinding()]
param([string]$Path = ".")

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-Location $Path

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

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
    ".py", ".java", ".cs", ".c", ".cpp", ".h", ".hpp", ".go", ".rb", ".php", ".rs", ".swift", ".kt", ".scala", ".dart", ".r", ".sh", ".bat", ".ps1"
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
                            ($Item.Name -notmatch "-[a-zA-Z0-9]{8,}\.") -and
                            ($Item.Name -notmatch "^_BUNDLER__") -and
                            ($Item.Name -notmatch "^_BLUEPRINT__") -and
                            ($Item.Name -notmatch "^_SELECTIVE__") -and
                            ($Item.Name -notmatch "^_AI_CONTEXT_")

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

$form = New-Object System.Windows.Forms.Form
$form.Text = "Vibe AI Toolkit"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(860, 820)
$form.MinimumSize = New-Object System.Drawing.Size(860, 820)
$form.MaximumSize = New-Object System.Drawing.Size(860, 1040)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.BackColor = $ThemeBg
$form.ForeColor = $ThemeText
$form.TopMost = $false

$script:IsDragging = $false
$script:DragCursor = [System.Drawing.Point]::Empty
$script:DragForm = [System.Drawing.Point]::Empty

$DragMouseDown = {
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:IsDragging = $true
        $script:DragCursor = [System.Windows.Forms.Cursor]::Position
        $script:DragForm = $form.Location
    }
}

$DragMouseMove = {
    if ($script:IsDragging) {
        $currentCursor = [System.Windows.Forms.Cursor]::Position
        $form.Location = New-Object System.Drawing.Point(
            ($script:DragForm.X + $currentCursor.X - $script:DragCursor.X),
            ($script:DragForm.Y + $currentCursor.Y - $script:DragCursor.Y)
        )
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
$form.Controls.Add($projectLabel)

$closeButton = New-Object System.Windows.Forms.Label
$closeButton.Text = "✕"
$closeButton.ForeColor = $ThemeText
$closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$closeButton.AutoSize = $true
$closeButton.Location = New-Object System.Drawing.Point(826, 9)
$closeButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$closeButton.Add_MouseEnter({ $closeButton.ForeColor = $ThemePink })
$closeButton.Add_MouseLeave({ $closeButton.ForeColor = $ThemeText })
$closeButton.Add_Click({ $form.Close() })
$titleBar.Controls.Add($closeButton)

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
$form.Controls.Add($chkSendToAI)

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
$form.Controls.Add($btnRun)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
$progressBar.MarqueeAnimationSpeed = 30
$progressBar.Size = New-Object System.Drawing.Size(824, 12)
$progressBar.Location = New-Object System.Drawing.Point(18, 444)
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
$form.Controls.Add($logViewer)

function Set-SniperLayout {
    param([bool]$Visible)

    $panelSniper.Visible = $Visible

    if ($Visible) {
        $form.Size = New-Object System.Drawing.Size(860, 1040)
        $form.MinimumSize = New-Object System.Drawing.Size(860, 1040)
        $chkSendToAI.Location = New-Object System.Drawing.Point(18, 628)
        $btnRun.Location = New-Object System.Drawing.Point(657, 622)
        $progressBar.Location = New-Object System.Drawing.Point(18, 676)
        $logViewer.Location = New-Object System.Drawing.Point(18, 698)
        $logViewer.Size = New-Object System.Drawing.Size(824, 300)
    } else {
        $form.Size = New-Object System.Drawing.Size(860, 820)
        $form.MinimumSize = New-Object System.Drawing.Size(860, 820)
        $chkSendToAI.Location = New-Object System.Drawing.Point(18, 396)
        $btnRun.Location = New-Object System.Drawing.Point(657, 390)
        $progressBar.Location = New-Object System.Drawing.Point(18, 444)
        $logViewer.Location = New-Object System.Drawing.Point(18, 466)
        $logViewer.Size = New-Object System.Drawing.Size(824, 316)
    }
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

Set-SniperLayout -Visible $false

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
        [string]$PrimaryProviderValue
    )

    if (-not (Test-Path $AgentScriptPath)) {
        throw "Script groq-agent.ts não localizado."
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $process.StartInfo.FileName = "cmd.exe"
    $process.StartInfo.Arguments = "/c npx --quiet tsx `"$AgentScriptPath`" `"$BundlePath`" `"$ProjectNameValue`" `"$ExecutorTargetValue`" `"$BundleModeValue`" `"$PrimaryProviderValue`""
    $process.StartInfo.WorkingDirectory = (Get-Location).Path
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true

    $env:DOTENV_CONFIG_SILENT = "true"

    if (-not $process.Start()) {
        throw "Falha ao iniciar o processo do agente de IA."
    }

    while (-not $process.HasExited) {
        while ($process.StandardOutput.Peek() -ge 0) {
            $line = $process.StandardOutput.ReadLine()
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                Write-UILog -Message $line -Color $ThemeCyan
            }
        }

        while ($process.StandardError.Peek() -ge 0) {
            $line = $process.StandardError.ReadLine()
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                Write-UILog -Message $line -Color $ThemePink
            }
        }

        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 100
    }

    while ($process.StandardOutput.Peek() -ge 0) {
        $line = $process.StandardOutput.ReadLine()
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            Write-UILog -Message $line -Color $ThemeCyan
        }
    }

    while ($process.StandardError.Peek() -ge 0) {
        $line = $process.StandardError.ReadLine()
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            Write-UILog -Message $line -Color $ThemePink
        }
    }

    $process.WaitForExit()

    if ($process.ExitCode -ne 0) {
        throw "groq-agent.ts finalizou com código $($process.ExitCode)."
    }
}

$btnRun.Add_Click({
    $currentChoice = Resolve-ChoiceFromUI -RbFull $rbFull -RbArchitect $rbArchitect -RbSniper $rbSniper
    $currentExecutorTarget = Resolve-ExecutorFromUI -RbAIStudio $rbAIStudio -RbAntigravity $rbAntigravity
    $currentAIProvider = Resolve-AIProviderFromUI -RbGroq $rbGroq -RbGemini $rbGemini -RbOpenAI $rbOpenAI -RbAnthropic $rbAnthropic

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

    Set-UiBusy -Busy $true
    $logViewer.Clear()

    try {
        Write-UILog -Message "HUD energizado." -Color $ThemeCyan
        Write-UILog -Message "Projeto detectado: $ProjectName"
        Write-UILog -Message "Modo selecionado: $(if ($Choice -eq '1') { 'Full Vibe' } elseif ($Choice -eq '2') { 'Architect' } else { 'Sniper' })"
        Write-UILog -Message "Executor alvo: $ExecutorTarget"
        Write-UILog -Message "IA primária: $AIProvider"
        Write-UILog -Message "Arquivos na operação: $($FilesToProcess.Count)"

        $HeaderContent = ""

        if ($ExecutorTarget -eq "AI Studio Apps") {
            $HeaderContent = @"
text
<system_instruction>
ROLE: SENIOR_ENGINEERING_EXECUTOR

OBJECTIVE:
Executar alterações técnicas com precisão, previsibilidade e zero impacto colateral.

NON_NEGOTIABLES:
- Tipagem estrita.
- Contratos claros.
- Princípios de design preservados.
- Nenhuma regressão funcional.
- Nenhuma modificação fora do escopo explícito.

PERFORMANCE_ENFORCEMENT:
- Eficiência antes de abstração.
- Evitar operações redundantes.
- Simplicidade como regra.

ERROR_POLICY:
- Falhas tratadas explicitamente.
- Assíncronos sempre controlados.
- Logs apenas quando necessários.

OUTPUT_RULES:
- Entrega completa.
- Nada fragmentado.
- Identificadores preservados.
- Sem comentários supérfluos.

INTERACTION_MODEL:
- Respostas curtas.
- Código como artefato principal.

FLOW:
1. Receber entrada.
2. Validar contexto.
3. Executar exatamente o solicitado.
4. Aguardar próxima instrução.

</system_instruction>
```
"@
        } else {
            $HeaderContent = @"
text
<system_instruction>
ROLE: SENIOR_ENGINEERING_EXECUTOR

OBJECTIVE:
Executar alterações técnicas com precisão, previsibilidade e zero impacto colateral.

NON_NEGOTIABLES:
- Tipagem estrita.
- Contratos claros.
- Princípios de design preservados.
- Nenhuma regressão funcional.
- Nenhuma modificação fora do escopo explícito.

PERFORMANCE_ENFORCEMENT:
- Eficiência antes de abstração.
- Evitar operações redundantes.
- Simplicidade como regra.

ERROR_POLICY:
- Falhas tratadas explicitamente.
- Assíncronos sempre controlados.
- Logs apenas quando necessários.

OUTPUT_RULES:
- Entrega completa.
- Nada fragmentado.
- Identificadores preservados.
- Sem comentários supérfluos.

INTERACTION_MODEL:
- Respostas curtas.
- Código como artefato principal.

FLOW:
1. Receber entrada.
2. Validar contexto.
3. Executar exatamente o solicitado.
4. Aguardar próxima instrução.

</system_instruction>
```
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
            $AgentScript = Join-Path $ToolkitDir "groq-agent.ts"
            $BundleMode = if ($Choice -eq '1') { 'full' } elseif ($Choice -eq '2') { 'blueprint' } else { 'manual' }

            Invoke-OrchestratorAgent -AgentScriptPath $AgentScript -BundlePath $OutputFullPath -ProjectNameValue $ProjectName -ExecutorTargetValue $ExecutorTarget -BundleModeValue $BundleMode -PrimaryProviderValue $AIProvider

            $FinalSummarizedContent = Get-Content $OutputFullPath -Raw -Encoding UTF8
            try {
                $FinalSummarizedContent | Set-Clipboard
                Write-UILog -Message "Prompt final preparado e copiado para o clipboard." -Color $ThemeSuccess
            } catch {
                Write-UILog -Message "Prompt final preparado, mas não foi possível copiar para o clipboard." -Color $ThemePink
            }
            Write-UILog -Message "Verifique no log acima qual provider venceu o fallback." -Color $ThemeCyan
            Write-UILog -Message "Agora é só colar no seu orquestrador." -Color $ThemeCyan
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
        Set-UiBusy -Busy $false
    }
})

Write-UILog -Message "Pronto. Configure o modo, o executor e energize." -Color $ThemeCyan
[void]$form.ShowDialog()
