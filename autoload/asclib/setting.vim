"======================================================================
"
" setting.vim - 
"
" Created by skywind on 2018/02/25
" Last Modified: 2018/02/25 15:05:42
"
"======================================================================


"----------------------------------------------------------------------
" internal config
"----------------------------------------------------------------------
if !exists('g:asclib#setting#config')
	let g:asclib#setting#config = {}
endif

let s:scriptname = expand('<sfile>:p')
let s:scripthome = fnamemodify(s:scriptname, ':h')
let s:windows = has('win32') || has('win64') || has('win95') || has('win16')

let asclib#setting#windows = s:windows

function! asclib#setting#get(key, default)
	return get(g:asclib#setting#config, a:key, a:default)
endfunc

function! asclib#setting#set(key, value)
	let g:asclib#setting#config[a:key] = a:value
endfunc

function! asclib#setting#update(dict)
	for key in keys(a:dict)
		let g:asclib#setting#config[key] = a:dict[key]
	endfor
endfunc

function! asclib#setting#script_home()
	return s:scripthome
endfunc

function! asclib#setting#has_windows()
	return s:windows
endfunc


"----------------------------------------------------------------------
" persist config
"----------------------------------------------------------------------
let s:cfg_loaded = 0
let s:cfg_config = {}
let s:cfg_dirty = 0
let s:cfg_name = expand('~/.vim/asclib.ini')

function! s:cfg_init()
	if s:cfg_loaded == 0
		let items = asclib#ini#read(s:cfg_name)
		if type(items) == type(0)
			let s:cfg_config = {}
		else
			let s:cfg_config = items
		endif
		let s:cfg_loaded = 1
	endif
endfunc

function! asclib#setting#save()
	call s:cfg_init()
	try
		call asclib#ini#save(s:cfg_name, s:cfg_config)
	catch
	endtry
	let s:cfg_dirty = 0
endfunc

function! asclib#setting#read(section, key, ...)
	call s:cfg_init()
	if has_key(s:cfg_config, a:section)
		let section = s:cfg_config[a:section]
		if has_key(section, a:key)
			return section[a:key]
		endif
	endif
	return ((a:0) > 0)? (a:1) : ''
endfunc


function! asclib#setting#write(section, key, value)
	call s:cfg_init()
	if !has_key(s:cfg_config, a:section)
		let s:cfg_config[a:section] = {}
	endif
	let section = s:cfg_config[a:section]
	let section[a:key] = a:value
	if s:cfg_dirty == 0
		augroup AsclibSettingPersist
			au!
			au VimLeave * call asclib#setting#save()
		augroup END
		let s:cfg_dirty = 1
	endif
endfunc



