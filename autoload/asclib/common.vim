"----------------------------------------------------------------------
" detection
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win16') || has('win95') || has('win64')
let g:asclib = get(g:, 'asclib', {})
let g:asclib#common#windows = s:windows
let g:asclib#common#unix = (s:windows == 0)? 1 : 0
let g:asclib#common#path = fnamemodify(expand('<sfile>:p'), ':h:h:h')


"----------------------------------------------------------------------
" returns v:echospace
"----------------------------------------------------------------------
function! asclib#common#echospace() abort
	if exists('v:echospace')
		return v:echospace
	endif
	let statusline = (&laststatus == 2)? 1 : 0
	let statusline = statusline || (&laststatus == 1 && winnr('$') > 1)
    let reqspaces_lastline = (statusline || !&ruler) ? 12 : 29
    return &columns - reqspaces_lastline
endfunc


"----------------------------------------------------------------------
" error message
"----------------------------------------------------------------------
function! asclib#common#errmsg(text, ...)
	let text = (a:0 == 0)? a:text : a:text . ' ' . join(a:000, ' ')
	let pos = stridx(text, "\n")
	if pos >= 0
		let text = strpart(text, 0, pos)
	endif
	let text = strpart(text, 0, asclib#common#echospace() - 1)
	redraw
	echohl ErrorMsg
	echom text
	echohl None
endfunc


"----------------------------------------------------------------------
" echo message (size safe)
"----------------------------------------------------------------------
function! asclib#common#echo(highlight, text, ...) abort
	let text = (a:0 == 0)? a:text : a:text . ' ' . join(a:000, ' ')
	let pos = stridx(text, "\n")
	if pos >= 0
		let text = strpart(text, 0, pos)
	endif
	let text = strpart(text, 0, asclib#common#echospace() - 1)
	redraw
	if a:highlight != ''
		exec 'echohl ' . a:highlight
	endif
	echo text
	echohl None
endfunc


"----------------------------------------------------------------------
" notify
"----------------------------------------------------------------------
function! asclib#common#notify(text, type) abort
	let text = (a:type == '')? a:text : printf("[%s] %s", a:type, a:text)
	call asclib#common#echo('Special', text)
endfunc


"----------------------------------------------------------------------
" message
"----------------------------------------------------------------------
function! asclib#common#message(text, ...) abort
	let text = (a:0 == 0)? a:text : a:text . ' ' . join(a:000, ' ')
	call asclib#common#echo('Title', text)
endfunc


"----------------------------------------------------------------------
" keywords complete
"----------------------------------------------------------------------
function! asclib#common#complete(ArgLead, CmdLine, CursorPos, Keywords)
	let candidate = []
	for word in a:Keywords
		if asclib#string#startswith(word, a:ArgLead)
			let candidate += [word]
		endif
	endfor
	return candidate
endfunc



"----------------------------------------------------------------------
" print lines
"----------------------------------------------------------------------
function! asclib#common#print_content(content) abort
	for text in a:content
		echo text
	endfor
endfunc


"----------------------------------------------------------------------
" timing
"----------------------------------------------------------------------
function! asclib#common#timeit(func, ...)
	let start = reltime()
	try
		call call(a:func, a:000)
	catch
		echohl ErrorMsg
		echo "Error: " . v:exception
		echohl None
	endtry
	let end = reltime()
	let time = reltimestr(reltime(start, end))
	return time
endfunc





