#!/usr/bin/env bash
# Symlink repo ./starburst into a directory on your PATH (default: ~/.local/bin).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/starburst"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
DEST="$INSTALL_DIR/starburst"

if [[ ! -x "$SRC" ]]; then
  echo "Expected executable at $SRC" >&2
  exit 1
fi

mkdir -p "$INSTALL_DIR"
ln -sf "$SRC" "$DEST"
echo "Installed: $DEST -> $SRC"
echo ""
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "Add this to your shell config (~/.zshrc or ~/.zprofile), then open a new terminal:"
  echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
else
  echo "$INSTALL_DIR is already on PATH. Try: starburst data-product --help"
fi
