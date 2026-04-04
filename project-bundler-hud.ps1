#requires -Version 7.0

[CmdletBinding()]
param(
    [string]$Path = '.'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ToolkitDir = $PSScriptRoot
$headlessScriptPath = Join-Path $script:ToolkitDir 'project-bundler-cli.ps1'
$hudScriptPath = Join-Path $script:ToolkitDir 'lib\SentinelHud.ps1'

if (-not (Test-Path $headlessScriptPath -PathType Leaf)) {
    throw "Engine headless não encontrado: $headlessScriptPath"
}

if (-not (Test-Path $hudScriptPath -PathType Leaf)) {
    throw "HUD WPF não encontrado: $hudScriptPath"
}

$hudContent = [System.IO.File]::ReadAllText($hudScriptPath, [System.Text.Encoding]::UTF8)
. ([scriptblock]::Create($hudContent))

Start-SentinelBundlerHud `
    -ToolkitDir $script:ToolkitDir `
    -HeadlessScriptPath $headlessScriptPath `
    -TargetPath $Path
