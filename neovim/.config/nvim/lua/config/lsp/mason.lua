local M = {}

-- Install LSP servers
function M.setup()
	local servers = {
		-- AWK
		'awk_ls',
		-- Bash
		'bashls',
		-- c/c++
		'clangd',
		-- CSS
		'cssls',
		-- Docker
		'dockerls',
		-- ESLint
		'eslint',
		-- Go
		'gopls',
		-- Gradle
		'gradle_ls',
		-- HTML
		'html',
		-- JSON
		'jsonls',
		-- Java
		'jdtls',
		-- JavaScript/TypeScript
		'tsserver',
		-- Lua
		'sumneko_lua',
		-- Markdown
		'marksman',
		-- Python
		'pyright',
		-- Solidity
		'solang',
		-- Stylelint
		'stylelint_lsp',
		-- TOML
		'taplo',
		-- Tailwind
		'tailwindcss',
		-- Vue
		'volar',
		-- YAML
		'yamlls'
	}

	local settings = {
		ui = {
			border = 'none',
			icons = {
				package_installed = '◍',
				package_pending = '◍',
				package_uninstalled = '◍',
			},
		},
		log_level = vim.log.levels.INFO,
		max_concurrent_installers = 4,
	}

	require('mason').setup(settings)
	require('mason-lspconfig').setup({
		ensure_installed = servers,
		automatic_installation = true,
	})

	local lspconfig = require('lspconfig')

	local opts = {}
	for _, server in pairs(servers) do
		opts = {
			on_attach = require('config.lsp.handlers').on_attach,
			capabilities = require('config.lsp.handlers').capabilities,
		}

		server = vim.split(server, '@')[1]

		local ok, lsp_config = pcall(require, 'config.lsp.settings' .. server)
		if ok then
			opts = vim.tbl_deep_extend('force', lsp_config, opts)
		end

		lspconfig[server].setup(opts)
	end

end

return M
