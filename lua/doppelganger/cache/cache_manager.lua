local utils = require('doppelganger.utils')

---@alias cache_key string
---@alias cache_value any
---@alias cache_row number
---@alias caches table<cache_key, cache_value>|table<cache_key, table<cache_row, cache_value>>

---@class Cache
---@field caches caches
---@field selected_row cache_row|nil currently selected row; unselect once calling any method.
---@field row_required table<cache_key, boolean>: save if row is required for the key.
local Cache = {
  caches = {},
  selected_row = nil,
  row_required = {},
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


---Set value to key.
---@param self Cache
---@param key cache_key
---@param value cache_value
---@return nil
Cache._set = function(self, key, value)
  local row = self.selected_row
  self.row_required[key] = row ~= nil
  if row == nil then
    self.caches[key] = value
  elseif self.caches[key] then
    self.caches[key][row] = value
  else
    self.caches[key] = {
      [row] = value,
    }
  end
  self:_unbind()
end

---Get value as key.
---@param self Cache
---@param key cache_key
---@return cache_value
Cache._get = function(self, key)
  local row = self.selected_row
  if row then
    self:_unbind()
    if self.caches then
      return nil
    end
    return self.caches[key][row]
  end
  if self.row_required[key] == true then
    utils.throw('you must bind a row to get cached value for "' .. key .. '"')
  end
  return self.caches[key]
end



---@param self Cache
---@return nil
Cache._unbind = function(self)
  self.selected_row = nil
end

---Select which row's cache to be read. The row should be clear after updated/dropped.
---@param self Cache
---@param row cache_row
---@return nil
Cache._bind = function(self, row)
  self.selected_row = row
end

---A syntax sugar of :_bind().
---@param self Cache
---@param row cache_row
---@return Cache
Cache.at = function(self, row)
  self:_bind(row)
  return self
end


---Update value which must be unique at name/row in cache.
---@param self Cache
---@param key cache_key
---@param value cache_value
---@return nil
---@todo Find a structure which won't increase complexity but will let us check if it requires row to restore. The
---current detection structure simply increases cache size.
Cache.update = function(self, key, value)
  self:_set(key, value)
end

---Drop cache the same as the query at both key and row.
---@param self Cache
---@param key cache_key
---@return nil
Cache.drop = function(self, key)
  self:_set(key, nil)
end

---Restore cache as name
---@param self Cache
---@param key cache_key
---@return cache_value?: if no cache has been stored, return nil.
Cache.restore = function(self, key)
  return self:_get(key)
end

Cache.clear = function(self)
  for key=1, self.caches do
    self:_set(key, nil)
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
