# =================================================================
# VibeToolkit - Context Menu Auto-Installer
# =================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BundlerPath = Join-Path $ScriptDir "project-bundler.ps1"
$RegFile = Join-Path $ScriptDir "install-vibe-menu.reg"

# Escapar barras invertidas para o formato de Registro do Windows
$EscapedPath = $BundlerPath -replace '\\', '\\\\'

$RegContent = @"
Windows Registry Editor Version 5.00

; 1. Opção para o clique direito no espaço em branco de uma pasta aberta
[HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkit]
@="Gerar Blueprint / Contexto (Vibe AI)"
"Icon"="powershell.exe"

[HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkit\command]
@="powershell.exe -ExecutionPolicy Bypass -NoProfile -File \"$EscapedPath\" -Path \"%V\""

; 2. Opção para o clique direito em cima do ícone de uma pasta
[HKEY_CLASSES_ROOT\Directory\shell\VibeToolkit]
@="Gerar Blueprint / Contexto (Vibe AI)"
"Icon"="powershell.exe"

[HKEY_CLASSES_ROOT\Directory\shell\VibeToolkit\command]
@="powershell.exe -ExecutionPolicy Bypass -NoProfile -File \"$EscapedPath\" -Path \"%1\""
"@

try {
    [System.IO.File]::WriteAllText($RegFile, $RegContent, [System.Text.Encoding]::Unicode)
    
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host " [✓] Ficheiro de registo gerado com sucesso!" -ForegroundColor Green
    Write-Host " Caminho: $RegFile"
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Deseja aplicar as alterações ao Registro agora? (S/N)" -ForegroundColor Cyan
    
    $Confirm = Read-Host
    if ($Confirm -match '^[Ss]$') {
        Start-Process "regedit.exe" -ArgumentList "/s `"$RegFile`"" -Verb RunAs
        Write-Host "[✓] Menu de contexto instalado!" -ForegroundColor Green
    } else {
        Write-Host "[!] Operação cancelada. Execute o ficheiro .reg manualmente." -ForegroundColor Yellow
    }
} catch {
    Write-Error "Falha ao gerar o ficheiro: $($_.Exception.Message)"
}

Pause