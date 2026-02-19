# dotfiles

Personal dotfiles for a macOS/Linux development environment.

## What is managed

- IntelliJ IdeaVim: `~/.ideavimrc`
- Neovim: `~/.config/nvim`
- tmux: `~/.tmux.conf`

## Installation

```bash
./bootstrap/install.sh
```

The installer creates these symlinks:

- `~/.ideavimrc` -> `editors/intellij/ideavimrc`
- `~/.config/nvim` -> `editors/nvim`
- `~/.tmux.conf` -> `terminal/tmux/tmux.conf`

If a target already exists and is not a symlink, it is moved to a `.bak` file before linking.

## tmux plugins (TPM, Resurrect, Continuum)

The tmux config includes:

- `tmux-plugins/tpm`
- `tmux-plugins/tmux-resurrect`
- `tmux-plugins/tmux-continuum`

Install TPM once:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then start tmux and install plugins:

- Reload config: `Prefix + r`
- Install plugins from `.tmux.conf`: `Prefix + I`

Useful keys for session persistence:

- Save session manually: `Prefix + Ctrl-s`
- Restore session manually: `Prefix + Ctrl-r`

`tmux-continuum` is set to auto-save every 5 minutes and auto-restore on tmux start.

## Neovim setup

### Prerequisites

- `git`
- `neovim`
- `ripgrep`
- `fd`
- `node` (for npm-based LSP/formatter tools)
- `go`
- `python3`
- `java` (JDK 21+)
- C build toolchain (`xcode-select --install` on macOS)

### Bootstrap plugins and tools

```bash
brew install neovim ripgrep fd node && \
nvim --headless "+Lazy! sync" "+qa" && \
nvim --headless "+Lazy load nvim-lspconfig nvim-treesitter.nvim" "+MasonToolsInstallSync" "+TSUpdateSync" "+qa"
```

Optional manual flow:

```bash
nvim
```

Then run:

- `:Mason`
- `:checkhealth`
