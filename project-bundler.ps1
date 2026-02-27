# =================================================================
# VIBE AI TOOLKIT - BUNDLER, BLUEPRINT & SELECTIVE
# =================================================================

[CmdletBinding()]
param([string]$Path = ".")

# Força o console a usar UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-Location $Path

$ProjectName = (Get-Item .).Name
$ScriptFullPath = $MyInvocation.MyCommand.Path
$ToolkitDir = Split-Path $ScriptFullPath

# ==========================================
# 1. MENU INTERATIVO
# ==========================================
Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "          VIBE AI TOOLKIT - $ProjectName          " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Escolha o modo de extração de contexto:"
Write-Host ""
Write-Host "[ 1 ] BUNDLER   (Código Completo - Todos os arquivos mapeados)" -ForegroundColor Yellow
Write-Host "[ 2 ] BLUEPRINT (Apenas Arquitetura e Assinaturas TypeScript)" -ForegroundColor Green
Write-Host "[ 3 ] SELECTIVE (Escolha manual de arquivos específicos)" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

$Choice = Read-Host "Digite 1, 2 ou 3"

if ($Choice -notmatch '^[123]$') {
    Write-Warning "Opção inválida. Saindo..."
    Start-Sleep -Seconds 2
    exit
}

# ==========================================
# 2. CONFIGURAÇÕES & REGRAS (WHITELIST/BLACKLIST)
# ==========================================
$AllowedExtensions = @(".tsx", ".ts", ".js", ".jsx", ".css", ".html", ".json", ".prisma", ".sql", ".yaml", ".md")
$SignatureExtensions = @(".tsx", ".ts", ".js", ".jsx", ".prisma")

$IgnoredDirs = @(
    "node_modules", ".git", "dist", "build", ".next", ".cache", "out",
    "android", "ios", "coverage"
)

$IgnoredFiles = @(
    "package-lock.json", "pnpm-lock.yaml", "yarn.lock", 
    ".DS_Store", "metadata.json", ".gitignore",
    "google-services.json", "capacitor.config.json", 
    "capacitor.plugins.json", "cordova.js", "cordova_plugins.js"
)

# Instrução base mantida para o artefato bruto, caso você decida lê-lo diretamente
$SystemInstruction = @"
<system_instruction>
ROLE: SENIOR_FULLSTACK_ARCHITECT_EXECUTOR
DETERMINISM_MODE: LOW_ENTROPY
OUTPUT_VARIANCE: MINIMIZED
</system_instruction>

"@

# ==========================================
# 3. MOTOR DE TRAVESSIA (Coleta de Arquivos)
# ==========================================
Write-Host "`nMapeando arquivos do projeto..." -ForegroundColor Gray

function Get-RelevantFiles {
    param([string]$CurrentPath)
    try {
        $Items = Get-ChildItem -Path $CurrentPath -ErrorAction Stop
        foreach ($Item in $Items) {
            if ($Item.PSIsContainer) {
                if ($Item.Name -notin $IgnoredDirs) { Get-RelevantFiles -CurrentPath $Item.FullName }
            } else {
                $IsTarget = ($Item.Extension -in $AllowedExtensions) -and 
                            ($Item.Name -notin $IgnoredFiles) -and 
                            ($Item.Name -notmatch "-[a-zA-Z0-9]{8,}\.") -and
                            ($Item.FullName -ne $ScriptFullPath) -and
                            ($Item.Name -notmatch "^_BUNDLER__") -and
                            ($Item.Name -notmatch "^_BLUEPRINT__") -and
                            ($Item.Name -notmatch "^_SELECTIVE__") -and
                            ($Item.Name -notmatch "^_AI_CONTEXT_")

                if ($IsTarget) { $Item }
            }
        }
    } catch { Write-Warning "Acesso negado: $CurrentPath" }
}

$FoundFiles = @(Get-RelevantFiles -CurrentPath (Get-Location).Path)

if ($FoundFiles.Count -eq 0) {
    Write-Warning "Nenhum arquivo relevante encontrado!"
    Pause
    exit
}

# ==========================================
# 4. SELEÇÃO DE ARQUIVOS (APENAS MODO 3)
# ==========================================
$FilesToProcess = $FoundFiles

if ($Choice -eq '3') {
    Write-Host "`n==================================================" -ForegroundColor Magenta
    Write-Host "          SELEÇÃO MANUAL DE ARQUIVOS              " -ForegroundColor Magenta
    Write-Host "==================================================" -ForegroundColor Magenta
    
    for ($i = 0; $i -lt $FoundFiles.Count; $i++) {
        $RelPath = Resolve-Path -Path $FoundFiles[$i].FullName -Relative
        Write-Host ("[{0,3}] {1}" -f $i, $RelPath)
    }
    
    Write-Host "==================================================" -ForegroundColor Magenta
    $SelectionStr = Read-Host "`nDigite os NÚMEROS dos arquivos que deseja (ex: 0, 2, 5 ou 0 2 5)"
    
    $SelectedIndices = $SelectionStr -split '[, ]+' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
    
    $FilesToProcess = @()
    foreach ($Index in $SelectedIndices) {
        if ($Index -ge 0 -and $Index -lt $FoundFiles.Count) {
            if ($FilesToProcess -notcontains $FoundFiles[$Index]) {
                $FilesToProcess += $FoundFiles[$Index]
            }
        }
    }
    
    if ($FilesToProcess.Count -eq 0) {
        Write-Warning "`nNenhum arquivo válido selecionado. Cancelando operação..."
        Pause
        exit
    }
}

# ==========================================
# 5. PROCESSAMENTO BASEADO NA ESCOLHA
# ==========================================
$FinalContent = ""

if ($Choice -eq '1' -or $Choice -eq '3') {
    if ($Choice -eq '1') {
        $OutputFile = "_BUNDLER__${ProjectName}.txt"
        Write-Host "Modo BUNDLER ativado. Consolidando código fonte..." -ForegroundColor Yellow
    } else {
        $OutputFile = "_SELECTIVE__${ProjectName}.txt"
        Write-Host "Modo SELECTIVE ativado. Consolidando $($FilesToProcess.Count) arquivo(s)..." -ForegroundColor Magenta
    }
    
    $FinalContent += $SystemInstruction
    $FinalContent += "<project_structure>`n"
    foreach ($File in $FilesToProcess) { $FinalContent += (Resolve-Path -Path $File.FullName -Relative) + "`n" }
    $FinalContent += "</project_structure>`n"

    foreach ($File in $FilesToProcess) {
        $RelPath = Resolve-Path -Path $File.FullName -Relative
        $Content = Get-Content $File.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($Content) {
            $Content = $Content -replace "(`r?`n){3,}", "`r`n`r`n"
            $FinalContent += "`n<file path=""$RelPath"">`n$Content`n</file>`n"
        }
    }

} else {
    $OutputFile = "_BLUEPRINT__${ProjectName}.md"
    Write-Host "Modo BLUEPRINT ativado. Extraindo contratos de arquitetura..." -ForegroundColor Green
    
    $FinalContent += $SystemInstruction
    $FinalContent += "# PROJECT BLUEPRINT: $ProjectName`n`n"
    
    $FinalContent += "## 1. TECH STACK`n"
    if (Test-Path "package.json") {
        $Pkg = Get-Content "package.json" | ConvertFrom-Json
        $FinalContent += "* **Deps:** $( ($Pkg.dependencies.PSObject.Properties.Name -join ", ") )`n"
        if ($Pkg.devDependencies) { $FinalContent += "* **Dev Deps:** $( ($Pkg.devDependencies.PSObject.Properties.Name -join ", ") )`n" }
    }
    $FinalContent += "`n"

    $FinalContent += "## 2. PROJECT STRUCTURE`n```text`n"
    foreach ($File in $FilesToProcess) { $FinalContent += (Resolve-Path -Path $File.FullName -Relative) + "`n" }
    $FinalContent += "````n`n"

    $FinalContent += "## 3. CORE DOMAINS & CONTRACTS`n"
    foreach ($File in $FilesToProcess) {
        if ($SignatureExtensions -contains $File.Extension) {
            $RelPath = Resolve-Path -Path $File.FullName -Relative
            $ContentRaw = Get-Content $File.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if (-not $ContentRaw) { continue }
            
            $Matches = [regex]::Matches($ContentRaw, 'export\s+(interface|type|enum|const|function|class)\s+([A-Za-z0-9_]+)')
            if ($Matches.Count -gt 0) {
                $FinalContent += "### File: $RelPath`n```typescript`n"
                $Lines = Get-Content $File.FullName -Encoding UTF8
                for ($i = 0; $i -lt $Lines.Count; $i++) {
                    $Line = $Lines[$i].Trim()
                    if ($Line -match '^export\s+(interface|type|enum)') {
                        $FinalContent += "$Line`n"
                        if ($Line -notmatch '\}' -and $Line -notmatch ' = ') {
                            $j = $i + 1
                            while ($j -lt $Lines.Count -and $Lines[$j] -notmatch '^\}') {
                                $FinalContent += "$($Lines[$j])`n"
                                $j++
                            }
                            if ($j -lt $Lines.Count) { $FinalContent += "$($Lines[$j])`n" }
                            $i = $j
                        }
                    } elseif ($Line -match '^export\s+(const|function|class)') {
                        $Signature = $Line -replace '\{.*$', '' -replace '\s*=>.*$', ''
                        $FinalContent += "$Signature`n"
                    }
                }
                $FinalContent += "````n`n"
            }
        }
    }
}

# ==========================================
# 6. SALVAMENTO (UTF-8 PURO) E ÁREA DE TRANSFERÊNCIA
# ==========================================
$OutputFullPath = Join-Path (Get-Location) $OutputFile

$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($OutputFullPath, $FinalContent, $Utf8NoBom)

$TokenEstimate = [math]::Round($FinalContent.Length / 4)

try {
    $FinalContent | Set-Clipboard
    $Copied = $true
} catch {
    $Copied = $false
}

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host "ARTEFATO BRUTO CONSOLIDADO!"

if ($Choice -eq '1') { $ModoNome = "BUNDLER" }
elseif ($Choice -eq '2') { $ModoNome = "BLUEPRINT" }
else { $ModoNome = "SELECTIVE" }

Write-Host "Modo     : $ModoNome"
Write-Host "Arquivo  : $OutputFile"
Write-Host "Tokens   : ~$TokenEstimate (Estimativa bruta)"
if ($Copied) { Write-Host "Status   : Copiado para a área de transferência." }
else { Write-Host "Status   : Arquivo salvo localmente." -ForegroundColor Yellow }
Write-Host "==================================================" -ForegroundColor Green

# ==========================================
# 7. GERAÇÃO DE CONTEXTO COM IA (GROQ)
# ==========================================
Write-Host "`nDeseja que a IA analise este artefato e gere um AI Context Document otimizado? (S/N)" -ForegroundColor Cyan
$SendToAI = Read-Host
if ($SendToAI -match '^[Ss]$') {
    Write-Host "`nAnalisando arquitetura e gerando documentação. Aguarde..." -ForegroundColor Yellow
    
    $AgentScript = Join-Path $ToolkitDir "groq-agent.ts"
    
    if (Test-Path $AgentScript) {
        cmd.exe /c npx tsx `"$AgentScript`" `"$OutputFullPath`" `"$ProjectName`"
        Write-Host "`nFinalizado. Verifique o arquivo _AI_CONTEXT_$ProjectName.md na pasta do projeto." -ForegroundColor Green
    } else {
        Write-Warning "Arquivo groq-agent.ts não encontrado em: $ToolkitDir"
    }
} else {
    Write-Host "Operação concluída. IA não acionada." -ForegroundColor Gray
}

Write-Host ""
Pause