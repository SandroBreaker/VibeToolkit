# PROJECT BUNDLER: VibeToolkit

## 1. PROJECT STRUCTURE
```text
.\groq-agent.ts
.\package.json
.\project-bundler.ps1
.\README.md
.\setup-menu.ps1
.\tsconfig.json
```

## 2. SOURCE FILES

### File: .\groq-agent.ts
```typescript
import Groq from "groq-sdk";
import * as dotenv from "dotenv";
import { promises as fs } from "fs";
import * as path from "path";

dotenv.config({ path: path.resolve(__dirname, ".env") });

interface GroqRequestParams {
    model: string;
    systemContent: string;
    userPrompt: string;
    temperature?: number;
    maxTokens?: number;
}

const logger = {
    info: (message: string) => {
        console.log(`[AI] ${message}`);
    },
    error: (message: string, error?: any) => {
        console.error(`[!] ERRO: ${message}`);
        if (error) {
            if (error.status === 401) console.error("    Detalhes: Chave de API inválida ou não encontrada.");
            else if (error.status === 429) console.error("    Detalhes: Limite de requisições atingido.");
            else console.error(`    Detalhes: ${error.message || error}`);
        }
    }
};

const SYSTEM_PROMPT = `
ROLE: PRINCIPAL_SOFTWARE_ARCHITECT
OBJECTIVE: Analisar o dump de um projeto e gerar um "AI Context Briefing" de ALTÍSSIMA DENSIDADE + um <system_instruction> EXECUTOR.

ESTRUTURA OBRIGATÓRIA DA SAÍDA (MARKDOWN):
1) <system_instruction> (O bloco executor baseado no projeto)
2) # AI PROJECT CONTEXT BRIEFING (As 5 seções técnicas)
`;

class GroqService {
    private client: Groq;
    constructor() { 
        this.client = new Groq({ apiKey: process.env.GROQ_API_KEY || "MISSING_KEY" }); 
    }

    public async generateContextDocument(params: GroqRequestParams): Promise<string | null> {
        try {
            const response = await this.client.chat.completions.create({
                messages: [{ role: "system", content: params.systemContent }, { role: "user", content: params.userPrompt }],
                model: params.model,
                temperature: 0.1,
            });
            return response.choices[0]?.message?.content || null;
        } catch (error) {
            logger.error("Falha na API Groq", error);
            return null;
        }
    }
}

async function main() {
    // Validação imediata da API Key para ajudar o usuário
    if (!process.env.GROQ_API_KEY) {
        logger.error("GROQ_API_KEY não configurada no arquivo .env");
        process.exit(1);
    }

    const [bundlePath, projectName] = process.argv.slice(2);
    if (!bundlePath) process.exit(1);

    const absolutePath = path.resolve(process.cwd(), bundlePath);
    let sourceCodeDump = await fs.readFile(absolutePath, "utf-8");

    sourceCodeDump = sourceCodeDump.replace(/<system_instruction>[\s\S]*?<\/system_instruction>/g, "").trim();

    const groqService = new GroqService();
    const result = await groqService.generateContextDocument({
        model: "llama-3.3-70b-versatile",
        systemContent: SYSTEM_PROMPT,
        userPrompt: `Analise este projeto '${projectName}':\n\n${sourceCodeDump}`,
    });

    if (result) {
        const outputPath = path.resolve(path.dirname(absolutePath), `_AI_CONTEXT_${projectName}.md`);
        const finalFile = `${result.trim()}\n\n---\n\n# PROJECT BLUEPRINT (TECHNICAL REFERENCE)\n${sourceCodeDump}`;
        await fs.writeFile(outputPath, finalFile, "utf-8");
        logger.info("Contexto unificado gerado sem duplicidade.");
    }
}

main();
```

### File: .\package.json
```json
{
  "name": "vibetoolkit",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "type": "commonjs",
  "dependencies": {
    "dotenv": "^17.3.1",
    "groq-sdk": "^0.37.0"
  },
  "devDependencies": {
    "@types/node": "^25.3.2",
    "tsx": "^4.21.0",
    "typescript": "^5.9.3"
  }
}
```

### File: .\project-bundler.ps1
```ps1
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
$BlueprintIssues = @()

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
    
    $FinalContent += "# ${HeaderTitle}: $ProjectName`n`n"
    
    $FinalContent += "## 1. PROJECT STRUCTURE`n" + '```text' + "`n"
    foreach ($File in $FilesToProcess) { $FinalContent += (Resolve-Path -Path $File.FullName -Relative) + "`n" }
    $FinalContent += '```' + "`n`n"

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
            
            $FinalContent += "### File: $RelPath`n"
            $FinalContent += '```' + $Ext + "`n"
            $FinalContent += $Content.TrimEnd() + "`n"
            $FinalContent += '```' + "`n`n"
        }
    }

} else {
    $OutputFile = "_BLUEPRINT__${ProjectName}.md"
    Write-Host "`n[>] Executando BLUEPRINT: Extraindo contratos de arquitetura..." -ForegroundColor Green
    
    $FinalContent += "# PROJECT BLUEPRINT: $ProjectName`n`n"
    
    $FinalContent += "## 1. TECH STACK`n"
    if (Test-Path "package.json") {
        $Pkg = Get-Content "package.json" | ConvertFrom-Json
        $FinalContent += "* **Deps:** $( ($Pkg.dependencies.PSObject.Properties.Name -join ", ") )`n"
        if ($Pkg.devDependencies) { $FinalContent += "* **Dev Deps:** $( ($Pkg.devDependencies.PSObject.Properties.Name -join ", ") )`n" }
    }
    $FinalContent += "`n"

    $FinalContent += "## 2. PROJECT STRUCTURE`n" + '```text' + "`n"
    foreach ($File in $FilesToProcess) { $FinalContent += (Resolve-Path -Path $File.FullName -Relative) + "`n" }
    $FinalContent += '```' + "`n`n"

    $FinalContent += "## 3. CORE DOMAINS & CONTRACTS`n"

    $BlueprintIssues = @()
    foreach ($File in $FilesToProcess) {
        if ($SignatureExtensions -contains $File.Extension) {
            $RelPath = Resolve-Path -Path $File.FullName -Relative
            $ContentRaw = Get-Content $File.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if (-not $ContentRaw) { continue }
            
            try {
                $Lines = @(Get-Content $File.FullName -Encoding UTF8)
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
            } catch {
                $BlueprintIssues += "[$RelPath] $($_.Exception.Message)"
                continue
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
                
                $FinalContent += "### File: $RelPath`n" + '```' + $Ext + "`n"
                $FinalContent += ($Signatures -join '')
                $FinalContent += '```' + "`n`n"
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

if ($BlueprintIssues -and $BlueprintIssues.Count -gt 0) {
    Write-Host "`n==================================================" -ForegroundColor Yellow
    Write-Host " [!] ARTEFATO GERADO COM AVISOS" -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host " ⚠️  Ocorreram $($BlueprintIssues.Count) aviso(s) durante o BLUEPRINT:" -ForegroundColor Yellow
    foreach ($Issue in ($BlueprintIssues | Select-Object -First 10)) {
        Write-Host "   - $Issue" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "`n==================================================" -ForegroundColor Green
    Write-Host " [✓] ARTEFATO CONSOLIDADO COM SUCESSO" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
}

if ($Choice -eq '1') { $ModoNome = "BUNDLER" }
elseif ($Choice -eq '2') { $ModoNome = "BLUEPRINT" }
else { $ModoNome = "SELECTIVE" }

Write-Host " 📌 Modo     : $ModoNome"
Write-Host " 📄 Arquivo   : $OutputFile"
Write-Host " 📦 Tokens    : ~$TokenEstimate"
if ($Copied) { Write-Host " 📋 Status    : Copiado para a área de transferência." -ForegroundColor Cyan }
else { Write-Host " 💾 Status    : Arquivo salvo localmente." -ForegroundColor Yellow }
Write-Host "==================================================`n" -ForegroundColor Green

# ==========================================
# 7. GERAÇÃO DE CONTEXTO COM IA (GROQ)
# ==========================================
$SendToAI = Read-Host "Deseja que a IA gere o 'AI Context Document' agora? (S/N)"
if ($SendToAI -match '^[Ss]$') {
    Write-Host "`n[~] Processando contexto no Groq via SDK. Aguarde..." -ForegroundColor Yellow
    
    $AgentScript = Join-Path $ToolkitDir "groq-agent.ts"
    
    if (Test-Path $AgentScript) {
        # Define variável de ambiente para silenciar o dotenv (algumas versões respeitam)
        $env:DOTENV_CONFIG_SILENT="true"

        # Executa o comando e filtra linhas que contenham "[dotenv]" ou mensagens de update do npm
        cmd.exe /c npx --quiet tsx `"$AgentScript`" `"$OutputFullPath`" `"$ProjectName`" 2>&1 | 
            Where-Object { $_ -notmatch "\[dotenv@.*\]" -and $_ -notmatch "npx: installed" } | 
            ForEach-Object { Write-Host "    $_.ToString()" -ForegroundColor Cyan }

        Write-Host "`n[✓] Documento de Contexto gerado com sucesso!" -ForegroundColor Green
    } else {
        Write-Warning "Falha: Script groq-agent.ts não localizado."
    }
}
Pause
```

### File: .\README.md
```md
# ⚡ VibeToolkit - AI Context Synthesizer & Bundler

O **VibeToolkit** é uma ferramenta de linha de comando (CLI) construída com **PowerShell** e **Node.js** que atua como um engenheiro reverso para seus projetos de software.

Ele varre seu repositório, extrai contratos, tipagens e arquitetura, e utiliza a API da **Groq (Llama 3.3 70B)** para gerar um "Super Prompt" de altíssima densidade. O resultado é um documento otimizado que você envia para qualquer LLM (ChatGPT, Claude, Gemini) para que a IA codifique no seu projeto com precisão milimétrica e zero alucinação.

## 🚨 O Problema que Resolvemos

Trabalhar com LLMs em projetos grandes envolve um gargalo terrível de contexto:

1. **Caos Manual:** Copiar e colar dezenas de arquivos é lento e gera erros.
2. **Desperdício de Tokens:** Enviar o código inteiro é caro e "dilui" a atenção da IA.
3. **Alucinação Arquitetural:** Sem interfaces claras, a IA inventa propriedades e quebra o build.

## 🛠️ A Solução (Vibe Workflow)

O toolkit automatiza a extração e cria um **AI Context Document** (`.md`) consolidado contendo:

* **Persona Executora:** Instruções estritas para garantir entregas de código completas.
* **AI Briefing (Zero Fluff):** Resumo estratégico gerado pelo Llama 3 focado em Tech Stack e Guardrails.
* **Project Blueprint:** Mapeamento de assinaturas, tipos e estruturas de arquivos para referência técnica.

---

## 🌟 Dica de Ouro: Como interagir com o resultado

Para um pair-programming de elite com Claude, ChatGPT ou Gemini, não basta apenas enviar o arquivo. Use a **consciência situacional** a seu favor:

1. Faça o upload do arquivo gerado (ex: `_AI_CONTEXT_MeuProjeto.md`).
2. Faça o upload do arquivo específico que você quer modificar (ex: `UserService.ts`).
3. **Dê a ordem mestre:** > *"Analise o arquivo `_AI_CONTEXT_` anexo para entender nossos padrões globais. Agora, refatore este `UserService.ts` para implementar o novo padrão de erro definido no Blueprint, garantindo que a tipagem respeite a interface `IAppError`."*

---

## 🚀 Como Instalar

### Pré-requisitos

* **Node.js** (v18+).
* **PowerShell**.
* Chave de API gratuita da [Groq Console](https://console.groq.com/).

### Passo a Passo

1. Clone este repositório.
2. Instale as dependências:
```bash
npm install

```

3. Configure sua chave no arquivo `.env` (use o `.env.example` como base):
```env
GROQ_API_KEY=gsk_sua_chave_aqui

```

### 🖱️ Setup Automático (Windows)

Para facilitar a vida, o toolkit vem com um script que configura as permissões do PowerShell e adiciona a ferramenta ao seu menu do botão direito:

1. Execute o script `setup-menu.ps1` como **Administrador**.
2. O script configurará a política de execução (`RemoteSigned`) e integrará o menu automaticamente.
3. **Pronto!** Clique com o botão direito em qualquer pasta de projeto e selecione **"Gerar Blueprint / Contexto (Vibe AI)"**.

---

## 💻 Modos de Extração

Ao rodar o toolkit, você terá três opções no menu interativo:

| Modo | Descrição | Quando usar |
| --- | --- | --- |
| **[ 1 ] BUNDLER** | Consolida o código-fonte completo de todos os arquivos permitidos. | Projetos pequenos onde o código inteiro cabe no contexto da IA. |
| **[ 2 ] BLUEPRINT** | Extrai apenas a "casca" técnica: interfaces, tipos, classes e assinaturas. | Projetos grandes onde você precisa que a IA entenda a arquitetura sem ler todo o código. |
| **[ 3 ] SELECTIVE** | Permite escolher manualmente quais arquivos entrarão no contexto. | Quando você está trabalhando em uma feature específica que toca apenas 3 ou 4 arquivos. |

---

## 🛡️ Segurança e Privacidade

O toolkit ignora automaticamente `node_modules`, `.git`, arquivos de lock e outros dados sensíveis via lista de exclusão configurável. O processamento via Groq foca apenas na extração da lógica estrutural.

---

**Quer que eu te ajude a gerar um arquivo `.env.example` pronto para acompanhar esse README?**
```

### File: .\setup-menu.ps1
```ps1
# =================================================================
# VibeToolkit - Context Menu & Environment Auto-Installer
# =================================================================

# 1. TENTA CONFIGURAR A POLÍTICA DE EXECUÇÃO AUTOMATICAMENTE
Write-Host "[*] Configurando permissões do PowerShell..." -ForegroundColor Cyan
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# 2. VERIFICA PRÉ-REQUISITOS (NODE.JS)
$NodeCheck = Get-Command node -ErrorAction SilentlyContinue
if (-not $NodeCheck) {
    Write-Error "Node.js não encontrado! Por favor, instale o Node.js antes de continuar."
    Pause
    exit
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BundlerPath = Join-Path $ScriptDir "project-bundler.ps1"
$RegFile = Join-Path $ScriptDir "install-vibe-menu.reg"

$EscapedPath = $BundlerPath -replace '\\', '\\\\'

$RegContent = @"
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkit]
@="Gerar Blueprint / Contexto (Vibe AI)"
"Icon"="powershell.exe"

[HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkit\command]
@="powershell.exe -ExecutionPolicy Bypass -NoProfile -File \"$EscapedPath\" -Path \"%V\""

[HKEY_CLASSES_ROOT\Directory\shell\VibeToolkit]
@="Gerar Blueprint / Contexto (Vibe AI)"
"Icon"="powershell.exe"

[HKEY_CLASSES_ROOT\Directory\shell\VibeToolkit\command]
@="powershell.exe -ExecutionPolicy Bypass -NoProfile -File \"$EscapedPath\" -Path \"%1\""
"@

try {
    [System.IO.File]::WriteAllText($RegFile, $RegContent, [System.Text.Encoding]::Unicode)
    
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host " [✓] Verificações de ambiente concluídas!" -ForegroundColor Green
    Write-Host " [✓] Ficheiro de registo gerado com sucesso!" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Deseja aplicar as alterações ao Registro (Botão Direito) agora? (S/N)" -ForegroundColor Cyan
    
    $Confirm = Read-Host
    if ($Confirm -match '^[Ss]$') {
        Start-Process "regedit.exe" -ArgumentList "/s `"$RegFile`"" -Verb RunAs
        Write-Host "[✓] Menu de contexto instalado e permissões configuradas!" -ForegroundColor Green
    }
} catch {
    Write-Error "Falha ao gerar o ficheiro: $($_.Exception.Message)"
}

Pause
```

### File: .\tsconfig.json
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "CommonJS",
    "moduleResolution": "node",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "./dist"
  },
  "include": ["**/*.ts"],
  "exclude": ["node_modules"]
}
```

