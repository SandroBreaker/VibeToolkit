# VibeToolkit

Toolkit operacional para **empacotar contexto técnico**, **extrair recortes estruturados do projeto** e **gerar artefatos prontos para Diretor/Executor** no fluxo de engenharia agêntica.

O projeto combina um **HUD moderno em WPF (WPF/XAML)**, módulos PowerShell para descoberta e serialização de contexto, e um agente TypeScript para saída estruturada e integração com provider de IA quando aplicável.

> [!NOTE]
> Este projeto foi evoluído de uma interface WinForms básica para um HUD robusto em WPF, garantindo melhor performance e experiência visual "glassmorphism" no Windows.

---

## Visão geral

O VibeToolkit foi desenhado para transformar uma pasta de código em artefatos operacionais com alto sinal técnico.

Capacidades centrais:

- **Bundler Engine**: consolida arquivos relevantes do projeto em um artefato legível.
- **WPF HUD**: interface gráfica moderna (XAML) para controle total do processo com feedback visual.
- **Headless Interface**: versão otimizada para terminal com seletores interativos (via `project-bundler-headless.ps1`).
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

### 1. Camada de entrada / HUD

Arquivos principais:

- `project-bundler-hud.ps1`: Ponto de entrada para a interface gráfica.
- `lib/SentinelHud.ps1`: Orquestrador da HUD WPF.
- `lib/SentinelHud.xaml`: Definição visual (XAML) do dashboard.
- `lib/SentinelHudViewModel.cs`: Lógica de binding e estado da UI em C#.

A HUD utiliza **WPF (Windows Presentation Foundation)** para uma identidade visual premium:

- Design moderno "Glassmorphism" com transparência e alta legibilidade (texto em alto contraste).
- Feedback em tempo real com barra de progresso, logs detalhados e opção **Copy Logs** para exportação rápida do histórico de operação.
- Seleção intuitiva de pastas e modos operacionais.

### 2. Camada de Engine CLI

Arquivo principal:

- `project-bundler-cli.ps1` e `project-bundler-headless.ps1`

Responsabilidades:

- **CLI Engine**: núcleo de processamento para automação.
- **Headless CLI**: interface de terminal com menus interativos para seleção Sniper e monitoramento de progresso.
- orquestração do fluxo de geração dos artefatos sem necessidade de UI.

### 3. Camada de utilitários PowerShell

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

### 4. Camada de agente TypeScript

Arquivo principal: `groq-agent.ts`

Responsabilidades:

- definição dos tipos centrais do pipeline;
- integração com providers (Groq, Gemini, OpenAI, Anthropic);
- suporte a template determinístico `director_meta_v1`.

### 5. Camada de reparo local

Arquivo auxiliar: `patch_agent.js`

- aplicar reparos conhecidos e seguros no `groq-agent.ts`.

---

## Estrutura do projeto

```text
.
├─ lib/
│  ├─ SentinelHud.ps1        # Script da HUD WPF
│  ├─ SentinelHud.xaml       # View (XAML)
│  ├─ SentinelHudViewModel.cs # ViewModel (C#)
│  └─ SentinelUI.ps1         # Helpers de UI Console
├─ modules/
│  ├─ VibeBundleWriter.psm1
│  ├─ VibeDirectorProtocol.psm1
│  ├─ VibeFileDiscovery.psm1
│  └─ VibeSignatureExtractor.psm1
├─ groq-agent.ts
├─ patch_agent.js
├─ project-bundler-hud.ps1        # Entry point HUD
├─ project-bundler-headless.ps1   # Entry point Terminal Interativo
├─ project-bundler-cli.ps1        # Entry point CLI Engine
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
- **.NET Desktop Runtime** (para suporte a WPF);
- Windows 10/11 para melhor compatibilidade com o HUD.

### Node.js / TypeScript

- **Node.js** 18+;
- Dependências: `dotenv`, `groq-sdk`.

---

---

## Instalação

1. **Clonar/Mover para o Diretório Padrão** (Recomendado):
   Para que os scripts do menu de contexto funcionem sem ajustes manuais, instale o toolkit em:
   `C:\dev\VibeToolkit`

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
   - Execute o arquivo `install-vibe-menu.reg`.
   - Isso adicionará duas opções ao clicar com o botão direito em pastas ou no fundo do diretório:
     - **VibeToolkit: Abrir HUD (WPF)**: Inicia a interface gráfica moderna.
     - **VibeToolkit: Abrir Terminal (Headless)**: Inicia o processo interativo diretamente no terminal.

2. **Desinstalação**:
   - Execute o arquivo `uninstall-vibe-menu.reg` para remover as entradas do registro.

> [!IMPORTANT]
> Se você optar por instalar o toolkit em um diretório diferente de `C:\dev\VibeToolkit`, deverá atualizar os caminhos nos arquivos `install-vibe-menu.reg`, `run-vibe-toolkit.vbs` e `run-vibe-headless.vbs` antes de importar o registro.

---

## Como executar

### Iniciar o HUD WPF (Recomendado)

```powershell
.\project-bundler-hud.ps1
```

### Executar via Terminal (Headless / Interativo)

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
- **MVVM simplificado** para o HUD WPF (XAML + ViewModel).
- **Tipagem forte** no agente TypeScript.
- **Blindagem de encoding** para evitar corrupção de texto.
- **Tratamento de erro classificado** no pipeline do agente.

---

## Referência rápida

### Arquivos centrais

- `project-bundler-hud.ps1` / `project-bundler-headless.ps1` / `project-bundler-cli.ps1`
- `lib/SentinelHud.ps1`
- `modules/VibeBundleWriter.psm1`
- `modules/VibeDirectorProtocol.psm1`
- `groq-agent.ts`
- `patch_agent.js`

### Stack

- PowerShell, WPF, C#, Node.js, TypeScript.
