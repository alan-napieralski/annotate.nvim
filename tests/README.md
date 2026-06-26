# Tests

Automated tests for `annotate.nvim`, written with
[plenary.nvim](https://github.com/nvim-lua/plenary.nvim)'s busted runner.

## Running

```sh
make test
```

If plenary lives somewhere non-standard, point the runner at it:

```sh
make test PLENARY_DIR=/path/to/plenary.nvim
```

The runner uses `tests/minimal_init.lua`, which locates plenary, puts this
plugin on the runtimepath, and registers the `PlenaryBusted*` commands.

## Coverage

- `project_spec.lua` — project root resolution (cwd fallback, `neovim-project`
  integration, custom root function) plus relative/absolute/store path mapping
- `store_spec.lua` — JSON store parsing, malformed-entry handling, upsert /
  replace_all / delete round-trips through disk, and sort order
- `ui_spec.lua` — manager list rendering, line parsing, and save behavior
  (deletions, edits, malformed lines, id preservation)
- `export_spec.lua` — AI handoff export formatting and register copying
