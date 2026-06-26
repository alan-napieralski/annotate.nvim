.PHONY: test

# Run the plenary.nvim test suite headlessly.
# Override the plenary location with: make test PLENARY_DIR=/path/to/plenary.nvim
test:
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"
