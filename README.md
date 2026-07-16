# dotfiles

Personal dotfiles for a macOS/Linux development environment.

## What is managed

- IntelliJ IdeaVim: `~/.ideavimrc`
- Neovim: `~/.config/nvim`
- Ghostty (macOS): `~/Library/Application Support/com.mitchellh.ghostty`
- Ghostty (Linux/XDG): `~/.config/ghostty`
- tmux: `~/.tmux.conf`
- Yazi: `~/.config/yazi`
- kitty: `~/.config/kitty`

## Installation

```bash
./bootstrap/install.sh
```

The installer creates these symlinks:

- `~/.ideavimrc` -> `editors/intellij/ideavimrc`
- `~/.config/nvim` -> `editors/nvim`
- macOS: `~/Library/Application Support/com.mitchellh.ghostty` -> `terminal/ghostty`
- Linux/XDG: `~/.config/ghostty` -> `terminal/ghostty`
- `~/.tmux.conf` -> `terminal/tmux/tmux.conf`
- `~/.config/yazi` -> `terminal/yazi`

If a target already exists and is not a symlink, it is moved to a `.bak` file before linking.

## kitty

Config lives in `terminal/kitty`, symlinked to `~/.config/kitty`.

Colors follow the macOS appearance automatically via kitty's
`light-theme.auto.conf` / `dark-theme.auto.conf` mechanism (kitty 0.38+):
Catppuccin Latte when light, Catppuccin Macchiato when dark — the same pair
Ghostty uses.

Those two files are generated from Ghostty's own theme files so both terminals
render identical colors. To regenerate (e.g. after changing the Ghostty theme):

```bash
G=/Applications/Ghostty.app/Contents/Resources/ghostty/themes
python3 terminal/kitty/generate-themes.py "$G/Catppuccin Latte" \
  "Catppuccin Latte" terminal/kitty/light-theme.auto.conf
python3 terminal/kitty/generate-themes.py "$G/Catppuccin Macchiato" \
  "Catppuccin Macchiato" terminal/kitty/dark-theme.auto.conf
```

The generator also picks `inactive_tab_foreground` by WCAG contrast against the
background, since the palette's dim slot is unreadable on dark themes.

## Yazi

Config lives in `terminal/yazi` (`yazi.toml`, `theme.toml`).

Flavors are managed as Yazi packages and recorded in `terminal/yazi/package.toml`,
which is committed; the downloaded package files under `terminal/yazi/flavors/`
are gitignored and restored by the installer via `ya pkg install`.

The active flavors follow the terminal's dark/light mode:

- dark: `vscode-dark-modern` (`956MB/vscode-dark-modern`)
- light: `vscode-light-modern` (`956MB/vscode-light-modern`)

To add another flavor, run `ya pkg add <owner>/<repo>`, add it to the `flavors`
list in `bootstrap/install.sh`, reference it in `terminal/yazi/theme.toml`, and
commit the updated `package.toml`.

## Nerd Font (required)

This setup expects a Nerd Font for terminal icons (Neovim and tmux statusline).

Install JetBrainsMono Nerd Font:

macOS:

```bash
brew install --cask font-jetbrains-mono-nerd-font
```

Linux:

```bash
mkdir -p ~/.local/share/fonts/JetBrainsMonoNerdFont && \
curl -fLo /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip && \
unzip -o /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMonoNerdFont && \
fc-cache -fv
```

After install, set your terminal font to `JetBrainsMono Nerd Font Mono`.

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
nvim --headless "+Lazy load mason-tool-installer.nvim" "+MasonToolsInstallSync" "+qa"
```

Optional manual flow:

```bash
nvim
```

Then run:

- `:Mason`
- `:checkhealth`
