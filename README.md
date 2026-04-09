Aqui está o **README.md completo** para o VibeToolkit, pensado para **iniciantes** e incluindo todas as melhorias (instalador automático, menu de contexto, etc.):

```markdown
# 🧰 VibeToolkit

**Empacotador de código para IAs** – transforme qualquer projeto em um artefato pronto para ChatGPT, Claude, Gemini ou qualquer outro assistente.

> ✅ 100% PowerShell • Zero dependências externas • Funciona em Windows • Instalação com dois cliques

---

## 🎯 Para que serve?

Você tem um projeto com vários arquivos (código, configurações, docs) e quer enviar tudo para uma IA de forma **organizada** e **completa**? O VibeToolkit:

- 📦 **Empacota** todos os arquivos relevantes em um único arquivo Markdown.
- 🧠 **Extrai assinaturas** de funções/classes (modo blueprint).
- ✂️ **Modo Sniper** – seleciona apenas os arquivos que você quer.
- 🖱️ **Menu de contexto** no Windows Explorer – clique com botão direito em qualquer pasta e execute.
- 🚀 **Instalador automático** – resolve a política de execução do PowerShell.

---

## 📋 Requisitos

- **Windows 10 ou 11** (funciona também em Linux/macOS via PowerShell 7, mas sem menu de contexto).
- **PowerShell** – pode ser o **PowerShell 5** (já vem no Windows) ou o **PowerShell 7+** (recomendado).
- Nenhuma outra dependência (Node.js, Python, Git são opcionais).

---

## 🚀 Instalação (para iniciantes)

1. **Baixe e extraia** a pasta do VibeToolkit em qualquer lugar (ex: `C:\MeusTools\VibeToolkit`).
2. **Dê dois cliques** no arquivo `Instalar VibeToolkit.cmd` (ícone de prompt de comando).
3. Uma janela preta vai abrir. Siga as instruções:
   - Se perguntar sobre política de execução, digite `S` (Sim) para permitir scripts.
   - O instalador vai registrar o menu de contexto automaticamente.
4. Pronto! Você verá a mensagem **"Instalação concluída"**.

> ⚠️ **Se nada acontecer ao clicar duas vezes** – clique com botão direito no arquivo `.cmd` e escolha **"Executar como administrador"**.

---

## 🖱️ Como usar (após instalado)

### Opção 1 – Menu de contexto (mais fácil)
- Navegue até a pasta do seu projeto.
- Clique com **botão direito** em um espaço vazio (ou na pasta em si).
- Escolha **"VibeToolkit: Abrir Terminal (CLI)"**.
- O terminal vai abrir já dentro da pasta do projeto.
- Siga as opções do menu (escolha o modo de extração, rota, etc.).
- O artefato final será salvo na pasta do projeto e copiado para a área de transferência.

### Opção 2 – Execução direta
- Abra o **PowerShell** na pasta do VibeToolkit (ou na pasta do seu projeto).
- Digite:
  ```powershell
  .\project-bundler-cli.ps1
  ```
- Use o menu interativo para escolher as opções.

---

## 🧠 Modos de extração

| Modo | O que faz | Quando usar |
|------|-----------|--------------|
| **Full** | Envia **todos** os arquivos do projeto (código, docs, configs) | Análise completa, refatoração, debugging |
| **Blueprint** | Extrai apenas **contratos, assinaturas e estrutura** (sem código interno) | Revisão arquitetural, documentação de API |
| **Sniper** | Você **seleciona manualmente** os arquivos que quer incluir | Recorte cirúrgico, correção pontual |
| **TXT Export** | Cria uma pasta com cada arquivo em `.txt` e um `.zip` | Importação em sistemas que não aceitam Markdown |

### Rotas de saída

- **Diretor** → gera um **meta-prompt** que instrui outra IA a executar uma tarefa (modo delegado).
- **Executor** → gera o **bundle final pronto** para você copiar e colar no ChatGPT (recomendado para uso direto).

---

## 🧰 Comandos úteis (para usuários avançados)

```powershell
# Execução não interativa (útil para scripts)
.\project-bundler-cli.ps1 -NonInteractive -BundleMode full -RouteMode executor

# Especificar um diretório diferente
.\project-bundler-cli.ps1 -Path "C:\MeuProjeto"

# Modo sniper com seleção antecipada
.\project-bundler-cli.ps1 -BundleMode sniper -SelectedPaths ".\src\*.ps1", ".\README.md"
```

---

## 🗑️ Desinstalação

- Para remover o menu de contexto, execute `uninstall-vibe-menu.cmd` (dois cliques).
- Para remover o VibeToolkit por completo, basta **excluir a pasta** (não há arquivos fora dela).

---

## ❓ Perguntas frequentes

### "O Windows bloqueou a execução do script"
- O instalador `.cmd` já contorna isso. Se aparecer um aviso amarelo, clique em **"Executar mesmo assim"**.
- Se preferir, abra o PowerShell como administrador e digite:
  ```powershell
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

### "O menu de contexto não aparece depois de instalar"
- Reinicie o **Explorador de Arquivos** (ou o computador).
- Verifique se o arquivo `run-vibe-headless.vbs` está na mesma pasta do instalador.
- Execute o instalador novamente **como administrador**.

### "Quero usar no Linux/macOS"
- O menu de contexto não funciona, mas a CLI sim.
- Use o PowerShell 7 e execute:
  ```bash
  pwsh ./project-bundler-cli.ps1
  ```

### "O bundle gerado está truncado / faltando código"
- Isso foi corrigido na versão atual. Se ainda ocorrer, atualize o repositório.
- O problema era com arquivos que continham três backticks (`` ` ``) – agora o fence é dinâmico.

---

## 📁 Estrutura do projeto

```
VibeToolkit/
├── Instalar VibeToolkit.cmd      ← Instalador (clique duas vezes)
├── setup-vibe-toolkit.ps1        ← Script de configuração
├── project-bundler-cli.ps1       ← Engine principal
├── project-bundler-headless.ps1  ← Wrapper para menu de contexto
├── run-vibe-headless.vbs         ← Launcher do menu (obrigatório)
├── install-vibe-menu.cmd/.ps1    ← Instalação do menu
├── uninstall-vibe-menu.cmd/.ps1  ← Remoção do menu
├── lib/
│   └── SentinelUI.ps1            ← Interface bonita no terminal
├── modules/
│   ├── VibeBundleWriter.psm1
│   ├── VibeDirectorProtocol.psm1
│   ├── VibeFileDiscovery.psm1
│   └── VibeSignatureExtractor.psm1
└── README.md                     ← Este arquivo
```

---

## 🤝 Contribuição

Sinta-se à vontade para abrir **issues** ou **pull requests** no GitHub. O projeto é 100% PowerShell e aberto a melhorias.

---

## 📜 Licença

MIT – use, modifique, compartilhe. Mantenha os créditos.

---

**Feito para humanos e IAs funcionarem juntos.**  
🐧🌊
```

Esse README está **pronto para colar** no seu repositório. Ele:

- É claro para **iniciantes** (passo a passo, sem jargões).
- Inclui o **novo instalador** e o menu de contexto.
- Explica os modos de extração de forma prática.
- Tem uma seção de FAQ para problemas comuns.
- Usa emojis e formatação amigável.

Basta substituir o README antigo por este conteúdo. 🚀