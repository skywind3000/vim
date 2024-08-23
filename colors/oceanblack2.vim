" Vim color file
" Maintainer:	Juan frias <juandfrias at gmail dot com>
" Last Change:	2007 Mar 29
" Version:	1.0.0
" URL:		http://www.axisym3.net/jdany/vim-the-editor/#oceanblack256
"
" These are the colors of the "OceanBlack" theme by Chris Vertonghen modified
" to work on 256-color xterms.
"
set background=dark

highlight clear
if exists("syntax_on")
    syntax reset
endif

let g:colors_name = "oceanblack2"

 highlight  Normal        cterm=none            ctermfg=7        ctermbg=0    gui=none  guifg=honeydew2      guibg=#000000
 highlight  NonText       cterm=none            ctermfg=117      ctermbg=0    gui=none  guifg=lightskyblue   guibg=#000000

 highlight  Visual        cterm=reverse         ctermfg=72       ctermbg=15   gui=reverse         guifg=#5faf87  guibg=#ffffff
 highlight  VisualNOS     cterm=bold,underline  ctermfg=151      ctermbg=0    gui=bold,underline  guifg=#afd7af  guibg=#000000

 highlight  Cursor        cterm=none            ctermfg=15       ctermbg=152  gui=none            guifg=#ffffff  guibg=#afd7d7
 highlight  CursorIM      cterm=bold            ctermfg=15       ctermbg=152  gui=bold            guifg=#ffffff  guibg=#afd7d7

 highlight  Directory     ctermfg=5             ctermbg=0                     guifg=#800080       guibg=#000000

 highlight  DiffAdd       cterm=none            ctermfg=15       ctermbg=22   gui=none            guifg=#ffffff  guibg=#005f00
 highlight  DiffChange    cterm=none            ctermfg=207      ctermbg=90   gui=none            guifg=#ff5fff  guibg=#870087
 highlight  DiffDelete    cterm=none            ctermfg=19       ctermbg=17   gui=none            guifg=#0000af  guibg=#00005f
 highlight  DiffText      cterm=bold            ctermfg=226      ctermbg=90   gui=bold            guifg=#ffff00  guibg=#870087

 highlight  Question      cterm=bold            ctermfg=85       ctermbg=0    gui=bold            guifg=#5fffaf  guibg=#000000
 highlight  ErrorMsg      ctermfg=230           ctermbg=167                   guifg=#ffffd7       guibg=#d75f5f
 highlight  ModeMsg       ctermfg=77            ctermbg=22                    guifg=#5fd75f       guibg=#005f00
 highlight  MoreMsg       cterm=bold            ctermfg=72       ctermbg=0    gui=bold            guifg=#5faf87  guibg=#000000
 highlight  WarningMsg    cterm=bold            ctermfg=203      ctermbg=0    gui=bold            guifg=#ff5f5f  guibg=#000000

 highlight  LineNr        ctermfg=243           guifg=#767676
 highlight  CursorLineNr  ctermfg=11            guifg=yellow     cterm=none   gui=none
 highlight  Folded        cterm=none            ctermfg=152      ctermbg=66   gui=none            guifg=#afd7d7  guibg=#5f8787
 highlight  FoldColumn    cterm=none            ctermfg=152      ctermbg=66   gui=none            guifg=#afd7d7  guibg=#5f8787

 highlight  Search        cterm=none            ctermfg=16       ctermbg=66   gui=none            guifg=#000000  guibg=#5f8787
 highlight  IncSearch     cterm=reverse         ctermfg=151      ctermbg=0    gui=reverse         guifg=#afd7af  guibg=#000000


 highlight  SpecialKey    ctermfg=60            ctermbg=0                     guifg=#5f5f87       guibg=#000000


 highlight  StatusLine    cterm=none            ctermfg=0        ctermbg=254  gui=none            guifg=#000000  guibg=#e4e4e4
 highlight  StatusLineNC  cterm=none            ctermfg=234      ctermbg=247  gui=none            guifg=#1c1c1c  guibg=#9e9e9e
 highlight  VertSplit     cterm=none            ctermfg=0        ctermbg=247  gui=none            guifg=#000000  guibg=#9e9e9e

 highlight  WildMenu      cterm=bold            ctermfg=0        ctermbg=118  gui=bold            guifg=#000000  guibg=#87ff00

 highlight  TabLine       term=underline        cterm=underline  ctermfg=15   gui=underline       guifg=#ffffff  guibg=#808080
 highlight  TabLineFill   term=reverse          cterm=reverse    gui=reverse  gui=reverse
 highlight  TabLineSel    term=bold             cterm=bold       gui=bold     gui=bold

 highlight  Title         cterm=bold            ctermfg=171      ctermbg=0    gui=bold            guifg=#d75fff  guibg=#000000


 highlight  Comment       cterm=none            ctermfg=95                    gui=none            guifg=#7c7268

 highlight  Constant      ctermfg=6             ctermbg=0                     guifg=#008080       guibg=#000000
 highlight  String        cterm=none            ctermfg=111      ctermbg=0    gui=none            guifg=#87afff  guibg=#000000
 highlight  Number        cterm=none            ctermfg=51       ctermbg=0    gui=none            guifg=#00ffff  guibg=#000000
 highlight  Boolean       cterm=none            ctermfg=51       ctermbg=0    gui=none            guifg=#00ffff  guibg=#000000

 highlight  Identifier    ctermfg=152                                         guifg=#afd7d7
 highlight  Function      cterm=none            ctermfg=151      ctermbg=0    gui=none            guifg=#afd7af  guibg=#000000

 highlight  Statement     cterm=none            ctermfg=77                    gui=none            guifg=#5fd75f
 highlight  Conditional   cterm=none            ctermfg=77       ctermbg=0    gui=none            guifg=#5fd75f  guibg=#000000
 highlight  Repeat        cterm=none            ctermfg=85       ctermbg=0    gui=none            guifg=#5fffaf  guibg=#000000
 highlight  Operator      cterm=none            ctermfg=118      ctermbg=0    gui=none            guifg=#87ff00  guibg=#000000
 highlight  Keyword       cterm=none            ctermfg=77       ctermbg=0    gui=none            guifg=#5fd75f  guibg=#000000
 highlight  Exception     cterm=none            ctermfg=77       ctermbg=0    gui=none            guifg=#5fd75f  guibg=#000000

 highlight  PreProc       ctermfg=117                                         guifg=#87d7ff
 highlight  Include       cterm=none            ctermfg=146      ctermbg=0    gui=none            guifg=#afafd7  guibg=#000000
 highlight  Define        cterm=none            ctermfg=110      ctermbg=0    gui=none            guifg=#87afd7  guibg=#000000
 highlight  Macro         cterm=none            ctermfg=152      ctermbg=0    gui=none            guifg=#afd7d7  guibg=#000000
 highlight  PreCondit     cterm=none            ctermfg=74       ctermbg=0    gui=none            guifg=#5fafd7  guibg=#000000

 highlight  Type          cterm=none            ctermfg=110                   gui=none            guifg=#87afd7
 highlight  StorageClass  cterm=none            ctermfg=110      ctermbg=0    gui=none            guifg=#87afd7  guibg=#000000
 highlight  Structure     cterm=none            ctermfg=110      ctermbg=0    gui=none            guifg=#87afd7  guibg=#000000
 highlight  Typedef       cterm=none            ctermfg=110      ctermbg=0    gui=none            guifg=#87afd7  guibg=#000000

 highlight  Special       ctermfg=247                                         guifg=#9e9e9e
 highlight  SpecialKey    ctermfg=60            ctermbg=0                     guifg=#5f5f87       guibg=#000000
 highlight  SpecialChar   ctermfg=247                                         guifg=#9e9e9e


 highlight  Underlined    cterm=underline       ctermfg=102      ctermbg=0    gui=underline       guifg=#878787  guibg=#000000

 highlight  Ignore        ctermfg=67                                          guifg=#5f87af

 highlight  Error         ctermfg=230           ctermbg=167                   guifg=#ffffd7       guibg=#d75f5f

 highlight  Todo          ctermfg=51            ctermbg=66                    guifg=#00ffff       guibg=#5f8787

