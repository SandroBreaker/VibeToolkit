Set-StrictMode -Version Latest

function Test-VibeGeneratedArtifactFileName {
    param([string]$FileName)

    if ([string]::IsNullOrWhiteSpace($FileName)) {
        return $false
    }

    $patterns = @(
        '^_(?:Diretor|Executor)_',
        '^_(?:COPIAR_TUDO|INTELIGENTE|MANUAL)__',
        '^_TXT_EXPORT__',
        '^_TXT_EXPORT__.*\.zip$',
        '^_(?:bundle|blueprint|manual|txt_export)_(?:diretor|executor)(?:_[A-Za-z0-9\-]+)?__.*\.(?:md|json)$',
        '^_meta-prompt_(?:bundle|blueprint|manual)_(?:diretor|executor)(?:_[A-Za-z0-9\-]+)?__.*\.(?:md|json)$'
    )

    foreach ($pattern in $patterns) {
        if ($FileName -match $pattern) {
            return $true
        }
    }

    return $false
}

function Get-VibeRelevantFiles {
    param(
        [string]$CurrentPath,
        [string[]]$AllowedExtensions,
        [string[]]$IgnoredDirs,
        [string[]]$IgnoredFiles
    )

    try {
        $items = Get-ChildItem -Path $CurrentPath -ErrorAction Stop

        foreach ($item in $items) {
            if ($item.PSIsContainer) {
                if ($item.Name -notin $IgnoredDirs) {
                    Get-VibeRelevantFiles -CurrentPath $item.FullName -AllowedExtensions $AllowedExtensions -IgnoredDirs $IgnoredDirs -IgnoredFiles $IgnoredFiles
                }

                continue
            }

            $isTarget =
                ($item.Extension -in $AllowedExtensions) -and
                ($item.Name -notin $IgnoredFiles) -and
                ($item.BaseName -notmatch '-[a-f0-9]{8,}$') -and
                (-not (Test-VibeGeneratedArtifactFileName -FileName $item.Name))

            if ($isTarget) {
                $item
            }
        }
    }
    catch {
    }
}

Export-ModuleMember -Function Test-VibeGeneratedArtifactFileName, Get-VibeRelevantFiles
