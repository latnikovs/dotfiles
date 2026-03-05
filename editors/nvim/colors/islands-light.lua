vim.cmd("highlight clear")

if vim.fn.exists("syntax_on") == 1 then
	vim.cmd("syntax reset")
end

vim.o.termguicolors = true
vim.o.background = "light"
vim.g.colors_name = "islands-light"

local c = {
	bg = "#ffffff",
	fg = "#000000",
	comment = "#8c8c8c",
	keyword = "#0033b3",
	string = "#067d17",
	number = "#1750eb",
	func = "#00627a",
	type = "#0f5c9c",
	const = "#0033b3",
	operator = "#1f2328",
	cursorline = "#f5f7fb",
	visual = "#dbe9ff",
	search = "#fff2a8",
	line = "#e9edf3",
	error = "#c7222d",
	warn = "#9f6a00",
	hint = "#00627a",
	info = "#1750eb",
	add = "#1a7f37",
	delete = "#cf222e",
	change = "#9a6700",
	panel = "#f7f8fa",
	cursor = "#1750eb",
	cursor_insert = "#00627a",
}

local set = vim.api.nvim_set_hl

set(0, "Normal", { fg = c.fg, bg = c.bg })
set(0, "NormalFloat", { fg = c.fg, bg = c.panel })
set(0, "FloatBorder", { fg = c.line, bg = c.panel })
set(0, "CursorLine", { bg = c.cursorline })
set(0, "CursorLineNr", { fg = c.func, bold = true })
set(0, "Cursor", { fg = c.bg, bg = c.cursor })
set(0, "lCursor", { fg = c.bg, bg = c.cursor_insert })
set(0, "CursorIM", { fg = c.bg, bg = c.cursor_insert })
set(0, "TermCursor", { fg = c.bg, bg = c.cursor })
set(0, "TermCursorNC", { fg = c.bg, bg = c.comment })
set(0, "LineNr", { fg = c.comment })
set(0, "Visual", { bg = c.visual })
set(0, "Search", { bg = c.search, fg = c.fg })
set(0, "IncSearch", { bg = c.keyword, fg = c.bg })
set(0, "MatchParen", { fg = c.keyword, bold = true })
set(0, "ColorColumn", { bg = c.cursorline })
set(0, "SignColumn", { bg = c.bg })
set(0, "VertSplit", { fg = c.line })
set(0, "WinSeparator", { fg = c.line })
set(0, "Pmenu", { fg = c.fg, bg = c.panel })
set(0, "PmenuSel", { fg = c.fg, bg = c.visual })
set(0, "StatusLine", { fg = c.fg, bg = c.panel })
set(0, "StatusLineNC", { fg = c.comment, bg = c.panel })
set(0, "TabLine", { fg = c.comment, bg = c.panel })
set(0, "TabLineSel", { fg = c.fg, bg = c.bg, bold = true })

set(0, "Comment", { fg = c.comment, italic = true })
set(0, "Keyword", { fg = c.keyword, bold = true })
set(0, "String", { fg = c.string })
set(0, "Number", { fg = c.number })
set(0, "Boolean", { fg = c.number, bold = true })
set(0, "Function", { fg = c.func })
set(0, "Identifier", { fg = c.fg })
set(0, "Type", { fg = c.type })
set(0, "Constant", { fg = c.const })
set(0, "Operator", { fg = c.operator })
set(0, "PreProc", { fg = c.keyword })
set(0, "Statement", { fg = c.keyword })
set(0, "Special", { fg = c.func })

set(0, "@comment", { link = "Comment" })
set(0, "@keyword", { link = "Keyword" })
set(0, "@keyword.return", { link = "Keyword" })
set(0, "@string", { link = "String" })
set(0, "@number", { link = "Number" })
set(0, "@boolean", { link = "Boolean" })
set(0, "@function", { link = "Function" })
set(0, "@function.call", { link = "Function" })
set(0, "@type", { link = "Type" })
set(0, "@constant", { link = "Constant" })
set(0, "@operator", { link = "Operator" })
set(0, "@variable", { fg = c.fg })

set(0, "DiagnosticError", { fg = c.error })
set(0, "DiagnosticWarn", { fg = c.warn })
set(0, "DiagnosticInfo", { fg = c.info })
set(0, "DiagnosticHint", { fg = c.hint })
set(0, "DiagnosticUnderlineError", { undercurl = true, sp = c.error })
set(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = c.warn })
set(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = c.info })
set(0, "DiagnosticUnderlineHint", { undercurl = true, sp = c.hint })

set(0, "DiffAdd", { fg = c.add, bg = "#e8f5e9" })
set(0, "DiffDelete", { fg = c.delete, bg = "#ffebe9" })
set(0, "DiffChange", { fg = c.change, bg = "#fff8c5" })
set(0, "DiffText", { fg = c.change, bg = "#ffef9f", bold = true })

set(0, "GitSignsAdd", { fg = c.add })
set(0, "GitSignsChange", { fg = c.change })
set(0, "GitSignsDelete", { fg = c.delete })
