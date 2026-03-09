# ⚡ VibeToolkit - AI Context Synthesizer & Bundler

O **VibeToolkit** é uma ferramenta de linha de comando (CLI) construída com **PowerShell** e **Node.js** que atua como um engenheiro reverso para seus projetos de software.

Ele varre seu repositório, extrai contratos, tipagens e arquitetura, e utiliza a API da **Groq (Llama 3.3 70B)** para gerar um "Super Prompt" de altíssima densidade. O resultado é um documento otimizado que você envia para qualquer LLM (ChatGPT, Claude, Gemini) para que a IA codifique no seu projeto com precisão milimétrica e zero alucinação.

## 🚨 O Problema que Resolvemos

Trabalhar com LLMs em projetos grandes envolve um gargalo terrível de contexto:

1. **Caos Manual:** Copiar e colar dezenas de arquivos é lento e gera erros.
2. **Desperdício de Tokens:** Enviar o código inteiro é caro e "dilui" a atenção da IA.
3. **Alucinação Arquitetural:** Sem interfaces claras, a IA inventa propriedades e quebra o build.

## 🛠️ A Solução (Vibe Workflow)

O toolkit automatiza a extração e cria um **AI Context Document** (`.md`) consolidado contendo:

* **Persona Executora:** Instruções estritas para garantir entregas de código completas.
* **AI Briefing (Zero Fluff):** Resumo estratégico gerado pelo Llama 3 focado em Tech Stack e Guardrails.
* **Project Blueprint:** Mapeamento de assinaturas, tipos e estruturas de arquivos para referência técnica.

---

## 🌟 Dica de Ouro: Como interagir com o resultado

Para um pair-programming de elite com Claude, ChatGPT ou Gemini, não basta apenas enviar o arquivo. Use a **consciência situacional** a seu favor:

1. Faça o upload do arquivo gerado (ex: `_AI_CONTEXT_MeuProjeto.md`).
2. Faça o upload do arquivo específico que você quer modificar (ex: `UserService.ts`).
3. **Dê a ordem mestre:** > *"Analise o arquivo `_AI_CONTEXT_` anexo para entender nossos padrões globais. Agora, refatore este `UserService.ts` para implementar o novo padrão de erro definido no Blueprint, garantindo que a tipagem respeite a interface `IAppError`."*

---

## 🚀 Como Instalar

### Pré-requisitos

* **Node.js** (v18+).
* **PowerShell**.
* Chave de API gratuita da [Groq Console](https://console.groq.com/).

### Passo a Passo

1. Clone este repositório.
2. Instale as dependências:
```bash
npm install

```


3. Configure sua chave no arquivo `.env` (use o `.env.example` como base):
```env
GROQ_API_KEY=gsk_sua_chave_aqui

```



### 🖱️ Setup Automático (Windows)

Para facilitar a vida, o toolkit vem com um script que configura as permissões do PowerShell e adiciona a ferramenta ao seu menu do botão direito:

1. Execute o script `setup-menu.ps1` como **Administrador**.
2. O script configurará a política de execução (`RemoteSigned`) e integrará o menu automaticamente.
3. **Pronto!** Clique com o botão direito em qualquer pasta de projeto e selecione **"Gerar Blueprint / Contexto (Vibe AI)"**.

---

## 💻 Modos de Extração

Ao rodar o toolkit, você terá três opções no menu interativo:

| Modo | Descrição | Quando usar |
| --- | --- | --- |
| **[ 1 ] BUNDLER** | Consolida o código-fonte completo de todos os arquivos permitidos. | Projetos pequenos onde o código inteiro cabe no contexto da IA. |
| **[ 2 ] BLUEPRINT** | Extrai apenas a "casca" técnica: interfaces, tipos, classes e assinaturas. | Projetos grandes onde você precisa que a IA entenda a arquitetura sem ler todo o código. |
| **[ 3 ] SELECTIVE** | Permite escolher manualmente quais arquivos entrarão no contexto. | Quando você está trabalhando em uma feature específica que toca apenas 3 ou 4 arquivos. |

---

## 🛡️ Segurança e Privacidade

O toolkit ignora automaticamente `node_modules`, `.git`, arquivos de lock e outros dados sensíveis via lista de exclusão configurável. O processamento via Groq foca apenas na extração da lógica estrutural.

---

**Quer que eu te ajude a gerar um arquivo `.env.example` pronto para acompanhar esse README?**