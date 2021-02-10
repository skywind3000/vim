"======================================================================
"
" lib.vim - 
"
" Created by skywind on 2020/02/21
" Last Modified: 2020/02/21 22:14:35
"
"======================================================================


"----------------------------------------------------------------------
" buffer instance
"----------------------------------------------------------------------
function! termbox#lib#object(bid)
	let name = '_termbox_'
	let bid = (a:bid > 0)? a:bid : (bufnr())
	if bufexists(bid) == 0
		return v:null
	endif
	let obj = getbufvar(bid, name)
	if type(obj) != v:t_dict
		call setbufvar(bid, name, {})
		let obj = getbufvar(bid, name)
	endif
	return obj
endfunc


"----------------------------------------------------------------------
" replace string
"----------------------------------------------------------------------
function! termbox#lib#string_replace(text, old, new)
	let l:data = split(a:text, a:old, 1)
	return join(l:data, a:new)
endfunc


"----------------------------------------------------------------------
" compose two string
"----------------------------------------------------------------------
function! termbox#lib#string_compose(target, pos, source)
	if a:source == ''
		return a:target
	endif
	let pos = a:pos
	let source = a:source
	if pos < 0
		let source = strcharpart(a:source, -pos)
		let pos = 0
	endif
	let target = strcharpart(a:target, 0, pos)
	if strchars(target) < pos
		let target .= repeat(' ', pos - strchars(target))
	endif
	let target .= source
	let target .= strcharpart(a:target, pos + strchars(source))
	return target
endfunc


"----------------------------------------------------------------------
" fit size
"----------------------------------------------------------------------
function! termbox#lib#string_fit(source, size)
	let require = a:size
	let source = a:source
	let size = len(source)
	if size <= require
		return source
	endif
	if require <= 2
		return repeat('.', (require < 0)? 0 : require)
	endif	
	let avail = require - 2
	let left = avail / 2
	let right = avail - left
	let p1 = strpart(source, 0, left)
	let p2 = strpart(source, size - right)
	let text = p1 . '..' . p2
	return text
endfunc


"----------------------------------------------------------------------
" safe change dir
"----------------------------------------------------------------------
function! termbox#lib#chdir(path)
	if has('nvim')
		let cmd = haslocaldir()? 'lcd' : (haslocaldir(-1, 0)? 'tcd' : 'cd')
	else
		let cmd = haslocaldir()? ((haslocaldir() == 1)? 'lcd' : 'tcd') : 'cd'
	endif
	silent execute cmd . ' '. fnameescape(a:path)
endfunc



"----------------------------------------------------------------------
" error msg
"----------------------------------------------------------------------
function! termbox#lib#errmsg(what)
	redraw
	echohl ErrorMsg
	echom 'Error: ' .a:what
	echohl None
endfunc


"----------------------------------------------------------------------
" warning
"----------------------------------------------------------------------
function! termbox#lib#warning(what)
	redraw
	echohl ErrorMsg
	echom 'Warning: ' .a:what
	echohl None
endfunc



