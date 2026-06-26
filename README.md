# annotate.nvim

Attach notes to lines of code without touching the file.

`annotate.nvim` stores annotations outside your source files, keeps them scoped per project, lets you manage them in an editable buffer, and gives you a one-command plain-text export you can paste into any AI agent or code review workflow.

That export is the core idea: you can annotate exactly where and why something matters, then copy the full context with file paths, line numbers, annotation text, and code snippets so an AI reviewer can understand the request immediately without relying on one specific harness or comment system.

> [!NOTE]
> `annotate.nvim` is in **beta testing**. Expect rough edges. If you hit a bug or
> have an idea, please [open an issue](https://github.com/alan-napieralski/annotate.nvim/issues)
> or send a pull request — feedback and contributions are very welcome.

## Features

- Add or edit annotations on the current line
- Keep annotations out of your real code files
- Store annotations per project in `<project-root>/.nvim/annotations.json`
- Manage annotations in an editable floating buffer
- Delete entries with normal Vim motions, then save with `:w`
- Show sign markers in the sign column
- Toggle inline annotation text in code buffers
- Copy a structured export for AI handoff or human review
- Optionally integrate with [`coffebar/neovim-project`](https://github.com/coffebar/neovim-project)
- Fall back to the current working directory when `neovim-project` is not installed

## Why this exists

Most annotation flows either:

- modify the source file directly
- act like bookmarks first and notes second
- or stop at in-editor navigation

`annotate.nvim` is designed for a different workflow:

1. mark exact lines in real code
2. explain what matters
3. export the notes as plain text
4. hand them to any AI agent or reviewer with the relevant context already attached

That makes it useful for:

- AI code review prompts
- handoff notes
- implementation guidance
- refactor planning
- review passes you do not want committed into source comments

## Installation

### lazy.nvim

```lua
{
  "alan-napieralski/annotate.nvim",
  config = function()
    require("annotate").setup()
  end,
}
```

### Local development

```lua
{
  dir = "/path/to/annotate.nvim",
  name = "annotate.nvim",
  config = function()
    require("annotate").setup()
  end,
}
```

### With `coffebar/neovim-project`

`annotate.nvim` does not require `neovim-project`, but it integrates with it automatically by default when the plugin is installed.

```lua
{
  "alan-napieralski/annotate.nvim",
  dependencies = {
    "coffebar/neovim-project",
  },
  config = function()
    require("annotate").setup({
      project = {
        integration = "auto",
      },
    })
  end,
}
```

## Setup

```lua
require("annotate").setup({
  project = {
    integration = "auto",
    reload_on_session_load = true,
  },
  store = {
    dir = ".nvim",
    file = "annotations.json",
  },
  signs = {
    enabled = true,
    text = "󰋼",
    hl = "DiagnosticHint",
    priority = 40,
  },
  inline = {
    enabled = false,
    icon = "󰋼",
    hl = "Comment",
  },
  ui = {
    width = 0.6,
    height = 0.6,
    border = "rounded",
    title = " Annotate ",
    -- When true, closing the manager with q or <Esc> saves pending edits
    -- (e.g. entries deleted with dd). When false, q/<Esc> discard them and
    -- only :w saves.
    save_on_close = false,
  },
  export = {
    copy_to_plus = true,
    copy_to_unnamed = true,
    include_code = true,
  },
  keymaps = {
    ["<leader>na"] = {
      action = function()
        require("annotate").add_or_edit_current()
      end,
      opts = { desc = "Add annotation" },
    },
  },
})
```

## Commands

- `:AnnotateAdd`
- `:AnnotateDelete`
- `:AnnotateList`
- `:AnnotateCopy`
- `:AnnotateRefresh`
- `:AnnotateToggleInline`

Compatibility aliases are also included for the earlier command names:

- `:AnnotationAdd`
- `:AnnotationDelete`
- `:AnnotationList`
- `:AnnotationsCopy`
- `:AnnotationsRefresh`
- `:AnnotationsToggleInline`

## Suggested keymaps

The plugin does not define default keymaps on its own.

```lua
require("annotate").setup({
  keymaps = {
    ["<leader>na"] = {
      action = function()
        require("annotate").add_or_edit_current()
      end,
      opts = { desc = "Add annotation" },
    },
    ["<leader>nd"] = {
      action = function()
        require("annotate").delete_current()
      end,
      opts = { desc = "Delete annotation" },
    },
    ["<leader>nl"] = {
      action = function()
        require("annotate").open_list()
      end,
      opts = { desc = "List annotations" },
    },
    ["<leader>nc"] = {
      action = function()
        require("annotate").copy_annotations()
      end,
      opts = { desc = "Copy annotations" },
    },
    ["<leader>nv"] = {
      action = function()
        require("annotate").toggle_inline()
      end,
      opts = { desc = "Toggle inline annotations" },
    },
  },
})
```

## Manager buffer

Use `:AnnotateList` to open the manager.

Each line is rendered as:

```text
path/to/file.lua:42 | explain why this line matters
```

Inside the manager:

- edit text directly
- delete entries with normal Vim motions like `dd`
- press `:w` to save
- press `<CR>` to jump to the selected file and line
- press `yy` to copy the AI handoff export
- press `q` or `<Esc>` to close without saving (or to save and close, if `ui.save_on_close = true`)

## AI export

Use `:AnnotateCopy` to copy the current project’s annotations into the clipboard.

The export is plain text and includes:

- project root
- file path
- line number
- annotation text
- current code line

Example:

```text
Project: /path/to/your-project
Purpose: Share these annotations with any AI agent or reviewer so they can understand the exact file, line, note, and nearby code context quickly.

File: src/theme/typography.ts
Line: 52
Annotation: rename this helper so it describes the default app font role
Code: export function appText(size: number, weight: FontWeight = "bold") {
```

This is intentionally generic so you can paste it into any AI coding assistant or review tool.

## Project behavior

### With `coffebar/neovim-project`

If `neovim-project` is available, `annotate.nvim` uses its active project root to decide where annotations live. It also reloads after `SessionLoadPost` so annotations follow project/session changes more naturally.

### Without `coffebar/neovim-project`

If `neovim-project` is not installed, the plugin falls back to the current working directory.

That means the store path is still:

```text
<resolved-root>/.nvim/annotations.json
```

The only difference is how the root is chosen.

## Storage

Annotations are stored outside code files in:

```text
<project-root>/.nvim/annotations.json
```

This keeps the workflow:

- local
- explicit
- easy to inspect
- easy to ignore with Git if you do not want annotation files committed

## Development

Run the test suite with [plenary.nvim](https://github.com/nvim-lua/plenary.nvim):

```sh
make test
```

See [`tests/README.md`](tests/README.md) for details.

## Roadmap

- richer code context export options
- Telescope picker integration
- smarter relocation when line numbers drift after edits
- additional project manager integrations

## License

MIT
