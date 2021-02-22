"======================================================================
"
" c.vim - c language module
"
" Created by skywind on 2021/02/19
" Last Modified: 2021/02/19 00:56:35
"
"======================================================================

"----------------------------------------------------------------------
" guard: take care vim-plug call setfiletype multiple times
"----------------------------------------------------------------------
if exists('b:ftplugin_init_c')
	if get(b:, 'did_ftplugin', 0) == 2
		finish
	endif
endif

let b:ftplugin_init_c = 1

" prevent vim-plug set ft=? twice
if exists('b:did_ftplugin')
	let b:did_ftplugin = 2
endif

if &ft == 'cpp'
	setlocal commentstring=//\ %s
endif

let b:commentary_format = "// %s"
let s:windows = has('win32') || has('win64') || has('win95') || has('win16')


"----------------------------------------------------------------------
" splint
"----------------------------------------------------------------------
if !exists('g:ftplugin_init_splint')
	if get(g:, 'ale_enabled', 0) != 0
		IncScript site/opt/ale_splint.vim
		" IncScript site/opt/ale_cppcheck.vim
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
	let b:ftplugin_fmt_astyle = &l:formatprg
endif


"----------------------------------------------------------------------
" format: clang-format
"----------------------------------------------------------------------
function! InitClangFormat()
	if get(s:, 'has_clang', -1) < 0
		let s:has_clang = executable('clang-format')
	endif
	let s:windows = has('win32') || has('win95') || has('win64')
	let fallback = get(g:, 'asc_format_clang_style', 'Microsoft')
	if s:has_clang > 0
		let prg = (s:windows)? 'call clang-format' : 'clang-format'
		let prg .= ' -style=file --fallback-style=' . fallback
		let name = expand('%:t')
		if name != ''
			let prg .= ' -assume-filename=' . shellescape(name)
			let cd = (s:windows)? 'cd /D ' : 'cd '
			let cd = cd . shellescape(expand('%:p:h')) . ' && '
			let prg = cd . prg
		endif
		let &l:formatprg = prg
	endif
endfunction

if get(g:, 'asc_format_clang', 1) != 0
	call InitClangFormat()
endif


