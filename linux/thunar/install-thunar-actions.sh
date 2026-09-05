#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
ACTIONS_DIR="$HOME/.config/Thunar/uca.xml"
THUNAR_CONFIG_DIR="$HOME/.config/Thunar"
BACKUP="$THUNAR_CONFIG_DIR/uca.xml.vibetoolkit.bak"

mkdir -p "$THUNAR_CONFIG_DIR"

if [[ ! -f "$ACTIONS_DIR" ]]; then
  cat > "$ACTIONS_DIR" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<actions>
</actions>
XML
fi

if grep -q 'vibetoolkit-linux' "$ACTIONS_DIR"; then
  echo "As ações do VibeToolkit já estão instaladas no Thunar."
  exit 0
fi

cp "$ACTIONS_DIR" "$BACKUP"
python3 - "$ACTIONS_DIR" "$REPO_ROOT" <<'PY'
import sys
import xml.etree.ElementTree as ET

path, repo_root = sys.argv[1:]
tree = ET.parse(path)
root = tree.getroot()

def add(name, command, patterns='*', folders=True, files=True):
    action = ET.SubElement(root, 'action', {'name': name, 'visibility': 'both', 'stock-label': name})
    ET.SubElement(action, 'icon').text = 'utilities-terminal'
    ET.SubElement(action, 'command').text = command
    ET.SubElement(action, 'patterns').text = patterns
    ET.SubElement(action, 'startup-notify').text = 'true'
    ET.SubElement(action, 'directories').text = 'true' if folders else 'false'
    ET.SubElement(action, 'audio-files').text = 'false'
    ET.SubElement(action, 'image-files').text = 'false'
    ET.SubElement(action, 'other-files').text = 'true' if files else 'false'
    ET.SubElement(action, 'text-files').text = 'false'
    ET.SubElement(action, 'video-files').text = 'false'

cmd = f'''bash -lc '"{repo_root}/linux/bin/vibe-toolkit" --path "%f" --BundleMode full --RouteMode director' '''.strip()
add('VibeToolkit · Full + Director', cmd)

cmd2 = f'''bash -lc '"{repo_root}/linux/bin/vibe-toolkit" --path "%f" --BundleMode blueprint --RouteMode executor --NonInteractive' '''.strip()
add('VibeToolkit · Blueprint + Executor', cmd2)

tree.write(path, encoding='UTF-8', xml_declaration=True)
PY

echo "Ações do VibeToolkit adicionadas ao Thunar."
echo "Faça logout/login ou reinicie o Thunar se elas não aparecerem imediatamente."
