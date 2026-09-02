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
terminal background: session on the left, window list centred, then git, docker,
CPU, memory, battery, network and clock on the right.

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
| `docker.sh` | the container engine, and how many containers are running |
| `sys.sh` | CPU and memory load (one job, two pills) |
| `battery.sh` | charge and charging state |
| `online.sh` | network reachability, probe cached for 30s |
| `flavor.sh` | the Catppuccin flavor matching the OS appearance |
| `theme-watch.sh` | reloads the config when that appearance changes |
| `icons.sh` | publishes the glyphs to tmux as `@cap_*` / `@ico_*` options |
| `claude-state.sh` | Claude Code's turn state, as a pane option the window chips read |
| `lib.sh` | the `pill` helper and the glyph constants |

tmux parses `#[...]` style sequences out of a `#()` job's output but does not
re-expand `#{...}` there, so each script receives its colors as arguments and
prints its own styling. See `scripts/lib.sh`.

To add a module: write a script that prints a pill, then append a `#(...)` entry
to `status-right` in `tmux.conf`, passing the `#{@thm_*}` colors it needs.

The docker pill is worth a note, because "prints nothing when it has nothing to
say" is doing real work there: a laptop's container VM is usually stopped, and a
pill that is always present tells you nothing. Its appearing *is* the signal,
and the number beside the whale is how many containers are running. A socket
that exists but does not answer, with a lima process alive, shows `...` while
the VM boots.

It reads the count from the Docker API over the unix socket rather than from
`docker ps`: the CLI costs ~65ms of Go startup against curl's ~12ms, inside a
job that runs every interval — and, more to the point, `curl --max-time` bounds
it. A half-booted VM answers its socket and then hangs, and `docker ps` has no
timeout flag to keep that from freezing the whole right-hand side of the bar.

### Claude Code activity dot

Windows running Claude Code carry a coloured dot after their name, so the bar
answers "which agent needs me?" without cycling through windows:

| Dot | Meaning |
| --- | --- |
| `○` peach | a turn is running |
| `◉` red | Claude is waiting on you (permission prompt, idle nag) |
| `●` green | the turn finished |

`scripts/claude-state.sh` is the whole mechanism. Claude Code's hooks call it on
every relevant event and it writes the state as a *pane* option
(`@claude_state`) on the pane the hook ran in; `@claude_dot` in `tmux.conf`
reads that option straight out of the format tree, since tmux resolves
`#{@...}` in `window-status-format` against the window's active pane. No `#()`
job, no polling, no state files to reap — the option dies with the pane, and the
script ends with `refresh-client -S` so the dot updates the moment a turn ends
rather than at the next 5s tick.

The dot is gated on the pane also *looking* like Claude, so a state left behind
by a crash disappears as soon as the pane runs something else.

The same state feeds the **agents pill** in `status-left`, which answers the
question the dot cannot: what are the agents in the tabs you are *not* looking
at doing? Every kitty tab is its own client on its own session, but they all
share one tmux server, so `#{S:...}` / `#{W:...}` — tmux's session and window
loops — let one status line walk the whole server and name each session that
holds agents, followed by one dot per agent in it: `󰚩 wms ◉ ●  ui ◉`. Still a
plain format, so still no job and no polling. Each client drops its own session from the list via
`#{client_session}`, since that agent is already on the window chip beside it.

Two things follow from how tmux parses formats, and both cost an evening if
rediscovered the hard way. Styles inside a conditional must be
single-attribute — `#[fg=x]#[bg=y]`, never `#[fg=x,bg=y]` — because the parser
splits the conditional's branches on that comma and draws half a pill. And the
"nothing to say, draw nothing" rule needs `#{E:...}` to expand the list before
comparing it to the empty string.

Hooks live in `~/.claude/settings.json`, which this repo does not track (it
holds machine-local permissions and plugin state). Wire them up per machine:

```jsonc
// one entry per event, matcher "*", alongside anything already there
"UserPromptSubmit" | "PreToolUse" | "PostToolUse" → claude-state.sh busy
"Notification"                                    → claude-state.sh wait
"Stop" | "SessionStart"                           → claude-state.sh idle
"SessionEnd"                                      → claude-state.sh clear
```

with each command spelled `bash ~/.tmux/scripts/claude-state.sh <state>`.

### Nerd Font glyphs are never pasted in literally

Every glyph is written as a `\u` escape in `lib.sh` / `icons.sh` and reaches
`tmux.conf` as a `#{@cap_*}` or `#{@ico_*}` option. Pasting private-use
codepoints straight into these files is the obvious approach and a trap: they
are invisible in editors and diffs, they carry no meaning without the patched
font, and any tool that rewrites the file can silently drop them — which leaves
a bar full of blank gaps that looks like a font problem but is not. The escapes
name the exact codepoint and cannot be mangled.

### What a codepoint actually draws

A codepoint in `icons.sh` says which glyph is meant but not what it looks like,
and a wrong one renders as a perfectly good picture of the wrong thing. The
patched font answers this itself: it keeps the upstream icon names in its `post`
table, so `\U000f085e` can be looked up and comes back `md-clipboard_pulse_outline`
— which is what every Neovim window in this bar showed until it was caught.
Vim and Neovim are not in Material Design at all; their glyphs come from the
Devicons/custom ranges (`\ue6ae` is `custom-neovim`).

So when adding an icon, verify the name rather than trusting a cheat sheet:
parse `~/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf`'s `cmap` and `post`
tables, or run `ttx -t post` if `fonttools` is available. Every other icon in
this repo has been checked against those names.

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
