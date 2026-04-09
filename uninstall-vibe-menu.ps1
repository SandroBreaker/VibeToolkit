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
