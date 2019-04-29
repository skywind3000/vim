

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


"----------------------------------------------------------------------
" airline setup me
"----------------------------------------------------------------------
function AirlineSetupMe(font)
	let g:airline_left_sep = ''
	let g:airline_left_alt_sep = ''
	let g:airline_right_sep = ''
	let g:airline_right_alt_sep = ''
	let g:airline_powerline_fonts = 0
	let g:airline_exclude_preview = 1
	let g:airline_section_b = '%n'
	if a:font 
		let g:airline_left_sep = "\ue0b0"
		let g:airline_left_alt_sep = "\ue0b1"
		let g:airline_right_sep = "\ue0b2"
		let g:airline_right_alt_sep = "\ue0b3"
		let g:airline_powerline_fonts = 1
		if !exists('g:airline_symbols')
			let g:airline_symbols = {}
		endif
		let g:airline_symbols.branch = "\ue0a0"
		let g:airline_symbols.readonly = "\ue0a2"
		let g:airline_symbols.linenr = "\u2630"
		let g:airline_symbols.maxlinenr = "\ue0a1"
		if has('win32') || has('win95') || has('win64') || has('win16')
			if has('gui_running') && &rop =~ 'directx'
				let g:airline_symbols.linenr = ''
				let g:airline_symbols.maxlinenr = ''
			endif
		endif
	endif
	let g:airline#extensions#branch#enabled = 0
	let g:airline#extensions#syntastic#enabled = 0
	let g:airline#extensions#fugitiveline#enabled = 0
	let g:airline#extensions#csv#enabled = 0
	let g:airline#extensions#vimagit#enabled = 0
endfunc


