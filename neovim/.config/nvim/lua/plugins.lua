local M = {}

local packer_bootstrap = false

local function packer_init()
  local fn = vim.fn
  local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
  local packer_url = 'https://github.com/wbthomason/packer.nvim'

  if fn.empty(fn.glob(install_path)) > 0 then
    packer_bootstrap = fn.system({
      'git',
      'clone',
      '--depth',
      '1',
      packer_url,
      install_path,
    })

    vim.cmd('packadd packer.nvim')
  end

  vim.cmd('autocmd BufWritePost plugins.lua source <afile> | PackerCompile')
end

packer_init()

function M.setup()
  local conf = {
    compile_path = vim.fn.stdpath('config') .. '/lua/packer_compiled.lua',
    display = {
      open_fn = function()
        return require('packer.util').float({
          border = 'rounded'
        })
      end,
    },
  }

  local function plugins(use)
    -- Packer
    use { 'wbthomason/packer.nvim' }

    -- Performance
    use { 'lewis6991/impatient.nvim' }

    -- File tree
    use {
      'nvim-tree/nvim-tree.lua',
      event = 'BufWinEnter',
      requires = {
        'nvim-tree/nvim-web-devicons', -- for file icons
      },
      tag = 'nightly', -- optional, updated every week
      config = function()
        require('config.nvim-tree').setup()
      end,
    }

    -- Nord theme
    use {
			'shaunsingh/nord.nvim',
			config = function()
				vim.cmd 'colorscheme nord'
			end,
		}

    -- Icons
    use { 'kyazdani42/nvim-web-devicons' }

    -- Dashboard / greeter
    use {
      'goolord/alpha-nvim',
      requires = { 'kyazdani42/nvim-web-devicons' },
      config = function ()
        require('config.alpha').setup()
      end
    }

    -- Smooth scrolling
    use {
      'karb94/neoscroll.nvim',
      event = 'BufReadPre',
      config = function()
        require('neoscroll').setup()
      end,
     }

    -- User interface
    use {
      'stevearc/dressing.nvim',
      event = 'BufReadPre',
      config = function()
        require('dressing').setup {
          input = { relative = 'editor' },
          select = {
            backend = { 'telescope', 'builtin' },
          },
        }
      end,
    }

    -- Notifications
    use {
      'rcarriga/nvim-notify',
      event = 'BufReadPre',
      config = function()
        require('config.notify').setup()
      end,
      disable = false,
    }

    -- Top window Bar
    use {
      'SmiteshP/nvim-navic',
      requires = 'neovim/nvim-lspconfig'
    }

    -- Status line
    use {
      "nvim-lualine/lualine.nvim",
      event = "BufReadPre",
      config = function()
        require("config.lualine").setup()
      end,
    }

    -- Bufferline
    use {
      'akinsho/bufferline.nvim',
      event = 'BufReadPre',
      config = function()
        require('config.bufferline')
      end
    }

    -- Indent indicators
    use { 'lukas-reineke/indent-blankline.nvim'}

    -- Key mappings menu
    use {
      'folke/which-key.nvim',
      event = 'VimEnter',
      module = { 'which-key' },
      config = function()
        require('config.whichkey').setup()
      end,
      disable = false,
    }

    -- Enable LSP
    use { 'neovim/nvim-lspconfig', }

    -- Manage LSP servers
    use {
      'williamboman/mason.nvim',
      config = function()
        require('config.lsp').setup()
      end
    }

    -- Bridge mason-lspconfig
    use { 'williamboman/mason-lspconfig.nvim', }

    -- Static analysis
    use {
      'jose-elias-alvarez/null-ls.nvim'
    }

    -- Highlighting
    use {
      'RRethy/vim-illuminate',
      config = function()
        require('config.illuminate')
      end
    }

    -- Completions
    use {
      'hrsh7th/nvim-cmp',
      config = function()
        require('config.cmp').setup()
      end
    }

    -- Buffer completions
    use { 'hrsh7th/cmp-buffer', }

    -- Path completions
    use { 'hrsh7th/cmp-path', }

    -- Snippet completions
    use { 'saadparwaiz1/cmp_luasnip', }
    use { 'hrsh7th/cmp-nvim-lsp', }
    use { 'hrsh7th/cmp-nvim-lua', }

    -- Snippet engine
    use { 'L3MON4D3/LuaSnip' }

    -- snippets
    use { 'rafamadriz/friendly-snippets' }

    -- Treesitter
    use {
      'nvim-treesitter/nvim-treesitter',
      config = function()
        require('config.treesitter')
      end
    }

    -- `end` syntax in langs e.g. Lua
    use {
      'RRethy/nvim-treesitter-endwise',
      opt = true,
      event = 'InsertEnter',
      disable = false,
    }

    -- Auto-closing of pairs
    use {
      'windwp/nvim-autopairs',
      event = 'InsertEnter',
      config = function()
        require('config.autopairs').setup()
      end,
    }

    -- Integrated terminal
    use {
      'akinsho/toggleterm.nvim',
      tag = '*',
      config = function()
        require('toggleterm').setup()
      end
    }

    -- Diagnostics, references, telescope results, quickfix and location lists
    use {
      'folke/trouble.nvim',
      requires = 'kyazdani42/nvim-web-devicons',
      config = function()
        require('trouble').setup({})
      end
    }

    -- Inline git commit history
    use {
      'lewis6991/gitsigns.nvim',
      config = function()
        require('gitsigns').setup()
      end
    }

    -- Dim unused words
    use {
      'narutoxy/dim.lua',
      requires = { 'nvim-treesitter/nvim-treesitter', 'neovim/nvim-lspconfig' },
      config = function()
        require('dim').setup {
          disable_lsp_decorations = true,
        }
      end,
      disable = true,
    }

     -- Todo comments
    use {
      'folke/todo-comments.nvim',
      config = function()
        require('todo-comments').setup()
      end,
      cmd = { 'TodoQuickfix', 'TodoTrouble', 'TodoTelescope' },
    }

    -- Comments toggling
    use {
      'numToStr/Comment.nvim',
      config = function()
        require('Comment').setup()
      end,
    }

    -- Useful lua functions (used by telescope)
    use { 'nvim-lua/plenary.nvim' }
    -- Find, filter, preview
    use {
      'nvim-telescope/telescope.nvim',
      tag = '0.1.0',
      config = function ()
        require('config.telescope').setup()
      end
    }

    -- Tell me when I'm using bad practices in Vim
    use {
      'antonk52/bad-practices.nvim',
      event = 'BufReadPre',
      config = function()
        require('bad_practices').setup()
      end,
      disable = true,
    }

    -- I WANNA VIM GOOD! BY TEH PRIMEAGEN VIMLORD
    use {
      'ThePrimeagen/vim-be-good'
    }

    if packer_bootstrap then
      print '[log] Setting up Neovim. Restart required after installation.'
      require('packer').sync()
    end
  end

  pcall(require, 'impatient')
  pcall(require, 'packer_compiled')
  require('packer').init(conf)
  require('packer').startup(plugins)
end

return M
