Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'


$script:SupportedVibeExecutionFallbackActions = @(
    'continue',
    'skip',
    'use_existing'
)

function Test-VibeExecutionFlowIdentifier {
    param([AllowEmptyString()][string]$Value = '')

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }

    return [bool]($Value -match '^[a-z][a-z0-9_]*$')
}

function Assert-VibeExecutionFallbackShape {
    param(
        $Fallback,
        [Parameter(Mandatory = $true)]
        [string]$StepId
    )

    if ($null -eq $Fallback) {
        return
    }

    $descriptor = Get-VibeExecutionFallbackDescriptor -Fallback $Fallback
    if ($null -eq $descriptor) {
        throw "Invalid fallback definition for step '$StepId'."
    }

    $action = [string]$descriptor.action
    if ([string]::IsNullOrWhiteSpace($action)) {
        throw "Invalid fallback definition for step '$StepId': missing 'action'."
    }

    if ($script:SupportedVibeExecutionFallbackActions -notcontains $action.ToLowerInvariant()) {
        throw "Unsupported fallback action '$action' for step '$StepId'. Supported actions: $($script:SupportedVibeExecutionFallbackActions -join ', ')."
    }
}

function Assert-VibeExecutionFlowDefinitionShape {
    param(
        [Parameter(Mandatory = $true)]
        $Definition,
        [Parameter(Mandatory = $true)]
        [string]$FlowPath
    )

    $flowId = [string]$Definition.flow
    if (-not (Test-VibeExecutionFlowIdentifier -Value $flowId)) {
        throw "Flow definition has invalid 'flow' id '$flowId': $FlowPath"
    }

    if (-not $Definition.PSObject.Properties['steps'] -or -not $Definition.steps -or @($Definition.steps).Count -eq 0) {
        throw "Flow definition is missing 'steps': $FlowPath"
    }

    foreach ($inputStep in @($Definition.steps)) {
        $normalizedStep = New-VibeExecutionFlowStepSpec -InputStep $inputStep
        if (-not (Test-VibeExecutionFlowIdentifier -Value ([string]$normalizedStep.stepId))) {
            throw "Flow definition has invalid step id '$([string]$normalizedStep.stepId)': $FlowPath"
        }

        Assert-VibeExecutionFallbackShape -Fallback $normalizedStep.fallback -StepId ([string]$normalizedStep.stepId)
    }
}

function ConvertTo-VibeFlowUtcString {
    param([datetime]$Value = (Get-Date))
    return $Value.ToUniversalTime().ToString('o')
}

function New-VibeExecutionFlowStepSpec {
    param(
        [Parameter(Mandatory = $true)]
        $InputStep
    )

    if ($InputStep -is [string]) {
        return @{
            stepId = $InputStep
            fallback = $null
        }
    }

    if ($InputStep -is [System.Collections.IDictionary]) {
        $stepId = [string]$InputStep['id']
        if ([string]::IsNullOrWhiteSpace($stepId)) {
            throw "Invalid flow step entry: missing 'id'."
        }

        $fallback = $null
        if ($InputStep.Contains('fallback')) {
            $fallback = $InputStep['fallback']
        }

        return @{
            stepId = $stepId
            fallback = $fallback
        }
    }

    if ($InputStep.PSObject -and $InputStep.PSObject.Properties['id']) {
        $stepId = [string]$InputStep.id
        if ([string]::IsNullOrWhiteSpace($stepId)) {
            throw "Invalid flow step entry: missing 'id'."
        }

        $fallback = $null
        if ($InputStep.PSObject.Properties['fallback']) {
            $fallback = $InputStep.fallback
        }

        return @{
            stepId = $stepId
            fallback = $fallback
        }
    }

    throw "Unsupported flow step entry type: $($InputStep.GetType().FullName)"
}

function Resolve-VibeExecutionFlowDefinitionPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        [Parameter(Mandatory = $true)]
        [string]$FlowId
    )

    return Join-Path $BasePath "$FlowId.flow.json"
}

function Read-VibeExecutionFlowDefinition {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FlowPath
    )

    if (-not (Test-Path -LiteralPath $FlowPath)) {
        throw "Flow definition not found: $FlowPath"
    }

    $raw = Get-Content -LiteralPath $FlowPath -Raw -Encoding utf8
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "Flow definition is empty: $FlowPath"
    }

    $parsed = $raw | ConvertFrom-Json -Depth 32
    Assert-VibeExecutionFlowDefinitionShape -Definition $parsed -FlowPath $FlowPath

    $normalizedSteps = @()
    foreach ($step in @($parsed.steps)) {
        $normalizedSteps += (New-VibeExecutionFlowStepSpec -InputStep $step)
    }

    return @{
        flow = [string]$parsed.flow
        description = [string]$parsed.description
        version = [string]$parsed.version
        steps = $normalizedSteps
        sourcePath = $FlowPath
    }
}

function Get-VibeExecutionFallbackDescriptor {
    param($Fallback)

    if ($null -eq $Fallback) {
        return $null
    }

    if ($Fallback -is [string]) {
        return @{
            action = $Fallback
            outputSummary = ''
        }
    }

    if ($Fallback -is [System.Collections.IDictionary]) {
        $action = ''
        $outputSummary = ''
        if ($Fallback.Contains('action')) {
            $action = [string]$Fallback['action']
        }
        if ($Fallback.Contains('outputSummary')) {
            $outputSummary = [string]$Fallback['outputSummary']
        }

        return @{
            action = $action
            outputSummary = $outputSummary
        }
    }

    if ($Fallback.PSObject) {
        $action = ''
        $outputSummary = ''
        if ($Fallback.PSObject.Properties['action']) {
            $action = [string]$Fallback.action
        }
        if ($Fallback.PSObject.Properties['outputSummary']) {
            $outputSummary = [string]$Fallback.outputSummary
        }

        return @{
            action = $action
            outputSummary = $outputSummary
        }
    }

    return @{
        action = [string]$Fallback
        outputSummary = ''
    }
}

function Write-VibeExecutionFlowLog {
    param(
        [scriptblock]$LogWriter,
        [string]$Message
    )

    if ($LogWriter) {
        & $LogWriter $Message
        return
    }

    Write-Host $Message
}

function New-VibeExecutionStepAudit {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepId,
        [Parameter(Mandatory = $true)]
        [string]$Status,
        [Parameter(Mandatory = $true)]
        [datetime]$StartedAt,
        [Parameter(Mandatory = $true)]
        [datetime]$FinishedAt,
        [string]$OutputSummary = '',
        [bool]$FallbackUsed = $false
    )

    return @{
        stepId = $StepId
        status = $Status
        startedAt = ConvertTo-VibeFlowUtcString -Value $StartedAt
        finishedAt = ConvertTo-VibeFlowUtcString -Value $FinishedAt
        durationMs = [int][Math]::Max(0, ($FinishedAt - $StartedAt).TotalMilliseconds)
        outputSummary = [string]$OutputSummary
        fallbackUsed = [bool]$FallbackUsed
    }
}

function Invoke-VibeExecutionFlow {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$FlowDefinition,
        [Parameter(Mandatory = $true)]
        [hashtable]$StepRegistry,
        [Parameter(Mandatory = $true)]
        [hashtable]$State,
        [scriptblock]$LogWriter
    )

    $flowStartedAt = Get-Date
    $stepResults = @()

    Write-VibeExecutionFlowLog -LogWriter $LogWriter -Message ("[sentinel-flow] flow '{0}' started" -f $FlowDefinition.flow)

    foreach ($step in @($FlowDefinition.steps)) {
        $stepId = [string]$step.stepId
        $fallbackDescriptor = Get-VibeExecutionFallbackDescriptor -Fallback $step.fallback
        $stepStartedAt = Get-Date

        if (-not $StepRegistry.ContainsKey($stepId)) {
            throw "Unknown flow step '$stepId' in flow '$($FlowDefinition.flow)'."
        }

        Write-VibeExecutionFlowLog -LogWriter $LogWriter -Message ("[sentinel-flow] step '{0}' running" -f $stepId)

        try {
            $handler = $StepRegistry[$stepId]
            $handlerResult = & $handler $State $step

            $outputSummary = ''
            if ($handlerResult -is [string]) {
                $outputSummary = $handlerResult
            }
            elseif ($handlerResult -is [System.Collections.IDictionary] -and $handlerResult.Contains('outputSummary')) {
                $outputSummary = [string]$handlerResult['outputSummary']
            }
            elseif ($handlerResult -and $handlerResult.PSObject -and $handlerResult.PSObject.Properties['outputSummary']) {
                $outputSummary = [string]$handlerResult.outputSummary
            }

            $stepFinishedAt = Get-Date
            $stepResults += (New-VibeExecutionStepAudit -StepId $stepId -Status 'completed' -StartedAt $stepStartedAt -FinishedAt $stepFinishedAt -OutputSummary $outputSummary -FallbackUsed $false)
            Write-VibeExecutionFlowLog -LogWriter $LogWriter -Message ("[sentinel-flow] step '{0}' completed" -f $stepId)
        }
        catch {
            $stepFinishedAt = Get-Date

            if ($fallbackDescriptor -and -not [string]::IsNullOrWhiteSpace([string]$fallbackDescriptor.action)) {
                $fallbackAction = [string]$fallbackDescriptor.action
                $fallbackSummary = [string]$fallbackDescriptor.outputSummary

                if ([string]::IsNullOrWhiteSpace($fallbackSummary)) {
                    $fallbackSummary = "fallback action '$fallbackAction' after error: $($_.Exception.Message)"
                }

                switch ($fallbackAction.ToLowerInvariant()) {
                    'continue' {
                        $stepResults += (New-VibeExecutionStepAudit -StepId $stepId -Status 'fallback' -StartedAt $stepStartedAt -FinishedAt $stepFinishedAt -OutputSummary $fallbackSummary -FallbackUsed $true)
                        Write-VibeExecutionFlowLog -LogWriter $LogWriter -Message ("[sentinel-flow] step '{0}' fallback=continue" -f $stepId)
                        continue
                    }
                    'skip' {
                        $stepResults += (New-VibeExecutionStepAudit -StepId $stepId -Status 'skipped' -StartedAt $stepStartedAt -FinishedAt $stepFinishedAt -OutputSummary $fallbackSummary -FallbackUsed $true)
                        Write-VibeExecutionFlowLog -LogWriter $LogWriter -Message ("[sentinel-flow] step '{0}' fallback=skip" -f $stepId)
                        continue
                    }
                    'use_existing' {
                        $stepResults += (New-VibeExecutionStepAudit -StepId $stepId -Status 'fallback' -StartedAt $stepStartedAt -FinishedAt $stepFinishedAt -OutputSummary $fallbackSummary -FallbackUsed $true)
                        Write-VibeExecutionFlowLog -LogWriter $LogWriter -Message ("[sentinel-flow] step '{0}' fallback=use_existing" -f $stepId)
                        continue
                    }
                    default {
                        throw "Unsupported fallback action '$fallbackAction' for step '$stepId'."
                    }
                }
            }

            throw
        }
    }

    $flowFinishedAt = Get-Date
    Write-VibeExecutionFlowLog -LogWriter $LogWriter -Message ("[sentinel-flow] flow '{0}' finished" -f $FlowDefinition.flow)

    $fallbackCount = @($stepResults | Where-Object { $_.fallbackUsed }).Count

    return @{
        flowId = [string]$FlowDefinition.flow
        sourcePath = [string]$FlowDefinition.sourcePath
        status = 'completed'
        startedAt = ConvertTo-VibeFlowUtcString -Value $flowStartedAt
        finishedAt = ConvertTo-VibeFlowUtcString -Value $flowFinishedAt
        durationMs = [int][Math]::Max(0, ($flowFinishedAt - $flowStartedAt).TotalMilliseconds)
        fallbackCount = [int]$fallbackCount
        steps = $stepResults
    }
}

Export-ModuleMember -Function `
    ConvertTo-VibeFlowUtcString, `
    Resolve-VibeExecutionFlowDefinitionPath, `
    Read-VibeExecutionFlowDefinition, `
    Invoke-VibeExecutionFlow
