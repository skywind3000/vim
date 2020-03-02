"======================================================================
"
" init_leaderf.vim - 
"
" Created by skywind on 2020/03/01
" Last Modified: 2020/03/01 04:43:07
"
"======================================================================


function! s:test_source(...)
	let lines = [
				\ "name1     detail1 a",
				\ "name2     detail2 b",
				\ "name3     detail3 c",
				\ "name4     detail4 d",
				\ "name5     detail5 e",
				\ ]
	return lines
endfunc

function! s:test_accept(line, arg)
	echo "accept: ". a:line
endfunc

function! s:test_digest(line, mode)
	try
		let p = split(a:line)
		" unsilent echom p
	catch /^.*/
		unsilent echom "exception"
	endtry
	return [p[0], 0]
endfunc


let g:Lf_Extensions = get(g:, 'Lf_Extensions', {})
let g:Lf_Extensions.test = {
			\ 'source': string(function('s:test_source'))[10:-3],
			\ 'accept': string(function('s:test_accept'))[10:-3],
			\ 'get_digest': string(function('s:test_digest'))[10:-3],
			\ }


function! s:lf_task_source(...)
	for row in rows
		let name = row[0] . repeat(' ', maxsize - len(row[0]))	
		let source += [name . '  ' . row[1] . '  : ' . row[2]]
	endfor
	return source
endfunc

function! s:lf_task_accept(line, arg)
	let pos = stridx(a:line, '<')
	if pos < 0
		return
	endif
	let name = strpart(a:line, 0, pos)
	let name = substitute(name, '^\s*\(.\{-}\)\s*$', '\1', '')
	if name != ''
		exec "AsyncTask " . name
	endif
endfunc

function! s:lf_task_digest(line, mode)
	let pos = stridx(a:line, '<')
	if pos < 0
		return [a:line, 0]
	endif
	let name = strpart(a:line, 0, pos)
	return [name, 0]
endfunc

function! s:lf_win_init(...)
	setlocal nonumber
	setlocal nowrap
endfunc


let g:Lf_Extensions.task = {
			\ 'source': string(function('s:lf_task_source'))[10:-3],
			\ 'accept': string(function('s:lf_task_accept'))[10:-3],
			\ 'get_digest': string(function('s:lf_task_digest'))[10:-3],
			\ 'highlights_def': {
			\     'Lf_hl_funcScope': '^\S\+',
			\     'Lf_hl_funcDirname': '^\S\+\s*\zs<.*>\ze\s*:',
			\ },
			\ 'highlights_cmd': [
			\     "hi def link Lf_task_name ModeMsg",
			\ ],
			\ 'after_enter': string(function('s:lf_win_init'))[10:-3],
		\ }

" let g:Lf_WindowPosition='bottom'
" echo s:lf_task_source()


