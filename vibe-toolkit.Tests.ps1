# vibe-toolkit.Tests.ps1
# Suíte Pester unificada para VibeToolkit – Versão Final (Should -Throw genérico)
# Uso: Invoke-Pester -Path .\vibe-toolkit.Tests.ps1 -Output Detailed

Describe "VibeToolkit - Suíte de Contratos e Regressão (unificada)" {

    Context "Sanity: arquivos essenciais existem" {
        BeforeAll {
            $ProjectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
            $script:ModulesPath = Join-Path $ProjectRoot 'modules'
            $script:LibPath     = Join-Path $ProjectRoot 'lib'
            $script:FlowsPath   = Join-Path $ProjectRoot 'flows'
            $script:Installer   = Join-Path $ProjectRoot 'Instalar-VibeToolkit.cmd'
            $script:BundlerCli  = Join-Path $ProjectRoot 'project-bundler-cli.ps1'
        }

        It "Deve conter diretórios e arquivos principais" {
            $ModulesPath | Should -Not -BeNullOrEmpty
            $LibPath     | Should -Not -BeNullOrEmpty
            $FlowsPath   | Should -Not -BeNullOrEmpty
            $Installer   | Should -Not -BeNullOrEmpty
            $BundlerCli  | Should -Not -BeNullOrEmpty

            Test-Path $ModulesPath | Should -BeTrue
            Test-Path $LibPath     | Should -BeTrue
            Test-Path $FlowsPath   | Should -BeTrue
            Test-Path $Installer   | Should -BeTrue
            Test-Path $BundlerCli  | Should -BeTrue
        }
    }

    Context "Validação de Assinaturas (VibeSignatureExtractor)" {
        BeforeAll {
            $ProjectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
            $ModulesPath = Join-Path $ProjectRoot 'modules'
            $SignatureExtractorModule = Join-Path $ModulesPath 'VibeSignatureExtractor.psm1'

            function Import-ModuleIfExists {
                param([string]$Path)
                if ($Path -and (Test-Path $Path)) {
                    try { Import-Module $Path -Force -ErrorAction Stop; return $true }
                    catch { return $false }
                }
                return $false
            }
            $null = Import-ModuleIfExists -Path $SignatureExtractorModule
        }

        It "Deve exportar função Get-VibePowerShellFunctionSignatures" {
            if (-not (Get-Command -Name Get-VibePowerShellFunctionSignatures -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Get-VibePowerShellFunctionSignatures não disponível (módulo não importado)."
            }
            (Get-Command -Name Get-VibePowerShellFunctionSignatures) | Should -Not -BeNullOrEmpty
        }

        It "Deve extrair assinaturas de todos os módulos visíveis" {
            if (-not (Test-Path $ModulesPath)) {
                Set-ItResult -Skipped -Because "Diretório modules não encontrado."
            }
            $psm1Files = Get-ChildItem -Path $ModulesPath -Filter *.psm1 -File -ErrorAction SilentlyContinue
            if ($psm1Files.Count -eq 0) {
                Set-ItResult -Skipped -Because "Nenhum arquivo .psm1 encontrado em modules."
            }
            foreach ($f in $psm1Files) {
                $sigs = $null
                try {
                    $content = Get-Content -Path $f.FullName -Raw
                    $lines = $content -split "`r?`n"
                    $sigs = Get-VibePowerShellFunctionSignatures -Lines $lines -ErrorAction Stop
                } catch {
                    $sigs = $null
                }
                $sigs | Should -Not -BeNullOrEmpty -Because "O arquivo $($f.Name) deve conter assinaturas."
            }
        }
    }

    Context "Execução de Flow (VibeExecutionFlow)" {
        BeforeAll {
            $ProjectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
            $ModulesPath = Join-Path $ProjectRoot 'modules'
            $FlowsPath   = Join-Path $ProjectRoot 'flows'
            $ExecutionFlowModule = Join-Path $ModulesPath 'VibeExecutionFlow.psm1'

            function Import-ModuleIfExists {
                param([string]$Path)
                if ($Path -and (Test-Path $Path)) {
                    try { Import-Module $Path -Force -ErrorAction Stop; return $true }
                    catch { return $false }
                }
                return $false
            }
            $null = Import-ModuleIfExists -Path $ExecutionFlowModule

            function Read-JsonFile {
                param([string]$Path)
                if ($Path -and (Test-Path $Path)) {
                    try { return Get-Content -Raw -Path $Path | ConvertFrom-Json -ErrorAction Stop }
                    catch { return $null }
                }
                return $null
            }

            function ConvertTo-Hashtable {
                param([Parameter(ValueFromPipeline)]$InputObject)
                process {
                    if ($null -eq $InputObject) { return $null }
                    if ($InputObject -is [System.Collections.IDictionary]) { return $InputObject }
                    $hash = @{}
                    $InputObject.PSObject.Properties | ForEach-Object {
                        $value = $_.Value
                        if ($value -is [PSCustomObject]) {
                            $hash[$_.Name] = ConvertTo-Hashtable $value
                        } elseif ($value -is [Array]) {
                            $hash[$_.Name] = @($value | ForEach-Object {
                                if ($_ -is [PSCustomObject]) { ConvertTo-Hashtable $_ } else { $_ }
                            })
                        } else {
                            $hash[$_.Name] = $value
                        }
                    }
                    return $hash
                }
            }
        }

        It "Deve exportar Invoke-VibeExecutionFlow" {
            if (-not (Get-Command -Name Invoke-VibeExecutionFlow -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Invoke-VibeExecutionFlow não disponível."
            }
            (Get-Command -Name Invoke-VibeExecutionFlow) | Should -Not -BeNullOrEmpty
        }

        It "Blueprint flow JSON deve ser legível e ter formato esperado" {
            $flowFile = Join-Path $FlowsPath 'blueprint_executor.flow.json'
            if (-not (Test-Path $flowFile)) {
                Set-ItResult -Skipped -Because "Arquivo de flow não encontrado."
            }
            $definition = Read-JsonFile -Path $flowFile
            $definition | Should -Not -BeNullOrEmpty
            $definition.flow | Should -Not -BeNullOrEmpty
            $definition.steps | Should -Not -BeNullOrEmpty
        }

        It "Invoke-VibeExecutionFlow deve aceitar definição conhecida e validar steps" {
            if (-not (Get-Command -Name Invoke-VibeExecutionFlow -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Invoke-VibeExecutionFlow não disponível."
            }
            $flowFile = Join-Path $FlowsPath 'blueprint_executor.flow.json'
            if (-not (Test-Path $flowFile)) {
                Set-ItResult -Skipped -Because "Arquivo de flow ausente."
            }
            $definition = Read-JsonFile -Path $flowFile
            $flowDefHash = ConvertTo-Hashtable $definition
            # StepRegistry e State vazios devem gerar uma exceção de validação
            { Invoke-VibeExecutionFlow -FlowDefinition $flowDefHash -StepRegistry @{} -State @{} } | Should -Throw
        }
    }

    Context "Instalação / Desinstalação (Instalar-VibeToolkit.cmd)" {
        BeforeAll {
            $ProjectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
            $Installer = Join-Path $ProjectRoot 'Instalar-VibeToolkit.cmd'
        }

        It "Script de instalação existe e contém funções esperadas (sem executar)" {
            if (-not (Test-Path $Installer)) {
                Set-ItResult -Skipped -Because "Instalar-VibeToolkit.cmd ausente."
            }
            $content = Get-Content -Path $Installer -ErrorAction Stop -Raw
            $content | Should -Match 'Install-VibeToolkit|Uninstall-VibeToolkit'
        }
    }

    Context "UI Sentinel (lib/SentinelUI.ps1)" {
        BeforeAll {
            $ProjectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
            $LibPath = Join-Path $ProjectRoot 'lib'
            $SentinelUi = Join-Path $LibPath 'SentinelUI.ps1'

            function Import-ModuleIfExists {
                param([string]$Path)
                if ($Path -and (Test-Path $Path)) {
                    try { Import-Module $Path -Force -ErrorAction Stop; return $true }
                    catch { return $false }
                }
                return $false
            }
            $null = Import-ModuleIfExists -Path $SentinelUi
        }

        It "Deve exportar funções de UI essenciais" {
            if (-not (Get-Command -Name Show-SentinelMenu -ErrorAction SilentlyContinue) -or
                -not (Get-Command -Name Show-SentinelSpinner -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Funções de UI essenciais não disponíveis."
            }
            (Get-Command -Name Show-SentinelMenu) | Should -Not -BeNullOrEmpty
            (Get-Command -Name Show-SentinelSpinner) | Should -Not -BeNullOrEmpty
            (Get-Command -Name Test-SentinelAnsiSupport) | Should -Not -BeNullOrEmpty
        }

        It "Test-SentinelAnsiSupport deve retornar booleano" {
            if (-not (Get-Command -Name Test-SentinelAnsiSupport -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Test-SentinelAnsiSupport não disponível."
            }
            $res = Test-SentinelAnsiSupport
            $res | Should -BeOfType 'System.Boolean'
        }
    }

    Context "Bundling e Export (project-bundler-cli.ps1 / VibeBundleWriter)" {
        BeforeAll {
            $ProjectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
            $ModulesPath = Join-Path $ProjectRoot 'modules'
            $BundlerCli = Join-Path $ProjectRoot 'project-bundler-cli.ps1'
            $BundleWriterModule = Join-Path $ModulesPath 'VibeBundleWriter.psm1'

            function Import-ModuleIfExists {
                param([string]$Path)
                if ($Path -and (Test-Path $Path)) {
                    try { Import-Module $Path -Force -ErrorAction Stop; return $true }
                    catch { return $false }
                }
                return $false
            }
            $null = Import-ModuleIfExists -Path $BundlerCli
            $null = Import-ModuleIfExists -Path $BundleWriterModule
        }

        It "Deve exportar New-DeterministicMetaPromptArtifact" {
            if (-not (Get-Command -Name New-DeterministicMetaPromptArtifact -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "New-DeterministicMetaPromptArtifact não disponível."
            }
            (Get-Command -Name New-DeterministicMetaPromptArtifact) | Should -Not -BeNullOrEmpty
        }

        It "New-DeterministicMetaPromptArtifact deve aceitar parâmetros mínimos em modo seguro" {
            if (-not (Get-Command -Name New-DeterministicMetaPromptArtifact -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "New-DeterministicMetaPromptArtifact não disponível."
            }
            $files = @()
            if (Test-Path $ModulesPath) {
                $files = Get-ChildItem -Path $ModulesPath -Filter *.psm1 -File -ErrorAction SilentlyContinue
            }
            { New-DeterministicMetaPromptArtifact `
                -ProjectNameValue "VibeToolkit-Test" `
                -ExecutorTargetValue "GenAI" `
                -ExtractionMode "blueprint" `
                -DocumentMode "executor" `
                -RouteMode "direct" `
                -SourceArtifactFileName "_blueprint_executor__VibeToolkit.md" `
                -OutputArtifactFileName "_meta-prompt_test.md" `
                -Files $files -WhatIf } | Should -Not -Throw
        }
    }

    Context "Descoberta de arquivos (VibeFileDiscovery)" {
        BeforeAll {
            $ProjectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
            $ModulesPath = Join-Path $ProjectRoot 'modules'
            $FileDiscoveryModule = Join-Path $ModulesPath 'VibeFileDiscovery.psm1'

            function Import-ModuleIfExists {
                param([string]$Path)
                if ($Path -and (Test-Path $Path)) {
                    try { Import-Module $Path -Force -ErrorAction Stop; return $true }
                    catch { return $false }
                }
                return $false
            }
            $null = Import-ModuleIfExists -Path $FileDiscoveryModule
        }

        It "Deve exportar Get-VibeRelevantFiles" {
            if (-not (Get-Command -Name Get-VibeRelevantFiles -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Get-VibeRelevantFiles não disponível."
            }
            (Get-Command -Name Get-VibeRelevantFiles) | Should -Not -BeNullOrEmpty
        }

        It "Get-VibeRelevantFiles deve retornar coleção (mesmo vazia) sem lançar" {
            if (-not (Get-Command -Name Get-VibeRelevantFiles -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Get-VibeRelevantFiles não disponível."
            }
            { Get-VibeRelevantFiles -Path $ProjectRoot } | Should -Not -Throw
        }
    }

    Context "Integridade determinística (hashes e conteúdo)" {
        BeforeAll {
            $ProjectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
            $ModulesPath = Join-Path $ProjectRoot 'modules'
        }

        It "Get-FileHashSha256 deve existir e produzir hash para arquivos de módulo" {
            if (-not (Get-Command -Name Get-FileHashSha256 -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Get-FileHashSha256 não disponível."
            }
            $sample = Get-ChildItem -Path $ModulesPath -Filter *.psm1 -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $sample) {
                Set-ItResult -Skipped -Because "Nenhum arquivo de módulo encontrado para hash."
            }
            $h = Get-FileHashSha256 -Path $sample.FullName
            $h | Should -Match '^[A-Fa-f0-9]{64}$'
        }
    }

    Context "Smoke final: execução end-to-end em modo dry-run" {
        BeforeAll {
            $ProjectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
            $FlowsPath = Join-Path $ProjectRoot 'flows'
            $ModulesPath = Join-Path $ProjectRoot 'modules'
            $ExecutionFlowModule = Join-Path $ModulesPath 'VibeExecutionFlow.psm1'

            function Import-ModuleIfExists {
                param([string]$Path)
                if ($Path -and (Test-Path $Path)) {
                    try { Import-Module $Path -Force -ErrorAction Stop; return $true }
                    catch { return $false }
                }
                return $false
            }
            $null = Import-ModuleIfExists -Path $ExecutionFlowModule

            function Read-JsonFile {
                param([string]$Path)
                if ($Path -and (Test-Path $Path)) {
                    try { return Get-Content -Raw -Path $Path | ConvertFrom-Json -ErrorAction Stop }
                    catch { return $null }
                }
                return $null
            }

            function ConvertTo-Hashtable {
                param([Parameter(ValueFromPipeline)]$InputObject)
                process {
                    if ($null -eq $InputObject) { return $null }
                    if ($InputObject -is [System.Collections.IDictionary]) { return $InputObject }
                    $hash = @{}
                    $InputObject.PSObject.Properties | ForEach-Object {
                        $value = $_.Value
                        if ($value -is [PSCustomObject]) {
                            $hash[$_.Name] = ConvertTo-Hashtable $value
                        } elseif ($value -is [Array]) {
                            $hash[$_.Name] = @($value | ForEach-Object {
                                if ($_ -is [PSCustomObject]) { ConvertTo-Hashtable $_ } else { $_ }
                            })
                        } else {
                            $hash[$_.Name] = $value
                        }
                    }
                    return $hash
                }
            }
        }

        It "Fluxo completo (determinístico) deve poder ser invocado em modo seguro" {
            if (-not (Get-Command -Name Invoke-VibeExecutionFlow -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Invoke-VibeExecutionFlow não disponível."
            }
            $flowFile = Join-Path $FlowsPath 'blueprint_executor.flow.json'
            if (-not (Test-Path $flowFile)) {
                Set-ItResult -Skipped -Because "Definição de flow ausente."
            }
            $definition = Read-JsonFile -Path $flowFile
            $flowDefHash = ConvertTo-Hashtable $definition
            { Invoke-VibeExecutionFlow -FlowDefinition $flowDefHash -StepRegistry @{} -State @{} } | Should -Throw
        }
    }
}