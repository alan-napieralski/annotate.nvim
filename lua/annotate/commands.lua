local M = {}

function M.register(api)
	vim.api.nvim_create_user_command("AnnotateAdd", function()
		api.add_or_edit_current()
	end, {})

	vim.api.nvim_create_user_command("AnnotateDelete", function()
		api.delete_current()
	end, {})

	vim.api.nvim_create_user_command("AnnotateList", function()
		api.open_list()
	end, {})

	vim.api.nvim_create_user_command("AnnotateCopy", function()
		api.copy_annotations()
	end, {})

	vim.api.nvim_create_user_command("AnnotateToggleInline", function()
		api.toggle_inline()
	end, {})

	vim.api.nvim_create_user_command("AnnotateRefresh", function()
		api.refresh_store()
	end, {})

	vim.api.nvim_create_user_command("AnnotationAdd", function()
		vim.cmd("AnnotateAdd")
	end, {})

	vim.api.nvim_create_user_command("AnnotationDelete", function()
		vim.cmd("AnnotateDelete")
	end, {})

	vim.api.nvim_create_user_command("AnnotationList", function()
		vim.cmd("AnnotateList")
	end, {})

	vim.api.nvim_create_user_command("AnnotationsCopy", function()
		vim.cmd("AnnotateCopy")
	end, {})

	vim.api.nvim_create_user_command("AnnotationsToggleInline", function()
		vim.cmd("AnnotateToggleInline")
	end, {})

	vim.api.nvim_create_user_command("AnnotationsRefresh", function()
		vim.cmd("AnnotateRefresh")
	end, {})
end

return M
