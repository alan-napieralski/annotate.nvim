local M = {}

local commands = require("annotate.commands")
local config = require("annotate.config")
local export = require("annotate.export")
local project = require("annotate.project")
local render = require("annotate.render")
local store = require("annotate.store")
local ui = require("annotate.ui")

local group = vim.api.nvim_create_augroup("annotate-nvim", { clear = true })
local setup_complete = false

local function line_context(lines, line)
	return {
		current = lines[line] or "",
		before = lines[line - 1] or "",
		after = lines[line + 1] or "",
	}
end

local function line_items_for_buffer(bufnr)
	local absolute = vim.api.nvim_buf_get_name(bufnr)
	if absolute == "" then
		return {}
	end

	local relative = project.relative_path(absolute)
	local items = {}
	for _, item in ipairs(store.list()) do
		if item.path == relative then
			items[#items + 1] = item
		end
	end
	return items
end

local function apply_keymaps()
	local keymaps = config.get().keymaps or {}
	for lhs, rhs in pairs(keymaps) do
		if type(rhs) == "function" then
			vim.keymap.set("n", lhs, rhs, { silent = true })
		elseif type(rhs) == "table" and rhs.action then
			vim.keymap.set("n", lhs, rhs.action, vim.tbl_extend("force", { silent = true }, rhs.opts or {}))
		end
	end
end

function M.refresh_buffer(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if vim.bo[bufnr].buftype ~= "" then
		return
	end
	render.render(bufnr, line_items_for_buffer(bufnr))
end

function M.refresh_all_buffers()
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			M.refresh_buffer(bufnr)
		end
	end
end

function M.add_or_edit_current()
	local bufnr = vim.api.nvim_get_current_buf()
	local absolute = vim.api.nvim_buf_get_name(bufnr)
	if absolute == "" then
		vim.notify("annotate.nvim: buffer has no file path", vim.log.levels.WARN)
		return
	end

	local line = vim.api.nvim_win_get_cursor(0)[1]
	local existing = store.find_at(absolute, line)
	vim.ui.input({
		prompt = existing and "Edit annotation: " or "Add annotation: ",
		default = existing and existing.text or "",
	}, function(input)
		if input == nil then
			return
		end

		if vim.trim(input) == "" then
			if existing then
				store.delete(existing.id)
				M.refresh_all_buffers()
				ui.refresh()
			end
			return
		end

		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local ctx = line_context(lines, line)
		local relative = project.relative_path(absolute)
		store.upsert({
			id = existing and existing.id or store.generate_id(relative, line),
			path = relative,
			line = line,
			text = input,
			line_text = ctx.current,
			context_before = ctx.before,
			context_after = ctx.after,
			created_at = existing and existing.created_at or nil,
		})
		M.refresh_all_buffers()
		ui.refresh()
	end)
end

function M.delete_current()
	local absolute = vim.api.nvim_buf_get_name(0)
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local existing = store.find_at(absolute, line)
	if not existing then
		vim.notify("annotate.nvim: no annotation on this line", vim.log.levels.INFO)
		return
	end

	store.delete(existing.id)
	M.refresh_all_buffers()
	ui.refresh()
end

function M.open_list()
	ui.open()
end

function M.copy_annotations()
	return export.copy()
end

function M.toggle_inline()
	local enabled = render.toggle_inline()
	M.refresh_all_buffers()
	vim.notify(enabled and "annotate.nvim: inline view enabled" or "annotate.nvim: inline view hidden", vim.log.levels.INFO)
end

function M.refresh_store()
	store.reload()
	M.refresh_all_buffers()
	ui.refresh()
end

function M.setup(opts)
	config.setup(opts)
	render.set_inline(config.get().inline.enabled)

	if setup_complete then
		M.refresh_store()
		return
	end

	commands.register(M)

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "BufWritePost", "TextChanged", "TextChangedI", "VimResized", "WinResized" }, {
		group = group,
		callback = function(args)
			if args.buf and args.buf ~= 0 then
				M.refresh_buffer(args.buf)
			else
				M.refresh_all_buffers()
			end
		end,
	})

	if config.get().project.reload_on_session_load then
		vim.api.nvim_create_autocmd("User", {
			group = group,
			pattern = "SessionLoadPost",
			callback = function()
				store.reload()
				M.refresh_all_buffers()
				ui.refresh()
			end,
		})
	end

	apply_keymaps()
	store.reload()
	M.refresh_all_buffers()
	setup_complete = true
end

return M
