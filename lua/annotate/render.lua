local M = {}

local config = require("annotate.config")
local ns = vim.api.nvim_create_namespace("annotate-nvim-signs")
local state = {
	inline_enabled = false,
}

function M.clear(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

function M.render(bufnr, annotations)
	local opts = config.get()
	M.clear(bufnr)

	for _, item in ipairs(annotations) do
		local line_text = vim.api.nvim_buf_get_lines(bufnr, item.line - 1, item.line, false)[1] or ""
		local extmark = {
			priority = opts.signs.priority,
		}

		if opts.signs.enabled then
			extmark.sign_text = opts.signs.text
			extmark.sign_hl_group = opts.signs.hl
		end

		if state.inline_enabled then
			extmark.virt_text = { { " " .. opts.inline.icon .. " " .. item.text, opts.inline.hl } }
			extmark.virt_text_pos = "inline"
			extmark.virt_text_repeat_linebreak = true
		end

		vim.api.nvim_buf_set_extmark(bufnr, ns, item.line - 1, #line_text, extmark)
	end
end

function M.set_inline(enabled)
	state.inline_enabled = not not enabled
	return state.inline_enabled
end

function M.toggle_inline()
	state.inline_enabled = not state.inline_enabled
	return state.inline_enabled
end

function M.inline_enabled()
	return state.inline_enabled
end

return M
