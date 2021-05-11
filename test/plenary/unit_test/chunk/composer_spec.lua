local M = require('doppelganger.chunk.composer')

describe("composer", function()
  describe(".__append_chunks()", function()

    it("appends a chunk to existing chunks", function()
      local chunks = {{'foo', 'bar'}, {'baz', 'qux'}}
      local chunk = {'quux', 'corge'}
      local actual = M.__append_chunks(chunks, chunk)
      local expected = {{'foo', 'bar'}, {'baz', 'qux'}, {'quux', 'corge'}}
      assert.is.same(expected, actual)
    end)

    it("appends chunks2 to existing chunks1", function()
      local chunks = {{'foo', 'bar'}, {'baz', 'qux'}}
      local chunk = {{'quux', 'corge'}, {'grault', 'garply'}}
      local actual = M.__append_chunks(chunks, chunk)
      local expected = {{'foo', 'bar'}, {'baz', 'qux'}, {'quux', 'corge'}, {'grault', 'garply'}}
      assert.is.same(expected, actual)
    end)

  end)
end)
