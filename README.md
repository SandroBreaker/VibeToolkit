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

```bat
.\Instalar VibeToolkit.cmd
```

Quando você executa esse arquivo sem argumentos, o comportamento é o seguinte:

- se o VibeToolkit ainda não estiver instalado, ele faz a instalação
- se já estiver instalado, ele pergunta se você quer **Repair**, **Uninstall** ou **Cancelar**

Também dá para chamar diretamente com argumento:

```bat
.\Instalar VibeToolkit.cmd /install
.\Instalar VibeToolkit.cmd /repair
.\Instalar VibeToolkit.cmd /uninstall
```

### Execução direta pela CLI

```powershell
.\project-bundler-cli.ps1
```

### Wrapper headless

```powershell
.\project-bundler-headless.ps1
```

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

```powershell
.\project-bundler-cli.ps1 -NonInteractive -BundleMode full -RouteMode executor
```

### Blueprint + Director

```powershell
.\project-bundler-cli.ps1 -NonInteractive -BundleMode blueprint -RouteMode director
```

### Sniper com seleção antecipada

```powershell
.\project-bundler-cli.ps1 -BundleMode sniper -SelectedPaths ".\src\*.ps1", ".\README.md"
```

### TXT Export + Executor

```powershell
.\project-bundler-cli.ps1 -NonInteractive -BundleMode txtExport -RouteMode executor
```

---

## Artefatos gerados

Os nomes seguem uma convenção por modo e rota. Exemplos:

```text
_bundle_executor__MeuProjeto.md
_blueprint_diretor__MeuProjeto.md
_meta-prompt_blueprint_diretor__MeuProjeto.md
_manual_executor__MeuProjeto.md
_txt_export_executor__MeuProjeto.zip
_bundle_executor__MeuProjeto.json
```

### Leitura rápida dos prefixos

- `bundle`: contexto completo
- `blueprint`: visão estrutural e arquitetural
- `manual`: recorte sniper
- `meta-prompt`: framing da rota director
- `txt_export`: exportação ZIP do modo TXT Export
- `.json`: metadata da execução

---

## Estrutura do projeto

```text
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
```

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
