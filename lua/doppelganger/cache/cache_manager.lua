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
---@todo Find a structure which won't increase complexity but will let us check if it requires row to restore. The
---current detection structure simply increases cache size.
Cache.update = function(self, key, value, row)
  if row == nil then
    self.caches[key] = value
  elseif self.caches[key] then
    self.caches[key][row] = value
  else
    self.caches[key] = {
      [row] = value,
    }
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
  if cache == nil then return nil end
  ---@todo Validate cache is table<row, value> or table<value>.
  if row then return cache[row] end
  return cache
end

Cache.clear = function(self)
  for i=1, #self.caches do
    self.caches[i] = nil
  end
end


---@alias cache_collection table[Cache]: a collection of Cache.
---@alias cm_number_id number: an identifer. Use winnr for the role because virtual texts are only relevant in apparent
--buffers.
---@alias cm_module_id string: another identifer to tell which module has tried to attach cache in logging.
---@alias cm_id cm_module_id|cm_number_id: an ideal identifer to tell which module has tried to attach cache in logging.
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


---@type cm_number_id
local number_id = 0

---Register as region. Without attaching at winnr, it must be useless.
---@factory Cache
---@param module_id cm_module_id
---@return CacheManager
M.register = function(module_id)
  local self = setmetatable({}, M)
  number_id = number_id + 1
  self.id = module_id .. '_' .. number_id
  return self
end

---Attach to winnr to update/drop in cache. It also means to detach the last cache.
---@private
---@param self CacheManager
---@param winnr cm_id
---@return Cache?
M.attach = function(self, winnr)
  local c = self.collection[winnr] or Cache.new()
  return c
end

---Clear all the caches under control.
---@param self CacheManager
---@param id cm_id
---@note collection do never become nil but must be a table, or an empty table at least.
---@todo Surely clear caches at given id.
M.clear = function(self, id)
  if id then
    local cache = self.collection[id]
    self.collection[id] = nil
    cache:clear()
    return
  end
  for _, cache in pairs(self.collection) do
    cache:clear()
  end
  self.collection = {}
end

if utils.debug then
  M.__Cache = Cache
end

return M
