local M = require('doppelganger.cache.cache_manager')


describe("cache_manager", function()
  describe(".__Cache", function()
    local common = {}

    describe(".update()", function()

      before_each(function()
        common.cache = M.__Cache.new()
        common.cache:update('foo', {bar = 'baz'})
      end)

      it("store {bar = 'baz'} at 'foo'", function()
        local expected = {bar = 'baz'}
        assert.is.same(expected, common.cache.caches.foo)
      end)

      it("overwrite at the same key, 'foo'", function()
        common.cache:update('foo', {qux = 'quux'})
        local expected = {qux = 'quux'}
        assert.is.same(expected, common.cache.caches.foo)
      end)

    end)
  end)

  describe(".register()", function()

  end)
end)
