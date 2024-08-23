"======================================================================
"
" neosnippet.vim - 
"
" Created by skywind on 2023/08/10
" Last Modified: 2023/08/10 22:31:38
"
"======================================================================

let s:scripthome = fnamemodify(resolve(expand('<sfile>:p')), ':h')

let g:neosnippet#enable_snipmate_compatibility = 1
let g:neosnippet#disable_runtime_snippets = { '_' : 1 }

let g:neosnippet#snippets_directory = s:scripthome . '/../snippets'


if 0
	imap <m-e>     <Plug>(neosnippet_expand_or_jump)
	smap <m-e>     <Plug>(neosnippet_expand_or_jump)
	xmap <m-e>     <Plug>(neosnippet_expand_or_jump)
else
	imap <m-e> <c-r>=neosnippet#mappings#expand_or_jump_impl()<cr>
	" smap <m-e> <c-r>=neosnippet#mappings#expand_or_jump_impl()<cr>
	smap <m-e>     <Plug>(neosnippet_expand_or_jump)
	xmap <m-e>     <Plug>(neosnippet_expand_or_jump)
endif


