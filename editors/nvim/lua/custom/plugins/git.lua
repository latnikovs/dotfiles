local function in_git_repo()
	local inside = vim.fn.systemlist({ "git", "rev-parse", "--is-inside-work-tree" })
	return vim.v.shell_error == 0 and inside[1] == "true"
end

local function list_branches()
	local local_branches = vim.fn.systemlist({
		"git",
		"for-each-ref",
		"--format=%(refname:short)",
		"refs/heads",
	})
	if vim.v.shell_error ~= 0 then
		return nil, nil, "Failed to list local branches"
	end

	local remote_branches = vim.fn.systemlist({
		"git",
		"for-each-ref",
		"--format=%(refname:short)",
		"refs/remotes",
	})
	if vim.v.shell_error ~= 0 then
		return nil, nil, "Failed to list remote branches"
	end

	table.sort(local_branches)
	table.sort(remote_branches)

	return local_branches, remote_branches, nil
end

local open_branch_picker

open_branch_picker = function()
	if not in_git_repo() then
		vim.notify("Not inside a git repository", vim.log.levels.WARN)
		return
	end

	local local_branches, remote_branches, err = list_branches()
	if err then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	local use_icons = vim.g.have_nerd_font
	local local_tag = use_icons and "  " or ""
	local remote_tag = use_icons and "󰛳  " or ""

	local items = {}
	for _, branch in ipairs(local_branches) do
		if branch ~= "" then
			table.insert(items, {
				label = local_tag .. branch,
				kind = "local",
				name = branch,
			})
		end
	end

	for _, remote in ipairs(remote_branches) do
		if remote ~= "" and not remote:match("/HEAD$") then
			table.insert(items, {
				label = remote_tag .. remote,
				kind = "remote",
				name = remote,
			})
		end
	end

	if #items == 0 then
		vim.notify("No branches found", vim.log.levels.WARN)
		return
	end

	local ok_pickers, pickers = pcall(require, "telescope.pickers")
	local ok_finders, finders = pcall(require, "telescope.finders")
	local ok_conf, telescope_conf = pcall(require, "telescope.config")
	local ok_actions, actions = pcall(require, "telescope.actions")
	local ok_state, action_state = pcall(require, "telescope.actions.state")

	if not (ok_pickers and ok_finders and ok_conf and ok_actions and ok_state) then
		vim.ui.select(items, {
			prompt = "Git branches:",
			format_item = function(item)
				return item.label
			end,
		}, function(choice)
			if not choice then
				return
			end
			if choice.kind == "remote" then
				vim.cmd("Git switch --track " .. vim.fn.fnameescape(choice.name))
			else
				vim.cmd("Git switch " .. vim.fn.fnameescape(choice.name))
			end
		end)
		return
	end

	pickers.new({}, {
		prompt_title = "Git branches",
		finder = finders.new_table({
			results = items,
			entry_maker = function(item)
				return {
					value = item,
					display = item.label,
					ordinal = (item.kind == "local" and "0 " or "1 ") .. item.name,
				}
			end,
		}),
		sorter = telescope_conf.values.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, map)
			local function get_selected()
				local entry = action_state.get_selected_entry()
				return entry and entry.value or nil
			end

			local function switch_selected()
				local item = get_selected()
				actions.close(prompt_bufnr)
				if not item then
					return
				end
				if item.kind == "remote" then
					vim.cmd("Git switch --track " .. vim.fn.fnameescape(item.name))
				else
					vim.cmd("Git switch " .. vim.fn.fnameescape(item.name))
				end
			end

			actions.select_default:replace(switch_selected)
			return true
		end,
	}):find()
end

local open_branch_delete_picker

open_branch_delete_picker = function()
	if not in_git_repo() then
		vim.notify("Not inside a git repository", vim.log.levels.WARN)
		return
	end

	local local_branches, _, err = list_branches()
	if err then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	local use_icons = vim.g.have_nerd_font
	local branch_icon = use_icons and "  " or ""

	local items = {}
	for _, branch in ipairs(local_branches) do
		if branch ~= "" then
			table.insert(items, {
				label = branch_icon .. branch,
				name = branch,
			})
		end
	end

	if #items == 0 then
		vim.notify("No local branches found", vim.log.levels.WARN)
		return
	end

	local ok_pickers, pickers = pcall(require, "telescope.pickers")
	local ok_finders, finders = pcall(require, "telescope.finders")
	local ok_conf, telescope_conf = pcall(require, "telescope.config")
	local ok_actions, actions = pcall(require, "telescope.actions")
	local ok_state, action_state = pcall(require, "telescope.actions.state")

	if not (ok_pickers and ok_finders and ok_conf and ok_actions and ok_state) then
		vim.ui.select(items, {
			prompt = "Delete local branch:",
			format_item = function(item)
				return item.label
			end,
		}, function(choice)
			if not choice then
				return
			end
			vim.ui.select({ "safe (-d)", "force (-D)" }, {
				prompt = "Delete mode:",
			}, function(mode)
				if mode == "safe (-d)" then
					vim.cmd("Git branch -d " .. vim.fn.fnameescape(choice.name))
				elseif mode == "force (-D)" then
					vim.cmd("Git branch -D " .. vim.fn.fnameescape(choice.name))
				end
			end)
		end)
		return
	end

	pickers.new({}, {
		prompt_title = "Delete branch (X force)",
		initial_mode = "normal",
		finder = finders.new_table({
			results = items,
			entry_maker = function(item)
				return {
					value = item,
					display = item.label,
					ordinal = item.name,
				}
			end,
		}),
		sorter = telescope_conf.values.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, map)
			local function get_selected()
				local entry = action_state.get_selected_entry()
				return entry and entry.value or nil
			end

			local function delete_selected()
				local item = get_selected()
				actions.close(prompt_bufnr)
				if not item then
					return
				end
				vim.cmd("Git branch -D " .. vim.fn.fnameescape(item.name))
				vim.schedule(open_branch_delete_picker)
			end

			actions.select_default:replace(function()
				vim.notify("Use X to force delete", vim.log.levels.INFO)
			end)
			map("n", "X", function()
				delete_selected()
			end)
			map("i", "<C-x>", function()
				delete_selected()
			end)
			return true
		end,
	}):find()
end

return {
	{
		"tpope/vim-fugitive",
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "fugitive",
				callback = function(event)
					local opts = { buffer = event.buf, silent = true }
					vim.keymap.set("n", "P", "<cmd>Git push<CR>", opts)
					vim.keymap.set("n", "p", "<cmd>Git pull<CR>", opts)
				end,
			})
		end,
		keys = {
			{
				"<leader>gs",
				function()
					if vim.bo.filetype == "fugitive" then
						vim.cmd("close")
					else
						vim.cmd("Git")
					end
				end,
				desc = "Toggle Git status (Fugitive)",
			},
			{
				"<leader>gbs",
				open_branch_picker,
				desc = "[G]it [b]ranch [s]elect",
			},
			{
				"<leader>gbn",
				function()
					if not in_git_repo() then
						vim.notify("Not inside a git repository", vim.log.levels.WARN)
						return
					end

					vim.ui.input({ prompt = "New branch name: " }, function(input)
						local name = input and vim.trim(input) or ""
						if name == "" then
							return
						end
						vim.cmd("Git switch -c " .. vim.fn.fnameescape(name))
					end)
				end,
				desc = "[G]it [b]ranch [n]ew",
			},
			{
				"<leader>gbd",
				open_branch_delete_picker,
				desc = "[G]it [b]ranch [d]elete",
			},
		},
	},
	{
		"sindrets/diffview.nvim",
		keys = {
			{
				"<leader>gk",
				function()
					local view = require("diffview.lib").get_current_view()
					if view then
						vim.cmd("DiffviewClose")
					else
						vim.cmd("DiffviewOpen")
					end
				end,
				desc = "Toggle DiffviewOpen/Close",
			},
		},
	},
}
