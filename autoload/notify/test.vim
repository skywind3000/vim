"======================================================================
"
" test.vim - 
"
" Created by skywind on 2023/08/01
" Last Modified: 2023/08/01 15:20:59
"
"======================================================================


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! notify#test#test1() abort
	let w1 = quickui#window#new()
	let opts = {}
	let opts.x = 60
	let opts.y = 20
	let opts.w = 3
	let opts.h = 4
	let opts.border = 4
	call w1.open(['hello', repeat('-', 30), 'world'], opts)
	call w1.show(1)
	redraw
	call getchar()
	call w1.close()
endfunc


