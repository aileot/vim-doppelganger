local g = vim.g
local b = vim.b
local bo = vim.bo

---@class utils
---@description All the member must be a static method.
local utils = {}

---@note Restart nvim instance to apply the change.
utils.debug = g['doppelganger#debug']

---@static
---@member utils
---@param msg string
function utils.throw(msg)
  local prefix = '[doppelganger] '
  error(prefix .. msg)
end

---@static
---@member utils
---@param t any: wanted type name
---@param arg any
function utils.validate_type(arg, t)
  if type(arg) ~= t then
    utils.throw("expected " .. type(arg) .. ", got " .. type(arg) .. ": " .. vim.inspect(arg))
  end
end

---Return config as name. If vim.b.doppelganger_name is found, return it; otherwise, return vim.g.doppelganger#name.
---@static
---@member utils
---@param name string
---@return any
function utils.get_config(name)
  name = 'doppelganger#' .. name
  local global_conf = g[name]
  local local_conf = b[name:gsub('#', '_')]
  return local_conf or global_conf
end

---Return config as name. If vim.b.doppelganger_name is found, return it; otherwise, return
---vim.g.doppelganger#name[vim.bo.filetype] or vim.g.doppelganger#name['_'].
---@static
---@member utils
---@param name string
---@return any
function utils.get_ftconfig(name)
  name = 'doppelganger#' .. name
  local global_var = g[name]
  local local_conf = b[name:gsub('#', '_')] or global_var[bo.filetype] or global_var['_']
  if local_conf == nil then
    utils.throw(vim.inspect(global_var))
  end
  return local_conf
end

--  ---@static
--  ---@description A wrapper to define augroup. It's recommended to start the autocmds with `autocmds!`.
--  ---@param au_name string
--  ---@vararg string: autocmd
--  ---@note define augroup without E216.
--  function utils.augroup(au_name, ...)
--    au_name = "doppelganger/" .. au_name
--    cmd("augroup " .. au_name)
--    for i=1, select("#", ...) do
--      cmd(select(i, ...))
--    end
--    cmd("augroup END")
--  end

return utils
