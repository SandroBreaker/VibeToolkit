# Documentação Técnica — VibeToolkit

## 1. Objetivo do projeto

O VibeToolkit é uma engine de **empacotamento de contexto técnico** e **orquestração de LLMs** voltada para fluxos de engenharia agêntica. Seu papel é reduzir ambiguidade operacional entre análise e implementação, convertendo um repositório de código em artefatos controlados para dois papéis:

- **Diretor**: camada analítica e de arquitetura de contexto.
- **Executor**: camada de implementação e materialização técnica.

---

## 2. Visão arquitetural atual

A arquitetura observada é híbrida e composta por dois eixos principais:

### 2.1 Eixo local (PowerShell)
Responsável pela UX operacional e pela geração local de bundles.

Arquivo principal:
- `project-bundler.ps1`

Funções de alto nível:
- UI/HUD em WinForms;
- seleção de modo, rota e provider;
- descoberta e filtragem de arquivos;
- geração de bundles locais;
- exportação TXT;
- logging;
- chamada do agente TypeScript.

### 2.2 Eixo de IA (TypeScript)
Responsável pela construção dos prompts, cadeia de providers e persistência dos artefatos gerados via IA.

Arquivo principal:
- `groq-agent.ts`

Funções de alto nível:
- parse de argumentos CLI;
- inferência de `routeMode` e `extractionMode`;
- normalização de prompt customization;
- construção dos prompts de Diretor e Executor;
- validação e reparo controlado de payload;
- fallback entre providers;
- classificação padronizada de erro;
- gravação dos artefatos finais.

---

## 3. Estrutura atual do projeto

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

### Leitura da estrutura
- O diretório `modules/` indica movimento de modularização do bundler.
- `project-bundler.ps1` ainda permanece como entrypoint e ainda concentra parte importante da operação.
- `groq-agent.ts` é o núcleo do pipeline estruturado.
- `patch_agent.js` atua como camada auxiliar de reforço/compliance.

---

## 4. Contratos e enums principais do agente

Observados em `groq-agent.ts`:

### Route mode
```ts
"director" | "executor"
```

### Extraction mode
```ts
"full" | "blueprint" | "sniper"
```

### Document mode
```ts
"full" | "manual"
```

### Providers
```ts
"groq" | "gemini" | "openai" | "anthropic"
```

### Modos de customização de prompt
```ts
"default" | "template" | "expertOverride"
```

### Classificação de erro
```ts
"AUTH_ERROR" | "RATE_LIMIT" | "NETWORK_ERROR" | "PARSE_ERROR" |
"PROVIDER_DOWN" | "CONFIG_ERROR" | "PAYLOAD_TOO_LARGE"
```

---

## 5. Pipeline operacional

## 5.1 Geração local de bundle
Entrada principal:
- usuário abre a HUD via `project-bundler.ps1`;
- seleciona rota, modo e provider;
- o bundler descobre os arquivos elegíveis e monta o bundle local.

### Outputs locais típicos
- `_Diretor_COPIAR_TUDO__<Projeto>.md`
- `_Diretor_INTELIGENTE__<Projeto>.md`
- `_Executor_INTELIGENTE__<Projeto>.md`
- exportações TXT e ZIP derivadas do modo TXT Export

## 5.2 Invocação do agente
O bundler chama o agente com `npx --quiet tsx groq-agent.ts` e passa, entre outros, os parâmetros:
- `bundlePath`
- `projectName`
- `executorTarget`
- `extractionMode`
- `provider`
- `routeMode`
- `resultMetaPath`

## 5.3 Processamento do agente
O `groq-agent.ts`:
1. lê o bundle;
2. infere o nome do projeto e o modo;
3. constrói o payload de prompt;
4. tenta a cadeia de providers;
5. valida/repara a resposta quando necessário;
6. grava os artefatos finais.

## 5.4 Saídas do agente
### Markdown
- `_diretor_AI_CONTEXT_<Projeto>.md`
- `_executor_AI_CONTEXT_<Projeto>.md`

### JSON
- `_diretor_AI_RESULT_<Projeto>.json`
- `_executor_AI_RESULT_<Projeto>.json`

### Sinais de integração
O agente emite marcadores para o bundler capturar:
- `[AI_RESULT] provider=...;model=...`
- `[AI_ERROR] {...}`

---

## 6. Papel dos módulos PowerShell

Mesmo sem afirmar delegação completa do runtime para eles, a estrutura atual já prevê divisão por responsabilidade:

### `VibeBundleWriter.psm1`
Responsabilidade esperada:
- escrita de bundles;
- serialização markdown;
- helpers de code fence;
- apoio ao contexto momentum.

### `VibeDirectorProtocol.psm1`
Responsabilidade esperada:
- seções do protocolo ELITE v3;
- montagem do header do Diretor;
- helpers do papel analítico.

### `VibeFileDiscovery.psm1`
Responsabilidade esperada:
- descoberta de arquivos;
- filtros estruturais;
- composição de conjunto processável.

### `VibeSignatureExtractor.psm1`
Responsabilidade esperada:
- extração de assinaturas por extensão;
- suporte a `.ps1` no modo analítico;
- fallback por linguagem não suportada.

---

## 7. Protocolo do Diretor

A versão atual já reflete o **PROTOCOLO OPERACIONAL TRANSVERSAL — ELITE v3** no fluxo do Diretor.

Elementos relevantes observados:
- identidade explícita do Diretor;
- enquadramento por `routeMode` e `extractionMode`;
- obrigação de resposta com:
  - `ANÁLISE DO DIRETOR`
  - `RACIOCÍNIO (CoT)`
  - `PROMPT PARA O EXECUTOR (COPIAR ABAIXO)`
- suporte a **Contexto Momentum** com reaproveitamento de `AI_RESULT` anterior.

---

## 8. Prompt engineering no `groq-agent.ts`

O agente já implementa um pipeline robusto de composição de prompt, incluindo:
- presets de template;
- profundidade (`normal`, `deep`, `max`);
- tom (`technical`, `surgical`, `assertive`);
- constraints e tags por rota;
- prompt de repair quando a resposta sai fora do contrato esperado.

Também existe separação entre:
- prompt do Diretor ELITE v3;
- prompt estruturado do Executor.

---

## 9. Robustez e tratamento de falhas

O `groq-agent.ts` possui:
- `AgentRuntimeError` com `status`, `details`, `retryable` e `errorType`;
- classificação central de erros HTTP;
- priorização do melhor erro ao final da cadeia;
- tentativa de fallback entre providers;
- persistência de metadados da execução;
- reparo controlado de resposta inválida.

Isso torna o agente mais previsível para o PowerShell e para a HUD.

---

## 10. Situação atual de qualidade

## 10.1 Pontos já maduros
- separação explícita entre Diretor e Executor;
- pipeline estruturado no agente;
- classificação consistente de erro;
- geração de metadados `_AI_RESULT`;
- captura de provider/model no stdout;
- presença de módulos auxiliares;
- suporte a assinatura de `project-bundler.ps1` em fluxo analítico.

## 10.2 Dívida técnica observada
A principal dívida técnica residual é **encoding na geração local do PowerShell**.

Sintoma observado:
- artefatos locais ainda exibem sequências como `â€”`, `Â§`, `VocÃª`, `ExecuÃ§Ã£o`.

Comportamento comparado:
- artefatos gerados via IA: corretos;
- artefatos gerados localmente: ainda suscetíveis a mojibake.

Interpretação:
- o problema remanescente está na camada local de geração/gravação textual, e não no `groq-agent.ts`.

---

## 11. Recomendações técnicas de manutenção

### Prioridade alta
- centralizar a política de encoding da geração local em helper único;
- revisar leitura e escrita textual no pipeline PowerShell;
- consolidar uso real dos módulos `modules/*.psm1` no runtime principal.

### Prioridade média
- reduzir responsabilidades residuais do `project-bundler.ps1`;
- avançar para arquitetura de fachada compatível + implementação modular real;
- alinhar README, documentação e UX aos contratos atuais de ELITE v3.

### Prioridade baixa
- ampliar cobertura de testes de regressão de bundles;
- consolidar documentação de templates/prompt customization;
- documentar melhor os contratos de integração PowerShell → TypeScript.

---

## 12. Convenções de nomenclatura

### Bundles locais
- `_Diretor_*__<Projeto>.md`
- `_Executor_*__<Projeto>.md`

### Saídas do agente
- `_diretor_AI_CONTEXT_<Projeto>.md`
- `_executor_AI_CONTEXT_<Projeto>.md`
- `_diretor_AI_RESULT_<Projeto>.json`
- `_executor_AI_RESULT_<Projeto>.json`

A convenção atual diferencia explicitamente:
- papel (`Diretor` / `Executor`)
- origem (`bundle local` / `AI_CONTEXT` / `AI_RESULT`)
- modo de geração

---

## 13. Resumo executivo técnico

O VibeToolkit atual já não é mais um protótipo simples de bundling. Ele evoluiu para uma base híbrida com:
- HUD operacional em PowerShell;
- agente estruturado em TypeScript;
- separação conceitual entre Diretor e Executor;
- protocolo do Diretor em ELITE v3;
- outputs Markdown + JSON;
- cadeia multi-provider com tratamento estruturado de falhas.

O principal ponto residual para estabilização não está no desenho do agente, mas sim na **camada local PowerShell**, especialmente na consistência de encoding e na consolidação da modularização iniciada.