local g = vim.g

local M = require('doppelganger.chunk.contents')

describe("chunk.contents", function()

  describe(".__trim_whitespace()", function()

    before_each(function()
      g['doppelganger#format#compress_whitespaces'] = false
    end)

    it("cuts off any indents (including tab chars) and trailing whitespaces", function()
      g['doppelganger#format#compress_whitespaces'] = false
      local lines = {
        '  foo  bar ',
        '    baz   qux ',
        '		quux   corge ',
      }
      local actual = M.__trim_whitespace(lines)
      local expected = {
        'foo  bar',
        'baz   qux',
        'quux   corge'
      }
      assert.is.same(expected, actual)
    end)

    it("cuts off any indents and trailing whitespaces, and compresses any number of spaces into a space", function()
      g['doppelganger#format#compress_whitespaces'] = true
      local lines = {
        '  foo  bar ',
        '    baz   qux ',
      }
      local actual = M.__trim_whitespace(lines)
      local expected = {
        'foo bar',
        'baz qux',
      }
      assert.is.same(expected, actual)
    end)

  end)

end)
