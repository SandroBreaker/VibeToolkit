Set WshShell = CreateObject("WScript.Shell")
WshShell.Run """C:\Program Files\PowerShell\7\pwsh.exe"" -ExecutionPolicy Bypass -File ""C:\dev\VibeToolkit\project-bundler.ps1""", 0, False