
"----------------------------------------------------------------------
" lightline components
"----------------------------------------------------------------------
let g:lightline = {
			\ 'active': {
			\   'left': [ [ 'mode', 'active' ],
			\             [ 'fullname' ], [ 'status' ] ]
			\ },
			\ 'inactive': {
			\   'left': [ [ 'mode' ],
			\             [ 'fullname' ], [ 'status' ] ]
			\ },
			\ 'component': {
			\   'fullname': '%F',
			\   'status': '[%M%n%R%H%W]'
			\ },
			\ 'component_function': {
			\   'mode': 'LightlineMode',
			\ },
			\ }

function! LightlineMode()
	if &bt != ''
		if &ft == 'qf' 
		elseif &ft == 'dirvish'
			" return 'Dirvish'
		endif
	endif
	return expand('%:t') ==# '__Tagbar__' ? 'Tagbar':
				\ expand('%:t') ==# 'ControlP' ? 'CtrlP' :
				\ &filetype ==# 'unite' ? 'Unite' :
				\ &filetype ==# 'vimfiler' ? 'VimFiler' :
				\ &filetype ==# 'vimshell' ? 'VimShell' :
				\ lightline#mode()
endfunc


