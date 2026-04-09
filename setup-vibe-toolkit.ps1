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