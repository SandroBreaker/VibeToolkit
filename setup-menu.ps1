# =================================================================
# VibeToolkit - Context Menu & Environment Auto-Installer
# =================================================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Cyan = [ConsoleColor]::Cyan
$Green = [ConsoleColor]::Green
$Yellow = [ConsoleColor]::Yellow
$White = [ConsoleColor]::White

Clear-Host
Write-Host "  ⚡ INSTALADOR VIBETOOLKIT ⚡" -ForegroundColor $Cyan
Write-Host "  ==========================" -ForegroundColor $Cyan
Write-Host "  Preparando seu ambiente para o futuro...`n" -ForegroundColor $White

# 1. TENTA CONFIGURAR A POLÍTICA DE EXECUÇÃO AUTOMATICAMENTE
Write-Host "  [+] Configurando permissões do PowerShell..." -ForegroundColor $White
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# 2. VERIFICA PRÉ-REQUISITOS (NODE.JS)
$NodeCheck = Get-Command node -ErrorAction SilentlyContinue
if (-not $NodeCheck) {
    Write-Host "  [!] Ops! O VibeToolkit precisa do Node.js instalado." -ForegroundColor $Yellow
    Write-Host "      Baixe em nodejs.org e tente novamente. :)" -ForegroundColor $White
    Pause
    exit
}

# 3. VERIFICA E CRIA ARQUIVO .ENV
$EnvFile = Join-Path $ScriptDir ".env"
if (-not (Test-Path $EnvFile)) {
    Write-Host "`n  🧠 Precisamos da sua chave da Groq para a IA funcionar." -ForegroundColor $Cyan
    $ApiKey = Read-Host "  👉 Cole aqui sua chave (ex: gsk_...)"
    if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
        "GROQ_API_KEY=$ApiKey" | Set-Content -Path $EnvFile -Encoding UTF8
        Write-Host "  [✓] Chave salva com sucesso!" -ForegroundColor $Green
    } else {
        Write-Host "  [!] Nenhuma chave colada. A IA não funcionará sem ela." -ForegroundColor $Yellow
    }
}

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
    
    Write-Host "`n  🚀 Quase lá! Pronto para adicionar o atalho ao Windows?" -ForegroundColor $Cyan
    $Confirm = Read-Host "  Deseja habilitar o Menu de Contexto agora? (S/N)"
    
    if ($Confirm -match '^[Ss]$') {
        Start-Process "regedit.exe" -ArgumentList "/s `"$RegFile`"" -Verb RunAs
        Write-Host "  [✓] Tudo pronto! Agora é só clicar com o botão direito nas pastas." -ForegroundColor $Green
    } else {
        Write-Host "  [!] Atalho ignorado. Você pode ativar depois rodando este script." -ForegroundColor $Yellow
    }
} catch {
    Write-Host "  [!] Erro ao criar registro. Tente rodar como Administrador." -ForegroundColor Red
}

Write-Host "`n  Finalizado. Boa vibe! ✌️" -ForegroundColor $Green
Start-Sleep -Seconds 3
