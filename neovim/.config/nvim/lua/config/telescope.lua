local M = {}

function M.setup()
  local telescope = require('telescope')
  local actions = require('telescope.actions')

  telescope.setup {
    defaults = {
      prompt_prefix = ' ',
      selection_caret = ' ',
      path_display = { 'smart' },
      file_ignore_patterns = { '.git/', 'node_modules' },

      mappings = {
        i = {
          ['<Down>'] = actions.cycle_history_next,
          ['<Up>'] = actions.cycle_history_prev,
          ['<Right>'] = actions.move_selection_next,
          ['<Left>'] = actions.move_selection_previous,
        },
      },
    },
  }
end

return M
