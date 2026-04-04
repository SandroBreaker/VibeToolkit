Dim targetPath
Dim args
Dim WshShell

Set WshShell = CreateObject("WScript.Shell")
Set args = WScript.Arguments

' Aceita o caminho passado pelo menu de contexto (registry %V ou %1)
If args.Count > 0 Then
    targetPath = args(0)
Else
    targetPath = WshShell.CurrentDirectory
End If

' Modo Terminal: Abre pwsh de forma visivel (1) para permitir interacao console (Sniper, etc)
' Nao usamos -NoExit aqui para que a janela feche apos a conclusao, a menos que o script peça pausa
WshShell.Run """C:\Program Files\PowerShell\7\pwsh.exe"" -ExecutionPolicy Bypass -NoProfile -File ""C:\dev\VibeToolkit\project-bundler-headless.ps1"" -Path """ & targetPath & """", 1, False
