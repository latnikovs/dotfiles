# dotfiles

Personal macOS development environment — Neovim, kitty, tmux, yazi, aerospace,
lazygit and delta, themed with Catppuccin that follows the system light/dark
appearance. Linux is partially supported: the shell, editors and terminal
configs work, but the Homebrew casks and a few paths are macOS-only.

## Design principles

- **One appearance, everywhere.** kitty, tmux, btop, delta and yazi all resolve
  light vs. dark from a single source of truth — the macOS appearance, read by
  `terminal/tmux/scripts/flavor.sh`. Catppuccin Latte in light mode, Macchiato
  in dark, in lockstep. Nothing themes itself independently.
- **Link vs. seed.** Configs an app never rewrites are **symlinked**, so edits
  flow both ways. Configs an app rewrites itself — `btop.conf`,
  `karabiner.json` — are **seeded** once and then left alone, so merely using
  the app never dirties the repo.
- **Machine-local escape hatch.** The shared `~/.zshrc` sources an untracked
  `~/.zshrc.local` for per-host paths, tooling and secrets. Nothing
  machine-specific is committed.
- **Idempotent bootstrap.** `install.sh` is safe to re-run: it skips work
  already done and backs up any real file it is about to replace to `*.bak`.

## Quick start

```bash
git clone <this-repo> ~/dotfiles
~/dotfiles/bootstrap/install.sh
```

Prerequisites: macOS with [Homebrew](https://brew.sh) and git. The bootstrap
installs everything else — packages, casks, the Nerd Font, and tmux/Neovim
plugins. Re-run it any time; it is idempotent.

## What's managed

| Tool | Source | Target | Method |
| --- | --- | --- | --- |
| Neovim | `editors/nvim` | `~/.config/nvim` | link |
| IdeaVim | `editors/intellij/ideavimrc` | `~/.ideavimrc` | link |
| Zsh | `shell/zshrc` | `~/.zshrc` | link (+ `~/.zshrc.local`) |
| kitty | `terminal/kitty` | `~/.config/kitty` | link |
| tmux | `terminal/tmux/tmux.conf`, `…/scripts` | `~/.tmux.conf`, `~/.tmux/scripts` | link |
| yazi | `terminal/yazi` | `~/.config/yazi` | link |
| btop | `terminal/btop` | `~/.config/btop` | seed config, link themes + launcher |
| delta | `terminal/delta/delta.sh` | `~/.config/delta/delta.sh` | link |
| lazygit | `terminal/lazygit/config.yml` | `~/Library/Application Support/lazygit/config.yml` | link (macOS) |
| aerospace | `aerospace/aerospace.toml` | `~/.aerospace.toml` | link (macOS) |
| karabiner | `karabiner/karabiner.json` | `~/.config/karabiner/karabiner.json` | seed (macOS) |

Git config is not symlinked — the bootstrap sets delta-related keys directly in
`~/.gitconfig` (see [git + delta](#git--delta)). If a link target already exists
and is not the expected symlink, it is moved to `*.bak` first.

## Packages

`install.sh` installs, via Homebrew:

- **Formulae:** `neovim`, `ripgrep`, `fd`, `node`, `tmux`, `tree-sitter-cli`,
  `gopass`, `yazi`, `lazygit`, `btop`, `zoxide`, `git-delta`, `direnv`, `fzf`,
  `zsh-autosuggestions`
- **Casks:** `font-jetbrains-mono-nerd-font`, `kitty`, `aerospace`,
  `karabiner-elements`

## git + delta

delta is the pager for both CLI git and lazygit. delta only auto-detects
light/dark when writing to a TTY, and fails in a pipe (notably lazygit's diff
pane), so a small wrapper — `terminal/delta/delta.sh` — forces `--light` /
`--dark` from the same `flavor.sh` probe kitty and btop use. The bootstrap
points `core.pager`, `interactive.diffFilter` and lazygit's pager at that
wrapper, and sets `navigate`, `zdiff3` conflicts and `colorMoved`.

## Shell

`~/.zshrc` is shared and tracked. Anything that differs per machine — work
paths, tool-managed blocks (SDKMAN, rustup), secrets — goes in
`~/.zshrc.local`, which is sourced at the end (before zoxide, so its PATH
additions are part of the final PATH) and never tracked. Homebrew paths resolve
through a detected `$BREW_PREFIX`, so the file works on both Apple Silicon and
Intel.

> **Caveat:** `~/.zshrc` is a symlink into this repo, so an installer that
> appends to `~/.zshrc` (SDKMAN, rustup, asdf…) writes *through* it
> and dirties the repo. When that happens, move the injected block into
> `~/.zshrc.local` and `git checkout shell/zshrc`.

## Development

`install.sh` enables a git `pre-commit` hook via `core.hooksPath` → `hooks/`.
It lints **staged** shell scripts before they can be committed — `shellcheck` +
`bash -n` for POSIX/bash, `zsh -n` for `shell/zshrc` — and blocks the commit on
failure. Only staged files are checked, so unrelated pre-existing findings never
block you. Bypass with `git commit --no-verify` when you must.

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

## tmux plugins (TPM)

The tmux config includes:

- `tmux-plugins/tpm`
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

There is no session persistence across reboots — sessions are recreated on
demand with the `td` shell function (see `shell/zshrc`), which attaches to a
session named after the current directory, creating it rooted there if needed.

## Neovim setup

The config is [LazyVim](https://lazyvim.org) — the starter, plus the extras
listed in `editors/nvim/lazyvim.json` (Angular, Go, Java, JSON, Markdown,
Tailwind, Terraform, TypeScript, and neo-tree) and a small amount of local
config under `editors/nvim/lua/`.

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

The bootstrap installs the Homebrew-provided ones and syncs plugins
automatically; the steps below are the manual equivalent.

### Bootstrap plugins

```bash
brew install neovim ripgrep fd node && \
nvim --headless "+Lazy! sync" "+qa"
```

LSP servers, formatters and treesitter parsers are not listed here — LazyVim
installs them from the `ensure_installed` entries of the enabled extras, and
Mason finishes any remaining downloads on first launch.

Then, in a normal `nvim` session:

- `:Lazy` — plugin status
- `:Mason` — tool status
- `:checkhealth`

### Local additions

`lua/config/` holds the deviations from the stock starter:

- `remote_clipboard.lua` — OSC 52 yank, so `y` reaches the local clipboard
  from an SSH or tmux session.
- `keymaps.lua` — `<leader>yp` yanks the current `path:line`.

`lua/plugins/example.lua` is the starter's commented reference file, kept as a
cookbook for adding plugin specs.
