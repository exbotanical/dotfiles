local M = {}

function M.setup()
  require('lspconfig')

  require('config.lsp.mason').setup()
  require('config.lsp.handlers').setup()
  require('config.lsp.null-ls').setup()
end

return M
