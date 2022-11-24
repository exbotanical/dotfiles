local M = {}

function M.setup()
  local autopairs = require('nvim-autopairs')

  autopairs.setup({
    -- treesitter integration
    check_ts = true,

    fast_wrap = {
      map = '<M-e>',
      chars = { '{', '[', '(', '\'', '\'' },
      pattern = string.gsub([[ [%'%'%)%>%]%)%}%,] ]], '%s+', ''),
      -- Offset from pattern match
      offset = 0,
      end_key = '$',
      keys = 'qwertyuiopzxcvbnmasdfghjkl',
      check_comma = true,
      highlight = 'PmenuSel',
      highlight_grey = 'LineNr',
    },
  })

  local cmp_autopairs = require('nvim-autopairs.completion.cmp')

  require('cmp').event:on('confirm_done', cmp_autopairs.on_confirm_done({
    map_char = { tex = '' }
  }))
end

return M
