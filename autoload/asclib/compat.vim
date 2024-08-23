"======================================================================
"
" compat.vim - compatibility layer for Vim 8.2 and Neovim 0.5
"
" Created by skywind on 2024/03/19
" Last Modified: 2024/03/19 23:21:34
"
"======================================================================


"----------------------------------------------------------------------
" get text region
"----------------------------------------------------------------------
function! asclib#compat#getregion(pos1, pos2, mode)
	if exists('*getregion') && has('patch-9.1.186') && 0
		let mode = (a:mode == "b")? "\<c-v>" : a:mode
		let opts = {'type': mode}
		return getregion(a:pos1, a:pos2, opts)
	endif
	let [line_start, column_start] = [line(a:pos1), charcol(a:pos1)]
	let [line_end, column_end]     = [line(a:pos2), charcol(a:pos2)]
	let delta = line_end - line_start
	if delta < 0 || (delta == 0 && column_start > column_end)
		let [line_start, line_end] = [line_end, line_start]
		let [column_start, column_end] = [column_end, column_start]
	endif
	let lines = getline(line_start, line_end)
	let inclusive = (&selection == 'inclusive')? 1 : 2
	if a:mode ==# 'v'
		" Must trim the end before the start, the beginning will shift left.
		let lines[-1] = strcharpart(lines[-1], 0, column_end - inclusive + 1)
		let lines[0] = strcharpart(lines[0], column_start - 1)
	elseif  a:mode ==# 'V'
	" Line mode no need to trim start or end
	elseif  a:mode == "\<c-v>" || a:mode == 'b'
		" Block mode, trim every line
		let w = column_end - inclusive + 2 - column_start
		let i = 0
		for line in lines
			let lines[i] = strcharpart(line, column_start - 1, w)
			let i = i + 1
		endfor
	else
		return []
	endif
	return lines
endfunc


"----------------------------------------------------------------------
" quickfix title
"----------------------------------------------------------------------
function! asclib#compat#quickfix_title(title)
	if !has('nvim')
		if v:version >= 800 || has('patch-7.4.2210')
			call setqflist([], 'a', {'title': a:title})
			redrawstatus!
		else
			call setqflist([], 'a')
		endif
	else
		call setqflist([], 'a', a:title)
		redrawstatus!
	endif
endfunc


