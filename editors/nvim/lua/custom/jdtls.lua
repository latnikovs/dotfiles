local M = {}

local root_markers = { "pom.xml", "build.gradle", "build.gradle.kts", ".git" }

local function root_dir(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		return nil
	end

	local found = vim.fs.find(root_markers, {
		path = vim.fs.dirname(vim.fs.normalize(name)),
		upward = true,
	})[1]

	return found and vim.fs.dirname(found) or nil
end

local function workspace_dir(root)
	return vim.fn.stdpath("data") .. "/jdtls/" .. vim.fs.basename(root)
end

local function glob_paths(pattern)
	return vim.fn.glob(pattern, true, true)
end

local function debug_bundles()
	local mason = vim.fn.stdpath("data") .. "/mason/packages"
	local bundles = {}

	vim.list_extend(
		bundles,
		glob_paths(mason .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar")
	)
	vim.list_extend(bundles, glob_paths(mason .. "/java-test/extension/server/*.jar"))

	return bundles
end

function M.start_or_attach()
	local bufnr = vim.api.nvim_get_current_buf()
	local root = root_dir(bufnr)
	if not root then
		return
	end

	local cmd = { "jdtls" }
	local lombok_jar = vim.fn.stdpath("data") .. "/mason/packages/jdtls/lombok.jar"
	if vim.uv.fs_stat(lombok_jar) then
		table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok_jar)
	end
	table.insert(cmd, "-data")
	table.insert(cmd, workspace_dir(root))

	local bundles = debug_bundles()
	local jdtls = require("jdtls")

	jdtls.start_or_attach({
		cmd = cmd,
		root_dir = root,
		capabilities = require("blink.cmp").get_lsp_capabilities(),
		init_options = {
			bundles = bundles,
		},
		settings = {
			java = {
				eclipse = {
					downloadSources = true,
				},
				maven = {
					downloadSources = true,
				},
				references = {
					includeDecompiledSources = true,
				},
				format = {
					settings = {
						url = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
						profile = "GoogleStyle",
					},
				},
			},
		},
	})

	if #bundles > 0 then
		jdtls.setup_dap({ hotcodereplace = "auto" })

		local ok, jdtls_dap = pcall(require, "jdtls.dap")
		if ok then
			jdtls_dap.setup_dap_main_class_configs()
		end
	end
end

return M
