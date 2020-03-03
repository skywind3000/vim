"----------------------------------------------------------------------
" windows
"----------------------------------------------------------------------
let s:windows = g:bundle#windows


"----------------------------------------------------------------------
" ale
"----------------------------------------------------------------------
let g:ale_linters_explicit = 1
let g:ale_completion_delay = 500
let g:ale_echo_delay = 20
let g:ale_lint_delay = 1000
let g:ale_echo_msg_format = '[%linter%] %code: %%s'
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1


"----------------------------------------------------------------------
" wrapper
"----------------------------------------------------------------------
if s:windows == 0 && has('win32unix') == 0
	let g:ale_command_wrapper = 'nice -n5'
endif

let g:airline#extensions#ale#enabled = 1


"----------------------------------------------------------------------
" linters
"----------------------------------------------------------------------
let g:ale_linters = {
			\ 'c': ['gcc', 'cppcheck'], 
			\ 'cpp': ['gcc', 'cppcheck'], 
			\ 'python': ['flake8', 'pylint'], 
			\ 'lua': ['luac'], 
			\ 'go': ['go build', 'gofmt'],
			\ 'java': ['javac'],
			\ 'javascript': ['eslint'], 
			\ }

function! s:lintcfg(name)
	let conf = bundle#path('tools/conf/')
	let path1 = conf . a:name
	let path2 = expand('~/.vim/linter/'. a:name)
	return shellescape(filereadable(path2)? path2 : path1)
endfunc

let g:ale_python_flake8_options = '--conf='.s:lintcfg('flake8.conf')
let g:ale_python_pylint_options = '--rcfile='.s:lintcfg('pylint.conf')
let g:ale_python_pylint_options .= ' --disable=W'
let g:ale_c_gcc_options = '-Wall -O2 -std=c99'
let g:ale_cpp_gcc_options = '-Wall -O2 -std=c++14'
let g:ale_c_cppcheck_options = ''
let g:ale_cpp_cppcheck_options = ''
let g:ale_lua_luacheck_options = '-d'

" let g:ale_linters.text = ['textlint', 'write-good', 'languagetool']
" let g:ale_linters.lua += ['luacheck']

if executable('gcc') == 0 && executable('clang')
	let g:ale_linters.c += ['clang']
	let g:ale_linters.cpp += ['clang']
endif


