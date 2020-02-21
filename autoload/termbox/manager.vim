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
let s:current = -1


"----------------------------------------------------------------------
" get index
"----------------------------------------------------------------------
function! termbox#manager#get(index)
	if a:index < 0 || a:index >= len(s:term_list)
		return -1
	endif
	return s:term_list[a:index]
endfunc


"----------------------------------------------------------------------
" index bid
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
" new bid
"----------------------------------------------------------------------
function! termbox#manager#new(bid)
	let index = termbox#manager#index(a:bid)
	if index >= 0
		call termbox#lib#error('duplicated bid')
		return v:null
	endif
	let s:term_list += [a:bid]
	if s:current < 0
		let s:current = 0
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
	if s:current >= len(s:term_list)
		let s:current = len(s:term_list) - 1
	endif
endfunc


"----------------------------------------------------------------------
" next item
"----------------------------------------------------------------------
function! termbox#manager#next(bid)
	let index = termbox#manager#index(a:bid)
	let size = len(s:term_list)
	if index < 0
		return -1
	elseif index  + 1 < size
		return s:item_list[index + 1]
	elseif size > 0
		return s:item_list[0]	
	else
		return -1
	endif
endfunc


"----------------------------------------------------------------------
" prev item
"----------------------------------------------------------------------
function! termbox#manager#prev(bid)
	let index = termbox#manager#index(a:bid)
	let size = len(s:term_list)
	if index < 0
		return -1
	elseif index > 0
		return s:item_list[index - 1]
	elseif size > 0
		return s:item_list[size - 1]	
	else
		return -1
	endif
endfunc



