local M = {}

local servers = {
  gopls = {},
  html = {},
  jsonls = {
    settings = {
      json = {
        schemas = require("schemastore").json.schemas(),
      },
    },
  },
  pyright = {},
  rust_analyzer = {
    settings = {
      ["rust-analyzer"] = {
        cargo = { allFeatures = true },
        checkOnSave = {
          command = "clippy",
          extraArgs = { "--no-deps" },
        },
      },
    },
  },
  sumneko_lua = {
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
          path = vim.split(package.path, ";"),
        },
        diagnostics = {
          globals = { "vim" },
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          library = {
            [vim.fn.expand "$VIMRUNTIME/lua"] = true,
            [vim.fn.expand "$VIMRUNTIME/lua/vim/lsp"] = true,
          },
        },
      },
    },
  },
  tsserver = {},
  vimls = {},
} 

local function on_attach(client, bufnr)
  -- Enable completion triggered by <C-X><C-O>
  -- See: `:help omnifunc`, `:help ins-completion`
  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  -- Use LSP as the handler for formatexpr.
  -- See: `:help formatexpr`
  vim.api.nvim_buf_set_option(0, "formatexpr", "v:lua.vim.lsp.formatexpr()")

  require("config.lsp.keymaps").setup(client, bufnr)
  require("config.lsp.highlight").setup(client)
  require("config.lsp.null-ls.format").setup(client, bufnr)
  
  if client.name == "tsserver" then
    require("config.lsp.ts-utils").setup(client)
  end
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
if PLUGINS.nvim_cmp.enabled then
  capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities) -- for nvim-cmp
end

local opts = {
  on_attach = on_attach,
  capabilities = capabilities,
  flags = {
    debounce_text_changes = 150,
  },
}

require("config.lsp.handlers").setup()

function M.setup()
  require("config.lsp.null-ls").setup(opts)
  require("config.lsp.installer").setup(servers, opts)
end

return M
