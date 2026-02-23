#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

link_dotfile() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [ ! -e "$src" ]; then
    echo "Error: $label not found at $src"
    exit 1
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "Backing up existing $dest to $dest.bak"
    mv "$dest" "$dest.bak"
  fi

  if [ -L "$dest" ]; then
    echo "$dest already linked"
    return
  fi

  ln -s "$src" "$dest"
  echo "Symlink created:"
  echo "  $dest -> $src"
}

link_dotfile "$ROOT_DIR/editors/intellij/ideavimrc" "$HOME/.ideavimrc" "ideavimrc"
link_dotfile "$ROOT_DIR/editors/nvim" "$HOME/.config/nvim" "nvim"
link_dotfile "$ROOT_DIR/terminal/tmux/tmux.conf" "$HOME/.tmux.conf" "tmux.conf"

if has_cmd nvim; then
  echo "Bootstrapping Neovim plugins and Mason tools..."
  nvim --headless "+Lazy! sync" "+qa"
  nvim --headless "+Lazy load mason-tool-installer.nvim" "+MasonToolsInstallSync" "+qa"
else
  echo "Skipping Neovim bootstrap: 'nvim' is not installed"
fi

echo "If icons look wrong, install and select 'JetBrainsMono Nerd Font Mono' in your terminal."
