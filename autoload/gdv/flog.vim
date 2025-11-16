"======================================================================
"
" flog.vim - 
"
" Created by skywind on 2025/11/16
" Last Modified: 2025/11/16 13:33:09
"
"======================================================================


"----------------------------------------------------------------------
" get flog commit line hash
"----------------------------------------------------------------------
function! gdv#flog#commit_line(bid, lnum) abort
	let bt = getbufvar(a:bid, '&buftype')
	let ft = getbufvar(a:bid, '&filetype')
	if bt != 'nofile'
		return ''
	elseif ft != 'floggraph' && ft != 'GV'
		return ''
	endif
	let content = getbufline(a:bid, a:lnum)
	let text = (len(content) > 0)? content[0] : ''
	let pos = stridx(text, '*')
	if pos < 0
		return ''
	endif
	let rest = strpart(text, pos + 1)
	let hash = ''
	if ft == 'floggraph'
		let p1 = stridx(rest, '[')
		if p1 < 0
			return ''
		endif
		let p2 = stridx(rest, ']')
		if p2 < 0 || p2 <= p1
			return ''
		endif
		let hash = strpart(rest, p1 + 1, p2 - p1 - 1)
	else
		let begin = '^[^0-9]*[0-9]\{4}-[0-9]\{2}-[0-9]\{2}\s\+'
		let hash = matchstr(rest, begin . '\zs[0-9a-f]\{5,40}\ze\s')
	endif
	return hash
endfunc


"----------------------------------------------------------------------
" floggraph commit extractor
"----------------------------------------------------------------------
function! gdv#flog#commit_extract() abort
	if &bt != 'nofile'
		return ''
	elseif &ft != 'floggraph' && &ft != 'GV'
		return ''
	endif
	let bid = bufnr('%')
	let lnum = line('.')
	while lnum > 0
		let hash = gdv#flog#commit_line(bid, lnum)
		if hash != ''
			return hash
		endif
		let lnum -= 1
	endwhile
	return ''
endfunc


