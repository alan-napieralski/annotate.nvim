local M = {}

local function project_utils()
	local ok, utils = pcall(require, "neovim-project.utils.path")
	if ok then
		return utils
	end
end

function M.available()
	return project_utils() ~= nil
end

function M.root()
	local utils = project_utils()
	if not utils then
		return
	end

	local root = utils.dir_pretty or utils.cwd()
	if root and root ~= "" then
		return vim.fs.normalize(vim.fn.expand(root))
	end
end

return M
