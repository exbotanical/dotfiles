local M = {}

function M.setup()
	local packer_bootstrap = false

	-- packer nvim config
	local conf = {
		-- Profiler
		profile = {
			enable = true,
			-- ms over which a plugin's load time must be
			-- for it to be included in the profile
			threshold = 0,
		},

		display = {
			open_fn = function() 
				return require("packer.util").float { border = "rounded" }
			end,
		},
	}

 -- check if packer.nvim is installed
 -- run PackerCompile if there are changes in this file
	local function packer_init() 
		local fn = vim.fn
		local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"

		if fn.empty(fn.glob(install_path)) > 0 then
			packer_bootstrap = fn.system {
				"git",
				"clone",
				"--depth",
				"1",
				"https://github.com/wbthomason/packer.nvim",
				install_path,
			}

			vim.cmd [[packadd packer.nvim]]
		end

		vim.cmd "autocmd BufWritePost plugins.lua source <afile> | PackerCompile"
	end

	-- Plugins
	local function plugins(use)
		use { 
			"wbthomason/packer.nvim" 
		}

		-- Color Scheme
		use {
			"shaunsingh/nord.nvim",
			config = function()
				vim.cmd "colorscheme nord"
			end,
		}

		-- Startup Screen
		use {
			"goolord/alpha-nvim",
			config = function()
				require("config.alpha").setup()
			end,
		}

    -- Notifications
    use {
      "rcarriga/nvim-notify",
      event = "VimEnter",
      config = function()
        vim.notify = require "notify"
      end,
    }

		-- Git
		use {
			"TimUntersberger/neogit",
			-- Only load when cmd used
			cmd = "Neogit",
			-- requires = "nvim-lua/plenary.nvim",
			config = function()
				require("config.neogit").setup()
			end,
		}

		-- Whichkey
		use {
			"folke/which-key.nvim",
			-- Load only on this event
			event = "VimEnter",
			config = function() 
				require("config.whichkey").setup()
			end,
		}

		-- IndentLine
		use {
			"lukas-reineke/indent-blankline.nvim",
			-- Load only on this event
			event = "BufReadPre",
			config = function()
				require("config.indentblankline").setup()
			end,
		}

		-- Plenary
		use {
			"nvim-lua/plenary.nvim",
			-- Load only when required
			module = "plenary"
		}

		-- Improved icons
		use {
			"kyazdani42/nvim-web-devicons",
			module = "nvim-web-devicons",
			config = function()
				require("nvim-web-devicons").setup { default = true }
			end,
		}

		-- Improved comments
		use {
			"numToStr/Comment.nvim",
			keys = { 
				"gc", 
				"gcc", 
				"gbc" 
			},
			config = function()
				require("Comment").setup {}
			end,
		}

		-- Improved hopping
		use {
			"phaazon/hop.nvim",
			cmd = { 
				"HopWord", 
				"HopChar1" 
			},
			config = function()
				require("hop").setup {}
			end,
		}

		-- Improved motions
		use {
			"ggandor/lightspeed.nvim",
			keys = { 
				"s", "S", 
				"f", "F", 
				"t", "T" 
			},
			config = function()
				require("lightspeed").setup {}
			end,
		}
    use { "andymass/vim-matchup", event = "CursorMoved" }
    use { "wellle/targets.vim", event = "CursorMoved" }
    use { "unblevable/quick-scope", event = "CursorMoved", disable = false }
    use { "chaoren/vim-wordmotion", opt = true, fn = { "<Plug>WordMotion_w" } }

     -- Improved surround
    use { 
      "tpope/vim-surround", 
      event = "InsertEnter" 
    }

		-- Markdown preview support
		use {
			"iamcco/markdown-preview.nvim",
			run = function()
				vim.fn["mkdp#util#install"]()
			end,
			ft = "markdown",
			cmd = { 
				"MarkdownPreview" 
			},
		}

		-- Status line
		use {
			"nvim-lualine/lualine.nvim",
			after = "nvim-treesitter",
			config = function()
				require("config.lualine").setup()
			end,
			requires = { 
				"nvim-web-devicons"
			},
		}

		-- Show current scope in status line
		use {
			"SmiteshP/nvim-gps",
			requires = "nvim-treesitter/nvim-treesitter",
			module = "nvim-gps",
			config = function()
				require("nvim-gps").setup()
			end,
		}

		-- Treesitter
		use {
			"nvim-treesitter/nvim-treesitter",
			opt = true,
      event = "BufRead",
			run = ":TSUpdate",
			config = function()
				require("config.treesitter").setup()
			end,
      requires = {
        "nvim-treesitter/nvim-treesitter-textobjects"
      },
		}

		-- Fuzzy search
    if PLUGINS.fzf_lua.enabled then
      use {
        "ibhagwan/fzf-lua",
        event = "BufEnter",
        requires = {
          "kyazdani42/nvim-web-devicons"
        },
      }
    end

    -- Improved Netrw
    use {
			"tpope/vim-vinegar"
		}
    
    -- File explorer
		use {
			"kyazdani42/nvim-tree.lua",
			requires = {
				"kyazdani42/nvim-web-devicons",
			},
			cmd = { 
				"NvimTreeToggle",
				"NvimTreeClose"
			},
			config = function()
				require("config.nvimtree").setup()
			end,
		}
    
    -- UI
    use {
      "stevearc/dressing.nvim",
      event = "BufEnter",
      config = function()
        require("dressing").setup {
          select = {
            backend = {
              "telescope",
              "fzf",
              "builtin"
            },
          },
        }
      end,
    }
    
    -- Telescope
    if PLUGINS.telescope.enabled then
      use {
        "nvim-telescope/telescope.nvim",
        opt = true,
        config = function()
          require("config.telescope").setup()
        end,
        cmd = { "Telescope" },
        module = "telescope",
        keys = { "<leader>f", "<leader>p" },
        wants = {
          "plenary.nvim",
          "popup.nvim",
          "telescope-fzf-native.nvim",
          "telescope-project.nvim",
          "telescope-repo.nvim",
          "telescope-file-browser.nvim",
          "project.nvim",
        },
        requires = {
          "nvim-lua/popup.nvim",
          "nvim-lua/plenary.nvim",
          { "nvim-telescope/telescope-fzf-native.nvim", run = "make" },
          "nvim-telescope/telescope-project.nvim",
          "cljoly/telescope-repo.nvim",
          "nvim-telescope/telescope-file-browser.nvim",
          {
            "ahmedkhalf/project.nvim",
            config = function()
              require("project_nvim").setup {}
            end,
          },
        },
      }
    end

    -- Buffer line
    use {
      "akinsho/nvim-bufferline.lua",
      event = "BufReadPre",
      wants = "nvim-web-devicons",
      config = function()
        require("config.bufferline").setup()
      end,
    }

    -- Completions
    use {
      "ms-jpq/coq_nvim",
      branch = "coq",
      event = "InsertEnter",
      opt = true,
      run = ":COQdeps",
      config = function()
        require("config.coq").setup()
      end,
      requires = {
        { 
          "ms-jpq/coq.artifacts",
          branch = "artifacts",
        },
        {
          "ms-jpq/coq.thirdparty",
          branch = "3p",
          module = "coq_3p",
        },
      },
      disable = not PLUGINS.coq.enabled,
    }

    use {
      "hrsh7th/nvim-cmp",
      event = "InsertEnter",
      opt = true,
      config = function()
        require("config.cmp").setup()
      end,
      wants = { "LuaSnip" },
      requires = {
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-nvim-lua",
        "ray-x/cmp-treesitter",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/cmp-nvim-lsp",
        "saadparwaiz1/cmp_luasnip",
        "hrsh7th/cmp-calc",
        "f3fora/cmp-spell",
        "hrsh7th/cmp-emoji",
        "hrsh7th/cmp-nvim-lsp-signature-help",
        {
          "L3MON4D3/LuaSnip",
          wants = { "friendly-snippets", "vim-snippets" },
          config = function()
            require("config.luasnip").setup()
          end,
        },
        "rafamadriz/friendly-snippets",
        "honza/vim-snippets",
      },
      disable = not PLUGINS.nvim_cmp.enabled,
    }
    
    -- Auto pairs
    use {
      "windwp/nvim-autopairs",
      wants = "nvim-treesitter",
      module = {
        "nvim-autopairs.completion.cmp",
        "nvim-autopairs",
      },
      config = function()
        require("config.autopairs").setup()
      end,
    }
    
    -- Auto tag
    use {
      "windwp/nvim-ts-autotag",
      wants = "nvim-treesitter",
      event = "InsertEnter",
      config = function()
        require("nvim-ts-autotag").setup { enable = true }
      end,
    }

    -- End wise 
    use {
      "RRethy/nvim-treesitter-endwise",
      wants = "nvim-treesitter",
      event = "InsertEnter",
    }

    -- LSP
    if PLUGINS.nvim_cmp.enabled then
       use {
        "neovim/nvim-lspconfig",
        opt = true,
        event = "BufReadPre",
        wants = { 
          "nvim-lsp-installer",
          "cmp-nvim-lsp",
          "lua-dev.nvim",
          "vim-illuminate",
          "null-ls.nvim",
          "schemastore.nvim",
          "nvim-lsp-ts-utils",
        },
        config = function()
          require("config.lsp").setup()
        end,
        requires = {
          "williamboman/nvim-lsp-installer",
          "folke/lua-dev.nvim",
          "RRethy/vim-illuminate",
          "jose-elias-alvarez/null-ls.nvim",
          {
            "j-hui/fidget.nvim",
            config = function()
              require("fidget").setup {}
            end,
          },
          "b0o/schemastore.nvim",
          "jose-elias-alvarez/nvim-lsp-ts-utils",
        },
      }
    end
    
    if PLUGINS.coq.enabled then
      use {
        "neovim/nvim-lspconfig",
        opt = true,
        event = "BufReadPre",
        wants = { 
          "nvim-lsp-installer",
          "lsp_signature.nvim",
          "coq_nvim",
          "lua-dev.nvim",
          "vim-illuminate",
          "null-ls.nvim",
          "schemastore.nvim",
          "nvim-lsp-ts-utils",
        },
        config = function()
          require("config.lsp").setup()
        end,
        requires = {
          "williamboman/nvim-lsp-installer",
          "ray-x/lsp_signature.nvim",
          "folke/lua-dev.nvim",
          "RRethy/vim-illuminate",
          "jose-elias-alvarez/null-ls.nvim",
          {
            "j-hui/fidget.nvim",
            config = function()
              require("fidget").setup {}
            end,
          },
          "b0o/schemastore.nvim",
          "jose-elias-alvarez/nvim-lsp-ts-utils",
        },
      }
    end

    -- trouble.nvim
    use {
      "folke/trouble.nvim",
      event = "BufReadPre",
      wants = "nvim-web-devicons",
      cmd = { "TroubleToggle", "Trouble" },
      config = function()
        require("trouble").setup {
          use_diagnostic_signs = true,
        }
      end,
    }

    -- lspsaga.nvim
    use {
      "tami5/lspsaga.nvim",
      event = "VimEnter",
      cmd = { "Lspsaga" },
      config = function()
        require("lspsaga").setup {}
      end,
    }

    -- Rust
    use {
      "simrat39/rust-tools.nvim",
      requires = { "nvim-lua/plenary.nvim", "rust-lang/rust.vim" },
      module = "rust-tools",
      ft = { "rust" },
      config = function()
        require("rust-tools").setup {}
      end,
    }

    -- Go
    use {
      "ray-x/go.nvim",
      ft = { "go" },
      config = function()
        require("go").setup()
      end,
    }

    -- Terminal
    use {
      "akinsho/toggleterm.nvim",
      keys = { [[<C-\>]] },
      cmd = { "ToggleTerm", "TermExec" },
      config = function()
        require("config.toggleterm").setup()
      end,
    }

    -- Testing
    use {
      "rcarriga/vim-ultest",
      requires = { "vim-test/vim-test" },
      opt = true,
      keys = { "<leader>t" },
      cmd = {
        "TestNearest",
        "TestFile",
        "TestSuite",
        "TestLast",
        "TestVisit",
        "Ultest",
        "UltestNearest",
        "UltestDebug",
        "UltestLast",
        "UltestSummary",
      },
      module = "ultest",
      run = ":UpdateRemotePlugins",
      config = function()
        require("config.test").setup()
      end,
    }

    -- Documentation
    use {
      "danymat/neogen",
      config = function()
       require("config.neogen").setup()
      end,
      cmd = { "Neogen" },
      module = "neogen",
      disable = false,
    }

    use {
      "kkoomen/vim-doge",
      run = ":call doge#install()",
      config = function()
       require("config.doge").setup()
      end,
      cmd = { "DogeGenerate", "DogeCreateDocStandard" },
      disable = false,
    }

    use { 
      "python-rope/ropevim", 
      run = "pip install ropevim", 
      disable = false 
    }
    
    if packer_bootstrap then
			print "Restart required"
			require("packer").sync()
		end
	end

	packer_init()

	local packer = require "packer"
	packer.init(conf)
	packer.startup(plugins)
end

return M
