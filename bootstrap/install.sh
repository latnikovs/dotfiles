#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

install_macos_deps() {
  if [ "$(uname -s)" != "Darwin" ]; then
    return
  fi

  if ! has_cmd brew; then
    echo "Homebrew not found. Skipping package install."
    echo "Install Homebrew from https://brew.sh, then re-run bootstrap."
    return
  fi

  local packages=(neovim ripgrep fd node tmux tree-sitter-cli)
  local missing=()
  local pkg

  for pkg in "${packages[@]}"; do
    if ! brew list "$pkg" >/dev/null 2>&1; then
      missing+=("$pkg")
    fi
  done

  if [ "${#missing[@]}" -gt 0 ]; then
    echo "Installing missing Homebrew packages: ${missing[*]}"
    brew install "${missing[@]}"
  else
    echo "Homebrew packages already installed: ${packages[*]}"
  fi

  if ! brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
    echo "Installing Nerd Font cask: font-jetbrains-mono-nerd-font"
    brew install --cask font-jetbrains-mono-nerd-font
  else
    echo "Nerd Font already installed: font-jetbrains-mono-nerd-font"
  fi

  if ! brew list --cask ghostty >/dev/null 2>&1; then
    echo "Installing Ghostty cask: ghostty"
    brew install --cask ghostty
  else
    echo "Ghostty already installed: ghostty"
  fi

  if ! brew list --cask nikitabobko/tap/aerospace >/dev/null 2>&1; then
    echo "Installing Aerospace cask: nikitabobko/tap/aerospace"
    brew install --cask nikitabobko/tap/aerospace
  else
    echo "Aerospace already installed: nikitabobko/tap/aerospace"
  fi

  if ! xcode-select -p >/dev/null 2>&1; then
    echo "Xcode Command Line Tools are required for some builds."
    echo "Run: xcode-select --install"
  fi
}

install_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"

  if [ -d "$tpm_dir" ]; then
    echo "TPM already installed: $tpm_dir"
    return
  fi

  if ! has_cmd git; then
    echo "Skipping TPM install: 'git' is not installed"
    return
  fi

  echo "Installing TPM to $tpm_dir"
  git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
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
if [ "$(uname -s)" = "Darwin" ]; then
  aerospace_xdg_config="$HOME/.config/aerospace/aerospace.toml"
  if [ -e "$aerospace_xdg_config" ] || [ -L "$aerospace_xdg_config" ]; then
    if [ -L "$aerospace_xdg_config" ]; then
      echo "Removing duplicate AeroSpace config symlink: $aerospace_xdg_config"
      rm "$aerospace_xdg_config"
      rmdir "$HOME/.config/aerospace" 2>/dev/null || true
    else
      echo "Backing up duplicate AeroSpace config to $aerospace_xdg_config.bak"
      mv "$aerospace_xdg_config" "$aerospace_xdg_config.bak"
    fi
  fi

  link_dotfile "$ROOT_DIR/aerospace/aerospace.toml" "$HOME/.aerospace.toml" "aerospace"
  link_dotfile "$ROOT_DIR/terminal/ghostty" "$HOME/Library/Application Support/com.mitchellh.ghostty" "ghostty (macOS)"
else
  link_dotfile "$ROOT_DIR/terminal/ghostty" "$HOME/.config/ghostty" "ghostty"
fi
link_dotfile "$ROOT_DIR/terminal/tmux/tmux.conf" "$HOME/.tmux.conf" "tmux.conf"

install_macos_deps
install_tpm

if has_cmd nvim; then
  echo "Bootstrapping Neovim plugins and Mason tools..."
  TS_PARSERS=(bash css diff go html java javascript lua luadoc markdown markdown_inline query tsx typescript vim vimdoc)
  nvim --headless "+Lazy! sync" "+qa"
  nvim --headless "+Lazy load mason-tool-installer.nvim" "+MasonToolsInstallSync" "+qa"
  nvim --headless "+Lazy load nvim-treesitter" "+TSInstall ${TS_PARSERS[*]}" "+qa"
else
  echo "Skipping Neovim bootstrap: 'nvim' is not installed"
fi

echo ""
echo ""
echo "⚠ If icons look wrong, install and select 'JetBrainsMono Nerd Font Mono' in your terminal."
