# Neovim Bootstrap (macOS)

Restore this exact Neovim setup on a fresh macOS machine (config already at `~/.config/nvim`).

Required software:

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

Optional manual flow (no headless bootstrap):

```bash
nvim
```

Then run `:Mason` and `:checkhealth` inside Neovim.
