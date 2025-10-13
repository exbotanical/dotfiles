" Plugins
call plug#begin('~/.vim/plugged')

" Source all the plugins with a global variable set that ensures only the
" Plugin 'name' code will be called
let g:vim_plug_installing_plugins = 1
for file in split(glob('$HOME/.vim/plugins/*.vim'), '\n')
  exe 'source' fnameescape(file)
endfor

unlet g:vim_plug_installing_plugins

call plug#end()

" Indentation
set expandtab                                 " Convert tabs to spaces
set smarttab                                  " Insert “tabstop” number of spaces when the “tab” key is pressed
set shiftwidth=2                              " When shifting, indent using n spaces
set tabstop=2                                 " Indent using n spaces
set shiftround                                " When shifting lines, round the indentation to the nearest multiple of “shiftwidth”
set autoindent                                " Always set auto-indenting on
set copyindent                                " Copy the previous indentation on auto-indenting
filetype plugin indent on

" Text Rendering
set display+=lastline                         " Always try to show a paragraph's last line
set encoding=utf-8                            " Use an encoding that supports unicode
set linebreak                                 " Avoid wrapping a line in the middle of a word
set scrolloff=1                               " The number of screen lines to keep above and below the cursor
set sidescrolloff=5                           " The number of screen columns to keep to the left and right of the cursor
syntax enable                                 " Enable syntax highlighting
set wrap                                      " Enable line wrapping
set showmatch                                 " Show matching parenthesis
set matchtime=2                               " Expedite matches
set list                                      " Display whitespace (list mode)
set listchars=""                              " Characters used in list mode
set listchars+=trail:•                        " Characters used to show trailing spaces
set listchars=tab:▸▸                          " Characters used to show tabs
set textwidth=80                              " Wrap lines at n characters

" UI Options
set ruler                                     " Always show cursor position
set wildmenu                                  " Display command line's tab complete options as a menu
set wildmode=list:longest                     " Make wildmenu behave like Bash completions
set wildignore=*.docx,*.jpg,*.png,*.gif       " Wildmenu will ignore files with these extensions
set wildignore+=*.pdf,*.pyc,*.exe,*.flv,*.img
set wildignore+=*.xlsx,*.o,*.obj,*.exe,*.so
set wildignore+=.svn,.git,*.class,*/node_modules/*
set tabpagemax=50                             " Maximum number of tab pages that can be opened from the command line
colorscheme dracula                           " Change color scheme
set termguicolors
set cursorline                                " Highlight the line currently under cursor
set cursorcolumn                              " Highlight the screen column of the cursor
set mouse=a                                   " Enable mouse for scrolling and resizing
set title                                     " Set the window's title, reflecting the file currently being edited
set background=dark                           " Use colors that suit a dark background
set number                                    " Show line number
set guifont="Fira Code"\ 16                   " Set font

" Behavior
set clipboard+=unnamed                        " Yanks go on clipboard instead

" Editing
set foldnestmax=3                             " Only fold up to n nested levels

" Miscellaneous Options
set backspace=indent,eol,start                " Allow backspacing over indention, line breaks and insertion start
set backupdir=~/.cache/vim                    " Directory to store backup files
set dir=~/.cache/vim                          " Directory to store swap files
set formatoptions+=j                          " Delete comment characters when joining lines
set history=1000                              " Increase the undo limit
set nomodeline                                " Ignore files' mode lines; use vimrc configurations instead
set noswapfile                                " Disable swap files
set nrformats-=octal                          " Interpret octal as decimal when incrementing numbers
set shell=/bin/bash                           " The shell used to execute commands
set spell                                     " Enable spellchecking
set nocompatible                              " Don't sacrifice functionality just to preserve backward compatibility with vi

" Enhanced LSP Configuration
let g:lsp_diagnostics_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_diagnostics_signs_enabled = 1
let g:lsp_diagnostics_virtual_text_enabled = 1
let g:lsp_text_edit_enabled = 1
let g:lsp_preview_float = 1
let g:lsp_diagnostics_float_cursor = 1
let g:lsp_hover_conceal = 0
let g:lsp_preview_keep_focus = 0
let g:lsp_fold_enabled = 0
let g:lsp_signature_help_enabled = 1
let g:lsp_completion_resolve_timeout = 60
let g:lsp_async_completion = 1

" Asyncomplete configuration
let g:asyncomplete_auto_popup = 1
let g:asyncomplete_auto_completeopt = 0
let g:asyncomplete_popup_delay = 200
let g:asyncomplete_close_preview_on_insert = 1

" Auto-formatting configuration
let g:autoformat_autoindent = 0
let g:autoformat_retab = 0
let g:autoformat_remove_trailing_spaces = 0

" LSP key mappings
function! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    setlocal signcolumn=yes
    if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif

    " Navigation
    nmap <buffer> gd <plug>(lsp-definition)
    nmap <buffer> gD <plug>(lsp-declaration)
    nmap <buffer> gs <plug>(lsp-document-symbol-search)
    nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
    nmap <buffer> gr <plug>(lsp-references)
    nmap <buffer> gi <plug>(lsp-implementation)
    nmap <buffer> gt <plug>(lsp-type-definition)
    nmap <buffer> <leader>rn <plug>(lsp-rename)
    nmap <buffer> [g <plug>(lsp-previous-diagnostic)
    nmap <buffer> ]g <plug>(lsp-next-diagnostic)
    nmap <buffer> K <plug>(lsp-hover)

    " Formatting
    nmap <buffer> <leader>f <plug>(lsp-document-format)
    vmap <buffer> <leader>f <plug>(lsp-document-range-format)

    " Code actions
    nmap <buffer> <leader>ca <plug>(lsp-code-action)

    " Workspace management
    nmap <buffer> <leader>wa <plug>(lsp-workspace-folders-add)
    nmap <buffer> <leader>wr <plug>(lsp-workspace-folders-remove)
    nmap <buffer> <leader>wl <plug>(lsp-workspace-folders-list)

    " Enable inlay hints if supported
    if exists('*lsp#get_server_capabilities')
        let l:capabilities = lsp#get_server_capabilities(lsp#get_server_names()[0])
        if has_key(l:capabilities, 'inlayHintProvider')
            call lsp#enable_inlay_hints()
        endif
    endif
endfunction

augroup lsp_install
    au!
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

" Diagnostic signs
let g:lsp_diagnostics_signs_error = {'text': '✗'}
let g:lsp_diagnostics_signs_warning = {'text': '⚠'}
let g:lsp_diagnostics_signs_information = {'text': 'ℹ'}
let g:lsp_diagnostics_signs_hint = {'text': '💡'}

" Formatting Configurations
:autocmd BufWritePre * :%s/\s\+$//e           " Strip trailing whitespace when a file is saved

" Status Line
set statusline=                               " Clear status line when vimrc is reloaded
set statusline+=\ %F\ %M\ %Y\ %R              " Status line on left side
set statusline+=%=                            " Use a divider to separate left and right sides
set laststatus=2                              " Show the status on the second to last line
