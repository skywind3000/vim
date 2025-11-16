"======================================================================
"
" stage.vim - 
"
" Created by skywind on 2025/11/16
" Last Modified: 2025/11/16 14:51:55
"
"======================================================================


"----------------------------------------------------------------------
" stage diff view
"----------------------------------------------------------------------
function! gdv#stage#diffview(where, fname, staged) abort
	let root = gdv#fugitive#current_root()
	if a:where != '' && a:where != '%'
		let root = gdv#git#root(a:where)
	endif
	if root == ''
		return -1
	endif
	if a:staged == 0
		let srcname = root . '/' . a:fname
	else
		let srcname = gdv#fugitive#make(root, '0', a:fname)
	endif
	let right = get(g:, 'gdv_tab_right', 0)
	if right == 0
		exec printf('-1tabe %s', fnameescape(srcname))
	else
		exec printf('tabe %s', fnameescape(srcname))
	endif
	exec printf('Gvdiffsplit! %s:%s', 'HEAD', a:fname)
endfunc


"----------------------------------------------------------------------
" clever stage diff on a fugitive status buffer
"----------------------------------------------------------------------
function! gdv#stage#open_diff() abort
	if &bt != 'nowrite'
		call gdv#git#errmsg('Not a fugitive status buffer.')
		return -1
	elseif &ft != 'fugitive'
		call gdv#git#errmsg('Not a fugitive status buffer.')
		return -1
	endif
	let lnum = line('.')
	let text = getline(lnum)
	if text !~ '^\S\s\+\S\+'
		call gdv#git#errmsg('Not on a valid file line.')
		return -1
	endif
	let status = strpart(text, 0, 1)
	let fname = quickui#core#string_strip(strpart(text, 2))
	if fname == ''
		call gdv#git#errmsg('Cannot extract filename.')
		return -1
	endif
	if status =~ '[\+\- ]'
		call gdv#git#errmsg('Cannot extract filename.')
		return -1
	endif
	if status !~ '\a'
		call gdv#git#errmsg('File is untracked or ignored')
		return -1
	endif
	let mode = ''
	while lnum > 0
		let curline = getline(lnum)
		if curline =~ '^\a\a\+\s\+('
			let mode = tolower(matchstr(curline, '^\a\S\+'))
			break
		endif
		let lnum -= 1
	endwhile
	if mode == ''
		call gdv#git#errmsg('Cannot determine staging mode.')
		return -1
	endif
	if mode == 'untracked'
		call gdv#git#errmsg('File is untracked, no diff available.')
		return -1
	endif
	call gdv#stage#diffview('', fname, mode == 'staged')
	return 0
endfunc



