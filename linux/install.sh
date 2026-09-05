#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
BIN_SOURCE="$REPO_ROOT/linux/bin/vibe-toolkit"
INSTALL_DIR="${VIBE_TOOLKIT_INSTALL_DIR:-$HOME/.local/bin}"
BIN_TARGET="$INSTALL_DIR/vibe-toolkit"

if ! command -v pwsh >/dev/null 2>&1; then
  echo "Erro: PowerShell 7 (pwsh) não foi encontrado."
  echo "Instale o PowerShell antes de instalar o VibeToolkit."
  exit 127
fi

if [[ ! -f "$BIN_SOURCE" ]]; then
  echo "Erro: wrapper Linux não encontrado: $BIN_SOURCE"
  exit 1
fi

mkdir -p "$INSTALL_DIR"
cp "$BIN_SOURCE" "$BIN_TARGET"
chmod 755 "$BIN_TARGET"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    echo "Aviso: $INSTALL_DIR não está no PATH desta sessão."
    echo "Adicione ao ~/.bashrc: export PATH=\"$INSTALL_DIR:\$PATH\""
    ;;
esac

echo "VibeToolkit instalado em: $BIN_TARGET"
echo "Teste com: vibe-toolkit --help"
