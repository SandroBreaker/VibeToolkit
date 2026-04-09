@echo off
title Instalador do VibeToolkit
echo.
echo === VibeToolkit - Instalador Automatico ===
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-vibe-toolkit.ps1"
echo.
echo Instalacao concluida. Pressione qualquer tecla para sair...
pause > nul