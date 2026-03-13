# MODO COPIAR TUDO: VibeToolkit

## 1. PROJECT STRUCTURE
```text
.\groq-agent.ts
.\package.json
.\project-bundler.ps1
.\README.md
.\remove-menu.ps1
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
            if (error.status === 401) {
                console.error("    Sua chave da Groq falhou. Verifique o arquivo .env.");
                console.error("    Dica: Acesse console.groq.com, crie uma nova chave e cole lá.");
            }
            else if (error.status === 429) {
                console.error("    O limite de uso gratuito da Groq foi atingido. Tente novamente em alguns minutos.");
            }
            else {
                console.error(`    Detalhes técnicos: ${error.message || error}`);
            }
        }
    }
};

const SYSTEM_PROMPT = `
Você é um "Professor de Programação Paciente". 
Sua tarefa é analisar o código do projeto enviado e gerar um resumo muito claro, didático e sem jargões complexos sobre:
1. Quais tecnologias este projeto usa.
2. Como os arquivos e pastas estão organizados (arquitetura).
3. Para que serve este projeto, de forma simples.

Não crie explicações longas ou código novo agora. Apenas entregue um resumo fácil de entender para quem está começando a mexer neste projeto.
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
        logger.error("Ops! Não achamos a sua chave da API da Groq no arquivo .env");
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

        const instructionalHeader = `> # CONTEXTO DO PROJETO
`;

        const finalFile = `${instructionalHeader}${result.trim()}\n\n---\n\n# ESTRUTURA E CÓDIGO (REFERÊNCIA TÉCNICA)\n${sourceCodeDump}`;
        await fs.writeFile(outputPath, finalFile, "utf-8");
        logger.info("Resumo criado com sucesso e pronto para uso.");
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
Write-Host " [ 1 ] Modo Copiar Tudo (Recomendado para projetos pequenos)" -ForegroundColor Yellow
Write-Host " [ 2 ] Modo Inteligente (Copia apenas a estrutura do projeto - gasta menos IA)" -ForegroundColor Green
Write-Host " [ 3 ] Modo Manual (Você escolhe os arquivos da lista)" -ForegroundColor Magenta
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
        $OutputFile = "_COPIAR_TUDO__${ProjectName}.md"
        Write-Host "`n[>] Iniciando Modo Copiar Tudo: Consolidando $($FilesToProcess.Count) arquivo(s)..." -ForegroundColor Yellow
        $HeaderTitle = "MODO COPIAR TUDO"
    } else {
        $OutputFile = "_MANUAL__${ProjectName}.md"
        Write-Host "`n[>] Iniciando Modo Manual: Consolidando $($FilesToProcess.Count) arquivo(s)..." -ForegroundColor Magenta
        $HeaderTitle = "MODO MANUAL"
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
    $OutputFile = "_INTELIGENTE__${ProjectName}.md"
    Write-Host "`n[>] Iniciando Modo Inteligente: Extraindo contratos e estrutura..." -ForegroundColor Green
    
    $FinalContent += "# MODO INTELIGENTE: $ProjectName`n`n"
    
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

if ($Choice -eq '1') { $ModoNome = "Copiar Tudo" }
elseif ($Choice -eq '2') { $ModoNome = "Inteligente" }
else { $ModoNome = "Manual" }

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
    Write-Host "`nConversando com a IA... isso pode levar alguns segundos." -ForegroundColor Yellow
    
    $AgentScript = Join-Path $ToolkitDir "groq-agent.ts"
    
    if (Test-Path $AgentScript) {
        # Define variável de ambiente para silenciar o dotenv (algumas versões respeitam)
        $env:DOTENV_CONFIG_SILENT="true"

        # Executa o comando silenciando toda a saída padrão e de erro
        $null = cmd.exe /c npx --quiet tsx `"$AgentScript`" `"$OutputFullPath`" `"$ProjectName`" 2>&1

        Write-Host "Pronto! O resumo do seu projeto está na área de transferência." -ForegroundColor Green
    } else {
        Write-Warning "Falha: Script groq-agent.ts não localizado."
    }
}
Pause
```

### File: .\README.md
```md
# ⚡ VibeToolkit: IA com Contexto Real

O **VibeToolkit** é a ponte definitiva entre o seu código local e as IAs (ChatGPT, Claude, Gemini). Ele resolve o problema da "amnésia" das IAs, consolidando seu projeto em um único documento de contexto inteligente, permitindo que a IA entenda a arquitetura, as tecnologias e a lógica do seu sistema de uma só vez.

## 🚀 O que ele faz?

* **Mapeamento Inteligente:** Varre suas pastas ignorando arquivos desnecessários (como `node_modules` e travas de pacotes).
* **Resumo por IA:** Utiliza a API da Groq para gerar um resumo didático no topo do arquivo, explicando o projeto como um "Professor de Programação Paciente".
* **Integração Nativa:** Adiciona uma opção ao menu de contexto do Windows (botão direito na pasta) para gerar o contexto instantaneamente.

---

## 🛠️ Modos de Extração

Ao rodar a ferramenta, você pode escolher o nível de detalhe que deseja enviar para a IA:

| Modo | Descrição | Uso Ideal |
| --- | --- | --- |
| **[ 1 ] Copiar Tudo** | Consolida o código-fonte completo de todos os arquivos relevantes. | Projetos pequenos ou depuração de lógica complexa. |
| **[ 2 ] Inteligente** | Extrai apenas a "assinatura" (esqueleto) das funções, classes e interfaces. | Projetos grandes onde você quer focar na arquitetura e economizar tokens. |
| **[ 3 ] Manual** | Você seleciona individualmente na lista quais arquivos quer incluir. | Quando você precisa de ajuda com arquivos específicos e quer evitar ruído. |

---

## 📦 Tecnologias Utilizadas

* **Node.js & TypeScript:** Motor principal para processamento de texto e integração com APIs.
* **PowerShell:** Automação de sistema e integração com o explorador de arquivos do Windows.
* **Groq SDK (Llama 3):** Inteligência artificial de ultravelocidade para resumir seu código.

---

## ⚙️ Como Instalar (Passo a Passo)

1. **Pré-requisitos:** Certifique-se de ter o [Node.js](https://nodejs.org/) instalado em sua máquina.
2. **Configuração Inicial:** Dentro da pasta do VibeToolkit, clique com o botão direito no arquivo `setup-menu.ps1` e selecione **"Executar com o PowerShell"**.
3. **Chave da API:** O instalador solicitará sua chave da Groq (gratuita em [console.groq.com](https://console.groq.com)). Ela ficará salva com segurança em um arquivo `.env`.
4. **Menu de Contexto:** O script perguntará se deseja adicionar o atalho ao Windows. Confirme para poder usar o toolkit em qualquer pasta do seu PC.

---

## 📖 Como Usar no Dia a Dia

1. Vá até qualquer pasta de um projeto que você esteja desenvolvendo.
2. Clique com o **botão direito** na pasta (ou no fundo dela) e escolha **"Gerar Blueprint / Contexto (Vibe AI)"**.
3. Escolha o modo desejado no console que abrirá.
4. Um arquivo chamado `_AI_CONTEXT_NomeDoProjeto.md` será gerado.
5. **Arraste esse arquivo para o chat da sua IA favorita** e comece a fazer perguntas com contexto total!

---

## 🧹 Remoção Manual (UI)

Se desejar remover os menus de contexto sem usar scripts:

1. Abra o **Editor de Registro (regedit)**.
2. Navegue até `HKEY_CLASSES_ROOT\Directory\shell\` e exclua a chave `VibeToolkit`.
3. Navegue até `HKEY_CLASSES_ROOT\Directory\Background\shell\` e exclua a chave `VibeToolkit`.

---

> **Dica de Ouro:** Sempre envie o arquivo gerado **antes** de começar a pedir novas funcionalidades para a IA. Isso garante que ela não "alucine" sugerindo coisas que não batem com o que você já construiu.
```

### File: .\remove-menu.ps1
```ps1
# =================================================================
# VibeToolkit - Uninstaller (Remove Context Menu)
# =================================================================

Write-Host "Removendo o VibeToolkit do seu Windows..." -ForegroundColor Cyan

$Paths = @(
    "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VibeToolkit",
    "Registry::HKEY_CLASSES_ROOT\Directory\shell\VibeToolkit"
)

foreach ($Path in $Paths) {
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
        Write-Host "[✓] Removido de: $Path" -ForegroundColor Green
    }
}

Write-Host "`nLimpeza concluída! O menu de contexto foi removido." -ForegroundColor Yellow
Pause
```

### File: .\setup-menu.ps1
```ps1
# =================================================================
# VibeToolkit - Context Menu & Environment Auto-Installer
# =================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. TENTA CONFIGURAR A POLÍTICA DE EXECUÇÃO AUTOMATICAMENTE
Write-Host "Preparando tudo para você..." -ForegroundColor Cyan
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# 2. VERIFICA PRÉ-REQUISITOS (NODE.JS)
$NodeCheck = Get-Command node -ErrorAction SilentlyContinue
if (-not $NodeCheck) {
    Write-Host "Ops! O VibeToolkit precisa do Node.js instalado. Baixe rapidamente em nodejs.org, instale e rode este script novamente." -ForegroundColor Yellow
    Pause
    exit
}

# 3. VERIFICA E CRIA ARQUIVO .ENV
$EnvFile = Join-Path $ScriptDir ".env"
if (-not (Test-Path $EnvFile)) {
    Write-Host "`nPrecisamos da sua chave da Groq para a Inteligência Artificial funcionar." -ForegroundColor Cyan
    $ApiKey = Read-Host "Cole aqui sua chave gratuita da Groq API (acesse console.groq.com)"
    if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
        "GROQ_API_KEY=$ApiKey" | Set-Content -Path $EnvFile -Encoding UTF8
        Write-Host "Chave salva com sucesso no arquivo .env!" -ForegroundColor Green
    } else {
        Write-Host "Nenhuma chave foi colada. Você precisará criar o arquivo .env manualmente depois." -ForegroundColor Yellow
    }
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
    
    Write-Host "`nQuase pronto! O último passo é adicionar a opção do VibeToolkit no seu Windows." -ForegroundColor Cyan
    $Confirm = Read-Host "Deseja adicionar o atalho ao botão direito do mouse agora? (S/N)"
    
    if ($Confirm -match '^[Ss]$') {
        Start-Process "regedit.exe" -ArgumentList "/s `"$RegFile`"" -Verb RunAs
        Write-Host "Tudo pronto! O atalho foi adicionado com sucesso. :)" -ForegroundColor Green
    } else {
        Write-Host "Tudo bem! Você pode rodar este script novamente caso mude de ideia." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Ops, não foi possível criar o arquivo de atalho. Tente rodar como Administrador." -ForegroundColor Red
}

Write-Host "`nPressione Enter para sair..." -ForegroundColor Cyan
Read-Host | Out-Null
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

