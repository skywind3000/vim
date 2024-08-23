"======================================================================
"
" html.vim - 
"
" Created by skywind on 2023/09/26
" Last Modified: 2023/09/26 15:27:41
"
"======================================================================


"----------------------------------------------------------------------
" locals 
"----------------------------------------------------------------------
setlocal expandtab 
" setlocal ts=2 sts=2 sw=2

" for emmet
imap <m-r> <c-z>


"----------------------------------------------------------------------
" navigator
"----------------------------------------------------------------------
let b:navigator = { 'prefix': '<tab><tab>' }
let b:navigator_insert = { 'prefix': '<c-\><c-\>' }

let b:navigator.z = {
	\ 'name': '+zen-coding',
	\ ';': ['<key><c-z>;', 'expand-word'],
	\ ',': ['<key><c-z>,', 'expand-abbreviation'],
	\ 'u': ['<key><c-z>u', 'update-tag'],
	\ 'd': ['<key><c-z>d', 'balance-tag-inward'],
	\ 'D': ['<key><c-z>D', 'balance-tag-outward'],
	\ 'n': ['<key><c-z>n', 'next-edit-point'],
	\ 'N': ['<key><c-z>N', 'prev-edit-point'],
	\ 'i': ['<key><c-z>i', 'update-image-size'],
	\ 'm': ['<key><c-z>m', 'merge-lines'],
	\ 'k': ['<key><c-z>k', 'remove-tag'],
	\ 'j': ['<key><c-z>j', 'split-join-tag'],
	\ '/': ['<key><c-z>/', 'toggle-comment'],
	\ 'a': ['<key><c-z>a', 'make-anchor-url'],
	\ 'A': ['<key><c-z>A', 'quoted-text-url'],
	\ 'c': ['<key><c-z>c', 'code-pretty'],
	\ }

let b:navigator_insert.z = deepcopy(b:navigator.z)



"----------------------------------------------------------------------
" switch function
"----------------------------------------------------------------------
function! s:switch_css(name, values)
	let definition = {}
	let size = len(a:values)
	for index in range(size)
		let inext = index + 1
		let inext = (inext >= size)? 0 : inext
		let word = a:values[index]
		let next = a:values[inext]
		let key = printf('\<%s\>\s*:\s*\<%s\>', a:name, word)
		let val = printf('%s: %s', a:name, next)
		let definition[key] = val
	endfor
	return definition
endfunc


"----------------------------------------------------------------------
" switch.vim
"----------------------------------------------------------------------
let b:switch_custom_definitions = [
			\ s:switch_css('position', ['static', 'fixed', 'absolute', 'relative']),
			\ s:switch_css('display', ['block', 'inline-block', 'none', 'flex', 'grid']),
			\ s:switch_css('flex-direction', ['row', 'row-reverse', 'column', 'column-reverse']),
			\   {
			\      '\<align\>\s*:\s*left': 'align: right',
			\      '\<align\>\s*:\s*right': 'align: center',
			\      '\<align\>\s*:\s*center': 'align: left',
			\   },
			\ ]


