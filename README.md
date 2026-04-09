# VibeToolkit

Toolkit operacional para **empacotar contexto técnico**, **extrair recortes estruturados do projeto** e **gerar artefatos prontos para Diretor/Executor** em fluxo **100% PowerShell** e **CLI-only**.

Nada de Node.js, TypeScript, provider remoto, momentum ou gambiarra estatística travestida de arquitetura. Milagre raro, eu sei.

---

## Visão geral

O VibeToolkit transforma uma pasta de código em artefatos operacionais com alto sinal técnico, sem dependência funcional de interface gráfica, runtime JavaScript ou serviços remotos.

Capacidades centrais:

- **Bundler Engine**: consolida arquivos relevantes do projeto em artefatos legíveis.
- **CLI interativa**: execução via terminal com seletores de modo e progresso textual.
- **Blueprint**: extrai visão estrutural focada em contratos, assinaturas e superfícies de integração.
- **Sniper / Manual**: trabalha com recorte parcial e controlado, sem extrapolar contexto invisível.
- **Route modes**:
  - **Director**: gera meta-prompt determinístico local em PowerShell.
  - **Executor**: gera contexto operacional pronto para implementação direta.
- **Governança local**: grava metadados úteis de execução em JSON, sem subprocesso externo.
- **TXT Export**: exporta arquivos como texto plano em diretório + ZIP.

---

## Arquitetura

### 1. Camada de entrada / CLI

Arquivos principais:

- `project-bundler-cli.ps1`: engine canônica com menus interativos e controle total do fluxo.
- `project-bundler-headless.ps1`: wrapper de integração, preservando contratos de invocação.

### 2. Camada de utilitários PowerShell

#### `modules/VibeBundleWriter.psm1`

Fornece funções de IO e serialização seguras:

- leitura de arquivos com política centralizada de encoding;
- escrita UTF-8 com ou sem BOM;
- geração de fences Markdown seguras.

#### `modules/VibeDirectorProtocol.psm1`

Centraliza cabeçalhos de protocolo para os dois papéis do sistema:

- Diretor local determinístico;
- Executor ELITE v4.1;
- labels de extração e governança textual sem momentum.

#### `modules/VibeFileDiscovery.psm1`

Responsável por descoberta recursiva de arquivos relevantes e exclusão de artefatos gerados automaticamente.

#### `modules/VibeSignatureExtractor.psm1`

Extrai assinaturas relevantes de arquivos para visão arquitetural/blueprint, com suporte para PowerShell, TypeScript/JavaScript, C#, Python, Go e Rust.

#### `lib/SentinelUI.ps1`

Utilitários de apresentação textual para terminal: tema ANSI, logs, menu interativo e spinner.

---

## Estrutura do projeto

```text
.
├─ lib/
│  └─ SentinelUI.ps1
├─ modules/
│  ├─ VibeBundleWriter.psm1
│  ├─ VibeDirectorProtocol.psm1
│  ├─ VibeFileDiscovery.psm1
│  └─ VibeSignatureExtractor.psm1
├─ project-bundler-headless.ps1
├─ project-bundler-cli.ps1
├─ run-vibe-headless.vbs          # launcher silencioso opcional, quando presente no clone
├─ install-vibe-menu.ps1
├─ uninstall-vibe-menu.ps1
└─ README.md
```

---

## Modos operacionais

### Route mode

- `director`: gera meta-prompt determinístico local com base apenas no bundle visível.
- `executor`: gera contexto direto para implementação.

### Extraction mode

- `full`: visão ampla do projeto contido no bundle.
- `blueprint`: foco em contratos, assinaturas e organização.
- `sniper`: recorte manual/parcial.
- `txtExport`: exporta arquivos como texto plano em diretório + ZIP.

---

## Requisitos

### Ambiente Windows

- **PowerShell 7.2+** recomendado;
- Windows 10/11.

### Dependências funcionais

- Nenhuma dependência funcional de Node.js, TypeScript, `.env`, API key ou provider remoto.

---

## Instalação

1. Clone o repositório em qualquer diretório.
2. Caso necessário, ajuste a política da sessão PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

3. Execute a engine:

```powershell
.\project-bundler-cli.ps1
```

---

## Menu de Contexto (Windows)

O VibeToolkit oferece integração com o Explorer para abrir a engine no terminal.

### Instalação

- Execute `install-vibe-menu.cmd` ou `install-vibe-menu.ps1`.
- A entrada instalada é:
  - **VibeToolkit: Abrir Terminal (CLI)**

### Desinstalação

- Execute `uninstall-vibe-menu.cmd` ou `uninstall-vibe-menu.ps1`.

> [!NOTE]
> O instalador grava o caminho real do clone atual. Sem hardcode tosco em `C:\dev\...`, porque a vida já tem sofrimento suficiente.

---

## Como executar

### Via CLI

```powershell
.\project-bundler-cli.ps1
```

### Via wrapper headless

```powershell
.\project-bundler-headless.ps1 -Path "C:\dev\SeuProjeto"
```

---

## Artefatos e convenções

O toolkit ignora automaticamente artefatos gerados como:

- `_bundle_*`
- `_blueprint_*`
- `_manual_*`
- `_meta-prompt_*`
- `_TXT_EXPORT__*`

Metadados locais são gerados em JSON com o mesmo basename do artefato final.

Exemplos:

- `_bundle_executor__Projeto.md`
- `_bundle_executor__Projeto.json`
- `_meta-prompt_blueprint_diretor__Projeto.md`
- `_meta-prompt_blueprint_diretor__Projeto.json`

---

## Padrões de projeto

- **Strict mode** em PowerShell.
- **Governança local** sem provider remoto.
- **Blindagem de encoding** para evitar corrupção de texto.
- **Sem momentum** e sem reaproveitamento de `_ai_*`.

---

## Referência rápida

### Arquivos centrais

- `project-bundler-cli.ps1`
- `project-bundler-headless.ps1`
- `lib/SentinelUI.ps1`
- `modules/VibeBundleWriter.psm1`
- `modules/VibeDirectorProtocol.psm1`
- `modules/VibeFileDiscovery.psm1`
- `modules/VibeSignatureExtractor.psm1`

### Stack

- PowerShell
