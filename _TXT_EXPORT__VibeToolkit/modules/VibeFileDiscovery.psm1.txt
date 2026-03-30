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