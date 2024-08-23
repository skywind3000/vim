" vim: set ts=4 sw=4 tw=78 noet :
"======================================================================
"
" utils.vim - utils
"
" Created by skywind on 2022/12/24
" Last Modified: 2022/12/24 03:38:40
"
"======================================================================


"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------


"----------------------------------------------------------------------
" internal save view
"----------------------------------------------------------------------
function! s:save_view(mode)
	if a:mode == 0
		let w:navigator_save = winsaveview()
	else
		if exists('w:navigator_save')
			if get(b:, 'navigator_keep', 0) == 0
				call winrestview(w:navigator_save)
			endif
			unlet w:navigator_save
		endif
	endif
endfunc


"----------------------------------------------------------------------
" save view
"----------------------------------------------------------------------
function! navigator#utils#save_view() abort
	let winid = winnr()
	keepalt noautocmd windo call s:save_view(0)
	keepalt noautocmd silent! exec printf('%dwincmd w', winid)
endfunc


"----------------------------------------------------------------------
" restore view
"----------------------------------------------------------------------
function! navigator#utils#restore_view() abort
	let winid = winnr()
	keepalt noautocmd windo call s:save_view(1)
	keepalt noautocmd silent! exec printf('%dwincmd w', winid)
endfunc


"----------------------------------------------------------------------
" create a new buffer
"----------------------------------------------------------------------
function! navigator#utils#create_buffer() abort
	if has('nvim') == 0
		let bid = bufadd('')
		call bufload(bid)
		call setbufvar(bid, '&buflisted', 0)
		call setbufvar(bid, '&bufhidden', 'hide')
	else
		let bid = nvim_create_buf(v:false, v:true)
		call setbufvar(bid, '&buftype', 'nofile')
		call setbufvar(bid, '&bufhidden', 'hide')
		call setbufvar(bid, 'noswapfile', 1)
	endif
	call setbufvar(bid, '&modifiable', 1)
	silent call deletebufline(bid, 1, '$')
	call setbufvar(bid, '&modified', 0)
	call setbufvar(bid, '&filetype', '')
	return bid
endfunc


"----------------------------------------------------------------------
" update buffer content
"----------------------------------------------------------------------
function! navigator#utils#update_buffer(bid, textlist) abort
	if type(a:textlist) == v:t_list
		let textlist = a:textlist
	else
		let textlist = split('' . a:textlist, '\n', 1)
	endif
	let old = getbufvar(a:bid, '&modifiable', 0)
	call setbufvar(a:bid, '&modifiable', 1)
	if exists('*deletebufline') && exists('*setbufline')
		silent call deletebufline(a:bid, 1, '$')
		silent call setbufline(a:bid, 1, textlist)
	elseif a:bid == bufnr('%')
		silent exec 'noautocmd 1,$d'
		silent call setline(1, textlist)
	endif
	call setbufvar(a:bid, '&modified', old)
endfunc


"----------------------------------------------------------------------
" resize window
"----------------------------------------------------------------------
function! navigator#utils#window_resize(wid, width, height) abort
	let wid = (a:wid <= 0)? winnr() : a:wid
	call navigator#utils#save_view()
	if a:width >= 0
		exec printf('vert %dresize %d', wid, a:width)
	endif
	if a:height >= 0
		exec printf('%dresize %d', wid, a:height)
	endif
	call navigator#utils#restore_view()
endfunc


"----------------------------------------------------------------------
" check quickfix
"----------------------------------------------------------------------
function! navigator#utils#quickfix_check() abort
	for i in range(winnr('$'))
		let bid = winbufnr(i + 1)
		if getbufvar(bid, '&buftype') == 'quickfix'
			return winheight(i + 1)
		endif
	endfor
	return 0
endfunc


"----------------------------------------------------------------------
" close quickfix
"----------------------------------------------------------------------
function! navigator#utils#quickfix_close() abort
	call navigator#utils#save_view()
	cclose
	call navigator#utils#restore_view()
endfunc


"----------------------------------------------------------------------
" open quickfix
"----------------------------------------------------------------------
function! navigator#utils#quickfix_open(...) abort
	let wid = winnr()
	call navigator#utils#save_view()
	exec 'keepalt botright copen ' . ((a:0 > 0)? a:1 : '')
	call navigator#utils#restore_view()
	exec printf('keepalt %dwincmd w', wid)
endfunc


"----------------------------------------------------------------------
" merge dictionary B into A
"----------------------------------------------------------------------
function! navigator#utils#merge(A, B) abort
	let A = a:A
	let B = a:B
	let t_dict = type({})
	for bkey in keys(B)
		if !has_key(A, bkey)
			let A[bkey] = B[bkey]
			continue
		endif
		let t_a = type(A[bkey])
		let t_b = type(B[bkey])
		if t_a != t_dict && t_b != t_dict
			let A[bkey] = B[bkey]
		elseif t_a == t_dict && t_b == t_dict
			if bkey != 'prefix' && bkey != 'config'
				call navigator#utils#merge(A[bkey], B[bkey])
			endif
		endif
	endfor
	return A
endfunc



