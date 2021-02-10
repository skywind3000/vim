" antarctic.vim -- Vim color scheme.
" Author:      swalladge (samuel@swalladge.net)
" Webpage:     https://github.com/swalladge/antarctic-vim
" Description: A readable light theme

hi clear

if exists("syntax_on")
  syntax reset
endif

let colors_name = "antarctic"

hi Normal ctermbg=254 ctermfg=234 cterm=NONE guibg=#e4e4e4 guifg=#1c1c1c gui=NONE

set background=light

hi NonText ctermbg=254 ctermfg=234 cterm=NONE guibg=#e4e4e4 guifg=#1c1c1c gui=NONE
hi Comment ctermbg=252 ctermfg=234 cterm=NONE guibg=#d0d0d0 guifg=#1c1c1c gui=NONE
hi Constant ctermbg=NONE ctermfg=234 cterm=NONE guibg=NONE guifg=#1c1c1c gui=NONE
hi Error ctermbg=210 ctermfg=234 cterm=NONE guibg=#ff8787 guifg=#1c1c1c gui=NONE
hi Identifier ctermbg=NONE ctermfg=234 cterm=NONE guibg=NONE guifg=#1c1c1c gui=NONE
hi Ignore ctermbg=NONE ctermfg=234 cterm=NONE guibg=NONE guifg=#1c1c1c gui=NONE
hi PreProc ctermbg=NONE ctermfg=234 cterm=NONE guibg=NONE guifg=#1c1c1c gui=NONE
hi Special ctermbg=NONE ctermfg=234 cterm=NONE guibg=NONE guifg=#1c1c1c gui=NONE
hi Statement ctermbg=NONE ctermfg=234 cterm=NONE guibg=NONE guifg=#1c1c1c gui=NONE
hi String ctermbg=NONE ctermfg=18 cterm=NONE guibg=NONE guifg=#000087 gui=NONE
hi Todo ctermbg=157 ctermfg=234 cterm=NONE guibg=#afffaf guifg=#1c1c1c gui=NONE
hi Type ctermbg=NONE ctermfg=234 cterm=NONE guibg=NONE guifg=#1c1c1c gui=NONE
hi Underlined ctermbg=NONE ctermfg=234 cterm=underline guibg=NONE guifg=#1c1c1c gui=underline
hi StatusLine ctermbg=24 ctermfg=255 cterm=NONE guibg=#005f87 guifg=#eeeeee gui=NONE
hi StatusLineNC ctermbg=247 ctermfg=234 cterm=NONE guibg=#9e9e9e guifg=#1c1c1c gui=NONE
hi VertSplit ctermbg=24 ctermfg=24 cterm=NONE guibg=#005f87 guifg=#005f87 gui=NONE
hi TabLine ctermbg=24 ctermfg=255 cterm=NONE guibg=#005f87 guifg=#eeeeee gui=NONE
hi TabLineFill ctermbg=24 ctermfg=24 cterm=NONE guibg=#005f87 guifg=#005f87 gui=NONE
hi TabLineSel ctermbg=255 ctermfg=234 cterm=NONE guibg=#eeeeee guifg=#1c1c1c gui=NONE
hi Title ctermbg=NONE ctermfg=234 cterm=bold guibg=NONE guifg=#1c1c1c gui=bold
hi LineNr ctermbg=252 ctermfg=240 cterm=NONE guibg=#d0d0d0 guifg=#585858 gui=NONE
hi CursorLineNr ctermbg=230 ctermfg=234 cterm=NONE guibg=#ffffd7 guifg=#1c1c1c gui=NONE
hi helpLeadBlank ctermbg=NONE ctermfg=234 cterm=NONE guibg=NONE guifg=#1c1c1c gui=NONE
hi helpNormal ctermbg=NONE ctermfg=234 cterm=NONE guibg=NONE guifg=#1c1c1c gui=NONE
hi Visual ctermbg=153 ctermfg=NONE cterm=NONE guibg=#afd7ff guifg=NONE gui=NONE
hi VisualNOS ctermbg=153 ctermfg=NONE cterm=NONE guibg=#afd7ff guifg=NONE gui=NONE
hi Pmenu ctermbg=248 ctermfg=234 cterm=NONE guibg=#a8a8a8 guifg=#1c1c1c gui=NONE
hi PmenuSbar ctermbg=254 ctermfg=234 cterm=NONE guibg=#e4e4e4 guifg=#1c1c1c gui=NONE
hi PmenuSel ctermbg=254 ctermfg=234 cterm=NONE guibg=#e4e4e4 guifg=#1c1c1c gui=NONE
hi PmenuThumb ctermbg=254 ctermfg=234 cterm=NONE guibg=#e4e4e4 guifg=#1c1c1c gui=NONE
hi FoldColumn ctermbg=249 ctermfg=234 cterm=NONE guibg=#b2b2b2 guifg=#1c1c1c gui=NONE
hi Folded ctermbg=253 ctermfg=237 cterm=italic guibg=#dadada guifg=#3a3a3a gui=italic
hi WildMenu ctermbg=230 ctermfg=234 cterm=NONE guibg=#ffffd7 guifg=#1c1c1c gui=NONE
hi SpecialKey ctermbg=NONE ctermfg=234 cterm=NONE guibg=NONE guifg=#1c1c1c gui=NONE
hi DiffAdd ctermbg=157 ctermfg=234 cterm=NONE guibg=#afffaf guifg=#1c1c1c gui=NONE
hi DiffChange ctermbg=222 ctermfg=234 cterm=NONE guibg=#ffd787 guifg=#1c1c1c gui=NONE
hi DiffDelete ctermbg=224 ctermfg=234 cterm=NONE guibg=#ffd7d7 guifg=#1c1c1c gui=NONE
hi DiffText ctermbg=229 ctermfg=234 cterm=NONE guibg=#ffffaf guifg=#1c1c1c gui=NONE
hi Search ctermbg=226 ctermfg=NONE cterm=NONE guibg=#ffff00 guifg=NONE gui=NONE
hi Directory ctermbg=NONE ctermfg=234 cterm=NONE guibg=NONE guifg=#1c1c1c gui=NONE
hi MatchParen ctermbg=47 ctermfg=234 cterm=NONE guibg=#00ff5f guifg=#1c1c1c gui=NONE
hi SpellBad ctermbg=224 ctermfg=234 cterm=NONE guibg=#ffd7d7 guifg=#1c1c1c gui=NONE
hi SpellCap ctermbg=219 ctermfg=234 cterm=NONE guibg=#ffafff guifg=#1c1c1c gui=NONE
hi SpellLocal ctermbg=223 ctermfg=234 cterm=NONE guibg=#ffd7af guifg=#1c1c1c gui=NONE
hi SpellRare ctermbg=225 ctermfg=234 cterm=NONE guibg=#ffd7ff guifg=#1c1c1c gui=NONE
hi ColorColumn ctermbg=254 ctermfg=NONE cterm=NONE guibg=#e4e4e4 guifg=NONE gui=NONE
hi SignColumn ctermbg=254 ctermfg=234 cterm=NONE guibg=#e4e4e4 guifg=#1c1c1c gui=NONE
hi ErrorMsg ctermbg=218 ctermfg=234 cterm=NONE guibg=#ffafd7 guifg=#1c1c1c gui=NONE
hi ModeMsg ctermbg=254 ctermfg=234 cterm=NONE guibg=#e4e4e4 guifg=#1c1c1c gui=NONE
hi MoreMsg ctermbg=254 ctermfg=234 cterm=NONE guibg=#e4e4e4 guifg=#1c1c1c gui=NONE
hi Question ctermbg=254 ctermfg=234 cterm=NONE guibg=#e4e4e4 guifg=#1c1c1c gui=NONE
hi WarningMsg ctermbg=218 ctermfg=234 cterm=NONE guibg=#ffafd7 guifg=#1c1c1c gui=NONE
hi Cursor ctermbg=232 ctermfg=NONE cterm=NONE guibg=#080808 guifg=NONE gui=NONE
hi CursorLine ctermbg=230 ctermfg=NONE cterm=NONE guibg=#ffffd7 guifg=NONE gui=NONE
hi CursorColumn ctermbg=230 ctermfg=NONE cterm=NONE guibg=#ffffd7 guifg=NONE gui=NONE
hi StatusLineTerm ctermbg=24 ctermfg=255 cterm=NONE guibg=#005f87 guifg=#eeeeee gui=NONE
hi StatusLineTermNC ctermbg=254 ctermfg=234 cterm=NONE guibg=#e4e4e4 guifg=#1c1c1c gui=NONE
hi Keyword ctermbg=NONE ctermfg=234 cterm=NONE guibg=NONE guifg=#1c1c1c gui=NONE
hi Character ctermbg=NONE ctermfg=234 cterm=NONE guibg=NONE guifg=#1c1c1c gui=NONE
hi helpHyperTextJump ctermbg=NONE ctermfg=20 cterm=underline guibg=NONE guifg=#0000d7 gui=underline
hi HighlightedyankRegion ctermbg=222 ctermfg=234 cterm=NONE guibg=#ffd787 guifg=#1c1c1c gui=NONE

hi link Number Constant
hi link IncSearch Search
hi link QuickFixLine Search
hi link diffAdded DiffAdd
hi link diffRemoved DiffDelete
hi link EndOfBuffer ColorColumn

" Generated with RNB (https://gist.github.com/romainl/5cd2f4ec222805f49eca)
