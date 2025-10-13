" JSON-specific settings
setlocal tabstop=2
setlocal shiftwidth=2
setlocal expandtab
setlocal autoindent
setlocal smartindent

" Enable LSP for JSON files
if executable('vscode-json-language-server')
    augroup LspJson
        au!
        autocmd User lsp_setup call lsp#register_server({
            \ 'name': 'json-languageserver',
            \ 'cmd': {server_info->['vscode-json-language-server', '--stdio']},
            \ 'whitelist': ['json', 'jsonc'],
            \ 'workspace_config': {
            \   'json': {
            \     'schemas': [],
            \     'format': {
            \       'enable': v:true
            \     }
            \   }
            \ }
            \ })
    augroup END
endif

" Auto-format on save
autocmd BufWritePre *.json call execute('LspDocumentFormat')

" Key mappings for JSON files
nnoremap <buffer> <leader>f :LspDocumentFormat<CR>
nnoremap <buffer> gd :LspDefinition<CR>
nnoremap <buffer> gr :LspReferences<CR>
nnoremap <buffer> K :LspHover<CR>
nnoremap <buffer> <leader>rn :LspRename<CR>

" Enable folding for JSON
setlocal foldmethod=syntax
setlocal foldlevelstart=1
