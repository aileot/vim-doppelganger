local vim = _G.vim

---@class utils
---@description All the member must be a static method.
local utils = {}

---@note Restart nvim instance to apply the change.
utils.debug = vim.g['doppelganger#debug']

---@static
---@member utils
---@param msg string
function utils.throw(msg)
  local prefix = '[doppelganger] '
  error(prefix .. msg)
end

---@static
---@member utils
---@param t any: wanted type in string
---@param arg any
function utils.validate_type(t, arg)
  if type(arg) ~= t then
    utils.throw("Invalid type, " .. type(arg) .. ": " .. vim.inspect(arg))
  end
end

---Return config as name. If vim.b.doppelganger_name is found, return it; otherwise, return vim.g.doppelganger#name.
---@static
---@member utils
---@param name string
---@return any
function utils.get_config(name)
  name = 'doppelganger#' .. name
  local global_conf = vim.g[name]
  local local_conf = vim.b[name:gsub('#', '_')]
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
  local global_var = vim.g[name]
  local local_conf = vim.b[name:gsub('#', '_')] or global_var[vim.bo.filetype] or global_var['_']
  if local_conf == nil then
    utils.throw(vim.inspect(global_var))
  end
  return local_conf
end

---@static
---@description A wrapper to define augroup. It's recommended to start the autocmds with `autocmds!`.
---@param au_name string
---@param autocmds string
function utils.vim_autocmds(au_name, autocmds)
  vim.nvim_command('augroup '.. au_name
    ..'\n'.. autocmds ..'\n'..
    'augroup END')
end
return utils
