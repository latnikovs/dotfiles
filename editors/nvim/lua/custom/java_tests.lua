local M = {}

local test_suffixes = { "SpecIT", "Spec", "Test", "IT" }

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Java Tests" })
end

local function buf_path(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then return nil end
  return vim.fs.normalize(name)
end

local function project_root(path)
  if not path then return nil end
  local markers = { "pom.xml", "build.gradle", "build.gradle.kts", ".git" }
  local found = vim.fs.find(markers, { path = path, upward = true })[1]
  if not found then return nil end
  return vim.fs.dirname(found)
end

local function rel_to_root(root, path)
  local prefix = root .. "/"
  if vim.startswith(path, prefix) then return path:sub(#prefix + 1) end
  return path
end

local function basename_without_ext(path)
  local base = vim.fs.basename(path)
  return (base:gsub("%.[^.]+$", ""))
end

local function dedupe_paths(paths)
  local out = {}
  local seen = {}
  for _, p in ipairs(paths) do
    local normalized = vim.fs.normalize(p)
    if not seen[normalized] then
      seen[normalized] = true
      table.insert(out, normalized)
    end
  end
  return out
end

local function source_base_from_test_base(test_base)
  for _, suffix in ipairs(test_suffixes) do
    if vim.endswith(test_base, suffix) then return test_base:sub(1, #test_base - #suffix) end
  end
  return test_base
end

local function is_test_path(path)
  return path:find("/src/test/") ~= nil
end

local function is_integration_test(path)
  local base = basename_without_ext(path)
  return vim.endswith(base, "IT") or vim.endswith(base, "SpecIT")
end

local function file_candidates_for_source_base(root, source_base)
  local candidates = {}
  local test_names = {
    source_base .. "Test.java",
    source_base .. "IT.java",
    source_base .. "Spec.groovy",
    source_base .. "SpecIT.groovy",
  }
  for _, name in ipairs(test_names) do
    local patterns = {
      "src/test/java/**/" .. name,
      "src/test/groovy/**/" .. name,
    }
    for _, pattern in ipairs(patterns) do
      local found = vim.fn.globpath(root, pattern, false, true)
      for _, p in ipairs(found) do
        table.insert(candidates, p)
      end
    end
  end
  return dedupe_paths(candidates)
end

local function source_candidates_from_test(root, source_base)
  local candidates = {}
  local names = { source_base .. ".java", source_base .. ".groovy" }
  for _, name in ipairs(names) do
    local patterns = {
      "src/main/java/**/" .. name,
      "src/main/groovy/**/" .. name,
    }
    for _, pattern in ipairs(patterns) do
      local found = vim.fn.globpath(root, pattern, false, true)
      for _, p in ipairs(found) do
        table.insert(candidates, p)
      end
    end
  end
  return dedupe_paths(candidates)
end

local function infer_source_base(path)
  local base = basename_without_ext(path)
  if is_test_path(path) then return source_base_from_test_base(base) end
  return base
end

local function gradle_has_integration_task(root)
  local files = { root .. "/build.gradle", root .. "/build.gradle.kts" }
  for _, file in ipairs(files) do
    if vim.fn.filereadable(file) == 1 then
      local lines = vim.fn.readfile(file)
      for _, line in ipairs(lines) do
        if line:find("integrationTest") then return true end
      end
    end
  end
  return false
end

local function build_tool(root)
  if vim.fn.filereadable(root .. "/pom.xml") == 1 then return "maven" end
  if vim.fn.filereadable(root .. "/build.gradle") == 1 or vim.fn.filereadable(root .. "/build.gradle.kts") == 1 then
    return "gradle"
  end
  return nil
end

local function fqcn_from_test_path(root, path)
  local rel = rel_to_root(root, path)
  rel = rel:gsub("^src/test/java/", "")
  rel = rel:gsub("^src/test/groovy/", "")
  rel = rel:gsub("%.[^.]+$", "")
  rel = rel:gsub("/", ".")
  return rel
end

local java_block_keywords = {
  ["if"] = true,
  ["for"] = true,
  ["while"] = true,
  ["switch"] = true,
  ["catch"] = true,
  ["return"] = true,
  ["new"] = true,
}

local function nearest_java_method_name(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  for line_nr = cursor[1], 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, line_nr - 1, line_nr, false)[1] or ""
    local name = line:match("([%a_][%w_]*)%s*%b()")
    if name and not java_block_keywords[name] then return name end
  end
  return nil
end

local function run_in_split(cmd, root)
  vim.cmd("botright 14new")
  local term_win = vim.api.nvim_get_current_win()
  local term_buf = vim.api.nvim_get_current_buf()
  vim.bo[term_buf].bufhidden = "hide"
  vim.keymap.set("t", "<C-u>", "<C-\\><C-n><C-u>", {
    buffer = term_buf,
    silent = true,
    desc = "Scroll test output up",
  })
  vim.keymap.set("t", "<C-d>", "<C-\\><C-n><C-d>", {
    buffer = term_buf,
    silent = true,
    desc = "Scroll test output down",
  })
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(term_win) and #vim.api.nvim_tabpage_list_wins(0) > 1 then
      pcall(vim.api.nvim_win_close, term_win, true)
      return
    end
    if vim.api.nvim_buf_is_valid(term_buf) then pcall(vim.api.nvim_buf_delete, term_buf, { force = true }) end
  end, { buffer = term_buf, silent = true, desc = "Close test output" })
  local shell_cmd = { "bash", "-lc", cmd }
  vim.fn.termopen(shell_cmd, {
    cwd = root,
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          notify("Tests passed")
        else
          notify("Tests failed (see terminal output)", vim.log.levels.WARN)
        end
      end)
    end,
  })
  if vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_set_current_win(term_win)
    vim.api.nvim_win_set_cursor(term_win, { vim.api.nvim_buf_line_count(term_buf), 0 })
    vim.cmd("startinsert")
  end
  notify("Running: " .. cmd)
end

local function test_spec_from_path(root, path)
  local base = basename_without_ext(path)
  return {
    path = path,
    class_name = base,
    fqcn = fqcn_from_test_path(root, path),
    integration = is_integration_test(path),
  }
end

local function command_for_target(root, spec, method)
  local tool = build_tool(root)
  if not tool then
    notify("No Maven/Gradle project root found", vim.log.levels.ERROR)
    return nil
  end

  if tool == "maven" then
    local maven_cmd = "mvn"
    local mvnw = vim.fs.find("mvnw", { path = spec.path, upward = true })[1]
    if mvnw then
      maven_cmd = vim.fn.shellescape(vim.fs.normalize(mvnw))
    elseif vim.fn.filereadable(root .. "/mvnw") == 1 then
      maven_cmd = "./mvnw"
    end
    local property = spec.integration and "-Dit.test=" or "-Dtest="
    local selector = spec.class_name
    if method and method ~= "" then selector = selector .. "#" .. method end
    local goal = spec.integration and "verify" or "test"
    local profile = spec.integration and " -P it" or ""
    return maven_cmd .. profile .. " " .. property .. selector .. " " .. goal
  end

  local gradle_cmd = "gradle"
  if vim.fn.filereadable(root .. "/gradlew") == 1 then gradle_cmd = "./gradlew" end
  local task = "test"
  if spec.integration and gradle_has_integration_task(root) then task = "integrationTest" end
  local selector = spec.fqcn
  if method and method ~= "" then selector = selector .. "." .. method end
  return gradle_cmd .. " " .. task .. " --tests " .. vim.fn.shellescape(selector)
end

local function select_target(root, targets, prompt, on_choice)
  if #targets == 0 then
    notify("No matching test targets found", vim.log.levels.WARN)
    return
  end

  vim.ui.select(targets, {
    prompt = prompt,
    format_item = function(item)
      local rel = rel_to_root(root, item.path)
      local kind = item.integration and "IT" or "TEST"
      return string.format("[%s] %s", kind, rel)
    end,
  }, function(choice)
    if not choice then return end
    on_choice(choice)
  end)
end

function M.jump_source_or_test()
  local path = buf_path()
  local root = project_root(path)
  if not path or not root then
    notify("Not inside a Maven/Gradle project", vim.log.levels.WARN)
    return
  end

  local source_base = infer_source_base(path)

  if is_test_path(path) then
    local sources = source_candidates_from_test(root, source_base)
    if #sources == 0 then
      notify("No source file found for " .. source_base, vim.log.levels.WARN)
      return
    end
    if #sources == 1 then
      vim.cmd.edit(vim.fn.fnameescape(sources[1]))
      return
    end
    vim.ui.select(sources, {
      prompt = "Choose source file",
      format_item = function(item)
        return rel_to_root(root, item)
      end,
    }, function(choice)
      if choice then vim.cmd.edit(vim.fn.fnameescape(choice)) end
    end)
    return
  end

  local tests = file_candidates_for_source_base(root, source_base)
  if #tests == 0 then
    notify("No test file found for " .. source_base, vim.log.levels.WARN)
    return
  end
  if #tests == 1 then
    vim.cmd.edit(vim.fn.fnameescape(tests[1]))
    return
  end
  local items = {}
  for _, p in ipairs(tests) do
    table.insert(items, test_spec_from_path(root, p))
  end
  select_target(root, items, "Choose test file", function(choice)
    vim.cmd.edit(vim.fn.fnameescape(choice.path))
  end)
end

function M.run_class_picker()
  local path = buf_path()
  local root = project_root(path)
  if not path or not root then
    notify("Not inside a Maven/Gradle project", vim.log.levels.WARN)
    return
  end

  local source_base = infer_source_base(path)
  local candidates = file_candidates_for_source_base(root, source_base)
  if #candidates == 0 and is_test_path(path) then candidates = { path } end

  local items = {}
  for _, p in ipairs(candidates) do
    table.insert(items, test_spec_from_path(root, p))
  end

  if #items == 1 then
    local cmd = command_for_target(root, items[1], nil)
    if cmd then run_in_split(cmd, root) end
    return
  end

  select_target(root, items, "Run test class", function(choice)
    local cmd = command_for_target(root, choice, nil)
    if cmd then run_in_split(cmd, root) end
  end)
end

function M.run_nearest()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = buf_path(bufnr)
  local root = project_root(path)
  if not path or not root then
    notify("Not inside a Maven/Gradle project", vim.log.levels.WARN)
    return
  end

  if not is_test_path(path) then
    notify("Nearest test works in test files. Opening class picker.")
    M.run_class_picker()
    return
  end

  local spec = test_spec_from_path(root, path)
  local method = nil
  if vim.bo[bufnr].filetype == "java" then method = nearest_java_method_name(bufnr) end

  local cmd = command_for_target(root, spec, method)
  if cmd then run_in_split(cmd, root) end
end

return M
