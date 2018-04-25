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
let s:persist_loaded = 0
let s:persist_config = {}
let s:persist_dirty = 0
let s:persist_name = expand('~/.vim/vim.cfg')

function! s:persist_init()
	if s:persist_loaded == 0
		let items = {}
		try
			let items = asclib#setting#read_cfg(s:persist_name)
		catch
			let items = {}
		endtry
		let s:persist_config = items
		let s:persist_loaded = 1
	endif
endfunc

function! asclib#setting#persist_save()
	call s:persist_init()
	try
		call asclib#setting#write_cfg(s:persist_name, s:persist_config)
	catch
	endtry
	let s:persist_dirty = 0
endfunc

function! asclib#setting#persist_get(key, default)
	call s:persist_init()
	return get(s:persist_config, a:key, a:default)
endfunc


function! asclib#setting#persist_set(key, value)
	call s:persist_init()
	let s:persist_config[a:key] = a:value
	if s:persist_dirty == 0
		augroup AsclibSettingPersist
			au!
			au VimLeave * call asclib#setting#persist_save()
		augroup END
		let s:persist_dirty = 1
	endif
endfunc



"----------------------------------------------------------------------
" internal functions
"----------------------------------------------------------------------
function! s:string_strip(text)
	return substitute(a:text, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunc

function! asclib#setting#read_cfg(filename)

	function! s:decode_cfg(string) abort
		let item = {}
		if type(a:string) == type('')
			let data = split(a:string, "\n")
		else
			let data = a:string
		endif
		for curline in data
			let pos = stridx(curline, ':')
			if pos <= 0
				continue
			endif
			let name = s:string_strip(strpart(curline, 0, pos))
			let data = s:string_strip(strpart(curline, pos + 1))
			if name == ''
				continue
			endif
			let item[name] = data
		endfor
		return item
	endfunc

	let filename = a:filename
	if stridx(filename, '~') >= 0
		let filename = expand(filename)
	endif
	let data = readfile(filename)
	return s:decode_cfg(data)
endfunc

function! asclib#setting#write_cfg(filename, item) abort

	function! s:encode_cfg(item) 
		let output = []
		for name in keys(a:item)
			let data = a:item[name]
			let name = substitute(name, '[\n\r]', '', 'g')
			let data = substitute(data, '[\n\r]', '', 'g')
			let output += [name . ': ' . data]
		endfor
		return join(output, "\n")
	endfunc

	let filename = a:filename
	if stridx(filename, '~') >= 0
		let filename = expand(filename)
	endif
	let data = s:encode_cfg(a:item)
	call writefile(split(data, "\n"), filename)
endfunc



