"======================================================================
"
" navigator.vim - 
"
" Created by skywind on 2023/06/27
" Last Modified: 2023/06/27 15:47:23
"
"======================================================================

let s:context = navigator#config#fetch('context', {})

if !has_key(s:context, 'page')
	finish
endif

let s:padding = s:context.padding
let s:spacing = s:context.spacing
let s:page = s:context.page
let s:content = s:page.content
let s:icon_separator = s:context.icon_separator

let s:position = repeat([0], len(s:page.cowidth))
let s:width = repeat([0], len(s:page.cowidth))
let startx = s:padding[0]

for i in range(len(s:position))
	let s:position[i] = startx
	let s:width[i] = s:page.cowidth[i]
	let startx += s:width[i]
	let startx += s:spacing
endfor

" messages clear
" echom printf("%s, %s, %s", s:position, s:width, 0)


"----------------------------------------------------------------------
" color the hole buffer
"----------------------------------------------------------------------
function! s:color_buffer()
	for y in range(len(s:content))
		let text = s:content[y]
		if text =~ '^\s\+$'
			continue
		endif
		" unsilent echom 'y: '. y
		for i in range(len(s:position))
			let x = s:position[i]
			let w = s:width[i]
			call s:color_item(text, x, w, y)
		endfor
	endfor
endfunc



"----------------------------------------------------------------------
" highlight region
"----------------------------------------------------------------------
function! s:high_region(name, srow, scol, erow, ecol, virtual)
	let sep = (a:virtual != 0)? 'c' : 'v'
	let cmd = 'syn region ' . a:name . ' '
	let cmd .= ' start=/\%' . a:srow . 'l\%' . a:scol . sep . '/'
	let cmd .= ' end=/\%' . a:erow . 'l\%' . a:ecol . sep . '/'
	return cmd
endfunc


"----------------------------------------------------------------------
" color item
"----------------------------------------------------------------------
function! s:color_item(text, pos, width, y) abort
	let part = strpart(a:text, a:pos, a:width)
	let head = matchstr(part, '^\s*\S\+')
	let skip = strlen(matchstr(head, '^\s*'))
	let head = strpart(head, skip)
	let size = strwidth(head)
	let y = a:y + 1
	let pos = a:pos + skip + 1
	let endup = a:pos + a:width + 1
	if 1
		" exec s:high_region('ErrorMsg', y, a:pos + 1, y, endup, 0)
		" return 0
	endif
	" echom printf("start pos=%d skip=%d: '%s'", pos, skip, part)
	if head[0] == '[' && head[size - 1] == ']'
		exec s:high_region('NavigatorBracket', y, pos + 0, y, pos + 1, 0)
		exec s:high_region('NavigatorKey', y, pos + 1, y, pos + 1 + size - 2, 0)
		exec s:high_region('NavigatorBracket', y, pos - 1 + size, y, pos + 0 + size, 0)
	else
		exec s:high_region('NavigatorKey', y, pos + 0, y, pos + size, 0)
	endif
	let pos += size + 1
	if s:icon_separator != ''
		let iw = strlen(s:icon_separator)
		exec s:high_region('NavigatorSeparator', y, pos, y, pos + iw, 0)
		let pos += iw + 1
	endif
	let mark = a:text[pos - 1]
	if mark != '+'
		exec s:high_region('NavigatorItem', y, pos, y, endup, 0)
	else
		exec s:high_region('NavigatorGroup', y, pos, y, endup, 0)
	endif
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! s:color_with_separator()
	let sep = s:icon_separator
	exec 'syntax match NavigatorSeparator /'. sep . '/ contained'
	exec 'syntax match NavigatorKey' '/\(^\s*\|\s\{2,}\)\S.\{-}'.sep.'/' 'contains=NavigatorSeparator'
	syntax match NavigatorGroup / +[0-9A-Za-z_/-]*/
	syntax region NavigatorItem start="^" end="$" contains=NavigatorKey, NavigatorGroup, NavigatorSeparator
endfunc



"----------------------------------------------------------------------
" main
"----------------------------------------------------------------------
syn clear

if s:icon_separator != ''
	call s:color_with_separator()
else
	call s:color_buffer()
endif

let b:current_syntax = 'navigator'


" echo s:position
" echo s:icon_separator


"----------------------------------------------------------------------
" highlighting
"----------------------------------------------------------------------
highlight default link NavigatorKey Special
highlight default link NavigatorBracket Normal
highlight default link NavigatorSeparator Type
highlight default link NavigatorItem Number
highlight default link NavigatorGroup Function

highlight default link NavigatorPopup Normal
highlight default link NavigatorFoot StatusLine
highlight default link NavigatorHead StatusLine
highlight default link NavigatorBorder Normal



