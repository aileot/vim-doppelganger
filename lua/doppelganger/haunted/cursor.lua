local vim = vim

local haunted_cursor = {}

--- Convert relative offset into absolute row.
local apparent_top = function(std_row, offset)
  local min = vim.fn.line('w0')
  local row = std_row
  local cnt = offset

  while cnt > 0 and row > min do
    local foldstart = vim.fn.foldclosed(row)
    row = foldstart == -1 and row - 1 or foldstart - 1
    cnt = cnt - 1
  end

  return row
end

--- Convert relative offset into absolute row.
local apparent_bottom = function(std_row, offset)
  local max = vim.fn.line('w$')
  local row = std_row
  local cnt = offset

  while cnt > 0 and row < max do
    local foldend = vim.fn.foldclosedend(row)
    row = foldend == -1 and row + 1 or foldend + 1
    cnt = cnt - 1
  end

  local foldstart = vim.fn.foldclosed(row)
  return foldstart == -1 and row or foldstart
end

function haunted_cursor.update()
  local current_row = vim.fn.line('.')
  local offset = vim.g['doppelganger#ego#max_offset']
  local top    = apparent_top(current_row, offset)
  local bottom = apparent_bottom(current_row, offset)

  local min_range = vim.g['doppelganger#ego#min_range_of_pairs']
  vim.fn['doppelganger#update'](top, bottom, min_range)
  return {top, bottom, min_range}
end

return haunted_cursor
