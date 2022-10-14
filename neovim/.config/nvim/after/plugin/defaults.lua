local api = vim.api
local g = vim.g
local opt = vim.opt

-- Remap leader and local leader to <Space>
api.nvim_set_keymap("", "<Space>", "<Nop>", {
  noremap = true,
  silent = true
})

-- Leader
g.mapleader = " "
g.maplocalleader = " "

-- Enable 24-bit RGB TUI colors
opt.termguicolors = true 
-- Set highlight on search
opt.hlsearch = true
-- Use line numbers
opt.number = true
-- Relative line numbers
opt.relativenumber = false
-- Enable mouse
opt.mouse = "a"
-- Break indent
opt.breakindent = true
-- Save undo history
opt.undofile = true
-- Case insensitive search
opt.ignorecase = true
-- Override `ignorecase` if search pattern contains upper
opt.smartcase = true
-- Decrease update time
opt.updatetime = 250
-- Always show sign column
opt.signcolumn = "yes"
-- Sys clipboard
opt.clipboard = "unnamedplus"

-- Highlight on yank
vim.cmd [[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank()
  augroup end
]]

-- Time in ms to wait for a mapped sequence to complete 
opt.timeoutlen = 300

-- Improved search
opt.path:remove "/usr/include"
-- Add all current folder's subdirectories to search
opt.path:append "**"

-- Alternatively, set the path
-- vim.cmd [[set path=.,,,$PWD/**]]

-- Perform case-insensitive search
opt.wildignorecase = true

-- Ignore directories in search
opt.wildignore:append "**/node_modules/*"
opt.wildignore:append "**/dist/*"
opt.wildignore:append "**/.git/*"
opt.wildignore:append "**/build/*"

-- Improved Netrw (overriden by nvimtree) --
-- Hide banner
-- g.netrw_banner = 0
-- -- Open in previous window
-- g.netrw_browse_split = 4
-- -- Open with right-splitting
-- g.netrw_altv = 1
-- -- Tree-style view
-- g.netrw_liststyle = 3
-- -- Use .gitignore
-- g.netrw_list_hide = (vim.fn["netrw_gitignore#Hide"]()) .. [[,\(^\|\s\s\)\zs\.\S\+]]  

-- Treesitter based folding
vim.cmd [[
  set foldlevel=20
  set foldmethod=expr
  set foldexpr=nvim_treesitter#foldexpr()
]]
