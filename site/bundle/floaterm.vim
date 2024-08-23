
function! s:setup_highlight()
	" Set floaterm window's background to black
	hi! Floaterm guibg=black ctermbg=0 guifg=white
	" Set floating window border line color to cyan, and background to orange
	hi! FloatermBorder guifg=cyan ctermfg=51 guibg=black ctermbg=0

	" Set floaterm window background to gray once the cursor moves out from it
	hi! FloatermNC guibg=gray
endfunc


augroup MyFloatermTheme
	au!
	au! VimEnter * call s:setup_highlight()
augroup END

let g:floaterm_borderchars = '─│─│┌┐┘└'

if has('gui_running') && (has('win32') || has('win64') || has('win95'))
	let g:floaterm_borderchars = '-|-|++++'
endif


