local M = {}

local defaults = {
	project = {
		integration = "auto",
		root = nil,
		reload_on_session_load = true,
	},
	store = {
		dir = ".nvim",
		file = "annotations.json",
	},
	signs = {
		enabled = true,
		text = "󰋼",
		hl = "DiagnosticHint",
		priority = 40,
	},
	inline = {
		enabled = false,
		icon = "󰋼",
		hl = "Comment",
	},
	ui = {
		float = true,
		width = 0.6,
		height = 0.6,
		border = "rounded",
		title = " Annotate ",
	},
	export = {
		copy_to_plus = true,
		copy_to_unnamed = true,
		include_code = true,
	},
	keymaps = {},
}

local state = {
	options = vim.deepcopy(defaults),
}

function M.setup(opts)
	state.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
	return state.options
end

function M.get()
	return state.options
end

return M
