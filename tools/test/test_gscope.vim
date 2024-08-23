"======================================================================
"
" test_gscope.vim - 
"
" Created by skywind on 2023/08/11
" Last Modified: 2023/08/11 11:13:54
"
"======================================================================

function! GscopeRun(exename, root, database, pattern, word, override)
	if !executable(a:exename)
		return ''
	endif
	let $GTAGSROOT = a:root
	let $GTAGSDBPATH = a:database
	let dbname = a:database . '\GTAGS'
	if !isdirectory(a:root)
		redrawstatus
		echohl ErrorMsg
		echo "gtags-cscope error: bad project root: " . a:root
		echohl None
		return -1
	endif
	if has('win32') || has('win64') || has('win95') || has('win16')
		let cmd = 'cd /d ' . shellescape(a:root) . ' && ' . a:exename
		let win = 1
	else
		let cmd = 'cd ' . shellescape(a:root) . ' && ' . a:exename
		let win = 0
	endif
	let num = 0
	if a:pattern == '0' || a:pattern == 's'
		let num = 0
	elseif a:pattern == '1' || a:pattern == 'g'
		let num = 1
	elseif a:pattern == '2' || a:pattern == 'd'
		let num = 2
	elseif a:pattern == '3' || a:pattern == 'c'
		let num = 3
	elseif a:pattern == '4' || a:pattern == 't'
		let num = 4
	elseif a:pattern == '6' || a:pattern == 'e'
		let num = 6
	elseif a:pattern == '7' || a:pattern == 'f'
		let num = 7
	elseif a:pattern == '8' || a:pattern == 'i'
		let num = 8
	elseif a:pattern == '9' || a:pattern == 'a'
		let num = 9
	endif
	let cmd = cmd . ' -d '
	let cmd = cmd . ' -F ' . shellescape(dbname)
	let cmd = cmd . ' -L -' . num . ' ' . shellescape(a:word)
	let content = system(cmd)
	if v:shell_error != 0
		redraw
		let hr = substitute(content, '[\n\r]', ' ', 'g')
		echohl ErrorMsg
		echo "gtags-cscope error: " . hr
		echohl None
		return -2
	endif
	let output = []
	for text in split(content, "\n")
		let text = substitute(text, '^\s*\(.\{-}\)\s*$', '\1', '')
		if text == ''
			continue
		endif
		let p1 = stridx(text, ' ')
		if p1 < 0
			continue
		endif
		let fn = strpart(text, 0, p1)
		let p2 = stridx(text, ' ', p1 + 1)
		if p2 < 0
			continue
		endif
		let fw = strpart(text, p1 + 1, p2 - p1 - 1)
		let p3 = stridx(text, ' ', p2 + 1)
		if p3 < 0
			continue
		endif
		let fl = strpart(text, p2 + 1, p3 - p2 - 1)
		let ft = strpart(text, p3 + 1)
		let nn = a:root . '/' . fn
		if win != 0
			let nn = tr(nn, "/", '\')
		endif
		let tt = printf('%s(%d): <<%s>> %s', nn, fl, fw, ft)
		call add(output, tt)
	endfor
	if len(output) == 0
		redraw
		echohl ErrorMsg
		echo "E259: not find '". a:word ."'"
		echohl None
		return 0
	endif
	let text = join(output, "\n")
	let efm = &l:errorformat
	let &l:errorformat = '%f(%l):%m'
	try
		if !a:override
			caddexpr text
		else
			cexpr text
		endif
	catch
	endtry
	let &l:errorformat = efm
	return len(output)
endfunc


let exename = 'gtags-cscope'
let root = 'E:\Code\ping\bbnet'
let database = 'E:\Local\Cache\tags\E--Code-ping-bbnet'

cexpr "[HELLO]"
call GscopeRun(exename, root, database, 0, 'ProtocolFlush', 0)


