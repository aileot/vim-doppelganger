local M = require('doppelganger.cache.cache_manager')


describe("cache_manager", function()
  local common = {}
  before_each(function()
    common.cache_manager = M.register('test')
    common.cache = common.cache_manager:attach('test')
  end)
  after_each(function()
    common.cache_manager:clear()
  end)

  describe(":clear()", function()
    it("clear all the cache collection to return an empty table", function()
      common.cache_manager:clear()
      assert.is.same({}, common.cache_manager.collection)
    end)
  end)

  describe(".__Cache", function()

    describe(":update()", function()

      before_each(function()
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

    describe(":restore()", function()

      pending("always returns nil if update() isn't called yet", function()
        local actual = common.cache:restore('foo')
        assert.is_nil(actual)
      end)

      it("return the very 42 as saved by :update()", function()
        local sample1 = 42
        common.cache:update('sample1', sample1)
        local actual = common.cache:restore('sample1')
        local expected = 42
        assert.is.same(expected, actual)
      end)

      it("return the very {'foo', 'bar'} as saved by :update()", function()
        local sample2 = {'foo', 'bar'}
        common.cache:update('sample2', sample2)
        local actual = common.cache:restore('sample2')
        local expected = {'foo', 'bar'}
        assert.is.same(expected, actual)
      end)

      it("return the very {'foo', 'bar'} as saved by :update() as current row is 1000", function()
        local sample3 = {'foo', 'bar'}
        common.cache:at(1000):update('sample3', sample3)
        local actual = common.cache:at(1000):restore('sample3')
        local expected = {'foo', 'bar'}
        assert.is.same(expected, actual)
      end)

    end)

  end)


end)
