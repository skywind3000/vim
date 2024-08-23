"======================================================================
"
" quickfix.vim - 
"
" Created by skywind on 2024/03/08
" Last Modified: 2024/03/08 17:33:22
"
"======================================================================


"----------------------------------------------------------------------
" filter unused quickfix items
"----------------------------------------------------------------------
function! module#quickfix#filter() abort
	let l:qflist = getqflist()
	let l:qf = []
	for l:item in l:qflist
		if l:item.valid
			call add(l:qf, l:item)
		endif
	endfor
	call setqflist(l:qf)
endfunc


"----------------------------------------------------------------------
" convert encoding for quickfix items
"----------------------------------------------------------------------
function! module#quickfix#iconv(encoding) abort
	if &encoding == a:encoding
		return -1
	elseif !exists('*iconv')
		return -1
	endif
	let l:qflist = getqflist()
	for i in l:qflist
		let i.text = iconv(i.text, a:encoding, &encoding)
	endfor
	return 0
endfunc


"----------------------------------------------------------------------
" ensure encoding for quickfix items
"----------------------------------------------------------------------
function! module#quickfix#ensure_encoding() abort
	let encoding = get(g:, 'asyncrun_encs', '')
	if encoding != ''
		call module#quickfix#iconv(encoding)
	endif
endfunc


"----------------------------------------------------------------------
" returns window number
"----------------------------------------------------------------------
function! module#quickfix#search_window()
	return asclib#window#search("quickfix", 'qf', 0)
endfunc


"----------------------------------------------------------------------
" scroll quickfix:  0:up, 1:down, 2:pgup, 3:pgdown 4:top, 5:bottom
"----------------------------------------------------------------------
function! module#quickfix#scroll(mode) abort
	let num = module#quickfix#search_window()
	if num > 0
		call asclib#window#scroll(num, a:mode)
	endif
endfunc



