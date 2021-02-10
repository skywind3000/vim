"======================================================================
"
" signtune.vim - tune signify's appearance to git gutter
"
" Created by skywind on 2018/10/26
" Last Modified: 2018/10/26 15:05:58
"
"======================================================================
if get(g:, 'signify_as_gitgutter', '0') == '0'
	finish
endif

let g:signify_sign_add               = '+'
let g:signify_sign_delete            = '_'
let g:signify_sign_delete_first_line = '‾'
let g:signify_sign_change            = '~'
let g:signify_sign_changedelete      = g:signify_sign_change
let g:signify_sign_show_count        = 0


function! s:match_highlight(highlight, pattern) abort
	let matches = matchlist(a:highlight, a:pattern)
	if len(matches) == 0
		return 'NONE'
	endif
	return matches[1]
endfunc

function! s:get_bg_colors(group) abort
	redir => highlight
	silent execute 'silent highlight ' . a:group
	redir END
	let link_matches = matchlist(highlight, 'links to \(\S\+\)')
	if len(link_matches) > 0 " follow the link
		return s:get_bg_colors(link_matches[1])
	endif
	let ctermbg = s:match_highlight(highlight, 'ctermbg=\([0-9A-Za-z]\+\)')
	let guibg   = s:match_highlight(highlight, 'guibg=\([#0-9A-Za-z]\+\)')
	return [guibg, ctermbg]
endfunc

function! s:tune_colors() abort
	let [guibg, ctermbg] = s:get_bg_colors('SignColumn')

	execute "hi GitGutterAddDefault    guifg=#009900 guibg=" . guibg . " ctermfg=2 ctermbg=" . ctermbg
	execute "hi GitGutterChangeDefault guifg=#bbbb00 guibg=" . guibg . " ctermfg=3 ctermbg=" . ctermbg
	execute "hi GitGutterDeleteDefault guifg=#ff2222 guibg=" . guibg . " ctermfg=1 ctermbg=" . ctermbg
	hi default link GitGutterChangeDeleteDefault GitGutterChangeDefault

	execute "hi GitGutterAddInvisible    guifg=bg guibg=" . guibg . " ctermfg=" . ctermbg . " ctermbg=" . ctermbg
	execute "hi GitGutterChangeInvisible guifg=bg guibg=" . guibg . " ctermfg=" . ctermbg . " ctermbg=" . ctermbg
	execute "hi GitGutterDeleteInvisible guifg=bg guibg=" . guibg . " ctermfg=" . ctermbg . " ctermbg=" . ctermbg
	hi default link GitGutterChangeDeleteInvisible GitGutterChangeInvisible

	hi default link SignifySignAdd GitGutterAddDefault
	hi default link SignifySignChange GitGutterChangeDefault
	hi default link SignifySignDelete GitGutterDeleteDefault
	hi default link SignifySignChangeDelete GitGutterChangeDeleteDefault
	hi default link SignifySignDeleteFirstLine GitGutterDeleteDefault
endfunc

" autocmd VimEnter * call s:tune_colors()
call s:tune_colors()


