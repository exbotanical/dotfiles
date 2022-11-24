local M = {}

function M.setup()
  local configs = require('nvim-treesitter.configs')

  configs.setup({
    ensure_installed = {
      'lua',
      'markdown',
      'markdown_inline',
      'bash',
      'python',
      'c',
      'javascript',
      'typescript',
      'java'
    },
    -- List of parsers to ignore installing
    ignore_install = { '' },
    -- install languages synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- false will disable the whole extension
    highlight = {
      enable = true,
      -- list of languages that will be disabled
      disable = { 'css' },
    },
    autopairs = {
      enable = true,
    },
    indent = {
      enable = true,
      disable = { 'python', 'css' }
    },
    context_commentstring = {
      enable = true,
      enable_autocmd = false,
    },
  })

end

return M
