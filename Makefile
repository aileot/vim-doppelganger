.PHONY: test plenary busted lua_version

lua_version:
	nvim --noplugin -u NONE --headless -c "lua print(_VERSION)" -c 'q!'
	@echo

t_plenary: lua_version
	nvim --headless --noplugin -u ./test/plenary/minimal.vim

t_themis:
	THEMIS_VIM=nvim themis --reporter dot

test: t_plenary t_themis
	#

