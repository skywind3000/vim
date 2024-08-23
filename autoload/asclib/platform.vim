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
" detect
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win64') || has('win95') || has('win16')
let g:asclib#platform#windows = s:windows
let g:asclib#platform#has_nvim = has('nvim')
let g:asclib#platform#has_vim9 = v:version >= 900
let g:asclib#platform#has_popup = exists('*popup_create') && v:version >= 800
let g:asclib#platform#has_floating = has('nvim-0.4')
let g:asclib#platform#has_vim9script = (v:version >= 900) && has('vim9script')
let g:asclib#platform#has_nvim_040 = has('nvim-0.4')
let g:asclib#platform#has_nvim_050 = has('nvim-0.5.0')
let g:asclib#platform#has_nvim_060 = has('nvim-0.6.0')
let g:asclib#platform#has_nvim_070 = has('nvim-0.7.0')
let g:asclib#platform#has_nvim_080 = has('nvim-0.8.0')
let g:asclib#platform#has_vim_820 = (has('nvim') == 0 && has('patch-8.2.1'))
let g:asclib#platform#has_win_exe = exists('*win_execute')


"----------------------------------------------------------------------
" uname -a
"----------------------------------------------------------------------
function! asclib#platform#system_uname(...)
	let force = (a:0 >= 1)? (a:1) : 0
	if exists('s:system_uname') == 0 || force != 0
		if s:windows
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
elseif has('gui_mac')
	let s:uname = 'darwin'
elseif has('dos16') || has('dos32')
	let s:uname = 'dos'
elseif has('bsd')
	let s:uname = 'bsd'
elseif has('sun')
	let s:uname = 'sunos'
elseif has('unix')
	let s:uname = asclib#platform#system_uname()
	if v:shell_error == 0 && match(s:uname, 'Linux') >= 0
		let s:uname = 'linux'
	elseif v:shell_error == 0 && match(s:uname, 'FreeBSD') >= 0
		let s:uname = 'bsd'
	elseif v:shell_error == 0 && match(s:uname, 'Darwin') >= 0
		let s:uname = 'darwin'
	elseif v:shell_error == 0 && match(s:uname, 'SunOS') >= 0
		let s:uname = 'sunos'
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
" omni "has" interface
"----------------------------------------------------------------------
function! asclib#platform#has(what)
	let what = a:what
	if what == 'wsl'
		return asclib#platform#has_wsl()
	elseif what == 'python'
		return asclib#platform#has_python()
	elseif what == 'gui_running'
		return asclib#platform#gui_running()
	elseif what == 'msys'
		return (has('win32unix') && isdirectory('/cygdrive/c') == 0)
	elseif what == 'cygwin'
		return (has('win32unix') && isdirectory('/cygdrive/c'))
	elseif what == 'windows' || what == 'win'
		return s:windows
	endif
	return has(what)
endfunc


"----------------------------------------------------------------------
" check wsl
"----------------------------------------------------------------------
function! asclib#platform#has_wsl()
	if exists('s:has_wsl')
		return s:has_wsl
	elseif s:uname != 'linux'
		return 0
	endif
	let s:has_wsl = 0
	let f = '/proc/version'
	if filereadable(f)
		try
			let text = readfile(f, '', 3)
		catch
			let text = []
		endtry
		for t in text
			if match(t, 'Microsoft') >= 0
				let s:has_wsl = 1
				return 1
			endif
		endfor
	endif
	let cmd = '/mnt/c/Windows/System32/cmd.exe'
	if !executable(cmd)
		" can't return here, some windows may locate
		" in somewhere else.
	endif
	if $WSL_DISTRO_NAME != ''
		let s:has_wsl = 1
		return 1
	endif
	let uname = asclib#platform#system_uname()
	if match(uname, 'Microsoft') >= 0
		let s:has_wsl = 1
	endif
	return s:has_wsl
endfunc



"----------------------------------------------------------------------
" check python: returns 0, 2, 3
"----------------------------------------------------------------------
function! asclib#platform#has_python()
	return asclib#python#has_python()
endfunc


"----------------------------------------------------------------------
" check time
"----------------------------------------------------------------------
function! asclib#platform#benchmark()
	let t1 = asclib#core#clock()
	call asclib#platform#has_python()
	silent call asclib#python#init()
	return asclib#core#clock() - t1
endfunc



