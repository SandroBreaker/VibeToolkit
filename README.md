# VibeToolkit

VibeToolkit é um toolkit de empacotamento de contexto e orquestração de LLMs para fluxos de engenharia agêntica. O projeto combina um entrypoint local em PowerShell (`project-bundler.ps1`) com um agente TypeScript (`groq-agent.ts`) para gerar bundles técnicos, acionar providers de IA e produzir artefatos estruturados para os papéis de **Diretor** e **Executor**.

## Estado atual

A versão atual já opera com **Protocolo Operacional Transversal — ELITE v3** no fluxo do Diretor, mantém separação explícita entre `director` e `executor`, suporta extrações `full`, `blueprint` e `sniper`, e inclui uma estrutura de módulos PowerShell no diretório `modules/` para evolução da base.

A arquitetura atual ainda é **híbrida**:
- `project-bundler.ps1` continua sendo o ponto de entrada principal da HUD e da geração local.
- `groq-agent.ts` concentra a lógica de prompt engineering, cadeia de providers e escrita dos artefatos gerados via IA.
- O projeto já possui módulos auxiliares em `modules/`, mas a base ainda convive com responsabilidades relevantes no bundler principal.

## Estrutura do projeto

```text
.
├── modules/
│   ├── VibeBundleWriter.psm1
│   ├── VibeDirectorProtocol.psm1
│   ├── VibeFileDiscovery.psm1
│   └── VibeSignatureExtractor.psm1
├── groq-agent.ts
├── package.json
├── patch_agent.js
├── project-bundler.ps1
├── README.md
└── tsconfig.json
```

## Componentes centrais

### `project-bundler.ps1`
Interface operacional em PowerShell com HUD WinForms.

Responsabilidades principais:
- seleção do modo de execução;
- descoberta e filtragem de arquivos do projeto;
- geração de bundles locais;
- extração de assinaturas para modos analíticos;
- exportação TXT;
- acionamento do agente TypeScript;
- pré-validação de bundles idênticos;
- logging operacional.

### `groq-agent.ts`
Agente principal de orquestração de IA.

Responsabilidades principais:
- normalização de `routeMode` e `extractionMode`;
- construção de prompts para Diretor e Executor;
- cadeia de fallback entre providers;
- classificação de erros (`AUTH_ERROR`, `RATE_LIMIT`, `NETWORK_ERROR`, `CONFIG_ERROR`, etc.);
- geração de `_AI_CONTEXT_*.md` e `_AI_RESULT_*.json`;
- emissão de marcadores estruturados em stdout/stderr (`[AI_RESULT]`, `[AI_ERROR]`).

### `patch_agent.js`
Script auxiliar para reforço/patching de comportamento do agente.

### `modules/*.psm1`
Módulos auxiliares introduzidos para separar responsabilidades de bundling, protocolo do Diretor, descoberta de arquivos e extração de assinaturas.

## Modos operacionais

### Route modes
- `director`: gera contexto e prompts analíticos.
- `executor`: gera contexto orientado à implementação.

### Extraction modes
- `full`: visão ampla do projeto.
- `blueprint`: foco em arquitetura, contratos e assinaturas.
- `sniper`: recorte cirúrgico para ajustes pontuais.

## Artefatos gerados

### Bundles locais
Gerados diretamente pelo PowerShell, por exemplo:
- `_Diretor_COPIAR_TUDO__<Projeto>.md`
- `_Diretor_INTELIGENTE__<Projeto>.md`
- `_Executor_INTELIGENTE__<Projeto>.md`

### Artefatos gerados via IA
Gerados pelo `groq-agent.ts`:
- `_diretor_AI_CONTEXT_<Projeto>.md`
- `_executor_AI_CONTEXT_<Projeto>.md`
- `_diretor_AI_RESULT_<Projeto>.json`
- `_executor_AI_RESULT_<Projeto>.json`

## Providers suportados

O agente suporta os providers:
- `groq`
- `gemini`
- `openai`
- `anthropic`

## Requisitos

- Windows com PowerShell e suporte a WinForms para a HUD.
- Node.js.
- `tsx`/TypeScript conforme `package.json`.
- Chaves de API configuradas via `.env` quando o fluxo com IA estiver habilitado.

## Instalação

```bash
npm install
```

Exemplo de `.env`:

```env
GROQ_API_KEY=...
GEMINI_API_KEY=...
OPENAI_API_KEY=...
ANTHROPIC_API_KEY=...
```

## Uso

### HUD local
```powershell
.\project-bundler.ps1
```

### CLI do agente
```bash
npx --quiet tsx .\groq-agent.ts \
  --bundlePath ".\_Executor_INTELIGENTE__MeuProjeto.md" \
  --projectName "MeuProjeto" \
  --provider "groq" \
  --routeMode "executor"
```

## Fluxo resumido

1. O bundler local monta um bundle a partir do projeto.
2. O usuário escolhe rota, modo de extração, provider e envio para IA.
3. O `groq-agent.ts` lê o bundle, constrói o prompt apropriado e tenta a cadeia de providers.
4. O resultado validado é salvo em Markdown (`_AI_CONTEXT_*.md`) e JSON (`_AI_RESULT_*.json`).

## Situação técnica relevante

### Já consolidado
- Protocolo do Diretor em ELITE v3.
- Separação semântica entre Diretor e Executor.
- Extração de assinatura de `project-bundler.ps1` presente no modo Architect/Inteligente.
- Proteção contra quebra de code fence no modo de cópia integral.
- Contexto Momentum para reaproveitar `AI_RESULT` anterior quando disponível.

### Ponto em aberto
Os artefatos **gerados localmente pelo PowerShell** ainda apresentam problema de encoding em parte do pipeline, com sinais de mojibake em alguns bundles locais. Os artefatos gerados via IA já saem corretos, o que indica que o ajuste residual precisa acontecer na camada de geração local.