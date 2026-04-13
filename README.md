# VibeToolkit

Toolkit em PowerShell para transformar um projeto em artefatos consumíveis por IA, com fluxo CLI/headless, modos de extração distintos e duas rotas operacionais: **via Diretor** ou **direto para Executor**.

> PowerShell 7+ • CLI/headless • Menu de contexto no Windows • Saídas em Markdown, JSON e ZIP

---

## O que o VibeToolkit faz

O VibeToolkit percorre um projeto, filtra arquivos relevantes e gera um artefato final pronto para uso com IA.

Ele cobre quatro necessidades principais:

- **Full / Tudo**: leva o contexto completo visível do projeto.
- **Architect / Blueprint**: leva estrutura, contratos e pontos de integração com custo menor de contexto.
- **Sniper / Manual**: leva só o recorte selecionado.
- **TXT Export**: exporta os arquivos textuais elegíveis para `.txt` e entrega um **ZIP final único**.

Além disso, o toolkit pode operar em duas rotas:

- **Diretor**: gera um artefato intermediário com meta-prompt local determinístico para delegação.
- **Executor**: gera o artefato final pronto para copiar e usar diretamente na IA.

---

## Como o fluxo funciona

O uso padrão segue três decisões:

1. **Origem do projeto**
   - usar o path local atual
   - ou clonar um repositório GitHub

2. **Modo de extração**
   - `full`
   - `blueprint`
   - `sniper`
   - `txtExport`

3. **Rota de saída**
   - `director`
   - `executor`

No Windows, o caminho mais simples é pelo menu de contexto. Em qualquer ambiente com PowerShell 7, a CLI também pode ser executada diretamente.

---

## Requisitos

### Obrigatórios
- **PowerShell 7 ou superior**
- Permissão para executar scripts locais

### Opcionais
- **Git**, apenas para o fluxo de clonagem de repositório GitHub
- Windows Explorer, apenas para o menu de contexto

### Compatibilidade
- **Windows**: suporte completo, incluindo instalador e menu de contexto
- **Linux/macOS**: uso via CLI; o menu de contexto do Windows não se aplica

---

## Instalação no Windows

### Instalação recomendada
1. Extraia ou clone a pasta do VibeToolkit.
2. Execute **`Instalar VibeToolkit.cmd`**.
3. O instalador:
   - verifica a política de execução
   - sugere ajuste para `RemoteSigned` no escopo do usuário, quando necessário
   - instala o menu **`VibeToolkit: Abrir Terminal (CLI)`**

### O que é instalado
A integração de shell é registrada no escopo do usuário atual, via `HKEY_CURRENT_USER\Software\Classes`, sem depender de caminho fixo do repositório.

---

## Uso rápido

### Opção 1 — menu de contexto no Windows
1. Clique com o botão direito em uma pasta, em seu fundo ou em uma unidade.
2. Escolha **`VibeToolkit: Abrir Terminal (CLI)`**.
3. O toolkit abre no terminal já apontando para o alvo escolhido.
4. Selecione origem, modo e rota.

### Opção 2 — CLI direta
Na pasta do toolkit:

```powershell
.\project-bundler-cli.ps1
```

Ou apontando para outro projeto:

```powershell
.\project-bundler-cli.ps1 -Path "C:\MeuProjeto"
```

---

## Modos de extração

| Modo | Objetivo | Saída típica |
|---|---|---|
| `full` | contexto completo do projeto | bundle Markdown + metadata JSON |
| `blueprint` | estrutura, contratos e integração com menor custo | blueprint Markdown + metadata JSON |
| `sniper` | recorte manual e cirúrgico | bundle manual Markdown + metadata JSON |
| `txtExport` | exportação textual para ambientes que preferem arquivos `.txt` | **ZIP final** + metadata JSON |

### Observações por modo

#### Full / Tudo
Use quando a IA precisa do máximo de contexto visível: código, docs, configs e estrutura.

#### Architect / Blueprint
Use quando o foco é arquitetura, contratos, entrypoints, integração e leitura econômica de contexto.

#### Sniper / Manual
Use quando você já sabe quais arquivos quer enviar e precisa de um recorte mínimo, sem carregar o restante do projeto.

#### TXT Export
Use quando o destino não trabalha bem com bundle Markdown.

No contrato atual do projeto, o `txtExport`:
- gera os `.txt` internamente
- compacta o resultado
- remove o staging ao final
- deixa **apenas o `.zip` como artefato final visível**

---

## Rotas de saída

| Rota | Objetivo |
|---|---|
| `director` | gerar um artefato analítico com meta-prompt local determinístico |
| `executor` | gerar o contexto final pronto para uso direto |

### Quando usar `director`
Quando você quer que outra IA receba um framing operacional mais forte, com instrução explícita de leitura do artefato e de atuação por papel.

### Quando usar `executor`
Quando você quer o resultado final pronto para colar na IA sem camada intermediária.

---

## Exemplos de uso

### Full + Executor
```powershell
.\project-bundler-cli.ps1 -NonInteractive -BundleMode full -RouteMode executor
```

### Blueprint + Diretor
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

### Clonando um repositório GitHub
Execute a CLI sem `-NonInteractive` e escolha a origem remota no passo 1. O fluxo permite clonagem temporária ou manual e pode limpar o clone ao final da execução.

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
- `bundle`: contexto completo
- `blueprint`: contexto arquitetural/econômico
- `manual`: recorte sniper
- `meta-prompt`: framing determinístico da rota Diretor
- `txt_export`: exportação ZIP do modo TXT Export
- `.json`: metadata local da execução

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
- **`project-bundler-cli.ps1`**: engine principal
- **`project-bundler-headless.ps1`**: wrapper fino para preservar integração visual
- **`run-vibe-headless.vbs`**: launcher do menu de contexto
- **`install-vibe-menu.ps1`**: grava a integração de shell
- **`uninstall-vibe-menu.ps1`**: remove integrações portáveis e legadas conhecidas
- **`modules/*`**: descoberta, escrita, protocolo e extração de assinaturas
- **`lib/SentinelUI.ps1`**: camada visual do terminal

---

## Comportamento relevante do produto

### Descoberta de arquivos
O toolkit ignora artefatos gerados anteriormente e trabalha só sobre extensões elegíveis do projeto.

### Metadata local
Toda execução gera metadata local em JSON ao lado do artefato final correspondente.

### Clonagem temporária
Quando a origem é GitHub, o toolkit pode clonar para diretório temporário e remover esse clone ao final da execução, salvo quando o usuário opta por mantê-lo.

### UI e fallback
A UI principal usa SentinelUI. O projeto também mantém fallback local para garantir operação em cenários onde o bootstrap visual falha.

---

## Desinstalação

### Remover apenas o menu de contexto
Execute:

```powershell
.\uninstall-vibe-menu.cmd
```

ou

```powershell
.\uninstall-vibe-menu.ps1
```

### Remover o toolkit por completo
Exclua a pasta do repositório.

---

## Solução de problemas

### O script não executa por causa da política do PowerShell
Rode o instalador recomendado (`Instalar VibeToolkit.cmd`).  
Se precisar ajustar manualmente:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### O menu de contexto não apareceu
- execute o instalador novamente
- reinicie o Explorer
- confirme que `run-vibe-headless.vbs` está presente na pasta do toolkit

### O fluxo de clonagem falha
Verifique:
- se o Git está instalado e no `PATH`
- se a URL do repositório está correta
- se há conectividade de rede

### Quero usar em Linux ou macOS
Use a CLI com PowerShell 7:

```bash
pwsh ./project-bundler-cli.ps1
```

---

## Filosofia operacional

O toolkit foi moldado para uso local e determinístico, com separação explícita entre:
- extração de contexto
- framing operacional
- artefato final

A combinação de **modos de extração**, **rotas de saída** e **metadata local** permite adaptar o mesmo projeto a cenários de análise completa, blueprint arquitetural, recorte cirúrgico ou exportação textual.

---

## Licença

MIT.
