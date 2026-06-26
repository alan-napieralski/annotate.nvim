-- Minimal init for running the test suite with plenary.nvim.
-- Resolves plenary from common plugin-manager locations, then puts this
-- plugin on the runtimepath.

local function first_existing(paths)
	for _, path in ipairs(paths) do
		if vim.fn.isdirectory(vim.fn.expand(path)) == 1 then
			return vim.fn.expand(path)
		end
	end
end

local plenary = os.getenv("PLENARY_DIR")
	or first_existing({
		"~/.local/share/nvim/lazy/plenary.nvim",
		"~/.local/share/nvim/site/pack/packer/start/plenary.nvim",
		"~/.config/nvim/pack/vendor/start/plenary.nvim",
	})

if not plenary then
	error("plenary.nvim not found; set PLENARY_DIR to its path")
end

-- Plugin root is the parent of this tests/ directory.
local plugin_root = vim.fn.fnamemodify(vim.fn.expand("<sfile>:p"), ":h:h")

vim.opt.runtimepath:append(plenary)
vim.opt.runtimepath:append(plugin_root)
vim.opt.swapfile = false

-- Register PlenaryBustedDirectory / PlenaryBustedFile commands.
vim.cmd("runtime plugin/plenary.vim")
