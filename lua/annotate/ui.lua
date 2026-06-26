local M = {}

local config = require("annotate.config")
local export = require("annotate.export")
local project = require("annotate.project")
local store = require("annotate.store")

local state = {
	bufnr = nil,
	winid = nil,
}

local function format_item(item)
	return string.format("%s:%d | %s", item.path, item.line, item.text)
end

local function parse_line(line)
	local path, lineno, text = line:match("^(.-):(%d+)%s+|%s*(.*)$")
	if not path or not lineno then
		return
	end
	return {
		path = path,
		line = tonumber(lineno),
		text = text,
	}
end

local function collect_items_from_buffer(bufnr)
	local previous = vim.b[bufnr].annotate_items or {}
	local previous_by_key = {}
	for _, item in pairs(previous) do
		previous_by_key[string.format("%s:%d", item.path, item.line)] = item
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local items = {}
	for _, line in ipairs(lines) do
		if line ~= "" then
			local parsed = parse_line(line)
			if parsed then
				local key = string.format("%s:%d", parsed.path, parsed.line)
				local previous_item = previous_by_key[key]
				items[#items + 1] = {
					id = previous_item and previous_item.id or store.generate_id(parsed.path, parsed.line),
					path = parsed.path,
					line = parsed.line,
					text = parsed.text,
					line_text = previous_item and previous_item.line_text or "",
					context_before = previous_item and previous_item.context_before or "",
					context_after = previous_item and previous_item.context_after or "",
					created_at = previous_item and previous_item.created_at or nil,
				}
			end
		end
	end

	return items
end

local function ensure_buffer()
	if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
		return state.bufnr
	end

	-- Reuse the named buffer if it already exists (e.g. after a plugin reload
	-- that dropped our module state) instead of failing with E95.
	local existing = vim.fn.bufnr("annotate://list")
	if existing ~= -1 and vim.api.nvim_buf_is_valid(existing) then
		state.bufnr = existing
		return existing
	end

	local bufnr = vim.api.nvim_create_buf(false, true)
	state.bufnr = bufnr

	-- An acwrite buffer needs a name, otherwise `:w` aborts with E32 before
	-- BufWriteCmd fires and edits (e.g. `dd` to delete an entry) are lost.
	vim.api.nvim_buf_set_name(bufnr, "annotate://list")
	vim.bo[bufnr].buftype = "acwrite"
	vim.bo[bufnr].bufhidden = "hide"
	vim.bo[bufnr].swapfile = false
	vim.bo[bufnr].filetype = "annotate"

	vim.api.nvim_buf_create_user_command(bufnr, "AnnotateCopy", function()
		export.copy()
	end, {})

	local group = vim.api.nvim_create_augroup("annotate-nvim-ui", { clear = false })
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		group = group,
		buffer = bufnr,
		callback = function()
			M.sync_from_buffer()
		end,
	})
	vim.api.nvim_create_autocmd("BufWinLeave", {
		group = group,
		buffer = bufnr,
		callback = function()
			state.winid = nil
		end,
	})

	return bufnr
end

local function close_window()
	if config.get().ui.save_on_close and state.bufnr and vim.bo[state.bufnr].modified then
		M.sync_from_buffer({ silent = true })
	end
	if state.winid and vim.api.nvim_win_is_valid(state.winid) then
		vim.api.nvim_win_close(state.winid, true)
	end
	state.winid = nil
end

function M.refresh()
	local bufnr = ensure_buffer()
	local items = store.list()
	local lines = {}
	for _, item in ipairs(items) do
		lines[#lines + 1] = format_item(item)
	end

	vim.bo[bufnr].modifiable = true
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.bo[bufnr].modifiable = false

	local metadata = {}
	for index, item in ipairs(items) do
		metadata[index] = item
	end
	vim.b[bufnr].annotate_items = metadata
end

function M.sync_from_buffer(opts)
	opts = opts or {}
	local bufnr = ensure_buffer()
	local items = collect_items_from_buffer(bufnr)
	store.replace_all(items)
	M.refresh()
	vim.bo[bufnr].modifiable = true
	vim.bo[bufnr].modified = false
	if not opts.silent then
		vim.notify("annotate.nvim: annotations saved", vim.log.levels.INFO)
	end
end

function M.open()
	local bufnr = ensure_buffer()
	local opts = config.get().ui
	M.refresh()

	if state.winid and vim.api.nvim_win_is_valid(state.winid) then
		vim.api.nvim_set_current_win(state.winid)
		return
	end

	local width = math.floor(vim.o.columns * opts.width)
	local height = math.max(10, math.floor(vim.o.lines * opts.height))
	state.winid = vim.api.nvim_open_win(bufnr, true, {
		relative = "editor",
		row = math.floor((vim.o.lines - height) / 2) - 1,
		col = math.floor((vim.o.columns - width) / 2),
		width = width,
		height = height,
		style = "minimal",
		border = opts.border,
		title = opts.title,
		title_pos = "center",
	})

	vim.bo[bufnr].modifiable = true
	if config.get().ui.save_on_close then
		vim.notify("Use :w to save annotation list edits. q or <Esc> will save and close.", vim.log.levels.INFO)
	else
		vim.notify("Use :w to save annotation list edits. q or <Esc> will close without saving.", vim.log.levels.INFO)
	end
	vim.keymap.set("n", "<CR>", function()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local item = (vim.b[bufnr].annotate_items or {})[line]
		if not item then
			return
		end
		local absolute = project.absolute_path(item.path)
		vim.cmd("edit " .. vim.fn.fnameescape(absolute))
		vim.api.nvim_win_set_cursor(0, { item.line, 0 })
	end, { buffer = bufnr, silent = true })
	vim.keymap.set("n", "<Esc>", close_window, { buffer = bufnr, silent = true })
	vim.keymap.set("n", "q", close_window, { buffer = bufnr, silent = true })
	vim.keymap.set("n", "yy", function()
		export.copy()
	end, { buffer = bufnr, silent = true })
end

return M
