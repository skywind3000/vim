"======================================================================
"
" snipmate.vim - 
"
" Created by skywind on 2022/08/30
" Last Modified: 2022/08/30 16:51:03
"
"======================================================================


"----------------------------------------------------------------------
" initialize
"----------------------------------------------------------------------
let g:snipMate = { 'snippet_version' : 1 }
let g:snipMate.dirs = [asclib#path#runtime('site')]
let g:snipMate.description_in_completion = 1

let g:snips_author = 'skywind'


"----------------------------------------------------------------------
" snipmate enhancement: allow extra paths in g:snipMate.dirs
"----------------------------------------------------------------------
call module#snipmate#active()


"----------------------------------------------------------------------
" edit snip
"----------------------------------------------------------------------
function! s:SnipMateEdit(args)
	let ft = (a:args == '')? &ft : (a:args)
	let test = asclib#path#runtime('site/snippets')
	let test = asclib#path#normalize(test)
	if isdirectory(test)
		let fn = printf('%s/%s.snippets', test, ft)
		let cmd = 'FileSwitch -switch=useopen,usetab,auto ' . fnameescape(fn)
		exec cmd
	else
		call asclib#core#errmsg('invalid path: ' . test)
	endif
endfunc

command! -nargs=? SnipMateEdit call s:SnipMateEdit(<q-args>)


if 0
	imap <expr> <m-e> pumvisible() ? '<c-g>u<Plug>snipMateTrigger' : '<Plug>snipMateTrigger'
	imap <expr> <m-n> pumvisible() ? '<c-g>u<Plug>snipMateNextOrTrigger' : '<Plug>snipMateNextOrTrigger'
	smap <m-n> <Plug>snipMateNextOrTrigger
	imap <expr> <m-p> pumvisible() ? '<c-g>u<Plug>snipMateBack' : '<Plug>snipMateBack'
	smap <m-p> <Plug>snipMateBack
	imap <expr> <m-m> pumvisible() ? '<c-g>u<Plug>snipMateShow' : '<Plug>snipMateShow'
elseif 0
	imap <expr> <m-e> pumvisible() ? '<c-g>u<Plug>snipMateNextOrTrigger' : '<Plug>snipMateNextOrTrigger'
	smap <m-e> <Plug>snipMateNextOrTrigger
	imap <expr> <m-E> pumvisible() ? '<c-g>u<Plug>snipMateBack' : '<Plug>snipMateBack'
	smap <m-E> <Plug>snipMateBack
	imap <expr> <m-m> pumvisible() ? '<c-g>u<Plug>snipMateShow' : '<Plug>snipMateShow'
else
	imap <m-e> <plug>snipMateNextOrTrigger
	smap <m-e> <plug>snipMateNextOrTrigger
	imap <m-E> <plug>snipMateBack
	smap <m-E> <plug>snipMateBack
endif



