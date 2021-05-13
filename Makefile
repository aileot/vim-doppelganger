.PHONY: test plenary busted lua_version

clone_themis:
	@ls vim-themis || git clone --depth=1 https://github.com/thinca/vim-themis

clone_plenary:
	@ls plenary.nvim || \
		git clone --depth=1 https://github.com/nvim-lua/plenary.nvim

lua_version:
	nvim --noplugin -u NONE --headless -c "lua print(_VERSION)" -c 'q!'
	@echo

t_plenary: clone_plenary lua_version
	nvim --headless --noplugin -u test/plenary/minimal.vim \
		-c "PlenaryBustedDirectory test/plenary/ {minimal_init = 'test/plenary/minimal.vim'}"

t_themis: clone_themis
	THEMIS_VIM=nvim themis --reporter dot

test: t_plenary t_themis
	#

