-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
	"tpope/vim-dadbod",
	"kristijanhusak/vim-dadbod-completion",
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			"tpope/vim-dadbod",
			"kristijanhusak/vim-dadbod-completion",
		},
		cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
		keys = {
			{ "<leader>db", "<cmd>DBUIToggle<cr>", desc = "Toggle DB UI" },
		},
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "sql", "mysql", "plsql", "pgsql", "psql", "postgres" },
				callback = function(event)
					vim.bo.omnifunc = "vim_dadbod_completion#omni"
					vim.keymap.set("i", "<C-Space>", "<C-x><C-o>", {
						buffer = event.buf,
						silent = true,
						desc = "Dadbod omni completion",
					})
				end,
			})
		end,
	},
}
