local M = {}

function M.setup()
  local status_ok, treesitter = pcall(require, 'nvim-treesitter')
  if not status_ok then
    return
  end

  local status_ok, configs = pcall(require, 'nvim-treesitter.configs')
  if not status_ok then
    return
  end

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
