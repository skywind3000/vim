" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :
"
" apm.vim - auto popup completion window
"
" Created by skywind on 2023/03/05
" Last Modified: 2023/12/11 00:00
"
" Features:
"
" - auto popup complete window without select the first one
" - tab/s-tab to cycle suggestions, <c-e> to cancel
" - use ApmEnable/ApmDisable to toggle for certiain file.
"
" Usage:
"
" set cpt=.,k,b
" set completeopt=menu,menuone,noselect
" let g:apm_enable_ft = {'text':1, 'markdown':1, 'php':1}

let g:apm_enable_ft = get(g:, 'apm_enable_ft', {})    " enable filetypes
let g:apm_enable_tab = get(g:, 'apm_enable_tab', 1)   " remap tab
let g:apm_min_length = get(g:, 'apm_min_length', 2)   " minimal length to open popup
let g:apm_key_ignore = get(g:, 'apm_key_ignore', [])  " ignore keywords
let g:apm_trigger = get(g:, 'apm_trigger', "\<c-n>")  " which key to trigger popmenu

" get word before cursor
function! s:get_context()
	return strpart(getline('.'), 0, col('.') - 1)
endfunc

function! s:meets_keyword(context)
	if g:apm_min_length <= 0
		return 0
	endif
	let matches = matchlist(a:context, '\(\k\{' . g:apm_min_length . ',}\)$')
	if empty(matches)
		return 0
	endif
	for ignore in g:apm_key_ignore
		if stridx(ignore, matches[1]) == 0
			return 0
		endif
	endfor
	return 1
endfunc

function! s:check_back_space() abort
	  return col('.') < 2 || getline('.')[col('.') - 2]  =~# '\s'
endfunc

function! s:check_omni_avail() abort
	if &omnifunc == ''
		return 0
	endif
	let ctx = s:get_context()
	if ctx =~ '^\s*$'
		return 0
	elseif ctx =~ '\s$'
		return 0
	endif
	let start = call(&omnifunc, [1, ''])
	if start < 0 || start >= col('.') - 1
		return 0
	endif
	let base = strpart(ctx, start)
	let pos = getpos('.')
	let new = [pos[0], pos[1], pos[2] - strchars(base), pos[3]]
	call setpos('.', new)
	let hr = call(&omnifunc, [0, base])
	call setpos('.', pos)
	if type(hr) == type(v:null)
		return 0
	elseif type(hr) == type([])
		if len(hr) == 0
			return 0
		endif
	elseif type(hr) == type({})
		if has_key(hr, 'words')
			if len(hr['words']) == 0
				return 0
			endif
		endif
	endif
	return 1
endfunc

function! s:on_backspace()
	if pumvisible() == 0
		return "\<BS>"
	endif
	let text = matchstr(s:get_context(), '.*\ze.')
	return s:meets_keyword(text)? "\<BS>" : "\<c-e>\<bs>"
endfunc


" autocmd for CursorMovedI
function! s:feed_popup()
	let enable = get(b:, 'apm_enable', 0)
	let lastx = get(b:, 'apm_lastx', -1)
	let lasty = get(b:, 'apm_lasty', -1)
	let tick = get(b:, 'apm_tick', -1)
	let omni = get(b:, 'apm_omni', 0)
	if &bt != '' || enable == 0 || &paste
		return -1
	endif
	let x = col('.') - 1
	let y = line('.') - 1
	if pumvisible()
		let context = s:get_context()
		if s:meets_keyword(context) == 0
			call feedkeys("\<c-e>", 'n')
		endif
		let b:apm_lastx = x
		let b:apm_lasty = y
		let b:apm_tick = b:changedtick
		return 0
	elseif lastx == x && lasty == y
		return -2
	elseif b:changedtick == tick
		let lastx = x
		let lasty = y
		return -3
	endif
	if omni
		if s:check_omni_avail()
			silent! call feedkeys("\<c-x>\<c-o>", 'n')
			let b:apm_lastx = x
			let b:apm_lasty = y
			let b:apm_tick = b:changedtick
			return 0
		endif
	endif
	let context = s:get_context()
	if s:meets_keyword(context)
		if exists('*complete_info') == 1
			let info = complete_info(['mode'])
			if info.mode != ''
				silent! call feedkeys("\<c-e>", 'n')
			endif
		endif
		silent! call feedkeys(get(b:, 'apm_trigger', g:apm_trigger), 'n')
		let b:apm_lastx = x
		let b:apm_lasty = y
		let b:apm_tick = b:changedtick
	endif
	return 0
endfunc

" autocmd for CompleteDone
function! s:complete_done()
	let b:apm_lastx = col('.') - 1
	let b:apm_lasty = line('.') - 1
	let b:apm_tick = b:changedtick
endfunc

" enable apc
function! s:apm_enable()
	if !exists('*complete_info')
		return
	endif
	call s:apm_disable()
	augroup ApmEventGroup
		au!
		au CursorMovedI <buffer> nested call s:feed_popup()
		au CompleteDone <buffer> call s:complete_done()
	augroup END
	let b:apm_init_autocmd = 1
	if g:apm_enable_tab
		inoremap <silent><buffer><expr> <tab>
					\ pumvisible()? "\<c-n>" :
					\ <SID>check_back_space() ? "\<tab>" : 
					\ get(b:, 'apm_trigger', g:apm_trigger)
		inoremap <silent><buffer><expr> <s-tab>
					\ pumvisible()? "\<c-p>" : "\<s-tab>"
		let b:apm_init_tab = 1
	endif
	if get(g:, 'apm_cr_confirm', 0) == 0
		inoremap <silent><buffer><expr> <cr> 
					\ pumvisible()? "\<c-y>\<cr>" : "\<cr>"
	else
		inoremap <silent><buffer><expr> <cr> 
					\ pumvisible()? "\<c-y>" : "\<cr>"
	endif
	inoremap <silent><buffer><expr> <bs> <SID>on_backspace()
	let b:apm_init_bs = 1
	let b:apm_init_cr = 1
	let b:apm_save_infer = &infercase
	setlocal infercase
	let b:apm_enable = 1
endfunc

" disable apc
function! s:apm_disable()
	if get(b:, 'apm_init_autocmd', 0)
		augroup ApmEventGroup
			au! 
		augroup END
	endif
	if get(b:, 'apm_init_tab', 0)
		silent! iunmap <buffer><expr> <tab>
		silent! iunmap <buffer><expr> <s-tab>
	endif
	if get(b:, 'apm_init_bs', 0)
		silent! iunmap <buffer><expr> <bs>
	endif
	if get(b:, 'apm_init_cr', 0)
		silent! iunmap <buffer><expr> <cr>
	endif
	if get(b:, 'apm_save_infer', '') != ''
		let &l:infercase = b:apm_save_infer
	endif
	let b:apm_init_autocmd = 0
	let b:apm_init_tab = 0
	let b:apm_init_bs = 0
	let b:apm_init_cr = 0
	let b:apm_save_infer = ''
	let b:apm_enable = 0
endfunc

" check if need to be enabled
function! s:apm_check_init()
	if &bt != '' || get(b:, 'apm_enable', 1) == 0
		return
	endif
	if get(g:apm_enable_ft, &ft, 0) != 0
		ApmEnable
	elseif get(g:apm_enable_ft, '*', 0) != 0
		ApmEnable
	elseif get(b:, 'apm_enable', 0)
		ApmEnable
	endif
endfunc

" commands & autocmd
command! -nargs=0 ApmEnable call s:apm_enable()
command! -nargs=0 ApmDisable call s:apm_disable()

augroup ApmInitGroup
	au!
	au FileType * call s:apm_check_init()
	au BufEnter * call s:apm_check_init()
	au TabEnter * call s:apm_check_init()
augroup END



