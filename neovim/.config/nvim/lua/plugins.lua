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
      -- cmd = { 'NvimTreeToggle', 'NvimTreeClose' },
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

    -- Dashboard / greeter
    use {
      'goolord/alpha-nvim',
      requires = { 'kyazdani42/nvim-web-devicons' },
      config = function ()
        require('config.alpha').setup()
      end
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

    -- LSP --

    -- Enable LSP
    use { 'neovim/nvim-lspconfig', }
    -- Manage LSP servers
    use {
      'williamboman/mason.nvim',
      config = function()
        require('config.lsp.mason').setup()
        require('config.lsp.handlers').setup()
      end
    }
    -- Bridge mason-lspconfig
    use { 'williamboman/mason-lspconfig.nvim', }
    -- Static analysis
    use {
      'jose-elias-alvarez/null-ls.nvim',
      config = function()
        require('config.lsp.null-ls')
      end
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

    -- snippet engine
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

    -- Auto-closing of pairs
    use {
      'windwp/nvim-autopairs',
      event = 'InsertEnter',
      config = function()
        require('config.autopairs').setup()
      end,
    }

    -- Lualine
    use {
      'nvim-lualine/lualine.nvim',
      -- event = 'BufReadPre',
      requires = {
        'kyazdani42/nvim-web-devicons',
        opt = true
      },
      config = function()
        require('lualine').setup()
      end
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

    -- Integrated terminal
    use {
      'akinsho/toggleterm.nvim',
      tag = '*',
      config = function()
        require('toggleterm').setup()
      end
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
