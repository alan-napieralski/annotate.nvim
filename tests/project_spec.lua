local H = require("tests.helpers")

describe("project root resolution", function()
	local project, config, dir

	before_each(function()
		H.reset_modules()
		project = require("annotate.project")
		config = require("annotate.config")
		dir = H.fresh_project()
	end)

	it("falls back to the current working directory without neovim-project", function()
		config.setup({})
		assert.are.equal(dir, project.root())
	end)

	it("uses the neovim-project integration root when available", function()
		config.setup({ project = { integration = "auto" } })
		package.loaded["annotate.integrations.neovim-project"] = {
			root = function()
				return "/tmp/integrated-root"
			end,
		}
		assert.are.equal("/tmp/integrated-root", project.root())
		package.loaded["annotate.integrations.neovim-project"] = nil
	end)

	it("honors a custom root function over everything else", function()
		config.setup({
			project = {
				root = function()
					return dir
				end,
			},
		})
		assert.are.equal(dir, project.root())
	end)

	it("computes a project-relative path", function()
		config.setup({})
		local abs = vim.fs.joinpath(dir, "src", "a.lua")
		assert.are.equal("src/a.lua", project.relative_path(abs))
	end)

	it("resolves a relative path back to absolute", function()
		config.setup({})
		assert.are.equal(vim.fs.joinpath(dir, "src/a.lua"), project.absolute_path("src/a.lua"))
	end)

	it("derives the store path under the configured dir/file", function()
		config.setup({ store = { dir = ".nvim", file = "annotations.json" } })
		assert.are.equal(vim.fs.joinpath(dir, ".nvim", "annotations.json"), project.store_path())
	end)
end)
