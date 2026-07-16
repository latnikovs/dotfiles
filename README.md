# dotfiles

Personal dotfiles for a macOS/Linux development environment.

## What is managed

- IntelliJ IdeaVim: `~/.ideavimrc`
- Neovim: `~/.config/nvim`
- kitty: `~/.config/kitty`
- tmux: `~/.tmux.conf`, status bar modules in `~/.tmux/scripts`
- Yazi: `~/.config/yazi`

## Installation

```bash
./bootstrap/install.sh
```

The installer creates these symlinks:

- `~/.ideavimrc` -> `editors/intellij/ideavimrc`
- `~/.config/nvim` -> `editors/nvim`
- `~/.config/kitty` -> `terminal/kitty`
- `~/.tmux.conf` -> `terminal/tmux/tmux.conf`
- `~/.tmux/scripts` -> `terminal/tmux/scripts`
- `~/.config/yazi` -> `terminal/yazi`
- macOS only: `~/.aerospace.toml` -> `aerospace/aerospace.toml`,
  `~/.config/karabiner/karabiner.json` -> `karabiner/karabiner.json`

If a target already exists and is not a symlink, it is moved to a `.bak` file before linking.

## kitty

Config lives in `terminal/kitty`, symlinked to `~/.config/kitty`.

Colors follow the macOS appearance automatically via kitty's
`light-theme.auto.conf` / `dark-theme.auto.conf` mechanism (kitty 0.38+):
Catppuccin Latte when light, Catppuccin Macchiato when dark.

Both files are generated from the palettes in `terminal/kitty/palettes` — do not
hand-edit them. To regenerate:

```bash
python3 terminal/kitty/generate-themes.py
```

The generator derives the tab bar rather than hardcoding it, picking both
`active_tab_foreground` and `inactive_tab_foreground` by WCAG contrast: the
palette's dim slot is unreadable on dark themes, and the accent is dark in Latte
but light in Macchiato, so no single fixed choice works for both.

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

## tmux status bar

The bar is transparent and each module is a rounded pill floating on the
terminal background: session on the left, window list centred, then git, CPU,
memory, battery, network and clock on the right.

### Colors follow the OS appearance

Catppuccin Latte when macOS is light, Macchiato when dark — the same pair kitty
uses, so the bar can never end up light on a dark terminal.
`scripts/flavor.sh` resolves the flavor at config load, and
`scripts/theme-watch.sh` reloads the config when the appearance changes, since
tmux has no appearance hook of its own. Pin it with `TMUX_FLAVOR=latte` or
`TMUX_FLAVOR=macchiato` in the environment.

Reloading goes through `scripts/reload.sh`, including `Prefix + r`, and that
detour is load-bearing. The plugin publishes its palette with `set -ogq`, where
`-o` means "leave an existing option alone" — so `@thm_*` is effectively frozen
once set, and a plain `source-file` silently keeps the old flavor's colors no
matter how often it runs. `reload.sh` unsets `@thm_*` first so the plugin can
repopulate it. Change the reload to a bare `source-file` and the theme will
appear to work on a fresh server and never switch on a running one.

The `@thm_*` palette comes from the `catppuccin/tmux` plugin; nothing hardcodes
a hex value except the fallbacks in the module scripts.

### Modules

Each module in `terminal/tmux/scripts` is a standalone script printing one pill,
and prints nothing when it has nothing to say — the git pill disappears outside
a work tree, the battery pill on a machine with no battery.

| Script | Shows |
| --- | --- |
| `git.sh` | branch, `✚` staged, `●` modified, `…` untracked, conflicts, `⇡⇣` vs upstream |
| `sys.sh` | CPU and memory load (one job, two pills) |
| `battery.sh` | charge and charging state |
| `online.sh` | network reachability, probe cached for 30s |
| `flavor.sh` | the Catppuccin flavor matching the OS appearance |
| `theme-watch.sh` | reloads the config when that appearance changes |
| `icons.sh` | publishes the glyphs to tmux as `@cap_*` / `@ico_*` options |
| `lib.sh` | the `pill` helper and the glyph constants |

tmux parses `#[...]` style sequences out of a `#()` job's output but does not
re-expand `#{...}` there, so each script receives its colors as arguments and
prints its own styling. See `scripts/lib.sh`.

To add a module: write a script that prints a pill, then append a `#(...)` entry
to `status-right` in `tmux.conf`, passing the `#{@thm_*}` colors it needs.

### Nerd Font glyphs are never pasted in literally

Every glyph is written as a `\u` escape in `lib.sh` / `icons.sh` and reaches
`tmux.conf` as a `#{@cap_*}` or `#{@ico_*}` option. Pasting private-use
codepoints straight into these files is the obvious approach and a trap: they
are invisible in editors and diffs, they carry no meaning without the patched
font, and any tool that rewrites the file can silently drop them — which leaves
a bar full of blank gaps that looks like a font problem but is not. The escapes
name the exact codepoint and cannot be mangled.

If an icon renders as a blank or a tofu box, check whether the glyph is actually
reaching the screen before blaming the font — `capture-pane` shows what tmux
drew:

```bash
tmux capture-pane -p | head -1 | python3 -c \
  'import sys; print([hex(ord(c)) for c in sys.stdin.read() if ord(c) > 0x2500])'
```

An empty list means the glyph was lost on the way in (check `lib.sh` /
`icons.sh`); a codepoint listed but not drawn means the font lacks it.

## tmux plugins (TPM, Resurrect, Continuum)

The tmux config includes:

- `tmux-plugins/tpm`
- `tmux-plugins/tmux-resurrect`
- `tmux-plugins/tmux-continuum`
- `catppuccin/tmux` (palette only; the status bar is defined in `tmux.conf`)
- `omerxx/tmux-sessionx`

Install TPM once:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then start tmux and install plugins:

- Reload config: `Prefix + r`
- Install plugins from `.tmux.conf`: `Prefix + I`
- Session switcher (sessionx): `Prefix + o`

Useful keys for session persistence:

- Save session manually: `Prefix + Ctrl-s`
- Restore session manually: `Prefix + Ctrl-r`

`tmux-continuum` is set to auto-save every 15 minutes (its default) and
auto-restore on tmux start. It hooks itself onto `status-right`, which is why
the `run '~/.tmux/plugins/tpm/tpm'` line has to stay last in `tmux.conf`.

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
