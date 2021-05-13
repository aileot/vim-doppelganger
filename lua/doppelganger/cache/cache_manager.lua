local vim = _G.vim
local utils = require('doppelganger.utils')

---@alias cache_key string
---@alias cache_value any
---@alias cache_row number
---@alias caches table<cache_key, cache_value>|table<cache_key, table<cache_row, cache_value>>

---@class Cache
---@field caches caches
local Cache = {
  caches = {},
}
Cache.__index = Cache

setmetatable(Cache, {
  __call = function(cls, ...)
    return cls.attach(...)
  end,
})


---@constructor cache
---@return Cache
Cache.new = function()
  local self = setmetatable({}, Cache)
  -- update_time = function() return os.time('%T') end
  return self
end


---Update value which must be unique at name/row in cache.
---@param self Cache
---@param key cache_key
---@param value cache_value
---@param row cache_row?
---@return cache_value
Cache.update = function(self, key, value, row)
  if row then
    self.caches[key] = { [row] = value }
  else
    self.caches[key] = value
  end
end

---Drop cache the same as the query at both key and row.
---@param self Cache
---@param key cache_key
---@param row cache_value
---@return Cache
Cache.drop = function(self, key, row)
  if row then
    self.caches[key][row] = nil
  else
    self.caches[key] = nil
  end
end

---Restore cache as name
---@param self Cache
---@param key cache_key
---@param row cache_row?
---@return cache_value?: if no cache has been stored, return nil.
Cache.restore = function(self, key, row)
  local cache = self.caches[key]
  return row and cache[row] or cache
end



---@alias cache_collection table[Cache]: a collection of Cache.
---@alias cm_id_number number: an identifer. Use winnr for the role because virtual texts are only relevant in apparent
--buffers.
---@alias cm_region string: another identifer to tell which module has tried to attach cache in logging.
---@alias cm_id cm_region|cm_id_number: an ideal identifer to tell which module has tried to attach cache in logging.
---See @todo below.
---@todo Replace cm_region with annother humanreadable cm_id to tell which module has tried to attach either cache or
---cache_manager.


---@class CacheManager @ define a singleton object which manage all the caches for vim-doppelganger.
---@field register function
---@field collection cache_collection
local M = {
  collection = {},
}
M.__index = M

setmetatable(M, {
  __call = function(cls, ...)
    return cls.new(...)
  end,
})


---@type cm_id_number
local id = 0

---Register as region. Without attaching at winnr, it must be useless.
---@factory Cache
---@param self CacheManager
---@param region cm_region
---@return CacheManager
M.register = function(self, region)
  id = id + 1
  self.id = region .. '_' .. id
  return self
end

---Attach to winnr to update/drop in cache. It also means to detach the last cache.
---@param self CacheManager
---@param winnr cm_id
---@return Cache?
M.attach = function(self, winnr)
  if vim.g['doppelganger#cache#disable'] then return nil end
  local c = self.collection[winnr] or Cache.new()
  return c
end


if utils.debug then
  M.__Cache = Cache
end

return M
