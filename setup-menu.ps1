# =================================================================
# VibeToolkit - Context Menu & Environment Auto-Installer
# =================================================================

# 1. TENTA CONFIGURAR A POLÍTICA DE EXECUÇÃO AUTOMATICAMENTE
Write-Host "[*] Configurando permissões do PowerShell..." -ForegroundColor Cyan
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# 2. VERIFICA PRÉ-REQUISITOS (NODE.JS)
$NodeCheck = Get-Command node -ErrorAction SilentlyContinue
if (-not $NodeCheck) {
    Write-Error "Node.js não encontrado! Por favor, instale o Node.js antes de continuar."
    Pause
    exit
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BundlerPath = Join-Path $ScriptDir "project-bundler.ps1"
$RegFile = Join-Path $ScriptDir "install-vibe-menu.reg"

$EscapedPath = $BundlerPath -replace '\\', '\\\\'

$RegContent = @"
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkit]
@="Gerar Blueprint / Contexto (Vibe AI)"
"Icon"="powershell.exe"

[HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkit\command]
@="powershell.exe -ExecutionPolicy Bypass -NoProfile -File \"$EscapedPath\" -Path \"%V\""

[HKEY_CLASSES_ROOT\Directory\shell\VibeToolkit]
@="Gerar Blueprint / Contexto (Vibe AI)"
"Icon"="powershell.exe"

[HKEY_CLASSES_ROOT\Directory\shell\VibeToolkit\command]
@="powershell.exe -ExecutionPolicy Bypass -NoProfile -File \"$EscapedPath\" -Path \"%1\""
"@

try {
    [System.IO.File]::WriteAllText($RegFile, $RegContent, [System.Text.Encoding]::Unicode)
    
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host " [✓] Verificações de ambiente concluídas!" -ForegroundColor Green
    Write-Host " [✓] Ficheiro de registo gerado com sucesso!" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Deseja aplicar as alterações ao Registro (Botão Direito) agora? (S/N)" -ForegroundColor Cyan
    
    $Confirm = Read-Host
    if ($Confirm -match '^[Ss]$') {
        Start-Process "regedit.exe" -ArgumentList "/s `"$RegFile`"" -Verb RunAs
        Write-Host "[✓] Menu de contexto instalado e permissões configuradas!" -ForegroundColor Green
    }
} catch {
    Write-Error "Falha ao gerar o ficheiro: $($_.Exception.Message)"
}

Pause