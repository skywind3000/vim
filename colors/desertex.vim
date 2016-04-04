" Vim color file
" Maintainer:   Mingbai <mbbill AT gmail DOT com>

set background=dark
if version > 580
	" no guarantees for version 5.8 and below, but this makes it stop
	" complaining
	hi clear
	if exists("syntax_on")
		syntax reset
	endif
endif
let g:colors_name="desertEx"

" Under GUI
highlight Normal guifg=gray guibg=gray17 gui=none
highlight SignColumn guifg=gray guibg=gray17 gui=none
highlight Cursor guifg=black guibg=yellow gui=none
highlight DiffAdd guifg=black guibg=wheat1
highlight DiffChange guifg=black guibg=skyblue1
highlight DiffDelete guifg=black guibg=gray45 gui=none
highlight DiffText guifg=black guibg=hotpink1 gui=none
highlight ErrorMsg guifg=white guibg=red gui=none
highlight FoldColumn guifg=tan guibg=gray30 gui=none
highlight Folded guifg=darkslategray3 guibg=gray30 gui=none
highlight IncSearch guifg=#b0ffff guibg=#2050d0
highlight LineNr guifg=burlywood3 guibg=gray20 gui=none
highlight MatchParen guifg=yellow guibg=gray17 gui=bold
highlight ModeMsg guifg=skyblue gui=bold
highlight MoreMsg guifg=seagreen gui=none
highlight NonText guifg=cyan guibg=gray20 gui=none
highlight Pmenu guifg=white guibg=#445599 gui=none
highlight PmenuSel guifg=#445599 guibg=gray
highlight Question guifg=springgreen gui=none
highlight Search guifg=white guibg=#445599 gui=bold
highlight SpecialKey guifg=gray30 gui=none
highlight StatusLine guifg=black guibg=#c2bfa5 gui=bold
highlight StatusLineNC guifg=gray guibg=gray40 gui=none
highlight Title guifg=indianred gui=none
highlight VertSplit guifg=gray40 guibg=gray40 gui=none
highlight Visual guifg=black guibg=#ffff78 gui=none
highlight WarningMsg guifg=salmon gui=none
highlight WildMenu guifg=gray guibg=gray17 gui=none
highlight colorcolumn guibg=gray20
highlight TabLine guifg=black guibg=lightsalmon gui=bold
highlight TabLineFill guifg=gray guibg=lightsalmon
highlight TabLineSel guifg=lightsalmon guibg=gray17

" syntax highlighting groups
highlight Comment guifg=palegreen3 gui=none
highlight Constant guifg=#ff7878 gui=none
highlight Identifier guifg=skyblue gui=none
highlight Function guifg=skyblue gui=none
highlight Statement guifg=#fcd38d gui=bold
highlight PreProc guifg=palevioletred2 gui=none
highlight Type guifg=lightsalmon gui=bold
highlight Special guifg=aquamarine2 gui=none
highlight Underlined guifg=#80a0ff gui=underline
highlight Ignore guifg=gray40 gui=none
highlight Error guifg=white guibg=red
highlight Todo guifg=black guibg=#fcd38a gui=none

if exists("g:desertEx_statusLineColor")
	highlight User1 guifg=gray10 gui=bold guibg=#eeb422
	highlight User2 guifg=gray85 gui=bold guibg=gray30
	highlight User3 guifg=gray10 gui=bold guibg=gray50
	highlight User4 guifg=gray10 gui=bold guibg=gray70
	highlight User5 guifg=gray10 gui=bold guibg=gray90
endif
