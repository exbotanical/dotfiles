local M = {}

local indent = 2
local g = vim.g
local cmd = vim.cmd
local opt = vim.opt

function M.setup()
  cmd [[filetype plugin indent on]]
  cmd [[syntax enable]]

  vim.api.nvim_set_keymap("", "<Space>", "<Nop>", { noremap = true, silent = true })
  g.mapleader = " "
  g.maplocalleader = ","

  opt.autoindent = true
  opt.breakindent = true
  opt.clipboard = "unnamed,unnamedplus"
  opt.cmdheight = 1
  opt.cursorline = true
  opt.expandtab = true
  opt.hidden = true
  opt.history = 100
  opt.ignorecase = true
  opt.inccommand = "split"
  opt.lazyredraw = true
  opt.mouse = "a"
  opt.number = true
  opt.pumblend = 17
  opt.relativenumber = false
  opt.scrolloff = 999
  opt.sessionoptions = "blank,buffers,curdir,folds,help,options,tabpages,winsize,resize,winpos,terminal"
  opt.shiftround = true
  opt.shiftwidth = indent
  opt.sidescrolloff = 999
  opt.smartcase = true
  opt.smartindent = true
  opt.smarttab = true
  opt.softtabstop = indent
  opt.splitbelow = true
  opt.splitright = true
  opt.synmaxcol = 240
  opt.tabstop = indent
  opt.termguicolors = true
  opt.timeoutlen = 300
  opt.updatetime = 300
  opt.path:append "**"

  opt.formatoptions = opt.formatoptions
    - "a" -- Auto formatting off.
    - "t" 
    + "c" -- Comments respect text width
    + "q" -- Allow gq to format comments.
    - "o" -- O and o; prevent comments continuation.
    - "r" -- Do not insert a comment after <Enter>
    + "n" -- Indent past the formatlistpat, not beneath it.
    + "j" -- Auto-remove comments where possible.
    - "2" 

  g.python3_host_prog = "/usr/bin/python3"
  g.vim_markdown_fenced_languages = { "html", "javascript", "typescript", "css", "python", "lua", "vim" }
end

M.setup()
