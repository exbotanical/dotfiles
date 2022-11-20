local M = {}

-- This is where key mappings are configured
local whichkey = require 'which-key'
local next = next

local conf = {
  window = {
    border = 'single', -- none, single, double, shadow
    position = 'bottom', -- bottom, top
  },
}
whichkey.setup(conf)

local opts = {
  mode = 'n', -- Normal mode
  prefix = '<leader>',
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true, -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = false, -- use `nowait` when creating keymaps
}

local v_opts = {
  mode = 'v', -- Visual mode
  prefix = '<leader>',
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true, -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = false, -- use `nowait` when creating keymaps
}

local function normal_keymap()
  local keymap_f = nil -- File search

  keymap_f = {
    name = 'Find',
    e = { '<cmd>NvimTreeToggle<cr>', 'Explorer' },
  }

  local keymap = {
    ['w'] = { '<cmd>update!<CR>', 'Save' },
    f = keymap_f,
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
