

"----------------------------------------------------------------------
" simple status line
"----------------------------------------------------------------------
let g:status_padding_left = ""
let g:status_padding_right = ""

set statusline=                                 " clear status line
set statusline+=%{''.g:status_padding_left}     " left padding
set statusline+=\ %F                            " filename
set statusline+=\ [%1*%M%*%n%R%H]               " buffer number and status
set statusline+=%{''.g:status_padding_right}    " left padding
" set statusline+=\ %{''.toupper(mode())}         " INSERT/NORMAL/VISUAL
set statusline+=%=                              " right align remainder
set statusline+=\ %y                            " file type
set statusline+=\ %0(%{&fileformat}\ [%{(&fenc==\"\"?&enc:&fenc).(&bomb?\",BOM\":\"\")}]\ %v:%l/%L%)


"----------------------------------------------------------------------
" lightline components
"----------------------------------------------------------------------
let g:lightline = {
			\ 'active': {
			\   'left': [ [ 'mode', 'paste' ],
			\             [ 'filename', 'status' ] ]
			\ },
			\ 'component': {
			\   'status': '[%M%n%R%H%W]'
			\ },
			\ 'component_function': {
			\   'mode': 'LightlineMode',
			\ },
			\ }

function! LightlineMode()
	if &bt != ''
		if &ft == 'qf' 
			return 'QuickFix'
		endif
	endif
	return expand('%:t') ==# '__Tagbar__' ? 'Tagbar':
				\ expand('%:t') ==# 'ControlP' ? 'CtrlP' :
				\ &filetype ==# 'unite' ? 'Unite' :
				\ &filetype ==# 'vimfiler' ? 'VimFiler' :
				\ &filetype ==# 'vimshell' ? 'VimShell' :
				\ lightline#mode()
endfunc

function! LightlineBufferNumber()
	let text = ''. bufnr("%")
	if &modified
		let text = '+' . text
	endif
	return text
endfunc



