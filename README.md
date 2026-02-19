# dotfiles
Opinionated dotfiles for a macOS/Linux dev setup.

Currently supported:
- IntelliJ IdeaVim (`~/.ideavimrc`)
- Neovim (`~/.config/nvim`)
- tmux (`~/.tmux.conf`)

## Install
```bash
./bootstrap/install.sh
```

The installer creates symlinks for:
- `~/.ideavimrc` -> `editors/intellij/ideavimrc`
- `~/.config/nvim` -> `editors/nvim`
- `~/.tmux.conf` -> `terminal/tmux/tmux.conf`

## Neovim bootstrap (macOS)

After linking `~/.config/nvim`, install required tools:

- `git`
- `neovim`
- `ripgrep`
- `fd`
- `go`
- `node`
- `python3`
- `java` (JDK 21+)

```bash
brew install neovim ripgrep fd && \
nvim --headless "+Lazy! sync" "+qa" && \
nvim --headless "+Lazy load nvim-lspconfig nvim-treesitter.nvim" "+MasonToolsInstallSync" "+TSUpdateSync" "+qa"
```

Optional manual flow:

```bash
nvim
```

Then run `:Mason` and `:checkhealth` inside Neovim.
