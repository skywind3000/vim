
let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_smart_case = 1
let g:deoplete#enable_refresh_always = 1

inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<tab>"
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr><BS> deoplete#smart_close_popup()."\<bs>"
inoremap <expr> <cr> pumvisible() ? "\<C-y>\<cr>" : "\<cr>"

if 0
	let g:deoplete#sources = {}
	let g:deoplete#sources._ = ['buffer', 'dictionary']
	" let g:deoplete#sources.cpp = ['clang']
	let g:deoplete#sources.python = ['jedi']
	let g:deoplete#sources.cpp = ['omni']
endif

set shortmess+=c
let g:echodoc#enable_at_startup = 1

if exists('g:python_host_prog')
	let g:deoplete#sources#jedi#python_path = g:python_host_prog
endif

let g:deoplete#sources#jedi#enable_cache = 1

