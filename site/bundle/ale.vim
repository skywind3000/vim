"----------------------------------------------------------------------
" windows
"----------------------------------------------------------------------
let s:windows = g:bundle#windows


"----------------------------------------------------------------------
" ale
"----------------------------------------------------------------------
let g:ale_linters_explicit = 1
let g:ale_completion_delay = 500
let g:ale_echo_delay = 100
let g:ale_lint_delay = 1000
let g:ale_echo_msg_format = '[%linter%] %code: %%s [%severity% (%type%)]'
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1
let g:ale_virtualtext_cursor = 0


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

let s:platform = ''

if has('win32')
	let s:platform = '-Id:/dev/local/include'
endif

let g:ale_python_flake8_options = '--conf='.s:lintcfg('flake8.conf')
let g:ale_python_pylint_options = '--rcfile='.s:lintcfg('pylint.conf')
let g:ale_python_pylint_options .= ' --disable=W'
let g:ale_c_gcc_options = '-Wall -O2 -std=c99 ' . s:platform
let g:ale_cpp_gcc_options = '-Wall -O2 -std=c++14 ' . s:platform
let g:ale_c_clang_options = '-Wall -O2 ' . s:platform
let g:ale_cpp_clang_options = '-Wall -O2 ' . s:platform
let g:ale_c_cc_options = '-Wall -std=c99 ' . s:platform
let g:ale_cpp_cc_options = '-Wall -std=c++14 ' . s:platform
let g:ale_lua_luacheck_options = '-d'
let g:ale_c_splint_options = '-f '. s:lintcfg('splint.conf')

if executable('gcc') == 0 && executable('clang')
	let g:ale_linters.c += ['clang']
	let g:ale_linters.cpp += ['clang']
endif

if executable('clang-tidy')
	" let g:ale_linters.c += ['clangtidy']
	" let g:ale_linters.cpp += ['clangtidy']
endif


" let g:ale_linters.text = ['textlint', 'write-good', 'languagetool']
" let g:ale_linters.lua += ['luacheck']

"----------------------------------------------------------------------
" cppcheck
"----------------------------------------------------------------------
let s:cppcheck = '--enable=warning,style,portability,performance,information'
let s:cppcheck .= ' --suppressions-list=' . s:lintcfg('cppcheck.conf')


" let s:cppcheck .= ' --inline-suppr'
let g:ale_c_cppcheck_options = s:cppcheck
let g:ale_cpp_cppcheck_options = s:cppcheck


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
noremap [z :ALEPrevious<cr>
noremap ]z :ALENext<cr>
noremap [Z :ALEFirst<cr>
noremap ]Z :ALELast<cr>


