# =================================================================
# VibeToolkit - Context Menu & Environment Auto-Installer
# =================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. TENTA CONFIGURAR A POLÍTICA DE EXECUÇÃO AUTOMATICAMENTE
Write-Host "Preparando tudo para você..." -ForegroundColor Cyan
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# 2. VERIFICA PRÉ-REQUISITOS (NODE.JS)
$NodeCheck = Get-Command node -ErrorAction SilentlyContinue
if (-not $NodeCheck) {
    Write-Host "Ops! O VibeToolkit precisa do Node.js instalado. Baixe rapidamente em nodejs.org, instale e rode este script novamente." -ForegroundColor Yellow
    Pause
    exit
}

# 3. VERIFICA E CRIA ARQUIVO .ENV
$EnvFile = Join-Path $ScriptDir ".env"
if (-not (Test-Path $EnvFile)) {
    Write-Host "`nPrecisamos da sua chave da Groq para a Inteligência Artificial funcionar." -ForegroundColor Cyan
    $ApiKey = Read-Host "Cole aqui sua chave gratuita da Groq API (acesse console.groq.com)"
    if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
        "GROQ_API_KEY=$ApiKey" | Set-Content -Path $EnvFile -Encoding UTF8
        Write-Host "Chave salva com sucesso no arquivo .env!" -ForegroundColor Green
    } else {
        Write-Host "Nenhuma chave foi colada. Você precisará criar o arquivo .env manualmente depois." -ForegroundColor Yellow
    }
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
    
    Write-Host "`nQuase pronto! O último passo é adicionar a opção do VibeToolkit no seu Windows." -ForegroundColor Cyan
    $Confirm = Read-Host "Deseja adicionar o atalho ao botão direito do mouse agora? (S/N)"
    
    if ($Confirm -match '^[Ss]$') {
        Start-Process "regedit.exe" -ArgumentList "/s `"$RegFile`"" -Verb RunAs
        Write-Host "Tudo pronto! O atalho foi adicionado com sucesso. :)" -ForegroundColor Green
    } else {
        Write-Host "Tudo bem! Você pode rodar este script novamente caso mude de ideia." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Ops, não foi possível criar o arquivo de atalho. Tente rodar como Administrador." -ForegroundColor Red
}

Write-Host "`nPressione Enter para sair..." -ForegroundColor Cyan
Read-Host | Out-Null
