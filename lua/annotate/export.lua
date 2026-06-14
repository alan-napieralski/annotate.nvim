local M = {}

local config = require("annotate.config")
local project = require("annotate.project")
local store = require("annotate.store")

local function current_line_text(item)
	local absolute = project.absolute_path(item.path)
	local lines = vim.fn.readfile(absolute)
	return lines[item.line] or item.line_text or ""
end

function M.lines()
	local opts = config.get().export
	local lines = {
		"Project: " .. project.root(),
		"Purpose: Share these annotations with any AI agent or reviewer so they can understand the exact file, line, note, and nearby code context quickly.",
		"",
	}

	for _, item in ipairs(store.list()) do
		lines[#lines + 1] = "File: " .. item.path
		lines[#lines + 1] = "Line: " .. item.line
		lines[#lines + 1] = "Annotation: " .. item.text
		if opts.include_code then
			lines[#lines + 1] = "Code: " .. current_line_text(item)
		end
		lines[#lines + 1] = ""
	end

	return lines
end

function M.text()
	return table.concat(M.lines(), "\n")
end

function M.copy()
	local opts = config.get().export
	local text = M.text()
	if opts.copy_to_plus then
		vim.fn.setreg("+", text)
	end
	if opts.copy_to_unnamed then
		vim.fn.setreg('"', text)
	end
	vim.notify("annotate.nvim: annotations copied for AI handoff", vim.log.levels.INFO)
	return text
end

return M
