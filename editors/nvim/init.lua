-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = 2

-- Make line numbers default
vim.o.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.o.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Don't show partial keypresses in the command area
vim.o.showcmd = false

-- Hide command line when idle (it still appears for prompts/messages)
vim.o.cmdheight = 0

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.winborder = "rounded"

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
--
--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-guide-options`
-- vim.o.list = true
-- vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.o.inccommand = "split"

-- Show which line your cursor is on
vim.o.cursorline = true
-- vim.o.guicursor = "n-v-c:block,i-ci-ve:block-CursorInsert,r-cr:hor20,o:hor50"
--
-- local function set_cursor_highlights()
-- 	if vim.o.background == "light" then
-- 		vim.api.nvim_set_hl(0, "CursorInsert", { fg = "#ffffff", bg = "#0b57d0" })
-- 	else
-- 		vim.api.nvim_set_hl(0, "CursorInsert", { fg = "#1e1e2e", bg = "#f9e2af" })
-- 	end
-- end
--
-- set_cursor_highlights()
-- vim.api.nvim_create_autocmd("ColorScheme", {
-- 	callback = set_cursor_highlights,
-- })

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		vim.api.nvim_set_hl(0, "NeoTreeFileName", { link = "NeoTreeNormal" })
	end,
})

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- Prioritize HTML highlighting for Go HTML templates
vim.filetype.add({
	extension = {
		gohtml = "html",
	},
})

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("i", "jj", "<Esc>")
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "[W]rite file" })
vim.keymap.set("n", "<leader>Q", "<cmd>qa<CR>", { desc = "[Q]uit all" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and keep selection" })
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and keep selection" })

local day_theme = "github_light_default"
local night_theme = "catppuccin-macchiato"
local theme_state_file = vim.fn.stdpath("state") .. "/theme.txt"

local function known_theme(theme_name)
	return theme_name == day_theme or theme_name == night_theme
end

local function set_background_for_theme(theme_name)
	vim.o.background = theme_name == day_theme and "light" or "dark"
end

local function persist_theme(theme_name)
	pcall(vim.fn.mkdir, vim.fn.fnamemodify(theme_state_file, ":h"), "p")
	pcall(vim.fn.writefile, { theme_name }, theme_state_file)
end

local function read_persisted_theme()
	local ok, lines = pcall(vim.fn.readfile, theme_state_file)
	if not ok or not lines or #lines == 0 then
		return day_theme
	end

	local saved = vim.trim(lines[1])
	if known_theme(saved) then
		return saved
	end

	return day_theme
end

local function apply_theme(theme_name)
	if not known_theme(theme_name) then
		return false
	end

	set_background_for_theme(theme_name)
	local ok = pcall(vim.cmd.colorscheme, theme_name)
	if not ok then
		vim.notify("Failed to apply theme: " .. theme_name, vim.log.levels.WARN)
		return false
	end

	return true
end

local function set_theme(theme_name)
	if apply_theme(theme_name) then
		persist_theme(theme_name)
	end
end

local function toggle_theme()
	local current = vim.g.colors_name
	if current == "catppuccin" then
		current = night_theme
	end

	local next_theme = current == day_theme and night_theme or day_theme
	set_theme(next_theme)
end

vim.keymap.set("n", "<leader>tt", toggle_theme, { desc = "[T]oggle [T]heme" })
vim.keymap.set("n", "<leader>yp", function()
	local location = vim.fn.expand("%:p") .. ":" .. vim.fn.line(".")
	vim.fn.setreg("+", location)
	vim.notify("Copied path:line")
end, { desc = "[Y]ank full [P]ath:line" })

-- Diagnostic Config & Keymaps
-- See :help vim.diagnostic.Opts
vim.diagnostic.config({
	update_in_insert = false,
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
	underline = { severity = vim.diagnostic.severity.ERROR },

	-- Can switch between these as you prefer
	virtual_text = true, -- Text shows up at the end of the line
	virtual_lines = false, -- Teest shows up underneath the line, with virtual lines

	-- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
	jump = { float = true },
})

vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q] location list" })
vim.keymap.set("n", "<leader>ls", vim.lsp.buf.document_symbol, { desc = "Open [L]SP document [S]ymbols" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Toggle a single reusable terminal in a full-width split at the bottom.
-- Pressing the key hides the window if it's open and reuses the same
-- terminal buffer when reopening, so it never spawns orphaned terminals.
local term = { buf = nil, win = nil }
vim.keymap.set("n", "<leader>ot", function()
	-- If the terminal window is open, hide it.
	if term.win and vim.api.nvim_win_is_valid(term.win) then
		vim.api.nvim_win_hide(term.win)
		term.win = nil
		return
	end

	-- Open a full-width bottom split.
	vim.cmd("botright split")
	vim.cmd("resize 15")
	term.win = vim.api.nvim_get_current_win()

	-- Reuse the existing terminal buffer, or create one on first use.
	if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
		vim.api.nvim_win_set_buf(term.win, term.buf)
	else
		vim.cmd("terminal")
		term.buf = vim.api.nvim_get_current_buf()
	end

	vim.cmd("startinsert")
end, { desc = "[O]pen [T]erminal (toggle)" })

-- TIP: Disable arrow keys in normal mode
vim.keymap.set("n", "<left>", '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set("n", "<right>", '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set("n", "<up>", '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set("n", "<down>", '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
vim.keymap.set("n", "]q", "<cmd>cnext<CR>", { desc = "Quickfix next" })
vim.keymap.set("n", "[q", "<cmd>cprev<CR>", { desc = "Quickfix previous" })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "DiffviewFiles", "DiffviewFileHistory" },
	callback = function(event)
		vim.keymap.set("n", "q", "<cmd>tabclose<CR>", {
			buffer = event.buf,
			silent = true,
			desc = "Close Diffview tab",
		})
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "java", "groovy" },
	callback = function(event)
		local java_tests = require("custom.java_tests")
		local opts = { buffer = event.buf, silent = true }
		vim.keymap.set("n", "<leader>jt", java_tests.jump_source_or_test, vim.tbl_extend("force", opts, {
			desc = "Java: Jump source/test",
		}))
		vim.keymap.set("n", "<leader>tc", java_tests.run_class_picker, vim.tbl_extend("force", opts, {
			desc = "Java: Run test class",
		}))
		vim.keymap.set("n", "<leader>tn", java_tests.run_nearest, vim.tbl_extend("force", opts, {
			desc = "Java: Run nearest test",
		}))
	end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

local function format_with_java_import_cleanup()
	local bufnr = vim.api.nvim_get_current_buf()
	if vim.bo[bufnr].filetype == "java" then
		local params = vim.lsp.util.make_given_range_params({ 0, 0 }, { vim.api.nvim_buf_line_count(bufnr), 0 }, bufnr)
		params.context = {
			only = { "source.organizeImports", "source.organizeImports.java" },
			diagnostics = vim.diagnostic.get(bufnr),
		}

		local applied = false
		local responses = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 3000) or {}
		for client_id, response in pairs(responses) do
			for _, action in ipairs(response.result or {}) do
				local client = vim.lsp.get_client_by_id(client_id)
				if
					client
					and action.data
					and not action.edit
					and not action.command
					and client:supports_method("codeAction/resolve", bufnr)
				then
					local resolved = client:request_sync("codeAction/resolve", action, 3000, bufnr)
					action = (resolved and resolved.result) or action
				end

				if action.edit then
					vim.lsp.util.apply_workspace_edit(action.edit, client and client.offset_encoding or "utf-16")
					applied = true
				end
				if action.command then
					local command = type(action.command) == "table" and action.command.command or action.command
					local arguments = type(action.command) == "table" and action.command.arguments or nil
					if client and command then
						client:request_sync("workspace/executeCommand", { command = command, arguments = arguments }, 3000, bufnr)
					end
					applied = true
				end
				break
			end
		end

		if not applied then
			local uri = vim.uri_from_bufnr(bufnr)
			for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = "jdtls" })) do
				local attempts = {
					{ command = "java.edit.organizeImports", arguments = { uri } },
					{ command = "java.edit.organizeImports", arguments = { { uri = uri } } },
					{ command = "java.edit.organizeImports" },
				}
				for _, payload in ipairs(attempts) do
					local ok = client:request_sync("workspace/executeCommand", payload, 3000, bufnr)
					if ok and not ok.err then
						break
					end
				end
			end
		end
	end

	require("conform").format({ bufnr = bufnr, async = false, lsp_format = "fallback", timeout_ms = 3000 })
end

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require("lazy").setup({
	-- NOTE: Plugins can be added via a link or github org/name. To run setup automatically, use `opts = {}`
	{ "NMAC427/guess-indent.nvim", opts = {} },

	-- Alternatively, use `config = function() ... end` for full control over the configuration.
	-- If you prefer to call `setup` explicitly, use:
	--    {
	--        'lewis6991/gitsigns.nvim',
	--        config = function()
	--            require('gitsigns').setup({
	--                -- Your gitsigns configuration here
	--            })
	--        end,
	--    }
	--
	-- Here is a more advanced example where we pass configuration
	-- options to `gitsigns.nvim`.
	--
	-- See `:help gitsigns` to understand what the configuration keys do
	{ -- Adds git related signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
		},
	},
	{
		"sindrets/diffview.nvim",
		dependencies = "nvim-lua/plenary.nvim",
		cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons", -- icons
		},
		default_component_configs = {
			git_status = {
				symbols = {
					added = "✚",
					modified = "",
					deleted = "✖",
					renamed = "󰁕",
					untracked = "",
					ignored = "",
					unstaged = "󰄱",
					staged = "",
					conflict = "",
				},
			},
		},
		config = function()
			require("neo-tree").setup({
				filesystem = {
					follow_current_file = { enabled = true },
					use_libuv_file_watcher = true,
					filtered_items = {
						hide_dotfiles = true,
						always_show = {
							".github",
							".gitignore",
							".envrc",
							".aiignore",
							".env",
						},
						never_show = {
							".DS_Store",
						},
					},
				},
				window = {
					mappings = {
						["<space>"] = "none", -- ❌ remove the conflicting mapping
						["<cr>"] = "open", -- open file/folder
						["l"] = "open", -- vim-style expand
						["h"] = "close_node", -- collapse folder
						["S"] = "open_split",
						["s"] = "open_vsplit",
					},
				},
			})
			vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>")
		end,
	},
	{
		"rcarriga/nvim-notify",
		opts = {
			background_colour = "#000000",
			render = "wrapped-compact",
			timeout = 3000,
		},
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {
			views = {
				cmdline_popup = {
					position = {
						row = "40%",
						col = "50%",
					},
				},
			},
			cmdline = {
				enabled = true,
				view = "cmdline_popup",
			},
			messages = {
				enabled = true,
			},
			popupmenu = {
				enabled = true,
			},
			notify = {
				enabled = true,
				view = "notify",
			},
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
			presets = {
				bottom_search = false,
				command_palette = true,
				long_message_to_split = true,
				inc_rename = false,
				lsp_doc_border = true,
			},
		},
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
	},
	-- NOTE: Plugins can also be configured to run Lua code when they are loaded.
	--
	-- This is often very useful to both group configuration, as well as handle
	-- lazy loading plugins that don't need to be loaded immediately at startup.
	--
	-- For example, in the following configuration, we use:
	--  event = 'VimEnter'
	--
	-- which loads which-key before all the UI elements are loaded. Events can be
	-- normal autocommands events (`:help autocmd-events`).
	--
	-- Then, because we use the `opts` key (recommended), the configuration runs
	-- after the plugin has been loaded as `require(MODULE).setup(opts)`.

	{ -- Useful plugin to show you pending keybinds.
		"folke/which-key.nvim",
		event = "VimEnter",
		opts = {
			-- delay between pressing a key and opening which-key (milliseconds)
			delay = 150,
			icons = { mappings = vim.g.have_nerd_font },

			-- Document existing key chains
			spec = {
				{ "<leader>d", group = "[D]ebug" },
				{ "<leader>s", group = "[S]earch", mode = { "n", "v" } },
				{ "<leader>t", group = "[T]oggle" },
				{ "<leader>o", group = "[O]pen" },
				{ "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
			},
		},
	},

	-- NOTE: Plugins can specify dependencies.
	--
	-- The dependencies are proper plugin specifications as well - anything
	-- you do for a plugin at the top level, you can do for a dependency.
	--
	-- Use the `dependencies` key to specify the dependencies of a particular plugin

	{ -- Fuzzy Finder (files, lsp, etc)
		"nvim-telescope/telescope.nvim",
		-- By default, Telescope is included and acts as your picker for everything.

		-- If you would like to switch to a different picker (like snacks, or fzf-lua)
		-- you can disable the Telescope plugin by setting enabled to false and enable
		-- your replacement picker by requiring it explicitly (e.g. 'custom.plugins.snacks')

		-- Note: If you customize your config for yourself,
		-- it’s best to remove the Telescope plugin config entirely
		-- instead of just disabling it here, to keep your config clean.
		enabled = true,
		event = "VimEnter",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ -- If encountering errors, see telescope-fzf-native README for installation instructions
				"nvim-telescope/telescope-fzf-native.nvim",

				-- `build` is used to run some command when the plugin is installed/updated.
				-- This is only run then, not every time Neovim starts up.
				build = "make",

				-- `cond` is a condition used to determine whether this plugin should be
				-- installed and loaded.
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },

			-- Useful for getting pretty icons, but requires a Nerd Font.
			{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
		},
		config = function()
			-- Telescope is a fuzzy finder that comes with a lot of different things that
			-- it can fuzzy find! It's more than just a "file finder", it can search
			-- many different aspects of Neovim, your workspace, LSP, and more!
			--
			-- The easiest way to use Telescope, is to start by doing something like:
			--  :Telescope help_tags
			--
			-- After running this command, a window will open up and you're able to
			-- type in the prompt window. You'll see a list of `help_tags` options and
			-- a corresponding preview of the help.
			--
			-- Two important keymaps to use while in Telescope are:
			--  - Insert mode: <c-/>
			--  - Normal mode: ?
			--
			-- This opens a window that shows you all of the keymaps for the current
			-- Telescope picker. This is really useful to discover what Telescope can
			-- do as well as how to actually do it!

			-- [[ Configure Telescope ]]
			-- See `:help telescope` and `:help telescope.setup()`
			require("telescope").setup({
				-- You can put your default mappings / updates / etc. in here
				--  All the info you're looking for is in `:help telescope.setup()`
				--
				-- defaults = {
				--   mappings = {
				--     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
				--   },
				-- },
				-- pickers = {}
				pickers = {
					find_files = {
						hidden = true,
						find_command = {
							"fd",
							"--type",
							"f",
							"--hidden",
							"--follow",
							"--exclude",
							".git",
						},
					},
				},
				extensions = {
					["ui-select"] = { require("telescope.themes").get_dropdown() },
				},
			})

			-- Enable Telescope extensions if they are installed
			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")

			-- See `:help telescope.builtin`
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
			vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
			vim.keymap.set("n", "<leader>p", builtin.find_files, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
			vim.keymap.set({ "n", "v" }, "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
			vim.keymap.set("n", "<leader>sg", function()
				builtin.live_grep({
					additional_args = function()
						return { "--hidden", "--glob", "!.git/*" }
					end,
				})
			end, { desc = "[S]earch by [G]rep" })
			vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
			vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
			vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
			vim.keymap.set("n", "<leader>sc", builtin.commands, { desc = "[S]earch [C]ommands" })
			vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })
			vim.keymap.set("n", "<leader>bn", "<cmd>enew<cr>", { desc = "[B]uffer [N]ew" })
			vim.keymap.set("n", "<leader>br", "<cmd>e!<cr>", { desc = "[B]uffer [R]eload" })

			-- This runs on LSP attach per buffer (see main LSP attach function in 'neovim/nvim-lspconfig' config for more info,
			-- it is better explained there). This allows easily switching between pickers if you prefer using something else!
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("telescope-lsp-attach", { clear = true }),
				callback = function(event)
					local buf = event.buf
					local function goto_definition()
						vim.lsp.buf.definition({
							on_list = function(options)
								if #options.items == 1 then
									local item = options.items[1]
									vim.cmd.edit(vim.fn.fnameescape(item.filename))
									vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
									return
								end

								builtin.lsp_definitions()
							end,
						})
					end

					-- Find references for the word under your cursor.
					vim.keymap.set("n", "grr", builtin.lsp_references, { buffer = buf, desc = "[G]oto [R]eferences" })

					-- Jump to the implementation of the word under your cursor.
					-- Useful when your language has ways of declaring types without an actual implementation.
					vim.keymap.set(
						"n",
						"gri",
						builtin.lsp_implementations,
						{ buffer = buf, desc = "[G]oto [I]mplementation" }
					)

					-- Jump to the definition of the word under your cursor.
					-- This is where a variable was first declared, or where a function is defined, etc.
					-- To jump back, press <C-t>.
					vim.keymap.set("n", "gd", goto_definition, { buffer = buf, desc = "[G]oto [D]efinition" })

					-- Fuzzy find all the symbols in your current document.
					-- Symbols are things like variables, functions, types, etc.
					vim.keymap.set(
						"n",
						"gO",
						builtin.lsp_document_symbols,
						{ buffer = buf, desc = "Open Document Symbols" }
					)

					-- Fuzzy find all the symbols in your current workspace.
					-- Similar to document symbols, except searches over your entire project.
					vim.keymap.set(
						"n",
						"gW",
						builtin.lsp_dynamic_workspace_symbols,
						{ buffer = buf, desc = "Open Workspace Symbols" }
					)

					-- Jump to the type of the word under your cursor.
					-- Useful when you're not sure what type a variable is and you want to see
					-- the definition of its *type*, not where it was *defined*.
					vim.keymap.set(
						"n",
						"gt",
						builtin.lsp_type_definitions,
						{ buffer = buf, desc = "[G]oto [T]ype Definition" }
					)
				end,
			})

			-- Override default behavior and theme when searching
			vim.keymap.set("n", "<leader>/", function()
				-- You can pass additional configuration to Telescope to change the theme, layout, etc.
				builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[/] Fuzzily search in current buffer" })

			-- It's also possible to pass additional configuration options.
			--  See `:help telescope.builtin.live_grep()` for information about particular keys
			vim.keymap.set("n", "<leader>s/", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "[S]earch [/] in Open Files" })

			-- Shortcut for searching your Neovim configuration files
			vim.keymap.set("n", "<leader>sn", function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "[S]earch [N]eovim files" })
		end,
	},

	-- LSP Plugins
	{
		-- Main LSP Configuration
		"neovim/nvim-lspconfig",
		dependencies = {
			-- Automatically install LSPs and related tools to stdpath for Neovim
			-- Mason must be loaded before its dependents so we need to set it up here.
			-- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
			{ "mason-org/mason.nvim", opts = {} },
			"WhoIsSethDaniel/mason-tool-installer.nvim",

			-- Useful status updates for LSP.
			{ "j-hui/fidget.nvim", opts = {} },

			-- Allows extra capabilities provided by blink.cmp
			"saghen/blink.cmp",
		},
		config = function()
			-- Brief aside: **What is LSP?**
			--
			-- LSP is an initialism you've probably heard, but might not understand what it is.
			--
			-- LSP stands for Language Server Protocol. It's a protocol that helps editors
			-- and language tooling communicate in a standardized fashion.
			--
			-- In general, you have a "server" which is some tool built to understand a particular
			-- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
			-- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
			-- processes that communicate with some "client" - in this case, Neovim!
			--
			-- LSP provides Neovim with features like:
			--  - Go to definition
			--  - Find references
			--  - Autocompletion
			--  - Symbol Search
			--  - and more!
			--
			-- Thus, Language Servers are external tools that must be installed separately from
			-- Neovim. This is where `mason` and related plugins come into play.
			--
			-- If you're wondering about lsp vs treesitter, you can check out the wonderfully
			-- and elegantly composed help section, `:help lsp-vs-treesitter`

			--  This function gets run when an LSP attaches to a particular buffer.
			--    That is to say, every time a new file is opened that is associated with
			--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
			--    function will be executed to configure the current buffer
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					-- NOTE: Remember that Lua is a real programming language, and as such it is possible
					-- to define small helper and utility functions so you don't have to repeat yourself.
					--
					-- In this case, we create a function that lets us more easily define mappings specific
					-- for LSP related items. It sets the mode, buffer and description for us each time.
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					-- Rename the variable under your cursor.
					--  Most Language Servers support renaming across files, etc.
					map("grn", vim.lsp.buf.rename, "[R]e[n]ame")

					-- Execute a code action, usually your cursor needs to be on top of an error
					-- or a suggestion from your LSP for this to activate.
					map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })

					-- WARN: This is not Goto Definition, this is Goto Declaration.
					--  For example, in C this would take you to the header.
					map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

					-- The following two autocommands are used to highlight references of the
					-- word under your cursor when your cursor rests there for a little while.
					--    See `:help CursorHold` for information about when this is executed
					--
					-- When you move your cursor, the highlights will be cleared (the second autocommand).
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client:supports_method("textDocument/documentHighlight", event.buf) then
						local highlight_augroup =
							vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})

						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})

						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
							end,
						})
					end

					-- The following code creates a keymap to toggle inlay hints in your
					-- code, if the language server you are using supports them
					--
					-- This may be unwanted, since they displace some of your code
					if client and client:supports_method("textDocument/inlayHint", event.buf) then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "[T]oggle Inlay [H]ints")
					end
				end,
			})

			-- LSP servers and clients are able to communicate to each other what features they support.
			--  By default, Neovim doesn't support everything that is in the LSP specification.
			--  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
			--  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- Enable the following language servers
			--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
			--  See `:help lsp-config` for information about keys and how to configure
			local servers = {
				gopls = {},
				angularls = {},
				html = {},
				cssls = {},
				tailwindcss = {},
				ts_ls = {},
				-- clangd = {},
				-- pyright = {},
				-- rust_analyzer = {},
				--
				-- Some languages (like typescript) have entire language plugins that can be useful:
				--    https://github.com/pmizio/typescript-tools.nvim
				--
				-- But for many setups, the LSP (`ts_ls`) will work just fine
				-- ts_ls = {},
			}

			-- Ensure the servers and tools above are installed
			--
			-- To check the current status of installed tools and/or manually install
			-- other tools, you can run
			--    :Mason
			--
			-- You can press `g?` for help in this menu.
			local mason_package_for_server = {
				angularls = "angular-language-server",
				cssls = "css-lsp",
				html = "html-lsp",
				lua_ls = "lua-language-server",
				tailwindcss = "tailwindcss-language-server",
				ts_ls = "typescript-language-server",
			}

			local extra_tools = {
				"jdtls",
				"java-debug-adapter",
				"java-test",
				"stylua",
				"gofumpt",
				"goimports",
				"prettierd",
				"prettier",
				"google-java-format",
			}

			local ensure_installed = vim.tbl_keys(servers)
			table.insert(ensure_installed, "lua_ls")

			for i, server_name in ipairs(ensure_installed) do
				ensure_installed[i] = mason_package_for_server[server_name] or server_name
			end

			vim.list_extend(ensure_installed, extra_tools)

			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			for name, server in pairs(servers) do
				server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
				vim.lsp.config(name, server)
				vim.lsp.enable(name)
			end

			-- Special Lua Config, as recommended by neovim help docs
			vim.lsp.config("lua_ls", {
				on_init = function(client)
					if client.workspace_folders then
						local path = client.workspace_folders[1].name
						if
							path ~= vim.fn.stdpath("config")
							and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
						then
							return
						end
					end

					client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
						runtime = {
							version = "LuaJIT",
							path = { "lua/?.lua", "lua/?/init.lua" },
						},
						workspace = {
							checkThirdParty = false,
							-- NOTE: this is a lot slower and will cause issues when working on your own configuration.
							--  See https://github.com/neovim/nvim-lspconfig/issues/3189
							library = vim.api.nvim_get_runtime_file("", true),
						},
					})
				end,
				settings = {
					Lua = {},
				},
			})
			vim.lsp.enable("lua_ls")
		end,
	},

	{ -- Autoformat
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				format_with_java_import_cleanup,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = true,
			format_on_save = function(bufnr)
				-- Disable "format_on_save lsp_fallback" for languages that don't
				-- have a well standardized coding style. You can add additional
				-- languages here or re-enable it for the disabled ones.
				local disable_filetypes = { c = true, cpp = true }
				if disable_filetypes[vim.bo[bufnr].filetype] then
					return nil
				else
					return {
						timeout_ms = 500,
						lsp_format = "fallback",
					}
				end
			end,
			formatters_by_ft = {
				css = { "prettierd", "prettier", stop_after_first = true },
				go = { "goimports", "gofumpt" },
				html = { "prettierd", "prettier", stop_after_first = true },
				-- Java formatting uses jdtls LSP with Google Style (configured in LSP settings)
				javascript = { "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "prettierd", "prettier", stop_after_first = true },
				lua = { "stylua" },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				typescriptreact = { "prettierd", "prettier", stop_after_first = true },
				-- Conform can also run multiple formatters sequentially
				-- python = { "isort", "black" },
				--
				-- You can use 'stop_after_first' to run the first available formatter from the list
				-- javascript = { "prettierd", "prettier", stop_after_first = true },
			},
		},
	},

	{ -- Autocompletion
		"saghen/blink.cmp",
		event = "VimEnter",
		version = "1.*",
		dependencies = {
			-- Snippet Engine
			{
				"L3MON4D3/LuaSnip",
				version = "2.*",
				build = (function()
					-- Build Step is needed for regex support in snippets.
					-- This step is not supported in many windows environments.
					-- Remove the below condition to re-enable on windows.
					if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
						return
					end
					return "make install_jsregexp"
				end)(),
				dependencies = {
					-- `friendly-snippets` contains a variety of premade snippets.
					--    See the README about individual language/framework/plugin snippets:
					--    https://github.com/rafamadriz/friendly-snippets
					-- {
					--   'rafamadriz/friendly-snippets',
					--   config = function()
					--     require('luasnip.loaders.from_vscode').lazy_load()
					--   end,
					-- },
				},
				opts = {},
			},
		},
		--- @module 'blink.cmp'
		--- @type blink.cmp.Config
		opts = {
			keymap = {
				-- 'default' (recommended) for mappings similar to built-in completions
				--   <c-y> to accept ([y]es) the completion.
				--    This will auto-import if your LSP supports it.
				--    This will expand snippets if the LSP sent a snippet.
				-- 'super-tab' for tab to accept
				-- 'enter' for enter to accept
				-- 'none' for no mappings
				--
				-- For an understanding of why the 'default' preset is recommended,
				-- you will need to read `:help ins-completion`
				--
				-- No, but seriously. Please read `:help ins-completion`, it is really good!
				--
				-- All presets have the following mappings:
				-- <tab>/<s-tab>: move to right/left of your snippet expansion
				-- <c-space>: Open menu or open docs if already open
				-- <c-n>/<c-p> or <up>/<down>: Select next/previous item
				-- <c-e>: Hide menu
				-- <c-k>: Toggle signature help
				--
				-- See :h blink-cmp-config-keymap for defining your own keymap
				preset = "default",

				-- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
				--    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
			},

			appearance = {
				-- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = "mono",
			},

			completion = {
				-- By default, you may press `<c-space>` to show the documentation.
				-- Optionally, set `auto_show = true` to show the documentation after a delay.
				documentation = { auto_show = false, auto_show_delay_ms = 500 },
			},

				sources = {
					default = { "lsp", "path", "snippets" },
					per_filetype = {
						sql = { "snippets", "dadbod", "buffer" },
						mysql = { "snippets", "dadbod", "buffer" },
						plsql = { "snippets", "dadbod", "buffer" },
						pgsql = { "snippets", "omni", "buffer" },
						psql = { "snippets", "omni", "buffer" },
						postgres = { "snippets", "omni", "buffer" },
					},
					providers = {
						dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
					},
			},

			snippets = { preset = "luasnip" },

			-- Blink.cmp includes an optional, recommended rust fuzzy matcher,
			-- which automatically downloads a prebuilt binary when enabled.
			--
			-- By default, we use the Lua implementation instead, but you may enable
			-- the rust implementation via `'prefer_rust_with_warning'`
			--
			-- See :h blink-cmp-config-fuzzy for more information
			fuzzy = { implementation = "lua" },

			-- Shows a signature help window while you type arguments for a function
			signature = { enabled = true },
		},
	},

	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "macchiato",
				-- Let the terminal's background_opacity through. The colorscheme
				-- would otherwise paint every cell with an explicit background,
				-- and kitty only makes the *default* background translucent.
				transparent_background = true,
				integrations = {
					gitsigns = true,
					treesitter = true,
					telescope = true,
					neotree = true,
					mason = true,
					which_key = true,
				},
			})
		end,
	},
	{
		"projekt0n/github-nvim-theme",
		name = "github-theme",
		priority = 1000,
		config = function()
			require("github-theme").setup({
				options = {
					-- Matches catppuccin's transparent_background above, so the
					-- terminal shows through on both sides of <leader>tt.
					transparent = true,
				},
			})
		end,
	},
	-- Highlight todo, notes, etc in comments
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},

	{ -- Collection of various small independent plugins/modules
		"nvim-mini/mini.nvim",
		config = function()
			-- Better Around/Inside textobjects
			--
			-- Examples:
			--  - va)  - [V]isually select [A]round [)]paren
			--  - yinq - [Y]ank [I]nside [N]ext [Q]uote
			--  - ci'  - [C]hange [I]nside [']quote
			require("mini.ai").setup({ n_lines = 500 })

			-- Add/delete/replace surroundings (brackets, quotes, etc.)
			--
			-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
			-- - sd'   - [S]urround [D]elete [']quotes
			-- - sr)'  - [S]urround [R]eplace [)] [']
			require("mini.surround").setup()

			-- Simple and easy statusline.
			--  You could remove this setup call if you don't like it,
			--  and try some other statusline plugin
			local statusline = require("mini.statusline")
			-- set use_icons to true if you have a Nerd Font
			statusline.setup({ use_icons = vim.g.have_nerd_font })

			-- You can configure sections in the statusline by overriding their
			-- default behavior. For example, here we set the section for
			-- cursor location to LINE:COLUMN
			---@diagnostic disable-next-line: duplicate-set-field
			statusline.section_location = function()
				return "%2l:%-2v"
			end

			---@diagnostic disable-next-line: duplicate-set-field
			statusline.section_filename = function()
				if vim.bo.buftype == "terminal" then
					return "%t"
				end

				return "%f%m%r"
			end

			---@diagnostic disable-next-line: duplicate-set-field
			statusline.section_git = function(args)
				if statusline.is_truncated(args.trunc_width) then
					return ""
				end

				local summary = vim.b.minigit_summary_string or vim.b.gitsigns_head
				if summary == nil then
					return ""
				end

				return " " .. (summary == "" and "-" or summary)
			end

			---@diagnostic disable-next-line: duplicate-set-field
			statusline.section_diff = function()
				return ""
			end

			---@diagnostic disable-next-line: duplicate-set-field
			statusline.section_fileinfo = function(args)
				if vim.bo.buftype ~= "" then
					return ""
				end

				local diagnostics_count = #vim.diagnostic.get(0)
				local filetype = vim.bo.filetype ~= "" and vim.bo.filetype or "no ft"
				local encoding = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
				local separator = " │ "
				local icon = ""

				if vim.g.have_nerd_font then
					local ok, devicons = pcall(require, "nvim-web-devicons")
					if ok then
						local filename = vim.api.nvim_buf_get_name(0)
						local icon_str = devicons.get_icon(filename, nil, { default = true })
						icon = (icon_str or "") .. " "
					end
				end

				if statusline.is_truncated(args.trunc_width) then
					return " " .. diagnostics_count .. separator .. icon .. filetype
				end

				return " " .. diagnostics_count .. separator .. icon .. filetype .. separator .. encoding
			end

			---@diagnostic disable-next-line: duplicate-set-field
			statusline.section_diagnostics = function()
				return ""
			end

			---@diagnostic disable-next-line: duplicate-set-field
			statusline.section_lsp = function()
				return ""
			end

			-- ... and there is more!
			--  Check out: https://github.com/nvim-mini/mini.nvim
		end,
	},

	{ -- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			local parsers = {
				"bash",
				"css",
				"diff",
				"go",
				"html",
				"java",
				"javascript",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"query",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
			}
			require("nvim-treesitter").install(parsers)

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "*",
				callback = function(args)
					pcall(vim.treesitter.start, args.buf)
				end,
			})
		end,
	},

	-- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
	-- init.lua. If you want these files, they are in the repository, so you can just download them and
	-- place them in the correct locations.

	-- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
	--
	--  Here are some example plugins that I've included in the Kickstart repository.
	--  Uncomment any of the lines below to enable them (you will need to restart nvim).
	--
	-- require 'kickstart.plugins.debug',
	-- require 'kickstart.plugins.indent_line',
	-- require 'kickstart.plugins.lint',
	-- require 'kickstart.plugins.autopairs',
	-- require 'kickstart.plugins.gitsigns', -- adds gitsigns recommend keymaps

	{
		"NeogitOrg/neogit",
		lazy = true,
		dependencies = {
			"nvim-lua/plenary.nvim", -- required

			-- Only one of these is needed.
			"sindrets/diffview.nvim", -- optional
			"esmuellert/codediff.nvim", -- optional

			-- Only one of these is needed.
			"nvim-telescope/telescope.nvim", -- optional
			"ibhagwan/fzf-lua", -- optional
			"nvim-mini/mini.pick", -- optional
			"folke/snacks.nvim", -- optional
		},
		cmd = "Neogit",
		keys = {
			{ "<leader>gg", "<cmd>Neogit<cr>", desc = "Show Neogit UI" },
		},
	},

	-- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
	--    This is the easiest way to modularize your config.
	--
	--  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
	{ import = "custom.plugins" },
	--
	-- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
	-- Or use telescope!
	-- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
	-- you can continue same window with `<space>sr` which resumes last telescope search
}, {
	rocks = { enabled = false },
	ui = {
		-- If you are using a Nerd Font: set icons to an empty table which will use the
		-- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
		icons = vim.g.have_nerd_font and {} or {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
})

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		set_theme(read_persisted_theme())
	end,
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
