# VibeToolkit

Toolkit operacional para **empacotar contexto técnico**, **extrair recortes estruturados do projeto** e **gerar artefatos prontos para Diretor/Executor** no fluxo de engenharia agêntica.

O projeto combina módulos PowerShell para descoberta e serialização de contexto com um agente TypeScript para saída estruturada e integração com providers de IA.

---

## Visão geral

O VibeToolkit foi desenhado para transformar uma pasta de código em artefatos operacionais com alto sinal técnico.

Capacidades centrais:

- **Bundler Engine**: consolida arquivos relevantes do projeto em um artefato legível.
- **CLI / Headless**: execução interativa via terminal com seletores de modo e monitoramento de progresso (via `project-bundler-headless.ps1` ou `project-bundler-cli.ps1`).
- **Blueprint**: extrai visão estrutural focada em contratos, assinaturas e superfícies de integração.
- **Sniper / Manual**: trabalha com recorte parcial e controlado, sem extrapolar contexto invisível.
- **Route modes**:
  - **Director**: produz contexto/meta-prompt para análise e especificação.
  - **Executor**: produz contexto pronto para implementação direta.
- **Deterministic mode**: permite gerar meta-prompt localmente, sem provider remoto.
- **Momentum context**: reaproveita o último `_ai__*.json` válido como estado anterior.
- **Safe patching**: inclui utilitário para correção segura de trechos conhecidos do `groq-agent.ts`.

---

## Arquitetura

### 1. Camada de entrada / CLI

Arquivos principais:

- `project-bundler-cli.ps1`: Engine canônica com menus interativos e controle total do fluxo.
- `project-bundler-headless.ps1`: Wrapper de integração — delega para a engine canônica CLI, preservando todos os contratos de parâmetros.

### 2. Camada de utilitários PowerShell

#### `modules/VibeBundleWriter.psm1`

Fornece funções de IO e serialização seguras:

- leitura de arquivos com detecção de encoding (UTF-8/UTF-16/UTF-32);
- escrita UTF-8 com ou sem BOM;
- geração de fences Markdown seguros.

#### `modules/VibeDirectorProtocol.psm1`

Centraliza a construção de slices e headers de protocolo para os dois papéis do sistema:

- cabeçalhos ELITE v3.1 e ELITE v4.1;
- seções de metadata, governança e contexto momentum.

#### `modules/VibeFileDiscovery.psm1`

Responsável por descoberta recursiva de arquivos relevantes e exclusão de artefatos gerados automaticamente (como `_BUNDLER__*`, `_ai_*`, etc).

#### `modules/VibeSignatureExtractor.psm1`

Extrai assinaturas relevantes de arquivos para visão arquitetural/blueprint, com suporte para:

- PowerShell, TypeScript/JavaScript, C#, Python, Go, Rust.

#### `lib/SentinelUI.ps1`

Utilitários de apresentação textual para o terminal: tema ANSI, funções de log, menu interativo e spinner. Carregado automaticamente pela engine CLI.

### 3. Camada de agente TypeScript

Arquivo principal: `groq-agent.ts`

Responsabilidades:

- definição dos tipos centrais do pipeline;
- integração com providers (Groq, Gemini, OpenAI, Anthropic);
- suporte a template determinístico `director_meta_v1`.

### 4. Camada de reparo local

Arquivo auxiliar: `patch_agent.js`

- aplicar reparos conhecidos e seguros no `groq-agent.ts`.

---

## Estrutura do projeto

```text
.
├─ lib/
│  └─ SentinelUI.ps1         # Helpers de apresentação textual (CLI)
├─ modules/
│  ├─ VibeBundleWriter.psm1
│  ├─ VibeDirectorProtocol.psm1
│  ├─ VibeFileDiscovery.psm1
│  └─ VibeSignatureExtractor.psm1
├─ groq-agent.ts
├─ patch_agent.js
├─ project-bundler-headless.ps1   # Wrapper/shim de integração
├─ project-bundler-cli.ps1        # Engine canônica CLI
├─ run-vibe-headless.vbs          # Launcher silencioso → projeto-bundler-headless.ps1
├─ install-vibe-menu.ps1          # Instala entrada CLI no menu de contexto
├─ uninstall-vibe-menu.ps1        # Remove entradas do menu de contexto
├─ package.json
└─ tsconfig.json
```

---

## Modos operacionais

### Route mode

- `director`: prepara contexto analítico e meta-prompt para o Executor.
- `executor`: prepara contexto direto para implementação.

### Extraction mode

- `full`: visão ampla do projeto contido no bundle.
- `blueprint`: foco em contratos, assinaturas e organização.
- `sniper`: recorte manual/parcial.

---

## Requisitos

### Ambiente Windows

- **PowerShell 7.2+** (recomendado para melhor performance);
- Windows 10/11.

### Node.js / TypeScript

- **Node.js** 18+;
- Dependências: `dotenv`, `groq-sdk`.

---

## Instalação

1. **Clonar o repositório** em qualquer diretório de sua preferência.

2. **Instalar dependências Node**:

   ```bash
   npm install
   ```

3. **Permissões PowerShell**:

   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   ```

4. **Configurar .env**:
   Crie um `.env` com sua `GROQ_API_KEY` ou outras chaves necessárias.

---

## Menu de Contexto (Windows)

O VibeToolkit oferece integração direta com o Windows Explorer para facilitar o empacotamento de pastas e unidades.

1. **Instalação**:
   - Execute `install-vibe-menu.cmd` (ou `install-vibe-menu.ps1` diretamente).
   - Isso adicionará ao menu de contexto do botão direito em pastas/diretórios:
     - **VibeToolkit: Abrir Terminal (CLI)**: Inicia a engine interativa diretamente no terminal.

2. **Desinstalação**:
   - Execute `uninstall-vibe-menu.cmd` (ou `uninstall-vibe-menu.ps1`).
   - O script remove entradas atuais e legadas automaticamente.

> [!NOTE]
> O instalador grava o caminho real do clone atual — não exige instalação em `C:\dev\VibeToolkit`.

---

## Como executar

### Via CLI (padrão)

```powershell
.\project-bundler-cli.ps1
```

### Via wrapper headless (contratos de integração)

```powershell
.\project-bundler-headless.ps1 -Path "C:\dev\SeuProjeto"
```

---

## Artefatos e convenções

O toolkit diferencia arquivos-fonte de artefatos gerados. Padrões ignorados automaticamente:

- `_BUNDLER__*`, `_BLUEPRINT__*`, `_AI_CONTEXT_*`, `_ai_*`.

O sistema busca automaticamente o **context momentum** (JSON mais recente `_ai_*.json`) para enriquecer o próximo ciclo de engenharia.

---

## Padrões de projeto

- **Strict mode** em módulos PowerShell.
- **Tipagem forte** no agente TypeScript.
- **Blindagem de encoding** para evitar corrupção de texto.
- **Tratamento de erro classificado** no pipeline do agente.

---

## Referência rápida

### Arquivos centrais

- `project-bundler-headless.ps1` / `project-bundler-cli.ps1`
- `lib/SentinelUI.ps1`
- `modules/VibeBundleWriter.psm1`
- `modules/VibeDirectorProtocol.psm1`
- `groq-agent.ts`
- `patch_agent.js`

### Stack

- PowerShell, Node.js, TypeScript.
