-- Shared helpers for the annotate.nvim test suite.

local H = {}

-- Create a fresh temporary directory and make it the current working dir, so
-- project root resolution falls back to it and the store lives under it.
function H.fresh_project()
	local dir = vim.fn.tempname()
	vim.fn.mkdir(dir, "p")
	vim.cmd("cd " .. vim.fn.fnameescape(dir))
	-- Return the resolved cwd (tempname may sit under a symlink such as
	-- /var -> /private/var on macOS) so it matches project.root().
	return vim.fs.normalize((vim.uv or vim.loop).cwd())
end

-- Reload all annotate modules so cached config/state never leak between specs.
function H.reset_modules()
	for name in pairs(package.loaded) do
		if name:match("^annotate") then
			package.loaded[name] = nil
		end
	end
end

-- Write a string to a file, creating parent directories.
function H.write_file(path, contents)
	local dir = vim.fs.dirname(path)
	if dir and dir ~= "" then
		vim.fn.mkdir(dir, "p")
	end
	local fd = assert(io.open(path, "w"))
	fd:write(contents)
	fd:close()
end

-- Read a file into a string, or nil if it does not exist.
function H.read_file(path)
	local fd = io.open(path, "r")
	if not fd then
		return nil
	end
	local contents = fd:read("*a")
	fd:close()
	return contents
end

return H
