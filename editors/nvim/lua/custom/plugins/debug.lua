return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			"jay-babu/mason-nvim-dap.nvim",
			"leoluz/nvim-dap-go",
		},
		keys = {
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Debug breakpoint",
			},
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Debug continue",
			},
			{
				"<leader>dr",
				function()
					require("dap").run_last()
				end,
				desc = "Debug run last",
			},
			{
				"<leader>dt",
				function()
					require("dap").terminate()
				end,
				desc = "Debug terminate",
			},
			{
				"<leader>di",
				function()
					require("dap").step_into()
				end,
				desc = "Debug step into",
			},
			{
				"<leader>do",
				function()
					require("dap").step_over()
				end,
				desc = "Debug step over",
			},
			{
				"<leader>dO",
				function()
					require("dap").step_out()
				end,
				desc = "Debug step out",
			},
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
				end,
				desc = "Debug conditional breakpoint",
			},
			{
				"<leader>du",
				function()
					require("dapui").toggle()
				end,
				desc = "Debug UI",
			},
			{
				"<leader>de",
				function()
					require("dapui").eval()
				end,
				desc = "Debug eval",
			},
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")
			local breakpoint_icons = vim.g.have_nerd_font and {
				Breakpoint = "",
				BreakpointCondition = "",
				BreakpointRejected = "",
				LogPoint = "󰆨",
				Stopped = "",
			} or {
				Breakpoint = "●",
				BreakpointCondition = "◐",
				BreakpointRejected = "⊘",
				LogPoint = "◆",
				Stopped = "▶",
			}

			require("mason-nvim-dap").setup({
				automatic_installation = true,
				ensure_installed = { "delve" },
				handlers = {},
			})

			dapui.setup({})

			vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e51400" })
			vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#ff8800" })
			vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = "#6b7280" })
			vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#0ea5e9" })
			vim.api.nvim_set_hl(0, "DapStopped", { fg = "#22c55e", bold = true })

			for type, icon in pairs(breakpoint_icons) do
				local sign = "Dap" .. type
				local texthl = sign
				local linehl = type == "Stopped" and "CursorLine" or nil
				vim.fn.sign_define(sign, { text = icon, texthl = texthl, linehl = linehl, numhl = texthl })
			end

			dap.listeners.after.event_initialized.dapui_config = dapui.open
			dap.listeners.before.event_terminated.dapui_config = dapui.close
			dap.listeners.before.event_exited.dapui_config = dapui.close

			require("dap-go").setup({
				delve = {
					detached = vim.fn.has("win32") == 0,
				},
			})
		end,
	},
	{
		"mfussenegger/nvim-jdtls",
		ft = { "java" },
		config = function()
			require("custom.jdtls").start_or_attach()

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "java",
				callback = function()
					require("custom.jdtls").start_or_attach()
				end,
			})
		end,
	},
}
