Set-StrictMode -Version Latest

$script:VibeUtf8NoBom = New-Object System.Text.UTF8Encoding($false, $false)
$script:VibeUtf8Bom = New-Object System.Text.UTF8Encoding($true, $false)

function Get-VibeUtf8Encoding {
    param([switch]$UseBom)
    if ($UseBom) { return $script:VibeUtf8Bom }
    return $script:VibeUtf8NoBom
}

function Remove-VibeAuthenticodeSignatureBlock {
    param(
        [AllowNull()][string]$Content
    )

    if ($null -eq $Content) {
        return ''
    }

    $text = [string]$Content
    if ([string]::IsNullOrEmpty($text)) {
        return $text
    }

    $marker = '# SIG # Begin signature block'
    $index = $text.IndexOf($marker, [System.StringComparison]::Ordinal)

    if ($index -lt 0) {
        return $text
    }

    return $text.Substring(0, $index).TrimEnd()
}

function Read-VibeTextFile {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path $Path -PathType Leaf)) {
        throw "Arquivo de texto não encontrado: $Path"
    }

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($null -eq $bytes -or $bytes.Length -eq 0) {
        return ''
    }

    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return (Remove-VibeAuthenticodeSignatureBlock ([System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)))
    }

    if ($bytes.Length -ge 4 -and $bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
        $utf32Be = New-Object System.Text.UTF32Encoding($true, $true)
        return (Remove-VibeAuthenticodeSignatureBlock ($utf32Be.GetString($bytes, 4, $bytes.Length - 4)))
    }

    if ($bytes.Length -ge 4 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
        return (Remove-VibeAuthenticodeSignatureBlock ([System.Text.Encoding]::UTF32.GetString($bytes, 4, $bytes.Length - 4)))
    }

    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        return (Remove-VibeAuthenticodeSignatureBlock ([System.Text.Encoding]::BigEndianUnicode.GetString($bytes, 2, $bytes.Length - 2)))
    }

    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        return (Remove-VibeAuthenticodeSignatureBlock ([System.Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)))
    }

    try {
        $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
        return (Remove-VibeAuthenticodeSignatureBlock ($strictUtf8.GetString($bytes)))
    }
    catch {
        # Fallback tolerante: continua em UTF-8 e substitui bytes inválidos,
        # evitando mojibake massivo causado por fallback para codepage local.
        try {
            return (Remove-VibeAuthenticodeSignatureBlock ($script:VibeUtf8NoBom.GetString($bytes)))
        }
        catch {
            return (Remove-VibeAuthenticodeSignatureBlock ([System.Text.Encoding]::Default.GetString($bytes)))
        }
    }
}

function Write-VibeTextFile {
    param(
        [string]$Path,
        [AllowEmptyString()][string]$Content,
        [switch]$UseBom
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Path não pode ser vazio."
    }

    $directory = [System.IO.Path]::GetDirectoryName($Path)
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    }

    $safeContent = if ($null -eq $Content) { '' } else { [string]$Content }
    [System.IO.File]::WriteAllText($Path, $safeContent, (Get-VibeUtf8Encoding -UseBom:$UseBom))
}

function Test-VibeMomentumResultFileName {
    param([string]$FileName)
    if ([string]::IsNullOrWhiteSpace($FileName)) { return $false }
    return $FileName -match '(?i)(?:^|_)_ai__.*\.json$'
}

function Resolve-VibeLatestMomentumContext {
    param([string]$SearchRoot)

    $result = [ordered]@{
        Status   = 'absent'
        FilePath = $null
        Content  = $null
        Message  = 'Nenhum contexto momentum anterior válido encontrado.'
        Warnings = @()
    }

    if ([string]::IsNullOrWhiteSpace($SearchRoot) -or -not (Test-Path $SearchRoot -PathType Container)) {
        $result.Message = 'Diretório de busca do contexto momentum não está disponível.'
        return [pscustomobject]$result
    }

    $candidates = @(
        Get-ChildItem -Path $SearchRoot -File -Filter "*.json" -ErrorAction SilentlyContinue |
        Where-Object { Test-VibeMomentumResultFileName -FileName $_.Name } |
        Sort-Object LastWriteTime -Descending
    )

    if ($candidates.Count -eq 0) {
        return [pscustomobject]$result
    }

    foreach ($candidate in $candidates) {
        try {
            $rawContent = Read-VibeTextFile -Path $candidate.FullName
            if ([string]::IsNullOrWhiteSpace($rawContent)) {
                $result.Warnings += "Contexto Momentum ignorado (arquivo vazio): $($candidate.Name)"
                continue
            }

            $null = $rawContent | ConvertFrom-Json -ErrorAction Stop

            $result.Status = 'found'
            $result.FilePath = $candidate.FullName
            $result.Content = $rawContent.Trim()
            $result.Message = 'Contexto Momentum carregado com sucesso.'
            return [pscustomobject]$result
        }
        catch {
            $result.Warnings += "Contexto Momentum inválido ignorado: $($candidate.Name) :: $($_.Exception.Message)"
        }
    }

    if ($result.Warnings.Count -gt 0) {
        $result.Message = 'Nenhum arquivo _ai_ válido pôde ser aproveitado como contexto momentum.'
    }

    return [pscustomobject]$result
}

function Get-VibeMarkdownFenceToken {
    param(
        [AllowNull()][string]$Content,
        [string]$FenceChar = '`',
        [int]$MinimumFenceLength = 4
    )

    if ([string]::IsNullOrEmpty($FenceChar)) {
        throw "FenceChar não pode ser vazio."
    }

    $safeContent = if ($null -eq $Content) { '' } else { [string]$Content }
    $pattern = [regex]::Escape($FenceChar) + '+'
    $regexMatches = [regex]::Matches($safeContent, $pattern)
    $maxRunLength = 0

    foreach ($match in $regexMatches) {
        if ($match.Length -gt $maxRunLength) {
            $maxRunLength = $match.Length
        }
    }

    $fenceLength = [Math]::Max($MinimumFenceLength, ($maxRunLength + 1))
    return ($FenceChar * $fenceLength)
}

function ConvertTo-VibeSafeMarkdownCodeBlock {
    param(
        [AllowNull()][string]$Content,
        [string]$Language = '',
        [string]$FenceChar = '`'
    )

    $safeContent = if ($null -eq $Content) { '' } else { [string]$Content }
    $fence = Get-VibeMarkdownFenceToken -Content $safeContent -FenceChar $FenceChar

    if ([string]::IsNullOrWhiteSpace($Language)) {
        return $fence + "`n" + $safeContent + "`n" + $fence
    }

    return $fence + $Language + "`n" + $safeContent + "`n" + $fence
}

function Get-VibeMomentumSectionContent {
    param($MomentumContext)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('##### 0. CONTEXTO MOMENTUM (ESTADO ANTERIOR)')
    $lines.Add('')

    if ($null -eq $MomentumContext -or $MomentumContext.Status -ne 'found') {
        $message = if ($MomentumContext -and -not [string]::IsNullOrWhiteSpace($MomentumContext.Message)) {
            [string]$MomentumContext.Message
        }
        else {
            'Nenhum contexto momentum anterior disponível.'
        }

        $lines.Add("- Estado: ausente")
        $lines.Add("- Observação: $message")
        return ($lines -join "`n")
    }

    $displayPath = $MomentumContext.FilePath
    try {
        $displayPath = (Resolve-Path -Path $MomentumContext.FilePath -Relative -ErrorAction Stop)
    }
    catch {}

    $lines.Add("- Estado: carregado")
    $lines.Add("- Fonte: $displayPath")
    $lines.Add((ConvertTo-VibeSafeMarkdownCodeBlock -Content (([string]$MomentumContext.Content).Trim()) -Language 'json'))

    return ($lines -join "`n")
}

function Get-VibeCodeFenceLanguageFromExtension {
    param([string]$Extension)
    $Ext = ($Extension | ForEach-Object { $_ })
    if ([string]::IsNullOrWhiteSpace($Ext)) { return "text" }
    $Ext = $Ext.TrimStart('.').ToLowerInvariant()
    if ($Ext -match '^(tsx?)$') { return 'typescript' }
    if ($Ext -match '^(jsx?)$') { return 'javascript' }
    if ($Ext -match '^(py)$') { return 'python' }
    if ($Ext -match '^(cs)$') { return 'csharp' }
    if ($Ext -match '^(rb)$') { return 'ruby' }
    if ($Ext -match '^(rs)$') { return 'rust' }
    if ($Ext -match '^(kt)$') { return 'kotlin' }
    if ($Ext -match '^(go)$') { return 'go' }
    if ($Ext -match '^(java)$') { return 'java' }
    if ($Ext -match '^(php)$') { return 'php' }
    if ($Ext -match '^(c|h|cpp|hpp)$') { return 'cpp' }
    if ($Ext -match '^(ps1|psm1)$') { return 'powershell' }
    return $Ext
}

Export-ModuleMember -Function Get-VibeUtf8Encoding, Read-VibeTextFile, Write-VibeTextFile, Test-VibeMomentumResultFileName, Resolve-VibeLatestMomentumContext, Get-VibeMarkdownFenceToken, ConvertTo-VibeSafeMarkdownCodeBlock, Get-VibeMomentumSectionContent, Get-VibeCodeFenceLanguageFromExtension