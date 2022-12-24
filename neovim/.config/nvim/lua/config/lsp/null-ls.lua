local M = {}

function M.setup()
  local null_ls = require('null-ls')

  -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
  local formatting = null_ls.builtins.formatting
  -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
  local diagnostics = null_ls.builtins.diagnostics

  local code_actions = null_ls.builtins.code_actions
  local completion = null_ls.builtins.completion

  local augroup = vim.api.nvim_create_augroup('LspFormatting', {})

  null_ls.setup({
    debug = false,
    sources = {
      -- Formatters
      formatting.clang_format.with({
        extra_args = {
          '--fallback-style=Google'
        }
      }),
      formatting.stylua,
      formatting.prettier.with({
        extra_filetypes = { 'toml' },
      }),
      formatting.black.with({
        extra_args = { '--fast' }
      }),
      formatting.stylua,
      formatting.google_java_format,

      -- diagnostics
      diagnostics.clang_check,
      diagnostics.flake8,
      diagnostics.eslint,

      -- Completions
      completion.spell,

      -- Code Actions
      code_actions.shellcheck,
    },
    -- Format on save
    on_attach = function(client, bufnr)
        -- nvim-navic
        if client.server_capabilities.documentSymbolProvider then
          local navic = require "nvim-navic"
          navic.attach(client, bufnr)
        end

        if client.supports_method('textDocument/formatting') then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd('BufWritePre', {
                group = augroup,
                buffer = bufnr,
                callback = function()
                  vim.lsp.buf.format({
                    bufnr = bufnr,
                    filter = function(client)
                        return client.name == 'null-ls'
                    end
                  })
                end,
            })
        end
    end,
  })
end

return M
