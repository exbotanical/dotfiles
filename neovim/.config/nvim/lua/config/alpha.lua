local M = {}

function M.setup()
	local status_ok, alpha = pcall(require, "alpha")
	if not status_ok then
		return
	end

	local dashboard = require "alpha.themes.dashboard"
	local function header()
			return {
				-- TODO
				[[some ascii]] 
			}
	end
	
	dashboard.section.header.val = header()

	dashboard.section.buttons.val = {
    		dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
		dashboard.button("c", "  Configuration", ":e $MYVIMRC <CR>"),
    		dashboard.button("q", "  Quit Neovim", ":qa<CR>"),
	}

	local function footer()
		local n_plugins = #vim.tbl_keys(packer_plugins)
		local datetime = os.date "%d/%m/%Y %H:%M:%S"
		local plugins_text = 
		"   "
		.. n_plugins
		.. " plugins"
		.. "   v"
		.. vim.version().major
		.. "."
		.. vim.version().minor
		.. "."
		.. vim.version().patch
		.. "   "
		.. datetime

		return plugins_text .. "\n"
	end

	dashboard.section.footer.val = footer()

	dashboard.section.footer.opts.h1 = "Constant"
	dashboard.section.header.opts.h1 = "Include"
	dashboard.section.buttons.opts.h1 = "Function"
	dashboard.section.buttons.opts.h1_shortcut = "Type"
	dashboard.opts.opts.noautocmd = true
	
	alpha.setup(dashboard.opts)
end

return M
