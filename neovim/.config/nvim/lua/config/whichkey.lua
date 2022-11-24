local M = {}

-- This is where key mappings are configured
local whichkey = require 'which-key'

local conf = {
  window = {
    border = 'single',
    position = 'bottom',
  },
}
whichkey.setup(conf)

local opts = {
  mode = 'n', -- Normal mode
  prefix = '<leader>',
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true,
  noremap = true,
  nowait = false,
}

local v_opts = {
  mode = 'v', -- Visual mode
  prefix = '<leader>',
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true,
  noremap = true,
  nowait = false,
}

local function normal_keymap()
  local keymap_f = nil -- File search
  local keymap_t = nil -- Utilities
  local keymap_g = nil -- Git

  keymap_f = {
    name = 'Find',
    e = { '<cmd>NvimTreeToggle<cr>', 'Explorer' },
  }

  keymap_t = {
    name = 'Utilities',
    t = { '<cmd>ToggleTerm<cr>', 'Terminal' },
    e = { '<cmd>TroubleToggle<cr>', 'Diagnostics' },
  }

  keymap_g = {
    name = 'Git',
    b = { '<cmd>Gitsigns toggle_current_line_blame<cr>', 'Blame' },
  }

  local keymap = {
    ['w'] = { '<cmd>update!<CR>', 'Save' },
    f = keymap_f,
    t = keymap_t,
    g = keymap_g,
  }

  whichkey.register(keymap, opts)
 end

local function visual_keymap()
  local keymap = {}


  whichkey.register(keymap, v_opts)
end

function M.setup()
  normal_keymap()
  visual_keymap()
end

return M
