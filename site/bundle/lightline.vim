
"----------------------------------------------------------------------
" lightline components
"----------------------------------------------------------------------
let g:lightline = {}

let g:lightline.active = {
			\ 'left': [ [ 'mode', 'active' ],
			\           [ 'fullname' ], [ 'status' ] ],
			\ 'right': [ ['lineinfo'], ['percent'],
			\           ['fileformat', 'fileencoding', 'filetype'] ],
			\ }

let g:lightline.inactive = {
			\ 'left': [ [ 'mode' ],
			\           [ 'fullname' ], [ 'status' ] ],
			\ 'right': [ ['lineinfo'], ['percent'] ],
			\ }


"----------------------------------------------------------------------
" customize components
"----------------------------------------------------------------------
let g:lightline.component = {
			\ 'fullname': '%F',
			\ 'status': '[%M%n%R%H%W]',
			\ 'mode': '%{LightlineMode()}',
			\ 'lineinfo': '%3l:%-2v',
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



"----------------------------------------------------------------------
" edge mode
"----------------------------------------------------------------------
if get(g:, 'lightline_unicode', 0)
	let g:lightline.separator = get(g:lightline, 'separator', {})
	let g:lightline.subseparator = get(g:lightline, 'subseparator', {})
	let g:lightline.separator.left = "\ue0b0"
	let g:lightline.separator.right = "\ue0b2"
	let g:lightline.subseparator.left = "\ue0b1"
	let g:lightline.subseparator.right = "\ue0b3"
endif


"----------------------------------------------------------------------
" prevent GVim crash
"----------------------------------------------------------------------
function! s:override_event()
	augroup lightline
		autocmd!
		autocmd WinEnter,BufEnter,BufDelete,FileChangedShellPost * call lightline#update()
		autocmd ColorScheme * if !has('vim_starting') || expand('<amatch>') !=# 'macvim'
					\ | call lightline#update() | call lightline#highlight() | endif
	augroup END
endfunc

if 1
	autocmd! VimEnter * call s:override_event()
endif



