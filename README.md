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
