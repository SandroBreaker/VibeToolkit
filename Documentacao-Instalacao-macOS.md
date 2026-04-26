# Documentação: Instalação do "Menu de Contexto" (Toolbar Applet) no macOS

Este documento contém todo o código e as instruções necessárias para replicar a adaptação do **VibeToolkit** para macOS. Como o macOS não permite edição de registro para injetar opções no "Botão Direito" com facilidade, a solução ideal e nativa do sistema é usar um **AppleScript convertido em um Aplicativo macOS (Droplet)**, que pode ser colocado na Barra de Ferramentas do Finder.

Siga os passos abaixo (ou peça para a sua IA seguir) para replicar essa solução no projeto principal.

---

## Passo 1: Criar o Script Gerador

Na raiz do repositório `VibeToolkit`, crie um novo arquivo chamado `Instalar-VibeToolkit-macOS.command`.

**Conteúdo do arquivo `Instalar-VibeToolkit-macOS.command`:**

```bash
#!/bin/bash

echo "======================================================"
echo "      VibeToolkit - Instalador para macOS"
echo "======================================================"

# Diretório atual do script
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
HEADLESS_SCRIPT="$REPO_ROOT/entrypoints/project-bundler-headless.ps1"
APP_NAME="VibeToolkit-Terminal"
APP_PATH="$REPO_ROOT/$APP_NAME.app"

if [ ! -f "$HEADLESS_SCRIPT" ]; then
    echo "Erro: O script headless não foi encontrado em:"
    echo "$HEADLESS_SCRIPT"
    exit 1
fi

echo "[*] Gerando o aplicativo nativo para macOS..."

# Cria um script AppleScript temporário
TMP_SCRIPT="/tmp/vibetoolkit-mac.applescript"

cat << 'EOF' > "$TMP_SCRIPT"
on run
    tell application "Finder"
        set selectedItems to selection
        if (count of selectedItems) > 0 then
            set targetPath to POSIX path of (item 1 of selectedItems as alias)
        else
            try
                set targetPath to POSIX path of (target of front Finder window as alias)
            on error
                set targetPath to POSIX path of (path to desktop)
            end try
        end if
    end tell
    
    set pwshScript to "###SCRIPT_PATH###"
    set theCommand to "pwsh -NoProfile -ExecutionPolicy Bypass -File " & quoted form of pwshScript & " -Path " & quoted form of targetPath
    
    tell application "Terminal"
        activate
        do script theCommand
    end tell
end run

on open droppedItems
    set targetPath to POSIX path of (item 1 of droppedItems)
    set pwshScript to "###SCRIPT_PATH###"
    set theCommand to "pwsh -NoProfile -ExecutionPolicy Bypass -File " & quoted form of pwshScript & " -Path " & quoted form of targetPath
    
    tell application "Terminal"
        activate
        do script theCommand
    end tell
end open
EOF

# Substitui o placeholder pelo caminho absoluto do script PowerShell
sed -i '' "s|###SCRIPT_PATH###|$HEADLESS_SCRIPT|g" "$TMP_SCRIPT"

# Compila o AppleScript em um aplicativo macOS (.app)
osacompile -o "$APP_PATH" "$TMP_SCRIPT"

# Remove o script temporário
rm "$TMP_SCRIPT"

echo "[*] Concluído!"
echo "======================================================"
echo "✅ Aplicativo criado com sucesso: $APP_NAME.app"
echo ""
echo "No macOS, a melhor alternativa ao 'Menu de Contexto' do Windows"
echo "é colocar este App na Barra de Ferramentas do Finder. É mais"
echo "rápido (1 clique) e funciona em qualquer pasta."
echo ""
echo "COMO INSTALAR NO FINDER:"
echo "1. Abra o Finder."
echo "2. Pressione e segure a tecla Command (⌘)."
echo "3. Arraste o '$APP_NAME.app' para a barra de ferramentas"
echo "   no topo da janela do Finder e solte."
echo ""
echo "COMO USAR:"
echo "A. Clique no botão na barra de ferramentas para abrir o VibeToolkit"
echo "   na pasta atual (ou na pasta que estiver selecionada)."
echo "B. Ou, simplesmente arraste e solte uma pasta em cima do aplicativo."
echo "======================================================"
```

---

## Passo 2: Dar permissão de execução

Após salvar o arquivo, abra o terminal no repositório real e dê permissão de execução ao script para que ele possa ser executado com 2 cliques:

```bash
chmod +x Instalar-VibeToolkit-macOS.command
```

---

## Passo 3: Gerar e "Instalar" no Finder

1. No Finder do macOS, dê **dois cliques** no arquivo `Instalar-VibeToolkit-macOS.command`.
2. Um terminal abrirá rapidamente para processar a compilação e, ao final, você verá o aplicativo recém gerado: **`VibeToolkit-Terminal.app`** surgir na pasta.
3. Este App serve como o seu **"Menu de Contexto"**.
4. **Instalação Final na Interface**: 
   - Segure a tecla **`Command (⌘)`**.
   - Arraste e solte o `VibeToolkit-Terminal.app` na barra de ferramentas superior de qualquer janela do Finder (ao lado dos botões de voltar/avançar).

Sempre que clicar nele, ele detectará imediatamente a pasta em que você está (ou a que você tem selecionada) e abrirá o terminal rodando o PowerShell automaticamente. Você também pode arrastar e soltar pastas diretamente em cima do ícone do App.

---
**Nota para a IA que irá aplicar isso:** 
*Garanta que o caminho para o `project-bundler-headless.ps1` definido na variável `HEADLESS_SCRIPT` esteja correto em relação à estrutura do repositório destino.*
