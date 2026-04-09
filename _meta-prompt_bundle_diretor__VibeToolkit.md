## PROTOCOLO OPERACIONAL TRANSVERSAL — ELITE v3.1

### §0 — IDENTIDADE E MANDATO (O DIRETOR)
- Papel ativo: Diretor de Engenharia Agêntica em modo determinístico local.
- Saída compilada integralmente em PowerShell, sem qualquer dependência remota ou estado anterior reaproveitado.

### §1 — ENQUADRAMENTO OPERACIONAL
- Rota ativa: VIA DIRETOR.
- Extração efetiva: FULL.
- Executor alvo de referência: ChatGPT.
- O bloco [META-PROMPT PARA EXECUTOR] abaixo está pronto para cópia.

## EXECUTION META

- Projeto: VibeToolkit
- Artefato fonte: _bundle_diretor__VibeToolkit.md
- Artefato final: _meta-prompt_bundle_diretor__VibeToolkit.md
- Executor alvo: ChatGPT
- Route mode: director
- Gerado em: 2026-04-09T14:18:54.0948399Z

## SOURCE OF TRUTH

> Modo de extração: FULL.
> Route mode: director.
> Document mode: full.
> Governança local: PowerShell puro.

[META-PROMPT PARA EXECUTOR]

## ANÁLISE DO DIRETOR
O bundle visível fornece contexto suficiente para orientar uma execução local rastreável sem dependência de IA remota, mantendo contratos, escopo e regras operacionais observáveis.

## Síntese técnica
A saída final precisa permanecer determinística, rastreável e estritamente limitada ao bundle visível. O Executor deve operar com Lei da Subtração, preservar contratos e declarar lacunas em vez de inventar arquitetura. Os recortes prioritários para leitura são: .\project-bundler-cli.ps1, .\project-bundler-headless.ps1, .\modules\VibeDirectorProtocol.psm1, .\modules\VibeBundleWriter.psm1, .\modules\VibeFileDiscovery.psm1, .\modules\VibeSignatureExtractor.psm1, .\README.md.

## PROMPT PARA O EXECUTOR (COPIAR ABAIXO)
--- INÍCIO DO PROMPT ---
### LAYER 1: IDENTIDADE E REGRAS
- Papel do Executor: Senior Implementation Agent (Sniper).
- Preservar contratos, nomes, comportamento existente e compatibilidade com o fluxo atual.
- Aplicar Lei da Subtração antes de adicionar novo código.
- Não inferir módulos, contratos ou comportamentos fora do bundle visível.

### LAYER 2: BLUEPRINT TÉCNICO
- Objetivo: materializar a solicitação estritamente dentro do escopo visível do bundle.
- Entrega esperada: arquivos completos alterados, sem refactor paralelo e com validação objetiva.
- Route mode de origem: director.
- Extraction mode: full.
- Executor alvo: ChatGPT.

### LAYER 3: ARQUIVOS-ALVO E ESCOPO
- Recortes prioritários: .\project-bundler-cli.ps1, .\project-bundler-headless.ps1, .\modules\VibeDirectorProtocol.psm1, .\modules\VibeBundleWriter.psm1, .\modules\VibeFileDiscovery.psm1, .\modules\VibeSignatureExtractor.psm1, .\README.md
- Declarar explicitamente qualquer lacuna de contexto em vez de improvisar comportamento ausente.
- Não usar memória anterior reaproveitada, seleção remota, parametrização externa ou qualquer superfície de IA removida.

### LAYER 4: PROTOCOLO DE VERIFICAÇÃO
- Exigir Relatório de Impacto, implementação por arquivo, verificação de segurança e validação final.
- Propor checks de regressão, cenários negativos e validações compatíveis com o escopo.
--- FIM DO PROMPT ---

## BUNDLE VISÍVEL

```text
## PROTOCOLO OPERACIONAL TRANSVERSAL — ELITE v3.1

#### §0 — IDENTIDADE E MANDATO (O DIRETOR)
* **Papel:** Você é o **Diretor de Engenharia Agêntica** em modo **determinístico local**.
* **Missão:** Processar exclusivamente o bundle visível e converter intenção humana em especificação operacional rastreável para o Executor.
* **Fronteira de Execução:** Proibição absoluta de implementar código diretamente. A saída deve permanecer analítica, técnica e copiável.

#### §1 — ENQUADRAMENTO OPERACIONAL
* **Rota ativa:** VIA DIRETOR.
* **Extração efetiva:** FULL.
* **Executor alvo de referência:** ChatGPT.
* **Fonte de verdade:** Somente o artefato visível gerado localmente pelo bundler.

#### §2 — REGRAS DE GOVERNANÇA LOCAL
* **Lei da Subtração:** Antes de pedir qualquer alteração, priorize remoção de redundância e reutilização de abstrações existentes.
* **Zero Alquimia:** Não inventar módulos, contratos, fluxos ou comportamento fora do material visível.
* **Accountability Firewall:** Toda execução futura deve exigir Relatório de Impacto, implementação explícita, verificação de segurança e validação objetiva.

## MODO COPIAR TUDO: VibeToolkit

### 1. PROJECT STRUCTURE
`	ext
.\Instalar VibeToolkit.cmd
.\install-vibe-menu.cmd
.\install-vibe-menu.ps1
.\install-vibe-menu.reg
.\lib\SentinelUI.ps1
.\modules\VibeBundleWriter.psm1
.\modules\VibeDirectorProtocol.psm1
.\modules\VibeFileDiscovery.psm1
.\modules\VibeSignatureExtractor.psm1
.\project-bundler-cli.ps1
.\project-bundler-headless.ps1
.\README.md
.\run-vibe-headless.vbs
.\setup-vibe-toolkit.ps1
.\uninstall-vibe-menu.cmd
.\uninstall-vibe-menu.ps1
.\uninstall-vibe-menu.reg
`\n\n### 2. SOURCE FILES

#### File: .\Instalar VibeToolkit.cmd
```text
@echo off
title Instalador do VibeToolkit
echo.
echo === VibeToolkit - Instalador Automatico ===
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-vibe-toolkit.ps1"
echo.
echo Instalacao concluida. Pressione qualquer tecla para sair...
pause > nul
```

#### File: .\install-vibe-menu.cmd
```text
@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%install-vibe-menu.ps1"

where pwsh.exe >nul 2>nul
if %errorlevel%==0 (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
)

set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
    echo.
    echo Falha ao instalar o menu de contexto do VibeToolkit. Código: %EXIT_CODE%
) else (
    echo.
    echo Instalação concluída.
)

pause
exit /b %EXIT_CODE%
```

#### File: .\install-vibe-menu.ps1
```text
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$cliRunner = Join-Path $scriptDir 'run-vibe-headless.vbs'

if (-not (Test-Path -LiteralPath $cliRunner -PathType Leaf)) {
    throw "Arquivo obrigatório não encontrado: $cliRunner"
}

$classesRoot = 'Registry::HKEY_CURRENT_USER\Software\Classes'

function Resolve-MenuIconPath {
    $pwshCommand = Get-Command -Name 'pwsh.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pwshCommand -and -not [string]::IsNullOrWhiteSpace($pwshCommand.Source)) {
        return $pwshCommand.Source
    }

    $candidates = [System.Collections.Generic.List[string]]::new()

    foreach ($basePath in @($env:ProgramFiles, $env:ProgramW6432)) {
        if (-not [string]::IsNullOrWhiteSpace($basePath)) {
            $candidates.Add((Join-Path $basePath 'PowerShell\7\pwsh.exe')) | Out-Null
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        $candidates.Add((Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe')) | Out-Null
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    return (Join-Path $env:SystemRoot 'System32\shell32.dll')
}

function Set-ContextMenuEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseKey,

        [Parameter(Mandatory = $true)]
        [string]$MenuKeyName,

        [Parameter(Mandatory = $true)]
        [string]$MenuLabel,

        [Parameter(Mandatory = $true)]
        [string]$RunnerPath,

        [Parameter(Mandatory = $true)]
        [string]$ArgumentToken,

        [Parameter(Mandatory = $true)]
        [string]$IconPath
    )

    $menuKeyPath = Join-Path $BaseKey $MenuKeyName
    $commandKeyPath = Join-Path $menuKeyPath 'command'
    $commandValue = 'wscript.exe "{0}" "{1}"' -f $RunnerPath, $ArgumentToken

    New-Item -Path $BaseKey -Force | Out-Null
    New-Item -Path $menuKeyPath -Force | Out-Null
    Set-Item -Path $menuKeyPath -Value $MenuLabel
    New-ItemProperty -Path $menuKeyPath -Name 'Icon' -PropertyType String -Value $IconPath -Force | Out-Null

    New-Item -Path $commandKeyPath -Force | Out-Null
    Set-Item -Path $commandKeyPath -Value $commandValue
}

$iconValue = ('{0},0' -f (Resolve-MenuIconPath))

$entries = @(
    @{ BaseKey = (Join-Path $classesRoot 'Directory\shell');            MenuKeyName = 'VibeToolkitTerminal'; MenuLabel = 'VibeToolkit: Abrir Terminal (CLI)'; RunnerPath = $cliRunner; ArgumentToken = '%V' },
    @{ BaseKey = (Join-Path $classesRoot 'Directory\Background\shell'); MenuKeyName = 'VibeToolkitTerminal'; MenuLabel = 'VibeToolkit: Abrir Terminal (CLI)'; RunnerPath = $cliRunner; ArgumentToken = '%V' },
    @{ BaseKey = (Join-Path $classesRoot 'Drive\shell');                MenuKeyName = 'VibeToolkitTerminal'; MenuLabel = 'VibeToolkit: Abrir Terminal (CLI)'; RunnerPath = $cliRunner; ArgumentToken = '%1' }
)

foreach ($entry in $entries) {
    Set-ContextMenuEntry @entry -IconPath $iconValue
}

Write-Host 'VibeToolkit: menu de contexto instalado com sucesso.' -ForegroundColor Green
Write-Host ('Diretório da instalação: {0}' -f $scriptDir)
Write-Host ('CLI runner: {0}' -f $cliRunner)
Write-Host 'Escopo: HKEY_CURRENT_USER\Software\Classes (sem caminho hardcoded e sem exigir diretório fixo).'
```

#### File: .\install-vibe-menu.reg
```text
Windows Registry Editor Version 5.00

; ARQUIVO LEGADO / DESCONTINUADO.
; A instalação portátil agora é feita por script para gravar o caminho real do clone atual.
; Use um destes arquivos no mesmo diretório:
; - install-vibe-menu.cmd
; - install-vibe-menu.ps1
;
; Motivo: um .reg estático não consegue descobrir automaticamente onde o repositório foi clonado.
; Manter entradas aqui recriaria o problema de hardcode em caminhos absolutos.
;
; O VibeToolkit opera em modo estritamente CLI/headless.
; A entrada instalada é VibeToolkitTerminal (run-vibe-headless.vbs).
```

#### File: .\lib\SentinelUI.ps1
```text
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
```

#### File: .\modules\VibeBundleWriter.psm1
```text
Set-StrictMode -Version Latest

$script:VibeUtf8NoBom = New-Object System.Text.UTF8Encoding($false, $false)
$script:VibeUtf8Bom = New-Object System.Text.UTF8Encoding($true, $false)

function Get-VibeUtf8Encoding {
    param([switch]$UseBom)
    if ($UseBom) { return $script:VibeUtf8Bom }
    return $script:VibeUtf8NoBom
}

function Remove-VibeAuthenticodeSignatureBlock {
    param(
        [AllowNull()][string]$Content
    )

    if ($null -eq $Content) {
        return ''
    }

    $text = [string]$Content
    if ([string]::IsNullOrEmpty($text)) {
        return $text
    }

    $marker = '
```

#### File: .\modules\VibeDirectorProtocol.psm1
```text
Set-StrictMode -Version Latest

function Get-VibeExtractionModeLabel {
    param([string]$ExtractionMode)

    switch ($ExtractionMode) {
        'blueprint' { return 'BLUEPRINT' }
        'sniper' { return 'SNIPER' }
        default { return 'FULL' }
    }
}

function Get-VibeDirectorLocalProtocolHeader {
    param(
        [string]$ExtractionMode,
        [string]$ExecutorTargetValue
    )

    return @"
## PROTOCOLO OPERACIONAL TRANSVERSAL — ELITE v3.1

#### §0 — IDENTIDADE E MANDATO (O DIRETOR)
* **Papel:** Você é o **Diretor de Engenharia Agêntica** em modo **determinístico local**.
* **Missão:** Processar exclusivamente o bundle visível e converter intenção humana em especificação operacional rastreável para o Executor.
* **Fronteira de Execução:** Proibição absoluta de implementar código diretamente. A saída deve permanecer analítica, técnica e copiável.

#### §1 — ENQUADRAMENTO OPERACIONAL
* **Rota ativa:** VIA DIRETOR.
* **Extração efetiva:** $(Get-VibeExtractionModeLabel -ExtractionMode $ExtractionMode).
* **Executor alvo de referência:** $ExecutorTargetValue.
* **Fonte de verdade:** Somente o artefato visível gerado localmente pelo bundler.

#### §2 — REGRAS DE GOVERNANÇA LOCAL
* **Lei da Subtração:** Antes de pedir qualquer alteração, priorize remoção de redundância e reutilização de abstrações existentes.
* **Zero Alquimia:** Não inventar módulos, contratos, fluxos ou comportamento fora do material visível.
* **Accountability Firewall:** Toda execução futura deve exigir Relatório de Impacto, implementação explícita, verificação de segurança e validação objetiva.
"@.Trim()
}

function Get-VibeExecutorLocalProtocolHeader {
    param(
        [string]$ExtractionMode,
        [string]$ExecutorTargetValue
    )

    $extractionLine = switch ($ExtractionMode) {
        'blueprint' { '* **Leitura de Extração:** Como a extração é BLUEPRINT, priorize contratos, assinaturas, interfaces e pontos de integração sem fingir leitura do que não está visível.' }
        'sniper' { '* **Leitura de Extração:** Como a extração é SNIPER, limite qualquer alteração ao recorte manual efetivamente visível.' }
        default { '* **Leitura de Extração:** Como a extração é FULL, opere com o contexto total visível do bundle.' }
    }

    return @"
### IMPLEMENTAÇÃO: PROTOCOLO OPERACIONAL EXECUTOR — ELITE v4.1 (SNIPER MODE)

#### §0 — IDENTIDADE OPERACIONAL (O SNIPER)
* **Papel:** Você é o **Senior Implementation Agent (Sniper)**.
* **Missão:** Converter o blueprint recebido em código funcional, respeitando invariantes, contratos e a arquitetura existente.
* **Filosofia:** O código é um **passivo técnico (liability)** até validação rigorosa. Não decida arquitetura; execute o plano.

#### §1 — REGRAS DE EXECUÇÃO "ZERO-GAP"
* **Rota ativa:** DIRETO PARA O EXECUTOR.
* **Extração efetiva:** $(Get-VibeExtractionModeLabel -ExtractionMode $ExtractionMode).
* **Executor alvo de referência:** $ExecutorTargetValue.
* **Lei da Subtração:** Antes de adicionar código, verifique se o problema pode ser resolvido reutilizando abstrações existentes ou removendo redundâncias.
* **Preservação de Contexto:** Mantenha nomes, contratos, comportamento existente e compatibilidade com o projeto original.
* **DNA do Output:** A entrega deve ser exclusivamente técnica e pronta para aplicação.

#### §2 — FLUXO DE MATERIALIZAÇÃO
* **Análise de Impacto:** Identifique arquivos afetados e dependências antes de iniciar a escrita.
* **Implementação de Alta Fidelidade:** Siga estritamente assinaturas, contratos e tipos definidos no bundle visível.
$extractionLine
* **Checklist de Segurança:** Verifique exposição de segredos, validação insuficiente de entrada e drift de contrato antes de concluir.

#### §3 — TEMPLATE OBRIGATÓRIO DE RESPOSTA
1. **[RELATÓRIO DE IMPACTO]**: Lista de arquivos alterados e dependências verificadas.
2. **[IMPLEMENTAÇÃO]**: Arquivos completos ou diffs precisos por arquivo.
3. **[PROTOCOLO DE VERIFICAÇÃO]**: Checks objetivos, regressão e hardening compatíveis com o escopo.
4. **[ASSINATURA TÉCNICA]**: Confirmação de aderência integral ao contrato.
"@.Trim()
}

function Get-VibeProtocolHeaderContent {
    param(
        [string]$RouteMode,
        [string]$ExtractionMode,
        [string]$ExecutorTargetValue
    )

    if ($RouteMode -eq 'executor') {
        return (Get-VibeExecutorLocalProtocolHeader -ExtractionMode $ExtractionMode -ExecutorTargetValue $ExecutorTargetValue)
    }

    return (Get-VibeDirectorLocalProtocolHeader -ExtractionMode $ExtractionMode -ExecutorTargetValue $ExecutorTargetValue)
}

Export-ModuleMember -Function Get-VibeExtractionModeLabel, Get-VibeProtocolHeaderContent
```

#### File: .\modules\VibeFileDiscovery.psm1
```text
Set-StrictMode -Version Latest

function Test-VibeGeneratedArtifactFileName {
    param([string]$FileName)

    if ([string]::IsNullOrWhiteSpace($FileName)) {
        return $false
    }

    $patterns = @(
        '^_(?:Diretor|Executor)_',
        '^_(?:COPIAR_TUDO|INTELIGENTE|MANUAL)__',
        '^_TXT_EXPORT__',
        '^_TXT_EXPORT__.*\.zip$',
        '^_(?:bundle|blueprint|manual|txt_export)_(?:diretor|executor)(?:_[A-Za-z0-9\-]+)?__.*\.(?:md|json)$',
        '^_meta-prompt_(?:bundle|blueprint|manual)_(?:diretor|executor)(?:_[A-Za-z0-9\-]+)?__.*\.(?:md|json)$'
    )

    foreach ($pattern in $patterns) {
        if ($FileName -match $pattern) {
            return $true
        }
    }

    return $false
}

function Get-VibeRelevantFiles {
    param(
        [string]$CurrentPath,
        [string[]]$AllowedExtensions,
        [string[]]$IgnoredDirs,
        [string[]]$IgnoredFiles
    )

    try {
        $items = Get-ChildItem -Path $CurrentPath -ErrorAction Stop

        foreach ($item in $items) {
            if ($item.PSIsContainer) {
                if ($item.Name -notin $IgnoredDirs) {
                    Get-VibeRelevantFiles -CurrentPath $item.FullName -AllowedExtensions $AllowedExtensions -IgnoredDirs $IgnoredDirs -IgnoredFiles $IgnoredFiles
                }

                continue
            }

            $isTarget =
                ($item.Extension -in $AllowedExtensions) -and
                ($item.Name -notin $IgnoredFiles) -and
                ($item.BaseName -notmatch '-[a-f0-9]{8,}$') -and
                (-not (Test-VibeGeneratedArtifactFileName -FileName $item.Name))

            if ($isTarget) {
                $item
            }
        }
    }
    catch {
    }
}

Export-ModuleMember -Function Test-VibeGeneratedArtifactFileName, Get-VibeRelevantFiles
```

#### File: .\modules\VibeSignatureExtractor.psm1
```text
Set-StrictMode -Version Latest

function Get-VibePowerShellFunctionSignatures {
    param([string[]]$Lines)

    if ($null -eq $Lines -or $Lines.Count -eq 0) { return @() }

    $signatures = New-Object System.Collections.Generic.List[string]

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $rawLine = $Lines[$i]
        if ($null -eq $rawLine) { continue }

        $trimmedLine = $rawLine.Trim()
        if ($trimmedLine -notmatch '^(?:filter|function)\s+((?:global:|script:)?[A-Za-z0-9_-]+)\s*\{?\s*$') { continue }

        $signatureLines = New-Object System.Collections.Generic.List[string]
        $signatureLines.Add($trimmedLine)

        $j = $i + 1
        while ($j -lt $Lines.Count) {
            $candidateRaw = $Lines[$j]
            if ($null -eq $candidateRaw) { $j++; continue }

            $candidateTrimmed = $candidateRaw.Trim()

            if ([string]::IsNullOrWhiteSpace($candidateTrimmed)) {
                $j++
                continue
            }

            if ($candidateTrimmed -match '^\s*#') {
                $j++
                continue
            }

            if ($candidateTrimmed -match '^param\b') {
                $paramBlock = New-Object System.Collections.Generic.List[string]
                $parenBalance = 0

                do {
                    $paramRaw = $Lines[$j]
                    if ($null -eq $paramRaw) { break }

                    $paramTrimmed = $paramRaw.TrimEnd()
                    $paramBlock.Add($paramTrimmed)

                    $openCount = ([regex]::Matches($paramTrimmed, '\(')).Count
                    $closeCount = ([regex]::Matches($paramTrimmed, '\)')).Count
                    $parenBalance += ($openCount - $closeCount)
                    $j++
                }
                while ($j -lt $Lines.Count -and $parenBalance -gt 0)

                foreach ($paramLine in $paramBlock) {
                    $signatureLines.Add($paramLine)
                }
            }

            break
        }

        $signatures.Add((($signatureLines | Where-Object { $null -ne $_ }) -join "`n") + "`n")
        $i = [Math]::Max($i, $j - 1)
    }

    return @($signatures)
}

function Get-VibeBundlerSignaturesForFile {
    param([System.IO.FileInfo]$File, [ref]$IssueMessage)
    if ($IssueMessage) { $IssueMessage.Value = $null }
    if ($null -eq $File) { return @() }
    $RelPath = Resolve-Path -Path $File.FullName -Relative
    $ContentRaw = Read-VibeTextFile -Path $File.FullName
    if ([string]::IsNullOrWhiteSpace($ContentRaw)) { return @() }
    try {
        $Lines = @([regex]::Split($ContentRaw, "`r?`n"))
        if ($File.Extension -eq '.ps1') {
            return @(Get-VibePowerShellFunctionSignatures -Lines $Lines)
        }

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
                        $Block += "$($Lines[$j])`n"; $j++
                    }
                    if ($j -lt $Lines.Count) { $Block += "$($Lines[$j])`n" }
                    $i = $j
                }
                $Signatures += $Block
            }
            elseif ($Line -match '^(?:export\s+)?(?:const|function|class)\s+[A-Za-z0-9_]+') {
                $Signatures += "$(($Line -replace '\{.*$','') -replace '\s*=>.*$','')`n"
            }
            elseif ($Line -match '^(?:public|protected|private|internal)\s+(?:class|interface|record|struct|enum)\s+[A-Za-z0-9_]+') {
                $Signatures += "$($Line -replace '\{.*$','')`n"
            }
            elseif ($Line -match '^(?:def|class)\s+[A-Za-z0-9_]+') {
                $Signatures += "$($Line -replace ':$','')`n"
            }
            elseif ($Line -match '^func\s+[A-Za-z0-9_]+') {
                $Signatures += "$($Line -replace '\{.*$','')`n"
            }
            elseif ($Line -match '^(?:pub\s+)?(?:fn|struct|enum|trait)\s+[A-Za-z0-9_]+') {
                $Signatures += "$($Line -replace '\{.*$','')`n"
            }
        }
        return @($Signatures)
    }
    catch {
        if ($IssueMessage) { $IssueMessage.Value = "[$RelPath] $($_.Exception.Message)" }
        return @()
    }
}

Export-ModuleMember -Function Get-VibePowerShellFunctionSignatures, Get-VibeBundlerSignaturesForFile
```

#### File: .\project-bundler-cli.ps1
````text
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
        [string]$ExecutorTargetValue
    )

    Write-SentinelPanel -Title 'Resumo operacional' -Tone 'Secondary' -Lines @(
        ('Projeto raiz: {0}' -f $ProjectNameValue),
        ('Executor alvo: {0}' -f $ExecutorTargetValue)
    )

    Write-SentinelBadgeLine -Badges (Get-SentinelModeBadgeLines -BundleModeValue $BundleModeValue -RouteModeValue $RouteModeValue)
    Write-SentinelKeyValue -Key 'Projeto' -Value $ProjectNameValue -Tone 'Primary'
    Write-SentinelKeyValue -Key 'Extração' -Value $BundleModeValue -Tone (Get-SentinelBundleModeTone -BundleModeValue $BundleModeValue)
    Write-SentinelKeyValue -Key 'Rota' -Value $(if ($RouteModeValue -eq 'executor') { 'Direto para Executor' } else { 'Via Diretor' }) -Tone (Get-SentinelRouteModeTone -RouteModeValue $RouteModeValue)
    Write-SentinelKeyValue -Key 'Executor' -Value $ExecutorTargetValue -Tone 'Primary'
    Write-Host ''
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
            default { '[*]' }
        }

        Write-Host ("{0} {1}" -f $prefix, $Message)
    }

    $writeSentinelDivider = {
        param(
            [string]$Label,
            [string]$Tone = 'Secondary',
            [int]$Width = 39,
            [string]$Character = '='
        )

        $line = ($Character * [Math]::Max($Width, 8))
        if ([string]::IsNullOrWhiteSpace($Label)) {
            Write-Host ("  {0}" -f $line)
        }
        else {
            Write-Host ("  {0} {1} {0}" -f $line, $Label)
        }
    }

    $writeSentinelHeader = {
        param(
            [string]$Title = 'SENTINEL',
            [string]$Version = 'v1.0.0',
            [ValidateSet('Hero', 'Compact', 'Minimal')]
            [string]$Variant = 'Hero'
        )

        Write-Host ('=' * 72)
        Write-Host (" {0}  ·  {1}" -f $Title, $Version)
        Write-Host ('=' * 72)
        Write-Host ''
    }

    $writeSentinelSection = {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Title,
            [string]$Subtitle,
            [string]$Tone = 'Primary'
        )

        Write-Host ''
        Write-Host ('=' * 39)
        Write-Host ("  {0}" -f $Title)
        if (-not [string]::IsNullOrWhiteSpace($Subtitle)) {
            Write-Host ("  {0}" -f $Subtitle)
        }
        Write-Host ('=' * 39)
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

        Write-Host ("  {0} : {1}" -f $Key.PadRight([Math]::Max($KeyWidth, 8)), $Value)
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
            [string]$Tone = 'Primary'
        )

        if ($Total -le 0) {
            Write-Host ("  > {0}" -f $Activity)
            return
        }

        Write-Host ("  > {0} ({1}/{2})" -f $Activity, $Current, $Total)
    }

    $formatSentinelBadge = {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Label,
            [string]$Tone = 'Primary'
        )

        return ('[{0}]' -f $Label.ToUpperInvariant())
    }

    $writeSentinelBadgeLine = {
        param([string[]]$Badges)

        $normalizedBadges = @($Badges | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($normalizedBadges.Count -gt 0) {
            Write-Host ("  {0}" -f ($normalizedBadges -join ' '))
        }
    }

    Set-Item -Path Function:\script:Write-SentinelText -Value $writeSentinelText -Force
    Set-Item -Path Function:\script:Write-SentinelStatus -Value $writeSentinelStatus -Force
    Set-Item -Path Function:\script:Write-SentinelDivider -Value $writeSentinelDivider -Force
    Set-Item -Path Function:\script:Write-SentinelHeader -Value $writeSentinelHeader -Force
    Set-Item -Path Function:\script:Write-SentinelSection -Value $writeSentinelSection -Force
    Set-Item -Path Function:\script:Write-SentinelPanel -Value $writeSentinelPanel -Force
    Set-Item -Path Function:\script:Write-SentinelKeyValue -Value $writeSentinelKeyValue -Force
    Set-Item -Path Function:\script:Write-SentinelMenuOptions -Value $writeSentinelMenuOptions -Force
    Set-Item -Path Function:\script:Write-SentinelProgress -Value $writeSentinelProgress -Force
    Set-Item -Path Function:\script:Format-SentinelBadge -Value $formatSentinelBadge -Force
    Set-Item -Path Function:\script:Write-SentinelBadgeLine -Value $writeSentinelBadgeLine -Force
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
    $lines.Add('## Síntese técnica') | Out-Null
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

    for ($index = 0; $index -lt $Files.Count; $index++) {
        $sourceFile = $Files[$index]
        Write-SentinelProgress -Activity 'TXT Export' -Current ($index + 1) -Total $Files.Count -Tone 'Secondary'
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

    Write-SentinelSection -Title 'Modo de Extração' -Subtitle 'Escolha o nível de contexto da execução.' -Tone 'Primary'
    Write-SentinelMenuOptions -Options @(
        'Full / Tudo  -  enviar tudo (análise completa)',
        'Architect    -  blueprint / estrutura',
        'Sniper       -  seleção manual (recorte com foco cirúrgico)',
        'TXT Export   -  pasta com arquivos separados'
    )

    $resolved = $null
    while ($null -eq $resolved) {
        $inp = (Read-Host '  Digite 1, 2, 3 ou 4').Trim()
        switch ($inp) {
            '1' { $resolved = 'full' }
            '2' { $resolved = 'blueprint' }
            '3' { $resolved = 'sniper' }
            '4' { $resolved = 'txtExport' }
            default { Write-SentinelStatus -Message 'Entrada inválida. Digite 1, 2, 3 ou 4.' -Type Warning }
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

    Write-SentinelSection -Title 'Fluxo de Saída' -Subtitle 'Defina o papel operacional do artefato final.' -Tone 'Primary'
    Write-SentinelMenuOptions -Options @(
        'Via Diretor          (gera meta-prompt local)',
        'Direto para Executor (gera contexto final)'
    )

    $resolved = $null
    while ($null -eq $resolved) {
        $inp = (Read-Host '  Digite 1 ou 2').Trim()
        switch ($inp) {
            '1' { $resolved = 'director' }
            '2' { $resolved = 'executor' }
            default { Write-SentinelStatus -Message 'Entrada inválida. Digite 1 ou 2.' -Type Warning }
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

    Write-SentinelSection -Title 'Origem do Projeto' -Subtitle 'Selecione de onde o contexto será carregado.' -Tone 'Primary'
    Write-SentinelMenuOptions -Options @(
        'Usar path atual',
        'Clonar repositório GitHub'
    )

    $choice = $null
    while ($choice -notin @('1', '2')) {
        $choice = (Read-Host '  Digite 1 ou 2').Trim()
        if ($choice -notin @('1', '2')) {
            Write-SentinelStatus -Message 'Entrada inválida. Digite 1 ou 2.' -Type Warning
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

    Write-SentinelSection -Title 'Clonagem de Repositório GitHub' -Subtitle 'Fluxo temporário ou manual, sem GUI e sem firula.' -Tone 'Primary'

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
    'bin', 'obj', 'target', 'vendor'
)

$script:IgnoredFiles = @(
    'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock',
    '.DS_Store', 'metadata.json', '.gitignore',
    'capacitor.plugins.json', 'cordova.js', 'cordova_plugins.js',
    'poetry.lock', 'Pipfile.lock', 'Cargo.lock', 'go.sum', 'composer.lock'
)

Register-SentinelCliFallback

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
            Write-SentinelStatus -Message 'SentinelUI bloqueado por assinatura/execution policy. Ativando fallback textual para o modo headless.' -Type Warning
            Write-SentinelPanel -Title 'Resumo do bootstrap' -Tone 'Warning' -Lines @($sentinelFailureSummary)
        }
        else {
            $sentinelFailureSummary = Get-SentinelUiBootstrapFailureSummary -ErrorRecord $sentinelBootstrapFailure
            throw "Falha estrutural ao carregar biblioteca de UI '$SentinelUiPath'. $sentinelFailureSummary"
        }
    }

    Assert-SentinelUiBootstrapContract -SentinelUiPath $SentinelUiPath -FallbackActive:$sentinelUiFallbackActive

    Write-SentinelHeader -Title 'SENTINEL HEADLESS' -Version 'v2.0.0' -Variant 'Hero'
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

    Write-SentinelSection -Title 'SENTINEL HEADLESS — Configuração' -Subtitle 'Fluxo CLI/headless local com renderização progressiva.' -Tone 'Primary'

    $executionStartedAt = Get-Date
    $resolvedBundleMode = Resolve-BundleMode -BundleMode $BundleMode -NonInteractive:$NonInteractive
    $resolvedRouteMode = Resolve-RouteMode -RouteMode $RouteMode -NonInteractive:$NonInteractive
    $choice = Resolve-ChoiceFromBundleMode -ModeValue $resolvedBundleMode
    $currentExtractionMode = Resolve-ExtractionModeFromBundleMode -ModeValue $resolvedBundleMode
    $currentDocumentMode = Resolve-DocumentModeFromExtractionMode -ExtractionMode $currentExtractionMode
    $isTxtExportMode = ($choice -eq '4')

    Write-SentinelOperationSummary -ProjectNameValue $projectName -BundleModeValue $resolvedBundleMode -RouteModeValue $resolvedRouteMode -ExecutorTargetValue $ExecutorTarget

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
        for ($index = 0; $index -lt $filesToProcess.Count; $index++) {
            $file = $filesToProcess[$index]
            $relPath = Resolve-Path -Path $file.FullName -Relative
            Write-SentinelProgress -Activity 'Leitura de arquivos' -Current ($index + 1) -Total $filesToProcess.Count -Tone 'Secondary'
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
````

#### File: .\project-bundler-headless.ps1
```text
#requires -Version 7.0

<#
.SYNOPSIS
    Shim/Wrapper para a engine canônica (project-bundler-cli.ps1).
    Mantido para preservar contratos de integração e invocação visual (via VBS/atalhos).
#>

[CmdletBinding()]
param(
    [string]$Path = ".",
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

$cliScript = Join-Path $PSScriptRoot 'project-bundler-cli.ps1'

if (-not (Test-Path $cliScript -PathType Leaf)) {
    throw "Erro Crítico: A engine canônica CLI não foi encontrada em: $cliScript`no wrapper headless requer a CLI para funcionar."
}

& $cliScript @PSBoundParameters
```

#### File: .\README.md
```text

Esse README está **pronto para colar** no seu repositório. Ele:

- É claro para **iniciantes** (passo a passo, sem jargões).
- Inclui o **novo instalador** e o menu de contexto.
- Explica os modos de extração de forma prática.
- Tem uma seção de FAQ para problemas comuns.
- Usa emojis e formatação amigável.

Basta substituir o README antigo por este conteúdo. 🚀
```

#### File: .\run-vibe-headless.vbs
```text
Option Explicit

Dim fso
Dim shell
Dim scriptDir
Dim psScript
Dim targetPath
Dim powerShellExe
Dim innerCommand
Dim command

Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
psScript = fso.BuildPath(scriptDir, "project-bundler-headless.ps1")

If Not fso.FileExists(psScript) Then
    MsgBox "Arquivo obrigatório não encontrado: " & psScript, vbCritical, "VibeToolkit"
    WScript.Quit 1
End If

targetPath = "."
If WScript.Arguments.Count > 0 Then
    targetPath = Trim(CStr(WScript.Arguments(0)))
    If Len(targetPath) = 0 Then
        targetPath = "."
    End If
End If

powerShellExe = ResolvePowerShellExecutable(shell, fso)
If Len(powerShellExe) = 0 Then
    MsgBox "PowerShell não encontrado no sistema.", vbCritical, "VibeToolkit"
    WScript.Quit 1
End If

innerCommand = Quote(powerShellExe) & _
    " -NoProfile -ExecutionPolicy Bypass -File " & Quote(psScript) & _
    " -Path " & Quote(targetPath)

command = "cmd.exe /k " & Quote(innerCommand)

shell.Run command, 1, False

Function ResolvePowerShellExecutable(shellObject, fileSystemObject)
    Dim commandPath
    Dim candidates
    Dim i

    commandPath = shellObject.ExpandEnvironmentStrings("%ProgramFiles%\PowerShell\7\pwsh.exe")
    If fileSystemObject.FileExists(commandPath) Then
        ResolvePowerShellExecutable = commandPath
        Exit Function
    End If

    commandPath = shellObject.ExpandEnvironmentStrings("%ProgramW6432%\PowerShell\7\pwsh.exe")
    If fileSystemObject.FileExists(commandPath) Then
        ResolvePowerShellExecutable = commandPath
        Exit Function
    End If

    commandPath = shellObject.ExpandEnvironmentStrings("%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe")
    If fileSystemObject.FileExists(commandPath) Then
        ResolvePowerShellExecutable = commandPath
        Exit Function
    End If

    candidates = Array("pwsh.exe", "powershell.exe")
    For i = LBound(candidates) To UBound(candidates)
        commandPath = ResolveCommandPath(shellObject, candidates(i))
        If Len(commandPath) > 0 Then
            ResolvePowerShellExecutable = commandPath
            Exit Function
        End If
    Next

    ResolvePowerShellExecutable = ""
End Function

Function ResolveCommandPath(shellObject, commandName)
    Dim execObject
    Dim resolved

    On Error Resume Next
    Set execObject = shellObject.Exec("cmd.exe /c where " & commandName)
    If Err.Number <> 0 Then
        Err.Clear
        ResolveCommandPath = ""
        Exit Function
    End If
    On Error GoTo 0

    If execObject.StdOut.AtEndOfStream Then
        ResolveCommandPath = ""
        Exit Function
    End If

    resolved = Trim(execObject.StdOut.ReadLine)
    If Len(resolved) = 0 Then
        ResolveCommandPath = ""
    Else
        ResolveCommandPath = resolved
    End If
End Function

Function Quote(value)
    Quote = Chr(34) & value & Chr(34)
End Function
```

#### File: .\setup-vibe-toolkit.ps1
```text
<#
.SYNOPSIS
    Instalador amigável do VibeToolkit.
    Este script deve ser executado através do arquivo 'Instalar VibeToolkit.cmd'.
.DESCRIPTION
    Configura a política de execução do PowerShell (se necessário) e instala o menu de contexto.
.NOTES
    Autor: VibeToolkit Team
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Se o script foi executado diretamente (sem o .cmd), mostra instrução e sai.
if ($MyInvocation.Line -notmatch 'Bypass' -and (Get-ExecutionPolicy) -in @('Restricted', 'AllSigned', 'RemoteSigned')) {
    Write-Host "Por favor, execute o arquivo 'Instalar VibeToolkit.cmd' (clique duas vezes)." -ForegroundColor Red
    Write-Host "Isso garante que o PowerShell ignore a política de execução temporariamente." -ForegroundColor Yellow
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Cores amigáveis
$Host.UI.RawUI.ForegroundColor = 'Cyan'
Write-Host "`n=== VibeToolkit - Instalador Automático ===`n" -ForegroundColor Cyan
$Host.UI.RawUI.ForegroundColor = 'White'

# 1. Verificar política de execução atual (apenas para informar)
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
$needsChange = $currentPolicy -in @('Restricted', 'AllSigned', 'Undefined')

if ($needsChange) {
    Write-Host "⚠️  A política de execução do PowerShell está como: $currentPolicy" -ForegroundColor Yellow
    Write-Host "Isso pode impedir scripts do VibeToolkit de rodarem com duplo clique." -ForegroundColor Yellow
    Write-Host "`nRecomenda-se alterar para 'RemoteSigned' (apenas para seu usuário)." -ForegroundColor White
    $choice = Read-Host "Deseja alterar agora? (S/N)"
    if ($choice -eq 'S' -or $choice -eq 's') {
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
            Write-Host "✅ Política alterada para RemoteSigned." -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Não foi possível alterar. Execute este script como administrador ou manualmente:" -ForegroundColor Red
            Write-Host "   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "⚠️  Você optou por não alterar. Alguns recursos podem falhar." -ForegroundColor Yellow
        Write-Host "   Para executar o VibeToolkit, sempre use o arquivo .cmd fornecido." -ForegroundColor DarkGray
    }
}
else {
    Write-Host "✅ Política de execução já está adequada: $currentPolicy" -ForegroundColor Green
}

# 2. Verificar se o VBS necessário existe
$vbsPath = Join-Path $PSScriptRoot 'run-vibe-headless.vbs'
if (-not (Test-Path $vbsPath)) {
    Write-Host "`n❌ Arquivo 'run-vibe-headless.vbs' não encontrado!" -ForegroundColor Red
    Write-Host "   Este arquivo é obrigatório para o menu de contexto." -ForegroundColor Yellow
    Write-Host "   Certifique-se de que ele está na mesma pasta que este instalador." -ForegroundColor Yellow
    exit 1
}

# 3. Instalar menu de contexto
Write-Host "`n📌 Instalando menu de contexto do Windows..." -ForegroundColor Cyan
$installScript = Join-Path $PSScriptRoot 'install-vibe-menu.ps1'
if (Test-Path $installScript) {
    try {
        & $installScript
        Write-Host "✅ Menu de contexto instalado com sucesso!" -ForegroundColor Green
        Write-Host "   Clique com botão direito em qualquer pasta → 'VibeToolkit: Abrir Terminal (CLI)'" -ForegroundColor White
    }
    catch {
        Write-Host "❌ Falha ao instalar menu: $_" -ForegroundColor Red
        Write-Host "   Tente executar este instalador como administrador." -ForegroundColor Yellow
    }
}
else {
    Write-Host "❌ Script de instalação do menu não encontrado: install-vibe-menu.ps1" -ForegroundColor Red
}

# 4. Conclusão
Write-Host "`n=== Instalação concluída ===" -ForegroundColor Cyan
Write-Host "Para usar o VibeToolkit agora, execute: .\project-bundler-cli.ps1" -ForegroundColor White
Write-Host "Ou clique com botão direito em uma pasta e escolha a opção do menu." -ForegroundColor White
Write-Host ""
Read-Host "Pressione Enter para sair"
```

#### File: .\uninstall-vibe-menu.cmd
```text
@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%uninstall-vibe-menu.ps1"

where pwsh.exe >nul 2>nul
if %errorlevel%==0 (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
)

set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
    echo.
    echo Falha ao remover o menu de contexto do VibeToolkit. Código: %EXIT_CODE%
) else (
    echo.
    echo Remoção concluída.
)

pause
exit /b %EXIT_CODE%
```

#### File: .\uninstall-vibe-menu.ps1
```text
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Remove-RegistryKeyIfExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
        return $true
    }

    return $false
}

$portableKeys = @(
    'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\shell\VibeToolkit',
    'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\VibeToolkit',
    'Registry::HKEY_CURRENT_USER\Software\Classes\Drive\shell\VibeToolkit',
    'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\shell\VibeToolkitHUD',
    'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\VibeToolkitHUD',
    'Registry::HKEY_CURRENT_USER\Software\Classes\Drive\shell\VibeToolkitHUD',
    'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\shell\VibeToolkitTerminal',
    'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\VibeToolkitTerminal',
    'Registry::HKEY_CURRENT_USER\Software\Classes\Drive\shell\VibeToolkitTerminal'
)

$legacyKeys = @(
    'Registry::HKEY_CLASSES_ROOT\Directory\shell\VibeToolkit',
    'Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkit',
    'Registry::HKEY_CLASSES_ROOT\Drive\shell\VibeToolkit',
    'Registry::HKEY_CLASSES_ROOT\Directory\shell\VibeToolkitHUD',
    'Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkitHUD',
    'Registry::HKEY_CLASSES_ROOT\Drive\shell\VibeToolkitHUD',
    'Registry::HKEY_CLASSES_ROOT\Directory\shell\VibeToolkitTerminal',
    'Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkitTerminal',
    'Registry::HKEY_CLASSES_ROOT\Drive\shell\VibeToolkitTerminal'
)

$removed = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

foreach ($key in $portableKeys) {
    if (Remove-RegistryKeyIfExists -Path $key) {
        $removed.Add($key) | Out-Null
    }
}

foreach ($key in $legacyKeys) {
    try {
        if (Remove-RegistryKeyIfExists -Path $key) {
            $removed.Add($key) | Out-Null
        }
    }
    catch {
        $warnings.Add(('Não foi possível remover {0}: {1}' -f $key, $_.Exception.Message)) | Out-Null
    }
}

if ($removed.Count -eq 0) {
    Write-Host 'VibeToolkit: nenhuma chave encontrada para remover.' -ForegroundColor Yellow
}
else {
    Write-Host 'VibeToolkit: menu de contexto removido.' -ForegroundColor Green
    foreach ($path in $removed) {
        Write-Host (' - {0}' -f $path)
    }
}

if ($warnings.Count -gt 0) {
    Write-Warning 'Algumas chaves legadas não puderam ser removidas automaticamente.'
    foreach ($warningMessage in $warnings) {
        Write-Warning $warningMessage
    }
}
```

#### File: .\uninstall-vibe-menu.reg
```text
Windows Registry Editor Version 5.00

; Remoção do Menu do VibeToolkit (portável + legado)

[-HKEY_CURRENT_USER\Software\Classes\Directory\shell\VibeToolkit]
[-HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\VibeToolkit]
[-HKEY_CURRENT_USER\Software\Classes\Drive\shell\VibeToolkit]

[-HKEY_CURRENT_USER\Software\Classes\Directory\shell\VibeToolkitHUD]
[-HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\VibeToolkitHUD]
[-HKEY_CURRENT_USER\Software\Classes\Drive\shell\VibeToolkitHUD]

[-HKEY_CURRENT_USER\Software\Classes\Directory\shell\VibeToolkitTerminal]
[-HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\VibeToolkitTerminal]
[-HKEY_CURRENT_USER\Software\Classes\Drive\shell\VibeToolkitTerminal]

[-HKEY_CLASSES_ROOT\Directory\shell\VibeToolkit]
[-HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkit]
[-HKEY_CLASSES_ROOT\Drive\shell\VibeToolkit]

[-HKEY_CLASSES_ROOT\Directory\shell\VibeToolkitHUD]
[-HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkitHUD]
[-HKEY_CLASSES_ROOT\Drive\shell\VibeToolkitHUD]

[-HKEY_CLASSES_ROOT\Directory\shell\VibeToolkitTerminal]
[-HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkitTerminal]
[-HKEY_CLASSES_ROOT\Drive\shell\VibeToolkitTerminal]
```
```