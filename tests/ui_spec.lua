local H = require("tests.helpers")

describe("manager list parsing and save", function()
	local ui, store, config, dir

	local function manager_bufnr()
		return vim.fn.bufnr("annotate://list")
	end

	local function set_buffer_lines(bufnr, lines)
		vim.bo[bufnr].modifiable = true
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	end

	before_each(function()
		H.reset_modules()
		ui = require("annotate.ui")
		store = require("annotate.store")
		config = require("annotate.config")
		dir = H.fresh_project()
		config.setup({})
		store.replace_all({
			{ id = "a.lua:1:1", path = "a.lua", line = 1, text = "first" },
			{ id = "b.lua:2:2", path = "b.lua", line = 2, text = "second" },
		})
	end)

	it("renders each annotation as `path:line | text`", function()
		ui.refresh()
		local lines = vim.api.nvim_buf_get_lines(manager_bufnr(), 0, -1, false)
		assert.are.same({ "a.lua:1 | first", "b.lua:2 | second" }, lines)
	end)

	it("persists a deleted line on save", function()
		ui.refresh()
		local bufnr = manager_bufnr()
		set_buffer_lines(bufnr, { "a.lua:1 | first" })
		ui.sync_from_buffer({ silent = true })

		local items = store.list()
		assert.are.equal(1, #items)
		assert.are.equal("first", items[1].text)
	end)

	it("persists edited annotation text on save", function()
		ui.refresh()
		local bufnr = manager_bufnr()
		set_buffer_lines(bufnr, { "a.lua:1 | edited text", "b.lua:2 | second" })
		ui.sync_from_buffer({ silent = true })

		local items = store.list()
		assert.are.equal(2, #items)
		assert.are.equal("edited text", items[1].text)
	end)

	it("ignores malformed lines that do not parse", function()
		ui.refresh()
		local bufnr = manager_bufnr()
		set_buffer_lines(bufnr, { "this is not a valid annotation line", "a.lua:1 | first" })
		ui.sync_from_buffer({ silent = true })

		local items = store.list()
		assert.are.equal(1, #items)
		assert.are.equal("first", items[1].text)
	end)

	it("preserves the id of a kept entry across a save", function()
		ui.refresh()
		local bufnr = manager_bufnr()
		set_buffer_lines(bufnr, { "a.lua:1 | first edited" })
		ui.sync_from_buffer({ silent = true })

		local items = store.list()
		assert.are.equal("a.lua:1:1", items[1].id)
	end)
end)
