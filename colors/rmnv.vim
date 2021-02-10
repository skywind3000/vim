" Vim colorscheme
set background=light
hi clear
if exists("syntax_on")
  syntax reset
endif

let colors_name = "rmnv"

hi Boolean           cterm=NONE         ctermfg=18      ctermbg=NONE
hi ColorColumn       cterm=NONE         ctermfg=NONE    ctermbg=255
hi Comment           cterm=NONE         ctermfg=244     ctermbg=NONE
hi Conceal           cterm=NONE         ctermfg=242     ctermbg=NONE
hi Conditional       cterm=NONE         ctermfg=18      ctermbg=NONE
hi Constant          cterm=NONE         ctermfg=242     ctermbg=NONE
hi Cursor            cterm=reverse      ctermfg=NONE    ctermbg=NONE
hi CursorColumn      cterm=NONE         ctermfg=NONE    ctermbg=255
hi CursorLine        cterm=NONE         ctermfg=NONE    ctermbg=255
hi CursorLineNr      cterm=NONE         ctermfg=247     ctermbg=NONE
hi DiffAdd           cterm=NONE         ctermfg=NONE    ctermbg=194
hi DiffChange        cterm=NONE         ctermfg=NONE    ctermbg=255
hi DiffDelete        cterm=NONE         ctermfg=NONE    ctermbg=224
hi DiffText          cterm=NONE         ctermfg=NONE    ctermbg=254
hi Directory         cterm=NONE         ctermfg=239     ctermbg=NONE
hi Error             cterm=NONE         ctermfg=NONE    ctermbg=224
hi ErrorMsg          cterm=NONE         ctermfg=NONE    ctermbg=224
hi FoldColumn        cterm=NONE         ctermfg=251     ctermbg=NONE
hi Folded            cterm=NONE         ctermfg=247     ctermbg=NONE
hi Ignore            cterm=NONE         ctermfg=NONE    ctermbg=NONE
hi IncSearch         cterm=NONE         ctermfg=NONE    ctermbg=254
hi LineNr            cterm=NONE         ctermfg=188     ctermbg=NONE
hi MatchParen        cterm=NONE         ctermfg=NONE    ctermbg=254
hi ModeMsg           cterm=NONE         ctermfg=NONE    ctermbg=NONE
hi MoreMsg           cterm=NONE         ctermfg=NONE    ctermbg=NONE
hi NonText           cterm=NONE         ctermfg=255     ctermbg=NONE
hi Normal            cterm=NONE         ctermfg=0       ctermbg=15
hi Number            cterm=NONE         ctermfg=18      ctermbg=NONE
hi Pmenu             cterm=NONE         ctermfg=NONE    ctermbg=255
hi PmenuSbar         cterm=NONE         ctermfg=NONE    ctermbg=254
hi PmenuSel          cterm=NONE         ctermfg=NONE    ctermbg=254
hi PmenuThumb        cterm=NONE         ctermfg=NONE    ctermbg=253
hi Question          cterm=NONE         ctermfg=NONE    ctermbg=NONE
hi Search            cterm=NONE         ctermfg=NONE    ctermbg=254
hi SignColumn        cterm=NONE         ctermfg=251     ctermbg=NONE
hi Special           cterm=NONE         ctermfg=18      ctermbg=NONE
hi SpecialKey        cterm=NONE         ctermfg=251     ctermbg=NONE
hi SpellBad          cterm=undercurl    ctermfg=NONE    ctermbg=224     termguicolors=NONE 
hi SpellCap          cterm=undercurl    ctermfg=NONE    ctermbg=NONE    termguicolors=NONE 
hi SpellLocal        cterm=undercurl    ctermfg=NONE    ctermbg=194     termguicolors=NONE 
hi SpellRare         cterm=undercurl    ctermfg=NONE    ctermbg=254     termguicolors=NONE 
hi Statement         cterm=NONE         ctermfg=18      ctermbg=NONE
hi StatusLine        cterm=NONE         ctermfg=235     ctermbg=254
hi StatusLineNC      cterm=NONE         ctermfg=247     ctermbg=254
hi StorageClass      cterm=NONE         ctermfg=18      ctermbg=NONE
hi String            cterm=NONE         ctermfg=28      ctermbg=NONE
hi TabLine           cterm=NONE         ctermfg=247     ctermbg=254
hi TabLineFill       cterm=NONE         ctermfg=NONE    ctermbg=254
hi TabLineSel        cterm=NONE         ctermfg=235     ctermbg=254
hi Title             cterm=NONE         ctermfg=0       ctermbg=NONE
hi Todo              cterm=standout     ctermfg=NONE    ctermbg=NONE
hi Type              cterm=NONE         ctermfg=0       ctermbg=NONE
hi Underlined        cterm=NONE         ctermfg=NONE    ctermbg=NONE
hi VertSplit         cterm=NONE         ctermfg=254     ctermbg=NONE
hi Visual            cterm=NONE         ctermfg=NONE    ctermbg=254
hi VisualNOS         cterm=NONE         ctermfg=NONE    ctermbg=NONE
hi WarningMsg        cterm=NONE         ctermfg=NONE    ctermbg=224
hi WildMenu          cterm=NONE         ctermfg=NONE    ctermbg=252
hi lCursor           cterm=NONE         ctermfg=NONE    ctermbg=NONE
hi Identifier        cterm=NONE         ctermfg=NONE    ctermbg=NONE
hi PreProc           cterm=NONE         ctermfg=NONE    ctermbg=  