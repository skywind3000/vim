"======================================================================
"
" tags.vim - 
"
" Created by skywind on 2023/08/17
" Last Modified: 2023/08/17 12:20:55
"
"======================================================================


"----------------------------------------------------------------------
" next function
"----------------------------------------------------------------------
function! module#tags#locate(items, lnum) abort
	let items = a:items
	let limit = len(items)
	let index = 0
	let current = a:lnum
	if limit == 0
		return -1
	endif
	while index < limit - 1
		if items[index + 1].line > current
			break
		endif
		let index += 1
	endwhile
	return index
endfunc


"----------------------------------------------------------------------
" search function
"----------------------------------------------------------------------
function! module#tags#function_list() abort
	return quickui#tags#function_list(bufnr(), &ft)
endfunc


"----------------------------------------------------------------------
" list function
"----------------------------------------------------------------------
function! module#tags#function_dump() abort
	for	i in module#tags#function_list()
		echo i
	endfor
endfunc


"----------------------------------------------------------------------
" query name
"----------------------------------------------------------------------
function! module#tags#function_name() abort
	let items = module#tags#function_list()
	let index = module#cpp#tag_index(items, line('.'))
	if index < 0
		return ''
	endif
	return items[index].tag
endfunc


"----------------------------------------------------------------------
" query text
"----------------------------------------------------------------------
function! module#tags#function_text() abort
	let items = module#tags#function_list()
	let index = module#cpp#tag_index(items, line('.'))
	if index < 0
		return ''
	endif
	return items[index].text
endfunc


"----------------------------------------------------------------------
" query text
"----------------------------------------------------------------------
function! module#tags#function_next(direction) abort
	let items = module#tags#function_list()
	let index = module#cpp#tag_index(items, line('.'))
	let limit = len(items)
	if index < 0
		return -1
	endif
	let index += (a:direction >= 0)? 1 : (-1)
	let index = (index < 0)? 0 : index
	let index = (index > limit - 1)? (limit - 1) : index
	exec printf(':%d', items[index].line)
	return 0
endfunc



