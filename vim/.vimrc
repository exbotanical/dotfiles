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
colorscheme nord                              " Change color scheme
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
set ai                                        " Auto-indent

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

" Formatting Configurations
:autocmd BufWritePre * :%s/\s\+$//e           " Strip trailing whitespace when a file is saved

" Status Line
set statusline=                               " Clear status line when vimrc is reloaded
set statusline+=\ %F\ %M\ %Y\ %R              " Status line on left side
set statusline+=%=                            " Use a divider to separate left and right sides
set laststatus=2                              " Show the status on the second to last line
