# VibeToolkit

Toolkit operacional para **empacotar contexto técnico**, **extrair recortes estruturais** e **gerar artefatos determinísticos** para uso com IA.

> PowerShell 7 preferencial • Windows PowerShell 5.1 como fallback no Windows • CLI/headless • Menu de contexto no Windows • Saídas em Markdown, JSON e ZIP

O projeto combina uma **CLI em PowerShell**, módulos para descoberta e serialização de contexto, geração de artefatos em Markdown/JSON/ZIP e integração operacional com rotas **Director** e **Executor**.

---

## O que o VibeToolkit faz

Capacidades centrais:

- **Bundler Engine**: consolida arquivos relevantes do projeto em artefatos legíveis.
- **CLI interativa**: execução via terminal com seleção de modo e feedback operacional.
- **Blueprint**: extrai visão estrutural focada em contratos, assinaturas e pontos de integração.
- **Sniper / Manual**: trabalha com recorte parcial e controlado, sem extrapolar contexto invisível.
- **Route modes**:
  - **Director**: gera meta-prompt determinístico local.
  - **Executor**: gera contexto operacional pronto para implementação direta.
- **Governança local**: grava metadata útil de execução em JSON.
- **TXT Export**: exporta arquivos como texto plano em diretório + ZIP final.

---

## Requisitos

### Obrigatórios

- **PowerShell 7** como runtime principal e recomendado
- **Windows PowerShell 5.1** como fallback compatível apenas no Windows

### Compatibilidade

- **Windows**: suporte completo, incluindo instalador e menu de contexto, com política **PS7 preferencial / PS5.1 fallback**
- **Linux/macOS**: uso via CLI com **PowerShell 7 (`pwsh`)**; o menu de contexto do Windows não se aplica

---

## Instalação e execução

No Windows, o caminho mais simples é pelo menu de contexto. Nos fluxos Windows, o toolkit tenta **PowerShell 7 (`pwsh`)** primeiro e usa **Windows PowerShell 5.1 (`powershell.exe`)** apenas como fallback quando necessário.

Em Linux/macOS, a CLI continua dependendo de **PowerShell 7 (`pwsh`)**.

### Instalador principal

```bat
.\Instalar VibeToolkit.cmd
```

### CLI direta

```powershell
.\project-bundler-cli.ps1
```

### Wrapper headless

```powershell
.\project-bundler-headless.ps1
```

---

## Modos operacionais

### Extraction mode

| Modo        | Objetivo                                                       | Saída típica                           |
| ----------- | -------------------------------------------------------------- | -------------------------------------- |
| `full`      | contexto completo do projeto                                   | bundle Markdown + metadata JSON        |
| `blueprint` | estrutura, contratos e integração com menor custo              | blueprint Markdown + metadata JSON     |
| `sniper`    | recorte manual e cirúrgico                                     | bundle manual Markdown + metadata JSON |
| `txtExport` | exportação textual para ambientes que preferem arquivos `.txt` | ZIP final + metadata JSON              |

### Observações por modo

#### Full

Use quando a IA precisa do máximo de contexto visível: código, docs, configs e estrutura.

#### Blueprint

Use quando o foco é arquitetura, contratos, entrypoints, integração e leitura econômica de contexto.

#### Sniper

Use quando você já sabe quais arquivos quer enviar e precisa de um recorte mínimo, sem carregar o restante do projeto.

#### TXT Export

Use quando o destino não trabalha bem com bundle Markdown.

No contrato atual do projeto, o `txtExport`:

* gera os `.txt` internamente
* compacta o resultado
* remove o staging ao final
* deixa **apenas o `.zip` como artefato final visível**

---

## Rotas de saída

| Rota       | Objetivo                                                         |
| ---------- | ---------------------------------------------------------------- |
| `director` | gerar um artefato analítico com meta-prompt local determinístico |
| `executor` | gerar o contexto final pronto para uso direto                    |

### Quando usar `director`

Quando você quer que outra IA receba um framing operacional mais forte, com instrução explícita de leitura do artefato e de atuação por papel.

### Quando usar `executor`

Quando você quer o resultado final pronto para colar na IA sem camada intermediária.

---

## Compatibilidade rápida por modo x rota

| Combinação             | Resultado principal          | Observações                                         |
| ---------------------- | ---------------------------- | --------------------------------------------------- |
| `full + director`      | bundle + meta-prompt         | fluxo completo delegado                             |
| `full + executor`      | bundle final direto          | fluxo completo direto                               |
| `blueprint + director` | blueprint + meta-prompt      | foco em contratos/estrutura                         |
| `blueprint + executor` | blueprint direto             | foco em contratos/estrutura                         |
| `sniper + director`    | recorte manual + meta-prompt | em modo não interativo exige `-SelectedPaths`       |
| `sniper + executor`    | recorte manual direto        | em modo não interativo exige `-SelectedPaths`       |
| `txtExport + director` | pasta `.txt` + `.zip`        | a rota afeta identidade/meta, não o miolo do export |
| `txtExport + executor` | pasta `.txt` + `.zip`        | a rota afeta identidade/meta, não o miolo do export |

### Observações importantes

* O CLI aceita `txtExport` e também o alias `txt_export`.
* Internamente, `txtExport` é persistido como `ExtractionMode = txt_export`.

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

Os nomes seguem uma taxonomia determinística por modo e rota.

Exemplos:

```text
_bundle_executor__MeuProjeto.md
_blueprint_diretor__MeuProjeto.md
_meta-prompt_blueprint_diretor__MeuProjeto.md
_manual_executor__MeuProjeto.md
_txt_export_executor__MeuProjeto.zip
_bundle_executor__MeuProjeto.json
```

### O que cada família representa

* `bundle`: contexto completo
* `blueprint`: contexto arquitetural/econômico
* `manual`: recorte sniper
* `meta-prompt`: framing determinístico da rota Director
* `txt_export`: exportação ZIP do modo TXT Export
* `.json`: metadata local da execução

---

## Estrutura do projeto

```text
VibeToolkit/
├── Instalar VibeToolkit.cmd
├── setup-vibe-toolkit.ps1
├── project-bundler-cli.ps1
├── project-bundler-headless.ps1
├── run-vibe-headless.vbs
├── install-vibe-menu.cmd
├── install-vibe-menu.ps1
├── uninstall-vibe-menu.cmd
├── uninstall-vibe-menu.ps1
├── lib/
│   └── SentinelUI.ps1
├── modules/
│   ├── VibeBundleWriter.psm1
│   ├── VibeDirectorProtocol.psm1
│   ├── VibeFileDiscovery.psm1
│   └── VibeSignatureExtractor.psm1
└── README.md
```

### Papéis principais dos arquivos

* **`project-bundler-cli.ps1`**: engine principal
* **`project-bundler-headless.ps1`**: wrapper fino para preservar integração operacional
* **`run-vibe-headless.vbs`**: launcher do menu de contexto
* **`install-vibe-menu.ps1`**: grava a integração de shell
* **`uninstall-vibe-menu.ps1`**: remove integrações existentes
* **`modules/*`**: descoberta, escrita, protocolo e extração de assinaturas
* **`lib/SentinelUI.ps1`**: camada visual do terminal

---

## Comportamento relevante do produto

### Descoberta de arquivos

O toolkit ignora artefatos gerados anteriormente e trabalha apenas sobre arquivos elegíveis do projeto.

### Metadata local

Toda execução gera metadata local em JSON ao lado do artefato final correspondente.

---

## Política de runtime

Regra operacional do projeto:

* **Tentar `pwsh` primeiro**
* **Usar `powershell.exe` apenas como fallback no Windows**
* **Não tratar Windows PowerShell 5.1 como padrão**
* **Em Linux/macOS, manter dependência de `pwsh`**

Essa política preserva compatibilidade com ambientes Windows legados sem rebaixar o fluxo principal quando PowerShell 7 estiver disponível.

---

## Resumo

O VibeToolkit opera com dois princípios práticos:

1. **PS7-first**
2. **PS5.1 apenas como contingência no Windows**

Com isso, os launchers e entrypoints mantêm o caminho moderno como padrão, sem perder degradabilidade onde o PowerShell 7 não estiver disponível.
