"======================================================================
"
" manager.vim - 
"
" Created by skywind on 2020/02/21
" Last Modified: 2020/02/21 23:27:12
"
"======================================================================


"----------------------------------------------------------------------
" internal status
"----------------------------------------------------------------------
let s:term_list = []
let s:active = -1


"----------------------------------------------------------------------
" get bid by index
"----------------------------------------------------------------------
function! termbox#manager#get(index)
	if a:index >= 0 && a:index < len(s:term_list)
		return s:term_list[a:index]
	else
		return -1
	endif
endfunc


"----------------------------------------------------------------------
" get index by bid
"----------------------------------------------------------------------
function! termbox#manager#index(bid)
	let index = 0
	let size = len(s:term_list)
	while index < size
		if s:term_list[index] == a:bid
			return index
		endif
		let index += 1
	endwhile
	return -1
endfunc


"----------------------------------------------------------------------
" get list
"----------------------------------------------------------------------
function! termbox#manager#array()
	return s:term_list
endfunc


"----------------------------------------------------------------------
" new bid
"----------------------------------------------------------------------
function! termbox#manager#insert(bid)
	let index = termbox#manager#index(a:bid)
	if index >= 0
		call termbox#lib#error('duplicated bid')
		return v:null
	endif
	let s:term_list += [a:bid]
	if s:active < 0
		let s:active = 0
	endif
endfunc


"----------------------------------------------------------------------
" remove bid
"----------------------------------------------------------------------
function! termbox#manager#remove(bid)
	let index = termbox#manager#index(a:bid)
	if index >= 0
		let newlist = []
		for i in range(len(s:term_list))
			let b = s:term_list[i]
			if b != a:bid
				let newlist += [b]
			endif
		endfor
		let s:term_list = newlist
	endif
	if s:active >= len(s:term_list)
		let s:active = len(s:term_list) - 1
	endif
endfunc


"----------------------------------------------------------------------
" next item
"----------------------------------------------------------------------
function! termbox#manager#next()
	let size = len(s:term_list)
	if size == 0
		let s:active = -1
	else
		let s:active = (s:active + 1 < size)? (s:active + 1) : 0
	endif
	return s:active
endfunc


"----------------------------------------------------------------------
" prev item
"----------------------------------------------------------------------
function! termbox#manager#prev()
	let size = len(s:term_list)
	if size == 0
		let s:active = -1
	else
		let s:active = (s:active > 0)? (s:active - 1) : (size - 1)
	endif
	return s:active
endfunc


"----------------------------------------------------------------------
" get active
"----------------------------------------------------------------------
function! termbox#manager#cursor()
	return s:active
endfunc


"----------------------------------------------------------------------
" active index
"----------------------------------------------------------------------
function! termbox#manager#active(i)
	let size = len(s:term_list)
	if i >= 0 && i < size
		let s:active = i
	endif
endfunc


"----------------------------------------------------------------------
" get size
"----------------------------------------------------------------------
function! termbox#manager#term_size(a:opts)
	let ww = get(g:, 'termbox_w', 0.6)
	let hh = get(g:, 'termbox_h', 0.6)
	let ww = get(a:opts, 'w', ww)
	let hh = get(a:opts, 'h', hh)
	if type(ww) == v:t_float && ww <= 1
		let w = float2nr(&columns * ww)
	else
		let w = float2nr(ww)
	endif
	if type(hh) == v:t_float && hh <= 1
		let h = float2nr(&lines * hh)
	else
		let h = float2nr(hh)
	endif
	return [w, h]
endfunc




"----------------------------------------------------------------------
" testing suit
"----------------------------------------------------------------------
if 0
	let x = termbox#manager#prev()
	call termbox#manager#insert(10)
	call termbox#manager#insert(11)
	call termbox#manager#insert(20)
	call termbox#manager#insert(50)
	call termbox#manager#insert(40)
	echo termbox#manager#array()
	call termbox#manager#remove(11)
	echo termbox#manager#array()
	call termbox#manager#insert(11)
	echo termbox#manager#array()
	echo s:active
	for i in range(20)
		echo termbox#manager#next()
	endfor
endif


