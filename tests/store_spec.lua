local H = require("tests.helpers")

describe("store", function()
	local store, config, project, dir

	before_each(function()
		H.reset_modules()
		store = require("annotate.store")
		config = require("annotate.config")
		project = require("annotate.project")
		dir = H.fresh_project()
		config.setup({})
	end)

	it("returns an empty list when no store file exists", function()
		assert.are.same({}, store.reload())
	end)

	it("parses an existing store file on disk", function()
		H.write_file(
			project.store_path(),
			vim.json.encode({
				project_root = dir,
				annotations = {
					{ id = "src/a.lua:1:1", path = "src/a.lua", line = 1, text = "note one" },
				},
			})
		)
		local items = store.reload()
		assert.are.equal(1, #items)
		assert.are.equal("note one", items[1].text)
		assert.are.equal("src/a.lua", items[1].path)
	end)

	it("drops malformed entries that are missing required fields", function()
		H.write_file(
			project.store_path(),
			vim.json.encode({
				annotations = {
					{ id = "ok:1:1", path = "ok.lua", line = 1, text = "valid" },
					{ path = "missing-id.lua", line = 2, text = "no id" },
				},
			})
		)
		local items = store.reload()
		assert.are.equal(1, #items)
		assert.are.equal("valid", items[1].text)
	end)

	it("round-trips an upsert through disk", function()
		store.upsert({
			id = "src/a.lua:5:5",
			path = "src/a.lua",
			line = 5,
			text = "written note",
		})

		-- Force a fresh read from disk rather than in-memory state.
		H.reset_modules()
		store = require("annotate.store")
		require("annotate.config").setup({})
		local items = store.reload()

		assert.are.equal(1, #items)
		assert.are.equal("written note", items[1].text)
		assert.is_string(items[1].created_at)
		assert.is_string(items[1].updated_at)
	end)

	it("replace_all overwrites the entire set and persists it", function()
		store.upsert({ id = "a:1:1", path = "a.lua", line = 1, text = "first" })
		store.replace_all({
			{ id = "b:2:2", path = "b.lua", line = 2, text = "second" },
		})

		local items = store.list()
		assert.are.equal(1, #items)
		assert.are.equal("second", items[1].text)

		-- Persisted to disk too.
		local decoded = vim.json.decode(H.read_file(project.store_path()))
		assert.are.equal(1, #decoded.annotations)
		assert.are.equal("second", decoded.annotations[1].text)
	end)

	it("deletes by id and persists the removal", function()
		store.upsert({ id = "a:1:1", path = "a.lua", line = 1, text = "keep" })
		store.upsert({ id = "b:2:2", path = "b.lua", line = 2, text = "remove" })
		store.delete("b:2:2")

		local items = store.list()
		assert.are.equal(1, #items)
		assert.are.equal("keep", items[1].text)
	end)

	it("sorts annotations by path then line", function()
		store.replace_all({
			{ id = "b:2:2", path = "b.lua", line = 2, text = "b2" },
			{ id = "a:9:9", path = "a.lua", line = 9, text = "a9" },
			{ id = "a:1:1", path = "a.lua", line = 1, text = "a1" },
		})
		local items = store.list()
		assert.are.same({ "a1", "a9", "b2" }, { items[1].text, items[2].text, items[3].text })
	end)
end)
