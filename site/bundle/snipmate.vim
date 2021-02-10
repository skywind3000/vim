" using new parser
let g:snipMate = { 'snippet_version' : 1 }

if 0
	imap <expr> <m-e> pumvisible() ? '<c-g>u<Plug>snipMateTrigger' : '<Plug>snipMateTrigger'
	imap <expr> <m-n> pumvisible() ? '<c-g>u<Plug>snipMateNextOrTrigger' : '<Plug>snipMateNextOrTrigger'
	smap <m-n> <Plug>snipMateNextOrTrigger
	imap <expr> <m-p> pumvisible() ? '<c-g>u<Plug>snipMateBack' : '<Plug>snipMateBack'
	smap <m-p> <Plug>snipMateBack
	imap <expr> <m-m> pumvisible() ? '<c-g>u<Plug>snipMateShow' : '<Plug>snipMateShow'
elseif 1
	imap <expr> <m-e> pumvisible() ? '<c-g>u<Plug>snipMateNextOrTrigger' : '<Plug>snipMateNextOrTrigger'
	smap <m-e> <Plug>snipMateNextOrTrigger
	imap <expr> <m-E> pumvisible() ? '<c-g>u<Plug>snipMateBack' : '<Plug>snipMateBack'
	smap <m-E> <Plug>snipMateBack
	imap <expr> <m-m> pumvisible() ? '<c-g>u<Plug>snipMateShow' : '<Plug>snipMateShow'
endif

