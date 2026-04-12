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
    [string]$ExecutorTarget = 'IA Generativa (GenAI)',
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$cliScript = Join-Path $PSScriptRoot 'project-bundler-cli.ps1'

if (-not (Test-Path $cliScript -PathType Leaf)) {
    throw "Erro Crítico: A engine canônica CLI não foi encontrada em: $cliScript`no wrapper headless requer a CLI para funcionar."
}

& $cliScript @PSBoundParameters
