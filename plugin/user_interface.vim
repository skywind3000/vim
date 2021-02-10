"----------------------------------------------------------------------
" Query SnipMate Database
"----------------------------------------------------------------------
function! s:snipmate_query(word, exact) abort
	let matches = snipMate#GetSnippetsForWordBelowCursor(a:word, a:exact)
	let result = []
	let size = 4
	for [trigger, dict] in matches
		let body = ''
		for key in keys(dict)
			let value = dict[key]
			if type(value) == v:t_list
				if len(value) > 0
					let body = value[0]
					break
				endif
			endif
		endfor
		if body != ''
			let size = max([size, len(trigger)])
			let result += [[trigger, body]]
		endif
	endfor
	for item in result
		let t = item[0] . repeat(' ', size - len(item[0]))
		call extend(item, [t])
	endfor
	call sort(result)
	return result
endfunc


"----------------------------------------------------------------------
" Simplify Snippet Body
"----------------------------------------------------------------------
function! s:snipmate_clear(body, width) abort
	let text = join(split(a:body, '\n')[:4], ' ; ')
	let text = substitute(text, '^\s*\(.\{-}\)\s*$', '\1', '')
	let text = substitute(text, '\${[^{}]*}', '...', 'g')
	let text = substitute(text, '\${[^{}]*}', '...', 'g')
	let text = substitute(text, '\s\+', ' ', 'g')
	let text = strcharpart(text, 0, a:width)
	return text
endfunc



"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
let s:keymaps = '123456789abcdefimnopqrstuvwxyz'
let s:previous_cursor = -1


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! QuickUI_Snippet()
	let source = []
	let snippet = []
	let matches = s:snipmate_query('', 0)
	let snips = {}
	let width = 100
	let index = 0
	for item in matches
		let trigger = item[0]
		if trigger =~ '^\u'
			continue
		endif
		let key = (index < len(s:keymaps))? strpart(s:keymaps, index, 1) : ''
		let text = '[' . ((key == '')? ' ' : ('&' . key)) . "]\t"
		let text .= trigger . "\t"
		let text .= ": " . s:snipmate_clear(item[1], 100)
		let source += [text]
		let snippet += [trigger]
		let index += 1
	endfor
	let opts = {}
	let opts.title = 'Snippet Selector'
	let opts.index = s:previous_cursor
	let opts.h = &lines * 80 / 100
	let index = quickui#listbox#inputlist(source, opts)
	let s:previous_cursor = g:quickui#listbox#cursor
	if index >= 0 
		" return snippet[index] . "\<Plug>snipMateTrigger"
		return snippet[index] . "\<c-r>=snipMate#TriggerSnippet(1)\<cr>"
	endif
	return ''
endfunc



"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------

" imap <expr><c-x><c-h> QuickUI_Snippet()
imap <c-x><c-h> <c-r>=QuickUI_Snippet()<cr>




