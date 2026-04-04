Dim targetPath, args, WshShell, fso, scriptDir

Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
Set args = WScript.Arguments

' Obtem o diretorio onde o VBS esta localizado
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)

' Aceita o caminho passado pelo menu de contexto (registry %V ou %1)
If args.Count > 0 Then
    targetPath = args(0)
Else
    targetPath = WshShell.CurrentDirectory
End If

' Chama pwsh explicitamente para maior estabilidade e compatibilidade com versao 7+
' Argumentos: -NoProfile (evita carregar perfis lentos), -ExecutionPolicy Bypass (evita bloqueios)
' Modo HUD (WPF): Abre pwsh de forma oculta (0)
WshShell.Run "pwsh.exe -NoProfile -ExecutionPolicy Bypass -File """ & scriptDir & "\project-bundler-hud.ps1"" -Path """ & targetPath & """", 0, False