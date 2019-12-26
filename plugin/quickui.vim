"======================================================================
"
" quickui.vim - 
"
" Created by skywind on 2019/12/26
" Last Modified: 2019/12/26 18:20:52
"
"======================================================================

" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :



"----------------------------------------------------------------------
" default highlighting
"----------------------------------------------------------------------

function! s:hilink(name, target)
	if !hlexists(a:name)
		exec 'hi! link ' . a:name . ' ' . a:target
	endif
endfunc

hi! QuickDefaultBackground ctermfg=0 ctermbg=7 guifg=black guibg=gray
hi! QuickDefaultKey ctermfg=9 guifg=#f92772
hi! QuickDefaultDisable ctermfg=59 guifg=#75715e
hi! QuickDefaultSel cterm=bold,reverse ctermfg=7 ctermbg=6 gui=bold,reverse guifg=brown guibg=gray

call s:hilink('QuickBG', 'Pmenu')
call s:hilink('QuickKey', 'Keyword')
call s:hilink('QuickOff', 'Comment')
call s:hilink('QuickSel', 'PmenuSel')
call s:hilink('QuickHelp', 'Title')


