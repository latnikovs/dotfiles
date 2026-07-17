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

  # lazygit: tmux.conf binds it to prefix+g as a popup.
  local packages=(neovim ripgrep fd node tmux tree-sitter-cli gopass yazi lazygit)
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

  if ! brew list --cask kitty >/dev/null 2>&1; then
    echo "Installing kitty cask: kitty"
    brew install --cask kitty
  else
    echo "kitty already installed: kitty"
  fi

  if ! brew list --cask nikitabobko/tap/aerospace >/dev/null 2>&1; then
    echo "Installing Aerospace cask: nikitabobko/tap/aerospace"
    brew install --cask nikitabobko/tap/aerospace
  else
    echo "Aerospace already installed: nikitabobko/tap/aerospace"
  fi

  if ! brew list --cask karabiner-elements >/dev/null 2>&1; then
    echo "Installing Karabiner-Elements cask: karabiner-elements"
    brew install --cask karabiner-elements
  else
    echo "Karabiner-Elements already installed: karabiner-elements"
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

install_yazi_flavors() {
  local flavors=(956MB/vscode-dark-modern 956MB/vscode-light-modern)

  if ! has_cmd ya; then
    echo "Skipping Yazi flavors: 'ya' is not installed"
    return
  fi

  if ! has_cmd git; then
    echo "Skipping Yazi flavors: 'git' is not installed"
    return
  fi

  local installed
  installed="$(ya pkg list 2>/dev/null || true)"

  local flavor
  for flavor in "${flavors[@]}"; do
    if printf '%s\n' "$installed" | grep -qF "$flavor"; then
      echo "Yazi flavor already added: $flavor"
    else
      echo "Adding Yazi flavor: $flavor"
      ya pkg add "$flavor"
    fi
  done

  # Restores anything recorded in package.toml but missing on disk,
  # e.g. on a fresh machine where only package.toml was checked out.
  ya pkg install

  # 'ya pkg add/install' reports success even when a package does not exist,
  # deploying nothing; verify the flavors theme.toml references really landed.
  local missing=()
  for flavor in "${flavors[@]}"; do
    local dir="$ROOT_DIR/terminal/yazi/flavors/${flavor##*/}.yazi"
    if [ ! -f "$dir/flavor.toml" ]; then
      missing+=("$flavor")
    fi
  done

  if [ "${#missing[@]}" -gt 0 ]; then
    echo "Error: Yazi flavors failed to install: ${missing[*]}"
    echo "Expected flavor.toml under $ROOT_DIR/terminal/yazi/flavors/"
    exit 1
  fi

  echo "Yazi flavors installed: ${flavors[*]}"
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

  if [ -L "$dest" ]; then
    if [ "$(readlink "$dest")" = "$src" ]; then
      echo "$dest already linked"
      return
    fi

    echo "Updating symlink $dest to $src"
    rm "$dest"
  elif [ -e "$dest" ]; then
    local backup="$dest.bak"
    local backup_index=1

    while [ -e "$backup" ] || [ -L "$backup" ]; do
      backup="$dest.bak.$backup_index"
      backup_index=$((backup_index + 1))
    done

    echo "Backing up existing $dest to $backup"
    mv "$dest" "$backup"
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
  link_dotfile "$ROOT_DIR/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json" "karabiner"
fi
link_dotfile "$ROOT_DIR/terminal/tmux/tmux.conf" "$HOME/.tmux.conf" "tmux.conf"
# The status bar calls these by absolute path, so they need a stable home that
# does not depend on where this repo is checked out.
link_dotfile "$ROOT_DIR/terminal/tmux/scripts" "$HOME/.tmux/scripts" "tmux status scripts"
link_dotfile "$ROOT_DIR/terminal/yazi" "$HOME/.config/yazi" "yazi"
link_dotfile "$ROOT_DIR/terminal/kitty" "$HOME/.config/kitty" "kitty"

install_macos_deps
install_tpm
install_yazi_flavors

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
