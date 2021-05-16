local g = vim.g
local fn = vim.fn
local cmd = vim.cmd
local cache_manager = require('doppelganger.cache.cache_manager').register('haunted_cursor')

--- Convert relative offset into absolute row.
local apparent_top = function(std_row, offset)
  local min = fn.line('w0')
  local row = std_row
  local cnt = offset

  while cnt > 0 and row > min do
    local foldstart = fn.foldclosed(row)
    row = foldstart == -1 and row - 1 or foldstart - 1
    cnt = cnt - 1
  end

  return row
end

--- Convert relative offset into absolute row.
local apparent_bottom = function(std_row, offset)
  local max = fn.line('w$')
  local row = std_row
  local cnt = offset

  while cnt > 0 and row < max do
    local foldend = fn.foldclosedend(row)
    row = foldend == -1 and row + 1 or foldend + 1
    cnt = cnt - 1
  end

  local foldstart = fn.foldclosed(row)
  return foldstart == -1 and row or foldstart
end


local M = {}

M.update = function()
  local current_row = fn.line('.')
  local offset = g['doppelganger#ego#max_offset']

  local wn = fn.winnr()
  local cache = cache_manager:attach(wn)
  local range = cache:at(current_row):restore('range')
  local top, bottom
  if range then
    top    = range[1]
    bottom = range[2]
  else
    top    = apparent_top(current_row, offset)
    bottom = apparent_bottom(current_row, offset)
    cache:at(current_row):update('range', { top, bottom })
  end

  local min_range = g['doppelganger#ego#min_range_of_pairs']
  fn['doppelganger#update'](top, bottom, min_range)
  return {top, bottom, min_range}
end


M.cache_manager = cache_manager
cmd("augroup doppelganger/cache/haunted_cursor")
cmd("autocmd!")
cmd([[autocmd TextChanged,TextChangedI,TextChangedP * lua require('doppelganger.haunted.cursor').cache_manager:attach(vim.fn.winnr()):drop('range')]])
cmd([[autocmd FileChangedShellPost * lua require('doppelganger.haunted.cursor').cache_manager:clear('range')]])
cmd("augroup END")


return M
