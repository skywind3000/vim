"======================================================================
"
" indentmove.vim - 
"
" Created by skywind on 2019/12/30
" Last Modified: 2019/12/30 02:38:40
"
"======================================================================

   
function! s:get_indent(lineno)
	let textlist = getbufline('%', a:lineno)
	if len(textlist) == 0
		return -1
	endif
	let text = textlist[0]
	let size = strchars(text)
	let pos = matchend(text, '^\s\+')
	let pos = (pos < 0)? 0 : pos
	return (pos == size)? -1 : pos
endfunc


