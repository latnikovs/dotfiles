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
  # git-delta: installs the 'delta' binary; wired into git via configure_delta.
  # direnv, fzf, zsh-autosuggestions: used by ~/.zshrc (not yet tracked here), so
  # a fresh machine has them available once the shell config lands.
  # fzf-tab: fzf-driven completion menu; bat/eza render its file/dir previews.
  # colima: the container runtime VM. Provides no CLI of its own, so docker and
  # its plugins come from Homebrew too; docker-credential-helper supplies
  # docker-credential-osxkeychain, without which every registry pull fails.
  # Plugin dirs are wired up by configure_docker_plugins.
  local packages=(neovim ripgrep fd node tmux tree-sitter-cli gopass yazi lazygit btop zoxide git-delta direnv fzf zsh-autosuggestions fzf-tab bat eza colima docker docker-compose docker-buildx docker-credential-helper)
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

# Wire delta into git's global config. This writes ~/.gitconfig (a machine-owned
# file this repo does not track), so it is imperative rather than symlinked.
# The pager is the delta.sh wrapper (symlinked below) rather than delta itself,
# so diffs follow the OS appearance (Latte/Macchiato) the way kitty and btop do;
# delta's own auto-detection fails whenever its output is a pipe. $HOME is quoted
# so git's shell expands it at run time instead of this script baking in a path.
configure_delta() {
  if ! has_cmd git; then
    echo "Skipping delta git config: 'git' is not installed"
    return
  fi

  if ! has_cmd delta; then
    echo "Skipping delta git config: 'delta' is not installed"
    return
  fi

  echo "Configuring git to use delta"
  # Store the literal $HOME so git's shell expands it when it runs the pager,
  # keeping the value portable instead of baking in this machine's home path.
  # shellcheck disable=SC2016
  git config --global core.pager '$HOME/.config/delta/delta.sh'
  # shellcheck disable=SC2016
  git config --global interactive.diffFilter '$HOME/.config/delta/delta.sh --color-only'
  git config --global delta.navigate true
  git config --global merge.conflictStyle zdiff3
  git config --global diff.colorMoved default
}

# Homebrew installs docker-compose and docker-buildx as CLI plugins under its own
# prefix, which the docker CLI does not search by default -- `docker compose`
# fails with "unknown command" until config.json points at it. Merge the path in
# rather than overwriting: the same file holds credential helpers and contexts.
configure_docker_plugins() {
  if ! has_cmd docker; then
    echo "Skipping docker plugin config: 'docker' is not installed"
    return
  fi

  if ! has_cmd python3; then
    echo "Skipping docker plugin config: 'python3' is not installed"
    return
  fi

  local plugin_dir
  plugin_dir="$(brew --prefix)/lib/docker/cli-plugins"

  if [ ! -d "$plugin_dir" ]; then
    echo "Skipping docker plugin config: $plugin_dir does not exist"
    return
  fi

  PLUGIN_DIR="$plugin_dir" python3 - <<'PYEOF'
import json, os, pathlib

path = pathlib.Path.home() / ".docker" / "config.json"
path.parent.mkdir(parents=True, exist_ok=True)

try:
    config = json.loads(path.read_text())
except (FileNotFoundError, ValueError):
    config = {}

plugin_dir = os.environ["PLUGIN_DIR"]
dirs = config.setdefault("cliPluginsExtraDirs", [])

if plugin_dir in dirs:
    print(f"Docker plugin dir already configured: {plugin_dir}")
else:
    dirs.append(plugin_dir)
    path.write_text(json.dumps(config, indent=2) + "\n")
    print(f"Docker plugin dir added: {plugin_dir}")
PYEOF
}

# Point git at the repo's tracked hooks (the pre-commit lint gate) via
# core.hooksPath, so the hook lives in the repo instead of an untracked
# .git/hooks copy. Local config only — it must not leak into other repos.
configure_git_hooks() {
  if ! has_cmd git; then
    echo "Skipping git hooks: 'git' is not installed"
    return
  fi

  if ! git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Skipping git hooks: $ROOT_DIR is not a git checkout"
    return
  fi

  git -C "$ROOT_DIR" config --local core.hooksPath "$ROOT_DIR/hooks"
  echo "Git hooks enabled: core.hooksPath -> $ROOT_DIR/hooks"
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

# Copy once and never touch again, for configs the app itself rewrites. A
# symlink into the repo would mean the app dirties the working tree just by
# being used, so these get seeded and then belong to the machine.
seed_dotfile() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [ ! -e "$src" ]; then
    echo "Error: $label template not found at $src"
    exit 1
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "$label already present, leaving it alone: $dest"
    return
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "Seeded $label:"
  echo "  $dest (from $src)"
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
# The shared zshrc sources ~/.zshrc.local at the end for per-machine tweaks
# (work paths, secrets, tool-managed blocks). That file is intentionally not
# tracked here and is left untouched on machines that already have one.
link_dotfile "$ROOT_DIR/shell/zshrc" "$HOME/.zshrc" "zshrc"
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
  # Karabiner-Elements rewrites its config on launch: it reads the file, expands
  # it (device settings, defaults) and writes back a regular file, replacing any
  # symlink. Linking would therefore be undone every run — each bootstrap would
  # find a real file, back it up (.bak.N pile-up) and reset Karabiner to this
  # minimal seed. So the repo file is a one-time seed and the live config, once
  # Karabiner owns it, is left alone. Same rationale as btop.conf below.
  seed_dotfile "$ROOT_DIR/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json" "karabiner config"
  # lazygit stores its config under Application Support on macOS, not ~/.config.
  link_dotfile "$ROOT_DIR/terminal/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml" "lazygit config"
fi
link_dotfile "$ROOT_DIR/terminal/tmux/tmux.conf" "$HOME/.tmux.conf" "tmux.conf"
# The status bar calls these by absolute path, so they need a stable home that
# does not depend on where this repo is checked out.
link_dotfile "$ROOT_DIR/terminal/tmux/scripts" "$HOME/.tmux/scripts" "tmux status scripts"
link_dotfile "$ROOT_DIR/terminal/yazi" "$HOME/.config/yazi" "yazi"
link_dotfile "$ROOT_DIR/terminal/kitty" "$HOME/.config/kitty" "kitty"
# The delta wrapper is referenced by git's core.pager and lazygit by absolute
# path, so it needs a stable home independent of where this repo is checked out.
link_dotfile "$ROOT_DIR/terminal/delta/delta.sh" "$HOME/.config/delta/delta.sh" "delta wrapper"

# btop persists its own settings: change a box or a sort in the TUI and it
# rewrites btop.conf on exit. So the live config is seeded rather than linked —
# linking it would mean merely using btop leaves the repo dirty. Only the pieces
# btop never writes to are symlinked. Edit btop.conf.default to change what a
# fresh machine starts with; an existing btop.conf is deliberately never
# overwritten.
seed_dotfile "$ROOT_DIR/terminal/btop/btop.conf.default" "$HOME/.config/btop/btop.conf" "btop config"
link_dotfile "$ROOT_DIR/terminal/btop/themes-latte" "$HOME/.config/btop/themes-latte" "btop latte theme"
link_dotfile "$ROOT_DIR/terminal/btop/themes-macchiato" "$HOME/.config/btop/themes-macchiato" "btop macchiato theme"
link_dotfile "$ROOT_DIR/terminal/btop/launch.sh" "$HOME/.config/btop/launch.sh" "btop launcher"

install_macos_deps
install_tpm
configure_delta
configure_docker_plugins
configure_git_hooks
install_yazi_flavors

if has_cmd nvim; then
  echo "Bootstrapping Neovim plugins..."
  # LazyVim owns its own tool lists: LSP servers, formatters and treesitter
  # parsers come from the ensure_installed entries of the extras enabled in
  # editors/nvim/lazyvim.json, not from an explicit list here. A plugin sync
  # is all the bootstrap needs; Mason finishes installing on first launch.
  nvim --headless "+Lazy! sync" "+qa"
else
  echo "Skipping Neovim bootstrap: 'nvim' is not installed"
fi

echo ""
echo ""
echo "⚠ If icons look wrong, install and select 'JetBrainsMono Nerd Font Mono' in your terminal."
