"======================================================================
"
" text.vim - 
"
" Created by skywind on 2024/03/19
" Last Modified: 2024/03/19 18:01
"
"======================================================================


"----------------------------------------------------------------------
" https://github.com/lilydjwg/dotvim 
"----------------------------------------------------------------------
function! asclib#text#match_at_cursor(pattern) abort
	let t = asclib#string#matchat(getline('.'), a:pattern, col('.') - 1)
	return t[2]
endfunc


"----------------------------------------------------------------------
" get select text
"----------------------------------------------------------------------
function! asclib#text#get_selected(...) abort
	let mode = get(a:, 1, mode(1))
	if mode =~ '^n'
		let mode = 'v'
	endif
	let lines = asclib#compat#getregion("'<", "'>", mode)
	return join(lines, "\n")
endfunc


"----------------------------------------------------------------------
" filter current buffer
"----------------------------------------------------------------------
function! asclib#text#filter(line1, line2, command, ...) abort
	let line1 = (type(a:line1) != v:t_number)? line(a:line1) : (a:line1)
	let line2 = (type(a:line2) != v:t_number)? line(a:line2) : (a:line2)
	let size = line2 - line1 + 1
	if line1 < line2
		let lnum = line('.')
		let bid = bufnr('')
		let encoding = (a:0 > 0)? a:1 : ''
		let opts = {'encoding': encoding}
		let opts.strict = 1
		call asclib#core#text_replace(bid, line1, size, a:command, opts)
		exec ':' . lnum
		if g:asclib#core#shell_error != 0
			let t ='filter shell error: ' . g:asclib#core#shell_error
			call asclib#common#errmsg(t)
		endif
	endif
endfunc


"----------------------------------------------------------------------
" format the whole buffer
"----------------------------------------------------------------------
function! asclib#text#format(command, ...) abort
	let encoding = (a:0 > 0)? a:1 : ''
	call asclib#text#filter(1, line('$'), a:command, encoding)
endfunc



