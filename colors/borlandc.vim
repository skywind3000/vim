" Vim color file
" Maintainer:   Yegappan Lakshmanan
" Last Change:  2001 Sep 9

" Color settings similar to that used in Borland IDE's.

set background=dark
hi clear
if exists("syntax_on")
    syntax reset
endif
let g:colors_name="borlandc"

hi Normal       term=NONE cterm=NONE ctermfg=Yellow ctermbg=DarkBlue
hi Normal       gui=NONE guifg=Yellow guibg=DarkBlue
hi NonText      term=NONE cterm=NONE ctermfg=White ctermbg=DarkBlue
hi NonText      gui=NONE guifg=White guibg=DarkBlue

hi Statement    term=NONE cterm=NONE ctermfg=White  ctermbg=NONE
hi Statement    gui=NONE guifg=White guibg=NONE
hi Special      term=NONE cterm=NONE ctermfg=Cyan ctermbg=NONE
hi Special      gui=NONE guifg=Cyan guibg=NONE
hi Constant     term=NONE cterm=NONE ctermfg=Magenta ctermbg=NONE
hi Constant     gui=NONE guifg=Magenta guibg=NONE
hi Comment      term=NONE cterm=NONE ctermfg=Gray ctermbg=NONE
hi Comment      gui=NONE guifg=Gray guibg=NONE
hi Preproc      term=NONE cterm=NONE ctermfg=Green ctermbg=NONE
hi Preproc      gui=NONE guifg=Green guibg=NONE
hi Type         term=NONE cterm=NONE ctermfg=White ctermbg=NONE
hi Type         gui=NONE guifg=White guibg=NONE
hi Identifier   term=NONE cterm=NONE ctermfg=White ctermbg=NONE
hi Identifier   gui=NONE guifg=White guibg=NONE

hi StatusLine   term=bold cterm=bold ctermfg=Black ctermbg=White
hi StatusLine   gui=bold guifg=Black guibg=White

hi StatusLineNC term=NONE cterm=NONE ctermfg=Black ctermbg=White
hi StatusLineNC gui=NONE guifg=Black guibg=White

hi Visual       term=NONE cterm=NONE ctermfg=Black ctermbg=DarkCyan
hi Visual       gui=NONE guifg=Black guibg=DarkCyan

hi Search       term=NONE cterm=NONE ctermbg=Gray
hi Search       gui=NONE guibg=Gray

hi VertSplit    term=NONE cterm=NONE ctermfg=Black ctermbg=White
hi VertSplit    gui=NONE guifg=Black guibg=White

hi Directory    term=NONE cterm=NONE ctermfg=Green ctermbg=NONE
hi Directory    gui=NONE guifg=Green guibg=NONE

hi WarningMsg   term=standout cterm=NONE ctermfg=Red ctermbg=NONE
hi WarningMsg   gui=standout guifg=Red guibg=NONE

hi Error        term=NONE cterm=NONE ctermfg=White ctermbg=Red
hi Error        gui=NONE guifg=White guibg=Red

hi Cursor       ctermfg=Black ctermbg=Yellow
hi Cursor       guifg=Black guibg=Yellow

hi TabLineFill    term=NONE cterm=NONE ctermfg=Black ctermbg=White
hi TabLineFill    gui=NONE guifg=Black guibg=White

