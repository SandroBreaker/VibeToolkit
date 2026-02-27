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
Write-Host "Selecione o modo de extração de contexto:`n"
Write-Host " [ 1 ] BUNDLER   (Código Completo - Todos os arquivos)" -ForegroundColor Yellow
Write-Host " [ 2 ] BLUEPRINT (Arquitetura e Assinaturas TypeScript)" -ForegroundColor Green
Write-Host " [ 3 ] SELECTIVE (Escolha manual de arquivos específicos)" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

$Choice = Read-Host "Opção (1, 2 ou 3)"

if ($Choice -notmatch '^[123]$') {
    Write-Warning "Opção inválida. Operação abortada."
    Start-Sleep -Seconds 2
    exit
}

# ==========================================
# 2. CONFIGURAÇÕES & REGRAS
# ==========================================
$AllowedExtensions = @(
    ".tsx", ".ts", ".js", ".jsx", ".css", ".html", ".json", ".prisma", ".sql", ".yaml", ".md",
    ".py", ".java", ".cs", ".c", ".cpp", ".h", ".hpp", ".go", ".rb", ".php", ".rs", ".swift", ".kt", ".scala", ".dart", ".r", ".sh", ".bat", ".ps1"
)
$SignatureExtensions = @(
    ".tsx", ".ts", ".js", ".jsx", ".prisma", 
    ".py", ".java", ".cs", ".go", ".rb", ".php", ".rs", ".swift", ".kt", ".scala", ".dart"
)

$IgnoredDirs = @(
    "node_modules", ".git", "dist", "build", ".next", ".cache", "out",
    "android", "ios", "coverage", ".venv", "venv", "env", "__pycache__",
    ".pytest_cache", ".tox", "bin", "obj", "target", "vendor"
)

$IgnoredFiles = @(
    "package-lock.json", "pnpm-lock.yaml", "yarn.lock", 
    ".DS_Store", "metadata.json", ".gitignore",
    "google-services.json", "capacitor.config.json", 
    "capacitor.plugins.json", "cordova.js", "cordova_plugins.js",
    "poetry.lock", "Pipfile.lock", "Cargo.lock", "go.sum", "composer.lock"
)

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
Write-Host "`n[+] Mapeando arquivos da árvore do projeto..." -ForegroundColor DarkGray

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
    Write-Warning "Nenhum arquivo válido encontrado no diretório."
    Pause
    exit
}

# ==========================================
# 4. SELEÇÃO DE ARQUIVOS (MODO 3)
# ==========================================
$FilesToProcess = $FoundFiles

if ($Choice -eq '3') {
    Write-Host "`n==================================================" -ForegroundColor Magenta
    Write-Host "              SELEÇÃO MANUAL DE ARQUIVOS          " -ForegroundColor Magenta
    Write-Host "==================================================" -ForegroundColor Magenta
    
    for ($i = 0; $i -lt $FoundFiles.Count; $i++) {
        $RelPath = Resolve-Path -Path $FoundFiles[$i].FullName -Relative
        Write-Host (" [{0,3}] {1}" -f $i, $RelPath)
    }
    
    Write-Host "==================================================" -ForegroundColor Magenta
    $SelectionStr = Read-Host "`nÍndices dos arquivos (ex: 0, 2, 5 ou 0 2 5)"
    
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
        Write-Warning "`nNenhum arquivo selecionado. Abortando."
        Pause
        exit
    }
}

# ==========================================
# 5. PROCESSAMENTO E GERAÇÃO DE MARKDOWN
# ==========================================
$FinalContent = ""

if ($Choice -eq '1' -or $Choice -eq '3') {
    if ($Choice -eq '1') {
        $OutputFile = "_BUNDLER__${ProjectName}.md"
        Write-Host "`n[>] Executando BUNDLER: Consolidando $($FilesToProcess.Count) arquivo(s)..." -ForegroundColor Yellow
        $HeaderTitle = "PROJECT BUNDLER"
    } else {
        $OutputFile = "_SELECTIVE__${ProjectName}.md"
        Write-Host "`n[>] Executando SELECTIVE: Consolidando $($FilesToProcess.Count) arquivo(s)..." -ForegroundColor Magenta
        $HeaderTitle = "PROJECT BUNDLER (SELECTIVE)"
    }
    
    $FinalContent += $SystemInstruction
    $FinalContent += "# ${HeaderTitle}: $ProjectName`n`n"
    
    $FinalContent += "## 1. PROJECT STRUCTURE`n```text`n"
    foreach ($File in $FilesToProcess) { $FinalContent += (Resolve-Path -Path $File.FullName -Relative) + "`n" }
    $FinalContent += "````n`n"

    $FinalContent += "## 2. SOURCE FILES`n`n"
    foreach ($File in $FilesToProcess) {
        $RelPath = Resolve-Path -Path $File.FullName -Relative
        $Content = Get-Content $File.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        
        if ($Content) {
            $Content = $Content -replace "(`r?`n){3,}", "`r`n`r`n"
            $Ext = $File.Extension.TrimStart('.')
            
            # Normalização de extensão para syntax highlight no MD
            if ($Ext -match "^(tsx?)$") { $Ext = "typescript" }
            elseif ($Ext -match "^(jsx?)$") { $Ext = "javascript" }
            elseif ($Ext -match "^(py)$") { $Ext = "python" }
            elseif ($Ext -match "^(cs)$") { $Ext = "csharp" }
            elseif ($Ext -match "^(rb)$") { $Ext = "ruby" }
            elseif ($Ext -match "^(rs)$") { $Ext = "rust" }
            elseif ($Ext -match "^(kt)$") { $Ext = "kotlin" }
            elseif ($Ext -match "^(go)$") { $Ext = "go" }
            elseif ($Ext -match "^(java)$") { $Ext = "java" }
            elseif ($Ext -match "^(php)$") { $Ext = "php" }
            elseif ($Ext -match "^(c|h|cpp|hpp)$") { $Ext = "cpp" }
            
            $FinalContent += "### File: `$RelPath``n"
            $FinalContent += "```$Ext`n"
            $FinalContent += $Content.TrimEnd() + "`n"
            $FinalContent += "````n`n"
        }
    }

} else {
    $OutputFile = "_BLUEPRINT__${ProjectName}.md"
    Write-Host "`n[>] Executando BLUEPRINT: Extraindo contratos de arquitetura..." -ForegroundColor Green
    
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
            
            $Lines = Get-Content $File.FullName -Encoding UTF8
            $Signatures = @()
            for ($i = 0; $i -lt $Lines.Count; $i++) {
                $Line = $Lines[$i].Trim()
                if ($Line -match '^(?:export\s+)?(interface|type|enum)\s+[A-Za-z0-9_]+') {
                    $Block = "$Line`n"
                    if ($Line -notmatch '\}' -and $Line -notmatch ' = ' -and $Line -notmatch ';$') {
                        $j = $i + 1
                        while ($j -lt $Lines.Count -and $Lines[$j] -notmatch '^\}') {
                            $Block += "$($Lines[$j])`n"
                            $j++
                        }
                        if ($j -lt $Lines.Count) { $Block += "$($Lines[$j])`n" }
                        $i = $j
                    }
                    $Signatures += $Block
                } elseif ($Line -match '^(?:export\s+)?(?:const|function|class)\s+[A-Za-z0-9_]+') {
                    $Signature = ($Line -replace '\{.*$', '') -replace '\s*=>.*$', ''
                    $Signatures += "$Signature`n"
                } elseif ($Line -match '^(?:public|protected|private|internal)\s+(?:class|interface|record|struct|enum)\s+[A-Za-z0-9_]+') {
                    $Signature = $Line -replace '\{.*$', ''
                    $Signatures += "$Signature`n"
                } elseif ($Line -match '^(?:def|class)\s+[A-Za-z0-9_]+') {
                    $Signature = $Line -replace ':$', ''
                    $Signatures += "$Signature`n"
                } elseif ($Line -match '^func\s+[A-Za-z0-9_]+') {
                    $Signature = $Line -replace '\{.*$', ''
                    $Signatures += "$Signature`n"
                } elseif ($Line -match '^(?:pub\s+)?(?:fn|struct|enum|trait)\s+[A-Za-z0-9_]+') {
                    $Signature = $Line -replace '\{.*$', ''
                    $Signatures += "$Signature`n"
                }
            }
            
            if ($Signatures.Count -gt 0) {
                $Ext = $File.Extension.TrimStart('.')
                if ($Ext -match "^(tsx?)$") { $Ext = "typescript" }
                elseif ($Ext -match "^(jsx?)$") { $Ext = "javascript" }
                elseif ($Ext -match "^(py)$") { $Ext = "python" }
                elseif ($Ext -match "^(cs)$") { $Ext = "csharp" }
                elseif ($Ext -match "^(rb)$") { $Ext = "ruby" }
                elseif ($Ext -match "^(rs)$") { $Ext = "rust" }
                elseif ($Ext -match "^(kt)$") { $Ext = "kotlin" }
                elseif ($Ext -match "^(go)$") { $Ext = "go" }
                elseif ($Ext -match "^(java)$") { $Ext = "java" }
                elseif ($Ext -match "^(php)$") { $Ext = "php" }
                elseif ($Ext -match "^(c|h|cpp|hpp)$") { $Ext = "cpp" }
                
                $FinalContent += "### File: `$RelPath``n```$Ext`n"
                $FinalContent += ($Signatures -join '')
                $FinalContent += "````n`n"
            }
        }
    }
}

# ==========================================
# 6. SALVAMENTO E ÁREA DE TRANSFERÊNCIA
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
Write-Host " [✓] ARTEFATO CONSOLIDADO COM SUCESSO" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

if ($Choice -eq '1') { $ModoNome = "BUNDLER" }
elseif ($Choice -eq '2') { $ModoNome = "BLUEPRINT" }
else { $ModoNome = "SELECTIVE" }

Write-Host " 📌 Modo     : $ModoNome"
Write-Host " 📄 Arquivo  : $OutputFile"
Write-Host " 📦 Tokens   : ~$TokenEstimate (Estimativa bruta)"
if ($Copied) { Write-Host " 📋 Status   : Copiado para a área de transferência." -ForegroundColor Cyan }
else { Write-Host " 💾 Status   : Arquivo salvo localmente." -ForegroundColor Yellow }
Write-Host "==================================================`n" -ForegroundColor Green

# ==========================================
# 7. GERAÇÃO DE CONTEXTO COM IA (GROQ)
# ==========================================
$SendToAI = Read-Host "Deseja que a IA gere o 'AI Context Document' agora? (S/N)"
if ($SendToAI -match '^[Ss]$') {
    Write-Host "`n[~] Processando contexto no Groq via SDK. Aguarde..." -ForegroundColor Yellow
    
    $AgentScript = Join-Path $ToolkitDir "groq-agent.ts"
    
    if (Test-Path $AgentScript) {
        cmd.exe /c npx tsx `"$AgentScript`" `"$OutputFullPath`" `"$ProjectName`"
        Write-Host "`n[✓] Execução finalizada. Verifique: _AI_CONTEXT_$ProjectName.md" -ForegroundColor Green
    } else {
        Write-Warning "Falha: Script groq-agent.ts não localizado em: $ToolkitDir"
    }
} else {
    Write-Host "`nOperação concluída. Fluxo de IA ignorado." -ForegroundColor DarkGray
}

Write-Host ""
Pause