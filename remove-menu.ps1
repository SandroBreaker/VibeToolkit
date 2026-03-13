# =================================================================
# VibeToolkit - Uninstaller (Remove Context Menu)
# =================================================================

Write-Host "Removendo o VibeToolkit do seu Windows..." -ForegroundColor Cyan

$Paths = @(
    "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkit",
    "Registry::HKEY_CLASSES_ROOT\Directory\shell\VibeToolkit"
)

foreach ($Path in $Paths) {
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
        Write-Host "[✓] Removido de: $Path" -ForegroundColor Green
    }
}

Write-Host "`nLimpeza concluída! O menu de contexto foi removido." -ForegroundColor Yellow
Pause