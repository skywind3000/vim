"======================================================================
"
" snippet.vim - 
"
" Created by skywind on 2023/07/31
" Last Modified: 2023/07/31 01:58:06
"
"======================================================================


"----------------------------------------------------------------------
" this is well known Filename found in snipmate (and the other 
" engines), but rewritten and documented :)
"
" optional arg1: string in which to replace '$1' by filename with 
" extension and path dropped. Defaults to $1
" optional arg2: return this value if buffer has no filename
"  But why not use the template in this case, too?
"  Doesn't make sense to me
"----------------------------------------------------------------------
function! snippet#filename(...)
	let template = get(a:000, 0, "$1")
	let arg2 = get(a:000, 1, "")

	let basename = expand('%:t:r')

	if basename == ''
		return arg2
	else
		return substitute(template, '$1', basename, 'g')
	endif
endfunc


"----------------------------------------------------------------------
" get cpp function name
"----------------------------------------------------------------------
function! snippet#cpp_clsname()
	return module#cpp#get_class_name()
endfunc


