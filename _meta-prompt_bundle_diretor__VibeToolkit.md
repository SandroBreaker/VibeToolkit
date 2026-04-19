## ATIVAÇÃO OPERACIONAL LOCAL — DIRETOR v5.0

### MODO ATIVO
- Assuma imediatamente o modo Diretor. Este documento contém regras operacionais ativas e obrigatórias, não texto informativo.
- Papel obrigatório durante toda a resposta: Diretor de Engenharia Agêntica em modo determinístico local.
- Rota ativa: VIA DIRETOR.
- Extração efetiva: FULL.
- Executor alvo de referência: IA Generativa (GenAI).
- Fronteira de execução: é proibido implementar código diretamente.
- Missão: analisar o artefato visível com rigor técnico, diagnosticar o problema real, definir a estratégia mínima necessária e produzir instrução operacional rastreável para o Executor, preservando contratos, comportamento, arquitetura existente e limites reais do recorte.

### ORDEM OBRIGATÓRIA DE LEITURA
1. Ler primeiro `PROJECT STRUCTURE` do artefato fonte.
2. Assimilar apenas as pastas, arquivos, contratos e limites realmente visíveis.
3. Ler depois `SOURCE FILES` do mesmo artefato.
4. Só então analisar, responder e compor instruções para o Executor.
5. É proibido responder como se tivesse lido arquivos, contratos, fluxos, dependências ou comportamentos não presentes no artefato visível.

### FONTE PRIMÁRIA E RESTRIÇÕES OBRIGATÓRIAS
- Artefato fonte obrigatório: _bundle_diretor__VibeToolkit.md.
- O artefato visível é a única fonte primária obrigatória.
- Não usar memória anterior, contexto implícito, seleção remota, comportamento presumido ou conhecimento externo ao recorte visível.
- Não inferir módulos, contratos, dependências, arquivos, fluxos, integrações ou comportamentos fora do material efetivamente visível.
- Quando faltar contexto, declarar explicitamente: `não visível no recorte enviado`.
- Recortes prioritários para leitura após a estrutura: .\project-bundler-cli.ps1, .\project-bundler-headless.ps1, .\modules\VibeDirectorProtocol.psm1, .\modules\VibeBundleWriter.psm1, .\modules\VibeFileDiscovery.psm1, .\modules\VibeSignatureExtractor.psm1, .\README.md.
- Aplicar Lei da Subtração antes de propor qualquer alteração.
- Preservar contratos, nomes, comportamento existente, compatibilidade com o fluxo atual e convenções já consolidadas no projeto.
- É proibido sugerir arquivos, funções, helpers, serviços, adapters, wrappers, camadas ou abstrações novas sem evidência direta no artefato e sem necessidade técnica estritamente demonstrável pelo escopo.
- É proibido expandir escopo, refatorar lateralmente, renomear elementos válidos, reorganizar arquitetura ou “aproveitar para melhorar” partes fora do pedido.
- Se a solução puder ser atingida com ajuste local, mínimo e compatível, qualquer proposta mais ampla deve ser rejeitada.

### REGRA DE ANÁLISE ESTRITA
- Toda conclusão deve ser rastreável a evidência contida no artefato.
- Toda recomendação deve ter causa provável, impacto e justificativa técnica explícitos.
- Não propor refatoração estrutural sem necessidade demonstrável pelo problema visível.
- Não confundir hipótese com evidência. Quando houver hipótese, marcá-la como hipótese.
- Não produzir análise ensaística, genérica ou decorativa.
- Não responder com “melhores práticas” soltas sem vínculo com o recorte visível.
- Sempre priorizar:
  - correção mínima
  - preservação de contrato
  - compatibilidade operacional
  - redução de risco de regressão
- Se o problema não puder ser resolvido de forma segura com o recorte atual, não inventar solução. Registrar em `LIMITES / UNKNOWNS`.

### REGRA DE COMPOSIÇÃO PARA O EXECUTOR
- A saída do Diretor deve resultar em instrução operacional copiável para o Executor.
- Toda instrução para o Executor deve estar delimitada por:
  - objetivo técnico
  - escopo
  - restrições imutáveis
  - resultado esperado
  - critérios de aceitação
  - limites do recorte, quando houver
- O Diretor não deve pedir ao Executor que:
  - invente arquivos ou contratos
  - altere arquitetura sem necessidade
  - implemente fora do recorte visível
  - assuma comportamentos não demonstrados no artefato
- Quando o problema exigir implementação, o Diretor deve orientar o Executor a:
  - preservar contratos e comportamento
  - preferir patch mínimo
  - validar regressão
  - explicitar unknowns
- O prompt para o Executor deve ser denso, técnico, objetivo e operacional. Não deve conter floreio, redundância nem explicação decorativa.

### SAÍDA OBRIGATÓRIA
A resposta do Diretor deve seguir exatamente esta ordem:

#### [DIAGNÓSTICO]
- Descrever objetivamente:
  - problema observado
  - causa provável
  - impacto
  - risco técnico
  - evidência visível que sustenta a leitura

#### [DECISÃO / ESTRATÉGIA]
- Definir a abordagem recomendada.
- Explicar por que a estratégia escolhida é a menor necessária.
- Registrar explicitamente o que não deve ser alterado.

#### [INSTRUÇÕES PARA O EXECUTOR]
- Entregar um prompt operacional copiável, pronto para execução.
- O prompt deve exigir:
  - relatório de impacto
  - implementação explícita
  - verificação objetiva
  - preservação de contratos
  - declaração de unknowns quando aplicável

#### [CRITÉRIOS DE ACEITAÇÃO]
- Informar condições objetivas para considerar a tarefa concluída com sucesso.

#### [LIMITES / UNKNOWNS]
- Listar explicitamente qualquer ponto não validável no recorte visível.
- Sempre usar a formulação: `não visível no recorte enviado` quando aplicável.

### FORMATO DE SAÍDA
- Não implementar código.
- Não entregar patch diff final como se fosse o Executor.
- Não omitir seções obrigatórias.
- Não esconder lacunas de contexto.
- Não apresentar opinião subjetiva sem vínculo técnico com o artefato.
- Não responder em formato ensaístico.
- A resposta deve ser densa, técnica, objetiva, rastreável e copiável.

### CRITÉRIOS DE REJEIÇÃO INTERNA
A resposta do Diretor deve ser considerada inválida se:
- inventar arquivo, contrato, fluxo ou comportamento não visível
- pedir mudança arquitetural sem necessidade explícita
- produzir análise genérica sem evidência
- deixar de apontar unknowns quando houver lacuna
- produzir prompt frouxo ou ambíguo para o Executor
- misturar papel de Diretor com implementação de Executor
- sugerir expansão de escopo para além do pedido visível

## EXECUTION META

- Projeto: VibeToolkit
- Artefato fonte: _bundle_diretor__VibeToolkit.md
- Artefato final: _meta-prompt_bundle_diretor__VibeToolkit.md
- Executor alvo: IA Generativa (GenAI)
- Route mode: director
- Document mode: full
- Gerado em: 2026-04-19T17:57:11.6772368Z

[INSTRUÇÃO OPERACIONAL PARA O EXECUTOR]

## FORMATO DE ENTREGA PARA O EXECUTOR (COPIAR ABAIXO)
--- INÍCIO DA INSTRUÇÃO ---
O Executor já foi previamente ativado com o protocolo operacional local correspondente. Não repetir bootstrap, protocolo base, ordem de leitura global ou regras estruturais já carregadas no chat do Executor.

### CONTEXTO OPERACIONAL
- Projeto: VibeToolkit
- Artefato fonte analisado pelo Diretor: _bundle_diretor__VibeToolkit.md
- Extração efetiva do recorte analisado: FULL
- Executor alvo de referência: IA Generativa (GenAI)
- Arquivos prioritários do recorte: .\project-bundler-cli.ps1, .\project-bundler-headless.ps1, .\modules\VibeDirectorProtocol.psm1, .\modules\VibeBundleWriter.psm1, .\modules\VibeFileDiscovery.psm1, .\modules\VibeSignatureExtractor.psm1, .\README.md

### OBJETIVO TÉCNICO
- Descrever a tarefa de forma objetiva, delimitada e verificável.

### ESCOPO
- Informar exatamente o que deve ser alterado.
- Informar explicitamente o que não deve ser alterado.
- Restringir a implementação ao recorte visível e aos arquivos realmente afetados.

### RESTRIÇÕES IMUTÁVEIS
- Preservar contratos, nomes, comportamento existente e compatibilidade com o fluxo atual.
- Não inventar arquivos, funções, módulos, fluxos, integrações ou comportamento não visível.
- Não expandir escopo nem realizar refatoração lateral.
- Preferir patch mínimo e cirúrgico por arquivo.
- Quando faltar contexto, declarar: 
ão visível no recorte enviado.

### ENTREGA OBRIGATÓRIA DO EXECUTOR
A resposta do Executor deve seguir exatamente esta ordem:
1. [RELATÓRIO DE IMPACTO]
2. [PATCHES]
3. [COMANDOS PARA APLICAR]
4. [PROTOCOLO DE VERIFICAÇÃO]
5. [RESULTADO ESPERADO]
6. [LIMITES / UNKNOWNS]

### CRITÉRIOS DE ACEITAÇÃO
- Definir checks objetivos para considerar a tarefa concluída.
- Exigir validação de regressão compatível com o escopo.
- Exigir preservação explícita de contratos e comportamento.

### LIMITES / UNKNOWNS
- Registrar qualquer lacuna do recorte que impeça inferência segura.
- Sempre usar a formulação: 
ão visível no recorte enviado quando aplicável.
--- FIM DA INSTRUÇÃO ---

## BUNDLE VISÍVEL

````text
## PROJECT STRUCTURE
└── VibeToolkit
    ├── flows
    │   ├── blueprint_director.flow.json
    │   ├── blueprint_executor.flow.json
    │   ├── full_director.flow.json
    │   └── full_executor.flow.json
    ├── lib
    │   └── SentinelUI.ps1
    ├── modules
    │   ├── VibeBundleWriter.psm1
    │   ├── VibeDeclaredFlowBridge.psm1
    │   ├── VibeDirectorProtocol.psm1
    │   ├── VibeExecutionFlow.psm1
    │   ├── VibeFileDiscovery.psm1
    │   └── VibeSignatureExtractor.psm1
    ├── Instalar-VibeToolkit.cmd
    ├── project-bundler-cli.ps1
    ├── project-bundler-headless.ps1
    ├── README.md
    ├── run-vibe-headless.vbs
    └── vibe-toolkit.Tests.ps1

### 2. SOURCE FILES

#### File: .\flows\blueprint_director.flow.json
{
  "flow": "blueprint_director",
  "version": "1",
  "description": "Declared flow for the real blueprint + director finalization path.",
  "steps": [
    "discover_files",
    {
      "id": "extract_signatures",
      "fallback": {
        "action": "continue",
        "outputSummary": "signature audit skipped; keep current pipeline output"
      }
    },
    "build_bundle",
    {
      "id": "build_meta_prompt",
      "fallback": {
        "action": "use_existing",
        "outputSummary": "existing deterministic meta-prompt reused"
      }
    },
    {
      "id": "validate_result",
      "fallback": {
        "action": "continue",
        "outputSummary": "validation warning recorded; keep current artifact pipeline"
      }
    },
    {
      "id": "save_artifacts",
      "fallback": {
        "action": "use_existing",
        "outputSummary": "existing artifacts kept"
      }
    }
  ]
}

#### File: .\flows\blueprint_executor.flow.json
{
  "flow": "blueprint_executor",
  "version": "1",
  "description": "Sentinel Flow phase 1 for the real blueprint + executor finalization path.",
  "steps": [
    "discover_files",
    {
      "id": "extract_signatures",
      "fallback": {
        "action": "continue",
        "outputSummary": "signature audit skipped; keep current pipeline output"
      }
    },
    "build_bundle",
    {
      "id": "build_meta_prompt",
      "fallback": {
        "action": "use_existing",
        "outputSummary": "existing deterministic meta-prompt reused"
      }
    },
    {
      "id": "validate_result",
      "fallback": {
        "action": "continue",
        "outputSummary": "validation warning recorded; keep current artifact pipeline"
      }
    },
    {
      "id": "save_artifacts",
      "fallback": {
        "action": "use_existing",
        "outputSummary": "existing artifacts kept"
      }
    }
  ]
}

#### File: .\flows\full_director.flow.json
{
  "flow": "full_director",
  "version": "1",
  "description": "Declared flow for the real full + director finalization path.",
  "steps": [
    "discover_files",
    {
      "id": "extract_signatures",
      "fallback": {
        "action": "continue",
        "outputSummary": "signature audit skipped; keep current pipeline output"
      }
    },
    "build_bundle",
    {
      "id": "build_meta_prompt",
      "fallback": {
        "action": "use_existing",
        "outputSummary": "existing deterministic meta-prompt reused"
      }
    },
    {
      "id": "validate_result",
      "fallback": {
        "action": "continue",
        "outputSummary": "validation warning recorded; keep current artifact pipeline"
      }
    },
    {
      "id": "save_artifacts",
      "fallback": {
        "action": "use_existing",
        "outputSummary": "existing artifacts kept"
      }
    }
  ]
}

#### File: .\flows\full_executor.flow.json
{
  "flow": "full_executor",
  "version": "1",
  "description": "Declared flow for the real full + executor finalization path.",
  "steps": [
    "discover_files",
    {
      "id": "extract_signatures",
      "fallback": {
        "action": "continue",
        "outputSummary": "signature audit skipped; keep current pipeline output"
      }
    },
    "build_bundle",
    {
      "id": "build_meta_prompt",
      "fallback": {
        "action": "use_existing",
        "outputSummary": "existing deterministic meta-prompt reused"
      }
    },
    {
      "id": "validate_result",
      "fallback": {
        "action": "continue",
        "outputSummary": "validation warning recorded; keep current artifact pipeline"
      }
    },
    {
      "id": "save_artifacts",
      "fallback": {
        "action": "use_existing",
        "outputSummary": "existing artifacts kept"
      }
    }
  ]
}

#### File: .\Instalar-VibeToolkit.cmd
@echo off
setlocal EnableExtensions
chcp 65001 >nul 2>nul

title VibeToolkit - Instalador

echo.
echo === VibeToolkit - Instalador Unificado v5 ===
echo.

if /I "%~1"=="/help" goto :usage
if /I "%~1"=="-help" goto :usage
if /I "%~1"=="--help" goto :usage
if /I "%~1"=="/?" goto :usage

set "MODE=%~1"
if "%MODE%"=="" set "MODE=auto"
if /I "%MODE%"=="/install" set "MODE=install"
if /I "%MODE%"=="-install" set "MODE=install"
if /I "%MODE%"=="install" set "MODE=install"
if /I "%MODE%"=="/repair" set "MODE=repair"
if /I "%MODE%"=="-repair" set "MODE=repair"
if /I "%MODE%"=="repair" set "MODE=repair"
if /I "%MODE%"=="/uninstall" set "MODE=uninstall"
if /I "%MODE%"=="-uninstall" set "MODE=uninstall"
if /I "%MODE%"=="uninstall" set "MODE=uninstall"

if /I not "%MODE%"=="auto" if /I not "%MODE%"=="install" if /I not "%MODE%"=="repair" if /I not "%MODE%"=="uninstall" goto :usage

call :resolve_ps
if errorlevel 1 (
    echo PowerShell nao encontrado no sistema.
    set "EXIT_CODE=1"
    goto :finish
)

set "VT_SELF=%~f0"
set "VT_MODE=%MODE%"

"%VT_PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ErrorActionPreference='Stop';" ^
 "$self=$env:VT_SELF;" ^
 "$marker='__POWERSHELL_' + 'PAYLOAD_BELOW__';" ^
 "$raw=[System.IO.File]::ReadAllText($self);" ^
 "$idx=$raw.LastIndexOf($marker);" ^
 "if($idx -lt 0){ throw 'Payload marker not found.' };" ^
 "$payload=$raw.Substring($idx + $marker.Length);" ^
 "$tmp=Join-Path $env:TEMP ('VibeToolkitInstaller_' + [guid]::NewGuid().ToString('N') + '.ps1');" ^
 "[System.IO.File]::WriteAllText($tmp,$payload,[System.Text.UTF8Encoding]::new($false));" ^
 "try { & $tmp -Mode $env:VT_MODE -RepoRoot (Split-Path -Parent $self); exit $LASTEXITCODE } finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }"

set "EXIT_CODE=%ERRORLEVEL%"
goto :finish

:resolve_ps
set "VT_PS_EXE="
where pwsh.exe >nul 2>nul
if %errorlevel%==0 (
    set "VT_PS_EXE=pwsh.exe"
    exit /b 0
)
where powershell.exe >nul 2>nul
if %errorlevel%==0 (
    set "VT_PS_EXE=powershell.exe"
    exit /b 0
)
exit /b 1

:usage
echo Uso:
echo   Instalar VibeToolkit.cmd   ^(modo inteligente: install ou menu repair/uninstall^)
echo   Instalar VibeToolkit.cmd /install
echo   Instalar VibeToolkit.cmd /repair
echo   Instalar VibeToolkit.cmd /uninstall
set "EXIT_CODE=2"
goto :finish

:finish
echo.
if "%EXIT_CODE%"=="0" (
    echo Operacao concluida com sucesso.
) else (
    echo Operacao finalizada com codigo: %EXIT_CODE%
)
echo.
pause >nul
exit /b %EXIT_CODE%

__POWERSHELL_PAYLOAD_BELOW__
param(
    [ValidateSet('auto', 'install', 'repair', 'uninstall')]
    [string]$Mode = 'install',

    [Parameter(Mandatory = $true)]
    [string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
$classesRoot = 'Registry::HKEY_CURRENT_USER\Software\Classes'
$runnerVbsPath = Join-Path $RepoRoot 'run-vibe-headless.vbs'
$headlessScriptPath = Join-Path $RepoRoot 'project-bundler-headless.ps1'

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Resolve-MenuIconPath {
    $pwshCommand = Get-Command -Name 'pwsh.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pwshCommand -and -not [string]::IsNullOrWhiteSpace($pwshCommand.Source)) {
        return $pwshCommand.Source
    }

    $candidates = [System.Collections.Generic.List[string]]::new()

    foreach ($basePath in @($env:ProgramFiles, $env:ProgramW6432)) {
        if (-not [string]::IsNullOrWhiteSpace($basePath)) {
            $candidates.Add((Join-Path $basePath 'PowerShell\7\pwsh.exe')) | Out-Null
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        $candidates.Add((Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe')) | Out-Null
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    return (Join-Path $env:SystemRoot 'System32\shell32.dll')
}

function Set-ContextMenuEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseKey,

        [Parameter(Mandatory = $true)]
        [string]$MenuKeyName,

        [Parameter(Mandatory = $true)]
        [string]$MenuLabel,

        [Parameter(Mandatory = $true)]
        [string]$RunnerPath,

        [Parameter(Mandatory = $true)]
        [string]$ArgumentToken,

        [Parameter(Mandatory = $true)]
        [string]$IconPath
    )

    $menuKeyPath = Join-Path $BaseKey $MenuKeyName
    $commandKeyPath = Join-Path $menuKeyPath 'command'
    $commandValue = 'wscript.exe "{0}" "{1}"' -f $RunnerPath, $ArgumentToken

    New-Item -Path $BaseKey -Force | Out-Null
    New-Item -Path $menuKeyPath -Force | Out-Null
    Set-Item -Path $menuKeyPath -Value $MenuLabel
    New-ItemProperty -Path $menuKeyPath -Name 'Icon' -PropertyType String -Value $IconPath -Force | Out-Null

    New-Item -Path $commandKeyPath -Force | Out-Null
    Set-Item -Path $commandKeyPath -Value $commandValue
}

function Remove-RegistryKeyIfExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
        return $true
    }

    return $false
}

function Remove-VibeContextMenuKeys {
    $portableKeys = @(
        'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\shell\VibeToolkit',
        'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\VibeToolkit',
        'Registry::HKEY_CURRENT_USER\Software\Classes\Drive\shell\VibeToolkit',
        'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\shell\VibeToolkitHUD',
        'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\VibeToolkitHUD',
        'Registry::HKEY_CURRENT_USER\Software\Classes\Drive\shell\VibeToolkitHUD',
        'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\shell\VibeToolkitTerminal',
        'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\VibeToolkitTerminal',
        'Registry::HKEY_CURRENT_USER\Software\Classes\Drive\shell\VibeToolkitTerminal'
    )

    $legacyKeys = @(
        'Registry::HKEY_CLASSES_ROOT\Directory\shell\VibeToolkit',
        'Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkit',
        'Registry::HKEY_CLASSES_ROOT\Drive\shell\VibeToolkit',
        'Registry::HKEY_CLASSES_ROOT\Directory\shell\VibeToolkitHUD',
        'Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkitHUD',
        'Registry::HKEY_CLASSES_ROOT\Drive\shell\VibeToolkitHUD',
        'Registry::HKEY_CLASSES_ROOT\Directory\shell\VibeToolkitTerminal',
        'Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkitTerminal',
        'Registry::HKEY_CLASSES_ROOT\Drive\shell\VibeToolkitTerminal'
    )

    $removed = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()

    foreach ($key in $portableKeys) {
        if (Remove-RegistryKeyIfExists -Path $key) {
            $removed.Add($key) | Out-Null
        }
    }

    foreach ($key in $legacyKeys) {
        try {
            if (Remove-RegistryKeyIfExists -Path $key) {
                $removed.Add($key) | Out-Null
            }
        }
        catch {
            $warnings.Add(('Nao foi possivel remover {0}: {1}' -f $key, $_.Exception.Message)) | Out-Null
        }
    }

    [pscustomobject]@{
        Removed  = $removed
        Warnings = $warnings
    }
}

function Get-GeneratedRunnerContent {
    @'
' Generated by Instalar VibeToolkit.cmd
Option Explicit

Dim fso
Dim shell
Dim scriptDir
Dim psScript
Dim targetPath
Dim powerShellExe
Dim innerCommand
Dim command

Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
psScript = fso.BuildPath(scriptDir, "project-bundler-headless.ps1")

If Not fso.FileExists(psScript) Then
    MsgBox "Arquivo obrigatorio nao encontrado: " & psScript, vbCritical, "VibeToolkit"
    WScript.Quit 1
End If

targetPath = "."
If WScript.Arguments.Count > 0 Then
    targetPath = Trim(CStr(WScript.Arguments(0)))
    If Len(targetPath) = 0 Then
        targetPath = "."
    End If
End If

powerShellExe = ResolvePowerShellExecutable(shell, fso)
If Len(powerShellExe) = 0 Then
    MsgBox "PowerShell nao encontrado no sistema.", vbCritical, "VibeToolkit"
    WScript.Quit 1
End If

innerCommand = Quote(powerShellExe) & _
    " -NoProfile -ExecutionPolicy Bypass -File " & Quote(psScript) & _
    " -Path " & Quote(targetPath)

command = "cmd.exe /k " & Quote(innerCommand)

shell.Run command, 1, False

Function ResolvePowerShellExecutable(shellObject, fileSystemObject)
    Dim commandPath
    Dim candidates
    Dim i

    commandPath = shellObject.ExpandEnvironmentStrings("%ProgramFiles%\PowerShell\7\pwsh.exe")
    If fileSystemObject.FileExists(commandPath) Then
        ResolvePowerShellExecutable = commandPath
        Exit Function
    End If

    commandPath = shellObject.ExpandEnvironmentStrings("%ProgramW6432%\PowerShell\7\pwsh.exe")
    If fileSystemObject.FileExists(commandPath) Then
        ResolvePowerShellExecutable = commandPath
        Exit Function
    End If

    commandPath = shellObject.ExpandEnvironmentStrings("%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe")
    If fileSystemObject.FileExists(commandPath) Then
        ResolvePowerShellExecutable = commandPath
        Exit Function
    End If

    candidates = Array("pwsh.exe", "powershell.exe")
    For i = LBound(candidates) To UBound(candidates)
        commandPath = ResolveCommandPath(shellObject, candidates(i))
        If Len(commandPath) > 0 Then
            ResolvePowerShellExecutable = commandPath
            Exit Function
        End If
    Next

    ResolvePowerShellExecutable = ""
End Function

Function ResolveCommandPath(shellObject, commandName)
    Dim execObject
    Dim resolved

    On Error Resume Next
    Set execObject = shellObject.Exec("cmd.exe /c where " & commandName)
    If Err.Number <> 0 Then
        Err.Clear
        ResolveCommandPath = ""
        Exit Function
    End If
    On Error GoTo 0

    If execObject.StdOut.AtEndOfStream Then
        ResolveCommandPath = ""
        Exit Function
    End If

    resolved = Trim(execObject.StdOut.ReadLine)
    If Len(resolved) = 0 Then
        ResolveCommandPath = ""
    Else
        ResolveCommandPath = resolved
    End If
End Function

Function Quote(value)
    Quote = Chr(34) & value & Chr(34)
End Function
'@
}

function Write-GeneratedRunner {
    if (-not (Test-Path -LiteralPath $headlessScriptPath -PathType Leaf)) {
        throw "Arquivo obrigatorio nao encontrado: $headlessScriptPath"
    }

    $content = Get-GeneratedRunnerContent
    [System.IO.File]::WriteAllText($runnerVbsPath, $content, [System.Text.UTF8Encoding]::new($false))
}

function Remove-GeneratedRunnerIfManaged {
    if (-not (Test-Path -LiteralPath $runnerVbsPath -PathType Leaf)) {
        return $false
    }

    $firstLine = Get-Content -LiteralPath $runnerVbsPath -TotalCount 1 -ErrorAction SilentlyContinue
    if ($firstLine -eq "' Generated by Instalar VibeToolkit.cmd") {
        Remove-Item -LiteralPath $runnerVbsPath -Force -ErrorAction Stop
        return $true
    }

    return $false
}

function Test-VibeToolkitInstalled {
    $paths = @(
        'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\shell\VibeToolkitTerminal',
        'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\VibeToolkitTerminal',
        'Registry::HKEY_CURRENT_USER\Software\Classes\Drive\shell\VibeToolkitTerminal'
    )

    foreach ($path in $paths) {
        if (Test-Path -LiteralPath $path) {
            return $true
        }
    }

    return $false
}

function Resolve-RequestedMode {
    if ($Mode -ne 'auto') {
        return $Mode
    }

    if (-not (Test-VibeToolkitInstalled)) {
        Write-Info 'Nenhuma instalacao ativa detectada. Executando install.'
        return 'install'
    }

    Write-Host ''
    Write-Host 'VibeToolkit ja esta instalado.' -ForegroundColor Yellow
    Write-Host 'Escolha uma opcao:'
    Write-Host '  [1] Repair'
    Write-Host '  [2] Uninstall'
    Write-Host '  [3] Cancelar'
    Write-Host ''

    while ($true) {
        $choice = (Read-Host 'Digite 1, 2 ou 3').Trim().ToLowerInvariant()
        switch ($choice) {
            '1' { return 'repair' }
            'repair' { return 'repair' }
            'r' { return 'repair' }
            '2' { return 'uninstall' }
            'uninstall' { return 'uninstall' }
            'u' { return 'uninstall' }
            '3' { return 'cancel' }
            'cancel' { return 'cancel' }
            'c' { return 'cancel' }
            default {
                Write-Warning 'Opcao invalida. Digite 1, 2 ou 3.'
            }
        }
    }
}

function Install-VibeToolkit {
    Write-Info ('Modo solicitado: {0}' -f $Mode)
    Write-Info ('Repositorio: {0}' -f $RepoRoot)

    $cleanup = Remove-VibeContextMenuKeys
    if ($cleanup.Removed.Count -gt 0) {
        Write-Host 'Chaves antigas removidas antes da reinstalacao:' -ForegroundColor Yellow
        foreach ($item in $cleanup.Removed) {
            Write-Host (' - {0}' -f $item)
        }
    }

    foreach ($warningMessage in $cleanup.Warnings) {
        Write-Warning $warningMessage
    }

    Write-GeneratedRunner

    $iconValue = ('{0},0' -f (Resolve-MenuIconPath))
    $entries = @(
        @{ BaseKey = (Join-Path $classesRoot 'Directory\shell');            MenuKeyName = 'VibeToolkitTerminal'; MenuLabel = 'VibeToolkit: Abrir Terminal (CLI)'; RunnerPath = $runnerVbsPath; ArgumentToken = '%V' },
        @{ BaseKey = (Join-Path $classesRoot 'Directory\Background\shell'); MenuKeyName = 'VibeToolkitTerminal'; MenuLabel = 'VibeToolkit: Abrir Terminal (CLI)'; RunnerPath = $runnerVbsPath; ArgumentToken = '%V' },
        @{ BaseKey = (Join-Path $classesRoot 'Drive\shell');                MenuKeyName = 'VibeToolkitTerminal'; MenuLabel = 'VibeToolkit: Abrir Terminal (CLI)'; RunnerPath = $runnerVbsPath; ArgumentToken = '%1' }
    )

    foreach ($entry in $entries) {
        Set-ContextMenuEntry @entry -IconPath $iconValue
    }

    Write-Host ''
    Write-Host 'VibeToolkit instalado com sucesso.' -ForegroundColor Green
    Write-Host ('Runner VBS gerado em: {0}' -f $runnerVbsPath)
    Write-Host ('Headless script esperado em: {0}' -f $headlessScriptPath)
    Write-Host 'Menu de contexto registrado em HKCU\Software\Classes.'
}

function Uninstall-VibeToolkit {
    Write-Info ('Modo solicitado: {0}' -f $Mode)
    Write-Info ('Repositorio: {0}' -f $RepoRoot)

    $cleanup = Remove-VibeContextMenuKeys
    $runnerRemoved = Remove-GeneratedRunnerIfManaged

    if ($cleanup.Removed.Count -eq 0) {
        Write-Host 'Nenhuma chave encontrada para remover.' -ForegroundColor Yellow
    }
    else {
        Write-Host 'Menu de contexto removido.' -ForegroundColor Green
        foreach ($item in $cleanup.Removed) {
            Write-Host (' - {0}' -f $item)
        }
    }

    foreach ($warningMessage in $cleanup.Warnings) {
        Write-Warning $warningMessage
    }

    if ($runnerRemoved) {
        Write-Host ('Runner removido: {0}' -f $runnerVbsPath)
    }
    else {
        Write-Host 'Nenhum runner gerado automaticamente precisou ser removido.'
    }
}

$effectiveMode = Resolve-RequestedMode
Write-Info ('Modo efetivo: {0}' -f $effectiveMode)

switch ($effectiveMode) {
    'install' {
        Install-VibeToolkit
    }
    'repair' {
        Install-VibeToolkit
    }
    'uninstall' {
        Uninstall-VibeToolkit
    }
    'cancel' {
        Write-Host 'Operacao cancelada pelo usuario.' -ForegroundColor Yellow
        exit 0
    }
    default {
        throw "Modo invalido: $effectiveMode"
    }
}

#### File: .\lib\SentinelUI.ps1
$script:SentinelEscape = [char]27

function Test-SentinelAnsiSupport {
    $isOutputRedirected = $false

    try {
        $isOutputRedirected = [Console]::IsOutputRedirected
    }
    catch {
        $isOutputRedirected = $false
    }

    if ($isOutputRedirected) {
        return $false
    }

    if (-not [string]::IsNullOrWhiteSpace($env:NO_COLOR) -and $env:NO_COLOR -ne '0') {
        return $false
    }

    try {
        if ($PSStyle -and $PSStyle.OutputRendering -eq 'PlainText') {
            return $false
        }
    }
    catch {
    }

    if (
        -not [string]::IsNullOrWhiteSpace($env:WT_SESSION) -or
        $env:TERM_PROGRAM -eq 'vscode' -or
        $env:ConEmuANSI -eq 'ON'
    ) {
        return $true
    }

    if (-not [string]::IsNullOrWhiteSpace($env:TERM) -and $env:TERM -ne 'dumb') {
        return $true
    }

    try {
        if ($Host.UI -and $Host.UI.SupportsVirtualTerminal) {
            return $true
        }
    }
    catch {
    }

    return $false
}

$script:SentinelAnsiEnabled = Test-SentinelAnsiSupport
$script:SentinelPlainGlyphs = @{
    Success = '[OK]'
    Info    = '[>>]'
    Warning = '[!!]'
    Error   = '[ER]'
}

$script:SentinelUiLayout = @{
    DividerWidth          = 70
    ProgressBarWidth      = 18
    ProgressActivityWidth = 24
}

$SentinelTheme = [ordered]@{
    Reset     = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[0m" } else { '' }
    Primary   = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;0;229;255m" } else { '' }
    Secondary = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;176;190;212m" } else { '' }
    Muted     = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;120;133;153m" } else { '' }
    Success   = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;34;197;94m" } else { '' }
    Warning   = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;245;158;11m" } else { '' }
    Error     = if ($script:SentinelAnsiEnabled) { "$($script:SentinelEscape)[38;2;239;68;68m" } else { '' }
    Glyphs    = @{
        Success = if ($script:SentinelAnsiEnabled) { '✅' } else { $script:SentinelPlainGlyphs.Success }
        Info    = if ($script:SentinelAnsiEnabled) { '➤' } else { $script:SentinelPlainGlyphs.Info }
        Warning = if ($script:SentinelAnsiEnabled) { '⚠️' } else { $script:SentinelPlainGlyphs.Warning }
        Error   = if ($script:SentinelAnsiEnabled) { '❌' } else { $script:SentinelPlainGlyphs.Error }
    }
}

function Get-SentinelConsoleWidth {
    try {
        $windowWidth = [Console]::WindowWidth
        if ($windowWidth -gt 0) {
            return $windowWidth
        }
    }
    catch {
    }

    try {
        $rawUiWidth = $Host.UI.RawUI.WindowSize.Width
        if ($rawUiWidth -gt 0) {
            return $rawUiWidth
        }
    }
    catch {
    }

    return 120
}

function Get-SentinelToneColor {
    param([string]$Tone = 'Primary')

    switch ($Tone) {
        'Success' { return $SentinelTheme.Success }
        'Warning' { return $SentinelTheme.Warning }
        'Error' { return $SentinelTheme.Error }
        'Secondary' { return $SentinelTheme.Secondary }
        'Muted' { return $SentinelTheme.Muted }
        default { return $SentinelTheme.Primary }
    }
}

function Get-SentinelTrimmedText {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$Text = '',
        [int]$MaxLength = 24
    )

    $value = if ($null -eq $Text) { '' } else { [string]$Text }
    if ([string]::IsNullOrEmpty($value)) {
        return ''
    }

    if ($value.Length -le $MaxLength) {
        return $value
    }

    if ($MaxLength -le 1) {
        return '…'
    }

    return ($value.Substring(0, $MaxLength - 1) + '…')
}

function Format-SentinelFitLine {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$Text = '',
        [int]$Indent = 4,
        [int]$Margin = 2
    )

    $value = if ($null -eq $Text) { '' } else { [string]$Text }

    $windowWidth = 80
    try { $windowWidth = [Math]::Max([Console]::WindowWidth, 40) } catch {}

    # Available columns after the indent prefix (e.g. "  ✅ ")
    $maxLen = $windowWidth - $Indent - $Margin
    if ($maxLen -le 4) { return $value }

    if ($value.Length -le $maxLen) {
        return $value
    }

    return ($value.Substring(0, $maxLen - 1) + '…')
}

function Get-SentinelDividerContent {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$Label = '',
        [int]$Width = 52,
        [string]$Character = '━'
    )

    $safeWidth = [Math]::Max($Width, 8)
    $dividerChar = if ([string]::IsNullOrEmpty($Character)) { '━' } else { $Character.Substring(0, 1) }

    if ([string]::IsNullOrWhiteSpace($Label)) {
        return ($dividerChar * $safeWidth)
    }

    $normalizedLabel = ($Label -replace '\s+', ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($normalizedLabel)) {
        return ($dividerChar * $safeWidth)
    }

    $minimumSideWidth = 2
    $labelPaddingWidth = 2
    $maxLabelLength = $safeWidth - (($minimumSideWidth * 2) + $labelPaddingWidth)

    if ($maxLabelLength -le 0) {
        return ($dividerChar * $safeWidth)
    }

    if ($normalizedLabel.Length -gt $maxLabelLength) {
        if ($maxLabelLength -eq 1) {
            $normalizedLabel = '…'
        }
        else {
            $normalizedLabel = $normalizedLabel.Substring(0, $maxLabelLength - 1) + '…'
        }
    }

    $framedLabel = " $normalizedLabel "
    $remaining = $safeWidth - $framedLabel.Length

    if ($remaining -lt ($minimumSideWidth * 2)) {
        $maxFramedLabelLength = $safeWidth - ($minimumSideWidth * 2)
        if ($maxFramedLabelLength -le 0) {
            return ($dividerChar * $safeWidth)
        }

        if ($framedLabel.Length -gt $maxFramedLabelLength) {
            $framedLabel = $framedLabel.Substring(0, $maxFramedLabelLength)
        }

        $remaining = $safeWidth - $framedLabel.Length
    }

    $leftWidth = [Math]::Max([int][Math]::Floor($remaining / 2), $minimumSideWidth)
    $rightWidth = [Math]::Max(($remaining - $leftWidth), $minimumSideWidth)

    $currentLength = $leftWidth + $framedLabel.Length + $rightWidth
    if ($currentLength -gt $safeWidth) {
        $overflow = $currentLength - $safeWidth

        if ($rightWidth -gt $minimumSideWidth) {
            $shrinkRight = [Math]::Min($overflow, $rightWidth - $minimumSideWidth)
            $rightWidth -= $shrinkRight
            $overflow -= $shrinkRight
        }

        if ($overflow -gt 0 -and $leftWidth -gt $minimumSideWidth) {
            $shrinkLeft = [Math]::Min($overflow, $leftWidth - $minimumSideWidth)
            $leftWidth -= $shrinkLeft
            $overflow -= $shrinkLeft
        }
    }

    return ('{0}{1}{2}' -f ($dividerChar * $leftWidth), $framedLabel, ($dividerChar * $rightWidth))
}

function Write-SentinelText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [string]$Color = $SentinelTheme.Primary
    )

    if ([string]::IsNullOrEmpty($Color)) {
        Write-Host $Text
        return
    }

    Write-Host ("{0}{1}{2}" -f $Color, $Text, $SentinelTheme.Reset)
}

function Write-SentinelDivider {
    [CmdletBinding()]
    param(
        [string]$Label,
        [ValidateSet('Primary', 'Success', 'Warning', 'Error', 'Secondary', 'Muted')]
        [string]$Tone = 'Secondary',
        [int]$Width = 52,
        [string]$Character = '━'
    )

    $dividerText = Get-SentinelDividerContent -Label $Label -Width $Width -Character $Character
    $color = Get-SentinelToneColor -Tone $Tone
    Write-SentinelText -Text ("  {0}" -f $dividerText) -Color $color
}

function Format-SentinelBadge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [ValidateSet('Primary', 'Success', 'Warning', 'Error', 'Secondary', 'Muted')]
        [string]$Tone = 'Primary'
    )

    $normalized = ($Label -replace '\s+', ' ').Trim().ToUpperInvariant()
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return ''
    }

    if (-not $script:SentinelAnsiEnabled) {
        return ('[{0}]' -f $normalized)
    }

    $color = Get-SentinelToneColor -Tone $Tone
    return ("{0}[{1}]{2}" -f $color, $normalized, $SentinelTheme.Reset)
}

function Write-SentinelBadgeLine {
    [CmdletBinding()]
    param([string[]]$Badges)

    $normalizedBadges = @($Badges | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($normalizedBadges.Count -eq 0) {
        return
    }

    Write-Host ("  {0}" -f ($normalizedBadges -join ' '))
}

function Write-SentinelHeader {
    [CmdletBinding()]
    param(
        [string]$Title = 'SENTINEL',
        [string]$Version = 'v1.0.0',
        [ValidateSet('Hero', 'Compact', 'Minimal')]
        [string]$Variant = 'Hero'
    )

    if ($Variant -eq 'Minimal') {
        Write-SentinelText -Text ("  {0} · {1}" -f $Title, $Version) -Color $SentinelTheme.Primary
        Write-Host ''
        return
    }

    $logo = @(
        '   (`  ,_ |      |)   _   |  _                                    ',
        '   _)(|||(||`()  |)|`(/_(||<(/_|`                                 ',
        '                                                                  ',
        '  ███████╗███████╗███╗   ██╗████████╗██╗███╗   ██╗███████╗██╗     ',
        '  ██╔════╝██╔════╝████╗  ██║╚══██╔══╝██║████╗  ██║██╔════╝██║     ',
        '  ███████╗█████╗  ██╔██╗ ██║   ██║   ██║██╔██╗ ██║█████╗  ██║     ',
        '  ╚════██║██╔══╝  ██║╚██╗██║   ██║   ██║██║╚██╗██║██╔══╝  ██║     ',
        '  ███████║███████╗██║ ╚████║   ██║   ██║██║ ╚████║███████╗███████╗',
        '  ╚══════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝',
        '                                                                  ',
        '                                                                  '
    )
    $mascot = @(
        ''            
    )

    $gap = 1
    $consoleWidth = Get-SentinelConsoleWidth
    $logoLines = @($logo | ForEach-Object { $_.TrimEnd() })
    $mascotLines = @($mascot | ForEach-Object { $_.TrimEnd() })
    $leftWidth = (($logoLines | Measure-Object -Maximum Length).Maximum | ForEach-Object { if ($_ -is [int]) { $_ } else { 0 } })
    $rightWidth = (($mascotLines | Measure-Object -Maximum Length).Maximum | ForEach-Object { if ($_ -is [int]) { $_ } else { 0 } })
    $useFixedColumn = ($leftWidth + $gap + $rightWidth) -le $consoleWidth

    $bestOffset = 0

    if (-not $useFixedColumn) {
        $minOffset = - ($mascotLines.Count - 1)
        $maxOffset = $logoLines.Count - 1
        $bestOverflow = [int]::MaxValue
        $bestWidth = [int]::MaxValue
        $bestDistance = [int]::MaxValue

        for ($offset = $minOffset; $offset -le $maxOffset; $offset++) {
            $startRow = [Math]::Min(0, $offset)
            $endRow = [Math]::Max($logoLines.Count - 1, $offset + $mascotLines.Count - 1)
            $maxCombinedWidth = 0

            for ($row = $startRow; $row -le $endRow; $row++) {
                $logoIndex = $row
                $mascotIndex = $row - $offset

                $logoLine = if ($logoIndex -ge 0 -and $logoIndex -lt $logoLines.Count) { $logoLines[$logoIndex] } else { '' }
                $mascotLine = if ($mascotIndex -ge 0 -and $mascotIndex -lt $mascotLines.Count) { $mascotLines[$mascotIndex] } else { '' }

                $combinedWidth = 0
                if (-not [string]::IsNullOrEmpty($logoLine) -and -not [string]::IsNullOrEmpty($mascotLine)) {
                    $combinedWidth = $logoLine.Length + $gap + $mascotLine.Length
                }
                elseif (-not [string]::IsNullOrEmpty($logoLine)) {
                    $combinedWidth = $logoLine.Length
                }
                else {
                    $combinedWidth = $mascotLine.Length
                }

                if ($combinedWidth -gt $maxCombinedWidth) {
                    $maxCombinedWidth = $combinedWidth
                }
            }

            $overflow = [Math]::Max(0, $maxCombinedWidth - $consoleWidth)
            $distance = [Math]::Abs($offset)

            if (
                $overflow -lt $bestOverflow -or
                ($overflow -eq $bestOverflow -and $maxCombinedWidth -lt $bestWidth) -or
                ($overflow -eq $bestOverflow -and $maxCombinedWidth -eq $bestWidth -and $distance -lt $bestDistance)
            ) {
                $bestOverflow = $overflow
                $bestWidth = $maxCombinedWidth
                $bestDistance = $distance
                $bestOffset = $offset
            }
        }
    }

    $p = $SentinelTheme.Primary
    $s = $SentinelTheme.Secondary
    $r = $SentinelTheme.Reset

    if ($Variant -eq 'Hero') {
        Write-SentinelDivider -Tone 'Secondary'
    }

    $startRow = [Math]::Min(0, $bestOffset)
    $endRow = [Math]::Max($logoLines.Count - 1, $bestOffset + $mascotLines.Count - 1)

    for ($row = $startRow; $row -le $endRow; $row++) {
        $logoIndex = $row
        $mascotIndex = $row - $bestOffset

        $logoLine = if ($logoIndex -ge 0 -and $logoIndex -lt $logoLines.Count) { $logoLines[$logoIndex] } else { '' }
        $mascotLine = if ($mascotIndex -ge 0 -and $mascotIndex -lt $mascotLines.Count) { $mascotLines[$mascotIndex] } else { '' }

        if (-not [string]::IsNullOrEmpty($logoLine) -and -not [string]::IsNullOrEmpty($mascotLine)) {
            if ($useFixedColumn) {
                $paddedLogo = $logoLine.PadRight($leftWidth + $gap)
                Write-Host ("{0}{1}{2}{3}{4}{5}" -f $p, $paddedLogo, $r, $s, $mascotLine, $r)
            }
            else {
                Write-Host ("{0}{1}{2}{3}{4}{5}{6}" -f $p, $logoLine, $r, (' ' * $gap), $s, $mascotLine, $r)
            }

            continue
        }

        if (-not [string]::IsNullOrEmpty($logoLine)) {
            Write-Host ("{0}{1}{2}" -f $p, $logoLine, $r)
            continue
        }

        if (-not [string]::IsNullOrEmpty($mascotLine)) {
            if ($useFixedColumn) {
                Write-Host ("{0}{1}{2}{3}{4}" -f (' ' * ($leftWidth + $gap)), $s, $mascotLine, $r, '')
            }
            else {
                Write-Host ("{0}{1}{2}" -f $s, $mascotLine, $r)
            }

            continue
        }

        Write-Host ''
    }

    if ($Variant -eq 'Hero') {
        Write-Host ''
        Write-SentinelText -Text ("  {0} · {1}" -f $Title, $Version) -Color $SentinelTheme.Secondary
        Write-SentinelDivider -Tone 'Secondary'
    }
    else {
        # Compact
        Write-SentinelText -Text ("  {0} · {1}" -f $Title, $Version) -Color $SentinelTheme.Primary
    }
    
    Write-Host ''
}

function Write-SentinelSection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [string]$Subtitle,
        [ValidateSet('Primary', 'Success', 'Warning', 'Error', 'Secondary', 'Muted')]
        [string]$Tone = 'Primary'
    )

    Write-Host ''
    Write-SentinelDivider -Label $Title -Tone $Tone
    if (-not [string]::IsNullOrWhiteSpace($Subtitle)) {
        Write-SentinelText -Text ("  {0}" -f $Subtitle) -Color $SentinelTheme.Secondary
    }
    Write-Host ''
}

function Write-SentinelPanel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [string[]]$Lines,
        [ValidateSet('Primary', 'Success', 'Warning', 'Error', 'Secondary', 'Muted')]
        [string]$Tone = 'Secondary'
    )

    $normalizedLines = @($Lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    Write-SentinelText -Text ("  {0}" -f $Title) -Color (Get-SentinelToneColor -Tone $Tone)

    foreach ($line in $normalizedLines) {
        Write-SentinelText -Text ("    {0}" -f $line) -Color $SentinelTheme.Secondary
    }

    Write-Host ''
}

function Write-SentinelKeyValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        [AllowEmptyString()][string]$Value = '',
        [int]$KeyWidth = 18,
        [ValidateSet('Primary', 'Success', 'Warning', 'Error', 'Secondary', 'Muted')]
        [string]$Tone = 'Primary'
    )

    $paddedKey = $Key.PadRight([Math]::Max($KeyWidth, 8))
    $valueText = if ($null -eq $Value) { '' } else { [string]$Value }

    if (-not $script:SentinelAnsiEnabled) {
        Write-Host ("  {0} : {1}" -f $paddedKey, $valueText)
        return
    }

    $keyColor = $SentinelTheme.Secondary
    $valueColor = Get-SentinelToneColor -Tone $Tone
    Write-Host ("  {0}{1}{2}{3}:{2} {4}{5}{2}" -f $keyColor, $paddedKey, $SentinelTheme.Reset, $SentinelTheme.Muted, $valueColor, $valueText)
}

function Write-SentinelMenuOptions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Options
    )

    for ($index = 0; $index -lt $Options.Count; $index++) {
        Write-SentinelText -Text ("    [{0}] {1}" -f ($index + 1), $Options[$index]) -Color $SentinelTheme.Secondary
    }

    Write-Host ''
}

function Write-SentinelProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Activity,
        [int]$Current = 0,
        [int]$Total = 0,
        [ValidateSet('Primary', 'Success', 'Warning', 'Error', 'Secondary', 'Muted')]
        [string]$Tone = 'Primary',
        [string]$Item = ''
    )

    $windowWidth = 80
    try {
        $windowWidth = [Math]::Max([Console]::WindowWidth, 60)
    }
    catch {}

    if ($Total -le 0) {
        $activityText = Get-SentinelTrimmedText -Text $Activity -MaxLength ([Math]::Max(($script:SentinelUiLayout.ProgressActivityWidth + 8), 12))
        $line = ("  ⟳ {0}" -f $activityText).PadRight($windowWidth - 1)
        if ($script:SentinelAnsiEnabled) {
            Write-Host ("`r{0}{1}{2}" -f (Get-SentinelToneColor -Tone $Tone), $line, $SentinelTheme.Reset) -NoNewline
        }
        else {
            Write-Host ("`r{0}" -f $line) -NoNewline
        }
        return
    }

    $safeCurrent = [Math]::Min([Math]::Max($Current, 0), $Total)
    $barWidth = [Math]::Max($script:SentinelUiLayout.ProgressBarWidth, 14)
    $ratio = if ($Total -eq 0) { 0 } else { [double]$safeCurrent / [double]$Total }
    $filled = [int][Math]::Round(($ratio * $barWidth), 0, [System.MidpointRounding]::AwayFromZero)
    $filled = [Math]::Min([Math]::Max($filled, 0), $barWidth)
    $empty = $barWidth - $filled
    $bar = if ($script:SentinelAnsiEnabled) { ('█' * $filled) + ('░' * $empty) } else { ('#' * $filled) + ('·' * $empty) }
    $percent = [int][Math]::Round(($ratio * 100), 0, [System.MidpointRounding]::AwayFromZero)

    # Monta a base fixa: "  ⟳ Activity  [████████] 100% (37/37)"
    $progressBase = "  ⟳ {0}  [{1}] {2,3}% ({3}/{4})" -f $Activity, $bar, $percent, $safeCurrent, $Total
    $baseLength = $progressBase.Length

    # Calcula espaço restante para o nome do item
    $availableForItem = $windowWidth - $baseLength - 2   # margem de segurança

    $displayItem = ''
    if (-not [string]::IsNullOrWhiteSpace($Item) -and $availableForItem -gt 4) {
        # Extrai só o nome do arquivo (ou último segmento) para priorizar legibilidade
        $leaf = [System.IO.Path]::GetFileName($Item)
        if ([string]::IsNullOrWhiteSpace($leaf)) { $leaf = $Item }

        if ($leaf.Length -le $availableForItem) {
            $displayItem = '  ' + $leaf
        }
        else {
            # Trunca com "…" no início para preservar final do nome (mais informativo)
            $displayItem = '  …' + $leaf.Substring($leaf.Length - ($availableForItem - 3))
        }
    }

    $line = ($progressBase + $displayItem).PadRight($windowWidth - 1)

    if ($script:SentinelAnsiEnabled) {
        $color = Get-SentinelToneColor -Tone $Tone
        Write-Host ("`r{0}{1}{2}" -f $color, $line, $SentinelTheme.Reset) -NoNewline
    }
    else {
        Write-Host ("`r{0}" -f $line) -NoNewline
    }
}

function Write-SentinelStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('Success', 'Info', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )

    $glyph = $SentinelTheme.Glyphs[$Type]
    $color = switch ($Type) {
        'Success' { $SentinelTheme.Success }
        'Warning' { $SentinelTheme.Warning }
        'Error' { $SentinelTheme.Error }
        default { $SentinelTheme.Primary }
    }

    # Indent: 2 spaces + glyph (1-2 chars) + 1 space = ~4-5 chars
    $fittedMessage = Format-SentinelFitLine -Text $Message -Indent 5 -Margin 2
    Write-SentinelText -Text ("  {0} {1}" -f $glyph, $fittedMessage) -Color $color
}

function Show-SentinelMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string[]]$Options,

        [string]$Prompt = ''
    )

    Write-SentinelSection -Title $Title -Tone 'Primary'
    Write-SentinelMenuOptions -Options $Options
    $promptText = if (-not [string]::IsNullOrWhiteSpace($Prompt)) { $Prompt } else { ('  Escolha [1-{0}]' -f $Options.Count) }
    return (Read-Host $promptText)
}

function Show-SentinelSpinner {
    [CmdletBinding()]
    param([string]$Message = 'Processando...')

    Write-SentinelProgress -Activity $Message -Tone 'Primary'
}

#### File: .\modules\VibeBundleWriter.psm1
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

    $marker = '

#### File: .\modules\VibeDeclaredFlowBridge.psm1
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

#### File: .\modules\VibeDirectorProtocol.psm1
Set-StrictMode -Version Latest

function Get-VibeExtractionModeLabel {
    param([string]$ExtractionMode)

    switch ($ExtractionMode) {
        'blueprint' { return 'BLUEPRINT' }
        'sniper' { return 'SNIPER' }
        default { return 'FULL' }
    }
}

function Get-VibeDirectorLocalProtocolHeader {
    param(
        [string]$ExtractionMode,
        [string]$ExecutorTargetValue
    )

    return @"
## ATIVAÇÃO OPERACIONAL LOCAL — DIRETOR v5.0

### MODO ATIVO
- Assuma imediatamente o modo Diretor. Este documento contém regras operacionais ativas e obrigatórias, não texto informativo.
- Papel obrigatório durante toda a resposta: Diretor de Engenharia Agêntica em modo determinístico local.
- Rota ativa: VIA DIRETOR.
- Extração efetiva: $(Get-VibeExtractionModeLabel -ExtractionMode $ExtractionMode).
- Executor alvo de referência: $ExecutorTargetValue.
- Fronteira de execução: é proibido implementar código diretamente.
- Missão: analisar o artefato visível com rigor técnico, diagnosticar o problema real, definir a estratégia mínima necessária e produzir instrução operacional rastreável para o Executor, preservando contratos, comportamento, arquitetura existente e limites reais do recorte.

### ORDEM OBRIGATÓRIA DE LEITURA
1. Ler primeiro `PROJECT STRUCTURE` do artefato fonte.
2. Assimilar apenas as pastas, arquivos, contratos e limites realmente visíveis.
3. Ler depois `SOURCE FILES` do mesmo artefato.
4. Só então analisar, responder e compor instruções para o Executor.
5. É proibido responder como se tivesse lido arquivos, contratos, fluxos, dependências ou comportamentos não presentes no artefato visível.

### FONTE PRIMÁRIA E RESTRIÇÕES OBRIGATÓRIAS
- O artefato visível é a única fonte primária obrigatória.
- Não usar memória anterior, contexto implícito, seleção remota, comportamento presumido ou conhecimento externo ao recorte visível.
- Não inferir módulos, contratos, dependências, arquivos, fluxos, integrações ou comportamentos fora do material efetivamente visível.
- Quando faltar contexto, declarar explicitamente: `não visível no recorte enviado`.
- Aplicar Lei da Subtração antes de propor qualquer alteração.
- Preservar contratos, nomes, comportamento existente, compatibilidade com o fluxo atual e convenções já consolidadas no projeto.
- É proibido sugerir arquivos, funções, helpers, serviços, adapters, wrappers, camadas ou abstrações novas sem evidência direta no artefato e sem necessidade técnica estritamente demonstrável pelo escopo.
- É proibido expandir escopo, refatorar lateralmente, renomear elementos válidos, reorganizar arquitetura ou “aproveitar para melhorar” partes fora do pedido.
- Se a solução puder ser atingida com ajuste local, mínimo e compatível, qualquer proposta mais ampla deve ser rejeitada.

### REGRA DE ANÁLISE ESTRITA
- Toda conclusão deve ser rastreável a evidência contida no artefato.
- Toda recomendação deve ter causa provável, impacto e justificativa técnica explícitos.
- Não propor refatoração estrutural sem necessidade demonstrável pelo problema visível.
- Não confundir hipótese com evidência. Quando houver hipótese, marcá-la como hipótese.
- Não produzir análise ensaística, genérica ou decorativa.
- Não responder com “melhores práticas” soltas sem vínculo com o recorte visível.
- Sempre priorizar:
  - correção mínima
  - preservação de contrato
  - compatibilidade operacional
  - redução de risco de regressão
- Se o problema não puder ser resolvido de forma segura com o recorte atual, não inventar solução. Registrar em `LIMITES / UNKNOWNS`.

### REGRA DE COMPOSIÇÃO PARA O EXECUTOR
- A saída do Diretor deve resultar em instrução operacional copiável para o Executor.
- Toda instrução para o Executor deve estar delimitada por:
  - objetivo técnico
  - escopo
  - restrições imutáveis
  - resultado esperado
  - critérios de aceitação
  - limites do recorte, quando houver
- O Diretor não deve pedir ao Executor que:
  - invente arquivos ou contratos
  - altere arquitetura sem necessidade
  - implemente fora do recorte visível
  - assuma comportamentos não demonstrados no artefato
- Quando o problema exigir implementação, o Diretor deve orientar o Executor a:
  - preservar contratos e comportamento
  - preferir patch mínimo
  - validar regressão
  - explicitar unknowns
- O prompt para o Executor deve ser denso, técnico, objetivo e operacional. Não deve conter floreio, redundância nem explicação decorativa.

### SAÍDA OBRIGATÓRIA
A resposta do Diretor deve seguir exatamente esta ordem:

#### [DIAGNÓSTICO]
- Descrever objetivamente:
  - problema observado
  - causa provável
  - impacto
  - risco técnico
  - evidência visível que sustenta a leitura

#### [DECISÃO / ESTRATÉGIA]
- Definir a abordagem recomendada.
- Explicar por que a estratégia escolhida é a menor necessária.
- Registrar explicitamente o que não deve ser alterado.

#### [INSTRUÇÕES PARA O EXECUTOR]
- Entregar um prompt operacional copiável, pronto para execução.
- O prompt deve exigir:
  - relatório de impacto
  - implementação explícita
  - verificação objetiva
  - preservação de contratos
  - declaração de unknowns quando aplicável

#### [CRITÉRIOS DE ACEITAÇÃO]
- Informar condições objetivas para considerar a tarefa concluída com sucesso.

#### [LIMITES / UNKNOWNS]
- Listar explicitamente qualquer ponto não validável no recorte visível.
- Sempre usar a formulação: `não visível no recorte enviado` quando aplicável.

### FORMATO DE SAÍDA
- Não implementar código.
- Não entregar patch diff final como se fosse o Executor.
- Não omitir seções obrigatórias.
- Não esconder lacunas de contexto.
- Não apresentar opinião subjetiva sem vínculo técnico com o artefato.
- Não responder em formato ensaístico.
- A resposta deve ser densa, técnica, objetiva, rastreável e copiável.

### CRITÉRIOS DE REJEIÇÃO INTERNA
A resposta do Diretor deve ser considerada inválida se:
- inventar arquivo, contrato, fluxo ou comportamento não visível
- pedir mudança arquitetural sem necessidade explícita
- produzir análise genérica sem evidência
- deixar de apontar unknowns quando houver lacuna
- produzir prompt frouxo ou ambíguo para o Executor
- misturar papel de Diretor com implementação de Executor
- sugerir expansão de escopo para além do pedido visível
"@.Trim()
}

function Get-VibeExecutorLocalProtocolHeader {
    param(
        [string]$ExtractionMode,
        [string]$ExecutorTargetValue
    )

    $extractionLine = switch ($ExtractionMode) {
        'blueprint' { '* **Leitura de Extração:** Como a extração é BLUEPRINT, priorize contratos, assinaturas, interfaces e pontos de integração sem fingir leitura do que não está visível.' }
        'sniper' { '* **Leitura de Extração:** Como a extração é SNIPER, limite qualquer alteração ao recorte manual efetivamente visível.' }
        default { '* **Leitura de Extração:** Como a extração é FULL, opere com o contexto total visível do bundle.' }
    }

    return @"
## ATIVAÇÃO OPERACIONAL LOCAL — EXECUTOR

#### §0 — MODO ATIVO
* **Assuma imediatamente o modo Executor.** Este header define regras operacionais ativas e obrigatórias para toda a resposta.
* **Papel obrigatório durante toda a sessão:** Você é o **Senior Implementation Agent (Sniper)**.
* **Rota ativa:** DIRETO PARA O EXECUTOR.
* **Extração efetiva:** $(Get-VibeExtractionModeLabel -ExtractionMode $ExtractionMode).
* **Executor alvo de referência:** $ExecutorTargetValue.
* **Missão:** Materializar o escopo solicitado com fidelidade ao bundle visível, preservando contratos, comportamento e arquitetura existente.

#### §1 — ORDEM OBRIGATÓRIA DE LEITURA
1. **Ler primeiro `PROJECT STRUCTURE`.**
2. **Assimilar apenas as pastas, arquivos e limites realmente visíveis no artefato.**
3. **Ler depois `SOURCE FILES`.**
4. **Só então iniciar análise de impacto, implementação e resposta técnica.**

#### §2 — FONTE PRIMÁRIA E RESTRIÇÕES OBRIGATÓRIAS
* **Fonte primária obrigatória:** Somente o artefato visível gerado localmente pelo bundler.
* **Leitura obrigatória antes de executar:** Não iniciar implementação nem resposta final antes de assimilar o artefato visível.
* **Recorte obrigatório:** Não usar memória externa, contexto implícito ou comportamento presumido fora do artefato.
* **Lacuna obrigatória:** Quando algo não estiver visível, declarar explicitamente **`não visível no recorte enviado`**.
* **Zero Alquimia:** É proibido inventar módulos, contratos, dependências ou comportamento ausente.
* **Lei da Subtração:** Antes de adicionar código, verifique se o objetivo pode ser atingido reutilizando abstrações existentes ou removendo redundâncias.
* **Preservação de Contexto:** Mantenha nomes, contratos, comportamento existente e compatibilidade com o projeto original.
$extractionLine
* **Checklist de Segurança:** Verifique exposição de segredos, validação insuficiente de entrada e drift de contrato antes de concluir.

#### §3 — SAÍDA OBRIGATÓRIA
1. **[RELATÓRIO DE IMPACTO]**: Lista de arquivos alterados e dependências verificadas.
2. **[IMPLEMENTAÇÃO]**: Arquivos completos ou diffs precisos por arquivo.
3. **[PROTOCOLO DE VERIFICAÇÃO]**: Checks objetivos, regressão e hardening compatíveis com o escopo.
4. **[VERIFICAÇÃO DE SEGURANÇA]**: Confirmação explícita de que a alteração não introduz vulnerabilidades conhecidas.
"@.Trim()
}

function Get-VibeProtocolHeaderContent {
    param(
        [string]$RouteMode,
        [string]$ExtractionMode,
        [string]$ExecutorTargetValue
    )

    if ($RouteMode -eq 'executor') {
        return (Get-VibeExecutorLocalProtocolHeader -ExtractionMode $ExtractionMode -ExecutorTargetValue $ExecutorTargetValue)
    }

    return (Get-VibeDirectorLocalProtocolHeader -ExtractionMode $ExtractionMode -ExecutorTargetValue $ExecutorTargetValue)
}

function Get-VibeExecutorTaskInstructionTemplate {
    param(
        [string]$ProjectNameValue,
        [string]$SourceArtifactFileName,
        [string]$ExecutorTargetValue,
        [string]$ExtractionMode,
        [string]$RelevantFilesValue
    )

    $extractionLabel = Get-VibeExtractionModeLabel -ExtractionMode $ExtractionMode

    return @"
[INSTRUÇÃO OPERACIONAL PARA O EXECUTOR]

## FORMATO DE ENTREGA PARA O EXECUTOR (COPIAR ABAIXO)
--- INÍCIO DA INSTRUÇÃO ---
O Executor já foi previamente ativado com o protocolo operacional local correspondente. Não repetir bootstrap, protocolo base, ordem de leitura global ou regras estruturais já carregadas no chat do Executor.

### CONTEXTO OPERACIONAL
- Projeto: $ProjectNameValue
- Artefato fonte analisado pelo Diretor: $SourceArtifactFileName
- Extração efetiva do recorte analisado: $extractionLabel
- Executor alvo de referência: $ExecutorTargetValue
- Arquivos prioritários do recorte: $RelevantFilesValue

### OBJETIVO TÉCNICO
- Descrever a tarefa de forma objetiva, delimitada e verificável.

### ESCOPO
- Informar exatamente o que deve ser alterado.
- Informar explicitamente o que não deve ser alterado.
- Restringir a implementação ao recorte visível e aos arquivos realmente afetados.

### RESTRIÇÕES IMUTÁVEIS
- Preservar contratos, nomes, comportamento existente e compatibilidade com o fluxo atual.
- Não inventar arquivos, funções, módulos, fluxos, integrações ou comportamento não visível.
- Não expandir escopo nem realizar refatoração lateral.
- Preferir patch mínimo e cirúrgico por arquivo.
- Quando faltar contexto, declarar: `não visível no recorte enviado`.

### ENTREGA OBRIGATÓRIA DO EXECUTOR
A resposta do Executor deve seguir exatamente esta ordem:
1. [RELATÓRIO DE IMPACTO]
2. [PATCHES]
3. [COMANDOS PARA APLICAR]
4. [PROTOCOLO DE VERIFICAÇÃO]
5. [RESULTADO ESPERADO]
6. [LIMITES / UNKNOWNS]

### CRITÉRIOS DE ACEITAÇÃO
- Definir checks objetivos para considerar a tarefa concluída.
- Exigir validação de regressão compatível com o escopo.
- Exigir preservação explícita de contratos e comportamento.

### LIMITES / UNKNOWNS
- Registrar qualquer lacuna do recorte que impeça inferência segura.
- Sempre usar a formulação: `não visível no recorte enviado` quando aplicável.
--- FIM DA INSTRUÇÃO ---
"@.Trim()
}

function Get-VibeDeterministicMetaPromptProtocolContent {
    param(
        [string]$ProjectNameValue,
        [string]$ExecutorTargetValue,
        [string]$ExtractionMode,
        [string]$DocumentMode,
        [string]$RouteMode,
        [string]$SourceArtifactFileName,
        [string]$OutputArtifactFileName,
        [string]$GeneratedAt,
        [string[]]$RelevantFiles
    )

    $relevantFilesValue = if (@($RelevantFiles).Count -gt 0) { @($RelevantFiles) -join ', ' } else { 'não identificados objetivamente' }
    $extractionLabel = Get-VibeExtractionModeLabel -ExtractionMode $ExtractionMode
    $isExecutorRoute = ($RouteMode -match '(?i)executor')

    $executorProtocolLines = @(
        '## ATIVAÇÃO OPERACIONAL LOCAL — EXECUTOR v5.0',
        '',
        '### MODO ATIVO',
        '- Assuma imediatamente o modo Executor. Este documento contém regras operacionais ativas e obrigatórias, não texto informativo.',
        '- Papel obrigatório durante toda a resposta: Senior Implementation Agent (Sniper).',
        '- Rota ativa: DIRETO PARA O EXECUTOR.',
        "- Extração efetiva: $extractionLabel.",
        "- Executor alvo de referência: $ExecutorTargetValue.",
        '- Missão: materializar o escopo solicitado com fidelidade ao artefato visível, preservando contratos, comportamento, arquitetura existente e limites reais do recorte.',
        '',
        '### ORDEM OBRIGATÓRIA DE LEITURA',
        '1. Ler primeiro `PROJECT STRUCTURE` do artefato fonte.',
        '2. Assimilar apenas as pastas, arquivos, contratos e limites realmente visíveis.',
        '3. Ler depois `SOURCE FILES` do mesmo artefato.',
        '4. Só então iniciar análise de impacto, implementação e resposta técnica.',
        '5. É proibido responder como se tivesse lido arquivos, contratos ou fluxos não presentes no artefato visível.',
        '',
        '### FONTE PRIMÁRIA E RESTRIÇÕES OBRIGATÓRIAS',
        "- Artefato fonte obrigatório: $SourceArtifactFileName.",
        '- O artefato visível é a única fonte primária obrigatória.',
        '- Não usar memória anterior, contexto implícito, seleção remota, comportamento presumido ou conhecimento externo ao recorte visível.',
        '- Não inferir módulos, contratos, dependências, arquivos, fluxos, integrações ou comportamentos fora do material efetivamente visível.',
        '- Quando faltar contexto, declarar explicitamente: `não visível no recorte enviado`.',
        "- Recortes prioritários para leitura após a estrutura: $relevantFilesValue.",
        '- Aplicar Lei da Subtração antes de adicionar novo código.',
        '- Preservar contratos, nomes, comportamento existente, compatibilidade com o fluxo atual e convenções já consolidadas no projeto.',
        '- É proibido criar arquivos, funções, helpers, serviços, adapters, wrappers, camadas ou abstrações novas sem evidência direta no artefato e sem necessidade técnica estritamente demonstrável pelo escopo.',
        '- É proibido expandir escopo, refatorar lateralmente, renomear elementos válidos, reorganizar arquitetura ou “aproveitar para melhorar” partes fora do pedido.',
        '- Se a alteração puder ser feita com ajuste local e mínimo, qualquer expansão estrutural deve ser rejeitada.',
        '- Antes de concluir, verificar explicitamente:',
        '  - exposição de segredos',
        '  - validação insuficiente de entrada',
        '  - drift de contrato',
        '  - regressão comportamental previsível',
        '  - quebra de compatibilidade com arquivos e fluxos visíveis',
        '',
        '### REGRA DE IMPLEMENTAÇÃO ESTRITA',
        '- Toda alteração deve ser rastreável a evidência contida no artefato.',
        '- Toda alteração deve ser minimamente invasiva.',
        '- Sempre preferir patch diff mínimo por arquivo em vez de reescrita integral.',
        '- Só entregar arquivo completo quando:',
        '  - o usuário pedir explicitamente',
        '  - o arquivo for curto o suficiente',
        '  - o diff ficar menos legível que o arquivo final',
        '- Quando houver mais de um arquivo afetado, separar claramente o impacto de cada um.',
        '- Toda mudança deve preservar:',
        '  - assinatura pública',
        '  - contratos existentes',
        '  - comportamento esperado',
        '  - compatibilidade com o restante do projeto visível',
        '- Se uma possível melhoria não for necessária para cumprir o pedido, não implementar.',
        '- Se uma alteração exigir inferência fora do recorte, não inventar solução. Registrar em `LIMITES / UNKNOWNS`.',
        '',
        '### SAÍDA OBRIGATÓRIA',
        'A resposta deve seguir exatamente esta ordem:',
        '',
        '#### [RELATÓRIO DE IMPACTO]',
        '- Listar objetivamente:',
        '  - arquivos afetados',
        '  - motivo de cada alteração',
        '  - dependências verificadas',
        '  - risco de regressão',
        '  - causa provável do problema, quando aplicável',
        '',
        '#### [PATCHES]',
        '- Entregar diff unificado por arquivo sempre que possível.',
        '- Cada patch deve estar identificado pelo caminho real do arquivo.',
        '- Não misturar múltiplos arquivos no mesmo bloco sem identificação clara.',
        '',
        '#### [COMANDOS PARA APLICAR]',
        '- Entregar comandos exatos, compatíveis com o ambiente visível.',
        '- Quando o contexto for Windows/PowerShell, priorizar comandos PowerShell copiáveis.',
        '- Não entregar pseudo-comando.',
        '',
        '#### [PROTOCOLO DE VERIFICAÇÃO]',
        '- Informar checks objetivos para validar:',
        '  - funcionamento principal',
        '  - ausência de regressão previsível',
        '  - integridade do contrato',
        '  - segurança básica compatível com o escopo',
        '',
        '#### [RESULTADO ESPERADO]',
        '- Descrever de forma objetiva o que deve mudar após aplicar os patches.',
        '',
        '#### [LIMITES / UNKNOWNS]',
        '- Listar explicitamente qualquer ponto não validável no recorte visível.',
        '- Sempre usar a formulação: `não visível no recorte enviado` quando aplicável.',
        '',
        '### FORMATO DE SAÍDA',
        '- Não usar introdução decorativa.',
        '- Não usar explicação genérica sobre o que “pretende fazer”.',
        '- Não responder em formato ensaístico.',
        '- Não omitir seções obrigatórias.',
        '- Não esconder lacunas de contexto.',
        '- Não apresentar opinião subjetiva sem vínculo técnico com o artefato.',
        '- A resposta deve ser densa, técnica, objetiva e copiável.',
        '',
        '### CRITÉRIOS DE REJEIÇÃO INTERNA',
        'A resposta deve ser considerada inválida se:',
        '- inventar arquivo, contrato, fluxo ou comportamento não visível',
        '- alterar arquitetura sem necessidade explícita',
        '- não informar unknowns quando houver lacuna',
        '- entregar apenas código solto sem relatório de impacto',
        '- entregar implementação sem verificação',
        '- substituir patch mínimo por reescrita arbitrária',
        '- quebrar compatibilidade para resolver problema local'
    )

    $lines = New-Object System.Collections.Generic.List[string]

    if ($isExecutorRoute) {
        $lines.AddRange([string[]]$executorProtocolLines)
        $lines.Add('') | Out-Null
        $lines.Add('## EXECUTION META') | Out-Null
        $lines.Add('') | Out-Null
        $lines.Add("- Projeto: $ProjectNameValue") | Out-Null
        $lines.Add("- Artefato fonte: $SourceArtifactFileName") | Out-Null
        $lines.Add("- Artefato final: $OutputArtifactFileName") | Out-Null
        $lines.Add("- Executor alvo: $ExecutorTargetValue") | Out-Null
        $lines.Add("- Route mode: $RouteMode") | Out-Null
        $lines.Add("- Document mode: $DocumentMode") | Out-Null
        $lines.Add("- Gerado em: $GeneratedAt") | Out-Null

        return ($lines -join [Environment]::NewLine)
    }

    $directorProtocolLines = @(
        '## ATIVAÇÃO OPERACIONAL LOCAL — DIRETOR v5.0',
        '',
        '### MODO ATIVO',
        '- Assuma imediatamente o modo Diretor. Este documento contém regras operacionais ativas e obrigatórias, não texto informativo.',
        '- Papel obrigatório durante toda a resposta: Diretor de Engenharia Agêntica em modo determinístico local.',
        '- Rota ativa: VIA DIRETOR.',
        "- Extração efetiva: $extractionLabel.",
        "- Executor alvo de referência: $ExecutorTargetValue.",
        '- Fronteira de execução: é proibido implementar código diretamente.',
        '- Missão: analisar o artefato visível com rigor técnico, diagnosticar o problema real, definir a estratégia mínima necessária e produzir instrução operacional rastreável para o Executor, preservando contratos, comportamento, arquitetura existente e limites reais do recorte.',
        '',
        '### ORDEM OBRIGATÓRIA DE LEITURA',
        '1. Ler primeiro `PROJECT STRUCTURE` do artefato fonte.',
        '2. Assimilar apenas as pastas, arquivos, contratos e limites realmente visíveis.',
        '3. Ler depois `SOURCE FILES` do mesmo artefato.',
        '4. Só então analisar, responder e compor instruções para o Executor.',
        '5. É proibido responder como se tivesse lido arquivos, contratos, fluxos, dependências ou comportamentos não presentes no artefato visível.',
        '',
        '### FONTE PRIMÁRIA E RESTRIÇÕES OBRIGATÓRIAS',
        "- Artefato fonte obrigatório: $SourceArtifactFileName.",
        '- O artefato visível é a única fonte primária obrigatória.',
        '- Não usar memória anterior, contexto implícito, seleção remota, comportamento presumido ou conhecimento externo ao recorte visível.',
        '- Não inferir módulos, contratos, dependências, arquivos, fluxos, integrações ou comportamentos fora do material efetivamente visível.',
        '- Quando faltar contexto, declarar explicitamente: `não visível no recorte enviado`.',
        "- Recortes prioritários para leitura após a estrutura: $relevantFilesValue.",
        '- Aplicar Lei da Subtração antes de propor qualquer alteração.',
        '- Preservar contratos, nomes, comportamento existente, compatibilidade com o fluxo atual e convenções já consolidadas no projeto.',
        '- É proibido sugerir arquivos, funções, helpers, serviços, adapters, wrappers, camadas ou abstrações novas sem evidência direta no artefato e sem necessidade técnica estritamente demonstrável pelo escopo.',
        '- É proibido expandir escopo, refatorar lateralmente, renomear elementos válidos, reorganizar arquitetura ou “aproveitar para melhorar” partes fora do pedido.',
        '- Se a solução puder ser atingida com ajuste local, mínimo e compatível, qualquer proposta mais ampla deve ser rejeitada.',
        '',
        '### REGRA DE ANÁLISE ESTRITA',
        '- Toda conclusão deve ser rastreável a evidência contida no artefato.',
        '- Toda recomendação deve ter causa provável, impacto e justificativa técnica explícitos.',
        '- Não propor refatoração estrutural sem necessidade demonstrável pelo problema visível.',
        '- Não confundir hipótese com evidência. Quando houver hipótese, marcá-la como hipótese.',
        '- Não produzir análise ensaística, genérica ou decorativa.',
        '- Não responder com “melhores práticas” soltas sem vínculo com o recorte visível.',
        '- Sempre priorizar:',
        '  - correção mínima',
        '  - preservação de contrato',
        '  - compatibilidade operacional',
        '  - redução de risco de regressão',
        '- Se o problema não puder ser resolvido de forma segura com o recorte atual, não inventar solução. Registrar em `LIMITES / UNKNOWNS`.',
        '',
        '### REGRA DE COMPOSIÇÃO PARA O EXECUTOR',
        '- A saída do Diretor deve resultar em instrução operacional copiável para o Executor.',
        '- Toda instrução para o Executor deve estar delimitada por:',
        '  - objetivo técnico',
        '  - escopo',
        '  - restrições imutáveis',
        '  - resultado esperado',
        '  - critérios de aceitação',
        '  - limites do recorte, quando houver',
        '- O Diretor não deve pedir ao Executor que:',
        '  - invente arquivos ou contratos',
        '  - altere arquitetura sem necessidade',
        '  - implemente fora do recorte visível',
        '  - assuma comportamentos não demonstrados no artefato',
        '- Quando o problema exigir implementação, o Diretor deve orientar o Executor a:',
        '  - preservar contratos e comportamento',
        '  - preferir patch mínimo',
        '  - validar regressão',
        '  - explicitar unknowns',
        '- O prompt para o Executor deve ser denso, técnico, objetivo e operacional. Não deve conter floreio, redundância nem explicação decorativa.',
        '',
        '### SAÍDA OBRIGATÓRIA',
        'A resposta do Diretor deve seguir exatamente esta ordem:',
        '',
        '#### [DIAGNÓSTICO]',
        '- Descrever objetivamente:',
        '  - problema observado',
        '  - causa provável',
        '  - impacto',
        '  - risco técnico',
        '  - evidência visível que sustenta a leitura',
        '',
        '#### [DECISÃO / ESTRATÉGIA]',
        '- Definir a abordagem recomendada.',
        '- Explicar por que a estratégia escolhida é a menor necessária.',
        '- Registrar explicitamente o que não deve ser alterado.',
        '',
        '#### [INSTRUÇÕES PARA O EXECUTOR]',
        '- Entregar um prompt operacional copiável, pronto para execução.',
        '- O prompt deve exigir:',
        '  - relatório de impacto',
        '  - implementação explícita',
        '  - verificação objetiva',
        '  - preservação de contratos',
        '  - declaração de unknowns quando aplicável',
        '',
        '#### [CRITÉRIOS DE ACEITAÇÃO]',
        '- Informar condições objetivas para considerar a tarefa concluída com sucesso.',
        '',
        '#### [LIMITES / UNKNOWNS]',
        '- Listar explicitamente qualquer ponto não validável no recorte visível.',
        '- Sempre usar a formulação: `não visível no recorte enviado` quando aplicável.',
        '',
        '### FORMATO DE SAÍDA',
        '- Não implementar código.',
        '- Não entregar patch diff final como se fosse o Executor.',
        '- Não omitir seções obrigatórias.',
        '- Não esconder lacunas de contexto.',
        '- Não apresentar opinião subjetiva sem vínculo técnico com o artefato.',
        '- Não responder em formato ensaístico.',
        '- A resposta deve ser densa, técnica, objetiva, rastreável e copiável.',
        '',
        '### CRITÉRIOS DE REJEIÇÃO INTERNA',
        'A resposta do Diretor deve ser considerada inválida se:',
        '- inventar arquivo, contrato, fluxo ou comportamento não visível',
        '- pedir mudança arquitetural sem necessidade explícita',
        '- produzir análise genérica sem evidência',
        '- deixar de apontar unknowns quando houver lacuna',
        '- produzir prompt frouxo ou ambíguo para o Executor',
        '- misturar papel de Diretor com implementação de Executor',
        '- sugerir expansão de escopo para além do pedido visível'
    )

    $lines.AddRange([string[]]$directorProtocolLines)
    $lines.Add('') | Out-Null
    $lines.Add('## EXECUTION META') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add("- Projeto: $ProjectNameValue") | Out-Null
    $lines.Add("- Artefato fonte: $SourceArtifactFileName") | Out-Null
    $lines.Add("- Artefato final: $OutputArtifactFileName") | Out-Null
    $lines.Add("- Executor alvo: $ExecutorTargetValue") | Out-Null
    $lines.Add("- Route mode: $RouteMode") | Out-Null
    $lines.Add("- Document mode: $DocumentMode") | Out-Null
    $lines.Add("- Gerado em: $GeneratedAt") | Out-Null
    $lines.Add('') | Out-Null
    $executorTaskInstruction = Get-VibeExecutorTaskInstructionTemplate `
        -ProjectNameValue $ProjectNameValue `
        -SourceArtifactFileName $SourceArtifactFileName `
        -ExecutorTargetValue $ExecutorTargetValue `
        -ExtractionMode $ExtractionMode `
        -RelevantFilesValue $relevantFilesValue

    $lines.Add($executorTaskInstruction) | Out-Null

    return ($lines -join [Environment]::NewLine)
}

Export-ModuleMember -Function Get-VibeExtractionModeLabel, Get-VibeProtocolHeaderContent, Get-VibeDeterministicMetaPromptProtocolContent, Get-VibeExecutorTaskInstructionTemplate

#### File: .\modules\VibeExecutionFlow.psm1
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

#### File: .\modules\VibeFileDiscovery.psm1
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

#### File: .\modules\VibeSignatureExtractor.psm1
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

#### File: .\project-bundler-cli.ps1
# Política de runtime: PowerShell 7 preferencial; Windows PowerShell 5.1 como fallback operacional.

[CmdletBinding()]
param(
    [string]$Path = '.',
    [Alias('Mode')]
    [string]$BundleMode = '',
    [string[]]$SelectedPaths,
    [string]$RouteMode = '',
    [string]$ExecutorTarget = 'IA Generativa (GenAI)',
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:SentinelUtf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $script:SentinelUtf8NoBom
[Console]::OutputEncoding = $script:SentinelUtf8NoBom
$OutputEncoding = $script:SentinelUtf8NoBom

$env:PYTHONUTF8 = '1'

$script:SentinelPlainOutput = $false
try {
    $script:SentinelPlainOutput = [Console]::IsOutputRedirected
}
catch {
    $script:SentinelPlainOutput = $false
}

try {
    if ($PSStyle) {
        $PSStyle.OutputRendering = if ($script:SentinelPlainOutput) { 'PlainText' } else { 'Host' }
    }
}
catch {
}

$script:ToolkitDir = $PSScriptRoot
$script:OriginalWorkingDirectory = Get-Location
$script:CloneCleanupInfo = $null
$script:EffectiveOutputDirectory = $null

$ThemeText = 'Info'
$ThemeCyan = 'Info'
$ThemeSuccess = 'Success'
$ThemeWarn = 'Warning'
$ThemePink = 'Error'

function Get-SentinelLogLeafName {
    param([AllowEmptyString()][string]$PathValue = '')

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return ''
    }

    $normalizedPathValue = $PathValue.Trim().Trim('"')
    $normalizedPathValue = $normalizedPathValue.TrimEnd([char[]]@('\', '/'))

    if ([string]::IsNullOrWhiteSpace($normalizedPathValue)) {
        return ''
    }

    try {
        $leafName = [System.IO.Path]::GetFileName($normalizedPathValue)
        if (-not [string]::IsNullOrWhiteSpace($leafName)) {
            return $leafName
        }
    }
    catch {
    }

    return $normalizedPathValue
}

function Format-SentinelLogMessage {
    param([Parameter(Mandatory = $true)][string]$Message)

    $normalizedMessage = $Message.Trim() -replace '\s+', ' '
    if ([string]::IsNullOrWhiteSpace($normalizedMessage)) {
        return $normalizedMessage
    }

    if ($normalizedMessage -match '^Lendo (?<path>.+)$') {
        $pathValue = $Matches.path.Trim()
        $leafName = Get-SentinelLogLeafName -PathValue $pathValue
        if (-not [string]::IsNullOrWhiteSpace($leafName) -and $leafName -ne $pathValue) {
            return ('Lendo {0} · {1}' -f $leafName, $pathValue)
        }
    }

    if ($normalizedMessage -match '^Extraindo assinaturas de (?<path>.+)$') {
        $pathValue = $Matches.path.Trim()
        $leafName = Get-SentinelLogLeafName -PathValue $pathValue
        if (-not [string]::IsNullOrWhiteSpace($leafName) -and $leafName -ne $pathValue) {
            return ('Extraindo assinaturas de {0} · {1}' -f $leafName, $pathValue)
        }
    }

    if ($normalizedMessage -match '^(?<prefix>TXT gerado:|Artefato final TXT Export:|Staging interno removido:|Pasta de saída:|Arquivo ZIP:|Metadados locais salvos em:|Meta-prompt salvo em:|Clone temporário removido:|Diretório temporário automático:|Diretório manual informado:)\s*(?<path>.+)$') {
        $prefix = $Matches.prefix
        $pathValue = $Matches.path.Trim()
        $leafName = Get-SentinelLogLeafName -PathValue $pathValue
        if (-not [string]::IsNullOrWhiteSpace($leafName) -and $leafName -ne $pathValue) {
            return ('{0} {1} · {2}' -f $prefix, $leafName, $pathValue)
        }
    }

    if ($normalizedMessage -match '^Falha ao exportar TXT:\s*(?<path>.+?)\s*::\s*(?<reason>.+)$') {
        $pathValue = $Matches.path.Trim()
        $reasonValue = $Matches.reason.Trim()
        $leafName = Get-SentinelLogLeafName -PathValue $pathValue
        if (-not [string]::IsNullOrWhiteSpace($leafName)) {
            return ('Falha ao exportar TXT: {0} :: {1}' -f $leafName, $reasonValue)
        }
    }

    return ($normalizedMessage -replace "`n", " " -replace "`r", " ")
}

function Write-UILog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Color = $ThemeText
    )

    if ([string]::IsNullOrWhiteSpace($Message)) {
        return
    }

    $formattedMessage = Format-SentinelLogMessage -Message $Message
    $statusType = switch ($Color) {
        'Success' { 'Success' }
        'Warning' { 'Warning' }
        'Error' { 'Error' }
        default { 'Info' }
    }

    try {
        Write-SentinelStatus -Message $formattedMessage -Type $statusType
    }
    catch {
        [Console]::Out.WriteLine($formattedMessage)
    }
}

function Get-SentinelBundleModeTone {
    param([string]$BundleModeValue)

    switch ($BundleModeValue) {
        'full' { return 'Primary' }
        'blueprint' { return 'Success' }
        'sniper' { return 'Warning' }
        'txtExport' { return 'Secondary' }
        'txt_export' { return 'Secondary' }
        default { return 'Muted' }
    }
}

function Get-SentinelRouteModeTone {
    param([string]$RouteModeValue)

    switch ($RouteModeValue) {
        'director' { return 'Primary' }
        'executor' { return 'Success' }
        default { return 'Muted' }
    }
}

function Get-SentinelModeBadgeLines {
    param(
        [string]$BundleModeValue,
        [string]$RouteModeValue
    )

    $badges = New-Object System.Collections.Generic.List[string]
    $normalizedBundleMode = if ($BundleModeValue -eq 'txt_export') { 'TXT_EXPORT' } else { $BundleModeValue.ToUpperInvariant() }
    $normalizedRouteMode = $RouteModeValue.ToUpperInvariant()

    $badges.Add((Format-SentinelBadge -Label $normalizedBundleMode -Tone (Get-SentinelBundleModeTone -BundleModeValue $BundleModeValue))) | Out-Null
    $badges.Add((Format-SentinelBadge -Label $normalizedRouteMode -Tone (Get-SentinelRouteModeTone -RouteModeValue $RouteModeValue))) | Out-Null

    return @($badges)
}

function Write-SentinelOperationSummary {
    param(
        [string]$ProjectNameValue,
        [string]$BundleModeValue,
        [string]$RouteModeValue,
        [string]$ExecutorTargetValue,
        [string]$OriginValue = '',
        [int]$EligibleCount = -1,
        [int]$OperationCount = -1
    )

    Write-Host ''
    Write-SentinelBadgeLine -Badges (Get-SentinelModeBadgeLines -BundleModeValue $BundleModeValue -RouteModeValue $RouteModeValue)
    Write-Host ''

    $routeLabel = if ($RouteModeValue -eq 'executor') { 'Executor' } else { 'Diretor' }
    $extractionLabel = switch ($BundleModeValue) {
        'full' { 'Full' }
        'blueprint' { 'Blueprint' }
        'sniper' { 'Sniper' }
        'txtExport' { 'TXT Export' }
        'txt_export' { 'TXT Export' }
        default { $BundleModeValue }
    }

    $displayOrigin = if (-not [string]::IsNullOrWhiteSpace($OriginValue) -and $OriginValue -eq (Get-Location).Path) {
        "mesmo diretório ($ProjectNameValue)"
    }
    elseif (-not [string]::IsNullOrWhiteSpace($OriginValue)) {
        Get-SentinelCompactDisplayText -Text $OriginValue -MaxLength 60
    }
    else {
        ''
    }

    Write-SentinelText -Text '  📦 Projeto' -Color $SentinelTheme.Muted
    Write-SentinelKeyValue -Key 'Nome' -Value $ProjectNameValue -Tone 'Primary' -KeyWidth 14
    if (-not [string]::IsNullOrWhiteSpace($displayOrigin)) {
        Write-SentinelKeyValue -Key '📍 Origem' -Value $displayOrigin -Tone 'Primary' -KeyWidth 14
    }
    Write-Host ''

    Write-SentinelText -Text '  ⚙️  Execução' -Color $SentinelTheme.Muted
    Write-SentinelKeyValue -Key 'Extração' -Value $extractionLabel -Tone (Get-SentinelBundleModeTone -BundleModeValue $BundleModeValue) -KeyWidth 14
    Write-SentinelKeyValue -Key '🎯 Rota' -Value $routeLabel -Tone (Get-SentinelRouteModeTone -RouteModeValue $RouteModeValue) -KeyWidth 14
    Write-SentinelKeyValue -Key '🤖 Executor' -Value $ExecutorTargetValue -Tone 'Primary' -KeyWidth 14
    Write-Host ''

    if ($EligibleCount -ge 0) {
        Write-SentinelText -Text '  📄 Escopo' -Color $SentinelTheme.Muted
        Write-SentinelKeyValue -Key 'Elegíveis' -Value $EligibleCount -Tone 'Primary' -KeyWidth 14
        Write-SentinelKeyValue -Key 'Operação' -Value $(if ($OperationCount -ge 0) { $OperationCount } else { $EligibleCount }) -Tone 'Primary' -KeyWidth 14
        Write-Host ''
    }
}

function Get-SentinelExecutionModeLabel {
    param([string]$ChoiceValue)

    switch ($ChoiceValue) {
        '1' { return 'Full' }
        '2' { return 'Blueprint' }
        '3' { return 'Sniper' }
        '4' { return 'TXT Export' }
        default { return 'Execução' }
    }
}

function Write-SentinelExecutionStreamHeader {
    param(
        [string]$ChoiceValue,
        [string]$ProjectNameValue,
        [int]$DiscoveredFileCount,
        [int]$FilesToProcessCount,
        [int]$UnselectedFileCount,
        [string]$EffectiveOutputDirectory
    )

    $displayOutput = if ($EffectiveOutputDirectory -eq (Get-Location).Path) {
        "mesmo diretório ($ProjectNameValue)"
    }
    else {
        Get-SentinelCompactDisplayText -Text $EffectiveOutputDirectory -MaxLength 60
    }

    Write-SentinelKeyValue -Key '📁 Saída' -Value $displayOutput -Tone 'Secondary' -KeyWidth 14
    Write-SentinelKeyValue -Key 'Arquivos na fila' -Value $FilesToProcessCount -Tone 'Primary' -KeyWidth 16

    if ($UnselectedFileCount -gt 0) {
        Write-SentinelKeyValue -Key 'Fora do recorte' -Value $UnselectedFileCount -Tone 'Warning' -KeyWidth 16
    }

    Write-SentinelDivider -Tone 'Muted'
    Write-Host ''
}

function Get-SentinelSourceModeDisplay {
    param([string]$SourceModeValue)

    switch ($SourceModeValue) {
        'github' { return 'Repositório GitHub' }
        default { return 'Path local' }
    }
}

function New-SentinelMenuOptionLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [AllowEmptyString()][string]$Description = '',
        [int]$LabelWidth = 18
    )

    $safeLabel = ($Label -replace '\s+', ' ').Trim()
    $safeDescription = ($Description -replace '\s+', ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($safeDescription)) {
        return $safeLabel
    }

    return ('{0} {1}' -f $safeLabel.PadRight([Math]::Max($LabelWidth, 8)), $safeDescription)
}

function Write-SentinelHintLines {
    param([string[]]$Lines)

    $normalizedLines = @($Lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($normalizedLines.Count -eq 0) {
        return
    }

    foreach ($line in $normalizedLines) {
        Write-SentinelText -Text ("  {0}" -f $line.Trim()) -Color $SentinelTheme.Muted
    }

    Write-Host ''
}

function Write-SentinelInvalidSelection {
    param([Parameter(Mandatory = $true)][string]$Expected)

    Write-SentinelStatus -Message ("Opção inválida. Use {0}. Ctrl+C cancela." -f $Expected) -Type 'Warning'
}

function Get-SentinelBundleModeHintLines {
    return @(
        'Full lê tudo. Blueprint prioriza estrutura e contratos. Sniper abre recorte manual.',
        'TXT Export gera ZIP textual. Digite 1-4 ou Ctrl+C para cancelar.'
    )
}

function Get-SentinelRouteModeHintLines {
    return @(
        'Director compila meta-prompt local. Executor entrega o artefato final direto.',
        'Enter mantém Director. Digite 1-2 ou Ctrl+C para cancelar.'
    )
}

function Get-SentinelSourceModeHintLines {
    return @(
        'Path atual usa o diretório informado. Clonar GitHub baixa uma cópia local para leitura.',
        'Digite 1-2 ou Ctrl+C para cancelar.'
    )
}

function Write-SentinelPostSuccessGuidance {
    param(
        [Parameter(Mandatory = $true)][string]$RouteMode,
        [Parameter(Mandatory = $true)][string]$ArtifactPath,
        [Parameter(Mandatory = $true)][string]$MetadataPath
    )

    $artifactLeaf = [System.IO.Path]::GetFileName($ArtifactPath)
    $metadataLeaf = [System.IO.Path]::GetFileName($MetadataPath)

    Write-SentinelDivider -Label '' -Tone 'Secondary' -Character '━' -Width 70
    Write-SentinelText -Text '  💡 PRÓXIMO PASSO' -Color $SentinelTheme.Secondary
    Write-Host ''

    if ($RouteMode -eq 'executor') {
        $artifactLine = Format-SentinelFitLine -Text ("• {0} é o contexto operacional final — pronto para execução direta." -f $artifactLeaf) -Indent 2
        Write-SentinelText -Text ("  " + $artifactLine) -Color $SentinelTheme.Secondary
        $execLine = Format-SentinelFitLine -Text "• Envie diretamente para a IA executora — nenhum meta-prompt adicional necessário." -Indent 2
        Write-SentinelText -Text ("  " + $execLine) -Color $SentinelTheme.Secondary
    }
    else {
        $artifactLine = Format-SentinelFitLine -Text ("• {0} é um meta-prompt determinístico local — copie o conteúdo." -f $artifactLeaf) -Indent 2
        Write-SentinelText -Text ("  " + $artifactLine) -Color $SentinelTheme.Secondary
        $execLine = Format-SentinelFitLine -Text "• Cole no ChatGPT, Claude ou Gemini para gerar artefatos baseados no blueprint." -Indent 2
        Write-SentinelText -Text ("  " + $execLine) -Color $SentinelTheme.Secondary
    }

    $metaLine = Format-SentinelFitLine -Text ("• {0} guarda auditoria e metadados para automação." -f $metadataLeaf) -Indent 2
    Write-SentinelText -Text ("  " + $metaLine) -Color $SentinelTheme.Muted
    Write-Host ''
}

function Write-SentinelConfigurationContext {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$StepLabel = '',
        [AllowEmptyString()][string]$ProjectNameValue = '',
        [AllowEmptyString()][string]$OriginValue = '',
        [AllowEmptyString()][string]$SourceModeValue = '',
        [AllowEmptyString()][string]$BundleModeValue = '',
        [AllowEmptyString()][string]$RouteModeValue = '',
        [AllowEmptyString()][string]$ExecutorTargetValue = ''
    )

    $hasContext = $false

    if (-not [string]::IsNullOrWhiteSpace($StepLabel)) {
        Write-SentinelBadgeLine -Badges @((Format-SentinelBadge -Label $StepLabel -Tone 'Secondary'))
        $hasContext = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($ProjectNameValue)) {
        Write-SentinelKeyValue -Key 'Projeto' -Value $ProjectNameValue -Tone 'Primary'
        $hasContext = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($OriginValue)) {
        Write-SentinelKeyValue -Key 'Origem' -Value $OriginValue -Tone 'Primary'
        $hasContext = $true
    }
    elseif (-not [string]::IsNullOrWhiteSpace($SourceModeValue)) {
        Write-SentinelKeyValue -Key 'Origem' -Value (Get-SentinelSourceModeDisplay -SourceModeValue $SourceModeValue) -Tone 'Primary'
        $hasContext = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($BundleModeValue)) {
        Write-SentinelKeyValue -Key 'Extração' -Value $BundleModeValue -Tone (Get-SentinelBundleModeTone -BundleModeValue $BundleModeValue)
        $hasContext = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($RouteModeValue)) {
        $routeLabel = if ($RouteModeValue -eq 'executor') { 'Executor' } else { 'Diretor' }
        Write-SentinelKeyValue -Key 'Rota' -Value $routeLabel -Tone (Get-SentinelRouteModeTone -RouteModeValue $RouteModeValue)
        $hasContext = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($ExecutorTargetValue)) {
        Write-SentinelKeyValue -Key 'Executor' -Value $ExecutorTargetValue -Tone 'Primary'
        $hasContext = $true
    }

    if ($hasContext) {
        Write-Host ''
    }
}

function Get-SentinelUiRequiredFunctionNames {
    return @(
        'Write-SentinelHeader',
        'Write-SentinelStatus',
        'Write-SentinelDivider',
        'Write-SentinelSection',
        'Write-SentinelPanel',
        'Write-SentinelKeyValue',
        'Write-SentinelMenuOptions',
        'Write-SentinelProgress',
        'Format-SentinelBadge',
        'Write-SentinelBadgeLine'
    )
}

function Get-SentinelUiBootstrapFailureSummary {
    param(
        [Parameter(Mandatory = $true)]
        $ErrorRecord
    )

    $fragments = New-Object System.Collections.Generic.List[string]

    if ($null -ne $ErrorRecord.Exception) {
        if (-not [string]::IsNullOrWhiteSpace($ErrorRecord.Exception.Message)) {
            $fragments.Add([string]$ErrorRecord.Exception.Message) | Out-Null
        }

        if ($null -ne $ErrorRecord.Exception.InnerException -and -not [string]::IsNullOrWhiteSpace($ErrorRecord.Exception.InnerException.Message)) {
            $fragments.Add([string]$ErrorRecord.Exception.InnerException.Message) | Out-Null
        }

        $fragments.Add($ErrorRecord.Exception.GetType().FullName) | Out-Null
    }

    if ($ErrorRecord.FullyQualifiedErrorId) {
        $fragments.Add([string]$ErrorRecord.FullyQualifiedErrorId) | Out-Null
    }

    if ($ErrorRecord.CategoryInfo -and $ErrorRecord.CategoryInfo.Reason) {
        $fragments.Add([string]$ErrorRecord.CategoryInfo.Reason) | Out-Null
    }

    $summary = (($fragments | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ' | ').Trim()

    if ([string]::IsNullOrWhiteSpace($summary)) {
        $summary = ([string]$ErrorRecord).Trim()
    }

    $summary = $summary -replace '\s+', ' '

    if ($summary.Length -gt 500) {
        $summary = $summary.Substring(0, 500) + '...'
    }

    return $summary
}

function Test-IsSentinelUiPolicyBlockedError {
    param(
        [Parameter(Mandatory = $true)]
        $ErrorRecord
    )

    $summary = Get-SentinelUiBootstrapFailureSummary -ErrorRecord $ErrorRecord

    return (
        $summary -match '(?i)not digitally signed' -or
        $summary -match '(?i)cannot be loaded because running scripts is disabled' -or
        $summary -match '(?i)authorizationmanager check failed' -or
        $summary -match '(?i)execution policy' -or
        $summary -match '(?i)PSSecurityException'
    )
}

function Register-SentinelCliFallback {
    $getFallbackDividerContent = {
        param(
            [AllowEmptyString()][string]$Label = '',
            [int]$Width = 34,
            [string]$Character = '='
        )

        $safeWidth = [Math]::Max($Width, 8)
        $dividerChar = if ([string]::IsNullOrEmpty($Character)) { '=' } else { $Character.Substring(0, 1) }

        if ([string]::IsNullOrWhiteSpace($Label)) {
            return ($dividerChar * $safeWidth)
        }

        $normalizedLabel = ($Label -replace '\s+', ' ').Trim()
        if ([string]::IsNullOrWhiteSpace($normalizedLabel)) {
            return ($dividerChar * $safeWidth)
        }

        $minimumSideWidth = 2
        $labelPaddingWidth = 2
        $maxLabelLength = $safeWidth - (($minimumSideWidth * 2) + $labelPaddingWidth)

        if ($maxLabelLength -le 0) {
            return ($dividerChar * $safeWidth)
        }

        if ($normalizedLabel.Length -gt $maxLabelLength) {
            if ($maxLabelLength -eq 1) {
                $normalizedLabel = '.'
            }
            elseif ($maxLabelLength -eq 2) {
                $normalizedLabel = '..'
            }
            else {
                $normalizedLabel = $normalizedLabel.Substring(0, $maxLabelLength - 3) + '...'
            }
        }

        $framedLabel = " $normalizedLabel "
        $remaining = $safeWidth - $framedLabel.Length

        if ($remaining -lt ($minimumSideWidth * 2)) {
            return ($dividerChar * $safeWidth)
        }

        $leftWidth = [int][Math]::Floor($remaining / 2)
        $rightWidth = $remaining - $leftWidth

        if ($leftWidth -lt $minimumSideWidth) {
            $leftWidth = $minimumSideWidth
            $rightWidth = $remaining - $leftWidth
        }

        if ($rightWidth -lt $minimumSideWidth) {
            $rightWidth = $minimumSideWidth
            $leftWidth = $remaining - $rightWidth
        }

        return ('{0}{1}{2}' -f ($dividerChar * $leftWidth), $framedLabel, ($dividerChar * $rightWidth))
    }

    $writeSentinelText = {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Text,
            [string]$Color = ''
        )

        Write-Host $Text
    }

    $writeSentinelStatus = {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message,

            [ValidateSet('Success', 'Info', 'Warning', 'Error')]
            [string]$Type = 'Info'
        )

        $prefix = switch ($Type) {
            'Success' { '[+]' }
            'Warning' { '[!]' }
            'Error' { '[x]' }
            default { '[>]' }
        }

        Write-Host ("  {0} {1}" -f $prefix, $Message)
    }

    $writeSentinelDivider = {
        param(
            [string]$Label,
            [string]$Tone = 'Secondary',
            [int]$Width = 34,
            [string]$Character = '='
        )

        $safeWidth = [Math]::Max($Width, 8)
        $dividerChar = if ([string]::IsNullOrEmpty($Character)) { '=' } else { $Character.Substring(0, 1) }

        if ([string]::IsNullOrWhiteSpace($Label)) {
            Write-Host ("  {0}" -f ($dividerChar * $safeWidth))
            return
        }

        $normalizedLabel = ($Label -replace '\s+', ' ').Trim()
        if ([string]::IsNullOrWhiteSpace($normalizedLabel)) {
            Write-Host ("  {0}" -f ($dividerChar * $safeWidth))
            return
        }

        $minimumSideWidth = 2
        $labelPaddingWidth = 2
        $maxLabelLength = $safeWidth - (($minimumSideWidth * 2) + $labelPaddingWidth)

        if ($maxLabelLength -le 0) {
            Write-Host ("  {0}" -f ($dividerChar * $safeWidth))
            return
        }

        if ($normalizedLabel.Length -gt $maxLabelLength) {
            if ($maxLabelLength -eq 1) {
                $normalizedLabel = '.'
            }
            elseif ($maxLabelLength -eq 2) {
                $normalizedLabel = '..'
            }
            else {
                $normalizedLabel = $normalizedLabel.Substring(0, $maxLabelLength - 3) + '...'
            }
        }

        $framedLabel = " $normalizedLabel "
        $remaining = $safeWidth - $framedLabel.Length

        if ($remaining -lt ($minimumSideWidth * 2)) {
            Write-Host ("  {0}" -f ($dividerChar * $safeWidth))
            return
        }

        $leftWidth = [int][Math]::Floor($remaining / 2)
        $rightWidth = $remaining - $leftWidth

        if ($leftWidth -lt $minimumSideWidth) {
            $leftWidth = $minimumSideWidth
            $rightWidth = $remaining - $leftWidth
        }

        if ($rightWidth -lt $minimumSideWidth) {
            $rightWidth = $minimumSideWidth
            $leftWidth = $remaining - $rightWidth
        }

        Write-Host ("  {0}" -f ('{0}{1}{2}' -f ($dividerChar * $leftWidth), $framedLabel, ($dividerChar * $rightWidth)))
    }

    $writeSentinelHeader = {
        param(
            [string]$Title = 'SENTINEL',
            [string]$Version = 'v1.0.0',
            [ValidateSet('Hero', 'Compact', 'Minimal')]
            [string]$Variant = 'Hero'
        )

        switch ($Variant) {
            'Minimal' {
                Write-Host ("  {0} · {1}" -f $Title, $Version)
                Write-Host ''
                return
            }
            'Compact' {
                & $writeSentinelDivider -Label $Title -Tone 'Primary'
                Write-Host ("  {0}" -f $Version)
                Write-Host ''
                return
            }
            default {
                & $writeSentinelDivider -Tone 'Secondary'
                Write-Host ("  {0} · {1}" -f $Title, $Version)
                & $writeSentinelDivider -Tone 'Secondary'
                Write-Host ''
            }
        }
    }

    $writeSentinelSection = {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Title,
            [string]$Subtitle,
            [string]$Tone = 'Primary'
        )

        Write-Host ''
        & $writeSentinelDivider -Label $Title -Tone $Tone
        if (-not [string]::IsNullOrWhiteSpace($Subtitle)) {
            Write-Host ("  {0}" -f $Subtitle)
        }
        Write-Host ''
    }

    $writeSentinelPanel = {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Title,
            [string[]]$Lines,
            [string]$Tone = 'Secondary'
        )

        Write-Host ("  {0}" -f $Title)
        foreach ($line in @($Lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
            Write-Host ("    {0}" -f $line)
        }
        Write-Host ''
    }

    $writeSentinelKeyValue = {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Key,
            [AllowEmptyString()][string]$Value = '',
            [int]$KeyWidth = 18,
            [string]$Tone = 'Primary'
        )

        $paddedKey = $Key.PadRight([Math]::Max($KeyWidth, 8))
        Write-Host ("  {0}: {1}" -f $paddedKey, $Value)
    }

    $writeSentinelMenuOptions = {
        param(
            [Parameter(Mandatory = $true)]
            [string[]]$Options
        )

        for ($index = 0; $index -lt $Options.Count; $index++) {
            Write-Host ("    [{0}] {1}" -f ($index + 1), $Options[$index])
        }
        Write-Host ''
    }

    $writeSentinelProgress = {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Activity,
            [int]$Current = 0,
            [int]$Total = 0,
            [string]$Tone = 'Primary',
            [string]$Item = ''
        )

        $windowWidth = 80
        try { $windowWidth = [Math]::Max([Console]::WindowWidth, 60) } catch {}

        if ($Total -le 0) {
            $line = "  > {0}" -f $Activity
            Write-Host ("`r{0}" -f $line.PadRight($windowWidth - 1)) -NoNewline
            return
        }

        $safeCurrent = [Math]::Min([Math]::Max($Current, 0), $Total)
        $barWidth = 14
        $ratio = if ($Total -eq 0) { 0 } else { [double]$safeCurrent / [double]$Total }
        $filled = [int][Math]::Round(($ratio * $barWidth), 0, [System.MidpointRounding]::AwayFromZero)
        $filled = [Math]::Min([Math]::Max($filled, 0), $barWidth)
        $empty = $barWidth - $filled
        $bar = ('#' * $filled) + ('-' * $empty)
        $percent = [int][Math]::Round(($ratio * 100), 0, [System.MidpointRounding]::AwayFromZero)

        $progressText = "[{0}] {1,3}% ({2}/{3})" -f $bar, $percent, $safeCurrent, $Total
        $fixedLength = 4 + $Activity.Length + 1 + $progressText.Length
        $availableForItem = $windowWidth - $fixedLength - 5
        
        $displayItem = ''
        if (-not [string]::IsNullOrWhiteSpace($Item) -and $availableForItem -gt 5) {
            $displayItem = if ($Item.Length -le $availableForItem) { $Item } else { '...' + $Item.Substring($Item.Length - ($availableForItem - 3)) }
            $displayItem = " " + $displayItem
        }

        $line = "  > {0} {1}{2}" -f $Activity, $progressText, $displayItem
        Write-Host ("`r{0}" -f $line.PadRight($windowWidth - 1)) -NoNewline
    }

    $formatSentinelBadge = {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Label,
            [string]$Tone = 'Primary'
        )

        return ('[{0}]' -f (($Label -replace '\s+', ' ').Trim().ToUpperInvariant()))
    }

    $writeSentinelBadgeLine = {
        param([string[]]$Badges)

        $normalizedBadges = @($Badges | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($normalizedBadges.Count -gt 0) {
            Write-Host ("  {0}" -f ($normalizedBadges -join ' '))
        }
    }

    Set-Item -Path Function:\script:Write-SentinelText -Value $writeSentinelText.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelStatus -Value $writeSentinelStatus.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelDivider -Value $writeSentinelDivider.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelHeader -Value $writeSentinelHeader.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelSection -Value $writeSentinelSection.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelPanel -Value $writeSentinelPanel.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelKeyValue -Value $writeSentinelKeyValue.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelMenuOptions -Value $writeSentinelMenuOptions.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelProgress -Value $writeSentinelProgress.GetNewClosure() -Force
    Set-Item -Path Function:\script:Format-SentinelBadge -Value $formatSentinelBadge.GetNewClosure() -Force
    Set-Item -Path Function:\script:Write-SentinelBadgeLine -Value $writeSentinelBadgeLine.GetNewClosure() -Force
}

function Assert-SentinelUiBootstrapContract {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SentinelUiPath,
        [switch]$FallbackActive
    )

    $requiredFunctions = @(Get-SentinelUiRequiredFunctionNames)
    $missingFunctions = New-Object System.Collections.Generic.List[string]

    foreach ($requiredFunction in $requiredFunctions) {
        $command = Get-Command -Name $requiredFunction -ErrorAction SilentlyContinue
        if ($null -eq $command -or $command.CommandType -ne 'Function') {
            $missingFunctions.Add($requiredFunction) | Out-Null
        }
    }

    if ($missingFunctions.Count -gt 0) {
        $bootstrapMode = if ($FallbackActive) { 'fallback local' } else { 'SentinelUI carregado' }
        throw "Contrato mínimo de UI indisponível após bootstrap ($bootstrapMode) para '$SentinelUiPath'. Funções ausentes: $($missingFunctions -join ', ')."
    }
}

function Test-IsGeneratedArtifactFileName {
    param([string]$FileName)

    if ([string]::IsNullOrWhiteSpace($FileName)) {
        return $false
    }

    if (Test-VibeGeneratedArtifactFileName -FileName $FileName) {
        return $true
    }

    $patterns = @(
        '^_(?:bundle|blueprint|manual|txt_export)_(?:diretor|executor)(?:_[A-Za-z0-9\-]+)?__.*\.(?:md|json)$',
        '^_meta-prompt_(?:bundle|blueprint|manual)_(?:diretor|executor)(?:_[A-Za-z0-9\-]+)?__.*\.(?:md|json)$',
        '^_txt_export_(?:diretor|executor)(?:_[A-Za-z0-9\-]+)?__.*\.zip$',
        '^_TXT_EXPORT__',
        '^_TXT_EXPORT__.*\.zip$'
    )

    foreach ($pattern in $patterns) {
        if ($FileName -match $pattern) {
            return $true
        }
    }

    return $false
}

function Get-RelevantFiles {
    param([string]$CurrentPath)

    $files = Get-VibeRelevantFiles -CurrentPath $CurrentPath -AllowedExtensions $script:AllowedExtensions -IgnoredDirs $script:IgnoredDirs -IgnoredFiles $script:IgnoredFiles
    return @($files | Where-Object { -not (Test-IsGeneratedArtifactFileName -FileName $_.Name) })
}

function Read-LocalTextArtifact {
    param([string]$Path)

    return (Read-VibeTextFile -Path $Path)
}

function Write-LocalTextArtifact {
    param(
        [string]$Path,
        [AllowEmptyString()][string]$Content,
        [switch]$UseBom
    )

    Write-VibeTextFile -Path $Path -Content $Content -UseBom:$UseBom
}

function Convert-ToSafeMarkdownCodeBlock {
    param(
        [AllowNull()][string]$Content,
        [string]$Language = '',
        [string]$FenceChar = '`'
    )

    return (ConvertTo-VibeSafeMarkdownCodeBlock -Content $Content -Language $Language -FenceChar $FenceChar)
}

function Get-CodeFenceLanguageFromExtension {
    param([string]$Extension)

    return (Get-VibeCodeFenceLanguageFromExtension -Extension $Extension)
}

function Get-BundlerSignaturesForFile {
    param([System.IO.FileInfo]$File, [ref]$IssueMessage)

    return @(Get-VibeBundlerSignaturesForFile -File $File -IssueMessage $IssueMessage)
}

function Get-NormalizedRelativeProjectPath {
    param([System.IO.FileInfo]$File)

    if ($null -eq $File) {
        return $null
    }

    $relPath = Resolve-Path -Path $File.FullName -Relative
    if ([string]::IsNullOrWhiteSpace($relPath)) {
        return $relPath
    }

    return ($relPath -replace '/', '\')
}

function Get-ProjectStructureTree {
    param(
        [System.IO.FileInfo[]]$Files,
        [string]$ProjectRootPath = (Get-Location).Path,
        [string]$ProjectName = (Get-Item $ProjectRootPath).Name
    )

    return (Get-VibeProjectStructureTree -Files $Files -ProjectRootPath $ProjectRootPath -ProjectName $ProjectName)
}

function Test-BlueprintPeripheralFile {
    param([string]$LeafName)

    if ([string]::IsNullOrWhiteSpace($LeafName)) {
        return $true
    }

    if ($LeafName -match '(?i)\.(test|spec|stories|story|mock|stub|fake|fixture|bench|snapshot)\b') {
        return $true
    }

    if ($LeafName -match '(?i)^(test_|spec_|__test|__spec|__mock)') {
        return $true
    }

    if ($LeafName -match '(?i)\.(module\.css|module\.scss|styles|styled|theme|animation)\b') {
        return $true
    }

    if ($LeafName -match '(?i)^(migration|seed|fixture|changelog|license)') {
        return $true
    }

    if ($LeafName -match '(?i)\.(generated|auto|g|designer)\.[^.]+$') {
        return $true
    }

    return $false
}

function Get-BlueprintContractBucket {
    param([System.IO.FileInfo]$File)

    if ($null -eq $File) {
        return $null
    }

    if ($script:SignatureExtensions -notcontains $File.Extension) {
        return $null
    }

    $relPath = (Get-NormalizedRelativeProjectPath -File $File).ToLowerInvariant()
    $leafName = $File.Name.ToLowerInvariant()
    $baseName = $File.BaseName.ToLowerInvariant()

    if ($File.Extension -in @('.cmd', '.bat', '.reg', '.vbs', '.ps1xml')) {
        return $null
    }

    if (Test-BlueprintPeripheralFile -LeafName $leafName) {
        return $null
    }

    # --- VibeToolkit-specific rules (preserved) ---

    if ($relPath -match '^\.\\project-bundler(?:-headless)?\.ps1$') {
        return 'ENTRYPOINTS & ORCHESTRATION'
    }

    if ($relPath -match '^\.\\modules\\.*protocol.*\.psm1$') {
        return 'PROTOCOLS & OPERATING RULES'
    }

    if ($relPath -match '^\.\\modules\\.*(discovery|writer|extractor).*\.psm1$') {
        return 'DISCOVERY, WRITERS & EXTRACTORS'
    }

    if ($relPath -match '^\.\\modules\\.*(bundle|artifact|context|execution|route|naming).*\.psm1$') {
        return 'CORE MODULES'
    }

    if ($relPath -match '^\.\\modules\\.*\.psm1$' -and $leafName -notmatch '^(sentinelui|sentineltheme|sentinelclonehelpers)\.psm1$') {
        return 'CORE MODULES'
    }

    # --- Generic entrypoints & roots (stack-agnostic) ---

    if ($relPath -match '^\.\\(?:main|index|app|server|program|startup|host|root|bootstrap|entrypoint)\.(?:ts|tsx|js|jsx|mjs|py|go|rs|cs|java|kt|php|rb|ex|swift|dart|scala)$') {
        return 'APPLICATION ENTRYPOINTS'
    }

    if ($relPath -match '^\.\\(?:src|app|server|api|lib|core)\\(?:main|index|app|server|program|startup|host|root|bootstrap|entrypoint)\.[^.]+$') {
        return 'APPLICATION ENTRYPOINTS'
    }

    # --- Contracts, types, schemas, DTOs, enums, protocols (stack-agnostic) ---

    if ($baseName -match '(?:^|[._-])(?:types|interfaces|contracts|schemas|models|dtos|entities|enums|protocols|events|constants|definitions|declarations)(?:$|[._-])') {
        return 'CONTRACTS & TYPES'
    }

    if ($relPath -match '[\\/](?:types|interfaces|contracts|schemas|models|dtos|entities|enums|protocols|events|definitions)[\\/]') {
        return 'CONTRACTS & TYPES'
    }

    if ($leafName -match '(?i)\.d\.ts$') {
        return 'CONTRACTS & TYPES'
    }

    # --- Integrations & boundaries (stack-agnostic) ---

    if ($baseName -match '(?:^|[._-])(?:client|service|provider|gateway|repository|adapter|transport|connector|proxy|driver|api[._-]?client|http[._-]?client|grpc[._-]?client)(?:$|[._-])') {
        return 'INTEGRATIONS & BOUNDARIES'
    }

    if ($baseName -match '(?:^|[._-])(?:auth|storage|database|cache|queue|messaging|notification|email|payment|search)[._-]?(?:service|client|provider|gateway|repository|adapter|boundary)(?:$|[._-])') {
        return 'INTEGRATIONS & BOUNDARIES'
    }

    if ($relPath -match '[\\/](?:services|providers|gateways|repositories|adapters|clients|infrastructure|integrations|boundaries)[\\/]') {
        return 'INTEGRATIONS & BOUNDARIES'
    }

    # --- Flow orchestrators (stack-agnostic) ---

    if ($baseName -match '(?:^|[._-])(?:store|state|context|session|middleware|pipeline|runtime|orchestrat|coordinat|dispatcher|controller|handler|resolver|interceptor|guard|router|routes|navigation|bus|queue|worker|scheduler|registry|factory|container|injector|compositor|manager|engine)(?:$|[._-])') {
        return 'FLOW ORCHESTRATORS'
    }

    if ($relPath -match '[\\/](?:stores|state|middleware|controllers|handlers|resolvers|interceptors|guards|routes|routing|orchestration|coordination|dispatchers|pipelines|workers|schedulers)[\\/]') {
        return 'FLOW ORCHESTRATORS'
    }

    # --- Domain core modules (position-based, stack-agnostic) ---

    if ($relPath -match '^\.\\(?:src|app|lib|core|pkg|internal|domain)\\[^\\/]+\.(?:ts|tsx|js|jsx|mjs|py|go|rs|cs|java|kt|php|rb|ex|swift|dart|scala|psm1|ps1)$') {
        if ($baseName -notmatch '(?:^|[._-])(?:utils?|helpers?|tools|common|shared|misc|log|logger|debug|polyfill|shim|patch|compat|i18n|locale|env|setup|teardown|init|cleanup)(?:$|[._-])') {
            return 'DOMAIN CORE'
        }
    }

    return $null
}

function Get-BlueprintContractEntries {
    param([System.IO.FileInfo[]]$Files)

    if ($null -eq $Files -or $Files.Count -eq 0) {
        return @()
    }

    $bucketOrder = @{
        'ENTRYPOINTS & ORCHESTRATION'     = 0
        'APPLICATION ENTRYPOINTS'         = 1
        'PROTOCOLS & OPERATING RULES'     = 2
        'CONTRACTS & TYPES'               = 3
        'INTEGRATIONS & BOUNDARIES'       = 4
        'FLOW ORCHESTRATORS'              = 5
        'DISCOVERY, WRITERS & EXTRACTORS' = 6
        'CORE MODULES'                    = 7
        'DOMAIN CORE'                     = 8
    }

    $bucketCap = @{
        'APPLICATION ENTRYPOINTS'   = 6
        'CONTRACTS & TYPES'         = 8
        'INTEGRATIONS & BOUNDARIES' = 8
        'FLOW ORCHESTRATORS'        = 6
        'DOMAIN CORE'               = 6
    }

    $entries = New-Object System.Collections.Generic.List[object]

    foreach ($file in $Files) {
        $bucket = Get-BlueprintContractBucket -File $file
        if ([string]::IsNullOrWhiteSpace($bucket)) {
            continue
        }

        $relPath = Get-NormalizedRelativeProjectPath -File $file
        $order = if ($bucketOrder.ContainsKey($bucket)) { $bucketOrder[$bucket] } else { 999 }

        $entries.Add([pscustomobject]@{
                File         = $file
                RelativePath = $relPath
                Bucket       = $bucket
                BucketOrder  = $order
            }) | Out-Null
    }

    $sorted = @($entries | Sort-Object BucketOrder, RelativePath -Unique)

    $bucketCounts = @{}
    $result = @($sorted | Where-Object {
            $b = $_.Bucket
            if (-not $bucketCounts.ContainsKey($b)) {
                $bucketCounts[$b] = 0
            }
            $cap = if ($bucketCap.ContainsKey($b)) { $bucketCap[$b] } else { 999 }
            if ($bucketCounts[$b] -lt $cap) {
                $bucketCounts[$b]++
                $true
            }
            else {
                $false
            }
        })

    return $result
}

function New-BlueprintContractsBlock {
    param(
        [System.IO.FileInfo[]]$Files,
        [ref]$IssueCollector,
        [string]$StructureHeading,
        [string]$ContractsHeading,
        [switch]$LogExtraction
    )

    if ($null -eq $Files -or $Files.Count -eq 0) {
        return ''
    }

    $projectRootPath = (Get-Location).Path
    $projectName = (Get-Item $projectRootPath).Name
    $projectStructureTree = Get-ProjectStructureTree -Files $Files -ProjectRootPath $projectRootPath -ProjectName $projectName

    $block = "${StructureHeading}`n"
    $block += (Convert-ToSafeMarkdownCodeBlock -Content $projectStructureTree -Language 'text')
    $block += "`n`n"
    $block += "${ContractsHeading}`n"
    $block += "> Cobertura abrangente de superfícies estruturais. Todos os arquivos elegíveis do escopo visível que possuem assinaturas extraíveis (contratos, headers, exports, tipos) estão mapeados abaixo. O blueprint preserva contexto mantendo a economia ao focar exclusivamente na extração estrutural, omitindo implementação completa.`n`n"
    
    $hasContracts = $false
    
    $processedCount = 0
    foreach ($file in $Files) {
        $processedCount++
        if ($script:SignatureExtensions -notcontains $file.Extension) {
            continue
        }
        
        $relPath = Get-NormalizedRelativeProjectPath -File $file
        
        if ($LogExtraction) {
            Write-SentinelProgress -Activity 'Extraindo assinaturas estruturais' -Current $processedCount -Total $Files.Count -Tone 'Secondary' -Item $relPath
        }
        
        $issueMessage = $null
        $signatures = @(Get-BundlerSignaturesForFile -File $file -IssueMessage ([ref]$issueMessage))
        if ($issueMessage) {
            if ($IssueCollector) {
                $IssueCollector.Value += $issueMessage
            }
            continue
        }
        
        if ($signatures.Count -le 0) {
            continue
        }
        
        $hasContracts = $true
        $fenceLanguage = Get-CodeFenceLanguageFromExtension -Extension $file.Extension
        $signatureContent = ($signatures -join '')
        $block += "#### File: $relPath`n"
        $block += (Convert-ToSafeMarkdownCodeBlock -Content $signatureContent -Language $fenceLanguage)
        $block += "`n`n"
    }

    if (-not $hasContracts) {
        $block += "_Nenhuma assinatura ou contrato central foi identificado no recorte visível._`n`n"
    }

    if ($LogExtraction) { Write-Host "" }

    return $block
}

function New-BundlerContractsBlock {
    param(
        [System.IO.FileInfo[]]$Files,
        [ref]$IssueCollector,
        [string]$StructureHeading,
        [string]$ContractsHeading,
        [switch]$LogExtraction
    )

    if ($null -eq $Files -or $Files.Count -eq 0) {
        return ''
    }

    $projectRootPath = (Get-Location).Path
    $projectName = (Get-Item $projectRootPath).Name
    $projectStructureTree = Get-ProjectStructureTree -Files $Files -ProjectRootPath $projectRootPath -ProjectName $projectName

    $block = "${StructureHeading}`n"
    $block += (Convert-ToSafeMarkdownCodeBlock -Content $projectStructureTree -Language 'text')
    $block += "`n`n"
    $block += "${ContractsHeading}`n"

    $processedCount = 0
    foreach ($file in $Files) {
        $processedCount++
        if ($script:SignatureExtensions -notcontains $file.Extension) {
            continue
        }

        $relPath = Resolve-Path -Path $file.FullName -Relative
        if ($LogExtraction) {
            Write-SentinelProgress -Activity 'Extraindo assinaturas' -Current $processedCount -Total $Files.Count -Tone 'Secondary' -Item $relPath
        }

        $issueMessage = $null
        $signatures = @(Get-BundlerSignaturesForFile -File $file -IssueMessage ([ref]$issueMessage))
        if ($issueMessage) {
            if ($IssueCollector) {
                $IssueCollector.Value += $issueMessage
            }
            continue
        }

        if ($signatures.Count -le 0) {
            continue
        }

        $fenceLanguage = Get-CodeFenceLanguageFromExtension -Extension $file.Extension
        $signatureContent = ($signatures -join '')
        $block += "#### File: $relPath`n"
        $block += (Convert-ToSafeMarkdownCodeBlock -Content $signatureContent -Language $fenceLanguage)
        $block += "`n`n"
    }

    if ($LogExtraction) { Write-Host "" }

    return $block
}

function Resolve-ChoiceFromBundleMode {
    param([string]$ModeValue)

    switch ($ModeValue) {
        'full' { return '1' }
        'blueprint' { return '2' }
        'sniper' { return '3' }
        'txtExport' { return '4' }
        default { throw "Modo inválido: $ModeValue" }
    }
}

function Resolve-ExtractionModeFromBundleMode {
    param([string]$ModeValue)

    switch ($ModeValue) {
        'full' { return 'full' }
        'blueprint' { return 'blueprint' }
        'sniper' { return 'sniper' }
        'txtExport' { return 'txt_export' }
        default { return 'full' }
    }
}

function Resolve-DocumentModeFromExtractionMode {
    param([string]$ExtractionMode)

    if ($ExtractionMode -eq 'sniper') {
        return 'manual'
    }

    if ($ExtractionMode -eq 'txt_export') {
        return 'txt_export'
    }

    if ($ExtractionMode -eq 'blueprint') {
        return 'blueprint'
    }

    return 'full'
}

function Test-InteractiveConsoleSelectionSupported {
    try {
        if ([Console]::IsInputRedirected) { return $false }
        if ([Console]::IsOutputRedirected) { return $false }
        $null = $Host.UI.RawUI.WindowSize
        return $true
    }
    catch {
        return $false
    }
}

function Get-SentinelCompactDisplayText {
    param(
        [AllowEmptyString()][string]$Text = '',
        [int]$MaxLength = 72
    )

    $value = if ($null -eq $Text) { '' } else { [string]$Text }
    if ([string]::IsNullOrWhiteSpace($value)) {
        return ''
    }

    $safeMaxLength = [Math]::Max($MaxLength, 12)
    if ($value.Length -le $safeMaxLength) {
        return $value
    }

    if ($safeMaxLength -le 3) {
        return '...'
    }

    $headLength = [Math]::Max([int][Math]::Floor(($safeMaxLength - 1) * 0.55), 8)
    $tailLength = [Math]::Max(($safeMaxLength - 1) - $headLength, 4)

    if (($headLength + $tailLength + 1) -gt $safeMaxLength) {
        $tailLength = [Math]::Max(($safeMaxLength - $headLength - 1), 1)
    }

    return ('{0}…{1}' -f $value.Substring(0, $headLength), $value.Substring($value.Length - $tailLength))
}

function Reset-SentinelTransientConsoleLine {
    try {
        $lineWidth = 160
        try {
            $lineWidth = [Math]::Max(([Console]::WindowWidth - 1), 32)
        }
        catch {
            $lineWidth = 160
        }

        [Console]::Out.Write("`r" + (' ' * $lineWidth) + "`r")
    }
    catch {
        Write-Host ''
    }
}

function Get-SentinelConsoleMultiSelectHintLines {
    param([AllowEmptyString()][string]$Hint = '')

    $normalizedHint = (($Hint -replace '\s+', ' ').Trim()).ToUpperInvariant()
    $defaultHints = @(
        '↑↓ NAVEGAR ESPACO MARCAR/DESMARCAR A TODOS N NENHUM ENTER CONFIRMAR Q CANCELAR',
        '↑↓ NAVEGAR ESPAÇO MARCAR/DESMARCAR A TODOS N NENHUM ENTER CONFIRMAR Q CANCELAR'
    )

    if ($defaultHints -contains $normalizedHint) {
        return @(
            '  ↑↓ mover · PgUp/PgDn página · Home/End extremos',
            '  Espaço marca · Enter confirma · A todos · N nenhum · Q/Esc sai'
        )
    }

    if ([string]::IsNullOrWhiteSpace($Hint)) {
        return @()
    }

    return @('  ' + ($Hint -replace '\s+', ' ').Trim())
}

function Invoke-ConsoleMultiSelect {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Items,
        [string]$Title = 'SENTINEL HEADLESS — Selecao Sniper',
        [string]$Hint = '↑↓ Navegar   ESPACO Marcar/Desmarcar   A Todos   N Nenhum   ENTER Confirmar   Q Cancelar'
    )

    if ($null -eq $Items -or $Items.Count -eq 0) {
        return @()
    }

    $selected = @{}
    $currentIndex = 0
    $offset = 0

    while ($true) {
        $windowHeight = 24
        $windowWidth = 100
        try {
            $windowHeight = [Math]::Max([Console]::WindowHeight, 18)
            $windowWidth = [Math]::Max([Console]::WindowWidth, 80)
        }
        catch {
            $windowHeight = 24
            $windowWidth = 100
        }

        $pageSize = [Math]::Max(8, $windowHeight - 16)
        $contentWidth = [Math]::Max(($windowWidth - 8), 28)
        $itemTextWidth = [Math]::Max(($contentWidth - 8), 20)

        if ($currentIndex -lt $offset) {
            $offset = $currentIndex
        }

        if ($currentIndex -ge ($offset + $pageSize)) {
            $offset = $currentIndex - $pageSize + 1
        }

        Clear-Host
        Write-Host ''
        Write-SentinelDivider -Label 'SNIPER' -Tone 'Warning'
        Write-Host ('  {0}' -f $Title) -ForegroundColor Cyan
        Write-SentinelBadgeLine -Badges @(
            (Format-SentinelBadge -Label 'INTERATIVO' -Tone 'Warning'),
            (Format-SentinelBadge -Label 'MULTISELECT' -Tone 'Secondary')
        )

        foreach ($hintLine in @(Get-SentinelConsoleMultiSelectHintLines -Hint $Hint)) {
            Write-Host $hintLine -ForegroundColor DarkGray
        }

        Write-SentinelDivider -Tone 'Secondary'
        Write-Host ''

        $endIndex = [Math]::Min($Items.Count - 1, $offset + $pageSize - 1)
        if ($offset -gt 0) {
            Write-Host ('  … itens anteriores: {0}' -f $offset) -ForegroundColor DarkGray
        }

        for ($i = $offset; $i -le $endIndex; $i++) {
            $item = $Items[$i]
            $isCurrent = ($i -eq $currentIndex)
            $isSelected = $selected.ContainsKey($item)
            $cursor = if ($isCurrent) { '>' } else { ' ' }
            $mark = if ($isSelected) { '[x]' } else { '[ ]' }
            $displayItem = Get-SentinelCompactDisplayText -Text $item -MaxLength $itemTextWidth
            $lineColor = if ($isCurrent) { 'Cyan' } elseif ($isSelected) { 'Gray' } else { 'Gray' }
            $markColor = if ($isSelected) { 'Green' } else { 'DarkGray' }
            $cursorColor = if ($isCurrent) { 'Cyan' } else { 'DarkGray' }

            Write-Host '  ' -NoNewline
            Write-Host $cursor -ForegroundColor $cursorColor -NoNewline
            Write-Host ' ' -NoNewline
            Write-Host $mark -ForegroundColor $markColor -NoNewline
            Write-Host ' ' -NoNewline
            Write-Host $displayItem -ForegroundColor $lineColor
        }

        if ($endIndex -lt ($Items.Count - 1)) {
            Write-Host ('  … itens seguintes: {0}' -f ($Items.Count - $endIndex - 1)) -ForegroundColor DarkGray
        }

        Write-Host ''
        Write-SentinelDivider -Tone 'Muted'
        Write-Host ('  Marcados : {0}/{1}' -f $selected.Count, $Items.Count) -ForegroundColor Yellow
        Write-Host ('  Exibindo : {0}-{1} de {2}' -f ($offset + 1), ($endIndex + 1), $Items.Count) -ForegroundColor DarkGray
        Write-Host ('  Atual    : {0} de {1}' -f ($currentIndex + 1), $Items.Count) -ForegroundColor DarkGray

        $keyInfo = [Console]::ReadKey($true)
        $keyChar = ''
        if ($keyInfo.KeyChar -ne [char]0) {
            $keyChar = ([string]$keyInfo.KeyChar).ToLowerInvariant()
        }

        switch ($keyInfo.Key) {
            'UpArrow' {
                if ($currentIndex -gt 0) { $currentIndex-- }
                continue
            }
            'DownArrow' {
                if ($currentIndex -lt ($Items.Count - 1)) { $currentIndex++ }
                continue
            }
            'PageUp' {
                $currentIndex = [Math]::Max(0, $currentIndex - $pageSize)
                continue
            }
            'PageDown' {
                $currentIndex = [Math]::Min($Items.Count - 1, $currentIndex + $pageSize)
                continue
            }
            'Home' {
                $currentIndex = 0
                continue
            }
            'End' {
                $currentIndex = $Items.Count - 1
                continue
            }
            'Spacebar' {
                $currentItem = $Items[$currentIndex]
                if ($selected.ContainsKey($currentItem)) {
                    $selected.Remove($currentItem)
                }
                else {
                    $selected[$currentItem] = $true
                }
                continue
            }
            'Escape' {
                throw 'Seleção sniper cancelada pelo usuário.'
            }
            'Enter' {
                if ($selected.Count -eq 0) {
                    Write-Host ''
                    Write-SentinelStatus -Message 'Selecione pelo menos um item antes de confirmar.' -Type Warning
                    [void][Console]::ReadKey($true)
                    continue
                }

                return @($Items | Where-Object { $selected.ContainsKey($_) })
            }
        }

        switch ($keyChar) {
            'a' {
                $selected = @{}
                foreach ($item in $Items) {
                    $selected[$item] = $true
                }
                continue
            }
            'n' {
                $selected = @{}
                continue
            }
            'q' {
                throw 'Seleção sniper cancelada pelo usuário.'
            }
        }
    }
}

function Resolve-SniperRequestedPaths {
    param(
        [string]$ProjectRootPath,
        [System.IO.FileInfo[]]$AllFiles,
        [string[]]$RequestedPaths,
        [switch]$NonInteractive
    )

    $normalizedRequestedPaths = @($RequestedPaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($normalizedRequestedPaths.Count -gt 0) {
        return $normalizedRequestedPaths
    }

    if ($NonInteractive) {
        throw 'No modo sniper não interativo, informe -SelectedPaths com pelo menos um arquivo ou diretório.'
    }

    $relativeOptions = @(
        $AllFiles |
        Sort-Object FullName |
        ForEach-Object { Resolve-Path -Path $_.FullName -Relative }
    )

    if (Test-InteractiveConsoleSelectionSupported) {
        return @(
            Invoke-ConsoleMultiSelect -Items $relativeOptions -Title 'SENTINEL HEADLESS — Seleção Sniper' -Hint '↑↓ Navegar   ESPAÇO Marcar/Desmarcar   A Todos   N Nenhum   ENTER Confirmar   Q Cancelar'
        )
    }

    Write-SentinelSection -Title 'Seleção manual do modo Sniper' -Subtitle 'Informe um ou mais caminhos relativos ou absolutos separados por ;' -Tone 'Warning'
    $sniperPreviewLines = New-Object System.Collections.Generic.List[string]
    $sniperPreviewLines.Add('Pode ser arquivo ou diretório.') | Out-Null
    foreach ($previewFile in ($relativeOptions | Select-Object -First 20)) {
        $sniperPreviewLines.Add('- ' + $previewFile) | Out-Null
    }
    if ($relativeOptions.Count -gt 20) {
        $sniperPreviewLines.Add('... e mais ' + ($relativeOptions.Count - 20) + ' arquivo(s).') | Out-Null
    }
    Write-SentinelPanel -Title 'Arquivos elegíveis detectados (prévia)' -Tone 'Secondary' -Lines ($sniperPreviewLines.ToArray())

    $inputValue = (Read-Host '  Caminhos do Sniper').Trim()
    if ([string]::IsNullOrWhiteSpace($inputValue)) {
        throw 'No modo sniper, informe -SelectedPaths com pelo menos um arquivo ou diretório.'
    }

    return @(
        $inputValue -split ';' |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
}

function Resolve-SelectedFilesForSniper {
    param(
        [string]$ProjectRootPath,
        [System.IO.FileInfo[]]$AllFiles,
        [string[]]$RequestedPaths
    )

    if ($null -eq $RequestedPaths -or $RequestedPaths.Count -eq 0) {
        throw 'No modo sniper, informe -SelectedPaths com pelo menos um arquivo ou diretório.'
    }

    $allowedMap = @{}
    foreach ($file in @($AllFiles)) {
        $allowedMap[[System.IO.Path]::GetFullPath($file.FullName)] = $file
    }

    $selectedMap = @{}

    foreach ($requestedPath in @($RequestedPaths)) {
        if ([string]::IsNullOrWhiteSpace($requestedPath)) {
            continue
        }

        $candidatePath = $requestedPath
        if (-not [System.IO.Path]::IsPathRooted($candidatePath)) {
            $candidatePath = Join-Path $ProjectRootPath $candidatePath
        }

        if (-not (Test-Path $candidatePath)) {
            throw "Caminho selecionado não encontrado: $requestedPath"
        }

        if (Test-Path $candidatePath -PathType Leaf) {
            $full = [System.IO.Path]::GetFullPath((Resolve-Path -Path $candidatePath).Path)
            if (-not $allowedMap.ContainsKey($full)) {
                throw "Arquivo fora do escopo de descoberta ou ignorado pelo bundler: $requestedPath"
            }

            $selectedMap[$full] = $allowedMap[$full]
            continue
        }

        if (Test-Path $candidatePath -PathType Container) {
            $discovered = @(Get-RelevantFiles -CurrentPath $candidatePath)
            foreach ($item in $discovered) {
                $full = [System.IO.Path]::GetFullPath($item.FullName)
                if ($allowedMap.ContainsKey($full)) {
                    $selectedMap[$full] = $allowedMap[$full]
                }
            }
            continue
        }

        throw "Caminho selecionado inválido: $requestedPath"
    }

    if ($selectedMap.Count -eq 0) {
        throw 'No modo sniper, nenhum arquivo elegível foi selecionado.'
    }

    return @($selectedMap.Values | Sort-Object FullName)
}

function Get-VibeArtifactRouteLabel {
    param([string]$RouteMode)

    if ($RouteMode -match '(?i)executor') {
        return 'executor'
    }

    return 'diretor'
}

function Get-VibeArtifactModeLabel {
    param([string]$ExtractionMode)

    switch -Regex ($ExtractionMode) {
        '(?i)sniper|manual|^3$' { return 'manual' }
        '(?i)blueprint|architect|^2$' { return 'blueprint' }
        '(?i)txt_export|txtExport|^4$' { return 'txt_export' }
        default { return 'bundle' }
    }
}

function Get-VibeArtifactFileName {
    param(
        [string]$ProjectNameValue,
        [string]$ExtractionMode,
        [string]$RouteMode,
        [string]$Prefix = '',
        [string]$Extension = '.md'
    )

    $mode = Get-VibeArtifactModeLabel -ExtractionMode $ExtractionMode
    $route = Get-VibeArtifactRouteLabel -RouteMode $RouteMode
    $pfx = if ([string]::IsNullOrWhiteSpace($Prefix)) { '_' } else { "_${Prefix}_" }

    return "${pfx}${mode}_${route}__${ProjectNameValue}${Extension}"
}

function Get-ResultMetaOutputFileName {
    param(
        [string]$ProjectNameValue,
        [string]$RouteMode,
        [string]$ExtractionMode
    )

    return (Get-VibeArtifactFileName -ProjectNameValue $ProjectNameValue -ExtractionMode $ExtractionMode -RouteMode $RouteMode -Extension '.json')
}

function Get-DeterministicMetaPromptOutputFileName {
    param(
        [string]$ProjectNameValue,
        [string]$ExtractionMode,
        [string]$RouteMode
    )

    return (Get-VibeArtifactFileName -ProjectNameValue $ProjectNameValue -ExtractionMode $ExtractionMode -RouteMode $RouteMode -Prefix 'meta-prompt')
}

function Get-DeterministicRelevantFiles {
    param([System.IO.FileInfo[]]$Files)

    $priorityPatterns = @(
        '.\project-bundler-cli.ps1',
        '.\project-bundler-headless.ps1',
        '.\modules\VibeDirectorProtocol.psm1',
        '.\modules\VibeBundleWriter.psm1',
        '.\modules\VibeFileDiscovery.psm1',
        '.\modules\VibeSignatureExtractor.psm1',
        '.\README.md'
    )

    $relativeMap = @{}
    foreach ($file in @($Files)) {
        try {
            $relativePath = Resolve-Path -Path $file.FullName -Relative
            $relativeMap[$relativePath] = $true
        }
        catch {
        }
    }

    $result = New-Object System.Collections.Generic.List[string]
    foreach ($pattern in $priorityPatterns) {
        if ($relativeMap.ContainsKey($pattern)) {
            $result.Add($pattern) | Out-Null
        }
    }

    if ($result.Count -eq 0) {
        foreach ($key in ($relativeMap.Keys | Select-Object -First 8)) {
            $result.Add([string]$key) | Out-Null
        }
    }

    return @($result)
}

function New-DeterministicMetaPromptArtifact {
    param(
        [string]$ProjectNameValue,
        [string]$ExecutorTargetValue,
        [string]$ExtractionMode,
        [string]$DocumentMode,
        [string]$RouteMode,
        [string]$SourceArtifactFileName,
        [string]$OutputArtifactFileName,
        [AllowEmptyString()][string]$BundleContent,
        [System.IO.FileInfo[]]$Files
    )

    $generatedAt = [DateTime]::UtcNow.ToString('o')
    $relevantFiles = @(Get-DeterministicRelevantFiles -Files $Files)

    $visibleArtifactHeading = if ($ExtractionMode -eq 'blueprint') { '## BLUEPRINT VISÍVEL' } else { '## BUNDLE VISÍVEL' }

    $lines = New-Object System.Collections.Generic.List[string]
    $protocolContent = Get-VibeDeterministicMetaPromptProtocolContent `
        -ProjectNameValue $ProjectNameValue `
        -ExecutorTargetValue $ExecutorTargetValue `
        -ExtractionMode $ExtractionMode `
        -DocumentMode $DocumentMode `
        -RouteMode $RouteMode `
        -SourceArtifactFileName $SourceArtifactFileName `
        -OutputArtifactFileName $OutputArtifactFileName `
        -GeneratedAt $generatedAt `
        -RelevantFiles $relevantFiles

    if (-not [string]::IsNullOrWhiteSpace($protocolContent)) {
        $lines.Add($protocolContent.Trim()) | Out-Null
        $lines.Add('') | Out-Null
    }

    $lines.Add($visibleArtifactHeading) | Out-Null
    $lines.Add('') | Out-Null

    $croppedContent = $BundleContent
    if (-not [string]::IsNullOrWhiteSpace($croppedContent)) {
        $structuralAnchors = @(
            '### 1. PROJECT STRUCTURE',
            '### 2. PROJECT STRUCTURE',
            '### PROJECT STRUCTURE (BUNDLER)',
            '### PROJECT STRUCTURE',
            '## 1. PROJECT STRUCTURE',
            '## 2. PROJECT STRUCTURE',
            '## PROJECT STRUCTURE'
        )

        $anchorIndex = -1
        foreach ($anchor in $structuralAnchors) {
            $idx = $croppedContent.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase)
            if ($idx -ge 0 -and ($anchorIndex -lt 0 -or $idx -lt $anchorIndex)) {
                $anchorIndex = $idx
            }
        }

        if ($anchorIndex -ge 0) {
            $croppedContent = $croppedContent.Substring($anchorIndex)
        }
    }

    # Limpar as costuras internas (fences vazios ou nomeados) para envelopar em um único fence coerente
    $cleanContent = [regex]::Replace($croppedContent, '(?m)^[ 	]*```+[a-zA-Z0-9\-\+]*[ 	]*\r?\n?', '')

    $lines.Add((Convert-ToSafeMarkdownCodeBlock -Content (Format-BundleContentForDiff -Content $cleanContent) -Language 'text')) | Out-Null

    return ($lines -join "`n")
}

function Format-BundleContentForDiff {
    param([AllowEmptyString()][string]$Content)

    if ($null -eq $Content) {
        return ''
    }

    return (($Content -replace "`0", '') -replace "`r`n", "`n").TrimEnd()
}

function Get-BundleContentHash {
    param([AllowEmptyString()][string]$Content)

    $normalized = Format-BundleContentForDiff -Content $Content
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()

    try {
        return ([System.BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Get-FileHashSha256 {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path $Path -PathType Leaf)) {
        return $null
    }

    return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-EnvironmentSnapshot {
    $psVersion = $null
    try {
        $psVersion = $PSVersionTable.PSVersion.ToString()
    }
    catch {
    }

    $isWindowsFlag = $false
    try {
        if (Test-Path variable:IsWindows) {
            $isWindowsFlag = [bool]$IsWindows
        }
        else {
            $isWindowsFlag = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
        }
    }
    catch {
        $isWindowsFlag = $false
    }

    return [ordered]@{
        osVersion           = [System.Environment]::OSVersion.VersionString
        psVersion           = $psVersion
        isWindows           = $isWindowsFlag
        hostname            = [System.Environment]::MachineName
        processArchitecture = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture.ToString()
    }
}

function Get-UserSnapshot {
    $username = $env:USERNAME
    if ([string]::IsNullOrWhiteSpace($username)) {
        $username = $env:USER
    }

    return [ordered]@{
        username      = $username
        domain        = $env:USERDOMAIN
        homeDirectory = $(if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) { $env:USERPROFILE } else { $env:HOME })
    }
}

function Write-LocalExecutionMeta {
    param(
        [string]$ProjectNameValue,
        [string]$RouteMode,
        [string]$ExtractionMode,
        [string]$DocumentMode,
        [string]$ExecutorTargetValue,
        [AllowNull()][string]$SourceArtifactPath = $null,
        [AllowNull()][string]$OutputPath = $null,
        [AllowNull()][string]$ResultMetaPath = $null,
        [int]$DurationMs = 0,
        [hashtable]$ExtraData
    )

    $resolvedResultMetaPath = if ([string]::IsNullOrWhiteSpace($ResultMetaPath)) {
        $baseDir = if ($script:EffectiveOutputDirectory) { $script:EffectiveOutputDirectory } else { (Get-Location).Path }
        Join-Path $baseDir (Get-ResultMetaOutputFileName -ProjectNameValue $ProjectNameValue -RouteMode $RouteMode -ExtractionMode $ExtractionMode)
    }
    else {
        $ResultMetaPath
    }

    $sourceHash = Get-FileHashSha256 -Path $SourceArtifactPath
    $outputHash = Get-FileHashSha256 -Path $OutputPath

    $meta = [ordered]@{
        ok                 = $true
        executionId        = [guid]::NewGuid().ToString()
        executionMode      = 'local'
        routeMode          = $RouteMode
        extractionMode     = $ExtractionMode
        documentMode       = $DocumentMode
        executorTarget     = $ExecutorTargetValue
        generatedAt        = [DateTime]::UtcNow.ToString('o')
        durationMs         = $DurationMs
        sourceArtifactPath = $SourceArtifactPath
        sourceArtifactHash = $sourceHash
        outputPath         = $OutputPath
        outputHash         = $outputHash
        resultMetaPath     = $resolvedResultMetaPath
        generatedLocally   = $true
        environment        = Get-EnvironmentSnapshot
        user               = Get-UserSnapshot
    }

    if ($ExtraData) {
        foreach ($key in $ExtraData.Keys) {
            $meta[$key] = $ExtraData[$key]
        }
    }

    $metaJson = $meta | ConvertTo-Json -Depth 12
    Write-LocalTextArtifact -Path $resolvedResultMetaPath -Content $metaJson -UseBom

    return [pscustomobject]@{
        Meta           = [pscustomobject]$meta
        ResultMetaPath = $resolvedResultMetaPath
    }
}

function New-TxtExportOutputDirectory {
    param(
        [string]$BaseDirectory,
        [string]$ProjectNameValue
    )

    $rootName = "_TXT_EXPORT__${ProjectNameValue}"
    $candidate = Join-Path $BaseDirectory $rootName
    $suffix = 2

    while (Test-Path $candidate) {
        $candidate = Join-Path $BaseDirectory ("{0}__{1}" -f $rootName, $suffix)
        $suffix++
    }

    [System.IO.Directory]::CreateDirectory($candidate) | Out-Null
    return $candidate
}

function Convert-SourceFileToTxtExportName {
    param(
        [string]$FullPath,
        [string]$ProjectRootPath
    )

    $fullPathResolved = [System.IO.Path]::GetFullPath($FullPath)
    $projectRootResolved = [System.IO.Path]::GetFullPath($ProjectRootPath)
    $relativePath = $null

    $getRelativePathMethod = [System.IO.Path].GetMethod('GetRelativePath', [type[]]@([string], [string]))
    if ($null -ne $getRelativePathMethod) {
        $relativePath = [System.IO.Path]::GetRelativePath($projectRootResolved, $fullPathResolved)
    }
    else {
        $basePathForUri = $projectRootResolved
        if (-not $basePathForUri.EndsWith([System.IO.Path]::DirectorySeparatorChar) -and -not $basePathForUri.EndsWith([System.IO.Path]::AltDirectorySeparatorChar)) {
            $basePathForUri += [System.IO.Path]::DirectorySeparatorChar
        }

        $projectRootUri = New-Object System.Uri($basePathForUri)
        $fullPathUri = New-Object System.Uri($fullPathResolved)

        if ($projectRootUri.IsBaseOf($fullPathUri)) {
            $relativePath = [System.Uri]::UnescapeDataString($projectRootUri.MakeRelativeUri($fullPathUri).ToString())
            $relativePath = $relativePath -replace '/', [string][System.IO.Path]::DirectorySeparatorChar
        }
        else {
            $relativePath = $fullPathResolved
        }
    }

    if ([string]::IsNullOrWhiteSpace($relativePath) -or $relativePath -eq '.') {
        $relativePath = [System.IO.Path]::GetFileName($fullPathResolved)
    }

    $normalizedRelativePath = $relativePath -replace '[\\/]+', [string][System.IO.Path]::DirectorySeparatorChar
    $normalizedRelativePath = $normalizedRelativePath.TrimStart([char[]]@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar, '.'))

    if ([string]::IsNullOrWhiteSpace($normalizedRelativePath) -or $normalizedRelativePath -eq '.') {
        $normalizedRelativePath = [System.IO.Path]::GetFileName($fullPathResolved)
    }

    $segments = @(
        $normalizedRelativePath -split '[\\/]+' |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_ -ne '.' }
    )

    if ($segments.Count -eq 0) {
        $segments = @([System.IO.Path]::GetFileName($fullPathResolved))
    }

    $safeSegments = New-Object System.Collections.Generic.List[string]
    foreach ($segment in $segments) {
        $safeSegment = $segment -replace '[:*?"<>|]', '_'
        if ([string]::IsNullOrWhiteSpace($safeSegment) -or $safeSegment -match '^\.+$') {
            $safeSegment = '_'
        }
        $safeSegments.Add($safeSegment) | Out-Null
    }

    $lastIndex = $safeSegments.Count - 1
    $safeSegments[$lastIndex] = '{0}.txt' -f $safeSegments[$lastIndex]

    $targetRelativePath = $safeSegments[0]
    for ($i = 1; $i -lt $safeSegments.Count; $i++) {
        $targetRelativePath = Join-Path $targetRelativePath $safeSegments[$i]
    }

    return $targetRelativePath
}

function New-TxtExportZipFilePath {
    param(
        [string]$BaseDirectory,
        [string]$ProjectNameValue,
        [string]$RouteMode
    )

    $resolvedBaseDirectory = [System.IO.Path]::GetFullPath($BaseDirectory)

    if ([string]::IsNullOrWhiteSpace($resolvedBaseDirectory) -or -not (Test-Path $resolvedBaseDirectory -PathType Container)) {
        throw "Diretório base inválido para o artefato final TXT Export: $BaseDirectory"
    }

    $artifactFileName = Get-VibeArtifactFileName -ProjectNameValue $ProjectNameValue -ExtractionMode 'txt_export' -RouteMode $RouteMode -Extension '.zip'
    $candidate = Join-Path $resolvedBaseDirectory $artifactFileName
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($artifactFileName)
    $suffix = 2

    while (Test-Path $candidate) {
        $candidate = Join-Path $resolvedBaseDirectory ("{0}__{1}.zip" -f $baseName, $suffix)
        $suffix++
    }

    return $candidate
}

function New-TxtExportZipArchive {
    param(
        [string]$OutputDirectory,
        [string]$BaseDirectory,
        [string]$ProjectNameValue,
        [string]$RouteMode
    )

    if ([string]::IsNullOrWhiteSpace($OutputDirectory) -or -not (Test-Path $OutputDirectory -PathType Container)) {
        throw "Diretório de staging do TXT Export inválido para compactação: $OutputDirectory"
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $zipFilePath = New-TxtExportZipFilePath -BaseDirectory $BaseDirectory -ProjectNameValue $ProjectNameValue -RouteMode $RouteMode
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $OutputDirectory,
        $zipFilePath,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false
    )

    return $zipFilePath
}

function Remove-TxtExportOutputDirectory {
    param([string]$OutputDirectory)

    if ([string]::IsNullOrWhiteSpace($OutputDirectory) -or -not (Test-Path $OutputDirectory -PathType Container)) {
        return $false
    }

    Remove-Item -Path $OutputDirectory -Recurse -Force -ErrorAction Stop
    return $true
}

function Test-IsLikelyBinaryFile {
    param([string]$FilePath)

    $stream = $null
    try {
        $stream = [System.IO.File]::Open($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $buffer = New-Object byte[] 4096
        $read = $stream.Read($buffer, 0, $buffer.Length)

        if ($read -le 0) {
            return $false
        }

        for ($i = 0; $i -lt $read; $i++) {
            if ($buffer[$i] -eq 0) {
                return $true
            }
        }

        return $false
    }
    finally {
        if ($null -ne $stream) {
            $stream.Dispose()
        }
    }
}

function Read-TextContentForTxtExport {
    param([string]$FilePath)

    return (Read-LocalTextArtifact -Path $FilePath)
}

function Export-OperationFilesToTxtDirectory {
    param(
        [object[]]$Files,
        [string]$ProjectRootPath,
        [string]$BaseOutputDirectory,
        [string]$ProjectNameValue,
        [string]$RouteMode
    )

    $outputDirectory = New-TxtExportOutputDirectory -BaseDirectory $BaseOutputDirectory -ProjectNameValue $ProjectNameValue
    $exportedFiles = New-Object System.Collections.Generic.List[string]
    $skippedFiles = New-Object System.Collections.Generic.List[string]

    for ($index = 0; $index -lt $Files.Count; $index++) {
        $sourceFile = $Files[$index]
        $sourcePathVisual = if ($sourceFile -is [System.IO.FileInfo]) { $sourceFile.FullName } else { [string]$sourceFile }
        Write-SentinelProgress -Activity 'TXT Export' -Current ($index + 1) -Total $Files.Count -Tone 'Secondary' -Item $sourcePathVisual
        try {
            $sourcePath = if ($sourceFile -is [System.IO.FileInfo]) { $sourceFile.FullName } else { [string]$sourceFile }
            if ([string]::IsNullOrWhiteSpace($sourcePath) -or -not (Test-Path $sourcePath -PathType Leaf)) {
                Write-Host ""
                Write-UILog -Message "TXT Export ignorado: arquivo não encontrado -> $sourcePath" -Color $ThemeWarn
                $skippedFiles.Add([string]$sourcePath) | Out-Null
                continue
            }

            $resolvedSource = (Resolve-Path $sourcePath).Path

            if (Test-IsLikelyBinaryFile -FilePath $resolvedSource) {
                Write-Host ""
                Write-UILog -Message "TXT Export ignorado: arquivo binário/incompatível -> $resolvedSource" -Color $ThemeWarn
                $skippedFiles.Add($resolvedSource) | Out-Null
                continue
            }

            $content = Read-TextContentForTxtExport -FilePath $resolvedSource
            $targetName = Convert-SourceFileToTxtExportName -FullPath $resolvedSource -ProjectRootPath $ProjectRootPath
            $targetPath = Join-Path $outputDirectory $targetName
            $targetDirectory = [System.IO.Path]::GetDirectoryName($targetPath)

            if (-not [string]::IsNullOrWhiteSpace($targetDirectory)) {
                [System.IO.Directory]::CreateDirectory($targetDirectory) | Out-Null
            }

            Write-LocalTextArtifact -Path $targetPath -Content $content -UseBom
            $exportedFiles.Add($targetPath) | Out-Null
        }
        catch {
            Write-Host ""
            $failedPath = if ($sourceFile -is [System.IO.FileInfo]) { $sourceFile.FullName } else { [string]$sourceFile }
            Write-UILog -Message "Falha ao exportar TXT: $failedPath :: $($_.Exception.Message)" -Color $ThemePink
            $skippedFiles.Add([string]$failedPath) | Out-Null
        }
    }
    
    Write-Host ""

    try {
        $zipFilePath = New-TxtExportZipArchive -OutputDirectory $outputDirectory -BaseDirectory $BaseOutputDirectory -ProjectNameValue $ProjectNameValue -RouteMode $RouteMode
    }
    catch {
        throw "Falha ao criar o artefato final do TXT Export: $($_.Exception.Message)"
    }

    try {
        $stagingRemoved = Remove-TxtExportOutputDirectory -OutputDirectory $outputDirectory
        if (-not $stagingRemoved) {
            throw "Diretório de staging não encontrado para remoção: $outputDirectory"
        }
    }
    catch {
        throw "Artefato final do TXT Export criado em '$zipFilePath', mas não foi possível remover o staging interno '$outputDirectory': $($_.Exception.Message)"
    }

    return [pscustomobject]@{
        StagingDirectory        = $outputDirectory
        StagingDirectoryRemoved = $stagingRemoved
        ZipFilePath             = $zipFilePath
        ExportedFiles           = $exportedFiles
        SkippedFiles            = $skippedFiles
    }
}

function Resolve-BundleMode {
    param(
        [string]$BundleMode,
        [switch]$NonInteractive
    )

    if ($BundleMode -in @('full', 'blueprint', 'sniper', 'txtExport', 'txt_export')) {
        if ($BundleMode -eq 'txt_export') {
            return 'txtExport'
        }
        return $BundleMode
    }

    if ($NonInteractive) {
        throw 'Modo de extração obrigatório em execução não interativa. Use -BundleMode full, blueprint, sniper ou txtExport.'
    }

    Write-SentinelSection -Title 'ETAPA 2/3 · Extração' -Tone 'Primary'
    Write-SentinelMenuOptions -Options @(
        (New-SentinelMenuOptionLine -Label 'Full' -Description 'código completo + contexto amplo' -LabelWidth 14),
        (New-SentinelMenuOptionLine -Label 'Blueprint' -Description 'estrutura + contratos centrais' -LabelWidth 14),
        (New-SentinelMenuOptionLine -Label 'Sniper' -Description 'recorte manual cirúrgico' -LabelWidth 14),
        (New-SentinelMenuOptionLine -Label 'TXT Export' -Description 'ZIP textual para ingestão externa' -LabelWidth 14)
    )
    Write-SentinelHintLines -Lines (Get-SentinelBundleModeHintLines)

    $resolved = $null
    while ($null -eq $resolved) {
        $inp = (Read-Host '  Escolha a extração [1-4]').Trim()
        switch ($inp) {
            '1' { $resolved = 'full' }
            '2' { $resolved = 'blueprint' }
            '3' { $resolved = 'sniper' }
            '4' { $resolved = 'txtExport' }
            default { Write-SentinelInvalidSelection -Expected '1, 2, 3 ou 4' }
        }
    }

    Write-Host ''
    return $resolved
}

function Resolve-RouteMode {
    param(
        [string]$RouteMode,
        [switch]$NonInteractive
    )

    if ($RouteMode -eq 'director' -or $RouteMode -eq 'executor') {
        return $RouteMode
    }

    if ($NonInteractive) {
        throw 'Rota obrigatória em execução não interativa. Use -RouteMode director ou executor.'
    }

    Write-SentinelSection -Title 'ETAPA 3/3 · Rota' -Tone 'Primary'
    Write-SentinelMenuOptions -Options @(
        (New-SentinelMenuOptionLine -Label 'Diretor' -Description 'compila meta-prompt local   ← padrão' -LabelWidth 14),
        (New-SentinelMenuOptionLine -Label 'Executor' -Description 'gera artefato final direto' -LabelWidth 14)
    )
    Write-SentinelHintLines -Lines (Get-SentinelRouteModeHintLines)

    $resolved = $null
    while ($null -eq $resolved) {
        $inp = (Read-Host '  Escolha a rota [1-2] (padrão: 1)').Trim()
        if ([string]::IsNullOrWhiteSpace($inp)) { $inp = '1' }
        switch ($inp) {
            '1' { $resolved = 'director' }
            '2' { $resolved = 'executor' }
            default { Write-SentinelInvalidSelection -Expected '1 ou 2. Enter usa 1' }
        }
    }

    Write-Host ''
    return $resolved
}

function Resolve-ProjectSource {
    param(
        [string]$DefaultPath,
        [switch]$NonInteractive
    )

    if ($NonInteractive) {
        return [pscustomobject]@{
            ResolvedPath     = [System.IO.Path]::GetFullPath((Resolve-Path -Path $DefaultPath -ErrorAction Stop).Path)
            SourceMode       = 'local'
            OriginalInput    = $DefaultPath
            CloneCleanupInfo = $null
        }
    }

    $originPreview = $DefaultPath
    try {
        $originPreview = [System.IO.Path]::GetFullPath((Resolve-Path -Path $DefaultPath -ErrorAction Stop).Path)
    }
    catch {
        $originPreview = $DefaultPath
    }

    Write-SentinelSection -Title 'ETAPA 1/3 · Origem' -Tone 'Primary'
    Write-SentinelKeyValue -Key 'Path atual' -Value (Get-SentinelCompactDisplayText -Text $originPreview -MaxLength 72) -Tone 'Secondary' -KeyWidth 14
    Write-Host ''
    Write-SentinelMenuOptions -Options @(
        (New-SentinelMenuOptionLine -Label 'Path atual' -Description 'usa o diretório informado' -LabelWidth 14),
        (New-SentinelMenuOptionLine -Label 'Clonar GitHub' -Description 'baixa uma cópia local antes da leitura' -LabelWidth 14)
    )
    Write-SentinelHintLines -Lines (Get-SentinelSourceModeHintLines)

    $choice = $null
    while ($choice -notin @('1', '2')) {
        $choice = (Read-Host '  Escolha a origem [1-2]').Trim()
        if ($choice -notin @('1', '2')) {
            Write-SentinelInvalidSelection -Expected '1 ou 2'
        }
    }

    if ($choice -eq '1') {
        Write-Host ''
        $resolved = [System.IO.Path]::GetFullPath((Resolve-Path -Path $DefaultPath -ErrorAction Stop).Path)
        Write-UILog -Message ("Origem: path local -> {0}" -f $resolved) -Color $ThemeSuccess
        return [pscustomobject]@{
            ResolvedPath     = $resolved
            SourceMode       = 'local'
            OriginalInput    = $DefaultPath
            CloneCleanupInfo = $null
        }
    }

    Write-SentinelSection -Title 'ETAPA 1.1 · Clonagem GitHub' -Tone 'Primary'

    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) {
        throw 'Git não está instalado ou não está disponível no PATH. A clonagem de repositórios GitHub requer o Git.'
    }

    $repoUrl = $null
    while ([string]::IsNullOrWhiteSpace($repoUrl)) {
        $repoUrl = (Read-Host '  URL do repositório GitHub (ex: https://github.com/user/repo.git)').Trim()
        if ([string]::IsNullOrWhiteSpace($repoUrl)) {
            Write-SentinelStatus -Message 'URL vazia. Cole uma URL válida ou Ctrl+C cancela.' -Type Warning
        }
    }

    if ($repoUrl -notmatch '^https?://(www\.)?github\.com/') {
        Write-UILog -Message 'Aviso: a URL fornecida não parece ser do GitHub. A clonagem será tentada mesmo assim.' -Color $ThemeWarn
    }

    Write-Host ''
    $useTempInput = (Read-Host '  Usar diretório temporário automático? (S/n)').Trim().ToLower()
    $useTempDir = -not ($useTempInput -eq 'n' -or $useTempInput -eq 'nao')

    $targetDir = $null
    $cloneMode = $null

    if ($useTempDir) {
        $cloneMode = 'temporary'
        $baseTemp = Join-Path ([System.IO.Path]::GetTempPath()) 'VibeToolkit\clones'
        if (-not (Test-Path $baseTemp)) {
            New-Item -ItemType Directory -Path $baseTemp -Force | Out-Null
        }
        $uniqueName = [System.Guid]::NewGuid().ToString('N')
        $targetDir = Join-Path $baseTemp $uniqueName
        Write-UILog -Message ("Diretório temporário automático: {0}" -f $targetDir) -Color $ThemeCyan
    }
    else {
        $cloneMode = 'manual'
        $manualPath = $null
        while ([string]::IsNullOrWhiteSpace($manualPath)) {
            $manualPath = (Read-Host '  Informe o caminho completo do diretório de destino').Trim()
            if ([string]::IsNullOrWhiteSpace($manualPath)) {
                Write-SentinelStatus -Message 'Caminho vazio. Informe um diretório válido ou Ctrl+C cancela.' -Type Warning
                continue
            }
            try {
                $resolvedManual = [System.IO.Path]::GetFullPath($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($manualPath))
            }
            catch {
                Write-SentinelStatus -Message 'Caminho inválido. Revise o diretório e tente novamente. Ctrl+C cancela.' -Type Warning
                $manualPath = $null
                continue
            }
            $manualPath = $resolvedManual
        }
        $targetDir = $manualPath
    }

    Write-Host ''
    $keepCloneInput = (Read-Host '  Manter o clone após a execução? (s/N)').Trim().ToLower()
    $keepClone = ($keepCloneInput -eq 's' -or $keepCloneInput -eq 'sim')

    Write-UILog -Message ("Iniciando clone de {0} para {1} ..." -f $repoUrl, $targetDir) -Color $ThemeCyan

    $cloneArgs = @('clone', '--', $repoUrl, $targetDir)
    $cloneProcess = Start-Process -FilePath 'git' -ArgumentList $cloneArgs -NoNewWindow -Wait -PassThru
    if ($cloneProcess.ExitCode -ne 0) {
        throw "Falha ao clonar repositório (código de saída: $($cloneProcess.ExitCode)). Verifique a URL e sua conexão."
    }

    Write-UILog -Message 'Clone concluído com sucesso.' -Color $ThemeSuccess

    $cleanupInfo = @{
        Path             = $targetDir
        CloneMode        = $cloneMode
        KeepClone        = $keepClone
        CreatedByUs      = $true
        cleanupPerformed = $false
    }

    return [pscustomobject]@{
        ResolvedPath     = $targetDir
        SourceMode       = 'github'
        OriginalInput    = $repoUrl
        CloneCleanupInfo = $cleanupInfo
    }
}

$script:AllowedExtensions = @(
    '.tsx', '.ts', '.js', '.jsx', '.mjs', '.cjs', '.mts', '.cts', '.vue', '.svelte', '.astro',
    '.css', '.scss', '.sass', '.less', '.html', '.htm', '.xhtml', '.cshtml', '.razor', '.xaml', '.svg',
    '.json', '.jsonc', '.json5', '.yaml', '.yml', '.xml', '.toml', '.ini', '.cfg', '.conf', '.config',
    '.properties', '.props', '.targets', '.editorconfig', '.plist', '.pbxproj', '.xcconfig',
    '.md', '.mdx', '.txt', '.rst', '.adoc', '.tex', '.csv', '.tsv',
    '.py', '.pyi', '.java', '.cs', '.vb', '.fs', '.fsi', '.fsx', '.c', '.cpp', '.cc', '.cxx', '.h', '.hh', '.hpp', '.hxx',
    '.go', '.rb', '.php', '.phtml', '.rs', '.swift', '.kt', '.kts', '.scala', '.dart', '.r', '.lua', '.pl', '.pm',
    '.jl', '.zig', '.nim', '.elm', '.ex', '.exs', '.erl', '.hrl', '.clj', '.cljs', '.cljc', '.edn', '.ml', '.mli',
    '.sh', '.bash', '.zsh', '.fish', '.ksh', '.bat', '.cmd', '.ps1', '.psm1', '.psd1', '.ps1xml',
    '.sql', '.prisma', '.graphql', '.gql', '.proto', '.tf', '.tfvars', '.hcl', '.bicep',
    '.gradle', '.sln', '.csproj', '.vbproj', '.fsproj', '.vcxproj', '.filters', '.reg', '.vbs'
)

$script:SignatureExtensions = @(
    '.tsx', '.ts', '.js', '.jsx', '.mjs', '.cjs', '.mts', '.cts', '.vue', '.svelte', '.astro',
    '.py', '.pyi', '.java', '.cs', '.vb', '.fs', '.fsi', '.fsx', '.c', '.cpp', '.cc', '.cxx', '.h', '.hh', '.hpp', '.hxx',
    '.go', '.rb', '.php', '.phtml', '.rs', '.swift', '.kt', '.kts', '.scala', '.dart', '.r', '.lua',
    '.pl', '.pm', '.jl', '.zig', '.nim', '.elm', '.ex', '.exs', '.erl', '.hrl', '.clj', '.cljs', '.cljc', '.edn', '.ml', '.mli',
    '.sh', '.bash', '.zsh', '.fish', '.ksh', '.bat', '.cmd', '.ps1', '.psm1', '.psd1', '.ps1xml',
    '.sql', '.prisma', '.graphql', '.gql', '.proto', '.tf', '.tfvars', '.hcl', '.bicep',
    '.cshtml', '.razor', '.xaml', '.xml', '.gradle', '.sln', '.csproj', '.vbproj', '.fsproj', '.vcxproj', '.props', '.targets', '.reg', '.vbs'
)

$script:IgnoredDirs = @(
    'node_modules', '.git', 'dist', 'build', '.next', '.cache', 'out',
    'coverage', '.venv', 'venv', 'env', '__pycache__', '.pytest_cache', '.tox',
    'bin', 'obj', 'target', 'vendor', '.agent', '.github', '.vite', 'android'
)

$script:IgnoredFiles = @(
    'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock',
    '.DS_Store', 'metadata.json', '.gitignore',
    'capacitor.plugins.json', 'cordova.js', 'cordova_plugins.js',
    'poetry.lock', 'Pipfile.lock', 'Cargo.lock', 'go.sum', 'composer.lock'
)

Register-SentinelCliFallback

try {
    $SentinelUiPath = Join-Path $script:ToolkitDir 'lib\SentinelUI.ps1'
    if (-not (Test-Path $SentinelUiPath -PathType Leaf)) {
        throw "Biblioteca de UI não encontrada: $SentinelUiPath"
    }

    $sentinelUiFallbackActive = $false
    try {
        . $SentinelUiPath
    }
    catch {
        $sentinelBootstrapFailure = $_
        if (Test-IsSentinelUiPolicyBlockedError -ErrorRecord $sentinelBootstrapFailure) {
            Register-SentinelCliFallback
            $sentinelUiFallbackActive = $true
            $sentinelFailureSummary = Get-SentinelUiBootstrapFailureSummary -ErrorRecord $sentinelBootstrapFailure
            Write-SentinelStatus -Message 'SentinelUI bloqueado por assinatura/execution policy. Ativando fallback textual para o modo headless.' -Type Warning
            Write-SentinelPanel -Title 'Resumo do bootstrap' -Tone 'Warning' -Lines @($sentinelFailureSummary)
        }
        else {
            $sentinelFailureSummary = Get-SentinelUiBootstrapFailureSummary -ErrorRecord $sentinelBootstrapFailure
            throw "Falha estrutural ao carregar biblioteca de UI '$SentinelUiPath'. $sentinelFailureSummary"
        }
    }

    Assert-SentinelUiBootstrapContract -SentinelUiPath $SentinelUiPath -FallbackActive:$sentinelUiFallbackActive

    Write-SentinelHeader -Title 'SENTINEL HEADLESS' -Version 'v2.0.0' -Variant 'Compact'
    if ($sentinelUiFallbackActive) {
        Write-UILog -Message 'Bootstrap headless carregado com fallback textual de console.' -Color $ThemeWarn
    }
    else {
        Write-UILog -Message 'Bootstrap headless carregado.' -Color $ThemeSuccess
    }

    Write-SentinelKeyValue -Key 'Projeto' -Value $Path -Tone 'Primary' -KeyWidth 14
    Write-SentinelKeyValue -Key 'Executor' -Value $ExecutorTarget -Tone 'Primary' -KeyWidth 14
    Write-Host ''

    $sourceResult = Resolve-ProjectSource -DefaultPath $Path -NonInteractive:$NonInteractive
    $resolvedTargetPath = $sourceResult.ResolvedPath
    $sourceMode = $sourceResult.SourceMode
    $originalInput = $sourceResult.OriginalInput
    $script:CloneCleanupInfo = $sourceResult.CloneCleanupInfo

    $script:EffectiveOutputDirectory = $resolvedTargetPath
    if ($sourceMode -eq 'github' -and $script:CloneCleanupInfo.CloneMode -eq 'temporary' -and -not $script:CloneCleanupInfo.KeepClone) {
        $script:EffectiveOutputDirectory = $script:OriginalWorkingDirectory.Path
    }

    $modulesDir = Join-Path $script:ToolkitDir 'modules'
    $requiredModulePaths = @(
        (Join-Path $modulesDir 'VibeDirectorProtocol.psm1'),
        (Join-Path $modulesDir 'VibeBundleWriter.psm1'),
        (Join-Path $modulesDir 'VibeSignatureExtractor.psm1'),
        (Join-Path $modulesDir 'VibeFileDiscovery.psm1')
        (Join-Path $modulesDir 'VibeExecutionFlow.psm1')
        (Join-Path $modulesDir 'VibeDeclaredFlowBridge.psm1')
    )

    foreach ($modulePath in $requiredModulePaths) {
        if (-not (Test-Path $modulePath -PathType Leaf)) {
            throw "Módulo obrigatório não encontrado: $modulePath"
        }
    }

    foreach ($modulePath in $requiredModulePaths) {
        $moduleContent = [System.IO.File]::ReadAllText($modulePath, [System.Text.Encoding]::UTF8)
        $scriptBlock = [scriptblock]::Create($moduleContent)
        $dynamicModuleName = [System.IO.Path]::GetFileNameWithoutExtension($modulePath)
        $dynamicModule = New-Module -Name $dynamicModuleName -ScriptBlock $scriptBlock
        Import-Module -ModuleInfo $dynamicModule -Force -DisableNameChecking -ErrorAction Stop
    }

    Set-Location $resolvedTargetPath
    $projectName = (Get-Item .).Name

    $executionStartedAt = Get-Date
    $resolvedBundleMode = Resolve-BundleMode -BundleMode $BundleMode -NonInteractive:$NonInteractive
    $resolvedRouteMode = Resolve-RouteMode -RouteMode $RouteMode -NonInteractive:$NonInteractive
    $choice = Resolve-ChoiceFromBundleMode -ModeValue $resolvedBundleMode
    $currentExtractionMode = Resolve-ExtractionModeFromBundleMode -ModeValue $resolvedBundleMode
    $currentDocumentMode = Resolve-DocumentModeFromExtractionMode -ExtractionMode $currentExtractionMode
    $isTxtExportMode = ($choice -eq '4')

    $foundFiles = @(Get-RelevantFiles -CurrentPath (Get-Location).Path | Sort-Object FullName)
    if ($foundFiles.Count -eq 0) {
        throw "Nenhum arquivo elegível foi encontrado em: $resolvedTargetPath"
    }

    $filesToProcess = @()
    $unselectedFiles = @()

    if ($choice -eq '3') {
        $resolvedSelectedPaths = @(Resolve-SniperRequestedPaths -ProjectRootPath (Get-Location).Path -AllFiles $foundFiles -RequestedPaths $SelectedPaths -NonInteractive:$NonInteractive)
        $filesToProcess = @(Resolve-SelectedFilesForSniper -ProjectRootPath (Get-Location).Path -AllFiles $foundFiles -RequestedPaths $resolvedSelectedPaths)
        $selectedMap = @{}
        foreach ($file in $filesToProcess) {
            $selectedMap[[System.IO.Path]::GetFullPath($file.FullName)] = $true
        }
        foreach ($file in $foundFiles) {
            $full = [System.IO.Path]::GetFullPath($file.FullName)
            if (-not $selectedMap.ContainsKey($full)) {
                $unselectedFiles += $file
            }
        }
    }
    else {
        $filesToProcess = @($foundFiles)
    }

    Write-SentinelOperationSummary -ProjectNameValue $projectName -BundleModeValue $resolvedBundleMode -RouteModeValue $resolvedRouteMode -ExecutorTargetValue $ExecutorTarget -OriginValue $resolvedTargetPath -EligibleCount $foundFiles.Count -OperationCount $filesToProcess.Count

    Write-SentinelExecutionStreamHeader -ChoiceValue $choice -ProjectNameValue $projectName -DiscoveredFileCount $foundFiles.Count -FilesToProcessCount $filesToProcess.Count -UnselectedFileCount $unselectedFiles.Count -EffectiveOutputDirectory $script:EffectiveOutputDirectory

    $baseExtraData = @{
        sourceMode               = $sourceMode
        originalInput            = $originalInput
        resolvedWorkingPath      = $resolvedTargetPath
        effectiveOutputDirectory = $script:EffectiveOutputDirectory
    }

    if ($script:CloneCleanupInfo) {
        $baseExtraData.cloneMode = $script:CloneCleanupInfo.CloneMode
        $baseExtraData.keepClone = $script:CloneCleanupInfo.KeepClone
        $baseExtraData.cleanupPerformed = $false
    }

    if ($isTxtExportMode) {
        $txtExportResult = Export-OperationFilesToTxtDirectory -Files $filesToProcess -ProjectRootPath (Get-Location).Path -BaseOutputDirectory $script:EffectiveOutputDirectory -ProjectNameValue $projectName -RouteMode $resolvedRouteMode

        Write-UILog -Message ("Artefato final TXT Export: {0}" -f $txtExportResult.ZipFilePath) -Color $ThemeSuccess
        Write-UILog -Message ("Staging interno removido: {0}" -f $txtExportResult.StagingDirectory) -Color $ThemeSuccess
        Write-UILog -Message ("Arquivos exportados: {0}" -f $txtExportResult.ExportedFiles.Count) -Color $ThemeSuccess

        if ($txtExportResult.SkippedFiles.Count -gt 0) {
            Write-UILog -Message ("Arquivos ignorados por incompatibilidade/erro: {0}" -f $txtExportResult.SkippedFiles.Count) -Color $ThemeWarn
        }

        $extraData = $baseExtraData.Clone()
        $extraData.finalArtifactPath = $txtExportResult.ZipFilePath
        $extraData.zipFilePath = $txtExportResult.ZipFilePath
        $extraData.stagingDirectory = $txtExportResult.StagingDirectory
        $extraData.stagingDirectoryRemoved = $txtExportResult.StagingDirectoryRemoved
        $extraData.exportedFiles = @($txtExportResult.ExportedFiles)
        $extraData.skippedFiles = @($txtExportResult.SkippedFiles)
        $extraData.exportedFileCount = $txtExportResult.ExportedFiles.Count
        $extraData.skippedFileCount = $txtExportResult.SkippedFiles.Count

        $durationMs = [int][Math]::Round(((Get-Date) - $executionStartedAt).TotalMilliseconds)
        $txtExportMetaResult = Write-LocalExecutionMeta -ProjectNameValue $projectName -RouteMode $resolvedRouteMode -ExtractionMode $currentExtractionMode -DocumentMode 'txt_export' -ExecutorTargetValue $ExecutorTarget -SourceArtifactPath $txtExportResult.ZipFilePath -OutputPath $txtExportResult.ZipFilePath -DurationMs $durationMs -ExtraData $extraData

        Write-UILog -Message ("Metadados locais salvos em: {0}" -f $txtExportMetaResult.ResultMetaPath) -Color $ThemeSuccess
        return
    }

    $headerContent = Get-VibeProtocolHeaderContent -RouteMode $resolvedRouteMode -ExtractionMode $currentExtractionMode -ExecutorTargetValue $ExecutorTarget
    $finalContent = $headerContent + "`n`n"
    $blueprintIssues = @()

    if ($choice -eq '1' -or $choice -eq '3') {
        if ($choice -eq '1') {
            $sourceArtifactFileName = Get-VibeArtifactFileName -ProjectNameValue $projectName -ExtractionMode $currentExtractionMode -RouteMode $resolvedRouteMode
            $headerTitle = 'MODO FULL'
            Write-UILog -Message 'Iniciando Modo Full...' -Color $ThemeCyan
        }
        else {
            $sourceArtifactFileName = Get-VibeArtifactFileName -ProjectNameValue $projectName -ExtractionMode $currentExtractionMode -RouteMode $resolvedRouteMode
            $headerTitle = 'MODO SNIPER'
            Write-UILog -Message 'Iniciando Modo Sniper...' -Color $ThemePink
        }

        Write-Host ''

        $finalContent += "## ${headerTitle}: $projectName`n`n"

        if ($choice -eq '3') {
            $finalContent += "### 0. ANALYSIS SCOPE`n```text`n"
            $finalContent += "ESCOPO: FECHADO / PARCIAL`n"
            $finalContent += "Este bundle contém apenas os arquivos selecionados manualmente pelo usuário.`n"
            if ($unselectedFiles.Count -gt 0) {
                $finalContent += "Os arquivos não selecionados foram anexados ao final em modo Bundler como contexto complementar.`n"
            }
            $finalContent += "Qualquer análise deve considerar exclusivamente o visível neste artefato.`n"
            $finalContent += "É proibido inferir módulos, dependências ou comportamento não visíveis.`n"
            $finalContent += "Quando faltar contexto, declarar: 'não visível no recorte enviado'.`n"
            $finalContent += "```\n\n"
        }

        Write-UILog -Message 'Montando estrutura do projeto...'
        $projectStructureTree = Get-ProjectStructureTree -Files $filesToProcess -ProjectRootPath (Get-Location).Path -ProjectName $projectName
        $finalContent += "## PROJECT STRUCTURE`n"
        $finalContent += (Convert-ToSafeMarkdownCodeBlock -Content $projectStructureTree -Language 'text') + "`n`n"

        Write-UILog -Message 'Lendo arquivos e consolidando conteúdo...'
        $finalContent += "### 2. SOURCE FILES`n`n"
        for ($index = 0; $index -lt $filesToProcess.Count; $index++) {
            $file = $filesToProcess[$index]
            $relPath = Resolve-Path -Path $file.FullName -Relative
            Write-SentinelProgress -Activity 'Consolidação' -Current ($index + 1) -Total $filesToProcess.Count -Tone 'Secondary' -Item $relPath
            $content = Read-LocalTextArtifact -Path $file.FullName
            if ($null -ne $content) {
                $content = $content -replace "(`r?`n){3,}", "`r`n`r`n"
                $finalContent += "#### File: $relPath`n"
                $finalContent += (Convert-ToSafeMarkdownCodeBlock -Content $content.TrimEnd() -Language 'text') + "`n`n"
            }
        }
        Write-Host ""

        if ($choice -eq '3' -and $unselectedFiles.Count -gt 0) {
            Write-UILog -Message 'Anexando arquivos não selecionados (modo Bundler)...' -Color $ThemeCyan
            $finalContent += "## ARQUIVOS NÃO SELECIONADOS INSERIDOS EM MODO BUNDLER`n`n"
            $finalContent += New-BundlerContractsBlock -Files $unselectedFiles -IssueCollector ([ref]$blueprintIssues) -StructureHeading '## PROJECT STRUCTURE' -ContractsHeading '### CORE DOMAINS & CONTRACTS (BUNDLER)' -LogExtraction
        }
    }
    else {
        $sourceArtifactFileName = Get-VibeArtifactFileName -ProjectNameValue $projectName -ExtractionMode $currentExtractionMode -RouteMode $resolvedRouteMode
        Write-UILog -Message 'Iniciando Modo Blueprint...' -Color $ThemeCyan
        Write-Host ''
        $finalContent += "## BLUEPRINT: $projectName`n`n"
        $finalContent += "### 0. BLUEPRINT CONTRACT`n"
        $finalContent += (Convert-ToSafeMarkdownCodeBlock -Content @'
Ler nesta ordem:
1. PROJECT STRUCTURE
2. CORE DOMAINS & CONTRACTS

Use apenas o recorte visível deste artefato.
Quando faltar contexto, declarar: não visível no recorte enviado.
A seção de contratos foi priorizada para entrypoints, contratos/tipos, integrações, orquestradores, protocolos, discovery, writers, extractors e módulos centrais de domínio.
'@.Trim() -Language 'text')
        $finalContent += "`n`n"
        $finalContent += "### 1. EXTERNAL DEPENDENCIES`n"

        $packageJsonPath = Join-Path (Get-Location).Path 'package.json'
        if (Test-Path $packageJsonPath -PathType Leaf) {
            try {
                Write-UILog -Message 'Lendo package.json para dependências externas do blueprint...'
                $pkg = (Read-LocalTextArtifact -Path $packageJsonPath) | ConvertFrom-Json
                $runtimeDeps = @()
                $devDeps = @()

                if ($pkg.dependencies) {
                    $runtimeDeps = @($pkg.dependencies.PSObject.Properties.Name | Sort-Object -Unique)
                }

                if ($pkg.devDependencies) {
                    $devDeps = @($pkg.devDependencies.PSObject.Properties.Name | Sort-Object -Unique)
                }

                if ($runtimeDeps.Count -gt 0) { $finalContent += "* **Runtime:** $(($runtimeDeps -join ', '))`n" }
                if ($devDeps.Count -gt 0) { $finalContent += "* **Dev:** $(($devDeps -join ', '))`n" }
                if ($runtimeDeps.Count -eq 0 -and $devDeps.Count -eq 0) { $finalContent += "* Nenhuma dependência declarada no package.json.`n" }
            }
            catch {
                Write-UILog -Message 'package.json existe, mas não pôde ser lido. Seguindo sem dependências externas declaradas.' -Color $ThemeWarn
                $finalContent += "* package.json presente, mas não legível no recorte local.`n"
            }
        }
        else {
            Write-UILog -Message 'package.json não encontrado; dependências externas serão omitidas do blueprint.' -Color $ThemeWarn
            $finalContent += "* package.json não visível no recorte local.`n"
        }
        
        Write-Host ''

        $finalContent += "`n"
        $finalContent += New-BlueprintContractsBlock -Files $filesToProcess -IssueCollector ([ref]$blueprintIssues) -StructureHeading '## PROJECT STRUCTURE' -ContractsHeading '### 3. CORE DOMAINS & CONTRACTS' -LogExtraction
    }

    $sourceArtifactPath = Join-Path $script:EffectiveOutputDirectory $sourceArtifactFileName
    $finalOutputPath = $sourceArtifactPath
    $persistSourceArtifact = $true
    $generateDeterministicMetaPrompt = (($currentExtractionMode -eq 'full') -or ($currentExtractionMode -eq 'blueprint') -or (($currentExtractionMode -eq 'sniper') -and ($resolvedRouteMode -eq 'director')))

    if ($generateDeterministicMetaPrompt -and ($currentExtractionMode -eq 'full' -or $currentExtractionMode -eq 'blueprint')) {
        $persistSourceArtifact = $false
    }

    if ($persistSourceArtifact) {
        Write-LocalTextArtifact -Path $sourceArtifactPath -Content $finalContent -UseBom
    }
    elseif (Test-Path $sourceArtifactPath -PathType Leaf) {
        Remove-Item -Path $sourceArtifactPath -Force -ErrorAction SilentlyContinue
    }

    Reset-SentinelTransientConsoleLine

    if ($generateDeterministicMetaPrompt) {
        $deterministicOutputFile = Get-DeterministicMetaPromptOutputFileName -ProjectNameValue $projectName -ExtractionMode $currentExtractionMode -RouteMode $resolvedRouteMode
        $deterministicOutputPath = Join-Path $script:EffectiveOutputDirectory $deterministicOutputFile

        Write-Host ''
        Write-UILog -Message 'Compilando meta-prompt determinístico local diretamente no bundler...' -Color $ThemeCyan
        $deterministicContent = New-DeterministicMetaPromptArtifact -ProjectNameValue $projectName -ExecutorTargetValue $ExecutorTarget -ExtractionMode $currentExtractionMode -DocumentMode $currentDocumentMode -RouteMode $resolvedRouteMode -SourceArtifactFileName $sourceArtifactFileName -OutputArtifactFileName $deterministicOutputFile -BundleContent $finalContent -Files $filesToProcess

        Write-LocalTextArtifact -Path $deterministicOutputPath -Content $deterministicContent -UseBom
        $finalOutputPath = $deterministicOutputPath

        Write-UILog -Message ("Meta-prompt salvo em: {0}" -f $deterministicOutputPath) -Color $ThemeSuccess
    }

    Reset-SentinelTransientConsoleLine

    if ($blueprintIssues -and $blueprintIssues.Count -gt 0) {
        Write-Host ''
        Write-UILog -Message ("Artefato gerado com {0} aviso(s)." -f $blueprintIssues.Count) -Color $ThemeWarn
        foreach ($issue in ($blueprintIssues | Select-Object -First 10)) {
            Write-UILog -Message $issue -Color $ThemeWarn
        }
    }
    else {
        Write-UILog -Message 'Artefato consolidado com sucesso.' -Color $ThemeSuccess
    }

    $durationMs = [int][Math]::Round(((Get-Date) - $executionStartedAt).TotalMilliseconds)
    $extraData = $baseExtraData.Clone()
    $extraData.sourceArtifactFile = $sourceArtifactFileName
    $extraData.outputArtifactFile = [System.IO.Path]::GetFileName($finalOutputPath)
    $extraData.fileCount = $filesToProcess.Count
    $extraData.unselectedFileCount = $unselectedFiles.Count
    $extraData.generatedFromLocalGovernance = $true

    $sentinelFlowRuntime = Invoke-SentinelDeclaredFinalizationFlow `
        -ToolkitDir $script:ToolkitDir `
        -ProjectNameValue $projectName `
        -ExecutorTargetValue $ExecutorTarget `
        -ExtractionMode $currentExtractionMode `
        -DocumentMode $currentDocumentMode `
        -RouteMode $resolvedRouteMode `
        -SourceArtifactFileName $sourceArtifactFileName `
        -OutputArtifactFileName ([System.IO.Path]::GetFileName($finalOutputPath)) `
        -BundleContent $finalContent `
        -Files $filesToProcess `
        -MetaPromptOutputPath $finalOutputPath `
        -SignatureExtractor {
            param($file, [ref]$issueMessage)
            Get-BundlerSignaturesForFile -File $file -IssueMessage $issueMessage
        } `
        -MetaPromptBuilder {
            param($flowState)
            New-DeterministicMetaPromptArtifact `
                -ProjectNameValue $flowState.ProjectNameValue `
                -ExecutorTargetValue $flowState.ExecutorTargetValue `
                -ExtractionMode $flowState.ExtractionMode `
                -DocumentMode $flowState.DocumentMode `
                -RouteMode $flowState.RouteMode `
                -SourceArtifactFileName $flowState.SourceArtifactFileName `
                -OutputArtifactFileName $flowState.OutputArtifactFileName `
                -BundleContent $flowState.BundleContent `
                -Files $flowState.Files
        } `
        -ArtifactWriter {
            param($path, $content)
            Write-LocalTextArtifact -Path $path -Content $content -UseBom
        } `
        -LogWriter {
            param($message)
            if (Get-Command -Name Write-UILog -ErrorAction SilentlyContinue) {
                Write-UILog -Message $message
            }
            else {
                Write-Host $message
            }
        }

    if ($sentinelFlowRuntime) {
        $extraData.executionFlow = @{
            flowId     = $sentinelFlowRuntime.flowId
            sourcePath = $sentinelFlowRuntime.sourcePath
            status     = $sentinelFlowRuntime.status
            startedAt  = $sentinelFlowRuntime.startedAt
            finishedAt = $sentinelFlowRuntime.finishedAt
            durationMs   = $sentinelFlowRuntime.durationMs
            fallbackCount = $sentinelFlowRuntime.fallbackCount
            steps        = @($sentinelFlowRuntime.steps)
        }

        $extraData.stepAudit = @($sentinelFlowRuntime.steps)
    }

    $resultMetaPath = Join-Path $script:EffectiveOutputDirectory ([System.IO.Path]::GetFileNameWithoutExtension($finalOutputPath) + '.json')
    $metaSourceArtifactPath = if ($persistSourceArtifact) { $sourceArtifactPath } else { $null }
    $metaResult = Write-LocalExecutionMeta -ProjectNameValue $projectName -RouteMode $resolvedRouteMode -ExtractionMode $currentExtractionMode -DocumentMode $currentDocumentMode -ExecutorTargetValue $ExecutorTarget -SourceArtifactPath $metaSourceArtifactPath -OutputPath $finalOutputPath -ResultMetaPath $resultMetaPath -DurationMs $durationMs -ExtraData $extraData

    Reset-SentinelTransientConsoleLine
    Write-Host ''
    Write-SentinelSection -Title '[^_^] SUCESSO' -Tone 'Success'
    $artifactName = [System.IO.Path]::GetFileName($finalOutputPath)
    $metaName = [System.IO.Path]::GetFileName($metaResult.ResultMetaPath)

    # Trunca nomes de arquivo muito longos para evitar quebra de linha
    $displayArtifact = Get-SentinelCompactDisplayText -Text $artifactName -MaxLength 50
    $displayMeta = Get-SentinelCompactDisplayText -Text $metaName -MaxLength 50

    # Compacta o diretório de destino (já existia a lógica "mesmo diretório")
    $currentDir = (Get-Location).Path
    $displayDestino = if ($script:EffectiveOutputDirectory -eq $currentDir) {
        "mesmo diretório ($projectName)"
    }
    else {
        Get-SentinelCompactDisplayText -Text $script:EffectiveOutputDirectory -MaxLength 60
    }

    Write-SentinelKeyValue -Key 'Artefato' -Value $displayArtifact -Tone 'Success' -KeyWidth 12
    Write-SentinelKeyValue -Key 'Metadata' -Value $displayMeta -Tone 'Secondary' -KeyWidth 12
    Write-SentinelKeyValue -Key 'Destino' -Value $displayDestino -Tone 'Secondary' -KeyWidth 12
    Write-Host ''
    Write-SentinelPostSuccessGuidance -RouteMode $resolvedRouteMode -ArtifactPath $finalOutputPath -MetadataPath $metaResult.ResultMetaPath
}
catch {
    $errorMessage = $_.Exception.Message
    Write-UILog -Message ("Falha na execução: {0}" -f $errorMessage) -Color $ThemePink
    throw
}
finally {
    if ($script:CloneCleanupInfo -and $script:CloneCleanupInfo.CreatedByUs -and -not $script:CloneCleanupInfo.KeepClone) {
        $clonePath = $script:CloneCleanupInfo.Path
        if (Test-Path $clonePath -PathType Container) {
            if ($script:OriginalWorkingDirectory) {
                Set-Location $script:OriginalWorkingDirectory.Path -ErrorAction SilentlyContinue
            }

            try {
                Remove-Item -Path $clonePath -Recurse -Force -ErrorAction Stop
                Write-UILog -Message ("Clone temporário removido: {0}" -f $clonePath) -Color $ThemeSuccess
                if ($script:CloneCleanupInfo.ContainsKey('cleanupPerformed')) {
                    $script:CloneCleanupInfo.cleanupPerformed = $true
                }
            }
            catch {
                Write-UILog -Message ("Não foi possível remover o clone temporário: {0}. Erro: {1}" -f $clonePath, $_.Exception.Message) -Color $ThemeWarn
            }
        }
    }
}

#### File: .\project-bundler-headless.ps1
# Política de runtime: PowerShell 7 preferencial; Windows PowerShell 5.1 como fallback operacional.

<#
.SYNOPSIS
    Shim/Wrapper para a engine canônica (project-bundler-cli.ps1).
    Mantido para preservar contratos de integração e invocação visual (via VBS/atalhos).
#>

[CmdletBinding()]
param(
    [string]$Path = ".",
    [Alias('Mode')]
    [string]$BundleMode = '',
    [string[]]$SelectedPaths,
    [string]$RouteMode = '',
    [string]$ExecutorTarget = 'IA Generativa (GenAI)',
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$cliScript = Join-Path $PSScriptRoot 'project-bundler-cli.ps1'

if (-not (Test-Path $cliScript -PathType Leaf)) {
    throw "Erro Crítico: A engine canônica CLI não foi encontrada em: $cliScript`no wrapper headless requer a CLI para funcionar."
}

& $cliScript @PSBoundParameters

#### File: .\README.md
# VibeToolkit

O VibeToolkit é um toolkit para empacotar contexto técnico de um projeto, gerar recortes mais enxutos quando for preciso e produzir artefatos prontos para uso em fluxos com IA.

Ele foi pensado para um uso bem operacional: rodar no terminal, apontar para um projeto e sair com um bundle, um blueprint, um recorte manual ou uma exportação em texto, dependendo do que você precisa.

> PowerShell 7 é o caminho principal. No Windows, o script ainda aceita fallback para Windows PowerShell 5.1 quando necessário.

---

## O que ele faz

Na prática, o toolkit cobre estes cenários:

- juntar o contexto relevante de um projeto em um artefato só
- gerar uma visão mais estrutural e econômica do código, focada em contratos e pontos de integração
- montar recortes manuais quando você não quer mandar o projeto inteiro
- exportar conteúdo em `.txt` + `.zip` para fluxos que não lidam bem com Markdown
- separar a saída entre rota **director** e rota **executor**
- gravar metadata local da execução em JSON

---

## Requisitos

### Windows

- PowerShell 7 recomendado
- Windows PowerShell 5.1 como fallback

### Linux e macOS

- PowerShell 7 (`pwsh`)

O menu de contexto é um recurso do Windows. Em Linux e macOS, o uso é direto pela CLI.

---

## Instalação e uso rápido

No Windows, o jeito mais simples é usar o instalador principal:

.\Instalar VibeToolkit.cmd

Quando você executa esse arquivo sem argumentos, o comportamento é o seguinte:

- se o VibeToolkit ainda não estiver instalado, ele faz a instalação
- se já estiver instalado, ele pergunta se você quer **Repair**, **Uninstall** ou **Cancelar**

Também dá para chamar diretamente com argumento:

.\Instalar VibeToolkit.cmd /install
.\Instalar VibeToolkit.cmd /repair
.\Instalar VibeToolkit.cmd /uninstall

### Execução direta pela CLI

.\project-bundler-cli.ps1

### Wrapper headless

.\project-bundler-headless.ps1

### Observação sobre o instalador

O instalador gera automaticamente o arquivo `run-vibe-headless.vbs` quando necessário para a integração com o menu de contexto do Windows. Esse arquivo não precisa ficar exposto como entrada principal do repositório.

---

## Modos operacionais

### Extraction mode

| Modo | Quando usar | Saída típica |
| --- | --- | --- |
| `full` | quando você quer o máximo de contexto visível do projeto | bundle Markdown + metadata JSON |
| `blueprint` | quando o foco é estrutura, contratos e integração com menos custo | blueprint Markdown + metadata JSON |
| `sniper` | quando você quer mandar só um recorte manual e controlado | bundle manual Markdown + metadata JSON |
| `txtExport` | quando o destino prefere `.txt` em vez de bundle Markdown | ZIP final + metadata JSON |

### Leituras rápidas por modo

#### Full

Melhor quando a outra ponta precisa de visão ampla: código, docs, configs e estrutura.

#### Blueprint

Melhor quando o objetivo é entender arquitetura, contratos, entrypoints e integrações sem carregar contexto demais.

#### Sniper

Melhor quando você já sabe quais arquivos importam e quer um recorte cirúrgico.

#### TXT Export

Melhor quando o ambiente de destino não lida bem com Markdown. Nesse modo, o toolkit gera os `.txt`, compacta o resultado e deixa o `.zip` como artefato final.

---

## Rotas

| Rota | Objetivo |
| --- | --- |
| `director` | gerar um artefato analítico com framing mais forte |
| `executor` | gerar um artefato final pronto para uso direto |

### Quando usar `director`

Quando você quer passar o contexto para outra IA junto com uma camada mais explícita de enquadramento operacional.

### Quando usar `executor`

Quando você quer a saída mais direta possível, pronta para colar e usar.

---

## Exemplos de uso

### Full + Executor

.\project-bundler-cli.ps1 -NonInteractive -BundleMode full -RouteMode executor

### Blueprint + Director

.\project-bundler-cli.ps1 -NonInteractive -BundleMode blueprint -RouteMode director

### Sniper com seleção antecipada

.\project-bundler-cli.ps1 -BundleMode sniper -SelectedPaths ".\src\*.ps1", ".\README.md"

### TXT Export + Executor

.\project-bundler-cli.ps1 -NonInteractive -BundleMode txtExport -RouteMode executor

---

## Artefatos gerados

Os nomes seguem uma convenção por modo e rota. Exemplos:

_bundle_executor__MeuProjeto.md
_blueprint_diretor__MeuProjeto.md
_meta-prompt_blueprint_diretor__MeuProjeto.md
_manual_executor__MeuProjeto.md
_txt_export_executor__MeuProjeto.zip
_bundle_executor__MeuProjeto.json

### Leitura rápida dos prefixos

- `bundle`: contexto completo
- `blueprint`: visão estrutural e arquitetural
- `manual`: recorte sniper
- `meta-prompt`: framing da rota director
- `txt_export`: exportação ZIP do modo TXT Export
- `.json`: metadata da execução

---

## Estrutura do projeto

VibeToolkit/
├── Instalar VibeToolkit.cmd
├── project-bundler-cli.ps1
├── project-bundler-headless.ps1
├── lib/
│   └── SentinelUI.ps1
├── modules/
│   ├── VibeBundleWriter.psm1
│   ├── VibeDirectorProtocol.psm1
│   ├── VibeFileDiscovery.psm1
│   └── VibeSignatureExtractor.psm1
└── README.md

### Papel dos arquivos principais

- **`Instalar VibeToolkit.cmd`**: ponto de entrada de instalação, reparo e remoção no Windows
- **`project-bundler-cli.ps1`**: engine principal
- **`project-bundler-headless.ps1`**: wrapper headless para integração operacional
- **`modules/*`**: descoberta, escrita, protocolo e extração de assinaturas
- **`lib/SentinelUI.ps1`**: camada visual usada pelo terminal

---

## Comportamento relevante

### Descoberta de arquivos

O toolkit ignora artefatos já gerados e trabalha só com arquivos elegíveis do projeto.

### Metadata local

Toda execução gera um JSON de metadata ao lado do artefato final correspondente.

### Política de runtime

A regra é simples:

- tentar `pwsh` primeiro
- usar `powershell.exe` apenas como fallback no Windows
- em Linux/macOS, seguir com `pwsh`

---

## Resumo

O VibeToolkit tenta resolver um problema bem específico: preparar contexto técnico de forma organizada, com pouco atrito, sem depender de improviso a cada execução.

Se a ideia é mandar o projeto inteiro, fazer um recorte mais econômico ou montar um bundle manual, o toolkit já cobre esse caminho sem exigir uma coreografia de scripts soltos na raiz.

#### File: .\run-vibe-headless.vbs
' Generated by Instalar VibeToolkit.cmd
Option Explicit

Dim fso
Dim shell
Dim scriptDir
Dim psScript
Dim targetPath
Dim powerShellExe
Dim innerCommand
Dim command

Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
psScript = fso.BuildPath(scriptDir, "project-bundler-headless.ps1")

If Not fso.FileExists(psScript) Then
    MsgBox "Arquivo obrigatorio nao encontrado: " & psScript, vbCritical, "VibeToolkit"
    WScript.Quit 1
End If

targetPath = "."
If WScript.Arguments.Count > 0 Then
    targetPath = Trim(CStr(WScript.Arguments(0)))
    If Len(targetPath) = 0 Then
        targetPath = "."
    End If
End If

powerShellExe = ResolvePowerShellExecutable(shell, fso)
If Len(powerShellExe) = 0 Then
    MsgBox "PowerShell nao encontrado no sistema.", vbCritical, "VibeToolkit"
    WScript.Quit 1
End If

innerCommand = Quote(powerShellExe) & _
    " -NoProfile -ExecutionPolicy Bypass -File " & Quote(psScript) & _
    " -Path " & Quote(targetPath)

command = "cmd.exe /k " & Quote(innerCommand)

shell.Run command, 1, False

Function ResolvePowerShellExecutable(shellObject, fileSystemObject)
    Dim commandPath
    Dim candidates
    Dim i

    commandPath = shellObject.ExpandEnvironmentStrings("%ProgramFiles%\PowerShell\7\pwsh.exe")
    If fileSystemObject.FileExists(commandPath) Then
        ResolvePowerShellExecutable = commandPath
        Exit Function
    End If

    commandPath = shellObject.ExpandEnvironmentStrings("%ProgramW6432%\PowerShell\7\pwsh.exe")
    If fileSystemObject.FileExists(commandPath) Then
        ResolvePowerShellExecutable = commandPath
        Exit Function
    End If

    commandPath = shellObject.ExpandEnvironmentStrings("%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe")
    If fileSystemObject.FileExists(commandPath) Then
        ResolvePowerShellExecutable = commandPath
        Exit Function
    End If

    candidates = Array("pwsh.exe", "powershell.exe")
    For i = LBound(candidates) To UBound(candidates)
        commandPath = ResolveCommandPath(shellObject, candidates(i))
        If Len(commandPath) > 0 Then
            ResolvePowerShellExecutable = commandPath
            Exit Function
        End If
    Next

    ResolvePowerShellExecutable = ""
End Function

Function ResolveCommandPath(shellObject, commandName)
    Dim execObject
    Dim resolved

    On Error Resume Next
    Set execObject = shellObject.Exec("cmd.exe /c where " & commandName)
    If Err.Number <> 0 Then
        Err.Clear
        ResolveCommandPath = ""
        Exit Function
    End If
    On Error GoTo 0

    If execObject.StdOut.AtEndOfStream Then
        ResolveCommandPath = ""
        Exit Function
    End If

    resolved = Trim(execObject.StdOut.ReadLine)
    If Len(resolved) = 0 Then
        ResolveCommandPath = ""
    Else
        ResolveCommandPath = resolved
    End If
End Function

Function Quote(value)
    Quote = Chr(34) & value & Chr(34)
End Function

#### File: .\vibe-toolkit.Tests.ps1
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
````