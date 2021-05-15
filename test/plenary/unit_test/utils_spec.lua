local utils = require('doppelganger.utils')

describe("utils", function()

  describe(".get_config", function()

    it("gets g:doppelganger#cache#disable", function()
      vim.g['doppelganger#cache#disable'] = false
      local actual = utils.get_config('cache#disable')
      local expected = false
      assert.is.same(expected, actual)
    end)
  end)

end)
