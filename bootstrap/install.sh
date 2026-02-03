#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT_DIR/editors/intellij/ideavimrc"
DEST="$HOME/.ideavimrc"

if [ ! -f "$SRC" ]; then
  echo "Error: ideavimrc not found at $SRC"
  exit 1
fi

if [ -e "$DEST" ] && [ ! -L "$DEST" ]; then
  echo "Backing up existing ~/.ideavimrc to ~/.ideavimrc.bak"
  mv "$DEST" "$DEST.bak"
fi

if [ -L "$DEST" ]; then
  echo "~/.ideavimrc already linked"
  exit 0
fi

ln -s "$SRC" "$DEST"
echo "Symlink created:"
echo "  ~/.ideavimrc → $SRC"
