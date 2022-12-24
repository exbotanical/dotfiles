--[[
lvim is the global options object

Linters should be
filled in as strings with either
a global executable or a path to
an executable
]]

-- Overrides

-- see: https://github.com/LunarVim/LunarVim/issues/2597
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "clangd" })
local capabilities = require("lvim.lsp").common_capabilities()
capabilities.offsetEncoding = { "utf-16" }
local opts = {capabilities = capabilities}
require("lvim.lsp.manager").setup("clangd", opts)

-- general
lvim.log.level = "warn"
lvim.format_on_save.enabled = false
lvim.colorscheme = "tokyonight-night"
-- to disable icons and use a minimalist setup, uncomment the following
-- lvim.use_icons = false

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
-- add your own keymapping
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
-- lvim.keys.normal_mode["<S-l>"] = ":BufferLineCycleNext<CR>"
-- lvim.keys.normal_mode["<S-h>"] = ":BufferLineCyclePrev<CR>"
-- unmap a default keymapping
-- vim.keymap.del("n", "<C-Up>")
-- override a default keymapping
-- lvim.keys.normal_mode["<C-q>"] = ":q<cr>" -- or vim.keymap.set("n", "<C-q>", ":q<cr>" )

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- we use protected-mode (pcall) just in case the plugin wasn't loaded yet.
-- local _, actions = pcall(require, "telescope.actions")
-- lvim.builtin.telescope.defaults.mappings = {
--   -- for input mode
--   i = {
--     ["<C-j>"] = actions.move_selection_next,
--     ["<C-k>"] = actions.move_selection_previous,
--     ["<C-n>"] = actions.cycle_history_next,
--     ["<C-p>"] = actions.cycle_history_prev,
--   },
--   -- for normal mode
--   n = {
--     ["<C-j>"] = actions.move_selection_next,
--     ["<C-k>"] = actions.move_selection_previous,
--   },
-- }

-- Change theme settings
-- lvim.builtin.theme.options.dim_inactive = true
-- lvim.builtin.theme.options.style = "storm"

-- Use which-key to add extra bindings with the leader-key prefix
-- lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects<CR>", "Projects" }
-- lvim.builtin.which_key.mappings["t"] = {
--   name = "+Trouble",
--   r = { "<cmd>Trouble lsp_references<cr>", "References" },
--   f = { "<cmd>Trouble lsp_definitions<cr>", "Definitions" },
--   d = { "<cmd>Trouble document_diagnostics<cr>", "Diagnostics" },
--   q = { "<cmd>Trouble quickfix<cr>", "QuickFix" },
--   l = { "<cmd>Trouble loclist<cr>", "LocationList" },
--   w = { "<cmd>Trouble workspace_diagnostics<cr>", "Workspace Diagnostics" },
-- }

-- TODO: User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false

 lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "c",
  "javascript",
  "json",
  "lua",
  "python",
  "typescript",
  "tsx",
  "css",
  "java",
  "yaml",
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enable = true

-- generic LSP settings

-- make sure server will always be installed even if the server is in skipped_servers list
lvim.lsp.installer.setup.ensure_installed = {
    "clangd",
}
-- -- change UI setting of `LspInstallInfo`
-- -- see <https://github.com/williamboman/nvim-lsp-installer#default-configuration>
-- lvim.lsp.installer.setup.ui.check_outdated_servers_on_open = false
-- lvim.lsp.installer.setup.ui.border = "rounded"
-- lvim.lsp.installer.setup.ui.keymaps = {
--     uninstall_server = "d",
--     toggle_server_expand = "o",
-- }

-- ---@usage disable automatic installation of servers
-- lvim.lsp.installer.setup.automatic_installation = false

-- ---configure a server manually. !!Requires `:LvimCacheReset` to take effect!!
-- ---see the full default list `:lua print(vim.inspect(lvim.lsp.automatic_configuration.skipped_servers))`
-- vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "pyright" })
-- local opts = {} -- check the lspconfig documentation for a list of all possible options
-- require("lvim.lsp.manager").setup("pyright", opts)

-- ---remove a server from the skipped list, e.g. eslint, or emmet_ls. !!Requires `:LvimCacheReset` to take effect!!
-- ---`:LvimInfo` lists which server(s) are skipped for the current filetype
-- lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
--   return server ~= "emmet_ls"
-- end, lvim.lsp.automatic_configuration.skipped_servers)

-- -- you can set a custom on_attach function that will be used for all the language servers
-- -- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
lvim.lsp.on_attach_callback = function(client, bufnr)
  -- Auto-format
  if client.supports_method("textDocument/formatting") then
    vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = augroup,
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({
          bufnr = bufnr,
        })
      end,
    })
  end
end

-- set a formatter, this will override the language server formatting capabilities (if it exists)
-- each formatter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  { command = "black", filetypes = { "python" } },
  { command = "isort", filetypes = { "python" } },
  {
    command = "clang_format",
    extra_args = { "--fallback-style", "Google" },
    filetypes = { "c", "cpp", "h", "hpp" },
  },
}

-- -- set additional linters
-- local linters = require "lvim.lsp.null-ls.linters"
-- linters.setup {
--   { command = "flake8", filetypes = { "python" } },
--   {
--     -- each linter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
--     command = "shellcheck",
--     ---@usage arguments to pass to the formatter
--     -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
--     extra_args = { "--severity", "warning" },
--   },
--   {
--     command = "codespell",
--     ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
--     filetypes = { "javascript", "python" },
--   },
-- }

-- Additional Plugins
lvim.plugins = {
  { "rmehri01/onenord.nvim" }
}

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
-- vim.api.nvim_create_autocmd("BufEnter", {
--   pattern = { "*.json", "*.jsonc" },
--   -- enable wrap mode for json files only
--   command = "setlocal wrap",
-- })
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "zsh",
--   callback = function()
--     -- let treesitter use bash highlight for zsh files as well
--     require("nvim-treesitter.highlight").attach(0, "bash")
--   end,
-- })

-- General Settings

vim.opt.backup = false                                    -- creates a backup file
vim.opt.clipboard = "unnamedplus"                         -- allows neovim to access the system clipboard
vim.opt.cmdheight = 2                                     -- more space in the neovim command line for displaying messages
vim.opt.colorcolumn = "99999"                             -- fixes indentline for now
vim.opt.completeopt = { "menuone", "noselect" }
vim.opt.conceallevel = 0                                  -- so that `` is visible in markdown files
vim.opt.fileencoding = "utf-8"                            -- the encoding written to a file
vim.opt.foldmethod = "manual"                             -- folding set to "expr" for treesitter based folding
vim.opt.foldexpr = ""                                     -- set to "nvim_treesitter#foldexpr()" for treesitter based folding
vim.opt.guifont = "monospace:h17"                         -- the font used in graphical neovim applications
vim.opt.hidden = true                                     -- required to keep multiple buffers and open multiple buffers
vim.opt.hlsearch = true                                   -- highlight all matches on previous search pattern
vim.opt.ignorecase = true                                 -- ignore case in search patterns
vim.opt.mouse = "a"                                       -- allow the mouse to be used in neovim
vim.opt.pumheight = 10                                    -- pop up menu height
vim.opt.showmode = true                                   -- show mode e.g. INSERT, VISUAL, et al
vim.opt.showtabline = 2                                   -- always show tabs
vim.opt.smartcase = true                                  -- smart case
vim.opt.smartindent = true                                -- make indenting smarter again
vim.opt.splitbelow = true                                 -- force all horizontal splits to go below current window
vim.opt.splitright = true                                 -- force all vertical splits to go to the right of current window
vim.opt.swapfile = false                                  -- creates a swapfile
vim.opt.termguicolors = true                              -- set term gui colors (most terminals support this)
vim.opt.timeoutlen = 100                                  -- time to wait for a mapped sequence to complete (in milliseconds)
vim.opt.title = true                                      -- set the title of window to the value of the titlestring
vim.opt.titlestring = "%<%F%=%l/%L - nvim"                -- what the title of the window will be set to
vim.opt.undodir = vim.fn.stdpath "cache" .. "/undo"
vim.opt.undofile = true                                  -- enable persistent undo
vim.opt.updatetime = 300                                 -- faster completion
vim.opt.writebackup = false                              -- if a file is being edited by another program (or was written to file while editing with another program) it is not allowed to be edited
vim.opt.expandtab = true                                 -- Convert tabs to spaces
vim.opt.shiftwidth = 2                                   -- When shifting, indent using n spaces
vim.opt.tabstop = 2                                      -- Indent using n spaces
vim.opt.cursorline = true                                -- Highlight the line currently under cursor
vim.opt.cursorcolumn = true                              -- Highlight the screen column of the cursor
vim.opt.number = true                                    -- set numbered lines
vim.opt.relativenumber = false                           -- set relative numbered lines
vim.opt.numberwidth = 4                                  -- set number column width to 2 {default 4}
vim.opt.signcolumn = "yes"                               -- always show the sign column otherwise it would shift the text each time
vim.opt.wrap = true                                      -- Enable line wrapping
vim.opt.spell = true                                     -- Enable spellchecking
vim.opt.spelllang = "en"
vim.opt.scrolloff = 1                                    -- The number of screen lines to keep above and below the cursor
vim.opt.sidescrolloff = 5                                -- The number of screen columns to keep to the left and right of the cursor
vim.opt.textwidth = 80                                   -- Wrap lines at n characters
vim.opt.history = 1000                                   -- Increase the undo limit
vim.opt.shell = "/bin/bash"                              -- The shell used to execute commands
vim.opt.nocompatible = true                              -- Don't sacrifice functionality just to preserve backward compatibility with vi
