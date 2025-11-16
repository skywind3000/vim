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



