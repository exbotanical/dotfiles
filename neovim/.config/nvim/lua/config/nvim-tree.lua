local M = {}

function M.setup()
  local config_status_ok, nvim_tree_config = pcall(require, 'nvim-tree.config')
  if not config_status_ok then
    return
  end

  -- disable netrw
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1

  -- set termguicolors to enable highlight groups
  vim.opt.termguicolors = true

  local tree_cb = nvim_tree_config.nvim_tree_callback

  require('nvim-tree').setup({
    -- Open tree when opening dir
    open_on_setup = true,

    -- Update the focused file on `BufEnter`, un-collapses the folders recursively
    -- until it finds the file
    update_focused_file = {
      enable = true,
      -- Changes the tree root directory on `DirChanged` and refreshes the tree
      update_cwd = true,
    },
    -- UI rendering setup
    renderer = {
      -- In what format to show root folder. See `:help filename-modifiers` for
      -- available options
      root_folder_modifier = ':t',
      icons = {
        glyphs = {
          default = '',
          symlink = '',
          folder = {
            arrow_open = '',
            arrow_closed = '',
            default = '',
            open = '',
            empty = '',
            empty_open = '',
            symlink = '',
            symlink_open = '',
          },
          git = {
            unstaged = '',
            staged = 'S',
            unmerged = '',
            renamed = '➜',
            untracked = 'U',
            deleted = '',
            ignored = '◌',
          },
        },
      },
    },
    -- Show LSP and COC diagnostics in the signcolumn
    diagnostics = {
      enable = true,
      show_on_dirs = true,
      icons = {
        hint = '',
        info = '',
        warning = '',
        error = '',
      },
    },
    -- Window / buffer setup
    view = {
      width = 30,
      side = 'left',
      mappings = {
        list = {
          { key = { 'l', '<CR>', 'o' }, cb = tree_cb 'edit' },
          { key = 'h', cb = tree_cb 'close_node' },
          { key = 'v', cb = tree_cb 'vsplit' },
        },
      },
    },
  })
end

return M
