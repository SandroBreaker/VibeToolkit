Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-SentinelDeclaredFlowId {
    param(
        [string]$ExtractionMode,
        [string]$RouteMode
    )

    $declaredFlowMap = [ordered]@{
        'full:director'      = 'full_director'
        'full:executor'      = 'full_executor'
        'blueprint:director' = 'blueprint_director'
        'blueprint:executor' = 'blueprint_executor'
    }

    $resolutionKey = ('{0}:{1}' -f [string]$ExtractionMode, [string]$RouteMode).ToLowerInvariant()
    if ($declaredFlowMap.Contains($resolutionKey)) {
        return [string]$declaredFlowMap[$resolutionKey]
    }

    return $null
}

function Get-SentinelDeclaredFlowDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolkitDir
    )

    return (Join-Path $ToolkitDir 'flows')
}

function New-SentinelDeclaredFlowStepRegistry {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$SignatureExtractor,
        [Parameter(Mandatory = $true)]
        [scriptblock]$MetaPromptBuilder,
        [Parameter(Mandatory = $true)]
        [scriptblock]$ArtifactWriter
    )

    return @{
        discover_files = {
            param($flowState, $step)
            $count = @($flowState.Files).Count
            @{ outputSummary = "$count file(s) available in current pipeline state" }
        }
        extract_signatures = {
            param($flowState, $step)
            if (-not $flowState.Files -or @($flowState.Files).Count -eq 0) {
                throw "No files available for signature audit."
            }

            $signatureHits = 0
            foreach ($file in @($flowState.Files)) {
                $issueMessage = ''
                $signatures = & $SignatureExtractor $file ([ref]$issueMessage)
                if ($signatures -and @($signatures).Count -gt 0) {
                    $signatureHits++
                }
            }

            $flowState.ExtractedSignatureFileCount = $signatureHits
            @{ outputSummary = "$signatureHits file(s) with extractable signatures" }
        }
        build_bundle = {
            param($flowState, $step)
            if ([string]::IsNullOrWhiteSpace($flowState.BundleContent)) {
                throw "Bundle content is empty in current pipeline state."
            }

            @{ outputSummary = "bundle already materialized ($($flowState.BundleContent.Length) chars)" }
        }
        build_meta_prompt = {
            param($flowState, $step)

            if (-not [string]::IsNullOrWhiteSpace($flowState.MetaPromptOutputPath) -and (Test-Path -LiteralPath $flowState.MetaPromptOutputPath)) {
                $flowState.MetaPromptContent = Get-Content -LiteralPath $flowState.MetaPromptOutputPath -Raw -Encoding utf8
                return @{ outputSummary = "existing deterministic meta-prompt reused" }
            }

            $flowState.MetaPromptContent = & $MetaPromptBuilder $flowState
            @{ outputSummary = "deterministic meta-prompt prepared ($($flowState.MetaPromptContent.Length) chars)" }
        }
        validate_result = {
            param($flowState, $step)
            if ([string]::IsNullOrWhiteSpace($flowState.BundleContent)) {
                throw "Bundle content is empty."
            }

            $hasExistingMetaPrompt = (
                -not [string]::IsNullOrWhiteSpace($flowState.MetaPromptOutputPath) -and
                (Test-Path -LiteralPath $flowState.MetaPromptOutputPath)
            )

            if ([string]::IsNullOrWhiteSpace($flowState.MetaPromptContent) -and -not $hasExistingMetaPrompt) {
                throw "Meta-prompt content is empty."
            }

            @{ outputSummary = "bundle/meta prompt validated" }
        }
        save_artifacts = {
            param($flowState, $step)

            if ([string]::IsNullOrWhiteSpace($flowState.MetaPromptOutputPath)) {
                return @{ outputSummary = "no meta-prompt output path available; nothing to save" }
            }

            if (Test-Path -LiteralPath $flowState.MetaPromptOutputPath) {
                return @{ outputSummary = "existing artifacts preserved" }
            }

            if ([string]::IsNullOrWhiteSpace($flowState.MetaPromptContent)) {
                throw "No meta-prompt content available to save."
            }

            & $ArtifactWriter $flowState.MetaPromptOutputPath $flowState.MetaPromptContent
            @{ outputSummary = "meta-prompt saved to $([System.IO.Path]::GetFileName($flowState.MetaPromptOutputPath))" }
        }
    }
}

function Invoke-SentinelDeclaredFinalizationFlow {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolkitDir,
        [string]$ProjectNameValue,
        [string]$ExecutorTargetValue,
        [string]$ExtractionMode,
        [string]$DocumentMode,
        [string]$RouteMode,
        [AllowEmptyString()][string]$SourceArtifactFileName = '',
        [AllowEmptyString()][string]$OutputArtifactFileName = '',
        [AllowEmptyString()][string]$BundleContent = '',
        [System.IO.FileInfo[]]$Files,
        [AllowNull()][string]$MetaPromptOutputPath = $null,
        [Parameter(Mandatory = $true)]
        [scriptblock]$SignatureExtractor,
        [Parameter(Mandatory = $true)]
        [scriptblock]$MetaPromptBuilder,
        [Parameter(Mandatory = $true)]
        [scriptblock]$ArtifactWriter,
        [scriptblock]$LogWriter
    )

    $flowId = Resolve-SentinelDeclaredFlowId -ExtractionMode $ExtractionMode -RouteMode $RouteMode
    if ([string]::IsNullOrWhiteSpace($flowId)) {
        return $null
    }

    $flowPath = Resolve-VibeExecutionFlowDefinitionPath -BasePath (Get-SentinelDeclaredFlowDirectory -ToolkitDir $ToolkitDir) -FlowId $flowId
    if (-not (Test-Path -LiteralPath $flowPath)) {
        return $null
    }

    $state = @{
        ProjectNameValue = $ProjectNameValue
        ExecutorTargetValue = $ExecutorTargetValue
        ExtractionMode = $ExtractionMode
        DocumentMode = $DocumentMode
        RouteMode = $RouteMode
        SourceArtifactFileName = $SourceArtifactFileName
        OutputArtifactFileName = $OutputArtifactFileName
        BundleContent = [string]$BundleContent
        Files = @($Files)
        MetaPromptOutputPath = $MetaPromptOutputPath
        MetaPromptContent = $null
        ExtractedSignatureFileCount = 0
    }

    $stepRegistry = New-SentinelDeclaredFlowStepRegistry `
        -SignatureExtractor $SignatureExtractor `
        -MetaPromptBuilder $MetaPromptBuilder `
        -ArtifactWriter $ArtifactWriter

    return Invoke-VibeExecutionFlow `
        -FlowDefinition (Read-VibeExecutionFlowDefinition -FlowPath $flowPath) `
        -StepRegistry $stepRegistry `
        -State $state `
        -LogWriter $LogWriter
}

Export-ModuleMember -Function `
    Resolve-SentinelDeclaredFlowId, `
    Get-SentinelDeclaredFlowDirectory, `
    Invoke-SentinelDeclaredFinalizationFlow
