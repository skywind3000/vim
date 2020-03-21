
"----------------------------------------------------------------------
" lightline components
"----------------------------------------------------------------------
let g:lightline = {}

let g:lightline.active = {
			\ 'left': [ [ 'mode', 'active' ],
			\           [ 'fullname' ], [ 'status' ] ]
			\ }

let g:lightline.inactive = {
			\ 'left': [ [ 'mode' ],
			\           [ 'fullname' ], [ 'status' ] ]
			\ }


"----------------------------------------------------------------------
" customize components
"----------------------------------------------------------------------
let g:lightline.component = {
			\ 'fullname': '%F',
			\ 'status': '[%M%n%R%H%W]',
			\ 'mode': '%{LightlineMode()}',
			\ }


"----------------------------------------------------------------------
" switch
"----------------------------------------------------------------------
let g:lightline.enable = {'statusline':1, 'tabline':0}


function! LightlineMode()
	if &bt != ''
		if &ft == 'qf' 
			return 'Quickfix'
		elseif &ft == 'dirvish'
			return 'Dirvish'
		endif
	endif
	return expand('%:t') ==# '__Tagbar__' ? 'Tagbar':
				\ expand('%:t') ==# 'ControlP' ? 'CtrlP' :
				\ &filetype ==# 'unite' ? 'Unite' :
				\ &filetype ==# 'vimfiler' ? 'VimFiler' :
				\ &filetype ==# 'vimshell' ? 'VimShell' :
				\ lightline#mode()
endfunc


