"======================================================================
"
" cpp.vim - 
"
" Created by skywind on 2021/12/22
" Last Modified: 2021/12/22 22:23:49
"
"======================================================================


"----------------------------------------------------------------------
" fetch current word
"----------------------------------------------------------------------
function! module#cpp#fetch_cword() abort
	let word = expand('<cword>')
	let text = asclib#text#match_at_cursor('\v(\w+\:\:)*\w+')
	if len(word) > len(text)
		return word
	endif
	return text
endfunc


"----------------------------------------------------------------------
" call cppman
"----------------------------------------------------------------------
function! module#cpp#cppman()
	let word = module#cpp#fetch_cword()
	if word == ''
		return
	endif
	exec printf('Cppman %s', word)
endfunc


"----------------------------------------------------------------------
" switch header
"----------------------------------------------------------------------
function! module#cpp#switch_header(...)
	let l:main = expand('%:p:r')
	let l:fext = expand('%:e')
	if index(['c', 'cpp', 'm', 'mm', 'cc'], l:fext) >= 0
		let l:altnames = ['h', 'hpp', 'hh']
	elseif index(['h', 'hh', 'hpp'], l:fext) >= 0
		let l:altnames = ['c', 'cpp', 'cc', 'm', 'mm']
	elseif l:fext == '' && ft == 'cpp'
		let l:altnames = ['cpp', 'cc' ]
	else
		echo 'switch failed, not a c/c++ source'
		return 
	endif
	let found = ''
	for l:next in l:altnames
		let l:newname = l:main . '.' . l:next
		if filereadable(l:newname)
			let found = l:newname
			break
		endif
	endfor
	if found != ''
		let switch = (a:0 < 1)? '' : a:1
		let opts = {}
		if switch != ''
			let opts.switch = 'useopen,' . switch
		endif
		" unsilent echom opts
		call asclib#core#switch(found, opts)
	else
		let t = 'switch failed, can not find another part of c/c++ source'
		call asclib#core#errmsg(t)
	endif
endfunc


"----------------------------------------------------------------------
" insert a class name
"----------------------------------------------------------------------
function! module#cpp#class_insert(line1, line2)
	let msg = 'Enter a class name to insert: '
	let tag = expand('%:t:r')
	let clsname = asclib#ui#input(msg, tag, 'clsname')
	if clsname != ''
		let clsname = escape(clsname, '/\[*~^')
		let text = 's/\~\=\w\+\s*(/' . clsname . '::&/'
		exec a:line1 . ',' . a:line2 . text
	endif
endfunc


"----------------------------------------------------------------------
" expand brace
"----------------------------------------------------------------------
function! module#cpp#brace_expand(line1, line2)
	let cmd = 's/;\s*$/\r{\r}\r\r/'
	exec a:line1 . ',' . a:line2 . cmd
endfunc


"----------------------------------------------------------------------
" WhatFunctionAreWeIn()
"----------------------------------------------------------------------
function! module#cpp#function_name()
	let strList = ["while", "foreach", "ifelse", "if else", "for", "if"]
	let strList += ["else", "try", "catch", "case", "switch"]
	let foundcontrol = 1
	let position = ""
	let pos = getpos(".")          " This saves the cursor position
	let view = winsaveview()       " This saves the window view
	while (foundcontrol)
		let foundcontrol = 0
		normal [{
		call search('\S','bW')
		let tempchar = getline(".")[col(".") - 1]
		if (match(tempchar, ")") >=0 )
			normal %
			call search('\S','bW')
		endif
		let tempstring = getline(".")
		for item in strList
			if (match(tempstring,item) >= 0)
			let position = item . " - " . position
			let foundcontrol = 1
			break
	  endif
		endfor
		if foundcontrol == 0
		call cursor(pos)
		call winrestview(view)
		return tempstring.position
	endif
	endwhile
	call cursor(pos)
	call winrestview(view)
	return tempstring.position
endfunc


"----------------------------------------------------------------------
" get class name
"----------------------------------------------------------------------
function! module#cpp#get_class_name()
	let lnum = line('.')
	while lnum > 0
		let text = getline(lnum)
		let name = matchstr(text, '^\s*\<class\>\s*\zs\w\+')
		if name != ''
			return name
		endif
		let name = matchstr(text, '^\s*\<struct\>\s*\zs\w\+')
		let lnum -= 1
	endwhile
	return ''
endfunc


"----------------------------------------------------------------------
" get namespace
"----------------------------------------------------------------------
function! module#cpp#get_namespace()
	let lnum = line('.')
	while lnum > 0
		let text = getline(lnum)
		let name = matchstr(text, '^\s*\<namespace\>\s*\zs\w\+')
		if name != ''
			return name
		endif
		let lnum -= 1
	endwhile
	return ''
endfunc


"----------------------------------------------------------------------
" copy function definition
"----------------------------------------------------------------------
function! module#cpp#copy_definition()
	let s:class = module#cpp#get_class_name()
	let s:namespace = module#cpp#get_namespace()
	let text = getline('.')
	let text = substitute(text, '\/\*.*\*\/', '', 'g')
	let text = substitute(text, '\/\/.*$', '', 'g')
	let text = substitute(text, '^\s*', '', 'g')
	let text = substitute(text, ';[\r\n\t ]*$', '', 'g')
	let s:defline = text
	let g:defline = s:defline
	let comments = []
	let curline = line('.')
	let nextline = curline - 1
	while nextline > 0
		let text = getline(nextline)
		let text = asclib#string#strip(text)
		if text =~ '^\/\/'
			call add(comments, text)
		else
			break
		endif
		let nextline -= 1
	endwhile
	call reverse(comments)
	let s:fcomments = comments
endfunc


"----------------------------------------------------------------------
" paste imp
"----------------------------------------------------------------------
function! module#cpp#paste_implementation()
	if exists('s:defline') == 0
		return 0
	endif
	if len(s:fcomments) > 0
		call append(line('.') - 1, '')
		call append(line('.') - 1, '//' .. repeat('-', 69))
		for text in s:fcomments
			call append(line('.') - 1, text)
		endfor
		call append(line('.') - 1, '//' .. repeat('-', 69))
		exe 'normal k'
	endif
	call append('.', s:defline)
	exe 'normal j'
	" Remove keywords
	s/\<virtual\>\s*//e
	s/\<static\>\s*//e
	let s:namespace = ''
	if s:namespace == ''
		let l:classString = s:class . "::"
	else
		let l:classString = s:namespace . "::" . s:class . "::"
	endif
	if s:class == '' || &ft == 'c'
		let l:classString = ''
	endif
	" Remove default parameters
	s/\s\{-}=\s\{-}[^,)]\{1,}//e
	" Add class qualifier
	exe 'normal! ^f(bi' . l:classString
	stopinsert
	" Add brackets
	exe "normal! $o{\<CR>\<TAB>\<CR>}\<CR>"
	stopinsert
	exec "normal! kkkk"
	" Fix indentation
	exe 'normal! =4j^<4j'
	return 1
endfunc


"----------------------------------------------------------------------
" create non-copyable
"----------------------------------------------------------------------
function! module#cpp#create_non_copyable()
	let cc = module#cpp#get_class_name()
	if cc == ''
		return 0
	endif
	let t = ['']
	if 1
		let t += [printf("\t%s(const %s&) = delete;", cc, cc)]
		let t += [printf("\t%s& operator = (const %s&) = delete;", cc, cc)]
	elseif 1
		let t += ['private:']
		let t += [printf("\t%s(const %s&);", cc, cc)]
		let t += [printf("\t%s & operator = (const %s&);", cc, cc)]
	else
		let t += ['private:']
		let t += [printf("\t%s(const %s&) = delete;", cc, cc)]
		let t += [printf("\t%s & operator = (const %s&) = delete;", cc, cc)]
	endif
	let t += ['']
	call append(line('.') - 1, t)
endfunc


