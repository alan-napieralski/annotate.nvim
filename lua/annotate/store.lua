local M = {}

local project = require("annotate.project")
local uv = vim.uv or vim.loop

local state = {
	project_key = nil,
	annotations = {},
}

local function now()
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function ensure_parent_dir(path)
	local dir = vim.fs.dirname(path)
	if dir and dir ~= "" then
		vim.fn.mkdir(dir, "p")
	end
end

local function annotation_sort(a, b)
	if a.path == b.path then
		if a.line == b.line then
			return (a.id or "") < (b.id or "")
		end
		return a.line < b.line
	end
	return a.path < b.path
end

local function sort_annotations(items)
	table.sort(items, annotation_sort)
	return items
end

local function read_disk()
	local path = project.store_path()
	local fd = uv.fs_open(path, "r", 420)
	if not fd then
		return {}
	end

	local stat = uv.fs_fstat(fd)
	if not stat then
		uv.fs_close(fd)
		return {}
	end

	local data = uv.fs_read(fd, stat.size, 0) or ""
	uv.fs_close(fd)
	if data == "" then
		return {}
	end

	local ok, decoded = pcall(vim.json.decode, data)
	if not ok or type(decoded) ~= "table" then
		vim.notify("annotate.nvim: failed to parse " .. path, vim.log.levels.WARN)
		return {}
	end

	local items = decoded.annotations or decoded
	if type(items) ~= "table" then
		return {}
	end

	local normalized = {}
	for _, item in ipairs(items) do
		if type(item) == "table" and item.id and item.path and item.line and item.text then
			normalized[#normalized + 1] = {
				id = item.id,
				path = item.path,
				line = item.line,
				text = item.text,
				line_text = item.line_text or "",
				context_before = item.context_before or "",
				context_after = item.context_after or "",
				created_at = item.created_at or now(),
				updated_at = item.updated_at or item.created_at or now(),
			}
		end
	end

	return normalized
end

local function write_disk()
	local path = project.store_path()
	ensure_parent_dir(path)

	local payload = {
		project_root = project.root(),
		updated_at = now(),
		annotations = state.annotations,
	}

	local encoded = vim.json.encode(payload)
	local fd = uv.fs_open(path, "w", 420)
	if not fd then
		error("annotate.nvim: failed to open store for writing")
	end
	uv.fs_write(fd, encoded, -1)
	uv.fs_close(fd)
end

local function ensure_loaded()
	local key = project.project_key()
	if state.project_key == key then
		return
	end

	state.project_key = key
	state.annotations = sort_annotations(read_disk())
end

local function copy_annotation(item)
	return vim.deepcopy(item)
end

function M.reload()
	state.project_key = nil
	ensure_loaded()
	return M.list()
end

function M.list()
	ensure_loaded()
	local items = {}
	for _, item in ipairs(state.annotations) do
		items[#items + 1] = copy_annotation(item)
	end
	return items
end

function M.find_by_id(id)
	ensure_loaded()
	for _, item in ipairs(state.annotations) do
		if item.id == id then
			return copy_annotation(item)
		end
	end
end

function M.find_at(path, line)
	ensure_loaded()
	local relative = project.relative_path(path)
	for _, item in ipairs(state.annotations) do
		if item.path == relative and item.line == line then
			return copy_annotation(item)
		end
	end
end

function M.upsert(item)
	ensure_loaded()

	local existing_index
	for index, current in ipairs(state.annotations) do
		if current.id == item.id then
			existing_index = index
			break
		end
	end

	if existing_index then
		local existing = state.annotations[existing_index]
		item.created_at = existing.created_at
		item.updated_at = now()
		state.annotations[existing_index] = item
	else
		item.created_at = item.created_at or now()
		item.updated_at = now()
		state.annotations[#state.annotations + 1] = item
	end

	sort_annotations(state.annotations)
	write_disk()
	return copy_annotation(item)
end

function M.delete(id)
	ensure_loaded()
	for index, item in ipairs(state.annotations) do
		if item.id == id then
			table.remove(state.annotations, index)
			write_disk()
			return copy_annotation(item)
		end
	end
end

function M.replace_all(items)
	ensure_loaded()
	state.annotations = {}
	for _, item in ipairs(items) do
		state.annotations[#state.annotations + 1] = {
			id = item.id,
			path = item.path,
			line = item.line,
			text = item.text,
			line_text = item.line_text or "",
			context_before = item.context_before or "",
			context_after = item.context_after or "",
			created_at = item.created_at or now(),
			updated_at = now(),
		}
	end
	sort_annotations(state.annotations)
	write_disk()
	return M.list()
end

function M.generate_id(path, line)
	local stamp = tostring(uv.hrtime())
	return string.format("%s:%d:%s", path, line, stamp)
end

return M
