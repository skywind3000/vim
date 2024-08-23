"======================================================================
"
" borland256.vim - 
"
" Created by skywind on 2024/03/24
" Last Modified: 2024/03/30 04:30
"
"======================================================================

"----------------------------------------------------------------------
" initialize
"----------------------------------------------------------------------
set background=dark
hi clear

let g:colors_name = "borland256"


"----------------------------------------------------------------------
" color table
"----------------------------------------------------------------------
hi Added gui=NONE term=NONE cterm=NONE guifg=LimeGreen guibg=NONE ctermfg=77 ctermbg=NONE
hi link Boolean NormalTransparent
hi Changed gui=NONE term=NONE cterm=NONE guifg=DodgerBlue guibg=NONE ctermfg=33 ctermbg=NONE
hi link Character NormalTransparent
hi ColorColumn gui=NONE term=NONE cterm=NONE guifg=NONE guibg=#0038a8 ctermfg=NONE ctermbg=236
hi Comment gui=NONE term=NONE cterm=NONE guifg=#a8a8a8 guibg=NONE ctermfg=248 ctermbg=NONE
hi Conceal gui=NONE term=NONE cterm=NONE guifg=LightGrey guibg=DarkGrey ctermfg=252 ctermbg=248
hi link Conditional Statement
hi Constant gui=NONE term=underline cterm=NONE guifg=#ffa0a0 guibg=NONE ctermfg=217 ctermbg=NONE
hi link CurSearch Search
hi Cursor gui=reverse,inverse term=NONE cterm=reverse,inverse guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE
hi CursorColumn gui=NONE term=reverse,inverse cterm=NONE guifg=NONE guibg=Grey40 ctermfg=NONE ctermbg=241
hi link CursorIM Cursor
" hi CursorLine gui=NONE term=underline cterm=NONE guifg=NONE guibg=Grey40 ctermfg=NONE ctermbg=241
hi CursorLine gui=NONE term=underline cterm=NONE guifg=NONE guibg=#0038a8 ctermfg=NONE ctermbg=24
hi link CursorLineFold Folded
hi CursorLineNr gui=bold term=bold cterm=bold guifg=Yellow guibg=NONE ctermfg=11 ctermbg=NONE
hi link CursorLineSign LineNr
hi link Debug Special
hi link Define PreProc
hi link Delimiter Special
hi DiffAdd gui=NONE term=bold cterm=NONE guifg=NONE guibg=DarkBlue ctermfg=NONE ctermbg=18
hi DiffChange gui=NONE term=bold cterm=NONE guifg=NONE guibg=DarkMagenta ctermfg=NONE ctermbg=90
hi DiffDelete gui=bold term=bold cterm=bold guifg=Blue guibg=DarkCyan ctermfg=12 ctermbg=30
hi DiffText gui=bold term=reverse,inverse cterm=bold guifg=NONE guibg=Red ctermfg=NONE ctermbg=9
" hi Directory gui=NONE term=bold cterm=NONE guifg=Cyan guibg=NONE ctermfg=14 ctermbg=NONE
hi link Directory Special
hi link EndOfBuffer NonText
hi Error gui=NONE term=reverse,inverse cterm=NONE guifg=White guibg=Red ctermfg=15 ctermbg=9
hi ErrorMsg gui=NONE term=NONE cterm=NONE guifg=#ffff57 guibg=#a80000 ctermfg=227 ctermbg=124
hi link Exception Statement
hi link Float NormalTransparent
hi FoldColumn gui=NONE term=standout cterm=NONE guifg=Cyan guibg=Grey ctermfg=14 ctermbg=7
hi Folded gui=NONE term=NONE cterm=NONE guifg=#000000 guibg=#00a8a8 ctermfg=0 ctermbg=37
hi link Function NormalTransparent
hi Identifier gui=NONE term=underline cterm=NONE guifg=#40ffff guibg=NONE ctermfg=87 ctermbg=NONE
hi Ignore gui=NONE term=NONE cterm=NONE guifg=bg guibg=NONE ctermfg=19 ctermbg=NONE
hi IncSearch gui=reverse,inverse term=reverse,inverse cterm=reverse,inverse guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE
hi link Include PreProc
hi link Keyword Statement
hi link Label Statement
hi LineNr gui=NONE term=NONE cterm=NONE guifg=#00a8a8 guibg=NONE ctermfg=37 ctermbg=NONE
hi clear LineNrAbove
hi clear LineNrBelow
hi link Macro PreProc
hi MatchParen gui=NONE term=NONE cterm=NONE guifg=NONE guibg=#00a8a8 ctermfg=NONE ctermbg=37
hi ModeMsg gui=NONE term=NONE cterm=NONE guifg=#ffffff guibg=NONE ctermfg=15 ctermbg=NONE
hi MoreMsg gui=bold term=bold cterm=bold guifg=SeaGreen guibg=NONE ctermfg=29 ctermbg=NONE
hi NonText gui=NONE term=NONE cterm=NONE guifg=#00a8a8 guibg=NONE ctermfg=37 ctermbg=NONE
hi Normal gui=NONE term=NONE cterm=NONE guifg=#ffff57 guibg=#0000a8 ctermfg=227 ctermbg=19
" hi link Number NormalTransparent
hi link Number Todo
hi link Operator Statement
hi Pmenu gui=NONE term=NONE cterm=NONE guifg=#000000 guibg=#00a8a8 ctermfg=0 ctermbg=37
hi link PmenuExtra Pmenu
hi link PmenuExtraSel PmenuSel
hi link PmenuKind Pmenu
hi link PmenuKindSel PmenuSel
hi PmenuSbar gui=NONE term=NONE cterm=NONE guifg=#0038a8 guibg=#0070a8 ctermfg=236 ctermbg=25
hi PmenuSel gui=NONE term=NONE cterm=NONE guifg=#ffffff guibg=#00a800 ctermfg=15 ctermbg=34
hi PmenuThumb gui=NONE term=NONE cterm=NONE guifg=#0070a8 guibg=#0038a8 ctermfg=25 ctermbg=236
hi PmenuMatchSel gui=NONE term=NONE cterm=NONE guifg=#ffff57 guibg=#00a800 ctermfg=227 ctermbg=34
hi link PreCondit PreProc
hi PreProc gui=NONE term=NONE cterm=NONE guifg=#57ff57 guibg=NONE ctermfg=83 ctermbg=NONE
hi Question gui=bold term=standout cterm=bold guifg=Green guibg=NONE ctermfg=10 ctermbg=NONE
hi link QuickFixLine Search
hi Removed gui=NONE term=NONE cterm=NONE guifg=Red guibg=NONE ctermfg=9 ctermbg=NONE
hi link Repeat Statement
hi Search gui=NONE term=reverse,inverse cterm=NONE guifg=Black guibg=Yellow ctermfg=0 ctermbg=11
" hi SignColumn gui=NONE term=standout cterm=NONE guifg=Cyan guibg=Grey ctermfg=14 ctermbg=7
hi SignColumn gui=NONE term=standout cterm=NONE guifg=Cyan guibg=NONE ctermfg=14 ctermbg=NONE
hi Special gui=NONE term=NONE cterm=NONE guifg=#57ffff guibg=NONE ctermfg=87 ctermbg=NONE
hi link SpecialChar Special
hi link SpecialComment Special
hi SpecialKey gui=NONE term=NONE cterm=NONE guifg=#57ffff guibg=NONE ctermfg=87 ctermbg=NONE
hi SpellBad gui=undercurl term=reverse,inverse cterm=undercurl guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE guisp=Red
hi SpellCap gui=undercurl term=reverse,inverse cterm=undercurl guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE guisp=Blue
hi SpellLocal gui=undercurl term=underline cterm=undercurl guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE guisp=Cyan
hi SpellRare gui=undercurl term=reverse,inverse cterm=undercurl guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE guisp=Magenta
hi Statement gui=NONE term=NONE cterm=NONE guifg=#ffffff guibg=NONE ctermfg=15 ctermbg=NONE
" hi StatusLine gui=NONE term=NONE cterm=NONE guifg=#000000 guibg=#00a800 ctermfg=0 ctermbg=34
hi StatusLine gui=NONE term=NONE cterm=NONE guifg=#000000 guibg=#e0e0e0 ctermfg=0 ctermbg=253
hi StatusLineNC gui=NONE term=NONE cterm=NONE guifg=#000000 guibg=#a8a8a8 ctermfg=0 ctermbg=248
hi StatusLineTerm gui=bold term=reverse,inverse,bold cterm=bold guifg=bg guibg=LightGreen ctermfg=19 ctermbg=120
hi StatusLineTermNC gui=NONE term=reverse,inverse cterm=NONE guifg=bg guibg=LightGreen ctermfg=19 ctermbg=120
hi link StorageClass Type
" hi link String NormalTransparent
hi link String Special
hi link Structure Type
" hi TabLine gui=underline term=underline cterm=underline guifg=NONE guibg=DarkGrey ctermfg=NONE ctermbg=248
" hi TabLineFill gui=reverse,inverse term=reverse,inverse cterm=reverse,inverse guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE
" hi TabLineSel gui=bold term=bold cterm=bold guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE
hi TabLine gui=underline term=underline cterm=NONE guifg=#000000 guibg=#a8a8a8 ctermfg=0 ctermbg=248
hi TabLineFill gui=NONE term=NONE cterm=NONE guifg=NONE guibg=#e0e0e0 ctermfg=NONE ctermbg=253
hi TabLineSel gui=bold term=bold cterm=bold guifg=#c0c0c0 guibg=NONE ctermfg=7 ctermbg=NONE
" hi TabLineSel gui=bold term=bold cterm=bold guifg=#000000 guibg=#eeeeee ctermfg=0 ctermbg=255
hi link Tag Special
hi link Terminal Normal
hi Title gui=bold term=bold cterm=bold guifg=Magenta guibg=NONE ctermfg=13 ctermbg=NONE
hi Todo gui=NONE term=NONE cterm=NONE guifg=#ff5757 guibg=NONE ctermfg=203 ctermbg=NONE
hi ToolbarButton gui=bold term=NONE cterm=bold guifg=Black guibg=LightGrey ctermfg=0 ctermbg=252
hi ToolbarLine gui=NONE term=underline cterm=NONE guifg=NONE guibg=Grey50 ctermfg=NONE ctermbg=8
hi Type gui=NONE term=NONE cterm=NONE guifg=#ffffff guibg=NONE ctermfg=15 ctermbg=NONE
hi link Typedef Type
hi Underlined gui=underline term=underline cterm=underline guifg=#80a0ff guibg=NONE ctermfg=111 ctermbg=NONE
" hi VertSplit gui=reverse,inverse term=reverse,inverse cterm=reverse,inverse guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE
hi VertSplit gui=NONE term=NONE cterm=NONE guifg=#000000 guibg=#dadada ctermfg=0 ctermbg=253
hi Visual gui=NONE term=NONE cterm=NONE guifg=#0000a8 guibg=#a8a8a8 ctermfg=19 ctermbg=248
hi VisualNOS gui=NONE term=NONE cterm=NONE guifg=#0000a8 guibg=#575757 ctermfg=19 ctermbg=240
hi WarningMsg gui=NONE term=NONE cterm=NONE guifg=#ffff57 guibg=#a85700 ctermfg=227 ctermbg=130
hi WildMenu gui=NONE term=standout cterm=NONE guifg=Black guibg=Yellow ctermfg=0 ctermbg=11
hi clear lCursor
hi NormalTransparent gui=NONE term=NONE cterm=NONE guifg=#ffff57 guibg=NONE ctermfg=227 ctermbg=NONE
hi link BorlandSpecial Statement


"----------------------------------------------------------------------
" options
"----------------------------------------------------------------------
if get(g:, 'borland256_darker', 0) == 1
	hi Normal ctermbg=18 guibg=#000087
endif


"----------------------------------------------------------------------
" extra elements for syntax highlighting
"----------------------------------------------------------------------
let s:langmap = {'c':1, 'cpp':1, 'java':1, 'go':1, 'cs':1, 'javascript': 1,
			\ 'typescript':1, 'rust':1, 'php':1, 'perl':1, 'ps1': 1,
			\ 'vim':0, 'yacc':1, 'lex':1 }

function! s:newmatch()
	if &bt != ''
		return
	elseif get(s:langmap, &ft, 0) == 0
		return
	elseif get(g:, 'colors_name', '') != 'borland256'
		return
	endif
	if get(b:, 'borland256_init', 0) == 0
		let b:borland256_init = 1
		syntax match BorlandSpecial '\v(\(|\)|\{|\}|\[|\])'
	endif
endfunc

augroup BorlandEventGroup
	au!
	au VimEnter,WinEnter,FileType * call s:newmatch()
	au BufNew,BufWinEnter,BufReadPost * call s:newmatch()
augroup END

call s:newmatch()


"----------------------------------------------------------------------
" plugin adaptation
"----------------------------------------------------------------------

" vim
hi! def link vimParenSep BorlandSpecial 
hi! def link Delimiter BorlandSpecial 

" quickui
hi QuickPreview gui=NONE term=NONE cterm=NONE guifg=#ffff57 guibg=#000087 ctermfg=227 ctermbg=18

" plugin: coc
hi! CocMenuSel ctermbg=34 guibg=#00aa00
hi! CocFloating ctermbg=37 guibg=#00aaaa ctermfg=253 guibg=#dadada
hi! CocSearch ctermfg=227 guifg=#ffff57
hi! CocFloating ctermbg=37 guibg=#00aaaa ctermfg=19 guifg=#0000af


