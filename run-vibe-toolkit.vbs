Dim targetPath
Dim args
Dim WshShell

Set WshShell = CreateObject("WScript.Shell")
Set args = WScript.Arguments

' Aceita o caminho passado pelo menu de contexto (registry %V ou %1)
' Se nao receber argumento, usa o diretorio corrente
If args.Count > 0 Then
    targetPath = args(0)
Else
    targetPath = WshShell.CurrentDirectory
End If

' Atualizado para o novo caminho do modulo e script do HUD WPF
' Nota: O caminho deve ser ajustado se o toolkit for movido
WshShell.Run """C:\Program Files\PowerShell\7\pwsh.exe"" -ExecutionPolicy Bypass -NoProfile -File ""C:\dev\VibeToolkit\project-bundler-hud.ps1"" -Path """ & targetPath & """", 0, False