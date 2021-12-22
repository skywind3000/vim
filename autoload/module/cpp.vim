"======================================================================
"
" cpp.vim - 
"
" Created by skywind on 2021/12/22
" Last Modified: 2021/12/22 22:23:49
"
"======================================================================

" switch header
function! minibox#cpp#switch_header(...)
	let l:main = expand('%:p:r')
	let l:fext = expand('%:e')
	if index(['c', 'cpp', 'm', 'mm', 'cc'], l:fext) >= 0
		let l:altnames = ['h', 'hpp', 'hh']
	elseif index(['h', 'hh', 'hpp'], l:fext) >= 0
		let l:altnames = ['c', 'cpp', 'cc', 'm', 'mm']
	elseif l:fext == '' && ft == 'cpp'
		let l:altnames = ['cpp', 'cc' ]
	else
		echo 'switch failed, not a c/c++ source'
		return 
	endif
	let found = ''
	for l:next in l:altnames
		let l:newname = l:main . '.' . l:next
		if filereadable(l:newname)
			let found = l:newname
			break
		endif
	endfor
	if found != ''
		let switch = (a:0 < 1)? '' : a:1
		let opts = {}
		if switch != ''
			let opts.switch = 'useopen,' . switch
		endif
		call asclib#core#switch(found, opts)
	else
		let t = 'switch failed, can not find another part of c/c++ source'
		call asclib#core#errmsg(t)
	endif
endfunc



