Dim targetPath, args, WshShell, fso, scriptDir, powerShellExe

Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
Set args = WScript.Arguments

' Obtem o diretorio onde o VBS esta localizado
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
powerShellExe = ResolvePowerShellExecutable()

' Aceita o caminho passado pelo menu de contexto (registry %V ou %1)
If args.Count > 0 Then
    targetPath = args(0)
Else
    targetPath = WshShell.CurrentDirectory
End If

' Chama PowerShell com fallback robusto e sem depender de C:\dev\VibeToolkit
' Argumentos: -NoProfile (evita carregar perfis lentos), -ExecutionPolicy Bypass (evita bloqueios)
' Modo Terminal (CLI): Abre PowerShell de forma visivel (1)
WshShell.Run powerShellExe & " -NoProfile -ExecutionPolicy Bypass -File """ & scriptDir & "\project-bundler-headless.ps1"" -Path """ & targetPath & """", 1, False

Function ResolvePowerShellExecutable()
    Dim defaultPwsh, legacyPowerShell, resolvedPath

    defaultPwsh = WshShell.ExpandEnvironmentStrings("%ProgramFiles%") & "\PowerShell\7\pwsh.exe"
    If fso.FileExists(defaultPwsh) Then
        ResolvePowerShellExecutable = Quote(defaultPwsh)
        Exit Function
    End If

    resolvedPath = ResolveFirstPathFromWhere("pwsh.exe")
    If Len(resolvedPath) > 0 Then
        ResolvePowerShellExecutable = Quote(resolvedPath)
        Exit Function
    End If

    legacyPowerShell = WshShell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
    If fso.FileExists(legacyPowerShell) Then
        ResolvePowerShellExecutable = Quote(legacyPowerShell)
        Exit Function
    End If

    ResolvePowerShellExecutable = "pwsh.exe"
End Function

Function ResolveFirstPathFromWhere(executableName)
    Dim execObj, outputLines, commandOutput

    On Error Resume Next
    Set execObj = WshShell.Exec("cmd.exe /c where " & executableName)
    If Err.Number <> 0 Then
        Err.Clear
        ResolveFirstPathFromWhere = ""
        On Error GoTo 0
        Exit Function
    End If
    On Error GoTo 0

    Do While execObj.Status = 0
        WScript.Sleep 25
    Loop

    commandOutput = Trim(execObj.StdOut.ReadAll)
    If Len(commandOutput) = 0 Then
        ResolveFirstPathFromWhere = ""
        Exit Function
    End If

    outputLines = Split(Replace(commandOutput, vbCr, ""), vbLf)
    ResolveFirstPathFromWhere = Trim(outputLines(0))
End Function

Function Quote(value)
    Quote = Chr(34) & value & Chr(34)
End Function
