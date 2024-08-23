"======================================================================
"
" generic.vim - generic filetype plugin
"
" Created by skywind on 2024/03/18
" Last Modified: 2024/03/18 17:14:27
"
"======================================================================


"----------------------------------------------------------------------
" fast return root
"----------------------------------------------------------------------
function! module#generic#root() abort
	if &bt != ''
		return asclib#path#current_root()
	elseif bufname('') == ''
		return asclib#path#current_root()
	endif
	let obj = asclib#core#object('b')
	if !has_key(obj, 'root')
		let obj.root = asclib#path#current_root()
	endif
	return obj.root
endfunc



