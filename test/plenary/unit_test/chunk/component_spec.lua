local M = require("doppelganger.chunk.component")

describe("chunk.component", function()

  describe(".__map_chunks()", function()

    it("substitute 'foo' to 'bar' in each chunk", function()
      local given_chunks = {
        {'foo1', 'hl_group1'},
        {'foo2', 'hl_group2'},
        {'foo3', 'hl_group3'},
      }
      local f = function(old_chunk)
        local old_text = old_chunk[1]
        local new_text = old_text:gsub('foo', 'bar')
        local new_chunk = { new_text, old_chunk[2] }
        return new_chunk
      end
      local actual = M.__map_chunks(given_chunks, f)
      local expected = {
        {'bar1', 'hl_group1'},
        {'bar2', 'hl_group2'},
        {'bar3', 'hl_group3'},
      }
      assert.is.same(expected, actual)
    end)

  end)

  describe(".__displaywidth(chunks)", function()

    it("returns length as displayed width", function()
      local width1 = ''
      local width2 = 'あ'
      local hl_group1 = ''
      local hl_group2 = ''
      local chunks1 = {{width1, hl_group1}}
      local chunks2 = {{width2, hl_group2}}
      local chunks3 = {{width1, hl_group1}, {width2, hl_group2}}
      assert.is.same(1, M.__displaywidth(chunks1))
      assert.is.same(2, M.__displaywidth(chunks2))
      assert.is.same(3, M.__displaywidth(chunks3))
    end)

  end)

  describe(":_replace_keywords_in_text()", function()

    it("replaces {absolute}, {relative} and {size} with numbers", function()
      local given = {
        abs = 100,
        rel = 49,
        size = 50,
      }
      local template = '{absolute}: {relative}[{size}]'
      local actual = M._replace_keywords_in_text(given, template)
      local expected = '100: 49[50]'
      assert.is.same(expected, actual)
    end)

  end)

  describe(":_create_chunks(tempate)", function()

    local context = {}
    before_each(function()
      -- For those the values don't matter.
      context.component = {
        abs = 0,
        rel = 0,
        size = 0,
      }
    end)

    it("returns an empty table from an empty template", function()
      local template = {}
      local actual = M._create_chunks(context.component, template)
      local expected = {}
      assert.is.same(expected, actual)
    end)

    it("create a set of chunks from a template", function()
      local given = {
        abs = 100,
        rel = 49,
        size = 50,
      }
      -- Hack: Is really sane workaround to run this test?
      given._replace_keywords_in_chunk = M._replace_keywords_in_chunk
      given._replace_keywords_in_text = M._replace_keywords_in_text
      local template = {
        { '{absolute}: {relative}[{size}]', 'hl_group1' },
        { '{relative}: {absolute}[{size}]', 'hl_group2' },
        { '{absolute}: {size}[{relative}]', 'hl_group3' },
      }
      local actual = M._create_chunks(given, template)
      local expected = {
        {'100: 49[50]', 'hl_group1'},
        {'49: 100[50]', 'hl_group2'},
        {'100: 50[49]', 'hl_group3'},
      }
      assert.is.same(expected, actual)
    end)

  end)

end)
