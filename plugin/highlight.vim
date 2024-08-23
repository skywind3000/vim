"======================================================================
"
" tunestyle.vim - 
"
" Created by skywind on 2018/06/02
" Last Modified: 2018/06/02 19:26:45
"
"======================================================================

" tune syntax style
hi! clear SpellBad
hi! clear SpellCap
hi! clear SpellRare
hi! clear SpellLocal

if has('gui_running')
	hi! SpellBad gui=undercurl guisp=red
	hi! SpellCap gui=undercurl guisp=blue
	hi! SpellRare gui=undercurl guisp=magenta
	hi! SpellLocal gui=undercurl guisp=cyan
else
	hi! SpellBad term=standout cterm=underline
	hi! SpellCap term=underline cterm=underline
	hi! SpellRare term=underline cterm=underline
	hi! SpellLocal term=underline cterm=underline
endif


if 0
	" tune line numbers
	highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE 
				\ gui=NONE guifg=#585858 guibg=NONE

	hi! SignColumn guibg=NONE ctermbg=NONE
endif

if get(g:, 'quickui_color_pmenu', 0) == 0
	if get(g:, 'quickui_color_theme', '') != 'vim'
		" tune completion popup menu
		hi! Pmenu guibg=gray guifg=black ctermbg=gray ctermfg=black
		hi! PmenuSel guibg=gray guifg=brown ctermbg=brown ctermfg=gray
		hi! PmenuExtra guibg=gray guifg=#707070 ctermbg=gray ctermfg=238
		hi! PmenuExtraSel guibg=gray guifg=#b54a4a ctermbg=brown ctermfg=gray
		hi! PmenuKind guibg=gray guifg=darkgreen ctermbg=22 ctermfg=black
		hi! PmenuKindSel guibg=gray guifg=brown ctermbg=brown ctermfg=gray
	endif
endif

" debug
if &t_Co < 256 || 1
	hi! debugPC term=reverse ctermbg=4 guibg=darkblue
	hi! debugBreakpoint term=reverse ctermbg=9 guibg=red
else
	hi! debugPC term=reverse ctermbg=45 guibg=darkblue
	hi! debugBreakpoint term=reverse ctermbg=196 guibg=red
endif


"----------------------------------------------------------------------
" lightline theme
"----------------------------------------------------------------------
if exists('g:lightline')
	if !has_key(g:lightline, 'colorscheme')
		let g:lightline.colorscheme = 'nord'
	elseif g:lightline.colorscheme == ''
		let g:lightline.colorscheme = 'nord'
	endif
endif


