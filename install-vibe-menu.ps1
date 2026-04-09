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
