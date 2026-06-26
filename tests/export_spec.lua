local H = require("tests.helpers")

describe("export formatting", function()
	local export, store, config, project, dir

	before_each(function()
		H.reset_modules()
		export = require("annotate.export")
		store = require("annotate.store")
		config = require("annotate.config")
		project = require("annotate.project")
		dir = H.fresh_project()
		config.setup({})
		H.write_file(vim.fs.joinpath(dir, "src", "a.lua"), "local a = 1\nlocal b = 2\n")
		store.replace_all({
			{ id = "src/a.lua:2:2", path = "src/a.lua", line = 2, text = "explain this" },
		})
	end)

	it("includes project, file, line, annotation and code", function()
		local text = export.text()
		assert.is_truthy(text:find("Project: " .. dir, 1, true))
		assert.is_truthy(text:find("File: src/a.lua", 1, true))
		assert.is_truthy(text:find("Line: 2", 1, true))
		assert.is_truthy(text:find("Annotation: explain this", 1, true))
		assert.is_truthy(text:find("Code: local b = 2", 1, true))
	end)

	it("omits the code line when include_code is false", function()
		config.setup({ export = { include_code = false } })
		local text = export.text()
		assert.is_truthy(text:find("Annotation: explain this", 1, true))
		assert.is_nil(text:find("Code:", 1, true))
	end)

	it("copies the export into the requested registers", function()
		config.setup({ export = { copy_to_plus = true, copy_to_unnamed = true, include_code = true } })
		local returned = export.copy()
		assert.are.equal(returned, vim.fn.getreg('"'))
		assert.is_truthy(vim.fn.getreg('"'):find("Annotation: explain this", 1, true))
	end)
end)
