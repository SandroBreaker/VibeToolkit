# 🌀 VibeToolkit

O **VibeToolkit** é uma ferramenta de automação para desenvolvedores que utiliza o SDK do Groq (IA) para gerar documentos de contexto (`_AI_CONTEXT_*.md`) de forma inteligente e rápida.

## 🚀 Instalação Rápida (Windows)

Para configurar o menu de contexto (Botão Direito) e preparar o ambiente, utilize o instalador que geramos:

1. Vá até a pasta `C:\dev\VibeToolkit`.
2. Execute o arquivo **`VibeToolkit-Setup.exe`** como Administrador.
3. Confirme a alteração no Registro quando solicitado.

> **Nota:** O instalador configura automaticamente a política de execução do PowerShell e verifica se o Node.js está presente no sistema.

---

## 🛠️ Estrutura do Projeto

O toolkit é composto pelos seguintes arquivos principais:

* **`groq-agent.ts`**: Core da inteligência, responsável pela interação com a API do Groq.
* **`project-bundler.ps1`**: Script que processa os arquivos locais para criar o "bundle" de contexto.
* **`VibeToolkit-Setup.exe`**: Executável de instalação e configuração do menu de contexto do Windows.
* **`.env`**: Arquivo de configuração para sua chave de API e variáveis de ambiente.

---

## 💻 Desenvolvimento e Requisitos

Se você desejar modificar o comportamento da IA ou do agente:

### Pré-requisitos

* Node.js instalado.
* Chave de API do Groq configurada no arquivo `.env`.

### Configuração de Dev

```bash
# 1. Instalar dependências
npm install

# 2. Configurar variáveis de ambiente
cp .env.example .env

# 3. Executar o agente manualmente
node groq-agent.ts

```

---

## 📄 Fluxo de Dados

1. O usuário clica com o botão direito em uma pasta/arquivo.
2. O menu **"Gerar Blueprint / Contexto (Vibe AI)"** aciona o script.
3. O `GroqService` processa as informações usando o modelo de linguagem.
4. Um arquivo Markdown estruturado é gerado com o prefixo `_AI_CONTEXT_`.

---
