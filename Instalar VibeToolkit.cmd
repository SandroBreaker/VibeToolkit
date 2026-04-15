@echo off
title Instalador do VibeToolkit
echo.
echo === VibeToolkit - Instalador Automatico ===
echo.
where pwsh.exe >nul 2>nul
if %errorlevel%==0 (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-vibe-toolkit.ps1"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-vibe-toolkit.ps1"
)

set "EXIT_CODE=%ERRORLEVEL%"
echo.
if not "%EXIT_CODE%"=="0" (
    echo Instalacao falhou. Codigo: %EXIT_CODE%
) else (
    echo Instalacao concluida. Pressione qualquer tecla para sair...
)
pause > nul
exit /b %EXIT_CODE%
