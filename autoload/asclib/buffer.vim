" vim: set ts=4 sw=4 tw=78 noet :
"======================================================================
"
" buffer.vim - 
"
" Created by skywind on 2022/10/01
" Last Modified: 2022/10/01 22:45:06
"
"======================================================================


"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let s:has_getbufinfo = exists('*getbufinfo')
let s:has_setbufline = exists('*setbufline')
let s:has_getbufline = exists('*getbufline')
let s:has_deletebufline = exists('*deletebufline')
let s:has_appendbufline = exists('*appendbufline')


"----------------------------------------------------------------------
" alloc a new buffer
"----------------------------------------------------------------------
function! asclib#buffer#alloc()
	if !exists('s:buffer_array')
		let s:buffer_array = {}
	endif
	let index = len(s:buffer_array) - 1
	if index >= 0
		let bid = s:buffer_array[index]
		unlet s:buffer_array[index]
	else
		if has('nvim') == 0
			let bid = bufadd('')
			call bufload(bid)
			call setbufvar(bid, '&buflisted', 0)
			call setbufvar(bid, '&bufhidden', 'hide')
			call setbufvar(bid, '&buftype', 'nofile')
			call setbufvar(bid, 'noswapfile', 1)
		else
			let bid = nvim_create_buf(v:false, v:true)
			call setbufvar(bid, '&buftype', 'nofile')
			call setbufvar(bid, '&bufhidden', 'hide')
			call setbufvar(bid, 'noswapfile', 1)
		endif
	endif
	call setbufvar(bid, '&modifiable', 1)
	silent call deletebufline(bid, 1, '$')
	call setbufvar(bid, '&modified', 0)
	call setbufvar(bid, '&filetype', '')
	return bid
endfunc


"----------------------------------------------------------------------
" free a buffer
"----------------------------------------------------------------------
function! asclib#buffer#release(bid)
	if !exists('s:buffer_array')
		let s:buffer_array = {}
	endif
	let index = len(s:buffer_array)
	let s:buffer_array[index] = a:bid
	call setbufvar(a:bid, '&modifiable', 1)
	silent call deletebufline(a:bid, 1, '$')
	call setbufvar(a:bid, '&modified', 0)
endfunc


"----------------------------------------------------------------------
" update buffer content
"----------------------------------------------------------------------
function! asclib#buffer#update(bid, textlist)
	if type(a:textlist) == v:t_list
		let textlist = a:textlist
	else
		let textlist = split('' . a:textlist, '\n', 1)
	endif
	let old = getbufvar(a:bid, '&modifiable', 0)
	call setbufvar(a:bid, '&modifiable', 1)
	if s:has_deletebufline && s:has_setbufline
		silent call deletebufline(a:bid, 1, '$')
		silent call setbufline(a:bid, 1, textlist)
	elseif a:bid == bufnr('%')
		silent exec 'noautocmd 1,$d'
		silent call setline(1, textlist)
	endif
	call setbufvar(a:bid, '&modified', old)
endfunc


"----------------------------------------------------------------------
" clear buffer content
"----------------------------------------------------------------------
function! asclib#buffer#clear(bid)
	call asclib#buffer#update(a:bid, [])
endfunc


"----------------------------------------------------------------------
" get named buffer
"----------------------------------------------------------------------
function! asclib#buffer#named(name)
	if !exists('s:buffer_cache')
		let s:buffer_cache = {}
	endif
	if a:name != ''
		let bid = get(s:buffer_cache, a:name, -1)
	else
		let bid = -1
	endif
	if bid < 0
		let bid = asclib#buffer#alloc()
		if a:name != ''
			let s:buffer_cache[a:name] = bid
		endif
	endif
	return bid
endfunc


"----------------------------------------------------------------------
" buffer local object
"----------------------------------------------------------------------
function! asclib#buffer#object(bid)
	let name = '__asclib__'
	if type(a:bid) == 0
		let bid = (a:bid >= 0)? bufnr(a:bid) : (bufnr(''))
	else
		let bid = bufnr(a:bid)
	endif
	if bufexists(bid) == 0
		return v:null
	endif
	let obj = getbufvar(bid, name)
	if type(obj) != 4
		call setbufvar(bid, name, {})
		let obj = getbufvar(bid, name)
	endif
	return obj
endfunc


"----------------------------------------------------------------------
" list buffer bid
"----------------------------------------------------------------------
function! asclib#buffer#list(...)
	let l:ls_cli = get(g:, 'asclib#buffer#list_cli', 'ls t')
	let l:ls_cli = (a:0 > 0)? (a:1) : (l:ls_cli)
	redir => buflist
	silent execute l:ls_cli
	redir END
	let bids = []
	for curline in split(buflist, '\n')
		if curline =~ '^\s*\d\+'
			let bid = str2nr(matchstr(curline, '^\s*\zs\d\+'))
			let bids += [bid]
		endif
	endfor
	return bids
endfunc


"----------------------------------------------------------------------
" check if contains variable
"----------------------------------------------------------------------
function! asclib#buffer#contains(bid, varname)
	let obj = asclib#buffer#object(a:bid)
	if type(obj) == type(v:null)
		return 0
	endif
	return has_key(obj, a:varname)
endfunc


"----------------------------------------------------------------------
" setbufvar
"----------------------------------------------------------------------
function! asclib#buffer#setvar(bid, varname, value)
	let obj = asclib#buffer#object(a:bid)
	if type(obj) == 4
		let obj[a:varname] = a:value
	endif
endfunc


"----------------------------------------------------------------------
" getbufvar
"----------------------------------------------------------------------
function! asclib#buffer#getvar(bid, varname, default)
	let obj = asclib#buffer#object(a:bid)
	if type(obj) == 4
		return get(obj, a:varname, a:default)
	endif
	return a:default
endfunc


"----------------------------------------------------------------------
" autocmd
"----------------------------------------------------------------------
function! asclib#buffer#autocmd(bid, group, funcname) abort
	exec printf('autocmd %s <buffer=%d> call %s()', a:group, a:bid, a:funcname)
endfunc


"----------------------------------------------------------------------
" remove all autocmd
"----------------------------------------------------------------------
function! asclib#buffer#remove_autocmd(bid, group) abort
	exec printf('autocmd! %s <buffer=%d>', a:group, a:bid)
endfunc


"----------------------------------------------------------------------
" append buffer
"----------------------------------------------------------------------
function! asclib#buffer#append(bid, lnum, text) abort
	if s:has_appendbufline
		call appendbufline(a:bid, a:lnum, a:text)
	elseif bufnr('%') == a:bid
		call append(a:lnum, a:text)
	endif
endfunc


"----------------------------------------------------------------------
" deletebufline
"----------------------------------------------------------------------
function! asclib#buffer#deleteline(bid, lnum, end) abort
	if s:has_deletebufline
		silent let hr = deletebufline(a:bid, a:lnum, a:end)
		return hr
	elseif bufnr('%') == a:bid
		silent noautocmd exec printf('%d,%dd', a:lnum, a:end)
		return 0
	endif
	return -1
endfunc


"----------------------------------------------------------------------
" setbufline
"----------------------------------------------------------------------
function! asclib#buffer#setline(bid, lnum, text) abort
	if s:has_setbufline
		return setbufline(a:bid, a:lnum, a:text)
	elseif bufnr('%') == a:bid
		return setline(a:lnum, a:text)
	endif
endfunc


"----------------------------------------------------------------------
" getbufline({buf}, {lnum} [, {end}])
"----------------------------------------------------------------------
function! asclib#buffer#getline(bid, lnum, ...) abort
	if s:has_getbufline
		if a:0 == 0
			return getbufline(a:bid, a:lnum)
		else
			return getbufline(a:bid, a:lnum, a:1)
		endif
	elseif bufnr('%') == a:bid
		if a:0 == 0
			return getline(a:lnum)
		else
			return getline(a:lnum, a:1)
		endif
	endif
endfunc


"----------------------------------------------------------------------
" open and edit named scratch buffer in current window
"----------------------------------------------------------------------
function! asclib#buffer#open_named(name) abort
	if !exists('s:buffer_names')
		let s:buffer_names = {}
	endif
	if has_key(s:buffer_names, a:name)
		let bid = s:buffer_names[a:name]
		exec 'b ' . bid
	else
		exec 'enew'
		let bid = bufnr('%')
		let s:buffer_names[a:name] = bid
		setlocal bt=nofile nobuflisted bufhidden=hide
	endif
	return bid
endfunc


"----------------------------------------------------------------------
" get line count
"----------------------------------------------------------------------
function! asclib#buffer#linecount(bid) abort
	if !s:has_getbufinfo
		if getbufnr('%') == a:bid
			return line('$')
		endif
	else
		let info = getbufinfo(a:bid)
		if len(info) > 0
			let item = info[0]
			if has_key(item, 'linecount')
				return item.linecount
			endif
		endif
	endif
	if getbufnr('%') == a:bid
		return line('$')
	elseif s:has_getbufline
		return len(getbufline(a:bid, 1, '$'))
	endif
	return 0
endfunc



