# ⚡ VibeToolkit: IA com Contexto Real

O **VibeToolkit** é a ponte definitiva entre o seu código local e as IAs (ChatGPT, Claude, Gemini). Ele resolve o problema da "amnésia" das IAs, consolidando seu projeto em um único documento de contexto inteligente, permitindo que a IA entenda a arquitetura, as tecnologias e a lógica do seu sistema de uma só vez.

## 🚀 O que ele faz?

* **Mapeamento Inteligente:** Varre suas pastas ignorando arquivos desnecessários (como `node_modules` e travas de pacotes).
* **Resumo por IA:** Utiliza a API da Groq para gerar um resumo didático no topo do arquivo, explicando o projeto como um "Professor de Programação Paciente".
* **Integração Nativa:** Adiciona uma opção ao menu de contexto do Windows (botão direito na pasta) para gerar o contexto instantaneamente.

---

## 🛠️ Modos de Extração

Ao rodar a ferramenta, você pode escolher o nível de detalhe que deseja enviar para a IA:

| Modo | Descrição | Uso Ideal |
| --- | --- | --- |
| **[ 1 ] Copiar Tudo** | Consolida o código-fonte completo de todos os arquivos relevantes. | Projetos pequenos ou depuração de lógica complexa. |
| **[ 2 ] Inteligente** | Extrai apenas a "assinatura" (esqueleto) das funções, classes e interfaces. | Projetos grandes onde você quer focar na arquitetura e economizar tokens. |
| **[ 3 ] Manual** | Você seleciona individualmente na lista quais arquivos quer incluir. | Quando você precisa de ajuda com arquivos específicos e quer evitar ruído. |

---

## 📦 Tecnologias Utilizadas

* **Node.js & TypeScript:** Motor principal para processamento de texto e integração com APIs.
* **PowerShell:** Automação de sistema e integração com o explorador de arquivos do Windows.
* **Groq SDK (Llama 3):** Inteligência artificial de ultravelocidade para resumir seu código.

---

## ⚙️ Como Instalar (Passo a Passo)

1. **Pré-requisitos:** Certifique-se de ter o [Node.js](https://nodejs.org/) instalado em sua máquina.
2. **Configuração Inicial:** Dentro da pasta do VibeToolkit, clique com o botão direito no arquivo `setup-menu.ps1` e selecione **"Executar com o PowerShell"**.
3. **Chave da API:** O instalador solicitará sua chave da Groq (gratuita em [console.groq.com](https://console.groq.com)). Ela ficará salva com segurança em um arquivo `.env`.
4. **Menu de Contexto:** O script perguntará se deseja adicionar o atalho ao Windows. Confirme para poder usar o toolkit em qualquer pasta do seu PC.

---

## 📖 Como Usar no Dia a Dia

1. Vá até qualquer pasta de um projeto que você esteja desenvolvendo.
2. Clique com o **botão direito** na pasta (ou no fundo dela) e escolha **"Gerar Blueprint / Contexto (Vibe AI)"**.
3. Escolha o modo desejado no console que abrirá.
4. Um arquivo chamado `_AI_CONTEXT_NomeDoProjeto.md` será gerado.
5. **Arraste esse arquivo para o chat da sua IA favorita** e comece a fazer perguntas com contexto total!

---

## 🧹 Remoção Manual (UI)

Se desejar remover os menus de contexto sem usar scripts:

1. Abra o **Editor de Registro (regedit)**.
2. Navegue até `HKEY_CLASSES_ROOT\Directory\shell\` e exclua a chave `VibeToolkit`.
3. Navegue até `HKEY_CLASSES_ROOT\Directory\Background\shell\` e exclua a chave `VibeToolkit`.

---

> **Dica de Ouro:** Sempre envie o arquivo gerado **antes** de começar a pedir novas funcionalidades para a IA. Isso garante que ela não "alucine" sugerindo coisas que não batem com o que você já construiu.