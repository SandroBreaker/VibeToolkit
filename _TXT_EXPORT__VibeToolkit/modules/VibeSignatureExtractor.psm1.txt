Set-StrictMode -Version Latest

function Get-VibePowerShellFunctionSignatures {
    param([string[]]$Lines)

    if ($null -eq $Lines -or $Lines.Count -eq 0) { return @() }

    $signatures = New-Object System.Collections.Generic.List[string]

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $rawLine = $Lines[$i]
        if ($null -eq $rawLine) { continue }

        $trimmedLine = $rawLine.Trim()
        if ($trimmedLine -notmatch '^(?:filter|function)\s+((?:global:|script:)?[A-Za-z0-9_-]+)\s*\{?\s*$') { continue }

        $signatureLines = New-Object System.Collections.Generic.List[string]
        $signatureLines.Add($trimmedLine)

        $j = $i + 1
        while ($j -lt $Lines.Count) {
            $candidateRaw = $Lines[$j]
            if ($null -eq $candidateRaw) { $j++; continue }

            $candidateTrimmed = $candidateRaw.Trim()

            if ([string]::IsNullOrWhiteSpace($candidateTrimmed)) {
                $j++
                continue
            }

            if ($candidateTrimmed -match '^\s*#') {
                $j++
                continue
            }

            if ($candidateTrimmed -match '^param\b') {
                $paramBlock = New-Object System.Collections.Generic.List[string]
                $parenBalance = 0

                do {
                    $paramRaw = $Lines[$j]
                    if ($null -eq $paramRaw) { break }

                    $paramTrimmed = $paramRaw.TrimEnd()
                    $paramBlock.Add($paramTrimmed)

                    $openCount = ([regex]::Matches($paramTrimmed, '\(')).Count
                    $closeCount = ([regex]::Matches($paramTrimmed, '\)')).Count
                    $parenBalance += ($openCount - $closeCount)
                    $j++
                }
                while ($j -lt $Lines.Count -and $parenBalance -gt 0)

                foreach ($paramLine in $paramBlock) {
                    $signatureLines.Add($paramLine)
                }
            }

            break
        }

        $signatures.Add((($signatureLines | Where-Object { $null -ne $_ }) -join "`n") + "`n")
        $i = [Math]::Max($i, $j - 1)
    }

    return @($signatures)
}

function Get-VibeBundlerSignaturesForFile {
    param([System.IO.FileInfo]$File, [ref]$IssueMessage)
    if ($IssueMessage) { $IssueMessage.Value = $null }
    if ($null -eq $File) { return @() }
    $RelPath = Resolve-Path -Path $File.FullName -Relative
    $ContentRaw = Read-VibeTextFile -Path $File.FullName
    if ([string]::IsNullOrWhiteSpace($ContentRaw)) { return @() }
    try {
        $Lines = @([regex]::Split($ContentRaw, "`r?`n"))
        if ($File.Extension -eq '.ps1') {
            return @(Get-VibePowerShellFunctionSignatures -Lines $Lines)
        }

        $Signatures = @()
        for ($i = 0; $i -lt $Lines.Count; $i++) {
            $RawLine = $Lines[$i]
            if ($null -eq $RawLine) { continue }
            $Line = $RawLine.Trim()
            if ($Line -match '^(?:export\s+)?(interface|type|enum)\s+[A-Za-z0-9_]+') {
                $Block = "$Line`n"
                if ($Line -notmatch '\}' -and $Line -notmatch ' = ' -and $Line -notmatch ';$') {
                    $j = $i + 1
                    while ($j -lt $Lines.Count -and $Lines[$j] -notmatch '^\}') {
                        $Block += "$($Lines[$j])`n"; $j++
                    }
                    if ($j -lt $Lines.Count) { $Block += "$($Lines[$j])`n" }
                    $i = $j
                }
                $Signatures += $Block
            }
            elseif ($Line -match '^(?:export\s+)?(?:const|function|class)\s+[A-Za-z0-9_]+') {
                $Signatures += "$(($Line -replace '\{.*$','') -replace '\s*=>.*$','')`n"
            }
            elseif ($Line -match '^(?:public|protected|private|internal)\s+(?:class|interface|record|struct|enum)\s+[A-Za-z0-9_]+') {
                $Signatures += "$($Line -replace '\{.*$','')`n"
            }
            elseif ($Line -match '^(?:def|class)\s+[A-Za-z0-9_]+') {
                $Signatures += "$($Line -replace ':$','')`n"
            }
            elseif ($Line -match '^func\s+[A-Za-z0-9_]+') {
                $Signatures += "$($Line -replace '\{.*$','')`n"
            }
            elseif ($Line -match '^(?:pub\s+)?(?:fn|struct|enum|trait)\s+[A-Za-z0-9_]+') {
                $Signatures += "$($Line -replace '\{.*$','')`n"
            }
        }
        return @($Signatures)
    }
    catch {
        if ($IssueMessage) { $IssueMessage.Value = "[$RelPath] $($_.Exception.Message)" }
        return @()
    }
}

Export-ModuleMember -Function Get-VibePowerShellFunctionSignatures, Get-VibeBundlerSignaturesForFile