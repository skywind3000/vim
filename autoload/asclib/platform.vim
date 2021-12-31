"======================================================================
"
" platform.vim - 
"
" Created by skywind on 2021/12/26
" Last Modified: 2021/12/26 02:29:06
"
"======================================================================

" vim: set ts=4 sw=4 tw=78 noet :

"----------------------------------------------------------------------
" uname -a
"----------------------------------------------------------------------
function! asclib#platform#system_uname(...)
	let force = (a:0 >= 1)? (a:1) : 0
	if exists('s:system_uname') == 0 || force != 0
		if has('win32') || has('win64') || has('win95') || has('win16')
			let uname = asclib#core#system('call cmd.exe /c ver')
			let uname = substitute(uname, '\s*\n$', '', 'g')
			let uname = substitute(uname, '^\s*\n', '', 'g')
			let uname = join(split(uname, '\n'), '')
		else
			let uname = substitute(system("uname -a"), '\s*\n$', '', 'g')
		endif
		let s:system_uname = uname
	endif
	return s:system_uname
endfunc


"----------------------------------------------------------------------
" system detection 
"----------------------------------------------------------------------
if has('win32') || has('win64') || has('win95') || has('win16')
	let s:uname = 'windows'
elseif has('win32unix')
	let s:uname = 'cygwin'
elseif has('linux') || has('wsl')
	let s:uname = 'linux'
elseif has('mac') || has('macunix') || has('macvim') || has('gui_macvim')
	let s:uname = 'darwin'
elseif has('bsd')
	let s:uname = 'bsd'
elseif has('unix')
	let s:uname = asclib#platform#system_uname()
	if v:shell_error == 0 && match(s:uname, 'Linux') >= 0
		let s:uname = 'linux'
	elseif v:shell_error == 0 && match(s:uname, 'FreeBSD') >= 0
		let s:uname = 'bsd'
	elseif v:shell_error == 0 && match(s:uname, 'Darwin') >= 0
		let s:uname = 'darwin'
	else
		let s:uname = 'posix'
	endif
else
	let s:uname = 'posix'
endif


"----------------------------------------------------------------------
" gui detection
"----------------------------------------------------------------------
let s:gui_running = 0

if has('gui_running')
	let s:gui_running = 1
elseif has('nvim')
	if exists('g:GuiLoaded')
		if g:GuiLoaded != 0
			let s:gui_running = 1
		endif
	elseif exists('*nvim_list_uis') && len(nvim_list_uis()) > 0
		let uis = nvim_list_uis()[0]
		let s:gui_running = get(uis, 'ext_termcolors', 0)? 0 : 1
	elseif exists("+termguicolors") && (&termguicolors) != 0
		let s:gui_running = 1
	endif
endif


"----------------------------------------------------------------------
" ostype
"----------------------------------------------------------------------
function! asclib#platform#uname()
	return s:uname
endfunc


"----------------------------------------------------------------------
" check gui
"----------------------------------------------------------------------
function! asclib#platform#gui_running()
	return s:gui_running
endfunc


"----------------------------------------------------------------------
" check wsl
"----------------------------------------------------------------------
function! asclib#platform#has_wsl()
	if exists('s:has_wsl') == 0
		let s:has_wsl = 0
		if s:uname == 'linux'
			let uname = asclib#platform#system_uname()
			if match(uname, 'Microsoft') >= 0
				let s:has_wsl = 1
			endif
		endif
	endif
	return s:has_wsl
endfunc



