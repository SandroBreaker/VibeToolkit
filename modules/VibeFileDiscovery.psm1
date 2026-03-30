Set-StrictMode -Version Latest

function Test-VibeGeneratedArtifactFileName {
    param([string]$FileName)
    if ([string]::IsNullOrWhiteSpace($FileName)) { return $false }
    return $FileName -match '^_(?:(?:Diretor|Executor)_)?(?:BUNDLER__|BLUEPRINT__|SELECTIVE__|COPIAR_TUDO__|INTELIGENTE__|MANUAL__|AI_CONTEXT_|_ai__)'
}

function Get-VibeRelevantFiles {
    param([string]$CurrentPath, [string[]]$AllowedExtensions, [string[]]$IgnoredDirs, [string[]]$IgnoredFiles)
    try {
        $Items = Get-ChildItem -Path $CurrentPath -ErrorAction Stop
        foreach ($Item in $Items) {
            if ($Item.PSIsContainer) {
                if ($Item.Name -notin $IgnoredDirs) { Get-VibeRelevantFiles -CurrentPath $Item.FullName -AllowedExtensions $AllowedExtensions -IgnoredDirs $IgnoredDirs -IgnoredFiles $IgnoredFiles }
            }
            else {
                $IsTarget = ($Item.Extension -in $AllowedExtensions) -and
                ($Item.Name -notin $IgnoredFiles) -and
                ($Item.BaseName -notmatch '-[a-f0-9]{8,}$') -and
                (-not (Test-VibeGeneratedArtifactFileName -FileName $Item.Name))
                if ($IsTarget) { $Item }
            }
        }
    }
    catch {}
}

Export-ModuleMember -Function Test-VibeGeneratedArtifactFileName, Get-VibeRelevantFiles
# SIG # Begin signature block
# MIIFuQYJKoZIhvcNAQcCoIIFqjCCBaYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBb5JFk+bjMxqEP
# Fsi9QoXf7XXzI+FqUjOjPv/++Yded6CCAyIwggMeMIICBqADAgECAhAcFjwdvC4r
# pEKLSn91yN5dMA0GCSqGSIb3DQEBCwUAMCcxJTAjBgNVBAMMHFZpYmVUb29sa2l0
# IERldiBDb2RlIFNpZ25pbmcwHhcNMjYwMzMwMTQyMTUzWhcNMjcwMzMwMTQ0MTUz
# WjAnMSUwIwYDVQQDDBxWaWJlVG9vbGtpdCBEZXYgQ29kZSBTaWduaW5nMIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuptAnyghPTgYHSqxi/7cqAdDmsJI
# 5BsmeTnQU9CHJgKu7eNz0Zr/xrK0LUDaOnLsl2OzwSF9xEFJBNCiA10K8+jBeef3
# aZLfZ3x6FOO2AfuQ6m8QPGGjXaoZI5mFDm9+yMNIN4FdxXXKkO5YX0zm0HDxcRCX
# idApXbNp2CQUEl4ChQbUD9vCD3Z4zgTEqIsUbfUGgkJEIWnK2ciJr65F4g/ke9Fg
# 1DItL4X7MLv585k/mWkCz+ak/Tmf9UDbJaEF999Q8vVD0xaTB1KtEwWZ52MLaThk
# TuykgzVHQDJHkWSp30XNB3eFygLugcbRGVFTGB3t58LuKBxeoetICRqzBQIDAQAB
# o0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0O
# BBYEFN6/fvmie8yDQXUs9EgF7KOOhndSMA0GCSqGSIb3DQEBCwUAA4IBAQAdLCBI
# zlSl2aeFseJefhm8b9i9HKFrVf+qcpCLGt6J6OUcHqE09BIBzUyMU+WJ+3NrNZPm
# hOZ6fNuWlWJypANLXesqBYbwFEkXRqwua2JxmXard0OIPGkfkqMTL0TvMrakUsA6
# Zj0ZVwzWnZUFk6aYGIwAEG9Kk6GmjjPxDTKNW5RTgtXT8j6U0zERr0qfm0iNzH+W
# 8/guu3a9pjHJJkZJzZpOXPNmgfxUZyzakeBxxzT5aaAs5CVeXI8Z1TKt/WEHkycB
# XLf8+4ldM8Wn4b2l8LZ1+Riv6j2wTQgli/ngCIIjhXH3HXQYBcP13+ZtE8fk9Vlx
# 6TXUuTo1w5HVU5WYMYIB7TCCAekCAQEwOzAnMSUwIwYDVQQDDBxWaWJlVG9vbGtp
# dCBEZXYgQ29kZSBTaWduaW5nAhAcFjwdvC4rpEKLSn91yN5dMA0GCWCGSAFlAwQC
# AQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZI
# hvcNAQkEMSIEIEr3p01ND7JFCpc7t2MffxdbQVCtXPHBD/CpNQQm/3NKMA0GCSqG
# SIb3DQEBAQUABIIBAB8wTQrtf6wQlSssashDMb+YbGFV5goqYz9KBMgN2x4ATrxs
# q69RDs/rwvfz5yNpwnSHlJLfNqMr1OeUFStlrEJumYN5V0AA4U0Fr6LLzqgFiUAJ
# et3CedfeIhkTw1RKmJdal6rI02sB/Ubs1qywCq7hU+N5EyNs62C0sEmuurRnkbOJ
# EBjLKkCNWXRwVZoxPzRctyoKufpmr2OjUAxfKfaevCSoNdWCFSA6xOXcvmW/03wt
# ioqEnBSnr4yL05vbo8k2nrROtp4WFnvI2eAoeD2oaAXDOtvEsWSoFtA3kdtHnNJU
# FS3ijDTAhDgJFDhwZs1u4h2SJC6WCHRCWoteNTs=
# SIG # End signature block
