-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Yank the current file's absolute path with the cursor's line number, in the
-- path:line form that jumps straight to the spot when pasted into a terminal,
-- an issue, or a chat. Carried over from the kickstart config.
vim.keymap.set("n", "<leader>yp", function()
  local location = vim.fn.expand("%:p") .. ":" .. vim.fn.line(".")
  vim.fn.setreg("+", location)
  vim.notify("Copied " .. location)
end, { desc = "[Y]ank full [P]ath:line" })

-- Buffer shortcuts carried over from the kickstart config.
vim.keymap.set("n", "<leader>bn", "<cmd>enew<cr>", { desc = "[B]uffer [N]ew" })
vim.keymap.set("n", "<leader>bR", "<cmd>e!<cr>", { desc = "[B]uffer [R]eload" })
