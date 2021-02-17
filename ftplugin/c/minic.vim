if exists('b:ftplugin_init_c')
	finish
endif

let b:ftplugin_init_c = 1

" IncScript site/opt/ale_cppcheck.vim

setlocal commentstring=//\ %s
setlocal comments-=:// comments+=:///,://

let b:commentary_format = "// %s"

if &ft == 'cpp'
	finish
endif


"----------------------------------------------------------------------
" splint
"----------------------------------------------------------------------
if !exists('g:ftplugin_init_splint')
	if get(g:, 'ale_enabled', 0) != 0
		IncScript site/opt/ale_splint.vim
		let g:ftplugin_init_splint = 1
	endif
endif


"----------------------------------------------------------------------
" format: astyle
"----------------------------------------------------------------------
if get(s:, 'has_astyle', -1) < 0
	let s:has_astyle = executable('astyle')
	let prg = 'astyle --indent=tab --style=kr'
	let prg .= ' --pad-oper'
	let prg .= ' --pad-comma'
	let prg .= ' --pad-header'
	let prg .= ' --align-pointer=middle'
	let prg .= ' --align-reference=middle'
	let prg .= ' --break-closing-braces'
	" let prg .= ' --break-return-type'
	let s:format_astyle = prg
endif

if s:has_astyle > 0
	let &l:formatprg = s:format_astyle
endif



