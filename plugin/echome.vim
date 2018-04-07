"======================================================================
"
" echome.vim - echo function signature on cmdline with YouCompleteMe
"
" Created by skywind on 2018/04/07
" Last Modified: 2018/04/07 22:15:12
"
"======================================================================


"----------------------------------------------------------------------
" echo text with highlighting in cmdline
"----------------------------------------------------------------------
function! echome#display(items)
    let wincols = &columns
    let statusline = (&laststatus==1 && winnr('$')>1) || (&laststatus==2)
    let reqspaces_lastline = (statusline || !&ruler) ? 12 : 29
    let avail = wincols - reqspaces_lastline - 1
	if avail <= 0 
		return
	endif
	redraw
	for item in a:items
		let text = ''
		let hi = ''
		if type(item) == 1
			let text = item
		elseif type(item) == 3
			let text = item[0]
			let hi = item[1]
		elseif type(item) == 4
			let text = item.text
			let hi = item.hi
		endif
		let width = len(text)
		if width == 0
			continue
		endif
		if width > avail 
			let text = strpart(text, 0, avail)
			let width = avail
		end
		if hi == '' || tolower(hi) == 'none' || tolower(hi) == 'null'
			echohl NONE
		else
			exec 'echohl ' . hi
		end
		echon text
		let avail -= width
		if avail <= 0
			break
		end
	endfor
	echohl None
endfunc


"----------------------------------------------------------------------
" remove tailing and leading spaces
"----------------------------------------------------------------------
function! s:string_strip(text)
	return substitute(a:text, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunc


"----------------------------------------------------------------------
" parse function prototype/signature and print with highlighting
"----------------------------------------------------------------------
function! echome#echo_function(prototype, head)
	let parameters = []
	let p1 = stridx(a:prototype, '(')
	let p2 = stridx(a:prototype, ')', p1 >= 0 ? p1 : 0)
	let main = a:prototype
	if p1 >= 0 && p2 >= 0
		let main = strpart(a:prototype, 0, p1)
		let main = s:string_strip(main)	
		let text = strpart(a:prototype, p1 + 1, p2 - p1 - 1)
		let text = s:string_strip(text)
		let parameters += [['(', 'Operator']]
		let items = split(text, ',', 1)
		for index in range(len(items))
			let item = items[index]
			let parameters += [[s:string_strip(item), '']]
			if index < len(items) - 1
				let parameters += [[', ', 'Delimiter']]
			endif
		endfor
		let parameters += [[')', 'Operator']]
	endif
	let items = []
	let pos = len(main) - 1
	let first = ''
	let second = main
	while pos >= 0
		let ch = strpart(main, pos - 1, 1)
		if ch !~ '\w'
			let first = strpart(main, 0, pos)
			let second = strpart(main, pos)
			break
		endif
		let pos -= 1
	endwhile
	if a:head != ''
		let items += [[a:head, 'Constant']]
	endif
	if first != ''
		let items += [[first, 'Type']]
	endif
	let items += [[second, 'Identifier']]
	let items += parameters
	call echome#display(items)
endfunc


"----------------------------------------------------------------------
" echo function from v:completed
"----------------------------------------------------------------------
function! echome#echo_completed()
	set noshowmode
	if !pumvisible()
		return
	endif
	let info = get(v:completed_item, 'info')
	if info != '' 
		let infos = split(info, "\n")
		if len(infos) > 0 
			let info = infos[0]
			if info != ''
				call echome#echo_function(info, '>>> ')
			endif
		endif
	endif 
endfunc


"----------------------------------------------------------------------
" insert mapping
"----------------------------------------------------------------------
function! echome#map_open_paren()
	call echome#echo_completed()
	return '('
endfunc

function! echome#enable()
	inoremap <silent><expr> ( echome#map_open_paren()
endfunc

let s:showmode = &showmode

function! echome#disable()
	iunmap <expr> (
	let &showmode = s:showmode
endfunc

function! echome#buffer_enable()
	inoremap <silent><buffer><expr> ( echome#map_open_paren()
endfunc

function! echome#buffer_disable()
	iunmap <buffer><expr> (
	let &showmode = s:showmode
endfunc


"----------------------------------------------------------------------
" initialize
"----------------------------------------------------------------------
if get(g:, 'echome_enable', 0) != 0
	call echome#enable()
endif



