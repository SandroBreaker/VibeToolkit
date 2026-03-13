# =================================================================
# VibeToolkit - Uninstaller (Remove Context Menu) - SIMPLIFICADO
# =================================================================

# Tenta liberar a execução nesta sessão
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-Host "Removendo o VibeToolkit do seu Windows..." -ForegroundColor Cyan

$Paths = @(
    "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkit",
    "Registry::HKEY_CLASSES_ROOT\Directory\shell\VibeToolkit"
)

foreach ($Path in $Paths) {
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
        Write-Host "[✓] Removido de: $Path" -ForegroundColor Green
    } else {
        Write-Host "[!] Não encontrado: $Path" -ForegroundColor DarkGray
    }
}

Write-Host "`nLimpeza concluída!" -ForegroundColor Yellow
Write-Host "Pressione Enter para sair..."
$null = Read-Host