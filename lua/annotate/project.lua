local M = {}

local config = require("annotate.config")
local uv = vim.uv or vim.loop

local function normalize(path)
	return vim.fs.normalize(path)
end

local function cwd_root()
	local cwd = uv.cwd()
	if cwd and cwd ~= "" then
		return normalize(cwd)
	end

	return normalize(vim.fn.getcwd())
end

local function integrated_root()
	local ok, integration = pcall(require, "annotate.integrations.neovim-project")
	if not ok then
		return
	end

	return integration.root()
end

function M.root()
	local opts = config.get().project or {}

	if type(opts.root) == "function" then
		local ok, resolved = pcall(opts.root)
		if ok and resolved and resolved ~= "" then
			return normalize(vim.fn.expand(resolved))
		end
	end

	local mode = opts.integration or "auto"
	if mode == "auto" or mode == "neovim-project" then
		local root = integrated_root()
		if root then
			return root
		end
	end

	return cwd_root()
end

function M.project_key()
	return M.root()
end

function M.relative_path(path)
	local root = M.root()
	local normalized = normalize(path)
	if normalized:sub(1, #root) == root then
		local relative = normalized:sub(#root + 2)
		if relative ~= "" then
			return relative
		end
	end
	return vim.fs.basename(normalized)
end

function M.absolute_path(path)
	if vim.startswith(path, "/") then
		return normalize(path)
	end
	return normalize(vim.fs.joinpath(M.root(), path))
end

function M.store_dir()
	local store = config.get().store or {}
	return vim.fs.joinpath(M.root(), store.dir or ".nvim")
end

function M.store_path()
	local store = config.get().store or {}
	return vim.fs.joinpath(M.store_dir(), store.file or "annotations.json")
end

return M
