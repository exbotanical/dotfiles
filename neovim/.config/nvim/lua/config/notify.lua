local M = {}

local icons = require('config.icons')

function M.setup()
  local notify = require('notify')

  notify.setup({
    icons = {
      ERROR = icons.diagnostics.Error,
      WARN = icons.diagnostics.Warning,
      INFO = icons.diagnostics.Information,
      DEBUG = icons.ui.Bug,
      TRACE = icons.ui.Pencil,
    },
  })

  -- vim.notify = notify
  -- TODO: https://github.com/jose-elias-alvarez/null-ls.nvim/issues/428
  vim.notify = function(msg, ...)
    if msg:match("warning: multiple different client offset_encodings") then
        return
    end

    notify(msg, ...)
  end
end

return M
