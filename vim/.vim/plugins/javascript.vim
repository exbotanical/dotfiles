" JavaScript/TypeScript LSP Configuration
if !exists('g:vim_plug_installing_plugins')
  finish
endif

" JavaScript/TypeScript specific plugins
Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'

" LSP server configuration for JavaScript/TypeScript
if executable('typescript-language-server')
  augroup lsp_javascript_typescript
    autocmd!
    autocmd User lsp_setup call lsp#register_server({
      \ 'name': 'typescript-language-server',
      \ 'cmd': {server_info->[&shell, &shellcmdflag, 'typescript-language-server --stdio']},
      \ 'root_uri': {server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), ['package.json', 'tsconfig.json', 'jsconfig.json', '.git/']))},
      \ 'whitelist': ['javascript', 'javascriptreact', 'typescript', 'typescriptreact'],
      \ 'initialization_options': {
      \   'preferences': {
      \     'includeCompletionsForModuleExports': v:true,
      \     'includeCompletionsWithInsertText': v:true,
      \   }
      \ }
      \ })
  augroup END
endif

" Auto-formatting configuration for JavaScript/TypeScript
let g:formatdef_prettier_js = '"prettier --stdin-filepath=".@%." --tab-width=2 --use-tabs=false"'
let g:formatters_javascript = ['prettier_js']
let g:formatters_javascriptreact = ['prettier_js']
let g:formatters_typescript = ['prettier_js']
let g:formatters_typescriptreact = ['prettier_js']

" Format on save for JavaScript/TypeScript files
augroup javascript_typescript_format
  autocmd!
  autocmd BufWritePre *.js,*.jsx,*.ts,*.tsx Autoformat
augroup END
