@echo off
setlocal EnableExtensions
chcp 65001 >nul 2>nul

title VibeToolkit - Instalador

echo.
echo === VibeToolkit - Instalador Unificado v5 ===
echo.

if /I "%~1"=="/help" goto :usage
if /I "%~1"=="-help" goto :usage
if /I "%~1"=="--help" goto :usage
if /I "%~1"=="/?" goto :usage

set "MODE=%~1"
if "%MODE%"=="" set "MODE=auto"
if /I "%MODE%"=="/install" set "MODE=install"
if /I "%MODE%"=="-install" set "MODE=install"
if /I "%MODE%"=="install" set "MODE=install"
if /I "%MODE%"=="/repair" set "MODE=repair"
if /I "%MODE%"=="-repair" set "MODE=repair"
if /I "%MODE%"=="repair" set "MODE=repair"
if /I "%MODE%"=="/uninstall" set "MODE=uninstall"
if /I "%MODE%"=="-uninstall" set "MODE=uninstall"
if /I "%MODE%"=="uninstall" set "MODE=uninstall"

if /I not "%MODE%"=="auto" if /I not "%MODE%"=="install" if /I not "%MODE%"=="repair" if /I not "%MODE%"=="uninstall" goto :usage

call :resolve_ps
if errorlevel 1 (
    echo PowerShell nao encontrado no sistema.
    set "EXIT_CODE=1"
    goto :finish
)

set "VT_SELF=%~f0"
set "VT_MODE=%MODE%"

"%VT_PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ErrorActionPreference='Stop';" ^
 "$self=$env:VT_SELF;" ^
 "$marker='__POWERSHELL_' + 'PAYLOAD_BELOW__';" ^
 "$raw=[System.IO.File]::ReadAllText($self);" ^
 "$idx=$raw.LastIndexOf($marker);" ^
 "if($idx -lt 0){ throw 'Payload marker not found.' };" ^
 "$payload=$raw.Substring($idx + $marker.Length);" ^
 "$tmp=Join-Path $env:TEMP ('VibeToolkitInstaller_' + [guid]::NewGuid().ToString('N') + '.ps1');" ^
 "[System.IO.File]::WriteAllText($tmp,$payload,[System.Text.UTF8Encoding]::new($false));" ^
 "try { & $tmp -Mode $env:VT_MODE -RepoRoot (Split-Path -Parent $self); exit $LASTEXITCODE } finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }"

set "EXIT_CODE=%ERRORLEVEL%"
goto :finish

:resolve_ps
set "VT_PS_EXE="
where pwsh.exe >nul 2>nul
if %errorlevel%==0 (
    set "VT_PS_EXE=pwsh.exe"
    exit /b 0
)
where powershell.exe >nul 2>nul
if %errorlevel%==0 (
    set "VT_PS_EXE=powershell.exe"
    exit /b 0
)
exit /b 1

:usage
echo Uso:
echo   Instalar VibeToolkit.cmd   ^(modo inteligente: install ou menu repair/uninstall^)
echo   Instalar VibeToolkit.cmd /install
echo   Instalar VibeToolkit.cmd /repair
echo   Instalar VibeToolkit.cmd /uninstall
set "EXIT_CODE=2"
goto :finish

:finish
echo.
if "%EXIT_CODE%"=="0" (
    echo Operacao concluida com sucesso.
) else (
    echo Operacao finalizada com codigo: %EXIT_CODE%
)
echo.
pause >nul
exit /b %EXIT_CODE%

__POWERSHELL_PAYLOAD_BELOW__
param(
    [ValidateSet('auto', 'install', 'repair', 'uninstall')]
    [string]$Mode = 'install',

    [Parameter(Mandatory = $true)]
    [string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
$classesRoot = 'Registry::HKEY_CURRENT_USER\Software\Classes'
$entrypointsDir = Join-Path $RepoRoot 'entrypoints'
$runnerVbsPath = Join-Path $entrypointsDir 'run-vibe-headless.vbs'
$legacyRunnerVbsPath = Join-Path $RepoRoot 'run-vibe-headless.vbs'
$headlessScriptPath = Join-Path $entrypointsDir 'project-bundler-headless.ps1'

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

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

function Remove-VibeContextMenuKeys {
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
            $warnings.Add(('Nao foi possivel remover {0}: {1}' -f $key, $_.Exception.Message)) | Out-Null
        }
    }

    [pscustomobject]@{
        Removed  = $removed
        Warnings = $warnings
    }
}

function Get-GeneratedRunnerContent {
    @'
' Generated by Instalar VibeToolkit.cmd
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
    MsgBox "Arquivo obrigatorio nao encontrado: " & psScript, vbCritical, "VibeToolkit"
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
    MsgBox "PowerShell nao encontrado no sistema.", vbCritical, "VibeToolkit"
    WScript.Quit 1
End If

innerCommand = Quote(powerShellExe) & _
    " -NoProfile -ExecutionPolicy Bypass -File " & Quote(psScript) & _
    " -Path " & Quote(targetPath)

command = "cmd.exe /c " & Quote(innerCommand)

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
'@
}

function Write-GeneratedRunner {
    if (-not (Test-Path -LiteralPath $headlessScriptPath -PathType Leaf)) {
        throw "Arquivo obrigatorio nao encontrado: $headlessScriptPath"
    }

    $runnerDir = Split-Path -Path $runnerVbsPath -Parent
    if (-not (Test-Path -LiteralPath $runnerDir -PathType Container)) {
        New-Item -ItemType Directory -Path $runnerDir -Force | Out-Null
    }

    $content = Get-GeneratedRunnerContent
    [System.IO.File]::WriteAllText($runnerVbsPath, $content, [System.Text.UTF8Encoding]::new($false))
}

function Remove-GeneratedRunnerIfManaged {
    $removed = $false

    foreach ($candidate in @($runnerVbsPath, $legacyRunnerVbsPath) | Select-Object -Unique) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            continue
        }

        $firstLine = Get-Content -LiteralPath $candidate -TotalCount 1 -ErrorAction SilentlyContinue
        if ($firstLine -eq "' Generated by Instalar VibeToolkit.cmd") {
            Remove-Item -LiteralPath $candidate -Force -ErrorAction Stop
            $removed = $true
        }
    }

    return $removed
}


function Test-VibeToolkitInstalled {
    $paths = @(
        'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\shell\VibeToolkitTerminal',
        'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\VibeToolkitTerminal',
        'Registry::HKEY_CURRENT_USER\Software\Classes\Drive\shell\VibeToolkitTerminal'
    )

    foreach ($path in $paths) {
        if (Test-Path -LiteralPath $path) {
            return $true
        }
    }

    return $false
}

function Resolve-RequestedMode {
    if ($Mode -ne 'auto') {
        return $Mode
    }

    if (-not (Test-VibeToolkitInstalled)) {
        Write-Info 'Nenhuma instalacao ativa detectada. Executando install.'
        return 'install'
    }

    Write-Host ''
    Write-Host 'VibeToolkit ja esta instalado.' -ForegroundColor Yellow
    Write-Host 'Escolha uma opcao:'
    Write-Host '  [1] Repair'
    Write-Host '  [2] Uninstall'
    Write-Host '  [3] Cancelar'
    Write-Host ''

    while ($true) {
        $choice = (Read-Host 'Digite 1, 2 ou 3').Trim().ToLowerInvariant()
        switch ($choice) {
            '1' { return 'repair' }
            'repair' { return 'repair' }
            'r' { return 'repair' }
            '2' { return 'uninstall' }
            'uninstall' { return 'uninstall' }
            'u' { return 'uninstall' }
            '3' { return 'cancel' }
            'cancel' { return 'cancel' }
            'c' { return 'cancel' }
            default {
                Write-Warning 'Opcao invalida. Digite 1, 2 ou 3.'
            }
        }
    }
}

function Install-VibeToolkit {
    Write-Info ('Modo solicitado: {0}' -f $Mode)
    Write-Info ('Repositorio: {0}' -f $RepoRoot)

    $cleanup = Remove-VibeContextMenuKeys
    if ($cleanup.Removed.Count -gt 0) {
        Write-Host 'Chaves antigas removidas antes da reinstalacao:' -ForegroundColor Yellow
        foreach ($item in $cleanup.Removed) {
            Write-Host (' - {0}' -f $item)
        }
    }

    foreach ($warningMessage in $cleanup.Warnings) {
        Write-Warning $warningMessage
    }

    Write-GeneratedRunner

    $iconValue = ('{0},0' -f (Resolve-MenuIconPath))
    $entries = @(
        @{ BaseKey = (Join-Path $classesRoot 'Directory\shell');            MenuKeyName = 'VibeToolkitTerminal'; MenuLabel = 'VibeToolkit: Abrir Terminal (CLI)'; RunnerPath = $runnerVbsPath; ArgumentToken = '%V' },
        @{ BaseKey = (Join-Path $classesRoot 'Directory\Background\shell'); MenuKeyName = 'VibeToolkitTerminal'; MenuLabel = 'VibeToolkit: Abrir Terminal (CLI)'; RunnerPath = $runnerVbsPath; ArgumentToken = '%V' },
        @{ BaseKey = (Join-Path $classesRoot 'Drive\shell');                MenuKeyName = 'VibeToolkitTerminal'; MenuLabel = 'VibeToolkit: Abrir Terminal (CLI)'; RunnerPath = $runnerVbsPath; ArgumentToken = '%1' }
    )

    foreach ($entry in $entries) {
        Set-ContextMenuEntry @entry -IconPath $iconValue
    }

    Write-Host ''
    Write-Host 'VibeToolkit instalado com sucesso.' -ForegroundColor Green
    Write-Host ('Runner VBS gerado em: {0}' -f $runnerVbsPath)
    Write-Host ('Headless script esperado em: {0}' -f $headlessScriptPath)
    Write-Host 'Menu de contexto registrado em HKCU\Software\Classes.'
}

function Uninstall-VibeToolkit {
    Write-Info ('Modo solicitado: {0}' -f $Mode)
    Write-Info ('Repositorio: {0}' -f $RepoRoot)

    $cleanup = Remove-VibeContextMenuKeys
    $runnerRemoved = Remove-GeneratedRunnerIfManaged

    if ($cleanup.Removed.Count -eq 0) {
        Write-Host 'Nenhuma chave encontrada para remover.' -ForegroundColor Yellow
    }
    else {
        Write-Host 'Menu de contexto removido.' -ForegroundColor Green
        foreach ($item in $cleanup.Removed) {
            Write-Host (' - {0}' -f $item)
        }
    }

    foreach ($warningMessage in $cleanup.Warnings) {
        Write-Warning $warningMessage
    }

    if ($runnerRemoved) {
        Write-Host ('Runner removido: {0}' -f $runnerVbsPath)
    }
    else {
        Write-Host 'Nenhum runner gerado automaticamente precisou ser removido.'
    }
}

$effectiveMode = Resolve-RequestedMode
Write-Info ('Modo efetivo: {0}' -f $effectiveMode)

switch ($effectiveMode) {
    'install' {
        Install-VibeToolkit
    }
    'repair' {
        Install-VibeToolkit
    }
    'uninstall' {
        Uninstall-VibeToolkit
    }
    'cancel' {
        Write-Host 'Operacao cancelada pelo usuario.' -ForegroundColor Yellow
        exit 0
    }
    default {
        throw "Modo invalido: $effectiveMode"
    }
}
