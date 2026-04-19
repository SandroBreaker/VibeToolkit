# VibeToolkit

O **VibeToolkit** é um toolkit em **PowerShell** para empacotar contexto técnico de um projeto e gerar artefatos prontos para consumo por IA, com foco em execução operacional, baixa fricção e nomenclatura determinística.

Na versão atual, o projeto trabalha com:

- **modos de extração**: `full`, `blueprint`, `sniper` e `txtExport`
- **rotas de saída**: `director` e `executor`
- **fluxos declarados** para combinações `full` e `blueprint`
- **metadata JSON local** por execução
- **wrapper headless** para integração com o menu de contexto do Windows
- **suite de testes Pester** para contratos e regressão

> **Runtime principal:** PowerShell 7 (`pwsh`). No Windows, há fallback operacional para Windows PowerShell 5.1 quando necessário.

---

## O que o toolkit faz

Na prática, o VibeToolkit cobre estes cenários:

- consolidar o contexto técnico de um projeto em um artefato único
- gerar uma visão mais econômica da arquitetura e dos contratos centrais
- montar recortes manuais e cirúrgicos de arquivos selecionados
- exportar conteúdo em `.txt` + `.zip` para ambientes que não lidam bem com Markdown
- separar a saída entre rota **director** e rota **executor**
- registrar auditoria local da execução em **JSON**
- aplicar **fluxos declarados** com fallback por etapa nas execuções suportadas

---

## Requisitos

### Windows

- **PowerShell 7** recomendado
- **Windows PowerShell 5.1** como fallback operacional

### Linux e macOS

- **PowerShell 7** (`pwsh`)

> O **menu de contexto** é um recurso do Windows. Em Linux e macOS, o uso é direto pela CLI.

---

## Instalação e uso rápido

No Windows, o ponto de entrada principal é:

```powershell
.\Instalar-VibeToolkit.cmd
```

Quando esse arquivo é executado sem argumentos:

- se o toolkit ainda **não estiver instalado**, ele faz a instalação
- se **já estiver instalado**, ele oferece as ações **Repair**, **Uninstall** ou **Cancel**

Também é possível chamar diretamente com argumento:

```powershell
.\Instalar-VibeToolkit.cmd /install
.\Instalar-VibeToolkit.cmd /repair
.\Instalar-VibeToolkit.cmd /uninstall
```

### O que o instalador faz na versão atual

- registra integração no **menu de contexto do Windows** para:
  - pasta
  - fundo de pasta (`Directory\Background`)
  - unidade (`Drive`)
- usa o escopo do **usuário atual** (`HKCU`)
- gera ou atualiza o wrapper **`run-vibe-headless.vbs`**
- aponta a execução visual para **`project-bundler-headless.ps1`**

---

## Execução direta

### CLI canônica

```powershell
.\project-bundler-cli.ps1
```

### Wrapper headless

```powershell
.\project-bundler-headless.ps1
```

### Parâmetros operacionais principais

Os dois entrypoints trabalham com a mesma base de parâmetros:

```powershell
-Path <string>
-BundleMode <full|blueprint|sniper|txtExport>
-SelectedPaths <string[]>
-RouteMode <director|executor>
-ExecutorTarget <string>
-NonInteractive
```

Notas objetivas:

- `-SelectedPaths` é especialmente relevante para **`sniper`**
- `-NonInteractive` exige modo de extração válido
- `-ExecutorTarget` padrão atual: `IA Generativa (GenAI)`

---

## Modos operacionais

### Extraction mode

| Modo | Uso principal | Saída operacional |
| --- | --- | --- |
| `full` | contexto amplo do projeto | artefato fonte interno + **meta-prompt final** + metadata JSON |
| `blueprint` | estrutura, contratos e integrações com menos custo | artefato estrutural interno + **meta-prompt final** + metadata JSON |
| `sniper` | recorte manual e controlado | **bundle manual** ou **meta-prompt manual** + metadata JSON |
| `txtExport` | exportação textual para ingestão externa | **ZIP final** + metadata JSON |

### Leitura rápida por modo

#### Full

Melhor quando a outra ponta precisa de visão ampla: arquivos, estrutura, contexto técnico e framing operacional.

#### Blueprint

Melhor quando o objetivo é entender arquitetura, contratos, entrypoints e integrações sem carregar contexto demais.

#### Sniper

Melhor quando você já sabe quais arquivos importam e quer um recorte cirúrgico.

#### TXT Export

Melhor quando o destino não lida bem com Markdown. Nesse modo, o toolkit exporta os arquivos como `.txt`, monta staging temporário, compacta em `.zip` e grava o metadata local da execução.

---

## Rotas

| Rota de entrada | Papel | Saída final típica |
| --- | --- | --- |
| `director` | framing analítico e operacional | `_meta-prompt_*_diretor__Projeto.md` |
| `executor` | entrega direta para execução | `_meta-prompt_bundle_executor__Projeto.md`, `_meta-prompt_blueprint_executor__Projeto.md`, `_manual_executor__Projeto.md` ou `_txt_export_executor__Projeto.zip` |

### Observação importante sobre os nomes

A entrada da rota usa **inglês** (`director` / `executor`), mas o rótulo persistido no nome do artefato usa:

- `diretor`
- `executor`

Sim, ficou híbrido mesmo. Engenharia real tem dessas gambiarras elegantes.

---

## Fluxos declarados

A versão atual possui **fluxos declarados** em `flows/` para estas combinações:

- `full_director`
- `full_executor`
- `blueprint_director`
- `blueprint_executor`

Esses fluxos são resolvidos por **`VibeDeclaredFlowBridge.psm1`** e executados/auditados por **`VibeExecutionFlow.psm1`**.

### O que os fluxos declarados agregam

- ordem explícita de etapas
- fallback por passo
- registro estruturado do runtime
- auditoria de `steps` no metadata final

### Etapas típicas dos fluxos atuais

Os fluxos de `full` e `blueprint` giram em torno de passos como:

- `discover_files`
- `extract_signatures`
- `build_bundle` ou equivalente estrutural
- `build_meta_prompt`
- `validate_result`
- `save_artifacts`

### Limite atual

- `sniper` **não** usa fluxo declarado JSON
- `txtExport` **não** usa fluxo declarado JSON

Nesses casos, a execução segue pelo pipeline direto da CLI.

---

## Exemplos de uso

### Full + Executor

```powershell
.\project-bundler-cli.ps1 -NonInteractive -BundleMode full -RouteMode executor
```

### Blueprint + Director

```powershell
.\project-bundler-cli.ps1 -NonInteractive -BundleMode blueprint -RouteMode director
```

### Sniper com seleção antecipada

```powershell
.\project-bundler-cli.ps1 -BundleMode sniper -RouteMode executor -SelectedPaths ".\src\*.ps1", ".\README.md"
```

### Sniper + Director

```powershell
.\project-bundler-cli.ps1 -NonInteractive -BundleMode sniper -RouteMode director -SelectedPaths ".\modules\*.psm1", ".\README.md"
```

### TXT Export + Executor

```powershell
.\project-bundler-cli.ps1 -NonInteractive -BundleMode txtExport -RouteMode executor
```

### Headless wrapper apontando para outro diretório

```powershell
.\project-bundler-headless.ps1 -Path "C:\dev\MeuProjeto" -BundleMode blueprint -RouteMode executor -NonInteractive
```

---

## Artefatos gerados

A convenção atual usa rótulos determinísticos por modo, rota e projeto.

### Exemplos reais de saída final

```text
_meta-prompt_bundle_executor__MeuProjeto.md
_meta-prompt_blueprint_diretor__MeuProjeto.md
_manual_executor__MeuProjeto.md
_meta-prompt_manual_diretor__MeuProjeto.md
_txt_export_executor__MeuProjeto.zip
_meta-prompt_bundle_executor__MeuProjeto.json
_manual_executor__MeuProjeto.json
_txt_export_executor__MeuProjeto.json
```

### Leitura rápida dos prefixos

- `bundle`: modo full em forma de artefato-fonte
- `blueprint`: modo estrutural
- `manual`: modo sniper
- `meta-prompt`: artefato final com framing operacional
- `txt_export`: exportação ZIP do modo TXT Export
- `.json`: metadata local da execução

### Importante

Nos modos **`full`** e **`blueprint`**, o pipeline atual compila um **meta-prompt determinístico local** como saída final.

No modo **`sniper`**:

- com `director`, a saída final é **meta-prompt manual**
- com `executor`, a saída final é **bundle manual**

No modo **`txtExport`**, a saída final é sempre o **ZIP**.

---

## Estrutura atual do projeto

```text
VibeToolkit/
├── Instalar-VibeToolkit.cmd
├── project-bundler-cli.ps1
├── project-bundler-headless.ps1
├── run-vibe-headless.vbs
├── vibe-toolkit.Tests.ps1
├── flows/
│   ├── blueprint_director.flow.json
│   ├── blueprint_executor.flow.json
│   ├── full_director.flow.json
│   └── full_executor.flow.json
├── lib/
│   └── SentinelUI.ps1
├── modules/
│   ├── VibeBundleWriter.psm1
│   ├── VibeDeclaredFlowBridge.psm1
│   ├── VibeDirectorProtocol.psm1
│   ├── VibeExecutionFlow.psm1
│   ├── VibeFileDiscovery.psm1
│   └── VibeSignatureExtractor.psm1
└── README.md
```

---

## Papel dos arquivos principais

- **`Instalar-VibeToolkit.cmd`**: instalação, reparo, remoção e integração com o Explorer
- **`project-bundler-cli.ps1`**: engine canônica e pipeline principal
- **`project-bundler-headless.ps1`**: wrapper/shim para preservar contratos de integração
- **`run-vibe-headless.vbs`**: launcher visual usado pelo menu de contexto do Windows
- **`flows/*.flow.json`**: definição declarativa de etapas, fallback e auditoria
- **`modules/VibeDeclaredFlowBridge.psm1`**: resolução do fluxo declarado aplicável
- **`modules/VibeExecutionFlow.psm1`**: runtime do fluxo, registro de etapa e fallback
- **`modules/VibeBundleWriter.psm1`**: escrita e consolidação dos artefatos
- **`modules/VibeFileDiscovery.psm1`**: descoberta e filtragem dos arquivos elegíveis
- **`modules/VibeSignatureExtractor.psm1`**: extração de assinaturas/contratos
- **`modules/VibeDirectorProtocol.psm1`**: composição do framing e cabeçalhos operacionais
- **`lib/SentinelUI.ps1`**: camada de UI/log visual usada pela experiência terminal
- **`vibe-toolkit.Tests.ps1`**: suíte de contratos e regressão

---

## Testes

A suíte atual usa **Pester**.

### Executar os testes

```powershell
Invoke-Pester -Path .\vibe-toolkit.Tests.ps1 -Output Detailed
```

### O que a suíte cobre hoje

- existência dos arquivos e diretórios centrais
- export das funções principais
- extração de assinaturas
- runtime de execução de fluxo
- bridge de fluxo declarado
- composição de protocolo
- geração de artefatos
- integridade do wrapper headless
- contratos do instalador

---

## Comportamentos relevantes

### Descoberta de arquivos

O toolkit ignora artefatos já gerados e trabalha apenas com arquivos elegíveis do projeto.

### Metadata local

Toda execução grava um **JSON** ao lado do artefato final correspondente.

Quando há **fluxo declarado ativo**, o metadata também pode carregar:

- `executionFlow`
- `stepAudit`
- status, duração e fallback por etapa

### Política de runtime

A regra operacional é:

- tentar **`pwsh`** primeiro
- usar **`powershell.exe`** apenas como fallback no Windows
- em Linux/macOS, seguir com **`pwsh`**

---

## Resumo

O VibeToolkit atual não é só um gerador de bundle solto. Ele já opera como uma pipeline com:

- extração por modo
- separação por rota
- meta-prompt determinístico
- runtime de fluxo declarado
- auditoria local da execução
- integração headless com o Windows

Em bom português: menos improviso, menos arquivo jogado na raiz, menos ritual esquisito toda vez que você precisa preparar contexto técnico para IA. Milagre moderno, por algum acidente estatístico.
