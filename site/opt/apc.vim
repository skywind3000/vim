"======================================================================
"
" apc.vim - auto popup completion window for dictionary completion
"
" Maintainer: skywind3000 (at) gmail.com, 2020
"
" Last Modified: 2020/03/03 16:26
" Verision: 0.0.2
"
" Usage:
"
" set cpt=.,w,b,k,t
" set completeopt=menu,menuone,noselect
" let g:apc_enable_ft = {'text':1, 'markdown':1, 'php':1}
" 
"======================================================================

" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :


"----------------------------------------------------------------------
" config
"----------------------------------------------------------------------

" enable filetypes
let g:apc_enable_ft = get(g:, 'apc_enable_ft', {})

" remap tab
let g:apc_enable_tab = get(g:, 'apc_enable_tab', 1)

" minimal length to open completion popup
let g:apc_min_length = get(g:, 'apc_min_length', 2)

" ignore keywords
let g:apc_key_ignore = get(g:, 'apc_key_ignore', [])

" reset cpt
let g:apc_reset_cpt = get(g:, 'apc_reset_cpt', 'k,.,w,b,t,i')


"----------------------------------------------------------------------
" internal methods
"----------------------------------------------------------------------

function! s:get_context()
	return strpart(getline('.'), 0, col('.') - 1)
endfunc

function! s:meets_keyword(context)
	if g:apc_min_length <= 0
		return 0
	endif
	let matches = matchlist(a:context, '\(\k\{' . g:apc_min_length . ',}\)$')
	if empty(matches)
		return 0
	endif
	for ignore in g:apc_key_ignore
		if stridx(ignore, matches[1]) == 0
			return 0
		endif
	endfor
	return 1
endfunc

function! s:check_back_space() abort
	  let col = col('.') - 1
	  return !col || getline('.')[col - 1]  =~# '\s'
endfunc


"----------------------------------------------------------------------
" feed popup
"----------------------------------------------------------------------
function! s:feed_popup()
	let enable = get(b:, 'apc_enable', 0)
	let lastx = get(b:, 'apc_lastx', -1)
	let lasty = get(b:, 'apc_lasty', -1)
	let tick = get(b:, 'apc_tick', -1)
	if pumvisible() || &bt != '' || enable == 0
		return -1
	endif
	let x = col('.') - 1
	let y = line('.') - 1
	if lastx == x && lasty == y
		return -2
	endif
	if b:changedtick == tick
		return -3
	endif
	let context = s:get_context()
	if s:meets_keyword(context)
		call feedkeys("\<c-n>", 'n')
		let b:apc_lastx = x
		let b:apc_lasty = y
		let b:apc_tick = b:changedtick
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" enable apc
"----------------------------------------------------------------------
function! s:apc_enable()
	call s:apc_disable()
	augroup ApcEventGroup
		au!
		au CursorMovedI <buffer> call s:feed_popup()
	augroup END
	let b:apc_init_autocmd = 1
	if g:apc_enable_tab
		inoremap <silent><buffer><expr> <tab>
					\ pumvisible()? "\<c-n>" :
					\ <SID>check_back_space() ? "\<tab>" : "\<c-n>"
		let b:apc_init_tab = 1
	endif
	let b:apc_save_cpt = ''
	if g:apc_reset_cpt != ''
		let b:apc_save_cpt = &cpt
		let &l:cpt = g:apc_reset_cpt
	endif
	let b:apc_save_infer = &infercase
	setlocal infercase
	let b:apc_enable = 1
endfunc


"----------------------------------------------------------------------
" disable apc
"----------------------------------------------------------------------
function! s:apc_disable()
	let init_autocmd = get(b:, 'apc_init_autocmd', 0)
	let init_tab = get(b:, 'apc_init_tab', 0)
	let save_cpt = get(b:, 'apc_save_cpt', '')
	let save_infer = get(b:, 'apc_save_infer', '')
	if init_autocmd
		augroup ApcEventGroup
			au! 
		augroup END
		let b:apc_init_autocmd = 0
	endif
	if init_tab
		silent! iunmap <buffer><expr> <tab>
		let b:apc_init_tab = 0
	endif
	if save_cpt != ''
		let &l:cpt = save_cpt
		let b:apc_save_cpt = ''
	endif
	if save_infer != ''
		let &l:infercase = save_infer
		let b:apc_save_infer = ''
	endif
	let b:apc_enable = 0
endfunc


"----------------------------------------------------------------------
" check if need to be enabled
"----------------------------------------------------------------------
function! s:apc_check_init()
	if &bt != ''
		return
	endif
	let enable = get(g:apc_enable_ft, &ft, 0)	
	if enable != 0
		ApcEnable
	endif
endfunc


"----------------------------------------------------------------------
" commands
"----------------------------------------------------------------------
command -nargs=0 ApcEnable call s:apc_enable()
command -nargs=0 ApcDisable call s:apc_disable()


"----------------------------------------------------------------------
" autocmd
"----------------------------------------------------------------------
augroup ApcInitGroup
	au!
	au FileType * call s:apc_check_init()
augroup END



