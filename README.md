Gerando arquivo README.md para VibeToolkit
bash -lc cat > /mnt/data/README.md <<'EOF'

# VibeToolkit

Toolkit operacional para **empacotar contexto técnico**, **extrair recortes estruturados do projeto** e **gerar artefatos prontos para Diretor/Executor** no fluxo de engenharia agêntica.

O projeto combina um **HUD em PowerShell/WinForms**, módulos PowerShell para descoberta e serialização de contexto, e um agente TypeScript para saída estruturada e integração com provider de IA quando aplicável.

> Estado documental desta versão: este README foi reconstruído a partir do bundle/manual visível do projeto e do material complementar anexado no artefato enviado.

---

## Visão geral

O VibeToolkit foi desenhado para transformar uma pasta de código em artefatos operacionais com alto sinal técnico.

Capacidades centrais:

- **Bundler**: consolida arquivos relevantes do projeto em um artefato legível.
- **Blueprint**: extrai visão estrutural focada em contratos, assinaturas e superfícies de integração.
- **Sniper / Manual**: trabalha com recorte parcial e controlado, sem extrapolar contexto invisível.
- **Route modes**:
  - **Director**: produz contexto/meta-prompt para análise e especificação.
  - **Executor**: produz contexto pronto para implementação direta.
- **Deterministic mode**: permite gerar meta-prompt localmente, sem provider remoto.
- **Momentum context**: reaproveita o último `AI_RESULT_*.json` válido como estado anterior.
- **Safe patching**: inclui utilitário para correção segura de trechos conhecidos do `groq-agent.ts`.

---

## Arquitetura

### 1. Camada de entrada / HUD

Arquivo principal:

- `project-bundler.ps1`

Responsabilidades visíveis:

- bootstrap do toolkit;
- carregamento da UI Sentinel (`lib/SentinelUI.ps1`);
- inicialização de WinForms;
- definição do ponto de entrada operacional do bundler;
- orquestração do fluxo de geração dos artefatos.

A HUD usa a biblioteca `SentinelUI.ps1` para identidade visual e feedback de execução, com:

- header ASCII “SENTINEL”;
- mensagens de status coloridas;
- menu e spinner simples no console. fileciteturn2file0

### 2. Camada de utilitários PowerShell

#### `modules/VibeBundleWriter.psm1`

Fornece funções de IO e serialização seguras:

- leitura de arquivos com detecção de encoding UTF-8/UTF-16/UTF-32;
- escrita UTF-8 com ou sem BOM;
- geração de fences Markdown seguros;
- resolução e materialização de contexto momentum;
- mapeamento de extensões para linguagem de bloco de código. fileciteturn2file0

#### `modules/VibeDirectorProtocol.psm1`

Centraliza a construção de slices e headers de protocolo para os dois papéis do sistema:

- labels de extração (`FULL`, `BLUEPRINT`, `SNIPER`);
- slices de modo Diretor;
- slices de modo Executor;
- cabeçalhos ELITE v3.1 e ELITE v4.1;
- seções de metadata, governança, engenharia de meta-prompt e contexto momentum. fileciteturn2file0turn2file1

#### `modules/VibeFileDiscovery.psm1`

Responsável por descoberta recursiva de arquivos relevantes e exclusão de artefatos gerados automaticamente, como:

- `_BUNDLER__*`
- `_BLUEPRINT__*`
- `_SELECTIVE__*`
- `_COPIAR_TUDO__*`
- `_INTELIGENTE__*`
- `_MANUAL__*`
- `_AI_CONTEXT_*`
- `_AI_RESULT_*` fileciteturn2file1

#### `modules/VibeSignatureExtractor.psm1`

Extrai assinaturas relevantes de arquivos para visão arquitetural/blueprint, com suporte visível para:

- PowerShell (`function`, `filter`, `param`);
- TypeScript/JavaScript (`interface`, `type`, `enum`, `const`, `function`, `class`);
- além de padrões para outras linguagens como C#, Python, Go e Rust. fileciteturn2file1

### 3. Camada de agente TypeScript

Arquivo principal:

- `groq-agent.ts`

Responsabilidades visíveis:

- definição dos tipos centrais do pipeline;
- configuração de `routeMode`, `extractionMode`, `documentMode`, provider e modos de prompt;
- registro de templates operacionais por cenário;
- classificação de falhas de provider (`AUTH_ERROR`, `RATE_LIMIT`, `NETWORK_ERROR`, `PARSE_ERROR`, `PROVIDER_DOWN`, `CONFIG_ERROR`, `PAYLOAD_TOO_LARGE`);
- geração de saída estruturada para Director/Executor;
- suporte a template determinístico `director_meta_v1`;
- emissão de marcadores estruturados como `[AI_RESULT]` e `[AI_ERROR]` para consumo pelo PowerShell. fileciteturn2file1turn3file1

### 4. Camada de reparo local

Arquivo auxiliar:

- `patch_agent.js`

Função:

- aplicar reparos conhecidos e seguros no `groq-agent.ts`;
- validar se fragmentos sintaticamente perigosos ainda existem;
- gerar backup `.bak` antes de sobrescrever o agente quando houver mudança. fileciteturn3file0turn3file4

---

## Estrutura visível do projeto

```text
.
├─ lib/
│  └─ SentinelUI.ps1
├─ modules/
│  ├─ VibeBundleWriter.psm1
│  ├─ VibeDirectorProtocol.psm1
│  ├─ VibeFileDiscovery.psm1
│  └─ VibeSignatureExtractor.psm1
├─ groq-agent.ts
├─ patch_agent.js
├─ project-bundler.ps1
├─ package.json
├─ tsconfig.json
├─ PROTOCOLO-OPERACIONAL-ajustado.md
└─ PROTOCOLO-OPERACIONAL.json
Estrutura confirmada pelo bundle manual enviado. fileciteturn1file3

Modos operacionais
Route mode
director: prepara contexto analítico e meta-prompt para o Executor.

executor: prepara contexto direto para implementação. fileciteturn2file1turn2file2

Extraction mode
full: visão ampla do projeto contido no bundle.

blueprint: foco em contratos, assinaturas e organização.

sniper: recorte manual/parcial, sem extrapolação. fileciteturn2file1

Document mode
full

manual fileciteturn2file1

Prompt modes visíveis no agente
default

template

expertOverride fileciteturn2file1

Providers tipados no agente
groq

gemini

openai

anthropic

local fileciteturn2file1

Templates operacionais visíveis
No groq-agent.ts, o registro de presets inclui, entre outros:

Para Director
director.full.diagnostic

director.full.feature-planning

director.full.architecture-review

director.full.hardening

director_meta_v1 (template determinístico local) fileciteturn2file1turn2file2

Para Executor
executor.full.surgical-patch

executor.full.feature-implementation

executor.full.safe-refactor

executor.full.regression-fix fileciteturn2file1

Fluxo operacional resumido
Projeto alvo
   ↓
project-bundler.ps1
   ↓
carrega SentinelUI + módulos PowerShell
   ↓
descobre arquivos relevantes
   ↓
extrai conteúdo / assinaturas / contexto momentum
   ↓
monta artefato conforme routeMode + extractionMode
   ↓
(opcional) delega ao groq-agent.ts
   ↓
gera saída final Markdown/JSON pronta para uso
Esse desenho é sustentado pela combinação do bootstrap do project-bundler.ps1, pelos módulos de descoberta/escrita/protocolo e pelos tipos e templates do groq-agent.ts. fileciteturn3file4turn2file0turn2file1

Requisitos
Ambiente Windows
O projeto usa:

PowerShell;

System.Windows.Forms;

System.Drawing.

Isso indica execução primária em ambiente Windows com .NET disponível para WinForms. fileciteturn3file4

Node.js / TypeScript
Dependências declaradas:

{
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
O tsconfig.json compila com:

target: ES2022

module: CommonJS

strict: true

outDir: ./dist fileciteturn3file0turn3file3

Instalação
1. Instalar dependências Node
npm install
2. Garantir política de execução adequada no PowerShell
Exemplo comum para sessão atual:

Set-ExecutionPolicy -Scope Process Bypass
Necessário quando o ambiente bloquear scripts .ps1 não assinados.

3. Configurar variáveis de ambiente
Crie um arquivo .env na raiz quando for usar provider remoto.

Exemplo mínimo para Groq:

GROQ_API_KEY=seu_token_aqui
O bundle visível mostra uso de dotenv/config no agente TypeScript. fileciteturn2file1

Como executar
Executar o bundler na pasta atual
.\project-bundler.ps1
Executar apontando para uma pasta-alvo
.\project-bundler.ps1 -Path "C:\dev\SeuProjeto"
O script recebe um parâmetro Path com default ".". fileciteturn3file4

Utilitário de reparo do agente
Quando houver quebra conhecida no groq-agent.ts, execute:

node patch_agent.js
Comportamento esperado:

verifica se groq-agent.ts existe;

aplica correções de ranges conhecidos;

valida fragmentos perigosos;

cria backup groq-agent.ts.bak antes de sobrescrever. fileciteturn3file0turn3file4

Artefatos e convenções
O toolkit diferencia arquivos-fonte de artefatos gerados. Alguns padrões ignorados pela descoberta:

_Diretor_BUNDLER__*

_Executor_BUNDLER__*

_BLUEPRINT__*

_SELECTIVE__*

_COPIAR_TUDO__*

_INTELIGENTE__*

_MANUAL__*

_AI_CONTEXT_*

_AI_RESULT_* fileciteturn2file1

Também há suporte a context momentum, buscando o JSON mais recente com padrão AI_RESULT válido para enriquecer o próximo ciclo. fileciteturn2file0

Padrões de projeto observados
Strict mode em módulos PowerShell. fileciteturn2file0turn2file1

Tipagem forte no agente TypeScript. fileciteturn2file1

Compatibilidade com leitura parcial/manual, evitando inferência fora do recorte. fileciteturn1file3turn2file1

Saída operacional estruturada, com protocolos explícitos para Diretor e Executor. fileciteturn2file1

Blindagem de encoding para reduzir corrupção de texto e mojibake. fileciteturn2file0

Tratamento de erro classificado no agente remoto/local. fileciteturn2file1turn3file1

Limitações visíveis neste recorte
Este README foi atualizado com base no material visível do bundle/manual enviado. Portanto:

o comportamento completo da HUD WinForms não está totalmente documentado neste recorte;

scripts adicionais de build, publish ou automação não aparecem além do que foi anexado;

o conteúdo integral do README.md antigo não estava claramente disponível no recorte principal, então esta versão foi reestruturada a partir da arquitetura real visível. fileciteturn1file3turn3file4

Próximos pontos naturais para documentação futura
mapa completo da HUD e seus controles;

exemplos de artefatos gerados por cada modo;

CLI/flags documentadas por cenário;

fluxo determinístico local versus fluxo com provider remoto;

troubleshooting de policy do PowerShell e parsing do agente.

Referência rápida
Arquivos centrais
project-bundler.ps1

lib/SentinelUI.ps1

modules/VibeBundleWriter.psm1

modules/VibeDirectorProtocol.psm1

modules/VibeFileDiscovery.psm1

modules/VibeSignatureExtractor.psm1

groq-agent.ts

patch_agent.js fileciteturn1file3turn3file0

Stack visível
PowerShell

WinForms

Node.js

TypeScript

dotenv

groq-sdk fileciteturn3file0turn3file3
EOF

