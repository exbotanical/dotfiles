if exists('g:vim_plug_installing_plugins')
  Plug 'fatih/vim-go'
endif

let g:go_fmt_command                      = "goimports"
let g:go_highlight_types                  = 1
let g:go_highlight_functions              = 1
let g:go_highlight_function_calls         = 1
let g:go_highlight_function_arguments     = 1
let g:go_highlight_operators              = 1
let g:go_highlight_extra_types            = 1
let g:go_highlight_fields                 = 1
let g:go_highlight_variable_assignments   = 1
let g:go_metalinter_autosave              = 1
let g:go_version_warning                  = 0
let g:go_auto_type_info                   = 1
