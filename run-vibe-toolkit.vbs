Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -ExecutionPolicy Bypass -File ""C:\dev\VibeToolkit\project-bundler.ps1""", 0, False