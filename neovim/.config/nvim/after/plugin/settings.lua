local M = {}

function M.auto_cmds()
  -- Highlight on yank
  vim.cmd "au TextYankPost * silent! lua vim.highlight.on_yank()"

  vim.cmd [[
    autocmd InsertLeave,WinEnter * set cursorline
    autocmd InsertEnter,WinLeave * set nocursorline
  ]]

  vim.cmd [[
        set wildmode=longest,list,full
        set wildoptions=pum
        set wildmenu
        set wildignore+=*.pyc
        set wildignore+=*_build/*
        set wildignore+=**/coverage/*
        set wildignore+=**/node_modules/*
        set wildignore+=**/android/*
        set wildignore+=**/ios/*
        set wildignore+=**/.git/*
    ]]

  -- don't auto comment new lines
  vim.cmd [[au BufEnter * set fo-=c fo-=r fo-=o]]

  vim.api.nvim_exec(
    [[
        cnoreabbrev W! w!
        cnoreabbrev Q! q!
        cnoreabbrev Qall! qall!
        cnoreabbrev Wq wq
        cnoreabbrev Wa wa
        cnoreabbrev wQ wq
        cnoreabbrev WQ wq
        cnoreabbrev W w
        cnoreabbrev Q q
        cnoreabbrev Qall qall
    ]],
    false
  )

  -- Terminal
  vim.api.nvim_exec(
    [[
      augroup auto_term
        autocmd!
        autocmd TermOpen * setlocal nonumber norelativenumber
        autocmd TermOpen * startinsert
      augroup END
    ]],
    false
  )

  -- Trimming and highlight search
  vim.api.nvim_exec(
    [[
      fun! TrimWhitespace()
        let l:save = winsaveview()
        keeppatterns %s/\s\+$//e
        call winrestview(l:save)
      endfun

      "-- autocmd FileType * autocmd BufWritePre <buffer> call TrimWhitespace()

      nnoremap <expr> <CR> {-> v:hlsearch ? ":nohl\<CR>" : "\<CR>"}()
    ]],
    false
  )

  -- Window highlight
  vim.api.nvim_exec(
    [[
      hi InactiveWindow guibg=#282C34
      autocmd VimEnter * set winhighlight=Normal:ActiveWindow,NormalNC:InactiveWindow
    ]],
    false
  )

  -- Go to last location
  vim.cmd [[
    autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif
  ]]

  vim.api.nvim_exec(
    [[
      autocmd BufNewFile  test_*.py	0r ~/.config/nvim/snippets/unittest.py
      autocmd BufNewFile  *.html	0r ~/.config/nvim/snippets/html5.html
      xmap <silent> . :normal .<CR>
    ]],
    false
  )
end

function M.setup()
  M.auto_cmds()
end

M.setup()
