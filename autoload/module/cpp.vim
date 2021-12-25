"======================================================================
"
" cpp.vim - 
"
" Created by skywind on 2021/12/22
" Last Modified: 2021/12/22 22:23:49
"
"======================================================================


"----------------------------------------------------------------------
" init
"----------------------------------------------------------------------
function! module#cpp#init()
	" echom "load cpp"
endfunc


"----------------------------------------------------------------------
" switch header
"----------------------------------------------------------------------
function! module#cpp#switch_header(...)
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


"----------------------------------------------------------------------
" insert a class name
"----------------------------------------------------------------------
function! module#cpp#class_insert(line1, line2)
	let msg = 'Enter a class name to insert: '
	let clsname = asclib#ui#input(msg, '', 'clsname')
	if clsname != ''
		let clsname = escape(clsname, '/\[*~^')
		let text = 's/\~\=\w\+\s*(/' . clsname . '::&/'
		exec a:line1 . ',' . a:line2 . text
	endif
endfunc


"----------------------------------------------------------------------
" expand brace
"----------------------------------------------------------------------
function! module#cpp#brace_expand(line1, line2)
	let cmd = 's/;\s*$/\r{\r}\r\r/'
	exec a:line1 . ',' . a:line2 . cmd
endfunc



